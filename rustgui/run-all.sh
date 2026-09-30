#!/usr/bin/env bash
# rustgui 教程 POSIX 验证入口（macOS / Linux / WSL 用这个）。
# 与 build.ps1 同一套判定：fmt + clippy + test + build + --selftest（超时、两跑一致）。
# 用法：./run-all.sh            全部示例
#       ./run-all.sh 02_egui_hello   单个示例
#       ./run-all.sh --clean     清理 target
set -u

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

# ---- 工具链定位：CARGO 环境变量优先，其次 PATH ----
CARGO="${CARGO:-cargo}"
if ! command -v "$CARGO" >/dev/null 2>&1; then
    echo "未找到 cargo（CARGO 环境变量或 PATH）" >&2
    exit 1
fi

BUILD_DIR="$PROJECT_ROOT/build"
TARGET_DIR="$PROJECT_ROOT/target"
EXAMPLES_DIR="$PROJECT_ROOT/examples"
SELFTEST_TIMEOUT=60
# 故意往 stderr 写内容的示例（目前无；有例外时在此登记并注明原因）
STDERR_ALLOW=""

mkdir -p "$BUILD_DIR"

if [ "${1:-}" = "--clean" ]; then
    rm -rf "$TARGET_DIR"
    echo "[Clean] 已清理 target 目录。"
    exit 0
fi

has_control_char() {
    # 逐字节找 <0x20 的控制字符（放行 TAB/LF/CR）；LANG=C 按字节语义比较
    LC_ALL=C tr -d '\11\12\15' < "$1" | LC_ALL=C grep -q '[[:cntrl:]]'
}

# ---- 四层验证 ----
verify_example() {
    local dir="$1"
    local name
    name="$(basename "$dir")"
    local pkg="${name#*_}"   # 02_egui_hello → egui_hello
    local out="$BUILD_DIR/$name.out"
    local err="$BUILD_DIR/$name.err"
    local run_out="$BUILD_DIR/$name.run.out"
    local run_out2="$BUILD_DIR/$name.run2.out"
    : > "$out"; : > "$err"; : > "$run_out"; : > "$run_out2"

    local reasons=()
    (
        cd "$dir" || exit 1
        "$CARGO" fmt --check >>"$out" 2>>"$err" || echo "fmt 未通过" >> "$out.fail"
        "$CARGO" clippy --quiet --all-targets -- -D warnings >>"$out" 2>>"$err" || echo "clippy 有告警" >> "$out.fail"
        "$CARGO" test --quiet >>"$out" 2>>"$err" || echo "测试未通过" >> "$out.fail"
        "$CARGO" build --quiet >>"$out" 2>>"$err" || echo "构建失败" >> "$out.fail"
    ) || reasons+=("cargo 命令执行失败")
    if [ -f "$out.fail" ]; then
        while IFS= read -r line; do reasons+=("$line"); done < "$out.fail"
        rm -f "$out.fail"
    fi

    # 第 4 层：直接驱动示例二进制的 --selftest（超时保护 + 两跑一致）
    local exe="$TARGET_DIR/debug/$pkg"
    if [ ${#reasons[@]} -eq 0 ] && [ -x "$exe" ]; then
        if ! timeout "$SELFTEST_TIMEOUT" "$exe" --selftest >"$run_out" 2>>"$err"; then
            local code=$?
            if [ $code -eq 124 ]; then
                reasons+=("selftest 超时（${SELFTEST_TIMEOUT}s）")
            else
                reasons+=("selftest 退出码 $code")
            fi
        elif ! timeout "$SELFTEST_TIMEOUT" "$exe" --selftest >"$run_out2" 2>>"$err"; then
            reasons+=("selftest 第二跑退出码 $?")
        elif ! cmp -s "$run_out" "$run_out2"; then
            reasons+=("两跑 stdout 不一致")
        fi
    elif [ ${#reasons[@]} -eq 0 ]; then
        reasons+=("找不到示例二进制：$exe")
    fi

    # ---- 三条运行期断言 ----
    if [ -s "$err" ] && [[ " $STDERR_ALLOW " != *" $name "* ]]; then
        reasons+=("stderr 非空（有告警）")
    fi
    if [ ! -s "$run_out" ]; then
        reasons+=("stdout 为空（没真跑起来）")
    else
        grep -q '==== [0-9][0-9] ' "$run_out" || reasons+=("stdout 缺开始标记（==== NN ）")
        grep -q '结束 ====' "$run_out" || reasons+=("stdout 缺结束标记（结束 ====）")
        if has_control_char "$run_out"; then
            reasons+=("stdout 含控制字符")
        fi
        cat "$run_out"
    fi

    if [ ${#reasons[@]} -gt 0 ]; then
        echo "[FAIL] $name：${reasons[*]}"
        if [ -s "$err" ]; then
            echo "---- $name 的 stderr ----"
            head -n 30 "$err"
            echo "-------------------------"
        fi
        return 1
    fi
    echo "[OK] $name 四层验证通过"
    return 0
}

if [ "${1:-}" != "" ] && [ "${1:-}" != "--all" ]; then
    dir="$EXAMPLES_DIR/$1"
    if [ ! -d "$dir" ]; then
        echo "找不到示例目录: $dir" >&2
        exit 1
    fi
    verify_example "$dir"
    exit $?
fi

pass=0; fail=0
for dir in "$EXAMPLES_DIR"/*/; do
    [ -d "$dir" ] || continue
    if verify_example "$dir"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
    fi
done
echo ""
if [ $fail -gt 0 ]; then
    echo "[Summary] 通过 $pass 失败 $fail"
    exit 1
fi
echo "[Summary] 通过 $pass 失败 0"
exit 0
