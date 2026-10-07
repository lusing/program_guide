# 16 · UI 线程模型：后台任务、Invoke、三种 Timer

> 对应示例：`examples/16_threading`（卡死演示 + 后台数素数 148933 断言 + 三 Timer 对照）

> **本章你将学会**：UI 单线程模型、卡死的机理与 Task.Run、IProgress、Invoke/BeginInvoke、两种 Timer 的分工、async/await。
> **前置章节**：[11 事件](11-events.md)；并发基础见 [csharp 31 章](../../csharp/docs/31-parallel.md) / [dotnet 24 章](../../dotnet/docs/24-sync.md)。

## 1. UI 单线程模型

WinForms 的铁律：**创建控件的线程（UI 线程）才能碰它**。其它线程直接改 `label.Text` → `InvalidOperationException: 线程间操作无效`。

UI 线程同时负责消息循环——**它在忙，整个窗口就冻住**（拖不动、点不响、白屏"未响应"）。16 示例的第一组就是这个反面教材：

```csharp
sleep.Click += (s, e) =>
{
    _state.Text = "  UI 线程睡 2 秒——这期间不处理任何消息（拖不动、点不响）";
    Thread.Sleep(2000);                       // ★ 罪魁：忙等占着 UI 线程
};
```

## 2. 正解一：Task.Run + IProgress + async/await

```csharp
private async Task RunAsync(Button stop)
{
    _cts = new CancellationTokenSource();
    var progress = new Progress<int>(p =>             // ★ Progress<T> 自动转投 UI 线程
    {
        _bar.Value = Math.Min(p, 100);
        _state.Text = $"  进度 {p}%%";                  // (F# 版注意：%% 才是百分号)
    });
    try
    {
        int count = await Task.Run(() => CountPrimes(2_000_000, progress, _cts.Token));
        _state.Text = $"  完成：{count:N0} 个素数{(count == 148933 ? "（与已知值一致 ✔）" : "（不对！）")}";
    }
    catch (OperationCanceledException) { _state.Text = "  已取消"; }
    finally { …恢复按钮… }
}
```

后台侧的三个要点：

```csharp
private static int CountPrimes(int max, IProgress<int> progress, CancellationToken ct)
{
    for (int n = 2; n <= max; n++)
    {
        ct.ThrowIfCancellationRequested();     // ① 响应取消靠主动检查（协作式）
        …
        if (n % (max / 100) == 0)
            progress.Report(n * 100 / max);    // ② 后台线程调用 → Progress 转投 UI 线程
    }
}
```

**await 之后自动回到 UI 线程**（上下文捕获），所以 await 后面直接改控件合法。**148933** 是 2×10⁶ 内素数个数的已知值——[csharp 31 章](../../csharp/docs/31-parallel.md)同款断言思路，算错立刻现形。

## 3. 正解二：Invoke / BeginInvoke

手里只有裸回调（定时器、别的线程的事件）时，手动把活儿转回 UI 线程：

```csharp
_poolTimer = new System.Threading.Timer(_ =>
{
    _poolTicks++;
    // 直接 _threadTimer.Text = ... → 跨线程异常
    _threadTimer.BeginInvoke(() =>
    {
        _threadTimer.Text = $"Threading.Timer：{_poolTicks}（…）";
    });
}, null, 0, 500);
```

| | `Invoke`（同步） | `BeginInvoke`（异步） |
|---|---|---|
| 调用方 | **阻塞等** UI 线程执行完 | 丢下就走 |
| 危险 | UI 线程同时在等你 → **死锁** | 无 |
| 场景 | 需要返回值 | 99% 的场景 |

**实测竞态坑（三语言通杀）**：`Threading.Timer` dueTime=0 可能在窗体句柄创建前开火，`BeginInvoke` 没句柄直接抛异常——**先查 `IsHandleCreated`**：

```csharp
if (!_threadTimer.IsHandleCreated) return;    // 没准备好就跳过这一拍
_threadTimer.BeginInvoke(...);
```

本教程 C++ 版曾表现为"时好时坏"（冒烟 5 次挂 3 次），加了守卫后 5/5 稳定——**启动期竞态的经典样本**。

## 4. 两种 Timer 的分工

| | `System.Windows.Forms.Timer` | `System.Threading.Timer` |
|---|---|---|
| Tick 回调线程 | **UI 线程** | 线程池 |
| 改控件 | 直接改 | 必须 Invoke |
| 精度 | ~几十 ms（消息循环级） | 较高 |
| 场景 | 时钟、轮询 UI、动画 | 后台节拍 |

还有第三个 `System.Timers.Timer`（组件模型，`SynchronizingObject` 属性可指回窗体）——16 示例没演示，知道名字别和前两位混了。**同名冲突**：F#/C++ 里同时开两个命名空间时 `Timer` 要限定（`System.Threading.Timer` / `Forms.Timer`）。

## 5. 三语言差异

**F#**——`Async.StartImmediate` + `AwaitTask`（async 块在 UI 线程启动，let! 后自动回来）：

```fsharp
Async.StartImmediate(async {
    let! count = Async.AwaitTask(Task.Run(fun () -> countPrimes 2000000 progress c.Token))
    … })
```

F# 独有坑：**`try/with` 与 `try/finally` 是两个结构**，不能像 C# 三合一（try-catch-finally）：

```fsharp
try
    try let! count = …
        …
    with :? OperationCanceledException -> …       // 内层管异常
finally
    …                                            // 外层管收尾
```

**C++/CLI 没有 async/await**——最顺的工具是 `BackgroundWorker`（事件驱动、专为无 lambda 的世界准备）：

```cpp
_worker->WorkerReportsProgress = true;            // 能力先开
_worker->WorkerSupportsCancellation = true;
_worker->DoWork += …(跑在线程池：绝不碰控件)
_worker->ProgressChanged += …(自动弹回 UI：更新进度条)
_worker->RunWorkerCompleted += …(弹回 UI：无论正常/取消/异常都从这扇门出来)
_worker->RunWorkerAsync(2000000);
```

DoWork 里检查 `worker->CancellationPending` 并 `e->Cancel = true`；结果从 `e->Result` 取。C# 里它是"被 async/await 淘汰的前辈"，在 C++/CLI 里刚好返聘。

## 坑位清单

1. 后台线程直接改控件属性 → InvalidOperationException（跨线程操作无效）。
2. `Invoke` 死锁：后台 `Invoke` 等 UI，UI 在等后台手里的锁——无返回值就 `BeginInvoke`。
3. `Threading.Timer` dueTime=0 的启动竞态 → BeginInvoke 前查 `IsHandleCreated`（本教程实测修过的坑）。
4. F# `try…with…finally` 三合一 → 解析报错；套两层。
5. 两个 `Timer` 类名冲突 → 限定；C++ 里 `Threading::Timer` 的 `Dispose()` 是显式接口实现，用 `delete` 调。

## 自测

1. 为什么 `Thread.Sleep(2000)` 在按钮处理器里会冻住整个窗口？
2. `Progress<T>` 与裸 `BeginInvoke` 各适合什么场景？
3. await 之后为什么能直接改控件？
4. 取消是"立即生效"吗？靠什么机制？
5. C++/CLI 没有 await，它的正统替代是谁？三个事件分别跑在哪个线程？

---

上一章：[15 DataGridView](15-datagridview.md) · 下一章：[17 文件 IO 与加密](17-io-crypto.md)
