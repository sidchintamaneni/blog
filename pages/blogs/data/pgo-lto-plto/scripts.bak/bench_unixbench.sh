#!/usr/bin/env bash
set -euo pipefail

# Benchmark: UnixBench (1-instance and 112-instance), repeated for statistics.
# Run this on the kernel-under-test. No perf — this is performance measurement.

BENCH_DIR="${BENCH_DIR:-/home/azure/sid/CBL-Mariner-Linux-Kernel/bench}"
UB_DIR="${UB_DIR:-${BENCH_DIR}/byte-unixbench/UnixBench}"
COPIES_HIGH="${COPIES_HIGH:-112}"
RUNS="${RUNS:-3}"
RESULTS_DIR="${RESULTS_DIR:-${BENCH_DIR}/results}"

KVER="$(uname -r)"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "${RESULTS_DIR}"

cd "${UB_DIR}"

# mean + sample stddev of the numbers passed as args
stats() {
  awk '{
    n=NF; sum=0;
    for (i=1;i<=n;i++) sum+=$i;
    mean=sum/n;
    ss=0;
    for (i=1;i<=n;i++) { d=$i-mean; ss+=d*d }
    sd=(n>1)?sqrt(ss/(n-1)):0;
    printf "%.1f %.1f", mean, sd
  }' <<< "$*"
}

scores_1=()
scores_112=()

for i in $(seq 1 "${RUNS}"); do
  echo ">> Run ${i}/${RUNS}: UnixBench (1 instance) ..."
  LOG1="${RESULTS_DIR}/unixbench-1inst-${KVER}-${STAMP}-run${i}.log"
  ./Run -c 1 2>&1 | tee "${LOG1}"
  s1="$(grep 'System Benchmarks Index Score' "${LOG1}" | tail -1 | awk '{print $NF}')"
  scores_1+=("${s1}")

  echo ">> Run ${i}/${RUNS}: UnixBench (${COPIES_HIGH} instances) ..."
  LOG112="${RESULTS_DIR}/unixbench-${COPIES_HIGH}inst-${KVER}-${STAMP}-run${i}.log"
  ./Run -c "${COPIES_HIGH}" 2>&1 | tee "${LOG112}"
  s112="$(grep 'System Benchmarks Index Score' "${LOG112}" | tail -1 | awk '{print $NF}')"
  scores_112+=("${s112}")
done

read -r MEAN_1 SD_1 <<< "$(stats "${scores_1[@]}")"
read -r MEAN_112 SD_112 <<< "$(stats "${scores_112[@]}")"

# Print summary block (copy-paste this)
echo
echo "================ RESULTS (UnixBench, ${RUNS} runs) ================"
echo "Kernel version            : ${KVER}"
echo "1 instance   runs         : ${scores_1[*]}"
echo "1 instance   mean ± stddev: ${MEAN_1} ± ${SD_1}"
echo "${COPIES_HIGH} instances runs        : ${scores_112[*]}"
echo "${COPIES_HIGH} instances mean ± stddev: ${MEAN_112} ± ${SD_112}"
echo "=================================================================="
