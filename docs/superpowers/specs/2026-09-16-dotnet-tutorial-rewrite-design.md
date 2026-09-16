# dotnet 教程重写设计（2026-09-16）

## 1. 背景与问题

`dotnet/` 目录现状：15 个可编译示例工程 + `build.ps1`，但 `DOTNET编程指南.md` 只是
"工程路径 + 演示点列表"（176 行），没有讲解，不适合学习。仓库中 WPF/Android 等教程
已采用 `docs/NN-name.md` 分章结构（每章 100–200 行，"先讲解决什么问题再讲语法"），
dotnet 需对齐该标准。

教学路径存在缺口：无面向对象章（class/interface/继承）、无委托/lambda/事件章（LINQ
的前置课）、无可空引用类型章（新手最常撞的警告墙）、无跨平台可移植性内容。

## 2. 目标与非目标

**目标**：把示例罗列改写为 20 章、适合自学的教程；补齐四大缺口；示例与章节一一对应
（章号 = 示例号）；全部示例可 `build.ps1 -All` 编译通过。

**非目标**：
- 不改写为面向零基础新手（起点是"会编程，初学 C#/.NET"）
- 不做实战收尾大项目（用户已选择"补缺口 + 重排"方案）
- 示例主线不降级到 netstandard2.0/net48——Win 8.1、macOS/Linux、Mono 作为第 19 章
  的教学主题（教"如何为这些平台写代码"），而非示例运行环境
- `advanced/` 空脚手架不动

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 读者定位 | 有编程基础，初学 C#/.NET（与 WPF/Android 教程一致，可横向对比其他语言） |
| 章节结构 | 补缺口 + 重排：新增 OOP、委托/lambda/事件、可空引用类型、跨平台四章 |
| 旧文件 | 删除 `DOTNET编程指南.md`、`SAMPLES_MIGRATION_MAP.md`、`samples/`；重写 `README.md`；保留并更新 `CHEATSheet.md` 索引 |
| 主线 SDK | .NET 10（`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`），所有示例 target `net10.0`（19 章示例除外，见下） |

## 4. 章节结构（docs/，20 章）

学习曲线：语言基础 → OOP → 函数式设施 → 数据与查询 → 可靠性 → 异步与性能 →
应用层 → 平台兼容 → 语言演进。

| # | 文件 | 主题 | 示例目录 |
|---|---|---|---|
| 01 | `01-overview.md` | 平台全景：CLR/IL/JIT、SDK 与 dotnet CLI、csproj、build.ps1 用法、支持矩阵速览与目标框架选型 | —（引用 02_hello） |
| 02 | `02-hello.md` | 第一个程序：顶层语句 vs Main、插值字符串、原始字符串字面量 | `02_hello`（←01_hello_console） |
| 03 | `03-types.md` | 类型与控制流：基本类型、var、数组、string 不可变、switch 表达式、方法与参数（out/ref/params）；跨平台提示：char/编码 | `03_types`（←02_types_control） |
| 04 | `04-oop.md` | **新增** 面向对象：字段/属性、构造、静态、继承、virtual/abstract/sealed、接口、多态、class vs struct | `04_oop`（新建） |
| 05 | `05-records.md` | record 与模式匹配：值语义、with、解构、属性/关系/位置模式 | `05_records`（←04_records_pattern） |
| 06 | `06-generics.md` | 泛型与扩展方法：类型约束、`INumber<T>` 泛型数学 | `06_generics`（←05_generics_extensions） |
| 07 | `07-delegates.md` | **新增** 委托、lambda 与事件：delegate、Func/Action、闭包、event——LINQ 前置课 | `07_delegates`（新建） |
| 08 | `08-collections.md` | 集合：List/Dictionary/HashSet、IEnumerable、yield 迭代器 | `08_collections`（←11_collections_mapped） |
| 09 | `09-linq.md` | LINQ：方法链 vs 查询表达式、聚合、延迟执行与多次枚举陷阱 | `09_linq`（←03_linq_basics） |
| 10 | `10-nullable.md` | **新增** 可空引用类型：NRT、`?`、CS8602 类警告排查、与 null 容器的交互 | `10_nullable`（新建） |
| 11 | `11-errors.md` | 错误处理：异常层次、catch 过滤器、TryParse、Result 模式 | `11_errors`（←06_error_handling） |
| 12 | `12-files-json.md` | 文件与 JSON：File/Path、System.Text.Json；跨平台提示：路径分隔符/行尾/显式 Encoding | `12_files_json`（←07_file_json） |
| 13 | `13-async.md` | async/await：Task、WhenAll、IAsyncEnumerable、async void 陷阱 | `13_async`（←08_async_await） |
| 14 | `14-parallel.md` | 并行：Parallel.ForEach、Interlocked、ConcurrentDictionary | `14_parallel`（←09_parallel_tasks） |
| 15 | `15-span.md` | Span 与 Memory：切片、栈分配、避免分配 | `15_span`（←10_span_memory） |
| 16 | `16-webapi.md` | ASP.NET Core Minimal API：路由、结果类型、DI | `16_webapi`（←12_minimal_api_mapped） |
| 17 | `17-efcore.md` | EF Core：DbContext、Code First、CRUD | `17_efcore`（←13_efcore_mapped） |
| 18 | `18-testing.md` | 测试：xUnit 风格、AAA、断言 | `18_testing`（←14_testing_mapped） |
| 19 | `19-portable.md` | **新增** 跨平台与可移植性（详见 §5） | `19_portable`（新建，多项目） |
| 20 | `20-modern-csharp.md` | 现代 C# 特性纵览：C# 10→13+ 语法演进速览 | `20_modern`（←15_new_features_mapped） |

## 5. 第 19 章设计：跨平台与可移植性

章节内容：

1. **支持矩阵与决策树**：给定目标平台（Windows 8.1 / Win10+ / macOS / Linux / Mono）
   → 选 .NET 10 / .NET 6(EOL) / .NET Framework 4.8 / netstandard2.0 库 + Mono
2. **netstandard2.0 的角色**：库 target netstandard2.0 可同时被 .NET Framework
   4.6.1+ / Mono / Unity / 现代 .NET 消费——可移植性的核心实践
3. **多目标编译**：`<TargetFrameworks>` 复数形式、`#if NET / NETFRAMEWORK` 条件编译
4. **可移植编码习惯**：`Path.Combine`、行尾、显式 `Encoding.UTF8`、`Environment.NewLine`
5. **LangVersion 与语言特性兼容**：record 在 net48/netstandard2.0 报错的原因
   （IsExternalInit）、polyfill
6. **发布模型**：RID、self-contained（目标机免装运行时——Win 8.1 场景的替代思路）、
   single-file
7. **Mono 专节**：历史角色、现存使用场景（Unity 等）、何时迁移到现代 .NET

示例 `19_portable/` 结构（多项目，教学"可移植库 + 消费端"的真实模式）：

```text
19_portable/
├── PortableLib/          # netstandard2.0 类库：可移植核心逻辑
│   ├── PortableLib.csproj
│   └── Greeting.cs       # 含 #if 条件编译演示
└── PortableApp/          # net10.0 控制台，ProjectReference 引用库
    ├── PortableApp.csproj
    └── Program.cs
```

## 6. 示例工程调整

- 现有 15 个示例 `git mv` 重编号重命名（映射见 §4 表），去掉 `_mapped` 后缀
- 新建 4 个示例：`04_oop`、`07_delegates`、`10_nullable`、`19_portable`；前三个遵循
  现有"单 Program.cs + csproj（net10.0）"模式，中文注释
- 现有示例代码基本保留（已可编译、主题聚焦），章节讲解时逐段引用示例代码
- `build.ps1` 改动两处：
  1. 工程发现从"每目录取第一个 csproj"改为递归枚举 `examples/**/*.csproj`（支持
     19_portable 嵌套结构）
  2. `BaseIntermediateOutputPath` 按工程名区分子目录（当前全部工程共享同一 obj 路径，
     是潜在冲突；多项目示例会触发）

## 7. 文档风格规范（对齐 WPF 教程）

- 文件名 `NN-kebab-case.md`；标题 `# NN · 主题：副标题`
- 每章开头 `> 对应示例：examples/NN_name`
- 结构：先讲"解决什么问题"再讲语法；代码段配讲解；对比表格；坑位清单（按命中率
  排序的排查步骤）；跨章引用（如"第 12 章实战就是这样写的"）
- 每章 100–200 行；中文行文，代码注释中文
- 相关章加"跨平台提示"小节：01（支持矩阵）、03（编码）、12（路径/行尾）

## 8. 文件变更清单

| 操作 | 文件/目录 |
|---|---|
| 新增 | `docs/01-overview.md` … `docs/20-modern-csharp.md`（20 个文件） |
| 新增 | `examples/04_oop/`、`examples/07_delegates/`、`examples/10_nullable/`、`examples/19_portable/` |
| 重命名 | `examples/` 下 15 个既有目录（见 §4 映射） |
| 修改 | `build.ps1`（§6 两处）、`README.md`（重写：新目录树 + 构建说明）、`CHEATSheet.md`（索引指向新章节） |
| 删除 | `DOTNET编程指南.md`、`SAMPLES_MIGRATION_MAP.md`、`samples/`（整个目录） |
| 不动 | `advanced/`、`build/`（产物目录） |

## 9. 事实核查清单（写作时用 WebSearch 核实，不凭记忆）

- [ ] 各 .NET 版本 Windows 最低版本要求（.NET 6 = Win7 SP1、.NET 8/10 = Win10 1607+）
- [ ] .NET 6 EOL 日期（2024-11）、.NET 8 LTS 期限（2026-11）、.NET 9 STS 期限
- [ ] .NET Framework 4.8 对 Windows 8.1 的支持；4.8.1 不支持 8.1
- [ ] Mono 仓库归档时间（2024）与维护现状、现存使用场景
- [ ] Windows 8.1 主流/扩展支持结束时间（2018-01 / 2023-01，ESU 至 2024-01）

## 10. 验证标准

1. `.\build.ps1 -All`：19 个示例（15 改名 + 4 新建）全部编译通过
2. `.\build.ps1 -Clean` 后重新 `-All` 通过（obj 路径改动验证）
3. 逐章抽查：文档引用的示例路径真实存在、代码片段与示例一致
4. 交叉链接抽查：章内 `第 NN 章` 引用无断链；README/CHEATSheet 索引与 docs/ 实际
   文件一致
5. `git status` 干净前：旧文件全部删除，`dotnet/` 目录内无残留引用（grep `DOTNET编程指南\|_mapped\|samples/`）

## 11. 风险与对策

| 风险 | 对策 |
|---|---|
| 重编号 git mv 后文档引用旧名 | 验证标准 §10.3/§10.5 的 grep 检查 |
| 19_portable 多目标在共享 build 目录下 obj 冲突 | build.ps1 按工程名拆分 obj 子目录（§6） |
| netstandard2.0 库使用新语法报错 | 库代码保守用 C# 7.3 兼容语法，或在 csproj 设 LangVersion + polyfill（章节正好以此教学） |
| 支持矩阵事实过时/记错 | §9 清单逐项 WebSearch 核实后落笔 |
