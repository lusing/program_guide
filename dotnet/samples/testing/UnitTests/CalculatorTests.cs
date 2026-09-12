// Unit Tests 示例
// 文件位置: samples/testing/UnitTests/CalculatorTests.cs

using Xunit;
using FluentAssertions;

// 被测试的类
public class Calculator
{
    public int Add(int a, int b) => a + b;
    public int Subtract(int a, int b) => a - b;
    public int Multiply(int a, int b) => a * b;
    public double Divide(double a, double b)
    {
        if (b == 0) throw new DivideByZeroException();
        return a / b;
    }
    public int Max(int a, int b) => a > b ? a : b;
}

public class CalculatorTests
{
    private readonly Calculator _calculator = new();

    // 基本测试
    [Fact]
    public void Add_PositiveNumbers_ReturnsSum()
    {
        // Arrange
        int a = 5, b = 3;

        // Act
        int result = _calculator.Add(a, b);

        // Assert
        Assert.Equal(8, result);
    }

    //Theory 测试
    [Theory]
    [InlineData(1, 2, 3)]
    [InlineData(-1, 1, 0)]
    [InlineData(0, 0, 0)]
    public void Add_Inputs_ReturnsSum(int a, int b, int expected)
    {
        Assert.Equal(expected, _calculator.Add(a, b));
    }

    // 测试异常
    [Fact]
    public void Divide_WithZero_ThrowsException()
    {
        Assert.Throws<DivideByZeroException>(() => _calculator.Divide(10, 0));
    }

    // 测试异常 (使用 Assert.ThrowsAsync)
    [Fact]
    public async Task DivideAsync_WithZero_ThrowsException()
    {
        await Assert.ThrowsAsync<DivideByZeroException>(() => _calculator.DivideAsync(10, 0));
    }
}

// 扩展: 异步方法
public class AsyncCalculator
{
    public async Task<int> AddAsync(int a, int b)
    {
        await Task.Delay(10);
        return a + b;
    }

    public async Task<double> DivideAsync(double a, double b)
    {
        await Task.Delay(10);
        if (b == 0) throw new DivideByZeroException();
        return a / b;
    }
}

// 测试异步方法
public class AsyncCalculatorTests
{
    private readonly AsyncCalculator _calculator = new();

    [Fact]
    public async Task AddAsync_ShouldReturnSum()
    {
        int result = await _calculator.AddAsync(5, 3);
        Assert.Equal(8, result);
    }

    [Fact]
    public async Task AddAsync_ShouldNotBeZero()
    {
        int result = await _calculator.AddAsync(5, 3);
        result.Should().NotBe(0);
    }
}

// Mock 测试示例 (使用 Moq)
public interface ILogger
{
    void Log(string message);
    bool IsEnabled(string level);
}

public class ServiceWithLogger
{
    private readonly ILogger _logger;

    public ServiceWithLogger(ILogger logger)
    {
        _logger = logger;
    }

    public string DoWork()
    {
        if (_logger.IsEnabled("Info"))
        {
            _logger.Log("工作开始");
        }
        return "完成";
    }
}

public class ServiceTests
{
    [Fact]
    public void DoWork_ShouldLog_WhenEnabled()
    {
        // Arrange
        var mockLogger = new Mock<ILogger>();
        mockLogger.Setup(l => l.IsEnabled("Info")).Returns(true);
        var service = new ServiceWithLogger(mockLogger.Object);

        // Act
        var result = service.DoWork();

        // Assert
        Assert.Equal("完成", result);
        mockLogger.Verify(l => l.Log("工作开始"), Times.Once);
    }
}

// 测试工具类
public static class TestExtensions
{
    public static void ShouldBe(this int actual, int expected)
    {
        Assert.Equal(expected, actual);
    }
}