#!/usr/bin/env bash
# D 语言教程 Unix 统一验证脚本（build.ps1 的对应物，Linux 与 macOS 均可用）
# 用法:
#   ./build.sh --all                  验证 examples 下全部示例
#   ./build.sh --example 13_ranges    验证单个示例
#   ./build.sh --clean                清理 build 目录与散落的 .o
# 环境变量:
#   DMD / DUB / DMD_ROOT / DUB_HOME   覆盖工具链与缓存位置（不设则自动探测）
set -euo pipefail

projectRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$projectRoot"

# 工具链探测：显式环境变量 > PATH > 已知安装位置（官方包 / MacPorts / 发行版包）。
# 不写死单一路径，找不到就报缺工具（DUB 缺失时跳过 DUB 通道，见 test_dub）。
find_tool() {
    local exe="$1" root
    for root in \
        "${DMD_ROOT:-}" \
        "$HOME/dmd2/osx/bin" "$HOME/dmd2/linux/bin64" \
        "/Volumes/mac004/lang/dmd2/osx/bin" \
        "/opt/local/bin" "/usr/local/bin" "/usr/bin" "/bin"
    do
        [ -n "$root" ] || continue
        [ -x "$root/$exe" ] || continue
        printf '%s\n' "$root/$exe"
        return 0
    done
    if command -v "$exe" >/dev/null 2>&1; then command -v "$exe"; return 0; fi
    return 1
}

if [ -n "${DMD:-}" ]; then
    :
elif DMD="$(find_tool dmd)"; then
    :
else
    echo "未找到 dmd，请先安装 DMD 2.113+（或设 DMD=... / DMD_ROOT=...）"; exit 1
fi
export PATH="$(dirname "$DMD"):$PATH"   # 让 dub / rdmd 找到同目录的 dmd

DUB="${DUB:-$(find_tool dub || true)}"

buildDir="$projectRoot/build"
examplesDir="$projectRoot/examples"

# macOS 专属：官方 dmd 包里的二进制是未签名的，而 macOS 对未签名进程在 ~/ 下
# unlink 文件会返回 EPERM —— dub 默认缓存 ~/.dub 正好踩中，报
# "Failed to remove file .../__dub_write_test_XXXX: Operation not permitted"。
# 把缓存挪出 $HOME 即可；Linux 无此现象，保持默认。
if [ -z "${DUB_HOME:-}" ] && [ "$(uname -s)" = "Darwin" ]; then
    export DUB_HOME="$buildDir/dub-home"
    mkdir -p "$DUB_HOME"
fi

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
    echo "[Example] ${name}"
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
    # 注意：必须写 ${name} 而不是 $name —— bash 5.3 下 `$name（含`）会把全角括号
    # 的字节吞进变量名，配合 set -u 直接报 "unbound variable"（Linux 旧 bash 不触发）。
    echo "[Example] ${name}（含 -betterC）"
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
    echo "[Example] ${name} (DUB 工程)"
    if [ -z "$DUB" ]; then
        echo "[Skip] ${name}: 未找到 dub，跳过该通道。"
        return 0
    fi
    ( cd "$dir" && "$DUB" test )
    ( cd "$dir" && "$DUB" build )
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

report_toolchain() {
    echo "[Tool] OS: $(uname -s) $(uname -m)"
    # ${DMD} 而非 $DMD：bash 5.3 会把紧跟的全角括号字节并入变量名（见 test_cinterop 注释）
    echo "[Tool] dmd: ${DMD}（"$("$DMD" --version 2>/dev/null | head -1)"）"
    echo "[Tool] dub: ${DUB:-（未找到，DUB 通道跳过）}"
    echo "[Tool] DUB_HOME=${DUB_HOME:-（dub 默认 ~/.dub）}"
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
        report_toolchain
        test_one "$dir"
        ;;
    --all)
        mkdir -p "$buildDir"
        report_toolchain
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
