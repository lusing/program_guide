# 14 · 并行：数据并行与共享状态

> 对应示例：`examples/14_parallel`

## 1. 并发 vs 并行：先分家

两个常被混用的词，对应两章：

- **并发（第 13 章 async）**：大量等待 IO 的任务交错推进——线程在等待时被释放，重点是不阻塞。
- **并行（本章）**：把 CPU 密集的计算切给多个核**同时**执行——重点是吃满硬件。

判据很硬：任务是"等外部"用 async，是"自己算"用并行。两者会组合（并行下载 + 每个下载内异步），但工具箱不同。

## 2. Parallel.ForEach：数据并行

示例全文：

```csharp
using System.Collections.Concurrent;
using System.Threading;

var nums = Enumerable.Range(1, 1000).ToArray();
var dict = new ConcurrentDictionary<int, int>();
int total = 0;

Parallel.ForEach(nums, n =>
{
    var sq = n * n;
    dict[n] = sq;
    Interlocked.Add(ref total, n);
});

Console.WriteLine($"count={dict.Count}, total={total}");
```

`Parallel.ForEach(数据, 体)`：把数据分块派给线程池（自动按核数与负载调度），全部完成后返回。它是 `foreach` 的并行版，两个语义差异要记住：**体的执行顺序不再确定**；**体内部的代码必须线程安全**——后者正是示例里两个主角（ConcurrentDictionary、Interlocked）存在的原因。

近亲 PLINQ：`nums.AsParallel().Select(n => n * n)` 用 LINQ 语法做同一件事（第 09 章的算子换并行实现）；要结果序列用 PLINQ，要副作用遍历用 Parallel.ForEach。

## 3. 共享状态：`total++` 为什么会丢更新

直觉上 `total += n` 是一步，实际是三步：读 total → 加 n → 写回 total。两个线程同时读到 100，各自加完写回 103——**本该 106，丢了 3**。这叫**竞态**（race condition）：结果取决于线程交错的运气，1000 次并发累加能稳定丢几十次。

示例的解法：

```csharp
Interlocked.Add(ref total, n);
```

`Interlocked` 家族（`Add/Increment/Decrement/Exchange/CompareExchange`）映射到 CPU 的**原子指令**——三步并成一步硬件完成，任何线程看到的都是完整结果。单变量场景它是首选：不需要锁、开销极小。

## 4. ConcurrentDictionary：线程安全的容器

```csharp
dict[n] = sq;    // 多线程同时写，不丢不坏
```

普通 `Dictionary` 在并发写下行为未定义（数据损坏、死循环都见过）。`System.Collections.Concurrent` 命名空间给容器做了并发安全实现：

| 类型 | 用途 |
|---|---|
| `ConcurrentDictionary<K,V>` | 并发读写字典；`GetOrAdd/TryUpdate` 原子组合操作 |
| `ConcurrentQueue<T>` / `ConcurrentStack<T>` | 生产者-消费者队列/栈 |
| `ConcurrentBag<T>` | 无序、可重复的高吞吐集合 |
| `Channel<T>`（System.Threading.Channels） | 现代的异步管道，配合第 13 章 |

对比传统手段 `lock (obj) { … }`：锁是通用但粗粒度的互斥（拿到才能进），Concurrent 系列用细粒度/无锁技巧换吞吐。判据：**保护单变量 → Interlocked；保护容器 → Concurrent 系列；保护多变量组成的不变量（转账：A 减 B 必须同时成）→ lock**。

## 5. 什么时候值得并行

启动多线程有线程调度与同步开销。并行收益 = 核数 × 单元耗时 − 调度与同步成本：单元只有几微秒时，一百万个交给 Parallel.ForEach 反而变慢（分块开销吞掉收益）——先保证单元够粗（例如按文件、按请求切，而不是按字符切）。规模存疑时量一下（Stopwatch 或 BenchmarkDotNet）再说。

## 6. 坑位清单

1. **闭包捕获共享变量**：`Parallel.ForEach(nums, n => total += n);` 就是 §3 的丢更新现场——编译通过、多数时候结果还"差不多对"，是最阴险的 bug 形态。
2. **`for` 循环变量捕获**（第 07 章坑位的并行版）：`for (int i…)` 里 lambda 捕获 i 再并行执行，看到的是最终值；`foreach` 迭代变量（C# 5 起）每轮是新变量、安全。
3. **Parallel.ForEach 里抛异常**：不是单个异常而是 `AggregateException`（各线程的异常打包）——catch 时取 `ex.InnerExceptions` 逐个看。
4. **lambda 里 await**：`Parallel.ForEach` 的重载不认 async lambda——异步工作回去用第 13 章的 `Task.WhenAll`。
5. **把 lock 当万能药**：锁住大段代码把并行退化成串行，还引入死锁风险；能缩小临界区就缩小，能用 Interlocked/Concurrent 替代就替代。
6. **并行度调优**：默认按核数就是最优起点；手动 `new ParallelOptions { MaxDegreeOfParallelism = N }` 只在 IO 混合负载（DB 连接数限制等）才有意义。
