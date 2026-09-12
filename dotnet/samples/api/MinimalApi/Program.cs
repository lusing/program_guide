// Minimal API 示例
// 文件位置: samples/api/MinimalApi/Program.cs

var builder = WebApplication.CreateBuilder(args);

// 配置服务
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors();

var app = builder.Build();

// 中间件
app.UseCors(policy => policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
app.UseSwagger();
app.UseSwaggerUI();

// GET - 获取所有用户
app.MapGet("/api/users", (ILogger<Program> logger) =>
{
    logger.LogInformation("获取所有用户");
    return Results.Ok(new[]
    {
        new User(1, "Alice"),
        new User(2, "Bob"),
        new User(3, "Charlie")
    });
});

// GET - 根据 ID 获取用户
app.MapGet("/api/users/{id:int}", (int id) =>
{
    if (id <= 0) return Results.BadRequest("无效的 ID");
    if (id > 3) return Results.NotFound($"未找到 ID 为 {id} 的用户");

    return Results.Ok(new User(id, $"User{id}"));
});

// POST - 创建用户
app.MapPost("/api/users", (User user) =>
{
    if (string.IsNullOrEmpty(user.Name)) return Results.BadRequest("用户名不能为空");
    if (user.Name.Length < 2) return Results.BadRequest("用户名至少需要 2 个字符");

    // 模拟保存
    user.Id = GetHashCode(); // 简化处理

    return Results.Created($"/api/users/{user.Id}", user);
});

// PUT - 更新用户
app.MapPut("/api/users/{id:int}", (int id, User inputUser) =>
{
    if (id != inputUser.Id) return Results.BadRequest("ID 不匹配");

    return Results.Ok(new User(id, inputUser.Name));
});

// DELETE - 删除用户
app.MapDelete("/api/users/{id:int}", (int id) =>
{
    if (id <= 0) return Results.BadRequest("无效的 ID");
    if (id > 3) return Results.NotFound($"未找到 ID 为 {id} 的用户");

    return Results.Ok(new { message = $"用户 {id} 已删除" });
});

// 带参数的路由
app.MapGet("/api/search", (string? q, int page = 1, int pageSize = 10) =>
{
    return Results.Ok(new
    {
        Query = q ?? "",
        Page = page,
        PageSize = pageSize,
        Total = 50
    });
});

// 内容协商
app.MapGet("/api/data", () =>
{
    return Results.Ok(new { message = "Hello", timestamp = DateTime.UtcNow });
});

// 返回不同状态码
app.MapGet("/api/status/{code:int}", (int code) =>
{
    return code switch
    {
        200 => Results.Ok(new { status = "OK" }),
        201 => Results.Created(new { status = "Created" }),
        400 => Results.BadRequest(new { error = "Bad Request" }),
        404 => Results.NotFound(new { error = "Not Found" }),
        500 => Results.StatusCode(500),
        _ => Results.StatusCode(code)
    };
});

// named endpoints
app.MapGet("/api/health", () => Results.Ok(new { status = "Healthy" }))
    .WithName("HealthCheck")
    .WithOpenApi();

// 组路由
var usersGroup = app.MapGroup("/api/users-v2");
usersGroup.MapGet("/", () => new[] { new User(1, "Alice") });
usersGroup.MapGet("/{id}", (int id) => Results.Ok(new User(id, $"User{id}")));

// 运行应用
app.Run();

// 数据模型
public record User(int Id, string Name);