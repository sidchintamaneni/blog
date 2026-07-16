# PGO, LTO & PLTO Experiments Part 2: Linux Kernel

**Machine:** Azure Linux 3.0, Intel Xeon Platinum 8473C (208 CPUs, 128 GB RAM)

**Kernel Version:** 6.18.26.1-1.azl3
**Grub Version:** RHEL 2.06 (had to replace it because azl grub's oom issues)

**Clang Version:** 22.1.2 (`llvmorg-22.1.2`) — O3+ThinLTO+AutoFDO+Propeller build from Part 1

**GCC Version:** 13.2.0 (system)

---

## Results Summary

| Metric               | GCC (baseline) | Clang (no LTO) | Clang-AutoFDO-Propeller (no LTO) | Clang-AutoFDO-Propeller (ThinLTO) | Clang-AutoFDO-Propeller (FullLTO) |
|----------------------|----------------|----------------|----------------------------------|-----------------------------------|-----------------------------------|
| Built with           | gcc 13.2.0     | O2-clang       | AutoFDO+Propeller                | AutoFDO+Propeller                 | AutoFDO+Propeller                 |
| Build time (wall)    | 2m 51s         | 2m 10s         | 1m 56s                           | 4m 2s                             | 10m 51s                           |
| vmlinux size         | 425M           | 356M           | 356M                             | 524M                              | 345M                              |
| .text                | 20,450,840     | 20,825,304     | 20,825,304                       | 21,197,016                        | 26,262,104                        |
| .rodata              | 7,909,766      | 7,840,517      | 7,840,517                        | 8,075,957                         | 8,116,453                         |
| Function count (T+t) | 164,721        | 231,698        | 231,698                          | 233,782                           | 232,489                           |

---

## Kernel AutoFDO & Propeller Results

| Metric               | ThinLTO + AutoFDO (no profile) | ThinLTO + AutoFDO (profile) | ThinLTO + AutoFDO + Propeller |
|----------------------|--------------------------------|-----------------------------|-------------------------------|
| Build time (wall)    | 4m 4s                          | 5m 4s                       | 5m 2s                         |
| vmlinux size         | 531M                           | 544M                        | 544M                          |
| .text                | 21,385,432                     | 21,636,632                  | 21,661,720                    |
| .rodata              | 8,063,189                      | 8,052,981                   | 8,106,197                     |
| Function count (T+t) | 232,497                        | 230,140                     | 231,739                       |


---

## Benchmark Results

Measured on the kernel-under-test (no `perf` running). UnixBench, sysbench, and neper. Higher is better unless noted.

> Noise control: before each run, fix the CPU frequency and disable deep C-states.
>
> ```bash
> sudo cpupower frequency-set -g performance   # fix machine frequency
> sudo cpupower idle-set -D 0                  # keep C0, disable deeper C-states
> ```

**How these were collected** (run on the booted kernel-under-test):

- **UnixBench** — [`scripts/bench_unixbench.sh`](scripts/bench_unixbench.sh): runs the index at 1 instance and 112 instances.
- **sysbench** — [`scripts/bench_sysbench.sh`](scripts/bench_sysbench.sh): cpu, memory, threads, and mutex tests (208 threads, 60s each). Needs a local sysbench build (`./configure --without-mysql && make`).
- **neper** — [`scripts/bench_neper.sh`](scripts/bench_neper.sh): tcp_rr (latency) and tcp_stream (throughput) at 1 flow / 1 thread (RFC performance-test config). Supports `MODE=loopback` (single host) or two-machine `MODE=server` / `MODE=client HOST=<server-ip>`.

### UnixBench — Index Score

> Note: with the `performance` governor + disabled deep C-states, single-core **turbo is suppressed**, so 1-instance scores are lower than an unpinned run but far more reproducible. 1-instance and 112-instance are pinned 3-run means where shown.

| Kernel variant                | 1 instance | 112 instances |
|-------------------------------|------------|---------------|
| Clang (no LTO)                | 1,709.4 ± 4.8 (3 runs) | 64,053.8 ± 143.8 (3 runs) | (Redo this at the end)
| Clang ThinLTO                 | 1,672.2 ± 5.1 (3 runs) | 64,137.2 ± 151.4 (3 runs) |
| ThinLTO + AutoFDO (profile)   | 1,840.7 ± 7.3 (3 runs) | 68,133.4 ± 268.4 (3 runs) |
| ThinLTO + AutoFDO + Propeller | 1,848.4 ± 2.5 (3 runs) | 68,309.6 ± 133.2 (3 runs) |

### UnixBench 112-instance — raw 3 runs (Clang no LTO, pinned)

Index values per run.

| Test                                  | Run 1     | Run 2     | Run 3     |
|---------------------------------------|-----------|-----------|-----------|
| Dhrystone 2 using register variables  | 369,489.8 | 368,983.6 | 369,852.2 |
| Double-Precision Whetstone            | 132,779.1 | 132,739.7 | 132,781.4 |
| Execl Throughput                      | 5,527.1   | 5,526.2   | 5,461.2   |
| File Copy 1024 bufsize 2000 maxblocks | 191,590.6 | 201,935.5 | 198,706.1 |
| File Copy 256 bufsize 500 maxblocks   | 204,405.1 | 206,159.4 | 205,409.9 |
| File Copy 4096 bufsize 8000 maxblocks | 75,996.0  | 75,467.0  | 75,934.1  |
| Pipe Throughput                       | 184,136.2 | 184,384.3 | 184,225.0 |
| Pipe-based Context Switching          | 35,611.3  | 35,583.9  | 35,582.6  |
| Process Creation                      | 9,722.6   | 9,730.0   | 9,754.3   |
| Shell Scripts (1 concurrent)          | 29,169.7  | 29,241.5  | 29,239.3  |
| Shell Scripts (8 concurrent)          | 25,942.2  | 25,894.9  | 25,925.1  |
| System Call Overhead                  | 119,030.8 | 118,922.0 | 118,909.8 |
| **System Benchmarks Index Score**     | **63,899.8** | **64,184.7** | **64,076.8** |

### UnixBench 1-instance — raw 3 runs (Clang no LTO, pinned)

Index values per run.

| Test                                  | Run 1     | Run 2     | Run 3     |
|---------------------------------------|-----------|-----------|-----------|
| Dhrystone 2 using register variables  | 3,379.8   | 3,379.0   | 3,376.7   |
| Double-Precision Whetstone            | 1,191.2   | 1,192.6   | 1,191.4   |
| Execl Throughput                      | 783.9     | 777.9     | 777.3     |
| File Copy 1024 bufsize 2000 maxblocks | 3,086.5   | 3,060.0   | 3,066.5   |
| File Copy 256 bufsize 500 maxblocks   | 2,019.8   | 2,020.3   | 2,026.7   |
| File Copy 4096 bufsize 8000 maxblocks | 6,292.1   | 6,185.1   | 6,171.6   |
| Pipe Throughput                       | 1,706.5   | 1,677.0   | 1,695.5   |
| Pipe-based Context Switching          | 444.4     | 439.8     | 443.1     |
| Process Creation                      | 488.6     | 487.4     | 479.9     |
| Shell Scripts (1 concurrent)          | 1,526.2   | 1,526.7   | 1,526.5   |
| Shell Scripts (8 concurrent)          | 8,525.2   | 8,530.3   | 8,522.0   |
| System Call Overhead                  | 1,085.1   | 1,086.6   | 1,086.5   |
| **System Benchmarks Index Score**     | **1,715.0** | **1,706.5** | **1,706.8** |

### UnixBench 112-instance — raw 3 runs (Clang ThinLTO, pinned)

Index values per run.

| Test                                  | Run 1     | Run 2     | Run 3     |
|---------------------------------------|-----------|-----------|-----------|
| Dhrystone 2 using register variables  | 369,242.7 | 369,328.4 | 369,136.5 |
| Double-Precision Whetstone            | 132,758.9 | 132,764.9 | 132,761.7 |
| Execl Throughput                      | 5,724.9   | 5,647.6   | 5,641.5   |
| File Copy 1024 bufsize 2000 maxblocks | 198,954.9 | 188,405.3 | 194,037.9 |
| File Copy 256 bufsize 500 maxblocks   | 196,844.7 | 196,065.3 | 196,474.7 |
| File Copy 4096 bufsize 8000 maxblocks | 74,244.4  | 74,858.9  | 76,423.6  |
| Pipe Throughput                       | 182,026.8 | 182,091.7 | 182,137.0 |
| Pipe-based Context Switching          | 35,316.0  | 35,279.5  | 35,262.6  |
| Process Creation                      | 10,059.6  | 10,099.4  | 10,033.4  |
| Shell Scripts (1 concurrent)          | 30,116.3  | 30,228.2  | 30,074.0  |
| Shell Scripts (8 concurrent)          | 26,460.0  | 26,518.5  | 26,512.0  |
| System Call Overhead                  | 118,045.2 | 117,925.2 | 117,891.0 |
| **System Benchmarks Index Score**     | **64,266.5** | **63,970.7** | **64,174.5** |

### UnixBench 1-instance — raw 3 runs (Clang ThinLTO, pinned)

Index values per run.

| Test                                  | Run 1     | Run 2     | Run 3     |
|---------------------------------------|-----------|-----------|-----------|
| Dhrystone 2 using register variables  | 3,340.9   | 3,380.6   | 3,382.1   |
| Double-Precision Whetstone            | 1,192.9   | 1,192.9   | 1,193.5   |
| Execl Throughput                      | 782.8     | 783.4     | 779.0     |
| File Copy 1024 bufsize 2000 maxblocks | 2,857.5   | 2,829.9   | 2,789.7   |
| File Copy 256 bufsize 500 maxblocks   | 1,913.7   | 1,905.3   | 1,920.1   |
| File Copy 4096 bufsize 8000 maxblocks | 5,777.3   | 5,724.3   | 5,893.3   |
| Pipe Throughput                       | 1,688.9   | 1,692.5   | 1,685.9   |
| Pipe-based Context Switching          | 421.1     | 449.2     | 414.6     |
| Process Creation                      | 488.1     | 484.8     | 484.5     |
| Shell Scripts (1 concurrent)          | 1,517.5   | 1,516.1   | 1,513.6   |
| Shell Scripts (8 concurrent)          | 8,437.8   | 8,455.1   | 8,434.8   |
| System Call Overhead                  | 1,081.5   | 1,080.6   | 1,080.1   |
| **System Benchmarks Index Score**     | **1,670.9** | **1,677.9** | **1,667.9** |

### UnixBench 112-instance — raw 3 runs (ThinLTO + AutoFDO profile, pinned)

Index values per run.

| Test                                  | Run 1     | Run 2     | Run 3     |
|---------------------------------------|-----------|-----------|-----------|
| Dhrystone 2 using register variables  | 369,741.1 | 369,402.9 | 369,237.3 |
| Double-Precision Whetstone            | 132,807.8 | 132,801.6 | 132,823.7 |
| Execl Throughput                      | 5,714.2   | 5,676.1   | 5,815.1   |
| File Copy 1024 bufsize 2000 maxblocks | 231,483.6 | 217,946.8 | 229,967.5 |
| File Copy 256 bufsize 500 maxblocks   | 244,196.4 | 241,973.2 | 242,747.5 |
| File Copy 4096 bufsize 8000 maxblocks | 77,254.3  | 76,648.7  | 76,753.1  |
| Pipe Throughput                       | 206,832.3 | 206,993.7 | 207,040.6 |
| Pipe-based Context Switching          | 41,669.2  | 41,719.9  | 41,719.0  |
| Process Creation                      | 9,702.8   | 9,662.7   | 9,702.2   |
| Shell Scripts (1 concurrent)          | 30,462.8  | 30,505.2  | 30,504.9  |
| Shell Scripts (8 concurrent)          | 26,920.3  | 26,986.5  | 26,844.7  |
| System Call Overhead                  | 122,503.4 | 122,538.7 | 122,514.6 |
| **System Benchmarks Index Score**     | **68,294.0** | **67,823.6** | **68,282.7** |

### UnixBench 1-instance — raw 3 runs (ThinLTO + AutoFDO profile, pinned)

Index values per run.

| Test                                  | Run 1     | Run 2     | Run 3     |
|---------------------------------------|-----------|-----------|-----------|
| Dhrystone 2 using register variables  | 3,378.2   | 3,384.6   | 3,354.1   |
| Double-Precision Whetstone            | 1,192.9   | 1,193.1   | 1,192.9   |
| Execl Throughput                      | 830.0     | 831.6     | 829.8     |
| File Copy 1024 bufsize 2000 maxblocks | 3,541.7   | 3,542.4   | 3,551.2   |
| File Copy 256 bufsize 500 maxblocks   | 2,402.7   | 2,394.3   | 2,396.6   |
| File Copy 4096 bufsize 8000 maxblocks | 6,842.3   | 6,826.8   | 6,717.6   |
| Pipe Throughput                       | 1,892.2   | 1,893.2   | 1,886.4   |
| Pipe-based Context Switching          | 522.3     | 521.7     | 495.1     |
| Process Creation                      | 508.1     | 503.2     | 504.4     |
| Shell Scripts (1 concurrent)          | 1,602.4   | 1,602.7   | 1,604.4   |
| Shell Scripts (8 concurrent)          | 8,909.1   | 8,931.1   | 8,920.2   |
| System Call Overhead                  | 1,118.1   | 1,118.3   | 1,118.6   |
| **System Benchmarks Index Score**     | **1,845.6** | **1,844.1** | **1,832.3** |

### UnixBench 112-instance — raw 3 runs (ThinLTO + AutoFDO + Propeller, pinned)

Index values per run.

| Test                                  | Run 1     | Run 2     | Run 3     |
|---------------------------------------|-----------|-----------|-----------|
| Dhrystone 2 using register variables  | 366,896.4 | 367,355.4 | 367,957.8 |
| Double-Precision Whetstone            | 132,791.9 | 132,821.4 | 132,802.7 |
| Execl Throughput                      | 5,671.1   | 5,686.6   | 5,662.5   |
| File Copy 1024 bufsize 2000 maxblocks | 232,537.6 | 220,318.2 | 227,424.8 |
| File Copy 256 bufsize 500 maxblocks   | 250,948.5 | 251,148.0 | 251,300.2 |
| File Copy 4096 bufsize 8000 maxblocks | 75,978.2  | 75,667.2  | 76,056.7  |
| Pipe Throughput                       | 208,750.7 | 208,509.7 | 208,736.1 |
| Pipe-based Context Switching          | 41,583.3  | 41,680.9  | 41,608.1  |
| Process Creation                      | 9,724.2   | 9,743.6   | 9,961.9   |
| Shell Scripts (1 concurrent)          | 30,090.8  | 30,437.0  | 30,250.5  |
| Shell Scripts (8 concurrent)          | 27,111.1  | 27,239.7  | 27,107.2  |
| System Call Overhead                  | 123,271.1 | 123,283.3 | 123,263.3 |
| **System Benchmarks Index Score**     | **68,351.7** | **68,160.4** | **68,416.7** |

### UnixBench 1-instance — raw 3 runs (ThinLTO + AutoFDO + Propeller, pinned)

Index values per run.

| Test                                  | Run 1     | Run 2     | Run 3     |
|---------------------------------------|-----------|-----------|-----------|
| Dhrystone 2 using register variables  | 3,364.2   | 3,363.4   | 3,349.2   |
| Double-Precision Whetstone            | 1,192.8   | 1,189.3   | 1,193.2   |
| Execl Throughput                      | 833.5     | 834.6     | 834.2     |
| File Copy 1024 bufsize 2000 maxblocks | 3,579.7   | 3,596.3   | 3,589.7   |
| File Copy 256 bufsize 500 maxblocks   | 2,440.4   | 2,436.5   | 2,440.6   |
| File Copy 4096 bufsize 8000 maxblocks | 6,853.7   | 6,789.7   | 6,883.8   |
| Pipe Throughput                       | 1,915.3   | 1,928.8   | 1,926.5   |
| Pipe-based Context Switching          | 510.0     | 521.7     | 520.2     |
| Process Creation                      | 500.9     | 503.9     | 501.7     |
| Shell Scripts (1 concurrent)          | 1,597.7   | 1,598.2   | 1,595.7   |
| Shell Scripts (8 concurrent)          | 8,846.4   | 8,843.2   | 8,846.0   |
| System Call Overhead                  | 1,127.3   | 1,126.3   | 1,126.5   |
| **System Benchmarks Index Score**     | **1,845.5** | **1,849.6** | **1,850.0** |

### perf stat — front-end counters (UnixBench 112-instance, system-wide)

Collected with [`scripts/perfstat_heatmap_112.sh`](scripts/perfstat_heatmap_112.sh) (`perf stat -a`, 3-run means over `./Run -c 112`). Same metrics as Part 1. Propeller is a layout-only optimisation (basic-block reorder + function placement), so its payoff is in the **front end** (instruction fetch — i-cache and iTLB), which the icache/iTLB miss rows surface directly.

> Caveat: these are **system-wide** counts with deep C-states disabled (`idle-set -D 0`). Both kernels are measured identically, so the **deltas** are what count — lower L1-icache / iTLB misses on the Propeller kernel = the layout win.

| Metric               | Clang (no LTO) 112-inst | AutoFDO 112-inst | Propeller 112-inst |
|----------------------|-------------------------|------------------|--------------------|
| Instructions (T)     | TBD                     | TBD              | TBD                |
| Cycles (T)           | TBD                     | TBD              | TBD                |
| IPC                  | TBD                     | TBD              | TBD                |
| L1-icache misses (T) | TBD                     | TBD              | TBD                |
| iTLB misses (B)      | TBD                     | TBD              | TBD                |

**Instruction-access heatmap** (temporal IP-offset density during `./Run -c 112`, same idea as Part 1 — tighter bright band = hot code packed closer):

<div style="display: flex; justify-content: center;">
<table style="margin: 0 auto;"><tr>
<td><img src="/pages/blogs/data/pgo-lto-plto/heatmaps/temporal-kernel-Clang-112.png" width="320"></td>
<td><img src="/pages/blogs/data/pgo-lto-plto/heatmaps/temporal-kernel-AutoFDO-112.png" width="320"></td>
<td><img src="/pages/blogs/data/pgo-lto-plto/heatmaps/temporal-kernel-Propeller-112.png" width="320"></td>
</tr></table>
</div>

### sysbench — summary (208 threads, 60s)

| Kernel variant                 | CPU (eps) | Memory (MiB/s) | Threads (eps) | Mutex (eps) |
|--------------------------------|-----------|----------------|---------------|-------------|
| Clang (no LTO)                 | 98,107.3 ± 2,504.3 | 29,194.3 ± 2,231.0 | 5,999.9 ± 229.5 | 146.5 ± 17.7 |
| Clang ThinLTO                  | 97,829.7 ± 3,122.6 | 30,767.8 ± 2,726.1 | 6,303.6 ± 177.5 | 153.8 ± 15.6 |
| ThinLTO + AutoFDO (profile)    | 98,168.3 ± 3,394.5 | 29,450.8 ± 1,274.4 | 6,583.1 ± 49.9 | 145.1 ± 16.1 |
| ThinLTO + AutoFDO + Propeller  | 97,450.9 ± 4,374.3 | 30,618.7 ± 1,775.7 | 6,746.6 ± 136.6 | 141.8 ± 7.0 |

### sysbench — raw (Clang no LTO, pinned) — Run 1

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 100,861.91 | 6,052,009  | 60.00    | 1.07         | 2.06         | 22.02        | 2.03          | 12,474,545.59 | 29,096.1971 / 1,915.04       | 59.9738 / 0.02                   |
| memory | 29,028.66  | 102,336    | 3.53     | 0.07         | 6.09         | 45.12        | 12.98         | 623,221.08    | 492.0000 / 0.00              | 2.9963 / 0.36                    |
| threads| 5,917.30   | 355,805    | 60.13    | 0.28         | 35.12        | 340.10       | 272.27        | 12,497,518.42 | 1,710.6010 / 113.31          | 60.0842 / 0.04                   |
| mutex  | 143.33     | 208        | 1.45     | 1,227.91     | 1,356.98     | 1,445.13     | 1,401.61      | 282,252.72    | 1.0000 / 0.00                | 1.3570 / 0.04                    |

### sysbench — raw (Clang no LTO, pinned) — Run 2

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 95,968.22  | 5,758,345  | 60.00    | 1.07         | 2.17         | 30.04        | 5.00          | 12,466,825.82 | 27,684.3510 / 4,126.92       | 59.9367 / 0.07                   |
| memory | 27,050.80  | 102,336    | 3.78     | 0.07         | 6.14         | 501.37       | 15.00         | 628,699.05    | 492.0000 / 0.00              | 3.0226 / 0.53                    |
| threads| 6,259.29   | 376,262    | 60.11    | 0.28         | 33.21        | 323.04       | 257.95        | 12,495,173.51 | 1,808.9519 / 106.23          | 60.0729 / 0.03                   |
| mutex  | 165.55     | 208        | 1.26     | 1,005.91     | 1,147.76     | 1,234.38     | 1,213.57      | 238,733.69    | 1.0000 / 0.00                | 1.1478 / 0.04                    |

### sysbench — raw (Clang no LTO, pinned) — Run 3

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 97,491.82  | 5,849,771  | 60.00    | 1.06         | 2.13         | 22.09        | 5.00          | 12,467,478.89 | 28,123.8990 / 4,056.74       | 59.9398 / 0.06                   |
| memory | 31,503.45  | 102,336    | 3.25     | 0.03         | 5.17         | 195.16       | 11.24         | 529,336.19    | 492.0000 / 0.00              | 2.5449 / 0.40                    |
| threads| 5,823.13   | 350,203    | 60.14    | 0.28         | 35.69        | 334.91       | 277.21        | 12,500,450.57 | 1,683.6683 / 107.24          | 60.0983 / 0.04                   |
| mutex  | 130.67     | 208        | 1.59     | 1,237.17     | 1,373.77     | 1,565.36     | 1,506.29      | 285,744.86    | 1.0000 / 0.00                | 1.3738 / 0.07                    |

### sysbench — raw (Clang ThinLTO, pinned) — Run 1

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 101,160.30 | 6,069,906  | 60.00    | 1.06         | 2.06         | 25.02        | 2.03          | 12,475,442.81 | 29,182.2404 / 1,962.29       | 59.9781 / 0.01                   |
| memory | 28,217.57  | 102,336    | 3.63     | 0.03         | 6.31         | 714.02       | 12.52         | 645,802.76    | 492.0000 / 0.00              | 3.1048 / 0.37                    |
| threads| 6,244.20   | 375,374    | 60.12    | 0.27         | 33.29        | 332.63       | 262.64        | 12,495,092.45 | 1,804.6827 / 110.44          | 60.0726 / 0.04                   |
| mutex  | 167.13     | 208        | 1.24     | 1,021.39     | 1,151.17     | 1,219.96     | 1,213.57      | 239,443.95    | 1.0000 / 0.00                | 1.1512 / 0.04                    |

### sysbench — raw (Clang ThinLTO, pinned) — Run 2

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 97,360.57  | 5,841,905  | 60.00    | 1.06         | 2.14         | 27.01        | 5.00          | 12,473,601.08 | 28,086.0817 / 3,353.85       | 59.9692 / 0.03                   |
| memory | 30,444.73  | 102,336    | 3.36     | 0.03         | 5.38         | 551.98       | 13.22         | 550,424.63    | 492.0000 / 0.00              | 2.6463 / 0.43                    |
| threads| 6,503.21   | 390,843    | 60.10    | 0.27         | 31.97        | 315.05       | 253.35        | 12,493,298.19 | 1,879.0529 / 112.59          | 60.0639 / 0.03                   |
| mutex  | 136.61     | 208        | 1.52     | 1,115.78     | 1,333.41     | 1,520.10     | 1,453.01      | 277,348.60    | 1.0000 / 0.00                | 1.3334 / 0.08                    |

### sysbench — raw (Clang ThinLTO, pinned) — Run 3

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 94,968.15  | 5,698,349  | 60.00    | 1.06         | 2.19         | 18.01        | 5.00          | 12,467,376.80 | 27,395.9087 / 3,041.32       | 59.9393 / 0.07                   |
| memory | 33,641.04  | 102,336    | 3.04     | 0.07         | 5.21         | 336.84       | 11.04         | 532,824.09    | 492.0000 / 0.00              | 2.5617 / 0.31                    |
| threads| 6,163.49   | 370,486    | 60.11    | 0.27         | 33.73        | 326.55       | 267.41        | 12,494,939.90 | 1,781.1827 / 102.09          | 60.0718 / 0.03                   |
| mutex  | 157.61     | 208        | 1.32     | 1,129.70     | 1,229.34     | 1,319.58     | 1,280.93      | 255,703.32    | 1.0000 / 0.00                | 1.2293 / 0.04                    |

### sysbench — raw (ThinLTO + AutoFDO profile, pinned) — Run 1

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 101,757.85 | 6,105,749  | 60.00    | 1.07         | 2.04         | 22.03        | 2.03          | 12,476,250.59 | 29,354.5625 / 1,581.46       | 59.9820 / 0.01                   |
| memory | 30,918.11  | 102,336    | 3.31     | 0.03         | 5.97         | 643.84       | 11.24         | 610,476.20    | 492.0000 / 0.00              | 2.9350 / 0.23                    |
| threads| 6,602.90   | 396,853    | 60.10    | 0.24         | 31.48        | 307.98       | 244.38        | 12,493,843.50 | 1,907.9471 / 115.60          | 60.0666 / 0.03                   |
| mutex  | 144.01     | 208        | 1.44     | 1,194.22     | 1,321.12     | 1,444.20     | 1,427.08      | 274,793.97    | 1.0000 / 0.00                | 1.3211 / 0.05                    |

### sysbench — raw (ThinLTO + AutoFDO profile, pinned) — Run 2

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 95,010.18  | 5,700,829  | 60.00    | 1.06         | 2.19         | 18.04        | 5.00          | 12,468,523.98 | 27,407.8317 / 3,841.19       | 59.9448 / 0.06                   |
| memory | 28,620.56  | 102,336    | 3.58     | 0.03         | 5.83         | 402.55       | 12.75         | 596,847.38    | 492.0000 / 0.00              | 2.8695 / 0.49                    |
| threads| 6,526.39   | 392,316    | 60.11    | 0.24         | 31.85        | 302.00       | 253.35        | 12,495,325.62 | 1,886.1346 / 114.96          | 60.0737 / 0.03                   |
| mutex  | 135.62     | 208        | 1.53     | 1,199.35     | 1,354.21     | 1,533.55     | 1,479.41      | 281,676.14    | 1.0000 / 0.00                | 1.3542 / 0.07                    |

### sysbench — raw (ThinLTO + AutoFDO profile, pinned) — Run 3

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 97,736.73  | 5,864,442  | 60.00    | 1.06         | 2.13         | 23.00        | 5.00          | 12,466,734.02 | 28,194.4327 / 3,102.45       | 59.9362 / 0.07                   |
| memory | 28,813.85  | 102,336    | 3.55     | 0.03         | 5.91         | 533.12       | 12.08         | 605,285.20    | 492.0000 / 0.00              | 2.9100 / 0.34                    |
| threads| 6,620.13   | 397,897    | 60.10    | 0.24         | 31.40        | 310.25       | 248.83        | 12,493,899.67 | 1,912.9663 / 102.36          | 60.0668 / 0.03                   |
| mutex  | 155.77     | 208        | 1.34     | 880.92       | 1,090.24     | 1,331.06     | 1,280.93      | 226,769.28    | 1.0000 / 0.00                | 1.0902 / 0.14                    |

### sysbench — raw (ThinLTO + AutoFDO + Propeller, pinned) — Run 1

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 98,741.27  | 5,924,739  | 60.00    | 1.06         | 2.10         | 26.00        | 2.03          | 12,467,274.87 | 28,484.3221 / 2,416.50       | 59.9388 / 0.06                   |
| memory | 29,096.66  | 102,336    | 3.52     | 0.03         | 5.68         | 378.91       | 12.98         | 581,403.95    | 492.0000 / 0.00              | 2.7952 / 0.44                    |
| threads| 6,874.01   | 413,112    | 60.10    | 0.23         | 30.24        | 322.30       | 240.02        | 12,493,086.85 | 1,986.1154 / 106.26          | 60.0629 / 0.03                   |
| mutex  | 149.82     | 208        | 1.39     | 1,087.66     | 1,255.90     | 1,355.80     | 1,327.91      | 261,227.16    | 1.0000 / 0.00                | 1.2559 / 0.05                    |

### sysbench — raw (ThinLTO + AutoFDO + Propeller, pinned) — Run 2

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 101,034.84 | 6,062,316  | 60.00    | 1.07         | 2.06         | 29.02        | 2.03          | 12,472,719.49 | 29,145.7500 / 3,010.12       | 59.9650 / 0.03                   |
| memory | 32,569.51  | 102,336    | 3.14     | 0.03         | 5.27         | 234.49       | 11.45         | 539,793.31    | 492.0000 / 0.00              | 2.5952 / 0.35                    |
| threads| 6,763.35   | 406,422    | 60.09    | 0.23         | 30.74        | 326.43       | 240.02        | 12,492,205.83 | 1,953.9519 / 109.93          | 60.0587 / 0.03                   |
| mutex  | 138.70     | 208        | 1.50     | 1,187.13     | 1,371.95     | 1,499.10     | 1,453.01      | 285,365.98    | 1.0000 / 0.00                | 1.3720 / 0.05                    |

### sysbench — raw (ThinLTO + AutoFDO + Propeller, pinned) — Run 3

| Test   | events/s | total events | time (s) | lat min (ms) | lat avg (ms) | lat max (ms) | lat 95th (ms) | lat sum (ms) | fairness events (avg/stddev) | fairness exec time (avg/stddev) |
|--------|----------|--------------|----------|--------------|--------------|--------------|---------------|--------------|------------------------------|----------------------------------|
| cpu    | 92,576.62  | 5,554,824  | 60.00    | 1.06         | 2.24         | 19.04        | 5.00          | 12,468,330.99 | 26,705.8846 / 4,159.60       | 59.9439 / 0.06                   |
| memory | 30,190.02  | 102,336    | 3.39     | 0.03         | 5.47         | 332.10       | 12.08         | 559,655.08    | 492.0000 / 0.00              | 2.6906 / 0.42                    |
| threads| 6,602.39   | 396,813    | 60.10    | 0.23         | 31.48        | 336.94       | 248.83        | 12,492,995.81 | 1,907.7548 / 111.16          | 60.0625 / 0.03                   |
| mutex  | 136.93     | 208        | 1.52     | 1,230.48     | 1,374.48     | 1,518.47     | 1,479.41      | 285,892.42    | 1.0000 / 0.00                | 1.3745 / 0.05                    |

### neper — tcp_rr (1F/1T, 60s)

> Setup — **loopback**: server + client are the same kernel-under-test over `127.0.0.1`. **two-machine**: server `10.199.8.118` = kernel-under-test (the variant named in the row); client `10.199.8.189` = fixed stock `6.18.26.1-1.npi`.
>
> Data source: **throughput** and **transactions** are reported by both server and client and agree (values below are client-side). **Latency** is client-only (server reports 0) — marked `[client]`.

| Kernel variant | Mode | Transactions | Throughput (tx/s) | Latency mean (µs) [client] | Latency min (µs) [client] | Latency max (µs) [client] | Latency stddev (µs) [client] | Samples |
|----------------|------|--------------|-------------------|----------------------------|---------------------------|---------------------------|------------------------------|---------|
| Clang (no LTO) | loopback (3 runs) | 3,690,482 ± 18,711 | 62,557.1 ± 330.5 | 15.912 ± 0.081 | 14.098 ± 0.744 | 67.304 ± 2.627 | 0.635 ± 0.036 | 60 |
| Clang (no LTO) | two-machine (3 runs) | 2,102,468 ± 54,901 | 35,638.8 ± 976.9 | 28.000 ± 0.736 | 22.326 ± 0.567 | 144.879 ± 5.891 | 3.213 ± 0.525 | 60 |
| Clang ThinLTO | loopback (3 runs) | 3,772,891 ± 121,150 | 63,573.4 ± 2,317.4 | 15.662 ± 0.573 | 13.005 ± 2.222 | 81.342 ± 22.430 | 1.152 ± 0.991 | 60-61 |
| Clang ThinLTO | two-machine (3 runs) | 2,163,165 ± 35,554 | 36,638.5 ± 568.0 | 27.206 ± 0.453 | 21.917 ± 1.162 | 133.380 ± 32.350 | 2.357 ± 0.294 | 60 |
| ThinLTO + AutoFDO (profile) | loopback (3 runs) | 3,993,251 ± 43,547 | 67,299.4 ± 428.8 | 14.784 ± 0.094 | 12.955 ± 0.471 | 58.705 ± 4.772 | 0.519 ± 0.008 | 60-61 |
| ThinLTO + AutoFDO (profile) | two-machine (3 runs) | 2,298,898 ± 102,235 | 38,976.4 ± 1,740.6 | 25.625 ± 1.173 | 20.024 ± 0.906 | 116.769 ± 28.880 | 1.872 ± 0.397 | 60 |
| ThinLTO + AutoFDO + Propeller | loopback (3 runs) | 4,002,505 ± 22,475 | 67,453.8 ± 427.6 | 14.749 ± 0.096 | 13.294 ± 0.738 | 62.980 ± 13.344 | 0.539 ± 0.004 | 60-61 |
| ThinLTO + AutoFDO + Propeller | two-machine (3 runs) | 2,359,105 ± 72,738 | 39,998.3 ± 1,231.0 | 24.952 ± 0.779 | 19.323 ± 0.369 | 116.670 ± 22.797 | 1.990 ± 0.460 | 60 |

### neper — tcp_stream (1F/1T, 60s)

> Data source: client is the writer, server is the reader, so throughput is measured at the **receiver (server in two-machine)** and relayed to the client; both agree. Same server/client setup as tcp_rr above.

| Kernel variant | Mode | Throughput (Mbit/s) | Samples |
|----------------|------|---------------------|---------|
| Clang (no LTO) | loopback (3 runs) | 26,647.6 ± 185.0 | 3 |
| Clang (no LTO) | two-machine (3 runs) | 29,756.4 ± 456.6 | 61 |
| Clang ThinLTO | loopback (3 runs) | 27,049.2 ± 885.3 | 3 |
| Clang ThinLTO | two-machine (3 runs) | 29,312.7 ± 591.6 | 61 |
| ThinLTO + AutoFDO (profile) | loopback (3 runs) | 29,377.2 ± 84.8 | 3 |
| ThinLTO + AutoFDO (profile) | two-machine (5 runs) | 26,522.9 ± 1,613.9 | 61 |
| ThinLTO + AutoFDO + Propeller | loopback (3 runs) | 28,568.0 ± 308.1 | 3 |
| ThinLTO + AutoFDO + Propeller | two-machine (3 runs) | 28,353.8 ± 1,691.7 | 61 |

---

# Build Notes

## Stock GCC kernel build (baseline)

Run [`scripts/01_build_gcc_baseline.sh`](scripts/01_build_gcc_baseline.sh). It builds the stock GCC kernel and installs it (tagged `-gcc-build`).

## Clang O2 kernel build (no LTO)

Run [`scripts/02_build_clang_nolto.sh`](scripts/02_build_clang_nolto.sh). It builds the O2 Clang kernel with LTO disabled and installs it (tagged `-clang-nolto-build`).

## Clang AutoFDO+Propeller kernel build (no LTO)

Run [`scripts/03_build_plto_nolto.sh`](scripts/03_build_plto_nolto.sh). It builds the kernel with the AutoFDO+Propeller Clang toolchain and LTO disabled and installs it (tagged `-plto-nolto-build`).

## Clang AutoFDO+Propeller kernel build (ThinLTO)

Run [`scripts/04_build_plto_thinlto.sh`](scripts/04_build_plto_thinlto.sh). It builds the kernel with the AutoFDO+Propeller Clang toolchain and ThinLTO enabled and installs it (tagged `-plto-thinlto-build`).

## Clang AutoFDO+Propeller kernel build (FullLTO)

Run [`scripts/05_build_plto_fulllto.sh`](scripts/05_build_plto_fulllto.sh). It builds the kernel with the AutoFDO+Propeller Clang toolchain and FullLTO enabled and installs it (tagged `-plto-fulllto-build`).

## Build ThinLTO + AutoFDO kernel (profiling kernel)

Run [`scripts/06_build_thinlto_autofdo_profiling.sh`](scripts/06_build_thinlto_autofdo_profiling.sh). It builds the ThinLTO + AutoFDO kernel (profile-less, used to boot and collect perf), installs it (tagged `-thinlto-autofdo-build`), and keeps a copy of `vmlinux` for `llvm-profgen`. After it finishes, reboot into the new kernel before Step 7.

## Collect AutoFDO profile (on booted `-thinlto-autofdo-build` kernel)

Per the RFC, the profile is collected under **high system load**. We profile three workloads separately (UnixBench, sysbench, neper), convert each to an AutoFDO profile, and merge them into one `kernel.afdo`.

### Setup

```bash
export KERNEL_SRC=/home/azure/sid/CBL-Mariner-Linux-Kernel
export PLTO_CLANG=/home/azure/sid/experiments/os-dev-env/llvm-project/builds/install-O3-ThinLTO-AutoFDO-propeller/bin
export VMLINUX=${KERNEL_SRC}/builds/clang-thinlto-autofdo/vmlinux
export BUILD=${KERNEL_SRC}/builds
export BENCH=${KERNEL_SRC}/bench
export PROFGEN=${PLTO_CLANG}/llvm-profgen
export PROFDATA=${PLTO_CLANG}/llvm-profdata
export PERIOD=500009

# verify we are on the profiling kernel and the matching vmlinux exists
uname -r                  # expect 6.18.26.1-thinlto-autofdo-build+
ls -lh ${VMLINUX}

# perf needs these so the [kernel.kallsyms] mmap is captured for llvm-profgen --kernel
sudo sysctl -w kernel.kptr_restrict=0
sudo sysctl -w kernel.perf_event_paranoid=-1

# noise control (same as benchmarking)
sudo cpupower frequency-set -g performance
sudo cpupower idle-set -D 0
```

### Workload 1 — UnixBench (112 copies)

```bash
sudo perf record -e BR_INST_RETIRED.NEAR_TAKEN:k -a -N -b -c ${PERIOD} \
  -o ${BUILD}/perf-unixbench.data -- \
  bash -c "cd ${BENCH}/byte-unixbench/UnixBench && ./Run -c 112"

# decode the binary perf.data into a text branch-record script
# -F ip,brstack is REQUIRED: default perf script omits the LBR branch stacks,
# and llvm-profgen builds the profile entirely from those branches.
sudo perf script -i ${BUILD}/perf-unixbench.data --show-mmap-events -F ip,brstack \
  > ${BUILD}/perf-unixbench.script

${PROFGEN} --kernel --binary=${VMLINUX} \
  --perfscript=${BUILD}/perf-unixbench.script \
  -o ${BUILD}/kernel-unixbench.afdo
```

### Workload 2 — sysbench (cpu, memory, threads, mutex)

```bash
SB=${BENCH}/sysbench/src/sysbench
sudo perf record -e BR_INST_RETIRED.NEAR_TAKEN:k -a -N -b -c ${PERIOD} \
  -o ${BUILD}/perf-sysbench.data -- bash -c "
    ${SB} cpu     --threads=208 --cpu-max-prime=20000 --time=60 run
    ${SB} memory  --threads=208 --memory-total-size=100G --memory-block-size=1M --time=60 run
    ${SB} threads --threads=208 --thread-yields=1001 --thread-locks=8 --time=60 run
    ${SB} mutex   --threads=208 --mutex-num=4097 --mutex-locks=50000 --mutex-loops=10000 run
  "

sudo perf script -i ${BUILD}/perf-sysbench.data --show-mmap-events -F ip,brstack \
  > ${BUILD}/perf-sysbench.script

${PROFGEN} --kernel --binary=${VMLINUX} \
  --perfscript=${BUILD}/perf-sysbench.script \
  -o ${BUILD}/kernel-sysbench.afdo
```

### Workload 3 — neper (100 flows / 10 threads, loopback)

```bash
NEPER=${BENCH}/neper
# start servers + clients in the background = high network load
${NEPER}/tcp_rr     -F 100 -T 10 -l 60 >/dev/null 2>&1 &
${NEPER}/tcp_stream -F 100 -T 10 -l 60 >/dev/null 2>&1 &
sleep 2
${NEPER}/tcp_rr     -F 100 -T 10 -l 60 -c -H 127.0.0.1 >/dev/null 2>&1 &
${NEPER}/tcp_stream -F 100 -T 10 -l 60 -c -H 127.0.0.1 >/dev/null 2>&1 &

sudo perf record -e BR_INST_RETIRED.NEAR_TAKEN:k -a -N -b -c ${PERIOD} \
  -o ${BUILD}/perf-neper.data -- sleep 60
wait

sudo perf script -i ${BUILD}/perf-neper.data --show-mmap-events -F ip,brstack \
  > ${BUILD}/perf-neper.script

${PROFGEN} --kernel --binary=${VMLINUX} \
  --perfscript=${BUILD}/perf-neper.script \
  -o ${BUILD}/kernel-neper.afdo
```

### Merge into one profile

```bash
${PROFDATA} merge --sample \
  -o ${BUILD}/kernel.afdo \
  ${BUILD}/kernel-unixbench.afdo \
  ${BUILD}/kernel-sysbench.afdo \
  ${BUILD}/kernel-neper.afdo

ls -lh ${BUILD}/kernel*.afdo
```

`${BUILD}/kernel.afdo` is the merged profile consumed by the next build (`CLANG_AUTOFDO_PROFILE`).

---

## Build ThinLTO + AutoFDO + Propeller kernel (profiling/labels kernel)

Propeller layers on top of AutoFDO, so this rebuilds the AutoFDO-optimised kernel (`CLANG_AUTOFDO_PROFILE=kernel.afdo`) with `CONFIG_PROPELLER_CLANG=y` but **no** Propeller profile yet — Clang then emits the basic-block address map needed for Propeller profiling. Keep a copy of `vmlinux` for `create_llvm_prof`, and reboot into the new kernel before collecting the profile.

> **EFI stub prerequisite (required for any Propeller build).** Propeller's `-fbasic-block-address-map`
> emits a `.llvm_bb_addr_map` section full of **absolute** relocations, which the EFI boot stub
> rejects (`absolute symbol references not allowed in the EFI stub`). These flags are applied
> per-object in `scripts/Makefile.lib` (not `KBUILD_CFLAGS`), so the fix is the per-dir disable
> knobs in `drivers/firmware/efi/libstub/Makefile` — add **both** (only `AUTOFDO_PROFILE := n`
> actually disables it, because the Propeller gate reads that variable first):
>
> ```make
> AUTOFDO_PROFILE := n
> PROPELLER_PROFILE := n
> ```
>
> This survives `make distclean` (tracked source) but is wiped by a re-clone.

```bash
export KERNEL_SRC=/home/azure/sid/CBL-Mariner-Linux-Kernel
export PLTO_CLANG=/home/azure/sid/experiments/os-dev-env/llvm-project/builds/install-O3-ThinLTO-AutoFDO-propeller/bin
export BUILD=${KERNEL_SRC}/builds
export AUTOFDO_PROFILE=${BUILD}/kernel.afdo   # merged profile from the AutoFDO step
cd ${KERNEL_SRC}

make distclean
wget "https://raw.githubusercontent.com/microsoft/CBL-Mariner-Linux-Kernel/refs/tags/rolling-lts/hwe/6.18.26.1/Microsoft/config" -O .config
wget "https://raw.githubusercontent.com/sidchintamaneni/azurelinux/refs/heads/siddharthc/kernel-hwe/6.18-v2/SPECS/kernel-hwe/azurelinux-ca-20230216.pem" -O certs/mariner.pem

scripts/config --set-str LOCALVERSION "-propeller-profiling-build"
scripts/config --enable LTO_CLANG
scripts/config --enable LTO_CLANG_THIN
scripts/config --disable LTO_CLANG_FULL
scripts/config --disable LTO_NONE
scripts/config --enable AUTOFDO_CLANG
scripts/config --enable PROPELLER_CLANG
make olddefconfig ARCH=x86_64 LLVM="${PLTO_CLANG}/"

# AutoFDO profile applied, NO propeller prefix -> Clang emits the basic-block address map
time make -j "$(nproc)" ARCH=x86_64 LLVM="${PLTO_CLANG}/" \
  CLANG_AUTOFDO_PROFILE="${AUTOFDO_PROFILE}"

# install (Azure Linux 3.0)
KVER="$(make -s kernelrelease)"
sudo make modules_install ARCH=x86_64 LLVM="${PLTO_CLANG}/"
sudo cp arch/x86/boot/bzImage "/boot/vmlinuz-${KVER}"
sudo dracut --force "/boot/initramfs-${KVER}.img" "${KVER}"
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# keep vmlinux for create_llvm_prof, then reboot into ${KVER}
mkdir -p ${BUILD}/clang-propeller-profiling
cp vmlinux ${BUILD}/clang-propeller-profiling/
```

## Collect Propeller profile (on booted `-propeller-profiling-build` kernel)

Same high-load capture as AutoFDO (LBR branch records), but the conversion tool is **`create_llvm_prof`** (from [google/autofdo](https://github.com/google/autofdo)) with `--format=propeller` — `llvm-profgen` does **not** emit Propeller cluster/symbol-order files. It reads the binary `perf.data` directly (no `perf script` step) and writes two files consumed by the final build: `<prefix>_cc_profile.txt` (basic-block clusters) and `<prefix>_ld_profile.txt` (symbol order).

### Setup

```bash
export KERNEL_SRC=/home/azure/sid/CBL-Mariner-Linux-Kernel
export PLTO_CLANG=/home/azure/sid/experiments/os-dev-env/llvm-project/builds/install-O3-ThinLTO-AutoFDO-propeller/bin
export VMLINUX=${KERNEL_SRC}/builds/clang-propeller-profiling/vmlinux
export BUILD=${KERNEL_SRC}/builds
export BENCH=${KERNEL_SRC}/bench
# create_llvm_prof must be built separately from github.com/google/autofdo
export CREATE_LLVM_PROF=${CREATE_LLVM_PROF:-/home/azure/sid/experiments/os-dev-env/llvm-project/builds/autofdo/build/create_llvm_prof}
export PERIOD=500009

# verify we are on the Propeller profiling kernel and the matching vmlinux exists
uname -r                  # expect 6.18.26.1-propeller-profiling-build+
ls -lh ${VMLINUX}

# perf needs these so the [kernel.kallsyms] mmap is captured
sudo sysctl -w kernel.kptr_restrict=0
sudo sysctl -w kernel.perf_event_paranoid=-1

# noise control (same as benchmarking)
sudo cpupower frequency-set -g performance
sudo cpupower idle-set -D 0
```

### Capture under load (fixed-window, all workloads in parallel)

> **Sizing gotcha (important).** `create_llvm_prof` is single-threaded and loads the
> *entire* `perf.data` into RAM. A long full-load capture (UnixBench `-c 112` ~28 min +
> sysbench + neper at `-c 500009`) produced ~89M events and got **OOM-killed** (~127 GB
> RSS on a 128 GB box; confirm with `dmesg | grep -i 'killed process'`). Neither a bigger
> period nor dropping `-c` fixed it — the size is `events ≈ (rate/period) × CPUs × duration`,
> and **duration dominates**. The robust fix is to bound the capture **by time**: launch all
> workloads in the background (in parallel = realistic high load), then `perf record -- sleep 60`
> to record a fixed 60s window regardless of how long the workloads run. ~60s ≈ ~30M events
> (~9 GB `perf.data`, ~40 GB RSS to convert) with broad hot-path coverage.

```bash
SB=${BENCH}/sysbench/src/sysbench
NEPER=${BENCH}/neper

sudo pkill -f 'byte-unixbench|sysbench|tcp_rr|tcp_stream' 2>/dev/null || true

# fire up mixed kernel-heavy load in the background (all workloads in parallel).
# UnixBench uses -i 1 + a kernel-heavy subset (not the full ~28 min -c 112 index).
( cd ${BENCH}/byte-unixbench/UnixBench && \
  ./Run -i 1 -c 112 syscall pipe context1 spawn execl fstime shell1 shell8 ) >/dev/null 2>&1 &
${SB} cpu     --threads=104 --cpu-max-prime=20000 --time=120 run >/dev/null 2>&1 &
${SB} threads --threads=104 --thread-yields=1001 --thread-locks=8 --time=120 run >/dev/null 2>&1 &
${NEPER}/tcp_rr     -F 100 -T 10 -l 120 >/dev/null 2>&1 &
${NEPER}/tcp_stream -F 100 -T 10 -l 120 >/dev/null 2>&1 &
sleep 2
${NEPER}/tcp_rr     -F 100 -T 10 -l 120 -c -H 127.0.0.1 >/dev/null 2>&1 &
${NEPER}/tcp_stream -F 100 -T 10 -l 120 -c -H 127.0.0.1 >/dev/null 2>&1 &

# record a FIXED 60s window while everything runs concurrently (bounds perf.data size)
sleep 5    # let load ramp up
sudo perf record -e BR_INST_RETIRED.NEAR_TAKEN:k -a -N -b -c ${PERIOD} \
  -o ${BUILD}/perf-propeller.data -- sleep 60

# tear down the load, then make the capture readable (perf record runs as root)
sudo pkill -f 'byte-unixbench|sysbench|tcp_rr|tcp_stream' || true
sudo chown "$(id -un):$(id -gn)" ${BUILD}/perf-propeller.data   # group 'azure' doesn't exist; use id -gn
ls -lh ${BUILD}/perf-propeller.data   # expect a few GB, not tens of GB
```

> Tip: run the capture inside `tmux`/`screen` so an SSH disconnect can't kill it, and
> watch `create_llvm_prof` RSS during conversion:
> `watch -n3 'ps -o rss= -p $(pgrep -f create_llvm_prof) | awk "{printf \"%.1f GB\\n\", \$1/1048576}"'`

### Generate the Propeller profiles

```bash
${CREATE_LLVM_PROF} \
  --binary=${VMLINUX} \
  --profile=${BUILD}/perf-propeller.data \
  --format=propeller \
  --propeller_output_module_name \
  --out=${BUILD}/propeller_cc_profile.txt \
  --propeller_symorder=${BUILD}/propeller_ld_profile.txt

# sanity-check the profile (want thousands of functions covering real hot paths)
grep -c '^f ' ${BUILD}/propeller_cc_profile.txt   # functions with basic-block layout (e.g. ~2440)
wc -l < ${BUILD}/propeller_ld_profile.txt          # functions in the symbol order (e.g. ~4376)
ls -lh ${BUILD}/propeller_*_profile.txt
```

Profile-file format: `propeller_cc_profile.txt` is `v1`, then per function `m <source file>`,
`f <function>`, `c0 <bb numbers…>` (the new basic-block order — hot blocks first, cold split
out; multiple `c<n>` lines = separate hot/cold clusters). `propeller_ld_profile.txt` is the
function placement order for `.text`. Expect genuinely hot kernel paths (`vfs_read`/`vfs_write`,
scheduler `update_curr`/`dequeue_task`, `maple_tree`, timers, memcg) — that's the signal the
capture hit the right code.

The prefix `${BUILD}/propeller` (→ `propeller_cc_profile.txt` + `propeller_ld_profile.txt`) is what the final build consumes via `CLANG_PROPELLER_PROFILE_PREFIX`.

## Build ThinLTO + AutoFDO + Propeller kernel (final)

Rebuild with **both** profiles — `CLANG_AUTOFDO_PROFILE=kernel.afdo` and `CLANG_PROPELLER_PROFILE_PREFIX=${BUILD}/propeller` — to produce the final Propeller-optimised layout. Reboot into it and run the benchmarks ([`scripts/bench_unixbench.sh`](scripts/bench_unixbench.sh), [`scripts/bench_sysbench.sh`](scripts/bench_sysbench.sh), [`scripts/bench_neper.sh`](scripts/bench_neper.sh)) to fill the `ThinLTO + AutoFDO + Propeller` rows.

```bash
export KERNEL_SRC=/home/azure/sid/CBL-Mariner-Linux-Kernel
export PLTO_CLANG=/home/azure/sid/experiments/os-dev-env/llvm-project/builds/install-O3-ThinLTO-AutoFDO-propeller/bin
export BUILD=${KERNEL_SRC}/builds
export AUTOFDO_PROFILE=${BUILD}/kernel.afdo
export PROPELLER_PREFIX=${BUILD}/propeller   # -> propeller_cc_profile.txt + propeller_ld_profile.txt
cd ${KERNEL_SRC}

make distclean
wget "https://raw.githubusercontent.com/microsoft/CBL-Mariner-Linux-Kernel/refs/tags/rolling-lts/hwe/6.18.26.1/Microsoft/config" -O .config
wget "https://raw.githubusercontent.com/sidchintamaneni/azurelinux/refs/heads/siddharthc/kernel-hwe/6.18-v2/SPECS/kernel-hwe/azurelinux-ca-20230216.pem" -O certs/mariner.pem

scripts/config --set-str LOCALVERSION "-plto-propeller-build"
scripts/config --enable LTO_CLANG
scripts/config --enable LTO_CLANG_THIN
scripts/config --disable LTO_CLANG_FULL
scripts/config --disable LTO_NONE
scripts/config --enable AUTOFDO_CLANG
scripts/config --enable PROPELLER_CLANG
make olddefconfig ARCH=x86_64 LLVM="${PLTO_CLANG}/"

# both profiles -> final propeller layout
time make -j "$(nproc)" ARCH=x86_64 LLVM="${PLTO_CLANG}/" \
  CLANG_AUTOFDO_PROFILE="${AUTOFDO_PROFILE}" \
  CLANG_PROPELLER_PROFILE_PREFIX="${PROPELLER_PREFIX}"

# binary stats -> fill the "ThinLTO + AutoFDO + Propeller" results column
ls -lh vmlinux                                    # vmlinux size
readelf -SW vmlinux | grep -E ' \.text | \.rodata '   # .text / .rodata (Size column is hex)
nm vmlinux | grep -c -E '^[0-9a-f]+ [Tt] '        # function count (T+t)

# install (Azure Linux 3.0), then reboot into ${KVER} and benchmark
KVER="$(make -s kernelrelease)"
sudo make modules_install ARCH=x86_64 LLVM="${PLTO_CLANG}/"
sudo cp arch/x86/boot/bzImage "/boot/vmlinuz-${KVER}"
sudo dracut --force "/boot/initramfs-${KVER}.img" "${KVER}"
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

---



