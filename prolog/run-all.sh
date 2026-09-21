#!/usr/bin/env bash
# =============================================================================
# run-all.sh —— Prolog 教程三通道验证入口（shell 版，判定与 build.ps1 一致）
#
#   ./run-all.sh              跑全部示例，只打印摘要
#   ./run-all.sh -v           跑全部并显示每个通道抽出的输出区间
#   ./run-all.sh 07 24        只跑指定编号
#   ./run-all.sh -Clean       清理 build/ 目录
#
# 三条通道（缺哪个跳哪个）：
#   1. swipl    —— SWI-Prolog 解释执行
#   2. gprolog  —— GNU Prolog 解释执行
#   3. gplc     —— GNU Prolog 编译成本地可执行文件后运行
#
# 六条判定（全部满足才算通过）：
#   1. 退出码为 0
#   2. stderr 为空（连警告都不许有）
#   3. stdout 里同时出现「==== NN 开始 ====」与「==== NN 结束 ====」
#   4. 两条标记之间（下称「输出区间」）非空，且不含 CR / ESC 等控制字符
#   5. 区间内不出现异常/失败痕迹
#   6. 三条通道抽出的输出区间【逐字节相同】
#
# 第 6 条为什么这么设计：GNU Prolog 启动时把 banner 与编译信息打进 stdout，
# SWI 与 GNU 的变量编号、浮点打印位数、错误项形状又各不相同。所以本教程
# 约定示例只打印「两套引擎必然一致」的内容，并用 开始/结束 标记把这段
# 内容圈起来；脚本抽区间再逐字节比对，banner 这类噪声自然被排除在外。
# =============================================================================

set -u
cd "$(dirname "$0")"

VERBOSE=0
CLEAN=0
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose)  VERBOSE=1 ;;
        -Clean|-clean) CLEAN=1 ;;
        *)             SELECT+=("$arg") ;;
    esac
done

if [ "$CLEAN" -eq 1 ]; then
    rm -rf build
    echo "已清理 build/"
    exit 0
fi

# ---------- 工具链定位（PATH 找不到时回退常见安装位置） ----------
find_tool() {
    local name="$1"; shift
    local p
    p=$(command -v "$name" 2>/dev/null) && [ -n "$p" ] && { printf '%s' "$p"; return; }
    local c
    for c in "$@"; do
        [ -x "$c" ] && { printf '%s' "$c"; return; }
    done
    printf ''
}

SWIPL=$(find_tool swipl /opt/local/bin/swipl /usr/local/bin/swipl /opt/homebrew/bin/swipl)
GPROLOG=$(find_tool gprolog /opt/local/bin/gprolog /usr/local/bin/gprolog /usr/bin/gprolog)
GPLC=$(find_tool gplc /opt/local/bin/gplc /usr/local/bin/gplc /usr/bin/gplc)

echo "=== 工具链 ==="
if [ -n "$SWIPL" ];   then echo "  swipl    : $SWIPL";   else echo "  swipl    : 未找到（跳过该通道）"; fi
if [ -n "$GPROLOG" ]; then echo "  gprolog  : $GPROLOG"; else echo "  gprolog  : 未找到（跳过该通道）"; fi
if [ -n "$GPLC" ];    then echo "  gplc     : $GPLC";    else echo "  gplc     : 未找到（跳过该通道）"; fi
if [ -z "$SWIPL" ] && [ -z "$GPROLOG" ]; then
    echo "两个解释器都没有，无法验证。"
    exit 1
fi

mkdir -p build
printf ':- initialization(main).\n' > build/_entry.pl

PASS=0
FAIL=0
FAILED=()

# ---------- 判定核心 ----------
# judge <标签> <rc> <stdout> <stderr> <开始标记> <结束标记> <区间文件>
judge() {
    local tag="$1" rc="$2" out="$3" err="$4" bgn="$5" end="$6" sec="$7"
    local why=""

    [ "$rc" -eq 0 ] || why="${why}退出码=$rc; "
    [ -s "$err" ] && why="${why}stderr 非空; "
    grep -qF "$bgn" "$out" 2>/dev/null || why="${why}缺开始标记; "
    grep -qF "$end" "$out" 2>/dev/null || why="${why}缺结束标记; "

    sed -n "/^${bgn}\$/,/^${end}\$/p" "$out" > "$sec" 2>/dev/null

    [ -s "$sec" ] || why="${why}输出区间为空; "
    if [ -s "$sec" ]; then
        LC_ALL=C grep -q $'\r' "$sec" && why="${why}含 CR; "
        LC_ALL=C grep -q $'\033' "$sec" && why="${why}含 ESC; "
        LC_ALL=C grep -q 'uncaught\|command-line goal\|异常:\|运行失败' "$sec" \
            && why="${why}区间内有溃逃痕迹; "
    fi

    if [ -z "$why" ]; then
        printf '    [OK]   %s\n' "$tag"
        return 0
    fi
    printf '    [FAIL] %s  (%s)\n' "$tag" "$why"
    [ -s "$err" ] && sed 's/^/           stderr: /' "$err" | head -4
    if [ -s "$out" ] && ! grep -qF "$end" "$out"; then
        echo "           stdout 末 4 行："
        tail -4 "$out" | sed 's/^/           /'
    fi
    return 1
}

# ---------- 单通道执行：把 rc 打到 stdout ----------
run_channel() {
    local ch="$1" src="$2" pfx="$3"
    local out="$pfx.out" err="$pfx.err" rc

    case "$ch" in
        swipl)
            "$SWIPL" -Dencoding=utf8 -q -f "$src" \
                -g "set_stream(user_output,encoding(utf8)),set_stream(user_error,encoding(utf8)),main" \
                -t halt </dev/null >"$out" 2>"$err"
            rc=$?
            ;;
        gprolog)
            "$GPROLOG" --consult-file "$src" --entry-goal main </dev/null >"$out" 2>"$err"
            rc=$?
            ;;
        gplc)
            cat build/_entry.pl "$src" > "$pfx.pl"
            if "$GPLC" "$pfx.pl" -o "$pfx.bin" >"$pfx.build" 2>&1; then
                "$pfx.bin" </dev/null >"$out" 2>"$err"
                rc=$?
            else
                : >"$out"
                cp "$pfx.build" "$err"
                rc=1
            fi
            ;;
    esac
    printf '%s' "$rc"
}

# ---------- 主循环 ----------
for dir in examples/[0-9]*/; do
    [ -d "$dir" ] || continue
    dname=$(basename "$dir")
    num=${dname%%_*}
    src="$dir$dname.pl"
    [ -f "$src" ] || continue

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
        [ "$hit" -eq 1 ] || continue
    fi

    echo "==== 示例 $dname ===="
    bgn="==== $num 开始 ===="
    end="==== $num 结束 ===="

    secs=()
    seen=()
    for ch in swipl gprolog gplc; do
        case "$ch" in
            swipl)   [ -n "$SWIPL" ]   || continue ;;
            gprolog) [ -n "$GPROLOG" ] || continue ;;
            gplc)    [ -n "$GPLC" ]    || continue ;;
        esac
        pfx="build/${dname}.${ch}"
        rc=$(run_channel "$ch" "$src" "$pfx")
        if judge "$(printf '%-8s %s' "$ch" "$dname")" "$rc" "$pfx.out" "$pfx.err" "$bgn" "$end" "$pfx.sec"; then
            PASS=$((PASS + 1))
            secs+=("$pfx.sec")
            seen+=("$ch")
        else
            FAIL=$((FAIL + 1))
            FAILED+=("$dname/$ch")
        fi
        [ "$VERBOSE" -eq 1 ] && sed 's/^/           /' "$pfx.sec" 2>/dev/null
    done

    # 判定第 6 条：通道间逐字节一致
    if [ ${#secs[@]} -ge 2 ]; then
        ref="${secs[0]}"
        i=1
        while [ "$i" -lt ${#secs[@]} ]; do
            if cmp -s "$ref" "${secs[$i]}"; then
                printf '    [OK]   区间一致  %s = %s\n' "${seen[0]}" "${seen[$i]}"
                PASS=$((PASS + 1))
            else
                printf '    [FAIL] 区间不一致  %s vs %s\n' "${seen[0]}" "${seen[$i]}"
                diff "$ref" "${secs[$i]}" | head -10 | sed 's/^/           /'
                FAIL=$((FAIL + 1))
                FAILED+=("$dname/${seen[$i]}#diff")
            fi
            i=$((i + 1))
        done
    fi

    # 观察通道 observe_*.pl：只要求「跑到底」，不参与逐字节比对。
    # 文件名后缀可指定只在某个引擎上跑：
    #   observe_xxx_swi.pl  → 只在 SWI 上跑（如原生模块、library(clpfd)）
    #   observe_xxx_gnu.pl  → 只在 GNU 上跑（如原生模块、内建 fd 约束）
    #   observe_xxx.pl      → 两个引擎都跑
    for obs in "$dir"observe_*.pl; do
        [ -f "$obs" ] || continue
        obase=$(basename "$obs" .pl)
        for ch in swipl gprolog; do
            case "$ch" in
                swipl)   [ -n "$SWIPL" ]   || continue ;;
                gprolog) [ -n "$GPROLOG" ] || continue ;;
            esac
            case "$obase" in
                *_swi) [ "$ch" = swipl ]  || continue ;;
                *_gnu) [ "$ch" = gprolog ] || continue ;;
            esac
            opfx="build/${dname}.${obase}"
            rc=$(run_channel "$ch" "$obs" "$opfx.$ch")
            if judge "$(printf '%-8s %s(观察)' "$ch" "$obase")" "$rc" \
                    "$opfx.$ch.out" "$opfx.$ch.err" \
                    "==== $num 观察 开始 ====" "==== $num 观察 结束 ====" "$opfx.$ch.sec"; then
                PASS=$((PASS + 1))
            else
                FAIL=$((FAIL + 1))
                FAILED+=("$dname/$obase/$ch")
            fi
        done
    done
done

echo
echo "================================"
echo "通过 $PASS    失败 $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "全部通过"
    exit 0
fi
echo "失败项："
for t in "${FAILED[@]}"; do echo "  - $t"; done
exit 1
