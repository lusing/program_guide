#!/usr/bin/env bash
# Godot 示例统一验证入口（macOS/Linux）。
# 每个示例以 headless 脚本模式运行；带看门狗超时防挂死；
# 因 Godot 脚本加载失败仍返回退出码 0（docs/02-hello.md 2.4 实测），
# 故额外扫描输出中的 ERROR 行判定失败。
set -u
cd "$(dirname "$0")"

GODOT="${GODOT:-/opt/local/bin/godot}"
WATCHDOG_SECS="${WATCHDOG_SECS:-30}"

if [[ ! -x "$(command -v "$GODOT")" ]]; then
    echo "未找到 godot 可执行文件：$GODOT（可用环境变量 GODOT 覆盖）" >&2
    exit 1
fi

run_one() {
    local name="$1"
    local dir="examples/$name"
    local log
    log="$(mktemp)"
    echo "[Run] $name"
    (cd "$dir" && "$GODOT" --headless --path . --script main.gd) >"$log" 2>&1 &
    local pid=$!
    (
        sleep "$WATCHDOG_SECS"
        kill "$pid" 2>/dev/null
    ) &
    local watchdog=$!
    wait "$pid"
    local rc=$?
    kill "$watchdog" 2>/dev/null
    wait "$watchdog" 2>/dev/null

    sed -n '3,$p' "$log"
    if [[ $rc -ne 0 ]] || grep -qE "SCRIPT ERROR|ERROR:" "$log"; then
        echo "[Fail] $name (exit=$rc)"
        rm -f "$log"
        return 1
    fi
    rm -f "$log"
    echo "[OK] $name"
}

failed=0
if [[ $# -ge 1 ]]; then
    run_one "$1" || failed=1
else
    for dir in examples/*/; do
        run_one "$(basename "$dir")" || failed=1
    done
fi

if [[ $failed -eq 0 ]]; then
    echo "[Done] 全部示例验证通过。"
else
    echo "[Done] 存在失败示例。" >&2
fi
exit $failed
