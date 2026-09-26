# 01 · .NET 全景：平台、运行时与工具链

本教程面向**会编程、初学 C#/.NET** 的读者：变量、循环、函数这些概念不再解释，重点讲 C# 的语法习惯、.NET 的平台模型和"为什么要这样写"。已有其他语言经验的读者可以随时横向对比——C# 的很多设计正是为了让从 Java/C++ 过来的人少踩坑。主线使用 .NET 10（LTS）。

## 1. .NET 是什么

先把两个常被混用的名字分开：**C# 是语言**（你写的源码），**.NET 是平台**（让源码跑起来的整套基础设施）。两者一对多——C# 可以 targeting .NET，F#、VB 也可以；.NET 的绝大部分生态是围绕 C# 建立的。

从源码到运行，中间经过三站：

```text
C# 源码 ──Roslyn 编译──▶ IL 中间语言 ──CLR: JIT 即时编译──▶ 机器码
```

- **IL**（Intermediate Language）：与 CPU 无关的指令集，打包进 dll/exe。
- **CLR**（Common Language Runtime）：运行时。加载 IL，首次执行某个方法时由 **JIT** 编译成本机代码并缓存——所以 .NET 程序"越跑越快"，首次调用有编译开销。
- **BCL**（Base Class Library）：随平台发布的基础库，`System.*` 命名空间下的一切——集合、文件、网络、JSON……你写 C# 其实大半在"组合 BCL"。

理解这条流水线，后面很多现象就自洽了：为什么 dll 跨平台（IL 与 CPU 无关，JIT 在目标机上现编）；为什么有"启动预热"；为什么第 19 章讲的多目标编译可行（同一份 IL 语义，不同平台的运行时都能执行）。

## 2. 家族史一页纸

| 世代 | 时间 | 特点 |
|---|---|---|
| .NET Framework | 2002– | 仅 Windows，随系统安装（Win10/11 自带 4.8），维护模式不再加新特性 |
| Mono | 2004– | 社区出品的跨平台开源实现，比官方早十年跨到 Linux/macOS；现已维护模式（详见第 19 章） |
| .NET Core | 2016–2019 | 微软的跨平台重写，性能优先，模块化发布 |
| .NET 5+ | 2020–今 | Core 与 Mono 主线合并后的统一品牌，跳过"4.x"避免与 Framework 混淆；此后每年 11 月大版本，偶数年为 LTS |

本教程写作时的最新 LTS 是 **.NET 10**（支持至 2028-11）。老 LTS（.NET 8）将于 2026-11-10 结束支持——**新项目没有理由不直接用 .NET 10**。

## 3. 支持矩阵速览与选型

| 运行时 | Windows 8.1 | Win10+ | macOS / Linux | 现状 |
|---|---|---|---|---|
| .NET 10 / 8 | ✘（Win10 1607 起） | ✔ | ✔ | 当前主线 |
| .NET 6 | ✔（Win7 SP1 起） | ✔ | ✔ | 已 EOL（2024-11-12） |
| .NET Framework 4.8 | ✔ | ✔ | ✘ | 长期维护，不加新特性 |
| Mono | ✔ | ✔ | ✔ | 维护模式（Unity 等仍在用） |

选型一句话：**目标机是 Win10+/macOS/Linux → .NET 10**；必须支持 Win 8.1/7 → 现代 .NET 已无被支持版本（.NET 6 也停止安全更新了），现实选择是维持 .NET Framework 4.8 / Mono 遗留方案，或推动系统升级——完整的取舍分析在第 19 章。

## 4. SDK 与命令行

SDK（软件开发工具包）= 编译器 + 运行时 + 项目工具。安装后 `dotnet` 通常已在 PATH 中，验证版本（三平台通用）：

```bash
dotnet --version          # Windows / macOS / Linux 一致
```

> 查看本机已装的 SDK 与运行时：`dotnet --list-sdks`、`dotnet --list-runtimes`；完整环境信息：`dotnet --info`（含平台 RID，如 macOS 为 `osx-x64`/`osx-arm64`、Windows 为 `win-x64`、Linux 为 `linux-x64`）。

日常三板斧（在任意目录）：

```bash
dotnet new console -n MyApp   # 生成控制台工程
dotnet build                   # 编译（产物默认在 bin/、中间文件在 obj/）
dotnet run                     # 编译并运行
```

本教程的示例工程刻意保持极简：**每个示例 = 一个目录 = 一个 csproj + 一个 Program.cs**，没有解决方案文件。你可以在任何一章的示例目录里直接 `dotnet run`。

## 5. 读懂 csproj

打开 `examples/02_hello/HelloConsole.csproj`，全部内容如下：

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
```

| 字段 | 含义 | 备注 |
|---|---|---|
| `Sdk="Microsoft.NET.Sdk"` | 使用标准 .NET 工程规则 | 自动把 `*.cs` 收进编译、默认引用 BCL |
| `OutputType` | `Exe`（可执行）或默认的类库 | |
| `TargetFramework` | 目标框架，`net10.0` | 决定可用的 API 面与默认语言版本；复数形式 `TargetFrameworks` 用于多目标（第 19 章） |
| `ImplicitUsings` | 自动添加 `using System;` 等常用命名空间 | 所以示例里看不到 using 也能用 `Console` |
| `Nullable` | 开启可空引用类型检查（第 10 章） | 新工程默认开启 |

老的 .NET Framework 工程动辄几百行 csproj（每个文件都要显式列出）；SDK 风格工程靠**约定优于配置**——目录里的源码自动纳入，绝大多数项目只需要上面几个属性。

## 6. 本教程怎么用

二十章的路线：语言基础（02–03）→ 面向对象（04–06）→ 函数式设施（07–09）→ 可靠性（10–11）→ IO 与异步（12–13）→ 性能（14–15）→ 应用层（16–18）→ 平台兼容与语言演进（19–20）。每章开头标注对应示例工程：

| 章 | 主题 | 示例 |
|---|---|---|
| 02 | 第一个程序 | `examples/02_hello` |
| 03 | 类型与控制流 | `examples/03_types` |
| 04 | 面向对象 | `examples/04_oop` |
| 05 | record 与模式匹配 | `examples/05_records` |
| 06 | 泛型与扩展方法 | `examples/06_generics` |
| 07 | 委托、lambda 与事件 | `examples/07_delegates` |
| 08 | 集合 | `examples/08_collections` |
| 09 | LINQ | `examples/09_linq` |
| 10 | 可空引用类型 | `examples/10_nullable` |
| 11 | 错误处理 | `examples/11_errors` |
| 12 | 文件与 JSON | `examples/12_files_json` |
| 13 | async/await | `examples/13_async` |
| 14 | 并行 | `examples/14_parallel` |
| 15 | Span 与 Memory | `examples/15_span` |
| 16 | Minimal API | `examples/16_webapi` |
| 17 | EF Core | `examples/17_efcore` |
| 18 | 测试 | `examples/18_testing` |
| 19 | 跨平台与可移植性 | `examples/19_portable` |
| 20 | 现代 C# 纵览 | `examples/20_modern` |

统一构建（比逐个 `dotnet build` 快且集中产物）。`build.ps1` 会自动探测 PATH 中的 `dotnet`（也可用环境变量 `DOTNET_EXE` 指定），需 PowerShell 7（`pwsh`），三平台通用：

```bash
cd dotnet
pwsh -ExecutionPolicy Bypass -File build.ps1 -All          # 编译全部示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 09_linq  # 只编译一个
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean        # 清理 build 目录
```

> 提示：`build.ps1` 含中文且无 BOM，需要 PowerShell 7（`pwsh`）运行；Windows 自带的 PowerShell 5.1 会因编码解析失败。Windows 下也可用 `.\build.ps1 -All`。

推荐学法：每章**读讲解 → 跑示例 → 改代码再跑**。改坏了就 `git checkout -- examples/NN_xxx` 还原，改对了就对正确输出形成肌肉记忆。

## 7. 坑位清单

1. **`dotnet` 不在 PATH / 版本不对**：报 `NETSDK1045`（识别到更低版本 SDK）多半是系统里装了多个 SDK 且当前目录的 `global.json` 钉死了旧版本——删掉目录里的 `global.json` 即可。
2. **PowerShell 执行策略**：首次跑 `.ps1` 报"禁止运行脚本"——用 `pwsh -ExecutionPolicy Bypass -File build.ps1 -All`。
3. **公司内网 NuGet 源**：restore 卡住或 401，多半走了内网代理源；`dotnet nuget list source` 检查，临时绕过可用 `--source https://api.nuget.org/v3/index.json`。
4. **示例目录里残留 obj/bin**：先 `dotnet run` 又用 build.ps1 构建时，脚本会自动清扫游离产物；若手动构建报"特性重复"（CS0579），删掉示例目录下的 `obj/`、`bin/` 重来。
