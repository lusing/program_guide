# 19 · 并发：线程与原子

> 对应示例：`examples/19_threads/`
>
> 0.16 大改：Mutex/Condition 移入 `std.Io` 且**方法要 io 参数**；`WaitGroup` 已移除（join 就是同步点）；`Thread.sleep` 没了（时间归 Io，22 章）。

## 19.1 spawn / join

```zig
const t1 = try std.Thread.spawn(.{}, worker.run, .{1});   // 配置、函数、参数元组
t1.join();                                                // 等它干完
```

`std.Thread.spawn(config, fn, args)` 起线程——config 能调 `.stack_size`；`join()` 等待并回收，`detach()` 撒手（之后句柄作废）。`std.Thread.getCurrentId()` 拿线程 id，`getCpuCount()` 探核数。**线程函数不能捕获**（没有闭包）——要"带数据的任务"传参数元组或上 struct（19.6 模式）。

## 19.2 Io.Mutex：互斥

```zig
var counter: usize = 0;
var mutex: std.Io.Mutex = .init;          // 0.16：命名常量 .init（不是 .{}）

fn addLocked(io: std.Io, n: usize) void {
    for (0..n) |_| {
        mutex.lockUncancelable(io);       // 0.16：锁操作要 io
        defer mutex.unlock(io);
        counter += 1;
    }
}
```

Mutex 保护"一次只许一个线程摸"的共享数据——解锁忘了 = 死锁，所以**永远配 defer**。0.16 的变化：锁的方法签名带 `io`（为将来的异步取消做准备）——线程函数一路把 `init.io` 传下去即可；`lockUncancelable` 是同步版（`lock` 返回可取消的错误联合，教学场景用不到取消）。去掉锁的实验在示例里：两线程各加 5 万次，无锁结果必小于 100000（丢更新）。

## 19.3 atomic.Value：无锁计数

```zig
var hits = std.atomic.Value(usize).init(0);
// 工作线程里：
_ = h.fetchAdd(1, .monotonic);            // 原子 +1
// 读取：
h.load(.seq_cst)
```

`std.atomic.Value(T)` 把任意整数/布尔/指针包成原子——`fetchAdd/fetchSub/swap/compareExchange` 读改写全家。**内存序**三档实用建议：

| 序 | 何时用 |
|---|---|
| `.monotonic` | 纯计数/统计（不要它同步别的数据） |
| `.acq_rel` / `.acquire`+`.release` | 通过原子标志发布/消费别的数据 |
| `.seq_cst` | 拿不准就用它（最保守，慢一点点） |

简单原则：**计数 monotonic，同步 seq_cst，测出热点再精细化**。

## 19.4 Io.Condition + 有界队列：生产者-消费者

```zig
const Queue = struct {
    buf: [8]u32 = undefined,
    head: usize = 0,
    count: usize = 0,
    mtx: std.Io.Mutex = .init,
    not_empty: std.Io.Condition = .init,     // 消费者等它
    not_full: std.Io.Condition = .init,      // 生产者等它

    fn push(self: *Queue, io: std.Io, v: u32) void {
        self.mtx.lockUncancelable(io);
        defer self.mtx.unlock(io);
        while (self.count == self.buf.len) {          // ← while 不是 if！
            self.not_full.waitUncancelable(io, &self.mtx);
        }
        self.buf[(self.head + self.count) % self.buf.len] = v;
        self.count += 1;
        self.not_empty.signal(io);
    }
    fn pop(self: *Queue, io: std.Io) u32 { /* 对称：等 not_empty，signal not_full */ }
};
```

经典模板，四个记忆点：**双条件**（空/满各一个等待点）、**wait 必须在 while 里**（虚假唤醒是 POSIX 的官方设定，if 会错过重检）、**wait 原子地放锁+睡眠+醒来抢锁**（这是它比 sleep 轮询优雅的全部）、signal 在 unlock 前后皆可。这套结构是线程池、任务队列、channel 式通信的地基（24 章用原子游标绕开了队列，另一条路）。

## 19.5 线程协调：join 就够了

0.16 移除了 `WaitGroup`（原"等 N 个活干完"的计数器）。替代：**直接 join 所有线程**——多数场景等的就是"线程结束"。要"等任务而不是等线程"（线程池常驻）就用 `Io.Condition` 广播或原子计数。示例里每个线程 join 一遍，语义清晰无遗漏。

## 19.6 线程任务模式：struct + 参数元组

```zig
const Task = struct {
    fn run(w: *Worker, fl: []const []const u8, nx: *std.atomic.Value(usize),
           a: std.mem.Allocator) void {
        while (true) {
            const i = nx.fetchAdd(1, .monotonic);   // 原子抢号
            if (i >= fl.len) break;
            w.searchFile(a, fl[i]);
        }
    }
};
const t = try std.Thread.spawn(.{}, Task.run, .{ &worker, files, &next, mem });
```

没有闭包的 Zig 用"**函数 + 参数元组**"传任务状态——或者像 24 章这样：**原子游标抢任务**（fetchAdd 拿号，号超了收工）比队列分发更简单且天然负载均衡，多线程批处理的默认套路。

## 19.7 坑位清单

1. **`.init` 不是 `.{} `**：0.16 的 `Io.Mutex`/`Io.Condition` 用命名常量初始化（`.init`）——空字面量会报 missing struct field。
2. **锁方法带 io**：`lock()`/`unlock()`/`wait()`/`signal()` 都要传 io——线程函数签名加个 `io: std.Io` 参数一路传下去。
3. **wait 写在 if 里是并发 bug**：虚假唤醒后条件不再成立却继续走——**一律 while 重检**。
4. **detach 后用句柄**：detach 是"放弃追踪"，之后再 join/deref 是 UB——要么 join 要么 detach，别都要。
5. **持锁做 IO**：锁区里 printf/写文件/网络 = 全队排队看你 IO——锁区压到最小，纯内存操作。

---

上一章：[18 交叉编译](18-cross.md) · 下一章：[20 文件与 IO](20-files-io.md)
