// 35 · 单元测试：自制迷你框架演示 xUnit 的核心概念
// 真实项目用 xUnit/NUnit/MSTest（dotnet test 驱动）；
// 这里零依赖手写一个测试器，讲清楚 Fact/Theory/Assert 的本质。
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 被测对象：一个税率计算器 =====");
var calc = new TaxCalculator(0.13m);
Console.WriteLine($"  净额 100 + 13% 税 = {calc.Gross(100):F2}");

Console.WriteLine();
Console.WriteLine("===== 迷你测试框架跑起来 =====");
var runner = new TestRunner();
runner.AddFact("净额为正时含税价正确", () =>
{
    var c = new TaxCalculator(0.13m);
    Assert.Equal(113.00m, c.Gross(100m));
});
runner.AddFact("净额为零不收税", () =>
{
    var c = new TaxCalculator(0.13m);
    Assert.Equal(0m, c.Gross(0m));
});
runner.AddFact("负数净额要抛异常", () =>
{
    var c = new TaxCalculator(0.13m);
    Assert.Throws<ArgumentException>(() => c.Gross(-1m));
});
// Theory：同一断言喂多组数据（xUnit 的 [Theory] + [InlineData] 就是这个）
foreach (var (net, rate, expected) in new[]
{
    (100m, 0.13m, 113.00m),
    (200m, 0.00m, 200.00m),
    (80m, 0.25m, 100.00m),
})
{
    runner.AddFact($"多组数据: 净额{net} 税率{rate:P0}", () =>
        Assert.Equal(expected, new TaxCalculator(rate).Gross(net)));
}
// 一个故意失败的用例，看框架怎么报告（真实教程不会写必挂用例，这里演示输出形态）
runner.AddFact("故意失败的演示", () => Assert.Equal(1, 2));

runner.RunAll();

Console.WriteLine();
Console.WriteLine("===== 测试金字塔与命名 =====");
Console.WriteLine("  单元测试（多）：纯逻辑，毫秒级，无 IO——本框架跑的就是这类");
Console.WriteLine("  集成测试（中）：真实文件/数据库/HTTP");
Console.WriteLine("  端到端（少）：模拟用户操作全链路");
Console.WriteLine("  命名：方法名_场景_期望 结果三段式，读名知意");

Console.WriteLine();
Console.WriteLine("===== 真实项目的样子 =====");
Console.WriteLine("  dotnet new xunit 生成测试工程，[Fact]/[Theory]/[InlineData] 与本例概念一一对应");
Console.WriteLine("  dotnet test 一条命令跑全部；断言库 Assert.Equal/Throws/Contains 家族更丰富");
Console.WriteLine("  WPF 教程 11 章的 ViewModel 就是「可单测」设计的现场——第 36 章解释器同款分层");

public sealed class TaxCalculator(decimal rate)
{
    public decimal Rate { get; } = rate;

    public decimal Gross(decimal net)
    {
        if (net < 0) throw new ArgumentException("净额不能为负", nameof(net));
        return net * (1 + Rate);
    }
}

public static class Assert
{
    public static void Equal<T>(T expected, T actual)
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
            throw new TestFailureException($"期望 {expected}，实际 {actual}");
    }

    public static void Throws<TEx>(Action action) where TEx : Exception
    {
        try { action(); }
        catch (TEx) { return; }
        throw new TestFailureException($"期望抛出 {typeof(TEx).Name}，但没有");
    }
}

public sealed class TestFailureException(string message) : Exception(message);

public sealed class TestRunner
{
    private readonly List<(string Name, Action Body)> _tests = new();

    public void AddFact(string name, Action body) => _tests.Add((name, body));

    public void RunAll()
    {
        var passed = 0;
        foreach (var (name, body) in _tests)
        {
            try
            {
                body();
                passed++;
                Console.WriteLine($"  ✔ {name}");
            }
            catch (TestFailureException ex)
            {
                Console.WriteLine($"  ✘ {name} —— {ex.Message}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  💥 {name} —— 意外异常: {ex.GetType().Name}: {ex.Message}");
            }
        }
        Console.WriteLine($"  ---- {_tests.Count} 个用例，{passed} 通过，{_tests.Count - passed} 失败");
    }
}
