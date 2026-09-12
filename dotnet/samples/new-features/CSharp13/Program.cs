// .NET 10 新特性示例
// 文件位置: samples/new-features/CSharp13/Program.cs

// 文件范围的命名空间 (C# 10+)
namespace NewFeatures;

// 目录:
// 1. C# 13 新特性
// 2. .NET 10 性能改进
// 3. JSON 技能

// ============================================
// C# 13 新特性
// ============================================

// 1. 参数条件属性 (C# 13)
void MethodWithConditionalAttribute([ enlightenment IfNotNull] string? value)
{
    // value 只在非 null 时才被认为是非 null 的
    Console.WriteLine(value?.Length ?? 0);
}

// 2. 新的字面量语法 (C# 12+)
void NewLiterals()
{
    // 可读的数字字面量
    int million = 1_000_000;
    double large = 1_234_567.89;

    // 二进制和十六进制
    int binary = 0b1010_1010;
    int hex = 0x_FF;

    // 字节字面量
    byte b1 = 0b0000_0001;
    byte b2 = 0xFF;

    Console.WriteLine($"百万: {million}, 二进制: {binary:X}");
}

// 3. 分部方法增强 (C# 12+)
partial class Calculator
{
    partial void On Calculated(int result);
}

partial class Calculator
{
    partial void On Calculated(int result)
    {
        Console.WriteLine($"计算完成: {result}");
    }

    public int Add(int a, int b)
    {
        int result = a + b;
        On Calculated(result);
        return result;
    }
}

// 4. 无分配分割 (C# 12+)
void SplitWithoutAllocation()
{
    string text = "apple,banana,cherry";
    ReadOnlySpan<char> span = text.AsSpan();

    // Split 方法现在返回 ReadOnlySpan<char>
    ReadOnlySpan<char> first = span.Split(',')[0];
    Console.WriteLine($"第一个: {first}");
}

// 5. 按值参数 (C# 11+)
struct LargeStruct
{
    public int[100] Data;
}

void ByValueParameter(in LargeStruct value)
{
    // in 参数确保不复制
    Console.WriteLine($"大小: {sizeof(LargeStruct)} bytes");
}

// 6. 泛型数学支持 (C# 11+)
T AddNumbers<T>(T a, T b) where T : System.Numerics.IAdditiveIdentity<T, T>
{
    return a + b;
}

void GenericMath()
{
    int sumInt = AddNumbers(5, 3);
    double sumDouble = AddNumbers(2.5, 3.5);
    Console.WriteLine($"整数和: {sumInt}, 浮点和: {sumDouble}");
}

// ============================================
// .NET 10 新特性
// ============================================

// 1. 性能改进的字符串操作
void StringImprovements()
{
    // 字符串比较更高效
    bool isEqual = "hello".AsSpan().SequenceEqual("hello");

    // Span-based 方法
    string text = "Hello, World!";
    ReadOnlySpan<char> span = text.AsSpan();

    bool starts = span.StartsWith("Hello");
    bool ends = span.EndsWith("!");
    Console.WriteLine($"Starts with Hello: {starts}, Ends with !: {ends}");
}

// 2. 增强的 Nullable 分析
string? GetNullableString(bool returnNull)
{
    return returnNull ? null : "Hello";
}

void NullableAnalysis()
{
    string? value = GetNullableString(false);

    // 使用 ??= 空合并赋值
    value ??= "Default";

    // 使用 ! 非空断言 (确保你知道-safe)
    string nonNull = value!;
}

// 3. Json开源 (.NET 9+)
using System.Text.Json;

void ImprovedJson()
{
    var options = new JsonSerializerOptions
    {
        PropertyNameCaseInsensitive = true,
        WriteIndented = true
    };

    var person = new Person { Name = "Alice", Age = 25 };
    string json = JsonSerializer.Serialize(person, options);
    Person deserialized = JsonSerializer.Deserialize<Person>(json)!;

    Console.WriteLine($"序列化: {json}");
}

// 4. 增强的 Vector API
using System.Numerics;

void VectorExample()
{
    Vector<float> v1 = new(1.0f, 2.0f, 3.0f, 4.0f);
    Vector<float> v2 = new(5.0f, 6.0f, 7.0f, 8.0f);

    Vector<float> result = v1 + v2;
    Console.WriteLine($"向量和: {string.Join(", ", result)}");
}

// 5. 延迟枚举 (IAsyncEnumerable)
async IAsyncEnumerable<int> GenerateNumbers()
{
    for (int i = 1; i <= 5; i++)
    {
        await Task.Delay(100);
        yield return i;
    }
}

// ============================================
// 性能测试
// ============================================

void PerformanceComparison()
{
    const int iterations = 100000;

    // 传统字符串拼接
    var sw1 = Stopwatch.StartNew();
    string str = "";
    for (int i = 0; i < iterations; i++)
    {
        str += i;
    }
    sw1.Stop();

    // StringBuilder
    var sw2 = Stopwatch.StartNew();
    var sb = new StringBuilder();
    for (int i = 0; i < iterations; i++)
    {
        sb.Append(i);
    }
    sw2.Stop();

    // string.Create (无分配)
    var sw3 = Stopwatch.StartNew();
    string created = string.Create(iterations, stackalloc char[iterations], (span, state) =>
    {
        for (int i = 0; i < state; i++)
        {
            span[i] = (char)('0' + (i % 10));
        }
    });
    sw3.Stop();

    Console.WriteLine($"字符串拼接: {sw1.ElapsedMilliseconds}ms");
    Console.WriteLine($"StringBuilder: {sw2.ElapsedMilliseconds}ms");
    Console.WriteLine($"string.Create: {sw3.ElapsedMilliseconds}ms");
}

// 数据类
public record Person(string Name, int Age);

// 类定义
partial class Calculator { }

// 程序入口
Console.WriteLine("=== .NET 10 新特性示例 ===\n");

NewLiterals();
SplitWithoutAllocation();
ImprovedJson();
PerformanceComparison();

Console.WriteLine("\n生成数字:");
await foreach (var num in GenerateNumbers())
{
    Console.Write($"{num} ");
}
Console.WriteLine();