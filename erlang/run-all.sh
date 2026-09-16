#!/usr/bin/env bash
# ============================================================
# run-all.sh —— 编译并运行 examples/ 下全部 Erlang 示例（shell 版，等价于 build.ps1）
#
#   ./run-all.sh             编译 + 运行 + 四条判定
#   ./run-all.sh -v          额外打印每个示例的完整输出
#   ./run-all.sh 01 13       只跑指定编号
#   ./run-all.sh --clean     清理 build 目录
#
# 两个通道（同一份 BEAM，只换运行时配置）：
#   A  默认（多调度器）
#   B  +S 1:1（单调度器）
#   两通道都要过四条判定，并且两通道输出必须**逐字节一致**。
#   为什么不照搬 sml/fortran 的「多实现比对」：本机只有一套 Erlang 实现
#   （erts 17.0.3 / OTP 29），没有第二套可比。改成「同一份代码在两种调度器
#   配置下输出必须完全相同」—— 这条对并发/容器类示例是真约束：map 的迭代
#   顺序每次启动都随机（原子哈希随机种子），ETS set 顺序未定义，打了 pid /
#   ref / 时间戳的输出都会在这里露出来。详见 README。
#
# 判定标准（四条，缺一不可，与 build.ps1 一致）：
#   1. 退出码 0
#   2. stderr 为空
#   3. stdout 里除 TAB/LF/CR 外没有 0..31 的控制字符
#   4. stdout 里有结束标记 "==== NN 结束 ===="
#
# 另外两条会单独记数但不改变通过与否：
#   [same]  两通道输出逐字节一致 / [DIFF] 不一致（不可重复输出）
#
# 注意：不要和 build.ps1 并行跑，两者共用 build/<示例名>/ 下的输出文件。
# ============================================================

set -u
cd "$(dirname "$0")"

VERBOSE=0
CLEAN=0
SELECT=()

for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        --clean)      CLEAN=1 ;;
        -h|--help)    sed -n '2,20p' "$0"; exit 0 ;;
        *)            SELECT+=("$arg") ;;
    esac
done

# ------------------------------------------------------------
# 工具链定位：环境变量 ERL / ERLC 优先，其次 PATH，最后是各平台常见安装路径。
# ------------------------------------------------------------
resolve_tool() {
    local envval="$1"; shift
    local c
    if [ -n "${envval}" ]; then
        printf '%s' "$envval"
        return
    fi
    for c in "$@"; do
        case "$c" in
            */*) [ -x "$c" ] && printf '%s' "$c" && return ;;
            *)   if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return; fi ;;
        esac
    done
    printf ''
}

ERL=$(resolve_tool "${ERL:-}" erl \
      /opt/local/bin/erl /usr/local/bin/erl \
      '/opt/homebrew/bin/erl' \
      '/c/Program Files/Erlang OTP/bin/erl.exe' \
      '/c/scoop/apps/erlang/current/bin/erl.exe')
ERLC=$(resolve_tool "${ERLC:-}" erlc \
       /opt/local/bin/erlc /usr/local/bin/erlc \
       '/opt/homebrew/bin/erlc' \
       '/c/Program Files/Erlang OTP/bin/erlc.exe' \
       '/c/scoop/apps/erlang/current/bin/erlc.exe')

[ -n "$ERL" ]  || { echo "未找到 erl （可设 ERL=/path/to/erl）"; exit 1; }
[ -n "$ERLC" ] || { echo "未找到 erlc（可设 ERLC=/path/to/erlc）"; exit 1; }

EXAMPLES_DIR="examples"
BUILD_DIR="build"
EBIN_DIR="$BUILD_DIR/ebin"

if [ "$CLEAN" -eq 1 ]; then
    rm -rf "$BUILD_DIR"
    echo "[Clean] 已清理 build 目录。"
    exit 0
fi

# erlc 崩溃时会往当前目录写 erl_crash.dump；示例里故意触发的异常也可能写到
# ERL_CRASH_DUMP 指定的位置。指到 /dev/null，免得污染仓库。
export ERL_CRASH_DUMP=/dev/null

# ------------------------------------------------------------
# 必须给 Erlang 一个 UTF-8 locale。
#   实测坑：locale 是 C/POSIX 时，Erlang 把 standard_io 的设备编码定成 latin1，
#   示例里的中文（包括 `==== NN 结束 ====` 这行字面量）会被写成
#   `\x{7ED3}\x{675F}` 这种转义形式，于是「有结束标记」这条判定必然失败，
#   而且 erlc 读源码也会按 latin1 解码 → 字符串字面量的字节全错。
#
#   所以**绝对不能**在这里 `export LC_ALL=C`。判定要用的 tr / grep 是在
#   各自的调用点单独加 LC_ALL=C 的（原因见下面 has_ctrl 的注释）。
# ------------------------------------------------------------
ensure_utf8_locale() {
    case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
        *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*) return ;;
    esac
    local cand
    for cand in en_US.UTF-8 zh_CN.UTF-8 C.UTF-8 en_US.utf8; do
        if [ "$(LC_ALL="$cand" locale charmap 2>/dev/null)" = "UTF-8" ]; then
            export LANG="$cand" LC_ALL="$cand"
            return
        fi
    done
    echo "警告：当前 locale 不是 UTF-8，也没找到可用的 UTF-8 locale。" >&2
    echo "      Erlang 会把中文输出成 \\x{...} 转义形式，结束标记会匹配失败。" >&2
    echo "      请先 export LANG=en_US.UTF-8 再重试。" >&2
}
ensure_utf8_locale

# 单个示例的运行时限（秒）。erl 会因 receive 死等而挂住，必须有上限。
TIMEOUT_SECS=${TIMEOUT_SECS:-60}

echo "erl      : $ERL ($("$ERL" -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt(0).' 2>/dev/null))"
echo "erlc     : $ERLC"
echo "超时上限 : ${TIMEOUT_SECS}s"
echo

mkdir -p "$EBIN_DIR"
PASS=0
FAIL=0
DIFFWARN=0
FAILED_LIST=()

# ------------------------------------------------------------
# 判定辅助
# ------------------------------------------------------------

# 输出里是否混进了「不该出现」的控制字符（TAB / LF / CR 除外）
#
# LC_ALL=C 不能省：UTF-8 locale 下 toybox 的 tr 会做多字节校验，碰到非法
# UTF-8 就报 "tr: Illegal byte sequence" 并**截断输入** —— 结束标记若在
# 截断点之后就查不到，会误报「缺少结束标记」。LC_ALL=C 退化成按字节处理。
# 注意只加在 tr/grep 这一层：整脚本 export 会连带把 Erlang 的设备编码变成 latin1。
has_ctrl() {
    [ "$(LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null \
         | LC_ALL=C tr -dc '\0-\10\13-\14\16-\37' | LC_ALL=C tr -d ' ' | wc -c | tr -d ' ')" != "0" ]
}

# 在输出里找结束标记。先剔掉 NUL 再匹配，免得二进制内容干扰 grep。
marker_present() {
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null | LC_ALL=C grep -qF "$2"
}

# 带超时地跑一条命令，stdout/stderr 分别重定向到文件。
# 本机没有 timeout / gtimeout 命令，只能自己起一个看门狗进程。
# 用法：run_limited <out> <err> <秒> <命令...>
run_limited() {
    local out="$1" err="$2" secs="$3"; shift 3
    local flag="$out.timedout"
    rm -f "$flag"

    "$@" >"$out" 2>"$err" &
    local pid=$!
    (
        sleep "$secs"
        if kill -0 "$pid" 2>/dev/null; then
            echo timed_out >"$flag"
            kill -TERM "$pid" 2>/dev/null
            sleep 1
            kill -KILL "$pid" 2>/dev/null
        fi
    ) &
    local watcher=$!

    wait "$pid" 2>/dev/null
    local rc=$?

    kill "$watcher" 2>/dev/null
    wait "$watcher" 2>/dev/null

    if [ -f "$flag" ]; then
        rm -f "$flag"
        return 124
    fi
    return $rc
}

# 用法：check <标签> <结束标记> <输出文件> <stderr文件> <退出码> <编译日志>
check() {
    local tag="$1" marker="$2" out="$3" err="$4" rc="$5" log="$6"
    local ok=1 why=()

    if [ "$rc" -eq 124 ]; then
        ok=0; why+=("超时 ${TIMEOUT_SECS}s 被杀")
    elif [ "$rc" -ne 0 ]; then
        ok=0; why+=("退出码 $rc")
    fi
    if [ -s "$err" ];  then ok=0; why+=("stderr 非空"); fi
    if has_ctrl "$out"; then ok=0; why+=("输出含控制字符"); fi
    if ! marker_present "$out" "$marker"; then ok=0; why+=("缺少结束标记 ${marker}"); fi

    if [ "$ok" -eq 1 ]; then
        PASS=$((PASS + 1))
        printf "  [OK]   %s\n" "$tag"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$tag")
        printf "  [FAIL] %s —— %s\n" "$tag" "$(printf '%s；' "${why[@]}")"
        if [ -s "$err" ]; then
            LC_ALL=C tr -d '\000' < "$err" | head -6 | sed 's/^/         stderr: /'
        fi
        if [ -s "$log" ]; then
            echo "         编译输出："
            LC_ALL=C tr -d '\000' < "$log" | tail -8 | sed 's/^/         /'
        fi
        if [ -s "$out" ]; then
            echo "         输出末尾："
            LC_ALL=C tr -d '\000' < "$out" | tail -6 | sed 's/^/         /'
        fi
    fi

    if [ "$VERBOSE" -eq 1 ]; then
        LC_ALL=C tr -d '\000' < "$out" | sed 's/^/         /'
    fi
}

# ------------------------------------------------------------
# 编译：examples/*.erl（顶层示例）与 examples/kvapp/*.erl（第 23/28 章用的最小 OTP 应用）
# 一次编一个文件，这样失败时能指出是哪个文件。
# ------------------------------------------------------------
COMPILE_FAILED=0
mkdir -p "$BUILD_DIR/compile"
compile_one() {
    local src="$1"
    local base
    base=$(basename "$src" .erl)
    local log="$BUILD_DIR/compile/$base.log"
    if "$ERLC" -Werror -Wall -o "$EBIN_DIR" "$src" >"$log" 2>&1; then
        rm -f "$log"
        return 0
    fi
    COMPILE_FAILED=$((COMPILE_FAILED + 1))
    echo "  [FAIL] 编译 $src"
    sed 's/^/         /' "$log"
    return 1
}

echo "== 编译 =="
# kvapp/ 是第 23/28 章用的最小 OTP 应用。
# 注意：.app 是**资源文件**（file:consult 读的数据），erlc 不认它，
# 必须手工拷到代码路径上 —— application:load(kvapp) 就是去代码路径里
# 找 build/ebin/kvapp.app 这个名字。忘了拷会得到 {error, {"no such file or directory", ...}}。
if [ -d "$EXAMPLES_DIR/kvapp" ]; then
    for f in "$EXAMPLES_DIR"/kvapp/*.erl; do [ -e "$f" ] || continue; compile_one "$f"; done
    for f in "$EXAMPLES_DIR"/kvapp/*.app; do
        [ -e "$f" ] || continue
        cp "$f" "$EBIN_DIR/$(basename "$f")"
    done
fi
TOTAL=0
for f in "$EXAMPLES_DIR"/[0-9][0-9]-*.erl; do
    [ -e "$f" ] || continue
    TOTAL=$((TOTAL + 1))
    compile_one "$f"
done
if [ "$TOTAL" -eq 0 ]; then
    echo "examples/ 下没有 NN-*.erl 示例文件。"
    exit 1
fi
if [ "$COMPILE_FAILED" -ne 0 ]; then
    echo
    echo "有 $COMPILE_FAILED 个文件编译失败（-Wall -Werror：警告即错误），停止运行。"
    exit 1
fi
echo "  全部 $TOTAL 个示例编译通过（源码 + kvapp/ 辅助模块，零警告）"
echo

# ------------------------------------------------------------
# 运行：每个示例跑两个通道
# ------------------------------------------------------------
echo "== 运行 =="
for f in "$EXAMPLES_DIR"/[0-9][0-9]-*.erl; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .erl)
    mod="$base"
    num=${base%%-*}

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
        [ "$hit" -eq 1 ] || continue
    fi

    marker="==== $num 结束 ===="
    outdir="$BUILD_DIR/$base"
    mkdir -p "$outdir"
    echo "==== $base ===="

    # 通道 A：默认调度器
    run_limited "$outdir/stdout.txt" "$outdir/stderr.txt" "$TIMEOUT_SECS" \
        "$ERL" -noshell -pa "$EBIN_DIR" -run "$mod" main -s init stop
    check "$base (A 默认)" "$marker" \
          "$outdir/stdout.txt" "$outdir/stderr.txt" "$?" "$BUILD_DIR/compile/$base.log"

    # 通道 B：单调度器
    run_limited "$outdir/stdout.s1.txt" "$outdir/stderr.s1.txt" "$TIMEOUT_SECS" \
        "$ERL" -noshell +S 1:1 -pa "$EBIN_DIR" -run "$mod" main -s init stop
    check "$base (B +S 1:1)" "$marker" \
          "$outdir/stdout.s1.txt" "$outdir/stderr.s1.txt" "$?" "$BUILD_DIR/compile/$base.log"

    # 附加检查：两个通道输出必须逐字节一致
    if [ -s "$outdir/stdout.txt" ] && [ -s "$outdir/stdout.s1.txt" ]; then
        if cmp -s "$outdir/stdout.txt" "$outdir/stdout.s1.txt"; then
            printf "  [same] 两通道输出逐字节一致\n"
        else
            DIFFWARN=$((DIFFWARN + 1))
            printf "  [DIFF] 两通道输出不一致（不可重复输出，见 build/%s/）\n" "$base"
            diff "$outdir/stdout.txt" "$outdir/stdout.s1.txt" | head -10 | sed 's/^/         /'
        fi
    fi
done

echo
echo "通过 $PASS   失败 $FAIL   不可重复 $DIFFWARN"
echo "（通道 A 默认 + 通道 B +S 1:1，每个示例各算一项；共 $TOTAL 个示例）"

if [ "$FAIL" -eq 0 ] && [ "$DIFFWARN" -eq 0 ]; then
    echo "全部通过：四条判定全过，且两通道输出逐字节一致。"
    exit 0
fi
if [ "$FAIL" -ne 0 ]; then
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
fi
exit 1
