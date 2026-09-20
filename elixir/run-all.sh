#!/bin/bash
# ============================================================
# Elixir 教程统一验证脚本（shell 入口）
#
# 与 build.ps1 完全等价的五层验证，两条入口必须给出同样的结论：
#   1) mix format --check-formatted       格式（2 空格，见各示例 .formatter.exs）
#   2) mix compile --warnings-as-errors   编译零告警（未用变量、影子变量都算）
#   3) mix test                           ExUnit 测试全绿
#   4) mix run --no-compile run.exs       真的跑一遍 + 四条判定
#   5) ERL_FLAGS="+S 1:1" 重跑            stdout 与通道 A 逐字节一致
#
# 第 4 层的四条判定（沿用本仓库标准）：
#   · 退出码 0
#   · stderr 为空 —— 抓「编译告警只在 stderr 露头」的毛病
#     （例外见 STDERR_ALLOW：有示例故意往 stderr 写东西）
#   · stdout 非空 —— 抓「根本没执行到业务代码、退出码却仍是 0」的假阳性
#   · stdout 含结束标记 `==== NN 结束 ====` —— BEAM 里进程崩了退出码
#     仍可能是 0，标记是「跑到底了」的铁证
#
# 第 5 层为什么重要：BEAM 是多调度器的，map 迭代顺序、并发任务的完成
# 顺序、pid 编号都可能随调度而变。钉成单调度器（+S 1:1）重跑一遍，
# 输出还必须逐字节一致 —— 这条逼着示例「断言性质」而不是「打印环境
# 相关的数字」，也正是本教程写作纪律的技术保障。
#
# 用法：
#   ./run-all.sh              验证 examples 下全部示例
#   ./run-all.sh 12_processes 验证单个示例
#   ./run-all.sh --clean      清理全部产物
#
# 工具链定位：MIX 环境变量 → PATH 里的 mix。
# ============================================================
set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT" || exit 1

BUILD_DIR="$PROJECT_ROOT/build"
EXAMPLES_DIR="$PROJECT_ROOT/examples"

# 故意往 stderr 写内容的示例 —— 「stderr 为空」对它们不适用：
#   11_errors  演示 Logger.error 与异常栈（就是要教 stdout / stderr 之别）
#   22_mix     演示 mix release 前把告警打到 stderr 的构建脚本
STDERR_ALLOW="11_errors"

# 允许双通道输出不一致的示例 —— 一律要写清理由：
#   （默认空。示例应当设计成确定性的；确有不可能的，登记在此并注明原因）
DETERMINISM_ALLOW=""

# ---- 工具链定位 ----
MIX_BIN="${MIX:-}"
if [ -z "$MIX_BIN" ]; then
    MIX_BIN="$(command -v mix 2>/dev/null || true)"
fi
if [ -z "$MIX_BIN" ] || [ ! -x "$MIX_BIN" ]; then
    echo "未找到 mix：请先安装 Elixir（本教程按 1.20.2 / OTP 29 实测），" >&2
    echo "或设 MIX=/path/to/mix 再跑。" >&2
    exit 1
fi
PATH="$(dirname "$MIX_BIN"):$PATH"
export PATH

mkdir -p "$BUILD_DIR"

# ---- 判定函数（一律用退出码，别用「数出来的数」比大小）----
# 处理「待验证输出」的 tr/grep 必须 LC_ALL=C：UTF-8 locale 下某些 tr
# 碰到非法 UTF-8 会报 Illegal byte sequence 并在那里截断输入。
has_ctrl() {
    LC_ALL=C tr -d '\11\12\15' <"$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

is_empty() { [ ! -s "$1" ]; }

in_list() {
    local needle="$1" n
    shift
    for n in $*; do [ "$n" = "$needle" ] && return 0; done
    return 1
}

PASS=0
FAIL=0
FAILED_NAMES=""

# ---- 单个示例的五层验证 ----
check_example() {
    local dir="$1"
    local name
    name="$(basename "$dir")"
    local nn="${name%%_*}"
    local marker="==== ${nn} 结束 ===="

    local compileout="$BUILD_DIR/$name.compile.out"
    local testout="$BUILD_DIR/$name.test.out"
    local err="$BUILD_DIR/$name.err"
    local runout="$BUILD_DIR/$name.run.out"
    local runout2="$BUILD_DIR/$name.run.S1.out"
    local reasons=""

    # 截断而不是删除：某些环境里 rm 会被静默拦掉，截断一定生效
    : >"$compileout"; : >"$testout"; : >"$err"; : >"$runout"; : >"$runout2"

    printf '\n[Example] %s\n' "$name"

    # 产物集中到 build/<示例名>/，示例目录保持干净
    export MIX_BUILD_ROOT="$BUILD_DIR/$name"
    export MIX_ENV=dev

    # 第 1 层：格式
    ( cd "$dir" && "$MIX_BIN" format --check-formatted ) >>"$compileout" 2>>"$err"
    [ $? -ne 0 ] && reasons="${reasons}format 未通过; "

    # 第 2 层：编译零告警
    ( cd "$dir" && "$MIX_BIN" compile --warnings-as-errors --force ) >>"$compileout" 2>>"$err"
    [ $? -ne 0 ] && reasons="${reasons}编译有告警; "

    # 第 3 层：测试
    ( cd "$dir" && "$MIX_BIN" test --color ) >>"$testout" 2>>"$err"
    [ $? -ne 0 ] && reasons="${reasons}测试未通过; "

    # 第 4 层：运行 + 四条判定（通道 A）
    ( cd "$dir" && "$MIX_BIN" run --no-compile run.exs ) >"$runout" 2>>"$err"
    local run_code=$?
    [ $run_code -ne 0 ] && reasons="${reasons}运行退出码 ${run_code}; "

    if ! in_list "$name" $STDERR_ALLOW && ! is_empty "$err"; then
        reasons="${reasons}stderr 非空（有告警）; "
    fi
    if is_empty "$runout"; then
        reasons="${reasons}stdout 为空（没真跑起来）; "
    fi
    if has_ctrl "$runout"; then
        reasons="${reasons}stdout 含控制字符; "
    fi
    if ! LC_ALL=C grep -qF "$marker" "$runout"; then
        reasons="${reasons}缺结束标记「${marker}」; "
    fi

    # 第 5 层：单调度器重跑，stdout 必须逐字节一致（通道 B）
    ( cd "$dir" && ERL_FLAGS="+S 1:1" "$MIX_BIN" run --no-compile run.exs ) >"$runout2" 2>>"$err"
    if ! in_list "$name" $DETERMINISM_ALLOW; then
        if ! cmp -s "$runout" "$runout2"; then
            reasons="${reasons}双通道输出不一致（+S 1:1）; "
        fi
    fi

    # 示例输出照常打出来（教程用法：读讲解 → 跑示例 → 改代码再跑）
    [ -s "$runout" ] && cat "$runout"

    unset MIX_BUILD_ROOT MIX_ENV

    if [ -n "$reasons" ]; then
        printf '[FAIL] %s：%s\n' "$name" "$reasons"
        [ -s "$err" ] && { printf -- '---- %s 的 stderr ----\n' "$name"; head -30 "$err"; printf -- '----------------------\n'; }
        if ! cmp -s "$runout" "$runout2"; then
            printf -- '---- %s 的双通道差异 ----\n' "$name"
            diff "$runout" "$runout2" | head -20
            printf -- '------------------------\n'
        fi
        FAIL=$((FAIL + 1))
        FAILED_NAMES="$FAILED_NAMES $name"
        return 1
    fi
    printf '[OK] %s 五层验证通过\n' "$name"
    PASS=$((PASS + 1))
    return 0
}

# ---- --clean ----
if [ "${1:-}" = "--clean" ] || [ "${1:-}" = "-c" ]; then
    if [ -d "$BUILD_DIR" ]; then
        find "$BUILD_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
        echo "[Clean] 已清理 build/ 下全部产物。"
    else
        echo "[Clean] build/ 不存在，无需清理。"
    fi
    exit 0
fi

# ---- 单个示例 ----
if [ $# -ge 1 ]; then
    if [ ! -d "$EXAMPLES_DIR/$1" ]; then
        echo "找不到示例目录: $EXAMPLES_DIR/$1" >&2
        exit 1
    fi
    check_example "$EXAMPLES_DIR/$1"
    echo
    if [ $FAIL -eq 0 ]; then
        echo "[Done] $1 五层验证通过。"
        exit 0
    fi
    echo "[Done] $1 验证失败。" >&2
    exit 1
fi

# ---- 全量 ----
for d in "$EXAMPLES_DIR"/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    name="$(basename "$d")"
    case "$name" in
        [0-9][0-9]*) [ -f "$d/mix.exs" ] && check_example "$d" || echo "[skip] $name 不是 mix 工程" ;;
        *) echo "[skip] 非示例目录：$name" ;;
    esac
done

echo
echo "通过 $PASS   失败 $FAIL   共 $((PASS + FAIL))"
if [ $FAIL -ne 0 ]; then
    echo "失败项：$FAILED_NAMES" >&2
    exit 1
fi
echo "[Done] 全部示例五层验证通过（format + 零告警 + test + 运行 + 双通道一致）。"
