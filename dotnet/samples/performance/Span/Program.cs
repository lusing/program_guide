// 性能优化示例 - Span
// 文件位置: samples/performance/Span/Program.cs

using System;
using System.Buffers;
using System.Diagnostics;
using System.Runtime.CompilerServices;

// Span 和 ReadOnlySpan
void SpanBasics()
{
    Console.WriteLine("=== Span 基础 ===");

    // 数组作为 Span
    int[] numbers = { 1, 2, 3, 4, 5 };
    Span<int> span = numbers;

    // 访问元素
    Console.WriteLine($"第一个元素: {span[0]}");
    Console.WriteLine($"最后一个元素: {span[^1]}");

    // 子 Span
    Span<int> subSpan = span[1..3];
    Console.WriteLine($"子 Span: [{string.Join(", ", subSpan)}]");

    // 修改 Span
    span[0] = 10;
    Console.WriteLine($"修改后: [{string.Join(", ", span)}]");

    // ReadOnlySpan
    ReadOnlySpan<char> text = "Hello, World!"u8;
    Console.WriteLine($"ReadOnlySpan: {System.Text.UTF8Encoding.UTF8.GetString(text)}");
}

// 性能对比
void SpanVsString()
{
    Console.WriteLine("\n=== Span vs String ===");

    string longString = new string('a', 10000);

    // 传统字符串Substring (分配新字符串)
    var sw1 = Stopwatch.StartNew();
    for (int i = 0; i < 10000; i++)
    {
        string sub = longString.Substring(100, 100);
        _ = sub.Length;
    }
    sw1.Stop();
    Console.WriteLine($"Substring: {sw1.ElapsedMilliseconds}ms");

    // Span Substring (无分配)
    var sw2 = Stopwatch.StartNew();
    ReadOnlySpan<char> span = longString.AsSpan();
    for (int i = 0; i < 10000; i++)
    {
        ReadOnlySpan<char> sub = span[100..110];
        _ = sub.Length;
    }
    sw2.Stop();
    Console.WriteLine($"Span: {sw2.ElapsedMilliseconds}ms");
}

// MemoryPool 示例
void MemoryPoolExample()
{
    Console.WriteLine("\n=== MemoryPool 示例 ===");

    // 获取缓冲区
    var pool = MemoryPool<byte>.Shared;
    var memory = pool.Rent(1024);

    try
    {
        // 使用缓冲区
        memory.Span.Fill(0xFF);
        Console.WriteLine($"缓冲区大小: {memory.Memory.Length}");
    }
    finally
    {
        // 返回缓冲区
        memory.Dispose();
    }
}

// 零分配解析
void ParseWithoutAllocation()
{
    Console.WriteLine("\n=== 零分配解析 ===");

    string data = "10,20,30,40,50";
    ReadOnlySpan<char> span = data.AsSpan();

    // 分割但不分配数组
    var segments = new List<ReadOnlySpan<char>>();
    int start = 0;

    for (int i = 0; i < span.Length; i++)
    {
        if (span[i] == ',')
        {
            segments.Add(span[start..i]);
            start = i + 1;
        }
    }
    segments.Add(span[start..]);

    // 解析数字
    var numbers = new List<int>();
    foreach (var segment in segments)
    {
        numbers.Add(int.Parse(segment));
    }

    Console.WriteLine($"解析的数字: [{string.Join(", ", numbers)}]");
}

// Memory<T> vs Span<T>
void MemoryVsSpan()
{
    Console.WriteLine("\n=== Memory<T> vs Span<T> ===");

    // Span: 栈上，不能跨异步边界，性能更好
    // Memory<T>: 堆上，可以跨异步边界，适用于 I/O

    int[] array = { 1, 2, 3, 4, 5 };

    // Span (栈)
    Span<int> span = stackalloc int[5];
    span.Fill(100);

    // Memory<T> (堆)
    Memory<int> memory = array;
    ReadOnlyMemory<char> readOnlyMemory = "Hello".AsMemory();
}

// Xmlns: 优化转换
void ConversionOptimization()
{
    Console.WriteLine("\n=== 转换优化 ===");

    // 字符串转字节数组 (无分配)
    string text = "Hello";
    var bytes = stackalloc byte[256];
    int written = System.Text.Encoding.UTF8.GetBytes(text.AsSpan(), bytes);
    Console.WriteLine($"转换的字节数: {written}");

    // 字节数组转字符串 (无分配)
    ReadOnlySpan<byte> readOnlyBytes = bytes[..written];
    string result = System.Text.Encoding.UTF8.GetString(readOnlyBytes);
    Console.WriteLine($"结果: {result}");
}

// 自定义 Span 方法
void CustomSpanMethods()
{
    Console.WriteLine("\n=== 自定义 Span 方法 ===");

    ReadOnlySpan<int> numbers = stackalloc int[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

    // 查找
    int index = numbers.IndexOf(5);
    Console.WriteLine($"5 的索引: {index}");

    // 是否包含
    bool contains = numbers.Contains(11);
    Console.WriteLine($"包含 11: {contains}");

    // 范围检查
    bool inRange = numbers.Slice(2, 5).Contains(5);
    Console.WriteLine($"范围 [2..7) 包含 5: {inRange}");
}

// ValueTask 性能
async ValueTask<int> FastCalculation(bool useCache)
{
    if (useCache)
    {
        // 同步返回，不分配 Task
        return 42;
    }

    // 异步操作
    await Task.Delay(10);
    return new Random().Next();
}

async Task Run()
{
    // 运行所有示例
    SpanBasics();
    SpanVsString();
    MemoryPoolExample();
    ParseWithoutAllocation();
    MemoryVsSpan();
    ConversionOptimization();
    CustomSpanMethods();

    // ValueTask 示例
    var sw = Stopwatch.StartNew();
    for (int i = 0; i < 100000; i++)
    {
        await FastCalculation(useCache: true);
    }
    sw.Stop();
    Console.WriteLine($"\nValueTask 100000 次调用: {sw.ElapsedMilliseconds}ms");
}

Run();