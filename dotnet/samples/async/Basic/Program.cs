// 异步编程示例 - 基础
// 文件位置: samples/async/Basic/Program.cs

using System;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

// async/await 基础
async Task MainAsync()
{
    Console.WriteLine("开始 Async/Await 示例");

    // 启动异步操作
    var task1 = DelayAsync(1000);
    var task2 = DelayAsync(2000);

    // 等待所有任务完成
    await Task.WhenAll(task1, task2);

    Console.WriteLine("所有任务完成");
}

async Task DelayAsync(int milliseconds)
{
    await Task.Delay(milliseconds);
    Console.WriteLine($"{DateTime.Now:HH:mm:ss} - 延迟 {milliseconds}ms 完成");
}

// 异常处理
async Task HandleExceptionsAsync()
{
    try
    {
        await FailAsync();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"捕获异常: {ex.Message}");
    }
}

async Task FailAsync()
{
    await Task.Delay(100);
    throw new InvalidOperationException("操作失败!");
}

// 并发请求 (使用 HttpClient)
async Task FetchDataAsync()
{
    using var client = new HttpClient();

    var urls = new[] {
        "https://jsonplaceholder.typicode.com/todos/1",
        "https://jsonplaceholder.typicode.com/todos/2",
        "https://jsonplaceholder.typicode.com/todos/3"
    };

    // 并发请求
    var tasks = urls.Select(url => client.GetStringAsync(url));
    var results = await Task.WhenAll(tasks);

    foreach (var result in results)
    {
        Console.WriteLine($"收到响应: {result.Substring(0, Math.Min(50, result.Length))}...");
    }
}

// 取消令牌
async Task WithCancellationAsync()
{
    var cts = new CancellationTokenSource();
    cts.CancelAfter(2000);

    try
    {
        await LongOperationAsync(cts.Token);
    }
    catch (OperationCanceledException)
    {
        Console.WriteLine("操作被取消");
    }
}

async Task LongOperationAsync(CancellationToken token)
{
    await Task.Delay(5000, token); // 5秒操作
    Console.WriteLine("操作完成");
}

// 异步流 (C# 8+)
async IAsyncEnumerable<int> GenerateNumbersAsync()
{
    for (int i = 1; i <= 5; i++)
    {
        await Task.Delay(100);
        yield return i;
    }
}

// ValueTask 示例 (避免分配 Task)
async ValueTask<int> GetCachedResultAsync()
{
    // 模拟缓存检查
    return 42;
}

// 测试所有方法
await MainAsync();
await HandleExceptionsAsync();
await FetchDataAsync();
await WithCancellationAsync();

Console.WriteLine("\n异步流:");
await foreach (var number in GenerateNumbersAsync())
{
    Console.WriteLine($"数字: {number}");
}