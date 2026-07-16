#!/usr/bin/env bash
set -euo pipefail

# bench_net.sh — neper (loopback) characterization for ONE kernel-under-test.
#
#   1. tcp_rr (latency + tx/s) and tcp_stream (Mbit/s) over loopback, RUNS times each
#      (default 3), 1 flow / 1 thread — mean ± sd.
#   2. perf stat (ONE loopback tcp_rr run): instructions, cycles, IPC,
#      L1-icache misses, iTLB misses.
#   3. Instruction-access heatmap (ONE capture of kernel IPs during loopback tcp_rr —
#      the network stack is kernel-hot).
#
# Loopback only (single host); two-machine runs still use bench_neper.sh.
# Run with sudo (perf -a needs root). neper itself runs as the invoking user.
#
#   sudo ./bench_net.sh
#
# Logs land next to this script:
#   logs/<uname -r>/neper/{tcp_rr,tcp_stream}.txt
#   logs/<uname -r>/perfstat/neper.csv        + summary.txt
#   logs/<uname -r>/heatmap-net/heatmap.{data,txt,png}
#   logs/<uname -r>/summary.txt   (appended)

# ----------------------------------------------------------------- config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="${BENCH_DIR:-/home/azure/sid/CBL-Mariner-Linux-Kernel/bench}"
NEPER_DIR="${NEPER_DIR:-${BENCH_DIR}/neper}"
RUNS="${RUNS:-3}"
FLOWS="${FLOWS:-1}"
NTHREADS="${NTHREADS:-1}"
LENGTH="${LENGTH:-60}"
HEATMAP_SECS="${HEATMAP_SECS:-60}"
HEATMAP_FREQ="${HEATMAP_FREQ:-4000}"

if [[ "$(id -u)" -ne 0 ]]; then echo "run with sudo (perf -a needs root)"; exit 1; fi
command -v perf >/dev/null || { echo "perf not found"; exit 1; }
for b in tcp_rr tcp_stream; do
  [[ -x "${NEPER_DIR}/${b}" ]] || { echo "missing neper binary: ${NEPER_DIR}/${b}"; exit 1; }
done

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
        printf "%.3f %.3f", m, sd}' <<< "$*"
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

kv() { grep -m1 "^$2=" <<< "$1" | cut -d= -f2; }   # kv "<text>" key

# one loopback run of a bench: server(bg) + client(fg). echoes "server_out|||client_out"
neper_loopback() {
  local bench="$1" srv cli
  srv="$(mktemp)"
  as_user "'${NEPER_DIR}/${bench}' -F ${FLOWS} -T ${NTHREADS} -l ${LENGTH}" >"${srv}" 2>&1 &
  local sp=$!
  sleep 1
  cli="$(as_user "'${NEPER_DIR}/${bench}' -F ${FLOWS} -T ${NTHREADS} -l ${LENGTH} -c -H 127.0.0.1" 2>/dev/null || true)"
  wait "${sp}" 2>/dev/null || true
  printf '%s\n|||\n%s\n' "$(cat "${srv}")" "${cli}"
  rm -f "${srv}"
}

{
  echo
  echo "bench_net.sh (loopback)"
  echo "kernel : ${KVER}"
  echo "user   : ${REAL_USER}"
  echo "date   : $(date)"
  echo "RUNS   : ${RUNS}   F=${FLOWS} T=${NTHREADS} l=${LENGTH}s"
} | tee -a "${SUMMARY}"

# noise control (best-effort)
cpupower frequency-set -g performance >/dev/null 2>&1 || true
cpupower idle-set -D 0               >/dev/null 2>&1 || true

# ensure loopback traffic is allowed (DROP policy can block 127.0.0.1 after reboot)
iptables -C INPUT -i lo -j ACCEPT 2>/dev/null || iptables -I INPUT -i lo -j ACCEPT 2>/dev/null || true

# ----------------------------------------------------------------- 1) neper benchmark
npdir="${LOGROOT}/neper"
mkdir -p "${npdir}"
echo "== neper loopback (${RUNS} runs each) ==" | tee -a "${SUMMARY}"

# tcp_rr: latency (µs) + throughput (tx/s), reported by the client
lat_list=(); rr_thr_list=()
for r in $(seq 1 "${RUNS}"); do
  echo ">> tcp_rr: run ${r}/${RUNS}" >&2
  out="$(neper_loopback tcp_rr)"
  cli="${out#*|||}"
  lat_s="$(kv "${cli}" latency_mean)"       # seconds
  thr="$(kv "${cli}" throughput)"           # tx/s
  lat_us="$(awk -v s="${lat_s:-0}" 'BEGIN{printf "%.3f", s*1e6}')"
  lat_list+=("${lat_us}"); rr_thr_list+=("${thr:-0}")
done
read -r lat_m lat_sd     <<< "$(stats "${lat_list[@]}")"
read -r rrt_m rrt_sd     <<< "$(stats "${rr_thr_list[@]}")"
{
  echo "latency_mean runs (µs) : ${lat_list[*]}"
  echo "latency_mean mean ± sd : ${lat_m} ± ${lat_sd} µs"
  echo "throughput   runs(tx/s): ${rr_thr_list[*]}"
  echo "throughput   mean ± sd : ${rrt_m} ± ${rrt_sd} tx/s"
} > "${npdir}/tcp_rr.txt"
echo "[tcp_rr] latency ${lat_m} ± ${lat_sd} µs | throughput ${rrt_m} ± ${rrt_sd} tx/s" | tee -a "${SUMMARY}"

# tcp_stream: throughput (Mbit/s), reported by the reader (server side)
st_list=()
for r in $(seq 1 "${RUNS}"); do
  echo ">> tcp_stream: run ${r}/${RUNS}" >&2
  out="$(neper_loopback tcp_stream)"
  srv="${out%%|||*}"
  thr="$(kv "${srv}" throughput)"           # Mbit/s
  st_list+=("${thr:-0}")
done
read -r st_m st_sd <<< "$(stats "${st_list[@]}")"
{
  echo "throughput runs (Mb/s) : ${st_list[*]}"
  echo "throughput mean ± sd   : ${st_m} ± ${st_sd} Mbit/s"
} > "${npdir}/tcp_stream.txt"
echo "[tcp_stream] ${st_m} ± ${st_sd} Mbit/s" | tee -a "${SUMMARY}"

# ----------------------------------------------------------------- 2) perf stat (1 tcp_rr run)
EVENTS="$(ev_supported)"
psdir="${LOGROOT}/perfstat"
mkdir -p "${psdir}"
csv="${psdir}/neper.csv"
echo "events : ${EVENTS}" | tee -a "${SUMMARY}"
echo "== perf stat (1 run, loopback tcp_rr) ==" | tee -a "${SUMMARY}"
echo ">> perf stat: loopback tcp_rr" >&2
perf stat -a -x, -e "${EVENTS}" -o "${csv}" -- bash -c "
  sudo -u '${REAL_USER}' '${NEPER_DIR}/tcp_rr' -F ${FLOWS} -T ${NTHREADS} -l ${LENGTH} >/dev/null 2>&1 &
  sleep 1
  sudo -u '${REAL_USER}' '${NEPER_DIR}/tcp_rr' -F ${FLOWS} -T ${NTHREADS} -l ${LENGTH} -c -H 127.0.0.1 >/dev/null 2>&1
  wait" >/dev/null 2>&1 || true
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
  echo "[loopback tcp_rr]"
  awk -v ins="$ins" -v cyc="$cyc" -v l1i="$l1i" -v itlb="$itlb" 'BEGIN{
    printf "  Instructions      : %.0f\n", ins
    printf "  Cycles            : %.0f\n", cyc
    printf "  IPC               : %s\n", (cyc>0)? sprintf("%.3f", ins/cyc) : "n/a"
    printf "  L1-icache misses  : %.0f\n", l1i
    printf "  iTLB misses       : %.0f\n", itlb
  }'
} | tee -a "${SUMMARY}"

# ----------------------------------------------------------------- 3) heatmap (loopback tcp_rr)
hmdir="${LOGROOT}/heatmap-net"
mkdir -p "${hmdir}"
HM_DATA="${hmdir}/heatmap.data"
HM_TXT="${hmdir}/heatmap.txt"
HM_PNG="${hmdir}/heatmap.png"
echo "== heatmap (${HEATMAP_SECS}s window during loopback tcp_rr) ==" | tee -a "${SUMMARY}"

HM_LEN=$((HEATMAP_SECS + 20))
as_user "'${NEPER_DIR}/tcp_rr' -F ${FLOWS} -T ${NTHREADS} -l ${HM_LEN}" >/dev/null 2>&1 &
SRV_BG=$!
sleep 1
as_user "'${NEPER_DIR}/tcp_rr' -F ${FLOWS} -T ${NTHREADS} -l ${HM_LEN} -c -H 127.0.0.1" >/dev/null 2>&1 &
CLI_BG=$!
sleep 5
perf record -F "${HEATMAP_FREQ}" -e cycles:k -a --timestamp -o "${HM_DATA}" -- sleep "${HEATMAP_SECS}" || true
kill "${SRV_BG}" "${CLI_BG}" 2>/dev/null || true
wait "${SRV_BG}" "${CLI_BG}" 2>/dev/null || true

perf script -i "${HM_DATA}" -F time,ip,dso 2>/dev/null | grep -F '[kernel.kallsyms]' > "${HM_TXT}" || true
echo "heatmap samples : $(wc -l < "${HM_TXT}" 2>/dev/null || echo 0)" | tee -a "${SUMMARY}"

if [[ -s "${HM_TXT}" ]] && command -v python3 >/dev/null && python3 -c 'import numpy,matplotlib' 2>/dev/null; then
  chown -R "${REAL_USER}" "${hmdir}" 2>/dev/null || true
  sudo -u "${REAL_USER}" python3 - "${HM_TXT}" "${HM_PNG}" "${KVER} (loopback tcp_rr)" <<'PY'
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
