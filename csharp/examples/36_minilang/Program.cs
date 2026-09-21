// 36 · 综合实战：MiniLang——一个能跑的表达式解释器
// 管线：源码 →[Lexer 记号流]→[Parser AST]→[Evaluator 结果]
// 用到的全书知识：枚举/记录(11)/模式匹配(19)/LINQ(16)/异常(22)/字典(12)
using MiniLang;

Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== MiniLang 演示脚本 =====");
var demo = new[]
{
    "let width = 3",
    "let height = 4",
    "let area = width * height",
    "area",                          // 裸表达式：求值并打印
    "let pi = 3.14159",
    "pi * (width + height) / 2",
    "-area + 10",
    "width == 3",
    "width >= height",
    "let unitPrice = 25.5",
    "let total = area * unitPrice",
    "total",
    "width = 10",                    // 重新赋值
    "area * 2",                      // 注意：area 不会自动跟着变——变量存值不存公式
};

var ev = new Evaluator();
foreach (var line in demo)
{
    var result = Run(ev, line);
    Console.WriteLine($"  > {line,-28} = {result:G7}");
}

Console.WriteLine();
Console.WriteLine("===== 错误处理：三种典型错误 =====");
foreach (var bad in new[] { "let x = 1 / 0", "let x = nosuch + 1", "let width = 5" })
{
    try
    {
        var fresh = new Evaluator();
        _ = fresh.Execute(new Parser(bad).ParseStatement());
    }
    catch (MiniLangException ex)
    {
        Console.WriteLine($"  > {bad,-16} ✘ {ex.Message}");
    }
}

Console.WriteLine();
Console.WriteLine("===== 变量表（Evaluator 的状态）=====");
foreach (var (name, value) in ev.Variables)
    Console.WriteLine($"  {name} = {value:G7}");

Console.WriteLine();
Console.WriteLine("===== 交互模式 =====");
Console.WriteLine("  命令行传 --repl 进入逐行交互（exit 退出）；本演示模式保证输出可自动验证");
if (args.Contains("--repl"))
{
    Console.WriteLine("MiniLang REPL——输入表达式或 let 语句，exit 退出：");
    var interactive = new Evaluator();
    while (true)
    {
        Console.Write("» ");
        var line = Console.ReadLine();
        if (line is null || line.Trim() == "exit") break;
        if (line.Trim().Length == 0) continue;
        try { Console.WriteLine(Run(interactive, line)); }
        catch (MiniLangException ex) { Console.WriteLine($"  ✘ {ex.Message}"); }
    }
}

static double Run(Evaluator ev, string line)
{
    try
    {
        return ev.Execute(new Parser(line).ParseStatement());
    }
    catch (MiniLangException ex)
    {
        Console.WriteLine($"  > {line,-28} ✘ {ex.Message}");
        return double.NaN;
    }
}
