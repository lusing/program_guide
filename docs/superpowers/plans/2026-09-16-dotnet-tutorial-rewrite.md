# dotnet 教程重写实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `dotnet/` 从"示例罗列"改写为 20 章自学教程（docs/ 分章 + 示例与章号一一对应 + 跨平台章），全部示例可 `build.ps1 -All` 编译通过。

**Architecture:** 现有 15 个示例 `git mv` 重编号并去 `_mapped` 后缀；新增 4 个示例（04_oop / 07_delegates / 10_nullable / 19_portable）；新建 `docs/01-overview.md`…`docs/20-modern-csharp.md` 20 个章节文件（WPF 教程风格）；build.ps1 升级（递归发现 csproj + 按工程拆分 obj）；最后删旧文件、重写 README、更新 CHEATSheet。

**Tech Stack:** .NET 10 SDK（`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`）、C#（net10.0 / netstandard2.0）、PowerShell 构建脚本、Markdown。

**Spec:** `G:\code\guide\docs\superpowers\specs\2026-09-16-dotnet-tutorial-rewrite-design.md`（本计划依 spec 而写，执行者两份都要读）

## Global Constraints

- 工作目录：`G:\code\guide\dotnet`（bash 路径 `/g/code/guide/dotnet`）；仓库根 `G:\code\guide`。
- dotnet 可执行文件：`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`（build.ps1 内已硬编码，勿改）。
- 示例 TargetFramework：一律 `net10.0`；唯一例外 `19_portable/PortableLib` = `netstandard2.0;net10.0` 多目标。
- csproj 模板（新示例沿用现有字段：`ImplicitUsings`/`Nullable` enable）：
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
- 章节写作模板（每章必须遵守）：
  - 文件名 `NN-kebab-case.md`；首行标题 `# NN · 主题：副标题`；第二行引用块 `> 对应示例：examples/NN_name`（第 01 章无此行，改为引用 `examples/02_hello`）。
  - 结构：`## 1.` 起编号小节；**先讲"解决什么问题"再讲语法**；代码段配讲解；对比用表格；结尾"坑位清单"（按命中率排序）。
  - 跨章引用格式：`第 12 章`（不带文件名）。章节内引用的示例代码片段必须与 `examples/` 实际代码**逐字一致**（省略处标 `// …`）。
  - 每章 100–200 行；中文行文；示例代码讲解的附加片段注释用中文。
  - 风格范本（每章动笔前先读）：`G:\code\guide\wpf\docs\06-binding.md`。
- **build.ps1 编码坑（来自项目记忆）**：build.ps1 含中文且当前带 UTF-8 BOM；Edit/Write 工具会剥掉 BOM，Windows PowerShell 5.1 下无 BOM 中文脚本会乱码。**每次编辑 build.ps1 后必须恢复 BOM**：`cd /g/code/guide/dotnet && printf '\xef\xbb\xbf' | cat - build.ps1 > build.ps1.tmp && mv build.ps1.tmp build.ps1`（先确认原文件确实有 BOM：`head -c 3 build.ps1 | od -An -tx1` 应输出 `ef bb bf`）。
- 构建验证命令（本计划所有"验证构建"步骤统一用）：
  ```bash
  cd /g/code/guide/dotnet && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```
  预期：每个工程输出 `[Build] <name>`，结尾 `[Done] examples 目录全部编译通过。`
- 运行单个示例验证：`cd /g/code/guide/dotnet && "G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/<name>`。
- 提交规范：信息用中文 conventional 风格（`docs:` / `feat:` / `chore:` 前缀），结尾必须带：
  `Co-Authored-By: Claude Code <noreply@anthropic.com>`
- 每个 Task 结束时 `git status` 应干净（本 Task 的变更已提交）。

## 已核实的平台事实（第 01/19 章直接采用，执行者不得凭记忆改动）

| 事实 | 内容 | 来源 |
|---|---|---|
| .NET 10 支持矩阵 | LTS（支持至 2028-11）；Windows 10 1607+ / Win 11 / Server 2012 R2+；macOS、Linux 官方支持 | github.com/dotnet/core release-notes/10.0/supported-os.md |
| .NET 8/9 EOL | 2026-11-10 结束支持（本教程写作时 .NET 8 仅剩约两个月）→ 新项目直接用 .NET 10 | dotnet.microsoft.com/platform/support/policy/dotnet-core |
| .NET 6 | 最后一个支持 Windows 7 SP1 / 8.1 的现代 .NET；EOL 2024-11-12；官方声明"目前没有任何被支持的 .NET 版本能跑在 Win7/8.1 上" | learn.microsoft.com/dotnet/core/install/windows、devblogs.microsoft.com/dotnet/dotnet-6-end-of-support |
| Windows 8.1 | 扩展支持结束于 2023-01-10；组织 ESU 至 2024-01 | Microsoft Lifecycle |
| .NET Framework 4.8 | 支持 Win 7 SP1 / 8.1 / 10 / 11（随 OS 长期维护）；**4.8.1 仅 Win 11+ / Server 2022，不支持 8.1** | learn.microsoft.com/dotnet/framework/get-started/system-requirements |
| Mono | 最后补丁 2024-02；进入维护模式；2024-08 微软捐赠给 Wine 团队；二进制在过渡后保留最多 4 年；Unity 仍内嵌 Mono 作脚本运行时；官方建议迁移现代 .NET | mono-project.com/download/stable、mono-project.com/community、WineHQ 公告 |

## 示例目录重命名映射（Task 1 专用）

| 旧目录 | 新目录 | | 旧目录 | 新目录 |
|---|---|---|---|---|
| 01_hello_console | 02_hello | | 09_parallel_tasks | 14_parallel |
| 02_types_control | 03_types | | 10_span_memory | 15_span |
| 03_linq_basics | 09_linq | | 11_collections_mapped | 08_collections |
| 04_records_pattern | 05_records | | 12_minimal_api_mapped | 16_webapi |
| 05_generics_extensions | 06_generics | | 13_efcore_mapped | 17_efcore |
| 06_error_handling | 11_errors | | 14_testing_mapped | 18_testing |
| 07_file_json | 12_files_json | | 15_new_features_mapped | 20_modern |
| 08_async_await | 13_async | | | |

**csproj 文件名一律不改**（build.ps1 按目录枚举，文件名无影响；减小 diff 噪音）。旧 `DOTNET编程指南.md`/`README.md` 中的旧路径引用会暂时失效——这是预期的中间状态，Task 14 统一处理，**不要提前修**。

---

### Task 1: 示例目录重编号（git mv）

**Files:**
- Rename: `examples/` 下 15 个目录（映射表见上）

**Interfaces:**
- Produces: 19 个示例目录最终命名 `02_hello`…`20_modern`（中间无 01）；后续所有章节任务按新名引用。

- [ ] **Step 1: 两阶段重命名（避免目标名撞车）**

```bash
cd /g/code/guide/dotnet
declare -A M=(
  [01_hello_console]=02_hello [02_types_control]=03_types [03_linq_basics]=09_linq
  [04_records_pattern]=05_records [05_generics_extensions]=06_generics
  [06_error_handling]=11_errors [07_file_json]=12_files_json [08_async_await]=13_async
  [09_parallel_tasks]=14_parallel [10_span_memory]=15_span [11_collections_mapped]=08_collections
  [12_minimal_api_mapped]=16_webapi [13_efcore_mapped]=17_efcore
  [14_testing_mapped]=18_testing [15_new_features_mapped]=20_modern
)
for k in "${!M[@]}"; do git mv "examples/$k" "examples/_tmp_${M[$k]}"; done
for k in "${!M[@]}"; do git mv "examples/_tmp_${M[$k]}" "examples/${M[$k]}"; done
```

- [ ] **Step 2: 验证目录集合正确**

```bash
ls examples/ | sort
```
预期：`02_hello 03_types 04_records_pattern 05_generics_extensions 06_generics_extensions 07_file_json 08_async_await 08_collections 09_linq 09_parallel_tasks 10_span_memory 10_nullable? …`——**注意**：此刻新旧混杂（如 `08_async_await` 与 `08_collections` 并存、`04_records_pattern`/`05_generics_extensions` 等旧名仍在），这是正常的：Task 3/4 才创建 04_oop、07_delegates、10_nullable。核对要点：15 个 `_tmp_` 已全部消失、15 个新名全部存在。

- [ ] **Step 3: 验证全量构建仍绿**

```bash
cd /g/code/guide/dotnet && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
```
预期：`[Done] examples 目录全部编译通过。`（build.ps1 动态枚举目录，重命名不影响；`-Project` 单工程模式此时传入新目录名即可用）

- [ ] **Step 4: Commit**

```bash
cd /g/code/guide/dotnet && git add -A examples && git commit -m "refactor(dotnet): 示例目录按 20 章结构重编号

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: build.ps1 升级（递归发现 + 按工程拆分 obj）

**Files:**
- Modify: `G:\code\guide\dotnet\build.ps1`

**Interfaces:**
- Produces: `-All` 递归枚举 `examples/**/*.csproj`（Task 4 的 19_portable 嵌套工程依赖此能力）；每个工程的 obj 目录为 `build/obj/<工程名>/`。

- [ ] **Step 1: 记录当前编码状态**

```bash
cd /g/code/guide/dotnet && head -c 3 build.ps1 | od -An -tx1
```
预期输出 `ef bb bf`（有 BOM）。若无 BOM 则后续恢复 BOM 步骤跳过（保持原样）。

- [ ] **Step 2: 应用两处修改**

修改点 1——工程发现（替换 `$projects = Get-ChildItem ...` 一行与其后 `if ($projects.Count -eq 0)` 校验）：
```powershell
$projects = Get-ChildItem -LiteralPath $examplesDir -Recurse -Filter "*.csproj" | Sort-Object FullName

if ($projects.Count -eq 0) {
    throw "examples 目录下没有示例工程。"
}
```

修改点 2——`Invoke-BuildProject` 内：把 obj 路径按工程名拆分，bin 保持共享（程序集名不冲突）。将函数体中这两行：
```powershell
    & $dotnet build $csproj.FullName --nologo -v minimal `
        "-p:BaseOutputPath=$buildDir\bin\" `
        "-p:BaseIntermediateOutputPath=$buildDir\obj\"
```
改为：
```powershell
    & $dotnet build $csproj.FullName --nologo -v minimal `
        "-p:BaseOutputPath=$buildDir\bin\" `
        "-p:BaseIntermediateOutputPath=$buildDir\obj\$($csproj.BaseName)\"
```
（`$projName` 变量保留原样，仅用于日志与 `-Project` 匹配。）

同步更新 `-Project` 分支：从"取目录下第一个 csproj"改为"构建该目录下全部 csproj"：
```powershell
if ($Project) {
    $projectDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $projectDir)) {
        throw "找不到示例工程: $projectDir"
    }
    $csprojs = Get-ChildItem -LiteralPath $projectDir -Recurse -Filter "*.csproj" | Sort-Object FullName
    if ($csprojs.Count -eq 0) {
        throw "示例工程缺少 csproj: $projectDir"
    }
    foreach ($p in $csprojs) {
        Invoke-BuildProject -ProjectDir $p.DirectoryName
    }
    Write-Host "[Done] 编译通过: $Project" -ForegroundColor Green
    exit 0
}
```
并把 `-All` 分支的 `foreach ($entry in $projects) { Invoke-BuildProject -ProjectDir $entry.FullName }` 改为 `foreach ($entry in $projects) { Invoke-BuildProject -ProjectDir (Split-Path -Parent $entry.FullName) }`。

用法提示文案追加一行：
```powershell
Write-Host "  .\build.ps1 -Project 19_portable     嵌套多工程目录会构建其下全部 csproj"
```

- [ ] **Step 3: 恢复 BOM（若 Step 1 显示有 BOM）**

```bash
cd /g/code/guide/dotnet && printf '\xef\xbb\xbf' | cat - build.ps1 > build.ps1.tmp && mv build.ps1.tmp build.ps1 && head -c 3 build.ps1 | od -An -tx1
```
预期输出 `ef bb bf` 且只出现一次（若原本就无 BOM，跳过本步）。

- [ ] **Step 4: Clean → All 全量验证**

```bash
cd /g/code/guide/dotnet && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All && ls build/obj | head -20
```
预期：全部编译通过；`build/obj/` 下出现按工程名命名的子目录（HelloConsole、TypesControl…）。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dotnet && git add build.ps1 && git commit -m "feat(dotnet): build.ps1 递归发现 csproj 并按工程拆分 obj 目录

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 新示例 04_oop / 07_delegates / 10_nullable

**Files:**
- Create: `examples/04_oop/{Oop.csproj, Program.cs}`
- Create: `examples/07_delegates/{Delegates.csproj, Program.cs}`
- Create: `examples/10_nullable/{Nullable.csproj, Program.cs}`

**Interfaces:**
- Produces: 三个可编译运行的控制台工程；Task 7/8/9 的章节逐段引用下述代码。

- [ ] **Step 1: 写 04_oop**（csproj 用全局模板，文件名 `Oop.csproj`）

`examples/04_oop/Program.cs`：
```csharp
// 04_oop：类、继承、接口、多态——C# 的面向对象骨架
var shapes = new List<Shape>
{
    new Circle("c1", 2.0),
    new Square("s1", 3.0),
};

foreach (var s in shapes)
{
    Console.WriteLine(s.Describe());   // 多态：同一次调用，各自执行自己的实现
}

Report(shapes[0], new ConsoleLogger());   // 依赖接口而非具体类

var p = new Point(3, 4);                  // struct：值类型，赋值即复制
Console.WriteLine($"point={p}");

Counter.Count = 0;                        // 静态成员属于类型本身
Counter.Increment();
Console.WriteLine($"counter={Counter.Count}");

static void Report(Shape shape, ILogger logger)
{
    logger.Log(shape.Describe());
}

interface ILogger                          // 接口：只规定"能做什么"
{
    void Log(string message);
}

sealed class ConsoleLogger : ILogger       // sealed：这个类不允许再被继承
{
    public void Log(string message) => Console.WriteLine($"[log] {message}");
}

abstract class Shape(string name)          // 主构造函数（C# 12）
{
    public string Name { get; } = name;    // 只读自动属性

    public abstract double Area { get; }   // 抽象成员：子类必须实现

    public virtual string Describe() => $"{Name}: area={Area:F2}";   // 虚方法：子类可覆盖
}

class Circle(string name, double radius) : Shape(name)   // 用 base 的主构造函数链
{
    public override double Area => Math.PI * radius * radius;

    public override string Describe() => $"[圆] {base.Describe()}";   // base. 调用父类实现
}

sealed class Square(string name, double side) : Shape(name)
{
    public override double Area => side * side;
}

struct Point(int x, int y)                 // 结构体：小而不可变的值对象
{
    public int X { get; } = x;
    public int Y { get; } = y;
    public override string ToString() => $"({X},{Y})";
}

static class Counter                       // 静态类：不能实例化，只放静态成员
{
    public static int Count { get; set; }

    public static void Increment() => Count++;
}
```

- [ ] **Step 2: 写 07_delegates**

`examples/07_delegates/Program.cs`：
```csharp
// 07_delegates：委托、lambda 与事件——LINQ 与回调的前置课
Func<int, int, int> add = (a, b) => a + b;              // Func<入参…, 返回值>
Action<string> print = msg => Console.WriteLine(msg);   // Action<入参>：无返回值

Console.WriteLine(add(2, 3));
print("hello delegates");

int factor = 3;
Func<int, int> multiply = x => x * factor;              // 闭包：捕获的是变量本身
factor = 10;
Console.WriteLine(multiply(5));                         // 50 而不是 15

var cart = new Cart("cart-001");
cart.PriceChanged += name => Console.WriteLine($"[通知] {name} 价格已更新");
cart.PriceChanged += name => Console.WriteLine($"[审计] {name} 价格已更新");

cart.Price = 100m;                                      // 一次赋值，两个订阅者都被调用
cart.Price = 120m;

Console.WriteLine(Apply(3, x => x * 10));
Console.WriteLine(string.Join(",", Filter(new[] {1, 2, 3, 4, 5}, x => x % 2 == 0)));

static int Apply(int input, Func<int, int> transform) => transform(input);

static List<T> Filter<T>(IEnumerable<T> source, Func<T, bool> predicate)
{
    var result = new List<T>();
    foreach (var item in source)
    {
        if (predicate(item)) result.Add(item);
    }
    return result;
}

class Cart(string id)
{
    private decimal _price;

    public string Id { get; } = id;

    public decimal Price
    {
        get => _price;
        set
        {
            if (_price == value) return;
            _price = value;
            PriceChanged?.Invoke(Id);      // ?. 触发：没有订阅者时避免 NullReferenceException
        }
    }

    public event Action<string>? PriceChanged;   // 事件：外部只能 += / -=，不能直接调用
}
```

- [ ] **Step 3: 写 10_nullable**

`examples/10_nullable/Program.cs`：
```csharp
// 10_nullable：可空引用类型（NRT）——编译器帮你盯住 null
string title = "hello";          // 非可空引用类型：承诺不为 null
string? subtitle = null;         // ? 声明"可能为 null"，编译器放松限制

Console.WriteLine(title.Length);
// Console.WriteLine(subtitle.Length);   // CS8602 警告：可能为 null 的解引用
Console.WriteLine(subtitle?.Length ?? -1);                       // 写法 1：?. 配 ??
Console.WriteLine(subtitle is null ? "(空)" : subtitle);         // 写法 2：判空后编译器"流"出非空

int? maybeScore = null;                                  // 可空值类型 int?
Console.WriteLine($"score={maybeScore ?? 0}");

var found = FindUser("alice");
Console.WriteLine(found?.Name ?? "(未找到)");

if (FindUser("bob") is { } bob)                          // 属性模式：非空才进入分支
{
    Console.WriteLine($"bob 的邮箱: {bob.Email ?? "未填写"}");
}

Console.WriteLine(Shout(title)!);                        // ! 断言非空：确信时才用，用错就是 NRE

static User? FindUser(string name) =>
    name == "alice" ? new User("alice", "alice@example.com") : null;

static string? Shout(string? input) => input?.ToUpperInvariant();

record User(string Name, string? Email);
```

- [ ] **Step 4: 三个工程构建 + 运行验证（含中文输出不乱码）**

```bash
cd /g/code/guide/dotnet && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/04_oop
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/07_delegates
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/10_nullable
```
预期：全部编译通过；运行输出中文正常显示（无 `??`/乱码——若有，说明 .cs 文件编码被写成 GBK/ANSI，用 UTF-8 重写）。10_nullable 的输出应含 `[通知] cart-001 价格已更新`…（07_delegates 的输出）等预期文案。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dotnet && git add examples/04_oop examples/07_delegates examples/10_nullable && git commit -m "feat(dotnet): 新增 oop/delegates/nullable 三个教学示例

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 新示例 19_portable（嵌套多工程，netstandard2.0 + net10.0）

**Files:**
- Create: `examples/19_portable/PortableLib/{PortableLib.csproj, Greeting.cs}`
- Create: `examples/19_portable/PortableApp/{PortableApp.csproj, Program.cs}`

**Interfaces:**
- Consumes: Task 2 的递归 csproj 发现。
- Produces: `PortableLib.Greeting` 静态类（`Runtime`/`BuildFilePath`/`Format` 成员）+ 消费它的 net10.0 控制台；Task 13 的 19 章逐段引用。

- [ ] **Step 1: 写 PortableLib**

`examples/19_portable/PortableLib/PortableLib.csproj`：
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>netstandard2.0;net10.0</TargetFrameworks>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>disable</ImplicitUsings>
  </PropertyGroup>
</Project>
```
（教学点：netstandard2.0 默认 LangVersion 是 7.3，显式 `latest` 才能用文件范围命名空间等新语法；`ImplicitUsings` 关掉以展示显式 using——这两点第 19 章都要讲。）

`examples/19_portable/PortableLib/Greeting.cs`：
```csharp
using System;
using System.IO;

namespace PortableLib;

// 可移植类库：只依赖 netstandard2.0 的 API 面
// —— .NET Framework 4.6.1+ / Mono / Unity / 现代 .NET 都能消费
public static class Greeting
{
    // 可移植习惯 1：Path.Combine 拼路径，不手写 '\\' 或 '/'
    public static string BuildFilePath(string dir, string name) => Path.Combine(dir, name);

    // 可移植习惯 2：显式 UTF8，行尾交给 Environment.NewLine
    public static string Format(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException("name 不能为空", nameof(name));
        }

        return "hello, " + name + Environment.NewLine;
    }

    // 条件编译：不同目标框架各取所需
#if NET
    public static string Runtime => ".NET (Core) 5+";
#elif NETFRAMEWORK
    public static string Runtime => ".NET Framework / Mono";
#else
    public static string Runtime => "纯 netstandard 实现";
#endif
}
```

- [ ] **Step 2: 写 PortableApp**

`examples/19_portable/PortableApp/PortableApp.csproj`：
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\PortableLib\PortableLib.csproj" />
  </ItemGroup>
</Project>
```

`examples/19_portable/PortableApp/Program.cs`：
```csharp
using PortableLib;

Console.WriteLine(Greeting.Runtime);                          // net10.0 目标 → ".NET (Core) 5+"
Console.WriteLine(Greeting.BuildFilePath("data", "notes.txt")); // Windows 上输出 data\notes.txt
Console.Write(Greeting.Format("portable"));
```

- [ ] **Step 3: 构建并运行验证**

```bash
cd /g/code/guide/dotnet && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/19_portable/PortableApp
```
预期：PortableLib（两个 TargetFramework 各编一次）与 PortableApp 都编译通过；运行输出三行，含 `.NET (Core) 5+` 与 `hello, portable`。

- [ ] **Step 4: Commit**

```bash
cd /g/code/guide/dotnet && git add examples/19_portable && git commit -m "feat(dotnet): 19_portable 多目标可移植示例（netstandard2.0 库 + net10.0 应用）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: docs/01-overview.md（平台全景与工具链）

**Files:**
- Create: `G:\code\guide\dotnet\docs\01-overview.md`

**Interfaces:**
- Produces: 教程入口章；后续章节以"第 01 章说过"引用其支持矩阵/工具链；README（Task 14）链接本章。

- [ ] **Step 1: 写文件**，结构（约 150 行）：
  1. `# 01 · .NET 全景：平台、运行时与工具链`（无 `> 对应示例` 行；开头一段说明本教程读者定位：会编程、初学 C#/.NET）
  2. `## 1. .NET 是什么`：C#（语言）与 .NET（平台）的关系；编译到 IL → CLR JIT 执行；BCL 概念。一张小图（文本框图）：`C# 源码 → Roslyn → IL → CLR(JIT) → 机器码`
  3. `## 2. 家族史一页纸`：.NET Framework（2002，仅 Windows）→ .NET Core（跨平台重写）→ .NET 5+ 统一命名（跳过"Core 4.0"避免与 4.x 混淆）→ 本文写作时的 .NET 10 LTS；Mono 一段（历史角色，详见第 19 章）
  4. `## 3. 支持矩阵速览与选型`：用"已核实事实"表里的矩阵做表格；决策要点：新项目 → .NET 10；目标机 Win 8.1/7 → 现代 .NET 无解（.NET 6 已 EOL 2024-11-12），遗留方案见第 19 章；本教程主线 .NET 10
  5. `## 4. SDK 与命令行`：本机 SDK 路径与 `--version`；`dotnet new/build/run` 三板斧；本教程示例均为单工程单 Program.cs
  6. `## 5. 读懂 csproj`：引用 `examples/02_hello/HelloConsole.csproj`（即旧 01_hello_console 的 csproj，内容见全局模板）逐字段讲解：Sdk 属性、OutputType、TargetFramework、ImplicitUsings、Nullable
  7. `## 6. 本教程怎么用`：20 章路线表（两列：章号+主题、对应示例目录）；`build.ps1 -All / -Project / -Clean` 三个命令；建议每章"读讲解 → 跑示例 → 改代码再跑"
  8. `## 7. 坑位清单`：SDK 版本不匹配（`NETSDK1045`）、powershell 执行策略、公司内网 NuGet 源

- [ ] **Step 2: 验证**：文件 100–200 行；`grep -c '^## ' docs/01-overview.md` 在 6–8 之间；文中 `examples/02_hello` 引用的 csproj 字段与实际文件一致（`cat examples/02_hello/HelloConsole.csproj` 对照）。

- [ ] **Step 3: Commit**

```bash
cd /g/code/guide/dotnet && git add docs/01-overview.md && git commit -m "docs(dotnet): 第 01 章平台全景

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: docs/02-hello.md + docs/03-types.md

**Files:**
- Create: `docs/02-hello.md`（示例 `examples/02_hello`，代码 11 行：顶层语句 + 插值 + 原始字符串 JSON）
- Create: `docs/03-types.md`（示例 `examples/03_types`，代码 17 行：switch 表达式 + foreach 累加）

- [ ] **Step 1: 写 02-hello.md**（约 110 行）：
  1. `# 02 · 第一个程序：从 Main 到顶层语句` + `> 对应示例：examples/02_hello`
  2. 先讲问题：为什么 C# 11 起可以整个 Program 只有几行——编译器在背后生成 `Main`；给出等价的经典写法对比（`class Program { static void Main() {...} }`）
  3. 插值字符串 `$"Hello, {name}!"`；格式项 `${expr:F2}`/对齐示例片段
  4. 原始字符串字面量 `"""..."""`（引用示例 JSON 段），何时优于转义
  5. 逐行讲解示例全文（11 行全引用）
  6. `## 坑位清单`：顶层语句只能一个文件有；`$` 与 `@` 顺序（`$@""` vs `@$""` 等价、`$"""` 内插 `{}`）；分号可省与不可省

- [ ] **Step 2: 写 03-types.md**（约 180 行）：
  1. `# 03 · 类型与控制流：C# 的地面规则` + `> 对应示例：examples/03_types`
  2. 基本类型表：`int/long/double/decimal/bool/char/string`（含典型字面量与场景，`decimal` 钱款、`double` 科学计算）
  3. `var`：编译期推断、只能局部变量、可读性取舍
  4. 数组 `new[] {...}` 与集合预告（指向第 08 章）
  5. `string` 不可变：拼接成本、`StringBuilder` 预告（第 20 章示例用到）；常用成员表（`Length/Substring/Contains/Replace/Split`）
  6. `switch` 表达式 vs 语句：引用示例 `sign` 段（关系模式 `> 0`）；穷尽性与 `_`
  7. 循环：`for/foreach/while`；引用示例 foreach 累加段
  8. 方法与参数（本示例无，用补充片段讲）：`out`（配 `TryParse`，预告第 11 章）、`ref/in`、`params`、默认参数
  9. `> 跨平台提示`：`char` 是 UTF-16 code unit；读写文件显式 `Encoding.UTF8`（详见第 12 章）
  10. `## 坑位清单`：整数溢出默认不抛异常、`/` 整型截断、`==` 与字符串（引用第 05 章值语义）、`decimal` 后缀 `m`

- [ ] **Step 3: 验证**：两文件各 100–200 行；引用片段与 `examples/02_hello/Program.cs`、`examples/03_types/Program.cs` 逐字对照。

- [ ] **Step 4: Commit**

```bash
cd /g/code/guide/dotnet && git add docs/02-hello.md docs/03-types.md && git commit -m "docs(dotnet): 第 02/03 章 hello 与类型控制流

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: docs/04-oop.md + docs/05-records.md + docs/06-generics.md

**Files:**
- Create: `docs/04-oop.md`（示例 `examples/04_oop`，Task 3 代码）
- Create: `docs/05-records.md`（示例 `examples/05_records`，12 行：record + 属性模式 + 解构）
- Create: `docs/06-generics.md`（示例 `examples/06_generics`，15 行：`Sum<T> where T : INumber<T>` + 扩展调用）

- [ ] **Step 1: 写 04-oop.md**（约 200 行）：
  1. `# 04 · 面向对象：类、继承、接口与多态`
  2. 问题先行：多态解决"新增形状不改调用方"——引用示例 `List<Shape>` 遍历段
  3. 类与成员：字段 vs 属性、自动属性、只读 `{ get; }`、主构造函数（C# 12）与 `base(...)` 链
  4. 继承：`virtual/override/abstract/sealed` 四件套语义表；`base.Describe()` 引用示例 Circle 段
  5. 接口：`ILogger` 段；"面向接口编程"（`Report(Shape, ILogger)`）；接口 vs 抽象类对比表
  6. `struct Point` 段：值语义、栈分配预告（第 15 章）；class vs struct 选型表（大小/可变性/装箱）
  7. `static class Counter` 段：静态成员、静态类
  8. `## 坑位清单`：隐藏 new 方法 vs override、构造链忘 base、struct 可变性的坑、主构造函数参数捕获为字段时机

- [ ] **Step 2: 写 05-records.md**（约 160 行）：
  1. `# 05 · record 与模式匹配：数据优先的类型`
  2. 问题先行：示例一行 `record User(string Name, int Age)` 生成了什么（构造/属性/Equals/GetHashCode/ToString/Deconstruct）与手写 class 等价物的对比表
  3. 值语义 vs 引用语义：两个相同 `new User("alice", 22)` 判等的演示片段
  4. `with` 表达式、解构（引用示例 `var (name, age) = u;`）
  5. 模式匹配：属性模式 `{Age: < 18}`、组合 `and`、`_` 兜底（引用示例 switch 段，逐行讲）；`is { } u` 非空模式（连第 10 章）
  6. `record class` vs `record struct` 一段
  7. `## 坑位清单`：record 里放可变集合、继承 record 的相等性陷阱、`with` 是浅拷贝

- [ ] **Step 3: 写 06-generics.md`（约 140 行）：
  1. `# 06 · 泛型与扩展方法：写一次，处处安全`
  2. 问题先行：没有泛型的世界（object 装箱 + 强转）演示片段
  3. 引用示例 `Sum<T>` 全文：`where T : INumber<T>` 约束、`T.Zero`、静态抽象接口成员（泛型数学）；约束种类表（`class/struct/new()/接口/unmanaged/notnull`）
  4. 泛型类/方法/接口一句话各带片段；类型推断
  5. 扩展方法：`"dotnet".Reverse()` 为什么能点出来——`this` 参数 + 静态类；引用示例最后两行；自定义扩展方法预告（第 08 章的 `PopIfMatch`）
  6. `## 坑位清单`：协变逆变滥用、扩展方法"发现不了"（缺 using）、泛型 + 运算符在 C# 10 前不可写

- [ ] **Step 4: 验证**：三文件行数 100–200；片段与 `examples/04_oop`、`examples/05_records`、`examples/06_generics` 逐字对照（05/06 是旧 04/05 的代码原样迁移，未改动）。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dotnet && git add docs/04-oop.md docs/05-records.md docs/06-generics.md && git commit -m "docs(dotnet): 第 04/05/06 章 OOP、record、泛型

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 8: docs/07-delegates.md + docs/08-collections.md + docs/09-linq.md

**Files:**
- Create: `docs/07-delegates.md`（示例 `examples/07_delegates`，Task 3 代码）
- Create: `docs/08-collections.md`（示例 `examples/08_collections`，61 行：List/Dictionary 操作 + 自定义扩展方法）
- Create: `docs/09-linq.md`（示例 `examples/09_linq`，22 行：匿名类型 + Where/OrderBy/ThenBy/Select/GroupBy）

- [ ] **Step 1: 写 07-delegates.md**（约 170 行）：
  1. `# 07 · 委托、lambda 与事件：把方法当值传`
  2. 问题先行：回调/策略需要"方法的类型"；`delegate` 关键字一句带过，主力是内置 `Func<>`/`Action<>`（变长类型参数表）
  3. lambda 语法（引用示例 add/print）；语句体 vs 表达式体
  4. 闭包：引用示例 `multiply` 段——**捕获变量本身**，`factor=10` 后调用得 50；循环变量捕获经典坑
  5. 事件：`event` 字段、`+=`/`-=`、`?.Invoke`（引用示例 Cart 段完整讲解）；事件 vs 公开委托字段（封装性）
  6. `Filter<T>` 段收尾：你已经手写了 `Where`——下一章 LINQ 就是把这个模式产品化
  7. `## 坑位清单`：忘退订事件 → 泄漏、多播委托返回值只留最后一个、闭包修改捕获变量、`?.Invoke` 与线程安全一句

- [ ] **Step 2: 写 08-collections.md**（约 150 行）：
  1. `# 08 · 集合：List、Dictionary 与 IEnumerable`
  2. 选型表：`List/Dictionary/HashSet/Queue/Stack`（用途/查找复杂度）
  3. List：引用示例 fruits 段（Add/Insert/Remove/FindIndex）
  4. Dictionary：引用示例 ages 段（索引器/TryAdd/Remove/KeyValuePair）；`TryGetValue` + out（连第 03 章 out）
  5. `IEnumerable<T>` 抽象 + 迭代器 `yield return`（补充片段：手写 Count 方法演示惰性）
  6. 自定义扩展方法：引用示例 `PopIfMatch` 段（`this List<T>` + `Predicate<T>`，呼应第 06/07 章）
  7. `## 坑位清单`：遍历时修改集合、结构体字典键可变、List.Contains 是 O(n) 误当 HashSet

- [ ] **Step 3: 写 09-linq.md**（约 170 行）：
  1. `# 09 · LINQ：集合查询的一等语法`
  2. 问题先行：手写 foreach 过滤排序（第 08 章 `namesLongerThan3` 的影子）vs 一条方法链
  3. 引用示例 `09_linq` 全文逐段：匿名类型 `new {}`、`Where/OrderByDescending/ThenBy/Select/ToList`、`GroupBy` 与 `g.Key`/`g.Select`
  4. 方法链 vs 查询表达式（`from x in data where ... select ...`）对照表：何时用哪个
  5. 聚合与元素：`Sum/Average/Count/Min/Max/First/FirstOrDefault/Single` 补充片段（`FirstOrDefault` 连第 10 章可空返回）
  6. **延迟执行**：`IEnumerable` 不 ToList 就每次重新算；多次枚举陷阱片段（同一 query 两次 Count 触发两轮计算）；`ToList/ToArray` 固化
  7. `## 坑位清单`：多次枚举、在 LINQ 里做副作用、`IEnumerable` 泄露到接口签名（暴露实现）、GroupBy 后乱序

- [ ] **Step 4: 验证**：行数 100–200；片段逐字对照三个示例源码。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dotnet && git add docs/07-delegates.md docs/08-collections.md docs/09-linq.md && git commit -m "docs(dotnet): 第 07/08/09 章 委托、集合、LINQ

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 9: docs/10-nullable.md + docs/11-errors.md

**Files:**
- Create: `docs/10-nullable.md`（示例 `examples/10_nullable`，Task 3 代码）
- Create: `docs/11-errors.md`（示例 `examples/11_errors`，23 行：元组返回 TryParse 风格 + try/catch）

- [ ] **Step 1: 写 10-nullable.md**（约 150 行）：
  1. `# 10 · 可空引用类型：编译器替你盯 null`
  2. 问题先行：`NullReferenceException` 占新手异常大头；NRT 是**编译期警告流分析**，不是运行时检查——这句要加粗
  3. `string` vs `string?` 语义承诺；引用示例 title/subtitle 段；CS8602 警告注释行讲解
  4. 正确处理四式：`?.`+`??`、`is null` 判断后流分析、`is { } x` 模式、`!` 断言（何时合法何时掩盖 bug）——各引用示例对应行
  5. `int?` 可空值类型：`?? 0`、`.Value` 慎用；引用示例 maybeScore 段
  6. API 边界：返回 `User?`（引用示例 `FindUser`）；record 字段可空（`string? Email`）；方法签名表达"找不到"优于返回魔法值
  7. csproj `<Nullable>enable</Nullable>` 开关与遗留代码 `#nullable disable` 注解
  8. `## 坑位清单`：`!` 滥用、`??` 抛新异常掩盖来源、可空注解只对引用类型是"提示"、反序列化结果未判空（连第 12 章）

- [ ] **Step 2: 写 11-errors.md**（约 150 行）：
  1. `# 11 · 错误处理：异常、TryParse 与 Result`
  2. 异常模型：调用栈展开、`Exception` 层次小图；`try/catch/finally` 基本形（引用示例 catch 段）
  3. catch 顺序与具体化；异常过滤器 `when` 补充片段；`throw;` vs `throw ex;`（栈迹保留）
  4. 预期失败不该用异常：引用示例 `ParsePositive` 全文——元组 `(bool ok, int value, string error)` 返回；对比 `int.TryParse` + out（连第 03 章）
  5. Result 模式：简易 `record Result<T>(bool Ok, T? Value, string? Error)` 补充片段；何时用异常（真正的异常路径）vs Result（可预期失败）决策表
  6. `## 坑位清单`：`catch (Exception)` 吞掉一切、空 catch 块、finally 里 return、异常做流程控制的性能

- [ ] **Step 3: 验证**：行数、片段对照同前。

- [ ] **Step 4: Commit**

```bash
cd /g/code/guide/dotnet && git add docs/10-nullable.md docs/11-errors.md && git commit -m "docs(dotnet): 第 10/11 章 可空引用类型与错误处理

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 10: docs/12-files-json.md + docs/13-async.md

**Files:**
- Create: `docs/12-files-json.md`（示例 `examples/12_files_json`，13 行：Path.Combine + 序列化/反序列化 record）
- Create: `docs/13-async.md`（示例 `examples/13_async`，25 行：WhenAll + IAsyncEnumerable）

- [ ] **Step 1: 写 12-files-json.md**（约 150 行）：
  1. `# 12 · 文件与 JSON：最常用的 IO 两件套`
  2. File 静态便利方法表（`ReadAllText/WriteAllText/AppendAllText/Exists/Delete`）与大文件 → Stream 一句话预告
  3. `Path.Combine/GetTempPath/GetFileName`；引用示例 path 段
  4. `> 跨平台提示`：分隔符交给 `Path`、行尾 `Environment.NewLine`、**读写必须显式 `Encoding.UTF8`**（默认编码随平台/语言设置漂移——坑位清单第 1 条）
  5. System.Text.Json：引用示例 Serialize/Deserialize 全段；`WriteIndented`；属性名策略 camelCase；record 天然适配（连第 05 章）
  6. `Deserialize<T>` 返回 `T?`（连第 10 章）；`JsonSerializerOptions` 复用（性能）
  7. `## 坑位清单`：无 Encoding 参数在非英文 Windows 上乱码、临时文件不清理、反序列化字段名不匹配静默得 null

- [ ] **Step 2: 写 13-async.md**（约 180 行）：
  1. `# 13 · async/await：异步编程的日常形态`
  2. 问题先行：IO 等待时线程空转浪费；`Task` = "正在进行的工作的凭据"；await = "等它完成，期间线程去干别的"（一句直觉，不展开状态机细节）
  3. 方法标记传染性：`async Task<int>`（引用示例 `WorkAsync`）；返回值即 Task
  4. 并发：逐个 await（串行）vs `Task.WhenAll`（并发）耗时对比片段；引用示例 tasks 段
  5. `IAsyncEnumerable<T>` + `await foreach`：引用示例 `SequenceAsync` 段；与第 08 章 `yield` 的关系（惰性流的异步版）
  6. 取消配合一句：`CancellationToken` 穿透（预告第 14 章）
  7. `## 坑位清单`：**`async void`**（只有事件处理器可用）、`.Result/.Wait()` 死锁、忘 await 静默丢异常、循环里逐个 await 该用 WhenAll、async 方法里 `ConfigureAwait` 在库代码的意义

- [ ] **Step 3: 验证 + Commit**

```bash
cd /g/code/guide/dotnet && git add docs/12-files-json.md docs/13-async.md && git commit -m "docs(dotnet): 第 12/13 章 文件 JSON 与异步

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 11: docs/14-parallel.md + docs/15-span.md

**Files:**
- Create: `docs/14-parallel.md`（示例 `examples/14_parallel`，16 行：Parallel.ForEach + ConcurrentDictionary + Interlocked）
- Create: `docs/15-span.md`（示例 `examples/15_span`，21 行：Span 切 CSV + stackalloc）

- [ ] **Step 1: 写 14-parallel.md**（约 150 行）：
  1. `# 14 · 并行：数据并行与共享状态`
  2. 并发 vs 并行（第 13 章异步是并发等待 IO，本章是吃满 CPU）
  3. `Parallel.ForEach`：引用示例段；与 PLINQ `AsParallel()` 一句对照
  4. 共享状态竞争：先给"裸 `total++` 会丢更新"的反例片段（多线程交错），再引出 `Interlocked.Add`（引用示例）；为什么 `total++` 不是原子的
  5. `ConcurrentDictionary`：引用示例 dict 段；`dict[n] = sq` 并发安全写入；与加锁 `lock` 对比表；`ConcurrentQueue/Bag` 一句
  6. `## 坑位清单`：闭包捕获循环变量在并行下的旧坑（C# 5+ foreach 安全，for 仍要局部拷贝）、并行度不是越大越快、Parallel.ForEach 里抛异常聚合 `AggregateException`、异步 lambda 进 Parallel 重载

- [ ] **Step 2: 写 15-span.md**（约 160 行）：
  1. `# 15 · Span 与 Memory：少分配的高性能之道`
  2. 问题先行：`text.Split(',')` 每字段都分配新 string + 数组；分配 → GC 压力 → 停顿
  3. `ReadOnlySpan<char>` + 切片 `span[start..i]`：引用示例 CSV 解析段全文逐行；`int.Parse(ReadOnlySpan<char>)` 无分配重载
  4. 索引与范围：`span[^1]`、`span[..n]` 语法表（引用示例 `data[^1]`）
  5. `Span<int>` + `stackalloc`：引用示例段；栈上缓冲，方法返回即释放
  6. Span 的纪律：不能存为字段、不能跨 await、不能装箱——栈专用窗口；需要跨边界用 `Memory<T>`
  7. 何时用：先用 LINQ 写对，剖析（`dotnet-counters`/BenchmarkDotNet 一句）证明热点再换 Span
  8. `## 坑位清单`：Span 指向的数组被改、stackalloc 大小失控、在 async 方法里用 Span 编译错、为快而难维护

- [ ] **Step 3: 验证 + Commit**

```bash
cd /g/code/guide/dotnet && git add docs/14-parallel.md docs/15-span.md && git commit -m "docs(dotnet): 第 14/15 章 并行与 Span

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 12: docs/16-webapi.md + docs/17-efcore.md + docs/18-testing.md

**Files:**
- Create: `docs/16-webapi.md`（示例 `examples/16_webapi`，51 行：Minimal API CRUD）
- Create: `docs/17-efcore.md`（示例 `examples/17_efcore`，40 行：InMemory DbContext CRUD）
- Create: `docs/18-testing.md`（示例 `examples/18_testing`，93 行：AssertEx 自检 + Calculator/FakeLogger）

- [ ] **Step 1: 写 16-webapi.md**（约 170 行）：
  1. `# 16 · ASP.NET Core Minimal API：几十行起一个服务`
  2. 模型：Kestrel 宿主 + 中间件管道一段直觉；`WebApplication.CreateBuilder/Build`
  3. 路由：`MapGet/MapPost/MapDelete`；路由参数 `{id:int}` 约束；引用示例各端点段
  4. 类型化结果 `Results.Ok/NotFound/Created/BadRequest`：比裸返回字符串好在哪（状态码 + 内容协商）
  5. 请求体绑定：`UserCreate` record 自动反序列化（连第 12 章）；模型校验手写段（引用示例 `IsNullOrWhiteSpace` 检查）
  6. DI 一小节：`builder.Services` 注册 → 端点参数注入的补充片段
  7. 运行与验证：`--run` 设计说明（示例默认只编译不监听端口，方便 CI；传 `--run` 启动）+ `curl` 三个实测命令与预期响应
  8. `## 坑位清单`：路由顺序（具体在前通配在后）、返回匿名对象 vs record、忘记 `app.Run()`、端口占用

- [ ] **Step 2: 写 17-efcore.md`（约 150 行）：
  1. `# 17 · EF Core：用 C# 对象对抗 SQL 样板`
  2. ORM 直觉：LINQ → SQL 翻译（连第 09 章）；`DbContext` = 工作单元、`DbSet<T>` = 仓库
  3. 引用示例实体段（`User` 带 `Id/Name/Email`，`string.Empty` 初始化连第 10 章非空警告）；DbContext + `OnConfiguring` 段
  4. CRUD 四式引用示例：`AddRange + SaveChanges`、`FirstOrDefault` 查询、改属性后 `SaveChanges`（变更追踪：只改属性即可，没有 Update 调用）、`ToList`
  5. InMemory 提供程序：教学取舍说明——真库用 `UseSqlServer/UseSqlite`；InMemory 不是关系数据库（不校验外键/约束）
  6. `EnsureCreated` vs Migrations 一段（`dotnet ef migrations add` 命令示例）
  7. `## 坑位清单`：忘 `SaveChanges`、查询已被跟踪实体改了属性误提交、N+1 查询与 `Include`、InMemory 测试通过 ≠ SQL 行为

- [ ] **Step 3: 写 18-testing.md**（约 160 行）：
  1. `# 18 · 测试：从第一个断言到可测设计`
  2. 本示例的形态说明：xUnit 风格自检控制台（`AssertEx` + `Main` 顺序执行）——为了进 build.ps1 统一构建；真项目 `dotnet new xunit` 起步，`[Fact]/[Theory]` 对照片段
  3. AAA：Arrange/Act/Assert，引用示例 `Add/Divide` 断言段
  4. 断言设计：`Equal/True/Throws<T>` 的选择（引用示例 AssertEx 实现逐个讲——为什么 `EqualityComparer<T>.Default`）
  5. 测试替身：`FakeLogger` 实现 `ILogger`（连第 04 章接口）——为什么可测设计依赖抽象；stub/fake/mock 一句话分家
  6. 异步测试：`AddAsync` 段（await 后断言）
  7. `## 坑位清单`：断言里写逻辑、测试互相依赖共享状态、测实现而非行为、`Math.Abs(x-y)<eps` 浮点比较（示例已示范）

- [ ] **Step 4: 验证 + Commit**

```bash
cd /g/code/guide/dotnet && git add docs/16-webapi.md docs/17-efcore.md docs/18-testing.md && git commit -m "docs(dotnet): 第 16/17/18 章 Web API、EF Core 与测试

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 13: docs/19-portable.md + docs/20-modern-csharp.md

**Files:**
- Create: `docs/19-portable.md`（示例 `examples/19_portable`，Task 4 代码）
- Create: `docs/20-modern-csharp.md`（示例 `examples/20_modern`，68 行：数字分隔符/partial/泛型数学/StringBuilder/await foreach）

- [ ] **Step 1: 写 19-portable.md**（约 200 行，事实用"已核实的平台事实"表，含来源链接）：
  1. `# 19 · 跨平台与可移植性：从 Windows 8.1 到 macOS/Linux`
  2. `## 1. 支持矩阵与残酷现实`：矩阵表（.NET 10 = Win10 1607+ / macOS / Linux；Win 8.1 → 现代 .NET 无被支持版本，.NET 6 已 EOL 2024-11-12；.NET Framework 4.8 支持 8.1 但仅 Windows；Mono 维护模式）；明确结论：**Win 8.1 上没有"现代 .NET"正解**，选择是 ①遗留系统继续 Framework 4.8 / Mono 维护 ②推动升级 OS
  3. `## 2. netstandard2.0：可移植库的通用语`：谁消费它（Framework 4.6.1+/Mono/Unity/现代 .NET）；引用示例 PortableLib.csproj 的 `TargetFrameworks` 多目标行
  4. `## 3. 多目标与条件编译`：`<TargetFrameworks>netstandard2.0;net10.0</TargetFrameworks>`；`#if NET / NETFRAMEWORK`（引用示例 `Greeting.Runtime` 段）；常用符号表（NET/net8_0/NETFRAMEWORK/NETSTANDARD）
  5. `## 4. LangVersion 与语法兼容`：netstandard2.0 默认 C# 7.3；显式 `latest` 的得与失（引用示例 csproj）；record 在旧目标的 `IsExternalInit` polyfill 一段
  6. `## 5. 可移植编码清单`：Path.Combine、Environment.NewLine、显式 Encoding.UTF8、`/` 与 `\`（连第 03/12 章）；文件名大小写敏感（Linux）；`Environment.OSPlatform` 平台分支补充片段
  7. `## 6. 发布模型`：RID 概念与 `-r win-x64/linux-x64/osx-arm64`；framework-dependent vs **self-contained**（目标机免装运行时——Win 8.1 场景的替代思路：.NET 6 self-contained 已无安全补丁，诚实告知）；single-file；`dotnet publish` 命令实例
  8. `## 7. Mono：过去与现在`：跨平台先行者 → 2024-02 最后补丁 → 维护模式 → 捐赠 Wine 团队；Unity 仍内嵌；何时还会遇见它、迁移到现代 .NET 的官方建议
  9. `## 8. 示例走读`：19_portable 结构（两个工程）、运行输出、动手改：把 PortableApp 改 TargetFramework 为 net8.0 编译观察
  10. `## 坑位清单`：在 netstandard 库里用了仅现代 .NET 的 API（编译即报）、条件编译区太宽难维护、忘记多目标restore、Linux 大小写

- [ ] **Step 2: 写 20-modern-csharp.md**（约 150 行）：
  1. `# 20 · 现代 C# 纵览：从 C# 9 到 13+`
  2. 版本时间线表（C# 9 record/init/模式增强 → 10 全局 using/文件范围命名空间 → 11 raw string/required/列表模式 → 12 主构造函数/collection expressions/别名任何类型 → 13 params 集合/lock 对象/转义三元反引号——每行"一句它替你省了什么"）；教程各章已讲特性标"第 NN 章"
  3. 走读示例 `20_modern`：数字分隔符与二进制字面量（`1_000_000`/`0b1010_1010`）；partial 类与 partial void 演进（编译器缝合、无实现时调用整体消失）；`AddNumbers<T>` 泛型数学（呼应第 06 章）；`StringBuilder` 循环拼接（呼应第 03 章不可变）；`await foreach`（呼应第 13 章）；Span `IndexOf + 切片`（呼应第 15 章）
  4. 怎么跟进新版本：Roslyn 版本跟 SDK 走；`LangVersion` 只开语法不开运行时库支持（连第 19 章）
  5. `## 坑位清单`：新语法 ≠ 新运行时可用（运行时库/attribute 缺失）、团队最低 SDK 版本、过度追求新糖

- [ ] **Step 3: 验证 + Commit**

```bash
cd /g/code/guide/dotnet && git add docs/19-portable.md docs/20-modern-csharp.md && git commit -m "docs(dotnet): 第 19/20 章 跨平台可移植性与现代 C# 纵览

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 14: README 重写 + CHEATSheet 更新 + 旧文件删除

**Files:**
- Modify: `G:\code\guide\dotnet\README.md`（全文重写）
- Modify: `G:\code\guide\dotnet\CHEATSheet.md`
- Delete: `DOTNET编程指南.md`、`SAMPLES_MIGRATION_MAP.md`、`samples/`（整个目录）

- [ ] **Step 1: 重写 README.md**（约 70 行）：目录树（docs/ 20 章 + examples/ 19 工程 + build.ps1 + CHEATSheet.md + advanced/）；20 章索引表（每行：`NN. [标题](docs/NN-xxx.md)` + 对应示例目录）；构建命令三则（-All/-Project/-Clean）；`advanced/` 一句话说明（预留扩展阅读）。开头一段说明教程定位（会编程、初学 C#/.NET，主线 .NET 10）。

- [ ] **Step 2: 更新 CHEATSheet.md**：保留现有 checklist 骨架，把"环境设置/项目创建"区指向 `docs/01-overview.md`；新增"章节速查"区：20 章一行链接；新增"高频坑位速查"区：从各章坑位清单摘 8–10 条一句话条目（每条附章节链接）。

- [ ] **Step 3: 删除旧文件**

```bash
cd /g/code/guide/dotnet && git rm -r --cached DOTNET编程指南.md SAMPLES_MIGRATION_MAP.md samples/ 2>/dev/null; git rm -f DOTNET编程指南.md SAMPLES_MIGRATION_MAP.md && git rm -rf samples/
```
（若部分文件未跟踪则直接 `rm -rf` 后 `git add -A`。）

- [ ] **Step 4: 残留引用检查**

```bash
cd /g/code/guide/dotnet && grep -rn "DOTNET编程指南\|_mapped\|samples/" --include="*.md" --include="*.ps1" . | grep -v "^\./build/"
```
预期：无输出（或仅 build/ 产物目录）。有输出则逐条修复。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dotnet && git add -A && git commit -m "docs(dotnet): 重写 README、更新速查表、删除旧指南与 samples 目录

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 15: 终验（全量构建 + 运行抽查 + 链接完整性）

**Files:**
- 无新文件；本任务只验证与修复。

- [ ] **Step 1: 干净构建**

```bash
cd /g/code/guide/dotnet && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean && powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
```
预期：19 个工程（18 个根级 + 19_portable 下 2 个）全部编译通过。

- [ ] **Step 2: 运行抽查**（覆盖新增示例与中文字符路径）：

```bash
cd /g/code/guide/dotnet
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/02_hello
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/04_oop
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/10_nullable
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/19_portable/PortableApp
"G:/scoop/apps/dotnet-sdk/current/dotnet.exe" run --project examples/12_files_json
```
预期：各程序按设计输出、中文不乱码；12_files_json 正常读写临时文件后打印 `1:alice`。

- [ ] **Step 3: 文档完整性**

```bash
cd /g/code/guide/dotnet
ls docs/ | wc -l                      # 预期 20
grep -rn "第 [0-9]* 章" docs/ -o | sort -u   # 人工核对引用的章号 ≤ 20 且合理
grep -rhn "examples/" docs/ -o | grep -oE "examples/[0-9a-z_/]+" | sort -u
```
最后一条输出的每个路径逐一 `test -d` / `test -f` 核对存在。

- [ ] **Step 4: 收尾**

```bash
cd /g/code/guide/dotnet && git status --short && git log --oneline -15
```
工作区应为干净（或仅剩本任务的修复，则修复后提交 `fix(dotnet): 终验修复`，同样带 Co-Authored-By 行）。

---

## Self-Review 记录

- **Spec 覆盖**：spec §4 的 20 章 → Task 5–13；§5 跨平台章 → Task 4 + 13；§6 build.ps1 两处 → Task 2；§8 文件清单（新增/重命名/修改/删除）→ Task 1/3/4/5–13/14；§9 事实核查 → 已在计划头部完成并嵌入 Task 5/13；§10 验证标准 → Task 15（+各 Task 内构建步骤）；§11 风险（BOM 坑、obj 冲突、残留引用、事实过时）→ Global Constraints/Task 2/Task 14/事实表。无缺口。
- **占位符扫描**：无 TBD/TODO；示例代码全文给出；章节任务给出小节级大纲与具体要点（教程正文本身是各任务的产出物，不属于占位符）。
- **一致性**：示例目录名在 Task 1 映射表、各 Task 引用、README 索引（Task 14）三处一致（02_hello…20_modern，无 01）；章文件名 `NN-xxx.md` 与 spec §4 一致；`PortableLib` 成员（Runtime/BuildFilePath/Format）在 Task 4 与 Task 13 引用一致。
