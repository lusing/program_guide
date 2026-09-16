# 13 · async/await：异步编程的日常形态

> 对应示例：`examples/13_async`

## 1. 为什么需要异步

程序等 IO（网络、磁盘、数据库）时，线程要么干等（同步阻塞——一个请求耗一个线程，线程是贵重资源），要么去干别的（异步）。async/await 让"去干别的"写起来和同步代码一样直白。

两个角色的直觉定义：

- **`Task` / `Task<T>`**："正在进行、将来会有结果的工作凭据"。`Task` 像回调/句柄，`Task<int>` 是"将来会有个 int"。
- **`await`**："等这个凭据兑现；等待期间当前线程回池子去服务别的调用，兑现后从这里继续"。

不需要 await 的时候：C# 5 时代手写的回调嵌套、`ContinueWith` 链都退役了——`await` 之后的世界是把异步代码写得**看起来**同步，但线程从不空转。

## 2. 传染性：async 的方法签名

示例的第一个函数：

```csharp
static async Task<int> WorkAsync(int n)
{
    await Task.Delay(10);
    return n * n;
}
```

- `async` 修饰符 + `Task<int>` 返回：方法内有 await，调用方也必须 await（或自己处理 Task）——异步**沿着调用链向上传染**，这是设计使然：谁调用异步工作，谁就要面对"它没立刻完成"的事实。
- `Task.Delay(10)` 是异步等待 10ms（**不是** `Thread.Sleep`——后者占着线程死等）；示例用它模拟一次 IO。
- 方法体内 `return n * n` 返回 int，签名却是 `Task<int>`——编译器把整个方法改写成状态机，int 被包进完成的 Task。

命名惯例：异步方法以 `Async` 结尾（BCL 的 `ReadAsync/WriteAsync/QueryAsync` 全部如此）。

## 3. 并发：WhenAll

```csharp
var tasks = Enumerable.Range(1, 5).Select(WorkAsync);
var results = await Task.WhenAll(tasks);
Console.WriteLine(string.Join(", ", results));
```

对比两种写法的时耗（每个 WorkAsync 睡 10ms）：

```csharp
// 串行：一个接一个 await——5 × 10ms = 50ms
var list = new List<int>();
foreach (var n in Enumerable.Range(1, 5)) list.Add(await WorkAsync(n));

// 并发：全部启动，一次 await 齐——≈10ms
var results = await Task.WhenAll(tasks);
```

**关键心智**：`WorkAsync(n)` 这个调用本身立即返回 Task（工作已启动）；await 才是等待动作。先 `Select` 把任务全启动、再 `WhenAll` 一起等——5 件事真的在同时飞。WhenAll 返回 `int[]`（结果保序）。

> 常见误区：循环里逐个 `await`（串行慢五倍）通常是无意的——想并发就"先收 Task、后 await"。有依赖的步骤（先登录拿 token 再请求）才该串行。

## 4. 异步流：IAsyncEnumerable

示例的第二段：

```csharp
await foreach (var x in SequenceAsync())
{
    Console.Write($"{x} ");
}
Console.WriteLine();

static async IAsyncEnumerable<int> SequenceAsync()
{
    for (int i = 1; i <= 3; i++)
    {
        await Task.Delay(5);
        yield return i;
    }
}
```

第 08 章的 `yield return`（惰性枚举）+ 本章的异步 = **异步流**：元素一个个异步到达，消费者用 `await foreach` 逐个接。对比"攒齐一个 List<Task> 再等"：异步流是"来一个处理一个"——分页 API、消息订阅、日志流的自然形态。生产一个、消费一个，背压（消费者处理慢）天然被照顾。

## 5. 取消与超时（预告）

健壮的异步要可取消：`CancellationToken` 作为参数流经调用链，取消时 `Task.Delay/ReadAsync` 等抛 `OperationCanceledException`。示例保持简单没有演示，但真实代码签名常见 `WorkAsync(int n, CancellationToken ct)`。超时 = `CancellationTokenSource(TimeSpan.FromSeconds(3))`。

## 6. 坑位清单

1. **`async void`**：不能 await、异常没人接（可能带崩进程）。**只有事件处理器**（第 07 章的 `PriceChanged` 若是异步场景）允许 async void，其余一律 `async Task`。
2. **`.Result` / `.Wait()`**：在异步上下文里同步阻塞等 Task——经典死锁（线程互相等）。要么 await 到底，要么真正需要同步桥接时 `Task.Run(...).GetAwaiter().GetResult()` 且明白自己在做什么。
3. **忘 await**：`WorkAsync(n);` 不接收返回的 Task，异常被静默吞、任务变成 fire-and-forget——编译器给 CS4014 警告，别无视。
4. **循环逐个 await 该并发**（见 §3）：先 `.Select(启动)` 再 `await Task.WhenAll`。
5. **`ConfigureAwait(false)`**：库代码里 await 后不需要回到原始上下文（UI/ASP.NET 同步上下文）时加上它，避免死锁并提速；应用程序顶层代码不用管。教程示例是控制台（无同步上下文），两种写法行为一致。
6. **async 方法里跑 CPU 密集循环**：await 只解决 IO 等待，CPU 满载计算该找第 14 章的并行。
