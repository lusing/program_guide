# 31 · 并发进阶

> 对应示例：`examples/31_concurrency/`
>
> 19 章会spawn线程了；本章补上真正的并发工具箱：原子操作、CAS、RwLock、条件变量、线程池。取材 Tsoukalos ch8（生产者-消费者两种实现、线程池）与 Sprinter ch9/10（并发 vs 并行）。
>
> ⚠️ 0.16 大迁移：`std.Thread.Mutex/Condition/RwLock` **已并入 std.Io 且全部方法带 io 参数**。网上一切旧教程的 `std.Thread.Mutex` 写法在本版直接编译不过。

## 31.1 竞态现场：裸 += vs fetchAdd

```zig
p.* +%= 1;                          // 读-改-写三步，随时被穿插
_ = p.fetchAdd(1, .seq_cst);        // 一条原子指令
```

示例 8 线程各加十万次：裸写丢六成更新（Debug 构建也可能"碰巧全对"——竞态是概率性的，这正是它可怕之处），原子版分毫不差。**只有断言原子侧**，裸侧打印观感——测试里断言裸计数 == 期望值是自欺。

## 31.2 CAS：cmpxchgWeak 乐观重试

```zig
while (true) {
    const cur = p.load(.seq_cst);
    if (candidate <= cur) return;
    if (p.cmpxchgWeak(cur, candidate, .seq_cst, .seq_cst)) |_| {
        // 有人抢先写了：重读重试
    } else return;
}
```

比较并交换是无锁算法的原子：期望旧值、想写新值，失败（返回非 null 的实际值）说明有人抢先——**循环重来**而不是报错。`fetchAdd` 是 CAS 的特例（底层同一条指令）。内存序从 `.seq_cst` 起步最稳； downgrade 到 `.acquire/.release` 是拿到正确性之后的优化，先对后快。

## 31.3 RwLock：读多写少

```zig
g.lock.lockUncancelable(io);        // 写锁：独占
defer g.lock.unlock(io);
// 读侧：lockSharedUncancelable(io) / unlockShared(io)——多个读者并发不互斥
```

配置快照、缓存元数据这类"写一次读一万次"的数据，RwLock 比 Mutex 吞吐高一截。`lockUncancelable` 是无取消点版本（简单场景语义更直白；`lock(io)` 返回 `Cancelable!void`，配合取消机制用）。

## 31.4 条件变量：有界队列的生产者-消费者

```zig
fn submit(self: *Pool, job: Job) !void {
    self.lock.lockUncancelable(self.io);
    while (self.count == QUEUE_CAP)                       // 满：等消费者腾位
        self.not_full.waitUncancelable(self.io, &self.lock);
    // 入队 ...
    self.not_empty.signal(self.io);
    self.lock.unlock(self.io);
}
```

`wait` 三件套纪律：**在持锁状态下判断条件**（防唤醒与判断之间被插队）、**while 循环重判**（防虚假唤醒）、signal 可以持锁（实现会处理）。队列满时生产者阻塞 = 天然**背压**——上游慢下来，而不是内存被无限堆爆。

## 31.5 线程池 + 哨兵关停

固定 worker 从队列取活儿；关停时每个 worker 投一个哨兵 job（`slot = null`），worker 见哨兵即 return——**不设 closed 标志、不强杀线程**，队列里排在前面的活儿自然干完。正确性验证：任务结果按下标落位（不比到达顺序），join 后与串行基线全等。

## 31.6 坑位清单

1. **持锁 join 是自锁经典**（本章实测现场）：放哨兵后必须**先解锁再 join**——worker 醒来要拿锁才能吃哨兵，你却攥着锁等它退出。死锁三小时定律：先查谁攥着锁等谁。
2. **`std.Thread.Mutex` 在 0.16 没了**：全部换成 `std.Io.Mutex`（`.init` 常量、方法带 io）——本教程最大的一次"网上资料全过时"现场。
3. **锁原语别在 `std.testing.io` 上多线程用**：实测 Condition 等待挂死（test runner 的 Io.Threaded 初始化不完整）；测试只测原子与纯函数，锁编排放 main 的 `init.io`（19 章同款取舍）。
4. **`@intCast` 需要可推断的结果类型**：`@intCast(i) * 7 - 3` 裸用编译错——套 `@as(i64, @intCast(i))`。
5. **u64 混合值相加会溢出 panic**：Debug 构建整数溢出直接崩——确定性哈希之类的演示求和用 `+%` 环绕加（本章实测现场）。

---

上一章：[30 HTTP 服务与客户端](30-http.md) · 下一章：[32 SQLite 实战](32-sqlite.md)
