# .NET SDK 10.0 编程指南

欢迎使用 .NET SDK 10.0！本指南将帮助您快速上手并掌握 .NET 10 的核心概念和开发技巧。

## 目录

- [新特性概览](#新特性概览)
- [环境安装](#环境安装)
- [项目结构](#项目结构)
- [基础语法](#基础语法)
- [高级特性](#高级特性)
- [最佳实践](#最佳实践)

---

## 新特性概览

.NET 10.0 引入了多项重要改进：

| 特性 | 描述 |
|------|------|
| **性能优化** | JIT 编译器改进，启动速度提升 15%+ |
| **C# 13** | 新增参数条件属性、增强的模式匹配 |
| **改进的 ORM** | Entity Framework Core 10 性能提升 |
| **JSON 技能** | `System.Text.Json` 新增更多特性 |
| **Web 开发** | Minimal API 增强，简化 API 开发 |
| **AI 集成** | 原生支持机器学习模型集成 |

---

## 环境安装

### Windows

```bash
# 安装 .NET 10 SDK
winget install Microsoft.DotNet.SDK.10

# 验证安装
dotnet --version
```

### macOS

```bash
# 使用 Homebrew 安装
brew install --cask dotnet-sdk10

# 验证安装
dotnet --version
```

### Linux (Ubuntu/Debian)

```bash
# 添加 Microsoft 包签名密钥
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

# 安装 .NET 10 SDK
sudo apt-get update && sudo apt-get install -y apt-transport-https
sudo apt-get update && sudo apt-get install -y dotnet-sdk-10.0
```

---

## 项目结构

### 创建新项目

```bash
# 创建控制台应用
dotnet new console -n MyApplication

# 创建 Web API 项目
dotnet new webapi -n MyApi

# 创建类库
dotnet new classlib -n MyLibrary

# 创建单元测试项目
dotnet new xunit -n MyTests
```

### 典型项目结构

```
MyApplication/
├── Program.cs          # 应用程序入口点
├── MyApplication.csproj  # 项目文件
├── Properties/
│   └── launchSettings.json
├── Models/            # 数据模型
├── Services/          # 业务逻辑
└── appsettings.json   # 配置文件
```

### 项目文件示例

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

</Project>
```

---

## 基础语法

### Hello World

```csharp
// Program.cs
Console.WriteLine("Hello, .NET 10!");

// 字符串插值
string name = "World";
Console.WriteLine($"Hello, {name}!");

// 格式化输出
double pi = 3.14159;
Console.WriteLine($"Pi: {pi:F2}");
```

### 变量和数据类型

```csharp
// 基本类型
int age = 25;
double price = 19.99;
string name = "Alice";
bool isActive = true;

// 隐式类型
var count = 10;        // int
var text = "Hello";    // string

// nullable 类型
int? nullableNumber = null;
string? nullableString = null;
```

### 条件语句

```csharp
int number = 10;

// if-else
if (number > 0)
{
    Console.WriteLine("Positive");
}
else if (number < 0)
{
    Console.WriteLine("Negative");
}
else
{
    Console.WriteLine("Zero");
}

// switch 表达式 (C# 8+)
string result = number switch
{
    > 0 => "Positive",
    < 0 => "Negative",
    _ => "Zero"
};
```

### 循环

```csharp
// for 循环
for (int i = 0; i < 5; i++)
{
    Console.WriteLine(i);
}

// foreach 循环
var numbers = new[] { 1, 2, 3, 4, 5 };
foreach (var num in numbers)
{
    Console.WriteLine(num);
}

// while 循环
int counter = 0;
while (counter < 5)
{
    Console.WriteLine(counter);
    counter++;
}
```

### 方法

```csharp
// 基本方法
int Add(int a, int b)
{
    return a + b;
}

// 返回值方法
string GetMessage() => "Hello";

// out 参数
void Divide(int a, int b, out int result)
{
    result = a / b;
}

// ref 参数
void Increment(ref int value)
{
    value++;
}
```

---

## 高级特性

### 集合

```csharp
// List<T>
var names = new List<string> { "Alice", "Bob" };
names.Add("Charlie");

// Dictionary<TKey, TValue>
var ages = new Dictionary<string, int>
{
    ["Alice"] = 25,
    ["Bob"] = 30
};

// Stack<T>
var stack = new Stack<int>();
stack.Push(1);
stack.Push(2);
var item = stack.Pop();

// Queue<T>
var queue = new Queue<int>();
queue.Enqueue(1);
queue.Enqueue(2);
var first = queue.Dequeue();
```

### LINQ 查询

```csharp
using System.Linq;

var numbers = new[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

// 查询表达式
var evenNumbers = from n in numbers
                  where n % 2 == 0
                  select n;

// 方法语法
var squares = numbers
    .Where(n => n % 2 == 0)
    .Select(n => n * n)
    .ToList();

// 分组
var grouped = numbers
    .GroupBy(n => n % 2 == 0 ? "Even" : "Odd")
    .ToDictionary(g => g.Key, g => g.ToList());
```

### 异常处理

```csharp
try
{
    int result = 10 / 0;
}
catch (DivideByZeroException ex)
{
    Console.WriteLine($"Error: {ex.Message}");
}
finally
{
    Console.WriteLine("Cleanup code");
}

// 空合并运算符
string? value = null;
string result = value ?? "Default";

// 空条件运算符
var person = new { Name = "Alice" };
string? name = person?.Name;
```

### 异步编程

```csharp
// async/await
async Task MainAsync()
{
    string result = await DownloadStringAsync();
    Console.WriteLine(result);
}

async Task<string> DownloadStringAsync()
{
    using var httpClient = new HttpClient();
    return await httpClient.GetStringAsync("https://example.com");
}

// 并行执行
var tasks = new List<Task>
{
    Task1Async(),
    Task2Async(),
    Task3Async()
};
await Task.WhenAll(tasks);
```

### 泛型

```csharp
// 泛型类
public class Repository<T>
{
    private readonly List<T> _items = new();

    public void Add(T item) => _items.Add(item);
    public T Get(int index) => _items[index];
}

// 泛型方法
T GetDefault<T>() => default(T);

// 约束
public class Container<T> where T : class, new()
{
    public void Create() => _item = new T();
    private T? _item;
}
```

### 属性

```csharp
public class Person
{
    // 自动属性
    public string Name { get; set; } = string.Empty;

    // 只读属性
    public DateTime CreatedAt { get; } = DateTime.Now;

    // 计算属性
    public int Age { get; }

    // 初始化
    public Person(string name, int age)
    {
        Name = name;
        Age = age;
    }
}

// 记录类型 (C# 9+)
public record Person(string Name, int Age);
```

### 接口和抽象类

```csharp
// 接口
public interface ILogger
{
    void Log(string message);
    Task LogAsync(string message);
}

// 抽象类
public abstract class BaseRepository
{
    public abstract void Save();

    public void Dispose()
    {
        // 公共实现
    }
}

// 默认接口方法 (C# 8+)
public interface ILogger
{
    public void Log(string message) => Console.WriteLine(message);
}
```

### 枚举

```csharp
// 基本枚举
public enum Status
{
    Pending,
    Active,
    Inactive
}

// 标志枚举
[Flags]
public enum Permissions
{
    None = 0,
    Read = 1,
    Write = 2,
    Execute = 4,
    All = Read | Write | Execute
}

// 使用
Permissions perms = Permissions.Read | Permissions.Write;
bool hasRead = perms.HasFlag(Permissions.Read);
```

---

## Web 开发

### Minimal API

```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// GET 请求
app.MapGet("/api/users", () =>
{
    return new[] { new User("Alice"), new User("Bob") };
});

// POST 请求
app.MapPost("/api/users", (User user) =>
{
    return Results.Created($"/api/users/{user.Id}", user);
});

// 带参数的路由
app.MapGet("/api/users/{id}", (int id) =>
{
    return Results.Ok(id);
});

// 使用 Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

app.Run();

record User(string Name, int Id);
```

### 配置管理

```csharp
var builder = WebApplication.CreateBuilder(args);

// 从 appsettings.json 读取配置
var connectionString = builder.Configuration.GetConnectionString("Default");

// 绑定配置到类
public class AppSettings
{
    public string ServiceUrl { get; set; } = string.Empty;
}

var settings = builder.Configuration.Get<AppSettings>();
```

### Dependency Injection

```csharp
var builder = WebApplication.CreateBuilder(args);

// 注册服务
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 自定义服务
builder.Services.AddTransient<IMailService, MailService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddSingleton<ICacheService, CacheService>();

var app = builder.Build();
```

---

## 数据访问

### Entity Framework Core 10

```csharp
// DbContext
public class AppDbContext : DbContext
{
    public DbSet<User> Users { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder options)
        => options.UseSqlServer("connection string");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>()
            .HasKey(u => u.Id);
    }
}

// Entity
public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

// 使用
using var context = new AppDbContext();
var users = context.Users.Where(u => u.Name.Contains("Alice")).ToList();
```

### ADO.NET

```csharp
using var connection = new SqlConnection(connectionString);
await connection.OpenAsync();

using var command = new SqlCommand("SELECT * FROM Users", connection);
using var reader = await command.ExecuteReaderAsync();

while (await reader.ReadAsync())
{
    var id = reader.GetInt32(reader.GetOrdinal("Id"));
    var name = reader.GetString(reader.GetOrdinal("Name"));
}
```

---

## JSON 处理

```csharp
using System.Text.Json;
using System.Text.Json.Serialization;

// 序列化
var person = new Person { Name = "Alice", Age = 25 };
string json = JsonSerializer.Serialize(person);

// 格式化输出
string prettyJson = JsonSerializer.Serialize(person,
    new JsonSerializerOptions { WriteIndented = true });

// 反序列化
Person person2 = JsonSerializer.Deserialize<Person>(json);

// 自定义序列化
public class Person
{
    [JsonPropertyName("full_name")]
    public string Name { get; set; } = string.Empty;

    [JsonIgnore]
    public int InternalId { get; set; }
}

// 支持的类型
public class Response
{
    public Dictionary<string, object> Data { get; set; } = new();
    public List<object> Items { get; set; } = new();
}
```

---

## 单元测试

```csharp
// 使用 xUnit
public class CalculatorTests
{
    [Fact]
    public void Add_PositiveNumbers_ReturnsSum()
    {
        // Arrange
        var calculator = new Calculator();

        // Act
        var result = calculator.Add(2, 3);

        // Assert
        Assert.Equal(5, result);
    }

    [Theory]
    [InlineData(1, 2, 3)]
    [InlineData(-1, 1, 0)]
    public void Add_Inputs_ReturnsSum(int a, int b, int expected)
    {
        var calculator = new Calculator();
        Assert.Equal(expected, calculator.Add(a, b));
    }
}

// 项目文件
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="xunit" Version="2.9.0" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2" />
  </ItemGroup>

</Project>
```

---

## 最佳实践

### 代码组织

```csharp
// 使用命名空间
namespace MyApplication.Services

// 使用别名
using Service = MyApplication.Services.UserService;
using Json = System.Text.Json;

// 文件范围的命名空间 (C# 10+)
namespace MyApplication.Models;

public class User { }
```

### 文件结构

```
MyApplication/
├── Program.cs              # 应用入口
├── Models/                 # 数据模型
│   ├── User.cs
│   └── Order.cs
├── Services/               # 业务逻辑
│   ├── UserService.cs
│   └── OrderService.cs
├── Controllers/            # API 控制器
│   ├── UserController.cs
│   └── OrderController.cs
├── Data/                   # 数据访问
│   ├── AppDbContext.cs
│   └── Repositories/
├── Tests/                  # 单元测试
│   ├── UnitTests/
│   └── IntegrationTests/
└── wwwroot/                # 静态文件 (Web 项目)
```

### 常用配置

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "Default": "Server=.;Database=MyDb;Trusted_Connection=True;"
  }
}
```

### 性能提示

1. 使用 `Span<T>` 和 `ReadOnlySpan<T>` 处理字符串和数组
2. 优先使用 `IAsyncEnumerable<T>` 处理大数据流
3. 使用 `ValueTask` 替代 `Task` 处理可能同步完成的操作
4. 合理使用对象池 `ObjectPool<T>`
5. 使用 `Memory<T>` 避免不必要的内存分配

```csharp
// Span 示例
void ProcessString(string text)
{
    ReadOnlySpan<char> span = text.AsSpan();
    // 高效处理
}

// ValueTask 示例
async ValueTask<int> GetValueAsync()
{
    if (IsCached())
        return cachedValue;  // 同步返回，无需分配 Task

    return await GetValueFromRemoteAsync();
}
```

---

## 常见问题

### Q: 如何升级到 .NET 10？

```bash
# 更新项目文件中的 TargetFramework
<TargetFramework>net10.0</TargetFramework>

# 更新NuGet包
dotnet add package Microsoft.AspNetCore.App.Runtime
```

### Q: 如何启用全球化不变模式？

```bash
# 在项目文件中
<PropertyGroup>
  <InvariantGlobalization>true</InvariantGlobalization>
</PropertyGroup>
```

### Q: 如何启用 AOT 编译？

```bash
# 发布时启用
dotnet publish -c Release -r win-x64 --self-contained true /p:PublishAot=true
```

---

## 学习资源

- [官方文档](https://learn.microsoft.com/zh-cn/dotnet/)
- [.NET 生命周期](https://dotnet.microsoft.com/download/dotnet/10.0)
- [GitHub 示例](https://github.com-dotnet)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/.net)

---

## licence

本指南采用 MIT 许可证。
