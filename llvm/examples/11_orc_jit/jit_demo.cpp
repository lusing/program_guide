// 第 11 章示例：ORC JIT（LLJIT）——三个方向的互调
//
//   ① IR 来自文本字符串（parseIR）    ② IR 来自 IRBuilder 手工构建
//   ③ JIT'd 代码回调宿主的 C 函数（Windows 上必须 __declspec(dllexport)！）
//
// 构建：
//   g++ jit_demo.cpp -o jit_demo $(llvm-config --cxxflags --ldflags \
//        --link-shared --libs core support orcjit executionengine irreader)
// 使用：
//   ./jit_demo

#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace llvm::orc;

static ExitOnError ExitOnErr;

// 宿主函数：JIT'd 代码要能"看见"它们，Windows 上必须显式导出
extern "C" __declspec(dllexport) int host_mul(int a, int b) { return a * b; }
extern "C" __declspec(dllexport) void print_i32(int v) {
  outs() << "jit says: " << v << "\n";
}

// ① 文本字符串形式的 IR（别忘了 DataLayout 要和 JIT 对齐）
static ThreadSafeModule makeTextModule(const DataLayout &DL) {
  auto Ctx = std::make_unique<LLVMContext>();
  SMDiagnostic Err;
  // 22 的 parseIR 收 MemoryBufferRef（轻量视图），不再收 unique_ptr<MemoryBuffer>
  auto M = parseIR(MemoryBufferRef(R"IR(
; 22 的解析器：调用的外部函数必须先声明（老版本会隐式插入声明）
declare i32 @host_mul(i32, i32)
declare void @print_i32(i32)

define i32 @poly(i32 %x) {
entry:
  %a = call i32 @host_mul(i32 %x, i32 %x)
  %b = call i32 @host_mul(i32 %x, i32 3)
  %s = add i32 %a, %b
  ret i32 %s
}
define void @show(i32 %x) {
entry:
  call void @print_i32(i32 %x)
  ret void
}
)IR",
                                   "poly.ll"),
                    Err, *Ctx);
  if (!M) {
    Err.print("jit_demo", errs());
    exit(1);
  }
  M->setDataLayout(DL);
  return ThreadSafeModule(std::move(M), std::move(Ctx));
}

// ② IRBuilder 手工构建的 IR：fib
static ThreadSafeModule makeFibModule(const DataLayout &DL) {
  auto Ctx = std::make_unique<LLVMContext>();
  auto M = std::make_unique<Module>("fib-mod", *Ctx);
  M->setDataLayout(DL);
  IRBuilder<> B(*Ctx);

  FunctionType *FT = FunctionType::get(B.getInt32Ty(), {B.getInt32Ty()}, false);
  Function *Fib = Function::Create(FT, Function::ExternalLinkage, "fib", M.get());
  Fib->getArg(0)->setName("n");
  BasicBlock *Entry = BasicBlock::Create(*Ctx, "entry", Fib);
  BasicBlock *Recur = BasicBlock::Create(*Ctx, "recur", Fib);
  BasicBlock *Base = BasicBlock::Create(*Ctx, "base", Fib);

  B.SetInsertPoint(Entry);
  Value *N = Fib->getArg(0);
  B.CreateCondBr(B.CreateICmpSLT(N, ConstantInt::get(B.getInt32Ty(), 2), "small"),
                 Base, Recur);
  B.SetInsertPoint(Base);
  B.CreateRet(N);
  B.SetInsertPoint(Recur);
  Value *F1 = B.CreateCall(FT, Fib, {B.CreateSub(N, ConstantInt::get(B.getInt32Ty(), 1), "n1")}, "f1");
  Value *F2 = B.CreateCall(FT, Fib, {B.CreateSub(N, ConstantInt::get(B.getInt32Ty(), 2), "n2")}, "f2");
  B.CreateRet(B.CreateAdd(F1, F2, "sum"));

  return ThreadSafeModule(std::move(M), std::move(Ctx));
}

int main() {
  // ORC 直接对目标机器动手，先初始化本机目标（JIT 编的是本机码）
  InitializeNativeTarget();
  InitializeNativeTargetAsmPrinter();
  InitializeNativeTargetAsmParser();

  auto J = ExitOnErr(LLJITBuilder().create());

  // 增量添加：两个来源的模块扔进同一个 Main JITDylib
  ExitOnErr(J->addIRModule(makeTextModule(J->getDataLayout())));
  ExitOnErr(J->addIRModule(makeFibModule(J->getDataLayout())));

  // ③+宿主调 JIT：lookup 拿到地址，toPtr 转成 C 函数指针
  auto PolyAddr = ExitOnErr(J->lookup("poly"));
  auto ShowAddr = ExitOnErr(J->lookup("show"));
  auto FibAddr = ExitOnErr(J->lookup("fib"));
  int (*poly)(int) = PolyAddr.toPtr<int (*)(int)>();
  void (*show)(int) = ShowAddr.toPtr<void (*)(int)>();
  int (*fib)(int) = FibAddr.toPtr<int (*)(int)>();

  outs() << "poly(7)  = " << poly(7) << "\n";  // 49+21 = 70
  show(poly(9));                               // JIT 内部回调宿主 print_i32：108
  outs() << "fib(10)  = " << fib(10) << "\n";  // 55

  // 顺带验证：进程符号（宿主自己的函数）也能查——但要用 ProcessSymbols JITDylib，
  // J->lookup() 只搜 Main JITDylib（22 的行为，实测结论）
  JITDylib *PJD = J->getProcessSymbolsJITDylib().get();
  auto HostMul = J->getExecutionSession().lookup({PJD}, "host_mul");
  outs() << "host_mul visible: " << (HostMul ? "yes" : "no") << "\n";

  outs() << "==== 11 ok ====\n";
  return 0;
}
