#!/usr/bin/env bash
# ============================================================
# run-all.sh —— 用 Ruby 跑遍所有示例（shell 版，等价于 build.ps1）
#
#   ./run-all.sh            只打印每条通道的通过/失败摘要
#   ./run-all.sh -v         附带每个示例的完整输出
#   ./run-all.sh 03 21      只跑指定编号（两位数字或目录名均可）
#
# 两层验证（与 build.ps1 完全一致）：
#   * 运行层：ruby main.rb                  —— exit 0 + 结束标记
#   * 测试层：ruby runtests.rb（minitest）  —— exit 0（有断言失败时 minitest 以非 0 退出）
#
# 运行层判定标准（六条，两个入口共用）：
#   1. 退出码为 0
#   2. stderr 为空（Ruby 的 warning/异常回溯都走 stderr —— 这一条等价于「零告警」；
#      示例若**故意**触发诊断（如 21_ractors 的实验特性告警），由示例自己
#      用 Warning[:experimental] = false / $VERBOSE = nil 圈起来，
#      判定标准不为任何示例放宽）
#   3. stdout 非空（只判退出码会漏掉「进程根本没执行到业务代码」的假阳性）
#   4. stdout 里没有多余控制字符（TAB/LF/CR 除外）
#   5. stdout 里有结束标记 "==== NN 结束 ===="
#   6. stdout 里没有 Ruby 的诊断字样兜底（行首 error/warning、Traceback、
#      独词 Error —— 示例演示异常时打印的是「中文句子 + 异常类名」，
#      ZeroDivisionError 这种 CamelCase 词不会被误伤；见 dump_rule_6）
#
#   判定函数处理「待验证输出」时一律带 LC_ALL=C：本机的 tr/grep 是 BSD 系，
#   UTF-8 locale 下碰到非法字节会报 Illegal byte sequence 并截断输入，
#   结束标记若在截断点之后就会误报「缺少结束标记」。
# ============================================================

set -u
cd "$(dirname "$0")"

VERBOSE=0
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        *) SELECT+=("$arg") ;;
    esac
done

# ------------------------------------------------------------
# 工具链定位：环境变量 RUBY 优先，其次常见安装位置，最后退回 PATH。
# 别硬编码某一台机器的路径 —— 教程目录要能在 Windows/macOS/Linux 上都跑。
# 注意：刻意不选 ruby1.8（2013 年的 1.8.7，缺 99% 的现代语法），
# 本教程主线是 Ruby 4.x；老版本只作为「演进史」在 01 章里提。
# ------------------------------------------------------------
resolve_tool() {
    local envval="$1"; shift
    local c
    if [ -n "$envval" ]; then
        printf '%s' "$envval"
        return
    fi
    for c in "$@"; do
        if command -v "$c" >/dev/null 2>&1; then
            command -v "$c"
            return
        fi
    done
    printf ''
}

RUBY=$(resolve_tool "${RUBY:-}" \
    ruby4.0 \
    ruby \
    /opt/local/bin/ruby4.0 \
    /opt/local/bin/ruby \
    /opt/homebrew/bin/ruby \
    /usr/local/bin/ruby)

if [ -z "$RUBY" ]; then
    echo "未找到 ruby（可设 RUBY=/path/to/ruby，或确认它在 PATH 上）"
    exit 1
fi
echo "ruby     : $RUBY"
"$RUBY" --version
echo

BUILD_DIR="build"
# 不清目录：build/ 里只有上一轮的 stdout/stderr 快照，直接覆盖即可。
mkdir -p "$BUILD_DIR"

PASS=0
FAIL=0
FAILED_LIST=()

# ------------------------------------------------------------
# 判定函数：只依赖退出码 / 存在性，不依赖被捕获的文本内容。
# 把子进程 stdout 抓进 $(...) 再比较字符串，会被任何往管道里插话的东西污染。
# ------------------------------------------------------------
has_ctrl() {   # 0..31 里除 TAB(09)/LF(10)/CR(13)（八进制）
    LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

has_diag() {   # Ruby 诊断字样兜底（判据是组合，防误伤）：
    #   a) 行首 error/warning/Traceback（未捕获异常的第一行 / warning 前缀）
    #   b) 独词 Error（前后不是字母数字下划线）—— 拦「Error: xxx」，
    #      不误伤 ZeroDivisionError 这种 CamelCase 异常类名（演示输出合法含它）
    LC_ALL=C grep -Eq '^(error|warning|Traceback)|(^|[^A-Za-z0-9_])Error([^A-Za-z0-9_]|$)' "$1"
}

# ------------------------------------------------------------
# 主循环：examples/ 下两位数字开头的目录，章号 = 目录号
# ------------------------------------------------------------
run_one() {
    local dir="$1"
    local nn="${dir%%_*}"
    local out="$BUILD_DIR/${nn}.out"
    local err="$BUILD_DIR/${nn}.err"
    local tst="$BUILD_DIR/${nn}.test"
    local rc_out rc_test reasons=""

    "$RUBY" "examples/$dir/main.rb" >"$out" 2>"$err"
    rc_out=$?
    "$RUBY" "examples/$dir/runtests.rb" >"$tst" 2>"$err.test"
    rc_test=$?

    [ $rc_out  -eq 0 ]            || reasons="$reasons 退出码=$rc_out"
    [ ! -s "$err" ]               || reasons="$reasons stderr非空"
    [ -s "$out" ]                 || reasons="$reasons stdout空"
    has_ctrl "$out"               && reasons="$reasons 控制字符"
    LC_ALL=C grep -q "==== $nn 结束 ====" "$out" || reasons="$reasons 缺结束标记"
    has_diag "$out"               && reasons="$reasons 诊断字样"
    [ $rc_test -eq 0 ]            || reasons="$reasons 测试层rc=$rc_test"

    if [ -z "$reasons" ]; then
        PASS=$((PASS + 1))
        printf '  ✓ %s\n' "$dir"
        [ $VERBOSE -eq 1 ] && cat "$out"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$dir:$reasons")
        printf '  ✗ %s —%s\n' "$dir" "$reasons"
        [ $VERBOSE -eq 1 ] && { echo '--- stdout ---'; cat "$out"; echo '--- stderr ---'; cat "$err"; }
    fi
}

# ------------------------------------------------------------
# 选例：无参数 = 全部；参数 = 两位数字或目录名
# ------------------------------------------------------------
ALL_DIRS=$(ls -d examples/[0-9][0-9]_* 2>/dev/null | sed 's|examples/||' | sort)
if [ ${#SELECT[@]} -eq 0 ]; then
    for d in $ALL_DIRS; do run_one "$d"; done
else
    for sel in "${SELECT[@]}"; do
        hit=""
        for d in $ALL_DIRS; do
            case "$d" in
                "$sel"_*|"$sel") hit="$d"; break ;;
            esac
        done
        if [ -z "$hit" ]; then
            echo "没有匹配「$sel」的示例目录"
            FAIL=$((FAIL + 1))
        else
            run_one "$hit"
        fi
    done
fi

echo
echo "=========================================="
echo "通过 $PASS / $((PASS + FAIL))"
if [ $FAIL -gt 0 ]; then
    echo "失败清单："
    for f in "${FAILED_LIST[@]}"; do echo "  $f"; done
    exit 1
fi
exit 0
