#!/usr/bin/env bash
# ============================================================
# run-all.sh —— Boost 教程 macOS/Linux 验证入口（shell 版，等价于 build.ps1）
#
#   ./run-all.sh                       跑全部示例，只打印摘要
#   ./run-all.sh -v                    附带每个示例的完整输出
#   ./run-all.sh 03 29                 只跑指定章号（两位数字或目录名均可）
#   ./run-all.sh -f 03_smartptr/smart_ptr.cpp   单示例
#   ./run-all.sh --clean               清理本脚本自己写的产物目录
#
# 两条通道（同一个编译器，只换 Boost 库的链接方式）：
#   shared —— 链接 libboost_*-mt.dylib（运行期按 rpath 找动态库）
#   static —— 链接 libboost_*-mt.a（全静态编进可执行文件）
# 两个二进制由同一份源码、同一套编译参数产出，因此「跨通道逐字节一致」
# 检验的不是两种语义，而是示例**有没有偷偷依赖动态库加载 / 安装前缀**。
#
# 判定标准（与 build.ps1 六条一致，逐通道都要过）：
#   1) 编译退出码 0
#   2) 编译日志为空 —— 含告警即失败（-Wall -Wextra，Boost 头用 -isystem 压掉）
#   3) 运行退出码 0
#   4) stdout 非空、且无控制字符（TAB/LF/CR 除外）
#   5) stderr 为空
#   6) stdout 里有结束标记 "自检通过"
# 附加第 7 条（本仓库多通道惯例）：两通道 stdout 逐字节一致。
#
# 结束标记沿用示例自己最后一行打印的 "自检通过"：docs/ 各章正文里嵌了示例的
# 完整输出，改文案要同步 33 篇文档；"自检通过" 本来就是示例自带的
# "我跑完了" 声明，语义与结束标记完全一致。
# ============================================================

set -u
cd "$(dirname "$0")"
TOP="$PWD"

VERBOSE=0
CLEAN=0
SELECT=()
SINGLE=""
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose) VERBOSE=1; shift ;;
        --clean)      CLEAN=1; shift ;;
        -f|--file)    SINGLE="${2:-}"; shift 2 ;;
        *)            SELECT+=("$1"); shift ;;
    esac
done

# ------------------------------------------------------------
# 工具链与依赖定位
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

CXX=$(resolve_tool "${CXX:-}" /usr/bin/clang++ clang++)
BOOST_INC="${BOOST_INC:-/Volumes/mac004/lang/boost}"
BOOST_LIB="${BOOST_LIB:-$PWD/build/boost-1.88/lib}"

if [ -z "$CXX" ]; then echo "未找到 C++ 编译器（可设 CXX=/path/to/clang++）"; exit 1; fi
if [ ! -f "${BOOST_INC}/boost/version.hpp" ]; then
    echo "Boost 头文件根不对：${BOOST_INC}（应包含 boost/version.hpp；可用 BOOST_INC 覆盖）"
    exit 1
fi
if [ ! -d "${BOOST_LIB}" ]; then
    echo "Boost 库目录不存在：${BOOST_LIB}（可用 BOOST_LIB 覆盖；构建方法见 README）"
    exit 1
fi

# Boost 版本顺手打出来：教程正文写的是 1.92，本机源码树可能更旧，
# 差多少决定了哪些示例跑不了（见 README 的「本机验证状态」一节）
# version.hpp 是 CRLF 换行，不带 tr 会把 \r 带进版本号，后面的字符串比较全飞
BOOST_VER=$(sed -n 's/^#define BOOST_VERSION //p' "${BOOST_INC}/boost/version.hpp" 2>/dev/null | tr -d '\r')
echo "编译器 : $CXX"
echo "Boost  : ${BOOST_INC}（BOOST_VERSION=${BOOST_VER:-未知}）"
echo "库目录 : ${BOOST_LIB}"

if [ "${CLEAN:-0}" -eq 1 ]; then
    rm -rf build/shared build/static build/tmp
    echo "[clean] 已清理 build/{shared,static,tmp}"
    exit 0
fi

mkdir -p build/shared build/static build/tmp

SDKROOT=$(xcrun --show-sdk-path 2>/dev/null || true)
COMMON_FLAGS=(-std=c++2b -O2 -Wall -Wextra -pthread -isystem "${BOOST_INC}")
if [ -n "${SDKROOT}" ]; then
    COMMON_FLAGS+=(-isysroot "${SDKROOT}")
fi
# -fexperimental-library：Apple 自带的 libc++ 把"还没完成"的标准设施藏在这个
# 开关后面（__config 里一串 _LIBCPP_HAS_NO_* 宏，stop_token/jthread 就在其中），
# 不开它 std::jthread / std::stop_token 连名字都没有——09 章的 jthread 对照段
# 直接编不过（实测报 "no member named 'jthread' in namespace 'std'"）。
# 开关不被编译器认得时自动跳过（先探一次，别让老编译器整个挂掉）。
if "${CXX}" -fexperimental-library -x c++ -c /dev/null -o /dev/null >/dev/null 2>&1; then
    COMMON_FLAGS+=(-fexperimental-library)
fi

# Boost.Locale 带 ICU 时的链接参数（19 章静态通道需要）。
# **不带 ICU 的 Boost.Locale 是"半残"的**：normalize() 退化成原样返回、
# to_upper("ß") 不变成 "SS"——这些不是平台差异，是构建缺依赖。所以宁可探到
# ICU 就带上，也别把退化后的输出当成"macOS 就是这样"写进教程。
# 把 "icu-config --ldflags" 的 -L/-l 形式改写成库的绝对路径（理由见上）。
icu_abs_libs() {
    command -v icu-config >/dev/null 2>&1 || return 0
    local out=() dir="" tok lib
    for tok in $(icu-config --ldflags 2>/dev/null || true); do
        case "${tok}" in
            -L*) dir="${tok#-L}" ;;
            -l*)
                lib="${tok#-l}"
                if [ -n "${dir}" ] && [ -f "${dir}/lib${lib}.dylib" ]; then
                    out+=("${dir}/lib${lib}.dylib")
                elif [ -n "${dir}" ] && [ -f "${dir}/lib${lib}.so" ]; then
                    out+=("${dir}/lib${lib}.so")
                else
                    out+=("${tok}")     # 找不到就原样给，让链接器自己去搜
                fi
                ;;
        esac
    done
    printf '%s\n' "${out[@]}"
}

ICU_LDFLAGS="${ICU_LDFLAGS:-}"
if [ -z "${ICU_LDFLAGS}" ]; then
    # 把 icu-config 给的 "-L<dir> -l<name>" 改写成 <dir>/lib<name>.dylib 的
    # **绝对路径**。为什么要绕这一下：留下 -L/opt/local/lib 的话，链接器会把
    # SDK 版 libiconv 再导出的 libcharset 解析到 MacPorts 那份，打印一行
    # "install name ... is different" 的 ld 告警——而本脚本的判据是
    # "stderr 必须为空"，一条无关告警就能让整章挂掉。
    ICU_LDFLAGS="$(icu_abs_libs)"
fi

# iconv 的链接参数：优先 SDK 里的绝对路径（见 static_sys_libs 里的说明）。
ICONV_LIB="${ICONV_LIB:-}"
if [ -z "${ICONV_LIB}" ]; then
    if [ -n "${SDKROOT}" ] && [ -f "${SDKROOT}/usr/lib/libiconv.tbd" ]; then
        ICONV_LIB="${SDKROOT}/usr/lib/libiconv.tbd"
    else
        ICONV_LIB="-liconv"
    fi
fi

# ------------------------------------------------------------
# 章节附加链接配置。
#   键 = 章节编号（目录名前缀），值是该章要额外链接的 Boost 库名（不带 -l）。
#   与 build.ps1 的 $chapterConfig 对应，但换成 Unix 侧的库名/框架：
#     13 章 nowide：Windows 要 Shell32.lib（CommandLineToArgvW），Unix 不需要
#     17 章 stacktrace：Windows 要 dbghelp.lib，Unix 用 addr2line 后端
#     25 章 compute：Windows 链 CUDA 的 OpenCL.lib，macOS 用系统 OpenCL 框架
#     28 章 asio/beast：Windows 要 ws2_32.lib，Unix 什么都不用
# ------------------------------------------------------------
chapter_libs() {
    case "$1" in
        06) echo "regex random" ;;          # random_device 在编译库里
        07) echo "chrono date_time timer" ;;
        09) echo "thread chrono" ;;          # this_thread::sleep_for 走 boost::chrono
        10) echo "atomic" ;;
        13) echo "filesystem nowide" ;;
        16) echo "context coroutine fiber cobalt thread" ;;
        17) echo "stacktrace_addr2line charconv" ;;
        19) echo "locale thread" ;;         # locale 内部用 thread 的 tss（静态链接时才暴露）
        27) echo "filesystem thread wave" ;;  # wave：库内部用 filesystem + spirit 的 once_flag
        28) echo "url" ;;                    # Boost.URL 是编译库（1.88 起）
        29) echo "iostreams program_options filesystem process" ;;
        30) echo "serialization json" ;;
        32) echo "unit_test_framework log log_setup contract filesystem thread" ;;
        *)  echo "" ;;
    esac
}

# 章节附加系统库/框架（不是 Boost 库）
chapter_sys_libs() {
    case "$1" in
        25) echo "-framework OpenCL" ;;
        *)  echo "" ;;
    esac
}

# 章节附加宏。
# 17 章 Boost.Stacktrace：Unix 侧靠 _Unwind_Backtrace 回溯，Boost 头里要求
# 先声明"这个函数不需要 _GNU_SOURCE 就有"——Windows 走 dbghelp，没有这回事，
# 所以这条是纯 Unix 差异（不写就 #error 停在那儿）。
chapter_defines() {
    case "$1" in
        17) echo "-DBOOST_STACKTRACE_GNU_SOURCE_NOT_REQUIRED" ;;
        *)  echo "" ;;
    esac
}

# 把 Boost 库名变成链接参数。
#
# 两条通道都按**完整路径**给库文件，而不是 -l<名字>，原因有二：
#   ① macOS 的 ld64 没有 -Bstatic，同一个 -L 目录里 .dylib 永远压过 .a，
#      静态通道不写全路径就等于再跑一遍动态通道，"跨通道比对" 成了摆设；
#   ② b2 的 --layout=tagged 把地址模型也塞进了库名（libboost_regex-mt-x64），
#      -lboost_regex-mt 根本对不上，按名字拼就得跟着 layout 改，glob 一次到位。
link_args() {
    local channel="$1"; shift
    local libs="$1"; shift
    local out=()
    local l p
    for l in ${libs}; do
        p=""
        if [ "$channel" = "static" ]; then
            for p in "${BOOST_LIB}"/libboost_${l}-*.a; do [ -f "$p" ] && break; done
        else
            for p in "${BOOST_LIB}"/libboost_${l}-*.dylib "${BOOST_LIB}"/libboost_${l}-*.so; do
                [ -f "$p" ] && break
            done
        fi
        if [ -n "$p" ] && [ -f "$p" ]; then
            out+=("$p")
        else
            out+=("-l${l}-mt")
        fi
    done
    printf '%s\n' "${out[@]}"
}

# 静态通道会漏掉 Boost 库自己依赖的系统库（iostreams 的 zlib/bzip2、
# locale 的 iconv，以及 locale 带 ICU 时的 ICU 三件套），统一补上；
# 动态库的依赖写在 dylib 自己的 install_name 里，不需要补。
#
# ICU 的链接参数靠 icu-config 探测（MacPorts/Linux 发行版都有）；探测不到就
# 退到 ICU_LDFLAGS 环境变量；再没有就留空——那种情况下 Boost.Locale 多半也
# 是按"不带 ICU"编的，本来就不需要。
static_sys_libs() {
    local ch="$1"
    local extra="-lpthread"
    case "$ch" in
        # iconv 走 SDK 里的绝对路径，不用 -liconv：MacPorts 的 GNU libiconv
        # 只导出 _libiconv（它的 iconv.h 把 iconv 宏定义成 libiconv），
        # 而 ICU 那套 -L/opt/local/lib 会把 -liconv 引到它身上，
        # 于是静态链接报 "Undefined symbols: _iconv"。写绝对路径就不存在
        # "哪个 libiconv 先被找到" 这道题。
        19) extra="$extra ${ICONV_LIB} ${ICU_LDFLAGS}" ;;
        29) extra="$extra -lz -lbz2" ;;
    esac
    echo "$extra"
}

MARKER="自检通过"

# ------------------------------------------------------------
# 跨通道比对里"已知会漂的行"。
#
# 关键设计：**只豁免行，不豁免整个示例**。
# 之前这里是按示例名整例豁免（timer 一整例都跳过比对），结果把"段2 wall>=1ms?"
# 这条**真正在掷硬币**的输出也一起放过了——同一通道连跑 5 次有 2 次是 false。
# 整例豁免是假绿：它让"跨通道一致"这条判据对该示例彻底失效。
# 现在改成给出"哪些行本来就不可能一致"的模式，比对前把这些行删掉，
# 剩下的行照常逐字节比；并额外校验"豁免模式确实命中了行"——
# 一条都没命中说明模式过期了，要报警，不能默默算通过。
# ------------------------------------------------------------
volatile_pattern() {
    case "$1" in
        # auto_cpu_timer 析构时打印的真实 wall/user/system 耗时
        timer)     echo '^ [0-9]+\.[0-9]+s wall, ' ;;
        *)         echo "" ;;
    esac
}

PASS=0
FAIL=0
DIFFWARN=0
FAILED_LIST=()

has_ctrl() {
    LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

marker_present() {
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null | LC_ALL=C grep -qF "$2"
}

# check <标签> <输出文件> <stderr文件> <退出码> <编译日志>
check() {
    local tag="$1" out="$2" err="$3" rc="$4" log="$5"
    local ok=1 why=()

    if [ "$rc" -ne 0 ]; then ok=0; why+=("退出码 $rc"); fi
    if [ -s "$err" ]; then ok=0; why+=("stderr 非空"); fi
    if [ -s "$log" ]; then ok=0; why+=("编译有告警/错误（日志非空）"); fi
    if [ ! -s "$out" ]; then ok=0; why+=("stdout 为空（进程没跑到业务代码）"); fi
    if has_ctrl "$out"; then ok=0; why+=("输出含控制字符"); fi
    if ! marker_present "$out" "${MARKER}"; then ok=0; why+=("缺少结束标记 \"${MARKER}\""); fi

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
            echo "        编译日志（前 12 行）："
            head -12 "$log" | sed 's/^/        /'
        fi
    fi

    if [ "${VERBOSE}" -eq 1 ] && [ -s "$out" ]; then
        LC_ALL=C tr -d '\000' < "$out" | sed 's/^/        /'
    fi
}

# 动态库后缀由 Boost.DLL 自己说了算（macOS 是 .dylib，Linux 是 .so）。
# 用它而不是 uname 猜：dll.cpp 侧也用同一个 API 拼文件名，两边不可能对不上。
probe_dll_suffix() {
    local probe="build/tmp/dll_suffix_probe.cpp"
    cat >"$probe" <<'EOF'
#include <boost/dll.hpp>
#include <iostream>
int main() { std::cout << boost::dll::shared_library::suffix().string() << '\n'; }
EOF
    if "$CXX" "${COMMON_FLAGS[@]}" "$probe" -o "build/tmp/dll_suffix_probe" \
        >"build/tmp/dll_suffix_probe.build" 2>&1; then
        "build/tmp/dll_suffix_probe" 2>/dev/null | head -1
    else
        case "$(uname -s)" in Darwin) echo ".dylib" ;; *) echo ".so" ;; esac
    fi
}
DLL_SUFFIX=$(probe_dll_suffix)
echo "动态库后缀: ${DLL_SUFFIX}（Boost.DLL 自报）"
echo

# compile_one <通道> <源文件> <章节号> —— 只编译（含 plugin_* 动态库）
compile_one() {
    local channel="$1" src="$2" ch="$3"
    local base
    base=$(basename "$src" .cpp)
    local outdir="build/$channel"
    local log="$outdir/$base.build"
    local libs
    libs=$(chapter_libs "$ch")
    local syslibs
    syslibs=$(chapter_sys_libs "$ch")
    local defs
    defs=$(chapter_defines "$ch")

    if [ "$base" = "plugin_greeter" ]; then
        # 插件：编成动态库（两条通道共用同一份源码，产物落在各自目录）
        "$CXX" "${COMMON_FLAGS[@]}" -fPIC -shared "$src" \
            -o "$outdir/${base}${DLL_SUFFIX}" >"$log" 2>&1
        return $?
    fi

    local args=("${COMMON_FLAGS[@]}")
    for d in ${defs}; do args+=("$d"); done
    args+=("$src" -o "$outdir/$base" -L"${BOOST_LIB}")
    local l
    while IFS= read -r l; do
        [ -n "$l" ] && args+=("$l")
    done < <(link_args "$channel" "$libs")
    if [ "$channel" = "static" ]; then
        # 静态链接：Boost 的 *_DYN_LINK 宏一个都不能开（开了会去找 dllimport
        # 的符号，静态库里没有）
        :
    else
        # 动态链接：Boost.Test / Boost.Log 都要显式声明（Unix 侧没有
        # 自动链接帮我们开）。Windows 侧 build.ps1 只开 BOOST_TEST_DYN_LINK，
        # Boost.Log 在同一条 BOOST_ALL_DYN_LINK  umbrella 下自动生效。
        case "$ch" in
            32) args+=(-DBOOST_TEST_DYN_LINK -DBOOST_LOG_DYN_LINK) ;;
        esac
    fi
    for s in ${syslibs}; do args+=("$s"); done
    if [ "$channel" = "static" ]; then
        for s in $(static_sys_libs "$ch"); do args+=("$s"); done
    else
        args+=(-Wl,-rpath,"${BOOST_LIB}")
    fi
    "$CXX" "${args[@]}" >"$log" 2>&1
}

run_one() {
    local channel="$1" base="$2"
    # TMPDIR 必须给**绝对路径、且不含通道名**：相对路径（或 ./.. 形态的
    # "build/shared/../tmp"）会被 boost::filesystem::temp_directory_path()
    # 原样带进输出，13 章那条"目录 = ..."就永远跨通道不一致——
    # 那是构建布局的差异，不是示例行为的差异。
    #
    # BOOST_TEST_COLOR_OUTPUT=0：Boost.Test 在非 Windows 上**默认**给报告加
    # ANSI 颜色转义（ESC[1;32;49m），Windows 侧走控制台 API 不打转义字节。
    # 本教程的"stdout 无控制字符"判定因此只在 Unix 侧挂——关掉颜色即可，
    # 判据本身不放宽。
    ( cd "build/$channel" && TMPDIR="$TOP/build/tmp" BOOST_TEST_COLOR_OUTPUT=0 \
        "./$base" >"$base.out" 2>"$base.err" )
    return $?
}

process_one() {
    local channel="$1" src="$2" ch="$3"
    local base
    base=$(basename "$src" .cpp)
    if [ "$base" = "plugin_greeter" ]; then
        compile_one "$channel" "$src" "$ch"
        local rc=$?
        if [ "$rc" -eq 0 ]; then
            printf "  [%s] %s（插件已产出 %s%s）\n" "OK" "$channel $base" "$base" "${DLL_SUFFIX}"
            PASS=$((PASS + 1))
        else
            printf "  [%s] %s —— 插件编译失败\n" "FAIL" "$channel $base"
            FAIL=$((FAIL + 1))
            FAILED_LIST+=("$channel $base")
            sed 's/^/        /' "build/$channel/$base.build" | head -12
        fi
        return
    fi
    if ! compile_one "$channel" "$src" "$ch"; then
        : >"build/$channel/$base.out"
        check "$channel   $base" "build/$channel/$base.out" "build/$channel/$base.err" \
              1 "build/$channel/$base.build"
        return
    fi
    run_one "$channel" "$base"
    local rc=$?
    check "$channel   $base" "build/$channel/$base.out" "build/$channel/$base.err" \
          "$rc" "build/$channel/$base.build"
}

# ------------------------------------------------------------
# 逐个示例：先全章编译（插件先就位），再统一运行
# ------------------------------------------------------------
run_dir() {
    local dir="$1"
    local ch
    ch=$(basename "$dir" | cut -d_ -f1)
    echo "==== $(basename "$dir") ===="
    local srcs=()
    local f
    for f in "$dir"/*.cpp; do
        [ -f "$f" ] || continue
        srcs+=("$f")
    done
    if [ ${#srcs[@]} -eq 0 ]; then return; fi

    local channel src base
    for channel in shared static; do
        for src in "${srcs[@]}"; do
            base=$(basename "$src" .cpp)
            case "$base" in plugin_*) compile_one "$channel" "$src" "$ch" ;; esac
        done
        for src in "${srcs[@]}"; do
            process_one "$channel" "$src" "$ch"
        done
    done

    # 跨通道比对。**必须在两条通道都跑完之后做**：放在通道循环里的话，
    # 第一轮拿到的 static/*.out 还是上一轮留下的旧产物，比的是"新 vs 旧"，
    # 会凭空报一堆差异（13 章那条路径差异就是这么冒出来的）。
    for src in "${srcs[@]}"; do
        base=$(basename "$src" .cpp)
        case "$base" in plugin_*) continue ;; esac
        if [ -s "build/shared/$base.out" ] && [ -s "build/static/$base.out" ]; then
            local pat nvol
            pat=$(volatile_pattern "$base")
            if [ -n "$pat" ]; then
                LC_ALL=C grep -E -v "$pat" "build/shared/$base.out" \
                    > "build/tmp/$base.cmp.a" || true
                LC_ALL=C grep -E -v "$pat" "build/static/$base.out" \
                    > "build/tmp/$base.cmp.b" || true
                nvol=$(( $(wc -l < "build/shared/$base.out")
                       - $(wc -l < "build/tmp/$base.cmp.a") ))
                # 反向验证：豁免模式一条都没命中 ⇒ 模式过期了，判据失效，必须报警
                if [ "$nvol" -eq 0 ]; then
                    DIFFWARN=$((DIFFWARN + 1))
                    printf "  [WARN] %s 的豁免模式没命中任何行——模式过期，判据失效\n" "$base"
                fi
            else
                cp "build/shared/$base.out" "build/tmp/$base.cmp.a"
                cp "build/static/$base.out" "build/tmp/$base.cmp.b"
                nvol=0
            fi
            if cmp -s "build/tmp/$base.cmp.a" "build/tmp/$base.cmp.b"; then
                if [ "$nvol" -gt 0 ]; then
                    printf "  [same] %s 两通道一致（豁免了 %s 行本来就会漂的真实耗时）\n" \
                        "$base" "$nvol"
                else
                    printf "  [same] %s 两通道输出逐字节一致\n" "$base"
                fi
            else
                DIFFWARN=$((DIFFWARN + 1))
                printf "  [DIFF] %s 两通道输出不一致（意外差异）\n" "$base"
                diff "build/tmp/$base.cmp.a" "build/tmp/$base.cmp.b" \
                    | head -10 | sed 's/^/        /'
            fi
        fi
    done
}

if [ -n "${SINGLE:-}" ]; then
    src="examples/${SINGLE}"
    [ -f "$src" ] || { echo "找不到示例：$src"; exit 1; }
    ch=$(basename "$(dirname "$src")" | cut -d_ -f1)
    echo "==== ${SINGLE} ===="
    for channel in shared static; do process_one "$channel" "$src" "$ch"; done
    echo
    echo "通过 $PASS   失败 $FAIL"
    [ "$FAIL" -eq 0 ] || exit 1
    exit 0
fi

for dir in examples/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    num=${name%%_*}
    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do
            [ "$s" = "$num" ] && hit=1
            [ "$s" = "$name" ] && hit=1
        done
        [ "$hit" -eq 1 ] || continue
    fi
    run_dir "$dir"
done

echo
echo "通过 $PASS   失败 $FAIL   输出差异 $DIFFWARN"
if [ "$FAIL" -eq 0 ]; then
    echo "全部通过"
    [ "$DIFFWARN" -eq 0 ] && exit 0
    echo "（有 $DIFFWARN 项跨通道输出不同，请人工确认是否可接受）"
    exit 0
else
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
    exit 1
fi
