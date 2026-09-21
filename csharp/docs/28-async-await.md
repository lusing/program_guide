# 28 · async/await

> 对应示例：`examples/28_async`

> **本章你将学会**：await 的挂起语义、编译器状态机、顺序与并行的时序、async 签名纪律、异步流。
> **前置章节**：[13 委托](13-delegates.md)、[18 迭代器](18-iterators.md)。

## 1. 异步解决什么问题

两种"慢"：**CPU 忙不过来**（计算）与**在等外部**（磁盘/网络/定时器）。后者占绝对多数——同步等待时线程干躺着占资源（GUI 线程等 = 界面冻结，WPF 教程 21 章的主角）。

```csharp
// 同步：占着线程 300ms
Thread.Sleep(300);

// 异步：挂起让路，完成后再继续
await Task.Delay(300);
```

**await 的语义：挂起当前方法、归还线程、完成后从断点续跑**——不是"等着不动"。线程被释放去干别的（UI 继续响应、服务器去处理别的请求），效率的天壤之别就在这。

## 2. await 的本质：编译器拆段

```csharp
async Task F()
{
    A();
    await Slow();
    B();
}
```

编译器把方法改写成**状态机**（示例用对照图展示）：

- `await` 处是"断点"：先返回（Task 给调用方），方法体暂停
- 被等待的 Task 完成后，**续体（B 及之后）被调度回来执行**
- 方法里的局部变量被搬进状态机对象——所以能"暂停后还记得"

和迭代器（18 章）的 yield 状态机是同胞兄弟：**yield 在"取下一个"处断开，await 在"等完成"处断开**——理解一个另一个就通了。

## 3. 上下文捕获：await 后回到哪

```csharp
await Task.Delay(300);
UpdateUI();        // UI 程序里：这行回到 UI 线程执行！
```

- **GUI 程序**（WPF/WinForms）：SynchronizationContext 存在，await 后**自动回到 UI 线程**——所以 await 后直接改控件是安全的（WPF 教程 21 章的核心）
- **控制台/ASP.NET Core**：无 UI 上下文，续体在线程池任意线程——示例打印了前后线程号可能不同
- **`ConfigureAwait(false)`**：不捕获上下文，续体在完成处继续——**库代码标配**（避免死锁 + 提性能），UI 代码禁用（回不去 UI 线程就崩）

## 4. 顺序 await vs 并行启动（高频错误）

```csharp
// 串行：600ms
await Task.Delay(200);
await Task.Delay(200);
await Task.Delay(200);

// 并行：200ms
var t1 = Task.Delay(200);        // 先启动（任务已在计时）
var t2 = Task.Delay(200);
var t3 = Task.Delay(200);
await Task.WhenAll(t1, t2, t3);  // 再一起等
```

**先启动再等**还是**边等边启动**——独立 IO 的吞吐差距是 N 倍。心智：`await X(); await Y();` 是"做完 X 再做 Y"；要并行就"任务都捏在手里，最后 WhenAll"。第 29 章的 WhenAll/WhenAny 是组合子的完整版。

## 5. async 的签名纪律

```csharp
// ✓ public API：返回 Task / Task<T>
public async Task<int> LoadAsync() { ... }

// ✘ async void：异常没人接（直接崩进程）；不能等待
public async void Load() { ... }
```

| 形态 | 用途 |
|---|---|
| `Task` / `Task<T>` | 99% 的场景（异步方法返回值） |
| `ValueTask<T>` | 高频且常同步完成（29 章） |
| `async void` | **仅事件处理器**（框架契约要求 void 签名） |
| `IAsyncEnumerable<T>` | 异步流（第 6 节） |

配套纪律：**async 方法内部必须自我消化异常**（29 章任务异常）+ **方法名以 Async 结尾**（约定）+ **不要 async 无 await**（编译器警告——白造状态机）。

## 6. 异步流：await foreach

迭代器（18 章）+ 异步的合体——**异步生产、逐个消费**：

```csharp
static async IAsyncEnumerable<int> ProduceAsync()
{
    for (var i = 1; i <= 3; i++)
    {
        await Task.Delay(50);        // 模拟网络/文件分页拉取
        yield return i * 10;         // await + yield 同框
    }
}

await foreach (var item in ProduceAsync())
    Console.WriteLine(item);
```

场景：分页 API 逐页吐、大文件逐行流式读（第 32 章的 ReadLinesAsync 家族）、消息流消费。`IAsyncEnumerable` 是拉模型（消费一个取一个）的异步版——背压天然存在。

## 7. 三条心智军规

1. **一 async 到底**：异步的传染性是真的——底层异步，调用链上层都该异步；中途 `.Result`/`.Wait()` 同步等 = 死锁风险（UI/有上下文场景必死）+ 白白阻塞
2. **async 不等于多线程**：`await Task.Delay` 全程没开线程（定时器激活续体）；要 CPU 并行得 Task.Run（29 章）
3. **异常在 Task 里**：async 方法抛的异常存在返回的 Task 中——不 await/不接住就"丢失"（29 章专题）

## 常见坑

**`.Result` / `.Wait()` 死锁**：UI/有 SynchronizationContext 的环境同步等异步 = 续体等 UI 线程、UI 线程被你占着——死锁。示例的控制台演示用了 `.Result` 并注明"UI 禁止"。

**async void 吞异常**：没有 Task 装异常 → 未处理异常直接崩。除事件处理器外一律 Task。

**忘了 await（CS4014 警告）**：`LoadAsync();` 后面没 await——任务在后台裸奔，异常丢失、顺序失控。警告必须处理。

**循环里 await 串行**：独立请求 `foreach (var u in urls) await Fetch(u);` 是串行——改 Task.WhenAll(urls.Select(Fetch))（29 章）。

**库代码忘了 ConfigureAwait(false)**：库被 UI 程序调用时上下文来回跳——库的每个 await 都 false（约定俗成）。

## 实战建议

- 命名后缀 Async 一致到底；接口/实现/虚方法签名统一 Task 返回
- IO 场景优先**框架内置异步 API**（File.ReadAllBytesAsync、HttpClient.GetAsync）——它们才是真异步；自己 Task.Run 包同步代码只是"换个线程阻塞"
- UI 层学 WPF 教程 21 章的完整模式（命令 → `_ = RunAsync()` → 内部 try/catch + IsBusy 防重入）
- 学习工具：给每个 await 前后打线程号日志（示例的做法）——"回到哪了"亲眼确认一次胜过读十篇
- 第 29 章 Task 组合/取消、30-31 章并发——async 是入口不是全部

## 自测

1. **await 与 Thread.Sleep 的本质区别？** —— 挂起让路（方法断点续跑）vs 占线程死等。
2. **编译器对 async 方法做了什么？** —— 改写成状态机：局部变量装箱入状态机、await 处断点、完成后续体调度。
3. **GUI 程序 await 后为什么能直接改 UI？库代码为什么要 ConfigureAwait(false)？** —— SynchronizationContext 自动回 UI 线程；库无 UI 需求，false 省切换且防死锁。
4. **"先启动再等"与顺序 await 的区别？** —— 并行（总时长=最慢）vs 串行（总时长=总和）。

---
上一章：[27 unsafe 与互操作](27-unsafe-interop.md) ｜ 下一章：[29 Task 深度](29-tasks.md)
