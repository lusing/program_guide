#!/usr/bin/env bash
# ============================================================
# run-all.sh —— Io 教程统一验证入口（shell 版，等价于 build.ps1）
#
#   ./run-all.sh              跑全部示例，只打印摘要
#   ./run-all.sh -v           附带每个示例的完整区间输出
#   ./run-all.sh 09 13        只跑指定编号（两位数字或目录名均可）
#   ./run-all.sh --no-rerun   跳过「重跑稳定」检查（省一半时间）
#
# 通道：同一个 VM 的两个二进制
#   io          动态链接版（依赖安装前缀里的 libiovmall.dylib，运行时按
#               rpath/安装前缀找动态库与 addon）
#   io_static   静态单文件版（不依赖任何外部文件，addon 查找路径同左）
# 两个二进制由同一份源码编译，因此「跨通道逐字节一致」在这里不是
# 检验两种语义，而是检验示例**没有偷偷依赖动态库加载 / 安装前缀**。
#
# 判定标准（每条通道都要过）：
#   1. 退出码为 0
#   2. stderr 为空
#   3. stdout 里同时出现 "==== NN 开始 ====" 与 "==== NN 结束 ===="
#   4. 两个标记之间的区间非空，且不含 \r 或 ESC
#   5. 区间里没有溃逃痕迹（未捕获异常横幅：「  Exception: …」紧跟一行纯 '-'）
# 另有两条跨运行判定：
#   6. 两条通道抽出的区间逐字节一致（LC_ALL=C cmp）
#   7. 同一条通道连跑两次，区间逐字节一致（抓 Map 迭代序、地址、时间等非确定性）
#
# 为什么必须有「结束标记」这一条：Io 的**未捕获异常会中断脚本、却仍然退出 0**，
# 只判退出码会放过「跑到一半就死了」的假阳性。见 examples/13_exceptions/
# observe_13_uncaught.io（专门把这个行为做成可验证的观察项）。
#
# 工具链一律探测、不硬编码路径；找不到的通道自动跳过（缺 io 只剩 io_static 也照样能跑）。
# 所有探测都带超时（gtimeout/timeout 有则用；都没有就用后台+轮询兜底），
# 免得一个不终止的示例把整个回归挂住。
# ============================================================
set -u
cd "$(dirname "$0")" || exit 1

PROJECT_ROOT=$(pwd)
BUILD_DIR="$PROJECT_ROOT/build"
EXAMPLES_DIR="$PROJECT_ROOT/examples"

VERBOSE=0
RERUN=1
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        --no-rerun)   RERUN=0 ;;
        -h|--help)    sed -n '2,40p' "$0"; exit 0 ;;
        *)            SELECT+=("$arg") ;;
    esac
done

# ------------------------------------------------------------
# 工具探测：find_tool <name> [候选绝对路径...]
# ------------------------------------------------------------
find_tool() {
    local name="$1"; shift
    local hit c
    hit=$(command -v "$name" 2>/dev/null) && { printf '%s\n' "$hit"; return 0; }
    for c in "$@"; do
        if [ -x "$c" ]; then printf '%s\n' "$c"; return 0; fi
    done
    return 1
}

TIMEOUT=$(find_tool gtimeout /opt/local/bin/gtimeout /usr/local/bin/gtimeout \
                    timeout /usr/bin/timeout) || TIMEOUT=""
PROBE_LIMIT=20          # 单个示例的墙钟上限（秒）

with_limit() {          # with_limit <cmd...>：有 timeout 就用，没有就直接跑
    if [ -n "$TIMEOUT" ]; then
        "$TIMEOUT" "$PROBE_LIMIT" "$@"
    else
        "$@"
    fi
}

# 候选二进制必须先自证是 Io —— 机器上可能有个同名但完全无关的 io
probe_io() {
    local bin="$1" out
    [ -x "$bin" ] || return 1
    out=$(with_limit "$bin" -e '"IO-PROBE" println' 2>/dev/null)
    [ "$out" = "IO-PROBE" ]
}

pick_io() {             # pick_io <名字> [候选路径...]
    local name="$1"; shift
    local c
    for c in $(find_tool "$name" "$@" 2>/dev/null); do
        if probe_io "$c"; then printf '%s\n' "$c"; return 0; fi
    done
    return 1
}

IO_DYN=$(pick_io io \
        /opt/local/bin/io /usr/local/bin/io \
        "$HOME/.workbuddy/binaries/io/bin/io" \
        /opt/local/libexec/io/bin/io) || IO_DYN=""
IO_STA=$(pick_io io_static \
        /opt/local/bin/io_static /usr/local/bin/io_static \
        "$HOME/.workbuddy/binaries/io/bin/io_static" \
        /opt/local/libexec/io/bin/io_static) || IO_STA=""

CHANNELS=()
[ -n "$IO_DYN" ] && CHANNELS+=(dyn)
[ -n "$IO_STA" ] && CHANNELS+=(static)
if [ ${#CHANNELS[@]} -eq 0 ]; then
    cat >&2 <<'EOF'
未找到 Io 解释器。任一通道都行：
  · MacPorts：      sudo port install Io        （装出 /opt/local/bin/io）
  · 源码构建：      git clone https://github.com/IoLanguage/io.git
                    git -C io fetch --depth 1 origin tag 2026.04.20-native-final
                    git -C io checkout native-final
                    git -C io submodule update --init --depth 1 deps/parson
                    mkdir -p io/build && cd io/build
                    cmake -DCMAKE_INSTALL_PREFIX=$HOME/.workbuddy/binaries/io .. && make -j8 all && make install
也可以用 IO=/path/to/io_static 指定二进制后再跑。
EOF
    exit 1
fi

bin_for() {
    case "$1" in
        dyn)    printf '%s\n' "$IO_DYN" ;;
        static) printf '%s\n' "$IO_STA" ;;
    esac
}

echo "Io 教程回归（$(date '+%Y-%m-%d %H:%M:%S')）"
echo "工作目录 : $PROJECT_ROOT"
[ -n "$IO_DYN" ] && echo "通道 io      : $IO_DYN ($(with_limit "$IO_DYN" -e 'System version println'))"
[ -n "$IO_STA" ] && echo "通道 io_static: $IO_STA ($(with_limit "$IO_STA" -e 'System version println'))"
[ -n "$TIMEOUT" ] && echo "超时守卫 : $TIMEOUT $PROBE_LIMIT"
echo

mkdir -p "$BUILD_DIR"

PASS=0
FAIL=0
FAILED_LIST=()

# ------------------------------------------------------------
# 判定原语：一律用退出码/存在性判定，不比较被捕获进变量的文本
# （往管道里插话的东西会污染字符串；退出码免疫）。
# tr/grep/sed 一律 LC_ALL=C：UTF-8 locale 下 toybox 的 tr 碰到非法字节会
# 报 Illegal byte sequence 并在那里截断输入，标记若在截断点之后就误报缺标记。
# ------------------------------------------------------------
has_ctrl() {
    LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

marker_present() {
    LC_ALL=C grep -qF "$2" "$1" 2>/dev/null
}

trace_present() {       # 溃逃痕迹 = **未捕获异常横幅**，不是「区间里提到了异常」
    # 合法示例会主动把异常消息打出来做演示（try(...) 的 error），也会打印表格
    # 分隔线（一长串 '-'），所以**任何单独一行的判据都会误报**。未捕获异常的
    # 横幅有固定形状，关键是那三行**连在一起**：
    #     （空行）
    #       Exception: <消息>
    #       ---------          ← 紧跟其上，且是纯 '-' 的分隔线
    #       <栈帧…>
    # 判据：出现 "  Exception: " 行，且**紧邻的下一行**是纯 '-' 分隔线。
    # 只写单边判据会出事：24 章渲染表格时会打 26 个 '-'，被当成溃逃痕迹；
    # 反过来，无脑 grep "Exception" 又会把 13 章的演示输出判成溃逃。
    # 注意这里宁可**细**一点：脚本真崩了会缺结束标记，那个判据兜得住。
    LC_ALL=C awk '
        /^[[:space:]]*Exception:[[:space:]]/ { seen = 1; next }
        seen && /^[[:space:]]*-{3,}[[:space:]]*$/ { found = 1; exit }
        { seen = 0 }
        END { exit(found ? 0 : 1) }
    ' "$1" 2>/dev/null
}

ok()   { PASS=$((PASS + 1)); printf '  [OK]   %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); FAILED_LIST+=("$1: $2"); printf '  [!]    %s  (%s)\n' "$1" "$2"; }

# judge <标签> <前缀> <开始标记> <结束标记>
judge() {
    local tag="$1" pfx="$2" b="$3" e="$4"
    local why=() rc
    # 区间抽取：删掉标记行本身，只剩可比对内容
    LC_ALL=C sed -n "/$b/,/$e/p" "$pfx.out" 2>/dev/null | sed '1d;$d' > "$pfx.sec"

    rc=$(cat "$pfx.exit" 2>/dev/null || echo 1)
    [ "$rc" = 0 ]                 || why+=("退出码 $rc")
    [ ! -s "$pfx.err" ]           || why+=("stderr 非空")
    marker_present "$pfx.out" "$b" || why+=("缺开始标记")
    marker_present "$pfx.out" "$e" || why+=("缺结束标记")
    [ -s "$pfx.sec" ]             || why+=("区间为空")
    has_ctrl "$pfx.sec"           && why+=("区间含控制字符")
    trace_present "$pfx.sec"      && why+=("区间含溃逃痕迹")

    if [ ${#why[@]} -eq 0 ]; then
        ok "$tag"
    else
        bad "$tag" "$(printf '%s；' "${why[@]}")"
        if [ -s "$pfx.err" ]; then
            printf '        stderr 前 6 行：\n'
            head -6 "$pfx.err" | LC_ALL=C tr -d '\000' | sed 's/^/          /'
        fi
        printf '        stdout 最后 6 行：\n'
        tail -6 "$pfx.out" | LC_ALL=C tr -d '\000' | sed 's/^/          /'
    fi
    [ "$VERBOSE" -eq 1 ] && [ -s "$pfx.out" ] && \
        LC_ALL=C tr -d '\000' < "$pfx.out" | sed 's/^/        | /'
    return 0
}

# same <标签> <左文件> <右文件>
same() {
    local tag="$1" a="$2" b="$3"
    if LC_ALL=C cmp -s "$a" "$b"; then
        ok "$tag"
    else
        bad "$tag" "两份区间不一致"
        LC_ALL=C diff "$a" "$b" 2>/dev/null | head -12 | sed 's/^/          /'
    fi
}

# run_channel <通道> <脚本> <前缀>   —— 真实退出码写进 "$pfx.exit"
run_channel() {
    local ch="$1" file="$2" pfx="$3"
    local bin; bin=$(bin_for "$ch")
    IO_BIN="$bin" IO_CHANNEL="$ch" with_limit "$bin" "$file" >"$pfx.out" 2>"$pfx.err"
    echo $? > "$pfx.exit"
}

selected() {            # selected <目录名> <编号>
    [ ${#SELECT[@]} -eq 0 ] && return 0
    local s
    for s in "${SELECT[@]}"; do
        [ "$s" = "$1" ] && return 0
        [ "$s" = "$2" ] && return 0
    done
    return 1
}

TOTAL_EXAMPLES=0
for dir in "$EXAMPLES_DIR"/[0-9]*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    num=${name%%_*}
    file="$dir$name.io"
    [ -f "$file" ] || continue
    selected "$name" "$num" || continue

    TOTAL_EXAMPLES=$((TOTAL_EXAMPLES + 1))
    echo "==== $name ===="
    b="==== $num 开始 ===="
    e="==== $num 结束 ===="

    for ch in "${CHANNELS[@]}"; do
        pfx="$BUILD_DIR/$name.$ch"
        run_channel "$ch" "$file" "$pfx"
        judge "$(printf '%-6s %s' "$ch" "$name")" "$pfx" "$b" "$e"
    done

    # 跨通道一致
    if [ ${#CHANNELS[@]} -ge 2 ]; then
        same "cross  $name" "$BUILD_DIR/$name.dyn.sec" "$BUILD_DIR/$name.static.sec"
    fi

    # 重跑稳定（同通道跑第二遍）
    if [ "$RERUN" -eq 1 ]; then
        ch=${CHANNELS[${#CHANNELS[@]}-1]}
        pfx="$BUILD_DIR/$name.rerun"
        run_channel "$ch" "$file" "$pfx"
        LC_ALL=C sed -n "/$b/,/$e/p" "$pfx.out" 2>/dev/null | sed '1d;$d' > "$pfx.sec"
        same "rerun  $name" "$BUILD_DIR/$name.$ch.sec" "$pfx.sec"
    fi
done

# ------------------------------------------------------------
# 观察项：故意不合规的示例，只在它们自己的观察标记上判定
#   观察项的判定与普通示例**不同**：它恰恰要求「脚本中断 + 退出码仍是 0」。
#   期望表：名称|期望出现的痕迹|必须缺席的字符串
# ------------------------------------------------------------
OBSERVATIONS="
observe_13_uncaught|Exception: Object does not respond to 'boom'|==== 13 观察 之后 ====
observe_15_relpath|判 3：两次的 launchPath 都是绝对路径 = true|
"
run_observations() {
    local ch="${CHANNELS[${#CHANNELS[@]}-1]}"
    local bin; bin=$(bin_for "$ch")
    local spec oname want must_not dir pfx
    while IFS='|' read -r oname want must_not; do
        [ -n "${oname:-}" ] || continue
        dir=$(find "$EXAMPLES_DIR" -name "$oname.io" -print 2>/dev/null | head -1)
        [ -n "$dir" ] || { bad "observe $oname" "找不到观察脚本"; continue; }
        pfx="$BUILD_DIR/$oname"
        IO_BIN="$bin" IO_CHANNEL="$ch" with_limit "$bin" "$dir" >"$pfx.out" 2>"$pfx.err"
        echo $? > "$pfx.exit"
        num=$(basename "$(dirname "$dir")"); num=${num%%_*}
        local why=() rc
        rc=$(cat "$pfx.exit")
        [ "$rc" = 0 ] || why+=("退出码 $rc")
        [ ! -s "$pfx.err" ] || why+=("stderr 非空")
        marker_present "$pfx.out" "==== $num 观察 开始 ====" || why+=("缺观察开始标记")
        marker_present "$pfx.out" "==== $num 观察 结束 ====" || why+=("缺观察结束标记")
        grep -qF "$want" "$pfx.out" || why+=("未见预期痕迹：$want")
        if [ -n "$must_not" ] && grep -qF "$must_not" "$pfx.out"; then
            why+=("出现了必须缺席的：$must_not")
        fi
        if [ ${#why[@]} -eq 0 ]; then ok "observe $oname"; else
            bad "observe $oname" "$(printf '%s；' "${why[@]}")"
            sed 's/^/          /' "$pfx.out" | head -8
        fi
    done <<< "$OBSERVATIONS"
}

echo
echo "==== 观察文件（不参与逐字节比对）===="
run_observations

echo
echo "---------------------------------------------"
if [ "$RERUN" -eq 1 ]; then
    echo "通过 $PASS   失败 $FAIL   （示例 $TOTAL_EXAMPLES 个，通道 ${#CHANNELS[@]} 条）"
else
    echo "通过 $PASS   失败 $FAIL   （示例 $TOTAL_EXAMPLES 个，通道 ${#CHANNELS[@]} 条，未跑重跑稳定）"
fi
if [ "$FAIL" -eq 0 ]; then
    echo "全部通过"
    exit 0
else
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
    exit 1
fi
