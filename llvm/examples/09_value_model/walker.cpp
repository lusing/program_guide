// 第 9 章示例：Value/User/Use 对象模型实战
//
// 功能：读入 .ll → 分类统计指令 → 打印 @square 的 use 链 →
//       克隆 @square 成 @square2 并 RAUW（替换全部使用）→ 删除原件 → 写出
//
// 构建：
//   g++ walker.cpp -o walker $(llvm-config --cxxflags --ldflags \
//        --link-shared --libs core support irreader asmparser transformutils)
// 使用：
//   ./walker walk.ll out.ll && lli out.ll   （行为不变，证明手术等价）

#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <map>

using namespace llvm;

int main(int argc, char **argv) {
  if (argc != 3) {
    errs() << "usage: walker <in.ll> <out.ll>\n";
    return 2;
  }

  // ---- ① 解析文本 IR：IRReader + SMDiagnostic（报错带行号）----
  LLVMContext Ctx;
  SMDiagnostic Err;
  auto M = parseIRFile(argv[1], Err, Ctx);
  if (!M) {
    Err.print("walker", errs());
    return 1;
  }

  // ---- ② 遍历：isa/dyn_cast 分类统计 ----
  //     对象模型速记：Module 拥有 Function，Function 拥有 BasicBlock，
  //     BasicBlock 拥有 Instruction，一切皆 Value（有类型、有名字、可被使用）
  errs() << "== module '" << M->getName() << "' has "
         << M->size() << " functions, " << M->global_size() << " globals\n";

  // 注意键用 std::string：Twine(...).str() 是临时对象，用 StringRef 当键会悬垂（实测踩坑）
  std::map<std::string, unsigned> Histogram;
  for (Function &F : *M) {
    if (F.isDeclaration()) continue; // printf/puts 只有声明
    unsigned nBB = 0, nInst = 0;
    for (BasicBlock &BB : F) {
      nBB++;
      for (Instruction &I : BB) {
        nInst++;
        // dyn_cast = "是这种类型就给指针，不是给 nullptr"（LLVM 自家的 RTTI）
        if (auto *BO = dyn_cast<BinaryOperator>(&I))
          Histogram[(Twine("binary:") + BO->getOpcodeName()).str()]++;
        else if (isa<CallBase>(I))
          Histogram["call"]++;
        else if (isa<ReturnInst>(I))
          Histogram["ret"]++;
        else
          Histogram["other"]++;
      }
    }
    errs() << "   " << F.getName() << ": " << nBB << " bb, " << nInst << " insts\n";
  }
  errs() << "== instruction histogram:\n";
  for (auto &[K, V] : Histogram)
    errs() << "   " << K << " x" << V << "\n";

  // ---- ③ use 链：谁在用 @square ----
  Function *Square = M->getFunction("square");
  if (!Square) {
    errs() << "no @square in module\n";
    return 1;
  }
  errs() << "== users of @square:\n";
  for (Use &U : Square->uses()) {
    // Use 是"一条边"：getUser() 是使用者，get() 是被用的值
    if (auto *CB = dyn_cast<CallBase>(U.getUser())) {
      Function *Caller = CB->getFunction();
      errs() << "   call site in @" << Caller->getName() << "\n";
    } else {
      errs() << "   used by: " << *U.getUser() << "\n";
    }
  }

  // ---- ④ 手术：克隆 + RAUW + 删除 ----
  // CloneFunction 的 22 版语义：返回副本并【已自动加入当前模块】——
  // 千万不要再 M->getFunctionList().push_back()（双重插入会损坏链表，实测死循环）
  ValueToValueMapTy VMap;
  Function *Square2 = CloneFunction(Square, VMap);
  Square2->setName("square2");
  // replaceAllUsesWith：把所有"用 @square 的地方"换成 @square2
  Square->replaceAllUsesWith(Square2);
  // 没人用了 → 可以安全抹掉（use_empty() 就是死代码判据）
  errs() << "== after RAUW: uses of @square = " << Square->getNumUses() << "\n";
  Square->eraseFromParent();

  // ---- ⑤ 写出 ----
  std::error_code EC;
  raw_fd_ostream Out(argv[2], EC);
  if (EC) {
    errs() << "cannot write " << argv[2] << ": " << EC.message() << "\n";
    return 1;
  }
  M->print(Out, nullptr);
  outs() << "wrote " << argv[2] << "\n";
  return 0;
}
