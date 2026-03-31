# PGO, LTO & PLTO Experiments: Compiling Clang with Clang

**Machine:** Azure Linux 3.0, kernel 6.18.5 ([config](https://github.com/sidchintamaneni/azurelinux/blob/siddharthc/kernel-hwe/6.18-v2/SPECS/kernel-hwe/config)), Intel Xeon Platinum 8473C

**LLVM Version:** 22.1.2 (`llvmorg-22.1.2`)

**GCC Version:** 13.2.0 (system)

---

## Results Summary

| Metric               | -O2 (GCC) | -O2 (Clang) | -O3 (Clang) | -O3, LTO | -O3, ThinLTO | -O3, ThinLTO, debug | -O3, ThinLTO, iFDO | -O3, ThinLTO, AutoFDO |
|----------------------|-----------|-------------|-------------|----------|-------------|--------------------|--------------------|----------------------|
| Built with           | gcc/g++  | O2-clang   | O2-clang   | O2-clang | O2-clang  | O2-clang        | O2-clang        | O2-clang          |
| Build time (wall)    | 3m 4s    | 2m 8s      | 2m 7s      | 21m 29s | 11m 37s    | 13m 16s         | 9m 51s          | 19m 59s           |
| clang-22 binary size | 136M     | 121M       | 125M       | 138M    | 139M       | 511M            | 123M            | 149M              |
| .text                | 82,769,981 | 68,258,815 | 73,173,247 | 90,727,949 | 90,303,327 | 89,506,271   | 69,345,502      | 105,372,911       |
| .rodata              | 10,939,520 | 11,619,752 | 11,635,640 | 11,933,428 | 11,930,600 | 11,936,136   | 11,703,184      | 12,076,680        |
| .data                | 62,520     | 50,120     | 50,120     | 33,480  | 33,528     | 33,528          | 33,528          | 33,528            |
| .bss                 | 646,472    | 506,714    | 506,714    | 506,608 | 506,778    | 506,778         | 506,714         | 506,762           |
| .debug (gmlt)        | -        | -          | -          | -       | -          | ~390M           | -               | -                 |
| Function count (T+t) | 165,177    | 137,339    | 136,581    | 132,828 | 134,836    | 131,840         | 157,289         | 119,584           |

### BOLT on iFDO and AutoFDO

| Metric | O3-ThinLTO-iFDO + BOLT | O3-ThinLTO-AutoFDO + BOLT |
|--------|------------|----------------|
| perf2bolt time | 4m 40s | 4m 41s |
| perf2bolt: functions profiled | 20,388 / 159,749 (12.8%) | 18,782 / 122,046 (15.4%) |
| bolt time | 26s | 29s |
| bolt: blocks reordered | 12,237 functions (60.0% of profiled) | 13,744 functions (73.2% of profiled) |
| bolt: hot/cold split | 8.7M hot / 12.4M cold (41.1% hot) | 9.4M hot / 16.8M cold (35.8% hot) |
| bolt: taken branches | -29.8% | -62.2% |
| bolt: taken forward branches | -51.5% | -79.2% |
| bolt: unconditional branches | -35.0% | -60.6% |
| bolt: instructions | -0.5% | -1.0% |
| clang-22 binary size | 169M | 198M |
| .text (hot) | 15,404,322 | 14,323,701 |
| .bolt.org.text (cold) | 69,345,502 | 105,372,911 |

### Propeller on AutoFDO

| Metric | O3-ThinLTO-AutoFDO + Propeller |
|--------|-------------------------------|
| 9a: O3+ThinLTO+AutoFDO+labels build time | 20m 27s |
| 9a: .llvm_bb_addr_map size | 27.6M |
| 9b: Perf profile (100 cmds, sequential) | 135M perf.data, 173K samples |
| 9c: create_llvm_prof time | 3.4s |
| Hot functions profiled | 12,285 |
| Hot basic blocks | 268,754 |
| CFG nodes created | 1,154,578 |
| Edges created | 369,255 |
| Inter-function ext-tsp score | +201.8% |
| Intra-function ext-tsp score | +37.0% |
| cluster.txt lines | 24,433 |
| symorder.txt lines | 23,425 |
| 9d: Final build time | 18m 31s |
| clang-22 binary size | 153M |
| .text | 105,889,327 |
| .rodata | 12,074,552 |
| Function count (T+t) | 129,421 |

### iFDO Intermediate Stats

| Step | Wall time | Details |
|------|-----------|---------|
| 6a: Instrumented build (O2 + compiler-rt) | 2m 50s | 213M binary, 171,633 functions, .text: 100,613,282 |
| 6b: Profile workload (O3+ThinLTO compile) | 84m 5s | Instrumented clang ~40x slower |
| 6b: Profile merge | 23m 12s | 4,229 .profraw files (112 GB) → 49M merged.profdata |

### AutoFDO Intermediate Stats

**Key findings:**
- `-fdebug-info-for-profiling` is critical — fixes 15.77% function name mismatch
- Sequential profiling (`-j1`) gives much better per-process sample density than `-j192`

| Step | Wall time | Details |
|------|-----------|---------|
| 7a: Debug build (O3+ThinLTO + -gmlt + -fdebug-info-for-profiling) | 13m 16s | 511M binary, 131,840 functions |
| 7b: Perf workload (full build, -c 50009, -j1) | ~2h | ~110 GB perf.data, 13,376 functions captured, 4.66B total count |
| 7c: llvm-profgen conversion | 20m 16s | 34M autofdo.profdata, no warnings |
| 7d: Final build (O3+ThinLTO+AutoFDO) | 19m 59s | 149M binary, 119,584 functions |

**For comparison — iFDO:** 171,236 functions, 4.1T total count, **21% faster**

### Benchmark: Compile Clang at O2 (5 runs each, wall clock seconds)

| Compiler | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 | Avg | vs O2-clang |
|----------|-------|-------|-------|-------|-------|-----|-------------|
| O2-clang (baseline) | 124 | 124 | 123 | 123 | 123 | 123.4s | - |
| O3-clang | 123 | 124 | 124 | 124 | 124 | 123.8s | +0.3% |
| O3-LTO | 120 | 120 | 120 | 120 | 120 | 120.0s | -2.8% |
| O3-ThinLTO | 121 | 120 | 121 | 120 | 121 | 120.6s | -2.3% |
| O3-ThinLTO-iFDO | 98 | 98 | 97 | 99 | 99 | 98.2s | **-20.4%** |
| O3-ThinLTO-AutoFDO | 113 | 113 | 113 | 113 | 113 | 113.0s | **-8.4%** |
| O3-ThinLTO-iFDO+BOLT | 95 | 95 | 95 | 95 | 95 | 95.0s | **-23.0%** |
| O3-ThinLTO-AutoFDO+BOLT | 98 | 97 | 97 | 98 | 98 | 97.6s | **-20.9%** |
| O3-ThinLTO-AutoFDO+Propeller | 97 | 98 | 97 | 98 | 97 | 97.4s | **-21.1%** |

### perf stat: Compile Clang at O2 (3 runs avg, -j192)

| Metric | O2-clang | O3-clang | O3-LTO | O3-ThinLTO | O3-ThinLTO-iFDO | O3-ThinLTO-AutoFDO | iFDO+BOLT | AutoFDO+BOLT | AutoFDO+Propeller |
|--------|----------|----------|--------|------------|-----------------|-------------------|-----------|--------------|-------------------|
| Instructions (T) | 43,826 | 43,386 | 40,208 | 40,450 | 32,540 | 37,068 | 32,497 | 36,825 | 37,007 |
| Cycles (T) | 54,126 | 54,051 | 52,451 | 52,761 | 41,847 | 48,961 | 40,399 | 41,489 | 41,197 |
| IPC | 0.81 | 0.80 | 0.77 | 0.77 | 0.78 | 0.76 | 0.80 | **0.89** | **0.90** |
| L1-icache misses (T) | 2,849 | 2,857 | 2,746 | 2,759 | 1,632 | 2,276 | **1,513** | **1,625** | **1,580** |
| iTLB misses (B) | 21.3 | 22.4 | 22.4 | 24.0 | 17.5 | 20.2 | **13.8** | **10.5** | **11.3** |
| Wall time | 125.1s | 124.6s | 121.1s | 121.8s | 99.1s | 114.5s | **95.9s** | **98.5s** | **98.6s** |
| vs O2-clang | - | -0.4% | -3.2% | -2.6% | **-20.8%** | **-8.5%** | **-23.4%** | **-21.3%** | **-21.2%** |

---

---

# Build Notes

## Checkout

```bash
cd /home/azure/sid/experiments/os-dev-env/llvm-project
git fetch --tags
git checkout llvmorg-22.1.2
```

---

## Step 1: O2 with GCC (bootstrap)

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O2 && cd build-O2

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG" \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_CXX_COMPILER=g++ \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O2 \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

---

## Step 2: O2 with Clang (baseline)

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O2-clang && cd build-O2-clang

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O2-clang \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

---

## Step 3: O3 with Clang

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O3-clang && cd build-O3-clang

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-clang \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

---

## Step 4: O3 + Full LTO

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O3-LTO-clang && cd build-O3-LTO-clang

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Full \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-LTO-clang \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1
grep "LLVM_ENABLE_LTO" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

---

## Step 5: O3 + ThinLTO

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O3-ThinLTO-clang && cd build-O3-ThinLTO-clang

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-ThinLTO-clang \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1
grep "LLVM_ENABLE_LTO" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

---

## Step 6: O3 + ThinLTO + iFDO (Instrumented FDO)

iFDO is a 3-step process: build an instrumented binary, run it to collect profiles, then rebuild with the profile data.

### Step 6a: Build instrumented Clang (O3 + ThinLTO + fprofile-generate)

This builds Clang with profiling instrumentation at O2. Includes `compiler-rt` for the profiling runtime (`libclang_rt.profile.a`).
The instrumented binary just needs to run and collect profiles — O2 is sufficient and builds faster.

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O2-instrumented && cd build-O2-instrumented

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_ENABLE_RUNTIMES="compiler-rt" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_BUILD_INSTRUMENTED=IR \
  -DLLVM_BUILD_RUNTIME=YES \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O2-instrumented \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1
grep "LLVM_BUILD_INSTRUMENTED" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

### Step 6b: Collect profile data (run instrumented Clang on a workload)

Use the instrumented Clang to compile Clang with O3+ThinLTO (exercises optimizer + LTO code paths).

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds

# Set profile output directory
export LLVM_PROFILE_FILE="${LLVM_SRC}/builds/profiles/profile-%p-%m.profraw"
mkdir -p ${LLVM_SRC}/builds/profiles

# Use instrumented clang to compile clang with O3+ThinLTO (the workload)
mkdir -p build-profile-workload && cd build-profile-workload

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-instrumented/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-instrumented/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  $LLVM_SRC/llvm

ninja -j192
# Don't need to install — we just want the profile data

# Merge the profiles
${LLVM_SRC}/builds/install-O2-instrumented/bin/llvm-profdata merge \
  -output=${LLVM_SRC}/builds/profiles/merged.profdata \
  ${LLVM_SRC}/builds/profiles/profile-*.profraw

# Check profile size
ls -lh ${LLVM_SRC}/builds/profiles/merged.profdata
```

### Step 6c: Build optimized Clang with profile (O3 + ThinLTO + fprofile-use)

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O3-ThinLTO-iFDO && cd build-O3-ThinLTO-iFDO

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_PROFDATA_FILE=${LLVM_SRC}/builds/profiles/merged.profdata \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-ThinLTO-iFDO \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1
grep "LLVM_PROFDATA_FILE" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

---

## Step 7: O3 + ThinLTO + AutoFDO

AutoFDO uses hardware performance counters (Intel LBR) instead of instrumentation to collect profiles.
Much lower overhead than iFDO — profiles can be collected from production binaries.

### Step 7a: Build Clang with debug info (for perf → source mapping)

Build O3+ThinLTO Clang with `-gmlt` (minimal line tables) and `-fdebug-info-for-profiling`
(adds discriminators and extra DWARF info for AutoFDO sample mapping).

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O3-ThinLTO-debug && cd build-O3-ThinLTO-debug

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG -gmlt -fdebug-info-for-profiling" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -gmlt -fdebug-info-for-profiling" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-ThinLTO-debug \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

### Step 7b: Collect perf profile with LBR

Profile the full Clang build to get maximum sample coverage.
Use `-c` (period) instead of `-F` (frequency) to avoid kernel throttling.

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds

# First configure the workload build
mkdir -p build-autofdo-workload && cd build-autofdo-workload

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O3-ThinLTO-debug/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O3-ThinLTO-debug/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  $LLVM_SRC/llvm

mkdir -p ${LLVM_SRC}/builds/autofdo-profiles
time perf record -e br_inst_retired.near_taken:upp -j any,u -c 50009 \
  -o ${LLVM_SRC}/builds/autofdo-profiles/perf.data \
  -- ninja -j1

# Check profile size
ls -lh ${LLVM_SRC}/builds/autofdo-profiles/perf.data
```

### Step 7c: Convert perf profile to LLVM format

Use `llvm-profgen` (built-in to LLVM 22.x) to convert perf data to sample profile.

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project

mkdir -p ${LLVM_SRC}/builds/autofdo-profiles

# Convert perf.data → LLVM sample profile
time ${LLVM_SRC}/builds/install-O3-ThinLTO-debug/bin/llvm-profgen \
  --binary=${LLVM_SRC}/builds/install-O3-ThinLTO-debug/bin/clang-22 \
  --perfdata=${LLVM_SRC}/builds/autofdo-profiles/perf.data \
  --output=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata

ls -lh ${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata
```

### Step 7d: Build optimized Clang with AutoFDO profile

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O3-ThinLTO-AutoFDO && cd build-O3-ThinLTO-AutoFDO

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG -fprofile-sample-use=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -fprofile-sample-use=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO \
  $LLVM_SRC/llvm

# Verify flags
grep "CMAKE_CXX_FLAGS_RELEASE" CMakeCache.txt | head -1

time ninja -j192
ninja install
```

---

## Step 8: BOLT (Binary Optimization and Layout Tool)

BOLT is a post-link optimizer that rearranges an already-compiled binary for better code layout.
It works on any binary — we apply it on top of iFDO and AutoFDO builds.

### Step 8a: Build BOLT

BOLT is part of LLVM. If not already built, rebuild O2-clang with `bolt` included:

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project

# Check if bolt exists
ls ${LLVM_SRC}/builds/install-O2-clang/bin/llvm-bolt 2>/dev/null && echo "Found" || echo "Need to build"

# If not found, rebuild O2-clang with bolt
cd ${LLVM_SRC}/builds/build-O2-clang
cmake -DLLVM_ENABLE_PROJECTS="clang;lld;bolt" .
ninja -j192 llvm-bolt merge-fdata
ninja install
```

### Step 8b: BOLT the iFDO binary

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
export BOLT=${LLVM_SRC}/builds/install-O2-clang/bin/llvm-bolt
export PERF2BOLT=${LLVM_SRC}/builds/install-O2-clang/bin/perf2bolt
IFDO_BIN=${LLVM_SRC}/builds/install-O3-ThinLTO-iFDO-bolt/bin/clang-22

# Build iFDO with --emit-relocs (required for BOLT)
cd ${LLVM_SRC}/builds
mkdir -p build-O3-ThinLTO-iFDO-bolt && cd build-O3-ThinLTO-iFDO-bolt

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG" \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,--emit-relocs" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_PROFDATA_FILE=${LLVM_SRC}/builds/profiles/merged.profdata \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-ThinLTO-iFDO-bolt \
  $LLVM_SRC/llvm

time ninja -j192
ninja install

# Profile for BOLT
cd ${LLVM_SRC}/builds/benchmarks/bench-build
cmake -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O3-ThinLTO-iFDO-bolt/bin/clang \
      -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O3-ThinLTO-iFDO-bolt/bin/clang++ \
      . > /dev/null 2>&1
ninja clean > /dev/null 2>&1

mkdir -p ${LLVM_SRC}/builds/bolt-profiles
time perf record -e cycles:u -j any,u -o ${LLVM_SRC}/builds/bolt-profiles/perf-ifdo.data \
  -- ninja -j192

# Convert perf to BOLT format
time ${PERF2BOLT} ${IFDO_BIN} \
  --perfdata=${LLVM_SRC}/builds/bolt-profiles/perf-ifdo.data \
  -o ${LLVM_SRC}/builds/bolt-profiles/bolt-ifdo.fdata

# Run BOLT
time ${BOLT} ${IFDO_BIN} \
  --data=${LLVM_SRC}/builds/bolt-profiles/bolt-ifdo.fdata \
  --relocs \
  --reorder-blocks=ext-tsp \
  --reorder-functions=cdsort \
  --split-functions \
  --split-all-cold \
  --dyno-stats \
  -o ${LLVM_SRC}/builds/install-O3-ThinLTO-iFDO-bolt/bin/clang-22.bolted

# Replace and benchmark
cp ${IFDO_BIN} ${IFDO_BIN}.orig
cp ${LLVM_SRC}/builds/install-O3-ThinLTO-iFDO-bolt/bin/clang-22.bolted ${IFDO_BIN}
```

### Step 8c: BOLT the AutoFDO binary

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
export BOLT=${LLVM_SRC}/builds/install-O2-clang/bin/llvm-bolt
export PERF2BOLT=${LLVM_SRC}/builds/install-O2-clang/bin/perf2bolt
AUTOFDO_BIN=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-bolt/bin/clang-22

# Build AutoFDO with --emit-relocs (required for BOLT)
cd ${LLVM_SRC}/builds
mkdir -p build-O3-ThinLTO-AutoFDO-bolt && cd build-O3-ThinLTO-AutoFDO-bolt

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG -fprofile-sample-use=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -fprofile-sample-use=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata" \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,--emit-relocs" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-bolt \
  $LLVM_SRC/llvm

time ninja -j192
ninja install

# Profile for BOLT
cd ${LLVM_SRC}/builds/benchmarks/bench-build
cmake -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-bolt/bin/clang \
      -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-bolt/bin/clang++ \
      . > /dev/null 2>&1
ninja clean > /dev/null 2>&1

time perf record -e cycles:u -j any,u -o ${LLVM_SRC}/builds/bolt-profiles/perf-autofdo.data \
  -- ninja -j192

# Convert perf to BOLT format
time ${PERF2BOLT} ${AUTOFDO_BIN} \
  --perfdata=${LLVM_SRC}/builds/bolt-profiles/perf-autofdo.data \
  -o ${LLVM_SRC}/builds/bolt-profiles/bolt-autofdo.fdata

# Run BOLT
time ${BOLT} ${AUTOFDO_BIN} \
  --data=${LLVM_SRC}/builds/bolt-profiles/bolt-autofdo.fdata \
  --relocs \
  --reorder-blocks=ext-tsp \
  --reorder-functions=cdsort \
  --split-functions \
  --split-all-cold \
  --dyno-stats \
  -o ${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-bolt/bin/clang-22.bolted

# Replace and benchmark
cp ${AUTOFDO_BIN} ${AUTOFDO_BIN}.orig
cp ${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-bolt/bin/clang-22.bolted ${AUTOFDO_BIN}
```

---

## Step 9: O3 + ThinLTO + AutoFDO + Propeller

It requires `-fbasic-blVendor ID:                   GenuineIntel
  Model name:                Intel(R) Core(TM) i7-8700T CPU @ 2.40GHz
    CPU family:              6
    Model:                   158
    Thread(s) per core:      1
    Core(s) per socket:      6
    Socket(s):               1
    Stepping:                10
    CPU(s) scaling MHz:      33%
    CPU max MHz:             2400.0000
    CPU min MHz:             800.0000ock-address-map` to emit BB metadata, and `create_llvm_prof --format=propeller`
(from Google's [autofdo](https://github.com/google/autofdo) repo) to convert perf profiles into layout files.

### Step 9a: Build Clang with BB address map (for Propeller profiling)

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O3-ThinLTO-AutoFDO-propeller-labels && cd build-O3-ThinLTO-AutoFDO-propeller-labels

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG -fprofile-sample-use=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata -funique-internal-linkage-names -fbasic-block-address-map" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -fprofile-sample-use=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata -funique-internal-linkage-names -fbasic-block-address-map" \
  -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld -Wl,--lto-basic-block-address-map" \
  -DCMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld -Wl,--lto-basic-block-address-map" \
  -DCMAKE_MODULE_LINKER_FLAGS="-fuse-ld=lld -Wl,--lto-basic-block-address-map" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-propeller-labels \
  $LLVM_SRC/llvm

time ninja -j192
ninja install

# Verify .llvm_bb_addr_map section exists
${LLVM_SRC}/builds/install-O2-clang/bin/llvm-readelf -S \
  ${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-propeller-labels/bin/clang-22 \
  | grep -i "bb_addr_map"
```

### Step 9b: Collect perf profile for Propeller

Profile a sequential workload (100 compilations) with `cycles:u -j any,u` for LBR branch traces.
Sequential execution gives better per-process sample density.

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
LABEL_BIN=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-propeller-labels/bin/clang
LABEL_BINXX=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-propeller-labels/bin/clang++
mkdir -p ${LLVM_SRC}/builds/propeller-profiles

# Configure workload
cd ${LLVM_SRC}/builds/benchmarks/bench-build
cmake -DCMAKE_C_COMPILER=${LABEL_BIN} \
      -DCMAKE_CXX_COMPILER=${LABEL_BINXX} \
      . > /dev/null 2>&1
ninja clean > /dev/null 2>&1

# Extract first 100 compilation commands as sequential workload
ninja -t commands | head -100 > ./propeller_workload.sh
chmod +x ./propeller_workload.sh

# Record with cycles:u + LBR
time perf record -e cycles:u -j any,u \
  -o ${LLVM_SRC}/builds/propeller-profiles/perf.data \
  -- ./propeller_workload.sh

ls -lh ${LLVM_SRC}/builds/propeller-profiles/perf.data
```

### Step 9c: Convert perf profile to Propeller layout files

Use `create_llvm_prof` from the [autofdo](https://github.com/google/autofdo) repo with `--format=propeller`.
This outputs two files: `cluster.txt` (BB reordering within functions) and `symorder.txt` (function reordering).

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
CREATE_LLVM_PROF=${LLVM_SRC}/builds/autofdo/build/create_llvm_prof

time ${CREATE_LLVM_PROF} \
  --format=propeller \
  --binary=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-propeller-labels/bin/clang-22 \
  --profile=${LLVM_SRC}/builds/propeller-profiles/perf.data \
  --out=${LLVM_SRC}/builds/propeller-profiles/cluster.txt \
  --propeller_symorder=${LLVM_SRC}/builds/propeller-profiles/symorder.txt \
  --profiled_binary_name=clang-22 \
  --propeller_call_chain_clustering \
  --propeller_chain_split

# Check outputs
wc -l ${LLVM_SRC}/builds/propeller-profiles/cluster.txt
wc -l ${LLVM_SRC}/builds/propeller-profiles/symorder.txt
```

### Step 9d: Build optimized Clang with Propeller layout

```bash
export LLVM_SRC=/home/azure/sid/experiments/os-dev-env/llvm-project
cd ${LLVM_SRC}/builds
mkdir -p build-O3-ThinLTO-AutoFDO-propeller && cd build-O3-ThinLTO-AutoFDO-propeller

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG -fprofile-sample-use=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata -funique-internal-linkage-names -fbasic-block-sections=list=${LLVM_SRC}/builds/propeller-profiles/cluster.txt" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -fprofile-sample-use=${LLVM_SRC}/builds/autofdo-profiles/autofdo.profdata -funique-internal-linkage-names -fbasic-block-sections=list=${LLVM_SRC}/builds/propeller-profiles/cluster.txt" \
  -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld -Wl,--lto-basic-block-sections=${LLVM_SRC}/builds/propeller-profiles/cluster.txt -Wl,--symbol-ordering-file=${LLVM_SRC}/builds/propeller-profiles/symorder.txt -Wl,--no-warn-symbol-ordering" \
  -DCMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld -Wl,--lto-basic-block-sections=${LLVM_SRC}/builds/propeller-profiles/cluster.txt -Wl,--symbol-ordering-file=${LLVM_SRC}/builds/propeller-profiles/symorder.txt -Wl,--no-warn-symbol-ordering" \
  -DCMAKE_MODULE_LINKER_FLAGS="-fuse-ld=lld -Wl,--lto-basic-block-sections=${LLVM_SRC}/builds/propeller-profiles/cluster.txt -Wl,--symbol-ordering-file=${LLVM_SRC}/builds/propeller-profiles/symorder.txt -Wl,--no-warn-symbol-ordering" \
  -DCMAKE_C_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang \
  -DCMAKE_CXX_COMPILER=${LLVM_SRC}/builds/install-O2-clang/bin/clang++ \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX=${LLVM_SRC}/builds/install-O3-ThinLTO-AutoFDO-propeller \
  $LLVM_SRC/llvm

time ninja -j192
ninja install
```
