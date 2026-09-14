# F# 编程教程

F# 是一种函数式优先、面向 .NET 平台的语言。它既支持函数式编程范式，也可以很好地与面向对象和命令式编程协作，适合：

- 数据处理与脚本编程
- 数值计算与分析
- 后端服务与 API
- 交互式开发与快速实验
- 与 .NET 运行时的无缝集成

本教程的目标是让读者能在本地 `.NET SDK` 环境中直接编译、运行和验证 F# 示例，并把代码存放为独立示例工程。

## 1. F# 与 .NET 的关系

F# 运行在 .NET 生态中，兼容：

- `System.String`
- `List`, `Array`, `Seq`
- `Task` / `async`
- LINQ 和 .NET 类库

最典型的 F# 代码通常使用：

- `let` 声明值和函数
- `match` 做模式匹配
- `function` / `fun` 定义匿名函数
- `record` 与 `discriminated union` 表达数据模型

## 2. 编译与运行模型

在本机使用 .NET SDK 直接创建 `console` 项目：

```powershell
G:\scoop\apps\dotnet-sdk\current\dotnet.exe new console -lang F# -o hello-fsharp
```

然后可直接运行：

```powershell
G:\scoop\apps\dotnet-sdk\current\dotnet.exe run --project .\hello-fsharp\hello-fsharp.fsproj
```

本仓库中的 `build.ps1` 会自动批量编译并运行各示例工程。

## 3. 基本语法：值、函数和输出

最简单的 F# 程序：

```fsharp
let message = "Hello from F#"
printfn "%s" message
```

F# 强调表达式和值，通常不需要显式的 `;` 分号。函数定义写法如下：

```fsharp
let add a b = a + b
let result = add 12 8
printfn "12 + 8 = %d" result
```

关键特点：

- `let` 创建绑定
- 函数是“一等公民”
- `printfn` 是常用输出函数
- 标准库函数可以链式组合

## 4. 基础类型与条件判断

F# 支持常见基础类型：

```fsharp
let name = "guide"
let age = 21
let score = 98.5
let active = true

if active then
    printfn "Name: %s, Age: %d, Score: %.1f" name age score
else
    printfn "inactive"
```

常见类型包括：

- `int`, `float`, `bool`, `string`
- `list<'T>`, `array<'T>`, `seq<'T>`
- `option<'T>`
- `Result<'T, 'E>`

## 5. 函数和模式匹配

函数式编程的核心能力之一是模式匹配：

```fsharp
let describeNumber n =
    match n with
    | x when x < 0 -> "negative"
    | 0 -> "zero"
    | x when x % 2 = 0 -> "even"
    | _ -> "odd"

[1; 2; 3; 4; 5; 6]
|> List.iter (fun x -> printfn "%d -> %s" x (describeNumber x))
```

模式匹配使代码更容易表达分支逻辑，并且比传统条件判断更简洁。

## 6. 记录类型与判别联合类型

F# 非常适合建模数据结构。

### 6.1 记录类型

```fsharp
type Person =
    { Name: string
      Age: int }

let alice = { Name = "Alice"; Age = 28 }
printfn "%s is %d years old." alice.Name alice.Age
```

### 6.2 判别联合类型（Discriminated Union）

```fsharp
type Shape =
    | Circle of radius: float
    | Rectangle of width: float * height: float

let area shape =
    match shape with
    | Circle r -> System.Math.PI * r * r
    | Rectangle (w, h) -> w * h

printfn "circle area = %.2f" (area (Circle 3.0))
```

这类类型对 DSL、状态机、配置模块和业务模型非常有用。

## 7. 集合与 LINQ 风格处理

F# 丰富的集合操作非常适合数据处理：

```fsharp
let values = [8; 3; 11; 7; 5; 9; 2]

let doubled = values |> List.map (fun x -> x * 2)
let evens = values |> List.filter (fun x -> x % 2 = 0)
let total = values |> List.sum

printfn "doubled = %A" doubled
printfn "evens = %A" evens
printfn "sum = %d" total
```

F# 与 .NET 也很自然地兼容 LINQ：

```fsharp
open System.Linq

let result = values.AsQueryable().Where(fun x -> x > 5).ToList()
printfn "%A" result
```

## 8. 异步工作流

F# 的 `async` 非常适合 I/O 绑定、并发、多任务处理：

```fsharp
let fetchDataAsync =
    async {
        do! Async.Sleep 100
        return "done"
    }

let result = fetchDataAsync |> Async.RunSynchronously
printfn "%s" result
```

这是 F# 语言在实战工程中最重要的特性之一，尤其适合：

- 网络请求
- 文件读取
- 批量处理
- UI / 服务端协作逻辑

## 9. 文件 I/O 与本地数据处理

F# 完全可以读取和写入文件：

```fsharp
open System
open System.IO

let path = Path.Combine(Environment.CurrentDirectory, "notes.txt")
let text = "F# writes files easily.\n"
File.WriteAllText(path, text)
let readBack = File.ReadAllText(path)
printfn "%s" readBack
```

这适合做：

- 日志文件
- 配置文件
- 批量输入输出
- 数据清洗脚本

## 10. 与 .NET 生态集成

F# 能直接使用 .NET 类库、NuGet 包和 ASP.NET Core 等框架。常见用途包括：

- `System.IO`：文件和目录
- `System.Net.Http`：HTTP 请求
- `System.Text.Json`：JSON 处理
- `System.Linq`：集合查询
- `Task` / `async`：异步开发

这使 F# 不只是教学语言，也能成为生产级开发语言。

## 11. WinForms 与 WPF 桌面界面开发

F# 不仅适合脚本和后端，也能做 Windows 桌面应用。最常见的两种技术栈是：

- WinForms：更传统、控件丰富、适合快速桌面工具
- WPF：更现代、XAML 与数据绑定、适合复杂界面和 MVVM

### 11.1 WinForms：快速创建表单程序

在 F# 中，WinForms 典型做法是使用 `System.Windows.Forms` 和 `Application.Run`：

```fsharp
open System
open System.Windows.Forms

[<EntryPoint>]
[<STAThread>]
let main _ =
    let form = new Form(Text = "F# WinForms Demo")
    let button = new Button(Text = "Click")
    button.Click.Add(fun _ -> MessageBox.Show("Hello from F#") |> ignore)
    form.Controls.Add(button)
    Application.Run(form)
    0
```

要编译 WinForms 项目，需要在 `.fsproj` 中配置：

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0-windows</TargetFramework>
    <UseWindowsForms>true</UseWindowsForms>
  </PropertyGroup>
</Project>
```

适合场景：

- 工具类应用
- 数据录入窗体
- 本地管理器/小型桌面工具
- 业务系统内部界面原型

### 11.2 WPF：更现代的桌面 UI 工具链

WPF 的核心是 `Window`、`StackPanel`、`TextBox`、`Button` 和绑定模型。一个最小例子如下：

```fsharp
open System
open System.Windows
open System.Windows.Controls

[<EntryPoint>]
[<STAThread>]
let main _ =
    let app = new Application()
    let window = new Window(Title = "F# WPF Demo", Width = 420.0, Height = 260.0)
    let stack = new StackPanel()
    let name = new TextBox(Width = 240.0)
    let button = new Button(Content = "Click")
    let label = new TextBlock(Text = "Waiting...")

    button.Click.Add(fun _ ->
        let value = if String.IsNullOrWhiteSpace name.Text then "empty" else name.Text
        label.Text <- sprintf "Hello, %s" value)

    stack.Children.Add(name) |> ignore
    stack.Children.Add(button) |> ignore
    stack.Children.Add(label) |> ignore
    window.Content <- stack
    app.Run(window)
    0
```

WPF 项目需要这样的配置：

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
  </PropertyGroup>
</Project>
```

适合场景：

- 数据展示和编辑界面
- 复杂布局与样式主题
- MVVM 架构
- 企业级桌面程序

### 11.3 F# 在 GUI 开发中的优势

F# 结合 Windows 桌面开发的优点包括：

- 函数式风格更适合表达 UI 状态转换
- `record` 和 `option` 适合做表单模型
- `async` 能很好处理后台工作和长任务
- 与 .NET 桌面 API 无缝集成

### 11.4 本目录的 GUI 例子

本目录新增了两个示例：

- `07_winforms`：基础 WinForms 表单与按钮事件
- `08_wpf`：基础 WPF 窗口、控件与事件处理

这两个示例都采用本地 .NET SDK 进行编译验证。GUI 项目本身需要交互式桌面环境，因此在自动化脚本中采用“构建验证”而非直接桌面运行方式。

## 12. 本目录示例工程

本仓库中已经整理了以下 F# 示例：

- `01_hello_console`：最小 Hello World
- `02_basic_types`：变量、字符串和布尔值
- `03_functions_and_patterns`：函数、分支和模式匹配
- `04_records_and_discriminated_unions`：数据建模
- `05_collections_and_linq`：集合操作与筛选
- `06_async_and_file_io`：异步与文件写入
- `07_winforms`：Windows 窗体程序基础示例
- `08_wpf`：WPF 桌面程序基础示例

这些示例都位于 `examples/` 目录下，并可通过 `build.ps1` 做实际编译验证。

## 13. 学习路径建议

推荐按下面顺序学习：

1. 值与基本类型
2. 函数与副作用边界
3. 条件判断和模式匹配
4. 集合与 `List` / `Seq`
5. 记录类型与联合类型
6. 异步 `async`
7. 文件 I/O 与 .NET 集成
8. WinForms 桌面编程
9. WPF 现代界面开发
10. 进一步进入 ASP.NET Core / 数据处理 / 数值分析

## 14. 结论

F# 的价值在于：

- 语法简洁、类型安全
- 函数式思维强，适合模型表达
- 与 .NET 生态深度集成
- 适合数据处理、算法、脚本、后端服务和桌面界面开发

如果想进一步提高 F# 能力，建议在本地使用 `dotnet` CLI 反复练习，并用真实项目目录中的示例进行编译验证；如需做 Windows GUI 应用，重点练习 WinForms 与 WPF 的事件、控件和状态管理。
