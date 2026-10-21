#!/usr/bin/env bash
# build.sh —— macOS / Linux 下的示例编译脚本（与 build.ps1 用法一致）
set -euo pipefail

projectRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$projectRoot"

examplesDir="$projectRoot/examples"
buildDir="$projectRoot/build"
buildExamplesDir="$buildDir/examples"

ALL=0
CLEAN=0
FILE=""

usage() {
    echo "用法:"
    echo "  ./build.sh -All          编译 examples 下全部示例"
    echo "  ./build.sh -File <name>  编译单个示例（如 01_intro.v）"
    echo "  ./build.sh -Clean        清理 build 目录"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -All)   ALL=1 ;;
        -Clean) CLEAN=1 ;;
        -File)
            shift
            FILE="${1:-}"
            if [ -z "$FILE" ]; then
                echo "-File 需要一个文件名参数。" >&2
                exit 1
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "未知参数: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if [ "$CLEAN" -eq 1 ]; then
    if [ -d "$buildDir" ]; then
        rm -rf "$buildDir"
        echo "[Clean] 已清理 build 目录。"
    else
        echo "[Clean] build 目录不存在，无需清理。"
    fi
    exit 0
fi

if [ "$ALL" -eq 0 ] && [ -z "$FILE" ]; then
    usage
    exit 0
fi

if ! command -v rocq >/dev/null 2>&1; then
    echo "未找到 rocq，请检查 Rocq 安装与 PATH 配置。" >&2
    exit 1
fi

if [ ! -d "$examplesDir" ]; then
    echo "找不到 examples 目录: $examplesDir" >&2
    exit 1
fi

mkdir -p "$buildExamplesDir"

compile_one() {
    local src="$1"
    local name
    name="$(basename "$src")"
    local target="$buildExamplesDir/ex_$name"
    cp "$src" "$target"
    echo "[Compile] ex_$name"
    (cd "$buildExamplesDir" && rocq compile -q "ex_$name")
}

if [ "$ALL" -eq 1 ]; then
    found=0
    for src in "$examplesDir"/*.v; do
        [ -e "$src" ] || continue
        found=1
        compile_one "$src"
    done
    if [ "$found" -eq 0 ]; then
        echo "examples 目录下没有 .v 示例文件。" >&2
        exit 1
    fi
    echo "[Done] examples 目录全部编译通过。"
    exit 0
fi

if [ -n "$FILE" ]; then
    if [ ! -f "$examplesDir/$FILE" ]; then
        echo "找不到示例文件: $FILE" >&2
        exit 1
    fi
    compile_one "$examplesDir/$FILE"
    echo "[Done] 编译通过: $FILE"
    exit 0
fi
