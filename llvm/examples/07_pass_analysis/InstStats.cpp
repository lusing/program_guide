// 第 7 章示例：带自定义 Analysis 的 pass + 扩展点（EP）接入标准 -O2 管线
//
// 三种被点名/触发的方式：
//   1) opt -load-pass-plugin=InstStats.dll -passes=inst-stats     x.ll -disable-output
//   2) opt -load-pass-plugin=InstStats.dll -passes=mem-stats      x.ll -disable-output
//   3) opt -load-pass-plugin=InstStats.dll -O2 x.ll -S -o nul     （EP：自动挂在 -O2 尾部）
//
// 构建：
//   g++ -shared InstStats.cpp -o InstStats.dll \
//        $(llvm-config --cxxflags --ldflags --link-shared --libs core analysis)

#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

// ---------- 自定义分析：数内存相关指令 ----------
// 分析 = 一个"结果可缓存"的计算单元。要点三个：
//   ① 继承 AnalysisInfoMixin 并声明 static AnalysisKey Key（缓存的身份标识）
//   ② run() 算结果
//   ③ Result::invalidate() 决定 IR 变化时缓存何时作废
struct MemOpAnalysis : AnalysisInfoMixin<MemOpAnalysis> {
  struct Result {
    unsigned Loads = 0;
    unsigned Stores = 0;
    unsigned Allocas = 0;
    unsigned Calls = 0;
    bool invalidate(Function &, const PreservedAnalyses &,
                    FunctionAnalysisManager::Invalidator &) {
      return false; // 返回 false = 作废缓存。这里示例性的"永不作废"
    }
  };
  Result run(Function &F, FunctionAnalysisManager &) {
    Result R;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        if (isa<LoadInst>(I)) R.Loads++;
        else if (isa<StoreInst>(I)) R.Stores++;
        else if (isa<AllocaInst>(I)) R.Allocas++;
        else if (isa<CallBase>(I)) R.Calls++;
      }
    return R;
  }
  static AnalysisKey Key; // 配套的 out-of-line 定义见文件底部
};

// ---------- pass 1：直接统计指令/基本块 ----------
struct InstStats : PassInfoMixin<InstStats> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    unsigned insts = 0;
    for (BasicBlock &BB : F)
      insts += std::distance(BB.begin(), BB.end());
    errs() << "inst-stats: " << F.getName() << " bb=" << F.size()
           << " insts=" << insts << "\n";
    return PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }
};

// ---------- pass 2：消费上面的 Analysis ----------
struct MemStats : PassInfoMixin<MemStats> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM) {
    MemOpAnalysis::Result &R = AM.getResult<MemOpAnalysis>(F); // 缓存的计算结果
    errs() << "mem-stats: " << F.getName() << " load=" << R.Loads
           << " store=" << R.Stores << " alloca=" << R.Allocas
           << " call=" << R.Calls << "\n";
    return PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }
};

} // namespace

// AnalysisKey 的 out-of-line 定义（AnalysisInfoMixin 靠它生成缓存的唯一 ID）
AnalysisKey MemOpAnalysis::Key;

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "inst-stats", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            // ① 名字注册：两个 pass 都走函数级适配器
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "inst-stats") { FPM.addPass(InstStats()); return true; }
                  if (Name == "mem-stats") { FPM.addPass(MemStats()); return true; }
                  return false;
                });
            // ② 分析注册：让 AnalysisManager 认识 MemOpAnalysis
            PB.registerAnalysisRegistrationCallback(
                [](FunctionAnalysisManager &FAM) {
                  FAM.registerPass([&] { return MemOpAnalysis(); });
                });
            // ③ 扩展点：-O1 及以上级别的"优化器最后"位置自动追加 MemStats
            //    注意 22 的 EP 回调带第三个参数 ThinOrFullLTOPhase（LTO 阶段）
            PB.registerOptimizerLastEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel Level,
                   ThinOrFullLTOPhase) {
                  if (Level.getSpeedupLevel() >= 2) {
                    FunctionPassManager FPM;
                    FPM.addPass(MemStats());
                    MPM.addPass(createModuleToFunctionPassAdaptor(std::move(FPM)));
                  }
                });
          }};
}
