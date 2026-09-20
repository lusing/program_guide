# LLVM 开发指南（22.x，应用开发向）

面向**会 C/C++、初学 LLVM** 的读者：不造编译器零件，学**把 LLVM 当库用**——读懂与手写 IR、写出自己的优化 Pass、用 C++ API 生成与变换代码、跑 ORC JIT，最后从零做一个完整玩具语言编译器 MiniLang（词法 → 语法 → IR → 优化 → JIT → 原生 `.exe`）。全部示例在 **Windows MSYS2 UCRT64 + LLVM 22.1.8** 实测通过，每章坑位清单只收真踩过的坑。

> ⚠️ 版本与工具链警告：LLVM 迭代快、破坏性变更多（指针形态、PassManager、头文件路径都换过）。本教程所有代码在 **MSYS2 UCRT64 的 LLVM 22.1.8** 实测；网上大量教程还是类型化指针（≤14）、旧 PassManager 或 `llvm/Passes/PassPlugin.h` 时代的写法，直接照抄编译不过。另：scoop 的 llvm 包是精简版（无 opt/lli/llvm-config/开发库），做不了本教程的实操——工具链就位见 [01 章检查清单](docs/01-overview.md)。

## 目录结构

```text
llvm/
├── README.md        本文件
├── docs/            24 章教程（01 → 24 顺序阅读）
├── examples/        24 个示例目录（章号 = 目录号；12-20/24 为 MiniLang 渐进版）
├── build.ps1        统一验证脚本（须 PowerShell 7 / pwsh 运行）
└── CHEATSheet.md    命令速查 + 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | LLVM 是什么、生态、三套本机工具链就位 | `01_overview` |
| [02 第一个手写 IR](docs/02-first-ir.md) | Module 结构、@/%、lli 执行、llvm-as/dis | `02_first_ir` |
| [03 类型系统](docs/03-ir-types.md) | 聚合类型、全局/常量、GEP 完全指南、ptr | `03_ir_types` |
| [04 SSA 与 phi](docs/04-ssa-phi.md) | 基本块、phi、alloca 风格、mem2reg | `04_ssa_phi` |
| [05 优化管线](docs/05-opt-pipeline.md) | opt、-O 系列、-passes= 语法、属性契约 | `05_opt_pipeline` |
| [06 ⭐第一个 Pass](docs/06-hello-pass.md) | 新 PassManager 插件、llvmGetPassPluginInfo | `06_hello_pass` |
| [07 ⭐Pass 进阶](docs/07-pass-analysis.md) | 自定义 Analysis、管线注册、pass 参数 | `07_pass_analysis` |
| [08 ⭐IRBuilder](docs/08-irbuilder.md) | C++ API 生成 IR、Module/Function/Block | `08_irbuilder` |
| [09 ⭐Value 对象模型](docs/09-value-model.md) | isa/dyn_cast、Use 链、replaceAllUsesWith | `09_value_model` |
| [10 代码生成](docs/10-codegen.md) | llc、目标三元组、DataLayout、交叉编译 | `10_codegen` |
| [11 ⭐ORC JIT](docs/11-orc-jit.md) | LLJIT、增量编译、宿主函数互调 | `11_orc_jit` |
| [12 ⭐MiniLang 前端](docs/12-minilang-front.md) | 词法、递归下降、AST | `12_minilang_front` |
| [13 ⭐AST→IR](docs/13-minilang-ir.md) | 表达式/if/for 代码生成 | `13_minilang_ir` |
| [14 函数与原型](docs/14-minilang-funcs.md) | def/extern、JIT 增量定义、递归 | `14_minilang_funcs` |
| [15 变量与可变状态](docs/15-minilang-vars.md) | alloca 模式、for 变量、作用域 | `15_minilang_vars` |
| [16 运算符扩展](docs/16-minilang-ops.md) | 表驱动解析、一元、自定义运算符 | `16_minilang_ops` |
| [17 ⭐优化层接入](docs/17-minilang-opt.md) | JIT 前置 -O2 管线、内联 | `17_minilang_opt` |
| [18 控制流进阶](docs/18-minilang-cf.md) | if/else 表达式化、逻辑短路、while | `18_minilang_cf` |
| [19 自定义 Pass 接入](docs/19-minilang-pass.md) | instrumentation + 导出 IR 给 opt | `19_minilang_pass` |
| [20 ⭐⭐原生编译](docs/20-minilang-native.md) | .o 生成、lld/clang 链接出 .exe | `20_minilang_native` |
| [21 测试](docs/21-filecheck.md) | FileCheck 语法、回归测试组织 | `21_filecheck` |
| [22 clang 工具链](docs/22-clang-tools.md) | ast-dump、clang-format/tidy/clangd | `22_clang_tools` |
| [23 LLVM 源码导览](docs/23-source-tour.md) | 源码树地图、v10↔v22 差异表 | `23_source_tour` |
| [24 ⭐⭐MiniLang v1.0](docs/24-minilang-full.md) | CLI 三模式、外部函数、回归+全书坑清单 | `24_minilang_full` |

## 构建工具链

- **MSYS2 UCRT64 LLVM 22.1.8**（`G:\scoop\apps\msys2\current\ucrt64`，scoop msys2 + pacman 包）：opt/lli/llc/llvm-config/FileCheck + g++ 16.2 + 完整 libLLVM——**主线工具链**，所有示例验证基于它。
- scoop LLVM 23.1.1：仅第 22 章（clang 前端工具），ABI 与主线不互通。
- 源码参考 `G:\github\lang\llvm`（v10 时代）：仅第 23 章阅读用。
- 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8）。

## 验证命令

```powershell
cd G:\code\guide\llvm
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全部示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_first_ir  # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 清理 build 目录
```

判定标准：每步命令退出码 0；可运行示例打印结束标记 `==== NN ok ====`。

## 相关教程

C++ 基础见 [cpp20](../cpp20/README.md)；本仓库 Zig 教程的 LLVM 后端视角见 [zig](../zig/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
