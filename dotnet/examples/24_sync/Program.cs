using System.Collections.Concurrent;
using System.IO;
using System.IO.Pipes;
using System.Text;

// ---------- SemaphoreSlim：并发限流（限 2，放 6 个任务过） ----------
using var gate = new SemaphoreSlim(initialCount: 2, maxCount: 2);
int running = 0, peak = 0;
var tasks = Enumerable.Range(1, 6).Select(async _ =>
{
    await gate.WaitAsync();
    try
    {
        int now = Interlocked.Increment(ref running);
        peak = Math.Max(peak, now);
        await Task.Delay(50);        // 模拟被限流的 IO
    }
    finally
    {
        _ = Interlocked.Decrement(ref running);
        gate.Release();
    }
}).ToArray();
await Task.WhenAll(tasks);
Console.WriteLine($"semaphore: peak={peak} (limit 2)");

// ---------- AutoResetEvent：生产者-消费者乒乓 3 个来回 ----------
using var ping = new AutoResetEvent(false);
using var pong = new AutoResetEvent(false);
long hits = 0;
bool stop = false;                   // 顶层语句的局部变量被 lambda 捕获（见第 07 章闭包）
var consumer = Task.Run(() =>
{
    while (true)
    {
        ping.WaitOne();              // 阻塞等待，不占 CPU
        if (Volatile.Read(ref stop)) break;
        _ = Interlocked.Increment(ref hits);
        pong.Set();
    }
});
for (int i = 0; i < 3; i++)
{
    ping.Set();
    pong.WaitOne();
}
Volatile.Write(ref stop, true);
ping.Set();                          // 唤醒消费者让它退出
await consumer;
Console.WriteLine($"autoreset: rounds={Interlocked.Read(ref hits)}");

// ---------- 匿名管道：同进程内双向字节通道（父子进程版同理） ----------
using var pipeOut = new AnonymousPipeServerStream(PipeDirection.Out, HandleInheritability.None);
using var pipeIn = new AnonymousPipeClientStream(PipeDirection.In, pipeOut.ClientSafePipeHandle);
var writer = Task.Run(async () =>
{
    await pipeOut.WriteAsync(Encoding.UTF8.GetBytes("pipe-msg"));
    pipeOut.Close();                 // 关写端，读端随后收到 EOF
});
var buf = new byte[64];
using var ms = new MemoryStream();
int n;
while ((n = await pipeIn.ReadAsync(buf)) > 0)
{
    ms.Write(buf, 0, n);
}
await writer;
Console.WriteLine($"pipe: {Encoding.UTF8.GetString(ms.ToArray())}");

// ---------- FileSystemWatcher：事件只收集，业务在别处做 ----------
var dir = Path.Combine(Path.GetTempPath(), "dotnet-fsw-demo");
Directory.CreateDirectory(dir);
using var watcher = new FileSystemWatcher(dir)
{
    NotifyFilter = NotifyFilters.FileName | NotifyFilters.LastWrite,
    EnableRaisingEvents = true,
};
var seen = new ConcurrentQueue<string>();
watcher.Created += (_, e) => seen.Enqueue($"created:{e.Name}");
watcher.Renamed += (_, e) => seen.Enqueue($"renamed:{e.Name}");

var aPath = Path.Combine(dir, "a.txt");
File.WriteAllText(aPath, "hello");
File.Move(aPath, Path.Combine(dir, "b.txt"));   // 事件里搬文件会再触发事件（重入坑）

var deadline = DateTime.UtcNow.AddSeconds(5);   // 事件在线程池送达，稍等
while (seen.Count < 2 && DateTime.UtcNow < deadline)
{
    await Task.Delay(50);
}
Console.WriteLine($"fsw: {string.Join(", ", seen.OrderBy(x => x))}");
