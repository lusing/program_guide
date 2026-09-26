# 24 · 同步原语与进程间通信：锁、信号量与管道

> 对应示例：`examples/24_sync`

## 1. 位置：把第 14 章的"一句话 lock"补成家族

第 14 章处理**共享状态**（Interlocked 原子操作、Concurrent 容器、一句 `lock`）。本章处理另外两件事：**限流**（最多 N 个同时进）与**等待-通知**（线程间打信号），再加上**进程边界**的通信。选型表：

| 需求 | 工具 |
|---|---|
| 互斥访问不变量 | `lock` / `Monitor`（第 14 章） |
| 限制并发数 | `SemaphoreSlim` |
| 单实例应用（跨进程互斥） | `Mutex`（命名） |
| 线程间信号 | `AutoResetEvent` / `ManualResetEventSlim` |
| 生产者-消费者 | `Channel<T>` 首选；经典写法 `Monitor.Wait/Pulse` |
| 进程间字节流 | 管道 / Socket（第 22 章） |
| 目录变更通知 | `FileSystemWatcher` |

## 2. SemaphoreSlim：限流，不是互斥

```csharp
using var gate = new SemaphoreSlim(2, 2);   // 2 个名额
await gate.WaitAsync();                      // async 版不占线程
try { /* 受限的 IO */ }
finally { gate.Release(); }
```

6 个并发任务过一道限 2 的闸门，实测峰值正好 2——连接池、对外 API 限速、保护下游都是它。`finally` 里 `Release` 是纪律：不还名额就是泄漏，后续全部永久堵死。与 `Mutex` 的区别一句话：**Semaphore 管数量（谁都可以进，数着），Mutex 管归属（我进去了别人就不该进，讲身份）**——所以 `Mutex` 才能拿来做"程序只能开一个"（命名 Mutex 跨进程可见，`new Mutex(true, "MyApp", out var createdNew)`，`createdNew == false` 说明已有实例）。`SemaphoreSlim` 的 `Slim` = 无内核对象开销的进程内版本；要跨进程计数信号量用 `Semaphore`。

## 3. 事件句柄：Auto 与 Manual

`EventWaitHandle` 家族是"信号灯"：

- **`AutoResetEvent`**：旋转门——`Set()` 放行**一个**等待者，门自动关上。示例用它做生产者-消费者乒乓：每 `Set` 一次恰好一次 `WaitOne` 通过。
- **`ManualResetEvent(Slim)`**：大门——`Set()` 后**敞开**，所有等待者（含后来的）全过，直到 `Reset()` 关门。适合"广播一个状态变了"。

带 `Slim` 的版本（`ManualResetEventSlim`、`SemaphoreSlim`）先用自旋再陷入内核，进程内等待快得多，默认选 Slim 系；`Auto` 没有Slim 版。等待给超时/取消是纪律：`WaitOne(1000)`、`WaitAsync(ct)`，避免对端死了自己陪葬。

## 4. 生产者-消费者：经典与现代

经典教材解法（`Monitor.Wait/Pulse`）：共享队列 + `lock` + 满则 `Wait`、放货后 `Pulse`——能写对是硬功夫，条件判断要 `while` 不能 `if`（防虚假唤醒），`Pulse`/`PulseAll` 的选择影响吞吐。**新代码不要手搓**：

```csharp
var channel = Channel.CreateBounded<int>(100);
await channel.Writer.WriteAsync(item);   // 满则异步等
await foreach (var item in channel.Reader.ReadAllAsync())
    Handle(item);                        // 消费端一个循环搞定
```

`Channel<T>`（第 13/14 章引过）就是生产者-消费者的框架化：背压、完成语义、异步等待全内置。看到 `Wait/Pulse` 的老代码，读懂，然后有条件就迁。

## 5. 管道：进程间的字节流

```csharp
using var pipeOut = new AnonymousPipeServerStream(PipeDirection.Out, HandleInheritability.None);
using var pipeIn  = new AnonymousPipeClientStream(PipeDirection.In, pipeOut.ClientSafePipeHandle);
```

- **匿名管道**：一对读写句柄，典型用法是父进程创建后把一端**继承**给子进程（`ProcessStartInfo` 启动时传句柄）——`stdin/stdout` 重定向（第 23 章）本质就是 OS 替你接的匿名管道。
- **命名管道**：`NamedPipeServerStream("myapp.pipe")`，任何进程按名字连——本机跨进程 RPC 的轻量首选，比开 Socket 端口轻、不带网络栈的防火墙麻烦，Windows/Linux 都支持（Linux 落在 Unix domain socket 上）。

管道是**字节流**，消息边界自理——第 22 章的分帧（长度前缀/分隔符）原样适用。

## 6. FileSystemWatcher：事件重入坑

```csharp
using var watcher = new FileSystemWatcher(dir)
{
    NotifyFilter = NotifyFilters.FileName | NotifyFilters.LastWrite,
    EnableRaisingEvents = true,
};
watcher.Created += (_, e) => seen.Enqueue($"created:{e.Name}");
```

三条纪律：

1. **事件在线程池 IO 线程上触发**——处理函数要快，别在里面做重活/阻塞；否则事件堆积撑爆内部缓冲区（`Error` 事件 + `InternalBufferOverflowException`，丢事件）。模式是**事件只入队，工作线程消费**（又一个生产者-消费者）。
2. **重入**：监听目录变更，处理函数又往这个目录写/搬文件——事件再触发，自己咬自己尾巴（在事件里"把新文件转移到归档目录"是经典事故：Move 本身再触发 Renamed/Created）。出队的工作线程处理时，写操作要么过滤路径，要么挪到监听范围外。
3. **事件不保证一次性齐全**：同一次保存可能来 2~3 个 `Changed`，通知有延迟——对"最终状态"感兴趣就防抖（收集→静默期→对账一遍目录），别对单个事件做反应式决策。

## 7. 坑位清单

1. **`lock (this)` / `lock (typeof(X))` / `lock ("str")`**：锁对象必须是 `private readonly object`——`this`/Type 外部可见（别人也 lock 它就死锁），字符串被驻留（全进程同名同对象）。
2. **锁里 `await`**：`lock` 语句块里不能 await（编译器直接拒绝）；`SemaphoreSlim.WaitAsync` + try/finally 是异步互斥的正解。
3. **两把锁顺序相反** → 经典死锁：A 拿 lock1 等 lock2，B 拿 lock2 等 lock1。全局规定加锁顺序，或合并成一把。
4. **`Release` 不在 finally** → 名额泄漏，后面的等待者永久挂起。
5. **`Monitor.Wait` 的条件用 `if`** → 虚假唤醒下抢到不该抢的货，必须 `while (条件) Monitor.Wait(...)`。
6. **裸 `WaitOne()` 无超时**：依赖对端行为才能返回，对端一死就陪葬；给超时或取消。
7. **管道读端不处理 EOF**：写端关闭后 `Read` 返回 0（不是抛异常），循环条件写成 `> 0`，忘了就是死循环读零字节。
