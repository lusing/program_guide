#!/bin/bash
# ============================================================
# Intel x86-64 汇编编程指南 —— macOS 构建脚本
#
# 用法：
#   ./build-mac.sh -All                  汇编 + 链接 + 运行全部 macOS 示例
#   ./build-mac.sh -Category 01_data_movement
#   ./build-mac.sh -File 01_data_movement/mov_basic.asm
#   ./build-mac.sh -BuildOnly -All       只汇编链接，不运行
#   ./build-mac.sh -Clean                清理 build/mac 目录
#
# 工具链（两套配置都实测通过 56/56）：
#   nasm   3.02           /opt/local/bin/nasm
#   A) macOS 14.8.9 / Intel i7-4770HQ：clang 16.0.0（Apple clang-1600.0.26.6）
#                                      ld64-1115.7.3（Xcode 16 CLT）
#   B) macOS 13.1   / Intel i7-3520M ：clang 14.0.0 / ld64-820.1
#   —— ld64 从 Xcode 15 起把 -macosx_version_min 改名为 -macos_version_min，
#      脚本先试新名字，失败再退回旧名字，两套都能用。
#
# 判定标准（三条同时满足才算通过）：
#   1) nasm 汇编退出码 0
#   2) 链接退出码 0
#   3) 运行退出码 0，且 stderr 为空
# ============================================================

set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
EXAMPLES="$ROOT/examples-macos"
BUILD="$ROOT/build/mac"
NASM="${NASM:-nasm}"
CLANG="${CLANG:-clang}"
LD="${LD:-ld}"

if [ -x /opt/local/bin/nasm ]; then NASM=/opt/local/bin/nasm; fi

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

    # 1) 汇编：-f macho64 生成 macOS 64 位目标文件
    local asmout
    asmout=$("$NASM" -I "$ROOT/lib" -f macho64 "$src" -o "$obj" 2>&1)
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
    echo "${GRN}[OK]${RST}   nasm -f macho64 -> $base.o"

    # 2) 链接
    #    引用了 libc 符号（extern _xxx）时用 clang 驱动，自动带 libSystem；
    #    完全不依赖库的纯系统调用程序可以直接用 ld 连，不需要 -lSystem。
    #    示例文件里写一行 `; LINK: -framework Accelerate` 就能给链接器加参数。
    local extra=""
    extra="$(sed -n 's/^; *LINK: *//p' "$src" | head -1)"

    # 注意：macOS 自带的 grep 是 BSD grep，不认 GNU 的 \s，这里必须写 [[:space:]]。
    # 写成 '^\s*extern _' 的话在所有 macOS 上都匹配不到，于是每个示例都会误走
    # 下面的 ld 直连分支——实测 56 个里 55 个会因此被换掉链接方式。
    local linkout linkrc
    if [ -n "$extra" ] || grep -q '^[[:space:]]*extern[[:space:]]*_' "$src"; then
        linkout=$("$CLANG" -arch x86_64 "$obj" -o "$bin" $extra 2>&1)
        linkrc=$?
        local how="clang -arch x86_64${extra:+ $extra}"
    else
        # macOS 的可执行文件必须是动态链接的，即使一个 libSystem 函数都不调，
        # 也要 -lSystem 把加载信息带上，否则 ld 会报
        # "dynamic executables or dylibs must link with libSystem.dylib"
        local sdk
        sdk="$(xcrun --show-sdk-path 2>/dev/null)"
        linkout=$("$LD" -arch x86_64 -macos_version_min 11.0 -e _main "$obj" -o "$bin" \
                        -lSystem -syslibroot "$sdk" -L"$sdk/usr/lib" 2>&1)
        linkrc=$?
        if [ "$linkrc" -ne 0 ]; then
            # 旧版 ld64 只认 -macosx_version_min（新名字从 Xcode 15 起才有）
            linkout=$("$LD" -arch x86_64 -macosx_version_min 11.0 -e _main "$obj" -o "$bin" \
                            -lSystem -syslibroot "$sdk" -L"$sdk/usr/lib" 2>&1)
            linkrc=$?
        fi
        how="ld -arch x86_64 -e _main"
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
        echo "Intel x86-64 汇编编程指南 —— macOS 构建脚本"
        echo ""
        echo "用法:"
        echo "  ./build-mac.sh -All                             构建并运行全部示例"
        echo "  ./build-mac.sh -Category 01_data_movement       构建指定类别"
        echo "  ./build-mac.sh -File 01_data_movement/lea.asm   构建单个示例"
        echo "  ./build-mac.sh -BuildOnly -All                  只构建不运行"
        echo "  ./build-mac.sh -Clean                           清理构建产物"
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
