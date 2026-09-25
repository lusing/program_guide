#!/bin/bash
# ============================================================
# build-boot.sh - 引导链示例的汇编 + 制盘 + QEMU 验证脚本
# ============================================================
# 用法:
#   ./build-boot.sh              # 构建并运行全部引导示例
#   ./build-boot.sh 01           # 只构建并运行 01_mbr_hello
#
# 依赖: nasm、qemu-system-x86_64（在 PATH 中）
# 验证方式: QEMU 无头模式启动，串口接到 stdout，
#           在输出中查找每个示例的期望标记行。
# ============================================================
set -u
cd "$(dirname "$0")"
mkdir -p build

IMG_SIZE=1474560        # 1.44MB 磁盘镜像（与 3.5" 软盘同尺寸，QEMU 通用）
TIMEOUT_SECS=20         # 单个示例的 QEMU 运行时限

# ------------------------------------------------------------
# make_image <img> <sector0.bin> [sector1.bin ...]
# 把若干 512 字节的块按扇区写入镜像；不足 IMG_SIZE 的部分补零
# ------------------------------------------------------------
make_image() {
    local img=$1; shift
    dd if=/dev/zero of="$img" bs=1 count=0 seek=$IMG_SIZE 2>/dev/null
    local idx=0
    for bin in "$@"; do
        dd if="$bin" of="$img" bs=512 conv=notrunc seek=$idx 2>/dev/null
        idx=$((idx + ( $(stat -c %s "$bin") + 511 ) / 512 ))
    done
}

# ------------------------------------------------------------
# run_qemu <img> <logfile> —— 带超时运行，串口输出写日志
# ------------------------------------------------------------
run_qemu() {
    local img=$1 log=$2
    timeout $TIMEOUT_SECS qemu-system-x86_64 \
        -drive format=raw,file="$img" \
        -display none -serial stdio -no-reboot > "$log" 2>&1
    return 0
}

# ------------------------------------------------------------
# check <logfile> <期望标记>... —— 逐个在串口日志里查找
# ------------------------------------------------------------
check() {
    local log=$1; shift
    local fail=0
    for marker in "$@"; do
        if ! grep -qF "$marker" "$log"; then
            echo "  [失败] 未找到期望输出: $marker"
            fail=1
        fi
    done
    return $fail
}

# ------------------------------------------------------------
# 各示例
# ------------------------------------------------------------
build_01() {
    echo "===== 01_mbr_hello（实模式主引导扇区）====="
    nasm -f bin 01_mbr_hello.asm -o build/01_mbr.bin || return 1
    make_image build/01.img build/01_mbr.bin
    run_qemu build/01.img build/01.log
    cat build/01.log
    check build/01.log "Hello from real-mode MBR!" "byte=H" "Halting"
}

# 两段式镜像：扇区 0 = 共享加载器 stage1，扇区 1 起 = 各示例的第二阶段
build_02() {
    echo "===== 02_pm32（进入 32 位保护模式）====="
    nasm -f bin stage1.asm -o build/stage1.bin || return 1
    nasm -f bin 02_pm32.asm -o build/02_pm32.bin || return 1
    make_image build/02.img build/stage1.bin build/02_pm32.bin
    run_qemu build/02.img build/02.log
    cat build/02.log
    check build/02.log "Hello from 32-bit protected mode!" "GDTR: base=" "CPL=0"
}

build_03() {
    echo "===== 03_paging（32 位分页：恒等映射 + 高端映射）====="
    nasm -f bin stage1.asm -o build/stage1.bin || return 1
    nasm -f bin 03_paging.asm -o build/03_paging.bin || return 1
    make_image build/03.img build/stage1.bin build/03_paging.bin
    run_qemu build/03.img build/03.log
    cat build/03.log
    check build/03.log "Paging enabled" "high[0xC0000000]=" "read back OK"
}

build_04() {
    echo "===== 04_long64（长模式：完整 16→32→64 引导链）====="
    nasm -f bin stage1.asm -o build/stage1.bin || return 1
    nasm -f bin 04_long64.asm -o build/04_long64.bin || return 1
    make_image build/04.img build/stage1.bin build/04_long64.bin
    run_qemu build/04.img build/04.log
    cat build/04.log
    check build/04.log "Hello from 64-bit long mode!" "RAX=123456789ABCDEF0"
}

# ------------------------------------------------------------
case "${1:-all}" in
    01) build_01 ;;
    02) build_02 ;;
    03) build_03 ;;
    04) build_04 ;;
    all)
        rc=0
        for n in 01 02 03 04; do
            if ! build_$n; then rc=1; fi
        done
        [ $rc -eq 0 ] && echo "== 全部引导示例验证通过 ==" || echo "== 有示例失败 =="
        exit $rc
        ;;
    *) echo "用法: $0 [01|02|03|04|all]"; exit 1 ;;
esac
