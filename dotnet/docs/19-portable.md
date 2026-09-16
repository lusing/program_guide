# 19 · 跨平台与可移植性：从 Windows 8.1 到 macOS/Linux

> 对应示例：`examples/19_portable`

本章回答一个工程问题：**"我的程序要跑在某台机器上，该 target 什么？"**——特别是目标机里有老 Windows（8.1/7）、macOS、Linux，或需要 Mono 的场合。

## 1. 支持矩阵与残酷现实

先摆事实（截至本教程写作，来源见文末）：

| 运行时 | Win 8.1/7 | Win10 1607+ | macOS / Linux | 状态 |
|---|---|---|---|---|
| .NET 10（本教程主线） | ✘ | ✔ | ✔ | LTS，支持至 2028-11 |
| .NET 8 | ✘ | ✔ | ✔ | 2026-11-10 结束支持 |
| .NET 6 | ✔（Win7 SP1 起） | ✔ | ✔ | **已 EOL（2024-11-12）**，无安全补丁 |
| .NET Framework 4.8 | ✔ | ✔ | ✘ | 随 OS 维护；4.8.1 仅 Win11+ |
| Mono | ✔ | ✔ | ✔ | 维护模式（见 §7） |

微软官方口径很直白：**目前没有任何一个处于支持期内的现代 .NET 版本能运行在 Windows 7/8.1 上**——最后支持它们的是 .NET 6，而 .NET 6 已于 2024-11-12 停止安全更新（Windows 8.1 本身的扩展支持也早在 2023-01 结束）。

所以"支持 Win 8.1"没有银弹，只有三条现实路径：

1. **维持遗留**：.NET Framework 4.8（Win 8.1 原生可装）或继续跑 Mono——接受无新特性、无安全更新的现状，适合"不能再动"的系统；
2. **self-contained 发布 + 明确风险**：把 .NET 6 运行时打进应用目录（目标机免安装），但运行时本身不再收补丁——只适合内网封闭环境；
3. **推动升级 OS**（长期正解）：升级到 Win10+ 后整个现代 .NET 生态立即可用。

选型决策一句话：**目标机 Win10+/macOS/Linux → net10.0；遗留 Win 8.1 → 上面三条路里选，并把"何时升级"写进计划而不是假装问题不存在**。

## 2. netstandard2.0：可移植库的通用语

示例的核心设计是"**可移植的库 + 各平台的消费端**"。`examples/19_portable` 是嵌套双工程：

```text
19_portable/
├── PortableLib/          # 类库：TargetFrameworks=netstandard2.0;net10.0
└── PortableApp/          # 控制台：net10.0，ProjectReference 引用库
```

`netstandard2.0` 不是运行时，是** API 契约**：库 target 它，就自动能被 .NET Framework 4.6.1+、Mono、Unity、以及一切现代 .NET（5/6/8/10…）消费——一份核心逻辑服务所有平台。"业务逻辑进 netstandard 库、平台壳（UI/入口）各自 target 具体运行时"是跨平台项目的基本功。

代价是** API 面冻结在 2017 年**：record 所需的类型、Span 大部分 API、IAsyncEnumerable 都不在 netstandard2.0 里。所以示例的库做了**多目标**（§3）：同时 target `netstandard2.0;net10.0`——老消费者拿 netstandard 版，现代消费者拿 net10 版（API 更全、优化更佳），NuGet 发包都是这么干的。

## 3. 多目标与条件编译

PortableLib.csproj 的关键一行：

```xml
<TargetFrameworks>netstandard2.0;net10.0</TargetFrameworks>
```

注意复数 `TargetFrameworks`（分号分隔）。每个目标单独编译一遍，配合 `#if` 按目标写差异化代码（Greeting.cs）：

```csharp
// 条件编译：不同目标框架各取所需
#if NET
    public static string Runtime => ".NET (Core) 5+";
#elif NETFRAMEWORK
    public static string Runtime => ".NET Framework / Mono";
#else
    public static string Runtime => "纯 netstandard 实现";
#endif
```

常用符号速查：`NET`（现代 .NET 5+）、`NETFRAMEWORK`（.NET Framework）、`NETSTANDARD`、精确版本如 `NET10_0` / `NET48_0`（`_OR_GREATER` 后缀表范围）。判据：**小差异用 #if**；一个文件实在分叉太深就拆成多文件 + csproj 的 `Condition` 按目标选入。

消费端 PortableApp 跑在 net10.0 上，拿到的是 net10 编译产物：

```csharp
Console.WriteLine(Greeting.Runtime);   // 输出 ".NET (Core) 5+"
```

## 4. LangVersion：语法与目标框架的错位

PortableLib.csproj 还有两行刻意为之的配置：

```xml
<LangVersion>latest</LangVersion>
<ImplicitUsings>disable</ImplicitUsings>
```

netstandard2.0 的**默认语言版本是 C# 7.3**（SDK 按目标框架给保守默认）——不设 LangVersion，`namespace PortableLib;` 这种文件范围命名空间（C# 10）直接编译错。`latest` 解锁新语法；`ImplicitUsings=disable` 则是反向示范：显式 `using System;` 让你看见 ImplicitUsings 平时替你写了什么（第 01 章）。

但要记住 **LangVersion 只开语法、不开运行时支持**：`record` 在 netstandard2.0 下还需要 `IsExternalInit` 类型（编译器生成的 init/record 机制依赖它，BCL 5.0 才有）——解法是加一个几十行的 polyfill 源文件（NuGet 搜 `IsExternalInit`）。这是"新语法 × 老目标"的经典三角债，写 netstandard 库迟早遇到。

## 5. 可移植编码清单

示例函数演示的习惯（呼应第 03/12 章）：

```csharp
// 可移植习惯 1：Path.Combine 拼路径，不手写 '\\' 或 '/'
public static string BuildFilePath(string dir, string name) => Path.Combine(dir, name);

// 可移植习惯 2：显式 UTF8，行尾交给 Environment.NewLine
public static string Format(string name) => /* … */ "hello, " + name + Environment.NewLine;
```

完整清单：`Path.Combine` 拼路径；读写显式 `Encoding.UTF8`；行尾用 `Environment.NewLine` 或统一 `\n` 约定；**文件名大小写当 Linux 是敏感的**（`Data.txt` ≠ `data.txt`）；路径分隔符别出现在字符串拼接里；平台特有 API（注册表、Win32 调用）用 `RuntimeInformation.IsOSPlatform(OSPlatform.Windows)` 分支隔离在薄薄的适配层里。

## 6. 发布模型：RID 与 self-contained

写好的程序怎么到目标机？`dotnet publish` 两种模式：

```bash
# 框架依赖（默认）：小产物，目标机需预装 .NET 运行时
dotnet publish -c Release -r win-x64

# 自包含：运行时打进应用，目标机什么都不用装
dotnet publish -c Release -r linux-x64 --self-contained true
```

`-r` 是 **RID**（Runtime Identifier）：`win-x64`、`win-arm64`、`linux-x64`、`osx-arm64`……每个 RID 一份发布产物。**self-contained** 体积大（带整个运行时）但免安装——它也是老 Windows 的唯一"现代 .NET"上车方式（带 .NET 6 运行时自包含，风险见 §1）。再加 `-p:PublishSingleFile=true` 可打成单文件便于分发。

## 7. Mono：过去与现在

Mono 是 2004 年起社区驱动的 .NET 跨平台开源实现——比官方早十几年跨到 Linux/macOS，滋养了 Xamarin 与 Unity。现状（写作时）：

- 最后一个补丁版本发布于 **2024-02**，此后进入**维护模式**；
- 2024-08 微软把 Mono 项目**捐赠给 Wine 团队**；官方建议新项目迁移到现代 .NET；
- 仍会遇见它的场合：**Unity 游戏脚本运行时**（Unity 同时推 IL2CPP 替代）、老的 Xamarin/MonoGame 应用、一些 Linux 发行版自带的 mono 工具。

对 Mono 的正确姿势：**读得懂、能维护，不新选**。给它写的代码 = netstandard2.0 兼容代码（§2 的库正好是）——这也是本章把 netstandard 放在中心的原因：它是通往所有历史平台的桥。

## 8. 动手做

```bash
cd examples/19_portable/PortableApp
dotnet run
```

输出三行：`.NET (Core) 5+`（条件编译选择）、`data\notes.txt`（Path.Combine 在 Windows 的结果——到 Linux/macOS 上跑就是 `data/notes.txt`）、`hello, portable`。再把 PortableApp.csproj 的 `TargetFramework` 改成 `net8.0` 编译一次，体会消费端与库的多目标如何配合。

## 9. 坑位清单

1. **netstandard 库里用了现代 API**：`Span` 大部分、`IAsyncEnumerable`、日期新重载——编译错 CS1061/CS8370 就是踩线了；多目标（§3）让现代消费者吃上现代 API。
2. **`#if` 区越写越宽**：条件编译块超过几行就该拆类型/拆文件，否则两套代码的漂移没人能审。
3. **多目标忘了还原**：改了 TargetFrameworks 后先 `dotnet restore`（或直接 build，它会触发）再期待 IDE 不飘红。
4. **路径大小写**：Windows 上开发"能跑"，部署到 Linux 容器 404——文件名常量统一大小写规范。
5. **在 self-contained 里赌安全**：.NET 6 self-contained 不再有补丁——用它支撑面向互联网的服务等于裸奔（§1 路径 2 的限定语"内网封闭"不是废话）。

---

**事实来源**：dotnet/core 仓库 `supported-os.md`（.NET 10 支持矩阵）、Microsoft Learn《Install .NET on Windows》（"没有任何被支持版本支持 Win7/8.1"）、.NET 支持策略页（.NET 8/9 于 2026-11-10 EOL）、devblogs.microsoft.com（.NET 6 EOS 公告）、mono-project.com（维护模式与捐赠说明）。数字会随时间变化，落笔重大决策前以官方页面为准。
