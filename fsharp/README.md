# F# 编程指南

面向**会编程、初学 F#** 的读者：重点是函数式思维、类型建模与惯用写法。主线 .NET 10 / F# 10，章节与示例一一对应，每章"读讲解 → 跑示例 → 改代码再跑"。

## 目录结构

```text
fsharp/
├── README.md               本文件
├── docs/                   20 章教程（01 → 20 顺序阅读）
├── examples/               19 个示例目录、21 个工程（章号 = 示例号）
├── build.ps1               统一构建脚本（须 PowerShell 7 / pwsh 运行）
└── CHEATSheet.md           语法速查
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 平台全景](docs/01-overview.md) | F# 与 .NET、dotnet CLI、fsx/fsproj/REPL | — |
| [02 第一个程序](docs/02-hello.md) | let、printfn、插值、dotnet fsi | `examples/02_hello` |
| [03 值与不可变性](docs/03-values.md) | 类型推断、let mutable、unit | `examples/03_values` |
| [04 函数](docs/04-functions.md) | 柯里化、管道、组合、递归 | `examples/04_functions` |
| [05 模式匹配](docs/05-patterns.md) | 全模式族谱、活动模式 | `examples/05_patterns` |
| [06 集合](docs/06-collections.md) | List/Array/Seq、fold 家族 | `examples/06_collections` |
| [07 Option](docs/07-option.md) | option、bind 链、null 边界 | `examples/07_option` |
| [08 Result 与异常](docs/08-result.md) | 校验链、try/with、分层策略 | `examples/08_result` |
| [09 记录类型](docs/09-records.md) | with、结构相等、匿名/struct 记录 | `examples/09_records` |
| [10 判别联合](docs/10-unions.md) | 递归 DU、单 case 包装、vs enum | `examples/10_unions` |
| [11 OOP 在 F#](docs/11-oop.md) | 类、接口、对象表达式、use | `examples/11_oop` |
| [12 泛型与度量单位](docs/12-generics.md) | 约束、SRTP、units of measure | `examples/12_generics` |
| [13 异步](docs/13-async.md) | async{} vs task{}、Parallel、取消 | `examples/13_async` |
| [14 计算表达式](docs/14-computations.md) | builder 协议、maybe/validate | `examples/14_computations` |
| [15 文件与 JSON](docs/15-files-json.md) | IO、CSV、System.Text.Json | `examples/15_files_json` |
| [16 Web API](docs/16-webapi.md) | Minimal API、自测型示例 | `examples/16_webapi` |
| [17 测试](docs/17-testing.md) | xUnit、Fact/Theory、纯函数架构 | `examples/17_testing` |
| [18 .NET 互操作](docs/18-interop.md) | null 边界、byref/Span、事件、query | `examples/18_interop` |
| [19 桌面 GUI](docs/19-gui.md) | WinForms 与 WPF（双工程） | `examples/19_gui` |
| [20 实战：待办管理器](docs/20-todo.md) | 建模、解析、持久化、测试 | `examples/20_todo` |

## 构建工具链

- .NET SDK：`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`（详见[第 01 章](docs/01-overview.md)）
- 构建脚本须 **pwsh 7** 运行（含中文无 BOM，Windows PowerShell 5.1 会误读）

## 编译验证

```powershell
cd G:\code\guide\fsharp
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全部示例：构建+运行+测试
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 06_collections   # 单个示例目录
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 20_todo      # 嵌套目录构建其下全部工程
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 清理 build 目录
```

行为分级：控制台示例编译后实际运行；GUI 工程只构建；测试工程自动 `dotnet test`。

单跑某个示例（第 02 章起的标准学法）：

```bash
cd examples/06_collections
dotnet run
```
