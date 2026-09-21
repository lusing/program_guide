#!/bin/bash
# ============================================================
# Intel x86-64 汇编编程指南 —— Linux 构建脚本
#
# 用法：
#   ./build-linux.sh -All                  汇编 + 链接 + 运行全部 Linux 示例
#   ./build-linux.sh -Category 01_data_movement
#   ./build-linux.sh -File 01_data_movement/mov_basic.asm
#   ./build-linux.sh -BuildOnly -All       只汇编链接，不运行
#   ./build-linux.sh -Clean                清理 build/linux 目录
#
# 工具链（本机实测）：
#   nasm   3.02        nasm
#   gcc    16.2.1      gcc               （链接器驱动，自动带上 glibc 启动文件）
#   ld     GNU ld 2.47 ld                （纯系统调用程序可直连，不需要 crt1.o）
#
# 判定标准（三条同时满足才算通过）：
#   1) nasm 汇编退出码 0
#   2) 链接退出码 0
#   3) 运行退出码 0，且 stderr 为空
#
# 注意：发行版 gcc 默认生成 PIE，而 NASM 源码使用绝对重定位，
#       所以链接一律加 -no-pie（纯 ld 链接的静态可执行文件天然不是 PIE）。
# ============================================================

set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
EXAMPLES="$ROOT/examples-linux"
BUILD="$ROOT/build/linux"
NASM="${NASM:-nasm}"
GCC="${GCC:-gcc}"
LD="${LD:-ld}"

RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; CYA=$'\033[36m'; RST=$'\033[0m'

# ------------------------------------------------------------
# 编译并运行单个示例
#   返回 0 = 通过，1 = 失败
# ------------------------------------------------------------
build_one() {
    local src="$1"
    local run="${2:-yes}"
    local base
    base="$(basename "$src" .asm)"
    local obj="$BUILD/$base.o"
    local bin="$BUILD/$base"

    echo ""
    echo "${CYA}---------- 构建: $base ----------${RST}"

    # 1) 汇编：-f elf64 生成 Linux 64 位目标文件
    local asmout
    asmout=$("$NASM" -I "$ROOT/lib" -f elf64 "$src" -o "$obj" 2>&1)
    if [ $? -ne 0 ]; then
        echo "${RED}[FAIL] 汇编失败${RST}"
        echo "$asmout" | sed 's/^/    /'
        return 1
    fi
    # nasm 的警告也要当成问题（例如 %warning 触发的提示）
    if [ -n "$asmout" ]; then
        echo "${YEL}[WARN] 汇编器有输出：${RST}"
        echo "$asmout" | sed 's/^/    /'
    fi
    echo "${GRN}[OK]${RST}   nasm -f elf64 -> $base.o"

    # 2) 链接
    #    引用了 libc 符号（extern xxx）时用 gcc 驱动，自动带 crt1.o 和 libc；
    #    完全不依赖库的纯系统调用程序可以直接用 ld 连，入口默认就是 _start。
    #    示例文件里写一行 `; LINK: -lm -lmvec` 就能给链接器加参数。
    local extra=""
    extra="$(sed -n 's/^; *LINK: *//p' "$src" | head -1)"

    local linkout linkrc
    # [[:space:]] 而不是 \s：\s 是 GNU 扩展，BSD grep（macOS）不认，
    # 换成 [[:space:]] 两边都能匹配（万一有人在 macOS 上跑这个脚本也不会全走 ld 分支）。
    if [ -n "$extra" ] || grep -qE '^[[:space:]]*extern[[:space:]]' "$src"; then
        linkout=$("$GCC" -no-pie "$obj" -o "$bin" $extra 2>&1)
        linkrc=$?
        local how="gcc -no-pie${extra:+ $extra}"
    else
        linkout=$("$LD" "$obj" -o "$bin" 2>&1)
        linkrc=$?
        how="ld（纯系统调用程序，默认入口 _start）"
    fi
    if [ $linkrc -ne 0 ]; then
        echo "${RED}[FAIL] 链接失败 ($how)${RST}"
        echo "$linkout" | sed 's/^/    /'
        return 1
    fi
    echo "${GRN}[OK]${RST}   $how -> $base"

    if [ "$run" != "yes" ]; then
        return 0
    fi

    # 3) 运行：退出码 0 且 stderr 为空
    local out err rc
    out=$("$bin" 2>"$BUILD/$base.err")
    rc=$?
    err="$(cat "$BUILD/$base.err")"
    [ -n "$out" ] && echo "$out"
    if [ $rc -ne 0 ]; then
        echo "${RED}[FAIL] 运行退出码 $rc${RST}"
        [ -n "$err" ] && echo "$err" | sed 's/^/    /'
        return 1
    fi
    if [ -n "$err" ]; then
        echo "${RED}[FAIL] stderr 非空：${RST}"
        echo "$err" | sed 's/^/    /'
        return 1
    fi
    echo "${GRN}[OK]${RST}   运行退出码 0，stderr 为空"
    return 0
}

# ------------------------------------------------------------
# 遍历一个目录（类别）下的全部示例
# ------------------------------------------------------------
DIR_TOTAL=0; DIR_PASS=0; DIR_FAIL=0

build_dir() {
    local dir="$1"
    local run="${2:-yes}"
    local f
    DIR_TOTAL=0; DIR_PASS=0; DIR_FAIL=0
    for f in "$dir"/*.asm; do
        [ -e "$f" ] || continue
        DIR_TOTAL=$((DIR_TOTAL + 1))
        if build_one "$f" "$run"; then
            DIR_PASS=$((DIR_PASS + 1))
        else
            DIR_FAIL=$((DIR_FAIL + 1))
        fi
    done
}

MODE=""; CATEGORY=""; FILE=""; RUN="yes"

while [ $# -gt 0 ]; do
    case "$1" in
        -All)        MODE="all" ;;
        -Category)   MODE="category"; CATEGORY="$2"; shift ;;
        -File)       MODE="file"; FILE="$2"; shift ;;
        -BuildOnly)  RUN="no" ;;
        -Clean)      MODE="clean" ;;
        -h|--help)   MODE="help" ;;
        *) echo "未知参数：$1"; MODE="help" ;;
    esac
    shift
done

mkdir -p "$BUILD"

TOTAL=0; PASS=0; FAIL=0

case "$MODE" in
    clean)
        rm -rf "$BUILD"
        echo "已清理 $BUILD"
        ;;
    file)
        # 允许只写文件名，也允许写完整相对路径
        src="$FILE"
        case "$src" in
            *.asm) ;;
            *) src="$FILE.asm" ;;
        esac
        if [ ! -f "$src" ]; then
            found="$(find "$EXAMPLES" -name "$(basename "$src")" | head -1)"
            [ -n "$found" ] && src="$found"
        fi
        if [ ! -f "$src" ]; then
            echo "${RED}找不到示例：$FILE${RST}"
            exit 1
        fi
        build_one "$src" "$RUN" || exit 1
        ;;
    category)
        dir="$EXAMPLES/$CATEGORY"
        if [ ! -d "$dir" ]; then
            echo "${RED}找不到类别：$CATEGORY${RST}"
            echo "可用类别："
            ls "$EXAMPLES"
            exit 1
        fi
        build_dir "$dir" "$RUN"
        TOTAL=$((TOTAL + DIR_TOTAL)); PASS=$((PASS + DIR_PASS)); FAIL=$((FAIL + DIR_FAIL))
        ;;
    all)
        for dir in "$EXAMPLES"/*/; do
            echo ""
            echo "${CYA}================ $(basename "$dir") ================${RST}"
            build_dir "$dir" "$RUN"
            TOTAL=$((TOTAL + DIR_TOTAL)); PASS=$((PASS + DIR_PASS)); FAIL=$((FAIL + DIR_FAIL))
        done
        ;;
    *)
        echo "Intel x86-64 汇编编程指南 —— Linux 构建脚本"
        echo ""
        echo "用法:"
        echo "  ./build-linux.sh -All                             构建并运行全部示例"
        echo "  ./build-linux.sh -Category 01_data_movement       构建指定类别"
        echo "  ./build-linux.sh -File 01_data_movement/lea.asm   构建单个示例"
        echo "  ./build-linux.sh -BuildOnly -All                  只构建不运行"
        echo "  ./build-linux.sh -Clean                           清理构建产物"
        echo ""
        echo "可用类别:"
        ls "$EXAMPLES" | sed 's/^/  /'
        exit 0
        ;;
esac

if [ "$MODE" = "all" ] || [ "$MODE" = "category" ]; then
    echo ""
    echo "=========================================="
    if [ "$FAIL" -eq 0 ]; then
        echo "${GRN}  构建汇总: 总计 $TOTAL 个, 通过 $PASS 个, 失败 $FAIL 个${RST}"
    else
        echo "${RED}  构建汇总: 总计 $TOTAL 个, 通过 $PASS 个, 失败 $FAIL 个${RST}"
    fi
    echo "=========================================="
    [ "$FAIL" -eq 0 ] || exit 1
fi
