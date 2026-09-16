// 10_nullable：可空引用类型（NRT）——编译器帮你盯住 null
string title = "hello";          // 非可空引用类型：承诺不为 null
string? subtitle = null;         // ? 声明"可能为 null"，编译器放松限制

Console.WriteLine(title.Length);
// Console.WriteLine(subtitle.Length);   // CS8602 警告：可能为 null 的解引用
Console.WriteLine(subtitle?.Length ?? -1);                       // 写法 1：?. 配 ??
Console.WriteLine(subtitle is null ? "(空)" : subtitle);         // 写法 2：判空后编译器"流"出非空

int? maybeScore = null;                                  // 可空值类型 int?
Console.WriteLine($"score={maybeScore ?? 0}");

var found = FindUser("alice");
Console.WriteLine(found?.Name ?? "(未找到)");

if (FindUser("bob") is { } bob)                          // 属性模式：非空才进入分支
{
    Console.WriteLine($"bob 的邮箱: {bob.Email ?? "未填写"}");
}

Console.WriteLine(Shout(title)!);                        // ! 断言非空：确信时才用，用错就是 NRE

static User? FindUser(string name) =>
    name == "alice" ? new User("alice", "alice@example.com") : null;

static string? Shout(string? input) => input?.ToUpperInvariant();

record User(string Name, string? Email);
