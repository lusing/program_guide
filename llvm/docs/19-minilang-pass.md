# 19 · 自定义 Pass 接入 MiniLang

> 对应示例：`examples/19_minilang_pass/`（minilang.cpp v0.8 + test.mini）

编译器做完功能，最后的问题是**怎么知道它生成了什么、优化器对它做了什么**。本章把第 6/7 章的 pass 技能搬进 minilang 进程内：一个 `ml-stats` 统计 pass，经 `registerPipelineParsingCallback` 挂进 `-passes=` 语言，对自产 IR 做前后对照。**不离开进程、不落盘、不依赖插件 dll**——这是真实编译器（rustc 的 `-Ztime-passes`、clang 的插件）观察自身的姿势。

## 19.1 进程内 pass 三件套

```cpp
namespace mlstats {
struct FnStats : PassInfoMixin<FnStats> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    unsigned Blocks=0, Insts=0, Allocas=0, Loads=0, Stores=0, Calls=0;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) { Insts++; /* isa<AllocaInst> 等分类计数 */ }
    outs() << "ml-stats: " << F.getName() << " ...\n";
    return PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }   // 打印型 pass 防淘汰
};
} // namespace mlstats
```

与第 6 章 HelloPass 的唯一区别：它**编译进程序**而不是做成 dll。接线方式完全同款：

```cpp
PassBuilder PB;
PB.registerPipelineParsingCallback(
    [](StringRef Name, FunctionPassManager &FPM,
       ArrayRef<PassBuilder::PipelineElement>) {
      if (Name == "ml-stats") { FPM.addPass(mlstats::FnStats()); return true; }
      return false;
    });
// 四件套注册 + crossRegisterProxies（第 17 章同款骨架）
ModulePassManager MPM;
PB.parsePassPipeline(MPM, "function(ml-stats)");   // 解析管线字符串
MPM.run(*M, MAM);
```

`parsePassPipeline` 是 `opt -passes=` 的内核暴露给库用户——你自己的编译器 thus 获得了"管线语言"的全部表达力（`function(mem2reg,ml-stats)` 这样的组合信手拈来）。

## 19.2 实测：mem2reg 前后对照

`minilang --stats test.mini`（实测输出）：

```text
== before mem2reg ==
ml-stats: fib bb=4 insts=19 alloca=1 load=4 store=1 call=2
ml-stats: sum_to bb=4 insts=24 alloca=3 load=6 store=5 call=0
ml-stats: unary- bb=1 insts=5 alloca=1 load=1 store=1 call=0
ml-stats: __anon0 bb=1 insts=3 alloca=0 load=0 store=0 call=2
...
== after mem2reg ==
ml-stats: fib bb=4 insts=13 alloca=0 load=0 store=0 call=2
ml-stats: sum_to bb=4 insts=12 alloca=0 load=0 store=0 call=0
ml-stats: unary- bb=1 insts=2 alloca=0 load=0 store=0 call=0
...
==== 19 ok ====
```

三组数字讲完第 15 章的全部理论：

- **fib**：1 个参数槽（n）被提升，4 次 load 归零，指令 19→13；
- **sum_to**：3 个槽（acc/i/参数 n）、6 load 5 store 全洗掉，指令 24→12；
- **unary-**：5 条指令缩到 2 条（load+store 没了，剩 fsub 与 ret）。

而 `__anon*`/`main` 没有局部变量，前后无差——pass 的作用域精确性可见。

## 19.3 与外部工具链的配合

进程内 pass 适合"编译器自知"；**跨工具观察**还是第 6/7 章的插件路线。两线互补的典型工作流：

```powershell
# 我们的编译器自审
minilang --stats test.mini

# 导出 IR 交给上游工具（第 5/6 章）
minilang --ir test.mini out.ll
opt -load-pass-plugin=InstStats.dll '-passes=inst-stats,mem-stats' out.ll -disable-output
opt -O2 out.ll -S -o out.O2.ll        # 再看优化后的形态
```

build 脚本把 `--stats` 的两段输出都纳入断言（before 必须有非零 alloca、after 必须全零）——**回归测试挂在了观察哨上**，前端改动若破坏 mem2reg 的前提（比如 alloca 逃逸），立刻红灯。

## 19.4 扩展方向（习题）

1. 给 FnStats 加"平均指令/块"与函数体积排名；
2. 写 `ml-instrument`：在每个函数入口插 `call void @ml_enter(i32 %id)` 计数调用（需要 `IRBuilder` 插指令 + 宿主侧计数器——第 11 章的 dllexport 回头客）；
3. 挂到第 17 章的 IRTransformLayer 里，`-O2` 前后各跑一次统计，输出差值报表。

## 19.5 本章小结

- pass 编译进程序 = 无 dll 依赖的自审能力；`parsePassPipeline` 让编译器拥有管线语言。
- 前后对照的量化数据（19→13、24→12、5→2）是 alloca 策略正确性的活体证明。
- 观察哨进回归：统计输出变成断言，前端回归提前暴露。

| 坑 | 解法 |
|---|---|
| pass 被静默跳过 | isRequired() 返回 true |
| 管线字符串解析失败 | parsePassPipeline 返回 Error，别忽略 |
| 想在 -O2 里自动统计 | 挂 EP 或 IRTransformLayer（第 7/17 章） |

下一章冲线：从 MiniLang 直接编出原生 `.exe`。
