#!/usr/bin/env bash
# ============================================================
# 第 22 章验证脚本（run.ps1 的 shell 镜像）：clang 前端工具链四连
#   ① -emit-llvm 产 IR → 交给**另一套** LLVM 的 lli 执行（跨版本 IR 互通实证）
#   ② -Xclang -ast-dump 看 AST
#   ③ clang-format + 本目录 .clang-format 配置文件
#   ④ clang-tidy 基础体检
#
# 运行：bash run.sh      需要的环境变量由 run-all.sh 导出；
#      也可以单独跑：LLVM_BIN=/opt/local/libexec/llvm-23/bin bash run.sh
#
# 与 Windows 侧的差异（都换成事实条件，不是放宽断言）：
#   * Windows 是「scoop clang 23 产 IR → MSYS2 lli 22 执行」，本机没有
#     MSYS2，改用 llvm-23 产 IR → llvm-21 的 lli 执行，一样是跨版本；
#     若本机只有一套 LLVM（LLVM2_BIN == LLVM_BIN），仍执行但会明确打印
#     「同版本，未构成跨版本验证」——不假装跨了。
#   * clang 需要 -isysroot（MacPorts 的 clang 找不到 Xcode SDK 的头文件），
#     Windows 侧对应的是「GNU 目标 + -isystem 借 MSYS2 头」。
# ============================================================

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"

: "${LLVM_BIN:?需要 LLVM_BIN（run-all.sh 会导出）}"
: "${LLVM_CONFIG:=${LLVM_BIN}/llvm-config}"
LLVM2_BIN="${LLVM2_BIN:-$LLVM_BIN}"
BUILD_DIR="${REPO_BUILD:-$(cd "$HERE/../.." && pwd)/build}"
OUT="$BUILD_DIR/22_clang_tools"
mkdir -p "$OUT"

CLANG="$LLVM_BIN/clang"
FMT="$LLVM_BIN/clang-format"
TIDY="$LLVM_BIN/clang-tidy"
LLI2="$LLVM2_BIN/lli"

for t in "$CLANG" "$FMT" "$TIDY" "$LLI2"; do
    [ -x "$t" ] || { echo "未找到 $t" >&2; exit 1; }
done

# SDK 根：run-all.sh 用空格分隔的字符串传进来
SDK_ARGS=()
if [ -n "${SDK_ARGS_STR:-}" ]; then
    read -r -a SDK_ARGS <<<"$SDK_ARGS_STR"
fi

echo "== 22 clang 前端工具链 =="
echo "  产 IR : ${CLANG}（$("$LLVM_CONFIG" --version)）"
if [ "$LLVM2_BIN" != "$LLVM_BIN" ]; then
    echo "  执行 IR: ${LLI2}（跨版本）"
else
    echo "  执行 IR: ${LLI2}（同版本，未构成跨版本验证）"
fi

# ① IR 生成 + 跨版本执行
"$CLANG" "${SDK_ARGS[@]}" -S -emit-llvm -O1 "$HERE/sample.c" -o "$OUT/sample.ll" || exit 1
LC_ALL=C grep -qE 'define .*@main' "$OUT/sample.ll" || { echo "IR 里没有 main" >&2; exit 1; }
"$LLI2" "$OUT/sample.ll" >"$OUT/sample.run" 2>&1 || { cat "$OUT/sample.run" >&2; exit 1; }
LC_ALL=C grep -qF '==== 22 ir ok ====' "$OUT/sample.run" \
    || { echo "lli 执行结果缺少结束标记" >&2; cat "$OUT/sample.run" >&2; exit 1; }
echo "[1/4] 产 IR → 另一套 lli 执行：OK"

# ② AST dump（前端视角：翻译前的树）
"$CLANG" "${SDK_ARGS[@]}" -Xclang -ast-dump -fsyntax-only "$HERE/sample.c" \
    >"$OUT/sample.ast" 2>&1 || { cat "$OUT/sample.ast" >&2; exit 1; }
LC_ALL=C grep -q 'FunctionDecl' "$OUT/sample.ast" || { echo "AST 缺 FunctionDecl" >&2; exit 1; }
LC_ALL=C grep -q 'ForStmt' "$OUT/sample.ast"      || { echo "AST 缺 ForStmt" >&2; exit 1; }
echo "[2/4] -Xclang -ast-dump：OK（FunctionDecl/ForStmt 都在）"

# ③ clang-format：配置文件驱动的重排（在副本上做，源文件保持「丑」）
cp "$HERE/ugly.c" "$OUT/ugly.c"
"$FMT" --style=file "$OUT/ugly.c" -i || exit 1
if LC_ALL=C grep -q 'if(x<0){return' "$OUT/ugly.c"; then
    echo "ugly.c 没有被格式化" >&2
    exit 1
fi
LC_ALL=C grep -q 'return -x;' "$OUT/ugly.c" || { echo "格式化结果异常" >&2; exit 1; }
echo "[3/4] clang-format + .clang-format：OK（压缩大括号已被展开）"

# ④ clang-tidy：静态体检（重点在能跑通 + 报告可读，不追求零告警）
#   MacPorts 的 clang-tidy 默认不启用任何检查，与 scoop 版同理，须 --checks 点名；
#   SDK 根要经 `--` 传给底层 clang，否则它自己会报 stdio.h not found。
"$TIDY" --checks="clang-diagnostic-*,readability-*" "$HERE/sample.c" \
    -- "${SDK_ARGS[@]}" >"$OUT/tidy.log" 2>&1 || { cat "$OUT/tidy.log" >&2; exit 1; }
echo "[4/4] clang-tidy：OK（$(( $(LC_ALL=C grep -c 'warning:' "$OUT/tidy.log") )) 条告警，属预期）"

echo "==== 22 ok ===="
