# F# 教程重写实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `fsharp/` 从"单文件浅讲 + 8 个玩具示例"重写为 20 章自学教程（docs/ 分章 + 19 个示例目录 21 个工程 + 实战收尾章），全部工程可 `build.ps1 -All` 编译、运行、测试通过。

**Architecture:** 现有 8 个示例 `git mv` 重编号（含 fsproj 改名），Program.fs 全部重写为与章节配套的 60–150 行程序；新建 12 个示例目录（含 19_gui 嵌套双工程、20_todo 嵌套 src/tests 双工程）；新建 `docs/01-overview.md`…`docs/20-todo.md`；build.ps1 重写（递归发现 fsproj + 按工程拆分 obj + 运行/测试分级）；最后删旧指南、重写 README、新增 CHEATSheet。

**Tech Stack:** .NET 10 SDK（F# 10）、F#（net10.0 / net10.0-windows）、xUnit、ASP.NET Core Minimal API、System.Text.Json、PowerShell 7 构建脚本、Markdown。

**Spec:** `G:\code\guide\docs\superpowers\specs\2026-09-16-fsharp-tutorial-rewrite-design.md`（本计划依 spec 而写，执行者两份都要读）

## Global Constraints

- 工作目录：`G:\code\guide\fsharp`（bash 路径 `/g/code/guide/fsharp`）；仓库根 `G:\code\guide`。
- dotnet 可执行文件：`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`（build.ps1 内已硬编码，勿改）。
- 示例 TargetFramework：一律 `net10.0`；GUI 工程例外为 `net10.0-windows`；无多目标。
- **控制台示例 fsproj 模板**（新示例照抄，只改文件名；F# 无 ImplicitUsings，字段保留是为与仓库现有示例一致）：

  ```xml
  <Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
      <OutputType>Exe</OutputType>
      <TargetFramework>net10.0</TargetFramework>
      <ImplicitUsings>enable</ImplicitUsings>
      <Nullable>enable</Nullable>
    </PropertyGroup>

    <ItemGroup>
      <Compile Include="Program.fs" />
    </ItemGroup>
  </Project>
  ```

  F# 工程的 `<Compile Include>` **顺序即编译顺序**，多文件工程必须按依赖序排列。
- **.fs 源文件编码**：UTF-8 无 BOM 即可（实测旧 07_winforms/Program.fs 含中文无 BOM 正常编译），Write 工具默认即正确。
- **示例分节注释约定**：每个 Program.fs 用 `// ═══ N.M 小节名 ═══` 分节注释，编号与本章文档小节编号一致（docs 任务按小节号摘录代码，保证逐字一致）。
- **章节写作模板**（每章必须遵守）：
  - 文件名 `NN-kebab-case.md`；首行标题 `# NN · 主题：副标题`；第二行引用块 `> 对应示例：examples/NN_name`（第 01 章无此行，改引用 `examples/02_hello`）。
  - 结构：`## N.M` 起编号小节；**先讲"解决什么问题"再讲语法**；代码段配讲解；对比用表格；结尾 `## 坑位清单`（按命中率排序）。
  - 跨章引用格式：`第 12 章`（不带文件名）。章节内代码片段必须与 `examples/` 实际代码**逐字一致**（省略处标 `// …`）。
  - 每章 100–200 行（重点章可到 220）；中文行文。
  - 风格范本（每章动笔前先读）：`G:\code\guide\wpf\docs\06-binding.md` 与 `G:\code\guide\dotnet\docs\09-linq.md`。
- **build.ps1 运行环境坑**：脚本含中文且无 BOM，**必须用 pwsh 7 运行**（本机 bash 路径 `/g/Program Files/PowerShell/7/pwsh`）；编辑时保持无 BOM。
- 构建验证命令（所有"验证构建"步骤统一用）：

  ```bash
  cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

- 单目录验证：`... -File build.ps1 -Project 06_collections`（嵌套目录如 19_gui/20_todo 会构建其下全部 fsproj）。
- 提交规范：中文 conventional 风格（`feat(fsharp):` / `docs(fsharp):` / `chore(fsharp):` 前缀），结尾必须带：
  `Co-Authored-By: Claude Code <noreply@anthropic.com>`
- 每个 Task 结束时 `git status` 应干净（本 Task 变更已提交）。

## 已核实的平台事实（执行者不得凭记忆改动）

| 事实 | 内容 | 来源 |
|---|---|---|
| F# 语言版本 | **F# 10.0**（`dotnet fsi` 横幅 "F# 10.0 的 15.2.401.0"），随 .NET 10 SDK | 2026-09-16 实测 |
| xUnit F# 模板 | `dotnet new xunit -lang F#` 可用，`dotnet test` 通过；包版本 `Microsoft.NET.Test.Sdk 17.14.1` / `xunit 2.9.3` / `xunit.runner.visualstudio 3.1.4` | 实测 |
| .fs 中文无 BOM | 可正常编译，无需 BOM | 实测 |
| System.Text.Json | .NET 9+ 内置 F# record/option/DU 序列化支持，net10.0 直接可用；第 15 章验证步骤兜底（异常则教自定义 JsonConverter） | .NET 9 发布说明 |
| 嵌套工程先例 | dotnet 教程 `19_portable/{PortableApp,PortableLib}` 双工程，build.ps1 递归构建 | 仓库现有代码 |

## 示例目录重命名映射（Task 1 专用）

| 旧目录 | 新目录 | fsproj 改名 |
|---|---|---|
| 01_hello_console | 02_hello | 01_hello_console.fsproj → 02_hello.fsproj |
| 02_basic_types | 03_values | 02_basic_types.fsproj → 03_values.fsproj |
| 03_functions_and_patterns | 04_functions | 03_functions_and_patterns.fsproj → 04_functions.fsproj |
| 04_records_and_discriminated_unions | 09_records | 同风格改 → 09_records.fsproj |
| 05_collections_and_linq | 06_collections | → 06_collections.fsproj |
| 06_async_and_file_io | 13_async | → 13_async.fsproj |
| 07_winforms | 19_gui/winforms | → 19_gui_winforms.fsproj |
| 08_wpf | 19_gui/wpf | → 19_gui_wpf.fsproj |

旧 Program.fs 是"3–5 个 API 点到即止"的薄示例，**保留目录与 fsproj，代码由 Task 3–9 全部重写**。新建目录：05_patterns、07_option、08_result、10_unions、11_oop、12_generics、14_computations、15_files_json、16_webapi、17_testing、18_interop、20_todo/{src,tests}。

---

### Task 1: 示例目录重编号与嵌套结构（git mv）

**Files:**
- Rename: `examples/` 下 8 个目录及其中 fsproj（映射表见上）

**Interfaces:**
- Produces: 示例目录最终命名 `02_hello`…`20_todo`（Task 2–14 按新名引用）；`19_gui/{winforms,wpf}` 嵌套双工程结构。

- [ ] **Step 1: 清扫旧构建产物**（均被 gitignore，直接删）

```bash
cd /g/code/guide/fsharp && find examples -type d \( -name bin -o -name obj \) -prune -exec rm -rf {} + && rm -rf build
```

- [ ] **Step 2: 按映射表重命名**

```bash
cd /g/code/guide/fsharp/examples
git mv 01_hello_console 02_hello
git mv 02_hello/01_hello_console.fsproj 02_hello/02_hello.fsproj
git mv 02_basic_types 03_values
git mv 03_values/02_basic_types.fsproj 03_values/03_values.fsproj
git mv 03_functions_and_patterns 04_functions
git mv 04_functions/03_functions_and_patterns.fsproj 04_functions/04_functions.fsproj
git mv 04_records_and_discriminated_unions 09_records
git mv 09_records/04_records_and_discriminated_unions.fsproj 09_records/09_records.fsproj
git mv 05_collections_and_linq 06_collections
git mv 06_collections/05_collections_and_linq.fsproj 06_collections/06_collections.fsproj
git mv 06_async_and_file_io 13_async
git mv 13_async/06_async_and_file_io.fsproj 13_async/13_async.fsproj
mkdir 19_gui
git mv 07_winforms 19_gui/winforms
git mv 19_gui/winforms/07_winforms.fsproj 19_gui/winforms/19_gui_winforms.fsproj
git mv 08_wpf 19_gui/wpf
git mv 19_gui/wpf/08_wpf.fsproj 19_gui/wpf/19_gui_wpf.fsproj
```

- [ ] **Step 3: 验证**

```bash
cd /g/code/guide/fsharp && ls examples && git status --short | head -25
```

预期：examples 下为 8 个新目录名（02/03/04/06/09/13 + 19_gui/{winforms,wpf}），旧名消失；`git status` 全部为 R（renamed）条目。

- [ ] **Step 4: Commit**

```bash
cd /g/code/guide/fsharp && git add -A examples && git commit -m "chore(fsharp): 示例目录重编号对齐章号（02–20 嵌套结构）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: build.ps1 重写（递归发现 + 按工程拆分 obj + 运行/测试分级）

**Files:**
- Modify: `G:\code\guide\fsharp\build.ps1`（整体重写）

**Interfaces:**
- Produces: `-All` 递归枚举 `examples/**/*.fsproj`（Task 9 的嵌套工程依赖）；每工程 obj 为 `build/obj/<fsproj 基名>/`；行为分级——控制台工程编译后运行 exe、GUI 工程（fsproj 含 `net10.0-windows`）仅构建、测试工程（含 `Microsoft.NET.Test.Sdk`）跑 `dotnet test`、`Todo` 工程以演示参数序列运行。

- [ ] **Step 1: 用下面全文覆盖 build.ps1**（保持无 BOM）

```powershell
param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$dotnet = "G:\scoop\apps\dotnet-sdk\current\dotnet.exe"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"

if (-not (Test-Path -LiteralPath $dotnet)) {
    throw "未找到 dotnet.exe，请检查 .NET SDK 安装路径：$dotnet"
}
if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

# 清扫 examples 下游离的 obj/bin（读者直接 dotnet run 会在示例目录生成默认产物，
# 与本脚本的集中重定向路径冲突，导致重复生成特性等错误）
$strayDirs = Get-ChildItem -LiteralPath $examplesDir -Recurse -Directory -Include obj, bin |
    Where-Object { $_.FullName -notlike "$buildDir*" }
foreach ($stray in $strayDirs) {
    Remove-Item -LiteralPath $stray.FullName -Recurse -Force
}

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

$projects = Get-ChildItem -LiteralPath $examplesDir -Recurse -Filter "*.fsproj" | Sort-Object FullName
if ($projects.Count -eq 0) {
    throw "examples 目录下没有示例工程。"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

function Invoke-Project {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo]$Fsproj)

    $name = $Fsproj.BaseName
    $raw = Get-Content -LiteralPath $Fsproj.FullName -Raw
    $isGui = $raw -match 'net10\.0-windows'
    $isTest = $raw -match 'Microsoft\.NET\.Test\.Sdk'

    # 测试工程不经重定向构建：全局 obj 属性会传播到 ProjectReference 工程并互相覆盖 assets；
    # 直接 dotnet test（自建默认 obj/bin，下次脚本运行时被清扫回收）
    if ($isTest) {
        Write-Host "[Test] $name" -ForegroundColor Magenta
        & $dotnet test $Fsproj.FullName --nologo -v minimal
        if ($LASTEXITCODE -ne 0) {
            throw "测试未通过: $name"
        }
        return
    }

    Write-Host "[Build] $name" -ForegroundColor Cyan
    & $dotnet build $Fsproj.FullName --nologo -v minimal -c Release `
        "-p:BaseOutputPath=$buildDir\bin\" `
        "-p:BaseIntermediateOutputPath=$buildDir\obj\$name\"
    if ($LASTEXITCODE -ne 0) {
        throw "编译失败: $($Fsproj.FullName)"
    }

    if ($isGui) {
        Write-Host "[BuildOnly] $name（GUI 工程，跳过运行）" -ForegroundColor DarkCyan
        return
    }

    $exe = Join-Path $buildDir "bin\Release\net10.0\$name.exe"
    $dll = Join-Path $buildDir "bin\Release\net10.0\$name.dll"

    if ($name -eq 'Todo') {
        $demoSequence = @(
            @('reset'),
            @('add', 'learn F#'),
            @('add', 'write tutorial'),
            @('show'),
            @('done', '2'),
            @('show'),
            @('remove', '1'),
            @('show')
        )
        foreach ($args_ in $demoSequence) {
            Write-Host "[Run] Todo $($args_ -join ' ')" -ForegroundColor DarkCyan
            & $exe @args_
            if ($LASTEXITCODE -ne 0) {
                throw "运行失败: Todo $($args_ -join ' ')"
            }
        }
        return
    }

    Write-Host "[Run] $name" -ForegroundColor DarkCyan
    if (Test-Path -LiteralPath $exe) {
        & $exe
    } elseif (Test-Path -LiteralPath $dll) {
        & $dotnet $dll
    } else {
        throw "未找到生成的可执行文件: $name"
    }
    if ($LASTEXITCODE -ne 0) {
        throw "运行失败: $name"
    }
}

if ($All) {
    foreach ($entry in $projects) {
        Invoke-Project -Fsproj $entry
    }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $projectDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $projectDir)) {
        throw "找不到示例工程: $projectDir"
    }
    $fsprojs = Get-ChildItem -LiteralPath $projectDir -Recurse -Filter "*.fsproj" | Sort-Object FullName
    if ($fsprojs.Count -eq 0) {
        throw "示例工程缺少 fsproj: $projectDir"
    }
    foreach ($p in $fsprojs) {
        Invoke-Project -Fsproj $p
    }
    Write-Host "[Done] 验证通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译并验证 examples 下全部示例工程（GUI 仅构建，测试工程跑 dotnet test）"
Write-Host "  .\build.ps1 -Project <name>       编译并验证单个示例目录（例如 06_collections；嵌套目录构建其下全部 fsproj）"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"
```

（注意 `$args_` 命名：`$args` 是 PowerShell 自动变量，不可占用。）

- [ ] **Step 2: 全量验证**（此刻仍是旧代码，用于验证脚本本身）

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All && ls build/obj
```

预期：8 个工程全部 `[Build]` 通过；控制台工程有 `[Run]` 输出；两个 GUI 工程 `[BuildOnly]`；结尾 `[Done]`。`build/obj/` 下出现按 fsproj 基名命名的子目录。

- [ ] **Step 3: Commit**

```bash
cd /g/code/guide/fsharp && git add build.ps1 && git commit -m "feat(fsharp): build.ps1 重写——递归发现 fsproj、按工程拆分 obj、运行/测试分级

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 示例 02_hello / 03_values / 04_functions

**Files:**
- Rewrite: `examples/02_hello/Program.fs`
- Rewrite: `examples/03_values/Program.fs`
- Rewrite: `examples/04_functions/Program.fs`

**Interfaces:**
- Consumes: Task 1 的目录命名、Task 2 的 build.ps1（`-Project` 验证）。
- Produces: 第 02/03/04 章引用的全部代码段落（小节 2.1–2.5、3.1–3.8、4.1–4.7）。

- [ ] **Step 1: 重写 examples/02_hello/Program.fs**（fsproj 不动）

```fsharp
// ═══ 2.1 最小的 F# 程序：值与函数 ═══
let message = "Hello from F#"       // let 绑定：默认不可变
let add a b = a + b                 // 函数：空格传参，无大括号

[<EntryPoint>]
let main _ =

    // ═══ 2.2 printfn 格式化输出 ═══
    printfn "%s" message
    let name = "F#"
    let version = 10
    printfn "Hello, %s %d!" name version      // %s 字符串、%d 整数
    printfn "浮点 %.2f、布尔 %b" 3.14159 true  // %.2f 保留两位、%b 布尔
    printfn "任意值 %A" [ 1; 2; 3 ]            // %A 万能打印（列表/记录/联合）

    // ═══ 2.3 字符串插值（F# 5+）═══
    let who = "world"
    printfn $"Hello, {who}!"                          // $"..." 内插
    printfn $"表达式 {add 12 8}、浮点 {3.14159:f2}"    // 内插里可放表达式与格式

    // ═══ 2.4 类型推断初识 ═══
    let count = 42                        // 推断为 int
    let pi = 3.14                         // 推断为 float（即 double）
    let words = "a b c".Split ' '         // 调用 .NET 方法，推断为 string[]
    printfn "count=%d pi=%f words=%A" count pi words

    // ═══ 2.5 REPL 工作流提示 ═══
    printfn "在终端运行 dotnet fsi，逐行粘贴以上代码即可交互验证。"
    0
```

- [ ] **Step 2: 重写 examples/03_values/Program.fs**

```fsharp
[<EntryPoint>]
let main _ =

    // ═══ 3.1 基本类型与字面量 ═══
    let i = 42            // int（int32）
    let big = 42L         // int64
    let f = 3.14          // float（double）
    let money = 19.99m    // decimal（金额）
    let c = 'A'
    let b = true
    printfn "int=%d int64=%d float=%f decimal=%M char=%c bool=%b" i big f money c b

    // ═══ 3.2 类型推断与显式注解 ═══
    let x = 10
    let y = x + 5                 // 同类型才可直接运算
    // let z = x + 3.14            // 编译错误：int 与 float 不能隐式互转
    let z = float x + 3.14        // 显式转换：float x 把 int 变 float
    printfn "y=%d z=%.2f" y z
    let toUpper (s: string) = s.ToUpper()   // 参数注解：调用 .NET API 时常见
    printfn "%s" (toUpper "fsharp")

    // ═══ 3.3 自动泛化 ═══
    let identity x = x            // 推断为 'a -> 'a：什么类型都能传
    printfn "identity 5 = %d" (identity 5)
    printfn "identity hi = %s" (identity "hi")

    // ═══ 3.4 不可变性是默认 ═══
    let baseValue = 10
    let next = baseValue + 1      // next 是新值，baseValue 不变
    printfn "base=%d next=%d" baseValue next

    // ═══ 3.5 let mutable：需要可变时显式声明 ═══
    let mutable counter = 0
    counter <- counter + 1        // <- 赋值运算符
    counter <- counter + 10
    printfn "counter = %d" counter

    // ═══ 3.6 ref cell：另一种可变容器 ═══
    let cell = ref 0
    cell := !cell + 5             // := 写入，! 读取
    printfn "cell = %d" !cell

    // ═══ 3.7 unit：没有有意义的返回值 ═══
    let greet () = printfn "hello"  // 无参函数必须写 ()
    greet ()
    let nothing = ignore 42         // ignore：把任意值变成 unit
    printfn "unit 打印为 %A" nothing

    // ═══ 3.8 数值边界速查 ═══
    printfn "int 上限 = %d" System.Int32.MaxValue
    printfn "int64 上限 = %d" System.Int64.MaxValue
    0
```

- [ ] **Step 3: 重写 examples/04_functions/Program.fs**

```fsharp
[<EntryPoint>]
let main _ =

    // ═══ 4.1 函数是一等公民 + 柯里化 ═══
    let add a b = a + b        // 签名 int -> int -> int（柯里化）
    let add5 = add 5           // 部分应用：只喂第一个参数
    printfn "add 3 4 = %d" (add 3 4)
    printfn "add5 10 = %d" (add5 10)

    // ═══ 4.2 管道 |>：数据流式表达 ═══
    let values = [ 3; 1; 4; 1; 5; 9; 2; 6 ]
    let result =
        values
        |> List.filter (fun x -> x % 2 = 1)   // 奇数
        |> List.map (fun x -> x * 10)         // ×10
        |> List.sum                           // 求和
    printfn "管道结果 = %d" result

    // ═══ 4.3 组合 >>：函数拼接 ═══
    let square x = x * x
    let negate x = -x
    let squareThenNegate = square >> negate    // 先 square 再 negate，产生新函数
    printfn "(square >> negate) 5 = %d" (squareThenNegate 5)

    // ═══ 4.4 高阶函数 ═══
    let twice f x = f (f x)
    printfn "twice square 3 = %d" (twice square 3)
    let adders = [ (fun x -> x + 1); (fun x -> x * 2) ]   // 函数也能进列表
    adders |> List.iter (fun f -> printfn "f 7 = %d" (f 7))

    // ═══ 4.5 递归：let rec ═══
    let rec factorial n = if n <= 1 then 1 else n * factorial (n - 1)
    printfn "5! = %d" (factorial 5)

    // ═══ 4.6 尾递归 + 累加器：不爆栈 ═══
    let rec sumTail acc list =
        match list with
        | [] -> acc
        | head :: tail -> sumTail (acc + head) tail
    printfn "sumTail [1..100] = %d" (sumTail 0 [ 1 .. 100 ])

    // ═══ 4.7 互递归：and ═══
    let rec isEven n = if n = 0 then true else isOdd (n - 1)
    and isOdd n = if n = 0 then false else isEven (n - 1)
    printfn "isEven 10 = %b" (isEven 10)
    0
```

- [ ] **Step 4: 验证三个工程**

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 02_hello && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 03_values && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 04_functions
```

预期：三工程各 `[Build]`+`[Run]` 通过并输出完整运行结果（02: Hello…；03: 类型演示；04: 管道结果 140 等），无编译错误。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/fsharp && git add examples/02_hello examples/03_values examples/04_functions && git commit -m "feat(fsharp): 示例 02_hello/03_values/04_functions 重写为章节配套程序

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 示例 05_patterns（新建）/ 06_collections

**Files:**
- Create: `examples/05_patterns/{05_patterns.fsproj, Program.fs}`
- Rewrite: `examples/06_collections/Program.fs`

**Interfaces:**
- Produces: 第 05/06 章引用代码；活动模式 `(|Even|Odd|)`、`(|DivisibleBy|_|)`、`(|IntParse|_|)`、列表模式 `describe`、fold 家族演示段。

- [ ] **Step 1: 新建 examples/05_patterns/05_patterns.fsproj**（控制台模板照抄，文件名 05_patterns.fsproj）

- [ ] **Step 2: 写 examples/05_patterns/Program.fs**

```fsharp
open System

// ═══ 5.6 完整活动模式：把分类规则变成可 match 的形状 ═══
let (|Even|Odd|) n = if n % 2 = 0 then Even else Odd

// ═══ 5.7 部分活动模式：可能不匹配 ═══
let (|DivisibleBy|_|) divisor n =
    if n % divisor = 0 then Some DivisibleBy else None

// ═══ 5.8 参数化活动模式：包装 TryParse ═══
let (|IntParse|_|) (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | false, _ -> None

// ═══ 5.4 列表模式：按形状分类 ═══
let describe list =
    match list with
    | [] -> "空列表"
    | [ single ] -> sprintf "单元素 %d" single
    | [ a; b ] -> sprintf "两个元素 %d 和 %d" a b
    | head :: _ -> sprintf "多元素，开头是 %d" head

// ═══ 5.5 记录模式用到的类型 ═══
type Person = { Name: string; Age: int }

[<EntryPoint>]
let main _ =

    // ═══ 5.1 常量与变量模式 ═══
    let meaning =
        match 42 with
        | 0 -> "零"
        | 42 -> "宇宙的答案"
        | other -> sprintf "其他(%d)" other
    printfn "%s" meaning

    // ═══ 5.2 when 卫兵与 or 模式 ═══
    let classify n =
        match n with
        | 0 -> "零"
        | x when x < 0 -> "负数"
        | 1 | 3 | 5 | 7 | 9 -> "个位奇数"
        | _ -> "其他"
    [ -2; 0; 3; 8 ] |> List.iter (fun n -> printfn "%d -> %s" n (classify n))

    // ═══ 5.3 元组解构模式 ═══
    match (3, 4) with
    | (0, 0) -> printfn "原点"
    | (x, y) -> printfn "点 (%d, %d)" x y

    // ═══ 5.4 列表与 cons 模式 ═══
    printfn "%s" (describe [])
    printfn "%s" (describe [ 7 ])
    printfn "%s" (describe [ 2; 9 ])
    printfn "%s" (describe [ 4; 5; 6 ])

    // ═══ 5.5 记录模式 + function 关键字 ═══
    let users = [ { Name = "Alice"; Age = 30 }; { Name = "Bob"; Age = 15 } ]
    let label =
        function
        | { Name = n; Age = a } when a >= 18 -> sprintf "%s（成年）" n
        | { Name = n } -> sprintf "%s（未成年）" n
    users |> List.iter (fun u -> printfn "%s" (label u))

    // ═══ 5.6 使用完整活动模式 ═══
    let evenOrOdd n =
        match n with
        | Even -> "偶数"
        | Odd -> "奇数"
    [ 1 .. 4 ] |> List.iter (fun n -> printfn "%d 是%s" n (evenOrOdd n))

    // ═══ 5.7 使用部分活动模式（FizzBuzz）═══
    let fizz n =
        match n with
        | DivisibleBy 15 -> "FizzBuzz"
        | DivisibleBy 3 -> "Fizz"
        | DivisibleBy 5 -> "Buzz"
        | _ -> string n
    [ 1 .. 7 ] |> List.iter (fun n -> printf "%s " (fizz n))
    printfn ""

    // ═══ 5.8 使用 IntParse 活动模式 ═══
    for s in [ "42"; "abc"; "7" ] do
        match s with
        | IntParse v -> printfn "\"%s\" 解析为 %d" s v
        | _ -> printfn "\"%s\" 不是整数" s
    0
```

- [ ] **Step 3: 重写 examples/06_collections/Program.fs**

```fsharp
[<EntryPoint>]
let main _ =

    // ═══ 6.1 三种集合的构造 ═══
    let ls = [ 1 .. 8 ]              // list：不可变链表
    let arr = [| 1; 2; 3; 4 |]       // array：可变、连续内存
    let sq = seq { 1; 2; 3 }         // seq：惰性 IEnumerable
    printfn "list=%A array=%A" ls arr
    printfn "seq 转列表：%A" (sq |> List.ofSeq)

    // ═══ 6.2 List 模块：map / filter ═══
    let doubled = ls |> List.map (fun x -> x * 2)
    let evens = ls |> List.filter (fun x -> x % 2 = 0)
    printfn "doubled=%A" doubled
    printfn "evens=%A" evens

    // ═══ 6.3 fold 家族 ═══
    let total = ls |> List.fold (fun acc x -> acc + x) 0
    let product = ls |> List.fold (fun acc x -> acc * x) 1
    let steps = ls |> List.scan (fun acc x -> acc + x) 0  // 保留每步中间值
    printfn "sum=%d product=%d" total product
    printfn "scan 中间步骤=%A" steps

    // ═══ 6.4 分组与排序 ═══
    let words = [ "apple"; "pear"; "avocado"; "fig" ]
    let grouped = words |> List.groupBy (fun w -> w[0]) |> List.map (fun (k, v) -> (k, List.length v))
    let byLength = words |> List.sortBy (fun w -> w.Length)
    printfn "按首字母分组=%A" grouped
    printfn "按长度排序=%A" byLength

    // ═══ 6.5 array：可变、就地更新 ═══
    arr[0] <- 100
    printfn "更新后 array=%A" arr
    printfn "Array.map=%A" (arr |> Array.map (fun x -> x + 1))

    // ═══ 6.6 seq：惰性与无限序列 ═══
    let naturals = Seq.initInfinite (fun i -> i * i)
    printfn "前 5 个平方数 = %A" (naturals |> Seq.truncate 5 |> List.ofSeq)

    // ═══ 6.7 三种集合互转 ═══
    printfn "List.ofArray=%A" (List.ofArray arr)
    printfn "Array.ofList=%A" (Array.ofList ls)

    // ═══ 6.8 与 LINQ 的关系 ═══
    let linqStyle =
        System.Linq.Enumerable.Where(ls, fun x -> x > 3)
        |> Seq.map (fun x -> x + 100)
        |> List.ofSeq
    printfn "LINQ 风格等价结果=%A" linqStyle

    // ═══ 6.9 常用 API 速查 ═══
    printfn "长度=%d，包含 4？%b" ls.Length (List.contains 4 ls)
    printfn "splitAt 3 = %A" (List.splitAt 3 ls)
    0
```

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 05_patterns && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 06_collections
```

预期：两工程 `[Build]`+`[Run]` 通过。若 `w[0]`/`arr[0]` 索引报错（索引语法差异），统一改为 `w.[0]`、`arr.[0]`。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/fsharp && git add examples/05_patterns examples/06_collections && git commit -m "feat(fsharp): 示例 05_patterns 新建、06_collections 重写

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: 示例 07_option / 08_result（新建）/ 09_records

**Files:**
- Create: `examples/07_option/{07_option.fsproj, Program.fs}`
- Create: `examples/08_result/{08_result.fsproj, Program.fs}`
- Rewrite: `examples/09_records/Program.fs`

**Interfaces:**
- Produces: 第 07/08/09 章引用代码；`safeDivide`（option）、`parseInt`/`classifyAge`（Result 链）、record with/相等性/匿名记录演示段。

- [ ] **Step 1: 新建 07_option 工程**（fsproj 模板，名 07_option.fsproj）

- [ ] **Step 2: 写 examples/07_option/Program.fs**

```fsharp
open System

// ═══ 7.2 返回 option 而不是抛异常 ═══
let safeDivide a b = if b = 0 then None else Some(a / b)

// ═══ 7.3 解析可能失败：返回 option ═══
let parseInt (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | false, _ -> None

[<EntryPoint>]
let main _ =

    // ═══ 7.1 构造与模式匹配消耗 ═══
    let someValue = Some 42
    let noneValue: int option = None
    match someValue with
    | Some v -> printfn "someValue = %d" v
    | None -> printfn "没有值"
    printfn "直接打印 %A / %A" someValue noneValue

    // ═══ 7.2 安全除法 ═══
    printfn "10 / 2 = %A" (safeDivide 10 2)
    printfn "10 / 0 = %A" (safeDivide 10 0)

    // ═══ 7.3 Option.map / bind 串联 ═══
    printfn "map×2 = %A" (Some 5 |> Option.map (fun x -> x * 2))
    let reciprocal s =
        parseInt s |> Option.bind (fun n -> safeDivide 100 n)
    printfn "reciprocal \"4\" = %A" (reciprocal "4")
    printfn "reciprocal \"0\" = %A" (reciprocal "0")
    printfn "reciprocal \"x\" = %A" (reciprocal "x")

    // ═══ 7.4 默认值与备选 ═══
    printfn "defaultValue 0 = %d" (None |> Option.defaultValue 0)
    printfn "orElse = %A" (None |> Option.orElse (Some 7))
    printfn "isSome = %b" (Some 1 |> Option.isSome)

    // ═══ 7.5 集合 API 里的 option ═══
    let found = [ 1; 3; 5; 7 ] |> List.tryFind (fun x -> x > 4)
    printfn "tryFind = %A" found
    let ages = Map [ ("Alice", 30); ("Bob", 25) ]
    printfn "Map.tryFind Alice = %A" (Map.tryFind "Alice" ages)
    printfn "Map.tryFind Carol = %A" (Map.tryFind "Carol" ages)

    // ═══ 7.6 与 null / Nullable 的边界转换 ═══
    // C# 风格 API（如 Array.Find 找不到时）返回 null；用 `| null` 注解显式接住可空值
    let csharpResult: string | null = System.Array.Find([||], fun (s: string) -> true)
    printfn "Option.ofObj null = %A" (Option.ofObj csharpResult)
    printfn "Option.ofNullable 5 = %A" (Option.ofNullable (Nullable 5))
    printfn "Option.toNullable None = %A" (Option.toNullable None)
    0
```

- [ ] **Step 3: 新建 08_result 工程**（fsproj 模板，名 08_result.fsproj）

- [ ] **Step 4: 写 examples/08_result/Program.fs**

```fsharp
open System

// ═══ 8.3 错误也建模成数据：可读的失败原因 ═══
type ParseError =
    | EmptyInput
    | NotANumber of string
    | OutOfRange of int

let parseInt (input: string) =
    if String.IsNullOrWhiteSpace input then Error EmptyInput
    else
        match Int32.TryParse input with
        | true, v -> Ok v
        | false, _ -> Error(NotANumber input)

let validateRange lo hi v =
    if v < lo || v > hi then Error(OutOfRange v) else Ok v

// ═══ 8.3 用 bind/map 串成校验链 ═══
let classifyAge input =
    parseInt input
    |> Result.bind (validateRange 0 150)
    |> Result.map (fun age -> if age >= 18 then "成年" else "未成年")

[<EntryPoint>]
let main _ =

    // ═══ 8.1 Result 的两轨结构 ═══
    let ok: Result<int, string> = Ok 1
    let err: Result<int, string> = Error "boom"
    printfn "ok = %A, err = %A" ok err

    // ═══ 8.2 map / bind / mapError ═══
    printfn "map = %A" (Ok 5 |> Result.map (fun x -> x * 2))
    printfn "map 不碰 Error = %A" (Error "e" |> Result.map (fun x -> x * 2))
    printfn "bind = %A" (Ok "20" |> Result.bind parseInt)
    printfn "mapError = %A" (Error(NotANumber "x") |> Result.mapError (sprintf "%A"))

    // ═══ 8.3 校验链实战 ═══
    [ "30"; "abc"; "200"; "" ]
    |> List.iter (fun s -> printfn "%A -> %A" s (classifyAge s))

    // ═══ 8.4 组合多个 Result ═══
    let addResults r1 r2 =
        match r1, r2 with
        | Ok a, Ok b -> Ok(a + b)
        | Error e, _ -> Error e
        | _, Error e -> Error e
    printfn "3 + 4 = %A" (addResults (parseInt "3") (parseInt "4"))
    printfn "3 + x = %A" (addResults (parseInt "3") (parseInt "x"))

    // ═══ 8.5 异常：try/with 与类型过滤 ═══
    let caught =
        try
            failwith "出错了"
            "没抛异常"
        with ex ->
            sprintf "捕获：%s" ex.Message
    printfn "%s" caught

    // ═══ 8.6 自定义异常抛出 ═══
    let parseOrThrow s =
        match parseInt s with
        | Ok v -> v
        | Error(NotANumber raw) -> raise (FormatException $"无法解析：{raw}")
        | Error e -> failwithf "%A" e
    try
        parseOrThrow "xyz" |> ignore
    with :? FormatException as ex ->
        printfn "自定义异常：%s" ex.Message

    // ═══ 8.7 分层策略总结 ═══
    printfn "经验：业务逻辑内部用 Result，边界（IO/框架）用异常。"
    0
```

- [ ] **Step 5: 重写 examples/09_records/Program.fs**

```fsharp
open System

// ═══ 9.1 基本记录：还可以带成员 ═══
type Person =
    { Name: string
      Age: int }
    member this.Greet() = sprintf "我是 %s，%d 岁" this.Name this.Age

// ═══ 9.7 struct 记录：栈上分配 ═══
[<Struct>]
type Point = { X: float; Y: float }

[<EntryPoint>]
let main _ =

    // ═══ 9.1 构造与字段访问 ═══
    let alice = { Name = "Alice"; Age = 30 }
    printfn "%s" (alice.Greet())
    printfn "alice.Name = %s" alice.Name

    // ═══ 9.2 with 表达式：非破坏性更新 ═══
    let aliceNextYear = { alice with Age = alice.Age + 1 }
    printfn "原值 = %A" alice
    printfn "明年 = %A" aliceNextYear

    // ═══ 9.3 结构相等：字段相同即相等 ═══
    let alice2 = { Name = "Alice"; Age = 30 }
    let bob = { Name = "Bob"; Age = 25 }
    printfn "alice = alice2 ? %b" (alice = alice2)
    printfn "alice = bob ? %b" (alice = bob)
    let nameByPerson = Map [ (alice, "第一个"); (alice2, "第二个") ]
    printfn "相等记录是同一个 Map 键：Count = %d" nameByPerson.Count

    // ═══ 9.5 解构 ═══
    let { Name = name; Age = age } = alice
    printfn "解构：name=%s age=%d" name age

    // ═══ 9.6 匿名记录：临时形状 ═══
    let profile = {| Name = "Carol"; Age = 28 |}
    printfn "匿名记录 = %A" profile
    printfn "字段访问 = %s" profile.Name

    // ═══ 9.7 struct 记录 ═══
    let p1 = { X = 1.0; Y = 2.0 }
    let p2 = { X = 1.0; Y = 2.0 }
    printfn "struct 相等 %b，类型 %s" (p1 = p2) (p1.GetType().Name)

    // ═══ 9.8 记录 + 集合管道 ═══
    let team = [ alice; bob; alice2 ]
    let adults =
        team
        |> List.distinct                 // alice2 与 alice 相等，去重
        |> List.filter (fun p -> p.Age >= 28)
        |> List.map (fun p -> p.Name)
    printfn "adults = %A" adults
    0
```

- [ ] **Step 6: 验证**

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 07_option && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 08_result && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 09_records
```

预期：三工程 `[Build]`+`[Run]` 通过。注意 08_result 里 `type ParseError` 避免直接叫 `Error`（与 Result 的 Error case 撞名）——这是刻意的教学点。

- [ ] **Step 7: Commit**

```bash
cd /g/code/guide/fsharp && git add examples/07_option examples/08_result examples/09_records && git commit -m "feat(fsharp): 示例 07_option/08_result 新建、09_records 重写

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: 示例 10_unions / 11_oop / 12_generics（均新建）

**Files:**
- Create: `examples/10_unions/{10_unions.fsproj, Program.fs}`
- Create: `examples/11_oop/{11_oop.fsproj, Program.fs}`
- Create: `examples/12_generics/{12_generics.fsproj, Program.fs}`

**Interfaces:**
- Produces: 第 10/11/12 章引用代码；递归 DU（`Expr`/`Json`）、单 case DU（`OrderId`/`Email`）、对象表达式 `ILogger`、SRTP `area2D`、度量单位演示段。

- [ ] **Step 1: 新建 10_unions 工程 + Program.fs**

```fsharp
// ═══ 10.1 简单 DU：形状 ═══
type Shape =
    | Circle of radius: float
    | Rectangle of width: float * height: float

let area shape =
    match shape with
    | Circle r -> System.Math.PI * r * r
    | Rectangle (w, h) -> w * h

// ═══ 10.2 单 case DU：强类型包装 ═══
type OrderId = OrderId of int
type Email = Email of string

let makeEmail (s: string) = if s.Contains "@" then Some(Email s) else None

// ═══ 10.3 递归 DU：表达式树 ═══
type Expr =
    | Num of float
    | Var of string
    | Add of Expr * Expr
    | Mul of Expr * Expr

let rec eval (vars: Map<string, float>) expr =
    match expr with
    | Num v -> v
    | Var name -> Map.find name vars
    | Add (a, b) -> eval vars a + eval vars b
    | Mul (a, b) -> eval vars a * eval vars b

let rec toStr expr =
    match expr with
    | Num v -> string v
    | Var n -> n
    | Add (a, b) -> sprintf "(%s + %s)" (toStr a) (toStr b)
    | Mul (a, b) -> sprintf "(%s * %s)" (toStr a) (toStr b)

// ═══ 10.4 递归 DU：JSON 值建模 ═══
type Json =
    | JString of string
    | JNumber of float
    | JBool of bool
    | JArray of Json list
    | JObject of (string * Json) list

let rec depth json =
    match json with
    | JString _ | JNumber _ | JBool _ -> 1
    | JArray items -> 1 + (items |> List.map depth |> List.fold max 0)
    | JObject fields -> 1 + (fields |> List.map (snd >> depth) |> List.fold max 0)

// ═══ 10.5 RequireQualifiedAccess：强制写全名 ═══
[<RequireQualifiedAccess>]
type Status = Active | Paused | Stopped

[<EntryPoint>]
let main _ =

    // ═══ 10.1 构造与 match ═══
    printfn "圆面积 = %.2f" (area (Circle 3.0))
    printfn "矩形面积 = %.2f" (area (Rectangle(2.0, 5.0)))

    // ═══ 10.2 单 case DU 防混淆 ═══
    let orderNo = OrderId 1001
    let (OrderId raw) = orderNo          // 解构取出原始值
    printfn "订单号原始值 = %d" raw
    match makeEmail "a@b.com" with
    | Some (Email e) -> printfn "合法邮箱：%s" e
    | None -> printfn "非法邮箱"

    // ═══ 10.3 表达式树求值：(2 + x) * 3，x = 4 ═══
    let expr = Mul(Add(Num 2.0, Var "x"), Num 3.0)
    let vars = Map [ ("x", 4.0) ]
    printfn "%s = %.1f" (toStr expr) (eval vars expr)

    // ═══ 10.4 JSON 深度计算 ═══
    let sample =
        JObject [ ("name", JString "guide")
                  ("tags", JArray [ JString "fsharp"; JString "dotnet" ]) ]
    printfn "JSON 嵌套深度 = %d" (depth sample)

    // ═══ 10.5 必须写 Status.Active 而不是裸 Active ═══
    let state = Status.Active
    printfn "状态 = %A" state
    0
```

- [ ] **Step 2: 新建 11_oop 工程 + Program.fs**

```fsharp
open System
open System.IO

// ═══ 11.1 接口定义 ═══
type ILogger =
    abstract member Log: string -> unit

// ═══ 11.1 对象表达式：不定义类直接实现接口 ═══
let consoleLogger =
    { new ILogger with
        member _.Log msg = printfn "[console] %s" msg }

// ═══ 11.2 抽象类与继承 ═══
[<AbstractClass>]
type Animal(name: string) =
    abstract member Speak: unit -> string
    member _.Name = name

type Dog(name: string, breed: string) =
    inherit Animal(name)
    override this.Speak() = sprintf "%s（%s）：汪！" this.Name breed

// ═══ 11.3 类：隐式构造、私有可变状态、静态成员 ═══
type Counter(start: int) =
    let mutable current = start          // 私有可变状态
    member _.Value = current             // 只读属性
    member this.Increment() =
        current <- current + 1
        this                              // 返回自身，支持链式调用
    member _.Reset() = current <- start
    static member Start() = Counter 0

// ═══ 11.4 IDisposable 与 use 绑定 ═══
type TempFile(path: string) =
    do File.WriteAllText(path, "临时内容")
    interface IDisposable with
        member _.Dispose() =
            File.Delete path
            printfn "已删除 %s" path

[<EntryPoint>]
let main _ =

    // ═══ 11.1 对象表达式（可带参数）═══
    consoleLogger.Log "对象表达式无需先定义类"
    let prefixLogger prefix =
        { new ILogger with
            member _.Log msg = printfn "[%s] %s" prefix msg }
    (prefixLogger "db").Log "带参数的对象表达式"

    // ═══ 11.2 多态 ═══
    let animals: Animal list = [ Dog("旺财", "柴犬"); Dog("来福", "边牧") ]
    animals |> List.iter (fun a -> printfn "%s" (a.Speak()))

    // ═══ 11.3 有状态对象 ═══
    let c = Counter.Start()
    c.Increment().Increment().Increment() |> ignore
    printfn "counter = %d" c.Value
    c.Reset()
    printfn "reset 后 = %d" c.Value

    // ═══ 11.4 use 绑定自动释放 ═══
    let path = Path.Combine(Path.GetTempPath(), "fsharp-demo.txt")
    use tmp = new TempFile(path)
    printfn "正在使用临时文件……（main 结束时自动 Dispose）"

    // ═══ 11.5 函数式与 OOP 的分工 ═══
    let count = animals |> List.length     // 集合处理仍交给函数式
    printfn "一共 %d 只动物" count
    0
```

- [ ] **Step 3: 新建 12_generics 工程 + Program.fs**

```fsharp
open System

// ═══ 12.2 显式约束：equality / comparison ═══
let areEqual (x: 'T when 'T : equality) (y: 'T) = x = y
let smallest list = list |> List.reduce (fun a b -> if a < b then a else b)

// ═══ 12.3 inline + SRTP：对"支持运算的类型"通用 ═══
let inline square (x: ^T) : ^T = x * x
let inline twiceSum (a: ^T) (b: ^T) : ^T = (a + b) + (a + b)

// ═══ 12.3 SRTP 成员约束：任何带 Area 成员的类型 ═══
let inline area2D (s: ^S) : float = (^S: (member Area: float) s)

type Disk = { Radius: float } with
    member this.Area = Math.PI * this.Radius * this.Radius

type Rect = { W: float; H: float } with
    member this.Area = this.W * this.H

// ═══ 12.4 度量单位 ═══
[<Measure>] type kg
[<Measure>] type m
[<Measure>] type s

[<EntryPoint>]
let main _ =

    // ═══ 12.1 自动泛化 ═══
    let firstOf list = List.head list       // 'a list -> 'a
    printfn "firstOf [3;1;2] = %d" (firstOf [ 3; 1; 2 ])
    printfn "firstOf ['a';'b'] = %c" (firstOf [ 'a'; 'b' ])

    // ═══ 12.2 约束演示 ═══
    printfn "smallest [5;2;9] = %d" (smallest [ 5; 2; 9 ])
    printfn "areEqual 1 1 = %b" (areEqual 1 1)

    // ═══ 12.3 SRTP：同一函数适配 int / float ═══
    printfn "square 4 = %d" (square 4)
    printfn "square 1.5 = %.2f" (square 1.5)
    printfn "twiceSum 3 4 = %d" (twiceSum 3 4)
    printfn "twiceSum 1.5 2.5 = %.1f" (twiceSum 1.5 2.5)

    // ═══ 12.3 成员约束：不同类型都点得出 Area ═══
    printfn "disk.Area = %.2f" (area2D { Radius = 2.0 })
    printfn "rect.Area = %.2f" (area2D { W = 3.0; H = 4.0 })

    // ═══ 12.4 度量单位：单位参与类型检查 ═══
    let mass = 75.0<kg>
    let height = 1.78<m>
    let distance = 100.0<m>
    let time = 9.58<s>
    let speed = distance / time            // m/s
    let bmi = mass / (height * height)     // kg/m^2
    // let wrong = mass + height           // 编译错误：kg 与 m 不能相加
    printfn "mass = %.1f kg" (float mass)  // float 剥掉单位用于打印
    printfn "speed = %.2f m/s" (float speed)
    printfn "bmi = %.1f" (float bmi)
    0
```

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 10_unions && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 11_oop && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 12_generics
```

预期：三工程 `[Build]`+`[Run]` 通过（表达式树 `(2.0 + x) * 3.0 = 18.0`、speed ≈ 10.44、bmi ≈ 23.7）。SRTP 若报约束错误，给 `square`/`twiceSum` 补显式约束 `when ^T : (static member ( * ) : ^T * ^T -> ^T)` 风格声明。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/fsharp && git add examples/10_unions examples/11_oop examples/12_generics && git commit -m "feat(fsharp): 示例 10_unions/11_oop/12_generics 新建

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: 示例 13_async / 14_computations / 15_files_json

**Files:**
- Rewrite: `examples/13_async/Program.fs`
- Create: `examples/14_computations/{14_computations.fsproj, Program.fs}`
- Create: `examples/15_files_json/{15_files_json.fsproj, Program.fs}`

**Interfaces:**
- Produces: 第 13/14/15 章引用代码；`Async.Parallel` 计时段、`task {}` 段、`TraceBuilder`/`MaybeBuilder`/`ResultBuilder`、文件 IO 与 STJ 序列化段。

- [ ] **Step 1: 重写 examples/13_async/Program.fs**

```fsharp
open System
open System.IO
open System.Threading.Tasks

// ═══ 13.1 定义 async 工作流（此刻并不执行）═══
let fetchPage (url: string) =
    async {
        do! Async.Sleep 200
        return sprintf "%s → %d 字节（模拟）" url url.Length
    }

[<EntryPoint>]
let main _ =

    // ═══ 13.1 let! 串联 + RunSynchronously 触发 ═══
    let demo =
        async {
            let! a = fetchPage "https://example.com/a"
            let! b = fetchPage "https://example.com/b"
            return [ a; b ]
        }
    Async.RunSynchronously demo |> List.iter (printfn "%s")

    // ═══ 13.2 Async.Parallel：总耗时 ≈ 单个任务 ═══
    let sw = Diagnostics.Stopwatch.StartNew()
    let squares =
        [ 1 .. 3 ]
        |> List.map (fun i ->
            async {
                do! Async.Sleep 300
                return i * i
            })
        |> Async.Parallel
        |> Async.RunSynchronously
    sw.Stop()
    printfn "并行结果 = %A，耗时 %d ms（串行需 900ms）" (Array.toList squares) sw.ElapsedMilliseconds

    // ═══ 13.3 task {}：与 .NET Task 原生融合（F# 6+）═══
    let t =
        task {
            let! x = Task.FromResult 40
            do! Task.Delay 100
            return x + 2
        }
    printfn "task 结果 = %d" t.Result

    // ═══ 13.4 async ↔ Task 互转 ═══
    let roundTrip =
        async { return 7 }
        |> Async.StartAsTask
        |> Async.AwaitTask
        |> Async.RunSynchronously
    printfn "async↔Task 往返 = %d" roundTrip

    // ═══ 13.5 用 AwaitTask 桥接 .NET 的 XxxAsync ═══
    let path = Path.Combine(Path.GetTempPath(), "fsharp-async-demo.txt")
    async {
        do! File.WriteAllTextAsync(path, "异步写入的内容") |> Async.AwaitTask
        let! text = File.ReadAllTextAsync(path) |> Async.AwaitTask
        printfn "读回 %d 字符：%s" text.Length (text.Trim())
    }
    |> Async.RunSynchronously

    // ═══ 13.6 取消令牌 ═══
    // 取消异常由运行器（RunSynchronously）抛出，try/with 要包住运行调用本身
    let cts = new Threading.CancellationTokenSource()
    cts.CancelAfter(100)
    let work =
        async {
            do! Async.Sleep 3000
            return "完成"
        }
    let outcome =
        try
            Async.RunSynchronously(work, cancellationToken = cts.Token) |> Some
        with :? OperationCanceledException ->
            None
    printfn "取消演示 outcome = %A" outcome
    0
```

- [ ] **Step 2: 新建 14_computations 工程 + Program.fs**

```fsharp
open System

// ═══ 14.2 讲解性 builder：打印每次 Bind/Return ═══
type TraceBuilder() =
    member _.Bind(x, f) =
        printfn "Bind: %A" x
        match x with
        | Some v -> f v
        | None -> None
    member _.Return x =
        printfn "Return: %A" x
        Some x
    member _.ReturnFrom x = x

let trace = TraceBuilder()

// ═══ 14.3 maybe builder：option 上的let! 语法糖 ═══
type MaybeBuilder() =
    member _.Bind(x, f) =
        match x with
        | Some v -> f v
        | None -> None
    member _.Return x = Some x
    member _.ReturnFrom x = x

let maybe = MaybeBuilder()

// ═══ 14.4 result builder：Result 上的校验链 ═══
type ResultBuilder() =
    member _.Bind(x, f) =
        match x with
        | Ok v -> f v
        | Error e -> Error e
    member _.Return x = Ok x
    member _.ReturnFrom x = x

let validate = ResultBuilder()

let tryParseInt (s: string) =
    match Int32.TryParse s with
    | true, v -> Some v
    | false, _ -> None

[<EntryPoint>]
let main _ =

    // ═══ 14.1 内置 CE：seq { }（async/task 见第 13 章）═══
    let squares =
        seq {
            for i in 1 .. 5 do
                yield i * i
        }
    printfn "seq CE = %A" (List.ofSeq squares)

    // ═══ 14.2 trace：看清 let! 的本质 ═══
    let traced =
        trace {
            let! a = Some 1
            let! b = Some 2
            return a + b
        }
    printfn "trace 结果 = %A" traced

    // ═══ 14.3 maybe：串联可失败操作 ═══
    let calc input1 input2 =
        maybe {
            let! a = tryParseInt input1
            let! b = tryParseInt input2
            let! c = if b = 0 then None else Some(100 / b)
            return a + c
        }
    printfn "maybe 成功 = %A" (calc "40" "8")
    printfn "maybe 失败 = %A" (calc "40" "x")

    // ═══ 14.4 validate：业务校验链 ═══
    let parse (s: string) =
        match Int32.TryParse s with
        | true, v -> Ok v
        | false, _ -> Error $"{s} 不是数字"

    let inRange lo hi v =
        if v < lo || v > hi then Error $"{v} 超出 [{lo}, {hi}]" else Ok()

    let processInput s =
        validate {
            let! n = parse s
            do! inRange 1 100 n
            return n * 2
        }
    printfn "validate 成功 = %A" (processInput "21")
    printfn "validate 非数字 = %A" (processInput "abc")
    printfn "validate 超范围 = %A" (processInput "150")

    // ═══ 14.5 return!：直接透传另一个同类计算 ═══
    let passthrough = maybe { return! Some 9 }
    printfn "return! = %A" passthrough
    0
```

（注意 `inRange` 失败分支返回 `Error ...`、成功分支返回 `Ok()`——`do!` 对 `Result<unit, _>` 的工作方式。）

- [ ] **Step 3: 新建 15_files_json 工程 + Program.fs**

```fsharp
open System
open System.IO
open System.Text.Encodings.Web
open System.Text.Json

// ═══ 15.3 CSV 解析目标：record ═══
type Language =
    { Name: string
      Year: int
      Score: float }

// ═══ 15.4 JSON 往返的记录类型 ═══
type Book =
    { Title: string
      Author: string
      Year: int
      Tags: string list }

// ═══ 15.5 option 字段 ═══
type Profile = { Name: string; Nickname: string option }

[<EntryPoint>]
let main _ =
    let dir = Path.Combine(Path.GetTempPath(), "fsharp-guide")
    Directory.CreateDirectory(dir) |> ignore

    // ═══ 15.1 文本文件读写 ═══
    let txt = Path.Combine(dir, "notes.txt")
    File.WriteAllText(txt, "第一行\n第二行\n第三行")
    printfn "读回 %d 字符" (File.ReadAllText(txt)).Length
    File.ReadAllLines(txt) |> Array.iteri (fun i line -> printfn "行 %d: %s" (i + 1) line)

    // ═══ 15.2 追加与 Path 工具 ═══
    File.AppendAllText(txt, "\n追加的一行")
    printfn "追加后 %d 行" (File.ReadAllLines(txt).Length)
    let target = Path.Combine(dir, "sub", "deep.txt")
    printfn "Combine 生成跨平台路径：%s" target

    // ═══ 15.3 CSV 字符串 → record 列表 ═══
    let csv = "F#,2010,4.7\nC#,2000,4.5\nPython,1991,4.8"
    let languages =
        csv.Split('\n')
        |> Array.map (fun line -> line.Split(','))
        |> Array.map (fun parts ->
            { Name = parts[0]
              Year = int parts[1]
              Score = float parts[2] })
    printfn "CSV 解析 = %A" (Array.toList languages)
    printfn "平均分 = %.2f" (languages |> Array.averageBy (fun l -> l.Score))

    // ═══ 15.4 System.Text.Json 序列化 F# record ═══
    let books =
        [ { Title = "F# 实战"; Author = "张三"; Year = 2024; Tags = [ "fsharp"; ".net" ] }
          { Title = "函数式入门"; Author = "李四"; Year = 2022; Tags = [] } ]
    let options = JsonSerializerOptions(WriteIndented = true, Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping)
    let json = JsonSerializer.Serialize(books, options)
    printfn "%s" json
    let back =
        JsonSerializer.Deserialize<Book list>(json)
        |> Option.ofObj                    // Deserialize 声明返回可空，接回 option（连第 07 章）
        |> Option.defaultValue []
    printfn "往返书名 = %A" (back |> List.map (fun b -> b.Title))

    // ═══ 15.5 option 字段的 JSON 形态（.NET 9+ 原生支持）═══
    let profiles =
        [ { Name = "Alice"; Nickname = Some "Ali" }
          { Name = "Bob"; Nickname = None } ]
    printfn "%s" (JsonSerializer.Serialize(profiles))
    0
```

**注意**：15 章运行时若 `Deserialize<Book list>` 或 option 序列化报 `NotSupportedException`，说明运行时未带 F# 支持：改用显式 `JsonSerializerOptions` 并添加讲解自定义 `JsonConverter` 的兜底段落（两种写法都先以实际运行输出为准，再写文档）。

- [ ] **Step 4: 验证**

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 13_async && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 14_computations && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 15_files_json
```

预期：三工程通过。13_async 耗时约 200+300+100+100+300(取消)≈1s 输出各段；14 输出 trace 的 Bind/Return 顺序；15 输出 JSON 缩进文本与往返结果。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/fsharp && git add examples/13_async examples/14_computations examples/15_files_json && git commit -m "feat(fsharp): 示例 13_async 重写、14_computations/15_files_json 新建

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 8: 示例 16_webapi / 17_testing / 18_interop（均新建）

**Files:**
- Create: `examples/16_webapi/{16_webapi.fsproj, Program.fs}`
- Create: `examples/17_testing/{17_testing.fsproj, Tests.fs}`
- Create: `examples/18_interop/{18_interop.fsproj, Program.fs}`

**Interfaces:**
- Produces: 第 16/17/18 章引用代码；自测型 Minimal API、xUnit 测试集、C# 互操作演示段。

- [ ] **Step 1: 新建 16_webapi/fsproj**（用 **Sdk.Web**，非控制台模板）：

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <Compile Include="Program.fs" />
  </ItemGroup>
</Project>
```

- [ ] **Step 2: 写 examples/16_webapi/Program.fs**（自测型：启动→请求→退出，不挂起）

```fsharp
module Program

open System
open System.Net.Http
open System.Text
open System.Text.Json
open Microsoft.AspNetCore.Builder
open Microsoft.AspNetCore.Http

// ═══ 16.2 待办数据模型与内存存储 ═══
type Todo = { Id: int; Title: string; Done: bool }

let todosStore = ResizeArray<Todo>()

// ═══ 16.1 定义全部端点（F# 惯用法：显式 Func<...> 委托，避免多重载决议歧义）═══
let buildApp () =
    let builder = WebApplication.CreateBuilder()
    let app = builder.Build()

    app.MapGet("/", Func<string>(fun () -> "F# Minimal API 自测")) |> ignore

    app.MapGet("/todos", Func<IResult>(fun () ->
        if todosStore.Count = 0 then
            Results.NotFound("还没有待办")
        else
            Results.Ok(todosStore.ToArray()))) |> ignore

    app.MapPost("/todos", Func<Todo, IResult>(fun todo ->
        todosStore.Add todo
        Results.Created($"/todos/{todo.Id}", todo))) |> ignore

    app.MapDelete("/todos/{id:int}", Func<int, IResult>(fun id ->
        let removed = todosStore.RemoveAll(fun t -> t.Id = id)
        if removed > 0 then
            Results.NoContent()
        else
            Results.NotFound($"没有 id={id} 的待办"))) |> ignore

    app

// ═══ 16.4 自测：启动 → HttpClient 逐个端点验证 → 退出 ═══
[<EntryPoint>]
let main _ =
    let app = buildApp ()
    app.Urls.Add("http://127.0.0.1:0")          // 端口 0 = 随机可用端口
    app.StartAsync().GetAwaiter().GetResult() |> ignore

    let test = task {
        use client = new HttpClient()
        let baseUri = Seq.head app.Urls

        let! created =
            let payload = JsonSerializer.Serialize({ Id = 1; Title = "学 F#"; Done = false })
            let content = new StringContent(payload, Encoding.UTF8, "application/json")
            client.PostAsync(baseUri + "/todos", content)
        printfn "POST /todos → %O" created.StatusCode

        let! list = client.GetAsync(baseUri + "/todos")
        let! body = list.Content.ReadAsStringAsync()
        printfn "GET /todos → %O：%s" list.StatusCode body

        let! deleted = client.DeleteAsync(baseUri + "/todos/1")
        printfn "DELETE /todos/1 → %O" deleted.StatusCode

        let! empty = client.GetAsync(baseUri + "/todos")
        printfn "GET /todos → %O（已清空）" empty.StatusCode
    }
    test.GetAwaiter().GetResult()

    app.StopAsync().GetAwaiter().GetResult() |> ignore
    printfn "自测完成，正常退出。"
    0
```

（教学程序里用 `GetAwaiter().GetResult()` 阻塞等待是可接受的简化；生产代码用 `app.RunAsync()`。）

- [ ] **Step 3: 新建 17_testing/fsproj + Tests.fs**（fsproj：xUnit 三件套，无 OutputType）

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <Compile Include="Tests.fs" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
  </ItemGroup>
</Project>
```

```fsharp
module Tests

open System
open Xunit

// ═══ 17.1 被测代码：纯函数（第 08 章风格）═══
let parseInt input =
    if String.IsNullOrWhiteSpace input then Error "输入为空"
    else
        match Int32.TryParse input with
        | true, v -> Ok v
        | false, _ -> Error $"无法解析：{input}"

let inRange lo hi v =
    if v < lo || v > hi then Error $"超出 [{lo}, {hi}]" else Ok v

// ═══ 17.1 被测代码：多分支逻辑 ═══
let classify n =
    if n % 15 = 0 then "FizzBuzz"
    elif n % 3 = 0 then "Fizz"
    elif n % 5 = 0 then "Buzz"
    else string n

// ═══ 17.2 Fact：单一事实 ═══
type 解析与校验 () =

    [<Fact>]
    let ``正常整数解析为 Ok`` () =
        Assert.Equal(Ok 42, parseInt "42")

    [<Theory>]
    [<InlineData("abc")>]
    [<InlineData("")>]
    [<InlineData("  ")>]
    let ``非法输入解析为 Error`` (input: string) =
        Assert.True(match parseInt input with Error _ -> true | _ -> false)

    [<Fact>]
    let ``范围校验两端都检查`` () =
        Assert.Equal(Ok 5, inRange 1 10 5)
        Assert.True(match inRange 1 10 99 with Error _ -> true | _ -> false)

// ═══ 17.3 Theory：数据驱动 ═══
type FizzBuzz () =

    [<Theory>]
    [<InlineData(15, "FizzBuzz")>]
    [<InlineData(9, "Fizz")>]
    [<InlineData(10, "Buzz")>]
    [<InlineData(7, "7")>]
    let ``分类正确`` (n: int) (expected: string) =
        Assert.Equal(expected, classify n)
```

- [ ] **Step 4: 新建 18_interop 工程 + Program.fs**（控制台模板）

```fsharp
open System
open System.Text
open System.Threading.Tasks

// ═══ 18.4 byref 参数只能放顶层函数/方法上 ═══
let bump (v: byref<int>) = v <- v + 1

[<EntryPoint>]
let main _ =

    // ═══ 18.1 直接调用 C# 风格的 BCL ═══
    let sb = StringBuilder()
    sb.Append("F#").Append(" <-> ").Append("C#") |> ignore
    printfn "%s" (sb.ToString())
    printfn "join=%s format=%s" (String.Join(", ", [ "a"; "b"; "c" ]) ) (String.Format("{0:D4}", 42))

    // ═══ 18.2 null 边界：用 option 包装 C# 的 null ═══
    // C# 风格 API（如 Array.Find 找不到时）返回 null；用 `| null` 注解显式接住可空值
    let csharpResult: string | null = System.Array.Find([||], fun (s: string) -> true)
    match Option.ofObj csharpResult with
    | Some s -> printfn "有值 %s" s
    | None -> printfn "C# 返回了 null → Option.ofObj 安全包装"

    // ═══ 18.3 Nullable<T> 双向转换 ═══
    printfn "ofNullable=%A %A" (Option.ofNullable (Nullable 5)) (Option.ofNullable (Nullable<int>()))

    // ═══ 18.4 byref：向函数传可变引用 ═══
    let mutable x = 10
    bump &x
    printfn "byref 后 x = %d" x

    // ═══ 18.5 Span：高性能切片 ═══
    let arr = [| 1; 2; 3; 4; 5 |]
    let span = arr.AsSpan(1, 3)
    let mutable sum = 0
    for i in 0 .. span.Length - 1 do
        sum <- sum + span[i]
    printfn "span 求和 = %d" sum

    // ═══ 18.6 订阅 .NET 事件 ═══
    use timer = new Timers.Timer(200.0)
    timer.Elapsed.Add(fun _ -> printfn "Timer 事件触发")
    timer.Start()
    Threading.Thread.Sleep 400
    timer.Stop()

    // ═══ 18.7 Task 与 async 互转 ═══
    let fromTask: Task<int> = Task.FromResult 20
    let viaAsync = fromTask |> Async.AwaitTask |> Async.RunSynchronously
    let viaTask = async { return viaAsync + 1 } |> Async.StartAsTask
    printfn "Task→async→Task: %d" viaTask.Result

    // ═══ 18.8 query 表达式：F# 的 LINQ 查询语法 ═══
    let squares =
        query { for i in [ 1 .. 5 ] do select (i * i) }
        |> Seq.toList
    printfn "query 结果 = %A" squares
    0
```

（`query` 需要文件顶部 `open Microsoft.FSharp.Linq`；若编译器提示找不到 `query`，加上该 open；若仍失败则把 18.8 段改为 `System.Linq.Enumerable` 方法链演示并同步调整文档。）

- [ ] **Step 5: 验证**

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 16_webapi && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 17_testing && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 18_interop
```

预期：16_webapi `[Build]`+`[Run]` 打印四个端点自测结果后退出（不挂起）；17_testing `[Build]` 后 `[Test]` 显示全部测试通过；18_interop 各段输出正常。16 若 MapPost 的 F# lambda 重载决议失败，给 lambda 显式标注返回 `:> IResult`（与 GET/DELETE 一致）。

- [ ] **Step 6: Commit**

```bash
cd /g/code/guide/fsharp && git add examples/16_webapi examples/17_testing examples/18_interop && git commit -m "feat(fsharp): 示例 16_webapi/17_testing/18_interop 新建

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 9: 示例 19_gui 双工程迁移 + 20_todo 双工程（新建）

**Files:**
- Keep: `examples/19_gui/winforms`、`examples/19_gui/wpf`（Task 1 已就位，Program.fs 不动，仅补分节注释）
- Create: `examples/20_todo/src/{Todo.fsproj, Todo.fs, Program.fs}`
- Create: `examples/20_todo/tests/{Todo.Tests.fsproj, Tests.fs}`

**Interfaces:**
- Consumes: Task 2 的 `Todo` 特判运行逻辑（`reset/add/show/done/remove` 参数序列）与测试工程识别。
- Produces: `Todo.parse : string[] -> Result<Command, string>`、`Todo.apply : Command -> Todo list -> Result<Todo list * string, string>`（测试直接调用）。

- [ ] **Step 1: 给两个 GUI Program.fs 的分节注释对齐第 19 章小节**（19.1 WinForms：窗体与控件 / 19.2 事件处理 / 19.3 WPF：内容模型与面板 / 19.4 WPF 事件；只加 `// ═══ N.M xxx ═══` 注释行，不改代码逻辑）

- [ ] **Step 2: 写 examples/20_todo/src/Todo.fsproj**

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <Compile Include="Todo.fs" />
    <Compile Include="Program.fs" />
  </ItemGroup>
</Project>
```

- [ ] **Step 3: 写 examples/20_todo/src/Todo.fs**（领域 + 解析 + 存储 + 核心逻辑）

```fsharp
module Todo

open System
open System.IO
open System.Text.Json

// ═══ 20.2 领域模型：数据用 record，命令用 DU ═══
type Todo =
    { Id: int
      Title: string
      Done: bool }

type Command =
    | Add of title: string
    | Done of id: int
    | Remove of id: int
    | Show
    | Reset

// ═══ 20.3 解析：argv → Result<Command, string> ═══
let parse (argv: string array) : Result<Command, string> =
    match argv |> Array.toList with
    | [] -> Ok Show
    | [ "show" ] -> Ok Show
    | [ "reset" ] -> Ok Reset
    | "add" :: rest when rest <> [] -> Ok(Add(String.concat " " rest))
    | [ "add" ] -> Error "add 需要标题参数"
    | [ "done"; id ] ->
        match Int32.TryParse id with
        | true, v -> Ok(Done v)
        | false, _ -> Error $"done 需要整数 id：{id}"
    | [ "remove"; id ] ->
        match Int32.TryParse id with
        | true, v -> Ok(Remove v)
        | false, _ -> Error $"remove 需要整数 id：{id}"
    | unknown -> Error $"无法识别的命令：{unknown}"

// ═══ 20.4 持久化：JSON 文件 ═══
let statePath () = Path.Combine(Path.GetTempPath(), "fsharp-todo.json")

let load () : Todo list =
    let path = statePath ()
    if File.Exists path then
        try
            JsonSerializer.Deserialize<Todo list>(File.ReadAllText path)
            |> Option.ofObj
            |> Option.defaultValue []
        with _ -> []          // 文件损坏时从空状态开始
    else []

let save (todos: Todo list) =
    JsonSerializer.Serialize(todos, JsonSerializerOptions(WriteIndented = true))
    |> File.WriteAllText(statePath ())

// ═══ 20.5 核心逻辑：纯函数，不碰 IO ═══
let nextId (todos: Todo list) =
    if todos = [] then 1
    else (todos |> List.map (fun t -> t.Id) |> List.max) + 1

let apply (cmd: Command) (todos: Todo list) : Result<Todo list * string, string> =
    match cmd with
    | Reset -> Ok([], "状态已清空")
    | Add title ->
        let t = { Id = nextId todos; Title = title; Done = false }
        Ok(t :: todos, $"已添加 #{t.Id} {t.Title}")
    | Show ->
        let render t = (if t.Done then "[x]" else "[ ]") + $" #{t.Id} {t.Title}"
        let body =
            if todos = [] then "（空）"
            else todos |> List.rev |> List.map render |> String.concat "\n"
        Ok(todos, body)
    | Done id ->
        match todos |> List.tryFind (fun t -> t.Id = id) with
        | None -> Error $"没有 id={id} 的待办"
        | Some _ ->
            let next = todos |> List.map (fun t -> if t.Id = id then { t with Done = true } else t)
            Ok(next, $"完成 #{id}")
    | Remove id ->
        match todos |> List.tryFind (fun t -> t.Id = id) with
        | None -> Error $"没有 id={id} 的待办"
        | Some _ ->
            let next = todos |> List.filter (fun t -> t.Id <> id)
            Ok(next, $"已删除 #{id}")
```

- [ ] **Step 4: 写 examples/20_todo/src/Program.fs**（薄壳：只做 IO 与退出码）

```fsharp
module Program

open System

[<EntryPoint>]
let main argv =
    let todos = Todo.load ()
    match Todo.parse argv with
    | Error usage ->
        printfn "%s" usage
        printfn "用法：todo add <标题> | done <id> | remove <id> | show | reset"
        1
    | Ok cmd ->
        match Todo.apply cmd todos with
        | Error msg ->
            printfn "错误：%s" msg
            1
        | Ok (next, report) ->
            match cmd with
            | Todo.Command.Show -> ()           // 查询不改状态
            | _ -> Todo.save next
            printfn "%s" report
            0
```

- [ ] **Step 5: 写 examples/20_todo/tests/Todo.Tests.fsproj**

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <Compile Include="Tests.fs" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\src\Todo.fsproj" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
  </ItemGroup>
</Project>
```

- [ ] **Step 6: 写 examples/20_todo/tests/Tests.fs**

```fsharp
module Todo.Tests

open Xunit

type Parse 测试 () =

    [<Fact>]
    let ``无参数默认 show`` () =
        Assert.Equal(Ok(Todo.Command.Show), Todo.parse [||])

    [<Fact>]
    let ``add 支持多词标题`` () =
        Assert.Equal(Ok(Todo.Command.Add "buy milk"), Todo.parse [| "add"; "buy"; "milk" |])

    [<Theory>]
    [<InlineData("done", "abc")>]
    [<InlineData("remove", "x")>]
    [<InlineData("frobnicate", "")>]
    let ``非法命令返回 Error`` (cmd: string) (arg: string) =
        let argv = if arg = "" then [| cmd |] else [| cmd; arg |]
        Assert.True(match Todo.parse argv with Error _ -> true | _ -> false)

type Apply 测试 () =

    let seed: Todo.Todo list =
        [ { Id = 1; Title = "旧任务"; Done = false } ]

    [<Fact>]
    let ``add 生成递增 id 并置于头部`` () =
        match Todo.apply (Todo.Command.Add "新任务") seed with
        | Ok (state, report) ->
            let added = List.head state
            Assert.Equal(2, added.Id)
            Assert.Equal("新任务", added.Title)
            Assert.False(added.Done)
            Assert.Equal("已添加 #2 新任务", report)
        | Error e -> failwith e

    [<Fact>]
    let ``done 只改目标项`` () =
        match Todo.apply (Todo.Command.Done 1) seed with
        | Ok (state, report) ->
            Assert.True((List.head state).Done)
            Assert.Equal(1, List.length state)
            Assert.Equal("完成 #1", report)
        | Error e -> failwith e

    [<Fact>]
    let ``remove 删除指定项`` () =
        match Todo.apply (Todo.Command.Remove 1) seed with
        | Ok (state, _) -> Assert.Empty(state)
        | Error e -> failwith e

    [<Fact>]
    let ``操作不存在的 id 返回 Error`` () =
        Assert.True(match Todo.apply (Todo.Command.Done 9) seed with Error _ -> true | _ -> false)
        Assert.True(match Todo.apply (Todo.Command.Remove 9) seed with Error _ -> true | _ -> false)

    [<Fact>]
    let ``reset 清空状态`` () =
        match Todo.apply Todo.Command.Reset seed with
        | Ok (state, msg) ->
            Assert.Empty(state)
            Assert.Equal("状态已清空", msg)
        | Error e -> failwith e
```

- [ ] **Step 7: 验证**

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 19_gui && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 20_todo
```

预期：19_gui 两个工程 `[Build]`+`[BuildOnly]`；20_todo 的 Todo `[Build]`+8 条 `[Run]` 序列（reset→add→add→show→done→show→remove→show）、Todo.Tests `[Build]`+`[Test]` 全绿。

- [ ] **Step 8: 全量中期验证**（至此 21 个工程齐了；测试工程直接 dotnet test，不经过脚本的重定向构建）

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
```

预期：21 个 `[Build]`；16 个控制台 `[Run]`；2 个 `[BuildOnly]`；2 个 `[Test]`；`[Done]`。

- [ ] **Step 9: Commit**

```bash
cd /g/code/guide/fsharp && git add examples/19_gui examples/20_todo && git commit -m "feat(fsharp): 19_gui 分节注释对齐、20_todo 实战项目（src/tests 双工程）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 10: docs/01-overview.md + docs/02-hello.md + docs/03-values.md + docs/04-functions.md

**Files:**
- Create: `docs/01-overview.md`（无示例，引用 `examples/02_hello`）
- Create: `docs/02-hello.md`（示例 `examples/02_hello`）
- Create: `docs/03-values.md`（示例 `examples/03_values`）
- Create: `docs/04-functions.md`（示例 `examples/04_functions`）

**Interfaces:**
- Consumes: Task 3 的三份 Program.fs（片段逐字摘录，按 `// ═══ N.M` 小节号对应）。
- Produces: `docs/` 目录与 01–04 章；后续章节沿用其行文结构。

- [ ] **Step 1: 写 01-overview.md**（约 150 行）：
  1. `# 01 · F# 全景：函数式优先的 .NET 语言`
  2. F# 是什么：函数式优先 + 多范式（函数式/命令式/OOP 都是一等公民）；引用示例 02_hello 的 2.1 段（4 行）作为"第一印象"
  3. F# 与 .NET/C# 关系：编译到同一 IL、共享 BCL、FSharp.Core、可混编一解决方案
  4. 语言五件套速览表：`let`/`match`/record/DU/计算表达式（各一行代码预告对应章号）
  5. 工具链：dotnet CLI（`dotnet new console -lang F#` / `dotnet run` / `dotnet fsi`）；fsx 脚本 vs fsproj 工程对比表（教学主线 fsproj + fsi 交互）
  6. fsproj 结构讲解：`<Compile Include>` 顺序即编译顺序（引用 20_todo/src/Todo.fsproj 的双文件排列）
  7. build.ps1 用法（-All/-Project/-Clean；pwsh 7 要求）
  8. 支持矩阵：.NET 10（本教程主线）、F# 10、跨平台（Windows/macOS/Linux）、编辑器（VS/VS Code + Ionide/Rider）
  9. 20 章学习路线图（按阶段分组的章节表）
  10. `## 坑位清单`：文件顺序、`Program.fs` 应最后、缩进敏感（4 空格）、无隐式 open

- [ ] **Step 2: 写 02-hello.md**（约 120 行）：
  1. `# 02 · 第一个程序：值、输出与 REPL` + 示例引用行
  2. 问题先行：为什么 F# 程序这么短——一切皆表达式、顶层 `let`、隐式 main（`[<EntryPoint>]` 是显式形式，两行对比）
  3. let 绑定与函数（引用 2.1 段）；`printfn` 格式符表（%s/%d/%f/%.2f/%M/%b/%c/%A/%O，各自适用）
  4. 字符串插值 `$""` vs printfn（引用 2.3 段）取舍：插值带表达式、printfn 编译期检查格式
  5. 类型推断初识（引用 2.4 段）：不用写类型，但类型在那里
  6. REPL 工作流：`dotnet fsi` 逐行粘贴示例；展示一次会话（`> let x = 42;;` → `val x: int = 42` 风格）、`#quit;;`；fsx 脚本执行 `dotnet fsi xx.fsx`
  7. `## 坑位清单`：printfn 格式符与实参类型不匹配=编译错误、%A 适合调试不适合生产格式化、缩进即语法、`;;` 只在 fsi 需要

- [ ] **Step 3: 写 03-values.md**（约 160 行）：
  1. `# 03 · 值与不可变性：默认不可变的世界`
  2. 基本类型表（int/int64/float/decimal/char/string/bool + 字面量后缀 L/m/f + 适用场景行）
  3. 类型推断机制：何时需要显式注解（引用 3.2 段，含被注释的编译错误行）；**没有隐式数值转换**（F# 立场与 C# 对比表：显式 `float x` / `int32` 转换函数表）
  4. 自动泛化（引用 3.3 段，`'a` 含义）
  5. 不可变默认（引用 3.4）；为什么：推理安全性、并发友好；`let mutable` + `<-`（3.5 段）
  6. ref cell（3.6 段）：`ref`/`:=`/`!`，与 mutable 的取舍（大多场景用 mutable）
  7. unit 类型与 ignore（3.7 段）；`()` 与 `ignore` 的关系
  8. 数值边界（3.8 段）；溢出默认不检查（`Checked` 模块一句话）
  9. `## 坑位清单`：`float` 是 double（float32 才是单精度）、mutable 闭包捕获、`=` 是比较不是赋值（`<-` 才是）、unit 不能丢（无返回值函数调用要 `|> ignore`）

- [ ] **Step 4: 写 04-functions.md**（约 170 行）：
  1. `# 04 · 函数：柯里化、管道与组合`
  2. 柯里化本质：`add a b` 的真实签名 `int -> int -> int` 是"取一个 int 返回函数"（引用 4.1）；部分应用（`add5`）
  3. 管道 `|>`（引用 4.2）：数据流可读性；`||>`（二元组）与 `|> ignore` 变体表
  4. 组合 `>>`/`<<`（引用 4.3）：产生新函数 vs 管道喂值——对比表
  5. 高阶函数（引用 4.4）：函数进列表、`twice`
  6. 递归 `let rec`（4.5）；尾递归 + 累加器（4.6）：为什么尾调用不爆栈（栈帧复用图解文字版）
  7. 互递归 `and`（4.7）
  8. `## 坑位清单`：部分应用优先级（`add 5 6` 是应用不是柯里化）、`>>` 方向记错、忘 `rec`、闭包里捕获可变值的陷阱、curried 函数直接喂 C# API 要元组化（连第 18 章）

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/fsharp && wc -l docs/0*.md
```

预期：4 个文件各 100–200 行；代码片段与 examples 逐字对照（抽查 2.1/3.6/4.6 三段）。

```bash
cd /g/code/guide/fsharp && git add docs && git commit -m "docs(fsharp): 第 01–04 章 全景、hello、值、函数

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 11: docs/05-patterns.md + docs/06-collections.md + docs/07-option.md + docs/08-result.md

**Files:**
- Create: `docs/05-patterns.md`、`docs/06-collections.md`、`docs/07-option.md`、`docs/08-result.md`

- [ ] **Step 1: 写 05-patterns.md**（约 200 行）：
  1. `# 05 · 模式匹配：分支的完全体`
  2. match 是表达式（有返回值）vs C# switch（引用 5.1 段）；完备性检查：缺分支=编译错误（删分支演示）
  3. 模式族谱表：常量/变量/or `|`/when/元组/列表/cons/记录/类型测试，各配一行示例
  4. when 卫兵与 or 模式（5.2）；元组解构（5.3）
  5. 列表与 cons 模式（5.4 段 + `describe`）：`[]`/`[x]`/`[x;y]`/`head::rest` 递归处理列表（连第 04 章 sumTail）
  6. 记录模式 + `function` 关键字（5.5 段）：`function` = `fun x -> match x with` 糖
  7. **活动模式**（5.6–5.8 段全部引用）：完整 `(|Even|Odd|)`（把布尔判断变成形状）、部分 `(|DivisibleBy|_|)`（FizzBuzz 实战）、参数化 `(|IntParse|_|)`（包装 TryParse 的惯用法）
  8. 选型表：if/elif vs match vs 活动模式
  9. `## 坑位清单`：变量模式遮蔽同名、`_` 过早兜底导致后续分支不可达告警、活动模式里抛异常的传播、`| x ->` 忘了 x 未用会有提示（用 `_`）

- [ ] **Step 2: 写 06-collections.md**（约 180 行）：
  1. `# 06 · 集合：List、Array 与 Seq`
  2. 三者对比表（不可变链表/可变数组/惰性枚举：内存模型、索引、典型场景、何时选谁）
  3. 构造：字面量、范围 `[1..8]`、comprehension、`seq {}`（引用 6.1 段）
  4. List/Array/Seq 模块函数命名一致（map/filter/sum 三胞胎）；`List.map` 演示（6.2 段）
  5. **fold 家族**（6.3 段）：fold/foldBack/scan/reduce 对比表（方向、初始值、中间结果）；fold 是"万能归约"
  6. groupBy/sortBy（6.4 段）；array 就地更新 `arr[0] <-`（6.5 段）与 `.[i]` 旧写法说明
  7. seq 惰性：initInfinite + truncate（6.6 段）；互转函数表（6.7 段）
  8. 与 LINQ（6.8 段）：F# 管道风格为主、Enumerable/query 兜底（连第 18 章 query 语法）
  9. `## 坑位清单`：`List.append` 是 O(n)、seq 多次枚举重复副作用、`[1..n]` 两端闭合、管道里 List vs Seq 混用错配

- [ ] **Step 3: 写 07-option.md**（约 150 行）：
  1. `# 07 · Option：与 null 划清界限`
  2. 问题先行：null 引用是"十亿美元错误"；F# 默认类型不可为 null → 缺失值显式建模为 `option`
  3. Some/None 构造、match 消耗（7.1 段）；`%A` 打印形态
  4. 返回 option 的函数（7.2 段 `safeDivide`）；集合与 Map 的 option API（7.5 段 tryFind/tryFind/Map.tryFind）
  5. Option 模块 API 表：map/bind/iter/defaultValue/orElse/isSome/isNone/filter（7.3/7.4 段引用）；bind 串联可能失败链
  6. 与 C# 交互：ofObj/toObj/ofNullable/toNullable（7.6 段）；`voption` 一句话
  7. `## 坑位清单`：`Some None` 嵌套、defaultValue 掩盖逻辑错误、option 直接当 bool 用要 `Option.isSome`、模式里忘 None 分支（编译器会提醒——这正是价值）

- [ ] **Step 4: 写 08-result.md**（约 170 行）：
  1. `# 08 · Result 与异常：失败处理的两个世界`
  2. 失败二分法：可预期的失败（Result）vs 不可预期（异常）；对比表（显式性/短路/性能/可组合性）
  3. Result 双轨模型（8.1 段）；错误也建模成 DU（8.3 段的 `ParseError`——注意别叫 `Error` 的原因）
  4. map/bind/mapError（8.2 段）；校验链（8.3 段 classifyAge 全文）
  5. 组合多个 Result（8.4 段 addResults）；预告第 14 章计算表达式消灭嵌套
  6. 异常侧：try/with、类型过滤 `:? FormatException`（8.5 段）；自定义异常与 raise/failwith/failwithf/invalidArg 表（8.6 段）
  7. 分层策略（8.7 段）：边界异常、内部 Result——第 20 章实战采用
  8. `## 坑位清单`：`Error` 撞名（错误 DU 别叫 Error）、Result 的 Error 类型不统一难组合、`with ex` 太宽吞掉所有异常、bind/map 混用类型错

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/fsharp && wc -l docs/0[5-8]*.md && git add docs && git commit -m "docs(fsharp): 第 05–08 章 模式匹配、集合、Option、Result

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 12: docs/09-records.md + docs/10-unions.md + docs/11-oop.md + docs/12-generics.md

**Files:**
- Create: `docs/09-records.md`、`docs/10-unions.md`、`docs/11-oop.md`、`docs/12-generics.md`

- [ ] **Step 1: 写 09-records.md**（约 160 行）：
  1. `# 09 · 记录类型：数据的默认形状`
  2. 问题先行：C# 手写 class 的样板（构造/属性/Equals/ToString）vs F# record 一行搞定——生成物对照表
  3. 定义、构造、字段访问、成员方法（9.1 段）
  4. `with` 非破坏性更新（9.2 段）：新值而非修改；浅拷贝语义
  5. 结构相等与哈希（9.3 段）：可作 Map 键/去重（distinct 演示）
  6. 解构（9.5 段）；匿名记录 `{| |}`（9.6 段）：临时投影、与 C# 互操作 DTO
  7. struct 记录（9.7 段）何时用（短生命周期大量小值）
  8. record + 集合管道（9.8 段）；record 与模式匹配联动回指第 05 章
  9. `## 坑位清单`：with 是浅拷贝（嵌套可变字段共享）、record 相等要求所有字段类型支持相等、匿名 record 与命名 record 不能直接互换、struct record 装箱

- [ ] **Step 2: 写 10-unions.md**（约 190 行）：
  1. `# 10 · 判别联合：用类型表达"或"`
  2. 问题先行：`shapeKind: int + width + height + radius` 的非法状态地狱 vs DU 让非法状态不可表示
  3. 简单 DU + match（10.1 段）；带名字段 vs 匿名字段
  4. 单 case DU 包装（10.2 段 OrderId/Email）：防裸 int/string 混用——对比表
  5. **递归 DU**：表达式树（10.3 段 Expr/eval/toStr 全文引用——本教程最经典的 F# 段落）；JSON 建模（10.4 段 Json/depth）
  6. DU vs enum 对比表（安全性/底层表示/何时用哪个）；`RequireQualifiedAccess`（10.5 段）
  7. DU 无处不在：option/Result 都是 DU（回指第 07/08 章）；领域建模建议
  8. `## 坑位清单`：大小写（Circle 是构造器 circle 不是）、分支遗漏编译器兜底、enum 装箱与 DU 的差别、DU 序列化要额外支持（连第 15 章）

- [ ] **Step 3: 写 11-oop.md**（约 160 行）：
  1. `# 11 · 面向对象在 F#：何时回到类`
  2. 问题先行：函数式优先，但三类场景仍要 OOP——框架互作（GUI/ASP.NET）、有状态组件、层次多态
  3. 接口定义与**对象表达式**（11.1 段）：`{ new ILogger with ... }` 免定义小类——F# 对"匿名实现"的回答；对比 C# 要先建类
  4. 抽象类、继承、override（11.2 段）；`inherit`/`abstract`/`default` 关键字表
  5. 类解剖（11.3 段）：隐式构造参数、`let` 私有状态、`member`、`this/_` 自引用、静态成员、链式调用
  6. IDisposable 与 `use`（11.4 段）：确定性释放；`use!` 一句话
  7. 类 vs record vs 函数 选型表
  8. `## 坑位清单`：构造参数自动成为字段吗（不会，除非用作成员）、接口显式实现不能直接点出、`override` 拼错编译错、可变状态默认私有（正确）

- [ ] **Step 4: 写 12-generics.md**（约 170 行）：
  1. `# 12 · 泛型、SRTP 与度量单位`
  2. 自动泛化（12.1 段）：F# 函数默认尽力泛化；`'a` 读法
  3. 显式约束（12.2 段）：`comparison`/`equality`/`struct`/`class`/`new()`/`unmanaged` 约束表
  4. `inline` 与 **SRTP**（12.3 段）：`^T` vs `'T` 的本质差别（编译点特化 vs 运行时擦除）；square/twiceSum 同一函数跑 int/float；成员约束 `area2D`（duck typing，Disk/Rect 都点出 Area）
  5. SRTP 的代价表：错误信息长、不能装进 list、调试难——何时退回普通泛型+接口
  6. **度量单位**（12.4 段全文引用）：`[<Measure>]`、`75.0<kg>`、单位参与类型检查（kg+m 编译错）、组合单位 `kg/m^2`、`float` 剥离、场景（科学计算/金融）
  7. `## 坑位清单`：SRTP 函数不能作为一等值传递、单位不一致编译错（正是价值）、`float x` 会把 `float<kg>` 变 `float`、inline 函数滥用编译膨胀

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/fsharp && wc -l docs/09* docs/10* docs/11* docs/12* && git add docs && git commit -m "docs(fsharp): 第 09–12 章 记录、判别联合、OOP、泛型与度量单位

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 13: docs/13-async.md + docs/14-computations.md + docs/15-files-json.md + docs/16-webapi.md

**Files:**
- Create: `docs/13-async.md`、`docs/14-computations.md`、`docs/15-files-json.md`、`docs/16-webapi.md`

- [ ] **Step 1: 写 13-async.md**（约 170 行）：
  1. `# 13 · 异步：async 与 task 两个世界`
  2. 问题先行：I/O 等待浪费 CPU；F# 两套异步设施的历史（async CE 是 F# 原创，task CE 是 F# 6 对 .NET Task 的直连）
  3. async 语法：`let!`/`do!`/`return`/`return!` 关键字表；**定义不执行**（13.1 段），`Async.RunSynchronously` 触发
  4. `Async.Parallel`（13.2 段）：实测耗时对比串行
  5. `task {}`（13.3 段）：与 async 差异对比表（底层/性能/上下文捕获/与 C# 互作）；新代码默认 task 的建议
  6. 互转 API 表（13.4 段）：Async.StartAsTask/AwaitTask/Task.FromResult
  7. 桥接 .NET XxxAsync（13.5 段 AwaitTask 惯用法）
  8. 取消（13.6 段）：CancellationTokenSource、OperationCanceledException
  9. `## 坑位清单`：忘 RunSynchronously（程序结束啥都没发生）、`Async.Sleep` vs `Task.Delay` 混用要桥接、task 里 `let!` 已解包 Task、闭包捕获循环变量

- [ ] **Step 2: 写 14-computations.md**（约 200 行）：
  1. `# 14 · 计算表达式：把语法糖做成语言`
  2. 问题先行：连续 `Result.bind`/`Option.bind` 的嵌套噪音（用第 08 章 classifyAge 的 bind 链改写成 CE 前后对比）
  3. **trace builder 逐行拆解**（14.2 段）：`let! a = Some 1` 脱糖为 `trace.Bind(Some 1, fun a -> ...)`——引用实际打印的 Bind/Return 顺序
  4. builder 协议成员表：Bind/Return/ReturnFrom/Zero/Delay/Combine/While/For/TryWith/TryFinally/Yield——各在什么语法处触发（只列前四个为必学）
  5. maybe builder 完整定义（14.3 段）；validate/result builder（14.4 段，含 `do!` 对 `Result<unit,_>`）
  6. `return!`（14.5 段）；内置 CE 清单：seq/async/task/query（回指第 06/13 章）
  7. 何时自定义 CE vs 高阶函数：三行内用函数，重复绑定链用 CE
  8. `## 坑位清单`：builder 缺 Zero 的编译错误场景、CE 内副作用执行时机（惰性）、Delay 忘记调 f 返回 thunk、过度抽象的 CE 难调试

- [ ] **Step 3: 写 15-files-json.md**（约 160 行）：
  1. `# 15 · 文件与 JSON：数据进出`
  2. 文本 IO API 表（15.1 段）：ReadAllText/WriteAllText/ReadAllLines/AppendAllText（一次读 vs 流式 File.ReadLines）
  3. Path 工具（15.2 段）：Combine/GetTempPath；跨平台路径提示
  4. CSV 解析管道（15.3 段）：split → record，标注其局限（引号/转义——现实用 CsvHelper 一句话）
  5. System.Text.Json（15.4 段）：Serialize/Deserialize、WriteIndented、命名策略选项；**.NET 9+ 对 F# record/option/DU 的原生支持**（15.5 段 option 字段实测输出）
  6. 若执行时发现原生支持异常 → 兜底段落：自定义 JsonConverter 示例（OptionConverter）
  7. `## 坑位清单`：默认编码（显式 UTF-8）、路径分隔符硬编码、反序列化 null、大小写敏感默认开启

- [ ] **Step 4: 写 16-webapi.md**（约 160 行）：
  1. `# 16 · Web API：F# 写服务端`
  2. 为什么 Minimal API 与 F# 气质相合（端点即函数）；fsproj 用 Sdk.Web 的差别
  3. 端点定义（16.1 段）：MapGet/MapPost/MapDelete；F# lambda 到委托的转换；`:> IResult` 上转型保重载决议
  4. 类型化结果（16.1 段）：Results.Ok/NotFound/Created/NoContent 表——状态码显式化
  5. 路由参数 `{id:int}`（16.1 段 DELETE）；JSON 自动协商（Todo record → JSON，连第 15 章）
  6. **自测模式**（16.4 段）：端口 0、StartAsync、HttpClient 自请求、StopAsync——为什么这样设计（可自动化验证不挂起）；生产用 RunAsync
  7. DI 一段：builder.Services 注册与构造注入（补充小片段，不入示例）
  8. 生态一句话：Giraffe/Saturn（更 F# 风格的路由 DSL）
  9. `## 坑位清单`：lambda 重载歧义、默认端口占用、Kestrel 控制台退出未 StopAsync 的挂起、F# 模块里 mutable 存储的线程安全警示

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/fsharp && wc -l docs/13* docs/14* docs/15* docs/16* && git add docs && git commit -m "docs(fsharp): 第 13–16 章 异步、计算表达式、文件 JSON、Web API

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 14: docs/17-testing.md + docs/18-interop.md + docs/19-gui.md + docs/20-todo.md

**Files:**
- Create: `docs/17-testing.md`、`docs/18-interop.md`、`docs/19-gui.md`、`docs/20-todo.md`

- [ ] **Step 1: 写 17-testing.md**（约 140 行）：
  1. `# 17 · 测试：xUnit 与纯函数架构`
  2. 工程：`dotnet new xunit -lang F#`；包三件套职责表（Test.Sdk=运行器接入、xunit=框架、runner.visualstudio=IDE 集成）
  3. `[<Fact>]` 与 `[<Theory>]`+`[<InlineData>]`（17.2/17.3 段引用）；F# 测试风格：`type 测试类 ()` 里 let 绑定方法、双反引号中文命名
  4. AAA 结构（Arrange-Act-Assert）套在 17.2 段示例上讲
  5. 断言与 F# 值：Assert.Equal 对 record/DU 天然结构相等（第 09/10 章的红利）；常用断言表（Equal/True/False/Empty/Throws）
  6. 可测架构：纯函数核心（parse/apply）+ 薄 IO 壳——为第 20 章铺垫；`dotnet test` 与 build.ps1 集成
  7. FsCheck 属性测试一句话展望
  8. `## 坑位清单`：测试必须在 type 里（顶层 let 不被识别）、浮点相等重载、中文测试名在某些 CI 的编码问题

- [ ] **Step 2: 写 18-interop.md**（约 170 行）：
  1. `# 18 · .NET 互操作：两个语言一个运行时`
  2. 日常互作（18.1 段）：StringBuilder/String.Join/String.Format；F# string 就是 System.String
  3. null 边界（18.2 段）：Option.ofObj/toObj 惯用法；F# 9 nullness 特性简述（引用类型空值注解在 F# 侧的感知增强——以编译器实际行为为准，示例只演示 Option 包装这条稳妥路径）
  4. Nullable<T>（18.3 段）：ofNullable/toNullable
  5. byref（18.4 段）：`&x`、不能进闭包/异步
  6. Span（18.5 段）：AsSpan 切片、何时关心
  7. 事件（18.6 段）：`evt.Add` 订阅；与第 19 章 GUI 事件同源
  8. Task 互转（18.7 段，回指第 13 章）；query 表达式（18.8 段）
  9. 暴露 F# 给 C#：curried 函数要元组化、record 的 C# 视图、`[<CompiledName>]` 一句话
  10. `## 坑位清单`：curried 函数在 C# 侧难看、byref/span 限制多、null 从边界漏进来、事件忘退订

- [ ] **Step 3: 写 19-gui.md**（约 150 行）：
  1. `# 19 · 桌面 GUI：WinForms 与 WPF`
  2. fsproj 配置对比表：UseWindowsForms / UseWPF、net10.0-windows、WinExe；`[<STAThread>]` 必要性
  3. WinForms（19.1–19.2 段引用 winforms/Program.fs）：控件树、Location 布局、`Click.Add` 事件（连第 18 章）
  4. WPF（19.3–19.4 段引用 wpf/Program.fs）：Application/Window 生命周期、内容模型（Content 单子）、StackPanel、`Children.Add` 返回值要 ignore
  5. F# GUI 的函数式视角：事件→新状态（record）→渲染；MVVM 与 INotifyPropertyChanged 一句话（推荐 Elmish/CommunityToolkit.Mvvm 生态）
  6. build.ps1 为何对 GUI 只构建不运行
  7. `## 坑位清单`：忘 STAThread、UseWindowsForms 忘开报类型不存在、WPF Add 忘 ignore 警告、net10.0-windows 不跨桌面 Linux

- [ ] **Step 4: 写 20-todo.md**（约 190 行）：
  1. `# 20 · 实战：待办管理器 CLI`
  2. 需求与命令表：add/done/remove/show/reset + 退出码约定（0 成功 1 失败）
  3. 工程结构（src/tests 双工程 + ProjectReference）；为何分两工程（可测试性）
  4. 领域建模（20.2 段）：Todo record + Command DU——"先定义数据与命令，再写逻辑"
  5. 解析（20.3 段 parse 全文）：模式匹配处理 argv；多词标题 String.concat
  6. 持久化（20.4 段 load/save）：TEMP 路径、try/with 容错
  7. 核心纯函数（20.5 段 apply 全文）：命令×状态→(新状态, 报告)——表驱动、无 IO、测试友好
  8. 薄壳 Program（20.6 段）：load→parse→apply→save + 退出码
  9. 测试（tests/Tests.fs 引用）：每个命令至少一个用例
  10. 实测演示：build.ps1 的 8 步序列实际输出（从 Task 9 验证输出粘贴）
  11. 扩展练习清单：优先级字段、按标题过滤、交互式 REPL 循环、`--json` 输出
  12. 全书回顾映射表：第 04 章管道→Program、第 05 章 match→parse、第 08 章 Result→parse/apply、第 09/10 章 record/DU→建模、第 15 章 JSON→save/load、第 17 章 xUnit→tests
  13. `## 坑位清单`：argv 的引号由 shell 处理、TEMP 文件多机冲突、apply 里做 IO 会毁掉可测性、ExitCode 忘返回

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/fsharp && wc -l docs/17* docs/18* docs/19* docs/20* && ls docs | wc -l && git add docs && git commit -m "docs(fsharp): 第 17–20 章 测试、互操作、GUI、实战待办管理器

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

预期：docs/ 下 20 个 .md。

---

### Task 15: README 重写 + CHEATSheet 新增 + 删除旧指南

**Files:**
- Rewrite: `README.md`
- Create: `CHEATSheet.md`
- Delete: `F#编程指南.md`

- [ ] **Step 1: 重写 README.md**（结构对齐 `G:\code\guide\dotnet\README.md`，内容如下骨架，20 行索引表逐行填）：
  1. 标题 `# F# 编程指南` + 一段定位（面向**会编程、初学 F#** 的读者；函数式优先；主线 .NET 10 / F# 10；每章"读讲解 → 跑示例 → 改代码再跑"）
  2. 目录结构代码块（README/docs/examples/build.ps1/CHEATSheet）
  3. 章节索引表：20 行 `| [NN 标题](docs/NN-xxx.md) | 一句话主题 | examples/NN_name |`（标题从各章首行抄）
  4. 构建工具链：dotnet 路径；编译验证命令块（-All / -Project / -Clean，注明 pwsh 7）
  5. 单跑示例：`cd examples/06_collections && dotnet run`

- [ ] **Step 2: 新建 CHEATSheet.md**（约 70 行速查，分节）：
  1. 语法速查：let/mutable/函数/match/function/for/try with（各一行）
  2. printfn 格式符表（%s %d %f %.2f %M %b %c %A）
  3. 集合模块速查：List/Array/Seq 的 map/filter/fold/sum/collect/groupBy/sortBy/tryFind/initInfinite
  4. Option/Result API：map/bind/defaultValue/orElse/ofObj/ofNullable；Result 的 map/bind/mapError
  5. async/task：Sleep/RunSynchronously/Parallel/StartAsTask/AwaitTask + task{} 关键字
  6. 计算表达式关键字：let!/do!/return/return!/yield/yield!
  7. dotnet CLI：new console -lang F# / new xunit -lang F# / run / fsi / test
  8. fsproj 要点：Compile 顺序、UseWindowsForms/UseWPF、Sdk.Web

- [ ] **Step 3: 删除旧文件并验证**

```bash
cd /g/code/guide/fsharp && git rm "F#编程指南.md" && grep -rn "编程指南" README.md CHEATSheet.md docs/ || true
```

预期：删除成功；其余文件不再引用旧文件名（README 历史提及清除）。

- [ ] **Step 4: Commit**

```bash
cd /g/code/guide/fsharp && git add -A && git commit -m "docs(fsharp): 重写 README、新增 CHEATSheet、删除旧单文件指南

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 16: 终验（全量构建 + 测试 + 链接与行数检查）

**Files:**
- Verify: 全部示例、docs、README、CHEATSheet

- [ ] **Step 1: 干净全量验证**

```bash
cd /g/code/guide/fsharp && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
```

预期核对清单：`[Build]` 共 19 次（02–18 十七个 + 19_gui 两个 + Todo）；`[Test]` 两次（17_testing、Todo.Tests，测试工程不输出 [Build] 而由 dotnet test 自行构建）；`[Run]` 十六次（02–16、18）；`[BuildOnly]` 两次；`[Test]` 两次全绿；Todo 八步序列输出正确；结尾 `[Done]`。

- [ ] **Step 2: 文档完整性**

```bash
cd /g/code/guide/fsharp && ls docs/*.md | wc -l && wc -l docs/*.md CHEATSheet.md README.md && grep -c "examples/" README.md
```

预期：docs 20 个文件；每章 100–220 行；README 索引表 20 行且文件都存在（逐个点开抽查 3 个链接路径）。

- [ ] **Step 3: 代码-文档一致性抽查**：抽第 05/08/20 章各 2 个代码片段，与 examples 对应 Program.fs 逐字对照（分节号一致）。

- [ ] **Step 4: REPL 抽查**

```bash
cd /g/code/guide/fsharp && printf 'let x = 42\nprintfn "x=%%d" x\n#quit;;\n' | "/g/scoop/apps/dotnet-sdk/current/dotnet.exe" fsi --quiet
```

预期输出 `x=42`（验证第 02 章的 REPL 会话可复现）。

- [ ] **Step 5: 勾选计划复选框并最终提交**

```bash
cd /g/code/guide && git status --short && git add docs/superpowers/plans/2026-09-16-fsharp-tutorial-rewrite.md && git commit -m "docs: 勾选 fsharp 教程实施计划全部 16 个任务完成

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```
