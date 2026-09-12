# .NET 10.0 代码示例 - 目录说明

## 快速开始
```bash
# 运行特定示例
cd samples/<category>/<example>
dotnet run

# 运行测试
cd samples/testing/UnitTests
dotnet test
```

## 示例分类

### basics/ - 基础语法
- `Hello/` - Hello World、字符串插值、多行字符串
- `Variables/` - 变量、数据类型、nullable 类型
- `ControlFlow/` - 条件、循环、模式匹配
- `Methods/` - 方法、参数、泛型

### collections/ - 集合操作
- `List/` - List<T> 操作、扩展方法
- `Dictionary/` - Dictionary<T> 使用
- `LINQ/` - LINQ 查询、分组、联接

### async/ - 异步编程
- `Basic/` - async/await、异常处理、HttpClient
- `Parallel/` - Parallel.For、PLINQ、并发集合

### api/ - Web API
- `MinimalApi/` - Minimal API、路由、Swagger

### efcore/ - 数据访问
- `CodeFirst/` - Entity Framework Core、Code First

### testing/ - 测试
- `UnitTests/` - xUnit、Mock、FluentAssertions

### performance/ - 性能优化
- `Span/` - Span<T>、Memory<T>、零分配

### new-features/ - 新特性
- `CSharp13/` - C# 13、.NET 10 新特性

## 环境要求
- .NET 10.0 SDK
- Visual Studio 2022 17.8+ 或 VS Code

## 相关文档
- [官方文档](https://learn.microsoft.com/zh-cn/dotnet/)
- [C# 13 文档](https://learn.microsoft.com/zh-cn/dotnet/csharp/whats-new/csharp-13)