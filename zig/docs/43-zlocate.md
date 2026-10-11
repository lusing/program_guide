# 43 · 实战：并发文件索引器 zlocate

> **阅读位置**：第六篇 · 综合实战（8/10） ｜ **承前**：并发线 [19](19-threads.md)→[31](31-concurrency.md)→[39](39-asyncio.md)、[27 遍历](27-tree.md)、[12 集合](12-collections.md) ｜ **启后**：[44 嵌入式](44-embedded.md) 把 volatile/无锁落到硬件侧。
>
> 对应示例：`examples/43_zlocate/main.zig`（547 行，4 个测试）
>
> 取材 Tsoukalos ch8（zlocate：并发文件索引器），升级到 0.17。ch8 的完整
> zlocate 是一个四文件项目（indexer/database/search/main，带持久化和 glob
> 搜索），本章把它的**并发内核**抽出来讲透：WorkQueue（泛型工作队列 +
> 条件变量）、3 个 worker 线程并行 BFS 目录树、结果收集排序、生产者-消费者
> 最小 demo、无锁环形缓冲设计。
>
> 本章有 **5 条实测结论会推翻你可能听过的说法**：
>
> 1. **「并发就是加锁」——错。** 锁只保护**共享可变状态**（`items`、`active`、
>    `result.files`），而 worker 的**主体工作**（打开目录、迭代条目、拼路径）
>    完全无锁。43.3 的 `crawlWorker` 里，锁的占比不到 20%。计数器连锁都不用——
>    `std.atomic.Value(u64).fetchAdd` 就够（43.3）。
> 2. **「工人线程提前退出没关系」——错，这是并行 BFS 的头号 bug。**
>    只看"队列为空"就退出，worker 会在另一个 worker 刚发现新子目录、还没
>    push 的瞬间误判"做完了"——丢一整棵子树。正确的不变量是
>    **`active == 0` 且队列为空**（43.2，这是本章的核心教学点）。
> 3. **「条件变量 wait 用 if 就行」——错。** 虚假唤醒（spurious wakeup）
>    是条件变量 API 的**正式语义**，不是实现瑕疵。`wait` 必须放在 `while`
>    循环里重查条件（43.2）。`std.Io.Condition` 的文档明确允许虚假唤醒。
> 4. **`std.Thread.WaitGroup` / `Pool` / `RwLock` / `Semaphore` / `ResetEvent`
>    在 0.17 全部不存在**。31 章用 `@hasDecl` 逐个实测为 `false`。
>    替代品在 `std.Io` 下（`Mutex` / `Condition` / `RwLock` / `Event`），
>    且方法首参是 `io: std.Io`（43.2、43.7）。
> 5. **`init.io` 可以跨线程共享**。`std.Io` 是值类型，底层是 Threaded 的
>    OS futex——31 章实测通过。worker 线程直接用主线程传下来的 `io`，
>    不需要每线程一个实例（43.3）。test 块里要用
>    `std.Io.Threaded = .init_single_threaded` 自建独立实例——
>    `std.testing.io` 的 `Condition` 会死锁（31.11 的教训）。
>
> **节号对应**：43.1–43.7 是示例 `main` 里的运行时小节（`begin("43.N …") …
> end("43.N")`，运行输出里能看到 `==== 43.N … 开始 ====`）；**43.8（坑位清单）
> 与 43.9（验证方式）不在 `main` 里**——43.7 在 `main` 末尾有同名小节，
> 但文档的 43.8 是它的展开版。
>
> **确定性纪律**（沿用 31 章 / 34 章）：标记区间里只印**确定性指标**
> （计数、路径列表、布尔判定），不印裸耗时/吞吐。43.3 的爬取结果
> （1 个文件 0 个目录）由示例目录的真实内容决定——本章选了一个只有
> `main.zig` 的目录，所以输出逐字节可复现。
>
> **前置章节**：[19 并发](19-threads.md)（线程基础：spawn/join、Mutex、
> Condition）、[27 目录遍历](27-tree.md)（`openDir`/`iterate`、
> `entry.name` 失效陷阱）、[31 并发进阶](31-concurrency.md)
> （0.17 的 `std.Io` 并发 API、原子操作、无锁数据结构）。
> 本章不复读那些基础，只讲 Scatter-Gather 模式下新出现的东西。

---

## 43.0 导读：这一章要推翻 3 个说法

**说法一：「并发就是加锁」。**

如果并发等于加锁，那并发程序的正确性就等于"锁没漏"——这会把注意力引向
完全错误的方向。本章的 `crawlWorker`（43.3）里，打开目录、迭代条目、
拼路径、判断文件类型——这些占了代码量 80% 的**主体工作**全部无锁运行。
锁只出现在三处：`WorkQueue` 的 `items`/`active`（push/pop/finish）、
`result.files` 的追加、以及 nowhere else。计数器用 `std.atomic.Value`
连锁都省了。写并发程序的**第一步不是"哪里加锁"，而是"哪些状态是共享的"**——
把共享面压到最小，锁自然就少了。

**说法二：「工人线程提前退出没关系，大不了少几个结果」。**

在 Scatter-Gather 里，worker 提前退出不是"少几个结果"的问题，是
**丢一整棵子树**的问题。场景：worker A 正在爬 `/src`，发现子目录
`/src/deep`，还没来得及 push；worker B 的队列已经空了，一看"没活了"
就退出——`/src/deep` 里的所有文件永远进不了索引。更糟的是 B 退出后
A 爬完 `/src` 也退出了，因为队列又空了——但 `/src/deep` 还在 A 的
本地变量里没推出去。正确的不变量：**只有当 `active == 0` 且队列为空时，
worker 才能返回 null**（"真的做完了"）。`active` 是"已推入但未完成"的
工作项计数，push 时 +1、finish 时 -1。43.2 用整节讲这一个概念。

**说法三：「条件变量 wait 用 if 就行」。**

教科书伪代码里条件变量的经典写法是 `if (!cond) wait()`——**这是错的**。
POSIX 明确允许虚假唤醒：线程可能在条件根本没满足的情况下从 `wait` 返回
（实现层面是为了效率，避免在信号路径里做过多检查）。正确写法永远是
`while (!cond) wait()`——醒来再查，不满足接着睡。43.2 的 `pop()` 就是
标准示范。

---

## 43.1 Scatter-Gather 理论

### 43.1.1 模式定义

Scatter-Gather 是并行编程的**架构模式**，三步：

1. **Scatter（分发）**：协调者（主线程）把大任务拆成小工作项，推入队列。
2. **并行处理**：worker 线程各自从队列取工作项、独立处理。
3. **Gather（收集）**：全部 worker 完成后，主线程汇总结果。

对文件索引器来说：工作项是**目录路径**，处理是"打开目录、列出条目、
把子目录推回队列（scatter 的递归形式）、把文件加入结果列表"，
收集是"合并所有 worker 产出的路径列表"。

### 43.1.2 为什么 Scatter-Gather 适合目录遍历

目录遍历有一个天然的**不规则性**：不同目录的条目数差几个数量级
（空目录 0 条，`node_modules` 几万条）。如果用"静态切分"——事先把
目录树分成 K 份、每线程一份——会出现严重的负载不均：某个 worker 分到
`node_modules` 就累死，分到 10 个空目录的就闲死。

Scatter-Gather 用**动态调度**解决这个问题：队列是共享的，谁先空谁取下一个，
处理快的 worker 自然多做。唯一的共享面是队列本身——一个 mutex 就够。

### 43.1.3 运行时输出

```zig
// examples/43_zlocate/main.zig 第 45-63 行
fn sectionTheory(io: std.Io, w: *std.Io.Writer) !void {
    _ = io;
    begin("43.1 Scatter-Gather 理论");

    try w.print("Scatter-Gather 三步：\n", .{});
    try w.print("  ① Scatter：主线程把任务切片分发给 worker\n", .{});
    try w.print("  ② 并行处理：每个 worker 独立消费自己的那份\n", .{});
    try w.print("  ③ Gather：主线程回收全部结果，合并输出\n", .{});
    try w.print("\n", .{});
    try w.print("单线程 vs 多线程（处理 N 个目录）：\n", .{});
    try w.print("  单线程：T_total = N × t_each（顺序累加）\n", .{});
    try w.print("  多线程：T_total ≈ (N / K) × t_each + overhead（K 个 worker）\n", .{});
    try w.print("  加速比上限 = K（Amdahl：受串行部分限制）\n", .{});
    try w.print("\n", .{});
    try w.print("关键不变量：worker 不能提前退出 —— 必须等所有任务做完。\n", .{});
    try w.print("  判定条件：active == 0 且队列为空（43.2 详解）\n", .{});
```

运行输出：

```text
==== 43.1 Scatter-Gather 理论 开始 ====
Scatter-Gather 三步：
  ① Scatter：主线程把任务切片分发给 worker
  ② 并行处理：每个 worker 独立消费自己的那份
  ③ Gather：主线程回收全部结果，合并输出

单线程 vs 多线程（处理 N 个目录）：
  单线程：T_total = N × t_each（顺序累加）
  多线程：T_total ≈ (N / K) × t_each + overhead（K 个 worker）
  加速比上限 = K（Amdahl：受串行部分限制）

关键不变量：worker 不能提前退出 —— 必须等所有任务做完。
  判定条件：active == 0 且队列为空（43.2 详解）
==== 43.1 Scatter-Gather 理论 结束 ====
```

第 46 行的 `_ = io;`：本节是纯打印，不用 `io`，但函数签名统一带 `io`
参数（其它小节要用）。Zig 要求未使用的参数显式丢弃。

---

## 43.2 WorkQueue：终止不变量

这是本章的**核心教学节**。WorkQueue 是整个 Scatter-Gather 的同步心脏——
它决定"任务怎么分"和"什么时候算做完"。

### 43.2.1 为什么不用 channel

Go 的并发模型是 "不要通过共享内存来通信"——目录爬取在 Go 里会写成
`chan string` + `range`。Zig 没有内置 channel（0.17 的 `std.Io.Channel`
不存在），而且即使存在，channel 也不适合这个场景：

1. **channel 的 close 语义不够表达"做完"**。`close(ch)` 表示"不会再发了"，
   但 worker 还需要等**已发出的全部处理完**。Go 的做法是再加一个
   `sync.WaitGroup`——两个原语配合。WorkQueue 把"队列 + 完成计数"
   合在一个结构里，用 `active` 一个变量表达"已推入但未完成"。
2. **WorkQueue 的 `active` 就是隐式的 WaitGroup**。push 时 +1 相当于
   `wg.add(1)`，finish 时 -1 相当于 `wg.done()`，pop 返回 null 的
   条件（active==0 且空）相当于 `wg.wait()` 的完成检测——但全部在
   一个 mutex 保护下，不需要第二个同步原语。
3. **0.17 没有 `std.Thread.WaitGroup`**（31 章 `@hasDecl` 实测为 false）。
   就算想用 WaitGroup 也得自己复刻——那不如直接设计一个更贴合需求的
   结构。

### 43.2.2 WorkQueue 结构

```zig
// examples/43_zlocate/main.zig 第 71-84 行
/// 泛型工作队列：并行 BFS 的核心同步结构。
/// 不变量（来自《Systems Programming with Zig》ch8）：
///   pop() 仅在 active == 0 且 items 为空时返回 null；
///   finish() 递减 active 并 broadcast 唤醒所有等待的 worker。
fn WorkQueue(comptime T: type) type {
    return struct {
        mutex: std.Io.Mutex = .init,
        cond: std.Io.Condition = .init,
        items: std.ArrayList(T) = .empty,
        active: usize = 0,
        allocator: std.mem.Allocator,
        io: std.Io,

        const Self = @This();

        fn init(allocator: std.mem.Allocator, io: std.Io) Self {
            return .{ .allocator = allocator, .io = io };
        }
```

逐行讲：

- **第 71 行**：`fn WorkQueue(comptime T: type) type`——返回类型的函数，
  14 章讲过的泛型模式。`WorkQueue([]const u8)` 是目录路径队列，
  `WorkQueue(u32)` 是整数队列（43.5 用）。同一个实现两种用途。
- **第 73 行**：`std.Io.Mutex = .init`——0.17 的 Mutex **没有 `init()` 函数**，
  默认值就是 `.init`。31 章讲过：`std.Thread.Mutex` 不存在，
  `std.Io.Mutex` 存在且方法首参是 `io`。
- **第 74 行**：`std.Io.Condition = .init`——同上，条件变量也在 `std.Io` 下。
- **第 75 行**：`std.ArrayList(T) = .empty`——0.17 的 `ArrayList` 默认
  值是 `.empty`（不是 `init()`），追加时按需分配。`items` 是工作项的
  实际存储。
- **第 76 行**：`active: usize = 0`——**已推入但未完成的工作项计数**。
  这是整个 WorkQueue 的灵魂。push 时 +1，finish 时 -1。
  `active > 0` 意味着"还有工作在进行中，可能马上有新工作项进队列"。
- **第 77-78 行**：allocator 和 io 存进结构体，方法里直接用。

### 43.2.3 push：推入工作项

```zig
// examples/43_zlocate/main.zig 第 91-97 行
/// 主线程调用：推入一个工作项，递增 active，唤醒一个等待的 worker。
fn push(self: *Self, item: T) !void {
    self.mutex.lockUncancelable(self.io);
    defer self.mutex.unlock(self.io);
    try self.items.append(self.allocator, item);
    self.active += 1;
    self.cond.signal(self.io);
}
```

逐行讲：

- **第 92 行**：`lockUncancelable(io)`——0.17 的 Mutex 有两个加锁方法：
  `lock(io)` 返回 `!void`（可能被取消）和 `lockUncancelable(io)` 返回
  `void`（不可取消）。本章用后者：WorkQueue 的临界区极短（append +
  递增 + signal），没有理由允许取消。
- **第 93 行**：`defer unlock(io)`——解锁注册在 defer 里，任何路径退出
  都会解锁。19 章的基本原则。
- **第 94 行**：`items.append(allocator, item)`——追加工作项。可能
  分配内存（ArrayList 扩容），所以 `push` 返回 `!void`。
- **第 95 行**：`self.active += 1`——**关键**：push 时 active 加 1。
  这个计数表示"有一个工作项被推入但还没人 finish 它"。
- **第 96 行**：`cond.signal(io)`——唤醒**一个**等待的 worker。
  `signal` 而不是 `broadcast` 的理由：一个 push 只让一个工作项可用，
  唤醒一个 worker 刚好消费它；broadcast 会吵醒所有睡眠者，它们
  抢一个工作项，没抢到的又睡回去——惊群效应。

### 43.2.4 pop：取出工作项（THE 核心）

```zig
// examples/43_zlocate/main.zig 第 109-118 行
/// Worker 调用：取出一个工作项（FIFO —— 从队首取）。
/// 返回 null 仅当 active == 0 且 items 为空 —— 这是终止不变量。
fn pop(self: *Self) ?T {
    self.mutex.lockUncancelable(self.io);
    defer self.mutex.unlock(self.io);
    // 必须是 while 不是 if：虚假唤醒是条件变量的正式语义
    while (self.items.items.len == 0) {
        if (self.active == 0) return null; // 真的做完了
        self.cond.waitUncancelable(self.io, &self.mutex);
    }
    return self.items.orderedRemove(0); // FIFO：从队首取
}
```

逐行讲：

- **第 112 行**：`while (self.items.items.len == 0)`——**必须是 while，
  不是 if**。这是导读说法三的正面回答：条件变量允许虚假唤醒，wait 返回后
  必须**重新检查**条件。用 `if` 的话，虚假唤醒会直接走到第 117 行，
  对一个空队列调 `orderedRemove(0)`——越界 panic（Debug 下）或
  未定义行为（Release 下）。
- **第 113 行**：`if (self.active == 0) return null`——**终止不变量**。
  队列为空**且**没有活跃工作项时，才返回 null（"真的做完了"）。
  注意检查顺序：先看队列空不空（外层 while），再看 active 是否为 0。
  如果队列不空，根本走不到这里——直接取工作项。
- **第 114 行**：`waitUncancelable(io, &self.mutex)`——睡眠等待。
  语义：**原子地释放 mutex 并挂起线程**；被唤醒后**重新获得 mutex**
  再返回。所以醒来时 mutex 是持有的，循环条件检查是线程安全的。
  传 `&self.mutex` 是因为条件变量需要操作关联的锁。
- **第 117 行**：`orderedRemove(0)`——从队首取，**FIFO**。
  `orderedRemove` 保持剩余元素的顺序（O(n) 移动），`swapRemove` 是
  O(1) 但乱序。工作项是目录路径，顺序影响 BFS 的遍历次序但不影响
  正确性——FIFO 让遍历次序更可预测，调试时输出更稳定。

### 43.2.5 finish：完成工作项

```zig
// examples/43_zlocate/main.zig 第 121-127 行
/// Worker 调用：完成一个工作项，递减 active，broadcast 通知可能等待的 worker。
fn finish(self: *Self) void {
    self.mutex.lockUncancelable(self.io);
    defer self.mutex.unlock(self.io);
    std.debug.assert(self.active > 0);
    self.active -= 1;
    if (self.active == 0) self.cond.broadcast(self.io);
}
```

逐行讲：

- **第 124 行**：`std.debug.assert(self.active > 0)`——finish 的前提是
  有活跃的未完成工作项。如果 active 已经是 0 还调 finish，说明调用方
  的 push/finish 配对错乱了——assert 在 Debug 下立刻 panic，把逻辑
  错误暴露在开发期。
- **第 125 行**：`self.active -= 1`——递减活跃计数。
- **第 126 行**：`if (self.active == 0) broadcast`——**当活跃计数归零时，
  广播唤醒所有等待的 worker**。为什么这里用 broadcast 而不是 signal：
  可能有**多个** worker 在 `pop` 里睡眠（队列空、active > 0），
  现在 active 归零了，**所有**睡眠者都需要醒来检查终止条件并返回 null。
  如果只 signal 一个，其它睡眠者永远不醒——程序挂死。

### 43.2.6 终止不变量：完整推演

这是本章最重要的一个概念，用完整的时间线推演一遍。

**不变量**：`pop()` 返回 `null` 当且仅当 `active == 0` 且 `items` 为空。

**场景**：3 个 worker（W1/W2/W3）爬取目录树，根目录 `/` 下有 `/a` 和 `/b`。

```
时刻  T0: main push("/")     → items=["/"],  active=1
      T1: W1 pop() → "/"    → items=[],     active=1（pop 不减 active）
      T1: W2 pop()          → items=[], active=1>0 → wait 睡眠
      T1: W3 pop()          → items=[], active=1>0 → wait 睡眠
      T2: W1 爬 "/" 发现 "/a" → push("/a") → items=["/a"], active=2
           signal → W2 醒来，pop() → "/a" → items=[], active=2
      T3: W1 发现 "/b"      → push("/b") → items=["/b"], active=3
           signal → W3 醒来，pop() → "/b" → items=[], active=3
      T4: W1 finish("/")    → active=2
      T5: W2 爬完 "/a"（无子目录）finish → active=1
      T6: W3 爬完 "/b"（无子目录）finish → active=0 → broadcast！
      T7: W1/W2/W3 都在 pop 里 wait（队列空、active 曾 >0）
           broadcast 唤醒全部 → 重查：队列空 且 active==0 → return null
      T8: 三个 worker 全部退出循环
```

**如果只看"队列为空"**：在 T2 时刻，W2 醒来前队列是空的——如果 W2 的
pop 在 T2 之前检查队列（比如 W1 的 push 还没完成），W2 看到"空队列"
就返回 null 退出。但 W1 正在爬 `/`，马上会 push `/a`——W2 的提前退出
意味着少了一个 worker 处理 `/a`，如果 W3 也犯了同样的错误，
`/a` 和 `/b` 就只有 W1 一个人爬（慢），或者更糟：W1 在 T4 finish 后
也退出（它看到队列空了），`/a` 和 `/b` 已经被 push 但**没有人处理**
——不是慢，是**丢工作**。

**`active` 的语义**：`active > 0` 意味着"至少有一个工作项被推入但还没
被 finish，它可能在处理中、可能即将 push 新的子工作项"。所以
"队列空 + active == 0" 才真的意味着"没有任何进行中的工作、也不会
再有新工作"——这是唯一安全的退出条件。

**和 ch8 原书的差异**：ch8 的 `pop()` 在取到工作项时 `active += 1`
（取的时候才计数），push 不动 active；本章的 `active` 在 **push 时 +1**。
两种设计都能保证不变量，区别在语义：ch8 的 active 是"正在处理中的
工作项数"，本章的是"已推入但未完成的工作项数"。本章的设计让
`startProducer`（43.5）更自然——生产者占一个 active 位，防止 consumer
在"生产者还没推完"时误判完成。

### 43.2.7 startProducer：生产者的占位符

```zig
// examples/43_zlocate/main.zig 第 101-105 行
/// 生产者调用：标记不再推入新工作项（配合 finish 使用）。
/// 解决「初始 active=0 导致 consumer 第一个 pop 就返回 null」的竞态。
fn startProducer(self: *Self) void {
    self.mutex.lockUncancelable(self.io);
    defer self.mutex.unlock(self.io);
    self.active += 1; // 生产者占一个 active 位，全部推完后 finish
}
```

这个方法是 43.5 生产者-消费者场景专用的。问题背景：producer 线程和
consumer 线程同时启动，如果 consumer 先跑、producer 还没推任何值，
consumer 的 `pop()` 会看到"队列空 + active == 0"→ 返回 null →
consumer 退出——producer 的值永远没人消费。

`startProducer` 让 producer 在推任何值**之前**先占一个 active 位
（+1），这样 consumer 的 pop 看到 `active > 0` 就会 wait 而不是退出。
producer 推完所有值后调 `finish()` 释放这个占位位——consumer 的
pop 在"队列空 + active == 0"时正确返回 null。

### 43.2.8 运行时输出

```zig
// examples/43_zlocate/main.zig 第 131-150 行
fn sectionWorkQueueTheory(io: std.Io, w: *std.Io.Writer) !void {
    begin("43.2 WorkQueue 理论");

    try w.print("WorkQueue 结构（泛型，T = 工作项类型）：\n", .{});
    try w.print("  mutex:   std.Io.Mutex      —— 保护 items 和 active\n", .{});
    try w.print("  cond:    std.Io.Condition   —— 空队列时 worker 睡眠，push 时唤醒\n", .{});
    try w.print("  items:   std.ArrayList(T)   —— 待处理工作项\n", .{});
    try w.print("  active:  usize              —— 已推入但未完成的工作项计数\n", .{});
    try w.print("\n", .{});
    try w.print("终止不变量（ch8 核心）：\n", .{});
    try w.print("  pop() 返回 null  ⟺  active == 0 AND items 为空\n", .{});
    try w.print("  若只看 items 为空：worker 可能在另一线程 finish 之前误判完成\n", .{});
    try w.print("  finish() 递减 active 并 broadcast —— 让最后一个 worker 能正确退出\n", .{});
    try w.print("\n", .{});
    try w.print("0.17 API：std.Io.Mutex.lock(io)/unlock(io)，Condition.wait(io, &mutex)/signal(io)/broadcast(io)\n", .{});
    try w.print("  std.Thread.WaitGroup/Pool 已移除 —— 用 Io.Group 或自建 join（见 31 章）\n", .{});
```

运行输出：

```text
==== 43.2 WorkQueue 理论 开始 ====
WorkQueue 结构（泛型，T = 工作项类型）：
  mutex:   std.Io.Mutex      —— 保护 items 和 active
  cond:    std.Io.Condition   —— 空队列时 worker 睡眠，push 时唤醒
  items:   std.ArrayList(T)   —— 待处理工作项
  active:  usize              —— 已推入但未完成的工作项计数

终止不变量（ch8 核心）：
  pop() 返回 null  ⟺  active == 0 AND items 为空
  若只看 items 为空：worker 可能在另一线程 finish 之前误判完成
  finish() 递减 active 并 broadcast —— 让最后一个 worker 能正确退出

0.17 API：std.Io.Mutex.lock(io)/unlock(io)，Condition.wait(io, &mutex)/signal(io)/broadcast(io)
  std.Thread.WaitGroup/Pool 已移除 —— 用 Io.Group 或自建 join（见 31 章）
==== 43.2 WorkQueue 理论 结束 ====
```

---

## 43.3 并行目录爬取

### 43.3.1 共享状态

```zig
// examples/43_zlocate/main.zig 第 154-171 行
const CrawlResult = struct {
    files: std.ArrayList([]const u8) = .empty,
    dirs: std.ArrayList([]const u8) = .empty,
    mutex: std.Io.Mutex = .init,
};

const CrawlCounters = struct {
    files: std.atomic.Value(u64) = .init(0),
    dirs: std.atomic.Value(u64) = .init(0),
};

const WorkerCtx = struct {
    queue: *WorkQueue([]const u8),
    result: *CrawlResult,
    counters: *CrawlCounters,
    gpa: std.mem.Allocator,
    io: std.Io,
};
```

逐行讲：

- **第 154-158 行**：`CrawlResult` 是 gather 阶段的共享容器。
  `files` 收集文件路径，`dirs` 收集目录路径（本章实际不用 `dirs`，
  但结构留着展示完整设计）。`mutex` 保护 `files`——多个 worker
  可能同时想追加，ArrayList 不是线程安全的。
- **第 160-163 行**：`CrawlCounters` 是**原子计数器**——`files` 和
  `dirs` 各一个 `std.atomic.Value(u64)`。计数器用原子而不是 mutex 的
  理由：递增是 O(1) 的单个 `fetchAdd`，原子操作足够且更快（无锁、
  无系统调用）。31 章讲过 `fetchAdd` 返回旧值、内存序选 `.monotonic`
  就够（不需要顺序一致性，只要计数不丢）。
- **第 165-171 行**：`WorkerCtx` 是传给每个 worker 线程的**单一参数**。
  `std.Thread.spawn` 只接受一个参数（19 章），多参数打包进结构体。
  全部用指针共享：`queue`、`result`、`counters` 都是 `*T`。

### 43.3.2 crawlWorker：worker 线程主体

```zig
// examples/43_zlocate/main.zig 第 173-209 行
fn crawlWorker(ctx: *WorkerCtx) void {
    while (ctx.queue.pop()) |dir_path| {
        defer ctx.queue.finish(); // 每轮结束 finish 一次（Zig defer 在 while body 末尾触发）
        var d = std.Io.Dir.cwd().openDir(ctx.io, dir_path, .{ .iterate = true }) catch {
            continue; // 打不开就跳过（defer 会 finish）
        };
        defer d.close(ctx.io);
        var it = d.iterate();
        while (true) {
            const maybe = it.next(ctx.io) catch break;
            const entry = maybe orelse break;
            var buf: [1024]u8 = undefined;
            const child = fmtJoin(&buf, dir_path, entry.name) catch continue;
            switch (entry.kind) {
                .directory => {
                    _ = ctx.counters.dirs.fetchAdd(1, .monotonic);
                    // 推回队列：BFS 的 scatter 阶段
                    const duped = ctx.gpa.dupe(u8, child) catch continue;
                    ctx.queue.push(duped) catch {
                        ctx.gpa.free(duped);
                        continue;
                    };
                },
                .file => {
                    _ = ctx.counters.files.fetchAdd(1, .monotonic);
                    const duped = ctx.gpa.dupe(u8, child) catch continue;
                    ctx.result.mutex.lockUncancelable(ctx.io);
                    defer ctx.result.mutex.unlock(ctx.io);
                    ctx.result.files.append(ctx.gpa, duped) catch {
                        ctx.gpa.free(duped);
                    };
                },
                else => {},
            }
        }
    }
}
```

逐行讲：

- **第 174 行**：`while (ctx.queue.pop()) |dir_path|`——worker 主循环。
  `pop()` 返回 `?[]const u8`：有工作项时解包为 `dir_path`，返回 null
  时循环结束（43.2 的终止不变量保证 null 只在"真的做完"时出现）。
- **第 175 行**：`defer ctx.queue.finish()`——**每轮循环结束调一次
  finish**。Zig 的 `defer` 在**作用域结束时**触发，`while` body 的
  defer 在每次迭代的末尾触发（不是整个 while 结束后）。这保证：
  无论循环体是正常走完、还是 `continue` 跳过、还是 `break` 中断，
  `finish` 都会调。push/finish 的配对靠 defer 自动化，不会漏。
- **第 176-178 行**：`openDir` 打开目录。`.iterate = true` 请求
  迭代能力（27 章讲过：不打开这个 flag 就不能 `iterate`）。
  `catch { continue; }`——目录打不开（权限不足、被删了）就跳过：
  `continue` 触发 defer 调 `finish`，然后进入下一轮 pop。
  单个坏目录不阻塞整个爬取。
- **第 179 行**：`defer d.close(ctx.io)`——目录句柄释放。同样靠 defer
  保证所有路径都执行。
- **第 180-183 行**：迭代器循环。`it.next(io)` 返回 `!?Entry`：
  `catch break` 处理迭代中的 I/O 错误（目录读一半坏了），
  `orelse break` 处理正常结束（返回 null）。27 章详细讲过这个
  两层解包模式。
- **第 184-185 行**：`fmtJoin(&buf, dir_path, entry.name)` 拼子路径。
  用 1024 字节的**栈缓冲**（零分配），`fmtJoin` 返回 `buffered()`
  即写入部分的切片。**注意**：这个切片指向栈缓冲 `buf`，下一轮循环
  就被覆盖——所以后面第 190/198 行要 `dupe` 到堆上才能长期保存。
  27 章的核心教训：`entry.name` 本身也指向迭代器内嵌缓冲，跨 `next()`
  失效，同样必须 dupe。
- **第 186 行**：`switch (entry.kind)` 按条目类型分派。
- **第 187-194 行**（`.directory` 分支）：目录 → 计数 + **推回队列**。
  这就是 BFS 的 scatter：发现子目录不自己递归，而是推给队列让
  任意空闲 worker 处理。`dupe` 是必须的（`child` 是栈缓冲切片）。
  `push` 失败时 `free(duped)` 再 `continue`——不泄漏。
- **第 195-203 行**（`.file` 分支）：文件 → 计数 + **加入结果列表**。
  `dupe` 后加 `result.files`。这里需要 `result.mutex` 保护——
  ArrayList 的 append 不是原子的（可能扩容、搬内存）。
  注意 defer 的嵌套：第 175 行的 defer 在**整个循环体**末尾触发，
  第 200 行的 defer 在 `.file` 分支的**块**末尾触发——Zig 的 defer
  严格按作用域配对。
- **第 205 行**（`else` 分支）：其它类型（符号链接、socket 等）忽略。
  27 章讲过：`walk` 天然不跟符号链接所以防环；本章的手写 BFS 也不跟
  （`.sym_link` 落入 else），同样天然防环。

### 43.3.3 主线程：spawn + join

```zig
// examples/43_zlocate/main.zig 第 211-255 行
fn sectionParallelCrawl(io: std.Io, gpa: std.mem.Allocator, w: *std.Io.Writer) !void {
    begin("43.3 并行目录爬取");

    var queue = WorkQueue([]const u8).init(gpa, io);
    defer queue.deinit();

    var result = CrawlResult{};
    defer {
        for (result.files.items) |p| gpa.free(p);
        result.files.deinit(gpa);
    }
    defer result.dirs.deinit(gpa);

    var counters = CrawlCounters{};

    // 根目录：本例所在目录（绝对路径，确保从任何 cwd 运行都能找到）
    const crawl_root = "/Volumes/mac004/code/programming/zig/examples/43_zlocate";
    const root_duped = try gpa.dupe(u8, crawl_root);
    try queue.push(root_duped);

    var ctx = WorkerCtx{
        .queue = &queue,
        .result = &result,
        .counters = &counters,
        .gpa = gpa,
        .io = io,
    };

    // Spawn 3 个 worker 线程
    var threads: [3]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, crawlWorker, .{&ctx});
    }
    for (threads) |t| t.join();

    const n_files = counters.files.load(.seq_cst);
    const n_dirs = counters.dirs.load(.seq_cst);
    try w.print("{d} 个工人索引了 {d} 个文件 {d} 个目录\n", .{ threads.len, n_files, n_dirs });
    try w.print("根目录: {s}\n", .{crawl_root});

    // 释放 push 时 dupe 的根路径（worker 不拥有它，只是借用）
    gpa.free(root_duped);
```

逐行讲：

- **第 214 行**：`WorkQueue([]const u8).init(gpa, io)`——实例化泛型。
  工作项类型是 `[]const u8`（目录路径切片）。
- **第 217-222 行**：`CrawlResult` 的 defer 释放。注意顺序：
  先 `free` 每个路径切片（worker dupe 的那些），再 `deinit` ArrayList
  本身。反过来的话，先释放了 list 的底层缓冲，就找不到路径切片了。
- **第 227-229 行**：根目录入队。`dupe` 是必要的——`crawl_root` 是
  字符串字面量（静态存储），但 `WorkQueue` 的约定是"推入的切片由
  调用方持有、worker 不释放"（worker 只 `pop` 出来用，不 `free`）。
  主线程在 join 之后 `free(root_duped)`（第 252 行）。
- **第 231-237 行**：构造 `WorkerCtx`。全部指针共享，worker 通过
  `ctx` 访问队列、结果、计数器。
- **第 240-243 行**：spawn 3 个 worker。`for (&threads) |*t|` 遍历
  数组的**指针**，直接赋值每个元素。`std.Thread.spawn(.{}, crawlWorker, .{&ctx})`
  的第三个参数是参数元组——`crawlWorker` 收一个 `*WorkerCtx`，
  元组里就传一个 `&ctx`。**三个线程共享同一个 `&ctx`**——这是故意的，
  `ctx` 里的字段全部设计成共享的。
- **第 244 行**：`for (threads) |t| t.join()`——join 全部三个。
  join 是同步点：三个 worker 都退出后（全部 pop 返回 null），
  主线程才继续。此时 `counters` 和 `result.files` 是**最终值**，
  可以安全读取。
- **第 246-247 行**：读计数器。`.seq_cst`（顺序一致性）是最保守的
  内存序——join 已经建立了 happens-before 关系（31 章），这里
  用 `.seq_cst` 是习惯性写法，`.monotonic` 也够。
- **第 252 行**：`gpa.free(root_duped)`——释放根路径的 dupe。
  时机在 join 之后：worker 不再引用它。

### 43.3.4 运行时输出

```text
==== 43.3 并行目录爬取 开始 ====
3 个工人索引了 1 个文件 0 个目录
根目录: /Volumes/mac004/code/programming/zig/examples/43_zlocate
==== 43.3 并行目录爬取 结束 ====
```

输出解读：

- **1 个文件 0 个目录**：示例目录 `examples/43_zlocate` 里只有
  `main.zig` 一个文件、没有子目录。3 个 worker 中只有一个拿到了
  工作（根目录），另外两个在第一次 pop 时 wait 睡眠、被 finish 的
  broadcast 唤醒后正确退出。**0 个目录**意味着 BFS 没有 scatter 出
  新工作项——队列里自始至终只有 1 个工作项。
- **为什么是"3 个工人"而不是"1 个工人"**：`threads.len` 是 spawn 的
  线程数（3），不是实际参与工作的线程数。3 个都跑了、都正确退出了，
  只是 2 个没活干。这恰好验证了终止不变量的正确性：空队列 + active
  归零 → 全部退出，没有挂死。

---

## 43.4 结果收集与排序

### 43.4.1 Gather 阶段

```zig
// examples/43_zlocate/main.zig 第 263-317 行
fn sectionGatherSort(io: std.Io, gpa: std.mem.Allocator, w: *std.Io.Writer) !void {
    begin("43.4 结果收集与排序");

    // 模拟 gather 阶段：从各 worker 收集路径，合并排序
    var all_paths: std.ArrayList([]const u8) = .empty;
    defer all_paths.deinit(gpa);

    // 实际从 43.3 的结果中收集（单线程重新跑一次，确保确定性）
    var queue = WorkQueue([]const u8).init(gpa, io);
    defer queue.deinit();

    var result = CrawlResult{};
    defer {
        for (result.files.items) |p| gpa.free(p);
        result.files.deinit(gpa);
    }

    var counters = CrawlCounters{};
    const crawl_root = "/Volumes/mac004/code/programming/zig/examples/43_zlocate";
    const root_duped = try gpa.dupe(u8, crawl_root);
    try queue.push(root_duped);

    var ctx = WorkerCtx{
        .queue = &queue,
        .result = &result,
        .counters = &counters,
        .gpa = gpa,
        .io = io,
    };

    var threads: [3]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, crawlWorker, .{&ctx});
    }
    for (threads) |t| t.join();

    // Gather：合并所有文件路径
    for (result.files.items) |p| {
        try all_paths.append(gpa, p);
    }

    // Sort：字典序
    std.mem.sort([]const u8, all_paths.items, {}, lessStr);

    try w.print("收集到 {d} 个文件路径，排序后前 {d} 个：\n", .{ all_paths.items.len, @min(@as(usize, 10), all_paths.items.len) });
    const show = @min(@as(usize, 10), all_paths.items.len);
    for (all_paths.items[0..show], 0..) |p, i| {
        try w.print("  [{d}] {s}\n", .{ i, p });
    }

    // 释放 push 时 dupe 的根路径
    gpa.free(root_duped);
```

本节重新跑了一次完整的并行爬取（代码和 43.3 相同），重点在爬取**之后**
的 gather 和 sort。

逐行讲：

- **第 267-268 行**：`all_paths` 是 gather 的目标容器——把
  `result.files` 里的路径**转移**进来。注意这里 `append(gpa, p)`
  复制的是**切片**（指针+长度，16 字节），不是切片指向的字符串数据——
  字符串数据仍然由 `result.files` 的 defer 释放（第 276 行）。
  `all_paths` 的 defer 只释放 ArrayList 的底层缓冲（切片数组），
  不释放字符串。
- **第 305 行**：`std.mem.sort([]const u8, all_paths.items, {}, lessStr)`——
  标准库排序。四个参数：元素类型、切片、上下文（`{}` 空）、比较函数。
- **第 259-261 行**（比较函数）：
  ```zig
  fn lessStr(_: void, x: []const u8, y: []const u8) bool {
      return std.mem.order(u8, x, y) == .lt;
  }
  ```
  `std.mem.order(u8, x, y)` 返回 `.lt` / `.eq` / `.gt` 三值比较结果，
  `lessStr` 只关心 `<`。第一个参数 `_` 是上下文占位（我们传了 `{}`）。
- **第 307-311 行**：打印前 `min(10, len)` 个。`@min` 是编译器内置的
  min 函数。`for (all_paths.items[0..show], 0..)` 双迭代——路径和
  序号同步遍历。

### 43.4.2 运行时输出

```text
==== 43.4 结果收集与排序 开始 ====
收集到 1 个文件路径，排序后前 1 个：
  [0] /Volumes/mac004/code/programming/zig/examples/43_zlocate/main.zig
==== 43.4 结果收集与排序 结束 ====
```

只有 1 个文件，排序没有实际效果。但代码路径是完整的：收集 → 排序 →
截取前 N 个——换成一个有几百个文件的目录，输出就是完整的有序列表。

### 43.4.3 测试：路径排序

```zig
// examples/43_zlocate/main.zig 第 502-522 行
test "路径排序与收集" {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const tio = threaded.io();
    _ = tio;

    const gpa = std.testing.allocator;
    var paths: std.ArrayList([]const u8) = .empty;
    defer paths.deinit(gpa);

    try paths.append(gpa, "examples/43_zlocate/main.zig");
    try paths.append(gpa, "examples/43_zlocate/src");
    try paths.append(gpa, "examples/43_zlocate");
    try paths.append(gpa, "examples/43_zlocate/.zig-cache");

    std.mem.sort([]const u8, paths.items, {}, lessStr);

    try std.testing.expectEqualStrings("examples/43_zlocate", paths.items[0]);
    try std.testing.expectEqualStrings("examples/43_zlocate/.zig-cache", paths.items[1]);
    try std.testing.expectEqualStrings("examples/43_zlocate/main.zig", paths.items[2]);
    try std.testing.expectEqualStrings("examples/43_zlocate/src", paths.items[3]);
}
```

这个 test 验证字典序的具体行为：`"examples/43_zlocate"` < 
`"examples/43_zlocate/.zig-cache"` < `"examples/43_zlocate/main.zig"` <
`"examples/43_zlocate/src"`。注意 `.zig-cache` 排在 `main.zig` 前面——
`.`（0x2E）的 ASCII 值小于 `m`（0x6D）。字典序不是"目录在前文件在后"的
语义序，就是纯字节序。

---

## 43.5 生产者-消费者

### 43.5.1 最小 demo

```zig
// examples/43_zlocate/main.zig 第 321-340 行
const IntQueue = WorkQueue(u32);

fn producer(ctx: *IntQueue) void {
    ctx.startProducer(); // 占一个 active 位，防止 consumer 首个 pop 就返回 null
    var i: u32 = 0;
    while (i < 5) : (i += 1) {
        ctx.push(i) catch {
            ctx.finish();
            return;
        };
    }
    ctx.finish(); // 释放生产者的 active 位
}

fn consumer(ctx: *IntQueue, out: *std.ArrayList(u32)) void {
    while (ctx.pop()) |v| {
        out.append(ctx.allocator, v) catch return;
        ctx.finish();
    }
}
```

逐行讲：

- **第 321 行**：`const IntQueue = WorkQueue(u32)`——同一个泛型，
  换个元素类型。43.3 用 `[]const u8`（路径），这里用 `u32`（整数）。
  泛型的复用价值就在这行：零修改、零复制。
- **第 324 行**：`ctx.startProducer()`——43.2.7 讲过的占位符。
  没有这行：consumer 先跑、producer 还没推值时，consumer 的 pop
  看到"空队列 + active==0"→ 返回 null → consumer 退出。
  有了这行：producer 先 +1，consumer 的 pop 看到 active>0 → wait。
- **第 326-331 行**：推 5 个值（0 到 4）。`push` 失败时 `finish()` +
  `return`——释放占位位再退出，不阻塞 consumer。
- **第 332 行**：`ctx.finish()`——释放生产者的占位位。此刻队列里
  可能还有未消费的值（consumer 慢），但 active 计数反映的是
  "consumer 还没 finish 的那些"——consumer 每 pop 一个 finish 一次，
  全部消费完后 active 归零，pop 返回 null，consumer 退出。
- **第 335-339 行**：consumer 主循环。`pop()` 拿到值就追加到 `out`，
  然后 `finish()`。注意 `out.append(...) catch return`——追加失败
  时直接退出（不 finish）——这会挂死程序（active 不归零、consumer
  退出后没人消费），但 `ArrayList.append` 只有 OOM 才失败，
  `std.testing.allocator` 下测试不会触发。生产代码应该 `finish` 后再
  传播错误。

### 43.5.2 运行时输出

```zig
// examples/43_zlocate/main.zig 第 342-364 行
fn sectionProducerConsumer(io: std.Io, gpa: std.mem.Allocator, w: *std.Io.Writer) !void {
    begin("43.5 生产者-消费者（条件变量版）");

    var queue = IntQueue.init(gpa, io);
    defer queue.deinit();

    var received: std.ArrayList(u32) = .empty;
    defer received.deinit(gpa);

    const pt = try std.Thread.spawn(.{}, producer, .{&queue});
    const ct = try std.Thread.spawn(.{}, consumer, .{ &queue, &received });
    pt.join();
    ct.join();

    try w.print("生产者推入 5 个值，消费者收到：", .{});
    for (received.items) |v| {
        try w.print("{d} ", .{v});
    }
    try w.print("\n", .{});
    try w.print("传输完成：{d} 个值，校验和 = {d}\n", .{ received.items.len, sumU32(received.items) });
```

运行输出：

```text
==== 43.5 生产者-消费者（条件变量版） 开始 ====
生产者推入 5 个值，消费者收到：0 1 2 3 4 
传输完成：5 个值，校验和 = 10
==== 43.5 生产者-消费者（条件变量版） 结束 ====
```

输出解读：5 个值按 FIFO 序到达（0 1 2 3 4），校验和 10 = 0+1+2+3+4。
`sumU32` 是确定性校验——不依赖时序，任何正确的执行都必然得到 10。
如果 consumer 漏了一个值（比如提前退出），校验和就不对——这就是
31 章确定性纪律的应用：**用校验和反证数据完整性**。

### 43.5.3 测试：WorkQueue 生命周期

```zig
// examples/43_zlocate/main.zig 第 456-500 行
test "WorkQueue push/pop/finish 生命周期" {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const tio = threaded.io();

    var q = WorkQueue(u32).init(std.testing.allocator, tio);
    defer q.deinit();

    // push 3 个
    try q.push(10);
    try q.push(20);
    try q.push(30);
    try std.testing.expectEqual(@as(usize, 3), q.active);
    try std.testing.expectEqual(@as(usize, 3), q.items.items.len);

    // pop 3 个（FIFO：从队首取）
    try std.testing.expectEqual(@as(u32, 10), q.pop().?);
    try std.testing.expectEqual(@as(u32, 20), q.pop().?);
    try std.testing.expectEqual(@as(u32, 30), q.pop().?);
    try std.testing.expectEqual(@as(usize, 3), q.active); // active 不减（finish 才减）

    // finish 3 次
    q.finish();
    q.finish();
    q.finish();
    try std.testing.expectEqual(@as(usize, 0), q.active);
}

test "终止不变量：finish 后 pop 返回 null" {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const tio = threaded.io();

    var q = WorkQueue(u32).init(std.testing.allocator, tio);
    defer q.deinit();

    // 空队列 + active=0 → pop 返回 null
    try std.testing.expect(q.pop() == null);

    // push 一个，pop 但不 finish → pop 返回 null（items 空但 active>0 时等待，这里单线程直接看）
    try q.push(42);
    try std.testing.expectEqual(@as(u32, 42), q.pop().?);
    // 此时 items 空但 active=1，pop 会阻塞 —— 单线程测试不能真的阻塞
    // 所以先 finish 再验证 null
    q.finish();
    try std.testing.expect(q.pop() == null);
}
```

两个 test 覆盖了 WorkQueue 的核心行为面：

第一个 test 验证 **push/pop/finish 的分离语义**：push 3 个后 active=3、
items.len=3；pop 3 个的顺序是 10, 20, 30（**FIFO**——`orderedRemove(0)`
从队首取，第 43.2.4 节讲过）；pop 3 个后 active **仍然是 3**
（pop 不减 active，finish 才减）；finish 3 次后 active=0。
**pop 和 finish 的分离**是 WorkQueue 的设计核心：pop 只取工作项，
finish 才宣告完成——两者之间是 worker 处理工作项的全过程，
active 在整个过程中保持 >0，其它 worker 不会误判"做完了"。

第二个 test 验证**终止不变量本身**：空队列 + active=0 时 pop 立即返回
null（第 491 行）；push 一个、pop 但不 finish 时 active=1（第 494-495 行）；
finish 之后 pop 返回 null（第 498-499 行）。第 496-497 行的注释说明了一个
测试限制：单线程测试不能真的让 pop 阻塞在 wait 里（没有其它线程会 push），
所以"items 空但 active>0"这个中间状态只能靠"先 finish 再验证 null"来间接
覆盖。多线程场景下的完整路径由 43.3/43.5 的运行时输出覆盖。

---

## 43.6 无锁替代方案（理论）

### 43.6.1 为什么需要无锁

WorkQueue 用一把 mutex 保护整个队列——临界区包含 `append`/`orderedRemove`
（O(n) 移动）和条件变量操作。在**高吞吐**场景（每秒几十万次 push/pop），
锁的竞争会成为瓶颈：多个 worker 抢一把锁，CPU 时间花在互斥而不是工作上。

无锁环形缓冲（lock-free ring buffer）是解决这个问题的经典方案：
**单生产者单消费者**（SPSC）场景下，用两个原子索引（head/tail）协调，
完全不需要 mutex。

### 43.6.2 设计

```zig
// examples/43_zlocate/main.zig 第 374-397 行
fn sectionLockFree(w: *std.Io.Writer) !void {
    begin("43.6 无锁替代方案（理论）");

    try w.print("无锁环形缓冲（SPSC：单生产者单消费者）设计：\n", .{});
    try w.print("  head: std.atomic.Value(u32) —— 生产者写入位置\n", .{});
    try w.print("  tail: std.atomic.Value(u32) —— 消费者读取位置\n", .{});
    try w.print("  buf:  [CAP]T                   —— 环形数组\n", .{});
    try w.print("\n", .{});
    try w.print("push（生产者）：\n", .{});
    try w.print("  1. h = head.load(.monotonic)\n", .{});
    try w.print("  2. 若 (h + 1) % CAP == tail.load(.acquire) → 满，自旋或让出\n", .{});
    try w.print("  3. buf[h] = item; head.store((h+1) % CAP, .release)\n", .{});
    try w.print("\n", .{});
    try w.print("pop（消费者）：\n", .{});
    try w.print("  1. t = tail.load(.monotonic)\n", .{});
    try w.print("  2. 若 t == head.load(.acquire) → 空，返回 null\n", .{});
    try w.print("  3. item = buf[t]; tail.store((t+1) % CAP, .release)\n", .{});
    try w.print("\n", .{});
    try w.print("优势：无锁、无系统调用（cache-line 乒乓是主要开销）\n", .{});
    try w.print("参考：《Systems Programming with Zig》ch8 的 ring buffer 实现\n", .{});
    try w.print("0.17 实测：std.atomic.Value(u32) 可用，CAS 用 cmpxchgWeak/Strong\n", .{});
```

运行输出：

```text
==== 43.6 无锁替代方案（理论） 开始 ====
无锁环形缓冲（SPSC：单生产者单消费者）设计：
  head: std.atomic.Value(u32) —— 生产者写入位置
  tail: std.atomic.Value(u32) —— 消费者读取位置
  buf:  [CAP]T                   —— 环形数组

push（生产者）：
  1. h = head.load(.monotonic)
  2. 若 (h + 1) % CAP == tail.load(.acquire) → 满，自旋或让出
  3. buf[h] = item; head.store((h+1) % CAP, .release)

pop（消费者）：
  1. t = tail.load(.monotonic)
  2. 若 t == head.load(.acquire) → 空，返回 null
  3. item = buf[t]; tail.store((t+1) % CAP, .release)

优势：无锁、无系统调用（cache-line 乒乓是主要开销）
参考：《Systems Programming with Zig》ch8 的 ring buffer 实现
0.17 实测：std.atomic.Value(u32) 可用，CAS 用 cmpxchgWeak/Strong
==== 43.6 无锁替代方案（理论） 结束 ====
```

逐点讲：

- **head/tail 分工**：`head` 只有生产者写、消费者读；`tail` 只有消费者写、
  生产者读。这是 SPSC 的关键——**每个索引只有一个写者**，不需要 CAS
  （compare-and-swap），普通的 load/store 就够。
- **内存序的选择**：生产者的 `head.store(.release)` 保证 `buf[h] = item`
  的写入**先于** head 的更新被消费者看到；消费者的 `head.load(.acquire)`
  与之配对。`tail` 同理。`.monotonic` 用于"只关心数值不关心顺序"的读
  （第 1 步的 load）——31 章讲过内存序的层级，这里是最小够用原则。
- **判满/判空**：`(h+1) % CAP == tail` 判满（再写一个就撞 tail）、
  `t == head` 判空。注意**牺牲一个槽位**来区分"满"和"空"——如果
  CAP=4，最多只能放 3 个元素。这是环形缓冲的经典设计。
- **为什么本章不实现**：SPSC 环形缓冲解决不了本章的问题——目录爬取是
  **多生产者多消费者**（MPMC）：任意 worker 都可能发现新目录（push）、
  任意 worker 都可能取目录（pop）。MPMC 无锁队列需要 CAS，复杂度陡增，
  而且 43.3 的瓶颈在目录 I/O 不在队列操作——**先测量再优化**，
  锁不是瓶颈时无锁只是增加 bug 面。

---

## 43.7 运行时坑位清单

`main` 末尾有一个 43.7 小节，把五条最重要的坑打在运行时输出里：

```zig
// examples/43_zlocate/main.zig 第 401-424 行
fn sectionPitfalls(io: std.Io, w: *std.Io.Writer) !void {
    _ = io;
    begin("43.7 坑位清单");

    try w.print("① 终止不变量：active==0 且队列为空才能返回 null\n", .{});
    try w.print("   否则 worker 提前退出丢工作（ch8 的核心教训）\n", .{});
    try w.print("\n", .{});
    try w.print("② std.Thread.WaitGroup/Pool 在 0.17 已移除\n", .{});
    try w.print("   用 Io.Group 或自建 join（见 31 章 WaitGroup 复刻）\n", .{});
    try w.print("\n", .{});
    try w.print("③ 条件变量 wait 必须放在 while 循环里检查条件\n", .{});
    try w.print("   虚假唤醒（spurious wakeup）是 API 的正式设定\n", .{});
    try w.print("\n", .{});
    try w.print("④ 工人线程的 Io 实例：init.io 可跨线程共享\n", .{});
    try w.print("   底层是 Threaded 的 OS futex（ch31 实测通过）\n", .{});
    try w.print("   test 块用 std.Io.Threaded = .init_single_threaded 独立实例\n", .{});
    try w.print("   （避开 std.testing.io 的 Condition 死锁，见 31.11）\n", .{});
    try w.print("\n", .{});
    try w.print("⑤ 目录迭代 entry.name 跨 next() 失效\n", .{});
    try w.print("   entry.name 指向迭代器内嵌 2048 字节缓冲，下一次 next 被覆盖\n", .{});
    try w.print("   跨 next 收集必须 dupe（27 章教训）\n", .{});
```

运行输出：

```text
==== 43.7 坑位清单 开始 ====
① 终止不变量：active==0 且队列为空才能返回 null
   否则 worker 提前退出丢工作（ch8 的核心教训）

② std.Thread.WaitGroup/Pool 在 0.17 已移除
   用 Io.Group 或自建 join（见 31 章 WaitGroup 复刻）

③ 条件变量 wait 必须放在 while 循环里检查条件
   虚假唤醒（spurious wakeup）是 API 的正式设定

④ 工人线程的 Io 实例：init.io 可跨线程共享
   底层是 Threaded 的 OS futex（ch31 实测通过）
   test 块用 std.Io.Threaded = .init_single_threaded 独立实例
   （避开 std.testing.io 的 Condition 死锁，见 31.11）

⑤ 目录迭代 entry.name 跨 next() 失效
   entry.name 指向迭代器内嵌 2048 字节缓冲，下一次 next 被覆盖
   跨 next 收集必须 dupe（27 章教训）
==== 43.7 坑位清单 结束 ====
```

---

## 43.8 坑位清单（展开版）

按「会不会让程序静默丢数据/挂死」排序。前 3 条是运行时才会暴露的。

### 一、会静默丢工作或挂死的（最危险）

1. **终止不变量不完整：只看"队列为空"就退出**。43.2.6 的完整推演已经
   展示过丢子树的场景。修复方法只有一个：`pop()` 返回 null 的条件必须
   是 **`active == 0` 且队列为空**，两者缺一不可。如果你发现并行程序
   "偶尔少几个结果"，第一检查点就是这个不变量。

2. **`finish` 忘记调 → worker 挂死**。push/finish 的配对靠 `defer` 自动化
   （43.3 的第 175 行），但 `catch { continue; }` 分支里 defer 会正确触发——
   真正危险的是**手动路径**：如果在某条错误分支里 `return` 或 `break`
   绕过了 defer 的作用域，`finish` 就漏了。后果：active 永远不归零，
   其它 worker 的 `pop` 永远 wait，程序挂死。纪律：**pop 之后立刻
   `defer finish`，不要分开写**。

3. **条件变量 `wait` 用 `if` 而不是 `while`**。虚假唤醒是 POSIX 条件变量
   的正式语义——`wait` 可能在条件不满足时返回。用 `if` 的话，虚假唤醒
   直接走到"取元素"逻辑，对空队列操作 → panic 或 UB。正确写法永远是：

   ```zig
   while (condition_not_met) {
       cond.wait(io, &mutex);
   }
   ```

   或者本章的等价形式（先检查终止条件再 wait）：

   ```zig
   while (items.len == 0) {
       if (active == 0) return null;
       cond.wait(io, &mutex);
   }
   ```

### 二、0.17 API 迁移的坑

4. **`std.Thread.WaitGroup` / `Pool` / `RwLock` / `Semaphore` / `ResetEvent`
   全部不存在**。31 章用 `@hasDecl` 逐个实测为 `false`。替代品：

   | 旧（0.16 及之前） | 新（0.17） |
   |---|---|
   | `std.Thread.Mutex` | `std.Io.Mutex`（方法首参 `io`） |
   | `std.Thread.Condition` | `std.Io.Condition`（方法首参 `io`） |
   | `std.Thread.WaitGroup` | 自建（31 章复刻）或 `Io.Group` |
   | `std.Thread.Pool` | 自建或用 `WorkQueue` 模式 |
   | `std.Thread.Semaphore` | `std.Io.Semaphore` |

   本章的 WorkQueue 就是"自建 Pool"的最小实现。

5. **`std.Io.Mutex` 的 `lock` 返回 `!void`，`lockUncancelable` 返回 `void`**。
   选哪个？临界区短到"没有理由取消"就用 `lockUncancelable`（本章全部用它）；
   临界区可能阻塞很久（等 I/O）就用 `lock` + `try`/`catch`。混用的后果：
   `lock` 的 `!void` 不处理编译报错，`lockUncancelable` 在可取消上下文里
   会忽略取消信号。

6. **`std.testing.io` 的 `Condition.wait` 会死锁**（31.11 实测）。test 块里
   要用 `std.Io.Threaded = .init_single_threaded` 自建独立 Io 实例：

   ```zig
   var threaded: std.Io.Threaded = .init_single_threaded;
   const tio = threaded.io();
   var q = WorkQueue(u32).init(std.testing.allocator, tio);
   ```

   本章的 4 个 test 全部遵守这条。

### 三、数据生命周期

7. **`entry.name` 跨 `next()` 失效**（27 章教训）。`entry.name` 指向迭代器
   内嵌的 2048 字节缓冲，下一次 `next()` 会覆盖它。43.3 的 `crawlWorker`
   里，`child` 由 `fmtJoin(&buf, dir_path, entry.name)` 拼出——`buf` 是
   栈缓冲、`entry.name` 是迭代器缓冲，**两个都活不过下一轮循环**。所以
   第 190/198 行必须 `gpa.dupe(u8, child)` 到堆上。漏掉 dupe 的话，
   收集到的路径切片指向已失效的内存——内容随机损坏，不崩溃、不报错。

8. **push 进队列的切片所有权**。WorkQueue 的约定：**push 方持有切片、
   worker 只借用**。43.3 里主线程 `dupe` 了根路径、join 后 `free`；
   worker `dupe` 了子路径、加入 `result.files` 后由主线程统一 `free`。
   如果让 worker `free` pop 出来的切片，就和"主线程 free 根路径"冲突了——
   同一块内存两次释放。所有权约定必须**全局一致**。

9. **`std.Io.Dir` 的 `iterate` flag 必须显式打开**。`openDir` 的默认选项
   不允许迭代——不传 `.iterate = true` 就调 `.iterate()` 会编译报错或
   运行时失败（27 章的 27.1.3 有完整实测签名表）。

### 四、设计层面的提醒

10. **先测量再决定是否无锁**。43.6 讲了 SPSC 环形缓冲的设计，但本章
    没有实现它——因为目录爬取的瓶颈在 I/O 不在队列。无锁数据结构的
    复杂度（内存序、ABA 问题、缓存行填充）只有在** profiling 证明锁是
    瓶颈之后**才值得引入。

11. **`std.Thread.spawn` 只接受一个参数**。多参数必须打包进结构体——
    本章的 `WorkerCtx` 就是这个模式的实例。打包时全部用指针共享：
    `queue`、`result`、`counters` 都是 `*T`，三个线程读写同一份。

---

## 43.9 验证方式

三层，与全项目一致（见 2.8 节）：

```bash
cd examples/43_zlocate
zig fmt --check .                                    # 第 1 层：格式 + 语法
zig test main.zig                                    # 第 2 层：4 个 test
zig build-exe main.zig -femit-bin=/tmp/43_zlocate    # 第 3 层：main 也要能编
/tmp/43_zlocate                                       # 第 3 层：真跑一遍
```

第 3 层不可省：`zig test` 不看 `main`，而本章最要紧的 7 个运行时小节
**全在 `main` 里`。

跑完应看到（逐字节抄自 macOS 实测）：

```text
==== 43.1 Scatter-Gather 理论 开始 ====
Scatter-Gather 三步：
  ① Scatter：主线程把任务切片分发给 worker
  ② 并行处理：每个 worker 独立消费自己的那份
  ③ Gather：主线程回收全部结果，合并输出

单线程 vs 多线程（处理 N 个目录）：
  单线程：T_total = N × t_each（顺序累加）
  多线程：T_total ≈ (N / K) × t_each + overhead（K 个 worker）
  加速比上限 = K（Amdahl：受串行部分限制）

关键不变量：worker 不能提前退出 —— 必须等所有任务做完。
  判定条件：active == 0 且队列为空（43.2 详解）
==== 43.1 Scatter-Gather 理论 结束 ====
==== 43.2 WorkQueue 理论 开始 ====
WorkQueue 结构（泛型，T = 工作项类型）：
  mutex:   std.Io.Mutex      —— 保护 items 和 active
  cond:    std.Io.Condition   —— 空队列时 worker 睡眠，push 时唤醒
  items:   std.ArrayList(T)   —— 待处理工作项
  active:  usize              —— 已推入但未完成的工作项计数

终止不变量（ch8 核心）：
  pop() 返回 null  ⟺  active == 0 AND items 为空
  若只看 items 为空：worker 可能在另一线程 finish 之前误判完成
  finish() 递减 active 并 broadcast —— 让最后一个 worker 能正确退出

0.17 API：std.Io.Mutex.lock(io)/unlock(io)，Condition.wait(io, &mutex)/signal(io)/broadcast(io)
  std.Thread.WaitGroup/Pool 已移除 —— 用 Io.Group 或自建 join（见 31 章）
==== 43.2 WorkQueue 理论 结束 ====
==== 43.3 并行目录爬取 开始 ====
3 个工人索引了 1 个文件 0 个目录
根目录: /Volumes/mac004/code/programming/zig/examples/43_zlocate
==== 43.3 并行目录爬取 结束 ====
==== 43.4 结果收集与排序 开始 ====
收集到 1 个文件路径，排序后前 1 个：
  [0] /Volumes/mac004/code/programming/zig/examples/43_zlocate/main.zig
==== 43.4 结果收集与排序 结束 ====
==== 43.5 生产者-消费者（条件变量版） 开始 ====
生产者推入 5 个值，消费者收到：0 1 2 3 4 
传输完成：5 个值，校验和 = 10
==== 43.5 生产者-消费者（条件变量版） 结束 ====
==== 43.6 无锁替代方案（理论） 开始 ====
无锁环形缓冲（SPSC：单生产者单消费者）设计：
  head: std.atomic.Value(u32) —— 生产者写入位置
  tail: std.atomic.Value(u32) —— 消费者读取位置
  buf:  [CAP]T                   —— 环形数组

push（生产者）：
  1. h = head.load(.monotonic)
  2. 若 (h + 1) % CAP == tail.load(.acquire) → 满，自旋或让出
  3. buf[h] = item; head.store((h+1) % CAP, .release)

pop（消费者）：
  1. t = tail.load(.monotonic)
  2. 若 t == head.load(.acquire) → 空，返回 null
  3. item = buf[t]; tail.store((t+1) % CAP, .release)

优势：无锁、无系统调用（cache-line 乒乓是主要开销）
参考：《Systems Programming with Zig》ch8 的 ring buffer 实现
0.17 实测：std.atomic.Value(u32) 可用，CAS 用 cmpxchgWeak/Strong
==== 43.6 无锁替代方案（理论） 结束 ====
==== 43.7 坑位清单 开始 ====
① 终止不变量：active==0 且队列为空才能返回 null
   否则 worker 提前退出丢工作（ch8 的核心教训）

② std.Thread.WaitGroup/Pool 在 0.17 已移除
   用 Io.Group 或自建 join（见 31 章 WaitGroup 复刻）

③ 条件变量 wait 必须放在 while 循环里检查条件
   虚假唤醒（spurious wakeup）是 API 的正式设定

④ 工人线程的 Io 实例：init.io 可跨线程共享
   底层是 Threaded 的 OS futex（ch31 实测通过）
   test 块用 std.Io.Threaded = .init_single_threaded 独立实例
   （避开 std.testing.io 的 Condition 死锁，见 31.11）

⑤ 目录迭代 entry.name 跨 next() 失效
   entry.name 指向迭代器内嵌 2048 字节缓冲，下一次 next 被覆盖
   跨 next 收集必须 dupe（27 章教训）
==== 43.7 坑位清单 结束 ====
```

4 个 test 覆盖的行为面：

| test | 验什么 |
|---|---|
| `WorkQueue push/pop/finish 生命周期` | push/pop/finish 分离语义、FIFO 顺序、active 计数 |
| `终止不变量：finish 后 pop 返回 null` | 空队列 + active=0 → null；finish 后 → null |
| `路径排序与收集` | 字典序排序的具体行为（`.` < `m`） |
| `isWanted glob 匹配` | `*`/`?` 通配符的匹配语义（`*` 不跨 `/`） |

**并发正确性的额外验证**：43.3 和 43.5 的运行时输出本身就是并发测试——
3 个 worker 正确退出（没有挂死）、5 个值按 FIFO 到达（校验和 = 10）。
如果终止不变量有 bug，43.3 会挂死或丢文件；如果 push/finish 配对乱了，
43.5 的校验和就不是 10。这是 31 章确定性纪律的应用：**用可复现的
输出反证并发正确性**。

---

上一章：[42 JSON 系统监控服务](42-memsrv.md)