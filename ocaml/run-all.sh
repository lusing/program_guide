#!/usr/bin/env bash
# ============================================================
# run-all.sh —— OCaml 示例全量验证（shell 版，等价于 build.ps1）
#
#   ./run-all.sh              字节码 + 原生两个通道（默认）
#   ./run-all.sh --interp     追加顶层解释器通道（ocaml X.ml；26 是多文件，跳过）
#   ./run-all.sh --byte       只跑字节码通道
#   ./run-all.sh --no-run     只编译不运行（只判「编译退出码 0 + 零告警」两条）
#   ./run-all.sh -v           附每个示例的完整输出
#   ./run-all.sh 01 07        只跑指定编号
#
# 通道：
#   byte   : ocamlc   → 字节码可执行文件（由 ocamlrun 执行）
#   native : ocamlopt → 原生可执行文件
#   interp : ocaml X.ml（顶层解释器，可选）
#
# 判定标准（与 build.ps1 逐条一致）：
#   1. 编译退出码为 0
#   2. 编译日志为空 —— 零告警；示例代码必须 warning-free
#   3. 运行退出码为 0
#   4. 运行 stderr 为空
#   5. stdout 非空，且无多余控制字符（TAB/LF/CR 除外）
#   6. stdout 含结束标记 "==== NN jieshu ===="
#
# macOS 注意：用到 Unix 模块的示例必须显式写 -I +unix，
# 否则编译器会吐 Alert ocaml_deprecated_auto_include（OCaml 5 起）。
# ============================================================

set -u
cd "$(dirname "$0")"

VERBOSE=0
WANT_BYTE=1
WANT_NATIVE=1
WANT_INTERP=0
NORUN=0
SELECT=()

for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        --byte)       WANT_NATIVE=0 ;;
        --no-run)     NORUN=1 ;;
        --interp)     WANT_INTERP=1 ;;
        *)            SELECT+=("$arg") ;;
    esac
done

# ----------------------------------------------------------------------
# 工具链发现：环境变量 → PATH → 常见安装目录（MacPorts / Homebrew / 系统）
# ----------------------------------------------------------------------
find_tool() {
    local name="$1" p
    if command -v "$name" >/dev/null 2>&1; then command -v "$name"; return 0; fi
    for p in /opt/local/bin /opt/homebrew/bin /usr/local/bin /usr/bin; do
        [ -x "$p/$name" ] && { printf '%s' "$p/$name"; return 0; }
    done
    printf ''
}

OCAMLC="${OCAMLC:-$(find_tool ocamlc)}"
if [ -z "$OCAMLC" ]; then
    echo "未找到 ocamlc。请把 OCaml 的 bin 目录加入 PATH，或设置 OCAMLC=/path/to/ocamlc"
    exit 1
fi
TOOLDIR=$(dirname "$OCAMLC")
OCAMLOPT="${OCAMLOPT:-$TOOLDIR/ocamlopt}"
OCAML="${OCAML:-$TOOLDIR/ocaml}"
OCAMLLEX="${OCAMLLEX:-$TOOLDIR/ocamllex}"

[ -x "$OCAMLOPT" ] || { echo "未找到 ocamlopt：$OCAMLOPT"; exit 1; }
[ -x "$OCAMLLEX" ] || { echo "未找到 ocamllex：$OCAMLLEX"; exit 1; }

STDLIB_DIR="$("$OCAMLC" -where)"
UNIX_DIR="$STDLIB_DIR/unix"
if [ ! -f "$UNIX_DIR/unix.cma" ]; then
    echo "未找到 unix 库：$UNIX_DIR/unix.cma"
    exit 1
fi

EXAMPLES_DIR="$PWD/examples"
LEX_DIR="$EXAMPLES_DIR/26_ocamllex"
BUILD_DIR="$PWD/build"
mkdir -p "$BUILD_DIR"

# 依赖 Unix 模块的示例
UNIX_EXAMPLES="15_algorithms 18_io 21_streams_seq 22_project 25_domains_effects"

needs_unix() {
    case " $UNIX_EXAMPLES " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

echo "[Info] ocamlc:   $OCAMLC"
echo "[Info] ocamlopt: $OCAMLOPT"
echo "[Info] stdlib:   $STDLIB_DIR"

PASS=0
FAIL=0
FAILED_LIST=()

# ----------------------------------------------------------------------
# 判定函数（只依赖退出码 / 文件是否为空，不依赖被捕获的文本）
# ----------------------------------------------------------------------
has_ctrl() {   # 0..31 里除 TAB(9)/LF(10)/CR(13) 之外还有别的控制字符 → 0
    LC_ALL=C tr -d '\011\012\015' < "$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

has_marker() {
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null | LC_ALL=C grep -qF "$2"
}

# check <标签> <结束标记> <stdout文件> <stderr文件> <退出码> <编译日志|"-">
check() {
    local tag="$1" marker="$2" out="$3" err="$4" rc="$5" log="$6"
    local why=()
    [ "$rc" -eq 0 ] || why+=("退出码 $rc")
    if [ "$log" != "-" ] && [ -s "$log" ]; then why+=("编译有告警（日志非空）"); fi
    if [ "$NORUN" -eq 0 ]; then
        [ -s "$err" ] && why+=("stderr 非空")
        [ -s "$out" ] || why+=("stdout 为空")
        has_ctrl "$out" && why+=("stdout 含控制字符")
        has_marker "$out" "$marker" || why+=("缺结束标记 [$marker]")
    fi

    if [ ${#why[@]} -eq 0 ]; then
        PASS=$((PASS + 1))
        printf "  [%s] %s\n" "OK" "$tag"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$tag")
        # 原因一律用数组拼接（printf + 去掉末尾分隔符）：
        # 写 "${msg:+$msg；}..." 时 bash 会把全角分号的首字节吞进变量名，
        # 在 set -u 下报 "msg?: unbound variable"，而且只在真失败时才炸。
        local IFS='；'      # 用 IFS 拼接：${why[*]} 不会留下末尾分隔符
        local msg="${why[*]}"
        printf "  [%s] %s —— %s\n" "FAIL" "$tag" "$msg"
        if [ "$log" != "-" ] && [ -s "$log" ]; then
            sed 's/^/        compile: /' "$log" | head -8
        fi
        [ -s "$err" ] && sed 's/^/        stderr: /' "$err" | head -5
        if ! has_marker "$out" "$marker"; then
            echo "        stdout 末尾 5 行："
            tail -5 "$out" | sed 's/^/        /'
        fi
    fi

    if [ "$VERBOSE" -eq 1 ]; then sed 's/^/        | /' "$out" | head -40; fi
}

# 把源文件内容复制一份到 build/ 再编译：ocamlc/ocamlopt 总是把 .cmi/.cmo/.cmx/.o
# 放在**源文件旁边**，直接编译 examples/NN.ml 会在源码目录里掉一堆中间产物。
# 复制到 build/ 之后产物天然落在 build/ 里，脚本也就不需要 rm 任何东西。
copy_source() {   # $1=源绝对路径  $2=build 里的文件名
    cp "$1" "$BUILD_DIR/$2"
}

# ----------------------------------------------------------------------
# 单个示例的一个通道：$1=源文件绝对路径  $2=base 名  $3=通道(byte|native|interp)
# ----------------------------------------------------------------------
run_channel() {
    local src="$1" base="$2" chan="$3"
    local num="${base%%_*}"
    local marker="==== $num jieshu ===="
    local tag="$chan $base"
    local out="$BUILD_DIR/$base.$chan.out"
    local err="$BUILD_DIR/$base.$chan.err"
    local log="$BUILD_DIR/$base.$chan.compile"
    local rc=0

    : > "$out"; : > "$err"; : > "$log"

    if [ "$chan" = "interp" ]; then
        local iargs=(-w -24)
        needs_unix "$base" && iargs+=(-I +unix unix.cma)
        # 解释器直接在源码路径上跑（不编译，不会产生中间产物）
        ( cd "$BUILD_DIR" && "$OCAML" "${iargs[@]}" "$src" ) >"$out" 2>"$err"
        rc=$?
        check "$tag" "$marker" "$out" "$err" "$rc" "-"
        return
    fi

    local compiler lib bin
    if [ "$chan" = "native" ]; then
        compiler="$OCAMLOPT"; lib="unix.cmxa"; bin="$BUILD_DIR/${base}_opt"
    else
        compiler="$OCAMLC";   lib="unix.cma";  bin="$BUILD_DIR/$base"
    fi

    copy_source "$src" "$base.ml"
    local cargs=(-w -24)
    needs_unix "$base" && cargs+=(-I +unix "$lib")
    cargs+=(-o "$(basename "$bin")" "$base.ml")

    ( cd "$BUILD_DIR" && "$compiler" "${cargs[@]}" ) >"$log" 2>&1
    rc=$?
    if [ "$rc" -ne 0 ] || [ -s "$log" ] || [ "$NORUN" -eq 1 ]; then
        check "$tag" "$marker" "$out" "$err" "$rc" "$log"
        return
    fi

    ( cd "$BUILD_DIR" && "./$(basename "$bin")" ) >"$out" 2>"$err"
    rc=$?
    check "$tag" "$marker" "$out" "$err" "$rc" "$log"
}

# ----------------------------------------------------------------------
# 26_ocamllex：ocamllex 生成 .ml，再与 main.ml 一起编译（byte + native）
# ----------------------------------------------------------------------
run_lex() {
    local base="26_ocamllex"
    local marker="==== 26 jieshu ===="
    local gen="$BUILD_DIR/ocamllex_expr.ml"
    cp "$LEX_DIR/main.ml" "$BUILD_DIR/ocamllex_main.ml"
    local main="$BUILD_DIR/ocamllex_main.ml"
    local genlog="$BUILD_DIR/$base.lex.generate"

    : > "$genlog"
    ( cd "$BUILD_DIR" && "$OCAMLLEX" -q -o "$gen" "$LEX_DIR/ocamllex_expr.mll" ) >"$genlog" 2>&1
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        FAIL=$((FAIL + 1)); FAILED_LIST+=("ocamllex $base")
        printf "  [%s] %s —— ocamllex 退出码 %s\n" "FAIL" "ocamllex $base" "$rc"
        sed 's/^/        /' "$genlog" | head -5
        return
    fi

    local chan
    for chan in byte native; do
        [ "$chan" = "native" ] && [ "$WANT_NATIVE" -eq 0 ] && continue
        local compiler lib bin
        if [ "$chan" = "native" ]; then
            compiler="$OCAMLOPT"; lib="unix.cmxa"; bin="$BUILD_DIR/${base}_opt"
        else
            compiler="$OCAMLC";   lib="unix.cma";  bin="$BUILD_DIR/$base"
        fi
        local tag="$chan $base"
        local out="$BUILD_DIR/$base.$chan.out"
        local err="$BUILD_DIR/$base.$chan.err"
        local log="$BUILD_DIR/$base.$chan.compile"
        : > "$out"; : > "$err"; : > "$log"

        ( cd "$BUILD_DIR" && "$compiler" -w -24 -I +unix "$lib" \
            -o "$(basename "$bin")" "$(basename "$gen")" "$(basename "$main")" ) >"$log" 2>&1
        rc=$?
        if [ "$rc" -ne 0 ] || [ -s "$log" ] || [ "$NORUN" -eq 1 ]; then
            check "$tag" "$marker" "$out" "$err" "$rc" "$log"
            continue
        fi
        ( cd "$BUILD_DIR" && "./$(basename "$bin")" ) >"$out" 2>"$err"
        rc=$?
        check "$tag" "$marker" "$out" "$err" "$rc" "$log"
    done
}

# ----------------------------------------------------------------------
# 主循环
# ----------------------------------------------------------------------
for f in "$EXAMPLES_DIR"/[0-9][0-9]_*.ml; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .ml)
    num="${base%%_*}"

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
        [ "$hit" -eq 1 ] || continue
    fi

    echo "==== $base ===="
    run_channel "$f" "$base" byte
    [ "$WANT_NATIVE" -eq 1 ] && run_channel "$f" "$base" native
    [ "$WANT_INTERP" -eq 1 ] && run_channel "$f" "$base" interp
done

if [ ${#SELECT[@]} -eq 0 ] || printf '%s\n' "${SELECT[@]}" | grep -qx "26"; then
    if [ -d "$LEX_DIR" ]; then
        echo "==== 26_ocamllex ===="
        run_lex
    fi
fi

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
