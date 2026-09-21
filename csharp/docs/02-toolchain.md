# 02 · 工具链与第一个程序

> 对应示例：`examples/02_toolchain`

> **本章你将学会**：dotnet CLI 的日常命令、csproj 逐行解读、程序的入口机制（顶层语句 vs Main）、命令行参数。
> **前置章节**：[01 全景](01-overview.md)。

## 1. 没有 IDE 也能干活：dotnet CLI

本教程全程用命令行构建（不需要 Visual Studio）。五个命令覆盖 90% 日常：

```powershell
dotnet new console -o MyApp    # 新建控制台工程（目录 MyApp）
dotnet build                    # 编译（产物进 bin/Debug/net10.0）
dotnet run                      # 编译 + 运行
dotnet run -- a b               # 同上，-- 之后是传给程序的参数
dotnet publish                  # 发布（部署优化版，见 WPF 教程 24 章的完整展开）
```

本教程的 `build.ps1` 把 36 个示例的构建/运行包成一条命令：

```powershell
cd G:\code\guide\csharp
.\build.ps1 -All              # 编译全部
.\build.ps1 -Run              # 编译 + 运行全部（每个示例输出讲解内容）
.\build.ps1 -Project 06_strings   # 只构建/运行某一个
```

脚本把 36 个工程的产物集中到 `build/` 目录（避免示例目录里散落 obj/bin），并清扫游离产物——实现细节见脚本注释。

## 2. csproj 逐行解读

`02_toolchain/ToolchainConsole.csproj` 全貌（36 个示例共用这套模板，仅 27 章多了 AllowUnsafeBlocks）：

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>          <!-- 控制台程序；dll 是类库 -->
    <TargetFramework>net10.0</TargetFramework>  <!-- 目标框架：决定可用 API 与语言版本 -->
    <ImplicitUsings>enable</ImplicitUsings>     <!-- 常用命名空间自动 using -->
    <Nullable>enable</Nullable>                 <!-- 可空引用类型检查（第 21 章） -->
  </PropertyGroup>
</Project>
```

对比老 .NET Framework 时代几百行的 csproj，现代工程极简的秘密是**约定**：`Sdk="Microsoft.NET.Sdk"` 隐含"目录下所有 .cs 自动编入、obj/bin 默认排除"。要加依赖（NuGet 包）时再加 `<ItemGroup>`（本教程为零依赖设计，第 35 章讲真实项目怎么加 xUnit）。

**TargetFramework 决定两件事**：能用哪些 BCL API（net10.0 有最新的）、编译器允许哪些语言特性。改小它 = 给自己戴上镣铐兼容老环境。

## 3. 程序入口：三种等价写法

**写法一：顶层语句（本教程默认）**——文件里直接写语句，编译器把它们搬进自动生成的 `Main`：

```csharp
Console.OutputEncoding = System.Text.Encoding.UTF8;   // 惯例第一行：中文输出不乱码
Console.WriteLine("Hello");
```

**写法二：经典 Main**——显式写入口方法，控制感更强：

```csharp
internal static class ClassicEntry
{
    internal static void MainWithArgs(string[] args) { ... }
}
```

**写法三：Program 类 + Main**——老项目最常见形态，本仓库其他教程的工程多是这种。

三条规则：

1. **整个工程只能有一个入口**——顶层语句所在文件就是入口，别处不能再写 Main
2. 顶层语句文件里**类型声明必须放在语句之后**（第 07 章的 enum、各类 class 都见过这种布局）
3. 顶层语句里可以直接 `await`（第 28 章起大量使用）——编译器生成的 Main 是 async 的

选型建议：小工具用顶层语句（少仪式感）；大项目用经典 Main（入口逻辑集中）。本教程示例小，一律顶层语句。

## 4. 命令行参数

参数通过 `args`（顶层语句直接可用 / Main 的形参）传入：

```powershell
dotnet run -- --repl      # 程序收到 args = ["--repl"]
```

`36_minilang` 就用 `--repl` 切换"演示模式/交互模式"。处理参数的成熟方案是 `System.CommandLine` 或手写 switch——第 36 章展示了最朴素的一个 if。

## 5. 开发环境选择

| 工具 | 特点 |
|---|---|
| VS Code + C# Dev Kit | 轻、跨平台、本教程够用 |
| Visual Studio 2022+ | 最全（调试器、设计器），Windows 重装机器 |
| Rider | JetBrains 出品，重构最强，收费 |

编辑器只影响手感，不影响代码——`dotnet build` 是唯一真相。

## 常见坑

**顶层语句和 Main 打架**：工程里已有 Main 又写了顶层语句 → CS0017 重复入口。删一个。

**类型声明混在语句中间**：顶层语句文件里 class/enum 声明出现在语句之前 → 编译错误。声明一律放文件末尾。

**`dotnet run` 的参数没传进去**：少了 `--` 分隔符，参数被 dotnet 自己吃了。

**中文输出乱码**：Windows 控制台默认 GBK。程序第一行设 `Console.OutputEncoding = System.Text.Encoding.UTF8`（本教程全部示例的惯例），或终端切 UTF-8 代码页。

**在示例目录里直接 dotnet run 留下 obj/bin**：与 build.ps1 的集中构建冲突（CS0579 重复特性）。脚本会自动清扫，读者自查时删掉示例目录下的 obj/bin 即可。

## 实战建议

- 把 `build.ps1 -Run` 当"带讲解的教材"跑——先看输出再读代码，学习效率翻倍
- 改示例立即 `.\build.ps1 -Project NN_name` 验证——反馈环越短学得越快
- 每个示例都开着编辑器对照读：代码是最终的事实，正文只是导游

## 自测

1. **csproj 的四个关键属性各干什么？** —— OutputType 程序/库；TargetFramework API 与语言版本；ImplicitUsings 自动 using；Nullable 可空检查。
2. **顶层语句的本质是什么？三条规则？** —— 编译器搬进生成的 Main；唯一入口、类型声明放语句后、可直接 await。
3. **怎么给 dotnet run 传程序参数？** —— `dotnet run -- 参数`。

---
上一章：[01 C# 与 .NET 全景](01-overview.md) ｜ 下一章：[03 变量、类型与运算符](03-variables-operators.md)
