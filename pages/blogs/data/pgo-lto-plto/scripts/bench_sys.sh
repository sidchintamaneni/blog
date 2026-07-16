#!/usr/bin/env bash
set -euo pipefail

# bench_sys.sh — sysbench characterization for ONE kernel-under-test.
#
#   1. sysbench cpu/memory/threads/mutex, RUNS times each (default 3), mean ± sd of eps.
#   2. perf stat (ONE run over the full 4-test suite): instructions, cycles, IPC,
#      L1-icache misses, iTLB misses.
#   3. Instruction-access heatmap (ONE capture of kernel IPs during the threads test —
#      the most kernel-hot of the four).
#
# Run with sudo (perf -a needs root). sysbench is dropped back to the invoking user.
#
#   sudo ./bench_sys.sh
#
# Logs land next to this script:
#   logs/<uname -r>/sysbench/{cpu,memory,threads,mutex}.txt
#   logs/<uname -r>/perfstat/sysbench.csv           + summary.txt
#   logs/<uname -r>/heatmap-sys/heatmap.{data,txt,png}
#   logs/<uname -r>/summary.txt   (appended)

# ----------------------------------------------------------------- config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="${BENCH_DIR:-/home/azure/sid/CBL-Mariner-Linux-Kernel/bench}"
SYSBENCH="${SYSBENCH:-${BENCH_DIR}/sysbench/src/sysbench}"
RUNS="${RUNS:-3}"
THREADS="${THREADS:-208}"
RUN_TIME="${RUN_TIME:-60}"
HEATMAP_SECS="${HEATMAP_SECS:-60}"
HEATMAP_FREQ="${HEATMAP_FREQ:-4000}"

if [[ "$(id -u)" -ne 0 ]]; then echo "run with sudo (perf -a needs root)"; exit 1; fi
command -v perf >/dev/null || { echo "perf not found"; exit 1; }
[[ -x "${SYSBENCH}" ]] || { echo "sysbench not found/executable: ${SYSBENCH}"; exit 1; }

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
KVER="$(uname -r)"
LOGROOT="${SCRIPT_DIR}/logs/${KVER}"
SUMMARY="${LOGROOT}/summary.txt"
mkdir -p "${LOGROOT}"

as_user() { sudo -u "${REAL_USER}" bash -c "$1"; }

# mean + sample stddev of args
stats() {
  awk '{n=NF; if(n==0){print "0 0"; exit} s=0; for(i=1;i<=n;i++)s+=$i; m=s/n;
        ss=0; for(i=1;i<=n;i++){d=$i-m; ss+=d*d} sd=(n>1)?sqrt(ss/(n-1)):0;
        printf "%.1f %.1f", m, sd}' <<< "$*"
}

# keep only perf events this CPU supports
EV_WANT=(instructions cycles L1-icache-load-misses iTLB-load-misses)
ev_supported() {
  local ev keep=()
  for ev in "${EV_WANT[@]}"; do
    perf stat -e "${ev}" -- true >/dev/null 2>&1 && keep+=("${ev}") \
      || echo "  (dropping unsupported event: ${ev})" >&2
  done
  ( IFS=,; echo "${keep[*]}" )
}

# sysbench invocation for a given test name -> stdout
sb_cmd() {
  case "$1" in
    cpu)     echo "${SYSBENCH} cpu --threads=${THREADS} --cpu-max-prime=20000 --time=${2:-$RUN_TIME} run" ;;
    memory)  echo "${SYSBENCH} memory --threads=${THREADS} --memory-total-size=100G --memory-block-size=1M --time=${2:-$RUN_TIME} run" ;;
    threads) echo "${SYSBENCH} threads --threads=${THREADS} --thread-yields=1001 --thread-locks=8 --time=${2:-$RUN_TIME} run" ;;
    mutex)   echo "${SYSBENCH} mutex --threads=${THREADS} --mutex-num=4097 --mutex-locks=50000 --mutex-loops=10000 run" ;;
  esac
}

# pull "events/s (eps): N" from sysbench output
parse_eps() { awk -F: '/events\/s \(eps\)/{gsub(/[ \t]/,"",$2); print $2; exit}'; }

{
  echo
  echo "bench_sys.sh"
  echo "kernel : ${KVER}"
  echo "user   : ${REAL_USER}"
  echo "date   : $(date)"
  echo "RUNS   : ${RUNS}   THREADS: ${THREADS}   RUN_TIME: ${RUN_TIME}s"
} | tee -a "${SUMMARY}"

# noise control (best-effort)
cpupower frequency-set -g performance >/dev/null 2>&1 || true
cpupower idle-set -D 0               >/dev/null 2>&1 || true

# ----------------------------------------------------------------- 1) sysbench benchmark
sbdir="${LOGROOT}/sysbench"
mkdir -p "${sbdir}"
echo "== sysbench (${RUNS} runs each, eps) ==" | tee -a "${SUMMARY}"
for test in cpu memory threads mutex; do
  epslist=()
  for r in $(seq 1 "${RUNS}"); do
    echo ">> sysbench ${test}: run ${r}/${RUNS}" >&2
    log="${sbdir}/${test}-run${r}.log"
    as_user "$(sb_cmd "${test}")" > "${log}" 2>&1 || true
    eps="$(parse_eps < "${log}")"
    epslist+=("${eps:-0}")
  done
  read -r mean sd <<< "$(stats "${epslist[@]}")"
  {
    echo "runs (eps)  : ${epslist[*]}"
    echo "mean ± sd   : ${mean} ± ${sd}"
  } > "${sbdir}/${test}.txt"
  echo "[sysbench ${test}] ${epslist[*]}  ->  ${mean} ± ${sd}" | tee -a "${SUMMARY}"
done

# ----------------------------------------------------------------- 2) perf stat (1 suite run)
EVENTS="$(ev_supported)"
psdir="${LOGROOT}/perfstat"
mkdir -p "${psdir}"
csv="${psdir}/sysbench.csv"
echo "events : ${EVENTS}" | tee -a "${SUMMARY}"
echo "== perf stat (1 run, full suite) ==" | tee -a "${SUMMARY}"
echo ">> perf stat: sysbench cpu+memory+threads+mutex" >&2
perf stat -a -x, -e "${EVENTS}" -o "${csv}" -- sudo -u "${REAL_USER}" bash -c "
  $(sb_cmd cpu)     ;
  $(sb_cmd memory)  ;
  $(sb_cmd threads) ;
  $(sb_cmd mutex)   " >/dev/null 2>&1 || true
ins=0; cyc=0; l1i=0; itlb=0
while IFS=, read -r count _u event _rest; do
  [[ "${count}" =~ ^[0-9]+$ ]] || continue
  case "${event}" in
    instructions)            ins="${count}"  ;;
    cycles)                  cyc="${count}"  ;;
    L1-icache-load-misses)   l1i="${count}"  ;;
    iTLB-load-misses)        itlb="${count}" ;;
  esac
done < <(grep -v '^#' "${csv}" | grep -v '^[[:space:]]*$')
{
  echo "[sysbench suite]"
  awk -v ins="$ins" -v cyc="$cyc" -v l1i="$l1i" -v itlb="$itlb" 'BEGIN{
    printf "  Instructions      : %.0f\n", ins
    printf "  Cycles            : %.0f\n", cyc
    printf "  IPC               : %s\n", (cyc>0)? sprintf("%.3f", ins/cyc) : "n/a"
    printf "  L1-icache misses  : %.0f\n", l1i
    printf "  iTLB misses       : %.0f\n", itlb
  }'
} | tee -a "${SUMMARY}"

# ----------------------------------------------------------------- 3) heatmap (threads test)
hmdir="${LOGROOT}/heatmap-sys"
mkdir -p "${hmdir}"
HM_DATA="${hmdir}/heatmap.data"
HM_TXT="${hmdir}/heatmap.txt"
HM_PNG="${hmdir}/heatmap.png"
echo "== heatmap (${HEATMAP_SECS}s window during sysbench threads) ==" | tee -a "${SUMMARY}"

# run threads long enough to cover the 5s pre-roll + record window
as_user "$(sb_cmd threads $((HEATMAP_SECS + 20)))" >/dev/null 2>&1 &
SB_BG=$!
sleep 5
perf record -F "${HEATMAP_FREQ}" -e cycles:k -a --timestamp -o "${HM_DATA}" -- sleep "${HEATMAP_SECS}" || true
kill "${SB_BG}" 2>/dev/null || true
wait "${SB_BG}" 2>/dev/null || true

perf script -i "${HM_DATA}" -F time,ip,dso 2>/dev/null | grep -F '[kernel.kallsyms]' > "${HM_TXT}" || true
echo "heatmap samples : $(wc -l < "${HM_TXT}" 2>/dev/null || echo 0)" | tee -a "${SUMMARY}"

if [[ -s "${HM_TXT}" ]] && command -v python3 >/dev/null && python3 -c 'import numpy,matplotlib' 2>/dev/null; then
  chown -R "${REAL_USER}" "${hmdir}" 2>/dev/null || true
  sudo -u "${REAL_USER}" python3 - "${HM_TXT}" "${HM_PNG}" "${KVER} (sysbench threads)" <<'PY'
import sys, re
import numpy as np
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
txt, png, title = sys.argv[1], sys.argv[2], sys.argv[3]
LINE = re.compile(r"^\s*([0-9]+\.[0-9]+):\s*([0-9a-fA-F]+)\b")
t, ip = [], []
for line in open(txt, errors="ignore"):
    m = LINE.match(line)
    if m:
        t.append(float(m.group(1))); ip.append(int(m.group(2), 16))
if not ip:
    sys.exit("no samples")
t = np.array(t); ip = np.array(ip, dtype=float)
x = (t - t.min()) / max(t.max() - t.min(), 1e-9)
y = (ip - ip.min()) / 1e6
span = float(np.percentile(y, 99))
h, _, _ = np.histogram2d(x, y, bins=800, range=[[0, 1], [0, span]])
h = np.ma.masked_where(h.T == 0, h.T)
fig, ax = plt.subplots(figsize=(7, 5))
im = ax.imshow(h, origin="lower", aspect="auto", extent=[0, 1, 0, span],
               cmap="inferno", norm=LogNorm(vmin=1, vmax=max(h.max(), 1)))
ax.set_facecolor("black")
ax.set_xlabel("Time (normalized)"); ax.set_ylabel(".text offset (MB)"); ax.set_title(title)
fig.colorbar(im, ax=ax, label="samples / bin (log)")
fig.savefig(png, dpi=150, bbox_inches="tight")
print("wrote", png)
PY
  echo "heatmap PNG     : ${HM_PNG}" | tee -a "${SUMMARY}"
else
  echo "heatmap PNG     : skipped (need python3 + numpy + matplotlib); data in ${HM_TXT}" | tee -a "${SUMMARY}"
fi

# ----------------------------------------------------------------- ownership + done
chown -R "${REAL_USER}" "${LOGROOT}" 2>/dev/null || true
echo "============================================================" | tee -a "${SUMMARY}"
echo "logs: ${LOGROOT}" | tee -a "${SUMMARY}"
