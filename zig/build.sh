#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

ZIG_EXE="${ZIG:-}"
if [[ -z "$ZIG_EXE" ]]; then
    if command -v zig &>/dev/null; then
        ZIG_EXE="zig"
    else
        echo "错误: 未找到 zig，请安装或设置 ZIG 环境变量。" >&2
        echo "  macOS:   brew install zig" >&2
        echo "  Linux:   下载 https://ziglang.org/download/ 并加入 PATH" >&2
        echo "  自定义:  export ZIG=/path/to/zig" >&2
        exit 1
    fi
fi

BUILD_DIR="$PROJECT_ROOT/build"
EXAMPLES_DIR="$PROJECT_ROOT/examples"

if [[ "${1:-}" == "--clean" ]]; then
    rm -rf "$BUILD_DIR"
    echo "[Clean] 已清理 build 目录。"
    exit 0
fi

mkdir -p "$BUILD_DIR"

DEFAULT_TARGETS=(
    "环境搭建/012_环境搭建_第一个程序.zig"
    "基础语法/015_基础语法_变量声明.zig"
    "控制流/021_控制流_if_语句.zig"
    "控制流/022_控制流_switch_语句.zig"
    "函数/025_函数_基本函数.zig"
)

compile() {
    local source_path="$1"
    local base_name
    base_name="$(basename "$source_path" .zig)"
    local source_dir
    source_dir="$(dirname "$source_path")"

    echo "[Compile] ${source_path#$PROJECT_ROOT/}"

    (cd "$source_dir" && "$ZIG_EXE" build-exe "$(basename "$source_path")" -O Debug)

    local generated_bin="$source_dir/$base_name"
    if [[ -f "$generated_bin" ]]; then
        mv "$generated_bin" "$BUILD_DIR/$base_name"
    fi
    rm -f "$source_dir/$base_name.o"
}

if [[ "${1:-}" == "--all" ]]; then
    for rel in "${DEFAULT_TARGETS[@]}"; do
        compile "$EXAMPLES_DIR/$rel"
    done
    echo "[Done] Zig 示例编译验证完成。"
    exit 0
elif [[ "${1:-}" == "--file" ]]; then
    if [[ -z "${2:-}" ]]; then
        echo "用法: $0 --file <path>" >&2
        exit 1
    fi
    compile "$EXAMPLES_DIR/$2"
    echo "[Done] 编译通过: $2"
    exit 0
else
    echo "用法:"
    echo "  $0 --all              编译 examples 下全部 Zig 示例"
    echo "  $0 --file <path>      编译单个示例，相对 examples 目录"
    echo "  $0 --clean            清理 build 目录"
    exit 0
fi
