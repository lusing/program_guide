# .NET 编程指南（示例工程版）

本指南面向 `dotnet` 目录下的可编译示例工程，强调“每章一个独立项目，可单独构建、可全量验证”。

## 目录

1. [环境准备](#环境准备)
2. [Hello Console](#hello-console)
3. [类型与流程控制](#类型与流程控制)
4. [LINQ 基础](#linq-基础)
5. [Record 与模式匹配](#record-与模式匹配)
6. [泛型与扩展方法](#泛型与扩展方法)
7. [异常与结果返回](#异常与结果返回)
8. [文件与 JSON](#文件与-json)
9. [异步与 await](#异步与-await)
10. [并行任务](#并行任务)
11. [Span 与 Memory](#span-与-memory)
12. [样例迁移映射](#样例迁移映射)
13. [统一编译验证](#统一编译验证)

---

## 环境准备

- .NET SDK：`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`
- 教程目录：`G:\code\guide\dotnet`

检查版本：

```powershell
G:\scoop\apps\dotnet-sdk\current\dotnet.exe --version
```

---

## Hello Console

工程：`examples/01_hello_console`

演示点：
- 顶层语句
- 字符串插值
- 原始字符串字面量

---

## 类型与流程控制

工程：`examples/02_types_control`

演示点：
- 基本类型与 `var`
- `switch` 表达式
- `for/foreach/while`

---

## LINQ 基础

工程：`examples/03_linq_basics`

演示点：
- `Where/Select/OrderBy/GroupBy`
- 查询表达式与方法链

---

## Record 与模式匹配

工程：`examples/04_records_pattern`

演示点：
- `record` 值对象
- 属性模式与位置模式

---

## 泛型与扩展方法

工程：`examples/05_generics_extensions`

演示点：
- 泛型方法
- 约束（`where T : INumber<T>`）
- 扩展方法

---

## 异常与结果返回

工程：`examples/06_error_handling`

演示点：
- `try/catch`
- `TryParse` 风格
- 结果联合（成功/失败）

---

## 文件与 JSON

工程：`examples/07_file_json`

演示点：
- 文件写入与读取
- `System.Text.Json` 序列化/反序列化

---

## 异步与 await

工程：`examples/08_async_await`

演示点：
- `Task.WhenAll`
- `async/await`
- `IAsyncEnumerable`

---

## 并行任务

工程：`examples/09_parallel_tasks`

演示点：
- `Parallel.ForEach`
- `Interlocked`
- `ConcurrentDictionary`

---

## Span 与 Memory

工程：`examples/10_span_memory`

演示点：
- `Span<T>` 切片
- `ReadOnlySpan<T>`
- 避免不必要分配

---

## 样例迁移映射

为把旧的 `samples/` 零散代码纳入标准工程，本目录新增以下映射工程：

- `examples/11_collections_mapped`：承接 `samples/collections/*`
- `examples/12_minimal_api_mapped`：承接 `samples/api/MinimalApi`
- `examples/13_efcore_mapped`：承接 `samples/efcore/CodeFirst`
- `examples/14_testing_mapped`：承接 `samples/testing/UnitTests`
- `examples/15_new_features_mapped`：承接 `samples/new-features/CSharp13` 与部分 `performance/Span`

详细逐文件映射请查看 [SAMPLES_MIGRATION_MAP.md](./SAMPLES_MIGRATION_MAP.md)。

---

## 统一编译验证

全量构建：

```powershell
cd G:\code\guide\dotnet
.\build.ps1 -All
```

单工程：

```powershell
.\build.ps1 -Project 04_records_pattern
```

清理：

```powershell
.\build.ps1 -Clean
```
