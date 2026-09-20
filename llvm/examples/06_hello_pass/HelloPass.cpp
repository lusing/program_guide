// 第 6 章示例：第一个 LLVM Pass（新 PassManager 插件形态）
//
// 构建（g++ -shared 出插件，链接 libLLVM 动态库）：
//   g++ -shared HelloPass.cpp -o HelloPass.dll \
//        $(llvm-config --cxxflags --ldflags --link-shared --libs core)
// 使用：
//   opt -load-pass-plugin=HelloPass.dll -passes=hello-pass test.ll -disable-output

#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h" // 注意：22 在 Plugins/ 目录（v10 时代在 Passes/）
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

// 新 PM 的 pass = 继承 PassInfoMixin<自己> 的普通结构体
struct HelloPass : PassInfoMixin<HelloPass> {
  // run() 是全部逻辑：拿一个 Function，返回"保住了哪些分析"
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    errs() << "hello-pass: " << F.getName() << " (" << F.size() << " bb)\n";
    // 我们只读不写：所有分析结果依然有效
    return PreservedAnalyses::all();
  }
  // 只打印、不改 IR 的 pass 声明"我是必需的"，防止被管线当作死 pass 跳过
  static bool isRequired() { return true; }
};

} // namespace

// 插件入口：C 链接、弱符号。opt 加载 dll 后按这个名字找它
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "hello-pass", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            // 把名字 "hello-pass" 挂进 -passes= 管线语言
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "hello-pass") {
                    FPM.addPass(HelloPass());
                    return true; // 名字认领成功
                  }
                  return false; // 不认识，交给下一个回调
                });
          }};
}
