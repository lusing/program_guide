# fsharp 教程重写设计（2026-09-16）

## 1. 背景与问题

`fsharp/` 目录现状：单文件 `F#编程指南.md`（375 行，语法罗列式浅讲）+ 8 个单
`Program.fs` 示例 + 105 行 `build.ps1`。对比今天完成的 dotnet 教程（20 章独立文档
2263 行、19 个示例工程、README/CHEATSheet、健壮的 build.ps1），F# 教程明显"太
简单"：无活动模式、SRTP、度量单位、计算表达式等 F# 特色深入章节，无 Option/Result
专门章，无 Web API/测试/互操作生态章，现有示例每个只演示 3–5 个 API。

教学缺口：函数式核心（柯里化/组合/管道的系统讲解）、递归 DU 建模、计算表达式原理、
async{} vs task{} 辨析、与 C# 生态互操作（nullness/byref）全部缺失。

## 2. 目标与非目标

**目标**：重写为 20 章、每章 100–200 行、适合自学的详细教程；章号 = 示例号（02–20
共 19 个示例目录）；全部工程可 `build.ps1 -All` 编译验证、控制台示例实际运行、测试
工程实际通过；第 20 章为实战收尾项目（待办管理器 CLI）。

**非目标**：
- 不做 Fable/Bolero/类型提供器等第三方生态章节（20 章主线零社区依赖，仅用
  xUnit/ASP.NET Core 等微软系包）
- 不面向零基础读者（起点是"会编程，初学 F#"，与 dotnet/WPF/Android 教程一致）
- 不单独设"现代 F# 纵览"章——F# 4.7→9 特性（task{}、字符串插值、nullness 等）
  融入各相关章节讲解

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 章节规模 | 20 章对齐 dotnet 教程 |
| GUI 章节 | 保留 1 章（WinForms + WPF 合并，现有 07/08 示例并入） |
| 实战项目 | 要：第 20 章待办管理器 CLI（DU 命令建模 + 解析 + JSON 持久化 + 测试） |
| 读者定位 | 会编程、初学 F# |
| 主线 SDK | .NET 10（`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`），示例 target `net10.0`（GUI 章为 `net10.0-windows`） |
| 旧文件 | 删除 `F#编程指南.md`；重写 `README.md`、`build.ps1`；新增 `CHEATSheet.md` |

## 4. 章节结构（docs/，20 章）

学习曲线：入门 → 函数式核心 → 类型建模 → 语言深入 → 生态实战 → GUI/实战收尾。

| # | 文件 | 主题 | 示例目录 | 来源 |
|---|---|---|---|---|
| 01 | `01-overview.md` | 平台全景：F# 定位与函数式优先、与 .NET/C# 关系、SDK 与 dotnet CLI、fsx/fsproj/`dotnet fsi` 三种工作方式、build.ps1 用法 | —（引用 02_hello） | 新写（吸收旧指南 §1–2） |
| 02 | `02-hello.md` | 第一个程序：let 绑定、缩进敏感语法、printfn/printf 格式化、类型推断初识、REPL 交互工作流 | `02_hello` | ←01_hello_console 扩充 |
| 03 | `03-values.md` | 值与不可变性：基本类型、unit、隐式转换边界、`let mutable`/ref、类型推断与自动泛化 | `03_values` | ←02_basic_types 扩充 |
| 04 | `04-functions.md` | 函数：柯里化与部分应用、管道 `\|>`、组合 `>>`、lambda、递归与尾递归、高阶函数 | `04_functions` | ←03_functions_and_patterns 拆分 |
| 05 | `05-patterns.md` | 模式匹配：常量/解构/cons/record 模式、when、`function`、完备性检查、**活动模式**（完整/部分） | `05_patterns` | ←03 拆分 + 新增 |
| 06 | `06-collections.md` | 集合：list/array/seq 对比与互转、模块函数三胞胎、fold 家族、无限序列、与 LINQ 互操作 | `06_collections` | ←05_collections_and_linq 扩充 |
| 07 | `07-option.md` **新增** | Option 与 null：`option`、Option 模块、模式交互、null 问题、`Nullable<T>` 边界 | `07_option` | 新建 |
| 08 | `08-result.md` **新增** | Result 与错误处理：`Result`、bind/map 链、try/with、自定义异常、Railway 风格 | `08_result` | 新建 |
| 09 | `09-records.md` | record：定义、with 复制更新、解构、匿名 record、struct record、相等与比较 | `09_records` | ←04_records_and_discriminated_unions 拆分 |
| 10 | `10-unions.md` | 判别联合：DU、单 case DU、递归 DU（表达式 AST/JSON 值建模）、vs enum、`RequireQualifiedAccess` | `10_unions` | ←04 拆分扩充 |
| 11 | `11-oop.md` **新增** | OOP 在 F#：类、接口、继承、**对象表达式**、属性/索引器、静态成员、函数式与 OOP 的分工 | `11_oop` | 新建 |
| 12 | `12-generics.md` **新增** | 泛型与度量单位：类型约束、inline、**SRTP**（静态解析类型参数）、units of measure | `12_generics` | 新建 |
| 13 | `13-async.md` | 异步：`async {}` vs `task {}` 辨析、Async/Task 互转、`Async.Parallel`、取消令牌 | `13_async` | ←06_async_and_file_io 拆分 |
| 14 | `14-computations.md` **新增** | 计算表达式：builder 协议（Bind/Return/Zero…）、自定义 `maybe {}`/`result {}`、seq/async 的本质 | `14_computations` | 新建 |
| 15 | `15-files-json.md` | 文件与 JSON：File/Path/Directory、CSV 解析、System.Text.Json 序列化 F# 类型（option/DU 自定义 converter） | `15_files_json` | ←06 拆分扩充 |
| 16 | `16-webapi.md` **新增** | ASP.NET Core Minimal API：路由、类型化结果、DI；示例为**自测型**（启动 Kestrel→HttpClient 自请求→打印→退出） | `16_webapi` | 新建 |
| 17 | `17-testing.md` **新增** | 测试：xUnit、AAA、record/DU 友好断言、纯函数可测性 | `17_testing` | 新建（xUnit 工程） |
| 18 | `18-interop.md` **新增** | .NET 互操作：调用 C# 库、F# 9 nullness、byref/span、事件、async↔Task、module/命名空间 | `18_interop` | 新建 |
| 19 | `19-gui.md` | 桌面 GUI：19.1 WinForms、19.2 WPF，仅构建验证 | `19_gui`（嵌套双工程） | ←07_winforms + 08_wpf 合并 |
| 20 | `20-todo.md` | **实战**：待办管理器 CLI——DU 建模命令、模式匹配解析、Result 错误处理、record 状态、JSON 持久化、xUnit 测试 | `20_todo`（嵌套 src/tests 双工程） | 新建 |

## 5. 示例工程规划

共 19 个示例目录、21 个工程：

- 单工程目录 17 个（02–18，全部控制台，`net10.0`）。
- `19_gui/`：嵌套 `winforms/19_gui_winforms.fsproj` + `wpf/19_gui_wpf.fsproj`
  （`net10.0-windows`，`UseWindowsForms`/`UseWPF`），对齐 dotnet 19_portable 的
  嵌套结构。
- `20_todo/`：嵌套 `src/Todo.fsproj`（控制台主程序）+ `tests/Todo.Tests.fsproj`
  （xUnit，引用 src）。

各示例不再"3–5 个 API 点到即止"，而是与章节讲解配套的 80–200 行可读程序：一个
`Program.fs`（或少量模块文件），从上到下按章内小节顺序组织，输出与文档中展示的
运行结果一致。

## 6. build.ps1 重写设计

对齐 dotnet 版本并保留"运行验证"能力：

1. **pwsh 7 运行**（含中文无 BOM，与仓库其他教程脚本一致；Windows PowerShell 5.1
   会按 ANSI 误读）。
2. **obj 按工程名拆分**：`build/obj/<fsproj 基名>/`，bin 共享
   （`build/bin/`）——修复现脚本全体共享一个 obj 的隐患。
3. **构建前清扫 examples 下游离 obj/bin**（读者 `dotnet run` 的默认产物与重定向
   路径冲突会报 CS0579/F# 等价错误）。
4. **递归发现 `*.fsproj`**（覆盖 19_gui、20_todo 嵌套结构）。
5. **分级行为**：
   - 控制台工程（02–16、18）：编译后运行 exe，校验退出码。
   - `16_webapi`：自测型程序，运行后自然退出。
   - GUI 工程（19_gui 下）：仅构建，按 `net10.0-windows`/工程名识别。
   - 测试工程（17_testing、20_todo/tests）：`dotnet test`（自建默认 obj，下次
     运行脚本时被清扫，无冲突）。
   - `20_todo/src`：以演示参数序列运行（add/list/done/remove）。
6. 参数 `-All` / `-Project <name>`（嵌套目录构建其下全部 fsproj）/ `-Clean`，行为
   与 dotnet 脚本一致。

## 7. 文件操作清单

| 操作 | 文件 |
|---|---|
| 删除 | `F#编程指南.md` |
| 重写 | `README.md`（目录结构 + 20 章索引表 + 构建验证说明，对齐 dotnet README） |
| 重写 | `build.ps1`（见 §6） |
| 新增 | `CHEATSheet.md`（F# 语法/模块函数速查，对齐 dotnet CHEATSheet 风格） |
| 新增 | `docs/01-overview.md` … `docs/20-todo.md` 共 20 章 |
| 改名/扩充 | 示例 01–06 → 02/03/04/05/06/13 等（见 §4 来源列），删除旧目录 |
| 清理 | `build/` 下现有产物（新版脚本 -Clean 重建） |

## 8. 验证方案

1. `pwsh -ExecutionPolicy Bypass -File build.ps1 -All`：21 个工程全部编译通过，
   控制台示例全部运行成功，`dotnet test` 两个测试工程全绿。
2. 每章文档引用的示例代码与 `examples/` 工程实际内容一致（写作时从工程摘录）。
3. README 章节索引表与 docs/ 实际文件一一对应。
4. 抽查 `dotnet fsi` REPL 会话可复现第 02 章演示。

## 9. 风险与对策

| 风险 | 对策 |
|---|---|
| .NET 10 SDK 附带的 F# 语言版本（F# 9/10）与文中特性声明不符 | 实施第一步用 `dotnet fsi` 打印版本确认，再定稿涉及版本的表述（nullness 需 F# 9+，task{} 需 F# 6+） |
| System.Text.Json 对 F# option/DU 默认序列化不友好 | 第 15 章教自定义 `JsonConverter`（既是知识点又零额外依赖），不引第三方 FSharp.SystemTextJson |
| `dotnet test` 与重定向 obj 冲突 | 测试工程不经重定向构建，让其在示例目录自建 obj/bin，由下次脚本运行的清扫步骤回收 |
| GUI 工程在无桌面环境挂起 | 仅构建不运行（沿用现脚本策略） |
| WPF/WinForms F# API 细节写错（无 LSP 校验 MFC 教训） | 以实际编译通过为准；文档中的 GUI 代码从可编译示例工程摘录 |
