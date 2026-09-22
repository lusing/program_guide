# 07 · Pass 进阶：自定义 Analysis 与扩展点

> 对应示例：`examples/07_pass_analysis/`（InstStats.cpp + test.ll）

第 6 章的 pass 是"睁眼瞎"——每次 run 都自己从头算。真实编译器里，**pass 消费分析（Analysis）产出的缓存结果**，多个 pass 共享一次计算。本章写一个自定义 Analysis，再演示两种"被动触发"：显式点名、自动挂进 `-O2` 尾部（Extension Point，EP）。

## 7.1 Analysis 是什么

Analysis = **带缓存的计算**。PassManager 替你管理它的生命周期：

```text
Pass A ──getResult<X>()──▶ Analysis X 的缓存 ──┐
Pass B ──getResult<X>()──▶（同一份，不重算）    │ IR 改动时按 invalidate() 作废
Pass C ──getResult<Y>()──▶ Analysis Y 的缓存 ──┘
```

新 PM 里 Analysis 也是个结构体，契约四件套：

```cpp
struct MemOpAnalysis : AnalysisInfoMixin<MemOpAnalysis> {  // ① Mixin 提供 ID 机制
  struct Result {
    unsigned Loads = 0, Stores = 0, Allocas = 0, Calls = 0;
    bool invalidate(Function &, const PreservedAnalyses &,
                    FunctionAnalysisManager::Invalidator &) {
      return false;   // ② IR 变了，缓存还算数吗？（false = 作废重算）
    }
  };
  Result run(Function &F, FunctionAnalysisManager &) { ... }  // ③ 纯计算
  static AnalysisKey Key;   // ④ 缓存身份（out-of-line 定义：AnalysisKey X::Key;）
};
```

四个都有讲究：

- **① AnalysisInfoMixin**：为你的分析生成唯一的缓存键（`ID()` 读 `Key`）——漏了会报 `'ID' is not a member`。
- **② invalidate()**：缓存的死亡条件。返回 `false` = "失效"（名字反直觉！它回答"这个分析结果是否可以在 IR 变化后继续有效"）。正经写法要检查 `PA.preserved<X>()` 与依赖的其他分析是否也活着；示例里演示"永不作废"的最简形态。
- **③ run() 不该有副作用**：Analysis 是纯函数，同输入必须同输出，否则缓存就是灾难。
- **④ Key 必须有 out-of-line 定义**：`AnalysisKey MemOpAnalysis::Key;`（跨翻译单元唯一性的实现技巧）。

消费侧一行：

```cpp
MemOpAnalysis::Result &R = AM.getResult<MemOpAnalysis>(F);  // 没算过→算，算过→给缓存
```

## 7.2 让 PassBuilder 认识你的 Analysis

插件里多挂两个钩子：

```cpp
// 分析注册：AnalysisManager 里登记"会算 MemOpAnalysis"
PB.registerAnalysisRegistrationCallback(
    [](FunctionAnalysisManager &FAM) {
      FAM.registerPass([&] { return MemOpAnalysis(); });
    });
```

这不放 `registerPipelineParsingCallback` 里——分析不是管线成员，是"设施"，注册一次全程可用。

## 7.3 扩展点：把 pass 自动挂进 -O2

`-O2` 的管线是 LLVM 预组装的，但它预留了**扩展点（Extension Point）**——插件可以在约定位置自动插入 pass：

```cpp
// "优化器最后"扩展点：-O2 的收尾处自动追加
PB.registerOptimizerLastEPCallback(
    [](ModulePassManager &MPM, OptimizationLevel Level,
       ThinOrFullLTOPhase) {                     // ← 22 起第三个参数（LTO 阶段）
      if (atLeastO2(Level)) {                    // 只在 -O2 及以上
        FunctionPassManager FPM;
        FPM.addPass(MemStats());
        MPM.addPass(createModuleToFunctionPassAdaptor(std::move(FPM)));
      }
    });
```

`atLeastO2` 是示例里的一个辅助函数，为的是跨版本：**23 把 `OptimizationLevel` 从"带 `getSpeedupLevel()` 的类"改成了裸 `enum class`**，旧写法（连同 `isOptimizingForSpeed()`）一并没了。

```cpp
#if LLVM_VERSION_MAJOR >= 23
static bool atLeastO2(OptimizationLevel Level) { return Level >= OptimizationLevel::O2; }
#else
static bool atLeastO2(OptimizationLevel Level) { return Level.getSpeedupLevel() >= 2; }
#endif
```

三个细节：

1. **EP 回调的层级是 Module**（OptimizerLast 是模块级 EP），函数 pass 要自己包 `createModuleToFunctionPassAdaptor`；
2. **22 的回调签名带 `ThinOrFullLTOPhase`**——旧教程两参数的 lambda 编不过（编译器会报 `cannot convert` 一大串）；
3. EP 家族还有 `PipelineStartEP`（管线最前）、`PeepholeEP`（细粒度优化点）、`LateLoopOptimizationsEP` 等——`grep register.*EPCallback PassBuilder.h` 看全表。

## 7.4 实测：三种触发方式

（构建命令与 06 章同构，链接组件加 `analysis`。）

```powershell
# ① 显式点名两个 pass
& "$uc\opt.exe" -load-pass-plugin=InstStats.dll '-passes=inst-stats,mem-stats' test.ll -disable-output
```

（实测输出，stderr）：

```text
inst-stats: sum_to bb=4 insts=16
mem-stats: sum_to load=3 store=4 alloca=2 call=0
inst-stats: main bb=1 insts=4
mem-stats: main load=0 store=0 alloca=0 call=3
```

`sum_to` 是 alloca 风格循环（第 4 章同款）：3 load、4 store、2 alloca，正是 MemOpAnalysis 数出来的账。

```powershell
# ② EP：什么名字都不点，普通 -O2 就会自动带上
& "$uc\opt.exe" -load-pass-plugin=InstStats.dll -O2 test.ll -S -o after.O2.ll
```

（实测输出，stderr）：

```text
mem-stats: sum_to load=0 store=0 alloca=0 call=0
mem-stats: main load=0 store=0 alloca=0 call=2
```

**见证魔法时刻**：同样的分析，数字全归零了——因为 MemStats 挂在"优化器最后"，此时 mem2reg 已把栈槽提升成 phi、内联已把 `sum_to` 塞进 main（call=2 只剩 printf 和 puts）。你写的不只是 pass，而是嵌进了工业级优化流水线的**观察哨**。

```powershell
# ③ 验证 -O0 不触发（speedup<2 的守卫）
& "$uc\opt.exe" -load-pass-plugin=InstStats.dll -O1 test.ll -S -o nul   # 无 mem-stats 输出
```

## 7.5 缓存有效性的验证实验

invalidate 返回 false（永不作废）在示例里安全吗？验证：让 pass 序列 `inst-stats,mem-stats,dce,mem-stats` 跑两遍 mem-stats——数字一致说明确实读的缓存（或 IR 没变）。真要演示作废，把某个 pass 的返回值改成空的 `PreservedAnalyses()`（全作废），mem-stats 第二次就会重算（结果相同但路径不同——用 `--debug-pass-manager` 能看到 `Invalidating all analyses` 的日志）。这个实验留给读者改代码做，build 脚本验证的是①②两条主路径。

## 7.6 本章小结

- Analysis = 缓存的纯计算：Mixin + Result::invalidate + run + out-of-line Key。
- 注册分析用 `registerAnalysisRegistrationCallback`，消费用 `AM.getResult<T>()`。
- EP 让 pass 自动进标准管线；22 的 EP lambda 带 `ThinOrFullLTOPhase` 参数，23 的 `OptimizationLevel` 变成裸 enum。
- `-O2` 尾部观察到的"归零"是分析+优化协作的直观证据。

| 坑 | 解法 |
|---|---|
| `'ID' is not a member` | 继承 AnalysisInfoMixin + 定义 static AnalysisKey Key |
| invalidate 语义绕 | 返回 false = 作废；true = 仍有效 |
| EP lambda 编不过（22） | 补第三个参数 ThinOrFullLTOPhase |
| `getSpeedupLevel` 不是成员（23） | 23 起 OptimizationLevel 是裸 enum class，改比 `Level >= OptimizationLevel::O2` |
| 函数 pass 挂模块级 EP | 包 createModuleToFunctionPassAdaptor |
| 分析结果好像过期 | 检查上游 pass 的 PreservedAnalyses 是否谎报 |

下一章离开 pass 视角，进入"生产者"视角：用 IRBuilder 直接造 IR。
