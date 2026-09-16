var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var users = new List<User>
{
    new(1, "Alice"),
    new(2, "Bob"),
    new(3, "Charlie")
};

app.MapGet("/api/users", () => Results.Ok(users));

app.MapGet("/api/users/{id:int}", (int id) =>
{
    var user = users.FirstOrDefault(u => u.Id == id);
    return user is null ? Results.NotFound() : Results.Ok(user);
});

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

if (args.Contains("--run", StringComparer.OrdinalIgnoreCase))
{
    app.Run();
}
else
{
    Console.WriteLine("Minimal API 示例已编译；使用 --run 启动。");
}

record User(int Id, string Name);
record UserCreate(string Name);

