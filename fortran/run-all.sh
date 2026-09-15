#!/usr/bin/env bash
# ============================================================
# run-all.sh —— 用两个 Fortran 编译器跑遍所有示例（shell 版，等价于 build.ps1）
#
#   ./run-all.sh            只打印每条通道的通过/失败摘要
#   ./run-all.sh -v         附带每个示例的完整输出
#   ./run-all.sh 03 07      只跑指定编号
#
# 两个通道：
#   1. flang     —— LLVM flang 23（主通道）
#   2. gfortran  —— GNU Fortran 15（对照通道）
#
# 判定标准（与 build.ps1 一致）：
#   退出码 0 + stderr 为空 + 输出里没有 NUL 字节 + 输出里有 "==== NN 结束 ===="
#
#   最后那条 NUL 检查不是多余的：格式描述符写少了会触发「格式重现」，
#   多出来的整数会被 (a) 描述符当成字符，原始字节直接混进 stdout。
#   这种输出用肉眼翻看不出来，但一定不是“通过”。
#
# 自动加分项：
#   * 源码里出现 !$omp 的示例自动加 -fopenmp（不需要手工维护清单）
#   * Windows 上自动给 flang 补链接 compiler-rt builtins（存在才加）
#   * flang / gfortran 的输出会逐字节比对；已知差异（见 diff_reason）
#     只打印原因、不计入告警
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
# 工具链定位：环境变量 FLANG / GFORTRAN 优先，其次常见的 MacPorts 路径，
#             最后退回 PATH 上的通用名字
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

FLANG=$(resolve_tool "${FLANG:-}"  flang-mp-23 /opt/local/bin/flang-mp-23 flang flang-new)
GFORTRAN=$(resolve_tool "${GFORTRAN:-}" gfortran-mp-15 /opt/local/bin/gfortran-mp-15 gfortran)

# Windows 上 LLVM 版 flang 的运行时库引用了 128 位转换例程（__floattidf 等），
# 链接时必须补上 compiler-rt builtins。这个文件只在 Windows 的 LLVM 发行版里
# 存在，macOS/Linux 探测不到就自动跳过。
FLANG_RT_LIB=""
if [ -n "$FLANG" ]; then
    FLANG_RT_LIB=$(ls "$(dirname "$FLANG")/../lib/clang/"*/lib/windows/clang_rt.builtins-x86_64.lib 2>/dev/null | head -1)
fi

[ -n "$FLANG" ]    || echo "未找到 flang（可设 FLANG=/path/to/flang）"
[ -n "$GFORTRAN" ] || echo "未找到 gfortran（可设 GFORTRAN=/path/to/gfortran）"
if [ -z "$FLANG" ] && [ -z "$GFORTRAN" ]; then exit 1; fi

echo "flang    : ${FLANG:-<缺失>}"
echo "gfortran : ${GFORTRAN:-<缺失>}"
echo

# 已知的跨编译器差异及其原因。这些示例的输出本来就不该逐字节相同，
# 打印原因即可，不计入告警；其余示例若输出不同则视为需要人工确认。
diff_reason() {
    case "$1" in
        02-kinds)          echo "flang 23 无四倍精度（real128 = -1），gfortran 有" ;;
        08-formatted-io)   echo "namelist 写出的排版由编译器决定" ;;
        09-files)          echo "flang 的 Windows 运行时 inquire(size=) 恒为 -1 且 close(status='delete') 失效" ;;
        15-algorithms)     echo "洗牌用了 random_number，两个发生器不同" ;;
        16-numeric)        echo "Richardson 外推的末位浮点差异（FMA 收缩与否随编译器/平台不同）" ;;
        17-random)         echo "随机数发生器与种子长度都不同" ;;
        20-parallel)       echo "含墙钟计时，线程调度也不保证一致" ;;
        21-errors-testing) echo "flang 的 Windows 运行时 inquire(size=) 恒为 -1" ;;
        *)                 echo "" ;;
    esac
}

mkdir -p build
PASS=0
FAIL=0
DIFFWARN=0
FAILED_LIST=()

# 输出里是否混进了「不该出现」的控制字符（制表符、换行、回车除外）。
# 出现这种情况几乎只有一个原因：写语句的格式描述符个数少于数据项个数，
# 触发了「格式重现」——多出来的整数被 (a) 描述符当成字符，原始字节直接落盘。
# 正整数的低字节后面通常跟着三个 NUL，所以最常见的表现就是 NUL 字节。
has_ctrl() {
    # 先放过 TAB(11)/LF(12)/CR(15)（八进制），再把 0..31 里剩下的都筛出来
    [ "$(LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null \
         | LC_ALL=C tr -dc '\0-\10\13-\14\16-\37' | wc -c | tr -d ' ')" != "0" ]
}

# 在输出里找结束标记。先剔掉控制字符再匹配，免得二进制内容干扰 grep。
marker_present() {
    tr -d '\000' < "$1" 2>/dev/null | grep -qF "$2"
}

# 用法：check <标签> <期望结束标记> <输出文件> <stderr文件> <退出码> <日志文件>
check() {
    local tag="$1" marker="$2" out="$3" err="$4" rc="$5" log="$6"
    local ok=1 why=()

    if [ "$rc" -ne 0 ]; then ok=0; why+=("退出码 $rc"); fi
    if [ -s "$err" ];   then ok=0; why+=("stderr 非空"); fi
    if has_ctrl "$out";  then
        ok=0
        why+=("输出含控制字符：格式描述符少于数据项，触发了格式重现")
    fi
    if ! marker_present "$out" "$marker"; then ok=0; why+=("缺少结束标记"); fi

    if [ "$ok" -eq 1 ]; then
        PASS=$((PASS + 1))
        printf "  [%s] %s\n" "OK" "$tag"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$tag")
        printf "  [%s] %s —— %s\n" "FAIL" "$tag" "$(printf '%s；' "${why[@]}")"
        if [ -s "$err" ]; then sed 's/^/        stderr: /' "$err" | head -5; fi
        if ! marker_present "$out" "$marker"; then
            echo "        stdout 最后 5 行："
            tail -5 "$out" | tr -d '\000' | sed 's/^/        /'
        fi
        if [ -s "$log" ]; then
            echo "        编译/链接输出："
            head -8 "$log" | sed 's/^/        /'
        fi
    fi

    if [ "$VERBOSE" -eq 1 ]; then
        tr -d '\000' < "$out" | sed 's/^/        /'
    fi
}

# 编译一个示例：build_and_run <通道名> <编译器> <源文件> <basename>
build_and_run() {
    local channel="$1" cc="$2" src="$3" base="$4"
    local moddir="build/mod/$channel"
    local bin="build/$base.$channel"
    mkdir -p "$moddir"

    # .f 是固定格式的老代码；.f90 才是现代自由格式。老代码不开 -pedantic：
    # 老特性本来就是标准的「已删/已过时」集合，用现代标准去挑毛病没意义。
    # -std 的选择还要看编译器：gfortran 用 -std=legacy 压掉「已删特性」警告；
    # flang 23 不认 -std=legacy（只接受 -std=f2018），它不加 -std 时本来就
    # 接受固定格式 —— 这本身就是一个跨编译器差异。
    local flags
    case "$src" in
        *.f)
            flags=(-O2 -J "$moddir")
            [ "$channel" = gfortran ] && flags+=(-std=legacy)
            ;;
        *)
            flags=(-std=f2018 -pedantic -O2 -J "$moddir")
            ;;
    esac
    # 用到 OpenMP 的示例自动补 -fopenmp
    if grep -qF '!$omp' "$src"; then
        flags+=(-fopenmp)
    fi
    # Windows 上 LLVM 版 flang 需要补链接 compiler-rt builtins（见脚本头部的说明）
    if [ "$channel" = flang ] && [ -n "$FLANG_RT_LIB" ]; then
        flags+=("$FLANG_RT_LIB")
    fi

    if ! "$cc" "${flags[@]}" "$src" -o "$bin" >"build/$base.$channel.build" 2>&1; then
        : >"build/$base.$channel.out"
        echo "编译失败，见 build/$base.$channel.build" >"build/$base.$channel.err"
        return 1
    fi
    # 示例里有相对路径读写，统一在 build/ 下运行
    ( cd build && "./$base.$channel" >"$base.$channel.out" 2>"$base.$channel.err" )
    return $?
}

for f in examples/[0-9]*.f90 examples/[0-9]*.f; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    base=${base%.*}
    num=${base%%-*}

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
        [ "$hit" -eq 1 ] || continue
    fi

    marker="==== $num 结束 ===="
    echo "==== $base ===="

    # ---- 通道 1：flang ----
    if [ -n "$FLANG" ]; then
        build_and_run flang "$FLANG" "$f" "$base"
        rc=$?
        check "flang    $base" "$marker" \
              "build/$base.flang.out" "build/$base.flang.err" "$rc" "build/$base.flang.build"
    fi

    # ---- 通道 2：gfortran ----
    if [ -n "$GFORTRAN" ]; then
        build_and_run gfortran "$GFORTRAN" "$f" "$base"
        rc=$?
        check "gfortran $base" "$marker" \
              "build/$base.gfortran.out" "build/$base.gfortran.err" "$rc" "build/$base.gfortran.build"
    fi

    # ---- 附加检查：两个编译器的输出应当逐字节一致 ----
    if [ -n "$FLANG" ] && [ -n "$GFORTRAN" ] \
       && [ -s "build/$base.flang.out" ] && [ -s "build/$base.gfortran.out" ]; then
        # 先比输出：一致就是 [same]，不一致再看是不是已知差异。
        # 已知差异的条目在 macOS 上往往是一致的，所以先 cmp 才不会误报。
        if cmp -s "build/$base.flang.out" "build/$base.gfortran.out"; then
            printf "  [same] 两编译器输出逐字节一致\n"
        else
            reason=$(diff_reason "$base")
            if [ -n "$reason" ]; then
                printf "  [diff] 已知差异：%s\n" "$reason"
            else
                DIFFWARN=$((DIFFWARN + 1))
                printf "  [DIFF] 两编译器输出不一致（意外差异，见 build/$base.*.out）\n"
                diff "build/$base.flang.out" "build/$base.gfortran.out" | head -10 | sed 's/^/        /'
            fi
        fi
    fi
done

echo
echo "通过 $PASS   失败 $FAIL   输出差异 $DIFFWARN"
if [ "$FAIL" -eq 0 ]; then
    echo "全部通过"
    [ "$DIFFWARN" -eq 0 ] && exit 0
    echo "（有 $DIFFWARN 项跨编译器输出不同，请人工确认是否可接受）"
    exit 0
else
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
    exit 1
fi
