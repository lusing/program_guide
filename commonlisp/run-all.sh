#!/usr/bin/env bash
# ============================================================
# commonlisp/run-all.sh — macOS / Linux 入口（双实现通道）
#
# 逐个运行 examples/NN_topic/main.lisp，通道按示例头部声明：
#   ;; channel: both  → SBCL 与 CLISP 各跑一遍，且两个通道的
#                       stdout 必须**逐字节一致**（可移植性证明）
#   ;; channel: sbcl  → 仅 SBCL（SBCL 专属扩展章：线程/FFI/性能/ASDF）
#
# 每个通道按四条标准判定：
#   1. 退出码为 0
#   2. stderr 为空
#   3. stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）
#   4. stdout 里有结束标记 ==== NN 结束 ====
# both 通道加第 5 条：SBCL 与 CLISP 的 stdout 逐字节一致。
#
# 用法：
#   ./run-all.sh                 跑全部
#   ./run-all.sh 09 10           只跑编号 09、10
#   SBCL=/path/to/sbcl ./run-all.sh
#   CLISP=/path/to/clisp ./run-all.sh
#
# 两个入口（run-all.sh / build.ps1）不要并行跑：共用 build/ 产物目录。
# ============================================================
set -u

cd "$(dirname "$0")"
ROOT=$PWD
BUILD=$ROOT/build

# ---------- 工具链解析：环境变量 → 常见安装位置 → PATH ----------
resolve_sbcl() {
    if [ -n "${SBCL:-}" ] && [ -x "$SBCL" ]; then printf '%s' "$SBCL"; return; fi
    for c in /opt/local/bin/sbcl /opt/homebrew/bin/sbcl /usr/local/bin/sbcl; do
        [ -x "$c" ] && { printf '%s' "$c"; return; }
    done
    command -v sbcl 2>/dev/null || printf ''
}

resolve_clisp() {
    if [ -n "${CLISP:-}" ] && [ -x "$CLISP" ]; then printf '%s' "$CLISP"; return; fi
    for c in /opt/local/bin/clisp /opt/homebrew/bin/clisp /usr/local/bin/clisp; do
        [ -x "$c" ] && { printf '%s' "$c"; return; }
    done
    command -v clisp 2>/dev/null || printf ''
}

SBCL_BIN=$(resolve_sbcl)
CLISP_BIN=$(resolve_clisp)

# ---------- 判定辅助 ----------
# 第 3 条：stdout 里混进 0..31 里除 TAB/LF/CR 之外的字节。
#   LC_ALL=C 必须带：UTF-8 locale 下 tr 会做多字节校验，遇到非法
#   UTF-8（并发打印可能拆开多字节字符）会报错并截断输入 → 误报。
has_ctrl() {
    local n
    n=$(LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null \
        | LC_ALL=C tr -dc '\0-\10\13-\14\16-\37' | wc -c | tr -d ' ')
    [ "${n:-0}" != "0" ]
}

# 第 4 条：结束标记。用 case 字面量匹配，避开 grep 对中文模式的怪癖。
#   LC_ALL=C 同上，防止非法 UTF-8 让 tr 截断后误报「缺标记」。
has_marker() {
    local want="==== $2 结束 ====" text
    text=$(LC_ALL=C tr -d '\000' < "$1" 2>/dev/null)
    case $text in *"$want"*) return 0 ;; *) return 1 ;; esac
}

# ---------- 收集要跑的示例（examples/NN_topic/main.lisp） ----------
all_examples() {
    local d
    for d in "$ROOT"/examples/[0-9][0-9]_*; do
        [ -f "$d/main.lisp" ] && basename "$d"
    done
}

if [ "$#" -gt 0 ]; then
    DIRS=""
    for want in "$@"; do
        match=$(all_examples | grep -E "^${want}" 2>/dev/null | head -1)
        [ -z "$match" ] && { echo "没有匹配 '$want' 的示例。"; exit 1; }
        DIRS="$DIRS $match"
    done
else
    DIRS=$(all_examples)
fi

mkdir -p "$BUILD"

echo "SBCL : ${SBCL_BIN:-未找到}  $( [ -n "$SBCL_BIN" ] && "$SBCL_BIN" --version 2>/dev/null | LC_ALL=C tr -d '\n' )"
echo "CLISP: ${CLISP_BIN:-未找到}  $( [ -n "$CLISP_BIN" ] && "$CLISP_BIN" --version 2>/dev/null | head -1 | LC_ALL=C tr -d '\n' )"
echo "工作目录: $BUILD"
echo

total=0
passed=0
failed=0
failed_list=""

# run_channel <示例名> <NN> <通道 sbcl|clisp>
#   在 build/<示例>.<通道>/ 下运行，stdout/stderr 落盘，打印 通过/失败。
run_channel() {
    local name=$1 nn=$2 ch=$3 src=$ROOT/examples/$name/main.lisp
    local dir out err rc reason
    dir=$BUILD/$name.$ch
    out=$dir/stdout.txt
    err=$dir/stderr.txt

    rm -rf "$dir"
    mkdir -p "$dir"

    # 工作目录切到 build/<示例>.<通道>/：示例里的相对路径读写都落在这里，
    # 不会把临时文件散到源码目录。
    case $ch in
    sbcl)
        # --script 与 --non-interactive 不能连用（文件名会被当成运行时参数）
        ( cd "$dir" && "$SBCL_BIN" --noinform --non-interactive --no-userinit \
            --load "$src" >"$out" 2>"$err" )
        rc=$?
        ;;
    clisp)
        # -E UTF-8：CLISP 默认编码跟随 locale，ASCII locale 下读写中文直接
        # 报「Invalid byte」退出码 1（WSL2/无 LANG 环境即中招），必须显式钉死。
        ( cd "$dir" && "$CLISP_BIN" -q -q -norc -E UTF-8 "$src" >"$out" 2>"$err" )
        rc=$?
        ;;
    esac

    reason=""
    if [ "$rc" -ne 0 ]; then
        reason="退出码 $rc"
    elif [ -s "$err" ]; then
        reason="stderr 非空（$(wc -c < "$err" | tr -d ' ') 字节）"
    elif has_ctrl "$out"; then
        reason="stdout 含控制字符"
    elif ! has_marker "$out" "$nn"; then
        reason="缺少结束标记 ==== $nn 结束 ===="
    fi

    if [ -z "$reason" ]; then
        echo "通过"
        return 0
    fi
    echo "失败 — $reason"
    if [ -s "$err" ]; then
        echo "      --- stderr 尾部 ---"
        tail -12 "$err" | sed 's/^/      /'
    elif [ "$rc" -eq 0 ]; then
        echo "      --- stdout 尾部 ---"
        tail -6 "$out" | sed 's/^/      /'
    fi
    return 1
}

for name in $DIRS; do
    nn=${name%%_*}
    src=$ROOT/examples/$name/main.lisp
    # 通道声明在示例头部：;; channel: both | sbcl（行内可带注释，取第一个词）
    channel=$(grep -m1 -E '^;; *channel:' "$src" | sed -E 's/^;; *channel: *//; s/[[:space:]].*//')

    if [ "$channel" = "sbcl" ]; then
        chans="sbcl"
    else
        chans="sbcl clisp"
    fi

    for ch in $chans; do
        if [ "$ch" = "sbcl" ] && [ -z "$SBCL_BIN" ]; then
            echo "[--] $name.sbcl 跳过（未找到 sbcl）"
            failed=$((failed+1)); failed_list="$failed_list $name.$ch"; continue
        fi
        if [ "$ch" = "clisp" ] && [ -z "$CLISP_BIN" ]; then
            echo "[--] $name.clisp 跳过（未找到 clisp）"
            failed=$((failed+1)); failed_list="$failed_list $name.$ch"; continue
        fi
        total=$((total + 1))
        printf '[%2d] %-30s ' "$total" "$name.$ch"
        if run_channel "$name" "$nn" "$ch"; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
            failed_list="$failed_list $name.$ch"
        fi
    done

    # 第 5 条（仅 channel: both）：两通道 stdout 逐字节一致。
    #   可移植示例的输出必须不依赖实现细节——fixnum 位宽、pi 的浮点格式、
    #   哈希表遍历顺序、宏展开形态都不许漏进输出。
    if [ "$channel" != "sbcl" ] && [ -n "$SBCL_BIN" ] && [ -n "$CLISP_BIN" ]; then
        a=$BUILD/$name.sbcl/stdout.txt
        b=$BUILD/$name.clisp/stdout.txt
        if [ -f "$a" ] && [ -f "$b" ]; then
            if LC_ALL=C cmp -s "$a" "$b"; then
                :
            else
                total=$((total + 1))
                failed=$((failed + 1))
                failed_list="$failed_list $name.xdiff"
                echo "     × 跨通道输出不一致："
                diff "$a" "$b" | head -12 | sed 's/^/       /'
            fi
        fi
    fi
done

echo
echo "通过 $passed   失败 $failed   共 $total"
if [ "$failed" -gt 0 ]; then
    echo "失败项:$failed_list"
    exit 1
fi

# 示例应当自己清理临时文件；这里有残留就提示一下
leftovers=$(find "$BUILD" -type f ! -name 'stdout.txt' ! -name 'stderr.txt' 2>/dev/null | head -20)
if [ -n "$leftovers" ]; then
    echo
    echo "提示：build/ 下有示例留下的临时文件（示例本应自己清理）："
    printf '%s\n' "$leftovers" | sed 's/^/  /'
fi

exit 0
