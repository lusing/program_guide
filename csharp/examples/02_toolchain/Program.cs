// 02 · 工具链：同一份程序的三种入口写法 + csproj 逐行解读
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 入口的三种写法（同一程序的等价形态）=====");

// 形态一：顶层语句（本文件用的就是它）——编译器把它搬进自动生成的 Main
// 形态二：经典 Main（Program.Main）——下面用普通调用演示
// 形态三：带 Main 的完整类（见文末 ClassicEntry 类，仅供参考对比）

Console.WriteLine("[形态一] 顶层语句：文件里的语句就是程序入口，从上到下执行");
Console.WriteLine("[形态二] 经典 Main 的效果：");
ClassicEntry.MainWithArgs(Array.Empty<string>());

Console.WriteLine();
Console.WriteLine("===== 命令行参数 =====");
var args2 = new[] { "--demo", "值" };
Console.WriteLine($"模拟收到 {args2.Length} 个参数: {string.Join(" | ", args2)}");
Console.WriteLine("（真实运行时 dotnet run -- a b 会把 a b 传给程序）");

Console.WriteLine();
Console.WriteLine("===== csproj 逐行解读（见 02_toolchain/ToolchainConsole.csproj）=====");
foreach (var line in new[]
{
    "Sdk=\"Microsoft.NET.Sdk\"        → 使用标准 .NET 工程模板（自动包含 **/*.cs）",
    "OutputType=Exe                   → 控制台程序（dll 是库）",
    "TargetFramework=net10.0          → 目标框架：决定可用 API 与语言版本",
    "ImplicitUsings=enable            → 常用命名空间（System/System.IO/System.Linq…）自动 using",
    "Nullable=enable                  → 可空引用类型检查（第 21 章专题）",
})
{
    Console.WriteLine("  " + line);
}

Console.WriteLine();
Console.WriteLine("===== 常用命令 =====");
Console.WriteLine("  dotnet build      编译（产物进 bin/Debug/net10.0）");
Console.WriteLine("  dotnet run        编译 + 运行（-- 后面是程序参数）");
Console.WriteLine("  dotnet publish    发布（WPF 教程 24 章全展开）");

internal static class ClassicEntry
{
    // 形态二的真身：显式 Main。一个程序只能有一个入口。
    internal static void MainWithArgs(string[] args)
    {
        Console.WriteLine($"  [形态二] static void Main(string[] args) 被调用，参数 {args.Length} 个");
    }
}
