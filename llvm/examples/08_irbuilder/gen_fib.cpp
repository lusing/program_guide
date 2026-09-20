// 第 8 章示例：用 C++ API（IRBuilder）编程生成 IR
//
// 这个程序本身不含任何 fib 的"源代码"——它在内存里搭出一个 Module，
// 写出 fib.ll，由 lli 去执行。这是第 12-20 章 MiniLang 代码生成器的雏形。
//
// 构建：
//   g++ gen_fib.cpp -o gen_fib $(llvm-config --cxxflags --ldflags \
//        --link-shared --libs core support irreader)
// 使用：
//   ./gen_fib fib.ll && lli fib.ll

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/raw_ostream.h"

#include <memory>

using namespace llvm;

// fib(n) = n < 2 ? n : fib(n-1) + fib(n-2)
static Function *buildFib(LLVMContext &Ctx, Module &M) {
  IRBuilder<> B(Ctx);
  FunctionType *FT = FunctionType::get(B.getInt32Ty(), {B.getInt32Ty()}, false);
  Function *F = Function::Create(FT, Function::ExternalLinkage, "fib", M);
  // 给参数起名（否则叫 %0）
  F->getArg(0)->setName("n");

  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", F);
  BasicBlock *Recur = BasicBlock::Create(Ctx, "recur", F);
  BasicBlock *Base = BasicBlock::Create(Ctx, "base", F);

  B.SetInsertPoint(Entry);
  Value *N = F->getArg(0);
  Value *IsSmall = B.CreateICmpSLT(N, ConstantInt::get(B.getInt32Ty(), 2), "is.small");
  B.CreateCondBr(IsSmall, Base, Recur);

  B.SetInsertPoint(Base);
  B.CreateRet(N);

  B.SetInsertPoint(Recur);
  Value *N1 = B.CreateSub(N, ConstantInt::get(B.getInt32Ty(), 1), "n.minus.1");
  Value *N2 = B.CreateSub(N, ConstantInt::get(B.getInt32Ty(), 2), "n.minus.2");
  Value *F1 = B.CreateCall(FT, F, {N1}, "fib.n.1");
  Value *F2 = B.CreateCall(FT, F, {N2}, "fib.n.2");
  B.CreateRet(B.CreateAdd(F1, F2, "add.r"));

  return F;
}

// main：printf("fib(10) = %d\n", fib(10)); puts("==== 08 ok ===="); return 0
static void buildMain(LLVMContext &Ctx, Module &M) {
  IRBuilder<> B(Ctx);
  FunctionType *MainT = FunctionType::get(B.getInt32Ty(), false);
  Function *Main = Function::Create(MainT, Function::ExternalLinkage, "main", M);

  // 字符串常量：数据是 [N x i8]，但"全局变量的值"在不透明指针时代就是 ptr，
  // 可以直接传给 printf——不再需要 ConstantExpr GEP（ConstantExpr 家族 21 起已删除）
  auto *Fmt = ConstantDataArray::getString(Ctx, "fib(10) = %d\n");
  auto *Ok = ConstantDataArray::getString(Ctx, "==== 08 ok ====");
  auto *GV = new GlobalVariable(M, Fmt->getType(), true,
                                GlobalValue::PrivateLinkage, Fmt, ".intfmt");
  auto *GVok = new GlobalVariable(M, Ok->getType(), true,
                                  GlobalValue::PrivateLinkage, Ok, ".ok");

  // printf / puts 声明
  auto *VoidPtrTy = PointerType::get(Ctx, 0);
  FunctionType *PrintfT = FunctionType::get(B.getInt32Ty(), VoidPtrTy, true);
  FunctionCallee Printf = M.getOrInsertFunction("printf", PrintfT);
  FunctionType *PutsT = FunctionType::get(B.getInt32Ty(), VoidPtrTy, false);
  FunctionCallee Puts = M.getOrInsertFunction("puts", PutsT);

  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", Main);
  B.SetInsertPoint(Entry);
  FunctionType *FibT = FunctionType::get(B.getInt32Ty(), B.getInt32Ty(), false);
  Function *Fib = M.getFunction("fib");
  Value *R = B.CreateCall(FibT, Fib, {ConstantInt::get(B.getInt32Ty(), 10)}, "r");
  B.CreateCall(PrintfT, Printf.getCallee(), {GV, R});
  B.CreateCall(PutsT, Puts.getCallee(), {GVok});
  B.CreateRet(ConstantInt::get(B.getInt32Ty(), 0));
}

int main(int argc, char **argv) {
  if (argc != 2) {
    errs() << "usage: gen_fib <output.ll>\n";
    return 2;
  }
  LLVMContext Ctx;
  Module M("fib-module", Ctx);
  M.setSourceFileName("gen_fib.ll");

  buildFib(Ctx, M);
  buildMain(Ctx, M);

  // 结构合法性验证（phi 来源数、终结指令、类型对齐……）
  if (verifyModule(M, &errs())) {
    errs() << "module verify failed\n";
    return 1;
  }

  std::error_code EC;
  raw_fd_ostream Out(argv[1], EC);
  if (EC) {
    errs() << "cannot open " << argv[1] << ": " << EC.message() << "\n";
    return 1;
  }
  M.print(Out, nullptr);
  outs() << "wrote " << argv[1] << "\n";
  return 0;
}
