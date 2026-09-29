#!/bin/bash
# 第 30 章探针的批量跑法。
#
# 为什么要探针：run-all.sh 的六条判定要求主线示例「编译日志为空、退出码 0、
# stderr 为空、stdout 可复现」，而「编译器原话」和「崩溃现场」恰恰是这三条不允许
# 出现在主线里的东西。它们只能各开一个进程去量，正文只抄结论。
#
# 编号约定（与 docs/30-swift-language-basics.md 的「探针记录」一一对应）：
#   eNN_*  编译期诊断：只看 swiftc 的输出，不运行
#   rNN_*  运行期现场：编好放到模拟器里跑，抄 stdout / stderr / 退出码
#   sNN_*  语言模式对照：同一份源码分别用 -swift-version 5 与 6 各编（跑）一遍
#   tNN_*  纯输出对照：不诊断、不崩溃，只是把某条事实跑成一个可抄的表
#
# 用法：
#   ./probes/run.sh                 # 跑全部
#   ./probes/run.sh e11 e20 r05     # 只跑编号匹配的（前缀匹配）
#   MODE=5 ./probes/run.sh s06      # s* 组只跑某一种语言模式
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
XCODE_XT="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr"
SDK="$(xcrun -sdk iphonesimulator --show-sdk-path)"
TARGET="x86_64-apple-ios15.0-simulator"
SIM_UDID="${SIM_UDID:-2C5E3D2C-6F1B-4951-905F-AC00213FD5CF}"
TMP="${TMPDIR:-/tmp}/iosdev30probes"
MODE="${MODE:-both}"
mkdir -p "$TMP"

# 顶层语句（本章所有探针都是顶层语句）只有文件名叫 main.swift 时才允许编译，
# 所以每个探针都先复制成 $TMP/main.swift 再编 —— 这也是探针不能直接
# 「swiftc e11_xxx.swift」的原因，报的是 "expressions are not allowed at the top level"。
prep() { cp "$HERE/$1" "$TMP/main.swift"; }

build() {   # $1 = swiftc 额外开关（如 -swift-version 6）
    "$XCODE_XT/bin/swiftc" -Onone -sdk "$SDK" -target "$TARGET" -module-name probe \
        $1 "$TMP/main.swift" -o "$TMP/probe" \
        -framework Foundation -framework UIKit 2>"$TMP/compile.txt"
}

run_probe() {
    printf '\n########## %s [%s]\n' "$1" "$2"
    prep "$1"
    build "$3"
    local rc=$?
    if [ -s "$TMP/compile.txt" ]; then
        printf -- '--- 编译输出 ---\n%s\n' "$(cat "$TMP/compile.txt")"
    else
        printf -- '--- 编译输出 ---（空）\n'
    fi
    [ $rc -ne 0 ] && { printf '编译退出码 = %s\n' "$rc"; return; }
    case "$1" in
        e*) printf '（编译类探针：到此为止，不运行）\n' ;;
        *)  printf -- '--- 运行 ---\n'
            xcrun simctl spawn "$SIM_UDID" "$TMP/probe" >"$TMP/out.txt" 2>"$TMP/err.txt"
            printf '运行退出码 = %s\n' "$?"
            printf -- 'stdout:\n%s\n' "$(cat "$TMP/out.txt")"
            if [ -s "$TMP/err.txt" ]; then
                printf -- 'stderr:\n%s\n' "$(cat "$TMP/err.txt")"
            else
                printf -- 'stderr:（空）\n'
            fi ;;
    esac
}

targets=()
for f in $(cd "$HERE" && ls *.swift | sort); do
    base="${f%.swift}"
    if [ $# -eq 0 ]; then targets+=("$base"); else
        for want in "$@"; do case "$base" in "$want"*) targets+=("$base"); break ;; esac; done
    fi
done

for t in ${targets[@]+"${targets[@]}"}; do
    case "$t" in
        s*)
            [ "$MODE" != 6 ] && run_probe "$t.swift" "swift-version 5" "-swift-version 5"
            [ "$MODE" != 5 ] && run_probe "$t.swift" "swift-version 6" "-swift-version 6"
            ;;
        *) run_probe "$t.swift" "language mode 5" "" ;;
    esac
done
printf '\n'
