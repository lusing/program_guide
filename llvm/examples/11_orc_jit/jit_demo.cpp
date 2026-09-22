// 第 11 章示例：ORC JIT（LLJIT）——三个方向的互调
//
//   ① IR 来自文本字符串（parseIR）    ② IR 来自 IRBuilder 手工构建
//   ③ JIT'd 代码回调宿主的 C 函数（宿主侧要显式导出，见下面 JIT_HOST_EXPORT）

//
// 构建：
//   clang++ jit_demo.cpp -o jit_demo $(llvm-config --cxxflags --ldflags \
//        --link-shared --libs core support orcjit executionengine irreader)
// 使用：
//   ./jit_demo

#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"
#include <string>

using namespace llvm;
using namespace llvm::orc;

static ExitOnError ExitOnErr;

// 宿主函数：JIT'd 代码要能"看见"它们，两侧平台都得显式导出，但理由不同：
//   * Windows（PE）：符号解析走**导出表**，MinGW 默认不给 exe 导出普通函数，
//     不写 dllexport 就报 Symbols not found: [ host_mul ]；
//   * Unix（ELF/Mach-O）：ORC 的 ProcessSymbols JD 走 dlsym(RTLD_DEFAULT)，
//     靠的是"默认可见性"。显式写 default 才能在别人加了 -fvisibility=hidden
//     的构建里依旧可见（macOS 上即使不加该开关也建议写，语义才对得上）。
// 所以这里用一个宏把两种写法统一，而不是#if 掉某一侧。
#if defined(_WIN32) || defined(__CYGWIN__)
#define JIT_HOST_EXPORT __declspec(dllexport)
#else
#define JIT_HOST_EXPORT __attribute__((visibility("default")))
#endif

extern "C" JIT_HOST_EXPORT int host_mul(int a, int b) { return a * b; }
extern "C" JIT_HOST_EXPORT void print_i32(int v) {
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
  // J->lookup() 只搜 Main JITDylib
  //
  // 查询名要带**目标平台的全局前缀**：DataLayout 的 m: 段是权威来源，
  // Mach-O 给 '_'，ELF 与 COFF-x86_64 给空。Windows/Linux 上 "host_mul"
  // 直接命中；macOS 上 dlsym 只认 "_host_mul"，裸名会报
  // "Symbols not found: [ host_mul ]"。
  // 另外各 LLVM 版本对"前缀由谁加"并不一致（23 的 LLJIT 交给调用方，
  // 22 的 DynamicLibrarySearchGenerator 自己加），所以两种写法都试，
  // 命中哪个都算数——这条断言要保证的事实是"宿主符号确实可见"。
  JITDylib *PJD = J->getProcessSymbolsJITDylib().get();
  char GP = J->getDataLayout().getGlobalPrefix();
  std::string HostNames[2] = {"host_mul",
                              (GP ? std::string(1, GP) : "") + "host_mul"};
  bool HostVisible = false;
  for (const std::string &N : HostNames) {
    auto R = J->getExecutionSession().lookup({PJD}, N);
    if (R) {
      HostVisible = true;
      break;
    }
    consumeError(R.takeError());
  }
  outs() << "host_mul visible: " << (HostVisible ? "yes" : "no") << "\n";

  outs() << "==== 11 ok ====\n";
  return 0;
}
