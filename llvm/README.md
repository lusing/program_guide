# LLVM 开发指南（22.x，应用开发向）

面向**会 C/C++、初学 LLVM** 的读者：不造编译器零件，学**把 LLVM 当库用**——读懂与手写 IR、写出自己的优化 Pass、用 C++ API 生成与变换代码、跑 ORC JIT，最后从零做一个完整玩具语言编译器 MiniLang（词法 → 语法 → IR → 优化 → JIT → 原生可执行文件）。每章坑位清单只收真踩过的坑。

**双平台实测**：示例在 **Windows MSYS2 UCRT64 + LLVM 22.1.8**（`build.ps1`）与 **macOS 13 x86_64 + MacPorts LLVM 23.1.0**（`run-all.sh`）两侧都全绿。macOS 侧是 24 个示例里 24 通过（第 23 章需自备源码检出，见下）。

> ⚠️ 版本与工具链警告：LLVM 迭代快、破坏性变更多（指针形态、PassManager、头文件路径都换过）。本教程所有代码在 **22.1.8 / 23.1.0** 实测；网上大量教程还是类型化指针（≤14）、旧 PassManager 或 `llvm/Passes/PassPlugin.h` 时代的写法，直接照抄编译不过。另：scoop 的 llvm 包是精简版（无 opt/lli/llvm-config/开发库），做不了本教程的实操——工具链就位见 [01 章检查清单](docs/01-overview.md)。

## 目录结构

```text
llvm/
├── README.md        本文件
├── docs/            24 章教程（01 → 24 顺序阅读）
├── examples/        24 个示例目录（章号 = 目录号；12-20/24 为 MiniLang 渐进版）
├── tools/           macOS 侧补丁：FileCheck 最小驱动（MacPorts 不装该可执行文件）
├── build.ps1        Windows 验证脚本（PowerShell 7 / pwsh）
├── run-all.sh       macOS/Linux 验证脚本（bash，判定与 build.ps1 逐项对齐）
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
| [20 ⭐⭐原生编译](docs/20-minilang-native.md) | .o 生成、clang 链接出可执行文件 | `20_minilang_native` |
| [21 测试](docs/21-filecheck.md) | FileCheck 语法、回归测试组织 | `21_filecheck` |
| [22 clang 工具链](docs/22-clang-tools.md) | ast-dump、clang-format/tidy/clangd | `22_clang_tools` |
| [23 LLVM 源码导览](docs/23-source-tour.md) | monorepo 地图、新旧版本对照表 | `23_source_tour` |
| [24 ⭐⭐MiniLang v1.0](docs/24-minilang-full.md) | CLI 三模式、外部函数、回归+全书坑清单 | `24_minilang_full` |

## 构建工具链

### Windows（主线）

- **MSYS2 UCRT64 LLVM 22.1.8**（`G:\scoop\apps\msys2\current\ucrt64`，scoop msys2 + pacman 包）：opt/lli/llc/llvm-config/FileCheck + g++ 16.2 + 完整 libLLVM。
- scoop LLVM 23.1.1：仅第 22 章（clang 前端工具），ABI 与主线不互通。
- 源码参考 `G:\github\lang\llvm-project`（monorepo 主干）：第 23 章导览用。
- 中文控制台乱码先 `chcp 65001`（build.ps1 已代设 UTF-8）。

### macOS（本机实况：Darwin 23 x86_64）

- **MacPorts LLVM 23.1.0**（`/opt/local/libexec/llvm-23`）：opt/lli/llc/llvm-as/llvm-dis/llvm-config/clang + libLLVM（动态库与 742 个组件静态库齐备）。**注意 MacPorts 上只有 19.1.7 / 21.1.8 / 23.1.0，没有 22**；选 23 的判据是头文件布局——`llvm/Plugins/PassPlugin.h`（22 的新家）在 23 就位，21 还是老位置 `llvm/Passes/PassPlugin.h`，第 6/7 章的插件在 21 上直接编不过。
- C++ 编译器：`/opt/local/bin/clang++-mp-23`（内部走 xcrun，自动带 SDK；`llvm-config --cxxflags` 带 `-stdlib=libc++`，别用系统 g++）。
- 第二套 LLVM 21.1.8：第 22 章的跨版本 IR 互通（clang 23 产 IR → lli 21 执行）。
- 源码参考：`LLVM_SRC=/Volumes/mac004/lang/llvm-project`（从官方 `llvm-project-23.1.0.src.tar.xz` 解开需要的子树，约 52 MB）。
- ⚠️ **MacPorts 的 llvm-2x 不装 FileCheck 可执行文件**（只有 `libLLVMFileCheck.a` + `llvm/FileCheck/FileCheck.h`）。`run-all.sh` 检测不到时会自动用官方库链一个驱动（`tools/filecheck_main.cpp`），语义与真的 FileCheck 一致。

## 验证命令

```powershell
# Windows
cd G:\code\guide\llvm
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全部示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_first_ir  # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 清理 build 目录
```

```bash
# macOS / Linux
cd /Volumes/mac004/code/programming/llvm
./run-all.sh                       # 全部示例（约 5-6 分钟，静态链较慢）
./run-all.sh 06 11                 # 只跑指定章号（也可写完整目录名）
./run-all.sh -v                    # 附带每个步骤的完整输出
LLVM_SRC=/path/to/llvm-project ./run-all.sh 23   # 第 23 章需要源码检出
```

判定标准（两侧一致）：每步命令退出码 0；可运行示例打印结束标记 `==== NN ok ====`。
`run-all.sh` 另有两条本侧加强，见文件头注释：

- **编译日志必须为空**：`-Wall -Wextra -isystem <llvm include>` 下 clang 成功时零输出，日志非空 = 有告警 = 失败（`-isystem` 是必须的，否则 LLVM 自己的头文件会刷屏把示例的告警淹掉）。这条抓到过 MiniLang 里一个没用到的 `BasicBlock *LBB`。
- **双通道产物输出逐字节一致**：每个链 LLVM 的示例都编两份——shared（链 `libLLVM-23.dylib`）与 static（链几十个组件 `.a`），输出不同即失败。

## 平台差异速查表

| 事项 | Windows | macOS |
|---|---|---|
| 插件产物 | `HelloPass.dll` | `HelloPass.so`（插件只走 `--link-shared`） |
| 可执行文件 | `demo.exe` | `demo`（无扩展名约定） |
| 原生 obj 格式 | COFF（`x86_64-w64-windows-gnu`） | Mach-O（`x86_64-apple-darwin23.6.0`），同一份代码零改动 |
| JIT 宿主函数导出 | `__declspec(dllexport)` | `__attribute__((visibility("default")))`（示例用宏统一） |
| 进程符号查询名 | `host_mul` | 需带全局前缀 `_host_mul`（`getDataLayout().getGlobalPrefix()`） |
| 本机汇编乘法助记符 | `imul` | x86_64 → `imul`；arm64 → `mul`（断言随 `uname -m` 走） |
| clang 找系统头 | `-target x86_64-pc-windows-gnu -isystem <ucrt64 include>` | `-isysroot $(xcrun --show-sdk-path)` |
| 跨版本 IR 互通 | scoop clang 23 → MSYS2 lli 22 | clang 23 → lli 21 |
| FileCheck | MSYS2 自带 | 需自链（见 tools/） |
| `OptimizationLevel` | 22：类 + `getSpeedupLevel()` | 23：裸 `enum class`（示例用 `atLeastO2()` 兼容两者） |
| 第 23 章源码 | `G:\github\lang\llvm-project` | `LLVM_SRC` 环境变量指定 |

## 相关教程

C++ 基础见 [cpp20](../cpp20/README.md)；本仓库 Zig 教程的 LLVM 后端视角见 [zig](../zig/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)（收录 34 条实测坑位，其中 10 条是 macOS 侧新增）。
