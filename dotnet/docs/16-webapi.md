# 16 · ASP.NET Core Minimal API：几十行起一个服务

> 对应示例：`examples/16_webapi`

## 1. 模型：宿主、管道、端点

ASP.NET Core 应用 = **Kestrel**（内建 Web 服务器，监听端口收 HTTP）+ **中间件管道**（请求逐层穿过：路由、认证、日志…）+ 你注册的**端点**（URL → 处理逻辑）。Minimal API（.NET 6 起）把这三件事压缩进一个文件——示例 51 行就是一个完整的用户 CRUD 服务。

## 2. 骨架与数据

```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var users = new List<User>
{
    new(1, "Alice"),
    new(2, "Bob"),
    new(3, "Charlie")
};
```

`CreateBuilder` → `Build` 两步是每个 ASP.NET Core 应用的固定开场：builder 阶段注册服务（依赖注入，§5），app 阶段配置管道与端点。`users` 是内存里的"数据库"（第 17 章换真的）；`record User(int Id, string Name)` 垫在文件末尾——数据形状一行说清（第 05 章）。

## 3. 端点：路由 + 类型化结果

读一个：

```csharp
app.MapGet("/api/users/{id:int}", (int id) =>
{
    var user = users.FirstOrDefault(u => u.Id == id);
    return user is null ? Results.NotFound() : Results.Ok(user);
});
```

三个成分：

- **路由**：`/api/users/{id:int}` 模板里 `{id}` 是路由参数，`:int` 是**约束**（非整数直接 404，进不了处理函数）；`id` 自动绑定到 lambda 的同名参数。
- **处理逻辑**：`FirstOrDefault`（第 09 章）查表；`is null`（第 10 章）判"查不到"。
- **类型化结果**：`Results.Ok(user)` → 200 + JSON body；`Results.NotFound()` → 404。**别返回裸字符串或裸对象**——`Results.*` 家族（`Ok/Created/NoContent/BadRequest/NotFound/Conflict`）明确给出状态码，还能参与 OpenAPI 文档生成与测试断言。

写操作两个：

```csharp
app.MapPost("/api/users", (UserCreate input) =>
{
    if (string.IsNullOrWhiteSpace(input.Name))
    {
        return Results.BadRequest("name is required");
    }

    var nextId = users.Count == 0 ? 1 : users.Max(x => x.Id) + 1;
    var user = new User(nextId, input.Name.Trim());
    users.Add(user);
    return Results.Created($"/api/users/{user.Id}", user);
});

app.MapDelete("/api/users/{id:int}", (int id) =>
{
    var idx = users.FindIndex(x => x.Id == id);
    if (idx < 0) return Results.NotFound();
    users.RemoveAt(idx);
    return Results.Ok(new {message = "deleted", id});
});
```

新知识点：

- **请求体绑定**：POST 的 lambda 参数是 `UserCreate` record——框架自动把 JSON body 反序列化成它（第 12 章的 JsonSerializer 在背后）。参数来自"路由 → 查询串 → body"按类型自动匹配，不用手写。
- **校验**：`IsNullOrWhiteSpace` 手工检查——Minimal API 不自动校验，重要字段（此处 `name`）自己把关，坏输入回 400。
- `Results.Created(位置, 内容)`：201 + `Location` 头指向新资源——REST 惯例。

## 4. DI 一小节

示例没用 DI（数据是局部变量），但真实服务离不开：builder 阶段注册，端点参数自动领取。

```csharp
builder.Services.AddSingleton<UserStore>();     // 注册：单例
app.MapGet("/api/users", (UserStore store) => Results.Ok(store.All));   // 使用：参数注入
```

原理是第 04 章的"依赖接口/抽象 + 谁用谁声明"——HTTP 层不 new 依赖，向框架要。`AddSingleton/AddScoped(每请求一个)/AddTransient(每次一个)` 是三个生命周期档位。

## 5. 运行与实测

示例为 CI 友好做了个设计：默认只编译不监听端口，传 `--run` 才启动：

```csharp
if (args.Contains("--run", StringComparer.OrdinalIgnoreCase))
{
    app.Run();
}
else
{
    Console.WriteLine("Minimal API 示例已编译；使用 --run 启动。");
}
```

实测（两个终端，或后台起服务）：

```bash
cd examples/16_webapi
dotnet run -- --run            # 注意中间的 -- ，之后的参数传给程序
# 另开终端：
curl http://localhost:5000/api/users
curl -X POST http://localhost:5000/api/users -H "Content-Type: application/json" -d '{"name":"Dave"}'
curl http://localhost:5000/api/users/1
```

预期：列表 JSON → 201 创建 → 单个用户。改代码里的端口/数据再试，端点行为立刻跟走。

## 6. 从 Web 到后台服务：Worker Service

同一套宿主模型换个模板就是**长期运行的后台服务**（定时任务、队列消费、监控 agent）：

```csharp
// dotnet new worker 生成的骨架，核心是 BackgroundService
public class Worker(ILogger<Worker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            logger.LogInformation("worker running at {Time}", DateTimeOffset.Now);
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
        }
    }
}
// Program.cs: builder.Services.AddHostedService<Worker>(); builder.Build().RunAsync();
```

循环 + `stoppingToken` 是全部框架：宿主启动时调 `ExecuteAsync`，关闭时取消 token。发布成 Windows 服务/系统守护进程只差一行 `builder.Services.AddWindowsService()`（或 `AddSystemd()`）——老教材里专章讲的"Windows 服务程序"，如今是 `dotnet new worker` + 一个 NuGet 包的事。

## 7. 坑位清单

1. **路由顺序**：具体的在前、带参数/通配的在后——`/api/users/me` 若注册在 `/api/users/{id}` 之后，"me" 会被 {id} 捕获（幸有 `:int` 约束兜底，但依赖约束不如排对顺序）。
2. **返回匿名对象 vs record**：`Results.Ok(new {message = "deleted", id})` 应急可以，正式契约用 record——字段名拼写错误在编译期就暴露。
3. **忘 `app.Run()`**：程序瞬间退出"什么都没发生"——Run 是阻塞监听，示例把它放在条件分支里正是提醒它的存在。
4. **端口占用/不确定端口**：控制台启动日志会打印实际监听地址（`http://localhost:5000` 或随机端口）；被占用时用 `--urls http://localhost:5099` 指定。
5. **POST body 大小写**：绑定 JSON 的 `"name"` 与 record 属性 `Name` 靠 camelCase 策略匹配（第 12 章）——字段名对不上会得到 null 而不是报错。
