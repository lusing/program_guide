#!/usr/bin/env bash
# ============================================================
# MiniLang v1.0 回归套件（regr.ps1 的 shell 镜像）：四种执行路径行为一致性
#   ① run（JIT -O2）  ② run0（JIT 无优化）  ③ ir→lli  ④ obj→clang 链接→可执行
# 判定：每种路径都输出 regression 的期望十行数值 + 退出码 0
#
# 运行：bash regr.sh（依赖 build/24_minilang_full/minilang.{shared,static} 已就位）
#       run-all.sh 会先构建再调本脚本。
#
# 本侧加强：四条路径在 **shared / static 两个链接通道** 上各跑一遍。
# 同一个 IR 与同一套 MiniLang 源码，换一种链法结果必须一致——这正好检验
# 「示例有没有依赖动态库加载或安装前缀」。
#
# 与 Windows 侧的差异：产物名不带 .exe（Unix 可执行没有扩展名约定），
# 链接要补 -isysroot（MacPorts 的 clang 找不着 Xcode SDK 会报
# ld: library 'System' not found）。数值断言一条没减。
# ============================================================

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
: "${LLVM_BIN:?需要 LLVM_BIN}"
BUILD_DIR="${REPO_BUILD:-$(cd "$HERE/../.." && pwd)/build}"
ROOT="$BUILD_DIR/24_minilang_full"

LLI="$LLVM_BIN/lli"
CLANG="$LLVM_BIN/clang"
for t in "$LLI" "$CLANG"; do
    [ -x "$t" ] || { echo "未找到 $t" >&2; exit 1; }
done

SDK_ARGS=()
if [ -n "${SDK_ARGS_STR:-}" ]; then
    read -r -a SDK_ARGS <<<"$SDK_ARGS_STR"
fi

EXPECTED=('55\.0+' '5050\.0+' '720\.0+' '42\.0+' '1024\.0+' \
          '1\.0+' '0\.0+' '1\.0+' '0\.0+' '0\.0+')

check_output() {   # check_output <名字> <输出文件>
    local name="$1" file="$2" e
    for e in "${EXPECTED[@]}"; do
        if ! LC_ALL=C grep -qE -- "$e" "$file"; then
            echo "$name 输出缺少预期值 /$e/" >&2
            sed 's/^/    /' "$file" >&2
            return 1
        fi
    done
    echo "  [ok] $name"
}

echo "== MiniLang v1.0 回归 =="
SRC="$HERE/regression.mini"

for ch in shared static; do
    MINI="$ROOT/minilang.$ch"
    [ -x "$MINI" ] || { echo "缺少 $MINI（先构建 24 章）" >&2; exit 1; }
    echo "-- 通道 $ch --"

    "$MINI" run  "$SRC"            >"$ROOT/run.$ch.out"  2>&1 || { cat "$ROOT/run.$ch.out" >&2; exit 1; }
    check_output "run (JIT -O2)"        "$ROOT/run.$ch.out"   || exit 1
    "$MINI" run0 "$SRC"            >"$ROOT/run0.$ch.out" 2>&1 || { cat "$ROOT/run0.$ch.out" >&2; exit 1; }
    check_output "run0 (JIT 无优化)"    "$ROOT/run0.$ch.out"  || exit 1

    "$MINI" ir "$SRC" "$ROOT/regression.$ch.ll" >/dev/null 2>&1 || { echo "ir 模式失败" >&2; exit 1; }
    "$LLI" "$ROOT/regression.$ch.ll" >"$ROOT/lli.$ch.out" 2>&1 || { cat "$ROOT/lli.$ch.out" >&2; exit 1; }
    check_output "ir -> lli"            "$ROOT/lli.$ch.out"   || exit 1

    "$MINI" obj "$SRC" "$ROOT/regression.$ch.o" >/dev/null 2>&1 || { echo "obj 模式失败" >&2; exit 1; }
    "$CLANG" "${SDK_ARGS[@]}" "$ROOT/regression.$ch.o" -o "$ROOT/regression.$ch" \
        || { echo "链接失败" >&2; exit 1; }
    "$ROOT/regression.$ch" >"$ROOT/exe.$ch.out" 2>&1 || { cat "$ROOT/exe.$ch.out" >&2; exit 1; }
    check_output "obj -> 可执行文件"      "$ROOT/exe.$ch.out"   || exit 1
done

# 两通道逐字节比对：同一个 .mini 走同一条路径，链法不同不应改变结果
for p in run run0 lli exe; do
    if ! cmp -s "$ROOT/$p.shared.out" "$ROOT/$p.static.out"; then
        echo "两通道 [$p] 输出不一致：见 $ROOT/$p.shared.out 与 $ROOT/$p.static.out" >&2
        exit 1
    fi
done
echo "  [ok] shared/static 四路径输出逐字节一致"

# 曼德博：只验 run 模式能画出图（首行应是纯 #）
"$ROOT/minilang.shared" run "$HERE/mandel.mini" >"$ROOT/mandel.out" 2>&1 \
    || { cat "$ROOT/mandel.out" >&2; exit 1; }
LC_ALL=C grep -qE '^(#+|=>)' "$ROOT/mandel.out" \
    || { echo "曼德博首行异常" >&2; cat "$ROOT/mandel.out" >&2; exit 1; }
echo "  [ok] mandelbrot (run)"

# ast / stats 冒烟
"$ROOT/minilang.shared" ast "$SRC" >/dev/null 2>&1 || { echo "ast 模式失败" >&2; exit 1; }
echo "  [ok] ast"
"$ROOT/minilang.shared" stats "$SRC" >"$ROOT/stats.out" 2>&1 || { cat "$ROOT/stats.out" >&2; exit 1; }
LC_ALL=C grep -q 'ml-stats: fib' "$ROOT/stats.out" \
    || { echo "stats 输出异常" >&2; cat "$ROOT/stats.out" >&2; exit 1; }
echo "  [ok] stats"

echo "==== 24 ok ===="
