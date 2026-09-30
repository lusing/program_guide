#!/bin/bash
# 第 34 章探针的批量跑法。
#
# 为什么要有探针而不是全写进主线：run-all.sh 的六条判定要求主线「编译日志为空、
# 退出码 0、stderr 为空、stdout 可复现，且 debug 与 release 两份输出逐字节一致」。
# 而本章要量的东西有三类天生进不了主线：
#   —— 主机上的 Apple 工具链原话（coremlcompiler 的命令行、它的拒答、生成物的字节数），
#      主线跑在模拟器里，碰不到 macOS 上的那个可执行文件；
#   —— 一次运行期没顶（signal 6）：主线一旦 abort 就打印不出后面十八节；
#   —— 一整棵几百行的字段树：它带浮点数尾巴和绝对路径，逐字节比对扛不住。
#
# 编号约定（与 docs/34-core-ml.md 的「探针记录」一一对应）：
#   aNN_*  主机工具链现场：每支是一个 .sh，直接在 macOS 上跑 xcrun coremlcompiler 之类的
#          主机程序，抄命令原文、退出码、产物字节数。
#   rNN_*  运行期现场：编成模拟器可执行文件再 simctl spawn，抄 stdout / stderr / 退出码 /
#          崩溃原文。这一族的成员会**故意**摔在错误路径上。
#   gNN_*  字节层取证：同样在模拟器里跑（真模型只在设备侧的 /System 分区里可读），
#          把 .mlmodel 的 protobuf 树整个摊开看字段号。
#
# 用法：
#   ./probes/run.sh                # 跑全部
#   ./probes/run.sh a01 r02        # 只跑编号前缀匹配的
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
CHAPTER="$(cd "$HERE/.." && pwd)"
XCODE_XT="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr"
SDK="$(xcrun -sdk iphonesimulator --show-sdk-path)"
TARGET="x86_64-apple-ios15.0-simulator"
# 模块名与主线一致：探针报的错、反射出来的类型名才算同一个模块里的同一个类
MODULE="core_ml"
TMP="${TMPDIR:-/tmp}/iosdev34probes"

rm -rf "$TMP"; mkdir -p "$TMP"

show() { # $1 = 标签, $2 = 文件
    if [ -s "$2" ]; then
        printf -- '--- %s ---\n%s\n' "$1" "$(cat "$2")"
    else
        printf -- '--- %s ---（空）\n' "$1"
    fi
}

# ---------------------------------------------------------------- 模拟器管理 --
SIM_UDID="${SIM_UDID:-}"
WE_BOOTED=0
pick_and_boot_sim() {
    SIM_UDID="$(xcrun simctl list devices booted 2>/dev/null \
        | grep -iE 'iPhone|iPad' | grep -oE '\([0-9A-F-]{36}\)' | tr -d '()' | head -1)"
    [ -n "$SIM_UDID" ] && { printf '复用已启动的模拟器：%s\n' "$SIM_UDID"; return 0; }
    SIM_UDID="$(xcrun simctl list devices available 2>/dev/null \
        | grep -iE 'iPhone' | grep -oE '\([0-9A-F-]{36}\)' | tr -d '()' | head -1)"
    if [ -z "$SIM_UDID" ]; then
        printf '错误：找不到任何可用的 iPhone 模拟器（xcrun simctl list devices available）\n'
        exit 1
    fi
    printf '启动模拟器：%s（首次冷启动可能要一两分钟）\n' "$SIM_UDID"
    xcrun simctl boot "$SIM_UDID" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null 2>&1 || {
        printf '错误：模拟器启动失败\n'; exit 1; }
    WE_BOOTED=1
}
cleanup_sim() {
    if [ "$WE_BOOTED" = "1" ] && [ "${KEEP_BOOTED:-0}" = "0" ]; then
        xcrun simctl shutdown "$SIM_UDID" >/dev/null 2>&1 || true
        printf '已关闭本脚本启动的模拟器 %s（KEEP_BOOTED=1 可保留）\n' "$SIM_UDID"
    fi
}

# ------------------------------------------------------------ 编译并跑一支 --
# 主线那套 swiftc 参数（见 run-all.sh）：顶层语句只允许写在 main.swift 里，所以每支探针
# 先改名再编；这一章的探针只要 CoreML + Foundation，图像那族（Vision/UIKit）主线已经量过。
run_sim_probe() { # $1 = base
    local base="$1"
    local bin="$TMP/$base" src="$HERE/$base.swift"
    cp "$src" "$TMP/main.swift"
    printf '\n$ %s/bin/swiftc -Onone -sdk %s -target %s -module-name %s -framework CoreML -framework Foundation main.swift -o %s\n' \
        "$XCODE_XT" "$SDK" "$TARGET" "$MODULE" "$base"
    ( "$XCODE_XT/bin/swiftc" -Onone -sdk "$SDK" -target "$TARGET" -module-name "$MODULE" \
        -framework CoreML -framework Foundation "$TMP/main.swift" -o "$bin" ) \
        > "$TMP/compile.$base.txt" 2>&1
    local cc=$?
    show "swiftc 输出" "$TMP/compile.$base.txt"
    printf 'swiftc 退出码 = %s\n' "$cc"
    [ "$cc" = 0 ] || { printf '（编译未通过：不运行）\n'; return; }
    ( xcrun simctl spawn "$SIM_UDID" "$bin" ) > "$TMP/out.$base.txt" 2> "$TMP/err.$base.txt"
    printf '运行退出码 = %s\n' "$?"
    show "stdout" "$TMP/out.$base.txt"
    show "stderr" "$TMP/err.$base.txt"
}

run_host_probe() { # $1 = base
    local base="$1"
    printf '\n$ bash probes/%s.sh\n' "$base"
    ( cd "$TMP" && bash "$HERE/$base.sh" ) 2>&1 | sed 's/^/    /'
    printf '探针退出码 = %s\n' "${PIPESTATUS[0]}"
}

targets=()
for f in $(cd "$HERE" && ls *.swift *.sh 2>/dev/null | sed -e 's/\.swift$//' -e 's/\.sh$//' | grep -v '^run$' | sort -u); do
    if [ $# -eq 0 ]; then targets+=("$f"); else
        for want in "$@"; do case "$f" in "$want"*) targets+=("$f"); break ;; esac; done
    fi
done

need_sim=0
for base in ${targets[@]+"${targets[@]}"}; do
    case "$base" in a*) ;; *) need_sim=1 ;; esac
done
[ "$need_sim" = 1 ] && pick_and_boot_sim

for base in ${targets[@]+"${targets[@]}"}; do
    printf '\n########## %s\n' "$base"
    case "$base" in
        a*) run_host_probe "$base" ;;
        *)  run_sim_probe "$base" ;;
    esac
done

[ "$need_sim" = 1 ] && cleanup_sim
printf '\n===== 第 34 章探针跑完：产物与日志都在 %s =====\n' "$TMP"
