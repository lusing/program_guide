#!/usr/bin/env bash
# Swift 教程统一验证脚本（Git Bash 入口，与 build.ps1 等价）
# 四层验证：swift-format lint --strict → swift build --target → swift test --filter → swift run
# 用法：./run-all.sh [NN_name]；无参数 = 全部示例。任一失败 exit 1。
set -euo pipefail

# ── 工具链常量（与 build.ps1 保持一致；升级时同改两处）────────────────────
SWIFT_ROOT="G:\\scoop\\apps\\swift\\6.3.3"
SWIFT_BIN="$SWIFT_ROOT\\Toolchains\\6.3.3+NoAsserts\\usr\\bin"
SWIFT="$SWIFT_BIN\\swift.exe"

if [ ! -f "$SWIFT" ]; then echo "未找到 swift.exe：$SWIFT" >&2; exit 1; fi

export SDKROOT="$SWIFT_ROOT\\Platforms\\Windows.platform\\Developer\\SDKs\\Windows.sdk"
export PATH="$SWIFT_ROOT/Runtimes/usr/bin:$SWIFT_BIN:$SWIFT_ROOT/Toolchains/usr/lib/swift/pm/ManifestAPI:$PATH"

cd "$(dirname "$0")"

# 章号 → 目标名映射（新增示例章时在此登记；与 build.ps1 保持一致）
declare -A TARGET_MAP=(
    [02_hello]=Ch02Hello
    [03_basics]=Ch03Basics
    [04_control]=Ch04Control
    [05_functions]=Ch05Functions
    [06_optionals]=Ch06Optionals
    [07_structs_classes]=Ch07StructsClasses
    [08_enums]=Ch08Enums
    [09_protocols]=Ch09Protocols
    [10_generics]=Ch10Generics
    [11_closures]=Ch11Closures
    [12_errors]=Ch12Errors
    [13_collections]=Ch13Collections
    [14_strings]=Ch14Strings
    [15_extensions]=Ch15Extensions
)
STANDALONE="22_spm 24_minigrep"

run_swift() { # 参数 = swift 子命令参数；输出透传
    "$SWIFT" "$@"
}

verify_plain() { # 参数 = 示例目录名
    local name="$1"
    local target="${TARGET_MAP[$name]}"
    if [ -z "$target" ]; then echo "目标名未登记：$name（请在 run-all.sh 的 TARGET_MAP 登记）" >&2; exit 1; fi
    local marker="==== ${name%%_*} 结束 ===="
    echo ""
    echo "[Example] $name（四层验证）"
    echo "  [1/4] swift-format lint --strict"
    run_swift format lint --configuration .swift-format --strict --recursive "examples/$name"
    echo "  [2/4] swift build --target $target"
    run_swift build --target "$target"
    echo "  [3/4] swift test --filter ${target}Tests"
    if ! run_swift test --filter "${target}Tests" | tee /dev/stderr | grep -Eq "Test run with [1-9][0-9]* test"; then
        echo "测试层未跑到任何用例（filter=${target}Tests 不匹配？）" >&2; exit 1
    fi
    echo "  [4/4] swift run $target（exit 0 + 结束标记）"
    local out
    out="$(run_swift run "$target")"
    echo "$out" | grep -Fq "$marker" || { echo "输出缺少结束标记：$marker" >&2; exit 1; }
    echo "$out" | tail -1
}

verify_standalone() { # 参数 = 示例目录名（嵌套独立包）
    local name="$1"
    echo ""
    echo "[Example] $name（独立包）"
    (cd "examples/$name" && run_swift build)
    if [ -d "examples/$name/Tests" ]; then
        (cd "examples/$name" && run_swift test)
    fi
    echo "  [OK] $name 独立包构建/测试通过"
}

verify_one() {
    local name="$1"
    case " $STANDALONE " in
        *" $name "*) verify_standalone "$name" ;;
        *) verify_plain "$name" ;;
    esac
}

if [ $# -ge 1 ]; then
    if [ ! -d "examples/$1" ]; then echo "找不到示例目录: examples/$1" >&2; exit 1; fi
    verify_one "$1"
    echo ""
    echo "[Done] $1 验证通过。"
    exit 0
fi

for dir in examples/*/; do
    verify_one "$(basename "$dir")"
done
echo ""
echo "[Done] 全部示例验证通过。"
