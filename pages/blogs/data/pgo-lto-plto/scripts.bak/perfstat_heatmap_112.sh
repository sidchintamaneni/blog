#!/usr/bin/env bash
set -euo pipefail

# One-shot: UnixBench 112-instance front-end perf stat + temporal instruction-access
# heatmap, for ONE kernel-under-test. Run on the AutoFDO kernel and on the Propeller
# kernel (separate boots); everything is tagged by `uname -r` so the two never collide.
#
#   Phase A — perf stat -a over `./Run -c 112` (COUNT_RUNS times) -> the 5 Part-1 metrics
#             (Instructions T, Cycles T, IPC, L1-icache misses T, iTLB misses B).
#   Phase B — perf record of kernel IPs during a HEATMAP_SECS window while `./Run -c 112`
#             runs in the background -> temporal heatmap PNG (via plot_heatmap.py).
#
# Usage:
#   sudo ./perfstat_heatmap_112.sh
#   sudo COUNT_RUNS=3 HEATMAP_SECS=60 ./perfstat_heatmap_112.sh
#   # compare two kernels' stat summaries afterwards (no sudo):
#   ./perfstat_heatmap_112.sh compare <kernelA-summary>.txt <kernelB-summary>.txt
#
# Env: BENCH_DIR, UB_DIR, RESULTS_DIR, COUNT_RUNS (3), HEATMAP_SECS (60), HEATMAP_FREQ (4000).

# ----------------------------------------------------------------------------- compare mode
# `perfstat_heatmap_112.sh compare a.txt b.txt` -> side-by-side + delta of the 5 metrics.
# Parses "  <key> : <number>" rows from two summary files. No perf / root needed.
if [[ "${1:-}" == "compare" ]]; then
  A="${2:?usage: compare <baseline.txt> <candidate.txt>}"
  B="${3:?usage: compare <baseline.txt> <candidate.txt>}"
  [[ -r "$A" && -r "$B" ]] || { echo "cannot read $A and/or $B"; exit 1; }
  awk -v fa="$A" -v fb="$B" '
    function load(f, arr,   line,k,v) {
      while ((getline line < f) > 0) {
        if (line ~ /^[[:space:]]+[A-Za-z0-9_.@/ %()-]+[[:space:]]+:[[:space:]]+[-0-9.]+$/) {
          k=line; sub(/[[:space:]]*:[[:space:]]+[-0-9.]+$/, "", k); gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
          v=line; sub(/^.*:[[:space:]]+/, "", v); arr[k]=v
        }
      }
      close(f)
    }
    function asort_keys(arr, len,   i,j,t) {
      for (i=0;i<len;i++) for (j=i+1;j<len;j++) if (arr[j]<arr[i]) { t=arr[i];arr[i]=arr[j];arr[j]=t }
    }
    BEGIN {
      load(fa, A); load(fb, B)
      printf "%-24s %16s %16s %10s\n", "metric", "baseline", "candidate", "delta %"
      printf "%-24s %16s %16s %10s\n", "------------------------", "----------------", "----------------", "----------"
      for (k in A) seen[k]=1
      for (k in B) seen[k]=1
      n=0; for (k in seen) keys[n++]=k
      asort_keys(keys, n)
      for (i=0;i<n;i++) {
        k=keys[i]; if (!(k in A) || !(k in B)) continue
        a=A[k]+0; b=B[k]+0; d=(a!=0)?(b-a)/a*100:0
        printf "%-24s %16.3f %16.3f %+9.2f%%\n", k, a, b, d
      }
    }
  ' </dev/null
  exit 0
fi

BENCH_DIR="${BENCH_DIR:-/home/azure/sid/CBL-Mariner-Linux-Kernel/bench}"
UB_DIR="${UB_DIR:-${BENCH_DIR}/byte-unixbench/UnixBench}"
RESULTS_DIR="${RESULTS_DIR:-${BENCH_DIR}/results}"
COUNT_RUNS="${COUNT_RUNS:-3}"
HEATMAP_SECS="${HEATMAP_SECS:-60}"
HEATMAP_FREQ="${HEATMAP_FREQ:-4000}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then echo "needs sudo (system-wide perf -a)"; exit 1; fi
command -v perf >/dev/null || { echo "perf not found"; exit 1; }
[[ -d "${UB_DIR}" ]] || { echo "UnixBench dir not found: ${UB_DIR}"; exit 1; }

KVER="$(uname -r)"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "${RESULTS_DIR}"
SUMMARY="${RESULTS_DIR}/perfstat112-summary-${KVER}-${STAMP}.txt"
RAW_LOG="${RESULTS_DIR}/perfstat112-raw-${KVER}-${STAMP}.log"
HM_DATA="${RESULTS_DIR}/heatmap-112-${KVER}-${STAMP}.data"
HM_TXT="${RESULTS_DIR}/heatmap-112-${KVER}-${STAMP}.txt"
HM_PNG="${RESULTS_DIR}/temporal-112-${KVER}-${STAMP}.png"
OWNER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"

# the 5 Part-1 metrics need exactly these events
CANDIDATE_EVENTS=(instructions cycles L1-icache-load-misses iTLB-load-misses)
supported_events() {
  local ev keep=()
  for ev in "${CANDIDATE_EVENTS[@]}"; do
    perf stat -e "${ev}" -- true >/dev/null 2>&1 && keep+=("${ev}") \
      || echo "  (dropping unsupported event: ${ev})" >&2
  done
  ( IFS=,; echo "${keep[*]}" )
}

stats() {  # mean + sample stddev of args
  awk '{n=NF; if(n==0){print "0 0"; exit} s=0; for(i=1;i<=n;i++)s+=$i; m=s/n;
        ss=0; for(i=1;i<=n;i++){d=$i-m; ss+=d*d} sd=(n>1)?sqrt(ss/(n-1)):0;
        printf "%.3f %.3f", m, sd}' <<< "$*"
}

echo ">> Detecting supported perf events ..." >&2
EVENTS="$(supported_events)"
echo ">> events: ${EVENTS}" >&2

# noise control (best-effort)
cpupower frequency-set -g performance >/dev/null 2>&1 || true
cpupower idle-set -D 0               >/dev/null 2>&1 || true

{
  echo "perf stat + heatmap (UnixBench 112-instance)"
  echo "kernel      : ${KVER}"
  echo "date        : $(date)"
  echo "events      : ${EVENTS}"
  echo "COUNT_RUNS  : ${COUNT_RUNS}   HEATMAP_SECS: ${HEATMAP_SECS}   FREQ: ${HEATMAP_FREQ}"
} | tee "${SUMMARY}"

# ----------------------------------------------------------------- Phase A: perf stat
declare -A acc
IFS=, read -ra EV_ARR <<< "${EVENTS}"
for ev in "${EV_ARR[@]}"; do acc["$ev"]=""; done

for r in $(seq 1 "${COUNT_RUNS}"); do
  echo ">> perf stat run ${r}/${COUNT_RUNS}: ./Run -c 112" >&2
  tmp="$(mktemp)"
  echo "######## perf stat run ${r}/${COUNT_RUNS} ($(date)) ########" >> "${RAW_LOG}"
  perf stat -a -x, -e "${EVENTS}" -o "${tmp}" -- bash -c "cd '${UB_DIR}' && ./Run -c 112" \
    >>"${RAW_LOG}" 2>&1 || true
  cat "${tmp}" >> "${RAW_LOG}"
  while IFS=, read -r count _unit event _rest; do
    [[ -z "${event:-}" ]] && continue
    [[ "${count}" =~ ^[0-9]+$ ]] || continue
    acc["${event}"]+=" ${count}"
  done < <(grep -v '^#' "${tmp}" | grep -v '^[[:space:]]*$')
  rm -f "${tmp}"
done

# means
ins="$(stats ${acc[instructions]:-0}            | awk '{print $1}')"
cyc="$(stats ${acc[cycles]:-0}                  | awk '{print $1}')"
l1i="$(stats ${acc[L1-icache-load-misses]:-0}   | awk '{print $1}')"
itlb="$(stats ${acc[iTLB-load-misses]:-0}       | awk '{print $1}')"

echo | tee -a "${SUMMARY}"
echo "================ perf stat (5 Part-1 metrics, ${COUNT_RUNS}-run means) ================" | tee -a "${SUMMARY}"
awk -v ins="$ins" -v cyc="$cyc" -v l1i="$l1i" -v itlb="$itlb" -v out="${SUMMARY}" '
function emit(name,val){ printf "  %-22s : %s\n", name, val; printf "  %-22s : %s\n", name, val >> out }
BEGIN{
  emit("Instructions (T)",     sprintf("%.2f", ins/1e12))
  emit("Cycles (T)",           sprintf("%.2f", cyc/1e12))
  emit("IPC",                  (cyc>0)? sprintf("%.3f", ins/cyc) : "n/a")
  emit("L1-icache misses (T)", sprintf("%.3f", l1i/1e12))
  emit("iTLB misses (B)",      sprintf("%.3f", itlb/1e9))
  # work-normalized rates (misses per 1000 instructions) — these are the apples-to-apples
  # numbers to compare across kernels, since UnixBench is time-boxed (work is NOT constant,
  # so total counts scale with throughput; only the per-instruction RATE is comparable).
  emit("L1i-MPKI",             (ins>0)? sprintf("%.3f", l1i/ins*1000) : "n/a")
  emit("iTLB-MPKI",            (ins>0)? sprintf("%.3f", itlb/ins*1000) : "n/a")
}'

# ----------------------------------------------------------------- Phase B: heatmap
echo | tee -a "${SUMMARY}"
echo ">> Phase B: heatmap capture (${HEATMAP_SECS}s window during ./Run -c 112)" >&2
pkill -f 'byte-unixbench' 2>/dev/null || true

( cd "${UB_DIR}" && ./Run -c 112 ) >/dev/null 2>&1 &
UB_BG=$!
sleep 5   # let the load ramp up
# sample kernel instruction pointers system-wide, with timestamps, for a fixed window
perf record -F "${HEATMAP_FREQ}" -e cycles:k -a --timestamp -o "${HM_DATA}" -- sleep "${HEATMAP_SECS}" || true
pkill -f 'byte-unixbench' 2>/dev/null || true
wait "${UB_BG}" 2>/dev/null || true

# dump <time, ip, dso>, keep kernel samples only (single-module offset axis)
perf script -i "${HM_DATA}" -F time,ip,dso 2>/dev/null | grep -F '[kernel.kallsyms]' > "${HM_TXT}" || true
chown "${OWNER}" "${HM_DATA}" "${HM_TXT}" 2>/dev/null || true
echo "heatmap samples : $(wc -l < "${HM_TXT}" 2>/dev/null || echo 0)" | tee -a "${SUMMARY}"

# render PNG if we can
if command -v python3 >/dev/null && python3 -c 'import numpy, matplotlib' 2>/dev/null \
   && [[ -s "${HM_TXT}" && -f "${SCRIPT_DIR}/plot_heatmap.py" ]]; then
  sudo -u "${OWNER}" python3 "${SCRIPT_DIR}/plot_heatmap.py" "${HM_TXT}" \
    -o "${HM_PNG}" --title "${KVER} (112-inst)" || echo "(plot failed; data is in ${HM_TXT})"
  chown "${OWNER}" "${HM_PNG}" 2>/dev/null || true
  echo "heatmap PNG     : ${HM_PNG}" | tee -a "${SUMMARY}"
else
  echo "heatmap PNG     : skipped (need python3 + numpy + matplotlib); plot later with:" | tee -a "${SUMMARY}"
  echo "    python3 '${SCRIPT_DIR}/plot_heatmap.py' '${HM_TXT}' -o '${HM_PNG}' --title '${KVER} (112-inst)'" | tee -a "${SUMMARY}"
fi

chown "${OWNER}" "${SUMMARY}" "${RAW_LOG}" 2>/dev/null || true
echo | tee -a "${SUMMARY}"
echo "=================================================================" | tee -a "${SUMMARY}"
echo "Summary : ${SUMMARY}" | tee -a "${SUMMARY}"
echo "Raw log : ${RAW_LOG}" | tee -a "${SUMMARY}"
echo "Heatmap : ${HM_TXT}  /  ${HM_PNG}"
echo "Compare two kernels: ./perfstat_heatmap_112.sh compare <a>.txt <b>.txt"
echo "================================================================="
