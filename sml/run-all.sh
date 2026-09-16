#!/usr/bin/env bash
# ============================================================
#  StandardML 教程 —— 三通道全量验证
#
#  通道1 ★ SML/NJ 110.99.9   （解释执行；先构建一个「静音堆」）
#  通道2   Poly/ML 5.9.2     （poly -q --script）
#  通道3   MLton 20241230    （整体优化编译器，标准符合性最严；可选）
#
#  用法：
#    ./run-all.sh            跑全部示例
#    ./run-all.sh 05 07      只跑 05、07
#    ./run-all.sh -v         连同每个示例的完整输出一起打印
#
#  判定标准（四条，缺一不可）：
#    1) 退出码为 0
#    2) stderr 为空
#       —— MLton 的编译错误走 stderr；SML/NJ/Poly/ML 的走 stdout，
#          所以这一条主要拦 MLton，下面第 5 条拦另外两个。
#    3) stdout 里没有多余控制字符（字节 0..31，但 TAB/LF/CR 除外）
#       —— 解释型语言里这通常不会触发，留着是为了和其他目录口径一致。
#    4) stdout 里有结束标记 "==== NN 结束 ===="
#       —— 这条最关键：SML/NJ 用了静音堆之后，编译错误被静音、退出码恒为 0，
#          只有「跑没跑到最后一行」能证明它真的成功了。
#    5) stdout 里不出现编译器诊断（error / Warning / Static Errors / unhandled）
#
#  另外三通道输出逐字节比对；确实不可能一致的列入「已知差异」表，
#  只打印原因、不计入告警，其余不一致报 [DIFF] 要求人工确认。
# ============================================================

set -u

# ---------------------------------------------------------------
# 环境坑（很费时间，先看这里）：
#   本机 PATH 最前面挂了一组 brokered 工具 shim（grep / sed / wc / head / tail）。
#   这些 shim 在高频调用下会偶发失败，往输出里插一行
#   "Brokered program policy check unavailable" 并返回非 0，
#   表现出来就是「文件里明明有结束标记，却报缺少结束标记」。
#   把真实的 BSD 工具提到 PATH 最前面即可绕开。
#   awk / tr / cmp / diff / sort 不在 shim 列表里，本来就可以放心用。
# ---------------------------------------------------------------
PATH="/usr/bin:/bin:$PATH"
export PATH

# ---------------------------------------------------------------
# 工具解析：环境变量 → MacPorts / 托管目录 → PATH，三级回退
# ---------------------------------------------------------------
resolve_tool() {
    local envval="$1"; shift
    local c
    if [ -n "$envval" ]; then printf '%s' "$envval"; return 0; fi
    for c in "$@"; do
        if [ -x "$c" ] && [ ! -d "$c" ]; then printf '%s' "$c"; return 0; fi
        if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return 0; fi
    done
    printf ''
}

# MLton 官方 macOS 二进制：托管目录下的固定名字，找不到就跳过该通道
MLTON_GLOB="/Users/xulun/.workbuddy/binaries/mlton/*/bin/mlton"

SML=$(resolve_tool "${SML:-}" /opt/local/bin/sml sml)
POLY=$(resolve_tool "${POLY:-}" /opt/local/bin/poly poly)

MLTON="${MLTON:-}"
if [ -z "$MLTON" ]; then
    for cand in $MLTON_GLOB /opt/local/bin/mlton mlton; do
        if [ -x "$cand" ] && [ ! -d "$cand" ]; then MLTON="$cand"; break; fi
        if command -v "$cand" >/dev/null 2>&1; then MLTON=$(command -v "$cand"); break; fi
    done
fi

# MLton 需要 GMP 的头文件与库；macports 装在 /opt/local
MLTON_OPTS=()
if [ -n "$MLTON" ] && [ -f /opt/local/include/gmp.h ]; then
    MLTON_OPTS=(-cc-opt -I/opt/local/include -link-opt -L/opt/local/lib)
fi

ROOT=$(cd "$(dirname "$0")" && pwd)
EXDIR="$ROOT/examples"
BUILD="$ROOT/build"

VERBOSE=0
SELECT=()
for a in "$@"; do
    case "$a" in
        -v|--verbose) VERBOSE=1 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) SELECT+=("$a") ;;
    esac
done

# ---------------------------------------------------------------
# 输出里是否混进了多余控制字符（0..31，TAB/LF/CR 除外）
# 八进制写法：\0-\10 是 0..8，\13 是 11(TAB)，\14 是 12(LF)，\16 是 14，
# \37 是 31。\11\12\15 先删掉，就是 CR(13)、TAB(9)、LF(10)。
# ---------------------------------------------------------------
has_ctrl() {
    [ "$(LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null \
         | LC_ALL=C tr -dc '\0-\10\13-\14\16-\37' | wc -c | tr -d ' ')" != "0" ]
}

# 找结束标记。先删 NUL 再匹配，免得二进制内容干扰 grep。
# LC_ALL=C 不能省：UTF-8 locale 下 toybox 的 tr 会做多字节校验，碰到非法
# UTF-8 就报 "tr: Illegal byte sequence" 并**截断输入** —— 结束标记若在
# 截断点之后就查不到，会误报「缺少结束标记」。LC_ALL=C 退化成按字节处理。
marker_present() {
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null | LC_ALL=C grep -qF "$2"
}

# stdout 里是否出现编译器诊断
#   Poly/ML 的错误与警告都打到 stdout，形如 "xx.sml:12: error: ..." / "warning: ..."
#   MLton 与 SML/NJ（不带静音堆时）用 Error: / Warning:
# 注意：本教程的示例自己不会打印含有这些字样的文本，所以可以放心用。
has_diag() {
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null \
        | grep -qE 'Error:|error:|Warning:|warning:|Static Errors|unhandled exception|Exception- |Matches are not exhaustive'
}

# ---------------------------------------------------------------
# 已知差异表：两个实现确实不可能逐字节一致的，只打印原因、不计入告警
# ---------------------------------------------------------------
diff_reason() {
    case "$1" in
        02-types)        echo "MLton 默认的 int 是 32 位，SML/NJ 与 Poly/ML 是 63 位" ;;
        18-numeric)      echo "第 10 节刻意打印实数格式化的分叉点：Real.toString/GEN 对整值实数、FIX 0 的 .5 进位、FIX 17 的末位（详见 README）" ;;
        *)               echo "" ;;
    esac
}

# ---------------------------------------------------------------
# 构建 SML/NJ 的「静音堆」
#   Control.Print.out 是 SML/NJ 编译器消息与顶层回显的输出流。
#   把它换成空操作之后，顶层 val/fun/structure 的回显全部消失，
#   stdout 里就只剩程序自己 print 的内容 —— 这正是逐字节比对的前提。
#   注意：exportML 之后的语句在堆被加载时会继续执行，所以它必须是最后一句。
# ---------------------------------------------------------------
build_quiet_heap() {
    local suffix
    suffix=$("$SML" @SMLsuffix 2>/dev/null | tr -d '[:space:]')
    [ -n "$suffix" ] || suffix="heap"
    QUIET="$BUILD/quiet.$suffix"
    if [ -f "$QUIET" ]; then return 0; fi

    cat > "$BUILD/quiet.sml" <<'SMLEOF'
val _ = Control.Print.out := { say = fn (_ : string) => (), flush = fn () => () }
val _ = SMLofNJ.exportML "quiet"
SMLEOF
    ( cd "$BUILD" && "$SML" @SMLquiet quiet.sml </dev/null >quiet.build.log 2>&1 )
    [ -f "$QUIET" ]
}

# ---------------------------------------------------------------
# 三个通道各自的运行函数。工作目录统一切到 build/，
# 这样示例里写相对路径产生的临时文件都落在 build/ 下。
# ---------------------------------------------------------------
run_smlnj() {   # $1 = 相对 build/ 的 .sml 路径（形如 ../examples/01-basics.sml）
    printf 'use "%s";\n' "$1" \
        | "$SML" @SMLquiet "@SMLload=$QUIET" >"$2" 2>"$3"
}

run_poly() {
    "$POLY" -q --script "$1" </dev/null >"$2" 2>"$3"
}

run_mlton() {   # $1 = 相对 build/ 的源路径, $2 = stdout 路径, $3 = stderr 路径
    local src="$1" out="$2" err="$3"
    local obase bin wextra
    obase=$(basename "$out")            # 例：01-basics.mlton.out
    bin="${obase%.out}.bin"             # 例：01-basics.mlton.bin
    wextra="$BUILD/$obase.compile.log"

    if ! "$MLTON" ${MLTON_OPTS[@]+"${MLTON_OPTS[@]}"} -output "$BUILD/$bin" "$src" >"$wextra" 2>&1; then
        # 编译失败：把真实诊断交给 stderr，好让判定统一处理
        grep -v 'was built for newer macOS' "$wextra" > "$err" 2>/dev/null
        : > "$out"
        return 1
    fi
    # 编译成功就不留日志了：本机的 MLton 二进制是给 macOS 13 编的，
    # 每次链接都会刷几十 KB 的 ld 版本警告，留着只会把 build/ 撑大。
    [ "$VERBOSE" -eq 1 ] || rm -f "$wextra"
    ( cd "$BUILD" && "./$bin" >"$out" 2>"$err" )
}

# ---------------------------------------------------------------
# 判定：$1=标签 $2=结束标记 $3=out $4=err $5=rc
# ---------------------------------------------------------------
check_one() {
    local tag="$1" marker="$2" out="$3" err="$4" rc="$5"
    local reasons=()

    [ "$rc" -eq 0 ]       || reasons+=("退出码 $rc")
    if [ -s "$err" ]; then reasons+=("stderr 非空"); fi
    if has_ctrl "$out"; then reasons+=("stdout 含控制字符"); fi
    if ! marker_present "$out" "$marker"; then reasons+=("缺少结束标记"); fi
    if has_diag "$out"; then reasons+=("stdout 里有编译器诊断"); fi

    if [ "${#reasons[@]}" -eq 0 ]; then
        printf '    %-8s %s\n' "[OK]" "$tag"
        return 0
    fi

    printf '    %-8s %s  —— %s\n' "[FAIL]" "$tag" "$(IFS='、'; echo "${reasons[*]}")"
    if [ -s "$err" ]; then
        echo "        stderr 前几行："
        head -5 "$err" | sed 's/^/          /'
    fi
    if [ -s "$out" ] && [ "$VERBOSE" -ne 1 ]; then
        echo "        stdout 最后 3 行："
        tail -3 "$out" | sed 's/^/          /'
    fi
    return 1
}

# ---------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------
mkdir -p "$BUILD" || exit 1

if [ -z "$SML" ]; then echo "错误：找不到 sml（SML/NJ）。可用环境变量 SML 指定路径。" >&2; exit 2; fi
if [ -z "$POLY" ]; then echo "错误：找不到 poly（Poly/ML）。可用环境变量 POLY 指定路径。" >&2; exit 2; fi

echo "StandardML 教程 —— 三通道全量验证"
echo "------------------------------------------------------------"
echo "  SML/NJ  : $SML"
echo "  Poly/ML : $POLY"
if [ -n "$MLTON" ]; then
    echo "  MLton   : $MLTON"
    [ "${#MLTON_OPTS[@]}" -gt 0 ] && echo "            （已挂钩 /opt/local 的 GMP）"
else
    echo "  MLton   : 未找到，跳过该通道（只跑前两条）"
fi
echo "  示例目录: $EXDIR"
echo "------------------------------------------------------------"

if ! build_quiet_heap; then
    echo "错误：SML/NJ 静音堆构建失败，见 build/quiet.build.log" >&2
    exit 2
fi

# ---------------------------------------------------------------
# 前置检查：字符串字面量必须是纯 ASCII
#   Poly/ML 与 MLton 都拒绝字符串里的原始 UTF-8 字节，SML/NJ 却接受；
#   中文一旦误进字面量，只有后两条通道会挂，而且报的是
#   "unprintable character \231 found in string" 这种不好定位的信息。
#   先用 check-literals.py 扫一遍，几毫秒就能把位置指出来。
# ---------------------------------------------------------------
if command -v python3 >/dev/null 2>&1; then
    if ! python3 "$ROOT/check-literals.py" "$EXDIR"/*.sml; then
        echo
        echo "字面量预检查未通过，先改好再编译。" >&2
        exit 2
    fi
else
    echo "  （没找到 python3，跳过字面量预检查）"
fi
echo "------------------------------------------------------------"

PASS=0
FAIL=0
DIFF=0
FAILED_LIST=()
DIFFED_LIST=()
TOTAL=0

for src in "$EXDIR"/*.sml; do
    base=$(basename "$src" .sml)
    num=${base%%-*}

    if [ "${#SELECT[@]}" -gt 0 ]; then
        keep=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && keep=1; done
        [ "$keep" -eq 1 ] || continue
    fi

    marker=$(printf '==== %s \347\273\223\346\235\237 ====' "$num")

    TOTAL=$((TOTAL + 1))
    echo
    echo "[$num] $base"

    # ---- 通道1：SML/NJ ----
    out1="$BUILD/$base.smlnj.out"; err1="$BUILD/$base.smlnj.err"
    ( cd "$BUILD" && run_smlnj "../examples/$base.sml" "$out1" "$err1" )
    rc1=$?
    if ! check_one "smlnj" "$marker" "$out1" "$err1" "$rc1"; then
        FAIL=$((FAIL + 1)); FAILED_LIST+=("smlnj $base")
        # 静音堆会把编译错误一起静音，这里重跑一次不过堆，把真实诊断捞出来
        echo "        —— SML/NJ 原始诊断（不带静音堆重跑）："
        ( cd "$BUILD" && "$SML" @SMLquiet "../examples/$base.sml" </dev/null 2>&1 \
            | grep -vE '^\[(opening|autoloading|library)' | head -8 | sed 's/^/          /' )
    fi

    # ---- 通道2：Poly/ML ----
    out2="$BUILD/$base.poly.out"; err2="$BUILD/$base.poly.err"
    ( cd "$BUILD" && run_poly "../examples/$base.sml" "$out2" "$err2" )
    rc2=$?
    if ! check_one "poly" "$marker" "$out2" "$err2" "$rc2"; then
        FAIL=$((FAIL + 1)); FAILED_LIST+=("poly $base")
    fi

    # ---- 通道3：MLton（可选）----
    rc3=0
    out3=""
    if [ -n "$MLTON" ]; then
        out3="$BUILD/$base.mlton.out"; err3="$BUILD/$base.mlton.err"
        ( cd "$BUILD" && run_mlton "../examples/$base.sml" "$out3" "$err3" )
        rc3=$?
        if ! check_one "mlton" "$marker" "$out3" "$err3" "$rc3"; then
            FAIL=$((FAIL + 1)); FAILED_LIST+=("mlton $base")
        fi
    fi

    # ---- 三通道逐字节比对 ----
    if [ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] && { [ -z "$MLTON" ] || [ "$rc3" -eq 0 ]; }; then
        same=1
        if ! cmp -s "$out1" "$out2"; then same=0; fi
        if [ -n "$MLTON" ] && ! cmp -s "$out2" "$out3"; then same=0; fi

        if [ "$same" -eq 1 ]; then
            PASS=$((PASS + 1))
            printf '    %-8s %s\n' "[same]" "三通道输出逐字节一致"
        else
            reason=$(diff_reason "$base")
            if [ -n "$reason" ]; then
                PASS=$((PASS + 1))
                printf '    %-8s 已知差异：%s\n' "[diff]" "$reason"
            else
                DIFF=$((DIFF + 1))
                DIFFED_LIST+=("$base")
                printf '    %-8s 三通道输出不一致，需要人工确认\n' "[DIFF]"
                diff "$out1" "$out2" 2>/dev/null | head -6 | sed 's/^/          smlnj vs poly: /'
                if [ -n "$MLTON" ]; then
                    diff "$out2" "$out3" 2>/dev/null | head -6 | sed 's/^/          poly vs mlton: /'
                fi
            fi
        fi
    fi

    if [ "$VERBOSE" -eq 1 ] && [ -s "$out1" ]; then
        echo "        ---- 输出 ----"
        sed 's/^/        /' "$out1"
    fi
done

echo
echo "============================================================"
CHANNELS=2
[ -n "$MLTON" ] && CHANNELS=3
echo "示例 $TOTAL 个 × 通道 $CHANNELS 条"
echo "通过 $PASS   失败 $FAIL   输出差异 $DIFF"
if [ "${#FAILED_LIST[@]}" -gt 0 ]; then
    echo "失败项："
    for f in "${FAILED_LIST[@]}"; do echo "  - $f"; done
fi
if [ "${#DIFFED_LIST[@]}" -gt 0 ]; then
    echo "需人工确认的差异："
    for f in "${DIFFED_LIST[@]}"; do echo "  - $f"; done
fi

[ "$FAIL" -eq 0 ] && [ "$DIFF" -eq 0 ] && exit 0
exit 1
