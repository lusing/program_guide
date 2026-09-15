#!/usr/bin/env bash
# ============================================================
# Emacs Lisp 示例批量验证入口
#
#   ./run-all.sh             验证 examples/ 下全部示例
#   ./run-all.sh 07-lists    只验证一个（可给多个）
#   ./run-all.sh -Clean      清理 build 目录
#   ./run-all.sh -Keep       验证但保留 build 里的产物
#
# 判定标准（四条，缺一不可）：
#   1. 退出码为 0
#   2. stderr 为空（字节编译的警告也走 stderr，所以这一条等价于「零警告」）
#   3. stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）
#   4. stdout 里有结束标记 "==== NN 结束 ===="（NN 与文件名前缀一致）
# ============================================================
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
EXAMPLES_DIR="$SCRIPT_DIR/examples"
BUILD_DIR="$SCRIPT_DIR/build"

KEEP=0

resolve_emacs() {
    if [ -n "${EMACS:-}" ]; then printf '%s' "$EMACS"; return; fi
    local c
    for c in /opt/local/bin/emacs /usr/local/bin/emacs \
             /Applications/Emacs.app/Contents/MacOS/Emacs emacs; do
        if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return; fi
    done
    printf ''
}

EMACS_BIN=$(resolve_emacs)
if [ -z "$EMACS_BIN" ]; then
    echo "错误：找不到 emacs 可执行文件。可用 EMACS=/path/to/emacs 指定。" >&2
    exit 1
fi

# 控制字符：0..31 中除 TAB(11)/LF(12)/CR(15) 之外的都要算脏
has_ctrl() {
    local f="$1" n
    n=$(LC_ALL=C tr -d '\11\12\15' < "$f" 2>/dev/null \
        | LC_ALL=C tr -dc '\0-\10\13-\14\16-\37' | wc -c | tr -d ' ')
    [ "$n" != "0" ]
}

# 结束标记：只匹配 ASCII 前缀 "==== NN "，避免依赖 grep 对 UTF-8 的支持
marker_present() {
    grep -qF -e "==== $1 " "$2" 2>/dev/null
}

run_one() {
    local src="$1"
    local base nn
    base=$(basename "$src" .el)
    nn=${base%%-*}

    printf '%-28s' "$base"

    cp -f "$src" "$BUILD_DIR/$base.el" || { echo "FAIL 复制失败"; return 1; }

    # --- 1) 字节编译（stderr 必须干净） ---
    ( cd "$BUILD_DIR" && "$EMACS_BIN" -Q --batch \
        --eval "(byte-compile-file \"$base.el\")" ) \
        >"$BUILD_DIR/$base.compile.out" 2>"$BUILD_DIR/$base.compile.err"
    local rc=$?

    if [ "$rc" -ne 0 ]; then
        echo "FAIL 编译退出码 $rc"
        sed -n '1,12p' "$BUILD_DIR/$base.compile.err" | sed 's/^/      /'
        return 1
    fi
    if [ -s "$BUILD_DIR/$base.compile.err" ]; then
        echo "FAIL 编译产生警告（stderr 非空）"
        sed -n '1,12p' "$BUILD_DIR/$base.compile.err" | sed 's/^/      /'
        return 1
    fi
    rm -f "$BUILD_DIR/$base.elc"

    # --- 2) 运行（四条标准） ---
    ( cd "$BUILD_DIR" && "$EMACS_BIN" -Q --batch -l "$base.el" ) \
        >"$BUILD_DIR/$base.out" 2>"$BUILD_DIR/$base.err"
    rc=$?

    if [ "$rc" -ne 0 ]; then
        echo "FAIL 运行退出码 $rc"
        sed -n '1,12p' "$BUILD_DIR/$base.err" | sed 's/^/      /'
        [ -s "$BUILD_DIR/$base.out" ] && tail -3 "$BUILD_DIR/$base.out" | sed 's/^/      | /'
        return 1
    fi
    if [ -s "$BUILD_DIR/$base.err" ]; then
        echo "FAIL 运行 stderr 非空"
        sed -n '1,12p' "$BUILD_DIR/$base.err" | sed 's/^/      /'
        return 1
    fi
    if has_ctrl "$BUILD_DIR/$base.out"; then
        echo "FAIL 输出含多余控制字符"
        LC_ALL=C tr -d '\11\12\15' < "$BUILD_DIR/$base.out" \
            | LC_ALL=C tr -dc '\0-\10\13-\14\16-\37' | od -c | head -3 | sed 's/^/      /'
        return 1
    fi
    if ! marker_present "$nn" "$BUILD_DIR/$base.out"; then
        echo "FAIL 缺少结束标记 '==== $nn 结束 ===='"
        tail -3 "$BUILD_DIR/$base.out" | sed 's/^/      | /'
        return 1
    fi

    echo "OK   ($(wc -l < "$BUILD_DIR/$base.out" | tr -d ' ') 行输出)"
    return 0
}

# ---------------- 主流程 ----------------

if [ "${1:-}" = "-Clean" ]; then
    rm -rf "$BUILD_DIR"
    echo "[Clean] 已删除 $BUILD_DIR"
    exit 0
fi

if [ "${1:-}" = "-Keep" ]; then
    KEEP=1
    shift
fi

if [ ! -d "$EXAMPLES_DIR" ]; then
    echo "错误：找不到 examples 目录：$EXAMPLES_DIR" >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"

if [ "$#" -gt 0 ]; then
    TARGETS=()
    for a in "$@"; do
        case "$a" in
            *.el) TARGETS+=("$EXAMPLES_DIR/$a") ;;
            *)    TARGETS+=("$EXAMPLES_DIR/$a.el") ;;
        esac
    done
else
    TARGETS=()
    while IFS= read -r f; do TARGETS+=("$f"); done < <(
        find "$EXAMPLES_DIR" -maxdepth 1 -name '[0-9][0-9]-*.el' | sort
    )
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
    echo "错误：examples 目录下没有 NN-*.el 示例文件" >&2
    exit 1
fi

echo "Emacs : $EMACS_BIN"
echo "示例数: ${#TARGETS[@]}"
echo "------------------------------------------------------------"

pass=0; fail=0
for t in "${TARGETS[@]}"; do
    if [ ! -f "$t" ]; then
        echo "$(basename "$t")   FAIL 文件不存在"; fail=$((fail + 1)); continue
    fi
    if run_one "$t"; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
done

echo "------------------------------------------------------------"
if [ "$KEEP" -eq 0 ]; then
    # 用 shell 通配符而不是 find -delete：本机 find 是 toybox，
    # 不支持 -delete 时会退化成 -print，文件根本没被删掉。
    rm -f "$BUILD_DIR"/*.out "$BUILD_DIR"/*.err "$BUILD_DIR"/*.el "$BUILD_DIR"/*.elc
fi

echo "通过 $pass   失败 $fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
