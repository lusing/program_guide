# .NET 编程指南

面向**会编程、初学 C#/.NET** 的读者：重点是 C# 语法习惯、.NET 平台模型与惯用写法。主线 .NET 10（LTS），章节与示例一一对应，每章"读讲解 → 跑示例 → 改代码再跑"。

## 目录结构

```text
dotnet/
├── README.md               本文件
├── docs/                   20 章教程（01 → 20 顺序阅读）
├── examples/               19 个示例工程（章号 = 示例号）
├── build.ps1               统一构建脚本（须 PowerShell 7 / pwsh 运行）
├── CHEATSheet.md           开发清单速查
└── advanced/               预留扩展阅读（docker/微服务/可观测/安全）
```

## 章节索引

| 章 | 主题 | 示例工程 |
|---|---|---|
| [01 平台全景](docs/01-overview.md) | CLR/IL、SDK 与 CLI、支持矩阵 | — |
| [02 第一个程序](docs/02-hello.md) | 顶层语句、插值、原始字符串 | `examples/02_hello` |
| [03 类型与控制流](docs/03-types.md) | 基本类型、switch 表达式、方法参数 | `examples/03_types` |
| [04 面向对象](docs/04-oop.md) | 类、继承、接口、多态、struct | `examples/04_oop` |
| [05 record 与模式匹配](docs/05-records.md) | 值语义、with、属性模式 | `examples/05_records` |
| [06 泛型与扩展方法](docs/06-generics.md) | 约束、泛型数学、扩展方法 | `examples/06_generics` |
| [07 委托、lambda 与事件](docs/07-delegates.md) | Func/Action、闭包、event | `examples/07_delegates` |
| [08 集合](docs/08-collections.md) | List/Dictionary、yield、扩展方法实战 | `examples/08_collections` |
| [09 LINQ](docs/09-linq.md) | 方法链、聚合、延迟执行 | `examples/09_linq` |
| [10 可空引用类型](docs/10-nullable.md) | NRT、`?.`/`??`、`is { }`、`!` | `examples/10_nullable` |
| [11 错误处理](docs/11-errors.md) | 异常、TryParse、Result 模式 | `examples/11_errors` |
| [12 文件与 JSON](docs/12-files-json.md) | File/Path、System.Text.Json | `examples/12_files_json` |
| [13 async/await](docs/13-async.md) | Task、WhenAll、异步流 | `examples/13_async` |
| [14 并行](docs/14-parallel.md) | Parallel、Interlocked、并发集合 | `examples/14_parallel` |
| [15 Span 与 Memory](docs/15-span.md) | 切片、stackalloc、少分配 | `examples/15_span` |
| [16 Minimal API](docs/16-webapi.md) | 路由、类型化结果、DI | `examples/16_webapi` |
| [17 EF Core](docs/17-efcore.md) | DbContext、变更追踪、CRUD | `examples/17_efcore` |
| [18 测试](docs/18-testing.md) | AAA、断言设计、测试替身 | `examples/18_testing` |
| [19 跨平台与可移植性](docs/19-portable.md) | 支持矩阵、netstandard、多目标、发布、Mono | `examples/19_portable` |
| [20 现代 C# 纵览](docs/20-modern-csharp.md) | C# 9→13+ 特性演进 | `examples/20_modern` |

## 构建工具链

- .NET SDK：`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`（详见[第 01 章](docs/01-overview.md)）

## 编译验证

```powershell
cd G:\code\guide\dotnet
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全部示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 09_linq      # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 清理 build 目录
```

单跑某个示例（第 02 章起的标准学法）：

```bash
cd examples/09_linq
dotnet run
```
