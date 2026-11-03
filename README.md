# Guide 导航索引

这里汇总仓库中的 **69 个教程与专题**。总索引只负责帮助你找到入口；章节安排、工具链版本、运行方法和验证状态，以各目录自己的 `README.md` 为准。

## 按学习目标选择

不知道从哪里开始时，可以先按目标选择。下面的路径是阅读建议，不是强制依赖；同一阶段的教程通常可以按兴趣选读。

| 学习目标 | 推荐入口与进阶方向 |
| --- | --- |
| 学一门通用编程语言 | [C++](./cpp20)、[C#](./csharp)、[Go](./go)、[Rust](./rust)、[Swift](./swift)、[Kotlin](./kotlin)、[Zig](./zig) |
| 学算法与软件设计 | [数据结构](./datastruct) → [算法](./algorithm) → [设计模式](./designpattern)；C++ 生态可再读 [Boost](./boost) |
| 学系统与底层开发 | [x86-64 汇编](./asm/intel) → [编译原理与静态分析](./compiler) → [LLVM](./llvm)；异构计算另读 [OpenCL](./OpenCL) |
| 做桌面或跨平台界面 | C++ 选 [C++ GUI](./cppgui)，Rust 选 [Rust GUI/TUI](./rustgui)，Dart 选 [Flutter](./flutter)，Windows 另见 [WPF](./wpf)、[WinForms](./winforms) 与 [WinUI 3](./WinUI3) |
| 做移动或 Apple 平台应用 | Android 先读 [Kotlin](./kotlin) 再读 [Android](./android)；Apple 平台先读 [Swift](./swift)，再选 [iOS](./iosdev) 或 [macOS](./macosdev) |
| 学函数式、逻辑与并发编程 | [Haskell](./haskell)、[OCaml](./ocaml)、[SML](./sml) 是函数式主线；[Erlang](./erlang) 与 [Elixir](./elixir) 聚焦容错并发；[Prolog](./prolog) 聚焦逻辑编程 |
| 学证明助手与形式化方法 | 先按生态选择 [Lean 4](./lean4)、[Coq](./coq)、[Agda](./agda)、[Isabelle/HOL](./isabelle) 或 [HOL4](./hol4)，再进入具体数学专题 |
| 学数学与形式化理论 | [数理逻辑](./mathlogic) 与 [类型论](./typetheory) 是理论基础；[范畴论](./category)、[集合论](./settheory)、[测度论](./measuretheory)、[概率论](./probability) 和 [泛函分析](./funanalysis) 可独立选读 |

## 教程分类

### 编程语言与通用开发

| 教程 | 主要内容 |
| --- | --- |
| [Ada](./Ada) | 强类型、泛型、任务并发、契约式编程与 SPARK 验证 |
| [Algol 68](./algol68) | 正交类型、表达式、闭包、文件与经典并行特性 |
| [COBOL](./cobol) | GNU COBOL 数据描述、批处理、文件、报表与终端界面 |
| [C++20/23](./cpp20) | 现代 C++ 语言、标准库、模板、并发与协程 |
| [C#](./csharp) | C# 类型、LINQ、异步、元编程、内存与互操作 |
| [Dart](./dart) | Dart 类型、模式、空安全、异步、Isolate 与测试 |
| [D](./dlang) | UFCS、区间、模板元编程、内存模型与消息并发 |
| [.NET](./dotnet) | C#/.NET 应用开发、Web、数据访问、网络与并发 |
| [F#](./fsharp) | 函数式建模、计算表达式、异步与 .NET 互操作 |
| [Fortran](./fortran) | 现代 Fortran 数组、模块、数值计算、并行与 C 互操作 |
| [FreeBASIC](./freebasic) | BASIC 语言、图形、多线程、系统 API 与 QB 迁移 |
| [Free Pascal / Lazarus](./freepascal) | Object Pascal、Lazarus 控件、自绘与桌面应用实战 |
| [Go](./go) | Go 语言、并发、测试、网络服务与常用标准库 |
| [Julia](./julia) | 多重派发、数组广播、科学计算、性能与并行 |
| [Kotlin](./kotlin) | Kotlin 类型与协程、Flow、DSL、多平台与项目实战 |
| [PowerShell](./powershell) | 对象管道、脚本、远程管理、模块、测试与自动化 |
| [Ruby](./ruby) | Ruby 对象与块、Enumerable、元编程、并发和 C 互操作 |
| [Rust](./rust) | 所有权、Trait、生命周期、并发、异步与工程实践 |
| [Swift](./swift) | 可选类型、协议、ARC、严格并发与 SPM 工程 |
| [Zig](./zig) | 显式内存、comptime、构建互操作、网络与系统编程 |

### 函数式、逻辑与多范式编程

| 教程 | 主要内容 |
| --- | --- |
| [Clojure](./clojure) | 不可变数据、惰性序列、宏、并发与 JVM Web 生态 |
| [Common Lisp](./commonlisp) | Common Lisp、CLOS、宏、条件系统及 SBCL 双实现实践 |
| [Elixir](./elixir) | 函数式编程、进程、GenServer、监督树与容错应用 |
| [Emacs / Emacs Lisp](./emacs) | Emacs 使用、CC Mode 配置与 Elisp 扩展开发 |
| [Erlang / OTP](./erlang) | 函数式编程、监督树、分布式系统与并发工程 |
| [Forth](./forth) | 栈机、词典、元编程、多任务与解释器实现 |
| [Haskell](./haskell) | 惰性求值、类型类、单子、解析与函数式工程 |
| [Io](./io) | 原型对象、消息传递、元编程、协程、Actor 与 FFI |
| [OCaml](./ocaml) | 函数式与模块系统、GADT、对象、并发与效应 |
| [Prolog](./prolog) | 合一回溯、DCG、约束、元编程与解释器实现 |
| [Standard ML](./sml) | 类型、模块函子、数据抽象、惰性与续延 |

### 算法、系统与底层工程

| 教程 | 主要内容 |
| --- | --- |
| [算法](./algorithm) | 以 CLRS 为主线，学习算法原理、正确性证明、复杂度与 C++ 实现 |
| [x86-64 汇编](./asm/intel) | 指令、调用约定、SIMD、异常同步与引导链 |
| [Boost](./boost) | 沿 C++ 标准演进学习 Boost 各库及其实际应用 |
| [编译原理与静态分析](./compiler) | 编译前端、优化、静态分析、抽象解释与后端实现 |
| [数据结构](./datastruct) | 用 C++ 手写线性表、树、图、排序及算法设计策略 |
| [设计模式](./designpattern) | 设计原则、经典模式、现代 C++ 写法及综合应用 |
| [LLVM](./llvm) | LLVM IR、Pass、IRBuilder、JIT 与玩具编译器 |
| [OpenCL](./OpenCL) | GPU 异构计算、内核编程、并行算法与性能优化 |

### 桌面、移动、GUI 与游戏

| 教程 | 主要内容 |
| --- | --- |
| [Android](./android) | Android 双 UI 范式、系统能力、原生开发与完整应用 |
| [C++ GUI/TUI](./cppgui) | 用四类 C++ 框架对照学习不同界面范式 |
| [Flutter](./flutter) | Widget、布局、状态管理、平台通道与发布 |
| [Godot](./godot) | GDScript、节点场景、信号、帧循环、异步与游戏实战 |
| [iOS](./iosdev) | iOS 原生双 UI、运行时、系统框架、持久化与发布 |
| [macOS](./macosdev) | AppKit、Objective-C、Cocoa Bindings、XIB 与打包 |
| [MFC](./mfc) | 消息映射、控件、文档视图、绘图及系统扩展 |
| [Ren'Py](./renpy) | 视觉小说脚本、画面、交互、存档与工程组织 |
| [Rust GUI/TUI](./rustgui) | 用五种 Rust 框架对照学习即时、声明式与保留式 UI |
| [SDL2](./sdl2) | 用 C++ 学习窗口渲染、事件、计时、音频、线程与 RAII |
| [Win32](./win32) | Win32 窗口控件及进程、内存、DLL、COM 与系统服务 |
| [WinForms](./winforms) | 用三种语言学 WinForms 控件、GDI+、绑定、数据与部署 |
| [WinUI 3](./WinUI3) | 用 C++/WinRT 学习控件、MVVM、系统整合与交付 |
| [WPF](./wpf) | 用三种语言学 XAML、绑定、MVVM、模板、图形与发布 |

### 证明助手与形式化方法

| 教程 | 主要内容 |
| --- | --- |
| [Agda](./agda) | 以依赖类型贯通函数式编程、定理证明与可验证算法 |
| [Coq / Rocq](./coq) | 从基础证明进入算法验证、语言理论、分离逻辑与安全 |
| [Coq-HoTT](./coq-hott) | 从路径与等价理解泛等、高阶归纳类型及同伦数学 |
| [HOL4](./hol4) | 从 LCF 内核与 ML 战术一路学到编译器正确性证明 |
| [Isabelle/HOL](./isabelle) | Isar、自动化、对象逻辑与形式化数学 |
| [Lean 4 / Mathlib](./lean4) | Lean 4 编程与证明、Mathlib 数学库及元编程 |
| [seL4](./sel4) | 用 Isabelle/HOL 学习能力模型、内核规范、精化与安全定理 |
| [TLA+](./tla) | 状态规格、时序性质、PlusCal 与 TLC 模型检查 |

### 数学、逻辑与形式化理论

| 教程 | 主要内容 |
| --- | --- |
| [范畴论](./category) | 从范畴、函子、极限与伴随一路学到层和拓扑斯 |
| [泛函分析](./funanalysis) | 以机器证明、离散模型和数值实验互证泛函分析 |
| [数理逻辑](./mathlogic) | 命题、一阶逻辑、证明论、模型论、可计算性与模态逻辑 |
| [测度论](./measuretheory) | 从测度与积分进入乘积空间、拓扑测度、鞅和极限定理 |
| [概率论](./probability) | 概率模型、渐近推断、GMM 与经典回归的 44 章研究生教程（洪永淼主线 + Miller 计算证明传统） |
| [集合论（冯琦）](./settheory) | 研究生向集合论，深入力迫、大基数、内模型与描述集合论 |
| [集合论教程（郝兆宽·杨跃）](./settheory-hao) | 入门集合论，从 ZFC、序数与基数学到可构成集与力迫 |
| [类型论](./typetheory) | 从 λ 演算进入依赖类型、Martin-Löf、现代类型论与同伦 |

## A–Z 完整索引

已经知道教程或目录名称时，直接按名称查找。

- **A–C**：[`Ada`](./Ada) · [`agda`](./agda) · [`algol68`](./algol68) · [`algorithm`](./algorithm) · [`android`](./android) · [`asm/intel`](./asm/intel) · [`boost`](./boost) · [`category`](./category) · [`clojure`](./clojure) · [`cobol`](./cobol) · [`commonlisp`](./commonlisp) · [`compiler`](./compiler) · [`coq`](./coq) · [`coq-hott`](./coq-hott) · [`cpp20`](./cpp20) · [`cppgui`](./cppgui) · [`csharp`](./csharp)
- **D–F**：[`dart`](./dart) · [`datastruct`](./datastruct) · [`designpattern`](./designpattern) · [`dlang`](./dlang) · [`dotnet`](./dotnet) · [`elixir`](./elixir) · [`emacs`](./emacs) · [`erlang`](./erlang) · [`flutter`](./flutter) · [`forth`](./forth) · [`fortran`](./fortran) · [`freebasic`](./freebasic) · [`freepascal`](./freepascal) · [`fsharp`](./fsharp) · [`funanalysis`](./funanalysis)
- **G–L**：[`go`](./go) · [`godot`](./godot) · [`haskell`](./haskell) · [`hol4`](./hol4) · [`io`](./io) · [`iosdev`](./iosdev) · [`isabelle`](./isabelle) · [`julia`](./julia) · [`kotlin`](./kotlin) · [`lean4`](./lean4) · [`llvm`](./llvm)
- **M–P**：[`macosdev`](./macosdev) · [`mathlogic`](./mathlogic) · [`measuretheory`](./measuretheory) · [`mfc`](./mfc) · [`ocaml`](./ocaml) · [`OpenCL`](./OpenCL) · [`powershell`](./powershell) · [`probability`](./probability) · [`prolog`](./prolog)
- **R–T**：[`renpy`](./renpy) · [`ruby`](./ruby) · [`rust`](./rust) · [`rustgui`](./rustgui) · [`sdl2`](./sdl2) · [`sel4`](./sel4) · [`settheory`](./settheory) · [`settheory-hao`](./settheory-hao) · [`sml`](./sml) · [`swift`](./swift) · [`tla`](./tla) · [`typetheory`](./typetheory)
- **W–Z**：[`win32`](./win32) · [`winforms`](./winforms) · [`WinUI3`](./WinUI3) · [`wpf`](./wpf) · [`zig`](./zig)

## 使用与验证

1. 从分类索引或 A–Z 索引进入教程目录。
2. 先读该目录的 `README.md`，确认所需工具链、支持平台、章节入口和验证范围。
3. 按教程说明构建或运行示例；不要把某一教程的环境变量和依赖版本直接套用到另一个教程。

常见目录结构如下，各教程会按技术栈适当调整：

```text
<topic>/
├── README.md       # 教程入口、环境要求与验证状态
├── docs/           # 分章正文（如采用分章结构）
├── examples/       # 独立示例或工程
├── build.ps1       # 常见 Windows 构建入口
└── run-all.sh      # 常见 macOS / Linux 构建入口
```

Windows 上常见命令为 `pwsh -File build.ps1`，macOS / Linux 上常见命令为 `./run-all.sh`；实际参数和是否提供这两个脚本，以各教程说明为准。

## 维护原则

- 总索引保留简短摘要，不复制完整章目、工具链版本和逐项验证记录。
- 新增或扩充教程时，详细变化写入对应目录的 `README.md`。
- 新增教程入口时，同时更新合适的分类和 A–Z 索引，并检查相对链接。
- 可运行示例与可复现验证仍是教程内容的基本要求。
