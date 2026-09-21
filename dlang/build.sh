#!/usr/bin/env bash
# D 语言教程 Linux 统一验证脚本（build.ps1 的 Linux 对应物）
# 用法:
#   ./build.sh --all                  验证 examples 下全部示例
#   ./build.sh --example 13_ranges    验证单个示例
#   ./build.sh --clean                清理 build 目录与散落的 .o
set -euo pipefail

projectRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$projectRoot"

DMD="${DMD:-dmd}"
command -v "$DMD" >/dev/null || { echo "未找到 dmd，请先安装 DMD 2.113+"; exit 1; }

buildDir="$projectRoot/build"
examplesDir="$projectRoot/examples"

do_clean() {
    rm -rf "$buildDir"
    find "$examplesDir" -maxdepth 2 -name '*.o' -delete 2>/dev/null || true
    find "$examplesDir" -maxdepth 3 -type d -name bin -exec rm -rf {} + 2>/dev/null || true
    echo "[Clean] 已清理 build 目录、散落的 .o 与 DUB 工程 bin/。"
    exit 0
}

# 普通示例两层验证：
#   1) dmd -w -unittest -run  → 警告当错误 + 跑全部 unittest（注意：此模式不执行 main！）
#   2) dmd -w 编译出可执行文件再运行 → 验证 main 路径
test_plain() {
    local dir="$1" name
    name="$(basename "$dir")"
    echo
    echo "[Example] $name"
    ( cd "$dir" && "$DMD" -w -unittest -run main.d )
    ( cd "$dir" && "$DMD" -w main.d "-of$buildDir/$name" "-od$buildDir" )
    # 运行时要位于示例目录：18/24 等示例按相对路径读自己的测试数据
    ( cd "$dir" && "$buildDir/$name" )
}

# 22_cinterop：常规两层 + betterC 产物
test_cinterop() {
    local dir="$1" name
    name="$(basename "$dir")"
    echo
    echo "[Example] $name（含 -betterC）"
    ( cd "$dir" && "$DMD" -w -unittest -run main.d )
    ( cd "$dir" && "$DMD" -w main.d "-of$buildDir/$name" "-od$buildDir" )
    ( cd "$dir" && "$buildDir/$name" )
    ( cd "$dir" && "$DMD" -w -betterC betterc.d "-of$buildDir/22_betterc" )
    ( cd "$dir" && "$buildDir/22_betterc" )
}

# DUB 工程（21/24）：dub test + dub build + 运行（产物在工程 bin/ 下）
test_dub() {
    local dir="$1" exe="$2" name
    name="$(basename "$dir")"
    echo
    echo "[Example] $name (DUB 工程)"
    ( cd "$dir" && dub test )
    ( cd "$dir" && dub build )
    ( cd "$dir" && "./bin/$exe" )
}

test_one() {
    local dir="$1"
    case "$(basename "$dir")" in
        21_dub)      test_dub "$dir" dguide_dub ;;
        24_minigrep) test_dub "$dir" minigrep ;;
        22_cinterop) test_cinterop "$dir" ;;
        *)           test_plain "$dir" ;;
    esac
    echo "[Done] $(basename "$dir") 验证通过。"
}

case "${1:-}" in
    --clean)
        do_clean
        ;;
    --example)
        [ $# -ge 2 ] || { echo "用法: $0 --example <目录名>"; exit 1; }
        dir="$examplesDir/$2"
        [ -d "$dir" ] || { echo "找不到示例目录: $dir"; exit 1; }
        mkdir -p "$buildDir"
        test_one "$dir"
        ;;
    --all)
        mkdir -p "$buildDir"
        while IFS= read -r dir; do
            test_one "$dir"
        done < <(find "$examplesDir" -mindepth 1 -maxdepth 1 -type d | sort)
        echo
        echo "[Done] 全部示例验证通过。"
        ;;
    *)
        echo "用法:"
        echo "  $0 --all                  验证 examples 下全部示例"
        echo "  $0 --example 13_ranges    验证单个示例"
        echo "  $0 --clean                清理 build 目录与 .o"
        exit 1
        ;;
esac
