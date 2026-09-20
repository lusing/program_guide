# 23 · LLVM 源码导览：把仓库变成你的地图

> 对应示例：`examples/23_source_tour/run.ps1`（对 `G:\github\lang\llvm-project` 的只读寻宝）

用别人的库到深处，迟早要读它的源码。本章带你把 **llvm-project monorepo**（本机检出：主干 ≥24 时代）走一遍——每个地标都对应本教程前面某一章的实操。脚本会跑 7 组断言，全部 `[found]` 即通过。

## 23.1 monorepo 布局：一个仓库住下所有项目

```text
llvm-project/
├── llvm/        ← 编译器本体（本教程全部内容的家）
├── clang/       ← C/C++ 前端（tools extra/ 里有 clangd、clang-tidy）
├── clang-tools-extra/
├── lld/         ← 链接器
├── lldb/        ← 调试器
├── flang/       ← Fortran 前端
├── mlir/        ← 多层 IR 基础设施
├── polly/  libcxx/  libunwind/  …
└── runtimes/    ← 运行时族
```

单一仓库统一构建、原子提交（clang 改 IR 接口，llvm 侧配套修改同一个 commit）——这是 2019 年从多仓合并来的决策。

## 23.2 你已经用过的类，源码都在哪

| 本书章节 | 你用过的 API | 源码位置（llvm/ 下） |
|---|---|---|
| 2/3 | Module、文本 IR 语法 | `include/llvm/IR/Module.h` + `lib/IR/AsmWriter.cpp`（打印）`lib/AsmParser/`（解析） |
| 8 | IRBuilder | `include/llvm/IR/IRBuilder.h` + `lib/IR/IRBuilder.cpp` |
| 8/13 | Function / BasicBlock | `include/llvm/IR/Function.h`、`BasicBlock.h` |
| 9 | Value/User/Use | `include/llvm/IR/Value.h`、`User.h`、`Use.h`——**读懂这三个头，LLVM 的 C++ 就入门了** |
| 4 | PHINode | `include/llvm/IR/Instructions.h` |
| 6/7/17/19 | PassBuilder / PassInfoMixin | `include/llvm/Passes/PassBuilder.h` + `lib/Passes/PassBuilder.cpp`（所有标准 pass 的装配处） |
| 6 | PassPlugin（插件协议） | **`include/llvm/Plugins/PassPlugin.h`**（22+ 的新家） |
| 11/14 | ORC LLJIT | `include/llvm/ExecutionEngine/Orc/LLJIT.h` + `lib/ExecutionEngine/Orc/` |
| 20 | TargetMachine / TargetRegistry | `include/llvm/MC/TargetRegistry.h` + `lib/Target/X86/`（x86 后端一个目录一个目标） |
| 21 | FileCheck | `llvm/utils/FileCheck/`（有趣：它自己是个小 TableGen 项目） |
| 1/5 | opt/lli/llc 命令行 | `llvm/tools/opt/`、`tools/lli/`、`tools/llc/`——每个都是 <1000 行的薄壳 |

源码树导航的黄金习惯：**从 include/llvm/ 的头文件进，Ctrl 到 lib/ 的同名 .cpp 看 实现**；对工具则直接读 tools/<名>/<名>.cpp 的 main()。

## 23.3 版本差异：老教程/旧源码 → 现代 LLVM 对照表

本机这份主干（≥24）与 2015-2020 年的教材/源码差异，恰好是本书一路踩过的坑的汇总：

| 主题 | 旧世界（≤ LLVM 14，老教程） | 新世界（15+，本书实测 22） |
|---|---|---|
| 指针 | 类型化指针 `i32*`、`%T*` | 不透明 `ptr`，类型在使用处声明（2/3 章） |
| bitcast 指针 | `bitcast i8* to i32*` 满天飞 | 基本消失（8 章） |
| ConstantExpr | `ConstantExpr::getGetElementPtr` 常用 | **21 起删除**；全局直接当 ptr（8 章） |
| PassManager | `FunctionPass`/`RegisterPass`/`runOnFunction` | PassInfoMixin + run() + PreservedAnalyses（6 章） |
| pass 注册 | `RegisterPass<X>` 静态对象 | PassBuilder 回调（registerPipelineParsingCallback 等） |
| 插件协议头 | `llvm/Passes/PassPlugin.h` | **`llvm/Plugins/PassPlugin.h`**（6 章；主干已验证） |
| EP 回调签名 | 两参数 (MPM, Level) | 三参数，多了 ThinOrFullLTOPhase（7 章） |
| 自定义 Analysis | 手写 ID 样板 | AnalysisInfoMixin + static Key（7 章） |
| 解析 IR | `parseIR(unique_ptr<MemoryBuffer>)` | `parseIR(MemoryBufferRef)`（11 章）；外部函数必须 declare |
| JIT 宿主符号 | MCJIT 时代 dlsym 天下大同 | LLJIT：宿主函数 dllexport；`J->lookup` 只搜 Main（11/14 章） |
| 块挂载 | Create 后 `getFunctionList().push_back` | Create 时传 F；push_back 路已私有（13 章） |
| GetInsertPoint | 返回 BasicBlock* | 返回迭代器；块指针用 GetInsertBlock（13 章） |
| CloneFunction | 返回后需手动入模块 | **自动入模块**，再 push_back 会损坏链表（9 章） |
| lookupTarget | 收 StringRef | 收 `const Triple&`；Host.h 从 Support 搬到 TargetParser（20 章） |
| 代码生成 emit | `legacy::PassManager` | 仍是 legacy PM（迁移未完，20 章） |
| opt 旗标 | `-sroa -instcombine` | `-passes=` 管线语言（5 章） |

读老材料时的换算心法：**看到 `i32*` 换 `ptr`；看到 `FunctionPass` 换 `PassInfoMixin`；看到 `Passes/PassPlugin.h` 换 `Plugins/`**——九成旧文就能继续用。

## 23.4 想构建源码？（超出本书范围的一页纸）

```bash
# 需求：cmake ≥3.20、ninja、约 30GB 磁盘与数小时（32GB 内存更舒适）
cd llvm-project
cmake -B build -G Ninja llvm/ -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_PROJECTS="clang;lld" -DLLVM_ENABLE_ASSERTIONS=ON
ninja -C build opt lli clang   # 只造要玩的工具，省大量时间
```

阅读源码不必构建：静态阅读 + 对着 22 版工具实测（本书路线）性价比最高。真要上手改 LLVM 时再构建——那时你已经知道自己要动哪个文件了。

## 23.5 导览脚本实测

（run.ps1 实测输出节选）：

```text
== 版本确认 ==
  HEAD: fa360c3b8dbf [ConstraintElim] Simplify all overflow intrinsics ...
== 地标 4：PassPlugin 的现代位置 ==
  [found] llvm/Plugins/PassPlugin.h（22+ 的家；老教程的 llvm/Passes/PassPlugin.h 已不存在）
== 规模感 ==
  llvm/lib/IR: 26 个 .cpp；include/llvm/IR: 79 个 .h
==== 23 ok ====
```

## 23.6 本章小结

- monorepo = llvm/clang/lld/lldb/mlir 同仓共生；include→lib 成对导航。
- Value/User/Use 三头是 C++ API 的钥匙；工具是薄壳，读 main()。
- 新旧对照表是读老教材的换算器；本书 24 章踩坑清单与其互为索引。

下一章收官：MiniLang v1.0 全模式回归 + 全书坑位总账。
