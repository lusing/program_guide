# 30 · 线程安全

> 对应示例：`examples/30_threadsafe`

> **本章你将学会**：竞态条件的机理、Interlocked/lock 的用法与纪律、ConcurrentDictionary、Channel 生产者消费者、死锁的预防。
> **前置章节**：[29 Task](29-tasks.md)、[12 泛型集合](12-generics.md)。

## 1. 竞态：读改写的缝

两个线程同时 `counter++`，一个 `++` 实际是**读→加→写**三步——线程 A 读到 100 还没写回，线程 B 也读到 100，各自 +1 写回 101：**丢了一次**。示例实测：

```csharp
var counter = 0;
Parallel.For(0, 100_000, _ => counter++);
Console.WriteLine(counter);     // < 100000（每次跑结果还不同——竞态的不确定性特征）
```

**竞态三特征**：结果错、每次错得不一样、小规模压测常常发现不了。根源都是"共享可变状态 + 并发访问"——所有线程安全手段都在拆这个组合。

## 2. Interlocked：单变量原子操作

```csharp
counter = 0;
Parallel.For(0, 100_000, _ => Interlocked.Increment(ref counter));
// 100000 ✓
```

`Interlocked.Increment/Decrement/Add/Exchange/CompareExchange`——**硬件级原子指令**（单条 CPU 指令完成读改写）。**单个数值的并发更新，Interlocked 永远优先于 lock**（快一个数量级）。

## 3. lock：互斥的钥匙

```csharp
private readonly object _gate = new();
Parallel.For(0, 1_000, i =>
{
    lock (_gate)                 // 同一时刻仅一个线程进入
    {
        list.Add(i);             // List<int> 本身不线程安全
    }
});
```

`lock` = Monitor.Enter/Exit 的语法糖。四条铁律：

1. **锁对象私有**（`private readonly object`）——别 lock(this)/lock(typeof(T))/lock(string)：外部也能 lock 你的对象 = 死锁盲区
2. **锁粒度最小**——块内只放必须互斥的代码；IO/await 一律出锁
3. **绝不在锁内 await**——锁释放的时机和续体回来的线程都对不上（编译器直接报错）
4. **锁对象与被保护的数据结对**——一个锁管一组数据；多锁管同一数据 = 保护了个寂寞

需要"锁 + 等待"的复合场景用 `SemaphoreSlim`（可异步 await 的信号量，29 章限流用它）。

## 4. ConcurrentDictionary：免锁并发字典

```csharp
var stats = new ConcurrentDictionary<string, int>();
Parallel.For(0, 10_000, i => stats.AddOrUpdate("hits", 1, (_, v) => v + 1));
// hits = 10000 ✓
```

`AddOrUpdate(key, 加键时的初始值, 更新函数)`——"存在则更新、不存在则插入"是**一个原子操作**。这是它与"先 ContainsKey 再写"（两步之间有缝）的本质区别。家族速查：`GetOrAdd`（缓存的标准写法）、`TryGetValue/TryRemove`。Concurrent 家族还有 `ConcurrentQueue/Stack/Bag`——**队列用 ConcurrentQueue 或下一节的 Channel，别用 List+lock 硬拼**。

读多写少要超高并发时还有 `ImmutableDictionary`（不可变结构 + 交换引用）——函数式路线。

## 5. Channel：生产者-消费者的现代答案

```csharp
var channel = System.Threading.Channels.Channel.CreateBounded<string>(4);
var producer = Task.Run(async () =>
{
    foreach (var msg in new[] { "任务A", "任务B", "任务C", "完成" })
    {
        await channel.Writer.WriteAsync(msg);     // 满了就等（背压！）
        Console.WriteLine($"[生产] {msg}");
    }
});
var consumer = Task.Run(async () =>
{
    await foreach (var msg in channel.Reader.ReadAllAsync())
    {
        Console.WriteLine($"[消费] {msg}");
        if (msg == "完成") break;
    }
});
await Task.WhenAll(producer, consumer);
```

Channel = **线程安全的异步队列**：生产快过消费时 WriteAsync 自动等待（背压内建）、消费侧 ReadAllAsync 异步拉取。对比老 BlockingCollection（线程阻塞式等待——占线程）：Channel 全异步零浪费。**流水线任务（下载→解析→入库）的现代骨架**：每段一个 Task，中间接 Channel。

## 6. 死锁：互相等待的天荒地老

```text
线程1: lock(A) → 等 B
线程2: lock(B) → 等 A          ← 各持一把、互欠一把：永久卡死
```

四条预防（按性价比排序）：

1. **减少锁数量**——一把锁管全部（小临界区时反而最快）
2. **全局锁序**——必须多锁时约定按固定顺序获取（如按对象 Id 排序后加锁）
3. **超时探测**——`Monitor.TryEnter(obj, TimeSpan)` 拿不到就放弃/重试，不死等
4. **锁内不做"可能等待"的事**（IO/事件/调外部）——嵌套等待是死锁温床

诊断：调试器暂停看两个线程的栈（都在 lock 上等对方）一目了然。

## 7. 线程安全的分层决策

```text
能不改共享数据吗？           → 改设计（局部变量/每次新建）——最优解
单数值原子更新？             → Interlocked
简单互斥？                   → lock（私有对象 + 最小块）
并发字典/队列？               → ConcurrentDictionary / ConcurrentQueue
生产者-消费者流水线？          → Channel
读多写少不可变？              → Immutable 系 + 引用交换
```

**顺序从上往下问**——并发正确性的成本阶梯，越往上越便宜。

## 常见坑

**"测试没复现"当"没问题"**：竞态是概率性的——并行压测（加大循环数/核数）+ 工具（dotnet-racetrack、Concurrency Checker 思路）才是证据。

**锁内 await / 锁内调事件回调**：回调里的未知代码可能再拿别的锁——嵌套等待；把事件触发挪出锁外。

**多个变量一个锁漏保护**：A、B 一起更新才一致，却只锁了 A——一致性边界 = 锁的边界。

**用 ConcurrentDictionary 但更新逻辑非原子**：`d[key] = d[key] + 1`（读和写两步）在 Concurrent 字典上照样竞态——用 AddOrUpdate。

**Channel 没人收、有界容量爆**：WriteAsync 永久等待——设计好完成信号（示例的"完成"哨兵消息）与消费者生命周期。

## 实战建议

- 第一原则：**能用不可变/局部化解决的，别上锁**——12 章 record、25 章 GC 的短命对象哲学在这里兑现
- 每把锁写注释："保护谁、和谁配对"——半年后没人记得住
- 后台流水线直接 Channel 起步（bounded + 合理容量）；需要"每项独立处理"再看 Parallel（31 章）
- 测试并发代码：压测脚本进 CI（偶发失败也能抓到），并记录种子/配置复现
- 深入阅读：官方线程安全文档 + 《C# in Depth》并发章节；本仓库 WPF 教程 21 章是 UI 线程视角的同一主题

## 自测

1. **竞态的三特征与根源？** —— 结果错、不确定性、难复现；共享可变状态 + 并发。
2. **lock 的四条铁律？** —— 私有对象、最小粒度、锁内禁 await、锁与数据结对。
3. **AddOrUpdate 原子在哪？对比 ContainsKey+写？** —— 检查与更新一条龙；两步之间有缝。
4. **Channel 相比阻塞队列的优势？** —— 异步等待（不占线程）+ 内建背压（Bounded）。
5. **死锁四预防？** —— 减锁、全局锁序、TryEnter 超时、锁内不等待。

---
上一章：[29 Task 深度](29-tasks.md) ｜ 下一章：[31 并行编程](31-parallel.md)
