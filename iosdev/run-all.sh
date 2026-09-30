#!/bin/bash
# ============================================================================
# iOS 应用开发教程（iosdev）—— 构建 / 模拟器运行 / 六条判定 / Debug·Release 比对
#
#   ./run-all.sh              跑全部示例
#   ./run-all.sh 07           只跑编号 07 的示例（可给多个编号）
#   ./run-all.sh --clean      清空 build/
#   ./run-all.sh --keep-booted 结束后不关闭本脚本启动的模拟器
#
# 与 macosdev 的关键差异：
#   iOS SDK 只随 Xcode 提供，Command Line Tools 里没有，所以**只有一条工具链**
#   （Xcode + iphonesimulator）。为了保留「双通道逐字节比对」这张安全网，
#   这里改成**同一工具链的两个优化配置**：debug(-Onone) 与 release(-O)。
#   两份产物都在模拟器里跑，stdout 必须逐字节一致 —— 能挡住「只在 -O 下才暴露」
#   的未定义行为、以及依赖优化等级的巧合。
#
# 运行方式：为 iphonesimulator 编译成命令行可执行文件，用
#   xcrun simctl spawn <UDID> <bin> --selftest
# 在一台已启动的 iPhone 模拟器里跑。示例是 headless 自测：构造 SwiftUI View /
# UIViewController / Foundation 对象，跑断言，打印，退出 —— 不建窗口、不弹 UI、
# 不调 UIApplicationMain。这样既真用了 iOS SDK 与 UIKit/SwiftUI 运行时，
# 又能像命令行程序一样被六条判定卡住。
#
# 六条判定（任一条失败即 FAIL，脚本最终退出码 1）：
#   1) 编译日志为空      —— 零告警（-Wall -Wextra；SDKROOT 已设，无 sysroot 噪声）
#   2) 退出码为 0
#   3) stderr 为空
#   4) stdout 非空       —— 挡住「进程根本没执行到业务代码、退出码却是 0」
#   5) stdout 无多余控制字符（0..31 除 TAB/LF/CR）
#   6) stdout 有结束标记 "==== NN 结束 ===="
#
# 外加一条：debug 与 release 两个配置的 stdout 逐字节一致。
#
# 界面文件：示例目录里的 .storyboard / .xib 会先经 ibtool 编译成 .storyboardc /
# .nib，和二进制一起放进 build/<示例>/；示例还可以放一个 Resources/ 目录，内容
# 原样拷进同一处。命令行可执行文件的 Bundle.main 就是它自己所在的目录，所以示例
# 代码里直接 UIStoryboard(name:bundle:nil) 就能取到故事板，不用拼任何路径。
# ibtool 的输出同样进 build.<配置>.log —— 故事板里冒出个告警（deprecated segue、
# 无入口的场景……）也算判定 1 失败。
# ============================================================================
set -u

TOP="$(cd "$(dirname "$0")" && pwd)"
EXAMPLES="$TOP/examples"
BUILD="$TOP/build"
TOOLS="$TOP/tools"

# ---- 目标平台 ---------------------------------------------------------------
HOST_ARCH="$(uname -m)"
case "$HOST_ARCH" in
    arm64) SIM_ARCH="arm64" ;;
    *)     SIM_ARCH="x86_64" ;;
esac
# 本机 Xcode 16.2 / iOS SDK 18.2，模拟器运行时 iOS 18.3.1。
# 部署目标钉在 15.0（远低于 SDK）：误用了 iOS 16/17/18 才有的 API 会在**编译期**
# 就暴露，而不是编过、跑到旧系统上才崩。示例都兼容到 15.0，需要新 API 时用
# #available / @available 显式守卫。
DEPLOY_TARGET="$SIM_ARCH-apple-ios15.0-simulator"

XCODE_ROOT="$(xcode-select -p)"
XCODE_XT="$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain"
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
SWIFTC="$XCODE_XT/usr/bin/swiftc"
CLANG="$XCODE_XT/usr/bin/clang"
# SwiftPM 用的是 `swift`（不是 swiftc）：`swift build --package-path …`。
# 和 swiftc 同一个工具链，免得两套版本对不上。
SWIFT="$XCODE_XT/usr/bin/swift"
# 界面文件（.storyboard / .xib）由 ibtool 编译成 .storyboardc / .nib。
# 部署目标从 DEPLOY_TARGET 里抠出来（x86_64-apple-ios15.0-simulator → 15.0），
# 免得两处数字各改各的。
ITOOL="$(xcrun -f ibtool)"
IB_MIN_DEPLOY="$(printf '%s' "$DEPLOY_TARGET" | sed -e 's/.*ios//' -e 's/-[^-]*$//')"

# SDKROOT 一设，swiftc 调用 clang 链接时就不会再默认 MacOSX sysroot，
# 也就没有那条 -Wincompatible-sysroot 噪声（判定 1 要求编译日志全空）。
export SDKROOT="$SDK"

PY="${PYTHON:-python3}"
TIMEOUT_BIN="$(command -v gtimeout || command -v timeout || true)"
RUN_TIMEOUT="${RUN_TIMEOUT:-90}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-300}"

# 两个优化配置（充当 macosdev 里的“双通道”）
CONFIGS="debug release"
config_flag() { if [ "$1" = "release" ]; then printf '%s' "-O"; else printf '%s' "-Onone"; fi; }

PASS=0
FAIL=0
DIFF=0
declare -a FAILURES
NFAIL=0

log_line() { printf '%s\n' "$*"; }

# ------------------------------------------------------------ 判定辅助函数 --
# 处理「待验证输出」的 tr / grep 一律加 LC_ALL=C：UTF-8 locale 下 toybox 的 tr
# 碰到非法字节会报 Illegal byte sequence 并截断输入，结束标记落在截断点之后
# 就会被误判成「缺少结束标记」。
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

# ---------------------------------------------------------------- 模拟器管理 --
SIM_UDID=""
WE_BOOTED=0
pick_and_boot_sim() {
    # 优先复用已启动的 iPhone/iPad；否则挑一台可用的 iPhone 启动
    SIM_UDID="$(xcrun simctl list devices booted 2>/dev/null \
        | grep -iE 'iPhone|iPad' | grep -oE '\([0-9A-F-]{36}\)' | tr -d '()' | head -1)"
    if [ -n "$SIM_UDID" ]; then
        log_line "  复用已启动的模拟器：$SIM_UDID"
        return 0
    fi
    SIM_UDID="$(xcrun simctl list devices available 2>/dev/null \
        | grep -iE 'iPhone' | grep -oE '\([0-9A-F-]{36}\)' | tr -d '()' | head -1)"
    if [ -z "$SIM_UDID" ]; then
        log_line "错误：找不到任何可用的 iPhone 模拟器（xcrun simctl list devices available）"
        exit 1
    fi
    log_line "  启动模拟器：$SIM_UDID（首次冷启动可能要一两分钟）"
    xcrun simctl boot "$SIM_UDID" >/dev/null 2>&1 || true
    if ! run_with_timeout "$BOOT_TIMEOUT" xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null 2>&1; then
        log_line "错误：模拟器启动超时（$BOOT_TIMEOUT 秒）"
        exit 1
    fi
    WE_BOOTED=1
    return 0
}
maybe_shutdown_sim() {
    if [ "$WE_BOOTED" = "1" ] && [ "$KEEP_BOOTED" = "0" ] && [ -n "$SIM_UDID" ]; then
        xcrun simctl shutdown "$SIM_UDID" >/dev/null 2>&1 || true
        log_line "  已关闭本脚本启动的模拟器 $SIM_UDID（--keep-booted 可保留）"
    fi
}

# 在模拟器里跑一个可执行文件：$1=二进制绝对路径，$2=stdout 文件，$3=stderr 文件，$4=退出码文件
sim_run() {
    local bin="$1" outf="$2" errf="$3" exitf="$4"
    ( run_with_timeout "$RUN_TIMEOUT" xcrun simctl spawn "$SIM_UDID" "$bin" --selftest \
        > "$outf" 2> "$errf" )
    printf '%s' "$?" > "$exitf"
}

# -------------------------------------------------------------- 编译单个配置 --
build_config() {
    # $1 = 示例目录名，$2 = 配置名（debug/release）
    local name="$1" cfg="$2"
    local dir="$EXAMPLES/$name" out="$BUILD/$name"
    local mod="${name#*_}"
    local opt log
    opt="$(config_flag "$cfg")"
    log="$out/build.$cfg.log"
    : > "$log"

    # SwiftPM 依赖包（见 build_packages）在这里并进主线，两样东西：
    #   1) 包编译器说过的告警/错误 —— 必须在这句截断**之后**才并进 build.<配置>.log，
    #      否则会被上面那行抹掉，包里的告警就悄悄不算失败了；
    #   2) swiftc 要多吃的输入（-I / -Xcc -fmodule-map-file / 各 target 的 .o）。
    # 只接「纯 Swift」那条分支：用包的示例就是纯 Swift。混编示例要用包，得先把
    # swiftc -c 那一步也带上这批输入，这里没有铺。
    local -a pmargs
    pmargs=()
    local arg
    if [ -s "$out/spm.$cfg.diags" ]; then
        cat "$out/spm.$cfg.diags" >> "$log"
    fi
    if [ -f "$out/spm/$cfg.extra.args" ]; then
        while IFS= read -r arg; do
            [ -n "$arg" ] && pmargs+=("$arg")
        done < "$out/spm/$cfg.extra.args"
    fi

    local -a srcs objs csrcs frameworks
    srcs=(); objs=(); csrcs=(); frameworks=()
    local f
    for f in $(cd "$dir" && ls *.swift 2>/dev/null | sort); do srcs+=("$dir/$f"); done
    for f in $(cd "$dir" && ls *.m 2>/dev/null | sort); do objs+=("$dir/$f"); done
    for f in $(cd "$dir" && ls *.c 2>/dev/null | sort); do csrcs+=("$dir/$f"); done

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

    local target_args=(-sdk "$SDK" -target "$DEPLOY_TARGET")
    local bin="$out/$name.$cfg"

    # ---- 纯 C 文件先单独编一遍 ----
    # 关键：绝不能给 .c 传 -fobjc-arc，clang 会对它报「argument unused / 只适用于 ObjC」的告警，
    # 而本教程要求编译日志为空。所以 C 文件走一条没有 ObjC 开关的命令。
    local -a csrcobjs
    csrcobjs=()
    for f in ${csrcs[@]+"${csrcs[@]}"}; do
        local cbase
        cbase="$(basename "$f" .c)"
        "$CLANG" -c -O2 -std=gnu11 -fmodules -Wall -Wextra -Wno-unused-parameter \
            -isysroot "$SDK" -target "$DEPLOY_TARGET" -I "$dir" \
            "$f" -o "$out/$cbase.$cfg.o" >> "$log" 2>&1
        if [ $? -ne 0 ]; then return 1; fi
        csrcobjs+=("$out/$cbase.$cfg.o")
    done

    if [ "${#objs[@]}" -eq 0 ] && [ "${#csrcobjs[@]}" -eq 0 ]; then
        # ---- 纯 Swift ----
        "$SWIFTC" "$opt" "${target_args[@]}" -module-name "$mod" \
            ${srcs[@]+"${srcs[@]}"} -o "$bin" \
            -framework Foundation -framework UIKit -framework SwiftUI \
            ${frameworks[@]+"${frameworks[@]}"} ${pmargs[@]+"${pmargs[@]}"} >> "$log" 2>&1
        return $?
    fi

    if [ "${#srcs[@]}" -eq 0 ]; then
        # ---- 纯 Objective-C（或纯 C）----
        # 没有 .m 时不传 -fobjc-arc，免得链接阶段冒出「argument unused」告警
        local -a arcf
        arcf=("-fobjc-arc")
        [ "${#objs[@]}" -eq 0 ] && arcf=()
        "$CLANG" -O2 -std=gnu11 -fmodules -Wall -Wextra -Wno-unused-parameter "${arcf[@]}" \
            -isysroot "$SDK" -target "$DEPLOY_TARGET" -I "$dir" \
            ${objs[@]+"${objs[@]}"} ${csrcobjs[@]+"${csrcobjs[@]}"} -o "$bin" \
            -framework Foundation -framework UIKit \
            ${frameworks[@]+"${frameworks[@]}"} >> "$log" 2>&1
        return $?
    fi

    # ---- Swift + Objective-C 混编 ----
    # Xcode 的做法：先把 Swift 编一遍（顺带产出 <Module>-Swift.h），再编 OC，最后链接。
    local needs_hdr=0
    [ -f "$dir/Needs-Swift-Header" ] && needs_hdr=1

    local -a swiftobjs
    swiftobjs=()
    # 坑：swiftc -c 多文件时把 .o 写在**当前目录**，不是 -o 指定的地方。
    # 所以 cd 进 build/<示例>/ 再编，免得 .o 散落到仓库根目录。
    if [ "$needs_hdr" -eq 1 ]; then
        ( cd "$out" && "$SWIFTC" -c "$opt" "${target_args[@]}" -module-name "$mod" \
            -import-objc-header "$bridge" \
            -emit-objc-header-path "$out/SwiftBridge-Swift.h" \
            ${srcs[@]+"${srcs[@]}"} ) >> "$log" 2>&1
    else
        ( cd "$out" && "$SWIFTC" -c "$opt" "${target_args[@]}" -module-name "$mod" \
            -import-objc-header "$bridge" ${srcs[@]+"${srcs[@]}"} ) >> "$log" 2>&1
    fi
    local rc=$?
    [ "$rc" -ne 0 ] && return "$rc"
    for f in ${srcs[@]+"${srcs[@]}"}; do
        swiftobjs+=("$out/$(basename "$f" .swift).o")
    done

    local -a cobjects
    cobjects=()
    for f in ${objs[@]+"${objs[@]}"}; do
        local obase
        obase="$(basename "$f" .m)"
        "$CLANG" -c -O2 -std=gnu11 -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter \
            -isysroot "$SDK" -target "$DEPLOY_TARGET" -I "$dir" -I "$out" \
            "$f" -o "$out/$obase.$cfg.o" >> "$log" 2>&1
        if [ $? -ne 0 ]; then return 1; fi
        cobjects+=("$out/$obase.$cfg.o")
    done

    "$SWIFTC" "$opt" "${target_args[@]}" \
        ${swiftobjs[@]+"${swiftobjs[@]}"} ${cobjects[@]+"${cobjects[@]}"} \
        ${csrcobjs[@]+"${csrcobjs[@]}"} -o "$bin" \
        -framework Foundation -framework UIKit -framework SwiftUI \
        ${frameworks[@]+"${frameworks[@]}"} >> "$log" 2>&1
    return $?
}

# ---------------------------------------------------------- 界面文件与资源 --
# 示例目录里可以额外放两样东西：
#   *.storyboard / *.xib —— 用 ibtool 编成 <同名>.storyboardc / <同名>.nib
#   Resources/           —— 目录内容原样拷进 build/<示例>/
# 两者都放进 build/<示例>/，也就是**二进制自己所在的那个目录**。这不是巧合，是
# 命令行可执行文件的 Bundle.main 语义：为本机跑的可执行文件（不是 .app），
# Bundle.main 就是它所在的目录，resourcePath 也等于那个目录（实测见第 31 章）。
# 于是示例里既不用拼路径也不用读环境变量，直接 UIStoryboard(name:bundle:nil)、
# Bundle.main.url(forResource:withExtension:)、UINib(nibName:bundle:nil) 就能取到。
#
# ibtool 的 stdout/stderr 一律追加进 build.<配置>.log，所以界面文件里任何一个
# 告警或错误都会撞上判定 1（编译日志为空）—— 故事板里遗留的「deprecated segue」
# 「无法访问的场景」这类问题，在这里和被弃用的 API 一样是硬失败。
compile_interfaces() {
    # $1 = 示例目录名，$2 = 配置名
    local name="$1" cfg="$2"
    local dir="$EXAMPLES/$name"
    local out="$BUILD/$name"
    local log="$out/build.$cfg.log"
    local f base
    # 先清掉上一轮编出来的界面产物，免得改名或删掉某个 .storyboard 之后，
    # 旧 .storyboardc 还留在 build/ 里被 Bundle.main 捡到，跑出「改了源码却
    # 还是老界面」的假绿。
    find "$out" -maxdepth 1 \( -name '*.storyboardc' -o -name '*.nib' \) -exec rm -rf {} + 2>/dev/null
    for f in $(cd "$dir" && ls *.storyboard 2>/dev/null | sort); do
        base="${f%.storyboard}"
        "$ITOOL" --compile "$out/$base.storyboardc" "$dir/$f" \
            --errors --warnings --notices \
            --target-device iphone --minimum-deployment-target "$IB_MIN_DEPLOY" \
            --output-format human-readable-text >> "$log" 2>&1
        if [ $? -ne 0 ]; then return 1; fi
    done
    for f in $(cd "$dir" && ls *.xib 2>/dev/null | sort); do
        base="${f%.xib}"
        "$ITOOL" --compile "$out/$base.nib" "$dir/$f" \
            --errors --warnings --notices \
            --target-device iphone --minimum-deployment-target "$IB_MIN_DEPLOY" \
            --output-format human-readable-text >> "$log" 2>&1
        if [ $? -ne 0 ]; then return 1; fi
    done
    if [ -d "$dir/Resources" ]; then
        mkdir -p "$out"
        cp -R "$dir/Resources/." "$out/" >> "$log" 2>&1
        if [ $? -ne 0 ]; then return 1; fi
    fi
    return 0
}

# ---------------------------------------------------------- SwiftPM 依赖包 --
# 示例目录里放一个 `Needs-SwiftPM`，它的**每一行**是一个包目录（相对示例目录），
# 脚本就按当前配置对每个包跑一遍
#   swift build --triple $DEPLOY_TARGET --sdk $SDK -c debug|release
#           --scratch-path build/<示例>/spm/<配置>
# 然后把编好的 .o、.swiftmodule、C 语言的 module.modulemap 接到主线的 swiftc 上。
#
# 为什么要单独立一条判定之外的日志：`swift build` 会打「Building for debugging… /
# Build complete!」这类进度文本，它们不是编译器诊断，进 build.<配置>.log 会让每个
# 用包的示例都撞上判定 1（编译日志为空）。所以进度文本进 spm.<配置>.log，
# 而从里面**筛出**含 warning/error 的行放进 spm.<配置>.diags，由 build_config 在
# 清空 build.<配置>.log 之后接进去 —— 包里的告警照样是硬失败，构建噪声不算。
# （顺序很关键：`swift build` 一定跑在 build_config **把日志截断**之前，
# 所以诊断不能由这里直接写 build.<配置>.log，否则会被那句 `: > "$log"` 抹掉。）
#
# 这一条也是本章正文的落点：Xcode 里点一下「Add Package」就消失的那些步骤
# （解析、编到哪个中间目录、C 语言的 module map 谁递给 clang、资源 bundle 放哪），
# 在这里全是看得见的命令与文件。
build_packages() {
    # $1 = 示例目录名，$2 = 配置名
    local name="$1" cfg="$2"
    local dir="$EXAMPLES/$name" out="$BUILD/$name"
    local pmlog="$out/spm.$cfg.log" diags="$out/spm.$cfg.diags"
    local root rc

    : > "$pmlog"
    : > "$diags"
    while IFS= read -r root; do
        root="${root%%#*}"
        root="$(printf '%s' "$root" | tr -d '[:space:]')"
        [ -z "$root" ] && continue
        if [ ! -f "$dir/$root/Package.swift" ]; then
            printf 'error: Needs-SwiftPM 指定的目录里没有 Package.swift：%s\n' "$root" >> "$pmlog"
            return 1
        fi
        # SwiftPM 的 -c 只认 debug/release，正好和本教程两个配置同名。
        #
        # `env -u SDKROOT` 不是保险，是**必须**：Package.swift 自己是一段要编译执行的
        # Swift 程序（manifest），而它只能为**主机**编（x86_64-apple-macosx13.0）。
        # 本脚本为了压掉 sysroot 告警把 SDKROOT 指到模拟器 SDK（见文件头），SwiftPM 会
        # 把它一起递给 manifest 的编译，于是当场失败：
        #   <unknown>:0: warning: using sysroot for 'iPhoneSimulator' but targeting 'MacOSX'
        #   <unknown>:0: error: unable to load standard library for target 'x86_64-apple-macosx13.0'
        # 目标侧的 SDK 不靠这个环境变量，走下面的 --sdk 显式传；manifest 因此回到主机 SDK。
        run_with_timeout "${BUILD_TIMEOUT:-600}" env -u SDKROOT "$SWIFT" build \
            --package-path "$dir/$root" \
            --scratch-path "$out/spm/$cfg/$(basename "$root")" \
            --triple "$DEPLOY_TARGET" --sdk "$SDK" -c "$cfg" >> "$pmlog" 2>&1
        rc=$?
        if [ "$rc" -ne 0 ]; then
            printf 'error: swift build 退出码 %s（见 %s）\n' "$rc" "$pmlog" >> "$pmlog"
            return 1
        fi
        # 把包编译器说过的告警/错误挑出来，交给 build_config 并进了日志
        grep -E '^(warning|error):| warning: | error: ' "$pmlog" >> "$diags" 2>/dev/null
    done < "$dir/Needs-SwiftPM"
    return 0
}

# 把上一个函数编出来的东西汇成 swiftc 的输入，按行写进
# build/<示例>/spm/<配置>.extra.args（每行一个参数或一个 .o 路径）：
#   -I <中间目录>/Modules                     —— .swiftmodule 在这里
#   -Xcc -fmodule-map-file=<T>.build/module.modulemap
#                                            —— **只给 C 语言的 target**：Swift target
#   的 modulemap 指向的是 <T>-Swift.h，再递一遍会和 Modules/<T>.swiftmodule 撞名
#   <T>.build/*.o                             —— 各 target 编好的目标文件，链接期要用
# 顺带把 <T>_<T>.bundle 拷进 build/<示例>/（也就是二进制自己躺的那个目录）。
# 这一步看着多余，其实是本机最容易骗过判定的一环：SwiftPM 生成的 Bundle.module
# 找资源只有两个候选位置 —— 二进制旁边的 <bundleName>.bundle，和**编译期写死在
# 二进制里的绝对中间目录路径**。后者在本机能命中，所以不拷 bundle 也照样跑出正确
# 输出；换台机器、或者把可执行文件单独拷走，才变成 fatalError。主线按前者摆。
#
# 这四类输入就是本章正文要量的东西：Xcode 里点「Add Package」之后全部由它替你
# 算好；命令行上它们是可数、可打印的。
spm_extra_args() {
    # $1 = 示例目录名，$2 = 配置名
    local name="$1" cfg="$2"
    local out="$BUILD/$name"
    local spmroot="$out/spm/$cfg"
    local args="$out/spm/$cfg.extra.args"
    local pkgdir cfgdir mm obj base b
    : > "$args"
    [ -d "$spmroot" ] || return 0
    for pkgdir in "$spmroot"/*/; do
        [ -d "$pkgdir" ] || continue
        for cfgdir in "$pkgdir"*/"$cfg"; do
            [ -d "$cfgdir/Modules" ] || continue
            printf '%s\n' "-I" "$cfgdir/Modules" >> "$args"
            for mm in "$cfgdir"/*.build/module.modulemap; do
                [ -f "$mm" ] || continue
                base="$(basename "$(dirname "$mm")" .build)"
                [ -f "$cfgdir/Modules/$base.swiftmodule" ] && continue
                printf '%s\n' "-Xcc" "-fmodule-map-file=$mm" >> "$args"
            done
            for obj in "$cfgdir"/*.build/*.o; do
                [ -f "$obj" ] || continue
                printf '%s\n' "$obj" >> "$args"
            done
            for b in "$cfgdir"/*.bundle; do
                [ -d "$b" ] || continue
                rm -rf "$out/$(basename "$b")"
                cp -R "$b" "$out/" || return 1
            done
        done
    done
    return 0
}

# -------------------------------------------------------------- 判定单个配置 --
check_config() {
    # $1 = 示例目录名，$2 = 配置名，$3 = 结束标记
    local name="$1" cfg="$2" marker="$3"
    local out="$BUILD/$name"
    local stdout_f="$out/stdout.$cfg.txt" stderr_f="$out/stderr.$cfg.txt"
    local log="$out/build.$cfg.log"
    local -a why
    why=()

    if [ -s "$log" ]; then why+=("编译日志非空（有告警）"); fi
    if [ ! -f "$out/exit.$cfg" ]; then why+=("没有退出码文件（进程未正常收尾）"); fi
    if [ -f "$out/exit.$cfg" ] && [ "$(cat "$out/exit.$cfg")" != "0" ]; then
        why+=("退出码 $(cat "$out/exit.$cfg")")
    fi
    if [ -s "$stderr_f" ]; then why+=("stderr 非空"); fi
    if [ ! -s "$stdout_f" ]; then why+=("stdout 为空"); fi
    if has_ctrl "$stdout_f"; then why+=("输出含多余控制字符"); fi
    if ! marker_present "$stdout_f" "$marker"; then why+=("缺少结束标记"); fi

    if [ "${#why[@]}" -eq 0 ]; then
        PASS=$((PASS + 1))
        log_line "      [$cfg] PASS"
        return 0
    fi
    FAIL=$((FAIL + 1))
    local reason sep item
    sep="、"; reason=""
    for item in "${why[@]}"; do reason="${reason}${item}${sep}"; done
    FAILURES+=("失败: ${name} [$cfg] ${reason%$sep}")
    NFAIL=$((NFAIL + 1))
    log_line "      [$cfg] FAIL —— ${reason%$sep}"
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

KEEP_BOOTED=0
only=()
for a in "$@"; do
    case "$a" in
        --clean) clean_build; exit 0 ;;
        --keep-booted) KEEP_BOOTED=1 ;;
        *) only+=("$a") ;;
    esac
done

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

log_line "=== 工具链 ==="
log_line "  Xcode 根 = $XCODE_ROOT"
log_line "  swiftc   = $SWIFTC"
log_line "  clang    = $CLANG"
log_line "  swift    = $SWIFT（只有 Needs-SwiftPM 的示例会用：swift build）"
log_line "  ibtool   = $ITOOL（界面文件最小部署目标 $IB_MIN_DEPLOY）"
log_line "  SDK      = $SDK"
log_line "  部署目标 = $DEPLOY_TARGET"
log_line "  配置     = debug(-Onone) / release(-O)"
log_line ""

log_line "=== 模拟器 ==="
pick_and_boot_sim
log_line ""

for name in "${names[@]}"; do
    nn="$(printf '%s' "$name" | cut -d_ -f1)"
    marker="==== $nn 结束 ===="
    outdir="$BUILD/$name"
    mkdir -p "$outdir"
    log_line "[$name]"

    for cfg in $CONFIGS; do
        # 先编包：build_config 需要包里的 .o / .swiftmodule / module map 已经就位
        if [ -f "$EXAMPLES/$name/Needs-SwiftPM" ]; then
            if ! build_packages "$name" "$cfg"; then
                FAIL=$((FAIL + 1))
                FAILURES+=("失败: ${name} [$cfg] SwiftPM 依赖包构建失败，见 $outdir/spm.$cfg.log")
                NFAIL=$((NFAIL + 1))
                log_line "      [$cfg] 依赖包构建失败"
                sed 's/^/        /' "$outdir/spm.$cfg.log" 2>/dev/null | head -25
                continue
            fi
            spm_extra_args "$name" "$cfg"
        fi
        if ! build_config "$name" "$cfg"; then
            FAIL=$((FAIL + 1))
            FAILURES+=("失败: ${name} [$cfg] 构建失败，见 $outdir/build.$cfg.log")
            NFAIL=$((NFAIL + 1))
            log_line "      [$cfg] 构建失败"
            sed 's/^/        /' "$outdir/build.$cfg.log" 2>/dev/null | head -25
            continue
        fi
        if ! compile_interfaces "$name" "$cfg"; then
            FAIL=$((FAIL + 1))
            FAILURES+=("失败: ${name} [$cfg] 界面文件（storyboard/xib）编译失败，见 $outdir/build.$cfg.log")
            NFAIL=$((NFAIL + 1))
            log_line "      [$cfg] 界面文件编译失败"
            sed 's/^/        /' "$outdir/build.$cfg.log" 2>/dev/null | head -25
            continue
        fi
        sim_run "$outdir/$name.$cfg" "$outdir/stdout.$cfg.txt" "$outdir/stderr.$cfg.txt" "$outdir/exit.$cfg"
        check_config "$name" "$cfg" "$marker"
    done

    # --- debug / release 输出逐字节比对 ---
    a="$outdir/stdout.debug.txt"; b="$outdir/stdout.release.txt"
    if [ -f "$a" ] && [ -f "$b" ] && [ -s "$a" ] && [ -s "$b" ]; then
        if cmp -s "$a" "$b"; then
            log_line "      [cmp] debug/release 输出逐字节一致"
        else
            DIFF=$((DIFF + 1))
            FAILURES+=("差异: ${name} debug 与 release 输出不一致")
            NFAIL=$((NFAIL + 1))
            log_line "      [cmp] DIFF —— 两个配置输出不一样"
            diff <(cat "$a") <(cat "$b") | head -20 | sed 's/^/        /'
        fi
    fi
done

maybe_shutdown_sim

log_line ""
log_line "=========================================================="
log_line " 通过 $PASS   失败 $FAIL   输出差异 $DIFF   示例 ${#names[@]}   配置 $(printf '%s' "$CONFIGS" | wc -w | tr -d ' ')"
if [ "$NFAIL" -gt 0 ]; then
    for line in ${FAILURES[@]+"${FAILURES[@]}"}; do log_line "  $line"; done
fi
log_line "=========================================================="
if [ "$FAIL" -ne 0 ] || [ "$DIFF" -ne 0 ]; then
    exit 1
fi
exit 0
