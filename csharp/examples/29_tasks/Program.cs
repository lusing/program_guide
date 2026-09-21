// 29 · Task 深度：组合、异常、取消与"信源"
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== Task 的两种来路 =====");
static int SumSlow(int from, int to)
{
    var s = 0;
    for (var i = from; i <= to; i++) s += i;
    return s;
}
var compute = Task.Run(() => SumSlow(1, 100));        // CPU 活：丢线程池
var io = Task.Delay(100);                             // IO 活：不占线程，定时器到期激活
Console.WriteLine($"  Task.Run 结果: {compute.Result:N0}（控制台演示用 .Result，UI 禁止）");
await io;

Console.WriteLine();
Console.WriteLine("===== 组合子：WhenAll / WhenAny =====");
static async Task<string> FetchAsync(string name, int delay)
{
    await Task.Delay(delay);
    return name;
}
var sw = System.Diagnostics.Stopwatch.StartNew();
var results = await Task.WhenAll(
    FetchAsync("A", 150),
    FetchAsync("B", 100),
    FetchAsync("C", 120));
Console.WriteLine($"  WhenAll 三路并发: [{string.Join(",", results)}] 用时 {sw.ElapsedMilliseconds}ms（最长路决定）");

var firstDone = await Task.WhenAny(FetchAsync("慢", 200), FetchAsync("快", 60));
Console.WriteLine($"  WhenAny 最先完成: {firstDone.Result}   ← 竞速场景：多源取最快");

Console.WriteLine();
Console.WriteLine("===== 任务里的异常：聚合后一次抛 =====");
var faulty = Task.WhenAll(
    Task.Run(() => throw new InvalidOperationException("第一个错")),
    Task.Run(() => throw new ArgumentException("第二个错")));
try { await faulty; }
catch (Exception ex)
{
    Console.WriteLine($"  await 只看到第一个: {ex.Message}");
    Console.WriteLine($"  完整列表在 Task.Exception.InnerExceptions: {faulty.Exception?.InnerExceptions.Count} 个");
}

Console.WriteLine();
Console.WriteLine("===== 取消：三件套完整版 =====");
using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(250));   // 250ms 后自动取消
try
{
    for (var i = 1; ; i++)
    {
        cts.Token.ThrowIfCancellationRequested();    // 协作检查点
        await Task.Delay(80, cts.Token);             // 可中断的等待
        Console.WriteLine($"  第 {i} 步完成");
    }
}
catch (OperationCanceledException)
{
    Console.WriteLine("  被取消（超时触发）——取消不是失败，单独接");
}

Console.WriteLine();
Console.WriteLine("===== TaskCompletionSource：把「任何事」包装成 Task =====");
var promise = new TaskCompletionSource<int>();
_ = Task.Run(async () =>
{
    await Task.Delay(100);               // 模拟：回调式 API / 事件 / IO 完成端口
    promise.TrySetResult(42);            // 事情完成 → 兑现 promise
});
Console.WriteLine($"  await promise → {await promise.Task}   ← 回调世界与 async/await 世界的翻译器");

Console.WriteLine();
Console.WriteLine("===== ValueTask：省一次分配 =====");
static ValueTask<int> CachedAsync(bool warm)
    => warm ? new(1) : new(Task.Run(() => 1));        // 热路径直接给结果，不造 Task
_ = await CachedAsync(true);
Console.WriteLine("  常同步完成的高频方法用 ValueTask<T>；代价：只能 await 一次，别再 WhenAll 它");
