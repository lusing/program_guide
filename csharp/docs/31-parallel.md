# 31 · 并行编程

> 对应示例：`examples/31_parallel`

> **本章你将学会**：ThreadPool 的角色、Parallel.For/ForEach 数据并行、取消与并行度、PLINQ、并行决策与量测纪律。
> **前置章节**：[29 Task](29-tasks.md)、[30 线程安全](30-thread-safety.md)。

## 1. 并行 vs 异步：先分清两件事

| | 异步（28-29 章） | 并行（本章） |
|---|---|---|
| 解决 | **等待**时的浪费（IO 等待让线程去干别的） | **计算**不够快（多核分摊 CPU 活） |
| 手段 | async/await + Task | Parallel / PLINQ / 多 Task.Run |
| 线程 | 等待期不占线程 | 占满核（CPU 利用率飙升） |

**IO 密集 → 异步；CPU 密集 → 并行**——用错工具（并行跑 IO / 异步等计算）两头皆输。

## 2. 线程从哪来：ThreadPool

```csharp
Console.WriteLine(ThreadPool.ThreadCount);      // 池里现役线程数
ThreadPool.QueueUserWorkItem(_ => ...);          // 最原始的"扔给池"
```

.NET 的一切后台执行（Task.Run、Parallel、定时器回调）都跑在**线程池**上——池自动伸缩（Hill Climbing 算法调线程数）、工作窃取式调度。**别手 new Thread**（不进池、无管理；仅剩"需要前台线程/极长生命周期"的边角场景）。池的两大坑：**同步阻塞**（池线程被 Wait/Result 占住 → 池饥饿，全应用卡顿——又是 28 章军规）与**池爆**（上千任务同时排队——限流见第 7 节）。

## 3. Parallel.For / ForEach：数据并行

```csharp
Parallel.For(0, squares.Length, i => squares[i] = (long)i * i);    // 把循环体分发多核

Parallel.ForEach(items,
    new ParallelOptions { MaxDegreeOfParallelism = 4, CancellationToken = cts.Token },
    item => Process(item));
```

- **下标独立、循环体无共享状态**才安全（示例的 squares[i] = ... 各写各的格子）；要累积结果用 `ThreadLocal<T>` 或各线程局部汇总再合并
- **MaxDegreeOfParallelism**：CPU 密集默认≈核数就最好；**IO 混合场景才需要调高**（瓶颈在网络不在 CPU）
- **CancellationToken** 传入后取消会传播到所有工作线程（抛 OperationCanceledException——29 章协作取消）
- `Parallel.Invoke(act1, act2, act3)`：几个独立动作并发跑

Parallel 是**阻塞调用**（方法返回时全部完成）——天生适合"一段计算"，不适合异步管线（那是 29/30 章的领地）。

## 4. PLINQ：声明式并行

```csharp
var parSum = numbers.AsParallel()
                    .Where(n => n % 2 == 0)
                    .Sum(n => (long)n);
```

一个 `AsParallel()` 把整条 LINQ 链变并行执行——分片 → 各核处理 → 合并。特性速记：

- 结果与串行语义一致（顺序敏感操作会自动加合并步骤）
- `WithDegreeOfParallelism(n)` / `WithCancellation(token)` 调节
- `AsOrdered()` 保序（有代价）；`ForAll(x => ...)` 免合并的最终处理

**小数据量并行反而慢**（分片/合并开销 > 收益）——示例对比了同一查询的串行/并行耗时，百万级元素才见分晓。

## 5. 隐形并行：ForEachAsync（.NET 6+）

异步 + 限流并行的现代合体（很多场景替代手写 SemaphoreSlim）：

```csharp
await foreach (...)                       // 数据源
await Parallel.ForEachAsync(urls, async (url, ct) =>
{
    await FetchAsync(url, ct);            // 体内可 await，默认并发=核数（可调）
}, cancellationToken);
```

**异步工作项 + 控制并发度**——爬虫、批量接口调用的标准姿势。它回答了"既想并行发请求又不想打爆对方"的日常需求。

## 6. 并行决策树

```text
工作是什么性质？
├─ IO 密集 → async/await（28 章）；批量 → WhenAll / ForEachAsync
└─ CPU 密集 → 单次大计算 → Parallel.For / PLINQ
             ├─ 数据独立（各算各的）→ 直接并行 ✓
             └─ 有共享/依赖 → 先改算法（分片局部 + 最终合并），锁是最后手段（30 章）
```

**并行化改写的前提是算法可并行**——强行的结果不是加速而是排队 + 竞态双重礼。

## 7. 量测纪律

1. **先有基线**（Stopwatch/PerfView/dotnet-benchmark）——"感觉慢"不算需求
2. **Amdahl 定律直觉**：串行部分决定并行上限——90% 可并行的工作，4 核最多提速 ~3 倍
3. **并行后量数据**：CPU 利用率、实际耗时、分配量（26 章的观测法）三者都要
4. **小数据别并行**：几千元素以下，调度开销白付

## 常见坑

**循环体共享状态没保护**：Parallel.For 里 `sum += x`——竞态（30 章）；局部累积 + 最后 Sum() 合并。

**并行体里抛异常**：AggregateException 包装所有线程的异常（Parallel）/ 第一个（PLINQ await 时）——29 章两种形态都遇过。

**MaxDegreeOfParallelism 乱调**：CPU 密集设成核数 10 倍——上下文切换狂欢，更慢了；只有 IO 场景才超核。

**PLINQ 里有顺序依赖的操作**：Take/Skip/First 在并行下语义微妙（AsOrdered 找回来但付代价）——语义靠前，性能靠后。

**池饥饿连锁**：Parallel 里同步等 Task.Result——池线程互相等，全应用瘫——28 章军规在并行场景加倍成立。

## 实战建议

- 并行化四步流程：**确认 CPU 瓶颈 → 找出独立单元 → Parallel/PLINQ 改写 → 量测验证**——缺一不可
- 批量异步用 `Parallel.ForEachAsync`（限流内建）；要精细控制用 SemaphoreSlim + WhenAll（29 章组合）
- 服务器场景并行要慎重：请求级并发 × 请求内并行 = 线程爆炸；**服务器内并行只在批量后台作业用**
- 长跑并行任务标配取消（29 章 token 一路传）与进度（IProgress，WPF 教程 21 章）
- 深入：PerfView/dotnet-trace 看 CPU 火焰图定位真正的热点——别凭直觉选优化点

## 自测

1. **异步与并行各解决什么？怎么选？** —— 等待浪费→异步；计算不够快→并行。IO 异步、CPU 并行。
2. **Parallel.For 安全的前提？** —— 下标独立、循环体无共享状态。
3. **PLINQ 什么时候反而慢？** —— 数据量小（分片合并开销 > 收益）。
4. **ForEachAsync 的定位？** —— 异步工作项 + 控制并发度（批量 IO 限流标准姿势）。
5. **Amdahl 定律的直觉？** —— 串行部分封顶并行收益。

---
上一章：[30 线程安全](30-thread-safety.md) ｜ 下一章：[32 文件与 IO](32-files-io.md)
