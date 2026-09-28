# C# 语言教程

一套以**语言本身**为主线的 C# 系统教程：**45 章正文 + 45 个可编译可运行的示例**（章号=示例号，net10.0 控制台，零 NuGet 依赖离线可复现）。主线 36 章收束于一个能跑的表达式解释器实战；**书本实践篇（37-42）按四本参考书扩充**——集合体系与选型（三本教材的共讲专题）+《Effective C#（第 3 版）》50 条全落位；**查缺补漏篇（43-45）按另五本教材补齐**——常用工具类型、预处理指令与代码组织、XML。所有示例在 .NET 10 SDK 上编译并逐一运行验证（Windows 与 macOS 双平台实测，输出即讲解内容），语言特性声明（含 C# 14 扩展成员）均经实测编译确认。

与同仓库其他教程的分工：**csharp 深挖语言 → [dotnet](../dotnet) 用语言建平台应用（Web/EF/测试）→ [wpf](../wpf) 用语言建桌面界面**。

## 快速开始

`build.ps1` 会自动探测 PATH 中的 `dotnet`（也可用环境变量 `DOTNET_EXE` 指定），需 PowerShell 7（`pwsh`）运行，三平台通用：

```bash
cd csharp
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                       # 编译全部 45 个示例（集中产物到 build/）
pwsh -ExecutionPolicy Bypass -File build.ps1 -Run                       # 编译 + 逐个运行（每个示例输出讲解内容，零交互）
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 36_minilang       # 只构建某一个
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 36_minilang -Run  # 只构建并运行某一个
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                     # 清理集中构建目录
```

> Windows PowerShell 下等价写法：`.\build.ps1 -All`（若报"禁止运行脚本"，改用 `pwsh -ExecutionPolicy Bypass -File build.ps1 -All`）。

单跑某个示例（任意平台）：

```bash
cd examples/16_linq_basic
dotnet run
```

## 目录结构

```text
csharp/
├── README.md                  # 本文件
├── build.ps1                  # 一键构建/运行脚本（须 PowerShell 7 / pwsh 运行，三平台通用）
├── docs/                      # 45 章正文（01 → 45 顺序阅读）
└── examples/                  # 45 个示例（NN_名字/XxxConsole.csproj + Program.cs，零 NuGet 依赖）
```

## 章节索引

### 一 · 起步（01-04）

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | C#、.NET、CLR、BCL 各是什么 | `01_overview` |
| [02 工具链](docs/02-toolchain.md) | SDK、dotnet CLI、第一个程序 | `02_toolchain` |
| [03 变量与运算符](docs/03-variables-operators.md) | 类型、字面量、运算符全景 | `03_variables_operators` |
| [04 流程控制与方法](docs/04-control-methods.md) | 分支/循环五种形态、参数五形态、局部函数 | `04_control_methods` |

### 二 · 类型系统（05-12）

| 章 | 主题 | 示例 |
|---|---|---|
| [05 值与引用](docs/05-value-reference.md) | 栈/堆、装箱实测、相等语义 | `05_value_reference` |
| [06 字符串](docs/06-strings.md) | 不可变、驻留、插值、编码陷阱 | `06_strings` |
| [07 数组与枚举](docs/07-arrays-enums.md) | 多维/交错数组、Array 类、enum | `07_arrays_enums` |
| [08 类与封装](docs/08-classes.md) | 字段/属性、构造、static、索引器 | `08_classes` |
| [09 继承](docs/09-inheritance.md) | 虚方法、抽象类、多态、object 合同 | `09_inheritance` |
| [10 接口](docs/10-interfaces.md) | 默认实现、显式实现、DI 思想 | `10_interfaces` |
| [11 结构体与记录](docs/11-records.md) | struct 语义、record 全家、解构 | `11_records` |
| [12 泛型](docs/12-generics.md) | 约束家族、装箱账单、协变逆变 | `12_generics` |

### 三 · 函数式与数据（13-19）

| 章 | 主题 | 示例 |
|---|---|---|
| [13 委托](docs/13-delegates.md) | 委托类型、多播、Func/Action | `13_delegates` |
| [14 事件](docs/14-events.md) | 事件模型、解订防泄漏 | `14_events` |
| [15 Lambda 与闭包](docs/15-lambdas.md) | 捕获机制、static lambda、表达式树 | `15_lambdas` |
| [16 LINQ 基础](docs/16-linq-basics.md) | 两种语法、高频操作符、延迟执行 | `16_linq_basic` |
| [17 LINQ 进阶](docs/17-linq-advanced.md) | GroupBy/Join/自造操作符、IQueryable 分界 | `17_linq_advanced` |
| [18 迭代器](docs/18-iterators.md) | yield、状态机、IEnumerable 设计 | `18_iterators` |
| [19 模式匹配](docs/19-patterns.md) | is/属性/列表/关系模式、穷尽性 | `19_patterns` |

### 四 · 高级特性（20-27）

| 章 | 主题 | 示例 |
|---|---|---|
| [20 扩展与运算符](docs/20-extensions-operators.md) | 扩展方法、扩展成员（C# 14）、运算符重载 | `20_extensions` |
| [21 可空引用类型](docs/21-nullable.md) | NRT、流分析、注解属性 | `21_nullable` |
| [22 异常](docs/22-exceptions.md) | 栈展开、throw; 语义、过滤器、自定义 | `22_exceptions` |
| [23 反射与特性](docs/23-reflection-attributes.md) | Type、动态实例化、Attribute | `23_reflection` |
| [24 元编程](docs/24-metaprogramming.md) | 表达式树、源生成器概念 | `24_metaprogramming` |
| [25 GC 与内存](docs/25-gc.md) | 分代、Dispose 模式、WeakReference | `25_gc` |
| [26 Span](docs/26-span.md) | Span/Memory、stackalloc、ArrayPool | `26_span` |
| [27 unsafe 与互操作](docs/27-unsafe-interop.md) | 指针、fixed、P/Invoke 双平台 | `27_unsafe` |

### 五 · 异步与并发（28-31）

| 章 | 主题 | 示例 |
|---|---|---|
| [28 async/await](docs/28-async-await.md) | 状态机、同步上下文、ValueTask | `28_async` |
| [29 Task 深度](docs/29-tasks.md) | 组合、取消、异常传播 | `29_tasks` |
| [30 线程安全](docs/30-thread-safety.md) | 锁家族、Interlocked、并发集合 | `30_threadsafe` |
| [31 并行](docs/31-parallel.md) | PLINQ、Partitioner、Channel | `31_parallel` |

### 六 · 平台延伸与实战（32-36）

| 章 | 主题 | 示例 |
|---|---|---|
| [32 文件与 IO](docs/32-files-io.md) | 流家族、编码、目录遍历 | `32_files_io` |
| [33 JSON](docs/33-json.md) | System.Text.Json、源生成序列化 | `33_json` |
| [34 诊断](docs/34-diagnostics.md) | Debug/Trace、Metric、Dump | `34_diagnostics` |
| [35 单元测试](docs/35-testing.md) | 自制 mini 框架讲 xUnit 概念 | `35_testing` |
| [36 实战：MiniLang](docs/36-minilang.md) | 表达式解释器：Lexer/Parser/Evaluator + REPL | `36_minilang` |

### 七 · 书本实践篇（37-42）⭐

按四本参考书扩充：37 集合体系是三本入门教材（VC# 从入门到精通 Ch18 / 大学程序设计 Ch14 / 从零开始学 Ch9）的共讲专题；38-42 按《Effective C#（第 3 版）》第 1-5 章的 50 条组织（条 11/17 的资源管理落在 25 章）。

| 章 | 主题 | 示例 |
|---|---|---|
| [37 集合体系与选型](docs/37-collections.md) ⭐ | List/Dictionary/Sorted 家族复杂度表、只读 vs 不可变、遍历修改、数据结构课 → BCL 映射 | `37_collections` |
| [38 Effective·语言习惯](docs/38-effective-habits.md) ⭐ | 条 1-10：var 判据、readonly vs const 跨程序集实测、is/as、插值与 FormattableString、nameof、多播坑、?.Invoke、装箱隐匿处、new 修饰符 | `38_effective_habits` |
| [39 Effective·初始化与生命周期](docs/39-effective-lifecycle.md) ⭐ | 条 12-16：构造 8 步序、初始化器三例外、静态 ctor 核弹、构造链、少造对象、ctor 调虚函数灾难 | `39_effective_lifecycle` |
| [40 Effective·泛型设计](docs/40-effective-generics.md) ⭐ | 条 18-28：约束刚好够用、运行期特化、比较礼仪、IDisposable 类型参数、变体设计、委托当约束、泛型方法优先 | `40_effective_generics` |
| [41 Effective·LINQ 惯用法](docs/41-effective-linq.md) ⭐ | 条 29-44：迭代器 API、查询 vs 循环、映射表、无穷序列边界、lambda 复用、闭包资源、Single/First 断言、绑定变量 | `41_effective_linq` |
| [42 Effective·异常设计](docs/42-effective-exceptions.md) ⭐ | 条 45-50：契约与 TryXxx、专属异常与转换、三级保证、筛选器保栈、副作用日志钩子——50 条收束 | `42_effective_exceptions` |

### 八 · 查缺补漏篇（43-45）

按另五本教材（《C# 从入门到项目实践》《基础入门与实战》《程序设计教程》两种《第2版》《经典教程（第三版）》）目录交叉比对补齐的专题——四本共讲而主线只顺带使用。

| 章 | 主题 | 示例 |
|---|---|---|
| [43 常用工具类型](docs/43-common-types.md) | DateTime/TimeSpan/DateOnly 时区规则、Guid、Uri、Math 银行家舍入、Random 同种子实测与安全随机 | `43_common_types` |
| [44 预处理指令与代码组织](docs/44-preprocessing.md) | #if 布尔开关、DEBUG/NET10_0 符号、#error 哨兵、#pragma 定点静音、#line hidden 实测、命名空间/嵌套类/程序集 | `44_preprocessor` |
| [45 XML 与 LINQ to XML](docs/45-xml.md) | XElement 函数式构建、Descendants 查询、命名空间第一大坑、函数式转换、XmlDocument/XPath、XmlReader 流式 | `45_xml` |

⭐ = 2026-09 按教材扩充的书本实践篇，可独立跳读（向前依赖都有链接）。43-45 为同期查缺补漏篇，同样可跳读。

## 学习路线

```text
01 ─ 04           起步：全景、工具链、语法地基
      │
05 ─ 12           类型系统：值/引用、字符串、类、继承、接口、记录、泛型
      │
13 ─ 19           函数式与数据：委托、事件、Lambda、LINQ×2、迭代器、模式匹配
      │
20 ─ 27           高级特性：扩展、可空、异常、反射、源生成器、GC、Span、unsafe
      │
28 ─ 31           异步与并发：async/await、Task、线程安全、并行
      │
32 ─ 35           平台延伸：IO、JSON、诊断、测试
      │
36                MiniLang 实战收束（主线终点）
      │
37                集合体系（教材共讲专题，承前：数组/泛型/迭代器）
      │
38 ─ 42           Effective C# 50 条：语言习惯 → 生命周期 → 泛型 → LINQ → 异常
      │
43 ─ 45           查缺补漏：工具类型 → 预处理与代码组织 → XML
```

跳读指南：

- 刚学完基础想看工程写法 → [38](docs/38-effective-habits.md) 直接进（每条独立）
- 性能敏感场景 → [37 集合选型](docs/37-collections.md) + [41 LINQ 惰性](docs/41-effective-linq.md)
- 写库给别人用 → [40 泛型设计](docs/40-effective-generics.md) + [42 异常设计](docs/42-effective-exceptions.md)
- 想验证自己的语言功力 → [36 MiniLang](docs/36-minilang.md) 改出第 7 节的练习
- 处理日期/随机数/XML/老代码 → [43](docs/43-common-types.md)、[45](docs/45-xml.md) 直接查

每章结构：本章你将学会 → 正文 → 常见坑 → 实战建议 → 自测。**建议节奏**：`build.ps1 -Run` 看输出 → 对照正文读代码 → 自测答不上来回读 → 改示例做实验。

## 实战项目：MiniLang 解释器

`examples/36_minilang` 实现一门能跑的表达式语言：变量声明与赋值、算术/比较运算、括号与优先级（递归下降 + 优先级爬升）、位置化错误报告、REPL 交互模式（`--repl`）。词法 → 语法 → 求值三段独立、零 UI 依赖，是"全书知识落位"的活样本。详见 [docs/36-minilang.md](docs/36-minilang.md)。

## 工具链

- .NET SDK: .NET 10（`dotnet --version` 确认；`build.ps1` 自动探测 PATH 中的 `dotnet`，也可用环境变量 `DOTNET_EXE` 覆盖）
- 目标框架: `net10.0`（27 章示例额外开 `AllowUnsafeBlocks`）
- 零 NuGet 依赖：全部示例只用 BCL（含内置的 System.Collections.Immutable / System.Collections.Concurrent），离线可复现
- 编译方式: `dotnet build`（不需要 Visual Studio；跨平台 IDE 用 VS Code + C# Dev Kit）
- 已验证平台: Windows / macOS —— 45 章全部编译通过并逐个运行；27 章 P/Invoke 按平台分支（Windows 调 `kernel32`，macOS/Linux 调 `libc`）
