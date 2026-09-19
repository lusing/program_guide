#!/usr/bin/env bash
# GNU COBOL 教程验证入口（macOS / Linux / Git Bash），与 build.ps1 等价：
#   每个示例双通道（check: -Wall / release: -O2）× 四条判定 + 输出逐字节比对
#   四条判定：退出码 0 / stderr 空 / stdout 无控制字符 / 含结束标记 ==== NN 结束 ====
# 用法：
#   ./run-all.sh            全部示例
#   ./run-all.sh 02 08      只跑指定编号/名称
#   ./run-all.sh -v         附带每个示例的完整输出
#   ./run-all.sh --clean    清理 build/ 产物
set -u

cd "$(dirname "$0")"
ROOT=$(pwd)
EXAMPLES=$ROOT/examples
BUILD=$ROOT/build

# ── 统一切到 UTF-8 locale ──
# macOS/Linux 上若 locale 为 C（LANG=""），bash 会把紧邻全角标点的 $var 误分词
# （例如 "$why；" 里把 $why 连后面的多字节一起当变量名），导致 set -u 报“未绑定变量”。
# 同时 UTF-8 locale 让中文 I/O 判定更稳。挑一个系统里存在的 UTF-8 locale 即可。
case "$(uname -s)" in
    Darwin|Linux)
        for loc in C.UTF-8 en_US.UTF-8 zh_CN.UTF-8; do
            if locale -a 2>/dev/null | grep -qix "$loc"; then
                export LC_ALL="$loc" LANG="$loc"; break
            fi
        done ;;
esac

on_windows() { [ -n "${OSTYPE:-}" ] && [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; }

# ── 工具链解析：环境变量 COBC → 固定路径 → PATH（固定路径优先，见 README 坑位）──
resolve_cobc() {
    local fromenv p
    fromenv=$(printenv COBC 2>/dev/null || true)
    [ -n "$fromenv" ] && [ -x "$fromenv" ] && { echo "$fromenv"; return; }
    for p in /opt/local/bin/cobc /usr/local/bin/cobc /usr/bin/cobc; do
        [ -x "$p" ] && { echo "$p"; return; }
    done
    command -v cobc >/dev/null 2>&1 && { command -v cobc; return; }
    echo ''
}
COBC=$(resolve_cobc)
die() { echo "错误：$*" >&2; exit 2; }
[ -n "$COBC" ] || die "未找到 cobc（可设 COBC=/path/to/cobc）"
[ -d "$EXAMPLES" ] || die "找不到 examples 目录"

EXEEXT=''
on_windows && EXEEXT='.exe'

# ── macOS/clang 专属：UTF-8 中文字面量会让 clang 喷 -Winvalid-source-encoding 警告 ──
# 警告走 stderr，会破坏“stderr 必须为空”的判定（程序其实运行正确，纯告警）。
# 对策：把该告警关掉，并保留 cobc 默认的头文件搜索路径（CPPFLAGS 里的 -I…），
# 否则覆盖 COB_CFLAGS 会丢掉 gmp.h 等 include。Linux/gcc 无此告警，分支不触发。
COB_VER=$("$COBC" --version 2>/dev/null | head -1)
export COB_CFLAGS=""
if "$COBC" -x -o /dev/null /dev/null 2>/dev/null; then :; fi   # noop，仅占位
case "$(uname -s)" in
    Darwin)
        # 从 cobc --info 抓默认 CPPFLAGS（含 -I…/include，gmp.h 等所在），再追加抑制开关
        DEF_CPP=$("$COBC" --info 2>/dev/null | awk -F': ' '/^CPPFLAGS/{print $2; exit}')
        export COB_CFLAGS="-pipe ${DEF_CPP} -Wno-invalid-source-encoding"
        ;;
esac

PASS=0; FAIL=0; DIFFWARN=0; FAILED=""
VERBOSE=0

# 控制字符检测（TAB/LF/CR 之外的 0x00-0x1F）。
has_ctrl() { od -An -v -tx1 "$1" | tr ' ' '\n' | grep -qE '^(00|01|02|03|04|05|06|07|08|0b|0c|0e|0f|1[0-9a-f])$'; }

# 四条判定：$1=tag $2=out $3=err $4=marker $5=运行退出码
check4() {
    local tag=$1 out=$2 err=$3 marker=$4 runrc=$5 why=""
    [ "$runrc" != "0" ] && why="运行退出码 ${runrc}（断言未过）"
    [ -s "$err" ] && { [ -n "$why" ] && why="${why}；"; why="${why}stderr 非空"; }
    if [ -s "$out" ]; then
        if has_ctrl "$out"; then
            [ -n "$why" ] && why="${why}；"
            why="${why}输出含控制字符"
        fi
        grep -qF "$marker" "$out" || why="${why:+${why}；}缺结束标记 ${marker}"
    else
        why="${why:+${why}；}stdout 为空"
    fi
    if [ -n "$why" ]; then
        FAIL=$((FAIL+1)); FAILED="$FAILED
  - ${tag}（${why}）"
        echo "  [FAIL] $tag —— $why" >&2
        [ -s "$err" ] && head -5 "$err" | sed 's/^/        stderr: /' >&2
    else
        PASS=$((PASS+1))
        echo '  [OK] '"$tag"
        [ "$VERBOSE" = 1 ] && sed 's/^/      | /' "$out"
    fi
}

run_cli() { # $1=示例目录
    local dir=$1 name num marker channel flags out exe rc runrc
    name=$(basename "$dir")
    num=${name%%[-_]*}
    marker="==== $num 结束 ===="
    # 入口源文件 = 与目录同名的 .cob；其余兄弟 .cob（子程序）与 .c（C 互操作）一并交给 cobc
    local entry=$dir/$name.cob
    [ -f "$entry" ] || { die "$entry 不存在"; }
    local srcs=("$entry")
    local s
    for s in "$dir"/*.cob; do
        [ "$s" = "$entry" ] && continue
        srcs+=("$s")
    done
    for s in "$dir"/*.c; do
        [ -e "$s" ] || continue
        srcs+=("$s")
    done

    for channel in check release; do
        case $channel in
            check)   flags='-x -Wall -std=default' ;;
            release) flags='-x -O2' ;;
        esac
        local outdir=$BUILD/$channel
        mkdir -p "$outdir"
        exe=$outdir/$name$EXEEXT
        rm -f "$exe"
        echo "[Compile] $channel $name"
        # -I "$dir"：让 COPY 能找到与源文件同目录的 copybook（cobc 默认不搜源文件目录）
        # shellcheck disable=SC2086
        MSYS2_ARG_CONV_EXCL='*' "$COBC" $flags -I "$dir" -o "$exe" "${srcs[@]}" \
            >"$outdir/$name.build.log" 2>"$outdir/$name.build.err"
        rc=$?
        if [ $rc -ne 0 ] || [ ! -f "$exe" ]; then
            echo "编译失败 [exit ${rc}]，见 ${outdir}/${name}.build.log" >&2
            tail -10 "$outdir/$name.build.log" "$outdir/$name.build.err" | sed 's/^/        /' >&2
            FAIL=$((FAIL+1)); FAILED="$FAILED
  - $channel ${name}（编译失败）"
            continue
        fi
        # 编译期告警也算 stderr 非空（check 通道开 -Wall，零告警是纪律）
        # 在 outdir 里运行：文件类示例的相对路径数据文件落在 build/，--clean 一并清掉，
        # 不污染 examples/（否则 rel.dat/idx.dat/seqdemo.txt 会散在源码目录）
        echo "[Run] $channel $name"
        ( cd "$outdir" && "./$name$EXEEXT" >"$outdir/$name.out" 2>"$outdir/$name.err" )
        runrc=$?
        # 把编译告警并进运行 stderr 一起判（任一非空即 FAIL）
        cat "$outdir/$name.build.err" >> "$outdir/$name.err"
        check4 "$channel $name" "$outdir/$name.out" "$outdir/$name.err" "$marker" "$runrc"
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

run_dir() { echo "==== $(basename "$1") ===="; run_cli "$1"; }

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
        --clean) rm -rf "$BUILD"; echo '[Clean] 已清理 build/'; exit 0 ;;
        -v)      VERBOSE=1 ;;
        *)       MODE=pick; ARGS+=("$arg") ;;
    esac
done

echo "工具链：cobc=$COBC"
echo "版本：  $COB_VER"
[ -n "$COB_CFLAGS" ] && echo "COB_CFLAGS=$COB_CFLAGS"
echo

if [ "$MODE" = pick ]; then
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
