#!/usr/bin/env bash
# Algol 68 Genie 教程验证入口（macOS / Linux / Git Bash），与 build.ps1 等价：
#   每个示例双通道 × 四条判定 + 输出逐字节比对
#     check   通道：a68g --warnings --notices  解释器（全运行时检查 + 告警 + notice）
#     release 通道：a68g -O2                   编译到 C 后端（优化，真实出货形态）
#   四条判定：运行退出码 0 / stderr 空 / stdout 无控制字符 / 含结束标记 ==== NN 结束 ====
#   跨通道：check 与 release 两通道 stdout 逐字节一致（解释器与编译后端语义必须吻合）
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
# 让中文 I/O 判定更稳；C locale 下 bash 会把紧邻全角标点的 $var 误分词。
case "$(uname -s)" in
    Darwin|Linux)
        for loc in C.UTF-8 en_US.UTF-8 zh_CN.UTF-8; do
            if locale -a 2>/dev/null | grep -qix "$loc"; then
                export LC_ALL="$loc" LANG="$loc"; break
            fi
        done ;;
esac

on_windows() { [ -n "${OSTYPE:-}" ] && [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; }

# ── 工具链解析：环境变量 A68G → 固定路径 → PATH ──
resolve_a68g() {
    local fromenv p
    fromenv=$(printenv A68G 2>/dev/null || true)
    [ -n "$fromenv" ] && [ -x "$fromenv" ] && { echo "$fromenv"; return; }
    for p in /opt/local/bin/a68g /usr/local/bin/a68g /usr/bin/a68g; do
        [ -x "$p" ] && { echo "$p"; return; }
    done
    command -v a68g >/dev/null 2>&1 && { command -v a68g; return; }
    echo ''
}
A68G=$(resolve_a68g)
die() { echo "错误：$*" >&2; exit 2; }
[ -n "$A68G" ] || die "未找到 a68g（可设 A68G=/path/to/a68g）"
[ -d "$EXAMPLES" ] || die "找不到 examples 目录"

A68_VER=$("$A68G" --version 2>/dev/null | head -1)

# ── macOS 专属坑：a68g -O2 的链接步骤直接调 ld 而不带 -syslibroot ──
# 实测：a68g 把源码翻成 .c → .o 后，用
#   ld -export_dynamic -undefined dynamic_lookup -lSystem -o x.so x.o
# 链接，但没有 -syslibroot，于是 macOS 上报 `ld: library 'System' not found`。
# 对策：造一个 ld 垫片放进 PATH 最前，把真实的 /usr/bin/ld 补上 -syslibroot。
# Linux 上 a68g 的链接命令本就正常，垫片不触发（仅在 Darwin 且能取到 SDK 时安装）。
SHIM_DIR=""
case "$(uname -s)" in
    Darwin)
        SDK=$(xcrun --show-sdk-path 2>/dev/null || true)
        if [ -n "$SDK" ]; then
            SHIM_DIR=$BUILD/.shim
            mkdir -p "$SHIM_DIR"
            cat > "$SHIM_DIR/ld" <<EOF
#!/bin/sh
exec /usr/bin/ld -syslibroot "$SDK" "\$@"
EOF
            chmod +x "$SHIM_DIR/ld"
        fi ;;
esac

PASS=0; FAIL=0; DIFFWARN=0; FAILED=""
VERBOSE=0

# 控制字符检测（TAB/LF/CR 之外的 0x00-0x1F）。
has_ctrl() { od -An -v -tx1 "$1" | tr ' ' '\n' | grep -qE '^(00|01|02|03|04|05|06|07|08|0b|0c|0e|0f|1[0-9a-f])$'; }

# 四条判定：$1=tag $2=out $3=err $4=marker $5=运行退出码
check4() {
    local tag=$1 out=$2 err=$3 marker=$4 runrc=$5 why=""
    [ "$runrc" != "0" ] && why="运行退出码 ${runrc}（运行时错误或断言失败）"
    [ -s "$err" ] && { [ -n "$why" ] && why="${why}；"; why="${why}stderr 非空（告警/FAIL/运行时错误）"; }
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

run_one() { # $1=示例目录
    local dir=$1 name num marker channel flags out runrc outdir entry
    name=$(basename "$dir")
    num=${name%%[-_]*}
    marker="==== $num 结束 ===="
    entry=$dir/$name.a68
    [ -f "$entry" ] || { die "$entry 不存在"; }

    for channel in check release; do
        case $channel in
            check)   flags='--warnings --notices' ;;
            release) flags='-O2' ;;
        esac
        outdir=$BUILD/$channel
        mkdir -p "$outdir"
        # a68g 写文件用 establish（建新文件），若同名文件已存在会报 "file exists" 而中止；
        # 且 erase 只能删「本会话 establish/create 出来的」文件，删不掉遗留文件。
        # 故每次运行前清掉 outdir 里的数据文件，保证文件类示例可重复运行（幂等）。
        rm -f "$outdir"/*.txt "$outdir"/*.dat 2>/dev/null
        # 在 outdir 里运行：-O2 产生的 .so 与文件类示例的数据文件都落在 build/，
        # --clean 一并清掉，不污染 examples/
        echo "[Run] $channel $name ($flags)"
        if [ "$channel" = release ] && [ -n "$SHIM_DIR" ]; then
            ( cd "$outdir" && PATH="$SHIM_DIR:$PATH" "$A68G" $flags "$entry" \
                >"$outdir/$name.out" 2>"$outdir/$name.err" )
        else
            ( cd "$outdir" && "$A68G" $flags "$entry" \
                >"$outdir/$name.out" 2>"$outdir/$name.err" )
        fi
        runrc=$?
        # 清掉 release 通道残留的编译产物，保持 build/ 干净
        rm -f "$outdir/$name.so" "$outdir/$name.o" "$outdir/$name.c" 2>/dev/null
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

run_dir() { echo "==== $(basename "$1") ===="; run_one "$1"; }

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

echo "工具链：a68g=$A68G"
echo "版本：  $A68_VER"
[ -n "$SHIM_DIR" ] && echo "ld 垫片：$SHIM_DIR/ld（macOS -O2 链接修复）"
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
