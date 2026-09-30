#!/bin/bash
# 第 33 章探针的批量跑法。
#
# 为什么要有探针而不是全写进主线：run-all.sh 的六条判定要求主线「编译日志为空、
# 退出码 0、stderr 为空、stdout 可复现，且 debug 与 release 两份输出逐字节一致」。
# 而本章要量的东西有一半天生进不了主线 —— 依赖管理器自己在命令行上说过的话
# （SwiftPM 的原生命令、它的 fixture、它的退出码），编译器的一句 error 原文，
# 一次运行期崩溃现场，只在某一种优化配置下才成立的数值行为。
#
# 编号约定（与 docs/33-dependency-management.md 的「探针记录」一一对应）：
#   sNN_*  SwiftPM 命令行现场：每支是一个 .sh，自己在临时目录里造包/造 git 仓库，
#          跑原生 `swift build` / `swift package` / `swift test`，抄命令原文与退出码。
#          本章一半的事实只有这里能拿到 —— 它们发生在主线编译**之前**。
#   eNN_*  编译期诊断：主线那套 swiftc 命令，故意少给一类输入（-I / modulemap /
#          可见性），抄 swiftc 原文，不运行
#   rNN_*  运行期现场：编好放进模拟器跑，抄 stdout / stderr / 退出码 / 崩溃原文
#   cNN_*  配置对照：同一份源码分别链 debug 与 release 两套包产物，抄两份输出的差异
#
# 用法：
#   ./probes/run.sh                 # 跑全部
#   ./probes/run.sh s02 e01         # 只跑编号前缀匹配的
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
CHAPTER="$(cd "$HERE/.." && pwd)"
XCODE_XT="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr"
SDK="$(xcrun -sdk iphonesimulator --show-sdk-path)"
TARGET="x86_64-apple-ios15.0-simulator"
SWIFT="$XCODE_XT/bin/swift"
SIM_UDID="${SIM_UDID:-2C5E3D2C-6F1B-4951-905F-AC00213FD5CF}"
# 模块名与主线一致：探针报的错才算同一个类型
MODULE="dependency_management"
TMP="${TMPDIR:-/tmp}/iosdev33probes"
# 包里带 .build 就没人管我们要干什么，所有探针一律只用 --scratch-path 写到这里
PKG="$TMP/pkg"
# 主线用的那套包产物：一次 swift build，eNN/rNN/cNN 都链它
SPMDBG="$TMP/spm/debug/WeatherKit/x86_64-apple-ios-simulator/debug"
SPMREL="$TMP/spm/release/WeatherKit/x86_64-apple-ios-simulator/release"
MODULES="$SPMDBG/Modules"

rm -rf "$TMP"; mkdir -p "$TMP"

show() { # $1 = 标签, $2 = 文件
    if [ -s "$2" ]; then
        printf -- '--- %s ---\n%s\n' "$1" "$(cat "$2")"
    else
        printf -- '--- %s ---（空）\n' "$1"
    fi
}

# ---------------------------------------------------------------- 包产物准备 --
# eNN/rNN/cNN 都要真的模块才能报出「少给一类输入」的那种错，所以先把本章的两个包
# 拷进 $TMP（**不**原地构建：包留在 examples/ 里被构建会写出 .build/，几百 MB）。
# 拷贝这一步无条件做：sNN 里也有拿本章的包当 fixture 的（s02/s09/s11）。
copy_packages() {
    rm -rf "$PKG"
    mkdir -p "$PKG"
    cp -R "$CHAPTER/Packages/ClimateCore" "$PKG/"
    cp -R "$CHAPTER/Packages/WeatherKit" "$PKG/"
}

prepare_package_builds() {
    local cfg out
    for cfg in debug release; do
        out="$TMP/spm/$cfg/WeatherKit"
        # env -u SDKROOT：manifest 是**主机**程序，见 s02 的原文
        env -u SDKROOT "$SWIFT" build \
            --package-path "$PKG/WeatherKit" --scratch-path "$out" \
            --triple "$TARGET" --sdk "$SDK" -c "$cfg" \
            > "$TMP/prepare.$cfg.txt" 2>&1
        if [ $? -ne 0 ]; then
            printf 'prepare_package_builds: swift build（%s）失败\n' "$cfg"
            cat "$TMP/prepare.$cfg.txt"
            return 1
        fi
    done
    return 0
}
copy_packages

# 把一支探针的 .args 文件展开成 swiftc 的参数：每行一个参数或一行 glob，
# 占位符统一在这里替换 —— 探针文件里因此不出现绝对路径，抄出来的命令才可比：
#   @MODULES@ 当前配置的 Modules 目录   @DIR@ 当前配置的中间目录（*.build 在那里面）
#   @DBG_DIR@ / @REL_DIR@ 写死两套之一   @TMP@ / @PKG@ 临时目录与包拷贝
# 含 `*` 的那一行是 glob（用来收各 target 的 .o）：路径前缀替换完仍然带着星号，
# 所以判断要看替换后的串，而不是行首。展开后一个文件都没匹配上时保留原文传给
# swiftc —— 让编译器报「少哪类输入」比在脚本里静默跳过好查。
# 模式写作 `*\**` 而不是 `*\*`：后者要求那颗星号**在串尾**，而 `.o` 在它后面，
# 于是整行原样进了 swiftc，直到链接那一步才由 clang 报出「no such file or directory」。
extra_args() { # $1 = base
    local f="$HERE/$1.args" line expanded matched m
    # 没写自己的 .args 就用默认那套（= 主线的全量输入），只有故意少给参数的探针才覆盖
    [ -f "$f" ] || f="$HERE/default.args"
    [ -f "$f" ] || return 0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        case "$line" in \#*) continue ;; esac
        expanded="$(printf '%s\n' "$line" \
            | sed -e "s|@MODULES@|$CUR_MODULES|g" \
                  -e "s|@DIR@|$CUR_DIR|g" \
                  -e "s|@DBG_DIR@|$SPMDBG|g" \
                  -e "s|@REL_DIR@|$SPMREL|g" \
                  -e "s|@TMP@|$TMP|g" \
                  -e "s|@PKG@|$PKG|g")"
        case "$expanded" in
            *\**)
                matched=0
                for m in $expanded; do
                    [ -e "$m" ] || continue
                    matched=1
                    printf '%s\n' "$m"
                done
                [ "$matched" = 1 ] || printf '%s\n' "$expanded"
                ;;
            *) printf '%s\n' "$expanded" ;;
        esac
    done < "$f"
}

compile_probe() { # $1 = base, $2 = -Onone|-O, $3 = 输出二进制, $4 = 日志
    local base="$1" opt="$2" bin="$3" log="$4"
    local -a extra=()
    while IFS= read -r line; do [ -n "$line" ] && extra+=("$line"); done < <(extra_args "$base")
    cp "$HERE/$base.swift" "$TMP/main.swift"
    # 顶层语句只有文件名叫 main.swift 才允许编译，所以每支探针都先改名再编。
    # shellcheck disable=SC2086
    "$XCODE_XT/bin/swiftc" "$opt" -sdk "$SDK" -target "$TARGET" -module-name "$MODULE" \
        "${extra[@]+"${extra[@]}"}" "$TMP/main.swift" -o "$bin" \
        -framework Foundation > "$log" 2>&1
    return $?
}

run_case() { # $1 = -Onone|-O，$2 = 配置标签, $3 = base
    local opt="$1" tag="$2" base="$3"
    local bin="$TMP/probe.$tag" log="$TMP/compile.$tag.txt"
    printf '\n===== %s (%s)\n' "$base" "$tag"
    case "$base" in
        s*)
            printf '（sNN 是命令行类探针，由 run.sh 末尾的分支单独跑）\n'
            return ;;
    esac
    # 同一份 .args 在两个配置里各自指向那一套包产物：cNN 靠这个做对照
    if [ "$tag" = "release" ]; then
        CUR_MODULES="$SPMREL/Modules"; CUR_DIR="$SPMREL"
    else
        CUR_MODULES="$MODULES"; CUR_DIR="$SPMDBG"
    fi
    compile_probe "$base" "$opt" "$bin" "$log"
    local cc=$?
    show "swiftc 输出" "$log"
    printf 'swiftc 退出码 = %s\n' "$cc"
    case "$base" in
        e*) printf '（编译类探针：到此为止，不运行）\n'; return ;;
    esac
    if [ "$cc" != 0 ]; then printf '（编译未通过：不运行）\n'; return; fi
    xcrun simctl spawn "$SIM_UDID" "$bin" > "$TMP/out.$tag.txt" 2> "$TMP/err.$tag.txt"
    printf '运行退出码 = %s\n' "$?"
    show "stdout" "$TMP/out.$tag.txt"
    show "stderr" "$TMP/err.$tag.txt"
}

targets=()
for f in $(cd "$HERE" && ls *.swift *.sh 2>/dev/null | sed -e 's/\.swift$//' -e 's/\.sh$//' | grep -v '^run$' | sort -u); do
    base="$f"
    if [ $# -eq 0 ]; then targets+=("$base"); else
        for want in "$@"; do case "$base" in "$want"*) targets+=("$base"); break ;; esac; done
    fi
done

# sNN 一族不需要包产物（它们自己造 fixture），编译类才需要
need_prepare=0
for base in ${targets[@]+"${targets[@]}"}; do
    case "$base" in s*) ;; *) need_prepare=1 ;; esac
done
if [ "$need_prepare" = "1" ]; then
    printf '== 准备包产物（swift build debug + release 各一遍，约 1 分钟）==\n'
    prepare_package_builds || exit 1
fi

for base in ${targets[@]+"${targets[@]}"}; do
    printf '\n########## %s\n' "$base"
    case "$base" in
        s*)
            printf '$ bash probes/%s.sh   # fixture 全写在 %s/%s 里\n' "$base" "$TMP" "$base" \
                > "$TMP/cmd.$base.txt"
            rm -rf "$TMP/$base"; mkdir -p "$TMP/$base"
            ( cd "$TMP/$base" && TMP="$TMP/$base" PKG_ROOT="$PKG" CHAPTER="$CHAPTER" \
                SDK="$SDK" TARGET="$TARGET" SWIFT="$SWIFT" SIM_UDID="$SIM_UDID" \
                SPMDBG="$SPMDBG" bash "$HERE/$base.sh" ) 2>&1 \
                | sed 's/^/    /'
            printf '探针退出码 = %s\n' "${PIPESTATUS[0]}"
            ;;
        c*)
            run_case -Onone debug "$base"
            run_case -O release "$base"
            ;;
        *)
            run_case -Onone debug "$base"
            ;;
    esac
done
printf '\n'
