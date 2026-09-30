#!/bin/bash
# 第 32 章探针的批量跑法。
#
# 为什么要有探针而不是全写进主线：run-all.sh 的六条判定要求主线「编译日志为空、
# 退出码 0、stderr 为空、stdout 可复现，且 debug 与 release 两份输出逐字节一致」。
# 而本章要量的东西有一半天生进不了主线 —— 编译器的一句 error 原文（eNN）、
# 一次 Index out of range 的崩溃现场（rNN）、只在某一种优化配置下才成立的行为（cNN）、
# 混编时 clang 与 swiftc 各说什么（mNN）。
#
# 编号约定（与 docs/32-app-architecture-mvc.md 的「探针记录」一一对应）：
#   eNN_*  Swift 编译期诊断：只看 swiftc 的输出，不运行
#   rNN_*  运行期现场：编好放进模拟器跑，抄 stdout / stderr / 退出码 / 崩溃原文
#   cNN_*  配置对照：同一份源码用 -Onone 和 -O 各编各跑，抄两份输出的**差异**
#   mNN_*  混编：给同名 .h/.m，按 run-all.sh 的混编段先编 Swift（产出 -Swift.h）
#          再编 OC、链接、运行，抄两侧编译器原文与运行输出
#
# 用法：
#   ./probes/run.sh                 # 跑全部
#   ./probes/run.sh c01 r03         # 只跑编号前缀匹配的
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
XCODE_XT="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr"
SDK="$(xcrun -sdk iphonesimulator --show-sdk-path)"
TARGET="x86_64-apple-ios15.0-simulator"
SIM_UDID="${SIM_UDID:-2C5E3D2C-6F1B-4951-905F-AC00213FD5CF}"
# 模块名与主线一致：探针报的错才算同一个类型（.swift 文件里写死的类名对得上）
MODULE="app_architecture"
TMP="${TMPDIR:-/tmp}/iosdev32probes"

rm -rf "$TMP"; mkdir -p "$TMP"

show() { # $1 = 标签, $2 = 文件
    if [ -s "$2" ]; then
        printf -- '--- %s ---\n%s\n' "$1" "$(cat "$2")"
    else
        printf -- '--- %s ---（空）\n' "$1"
    fi
}

# 编译一份探针：$1 = 源码, $2 = -Onone|-O, $3 = 输出, $4 = 日志, $5 = 同名 .h（可空）
# $6 = emit（可空）：默认 eNN 走 -typecheck（快），传 emit 才做完整代码生成。
#      这个区分不是图快：definite-initialization 那一类诊断（e04 的「self 在闭包里
#      被抓住时还没初始化完」）**只在真正发射函数时**才会打印，-typecheck 一声不吭。
#      mNN 一律走完整编译（要链接同名 .m、要产出二进制）。
compile() {
    local src="$1" opt="$2" bin="$3" log="$4" hdr="$5" mode="${6:-}"
    local -a front=() objs=()
    [ -f "$hdr" ] && front=(-import-objc-header "$hdr")
    # 顶层语句只有文件名叫 main.swift 时才允许编译，所以每支探针都先复制成
    # $TMP/main.swift 再编 —— 这也是探针不能直接「swiftc c01_dealloc_timing.swift」
    # 的原因，报的是 "expressions are not allowed at the top level"。
    cp "$src" "$TMP/main.swift"
    case "$base" in
        e*) [ "$mode" = "typecheck" ] && front+=("-typecheck") ;;
        m*) [ -f "$HERE/$base.m" ] && objs=("$HERE/$base.m") ;;
    esac
    # shellcheck disable=SC2086
    "$XCODE_XT/bin/swiftc" "$opt" -sdk "$SDK" -target "$TARGET" -module-name "$MODULE" \
        ${front[@]+"${front[@]}"} "$TMP/main.swift" ${objs[@]+"${objs[@]}"} \
        -o "$bin" \
        -framework Foundation -framework UIKit > "$log" 2>&1
    return $?
}

run_case() { # $1 = -Onone|-O，$2 = 配置标签（源码路径取全局 $swift）
    local opt="$1" tag="$2"
    printf '\n===== %s (%s)\n' "$base" "$tag"
    local bin="$TMP/probe.$tag" log="$TMP/compile.$tag.txt"
    compile "$swift" "$opt" "$bin" "$log" "$ch" typecheck
    local cc=$?
    # eNN 若被 -typecheck 放过了，再用完整编译问一遍：有些诊断只有发射那一路才有。
    if [ "$cc" = 0 ] && [ "${base#e}" != "$base" ]; then
        printf '（-typecheck 一声不吭：再用完整编译问一遍）\n'
        compile "$swift" "$opt" "$bin" "$log" "$ch" emit
        cc=$?
    fi
    show "swiftc 输出" "$log"
    printf 'swiftc 退出码 = %s\n' "$cc"
    if [ "$cc" != 0 ]; then printf '（编译未通过：不运行）\n'; return; fi
    case "$base" in
        e*) printf '（编译类探针：到此为止，不运行）\n'; return ;;
    esac
    xcrun simctl spawn "$SIM_UDID" "$bin" > "$TMP/out.$tag.txt" 2> "$TMP/err.$tag.txt"
    printf '运行退出码 = %s\n' "$?"
    show "stdout" "$TMP/out.$tag.txt"
    show "stderr" "$TMP/err.$tag.txt"
}

targets=()
for f in $(cd "$HERE" && ls *.swift 2>/dev/null | sort); do
    base="${f%.swift}"
    if [ $# -eq 0 ]; then targets+=("$base"); else
        for want in "$@"; do case "$base" in "$want"*) targets+=("$base"); break ;; esac; done
    fi
done

for base in ${targets[@]+"${targets[@]}"}; do
    swift="$HERE/$base.swift"
    ch="$HERE/$base.h"
    printf '\n########## %s\n' "$base"
    run_case -Onone debug
    # cNN 一族才跑第二份配置：其余家族只有一份，省时间
    case "$base" in
        c*) run_case -O release ;;
    esac
done
printf '\n'
