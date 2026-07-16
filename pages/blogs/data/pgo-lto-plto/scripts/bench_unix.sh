#!/usr/bin/env bash
set -euo pipefail

# bench_unix.sh — UnixBench characterization for ONE kernel-under-test.
#
#   1. Index benchmark: 1-instance and 112-instance, RUNS times each (default 3).
#   2. perf stat (ONE run each of 1-inst and 112-inst): instructions, cycles, IPC,
#      L1-icache misses, iTLB misses.
#   3. Instruction-access heatmap (ONE capture of kernel IPs during ./Run -c 112).
#
# Run with sudo (perf -a needs root). ./Run is dropped back to the invoking user so it
# never litters root-owned scratch files in the UnixBench tree.
#
#   sudo ./bench_unix.sh
#
# Logs land next to this script:
#   logs/<uname -r>/unixbench-1inst/run{1..3}.log   + score.txt
#   logs/<uname -r>/unixbench-112inst/run{1..3}.log + score.txt
#   logs/<uname -r>/perfstat/{1inst,112inst}.csv    + summary.txt
#   logs/<uname -r>/heatmap/heatmap.{data,txt,png}
#   logs/<uname -r>/summary.txt

# ----------------------------------------------------------------- config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="${BENCH_DIR:-/home/azure/sid/CBL-Mariner-Linux-Kernel/bench}"
UB_DIR="${UB_DIR:-${BENCH_DIR}/byte-unixbench/UnixBench}"
RUNS="${RUNS:-3}"
COPIES_HIGH="${COPIES_HIGH:-112}"
HEATMAP_SECS="${HEATMAP_SECS:-60}"
HEATMAP_FREQ="${HEATMAP_FREQ:-4000}"

if [[ "$(id -u)" -ne 0 ]]; then echo "run with sudo (perf -a needs root)"; exit 1; fi
command -v perf >/dev/null || { echo "perf not found"; exit 1; }
[[ -d "${UB_DIR}" ]] || { echo "UnixBench dir not found: ${UB_DIR}"; exit 1; }

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
KVER="$(uname -r)"
LOGROOT="${SCRIPT_DIR}/logs/${KVER}"
SUMMARY="${LOGROOT}/summary.txt"
mkdir -p "${LOGROOT}"

# run a shell command as the invoking (non-root) user
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

{
  echo "bench_unix.sh"
  echo "kernel : ${KVER}"
  echo "user   : ${REAL_USER}"
  echo "date   : $(date)"
  echo "RUNS   : ${RUNS}   COPIES_HIGH: ${COPIES_HIGH}"
} | tee "${SUMMARY}"

# noise control (best-effort)
cpupower frequency-set -g performance >/dev/null 2>&1 || true
cpupower idle-set -D 0               >/dev/null 2>&1 || true

# ----------------------------------------------------------------- 1) index benchmark
for COPIES in 1 "${COPIES_HIGH}"; do
  name="unixbench-${COPIES}inst"
  dir="${LOGROOT}/${name}"
  mkdir -p "${dir}"
  scores=()
  for r in $(seq 1 "${RUNS}"); do
    echo ">> ${name}: run ${r}/${RUNS}" >&2
    log="${dir}/run${r}.log"
    as_user "cd '${UB_DIR}' && ./Run -c ${COPIES}" > "${log}" 2>&1 || true
    s="$(grep 'System Benchmarks Index Score' "${log}" | tail -1 | awk '{print $NF}')"
    scores+=("${s:-0}")
  done
  read -r mean sd <<< "$(stats "${scores[@]}")"
  {
    echo "runs        : ${scores[*]}"
    echo "mean ± sd   : ${mean} ± ${sd}"
  } > "${dir}/score.txt"
  echo "[${name}] ${scores[*]}  ->  ${mean} ± ${sd}" | tee -a "${SUMMARY}"
done

# ----------------------------------------------------------------- 2) perf stat (1 run each)
EVENTS="$(ev_supported)"
psdir="${LOGROOT}/perfstat"
mkdir -p "${psdir}"
echo "events : ${EVENTS}" | tee -a "${SUMMARY}"
echo "== perf stat (1 run each) ==" | tee -a "${SUMMARY}"

for COPIES in 1 "${COPIES_HIGH}"; do
  csv="${psdir}/${COPIES}inst.csv"
  echo ">> perf stat: ./Run -c ${COPIES}" >&2
  perf stat -a -x, -e "${EVENTS}" -o "${csv}" -- \
    sudo -u "${REAL_USER}" bash -c "cd '${UB_DIR}' && ./Run -c ${COPIES}" >/dev/null 2>&1 || true
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
    echo "[${COPIES}-instance]"
    awk -v ins="$ins" -v cyc="$cyc" -v l1i="$l1i" -v itlb="$itlb" 'BEGIN{
      printf "  Instructions      : %.0f\n", ins
      printf "  Cycles            : %.0f\n", cyc
      printf "  IPC               : %s\n", (cyc>0)? sprintf("%.3f", ins/cyc) : "n/a"
      printf "  L1-icache misses  : %.0f\n", l1i
      printf "  iTLB misses       : %.0f\n", itlb
    }'
  } | tee -a "${SUMMARY}"
done

# ----------------------------------------------------------------- 3) heatmap (1 capture)
hmdir="${LOGROOT}/heatmap"
mkdir -p "${hmdir}"
HM_DATA="${hmdir}/heatmap.data"
HM_TXT="${hmdir}/heatmap.txt"
HM_PNG="${hmdir}/heatmap.png"
echo "== heatmap (${HEATMAP_SECS}s window during ./Run -c ${COPIES_HIGH}) ==" | tee -a "${SUMMARY}"

pkill -f 'byte-unixbench' 2>/dev/null || true
as_user "cd '${UB_DIR}' && ./Run -c ${COPIES_HIGH}" >/dev/null 2>&1 &
UB_BG=$!
sleep 5
perf record -F "${HEATMAP_FREQ}" -e cycles:k -a --timestamp -o "${HM_DATA}" -- sleep "${HEATMAP_SECS}" || true
pkill -f 'byte-unixbench' 2>/dev/null || true
wait "${UB_BG}" 2>/dev/null || true

perf script -i "${HM_DATA}" -F time,ip,dso 2>/dev/null | grep -F '[kernel.kallsyms]' > "${HM_TXT}" || true
echo "heatmap samples : $(wc -l < "${HM_TXT}" 2>/dev/null || echo 0)" | tee -a "${SUMMARY}"

# render PNG inline (needs numpy + matplotlib); skip gracefully if missing
if [[ -s "${HM_TXT}" ]] && command -v python3 >/dev/null && python3 -c 'import numpy,matplotlib' 2>/dev/null; then
  # the heatmap dir was created by root; hand it to REAL_USER so the (non-root)
  # python render can write heatmap.png into it
  chown -R "${REAL_USER}" "${hmdir}" 2>/dev/null || true
  sudo -u "${REAL_USER}" python3 - "${HM_TXT}" "${HM_PNG}" "${KVER} (112-inst)" <<'PY'
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
y = (ip - ip.min()) / 1e6                 # .text offset, MB
span = float(np.percentile(y, 99))        # zoom past sparse module/BPF samples
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
