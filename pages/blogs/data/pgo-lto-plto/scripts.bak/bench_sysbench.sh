#!/usr/bin/env bash
set -euo pipefail

# Benchmark: sysbench (cpu, memory, threads, mutex), repeated for statistics.
# Run this on the kernel-under-test. No perf — this is performance measurement.

THREADS="${THREADS:-$(nproc)}"
CPU_MAX_PRIME="${CPU_MAX_PRIME:-20000}"
MEM_TOTAL="${MEM_TOTAL:-100G}"
MEM_BLOCK="${MEM_BLOCK:-1M}"
RUN_TIME="${RUN_TIME:-60}"
RUNS="${RUNS:-3}"
RESULTS_DIR="${RESULTS_DIR:-/home/azure/sid/CBL-Mariner-Linux-Kernel/bench/results}"

# sysbench binary (override with SYSBENCH=/path/to/sysbench)
SYSBENCH="${SYSBENCH:-/home/azure/sid/CBL-Mariner-Linux-Kernel/bench/sysbench/src/sysbench}"
[[ -x "${SYSBENCH}" ]] || { echo "sysbench not found at ${SYSBENCH} (set SYSBENCH=/path/to/sysbench)"; exit 1; }

KVER="$(uname -r)"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "${RESULTS_DIR}"
LOG="${RESULTS_DIR}/sysbench-${KVER}-${STAMP}.log"

# mean + sample stddev of the numbers passed as args
stats() {
  awk '{
    n=NF; sum=0;
    for (i=1;i<=n;i++) sum+=$i;
    mean=sum/n;
    ss=0;
    for (i=1;i<=n;i++) { d=$i-mean; ss+=d*d }
    sd=(n>1)?sqrt(ss/(n-1)):0;
    printf "%.2f %.2f", mean, sd
  }' <<< "$*"
}

# run a sysbench test once and echo its "events per second" value
run_eps() {
  "${SYSBENCH}" "$@" run 2>&1 | tee -a "${LOG}" | awk '/events per second:/{print $4; exit} /eps\):/{print $NF}'
}

cpu_eps=()
mem_eps=()
thr_eps=()
mtx_eps=()

for i in $(seq 1 "${RUNS}"); do
  echo "================ sysbench run ${i}/${RUNS} ================" | tee -a "${LOG}"

  echo ">> cpu" | tee -a "${LOG}"
  cpu_eps+=("$("${SYSBENCH}" cpu --threads="${THREADS}" --cpu-max-prime="${CPU_MAX_PRIME}" --time="${RUN_TIME}" run 2>&1 | tee -a "${LOG}" | awk '/events per second:/{print $4; exit}')")

  echo ">> memory" | tee -a "${LOG}"
  mem_eps+=("$("${SYSBENCH}" memory --threads="${THREADS}" --memory-total-size="${MEM_TOTAL}" --memory-block-size="${MEM_BLOCK}" --time="${RUN_TIME}" run 2>&1 | tee -a "${LOG}" | awk '/MiB transferred/{gsub(/\(/,""); print $3; exit}')")

  echo ">> threads" | tee -a "${LOG}"
  thr_eps+=("$("${SYSBENCH}" threads --threads="${THREADS}" --thread-yields=1001 --thread-locks=8 --time="${RUN_TIME}" run 2>&1 | tee -a "${LOG}" | awk '/eps\):/{print $NF; exit}')")

  echo ">> mutex" | tee -a "${LOG}"
  mtx_eps+=("$("${SYSBENCH}" mutex --threads="${THREADS}" --mutex-num=4097 --mutex-locks=50000 --mutex-loops=10000 run 2>&1 | tee -a "${LOG}" | awk '/eps\):/{print $NF; exit}')")
done

read -r CPU_MEAN CPU_SD <<< "$(stats "${cpu_eps[@]}")"
read -r MEM_MEAN MEM_SD <<< "$(stats "${mem_eps[@]}")"
read -r THR_MEAN THR_SD <<< "$(stats "${thr_eps[@]}")"
read -r MTX_MEAN MTX_SD <<< "$(stats "${mtx_eps[@]}")"

echo
echo "================ RESULTS (sysbench, ${RUNS} runs) ================"
echo "Kernel version           : ${KVER}"
echo "Threads                  : ${THREADS}"
echo "CPU events/sec   runs    : ${cpu_eps[*]}"
echo "CPU events/sec   mean±sd : ${CPU_MEAN} ± ${CPU_SD}"
echo "Memory MiB/s     runs    : ${mem_eps[*]}"
echo "Memory MiB/s     mean±sd : ${MEM_MEAN} ± ${MEM_SD}"
echo "Threads eps      runs    : ${thr_eps[*]}"
echo "Threads eps      mean±sd : ${THR_MEAN} ± ${THR_SD}"
echo "Mutex eps        runs    : ${mtx_eps[*]}"
echo "Mutex eps        mean±sd : ${MTX_MEAN} ± ${MTX_SD}"
echo "Full log                 : ${LOG}"
echo "================================================================="
