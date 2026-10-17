#!/usr/bin/env bash
#
# 一键编译并静态校验 examples/ 下的全部 Ren'Py 示例工程（Linux / macOS）。
#
# 注意：本脚本是本书自带的便捷工具，不是 Ren'Py 官方文档里的东西。
# 官方对构建的标准入口只有启动器 Build 页与 `renpy.sh launcher distribute`。
#
# 用法:
#   ./build.sh                      编译 + lint 校验 examples 下的全部示例
#   ./build.sh 02_images_and_stage  只校验单个示例
#   ./build.sh --compile-only       只做编译，不跑 lint
#   ./build.sh --clean              清理各示例的编译缓存、存档与运行日志
#
# 环境变量:
#   RENPY  指向 SDK 中 renpy.sh 的绝对路径；设置后优先使用它。

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES="$ROOT/examples"

# ---------------------------------------------------------------- 定位 Ren'Py
find_renpy() {
    if [ -n "${RENPY:-}" ] && [ -x "${RENPY}" ]; then
        printf '%s\n' "$RENPY"
        return 0
    fi

    local cand
    for cand in \
        "$ROOT/renpy.sh" \
        /Applications/renpy*/renpy.sh \
        "$HOME"/renpy*-sdk/renpy.sh \
        "$HOME"/renpy-sdk/renpy.sh \
        /opt/renpy/renpy.sh
    do
        if [ -x "$cand" ]; then
            printf '%s\n' "$cand"
            return 0
        fi
    done

    if command -v renpy.sh >/dev/null 2>&1; then
        command -v renpy.sh
        return 0
    fi

    return 1
}

RENPY_BIN="$(find_renpy || true)"
if [ -z "$RENPY_BIN" ]; then
    echo "错误：找不到 Ren'Py SDK。" >&2
    echo "请设置环境变量，例如：" >&2
    echo "    RENPY=/path/to/renpy-8.5.x-sdk/renpy.sh ./build.sh" >&2
    exit 1
fi

if [ ! -d "$EXAMPLES" ]; then
    echo "错误：找不到 examples 目录：$EXAMPLES" >&2
    exit 1
fi

# ------------------------------------------------------------------ 参数解析
MODE="all"        # all | single | clean
PROJECT=""
RUN_LINT=1

for arg in "$@"; do
    case "$arg" in
        --clean)        MODE="clean" ;;
        --compile-only) RUN_LINT=0 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^#\{0,1\} \{0,1\}//'
            exit 0
            ;;
        -*)
            echo "错误：未知参数 $arg（用 --help 查看用法）" >&2
            exit 1
            ;;
        *)
            MODE="single"
            PROJECT="$arg"
            ;;
    esac
done

# ------------------------------------------------------------------ 清理模式
do_clean() {
    local any=0 dir
    for dir in "$EXAMPLES"/*/; do
        [ -d "$dir" ] || continue
        rm -rf "$dir/game/cache" "$dir/game/saves" \
               "$dir/log.txt" "$dir/errors.txt" "$dir/traceback.txt"
        find "$dir" -name '*.rpyc' -delete 2>/dev/null
        any=1
    done
    if [ "$any" -eq 1 ]; then
        echo "[Clean] 已清理各示例的 cache / saves / *.rpyc / log.txt。"
    else
        echo "[Clean] examples 下没有示例工程。"
    fi
}

# ------------------------------------------------------------ 单个工程校验
# $1 = 示例目录（绝对路径）
verify_project() {
    local dir="$1"
    local name
    name="$(basename "$dir")"

    echo "[Compile] $name"
    if ! "$RENPY_BIN" "$dir" compile; then
        echo "[FAIL] 编译失败：$name" >&2
        return 1
    fi

    if [ "$RUN_LINT" -eq 1 ]; then
        # lint --error-code：发现问题时退出码非 0
        if ! "$RENPY_BIN" "$dir" lint --error-code; then
            echo "[FAIL] lint 未通过：$name" >&2
            return 1
        fi
    fi

    echo "[OK] $name"
    return 0
}

# ---------------------------------------------------------------- 主流程
failed=0
total=0
skipped=0

if [ "$MODE" = "clean" ]; then
    do_clean
    exit 0
fi

if [ "$MODE" = "single" ]; then
    target="$EXAMPLES/$PROJECT"
    if [ ! -d "$target" ]; then
        echo "错误：找不到示例工程 $target" >&2
        exit 1
    fi
    if [ ! -f "$target/game/script.rpy" ]; then
        echo "错误：${PROJECT} 缺少 game/script.rpy" >&2
        exit 1
    fi
    total=1
    verify_project "$target" || failed=1
else
    for dir in "$EXAMPLES"/*/; do
        [ -d "$dir" ] || continue
        if [ ! -f "$dir/game/script.rpy" ]; then
            echo "[Skip] $(basename "$dir")：没有 game/script.rpy，跳过"
            skipped=$((skipped + 1))
            continue
        fi
        total=$((total + 1))
        verify_project "$dir" || failed=$((failed + 1))
    done
fi

echo
note=""
[ "$skipped" -gt 0 ] && note="，跳过 $skipped 个空目录"
if [ "$failed" -eq 0 ]; then
    echo "[Done] 全部通过（共 $total 个示例${note}）。"
    exit 0
else
    echo "[Done] 有 $failed 个示例未通过，共 $total 个${note}。"
    exit 1
fi
