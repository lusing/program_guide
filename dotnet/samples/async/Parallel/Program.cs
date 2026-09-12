// 并行编程示例
// 文件位置: samples/async/Parallel/Program.cs

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

// Parallel.For 示例
void ParallelForExample()
{
    Console.WriteLine("Parallel.For 示例");
    var numbers = Enumerable.Range(1, 10).ToList();

    Parallel.For(0, numbers.Count, i =>
    {
        Thread.Sleep(100); // 模拟耗时操作
        Console.WriteLine($"处理索引 {i}, 值: {numbers[i]}, 线程: {Environment.CurrentManagedThreadId}");
    });
}

// Parallel.ForEach 示例
void ParallelForEachExample()
{
    Console.WriteLine("\nParallel.ForEach 示例");
    var items = new List<string> { "A", "B", "C", "D", "E" };

    Parallel.ForEach(items, item =>
    {
        Thread.Sleep(100);
        Console.WriteLine($"处理项目: {item}, 线程: {Environment.CurrentManagedThreadId}");
    });
}

// PLINQ 示例
void PlinqExample()
{
    Console.WriteLine("\nPLINQ 示例");
    var numbers = Enumerable.Range(1, 1000000);

    var stopwatch = Stopwatch.StartNew();

    // 并行 LINQ 查询
    var query = numbers.AsParallel()
        .Where(n => n % 2 == 0)
        .Select(n => n * n)
        .Take(10)
        .ToList();

    stopwatch.Stop();
    Console.WriteLine($"并行 LINQ 耗时: {stopwatch.ElapsedMilliseconds}ms");
    Console.WriteLine($"结果: {string.Join(", ", query)}");
}

// 并发集合
void ConcurrentCollectionsExample()
{
    Console.WriteLine("\n并发集合示例");
    var concurrentList = new ConcurrentBag<int>();
    var concurrentQueue = new ConcurrentQueue<int>();
    var concurrentDictionary = new ConcurrentDictionary<string, int>();

    Parallel.For(0, 10, i =>
    {
        concurrentList.Add(i);
        concurrentQueue.Enqueue(i);
        concurrentDictionary.TryAdd($"key{i}", i);
    });

    Console.WriteLine($"ConcurrentBag 计数: {concurrentList.Count}");
    Console.WriteLine($"ConcurrentQueue 计数: {concurrentQueue.Count}");
    Console.WriteLine($"ConcurrentDictionary 计数: {concurrentDictionary.Count}");
}

// Task.WhenAll 示例
async Task WhenAllExample()
{
    Console.WriteLine("\nTask.WhenAll 示例");
    var tasks = Enumerable.Range(1, 5).Select(async i =>
    {
        await Task.Delay(100);
        return i * i;
    });

    var results = await Task.WhenAll(tasks);
    Console.WriteLine($"结果: {string.Join(", ", results)}");
}

// Task.WhenAny 示例
async Task WhenAnyExample()
{
    Console.WriteLine("\nTask.WhenAny 示例");
    var tasks = new[] {
        SlowTask(3000),
        FastTask(500),
        MediumTask(1500)
    };

    var firstCompleted = await Task.WhenAny(tasks);
    Console.WriteLine($"第一个完成的任务");
}

async Task SlowTask(int ms) { await Task.Delay(ms); return "慢"; }
async Task FastTask(int ms) { await Task.Delay(ms); return "快"; }
async Task MediumTask(int ms) { await Task.Delay(ms); return "中"; }

// 并行归约
void ReductionExample()
{
    Console.WriteLine("\n并行归约示例");
    var numbers = Enumerable.Range(1, 100).ToList();

    // 并行求和
    int sum = 0;
    Parallel.ForEach(numbers, () => 0, (n, loopState, local Sum) =>
    {
        return local Sum + n;
    }, local Sum => Interlocked.Add(ref sum, local Sum));

    Console.WriteLine($"并行求和结果: {sum}");
}

// 取消并行操作
void CancelParallelExample()
{
    Console.WriteLine("\n取消并行操作示例");
    var cts = new CancellationTokenSource();

    try
    {
        ParallelOptions options = new() { CancellationToken = cts.Token };

        Parallel.For(0, 1000, options, i =>
        {
            if (i == 50) cts.Cancel(); // 在某处取消
            Thread.Sleep(10);
        });
    }
    catch (OperationCanceledException)
    {
        Console.WriteLine("并行操作被取消");
    }
}

// 运行所有示例
ParallelForExample();
ParallelForEachExample();
PlinqExample();
ConcurrentCollectionsExample();
WhenAllExample().Wait();
WhenAnyExample().Wait();
ReductionExample();
CancelParallelExample();