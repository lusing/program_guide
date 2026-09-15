#!/usr/bin/env bash
# ============================================================
# run-all.sh —— 用两个引擎跑遍所有示例（shell 版，等价于 build.ps1）
#
#   ./run-all.sh          只打印每条通道的通过/失败摘要
#   ./run-all.sh -v       附带每个示例的完整输出
#   ./run-all.sh 03 07    只跑指定编号
#
# 三个通道：
#   1. swipl     —— SWI-Prolog 解释执行
#   2. gprolog   —— GNU Prolog 解释执行
#   3. gplc      —— GNU Prolog 编译成本地可执行文件后运行
# 判定标准（与 build.ps1 一致）：退出码 0 + stderr 为空 + 输出里有 "==== NN 结束 ===="
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

SWIPL=$(command -v swipl   || echo "")
GPROLOG=$(command -v gprolog || echo "")
GPLC=$(command -v gplc     || echo "")

if [ -z "$SWIPL" ];   then echo "未找到 swipl";   fi
if [ -z "$GPROLOG" ]; then echo "未找到 gprolog"; fi
if [ -z "$GPLC" ];    then echo "未找到 gplc";    fi
if [ -z "$SWIPL" ] && [ -z "$GPROLOG" ]; then exit 1; fi

mkdir -p build
PASS=0
FAIL=0
FAILED_LIST=()

# 用法：check <标签> <期望的结束标记> <输出文件> <stderr文件> <退出码> <日志>
check() {
    local tag="$1" marker="$2" out="$3" err="$4" rc="$5" log="$6"
    local ok=1
    [ "$rc" -eq 0 ] || ok=0
    [ -s "$err" ] && ok=0
    grep -q "$marker" "$out" 2>/dev/null || ok=0

    if [ "$ok" -eq 1 ]; then
        PASS=$((PASS + 1))
        printf "  [%s] %s\n" "OK" "$tag"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$tag")
        printf "  [%s] %s (rc=%s)\n" "FAIL" "$tag" "$rc"
        [ -s "$err" ] && sed 's/^/        stderr: /' "$err" | head -5
        if ! grep -q "$marker" "$out" 2>/dev/null; then
            echo "        stdout 缺少结束标记，最后 5 行："
            tail -5 "$out" | sed 's/^/        /'
        fi
    fi

    if [ "$VERBOSE" -eq 1 ]; then
        sed 's/^/        /' "$log"
    fi
}

for f in examples/[0-9]*.pl; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .pl)
    num=${base%%-*}

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
        [ "$hit" -eq 1 ] || continue
    fi

    marker="==== $num 结束 ===="
    echo "==== $base ===="

    # ---- 通道 1：SWI-Prolog ----
    if [ -n "$SWIPL" ]; then
        log="build/$base.swi.log"
        # -Dencoding=utf8 + set_stream：Windows 上 swipl 默认按 ANSI 代码页读源文件、
        # 写重定向流，UTF-8 中文示例会报 Illegal multibyte Sequence；
        # macOS/Linux 上等价无操作，保持单一代码路径。
        SWI_GOAL='set_stream(user_output,encoding(utf8)),set_stream(user_error,encoding(utf8)),main'
        "$SWIPL" -Dencoding=utf8 -q -f "$f" -g "$SWI_GOAL" -t halt </dev/null >"$log" 2>"build/$base.swi.err"
        rc=$?
        check "swipl    $base" "$marker" "$log" "build/$base.swi.err" "$rc" "$log"
    fi

    # ---- 通道 2：GNU Prolog 解释执行 ----
    if [ -n "$GPROLOG" ]; then
        log="build/$base.gnu.log"
        "$GPROLOG" --consult-file "$f" --entry-goal main </dev/null >"$log" 2>"build/$base.gnu.err"
        rc=$?
        check "gprolog  $base" "$marker" "$log" "build/$base.gnu.err" "$rc" "$log"
    fi

    # ---- 通道 3：gplc 编译成本地可执行文件 ----
    if [ -n "$GPLC" ]; then
        { echo ':- initialization(main).'; cat "$f"; } > "build/$base.pl"
        log="build/$base.gplc.log"
        if "$GPLC" "build/$base.pl" -o "build/$base.bin" >"build/$base.gplc.build" 2>&1; then
            "./build/$base.bin" </dev/null >"$log" 2>"build/$base.gplc.err"
            rc=$?
        else
            : >"$log"
            cp "build/$base.gplc.build" "build/$base.gplc.err"
            rc=1
        fi
        check "gplc     $base" "$marker" "$log" "build/$base.gplc.err" "$rc" "$log"
    fi
done

echo
echo "通过 $PASS   失败 $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "全部通过"
    exit 0
else
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
    exit 1
fi
