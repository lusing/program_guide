#!/usr/bin/env bash
# ============================================================
# 第 23 章验证脚本（run.ps1 的 shell 镜像）：LLVM 源码导览（只读寻宝）
#   对象：LLVM monorepo 检出。目的是拿到「类/头文件在源码树的哪里」的
#         肌肉记忆 + 新旧版本差异实感。
#
# 运行：LLVM_SRC=/path/to/llvm-project bash run.sh
#       （不设 LLVM_SRC 时，run-all.sh 会把本例记为环境缺口并跳过）
#
# 与 Windows 侧的唯一差异是源码路径：那边是 G:\github\lang\llvm-project，
# 本机用 LLVM_SRC 指定。**断言一条都没减**——地标检查项与 run.ps1 完全对齐。
# 若设了 LLVM_SRC 却不是 monorepo 布局，按失败处理，不降级。
# ============================================================

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${REPO_BUILD:-$(cd "$HERE/../.." && pwd)/build}"
OUT="$BUILD_DIR/23_source_tour"
mkdir -p "$OUT"

: "${LLVM_SRC:?需要 LLVM_SRC=/path/to/llvm-project（monorepo 检出）}"
SRC="$LLVM_SRC/llvm"          # monorepo 布局：llvm/ 是编译器本体，旁边还有 clang/ lld/ …
REPO="$LLVM_SRC"

if [ ! -f "$SRC/CMakeLists.txt" ]; then
    echo "未找到 LLVM monorepo：$REPO（llvm/ 子目录缺失）" >&2
    exit 1
fi

# 在文件里找指定模式，找不到就失败
assert_found() {   # assert_found <正则> <文件> <说明>
    local pat="$1" path="$2" what="$3" n
    n=$(LC_ALL=C grep -cE -- "$pat" "$path" 2>/dev/null || true)
    if [ "${n:-0}" -eq 0 ]; then
        echo "源码导览断言失败：在 $(basename "$path") 找不到 ${what}" >&2
        exit 1
    fi
    echo "  [found] ${what}  (${n} 处)"
}

need_path() {   # need_path <路径> <说明>
    if [ ! -e "$1" ]; then
        echo "缺少 $2：$1" >&2
        exit 1
    fi
}

echo "== 版本确认 =="
echo "  HEAD: $(git -C "$REPO" log --oneline -1 2>/dev/null || echo '（非 git 检出）')"
echo "  本教程实操工具链：$(${LLVM_CONFIG:-llvm-config} --version 2>/dev/null || echo '未知')；差异见 docs/23-source-tour.md 的对照表"

echo "== 地标 1：IR 核心类（llvm/include/llvm/IR/）=="
for f in Module.h Function.h BasicBlock.h IRBuilder.h Instructions.h Verifier.h; do
    need_path "$SRC/include/llvm/IR/$f" "include/llvm/IR/$f"
done
echo "  [found] Module/Function/BasicBlock/IRBuilder/Instructions/Verifier 六件套"

echo "== 地标 2：第 9 章对象模型的源头 =="
assert_found 'class Value'   "$SRC/include/llvm/IR/Value.h"        "class Value"
assert_found 'class User'    "$SRC/include/llvm/IR/User.h"         "class User"
assert_found 'class Use'     "$SRC/include/llvm/IR/Use.h"          "class Use"
assert_found 'class PHINode' "$SRC/include/llvm/IR/Instructions.h" "class PHINode"

echo "== 地标 3：PassManager 新旧双制 =="
assert_found 'class PassManager'  "$SRC/include/llvm/IR/PassManager.h"      "新 PM: class PassManager"
assert_found 'class FunctionPass' "$SRC/include/llvm/IR/LegacyPassManager.h" "旧 PM: class FunctionPass（Legacy 体系仍在，供代码生成管线用）"

echo "== 地标 4：PassPlugin 的现代位置（本书 6 章踩过的搬家）=="
need_path "$SRC/include/llvm/Plugins/PassPlugin.h" "llvm/Plugins/PassPlugin.h（22+ 的家）"
echo "  [found] llvm/Plugins/PassPlugin.h（老教程的 llvm/Passes/PassPlugin.h 已不存在）"
assert_found 'registerPipelineParsingCallback' "$SRC/include/llvm/Passes/PassBuilder.h" "PassBuilder 的管线解析回调"

echo "== 地标 5：本教程各章对应的实现文件（llvm/lib/）=="
for f in lib/IR/Module.cpp lib/IR/IRBuilder.cpp lib/IR/Verifier.cpp \
         lib/IR/AsmWriter.cpp lib/Passes/PassBuilder.cpp; do
    need_path "$SRC/$f" "$f"
done
echo "  [found] Module/IRBuilder/Verifier/AsmWriter/PassBuilder 的 .cpp 都在老位置"

echo "== 地标 6：工具与 JIT =="
for d in tools/opt tools/llc tools/lli tools/llvm-as tools/llvm-dis; do
    need_path "$SRC/$d" "$d"
done
echo "  [found] opt/llc/lli/llvm-as/llvm-dis 的命令行实现"
assert_found 'class LLJIT' "$SRC/include/llvm/ExecutionEngine/Orc/LLJIT.h" "ORC LLJIT"

echo "== 地标 7：monorepo 的邻居（同仓多项目）=="
for d in clang/lib/Sema lld/ELF; do
    need_path "$REPO/$d" "monorepo 子项目 $d"
done
echo "  [found] clang/ 与 lld/ 同仓共生（这就是 monorepo 的含义）"

echo "== 规模感 =="
ir_cpp=$(find "$SRC/lib/IR" -name '*.cpp' 2>/dev/null | wc -l | tr -d ' ')
inc_ir=$(find "$SRC/include/llvm/IR" -name '*.h' 2>/dev/null | wc -l | tr -d ' ')
echo "  llvm/lib/IR: ${ir_cpp} 个 .cpp；llvm/include/llvm/IR: ${inc_ir} 个 .h"

echo "==== 23 ok ===="
