#!/usr/bin/env bash
# ============================================================
# run-all.sh —— 用两套 C++ 工具链跑遍所有示例（shell 版，等价于 build.ps1）
#
#   ./run-all.sh            只打印每条通道的通过/失败摘要
#   ./run-all.sh -v         附带每个示例的完整输出
#   ./run-all.sh 18 22      只跑指定编号
#
# 两个通道（macOS/Linux 侧；Windows 侧 build.ps1 走 MSVC）：
#   1. clang     —— LLVM clang++ 23 + 它自带的 libc++（主通道）
#   2. gcc       —— GNU g++ 15 + libstdc++（对照通道）
#
# 判定标准（与 build.ps1 一致）：
#   退出码 0 + stderr 为空 + **编译日志为空（零告警）** + 输出非空
#   + 输出里没有控制字符 + 输出里有结束标记 "自检通过"
#
#   结束标记用的是示例自己最后一行打印的 "自检通过"，不是仓库其他目录的
#   "==== NN 结束 ===="。原因：本教程 24 章的正文（docs/*.md）里嵌了示例
#   的完整输出，改一行文案就要同步 24 篇文档；"自检通过" 本来就是示例
#   自带的"我跑完了"声明，语义与结束标记完全一致。
#
#   MSVC 的 /W4 在这里换成 -Wall -Wextra。注意「编译日志为空」这条不能省：
#   编译命令把 stderr 也并进了日志文件，所以「stderr 为空」盖不住编译期告警
#   （反向验证时故意写了个 "int unused = 42;" 的样例，一开始正是靠这条抓出来的）。
#
# 自动加分项：
#   * 18_modules 走真正的模块构建（clang 用 .pcm，gcc 用 gcm.cache）
#   * clang 通道自动补 libc++ 的可用性开关与自带 libc++ 的运行库路径
#     （原因见下面 libcxx 那一段注释，这是 macOS 上最大的一个坑）
#   * 两个通道的输出逐字节比对；已知差异（见 diff_reason）只打印原因
# ============================================================

set -u
cd "$(dirname "$0")"

VERBOSE=0
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        *) SELECT+=("$arg") ;;
    esac
done

# ------------------------------------------------------------
# 工具链定位：环境变量 CXX_CLANG / CXX_GCC 优先，
#             其次常见的 MacPorts 路径，最后退回 PATH 上的通用名字
# ------------------------------------------------------------
resolve_tool() {
    local envval="$1"; shift
    local c
    if [ -n "${envval}" ]; then
        printf '%s' "$envval"
        return
    fi
    for c in "$@"; do
        if command -v "$c" >/dev/null 2>&1; then
            command -v "$c"
            return
        fi
    done
    printf ''
}

CLANGXX=$(resolve_tool "${CXX_CLANG:-}" /opt/local/bin/clang++-mp-23 clang++-mp-23 clang++-mp-devel clang++)
GCCXX=$(resolve_tool   "${CXX_GCC:-}"   /opt/local/bin/g++-mp-15     g++-mp-15     g++)

[ -n "$CLANGXX" ] || echo "未找到 clang++（可设 CXX_CLANG=/path/to/clang++）"
[ -n "$GCCXX" ]   || echo "未找到 g++（可设 CXX_GCC=/path/to/g++）"
if [ -z "$CLANGXX" ] && [ -z "$GCCXX" ]; then exit 1; fi

COMMON_FLAGS=(-std=c++23 -Wall -Wextra -O2)

# ------------------------------------------------------------
# clang 通道的编译/链接参数。
#
# macOS 上最大的一个坑：clang 自带的 libc++ 与系统 libc++ 不是同一套。
# MacPorts 的 clang-23 带的是完整 libc++ 23（<print>、<expected>、<flat_map>、
# <mdspan> 都齐），但它的 .dylib 不在默认库搜索路径里；而头文件里带着 Apple 的
# availability 注解 —— 那套注解描述的是「苹果自家 libc++ 什么时候有这个符号」，
# 在本机 macOS 12.7 上等于给 std::to_chars(浮点) 打上「13.3 才可用」，
# 于是 <print> 只要格式化一个浮点数就直接编译失败。
#
# 正确姿势（三件一起，缺一不可）：
#   -D_LIBCPP_DISABLE_AVAILABILITY  关掉那套注解（libc++ 官方留的逃生口）
#   -L/-rpath 指向 clang 自带的 libc++ 与 libunwind，让它自己的实现顶上
#   -fexperimental-library          打开 libc++ 默认关着的 C++ 特性
#     （本教程里它决定 <execution> 的 std::execution::par 存不存在：
#      libc++ 的并行算法挂在 PSTL 后面，不加这个开关连名字都没有）
# 只做第一半会在链接期报 "to_chars 未定义" —— 系统 libc++ 里确实没有它。
# ------------------------------------------------------------
CLANG_CFLAGS=()
CLANG_LDFLAGS=()
LIBCXX_LIBDIR=""
if [ -n "$CLANGXX" ]; then
    # 别用 dirname/.. 去猜安装根 —— MacPorts 的 /opt/local/bin/clang++-mp-23
    # 是个 178 字节的 shell 包装脚本，不是符号链接，猜出来的是 /opt/local，
    # 而真正的库在 /opt/local/libexec/llvm-23/lib。问编译器自己的资源目录最稳：
    #   -print-resource-dir → /opt/local/libexec/llvm-23/lib/clang/23
    resource_dir=$("$CLANGXX" -print-resource-dir 2>/dev/null || true)
    mp_root=${resource_dir%/lib/clang/*}
    [ -n "$resource_dir" ] && [ "$mp_root" != "$resource_dir" ] || mp_root=""
    if [ -n "$mp_root" ] && [ -f "$mp_root/lib/libc++/libc++.dylib" ]; then
        LIBCXX_LIBDIR="$mp_root/lib/libc++"
        LIBUNWIND_LIBDIR="$mp_root/lib/libunwind"
        CLANG_CFLAGS+=(-D_LIBCPP_DISABLE_AVAILABILITY)
        CLANG_LDFLAGS+=(-L"$LIBCXX_LIBDIR" -Wl,-rpath,"$LIBCXX_LIBDIR" -lc++)
        if [ -d "$LIBUNWIND_LIBDIR" ]; then
            CLANG_LDFLAGS+=(-L"$LIBUNWIND_LIBDIR" -Wl,-rpath,"$LIBUNWIND_LIBDIR")
        fi
    else
        # 非 MacPorts 布局（系统 clang / Linux 的 clang）：照常链接即可
        CLANG_CFLAGS+=(-stdlib=libc++)
        CLANG_LDFLAGS+=(-stdlib=libc++ -lc++abi)
    fi
    CLANG_CFLAGS+=(-fexperimental-library)
fi

GCC_CFLAGS=(-pthread)
GCC_LDFLAGS=(-pthread)

echo "clang : ${CLANGXX:-<缺失>} ${CLANG_CFLAGS[*]:-}"
echo "gcc   : ${GCCXX:-<缺失>} ${GCC_CFLAGS[*]:-}"
# 注意：bash 里 $VAR 后面紧跟全角字符（如「（」）会被当成变量名的一部分，
# 报 unbound variable —— 一律写 ${VAR}，别省花括号
[ -n "${LIBCXX_LIBDIR}" ] && echo "libc++: ${LIBCXX_LIBDIR}（clang 自带的那一套）"
echo

# 当前通道的编译/链接参数（select_channel 之后有效）
SEL_CC=""
SEL_CFLAGS=()
SEL_LDFLAGS=()
select_channel() {
    case "$1" in
        clang) SEL_CC="$CLANGXX"; SEL_CFLAGS=("${CLANG_CFLAGS[@]}"); SEL_LDFLAGS=("${CLANG_LDFLAGS[@]}") ;;
        gcc)   SEL_CC="$GCCXX";   SEL_CFLAGS=("${GCC_CFLAGS[@]}");   SEL_LDFLAGS=("${GCC_LDFLAGS[@]}") ;;
        *) return 1 ;;
    esac
    [ -n "$SEL_CC" ]
}

# ------------------------------------------------------------
# 已知的跨工具链差异及原因。这些示例的输出本来就不该逐字节相同，
# 打印原因即可，不计入告警；其余示例若输出不同则视为需要人工确认。
#
# 纪律：能修的一律修。这里登记的三条都是「标准库缺头文件」造成的
# —— libc++ 没有 <generator>/<stacktrace>，libstdc++ 15 没有 <mdspan>，
# 示例里已经用 __has_include / 特性宏把缺的特性跳过并明确打出一行说明。
# 其余几条是「调度/并行度由实现决定」，属于标准明确允许的差异。
# ------------------------------------------------------------
diff_reason() {
    case "$1" in
        08_classes)    echo "示例故意演示实参求值顺序未指定（GCC 从右往左、clang 从左往右）" ;;
        19_threads)    echo "多线程按完成顺序打印，调度不同则行序不同" ;;
        20_atomic)     echo "并行算法把工作拆给几个线程由实现决定" ;;
        21_coroutines) echo "libc++ 无 <generator>，clang 通道跳过 21.3 并说明" ;;
        22_textfiles)  echo "libstdc++ 15 无 <mdspan>，gcc 通道跳过 22.4 并说明" ;;
        23_tooling)    echo "两套库都没有 <stacktrace>，两通道都跳过 23.3 并说明" ;;
        24_minigrep)   echo "多线程搜索的命中行顺序随调度变化" ;;
        *)             echo "" ;;
    esac
}

mkdir -p build/tmp
# build/tmp 是给示例运行时用的 TMPDIR（见下面 run_binary）。这里清一遍是防"外来垃圾"：
# 编译被信号打断、手工在 build/ 下敲过编译器、或别的工具用了这个 TMPDIR 时，
# 都会在这里留下 .s/.o 之类的中间产物 —— 让 build/ 保持"只有产物和输出"。
rm -f build/tmp/*.s build/tmp/*.o build/tmp/*.d build/tmp/*.ii 2>/dev/null
PASS=0
FAIL=0
DIFFWARN=0
FAILED_LIST=()

# 输出里是否混进了「不该出现」的控制字符（制表符、换行、回车除外）。
# 用 grep 的**退出码**判定，不要用「数出来的字节数 != 0」那种写法：
# 数数得把子进程的 stdout 抓进 $(...) 里再比较，任何往管道里插话的东西
# （包装脚本、沙箱策略探针……）都会污染那个字符串，让判定莫名其妙地报失败。
has_ctrl() {
    # 先放过 TAB(11)/LF(12)/CR(15)，再看剩下的 0..31 里还有没有
    LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

# 在输出里找结束标记。先剔掉 NUL 再匹配，免得二进制内容干扰 grep。
# LC_ALL=C 不能省：UTF-8 locale 下 toybox 的 tr 会做多字节校验，碰到非法
# UTF-8 就报 "tr: Illegal byte sequence" 并**截断输入**，标记在截断点之后
# 就查不到，会误报「缺少结束标记」。
marker_present() {
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null | LC_ALL=C grep -qF "$2"
}

# check <标签> <输出文件> <stderr文件> <退出码> <编译日志>
check() {
    local tag="$1" out="$2" err="$3" rc="$4" log="$5"
    local ok=1 why=()

    if [ "$rc" -ne 0 ]; then ok=0; why+=("退出码 $rc"); fi
    if [ -s "$err" ]; then ok=0; why+=("stderr 非空（警告也算失败）"); fi
    # 编译日志非空 = 有告警。**这条不能省**：编译命令把 stderr 也并进了日志
    # 文件（>$log 2>&1），所以"stderr 为空"那条根本盖不住编译期告警，
    # 得单独判日志。clang/gcc 成功时一个字都不打，空就是零告警。
    if [ -s "$log" ]; then ok=0; why+=("编译有告警（日志非空）"); fi
    if [ ! -s "$out" ]; then ok=0; why+=("stdout 为空（进程没跑到业务代码）"); fi
    if has_ctrl "$out"; then ok=0; why+=("输出含控制字符"); fi
    if ! marker_present "$out" "$MARKER"; then ok=0; why+=("缺少结束标记 \"$MARKER\""); fi

    if [ "$ok" -eq 1 ]; then
        PASS=$((PASS + 1))
        printf "  [%s] %s\n" "OK" "$tag"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$tag")
        printf "  [%s] %s —— %s\n" "FAIL" "$tag" "$(printf '%s；' "${why[@]}")"
        if [ -s "$err" ]; then sed 's/^/        stderr: /' "$err" | head -5; fi
        if [ -s "$out" ]; then
            echo "        stdout 最后 5 行："
            tail -5 "$out" | LC_ALL=C tr -d '\000' | sed 's/^/        /'
        fi
        if [ -s "$log" ]; then
            echo "        编译日志："
            head -10 "$log" | sed 's/^/        /'
        fi
    fi

    if [ "$VERBOSE" -eq 1 ] && [ -s "$out" ]; then
        LC_ALL=C tr -d '\000' < "$out" | sed 's/^/        /'
    fi
}

# 示例会在临时目录里造文件：把 TMPDIR 固定到 build/tmp，
# 这样两条通道看到同一份路径，22_textfiles 打出来的路径也可复现
run_binary() {
    local name="$1" channel="$2"
    ( cd build && TMPDIR="$PWD/tmp" "./$name.$channel" \
        >"$name.$channel.out" 2>"$name.$channel.err" )
    return $?
}

# build_and_run <通道> <示例目录> <示例名> —— 单文件/多文件示例的通用路径
build_and_run() {
    local channel="$1" dir="$2" name="$3"
    select_channel "$channel" || return 1
    local bin="build/$name.$channel"

    local srcs=("$dir"/*.cpp)
    if ! "$SEL_CC" "${COMMON_FLAGS[@]}" "${SEL_CFLAGS[@]}" -I"$dir" "${srcs[@]}" \
            -o "$bin" "${SEL_LDFLAGS[@]}" >"build/$name.$channel.build" 2>&1; then
        : >"build/$name.$channel.out"
        echo "编译失败，见 build/$name.$channel.build" >"build/$name.$channel.err"
        return 1
    fi
    run_binary "$name" "$channel"
}

# build_with_modules <通道> <示例目录> <示例名> —— 18_modules 专用。
# 模块接口单元必须先编成「已编译模块接口」，再编 import 方，最后链接；
# 两套工具链的命令行完全不同：
#   clang: --precompile 出 .pcm，import 方用 -fmodule-file=math=math.pcm
#   gcc  : 编 .ixx 时 -fmodules-ts 会把 math.gcm 落进 ./gcm.cache
build_with_modules() {
    local channel="$1" dir="$2" name="$3"
    select_channel "$channel" || return 1
    local bin="build/$name.$channel"
    local wd="build/mod/$channel"
    local log="build/$name.$channel.build"
    local root="$PWD"
    rm -f "$wd"/*.cpp "$wd"/*.ixx "$wd"/*.o "$wd"/*.pcm 2>/dev/null
    rm -rf "$wd/gcm.cache" 2>/dev/null
    mkdir -p "$wd"
    cp "$dir"/*.cpp "$dir"/*.ixx "$wd"/

    (
        cd "$wd" || exit 1
        set -e
        local m mod
        m=$(ls *.ixx)
        mod=${m%.ixx}   # 模块名取自文件名（math.ixx → math），不是文件名本身
        case "$channel" in
            clang)
                "$SEL_CC" "${COMMON_FLAGS[@]}" "${SEL_CFLAGS[@]}" -x c++-module "$m" \
                      --precompile -o "$mod.pcm"
                "$SEL_CC" "${COMMON_FLAGS[@]}" "${SEL_CFLAGS[@]}" \
                      -fmodule-file="$mod=$mod.pcm" -c main.cpp -o main.o
                "$SEL_CC" "${COMMON_FLAGS[@]}" "${SEL_CFLAGS[@]}" \
                      "$mod.pcm" main.o -o "$root/$bin" "${SEL_LDFLAGS[@]}"
                ;;
            gcc)
                # libstdc++ 的模块产物落进 ./gcm.cache，import 方要在同一目录编译
                "$SEL_CC" "${COMMON_FLAGS[@]}" "${SEL_CFLAGS[@]}" -fmodules-ts -c "$m" \
                      -o "$mod.o"
                "$SEL_CC" "${COMMON_FLAGS[@]}" "${SEL_CFLAGS[@]}" -fmodules-ts -c main.cpp \
                      -o main.o
                "$SEL_CC" "${COMMON_FLAGS[@]}" "${SEL_CFLAGS[@]}" \
                      "$mod.o" main.o -o "$root/$bin" "${SEL_LDFLAGS[@]}"
                ;;
        esac
    ) >"$log" 2>&1
    if [ ! -x "$bin" ]; then
        : >"build/$name.$channel.out"
        echo "模块构建失败，见 $log" >"build/$name.$channel.err"
        return 1
    fi
    run_binary "$name" "$channel"
}

MARKER="自检通过"

for dir in examples/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    num=${name%%_*}

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
        [ "$hit" -eq 1 ] || continue
    fi

    echo "==== $name ===="

    for channel in clang gcc; do
        case "$channel" in
            clang) [ -n "$CLANGXX" ] || continue ;;
            gcc)   [ -n "$GCCXX" ] || continue ;;
        esac

        if [ "$name" = "18_modules" ]; then
            build_with_modules "$channel" "$dir" "$name"
        else
            build_and_run "$channel" "$dir" "$name"
        fi
        rc=$?
        check "$channel   $name" "build/$name.$channel.out" "build/$name.$channel.err" \
              "$rc" "build/$name.$channel.build"
    done

    # 附加检查：两个工具链的输出应当逐字节一致
    if [ -n "$CLANGXX" ] && [ -n "$GCCXX" ] \
       && [ -s "build/$name.clang.out" ] && [ -s "build/$name.gcc.out" ]; then
        if cmp -s "build/$name.clang.out" "build/$name.gcc.out"; then
            printf "  [same] 两工具链输出逐字节一致\n"
        else
            reason=$(diff_reason "$name")
            if [ -n "$reason" ]; then
                printf "  [diff] 已知差异：%s\n" "$reason"
            else
                DIFFWARN=$((DIFFWARN + 1))
                printf "  [DIFF] 两工具链输出不一致（意外差异，见 build/$name.*.out）\n"
                diff "build/$name.clang.out" "build/$name.gcc.out" | head -10 | sed 's/^/        /'
            fi
        fi
    fi
done

echo
echo "通过 $PASS   失败 $FAIL   输出差异 $DIFFWARN"
if [ "$FAIL" -eq 0 ]; then
    echo "全部通过"
    [ "$DIFFWARN" -eq 0 ] && exit 0
    echo "（有 $DIFFWARN 项跨工具链输出不同，请人工确认是否可接受）"
    exit 0
else
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
    exit 1
fi
