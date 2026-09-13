# dotnet/samples 迁移映射表

本文件记录 `samples/` 旧目录向 `examples/` 标准工程的迁移关系。

## 映射总览

| 旧位置 | 新工程 | 说明 |
|---|---|---|
| `samples/basics/Hello/Program.cs` | `examples/01_hello_console` | 顶层语句、插值字符串、原始字符串 |
| `samples/basics/Variables/Program.cs` | `examples/02_types_control` | 变量、字面量、数组、字符串操作 |
| `samples/basics/ControlFlow/Program.cs` | `examples/02_types_control`、`examples/04_records_pattern` | if/switch/模式匹配 |
| `samples/basics/Methods/Program.cs` | `examples/05_generics_extensions`、`examples/06_error_handling`、`examples/08_async_await` | 泛型、参数风格、异步方法 |
| `samples/collections/List/Program.cs` | `examples/11_collections_mapped` | List 操作与扩展方法 |
| `samples/collections/Dictionary/Program.cs` | `examples/11_collections_mapped` | Dictionary 操作与查询 |
| `samples/collections/LINQ/Program.cs` | `examples/03_linq_basics`、`examples/11_collections_mapped` | LINQ 查询、分组、投影 |
| `samples/async/Basic/Program.cs` | `examples/08_async_await` | async/await、Task.WhenAll、异步流 |
| `samples/async/Parallel/Program.cs` | `examples/09_parallel_tasks` | Parallel、并发集合、Interlocked |
| `samples/api/MinimalApi/Program.cs` | `examples/12_minimal_api_mapped` | Minimal API 路由与结果类型 |
| `samples/efcore/CodeFirst/Program.cs` | `examples/13_efcore_mapped` | EF Core InMemory 上下文与 CRUD |
| `samples/testing/UnitTests/CalculatorTests.cs` | `examples/14_testing_mapped` | xUnit 风格用例迁移为可编译自检 |
| `samples/performance/Span/Program.cs` | `examples/10_span_memory`、`examples/15_new_features_mapped` | Span/Memory 与分配优化思路 |
| `samples/new-features/CSharp13/Program.cs` | `examples/15_new_features_mapped` | 新语法与泛型数学示例（修正可编译） |

## 迁移策略说明

- 优先保证所有迁移后的标准工程都能 `dotnet build` 通过。
- 对旧示例中不兼容或语法错误片段进行了等价改写（保留主题，不保留错误写法）。
- `samples/` 目录暂保留为历史参考；后续可按需要归档或删除。

