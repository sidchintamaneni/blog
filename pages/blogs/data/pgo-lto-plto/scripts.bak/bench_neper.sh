#!/usr/bin/env bash
set -euo pipefail

# Benchmark: neper (tcp_rr latency + tcp_stream throughput)
# Performance-testing config per the LLVM AutoFDO RFC: 1 flow, 1 thread.
#
# MODE:
#   loopback : run server + client on this host over 127.0.0.1 (no 2nd machine)
#   server   : run only the server side (start this first on the server host)
#   client   : run only the client side against HOST (run on the client host)

MODE="${MODE:-loopback}"               # loopback | server | client
NEPER_DIR="${NEPER_DIR:-/home/azure/sid/CBL-Mariner-Linux-Kernel/bench/neper}"
RESULTS_DIR="${RESULTS_DIR:-${HOME}/neper-results}"
HOST="${HOST:-127.0.0.1}"              # client connects here (server IP)
FLOWS="${FLOWS:-1}"
THREADS="${THREADS:-1}"
LENGTH="${LENGTH:-60}"
RUNS="${RUNS:-3}"                      # repetitions for loopback statistics

for b in tcp_rr tcp_stream; do
  [[ -x "${NEPER_DIR}/${b}" ]] || { echo "missing neper binary: ${NEPER_DIR}/${b}"; exit 1; }
done

KVER="$(uname -r)"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "${RESULTS_DIR}"
LOG="${RESULTS_DIR}/neper-${MODE}-${KVER}-${STAMP}.log"

server_only() {
  local bench="$1"
  echo ">> [server] neper ${bench} (F=${FLOWS} T=${THREADS} l=${LENGTH}s)" | tee -a "${LOG}"
  "${NEPER_DIR}/${bench}" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" 2>&1 | tee -a "${LOG}"
  echo | tee -a "${LOG}"
}

client_only() {
  local bench="$1"
  echo ">> [client] neper ${bench} -> ${HOST} (F=${FLOWS} T=${THREADS} l=${LENGTH}s)" | tee -a "${LOG}"
  "${NEPER_DIR}/${bench}" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" -c -H "${HOST}" 2>&1 | tee -a "${LOG}"
  echo | tee -a "${LOG}"
}

loopback() {
  local bench="$1"
  echo "================================================================" | tee -a "${LOG}"
  echo ">> neper ${bench} (F=${FLOWS} T=${THREADS} l=${LENGTH}s, loopback)" | tee -a "${LOG}"
  echo "================================================================" | tee -a "${LOG}"
  "${NEPER_DIR}/${bench}" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" >/dev/null 2>&1 &
  local server_pid=$!
  sleep 2
  "${NEPER_DIR}/${bench}" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" -c -H "${HOST}" 2>&1 | tee -a "${LOG}"
  wait "${server_pid}" 2>/dev/null || true
  echo | tee -a "${LOG}"
}

# mean + sample stddev of the numbers passed as args
stats() {
  awk '{
    n=NF; sum=0;
    for (i=1;i<=n;i++) sum+=$i;
    mean=sum/n;
    ss=0;
    for (i=1;i<=n;i++) { d=$i-mean; ss+=d*d }
    sd=(n>1)?sqrt(ss/(n-1)):0;
    printf "%.3f %.3f", mean, sd
  }' <<< "$*"
}

# run one loopback test, append raw output to LOG, echo full client output
loopback_capture() {
  local bench="$1"
  "${NEPER_DIR}/${bench}" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" >/dev/null 2>&1 &
  local srv=$!
  sleep 2
  local out
  out="$("${NEPER_DIR}/${bench}" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" -c -H "${HOST}" 2>/dev/null)"
  wait "${srv}" 2>/dev/null || true
  echo "${out}"
}

# run one client-only test (server must already be listening on HOST), echo output
client_capture() {
  local bench="$1"
  sleep 2   # give the server listener a moment to come up
  "${NEPER_DIR}/${bench}" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" -c -H "${HOST}" 2>/dev/null
}

# RUNS-iteration collector. $1 = capture function (loopback_capture | client_capture)
collect_multi() {
  local cap="$1"
  local rr_tx=() rr_tp=() rr_lat=() rr_lmin=() rr_lmax=() rr_lstd=() rr_smp=()
  local st_tp=() st_smp=()
  for i in $(seq 1 "${RUNS}"); do
    echo "================ ${MODE} run ${i}/${RUNS} ================" | tee -a "${LOG}"

    echo ">> tcp_rr" | tee -a "${LOG}"
    local out_rr; out_rr="$("${cap}" tcp_rr)"
    echo "${out_rr}" >> "${LOG}"
    rr_tx+=("$(awk -F= '/^num_transactions=/{print $2}' <<< "${out_rr}")")
    rr_tp+=("$(awk -F= '/^throughput=/{print $2}' <<< "${out_rr}")")
    rr_lat+=("$(awk -F= '/^latency_mean=/{printf "%.3f", $2*1e6}' <<< "${out_rr}")")
    rr_lmin+=("$(awk -F= '/^latency_min=/{printf "%.3f", $2*1e6}' <<< "${out_rr}")")
    rr_lmax+=("$(awk -F= '/^latency_max=/{printf "%.3f", $2*1e6}' <<< "${out_rr}")")
    rr_lstd+=("$(awk -F= '/^latency_stddev=/{printf "%.3f", $2*1e6}' <<< "${out_rr}")")
    rr_smp+=("$(awk -F= '/^num_samples=/{print $2}' <<< "${out_rr}")")

    echo ">> tcp_stream" | tee -a "${LOG}"
    local out_st; out_st="$("${cap}" tcp_stream)"
    echo "${out_st}" >> "${LOG}"
    local stp; stp="$(awk -F= '/^throughput=/{print $2}' <<< "${out_st}")"
    [[ -z "${stp}" ]] && stp="$(awk -F= '/^remote_throughput=/{printf "%.2f", $2/1e6}' <<< "${out_st}")"
    st_tp+=("${stp}")
    st_smp+=("$(awk -F= '/^num_samples=/{print $2}' <<< "${out_st}")")
  done

  read -r RR_TX_MEAN  RR_TX_SD  <<< "$(stats "${rr_tx[@]}")"
  read -r RR_TP_MEAN  RR_TP_SD  <<< "$(stats "${rr_tp[@]}")"
  read -r RR_LAT_MEAN RR_LAT_SD <<< "$(stats "${rr_lat[@]}")"
  read -r RR_LMIN_MEAN RR_LMIN_SD <<< "$(stats "${rr_lmin[@]}")"
  read -r RR_LMAX_MEAN RR_LMAX_SD <<< "$(stats "${rr_lmax[@]}")"
  read -r RR_LSTD_MEAN RR_LSTD_SD <<< "$(stats "${rr_lstd[@]}")"
  read -r ST_TP_MEAN  ST_TP_SD  <<< "$(stats "${st_tp[@]}")"

  echo | tee -a "${LOG}"
  echo "================ RESULTS (neper ${MODE}, ${RUNS} runs) ================" | tee -a "${LOG}"
  echo "Kernel version            : ${KVER}" | tee -a "${LOG}"
  echo "--- tcp_rr ---" | tee -a "${LOG}"
  echo "transactions  runs        : ${rr_tx[*]}" | tee -a "${LOG}"
  echo "transactions  mean±sd     : ${RR_TX_MEAN} ± ${RR_TX_SD}" | tee -a "${LOG}"
  echo "throughput    runs (tx/s) : ${rr_tp[*]}" | tee -a "${LOG}"
  echo "throughput    mean±sd     : ${RR_TP_MEAN} ± ${RR_TP_SD} tx/s" | tee -a "${LOG}"
  echo "latency_mean  runs (µs)   : ${rr_lat[*]}" | tee -a "${LOG}"
  echo "latency_mean  mean±sd     : ${RR_LAT_MEAN} ± ${RR_LAT_SD} µs" | tee -a "${LOG}"
  echo "latency_min   runs (µs)   : ${rr_lmin[*]}" | tee -a "${LOG}"
  echo "latency_min   mean±sd     : ${RR_LMIN_MEAN} ± ${RR_LMIN_SD} µs" | tee -a "${LOG}"
  echo "latency_max   runs (µs)   : ${rr_lmax[*]}" | tee -a "${LOG}"
  echo "latency_max   mean±sd     : ${RR_LMAX_MEAN} ± ${RR_LMAX_SD} µs" | tee -a "${LOG}"
  echo "latency_stddev runs (µs)  : ${rr_lstd[*]}" | tee -a "${LOG}"
  echo "latency_stddev mean±sd    : ${RR_LSTD_MEAN} ± ${RR_LSTD_SD} µs" | tee -a "${LOG}"
  echo "samples       runs        : ${rr_smp[*]}" | tee -a "${LOG}"
  echo "--- tcp_stream ---" | tee -a "${LOG}"
  echo "throughput    runs (Mb/s) : ${st_tp[*]}" | tee -a "${LOG}"
  echo "throughput    mean±sd     : ${ST_TP_MEAN} ± ${ST_TP_SD} Mbit/s" | tee -a "${LOG}"
  echo "samples       runs        : ${st_smp[*]}" | tee -a "${LOG}"
  echo "=======================================================================" | tee -a "${LOG}"
}

# server side for RUNS iterations (each: tcp_rr then tcp_stream listener)
server_multi() {
  echo "Server mode: ${RUNS} runs. Start the client now (it drives each test)." | tee -a "${LOG}"
  for i in $(seq 1 "${RUNS}"); do
    echo "================ server run ${i}/${RUNS} ================" | tee -a "${LOG}"
    echo ">> [server] tcp_rr" | tee -a "${LOG}"
    "${NEPER_DIR}/tcp_rr" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" 2>&1 | tee -a "${LOG}"
    echo ">> [server] tcp_stream" | tee -a "${LOG}"
    "${NEPER_DIR}/tcp_stream" -F "${FLOWS}" -T "${THREADS}" -l "${LENGTH}" 2>&1 | tee -a "${LOG}"
  done
}

case "${MODE}" in
  loopback)
    collect_multi loopback_capture
    ;;
  server)
    server_multi
    ;;
  client)
    collect_multi client_capture
    ;;
  *)
    echo "Unknown MODE='${MODE}' (use loopback | server | client)"; exit 1
    ;;
esac

echo
echo "Full log: ${LOG}"
echo "(paste the client-side output for tcp_rr / tcp_stream so the tables can be filled)"
