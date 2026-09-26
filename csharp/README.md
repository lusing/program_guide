# C# 语言教程

一套以**语言本身**为主线的 C# 系统教程：**36 章正文 + 36 个可编译可运行的示例**（章号=示例号），收束于一个能跑的表达式解释器实战。所有示例在 .NET 10 SDK 上编译并逐一运行验证（Windows 与 macOS 双平台实测，输出即讲解内容），语言特性声明（含 C# 14 扩展成员）均经实测编译确认。

与同仓库其他教程的分工：**csharp 深挖语言 → [dotnet](../dotnet) 用语言建平台应用（Web/EF/测试）→ [wpf](../wpf) 用语言建桌面界面**。

## 快速开始

`build.ps1` 会自动探测 PATH 中的 `dotnet`（也可用环境变量 `DOTNET_EXE` 指定），需 PowerShell 7（`pwsh`）运行，三平台通用：

```bash
cd csharp
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                       # 编译全部 36 个示例（集中产物到 build/）
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
├── README.md
├── build.ps1                  # 一键构建/运行脚本（须 PowerShell 7 / pwsh 运行，三平台通用）
├── docs/                      # 36 章正文
│   ├── 01-overview.md             # C# 与 .NET 全景
│   ├── 02-toolchain.md            # 工具链与第一个程序
│   ├── 03-variables-operators.md  # 变量、类型与运算符
│   ├── 04-control-methods.md      # 流程控制与方法
│   ├── 05-value-reference.md      # 值/引用类型与内存
│   ├── 06-strings.md              # 字符串深度
│   ├── 07-arrays-enums.md         # 数组与枚举
│   ├── 08-classes.md              # 类与封装
│   ├── 09-inheritance.md          # 继承与多态
│   ├── 10-interfaces.md           # 接口
│   ├── 11-records.md              # 结构体与记录
│   ├── 12-generics.md             # 泛型
│   ├── 13-delegates.md            # 委托
│   ├── 14-events.md               # 事件
│   ├── 15-lambdas.md              # Lambda 与闭包
│   ├── 16-linq-basics.md          # LINQ 基础
│   ├── 17-linq-advanced.md        # LINQ 进阶
│   ├── 18-iterators.md            # 迭代器与 yield
│   ├── 19-patterns.md             # 模式匹配
│   ├── 20-extensions-operators.md # 扩展方法与运算符重载
│   ├── 21-nullable.md             # 可空引用类型
│   ├── 22-exceptions.md           # 异常处理
│   ├── 23-reflection-attributes.md# 反射与特性
│   ├── 24-metaprogramming.md      # 元编程与源生成器
│   ├── 25-gc.md                   # GC 与内存管理
│   ├── 26-span.md                 # Span 与高性能内存
│   ├── 27-unsafe-interop.md       # unsafe 与互操作
│   ├── 28-async-await.md          # async/await
│   ├── 29-tasks.md                # Task 深度
│   ├── 30-thread-safety.md        # 线程安全
│   ├── 31-parallel.md             # 并行编程
│   ├── 32-files-io.md             # 文件与 IO
│   ├── 33-json.md                 # 序列化与 JSON
│   ├── 34-diagnostics.md          # 诊断与日志
│   ├── 35-testing.md              # 单元测试
│   └── 36-minilang.md             # 实战：MiniLang 解释器
└── examples/                  # 36 个示例（net10.0 控制台，零 NuGet 依赖）
    ├── 01_overview/  ...  35_testing/      # 每章一个：NN_名字/XxxConsole.csproj + Program.cs
    └── 36_minilang/                          # 多文件工程：Lexer/Parser/Evaluator/Program
```

## 工具链

- .NET SDK: .NET 10（`dotnet --version` 确认；`build.ps1` 自动探测 PATH 中的 `dotnet`，也可用环境变量 `DOTNET_EXE` 覆盖）
- 目标框架: `net10.0`（27 章示例额外开 `AllowUnsafeBlocks`）
- 零 NuGet 依赖：全部示例只用 BCL，离线可复现
- 编译方式: `dotnet build`（不需要 Visual Studio；跨平台 IDE 用 VS Code + C# Dev Kit）
- 已验证平台: Windows / macOS —— 36 章全部编译通过并逐个运行；27 章 P/Invoke 按平台分支（Windows 调 `kernel32`，macOS/Linux 调 `libc`）

## 学习路线

六大部分，按章顺序走：

1. **起步（01-04）**：全景、工具链、语法地基
2. **类型系统（05-12）**：值/引用、字符串、类、继承、接口、记录、泛型
3. **函数式与数据（13-19）**：委托、事件、Lambda、LINQ×2、迭代器、模式匹配
4. **高级特性（20-27）**：扩展、可空、异常、反射、源生成器、GC、Span、unsafe
5. **异步与并发（28-31）**：async/await、Task、线程安全、并行
6. **平台延伸与实战（32-36）**：IO、JSON、诊断、测试、**MiniLang 解释器**

每章结构：本章你将学会 → 正文 → 常见坑 → 实战建议 → 自测。**建议节奏**：`build.ps1 -Run` 看输出 → 对照正文读代码 → 自测答不上来回读 → 改示例做实验。

## 实战项目：MiniLang 解释器

`examples/36_minilang` 实现一门能跑的表达式语言：变量声明与赋值、算术/比较运算、括号与优先级（递归下降 + 优先级爬升）、位置化错误报告、REPL 交互模式（`--repl`）。词法 → 语法 → 求值三段独立、零 UI 依赖，是"全书知识落位"的活样本。详见 [docs/36-minilang.md](docs/36-minilang.md)。
