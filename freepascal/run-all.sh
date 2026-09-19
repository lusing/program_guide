#!/usr/bin/env bash
# FreePascal/Lazarus 教程验证入口（Git Bash），与 build.ps1 等价：
#   CLI 示例双通道（check: -Cr -Co -Ci -Sa -B / release: -O2）× 四条判定 + SHA256 对比
#   GUI 示例 lazbuild + --selftest 日志四条判定
# 用法：
#   ./run-all.sh            全部示例
#   ./run-all.sh 02 08      只跑指定编号/名称
#   ./run-all.sh --gui      只跑 GUI 工程
#   ./run-all.sh -v         附带每个示例的完整输出
#   ./run-all.sh --clean    清理产物
set -u

cd "$(dirname "$0")"
ROOT=$(pwd)
EXAMPLES=$ROOT/examples
BUILD=$ROOT/build

on_windows() { [ -n "${OSTYPE:-}" ] && [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; }

# 控制台切 65001：FPC 文本输出跟随活动控制台代码页（build.ps1 同款纪律）
if on_windows && command -v chcp.com >/dev/null 2>&1; then
    chcp.com 65001 >/dev/null 2>&1 || true
fi

resolve_tool() { # $1=env名 $2=命令名 其余=固定路径；固定路径优先于 PATH（scoop 的 fpc shim 是 i386）
    local envname=$1 cmd=$2 p
    local fromenv
    fromenv=$(printenv "$envname" 2>/dev/null || true)
    [ -n "$fromenv" ] && [ -e "$fromenv" ] && { echo "$fromenv"; return; }
    shift 2
    for p in "$@"; do [ -e "$p" ] && { echo "$p"; return; }; done
    command -v "$cmd" >/dev/null 2>&1 && { command -v "$cmd"; return; }
    echo ''
}

# 原生 Windows 工具（fpc/lazbuild）需要 Windows 路径；Git Bash 下用 cygpath -m 转成 G:/... 形式
topath() {
    if on_windows && command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi
}

FPC=$(resolve_tool FPC fpc \
    'G:\scoop\apps\lazarus\current\fpc\3.2.2\bin\x86_64-win64\fpc.exe' \
    'G:/scoop/apps/lazarus/current/fpc/3.2.2/bin/x86_64-win64/fpc.exe' \
    '/usr/bin/fpc' '/usr/local/bin/fpc' '/opt/local/bin/fpc')
LAZBUILD=$(resolve_tool LAZBUILD lazbuild \
    'G:\scoop\apps\lazarus\current\lazbuild.exe' \
    'G:/scoop/apps/lazarus/current/lazbuild.exe' \
    '/usr/bin/lazbuild' '/usr/local/bin/lazbuild' '/opt/local/bin/lazbuild')

EXEEXT=''
on_windows && EXEEXT='.exe'

PASS=0; FAIL=0; DIFFWARN=0; FAILED=""
VERBOSE=0

die() { echo "错误：$*" >&2; exit 2; }

# 控制字符检测（TAB/LF/CR 之外的 0x00-0x1F）。
# 不用 grep -P：Git Bash 下与 LC_ALL 组合会报 locale 错并以非零退出，判定被静默跳过。
has_ctrl() { od -An -v -tx1 "$1" | tr ' ' '\n' | grep -qE '^(00|01|02|03|04|05|06|07|08|0b|0c|0e|0f|1[0-9a-f])$'; }

[ -n "$FPC" ] || die "未找到 fpc（可设 FPC=/path/to/fpc）"
[ -d "$EXAMPLES" ] || die "找不到 examples 目录"

# 四条判定：$1=tag $2=out $3=err $4=marker
check4() {
    local tag=$1 out=$2 err=$3 marker=$4 why=""
    [ -s "$err" ] && why="stderr 非空"
    if [ -s "$out" ]; then
        if has_ctrl "$out"; then
            [ -n "$why" ] && why="$why；"
            why="${why}输出含控制字符"
        fi
        grep -qF "$marker" "$out" || why="${why:+$why；}缺结束标记 $marker"
    else
        why="${why:+$why；}stdout 为空"
    fi
    if [ -n "$why" ]; then
        FAIL=$((FAIL+1)); FAILED="$FAILED
  - $tag（$why）"
        echo "  [FAIL] $tag —— $why" >&2
        [ -s "$err" ] && head -5 "$err" | sed 's/^/        stderr: /' >&2
    else
        PASS=$((PASS+1))
        echo '  [OK] '"$tag"
        [ "$VERBOSE" = 1 ] && sed 's/^/      | /' "$out"
    fi
}

run_cli() { # $1=示例目录
    local dir=$1 name num marker src channel flags out exe rc
    name=$(basename "$dir")
    num=${name%%[-_]*}
    marker="==== $num 结束 ===="
    src=$dir/$name.pas
    [ -f "$src" ] || { die "$src 不存在"; }

    for channel in check release; do
        case $channel in
            check)   flags='-MObjFPC -Cr -Co -Ci -Sa -B' ;;
            release) flags='-MObjFPC -O2' ;;
        esac
        local outdir=$BUILD/$channel
        mkdir -p "$outdir"
        exe=$outdir/$name$EXEEXT
        rm -f "$exe"
        echo "[Compile] $channel $name"
        # MSYS2_ARG_CONV_EXCL='*'：关闭 Git Bash 对参数的 POSIX→Windows 自动转换——
        # 路径已由 topath 转好；放任它转会把 -FEG:/... 内嵌的 /code/... 转成
        # G:\Program Files\Git\code\...（实测坑）
        # shellcheck disable=SC2086
        MSYS2_ARG_CONV_EXCL='*' "$FPC" $flags "-FE$(topath "$outdir")" "-FU$(topath "$outdir")" \
            "-Fu$(topath "$dir")" "-o$(topath "$exe")" "$(topath "$src")" \
            >"$outdir/$name.build.log" 2>"$outdir/$name.build.err"
        rc=$?
        if [ $rc -ne 0 ] || [ ! -f "$exe" ]; then
            echo "编译失败（exit $rc），见 $outdir/$name.build.log" >&2
            tail -8 "$outdir/$name.build.log" | sed 's/^/        /' >&2
            FAIL=$((FAIL+1)); FAILED="$FAILED
  - $channel $name（编译失败）"
            continue
        fi
        echo "[Run] $channel $name"
        ( cd "$outdir" && "./$name$EXEEXT" >"$outdir/$name.out" 2>"$outdir/$name.err" )
        check4 "$channel $name" "$outdir/$name.out" "$outdir/$name.err" "$marker"
    done

    local a=$BUILD/check/$name.out b=$BUILD/release/$name.out
    if [ -s "$a" ] && [ -s "$b" ]; then
        if cmp -s "$a" "$b"; then
            echo '  [same] 双通道输出逐字节一致'
        else
            DIFFWARN=$((DIFFWARN+1))
            echo "  [DIFF] 双通道输出不一致（见 build/{check,release}/$name.out）"
            diff "$a" "$b" | head -10 | sed 's/^/        /'
        fi
    fi
}

run_gui() { # $1=示例目录
    local dir=$1 name num marker lpi exe selflog rc
    name=$(basename "$dir")
    num=${name%%[-_]*}
    marker="==== $num selftest OK ===="
    lpi=$(ls "$dir"/*.lpi 2>/dev/null | head -1)
    [ -n "$lpi" ] || { die "$dir 里没有 .lpi"; }
    if [ -z "$LAZBUILD" ]; then
        echo '  [SKIP] lazbuild 未安装（可设 LAZBUILD=/path/to/lazbuild）'
        return
    fi

    mkdir -p "$BUILD"
    echo "[lazbuild] $name"
    MSYS2_ARG_CONV_EXCL='*' "$LAZBUILD" "$(topath "$lpi")" \
        >"$BUILD/$name.build.log" 2>"$BUILD/$name.build.err"
    rc=$?
    exe=$(ls "$dir"/lib/*/"$name$EXEEXT" 2>/dev/null | head -1)
    if [ $rc -ne 0 ] || [ -z "$exe" ]; then
        echo "  [FAIL] lazbuild $name（exit $rc）" >&2
        tail -8 "$BUILD/$name.build.log" | sed 's/^/        /' >&2
        FAIL=$((FAIL+1)); FAILED="$FAILED
  - lazbuild $name"
        return
    fi
    echo "  [OK] lazbuild $name"
    PASS=$((PASS+1))

    echo "[selftest] $name"
    rm -f "$dir/selftest.log"
    ( cd "$dir" && "./lib/"*"/$name$EXEEXT" --selftest \
        >"$BUILD/$name.selftest.out" 2>"$BUILD/$name.selftest.err" )
    rc=$?
    # 四条判定的对象是 selftest.log；退出码并入判定
    local why=""
    [ $rc -ne 0 ] && why="退出码 $rc"
    if [ -s "$dir/selftest.log" ]; then
        if has_ctrl "$dir/selftest.log"; then
            [ -n "$why" ] && why="$why；"
            why="${why}日志含控制字符"
        fi
        grep -qF "$marker" "$dir/selftest.log" || why="${why:+$why；}缺标记 $marker"
    else
        why="${why:+$why；}selftest.log 为空或缺失"
    fi
    [ -s "$BUILD/$name.selftest.err" ] && why="${why:+$why；}stderr 非空"
    if [ -n "$why" ]; then
        FAIL=$((FAIL+1)); FAILED="$FAILED
  - selftest $name（$why）"
        echo "  [FAIL] selftest $name —— $why" >&2
    else
        PASS=$((PASS+1))
        echo '  [OK] selftest '"$name"
        [ "$VERBOSE" = 1 ] && sed 's/^/      | /' "$dir/selftest.log"
    fi
}

is_cli() { [ -f "$1/$(basename "$1").pas" ]; }
is_gui() { ls "$1"/*.lpi >/dev/null 2>&1; }

run_dir() {
    if is_cli "$1"; then
        echo "==== $(basename "$1") ===="
        run_cli "$1"
    elif is_gui "$1"; then
        run_gui "$1"
    else
        die "$(basename "$1") 既非 CLI 也非 GUI 示例"
    fi
}

find_dir() { # $1=编号或名称
    local want=$1 d
    [ -d "$EXAMPLES/$want" ] && { echo "$EXAMPLES/$want"; return; }
    for d in "$EXAMPLES"/*/; do
        d=${d%/}
        case "$(basename "$d")" in
            "$want"|"$want"_*|"$want"-*) echo "$d"; return ;;
        esac
    done
    return 1
}

summary() {
    echo
    echo "通过 $PASS   失败 $FAIL   输出差异 $DIFFWARN"
    if [ "$FAIL" -eq 0 ]; then
        echo '[Done] 全部验证通过。'
        [ "$DIFFWARN" -gt 0 ] && echo "（有 $DIFFWARN 项双通道输出不同，请人工确认）"
        exit 0
    fi
    echo "失败项：$FAILED" >&2
    exit 1
}

ARGS=()
MODE=all
for arg in "$@"; do
    case $arg in
        --clean)
            rm -rf "$BUILD"
            for d in "$EXAMPLES"/*/; do
                rm -f "${d}selftest.log"; rm -rf "${d}lib"
            done
            echo '[Clean] 已清理 build/、examples/*/selftest.log、examples/*/lib/'
            exit 0 ;;
        --gui) MODE=gui ;;
        -v)    VERBOSE=1 ;;
        *)     MODE=pick; ARGS+=("$arg") ;;
    esac
done

echo "工具链：fpc=$FPC"
echo "       lazbuild=${LAZBUILD:-<未找到>}"
echo

if [ "$MODE" = gui ]; then
    for d in "$EXAMPLES"/*/; do is_gui "${d%/}" && run_gui "${d%/}"; done
    summary
elif [ "$MODE" = pick ]; then
    for a in "${ARGS[@]}"; do
        d=$(find_dir "$a") || die "找不到示例: $a"
        run_dir "$d"
    done
    summary
else
    for d in "$EXAMPLES"/*/; do
        d=${d%/}
        case "$(basename "$d")" in [0-9]*) run_dir "$d" ;; esac
    done
    summary
fi
