#!/usr/bin/env bash
# ============================================================
# sbcl/run-all.sh — macOS / Linux 入口
#
# 运行 examples 里的全部 SBCL 示例，并按四条标准判定：
#   1. 退出码为 0
#   2. stderr 为空
#   3. stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）
#   4. stdout 里有结束标记 ==== NN 结束 ====
#
# 用法：
#   ./run-all.sh                 跑全部
#   ./run-all.sh 09 10           只跑编号 09、10
#   SBCL=/path/to/sbcl ./run-all.sh
# ============================================================
set -u

cd "$(dirname "$0")"
ROOT=$PWD
BUILD=$ROOT/build

# ---------- 工具链解析：环境变量 → MacPorts/Homebrew → PATH ----------
resolve_sbcl() {
    if [ -n "${SBCL:-}" ] && [ -x "$SBCL" ]; then printf '%s' "$SBCL"; return; fi
    for c in /opt/local/bin/sbcl /opt/homebrew/bin/sbcl /usr/local/bin/sbcl; do
        [ -x "$c" ] && { printf '%s' "$c"; return; }
    done
    command -v sbcl 2>/dev/null || printf ''
}

SBCL_BIN=$(resolve_sbcl)
if [ -z "$SBCL_BIN" ]; then
    echo "找不到 sbcl。请安装（MacPorts: port install sbcl），"
    echo "或用 SBCL=/path/to/sbcl ./run-all.sh 指定路径。"
    exit 1
fi

# ---------- 判定辅助 ----------
# 第 3 条：stdout 里混进 0..31 里除 TAB/LF/CR 之外的字节
#   注意必须用 LC_ALL=C，否则多字节字符会被按字符类切碎误报
has_ctrl() {
    local n
    n=$(LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null \
        | LC_ALL=C tr -dc '\0-\10\13-\14\16-\37' | wc -c | tr -d ' ')
    [ "${n:-0}" != "0" ]
}

# 第 4 条：结束标记。
#   这里刻意不用 grep —— 本机 bash 里的 grep 是 toybox，对中文模式会静默失配；
#   case 的引号模式是字面量匹配，且不受这方面影响。
#
#   LC_ALL=C 不能省！在 UTF-8 locale 下 toybox 的 tr 会做多字节校验，
#   碰到非法 UTF-8（多线程并发打印会把一个汉字的字节拆开，详见
#   12-threads.lisp 的说明）就报 "tr: Illegal byte sequence" 并在那里
#   **截断输入**，标记若在截断点之后就查不到 → 误报「缺结束标记」。
#   LC_ALL=C 让 tr 退化成按字节处理，不做校验，也就不可能失败。
has_marker() {
    local want="==== $2 结束 ====" text
    text=$(LC_ALL=C tr -d '\000' < "$1" 2>/dev/null)
    case $text in *"$want"*) return 0 ;; *) return 1 ;; esac
}

# ---------- 收集要跑的示例 ----------
all_examples() {
    local f
    for f in "$ROOT"/[0-9][0-9]-*.lisp; do
        [ -f "$f" ] && basename "$f"
    done
}

if [ "$#" -gt 0 ]; then
    FILES=""
    for want in "$@"; do
        match=$(all_examples | grep -E "^${want}" 2>/dev/null | head -1)
        [ -z "$match" ] && { echo "没有匹配 '$want' 的示例。"; exit 1; }
        FILES="$FILES $match"
    done
else
    FILES=$(all_examples)
fi

mkdir -p "$BUILD"

echo "SBCL: $SBCL_BIN  ($("$SBCL_BIN" --version 2>/dev/null | LC_ALL=C tr -d '\n'))"
echo "工作目录: $BUILD"
echo

total=0
passed=0
failed=0
failed_list=""

for name in $FILES; do
    nn=${name%%-*}
    src=$ROOT/$name
    dir=$BUILD/${name%.lisp}
    out=$dir/stdout.txt
    err=$dir/stderr.txt

    rm -rf "$dir"
    mkdir -p "$dir"

    total=$((total + 1))
    printf '[%2d] %-34s ' "$total" "$name"

    # 工作目录切到 build/<示例>/，示例里的相对路径读写都落在这里，
    # 不会把临时文件散到源码目录。--script 与 --non-interactive 不能混用：
    # 那样写会把文件名当成运行时参数，脚本根本不执行。
    ( cd "$dir" && "$SBCL_BIN" --noinform --non-interactive --no-userinit \
        --load "$src" >"$out" 2>"$err" )
    rc=$?

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
        passed=$((passed + 1))
        echo "通过"
    else
        failed=$((failed + 1))
        failed_list="$failed_list $name"
        echo "失败 — $reason"
        # 失败时把诊断打出来，别让人再去翻文件
        if [ -s "$err" ]; then
            echo "      --- stderr 尾部 ---"
            tail -12 "$err" | sed 's/^/      /'
        fi
        if [ "$rc" -eq 0 ] && [ ! -s "$err" ]; then
            echo "      --- stdout 尾部 ---"
            tail -6 "$out" | sed 's/^/      /'
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
leftovers=$(find "$BUILD" -type f ! -name 'stdout.txt' ! -name 'stderr.txt' | head -20)
if [ -n "$leftovers" ]; then
    echo
    echo "提示：build/ 下有示例留下的临时文件（示例本应自己清理）："
    printf '%s\n' "$leftovers" | sed 's/^/  /'
fi

exit 0
