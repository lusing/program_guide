#!/bin/bash
# ============================================================
# Rust 教程统一验证脚本（shell 入口）
#
# 与 build.ps1 完全等价的四层验证，两条通道必须给出同样的结论：
#   1) cargo fmt --check      格式
#   2) cargo clippy -D warnings  零告警（含 clippy lint）
#   3) cargo test             单元/集成/文档测试
#   4) cargo run              真的跑一遍，退出码 0
#
# 外加三条运行期断言（沿用本仓库的验证判定标准）：
#   · stderr 为空 —— 抓「编译/链接告警」这类只在 stderr 露头的毛病
#     （例外见 STDERR_ALLOW：有示例故意往 stderr 写东西）
#   · stdout 非空 —— 抓「进程根本没执行到业务代码、退出码却仍是 0」的假阳性
#   · stdout 无多余控制字符（0..31 除 TAB/LF/CR）
#
# 用法：
#   ./run-all.sh              验证 examples 下全部示例
#   ./run-all.sh 12_traits    验证单个示例
#   ./run-all.sh --clean      清理全部 target 目录
#
# 本目录不用「结束标记」那条判定：示例是 cargo 工程，panic 会让退出码非 0，
# 而「stderr 为空」已经能抓住中途失败，再加标记是重复。
# ============================================================
set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT" || exit 1

BUILD_DIR="$PROJECT_ROOT/build"
EXAMPLES_DIR="$PROJECT_ROOT/examples"

# 故意往 stderr 写内容的示例 —— 「stderr 为空」对它们不适用：
#   02_hello   演示 eprintln!（就是教你区分 stdout / stderr）
#   22_threads 演示锁中毒，必须真的 panic 一次
STDERR_ALLOW="02_hello 22_threads"

# ---- 工具链定位：CARGO 环境变量 → PATH ----
CARGO_BIN="${CARGO:-}"
if [ -z "$CARGO_BIN" ]; then
    CARGO_BIN="$(command -v cargo 2>/dev/null || true)"
fi
if [ -z "$CARGO_BIN" ] || [ ! -x "$CARGO_BIN" ]; then
    echo "未找到 cargo：请先安装 Rust（edition 2024 需 1.85+，本教程按 1.98.1 实测），" >&2
    echo "或设 CARGO=/path/to/cargo 再跑。" >&2
    exit 1
fi
PATH="$(dirname "$CARGO_BIN"):$PATH"
export PATH

mkdir -p "$BUILD_DIR"

# ---- 判定函数（一律用退出码，别用「数出来的数」比大小）----
# 处理「待验证输出」的 tr/grep 必须 LC_ALL=C：UTF-8 locale 下 toybox 的 tr
# 碰到非法 UTF-8 会报 Illegal byte sequence 并在那里截断输入。
has_ctrl() {
    LC_ALL=C tr -d '\11\12\15' <"$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

is_empty() { [ ! -s "$1" ]; }

stderr_allowed() {
    local n
    for n in $STDERR_ALLOW; do [ "$n" = "$1" ] && return 0; done
    return 1
}

PASS=0
FAIL=0
FAILED_NAMES=""

# ---- 单个示例的四层验证 ----
check_example() {
    local dir="$1"
    local name
    name="$(basename "$dir")"
    local out="$BUILD_DIR/$name.out"
    local err="$BUILD_DIR/$name.err"
    local runout="$BUILD_DIR/$name.run.out"
    local reasons=""

    # 截断而不是删除：某些环境里 rm 会被静默拦掉，截断一定生效
    : >"$out"; : >"$err"; : >"$runout"

    printf '\n[Example] %s\n' "$name"

    ( cd "$dir" && cargo fmt --check ) >>"$out" 2>>"$err"
    [ $? -ne 0 ] && reasons="${reasons}fmt 未通过; "

    ( cd "$dir" && cargo clippy --quiet --all-targets -- -D warnings ) >>"$out" 2>>"$err"
    [ $? -ne 0 ] && reasons="${reasons}clippy 有告警; "

    ( cd "$dir" && cargo test --quiet ) >>"$out" 2>>"$err"
    [ $? -ne 0 ] && reasons="${reasons}测试未通过; "

    ( cd "$dir" && cargo run --quiet ) >"$runout" 2>>"$err"
    local run_code=$?
    [ $run_code -ne 0 ] && reasons="${reasons}运行退出码 ${run_code}; "

    # ---- 运行期三条断言 ----
    if ! stderr_allowed "$name" && ! is_empty "$err"; then
        reasons="${reasons}stderr 非空（有告警）; "
    fi
    if is_empty "$runout"; then
        reasons="${reasons}stdout 为空（没真跑起来）; "
    fi
    if has_ctrl "$runout"; then
        reasons="${reasons}stdout 含控制字符; "
    fi

    # 示例输出照常打出来（教程用法：改代码 → 重跑 → 看输出）
    [ -s "$runout" ] && cat "$runout"

    if [ -n "$reasons" ]; then
        printf '[FAIL] %s：%s\n' "$name" "$reasons"
        [ -s "$err" ] && { printf -- '---- %s 的 stderr ----\n' "$name"; head -20 "$err"; printf -- '----------------------\n'; }
        FAIL=$((FAIL + 1))
        FAILED_NAMES="$FAILED_NAMES $name"
        return 1
    fi
    printf '[OK] %s 四层验证通过\n' "$name"
    PASS=$((PASS + 1))
    return 0
}

# ---- --clean ----
if [ "${1:-}" = "--clean" ] || [ "${1:-}" = "-c" ]; then
    ( cd "$PROJECT_ROOT" && cargo clean --quiet )
    for d in 17_cargo 24_minigrep; do
        [ -d "$EXAMPLES_DIR/$d" ] && ( cd "$EXAMPLES_DIR/$d" && cargo clean --quiet )
    done
    echo "[Clean] 已清理全部 target 目录。"
    exit 0
fi

# ---- 单个示例 ----
if [ $# -ge 1 ]; then
    if [ ! -d "$EXAMPLES_DIR/$1" ]; then
        echo "找不到示例目录: $EXAMPLES_DIR/$1" >&2
        exit 1
    fi
    check_example "$EXAMPLES_DIR/$1"
    if [ $FAIL -eq 0 ]; then
        echo
        echo "[Done] $1 验证通过。"
        exit 0
    fi
    echo; echo "[Done] $1 验证失败。" >&2
    exit 1
fi

# ---- 全量 ----
# 根 workspace 先做一次 fmt 兜底
( cd "$PROJECT_ROOT" && cargo fmt --check ) >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "根 workspace fmt 未通过（在 rust/ 跑 cargo fmt）" >&2
    exit 1
fi

for d in "$EXAMPLES_DIR"/*/; do
    d="${d%/}"
    name="$(basename "$d")"
    case "$name" in
        [0-9][0-9]*) check_example "$d" ;;
        *) echo "[skip] 非示例目录：$name" ;;
    esac
done

echo
echo "通过 $PASS   失败 $FAIL   共 $((PASS + FAIL))"
if [ $FAIL -ne 0 ]; then
    echo "失败项：$FAILED_NAMES" >&2
    exit 1
fi
echo "[Done] 全部示例四层验证通过（fmt + clippy + test + run）。"
