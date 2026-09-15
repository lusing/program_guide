#!/usr/bin/env bash
# ============================================================
# run-all.sh —— 用两种语言模式跑遍所有 Free Pascal 示例（shell 版，等价于 build.ps1）
#
#   ./run-all.sh            只打印每条通道的通过/失败摘要
#   ./run-all.sh -v         附带每个示例的完整输出
#   ./run-all.sh 03 07      只跑指定编号
#   ./run-all.sh --gui      只构建 examples/ 下的 3 个 Lazarus 工程
#   ./run-all.sh --clean    清理 build 目录
#
# 两个通道（区别只在语言模式，编译器是同一个）：
#   1. objfpc  —— Free Pascal 的扩展对象模式，教程与 build.ps1 用的就是它
#   2. delphi  —— Delphi 兼容模式，作为对照通道
#   3 个 GUI 工程走 lazbuild（macOS 上默认 cocoa 控件集）。
#
# 判定标准（与 build.ps1 一致）：
#   退出码 0 + stderr 为空 + 输出里没有多余控制字符 + 输出里有 "==== NN 结束 ===="
#   最后一条目前对每个示例降级：本目录的 12 个示例还没有打印结束标记，
#   没有标记时改判「stdout 非空」并单独计数提示；示例补上标记后会自动改回严格匹配。
#
# 顺带记录一个跨模式事实：11_file_io 与 12_classes 在 FPC 默认模式（-MFPC）下
# 编译不过（AssignFile / class 都找不到），objfpc 与 delphi 两种模式才能通过。
# 所以对照通道选 delphi 而不是默认的 fpc。
# ============================================================

set -u
cd "$(dirname "$0")"

VERBOSE=0
GUI_ONLY=0
CLEAN=0
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        --gui)        GUI_ONLY=1 ;;
        --clean)      CLEAN=1 ;;
        *)            SELECT+=("$arg") ;;
    esac
done

# ------------------------------------------------------------
# 工具链定位：环境变量 FPC / LAZBUILD 优先，其次 PATH 上的通用名字，
#             最后退回 macOS(MacPorts / Homebrew) 与 Windows(scoop) 的常见路径
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
    for c in "$@"; do
        case "$c" in
            */*) [ -x "$c" ] && printf '%s' "$c" && return ;;
        esac
    done
    printf ''
}

FPC=$(resolve_tool "${FPC:-}" fpc /opt/local/bin/fpc /usr/local/bin/fpc \
      '/c/scoop/apps/freepascal/current/bin/fpc.exe' \
      '/c/scoop/apps/freepascal/current/bin/i386-win32/fpc.exe')
LAZBUILD=$(resolve_tool "${LAZBUILD:-}" lazbuild /opt/local/bin/lazbuild /usr/local/bin/lazbuild \
           '/c/scoop/apps/lazarus/current/lazbuild.exe')

[ -n "$FPC" ] || { echo "未找到 fpc（可设 FPC=/path/to/fpc）"; exit 1; }

if [ "$CLEAN" -eq 1 ]; then
    rm -rf build
    echo "[Clean] 已清理 build 目录。"
    exit 0
fi

# 控件集不显式指定：lazbuild 会按宿主平台取默认值（Windows → win32，macOS → cocoa，
# Linux → gtk2）。写死 --widgetset 反而会在没装那个控件集的机器上编不过，也和 build.ps1 不一致。
LAZ_WS=''

echo "fpc      : $FPC ($("$FPC" -iV 2>/dev/null))"
echo "lazbuild : ${LAZBUILD:-<缺失>}"
echo

# 已知的跨模式输出差异及其原因（目前两种模式输出逐字节一致，表留空）。
diff_reason() {
    echo ""
}

mkdir -p build
PASS=0
FAIL=0
DIFFWARN=0
NOMARKER=0
FAILED_LIST=()

# 输出里是否混进了「不该出现」的控制字符（制表符、换行、回车除外）。
has_ctrl() {
    [ "$(LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null \
         | LC_ALL=C tr -dc '\0-\10\13-\14\16-\37' | wc -c | tr -d ' ')" != "0" ]
}

# 在输出里找结束标记。先剔掉控制字符再匹配，免得二进制内容干扰 grep。
marker_present() {
    tr -d '\000' < "$1" 2>/dev/null | grep -qF "$2"
}

# 用法：check <标签> <期望结束标记> <输出文件> <stderr文件> <退出码> <编译日志>
check() {
    local tag="$1" marker="$2" out="$3" err="$4" rc="$5" log="$6"
    local ok=1 why=()

    if [ "$rc" -ne 0 ]; then ok=0; why+=("退出码 $rc"); fi
    if [ -s "$err" ];   then ok=0; why+=("stderr 非空"); fi
    if has_ctrl "$out";  then ok=0; why+=("输出含控制字符"); fi
    if marker_present "$out" "$marker"; then
        :
    elif [ -s "$out" ]; then
        NOMARKER=$((NOMARKER + 1))
    else
        ok=0; why+=("stdout 为空")
    fi

    if [ "$ok" -eq 1 ]; then
        PASS=$((PASS + 1))
        printf "  [%s] %s\n" "OK" "$tag"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$tag")
        printf "  [%s] %s —— %s\n" "FAIL" "$tag" "$(printf '%s；' "${why[@]}")"
        if [ -s "$err" ]; then sed 's/^/        stderr: /' "$err" | head -5; fi
        if [ -s "$log" ]; then
            echo "        编译输出："
            tail -8 "$log" | sed 's/^/        /'
        fi
    fi

    if [ "$VERBOSE" -eq 1 ]; then
        tr -d '\000' < "$out" | sed 's/^/        /'
    fi
}

# 编译并运行一个示例：build_and_run <通道名> <语言模式参数> <源文件> <basename>
# 产物全部收进 build/<通道>：fpc 的 -o/-FE/-FU 一律给绝对路径，
# 否则相对路径会按「源文件所在目录」解析，把 .o 和可执行文件落进 examples/。
build_and_run() {
    local channel="$1" mode="$2" src="$3" base="$4"
    local outdir="$PWD/build/$channel"
    mkdir -p "$outdir"

    if ! "$FPC" "$mode" -Sc -O2 \
            "-FE$outdir" "-FU$outdir" "-o$outdir/$base" \
            "$src" >"$outdir/$base.build.log" 2>&1; then
        : >"$outdir/$base.out"
        echo "编译失败，见 build/$channel/$base.build.log" >"$outdir/$base.err"
        return 1
    fi
    # 11_file_io 有相对路径读写，统一在 build/<通道> 下运行
    ( cd "$outdir" && "./$base" >"$base.out" 2>"$base.err" )
    return $?
}

# ------------------------------------------------------------
# 通道 1 / 2：命令行示例
# ------------------------------------------------------------
if [ "$GUI_ONLY" -eq 0 ]; then
    for f in examples/[0-9]*.pas; do
        [ -e "$f" ] || continue
        base=$(basename "$f"); base=${base%.pas}
        num=${base%%[-_]*}

        if [ ${#SELECT[@]} -gt 0 ]; then
            hit=0
            for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
            [ "$hit" -eq 1 ] || continue
        fi

        marker="==== $num 结束 ===="
        echo "==== $base ===="

        build_and_run objfpc -MObjFPC "$f" "$base"; rc=$?
        check "objfpc $base" "$marker" \
              "build/objfpc/$base.out" "build/objfpc/$base.err" "$rc" "build/objfpc/$base.build.log"

        build_and_run delphi -MDelphi "$f" "$base"; rc=$?
        check "delphi $base" "$marker" \
              "build/delphi/$base.out" "build/delphi/$base.err" "$rc" "build/delphi/$base.build.log"

        # ---- 附加检查：两种语言模式的输出应当逐字节一致 ----
        if [ -s "build/objfpc/$base.out" ] && [ -s "build/delphi/$base.out" ]; then
            if cmp -s "build/objfpc/$base.out" "build/delphi/$base.out"; then
                printf "  [same] 两模式输出逐字节一致\n"
            else
                reason=$(diff_reason "$base")
                if [ -n "$reason" ]; then
                    printf "  [diff] 已知差异：%s\n" "$reason"
                else
                    DIFFWARN=$((DIFFWARN + 1))
                    printf "  [DIFF] 两模式输出不一致（意外差异，见 build/*/$base.out）\n"
                    diff "build/objfpc/$base.out" "build/delphi/$base.out" | head -10 | sed 's/^/        /'
                fi
            fi
        fi
    done
fi

# ------------------------------------------------------------
# 通道 3：Lazarus GUI 工程（只验证能被编译）
# ------------------------------------------------------------
GUI_TOTAL=0
if [ "$GUI_ONLY" -eq 1 ] || [ ${#SELECT[@]} -eq 0 ]; then
for proj in 13_lazarus_gui/LazarusGuiDemo.lpi \
            14_lazarus_advanced_controls/AdvancedControlsDemo.lpi \
            15_lazarus_menus_dialogs/LazarusMenusDemo.lpi; do
    [ -e "examples/$proj" ] || continue
    GUI_TOTAL=$((GUI_TOTAL + 1))
    name=$(basename "$proj")
    [ "$GUI_ONLY" -eq 1 ] && echo "==== $name ===="

    if [ -z "$LAZBUILD" ]; then
        FAIL=$((FAIL + 1)); FAILED_LIST+=("lazbuild $name")
        echo "  [SKIP] lazbuild 未安装（可设 LAZBUILD=/path/to/lazbuild）"
        continue
    fi
    if $LAZBUILD $LAZ_WS "examples/$proj" >"build/$name.build.log" 2>&1; then
        PASS=$((PASS + 1))
        printf "  [OK]   lazbuild %s\n" "$name"
    else
        FAIL=$((FAIL + 1)); FAILED_LIST+=("lazbuild $name")
        printf "  [FAIL] lazbuild %s\n" "$name"
        tail -8 "build/$name.build.log" | sed 's/^/        /'
    fi
done
fi

echo
echo "通过 $PASS   失败 $FAIL   输出差异 $DIFFWARN"
if [ "$NOMARKER" -gt 0 ]; then
    echo "提示：$NOMARKER 项没有结束标记，按「stdout 非空」降级判定（示例补上 ==== NN 结束 ==== 后自动收紧）"
fi
if [ "$FAIL" -eq 0 ]; then
    echo "全部通过（命令行示例 × 两模式 + Lazarus 工程 × ${GUI_TOTAL}）"
    [ "$DIFFWARN" -eq 0 ] && exit 0
    echo "（有 $DIFFWARN 项跨模式输出不同，请人工确认是否可接受）"
    exit 0
else
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
    exit 1
fi
