var calc = new Calculator();

AssertEx.Equal(8, calc.Add(5, 3), "Add");
AssertEx.Equal(2, calc.Subtract(5, 3), "Subtract");
AssertEx.Equal(15, calc.Multiply(5, 3), "Multiply");
AssertEx.True(Math.Abs(calc.Divide(10, 2) - 5.0) < 0.0001, "Divide");
AssertEx.Throws<DivideByZeroException>(() => calc.Divide(10, 0), "Divide by zero");

var asyncCalc = new AsyncCalculator();
var sum = await asyncCalc.AddAsync(4, 6);
AssertEx.Equal(10, sum, "AddAsync");

var logger = new FakeLogger(enabled: true);
var svc = new ServiceWithLogger(logger);
var result = svc.DoWork();
AssertEx.Equal("完成", result, "Service result");
AssertEx.True(logger.Messages.Count == 1, "Service log called");

Console.WriteLine("All mapped test-style checks passed.");

sealed class Calculator
{
    public int Add(int a, int b) => a + b;
    public int Subtract(int a, int b) => a - b;
    public int Multiply(int a, int b) => a * b;

    public double Divide(double a, double b)
    {
        if (b == 0) throw new DivideByZeroException();
        return a / b;
    }
}

sealed class AsyncCalculator
{
    public async Task<int> AddAsync(int a, int b)
    {
        await Task.Delay(5);
        return a + b;
    }
}

interface ILogger
{
    bool IsEnabled(string level);
    void Log(string message);
}

sealed class FakeLogger(bool enabled) : ILogger
{
    public List<string> Messages { get; } = [];
    public bool IsEnabled(string level) => enabled && level == "Info";
    public void Log(string message) => Messages.Add(message);
}

sealed class ServiceWithLogger(ILogger logger)
{
    public string DoWork()
    {
        if (logger.IsEnabled("Info")) logger.Log("工作开始");
        return "完成";
    }
}

static class AssertEx
{
    public static void Equal<T>(T expected, T actual, string name)
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
        {
            throw new InvalidOperationException($"{name}: expected={expected}, actual={actual}");
        }
    }

    public static void True(bool condition, string name)
    {
        if (!condition) throw new InvalidOperationException($"{name}: condition failed");
    }

    public static void Throws<TException>(Action action, string name) where TException : Exception
    {
        try
        {
            action();
        }
        catch (TException)
        {
            return;
        }
        throw new InvalidOperationException($"{name}: expected exception {typeof(TException).Name}");
    }
}

