#!/usr/bin/env bash
set -euo pipefail

# Step 2: Clang O2 kernel build (no LTO)

KERNEL_SRC="${KERNEL_SRC:-/home/azure/sid/CBL-Mariner-Linux-Kernel}"
O2_CLANG="${O2_CLANG:-/home/azure/sid/experiments/os-dev-env/llvm-project/builds/install-O2-clang/bin}"
CONFIG_URL="https://raw.githubusercontent.com/microsoft/CBL-Mariner-Linux-Kernel/refs/tags/rolling-lts/hwe/6.18.26.1/Microsoft/config"
CERT_URL="https://raw.githubusercontent.com/sidchintamaneni/azurelinux/refs/heads/siddharthc/kernel-hwe/6.18-v2/SPECS/kernel-hwe/azurelinux-ca-20230216.pem"

cd "${KERNEL_SRC}"

make distclean
wget "${CONFIG_URL}" -O .config
wget "${CERT_URL}" -O certs/mariner.pem

# Tag this build so it shows up as a distinct kernel version (uname -r)
scripts/config --set-str LOCALVERSION "-clang-nolto-build"

# Disable LTO
scripts/config --disable LTO_CLANG_THIN
scripts/config --disable LTO_CLANG_FULL
scripts/config --disable LTO_CLANG
scripts/config --enable LTO_NONE

make olddefconfig ARCH=x86_64 LLVM="${O2_CLANG}/"

# Capture build wall time
BUILD_LOG="$(mktemp)"
{ time make -j "$(nproc)" ARCH=x86_64 LLVM="${O2_CLANG}/"; } 2> "${BUILD_LOG}"
BUILD_TIME="$(grep -E '^real' "${BUILD_LOG}" | awk '{print $2}')"
rm -f "${BUILD_LOG}"

# Install the kernel (Azure Linux 3.0)
KVER="$(make -s kernelrelease)"
sudo make modules_install ARCH=x86_64 LLVM="${O2_CLANG}/"
sudo cp arch/x86/boot/bzImage "/boot/vmlinuz-${KVER}"
sudo dracut --force "/boot/initramfs-${KVER}.img" "${KVER}"
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Collect binary stats
VMLINUX_SIZE="$(ls -lh vmlinux | awk '{print $5}')"
TEXT_SIZE="$(readelf -SW vmlinux | sed -E 's/\[[ 0-9]*\]//' | awk '$1 == ".text" {print strtonum("0x" $5)}')"
RODATA_SIZE="$(readelf -SW vmlinux | sed -E 's/\[[ 0-9]*\]//' | awk '$1 == ".rodata" {print strtonum("0x" $5)}')"
FUNC_COUNT="$(nm vmlinux | grep -c -E '^[0-9a-f]+ [Tt] ')"

# Print summary block (copy-paste this)
echo
echo "================ RESULTS (Clang no-LTO) ================"
echo "Kernel version       : ${KVER}"
echo "Build time (wall)    : ${BUILD_TIME}"
echo "vmlinux size         : ${VMLINUX_SIZE}"
echo ".text                : ${TEXT_SIZE}"
echo ".rodata              : ${RODATA_SIZE}"
echo "Function count (T+t) : ${FUNC_COUNT}"
echo "======================================================="
