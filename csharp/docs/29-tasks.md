# 29 · Task 深度

> 对应示例：`examples/29_tasks`

> **本章你将学会**：Task 的两种来路、WhenAll/WhenAny 组合、任务异常的传播、协作式取消全家桶、TaskCompletionSource 与 ValueTask。
> **前置章节**：[28 async/await](28-async-await.md)。

## 1. Task 的两种来路

```csharp
var compute = Task.Run(() => SumSlow(1, 100));   // ① CPU 活：丢线程池执行
var io = Task.Delay(100);                        // ② IO/定时：不占线程，完成时被激活
```

**Task ≠ 线程**——它是"未来的结果"这个概念的抽象：CPU 任务由线程池算出来，IO 任务由操作系统完成后通知。**IO 场景不要 Task.Run 包一层**（白占线程搬运）——直接用框架的异步 API（28 章）。

Task.Run 的真实用途：**把 CPU 密集工作挪出当前线程**（UI 不卡、服务并行计算）+ 简化"即发即忘"的后台工作。

## 2. 组合子：WhenAll 与 WhenAny

```csharp
var results = await Task.WhenAll(FetchAsync("A", 150), FetchAsync("B", 100), FetchAsync("C", 120));
// 三路并发，取全部结果（数组）；总时长 ≈ 最长的 150ms

var firstDone = await Task.WhenAny(FetchAsync("慢", 200), FetchAsync("快", 60));
// 谁先完成返回谁（返回 Task<Task<T>>，await 后拿先完成者的 Task）
```

| 组合子 | 语义 | 场景 |
|---|---|---|
| `WhenAll` | 全部完成 | 批量并行、聚合结果 |
| `WhenAny` | 任一完成 | 竞速（多源取最快）、超时兜底（与 Task.Delay 竞速） |
| `WhenEach`（.NET 9+） | 逐个完成即产出 | 流式处理并行结果 |

超时的惯用法就是 WhenAny 竞速：

```csharp
var winner = await Task.WhenAny(work, Task.Delay(3000));
if (winner != work) throw new TimeoutException();   // work 还没完
```

## 3. 任务异常：聚合与丢失

```csharp
var faulty = Task.WhenAll(
    Task.Run(() => throw new InvalidOperationException("第一个错")),
    Task.Run(() => throw new ArgumentException("第二个错")));

try { await faulty; }
catch (Exception ex) { /* ex = 第一个异常 */ }

faulty.Exception.InnerExceptions      // 完整列表在这（AggregateException 包装）
```

规则：

- `await` 只抛**第一个**异常；要看全部走 `Task.Exception.InnerExceptions`
- **不 await 的 Task 抛异常 = 异常丢失**（无人观察）——28 章"async 到底"军规的机制面；.NET 的 `UnobservedTaskException` 兜底并不保证触发
- `Task.Wait()`/`.Result` 抛的是 **AggregateException**（又一个别同步等的理由：异常形态都不同）

## 4. 取消：三件套全家桶

```csharp
using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(250));  // 定时自动取消
try
{
    for (var i = 1; ; i++)
    {
        cts.Token.ThrowIfCancellationRequested();    // 检查点①：主动检查
        await Task.Delay(80, cts.Token);             // 检查点②：可中断的等待
        Console.WriteLine($"第 {i} 步");
    }
}
catch (OperationCanceledException) { /* 取消不是失败，单独接 */ }
```

| 角色 | 谁 | 职责 |
|---|---|---|
| `CancellationTokenSource` | 发起方 | 发取消信号（Cancel / 构造传超时） |
| `CancellationToken` | 执行方 | 检查信号（ThrowIfCancellationRequested / 传给可取消 API） |
| `OperationCanceledException` | 协议 | 取消的传播载体 |

**取消是协作式的**：Cancel 只是立旗，任务代码在检查点自觉退出。设计纪律：**长任务的方法签名带 CancellationToken 参数**（默认 `default` 保持兼容）并一路传下去——框架异步 API 全部支持它，链路通了"用户点取消"才能一路传导到最深处。

## 5. TaskCompletionSource：把任何事包装成 Task

回调世界（事件、IO 完成端口、别人的 SDK）→ async/await 世界的翻译器：

```csharp
var promise = new TaskCompletionSource<int>();
_ = Task.Run(async () =>
{
    await Task.Delay(100);           // 模拟"回调式 API 完成了"
    promise.TrySetResult(42);        // 兑现承诺
});
Console.WriteLine(await promise.Task);   // 42
```

**你控制 Task 的完成时机**——SetResult/SetException/SetCanceled 三选一（Try 前缀防重复设置）。真实用例：包装老式 Begin/End API、包装事件（WPF 的 TaskCompletionSource 等 ShowDialog 关闭）、单元测试造"恰好按剧本完成"的假任务（35 章）。

## 6. ValueTask：省一次分配

```csharp
static ValueTask<int> CachedAsync(bool warm)
    => warm ? new(1) : new(Task.Run(() => 1));
// 缓存命中：直接返回结果值，不造 Task 对象（零分配）
// 缓存未命中：退化为 Task
```

`ValueTask<T>` 是"结果或 Task"的联合体——**高频 + 常同步完成**的方法（缓存读取、缓冲区非空检查）用它省分配。代价（纪律）：**只能 await 一次**、不能直接 WhenAll/存字段。默认仍写 Task；分配被证明是瓶颈再换。

## 7. Task 的调试入口

- VS 的"并行堆栈/任务窗口"看活任务与阻塞点
- `task.Status`（Created/WaitingForActivation/Running/RanToCompletion/Faulted/Canceled）
- 异步栈在调试器里"逻辑栈"跨断点显示——状态机的方法名（`<LoadAsync>d__10.MoveNext()`）就是 async 方法的真身

## 常见坑

**WhenAny 后丢异常**：先完成者可能不是最快成功的——败者的异常没人看；竞速场景给败者也接上观察（`_ = loser.ContinueWith(t => _ = t.Exception, ...) ` 或明确丢弃策略）。

**循环里 Task.Run 爆线程池**：一千个任务全排队——用 `SemaphoreSlim` 限并发或分批 WhenAll（31 章并行度）。

**Cancel 后还继续跑**：检查点太少（只在开头查一次）——长循环里多点布控 + 可取消 API 全程传 token。

**把 CancellationToken 藏死**：方法签名不带 token 参数 = 调用方永远没法取消你的长任务——设计期就留门。

**TrySetResult 之外还 SetResult**：重复完成抛异常——并发场景一律 Try 前缀。

## 实战建议

- 批量 IO 的标准姿势：`await Task.WhenAll(ids.Select(FetchAsync))`；要限流加 SemaphoreSlim 滑窗
- 公共异步 API 三件套签名：`Task<T> XxxAsync(参数, CancellationToken ct = default)`
- 超时两选一：cts 构造传 TimeSpan（能传播取消）或 WhenAny 竞速（不动原任务）——前者优先
- 回调式 SDK 私有化：TaskCompletionSource 包一层，团队只见 Task
- 30-31 章是并发纵深（线程安全集合/并行计算）；先把本章组合子用熟，多数"并行需求"到此为止

## 自测

1. **Task.Run 与异步 API 的分工？** —— CPU 活丢线程池；IO 直接用框架异步 API（不 Task.Run 包装）。
2. **WhenAll/WhenAny 各自语义与经典搭配？** —— 全部完成聚合 / 任一完成竞速；WhenAny+Delay=超时。
3. **await 只抛哪个异常？完整列表在哪？** —— 第一个；Task.Exception.InnerExceptions（AggregateException）。
4. **取消为什么是协作式？三件套各干什么？** —— Cancel 只立旗，检查点自觉退出；CTS 发令、Token 检查、OCE 传播。
5. **TaskCompletionSource 解决什么？** —— 把回调/事件式完成机制翻译成可 await 的 Task。

---
上一章：[28 async/await](28-async-await.md) ｜ 下一章：[30 线程安全](30-thread-safety.md)
