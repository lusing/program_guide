#!/bin/bash
# ============================================================================
# macOS 应用开发教程（macosdev）—— 构建 / 运行 / 六条判定 / 双工具链通道比对
#
#   ./run-all.sh              跑全部示例
#   ./run-all.sh 07           只跑编号 07 的示例（可给多个编号）
#   ./run-all.sh --clean      清空 build/
#
# 五条 + 一条 判定（任一条失败即 FAIL，脚本最终退出码 1）：
#   1) 编译日志为空      —— 零告警（含 ibtool 日志；-Wall -Wextra 已开）
#   2) 退出码为 0
#   3) stderr 为空
#   4) stdout 非空       —— 挡住「进程根本没执行到业务代码、退出码却是 0」
#   5) stdout 无多余控制字符（0..31 除 TAB/LF/CR）
#   6) stdout 有结束标记 "==== NN 结束 ===="
#
# 外加两条约束：
#   - 两套工具链（Command Line Tools / Xcode 16.2）编译出的产物，stdout 逐字节一致
#   - XIB 与源码的一致性由 tools/check_xib.py 静态检查（编译之前跑）
#
# 为什么没有「stdout 不得含诊断字样」那条：Swift/Clang 的诊断一律走 stderr，
# 第 1、3 条已经覆盖；而本教程有示例故意打印 "warning:" 之类的文本做演示。
# ============================================================================
set -u

TOP="$(cd "$(dirname "$0")" && pwd)"
EXAMPLES="$TOP/examples"
BUILD="$TOP/build"
TOOLS="$TOP/tools"

HOST_ARCH="$(uname -m)"
# 本机 macOS 14.8.9，SDK 是 15.2：不钉住部署目标的话，
# 误用了 macOS 13/14/15 才有的 API 也能编译过，运行到老系统上才崩。
# 钉在 12.0（比本机低）让「误用新 API」在编译期就暴露；示例都兼容到 12.0。
DEPLOY_TARGET="$HOST_ARCH-apple-macos12.0"

CLT_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
XCODE_ROOT="/Applications/Xcode.app/Contents/Developer"
XCODE_XT="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain"
XCODE_SDK="$XCODE_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

IBTOOL="${IBTOOL:-$XCODE_ROOT/usr/bin/ibtool}"
PY="${PYTHON:-python3}"
TIMEOUT_BIN="$(command -v gtimeout || command -v timeout || true)"

# ibtool 在本机第一次跑要几十秒（冷启动），之后秒回；这里给足额度
IBTOOL_TIMEOUT="${IBTOOL_TIMEOUT:-180}"
RUN_TIMEOUT="${RUN_TIMEOUT:-60}"

PASS=0
FAIL=0
DIFF=0
declare -a FAILURES
NFAIL=0

log_line() { printf '%s\n' "$*"; }

# ---------------------------------------------------------------- 工具选择 --
lane_sdk() {
    if [ "$1" = "xcode" ]; then printf '%s' "$XCODE_SDK"; else printf '%s' "$CLT_SDK"; fi
}
lane_swiftc() {
    if [ "$1" = "xcode" ]; then printf '%s' "$XCODE_XT/usr/bin/swiftc"; else printf '%s' "${SWIFTC_CLT:-/usr/bin/swiftc}"; fi
}
lane_clang() {
    if [ "$1" = "xcode" ]; then printf '%s' "$XCODE_XT/usr/bin/clang"; else printf '%s' "${CLANG_CLT:-/usr/bin/clang}"; fi
}

LANES=""
if [ -x "$(lane_swiftc clt)" ] && [ -x "$(lane_clang clt)" ] && [ -d "$(lane_sdk clt)" ]; then
    LANES="clt"
fi
if [ -x "$(lane_swiftc xcode)" ] && [ -x "$(lane_clang xcode)" ] && [ -d "$(lane_sdk xcode)" ]; then
    LANES="$LANES xcode"
fi
if [ -z "$LANES" ]; then
    log_line "错误：没有找到任何可用的 Swift 工具链"
    exit 1
fi

# ------------------------------------------------------------ 判定辅助函数 --
# 注意：处理「待验证输出」的 tr / grep 一律加 LC_ALL=C。
# UTF-8 locale 下 toybox 的 tr 碰到非法字节会报 Illegal byte sequence 并在那里
# 截断输入，结束标记落在截断点之后就会被误判成「缺少结束标记」。
has_ctrl() {
    LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}
marker_present() {
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null | LC_ALL=C grep -qF "$2"
}
run_with_timeout() {
    local secs="$1"; shift
    if [ -n "$TIMEOUT_BIN" ]; then
        "$TIMEOUT_BIN" -s TERM "$secs" "$@"
    else
        "$@"
    fi
}

# ---------------------------------------------------------------- XIB 部分 --
compile_nibs() {
    # $1 = 示例目录，$2 = 输出目录（运行时的工作目录兼 Bundle 资源目录）
    local dir="$1" out="$2" xib base rc
    for xib in $(cd "$dir" && ls *.xib 2>/dev/null | sort); do
        base="${xib%.xib}"
        log_line "        [ibtool] $xib -> $base.nib"
        DEVELOPER_DIR="$XCODE_ROOT" run_with_timeout "$IBTOOL_TIMEOUT" \
            "$IBTOOL" --compile "$out/$base.nib" "$dir/$xib" > "$out/ibtool.$base.log" 2>&1
        rc=$?
        if [ "$rc" -ne 0 ]; then
            log_line "        ibtool 编译失败（退出码 $rc）：$out/ibtool.$base.log"
            sed 's/^/        /' "$out/ibtool.$base.log" 2>/dev/null | head -20
            return 1
        fi
        if [ -s "$out/ibtool.$base.log" ]; then
            log_line "        ibtool 有告警（日志非空）：$out/ibtool.$base.log"
            return 1
        fi
    done
    return 0
}

# -------------------------------------------------------------- 编译单个通道 --
build_lane() {
    # $1 = 示例目录名，$2 = 通道名
    local name="$1" lane="$2"
    local dir="$EXAMPLES/$name" out="$BUILD/$name"
    local mod="${name#*_}"
    local swiftc clang sdk log extra=""
    swiftc="$(lane_swiftc "$lane")"
    clang="$(lane_clang "$lane")"
    sdk="$(lane_sdk "$lane")"
    log="$out/build.$lane.log"
    : > "$log"

    local -a srcs objs frameworks
    srcs=(); objs=(); frameworks=()
    local f
    for f in $(cd "$dir" && ls *.swift 2>/dev/null | sort); do srcs+=("$dir/$f"); done
    for f in $(cd "$dir" && ls *.m 2>/dev/null | sort); do objs+=("$dir/$f"); done

    if [ -f "$dir/Frameworks" ]; then
        while IFS= read -r line; do
            line="${line%%#*}"
            line="$(printf '%s' "$line" | tr -d '[:space:]')"
            [ -n "$line" ] && frameworks+=("-framework" "$line")
        done < "$dir/Frameworks"
    fi

    local bridge=""
    for f in "$dir"/Bridging.h "$dir"/bridging.h; do
        [ -f "$f" ] && bridge="$f"
    done

    local target_args=(-sdk "$sdk" -target "$DEPLOY_TARGET")
    local bin="$out/$name.$lane"

    if [ "${#objs[@]}" -eq 0 ]; then
        # ---- 纯 Swift ----
        "$swiftc" -O "${target_args[@]}" -module-name "$mod" \
            ${srcs[@]+"${srcs[@]}"} -o "$bin" -framework Foundation -framework AppKit \
            ${frameworks[@]+"${frameworks[@]}"} >> "$log" 2>&1
        return $?
    fi

    if [ "${#srcs[@]}" -eq 0 ]; then
        # ---- 纯 Objective-C ----
        "$clang" -O2 -std=gnu11 -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter \
            -isysroot "$sdk" -target "$DEPLOY_TARGET" -I "$dir" \
            ${objs[@]+"${objs[@]}"} -o "$bin" -framework Foundation -framework AppKit \
            ${frameworks[@]+"${frameworks[@]}"} >> "$log" 2>&1
        return $?
    fi

    # ---- Swift + Objective-C 混编 ----
    # Xcode 的做法：先把 Swift 编一遍（顺带产出 <Module>-Swift.h），
    # 再编 Objective-C，最后一起链接。这里手工复刻同样的两步。
    local needs_hdr=0
    [ -f "$dir/Needs-Swift-Header" ] && needs_hdr=1

    local -a swiftobjs
    swiftobjs=()
    # 坑：swiftc -c 多文件时把 .o 写在**当前目录**，不是 -o 指定的地方。
    # 不 cd 进 build/<示例>/ 的话，main.o 会散落到仓库根目录里。
    if [ "$needs_hdr" -eq 1 ]; then
        ( cd "$out" && "$swiftc" -c "${target_args[@]}" -module-name "$mod" \
            -import-objc-header "$bridge" \
            -emit-objc-header-path "$out/SwiftBridge-Swift.h" \
            ${srcs[@]+"${srcs[@]}"} ) >> "$log" 2>&1
        local rc=$?
        [ "$rc" -ne 0 ] && return "$rc"
        local sbase
        for f in ${srcs[@]+"${srcs[@]}"}; do
            sbase="$(basename "$f" .swift)"
            swiftobjs+=("$out/$sbase.o")
        done
    else
        ( cd "$out" && "$swiftc" -c "${target_args[@]}" -module-name "$mod" \
            -import-objc-header "$bridge" ${srcs[@]+"${srcs[@]}"} ) >> "$log" 2>&1
        local rc=$?
        [ "$rc" -ne 0 ] && return "$rc"
        local sbase
        for f in ${srcs[@]+"${srcs[@]}"}; do
            sbase="$(basename "$f" .swift)"
            swiftobjs+=("$out/$sbase.o")
        done
    fi

    local -a cobjects
    cobjects=()
    for f in ${objs[@]+"${objs[@]}"}; do
        local obase
        obase="$(basename "$f" .m)"
        "$clang" -c -O2 -std=gnu11 -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter \
            -isysroot "$sdk" -target "$DEPLOY_TARGET" -I "$dir" -I "$out" \
            "$f" -o "$out/$obase.$lane.o" >> "$log" 2>&1
        if [ $? -ne 0 ]; then return 1; fi
        cobjects+=("$out/$obase.$lane.o")
    done

    "$swiftc" "${target_args[@]}" ${swiftobjs[@]+"${swiftobjs[@]}"} ${cobjects[@]+"${cobjects[@]}"} -o "$bin" \
        -framework Foundation -framework AppKit ${frameworks[@]+"${frameworks[@]}"} >> "$log" 2>&1
    return $?
}

# -------------------------------------------------------------- 判定单个通道 --
check_lane() {
    # $1 = 示例目录名，$2 = 通道名，$3 = 结束标记
    local name="$1" lane="$2" marker="$3"
    local out="$BUILD/$name"
    local stdout_f="$out/stdout.$lane.txt" stderr_f="$out/stderr.$lane.txt"
    local log="$out/build.$lane.log"
    local -a why
    why=()

    if [ -s "$log" ]; then why+=("编译日志非空（有告警）"); fi
    if [ ! -f "$out/exit.$lane" ]; then why+=("没有退出码文件（进程未正常收尾）"); fi
    if [ -f "$out/exit.$lane" ] && [ "$(cat "$out/exit.$lane")" != "0" ]; then
        why+=("退出码 $(cat "$out/exit.$lane")")
    fi
    if [ -s "$stderr_f" ]; then why+=("stderr 非空"); fi
    if [ ! -s "$stdout_f" ]; then why+=("stdout 为空"); fi
    if has_ctrl "$stdout_f"; then why+=("输出含多余控制字符"); fi
    if ! marker_present "$stdout_f" "$marker"; then why+=("缺少结束标记"); fi

    if [ "${#why[@]}" -eq 0 ]; then
        PASS=$((PASS + 1))
        log_line "      [$lane] PASS"
        return 0
    fi
    FAIL=$((FAIL + 1))
    local reason sep item
    sep="、"; reason=""
    for item in "${why[@]}"; do reason="${reason}${item}${sep}"; done
    FAILURES+=("失败: ${name} [$lane] ${reason%$sep}")
    NFAIL=$((NFAIL + 1))
    log_line "      [$lane] FAIL —— ${reason%$sep}"
    return 1
}

# ------------------------------------------------------------------ 主流程 --
clean_build() {
    if [ -d "$BUILD" ]; then
        find "$BUILD" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + 2>/dev/null
        find "$BUILD" -mindepth 1 -maxdepth 1 -type f -exec rm -f {} + 2>/dev/null
    fi
    log_line "已清空 $BUILD"
}

only=()
if [ "${1:-}" = "--clean" ]; then
    clean_build
    exit 0
fi
for a in "$@"; do only+=("$a"); done

if [ -d "$BUILD" ] && [ -z "${only[*]:-}" ]; then
    log_line "提示：build/ 里可能有上一轮产物，需要干净重跑请先 ./run-all.sh --clean"
fi

names=()
for d in $(cd "$EXAMPLES" && ls -d [0-9][0-9]_* 2>/dev/null | sort); do
    keep=1
    if [ "${#only[@]}" -gt 0 ]; then
        keep=0
        for want in "${only[@]}"; do
            case "$d" in "${want}"_*|"${want}") keep=1 ;; esac
        done
    fi
    [ "$keep" -eq 1 ] && names+=("$d")
done
if [ "${#names[@]}" -eq 0 ]; then
    log_line "没有匹配到示例"
    exit 1
fi

# --- 静态检查：XIB 与源码是否一致（编译之前） ---
if [ -f "$TOOLS/check_xib.py" ]; then
    log_line "=== XIB 静态一致性检查 ==="
    "$PY" "$TOOLS/check_xib.py" "$EXAMPLES" || exit 1
    log_line ""
fi

log_line "=== 工具链 ==="
for lane in $LANES; do
    log_line "  $lane : swiftc=$(lane_swiftc "$lane")"
    log_line "          clang =$(lane_clang "$lane")"
    log_line "          sdk   =$(lane_sdk "$lane")"
done
log_line "  部署目标 = $DEPLOY_TARGET"
log_line ""

for name in "${names[@]}"; do
    nn="$(printf '%s' "$name" | cut -d_ -f1)"
    marker="==== $nn 结束 ===="
    outdir="$BUILD/$name"
    mkdir -p "$outdir"
    log_line "[$name]"

    if ! compile_nibs "$EXAMPLES/$name" "$outdir"; then
        FAIL=$((FAIL + 1))
        FAILURES+=("失败: ${name} XIB 编译阶段失败")
        NFAIL=$((NFAIL + 1))
        log_line "      [XIB] FAIL"
        continue
    fi

    for lane in $LANES; do
        if ! build_lane "$name" "$lane"; then
            FAIL=$((FAIL + 1))
            FAILURES+=("失败: ${name} [$lane] 构建失败，见 $outdir/build.$lane.log")
            NFAIL=$((NFAIL + 1))
            log_line "      [$lane] 构建失败"
            sed 's/^/        /' "$outdir/build.$lane.log" 2>/dev/null | head -25
            continue
        fi
        # 运行：工作目录必须是 build/<示例>/ —— Bundle.main 的资源路径就是可执行文件所在目录，
        # 编译好的 .nib 也放在那里；同时保证示例写临时文件时不会散到仓库里。
        ( cd "$outdir" && run_with_timeout "$RUN_TIMEOUT" "./$name.$lane" --selftest \
            > "stdout.$lane.txt" 2> "stderr.$lane.txt" )
        printf '%s' "$?" > "$outdir/exit.$lane"
        check_lane "$name" "$lane" "$marker"
    done

    # --- 双通道输出逐字节比对 ---
    if [ "$(printf '%s' "$LANES" | wc -w | tr -d ' ')" = "2" ]; then
        a="$outdir/stdout.clt.txt"; b="$outdir/stdout.xcode.txt"
        if [ -f "$a" ] && [ -f "$b" ]; then
            if cmp -s "$a" "$b"; then
                log_line "      [cmp] 双工具链输出逐字节一致"
            else
                DIFF=$((DIFF + 1))
                FAILURES+=("差异: ${name} 两套工具链输出不一致")
                NFAIL=$((NFAIL + 1))
                log_line "      [cmp] DIFF —— 两套工具链输出不一样"
                diff <(cat "$a") <(cat "$b") | head -20 | sed 's/^/        /'
            fi
        fi
    fi
done

log_line ""
log_line "=========================================================="
log_line " 通过 $PASS   失败 $FAIL   输出差异 $DIFF   示例 ${#names[@]}   通道 $(printf '%s' "$LANES" | wc -w | tr -d ' ')"
if [ "$NFAIL" -gt 0 ]; then
    for line in ${FAILURES[@]+"${FAILURES[@]}"}; do log_line "  $line"; done
fi
log_line "=========================================================="
if [ "$FAIL" -ne 0 ] || [ "$DIFF" -ne 0 ]; then
    exit 1
fi
exit 0
