# 01 · F# 全景：函数式优先的 .NET 语言

> 本教程主线：.NET 10 SDK + F# 10。本章无专属示例，代码引用 `examples/02_hello`。

## 1.1 F# 是什么

F# 是运行在 .NET 上的**函数式优先**多范式语言：函数、不可变数据与类型推演是默认工作方式，同时命令式与面向对象设施完备。它适合：

- 数据处理与分析（管道 + 强类型建模）
- 后端服务与 Web API（第 16 章）
- 领域建模（record + 判别联合，第 09/10 章）
- 脚本与快速实验（`.fsx` + `dotnet fsi`）

对"第一个印象"，四行就够了（摘自 `examples/02_hello/Program.fs` 的 2.1 段）：

```fsharp
let message = "Hello from F#"       // let 绑定：默认不可变
let add a b = a + b                 // 函数：空格传参，无大括号
```

没有分号、没有大括号、没有类型声明——类型在编译期全部推出来了。

## 1.2 F# 与 .NET / C# 的关系

| 事实 | 说明 |
|---|---|
| 同一运行时 | F# 编译到与 C# 相同的 IL，跑在同一个 CLR 上 |
| 共享类库 | `System.String`、`List<T>`、`Task`、ASP.NET Core 直接可用（第 18 章） |
| 混编 | 一个解决方案里 F# 与 C# 工程互相引用是常规操作 |
| 专属库 | `FSharp.Core` 提供 `option`/`Result`/`List` 模块等函数式设施 |

F# 不是"隔离的语言"，而是"同一平台上的另一种思维方式"。

## 1.3 语言五件套速览

全书围绕五个核心设施展开，先混个眼熟：

| 设施 | 一行代码 | 详见 |
|---|---|---|
| `let` 绑定 | `let xs = [1; 2; 3]` | 第 03 章 |
| 函数与管道 | `xs \|> List.sum` | 第 04 章 |
| 模式匹配 | `match x with Some v -> ...` | 第 05 章 |
| record / DU | `type Shape = Circle of float \| ...` | 第 09/10 章 |
| 计算表达式 | `async { let! x = f () in ... }` | 第 14 章 |

## 1.4 工具链：dotnet CLI 一种就够

本教程只用 .NET SDK 自带的 CLI。脚本会自动找 `dotnet`，查找顺序是：显式参数 `-Dotnet <路径>` / `DOTNET=<路径>` → `DOTNET_ROOT` → 常见安装位置（Windows 的 scoop/Program Files、macOS 的 `/opt/local/bin`、Homebrew 的 `/opt/homebrew/bin`）→ PATH 里的 `dotnet`。平时直接用 PATH 里的即可：

```bash
dotnet new console -lang F# -o hello     # 新建 F# 控制台工程
dotnet run --project hello               # 编译并运行
dotnet fsi                               # 进入交互 REPL（第 02 章）
dotnet fsi script.fsx                    # 执行脚本
dotnet new xunit -lang F# -o tests       # 新建 xUnit 测试工程（第 17 章）
```

## 1.5 三种工作方式：fsproj、fsx 与 REPL

| 方式 | 载体 | 适合 |
|---|---|---|
| 工程 `*.fsproj` | 多个 `.fs` 文件 | 正式项目、本教程示例 |
| 脚本 `*.fsx` | 单文件，可含 `#r "nuget: ..."` 引包 | 一次性实验、数据清洗 |
| REPL `dotnet fsi` | 终端逐行求值 | 学习期逐段验证代码 |

教学主线是 fsproj 示例工程 + fsi 随手验证的组合。

## 1.6 fsproj 结构：文件顺序即编译顺序

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <Compile Include="Todo.fs" />
    <Compile Include="Program.fs" />
  </ItemGroup>
</Project>
```

上面是实战项目 `examples/20_todo/src/Todo.fsproj` 的骨架（第 20 章）。**`<Compile Include>` 的排列顺序就是编译顺序**：被依赖的文件必须排在前面，`Program.fs`（含入口）放最后。新建工程默认只列 `Program.fs`，多文件时手工维护这份列表。

GUI 工程另有开关（第 19 章）：`UseWindowsForms` / `UseWPF` + `net10.0-windows`；Web 工程用 `Sdk="Microsoft.NET.Sdk.Web"`（第 16 章）。

## 1.7 本目录的构建脚本

**Windows（PowerShell 7）**：

```powershell
cd D:\code\guide\fsharp          # 换成你自己的路径
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                       # 全部示例：构建+运行+测试
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 06_collections    # 单个示例目录
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                     # 清理 build 目录
```

**macOS / Linux（bash）**：

```bash
cd ~/code/guide/fsharp           # 换成你自己的路径
./run-all.sh                     # 全部示例：构建+运行+测试
./run-all.sh 06_collections      # 单个示例目录
./run-all.sh --clean             # 清理 build 目录
```

两个入口等价：控制台示例编译后实际运行；GUI 工程只构建；测试工程直接 `dotnet test`。
判定标准是**退出码为 0 且 stderr 为空**；运行输出留档在 `build/log/<工程名>.out`。

ps1 脚本含中文且无 BOM，**必须用 PowerShell 7（pwsh）运行**，Windows PowerShell 5.1 会按 ANSI 误读。

根目录的 `global.json` 把 SDK 钉在 `10.0.*`（`rollForward: latestFeature`）：机器上同时装了 .NET 11 preview 之类的更高版本时，`dotnet` 默认会挑最新的，钉住可以避免"教程跑在没验证过的 SDK 上"。

单跑一个示例的日常学法：

```bash
cd examples/06_collections
dotnet run
```

## 1.8 支持矩阵

| 维度 | 本教程取值 |
|---|---|
| SDK | .NET 10（`dotnet --info` 确认） |
| 语言 | F# 10（`dotnet fsi` 启动横幅可见） |
| 目标框架 | `net10.0`（GUI 章为 `net10.0-windows`） |
| 平台 | Windows / macOS / Linux 全支持（GUI 章**只能构建**，运行仍限 Windows） |
| 编辑器 | VS、VS Code（Ionide/fscodec）、Rider 均可 |

## 1.9 学习路线图

| 阶段 | 章 | 主题 |
|---|---|---|
| 入门 | 02–04 | 第一个程序、值与不可变、函数 |
| 函数式核心 | 05–06 | 模式匹配（含活动模式）、集合 |
| 类型建模 | 07–10 | Option、Result、record、判别联合 |
| 深入语言 | 11–14 | OOP、泛型/SRTP/度量单位、异步、计算表达式 |
| 生态实战 | 15–18 | 文件与 JSON、Web API、测试、.NET 互操作 |
| 收尾 | 19–20 | 桌面 GUI、实战：待办管理器 CLI |

## 1.10 坑位清单

- **文件顺序**：fsproj 里 `Compile` 顺序即依赖顺序，排错直接编译失败。
- **`Program.fs` 放最后**：入口文件依赖其他模块，必须排尾。
- **缩进即语法**：F# 用 4 空格缩进划分块，缩进错了不是风格问题，是编译错误。
- **无隐式 open**：`Split` 不会自动可见，`String` 的方法要么 `open System`，要么写全名。
- **pwsh 7**：跑 build.ps1 别用 Windows PowerShell 5.1（编码问题）。
- **SDK 版本**：机器上装了多个 SDK 时，`dotnet` 默认挑版本最高的那个。要跑教程主线就靠根目录 `global.json` 钉住 10.0（`rollForward: latestFeature` 会自动选 10.0 里最新的 feature band）。
- **示例与脚本的 obj/bin 冲突**：在示例目录直接 `dotnet run` 会就地生成 `obj/`、`bin/`，之后再跑总脚本会撞上"重复生成特性"之类的错。总脚本开跑前会自动清扫这些游离目录，所以不用手动管。
