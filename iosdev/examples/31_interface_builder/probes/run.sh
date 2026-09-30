#!/bin/bash
# 第 31 章探针的批量跑法。
#
# 为什么要探针：run-all.sh 的六条判定要求主线示例「编译日志为空、退出码 0、
# stderr 为空、stdout 可复现」。而 Interface Builder 的错误恰好两头都不占：
# 坏 XML 在 ibtool 那里通常连一条告警都没有（bNN 组量的是「ibtool 说了什么」），
# 真出问题时UIKit 用 NSLog 把话打到 stderr、或者直接抛 ObjC 异常把进程带走
# （rNN 组量的是「崩溃现场与原文」）。这些东西一次都进不了主线：一次未捕获异常
# 会把后面所有输出全带走，而 stderr 非空直接判失败。
#
# 编号约定（与 docs/31-interface-builder.md 的「探针记录」一一对应）：
#   bNN_*  坏界面文件：只（主要）跑 ibtool，抄它的 stdout/stderr/退出码；
#          带同名 .swift 的还会把编译产物 instantiate 一次，抄「运行时到底拿到什么类」
#   eNN_*  Swift 编译期诊断：只看 swiftc 的输出，不运行
#   rNN_*  运行期现场：编好放进模拟器跑，抄 stdout / stderr / 退出码 / 崩溃原文
#
# 一个探针 = 同名的一组文件：
#   probes/b03_unreachable.storyboard       坏 XML（可以只有它）
#   probes/b04_unreachable_removed.swift    可选：读那份坏 XML 的运行时后果
#   probes/r11_owner_nil.xib                XIB 类探针给同名 .xib
#
# 关键约定：探针二进制的 -module-name 与主线一致（interface_builder）。坏 XML 里
# 写的 customModule 也是它 —— 否则「类名写错」和「模块名写错」两种失败会被
# 「探针自己的模块名不对」这一种噪声盖掉。产物和二进制放在同一个临时目录，
# Bundle.main 就是那个目录（主线 §1 量的就是这条），所以探针里
# UIStoryboard(name:"<同名>", bundle: nil) 直接可用。
#
# 用法：
#   ./probes/run.sh                 # 跑全部
#   ./probes/run.sh b03 r06 r11     # 只跑编号匹配的（前缀匹配）
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
XCODE_XT="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr"
SDK="$(xcrun -sdk iphonesimulator --show-sdk-path)"
TARGET="x86_64-apple-ios15.0-simulator"
SIM_UDID="${SIM_UDID:-2C5E3D2C-6F1B-4951-905F-AC00213FD5CF}"
MODULE="interface_builder"
MIN_DEPLOY="15.0"
ITOOL="$(xcrun -f ibtool)"
TMP="${TMPDIR:-/tmp}/iosdev31probes"

rm -rf "$TMP"; mkdir -p "$TMP"

show() { # $1 = 标签, $2 = 文件
    if [ -s "$2" ]; then
        printf -- '--- %s ---\n%s\n' "$1" "$(cat "$2")"
    else
        printf -- '--- %s ---（空）\n' "$1"
    fi
}

run_probe() {
    local base="$1"
    printf '\n########## %s\n' "$base"
    rm -rf "$TMP"/*.storyboardc "$TMP"/*.nib "$TMP"/main.swift "$TMP"/probe \
         "$TMP"/ibtool.txt "$TMP"/compile.txt "$TMP"/out.txt "$TMP"/err.txt 2>/dev/null

    # 1) 界面文件：ibtool
    local ib_rc="-" have_xml=0
    for ext in storyboard xib; do
        local src="$HERE/$base.$ext"
        [ -f "$src" ] || continue
        have_xml=1
        local out="$TMP/$(basename "$src" ".$ext").$([ "$ext" = storyboard ] && echo storyboardc || echo nib)"
        "$ITOOL" --compile "$out" "$src" --errors --warnings --notices \
            --target-device iphone --minimum-deployment-target "$MIN_DEPLOY" \
            --output-format human-readable-text >> "$TMP/ibtool.txt" 2>&1
        ib_rc="$?"
        printf 'ibtool（%s）退出码 = %s，产物 = %s\n' "$ext" "$ib_rc" "$(basename "$out")"
    done
    [ "$have_xml" = 1 ] && show "ibtool 输出" "$TMP/ibtool.txt"
    if [ "$have_xml" = 1 ] && [ "$ib_rc" != 0 ]; then
        printf '（ibtool 没放行：没有产物可跑，探针到此为止）\n'
        return
    fi

    # 2) Swift：编译（eNN 组的结论就在这一步的输出里）
    local swift="$HERE/$base.swift"
    if [ ! -f "$swift" ]; then
        printf '（纯 ibtool 探针：无同名 .swift，到此为止）\n'
        return
    fi
    # 顶层语句只有文件名叫 main.swift 时才允许编译（主线示例本来就叫这个名字），
    # 所以每个探针都先复制成 $TMP/main.swift 再编 —— 这也是探针不能直接
    # 「swiftc b01_ghost_class.swift」的原因，报的是 "expressions are not allowed at the top level"。
    cp "$swift" "$TMP/main.swift"
    "$XCODE_XT/bin/swiftc" -Onone -sdk "$SDK" -target "$TARGET" -module-name "$MODULE" \
        "$TMP/main.swift" -o "$TMP/probe" \
        -framework Foundation -framework UIKit -framework SwiftUI > "$TMP/compile.txt" 2>&1
    local cc=$?
    show "swiftc 输出" "$TMP/compile.txt"
    printf 'swiftc 退出码 = %s\n' "$cc"
    if [ "$cc" != 0 ]; then printf '（编译未通过：不运行）\n'; return; fi
    case "$base" in
        e*) printf '（编译类探针：到此为止，不运行）\n'; return ;;
    esac

    # 3) 运行：崩溃与 stderr 原文都在这一步
    xcrun simctl spawn "$SIM_UDID" "$TMP/probe" > "$TMP/out.txt" 2> "$TMP/err.txt"
    printf '运行退出码 = %s\n' "$?"
    show "stdout" "$TMP/out.txt"
    show "stderr" "$TMP/err.txt"
}

bases=()
for f in $(cd "$HERE" && ls); do
    case "$f" in
        *.swift|*.storyboard|*.xib) bases+=("$(basename "$f" ".${f##*.}")") ;;
    esac
done
targets=()
for f in $(printf '%s\n' ${bases[@]+"${bases[@]}"} | sort -u); do
    if [ $# -eq 0 ]; then targets+=("$f"); else
        for want in "$@"; do case "$f" in "$want"*) targets+=("$f"); break ;; esac; done
    fi
done

for t in ${targets[@]+"${targets[@]}"}; do run_probe "$t"; done
printf '\n'
