using System.Text.RegularExpressions;

// 1. 命名组提取：一行访问日志拆出字段
var lines = new[]
{
    "10.8.0.12 [2026-09-26 08:01:02] \"GET /api/users\"",
    "192.168.1.7 [2026-09-26 08:01:05] \"POST /api/orders\"",
};

foreach (var line in lines)
{
    var m = Patterns.LogPattern().Match(line);
    if (m.Success)
    {
        Console.WriteLine($"{m.Groups["ip"].Value,-15} {m.Groups["method"].Value,-4} {m.Groups["path"].Value}");
    }
}

// 2. MatchEvaluator 替换：邮箱打码（普通 Replace 动态拼接不了首字母）
var text = "联系 alice@example.com 或 bob@test.org";
var masked = Regex.Replace(
    text,
    @"(?<user>\w+)@(?<domain>\w+\.\w+)",
    m => $"{m.Groups["user"].Value[0]}***@{m.Groups["domain"].Value}");
Console.WriteLine(masked);

// 3. 超时防御：灾难性回溯在 100ms 处被拦下
try
{
    var evil = new Regex(@"^(a+)+$", RegexOptions.None, TimeSpan.FromMilliseconds(100));
    evil.IsMatch(new string('a', 40) + "!");
    Console.WriteLine("evil-pattern: matched (unexpected)");
}
catch (RegexMatchTimeoutException)
{
    Console.WriteLine("evil-pattern: timeout caught");
}

// 源生成器版本：编译期生成实现，启动零解析开销、AOT 友好
static partial class Patterns
{
    [GeneratedRegex(@"(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) \[(?<time>[^\]]+)\] ""(?<method>GET|POST) (?<path>[^""]+)""")]
    public static partial Regex LogPattern();
}
