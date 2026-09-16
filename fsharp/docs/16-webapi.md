# 16 · Web API：F# 写服务端

> 对应示例：examples/16_webapi（自测型：启动 → 自请求 → 退出）

## 16.1 解决什么问题

F# 写后端最顺的形态是 ASP.NET Core **Minimal API**：端点就是函数，路由就是数据——和函数式气质完全合拍。本章做一个待办 API：GET 列表、POST 新增、DELETE 删除，并且示例是**自测型**的——启动真实 Kestrel、用 HttpClient 打自己、打印结果后退出，因此能进自动化验证（这是它与常规"挂住等请求"示例的根本区别）。

## 16.2 工程与数据模型

fsproj 用 **Web SDK**（自带 ASP.NET Core 框架引用，无 NuGet 包）：

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <Compile Include="Program.fs" />
  </ItemGroup>
</Project>
```

数据模型是第 09 章的 record，存储用 `ResizeArray`（教学用内存库；真实项目上数据库 + 第 17 章测试）：

```fsharp
type Todo = { Id: int; Title: string; Done: bool }

let todosStore = ResizeArray<Todo>()
```

> 并发提示：`ResizeArray` 非线程安全，多请求并发写会出问题——教学示例单线程自测没问题，生产换成 `ConcurrentDictionary` 或数据库。

## 16.3 端点定义：MapGet / MapPost / MapDelete

```fsharp
app.MapGet("/", Func<string>(fun () -> "F# Minimal API 自测")) |> ignore

app.MapGet("/todos", Func<IResult>(fun () ->
    if todosStore.Count = 0 then
        Results.NotFound("还没有待办")
    else
        Results.Ok(todosStore.ToArray()))) |> ignore

app.MapPost("/todos", Func<Todo, IResult>(fun todo ->
    todosStore.Add todo
    Results.Created($"/todos/{todo.Id}", todo))) |> ignore

app.MapDelete("/todos/{id:int}", Func<int, IResult>(fun id ->
    let removed = todosStore.RemoveAll(fun t -> t.Id = id)
    if removed > 0 then
        Results.NoContent()
    else
        Results.NotFound($"没有 id={id} 的待办"))) |> ignore
```

三个要点（全部来自示例编译实测）：

1. **显式 `Func<...>` 包装**：MapXxx 有十几个重载，裸 F# lambda 的重载决议不稳（会撞上 `RequestDelegate`）。`Func<IResult>`、`Func<Todo, IResult>` 一标就准——F# Minimal API 的惯用法。
2. **类型化结果**：`Results.Ok/NotFound/Created/NoContent` 显式控制状态码，比抛异常/返字符串明确。
3. **路由参数**：`{id:int}` 模板直接绑定到 `Func<int, IResult>` 的参数。

JSON 自动协商：`Results.Ok(todosStore.ToArray())` 把 record 数组序列化为 JSON——HTTP 侧默认 camelCase（`{"id":1,"title":"学 F#","done":false}`），与第 15 章控制台默认的 PascalCase 不同，这是 ASP.NET Core 的 Web 默认选项在起作用。

## 16.4 自测模式：让 API 验证可自动化

常规写法 `app.Run()` 会挂住等请求——没法进 build.ps1。示例的方案：

```fsharp
let app = buildApp ()
app.Urls.Add("http://127.0.0.1:0")          // 端口 0 = 随机可用端口
app.StartAsync().GetAwaiter().GetResult() |> ignore

let test = task {
    use client = new HttpClient()
    let baseUri = Seq.head app.Urls

    let! created =
        let payload = JsonSerializer.Serialize({ Id = 1; Title = "学 F#"; Done = false })
        let content = new StringContent(payload, Encoding.UTF8, "application/json")
        client.PostAsync(baseUri + "/todos", content)
    printfn "POST /todos → %O" created.StatusCode
    // … GET / DELETE / 再 GET 依次自请求并打印
}
test.GetAwaiter().GetResult()

app.StopAsync().GetAwaiter().GetResult() |> ignore
```

设计拆解：**端口 0** 让 OS 分配空闲端口（并行跑不冲突）；`StartAsync` 启动不阻塞；`Seq.head app.Urls` 拿实际地址；`task {}` 里逐个端点请求（第 13 章）；最后 `StopAsync` 优雅退出。教学程序里 `GetAwaiter().GetResult()` 阻塞等待是可接受的简化，生产入口用 `app.RunAsync()`。

实测输出（节选）：

```
POST /todos → Created
GET /todos → OK：[{"id":1,"title":"学 F#","done":false}]
DELETE /todos/1 → NoContent
GET /todos → NotFound（已清空）
```

## 16.5 DI 一段（补充片段，不入示例）

```fsharp
builder.Services.AddSingleton<ILogger, FileLogger>()   // 注册
// 端点参数或构造函数注入即可拿到——连第 11 章接口
```

真实项目里 logger/配置/dbContext 全走这条线。

## 16.6 生态一句话

想要更 F# 风格的路由 DSL（路由本身用模式匹配写），看社区框架 **Giraffe** 与其上的 **Saturn**；微软系 Minimal API 与 F# 的组合已足够顺手，本教程止步于此。

## 16.7 坑位清单

- **lambda 重载歧义**：裸 lambda 报 "HttpContext vs unit" 类错误就是撞重载了——上 `Func<...>`。
- **忘 StopAsync**：进程退出前不优雅停机，连接可能被硬切。
- **端口冲突**：写死端口并行测试必撞；用 `:0`。
- **ResizeArray 并发**：见 16.2，教学库不做并发保护。
- **`|> ignore`**：MapXxx 返回 endpoint 约定名，F# 侧不需要就 ignore 掉（每行都有，别嫌吵）。
