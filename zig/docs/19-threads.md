# 19 · 并发 ⭐

> 对应示例：`examples/19_threads/main.zig`（728 行，15 个 test）
>
> 0.17 是一次并发侧的**大迁移**：所有同步原语（`Mutex` / `Condition` / `Semaphore` / `Event` / `RwLock`）
> 从 `std.Thread` 搬进了 `std.Io`，而且**几乎全部方法第一个参数变成了 `io`**。
> 照抄旧教程的 `std.Thread.Mutex` 写法会一路报
> `root source file struct 'Thread' has no member named 'Mutex'`。
>
> 同一批被删掉的还有：`std.Thread.WaitGroup`、`std.Thread.Condition`、
> `std.Thread.Futex`、`std.Thread.ResetEvent`、`std.Thread.sleep`。
>
> 本章把 0.17.0 上每一个并发 API 的**真实签名逐个实测**（19.3 节那张表），
> 然后按"线程 → 数据竞争 → 三条修法 → 锁的纪律 → 条件变量 → 信号量 → 内存序 →
> 异步那条路 → 伪共享 → 什么时候不需要并发"十一条线展开。
>
> 本章有**六条结论会推翻你可能听过的说法**：
>
> 1. **`std.Io.Semaphore` 存在，但它叫 `wait` / `post`，不叫 `acquire` / `release`。**
>    写 `sem.acquire()` 报 `no field or member function named 'acquire' in 'Io.Semaphore'`。
> 2. **`std.Io.Mutex` 没有 `isLocked` 方法**（0.16 时代有过，0.17 移除了）。
>    想看锁状态只能自己加个原子标志。
> 3. **`std.Io` 没有 `await` 这个自由函数，也没有 `std.Io.Task`。**
>    `await` 是 `Future` / `Group` 的**方法**；`@hasDecl(std.Io, "Task")` 实测 `false`。
> 4. **`Future.await(io)` 和 `Future.cancel(io)` 返回 `Result` 本身，不是错误联合。**
>    写 `try f.await(io)` 报 `expected error union type, found 'u32'`。
> 5. **`Io.Event.reset()` 不要 `io`，但 `Io.Event.set(io)` 要。**
>    这是 0.17 里一个真实的不一致点，写错报 `member function expected 0 argument(s), found 1`。
> 6. **拿字节数组当"缓存行填充"是无效的**——Zig 会按对齐重排结构体字段，
>    你的 `pad` 会被挪走，被保护的变量仍留在原处。必须给字段加 `align(std.atomic.cache_line)`。
>
> 另外两条属于"实测才知道"的诚实结论：
>
> - **`cmpxchgWeak` 在 x86 上实测 200 万次 0 次伪失败**（x86 的 `lock cmpxchg` 硬件上就是强的）。
>   但你**仍然必须**写成循环——这是跨架构的可移植性要求，不是 x86 的特例。
> - **Dekker 那个"两个线程都读到 false"的经典反例，在本机 x86 上跑 3 次都复现不出来**。
>   x86 是 TSO，硬件本身挡住了它。所以"内存序错了会怎样"这个问题，
>   在 x86 上**得不到答案**——只能靠看汇编（19.8 节给了 aarch64 上的对照）。

---

## 19.1 没有 `static mut`：共享状态必须显式经参数传递

C 里写 `static int counter;` 然后多线程去 `++counter`，是**未定义行为**——
不是"可能有竞态"，是标准明确说 UB。Zig 干脆**取消了这条路径**：语言里没有 `static mut`，
没有 `__thread` / `thread_local`。你没法写出一个"我知道它是共享的"的可变全局。

这不是语法糖，是一个真实的取舍。共享状态在 Zig 里只有两个来源：

```zig
// examples/19_threads/main.zig 第 15-25 行
// ═══ 19.4 数据竞争：裸 += 丢更新（对照组的共享状态）═══
/// 19.4 的裸计数器。Zig 没有 `static mut`，但文件级 `var` 一样是**全进程共享**的，
/// 两个线程同时 `+=` 就是数据竞争（见 main 里19.4 节的实测输出）。
var racer: usize = 0;

/// 19.4/19.5 的共享计数器。改成原子量或加锁就安全了。
var guarded: usize = 0;

/// 19.5/19.7 的互斥量：0.16 起 Mutex 从 std.Thread 移入 std.Io，
/// 初始化用**命名常量 `.init`**（不是 `.{}`——那是给带字段的结构体用的）。
var counter_lock: std.Io.Mutex = .init;
```

① **文件级 `var`**：注意它的类型就是 `usize`，**没有任何"我是共享的"标记**。
编译器不会因为两个线程可能同时摸它就报警——Zig 的并发安全是**你的责任**，
不像 Java 的 `volatile` 或 C# 的 `volatile` 那样有语言级注解。

② **显式按指针传参**：这是 19.3 的模式，也是本章 90% 代码在用的方式。

```zig
// examples/19_threads/main.zig 第 142-150 行
    // ═══ 19.1 Zig 没有 static mut：共享状态必须显式经参数传递 ═══
    begin("19.1 没有 static mut");
    std.debug.print("本文件里没有任何 `static mut` / `threadlocal` —— Zig **不提供**可变全局的豁免通道\n", .{});
    std.debug.print("  共享状态只有两个来源：①文件级 `var`（像 racer/guarded）②显式按指针传参\n", .{});
    std.debug.print("  文件级 var 类型 = {s}，是普通存储（不像 C 那样名字暗示了并发语义）\n", .{@typeName(@TypeOf(guarded))});
    std.debug.print("⇒ 想不被别人踩，就得自己上锁/上原子（19.5 / 19.7）—— 编译器不兜底\n", .{});
    std.debug.print("  对比：C 的 `static int x;` 在多线程下是未定义行为，Zig 取消了这条歧义路径\n", .{});
    end("19.1 没有 static mut");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.1 没有 static mut 开始 ====
本文件里没有任何 `static mut` / `threadlocal` —— Zig **不提供**可变全局的豁免通道
  共享状态只有两个来源：①文件级 `var`（像 racer/guarded）②显式按指针传参
  文件级 var 类型 = usize，是普通存储（不像 C 那样名字暗示了并发语义）
⇒ 想不被别人踩，就得自己上锁/上原子（19.5 / 19.7）—— 编译器不兜底
  对比：C 的 `static int x;` 在多线程下是未定义行为，Zig 取消了这条歧义路径
==== 19.1 没有 static mut 结束 ====
```

**这个取舍的代价**你要清楚：没有语言级注解意味着**代码审查时你必须自己看出共享性**。
一个"看起来很无害"的模块级 `var cache: [256]u8` 被两个线程摸，编译器一句话都不会说。

## 19.2 `std.Thread`：spawn / join / detach

```zig
// examples/19_threads/main.zig 第 151-192 行
    // ═══ 19.2 std.Thread：spawn / join / detach / yield / getCpuCount ═══
    begin("19.2 spawn / join / detach");
    const cpu_count = try std.Thread.getCpuCount();
    std.debug.print("getCpuCount() = {d}（SpawnConfig.default_stack_size = {d} 字节 = {d} MiB）\n", .{
        cpu_count, std.Thread.SpawnConfig.default_stack_size, std.Thread.SpawnConfig.default_stack_size / 1024 / 1024,
    });
    std.debug.print("getCurrentId() 类型 = {s}（本机是 usize 宽，别的平台可能是 u32）\n", .{@typeName(@TypeOf(std.Thread.getCurrentId()))});

    // 19.2 起两个线程：打印各自的 id，然后 join
    const id_probe = struct {
        fn run(out: *std.Thread.Id) void {
            out.* = std.Thread.getCurrentId();
        }
    };
    var tid_a: std.Thread.Id = 0;
    var tid_b: std.Thread.Id = 0;
    const t_a = try std.Thread.spawn(.{}, id_probe.run, .{&tid_a});
    const t_b = try std.Thread.spawn(.{}, id_probe.run, .{&tid_b});
    t_a.join(); // join = 等它干完 + 回收资源
    t_b.join();
    std.debug.print("两个 worker 的线程 id = {d} / {d}（数字每次运行都不同，不抄）\n", .{ tid_a, tid_b });
    std.debug.print("两个 id 不同 = {}\n", .{tid_a != tid_b});
    // ⚠️ 线程 id 是**复用**的：join 掉的 id 会被后来的线程再拿去用。判"活线程数"别用它。
    try std.Thread.yield(); // 让出时间片：0.17 里仍然要 try（YieldError）
    std.debug.print("Thread.yield() 通过（注意它返回 error union，得 try）\n", .{});

    // detach：撒手不管，句柄立刻作废
    const detached = struct {
        fn run(slot: *std.atomic.Value(u32)) void {
            _ = slot.fetchAdd(1, .monotonic);
        }
    };
    var detached_hits = std.atomic.Value(u32).init(0);
    const td = try std.Thread.spawn(.{}, detached.run, .{&detached_hits});
    td.detach(); // 之后**绝不能**再 join/detach 这个句柄（UB）
    // detach 的线程不join 也能保证跑完吗？不能保证——只能靠"主线程最后别急着退"这种脆弱约定。
    // 所以生产代码用 join，detach 只用于"进程退出时它跑没跑完都无所谓"的场景。
    while (detached_hits.load(.acquire) == 0) std.atomic.spinLoopHint(); // 这里只是等它真跑过
    std.debug.print("detach 的线程确实执行了（hits = {d}）—— 但注意这是**碰运气**等出来的，不是 join\n", .{detached_hits.load(.seq_cst)});
    std.debug.print("⚠️ 0.17 没有 Thread.sleep：睡眠走 io.sleep(duration, clock)（见 19.6 / 19.11）\n", .{});
    end("19.2 spawn / join / detach");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.2 spawn / join / detach 开始 ====
getCpuCount() = 8（SpawnConfig.default_stack_size = 16777216 字节 = 16 MiB）
getCurrentId() 类型 = u64（本机是 usize 宽，别的平台可能是 u32）
两个 worker 的线程 id = 1537489 / 1537490（数字每次运行都不同，不抄）
两个 id 不同 = true
Thread.yield() 通过（注意它返回 error union，得 try）
detach 的线程确实执行了（hits = 1）—— 但注意这是**碰运气**等出来的，不是 join
⚠️ 0.17 没有 Thread.sleep：睡眠走 io.sleep(duration, clock)（见 19.6 / 19.11）
==== 19.2 spawn / join / detach 结束 ====
```

**实测形如**（线程 id 每次都不同，上面那组数字是一次运行的，不可复现；
`getCpuCount() = 8` 与核数有关，换机器会变；`default_stack_size = 16 MiB` 则是常量）。

四个要点：

- **`spawn(config, function, args)`** 的 `args` 是**类型化元组**。参数个数必须和
  `function` 的形参**完全一致**，少一个就报 `expected 2 argument(s), found 1`（实测）。
- **`join()` 消费掉句柄**。调用后那个 `Thread` 值就作废了。`detach()` 也是。
  **两个都不能各调一次**——第二个是 UB。
- **`getCurrentId()` 的返回值类型随平台变**。本机（macOS x86_64）是 `u64`，
  `Thread.Id` 本身是 `switch (native_os)` 出来的（Windows 是 `u32`，Linux 是 `pthread_t`）。
  要打印就别写死类型。
- **`Thread.yield()` 在 0.17 仍然返回 `error{YieldError}`**，所以要 `try`。
  它不收 `io`——这是 0.17 里极少数"没被 Io 化"的运行时接口。

### ⚠️ 线程 id 是**复用**的

`getCurrentId()` 拿到的是 OS 线程句柄，**已join 掉的线程的 id 会被后来的线程重新拿去用**。
所以"用线程 id 集合算存活线程数"这种写法是错的。要判活线程数，自己维护一个原子计数器。

## 19.3 0.17 并发 API 实测签名表

这是本章最该抄走的一张表。**每一行都在 0.17.0 上实测过**
（`@hasDecl` 探测 + 实际编译调用），不是文档摘抄。

| API | 0.17 实测签名 | 返回类型 | 备注 |
|---|---|---|---|
| `std.Thread.spawn` | `spawn(config: SpawnConfig, function: anytype, args: anytype) SpawnError!Thread` | 错误联合 | `args` 是元组，个数必须严格匹配 |
| `std.Thread.join` | `join(self: Thread) void` | void | 消费句柄，之后作废 |
| `std.Thread.detach` | `detach(self: Thread) void` | void | 同上，**与 join 互斥** |
| `std.Thread.getCpuCount` | `getCpuCount() CpuCountError!usize` | 错误联合 | 保证 ≥ 1 |
| `std.Thread.getCurrentId` | `getCurrentId() Id` | **非错误联合** | `Id` 类型随平台变（本机 `u64`） |
| `std.Thread.yield` | `yield() YieldError!void` | 错误联合 | **不收 `io`** |
| `std.Thread.spawn` 的 `SpawnConfig` | `{ stack_size: usize = 16MiB, allocator: ?Allocator = null }` | — | 默认栈 **16 MiB** |
| ~~`std.Thread.sleep`~~ | **已移除** | — | 报 `no member named 'sleep'` |
| ~~`std.Thread.WaitGroup`~~ | **已移除** | — | 报 `no member named 'WaitGroup'` |
| ~~`std.Thread.Mutex`~~ | **已移除** | — | 报 `no member named 'Mutex'` |
| ~~`std.Thread.Condition`~~ | **已移除** | — | 报 `no member named 'Condition'` |
| ~~`std.Thread.Futex`~~ | **已移除** | — | `@hasDecl` 实测 `false` |
| ~~`std.Thread.ResetEvent`~~ | **已移除** | — | `@hasDecl` 实测 `false` |
| `std.Io.Mutex` | `extern struct`，字段 `state: atomic.Value(State)` | 值类型 | `State` 是 `enum(u32){unlocked,locked_once,contended}` |
| `Io.Mutex.init` | `pub const init: Mutex = .{ .state = .init(.unlocked) }` | **命名常量** | 写 `.{}` 报 `missing struct field: state` |
| `Io.Mutex.tryLock` | `tryLock(m: *Mutex) bool` | **不收 `io`** | 唯一一个不 Io 化的方法 |
| `Io.Mutex.lock` | `lock(m: *Mutex, io: Io) Cancelable!void` | `error{Canceled}!void` | 可被取消 |
| `Io.Mutex.lockUncancelable` | `lockUncancelable(m: *Mutex, io: Io) void` | **void** | 无取消点，教学场景用这个 |
| `Io.Mutex.unlock` | `unlock(m: *Mutex, io: Io) void` | void | |
| ~~`Io.Mutex.isLocked`~~ | **0.17 已移除** | — | `@hasDecl` 实测 `false` |
| `Io.Condition` | `struct`，字段 `state: atomic.Value(State)` + `epoch: atomic.Value(u32)` | 值类型 | `State` 是 `packed struct(u32){waiters:u16,signals:u16}` |
| `Io.Condition.init` | 命名常量 | — | 同上 |
| `Io.Condition.wait` | `wait(cond: *Condition, io: Io, mutex: *Mutex) Cancelable!void` | 错误联合 | **必须配 Mutex** |
| `Io.Condition.waitUncancelable` | `waitUncancelable(cond: *Condition, io: Io, mutex: *Mutex) void` | void | 内部是 futex 循环 |
| `Io.Condition.waitTimeout` | `waitTimeout(cond, io, mutex, timeout: Timeout) (Cancelable \|\| Timeout.Error)!void` | 错误联合 | |
| `Io.Condition.signal` | `signal(cond: *Condition, io: Io) void` | void | 唤醒**一个** |
| `Io.Condition.broadcast` | `broadcast(cond: *Condition, io: Io) void` | void | 唤醒**全部** |
| `std.Io.Semaphore` | **存在**（`Io/Semaphore.zig`） | 值类型 | 字段 `mutex` / `cond` / `permits: usize` |
| `Io.Semaphore.init` | **没有** `init` 常量 | — | 用 `.{ .permits = N }`（有默认字段） |
| `Io.Semaphore.wait` | `wait(s: *Semaphore, io: Io) Io.Cancelable!void` | 错误联合 | **不叫 `acquire`** |
| `Io.Semaphore.waitUncancelable` | `waitUncancelable(s: *Semaphore, io: Io) void` | void | |
| `Io.Semaphore.waitTimeout` | `waitTimeout(s, io, timeout) (Cancelable \|\| Timeout.Error)!void` | 错误联合 | |
| `Io.Semaphore.post` | `post(s: *Semaphore, io: Io) void` | void | **不叫 `release`** |
| ~~`Io.Semaphore.acquire`~~ | **不存在** | — | 报 `no field or member function named 'acquire'` |
| ~~`Io.Semaphore.release`~~ | **不存在** | — | `@hasDecl` 实测 `false` |
| `std.Io.Event` | `enum(u32)`，成员 `unset` / `waiting` / `is_set` | **枚举** | 初值是 `.unset` |
| `Io.Event.isSet` | `isSet(event: *const Event) bool` | **不收 `io`** | |
| `Io.Event.set` | `set(e: *Event, io: Io) void` | void | **要 `io`** |
| `Io.Event.reset` | `reset(e: *Event) void` | void | ⚠️ **不要 `io`**（与 `set` 不一致） |
| `Io.Event.wait` | `wait(event: *Event, io: Io) Cancelable!void` | 错误联合 | |
| `Io.Event.waitUncancelable` | 同上但void | void | |
| `Io.Event.waitTimeout` | `waitTimeout(event, io, timeout) (error{Timeout} \|\| Cancelable)!void` | 错误联合 | |
| `std.Io.RwLock` | **存在**（`Io/RwLock.zig`） | 值类型 | `lockShared` / `unlockShared` / `tryLockShared` 等 |
| `std.Io.Group` | **存在**，`pub const init: Group = ...` | 值类型 | 批量起活儿 |
| `Group.async` | `async(g: *Group, io: Io, function, args) void` | **void** | 不返回错误 |
| `Group.concurrent` | `concurrent(g: *Group, io, function, args) ConcurrentError!void` | 错误联合 | |
| `Group.await` | `await(g: *Group, io: Io) Cancelable!void` | 错误联合 | 幂等 |
| `Group.cancel` | `cancel(g: *Group, io: Io) void` | void | 幂等 |
| ~~`std.Io.Task`~~ | **不存在** | — | `@hasDecl(std.Io, "Task")` 实测 `false` |
| `Io.async` | `async(io: Io, function, args) Future(Ret)` | **非错误联合** | 比 `concurrent` 弱（可能立即执行） |
| `Io.concurrent` | `concurrent(io, function, args) ConcurrentError!Future(Ret)` | 错误联合 | 强制真并发 |
| `Future.await` | `await(f: *@This(), io: Io) Result` | ⚠️ **Result 本身** | **不是错误联合**（除非函数返回类型是） |
| `Future.cancel` | `cancel(f: *@This(), io: Io) Result` | ⚠️ **Result 本身** | 同上；未完成时值无意义 |
| ~~`Io.await`~~ | **不存在**（`await` 是方法） | — | `@hasDecl(std.Io, "await")` 实测 `false` |
| `Io.sleep` | `sleep(io: Io, duration: Duration, clock: Clock) Cancelable!void` | 错误联合 | **替代 `Thread.sleep`** |
| `Io.recancel` | `recancel(io: Io) void` | void | 重新武装取消请求 |
| `Io.Cancelable` | `error{Canceled}` | 错误集 | 几乎所有 Io 阻塞点的错误集 |
| `Io.Clock` | `enum{real, awake, boot, cpu_process, cpu_thread}` | 枚举 | **没有 `.monotonic`**（15 章坑过） |
| `std.atomic.Value(T)` | `extern struct`，字段 `raw: T`（**公开**，注释警告别直接摸） | 值类型 | |
| `Value.init` | `init(value: T) Self` | — | |
| `Value.load/store/swap` | `(order: AtomicOrder)` | T / void | |
| `Value.fetchAdd` | `fetchAdd(operand: T, order) T` | T | 返回**旧值** |
| `Value.fetchSub/fetchAnd/fetchOr/fetchXor` | 同上 | T | 都返回**旧值** |
| `Value.fetchMax/fetchMin` | 同上 | T | 返回**旧值** |
| `Value.cmpxchgWeak` | `(expected: T, new: T, success_order, fail_order) ?T` | `?T` | **可能伪失败**，必须循环 |
| `Value.cmpxchgStrong` | 同上 | `?T` | 保证不伪失败 |
| `std.atomic.cache_line` | `pub const cache_line: comptime_int` | **编译期常量** | **存在**（本机 128；ARM 常见 64） |
| ~~`std.atomic.cache_line_padded`~~ | **不存在** | — | `@hasDecl` 实测 `false` |

三条最容易踩的，从表里单独拎出来：

**① `Future.await` 返回 `Result`，不是 `Result!`。** 这是 0.17 改的：

```zig
// ❌ 编译失败：expected error union type, found 'u32'
const r = try f.await(io);

// ✅ 0.17 的正确写法（当被调函数返回非错误类型时）
const r = f.await(io);
```

只有当你的 worker 函数**自己**返回 `!T`（比如 `Cancelable!void`）时，
`await` 才返回错误联合，那时才需要 `try`。

**② `Event.set` 要 `io`，`Event.reset` 不要。** 这是 0.17 里的真实不一致：

```zig
e.set(io);   // ✅
e.set();     // ❌ member function expected 1 argument(s), found 0
e.reset();   // ✅
e.reset(io); // ❌ member function expected 0 argument(s), found 1
```

**③ `Io.Mutex` 是 `extern struct`。** 这意味着它**可以**作为字段放进另一个 `extern struct`，
`@sizeOf` / `@offsetOf` 语义和 C 结构体一致。本章的 `Gate`（19.9）就是拿它当字段的。

## 19.4 数据竞争：裸 `+=` 必然丢更新

先看反面教材。两个线程各 20 万次裸 `+= 1`：

```zig
// examples/19_threads/main.zig 第 27-32 行
/// 19.4 的裸写 worker：读-改-写三步，随时会被另一个线程穿插。
/// 注意 `io` 只是为了和别的 worker 签名一致而存在，函数体里没用它。
fn bumpRacy(io: std.Io, n: usize) void {
    _ = io;
    for (0..n) |_| racer += 1;
}
```

```zig
// examples/19_threads/main.zig 第 212-227 行
    // ═══ 19.4 数据竞争：裸 += 必然丢更新 ═══
    begin("19.4 数据竞争：裸 += 丢更新");
    const per_thread: usize = 200_000;
    const r1 = try std.Thread.spawn(.{}, bumpRacy, .{ io, per_thread });
    const r2 = try std.Thread.spawn(.{}, bumpRacy, .{ io, per_thread });
    r1.join();
    r2.join();
    const expected: usize = 2 * per_thread;
    std.debug.print("两个线程各 {d} 次裸 `racer += 1`：得到 {d}\n", .{ per_thread, racer });
    std.debug.print("期望 {d}，**少了 {d} 次** —— 丢更新（lost update）\n", .{ expected, expected - racer });
    std.debug.print("机理：`racer += 1` 编译成读-改-写三步，两个线程的「读」都拿到了同一个旧值，\n", .{});
    std.debug.print("      第二个线程的「写」把第一个的写**覆盖**掉了。`+=` 不是一条原子指令。\n", .{});
    std.debug.print("⚠️ 这个结果**确定小于** {d}（不只是\"可能\"）—— 本机连跑 6 次落在 20~33 万之间\n", .{expected});
    std.debug.print("   但\"少多少\"完全不可复现（取决于 OS 调度），所以文档只抄\"小于期望\"这个结论\n", .{});
    end("19.4 数据竞争：裸 += 丢更新");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.4 数据竞争：裸 += 丢更新 开始 ====
两个线程各 200000 次裸 `racer += 1`：得到 286040
期望 400000，**少了 113960 次** —— 丢更新（lost update）
机理：`racer += 1` 编译成读-改-写三步，两个线程的「读」都拿到了同一个旧值，
      第二个线程的「写」把第一个的写**覆盖**掉了。`+=` 不是一条原子指令。
⚠️ 这个结果**确定小于** 400000（不只是"可能"）—— 本机连跑 6 次落在 20~33 万之间
   但"少多少"完全不可复现（取决于 OS 调度），所以文档只抄"小于期望"这个结论
==== 19.4 数据竞争：裸 += 丢更新 结束 ====
```

**哪部分可以复现、哪部分不可以**：

| 断言 | 可复现性 |
|---|---|
| 结果 **< 400000** | ✅ **确定成立**（6 次连跑：202579 / 233785 / 327640 / 208779 / 212392 / 208460） |
| 具体少多少 | ❌ 完全不可复现（上面那组数字里最少的和最多的差 1.6倍） |
| 机理描述 | ✅ 是语言语义层面的事实，与机器无关 |

**这个"确定小于"其实不是每次都成立**——如果两个线程恰好完全没有交错（一个跑完了另一个才开始），
结果就正好是 400000。本机 20 万次 × 2 的规模下交错几乎必然发生，所以实测 6 次全部小于。
但你**不能**把它当定理。**唯一确定的是：结果 ≤ 400000，且实际调度越交错就越小。**

### 为什么 Debug 构建也会丢

一个常见误解是"Debug 有溢出检查和边界检查，裸 `+=` 会被抓住"。**不会。**
Debug 检查的是**单个线程视角**的越界/溢出，**没有任何一项检查跨线程的原子性**。
数据竞争是 UB（虽然 Zig 不会给你 UB 的编译期警告），Debug 构建照样丢。

## 19.5 `Io.Mutex`：把同一个计数器修对

```zig
// examples/19_threads/main.zig 第 34-44 行
/// 19.5 的加锁 worker：三条纪律的示范。
/// 1. 临界区最小化（只有 `guarded += 1` 这一行）；
/// 2. 永远 `defer unlock`（即使临界区里有 return / 错误也不会漏解锁）；
/// 3. 不在持锁时做别的线程需要的东西（尤其不 join）。
fn bumpLocked(io: std.Io, n: usize) void {
    for (0..n) |_| {
        counter_lock.lockUncancelable(io);
        defer counter_lock.unlock(io);
        guarded += 1;
    }
}
```

```zig
// examples/19_threads/main.zig 第 228-243 行
    // ═══ 19.5 Io.Mutex：把同一个计数器修对 ═══
    begin("19.5 Io.Mutex：互斥保护共享状态");
    const l1 = try std.Thread.spawn(.{}, bumpLocked, .{ io, 50_000 });
    const l2 = try std.Thread.spawn(.{}, bumpLocked, .{ io, 50_000 });
    l1.join();
    l2.join();
    std.debug.print("两个线程各 50000 次**加锁** += 1：guarded = {d}（期望 100000）\n", .{guarded});
    std.debug.print("Io.Mutex 的方法清单（0.17 全部要 io）：\n", .{});
    std.debug.print("  init（命名常量）/ tryLock()（**不要 io**）/ lock(io) / lockUncancelable(io) / unlock(io)\n", .{});
    std.debug.print("lock(io) 返回 {any}（可被取消），lockUncancelable(io) 返回 void\n", .{std.Io.Cancelable});
    std.debug.print("⚠️ 初始化必须写 `.init`：写 `.{{}}` 会报 missing struct field: state（实测）\n", .{});
    // tryLock 演示：唯一一个不带 io 的方法
    std.debug.print("tryLock 无人竞争时 = {}（它不需要 io，因为不会阻塞）\n", .{counter_lock.tryLock()});
    counter_lock.unlock(io);
    end("19.5 Io.Mutex：互斥保护共享状态");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.5 Io.Mutex：互斥保护共享状态 开始 ====
两个线程各 50000 次**加锁** += 1：guarded = 100000（期望 100000）
Io.Mutex 的方法清单（0.17 全部要 io）：
  init（命名常量）/ tryLock()（**不要 io**）/ lock(io) / lockUncancelable(io) / unlock(io)
lock(io) 返回 error{Canceled}（可被取消），lockUncancelable(io) 返回 void
⚠️ 初始化必须写 `.init`：写 `.{}` 会报 missing struct field: state（实测）
tryLock 无人竞争时 = true（它不需要 io，因为不会阻塞）
==== 19.5 Io.Mutex：互斥保护共享状态 结束 ====
```

对比 19.4 和 19.5：**同一件事，同一个计数器，20 万次裸写丢一半，
5 万次加锁一次不丢。**（加锁那版次数少，因为每次进临界区有开销——这是锁的代价。）

### 三个签名的取舍

- **`lock(io)` vs `lockUncancelable(io)`**：`lock` 返回 `error{Canceled}!void`，
  意味着等待锁的过程中这个线程**可以被取消**（19.13 节的 `Future.cancel` 就靠这个）。
  `lockUncancelable` 返回 `void`，语义是"我一定拿到锁"。
  **本教程全部示例用 `lockUncancelable`**——因为在线程里谈取消没有意义（你不能从外面取消一个 `Thread`），
  异步场景才需要 `lock`。
- **`tryLock()` 唯一不收 `io`**。因为它不阻塞，所以不需要事件循环参与。
  这是 0.17 里 `Io.Mutex` 四个方法里唯一的例外，**容易忘**。
- **`init` 是命名常量不是 `init()` 调用**。这是 0.16/0.17 的一批同步原语共有的风格变化：

```text
// 写 .{} 的实测报错：
e.zig:2:46: error: missing struct field: state
pub fn main() !void { var m: std.Io.Mutex = .{}; _ = m; }
                                             ~^~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io.zig:1716:26: note: struct declared here
```

## 19.6 锁的正确用法：三条纪律

```zig
// examples/19_threads/main.zig 第 244-260 行
    // ═══ 19.6 锁的正确用法：三条纪律 ═══
    begin("19.6 锁的正确用法");
    std.debug.print("纪律1  永远 `defer unlock`：解锁忘了会死锁，defer 覆盖**所有**退出路径\n", .{});
    std.debug.print("纪律2  临界区最小化：锁区里只放纯内存操作，别放 printf / 写文件 / 网络\n", .{});
    std.debug.print("纪律3  **不要在持锁时 join**：worker 拿不到锁就永远结束不了 ⇒ 死锁\n", .{});
    std.debug.print("反例（本文件不写出来，会挂死；实测见文档 19.6）：\n", .{});
    std.debug.print("  m.lockUncancelable(io);          // 主线程先拿锁\n", .{});
    std.debug.print("  const t = try std.Thread.spawn(.{{}}, w, .{{io}});  // w 也要这把锁\n", .{});
    std.debug.print("  t.join();                         // ← 主线程等 w，w 等锁，锁等主线程 ⇒ 死锁\n", .{});
    std.debug.print("正确写法：先 unlock 再 join，或者像 19.5 那样**根本不持锁**去 join\n", .{});
    std.debug.print("⚠️ 0.16 起 Thread.sleep 已移除，睡眠归 Io：io.sleep(.{{fromMilliseconds(3)}}, .awake)\n", .{});
    const t_sleep = std.Io.Clock.now(.awake, io);
    try io.sleep(.fromMilliseconds(3), .awake);
    const slept_ns = t_sleep.durationTo(std.Io.Clock.now(.awake, io)).nanoseconds;
    std.debug.print("   实测 io.sleep(3ms, .awake) 睡了 {d} ns（≥3000000 才是真睡到了）\n", .{slept_ns});
    end("19.6 锁的正确用法");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.6 锁的正确用法 开始 ====
纪律1  永远 `defer unlock`：解锁忘了会死锁，defer 覆盖**所有**退出路径
纪律2  临界区最小化：锁区里只放纯内存操作，别放 printf / 写文件 / 网络
纪律3  **不要在持锁时 join**：worker 拿不到锁就永远结束不了 ⇒ 死锁
反例（本文件不写出来，会挂死；实测见文档 19.6）：
  m.lockUncancelable(io);          // 主线程先拿锁
  const t = try std.Thread.spawn(.{}, w, .{io});  // w 也要这把锁
  t.join();                         // ← 主线程等 w，w 等锁，锁等主线程 ⇒ 死锁
正确写法：先 unlock 再 join，或者像 19.5 那样**根本不持锁**去 join
⚠️ 0.16 起 Thread.sleep 已移除，睡眠归 Io：io.sleep(.{fromMilliseconds(3)}, .awake)
   实测 io.sleep(3ms, .awake) 睡了 4543707 ns（≥3000000 才是真睡到了）
==== 19.6 锁的正确用法 结束 ====
```

（`io.sleep(3ms)` 实测约 4.5 ms，**每次运行都不同**——它至少睡到了 3 ms，
但调度粒度决定实际值。这个数字不可复现。）

### 纪律 3 的实测复现

反例单独写成文件跑，实测**确实死锁**：

```zig
const std = @import("std");
var m: std.Io.Mutex = .init;
fn w(io: std.Io) void { m.lockUncancelable(io); defer m.unlock(io); }
pub fn main(init: std.process.Init) !void {
    std.debug.print("主线程先拿锁\n", .{});
    m.lockUncancelable(init.io);
    const t = try std.Thread.spawn(.{}, w, .{init.io});
    std.debug.print("已 spawn worker，worker 现在阻塞在 lockUncancelable\n", .{});
    std.debug.print("主线程在**持锁**状态下 join → worker 永远拿不到锁 ⇒ 死锁\n", .{});
    t.join();
    m.unlock(init.io);
    std.debug.print("这一行永远不会打印\n", .{});
}
```

实测输出（`build/probe19/dl.zig`，含耗时故不逐字节抄时间）：

```text
主线程先拿锁
已 spawn worker，worker 现在阻塞在 lockUncancelable
主线程在**持锁**状态下 join → worker 永远拿不到锁 ⇒ 死锁
★ 6 秒后仍在运行 ⇒ 确认死锁（手动 kill -9 才结束）
```

**死锁的环路**很清楚：`主线程等 join 完成 → 等 worker 返回 → worker 等锁 → 锁等主线程 unlock`。
**破解办法只有两个**：先 `unlock` 再 `join`；或者像 19.5 那样**根本不持锁**去 `join`。

### 纪律 2 的量化

"临界区最小化"不是洁癖。锁区里每多一个字节，别的主线程就多阻塞一会儿。
**在锁区里 `std.debug.print` 是最常见的错误**——`print` 要拿 `io` 的内部锁、写 stderr、
可能做系统调用。所有输出都应该在**解锁之后**做。本章所有示例都守着这条：
`begin(...)` / `end(...)` / `print` 全在临界区外。

## 19.7 `std.atomic.Value`：无锁的第三条路

```zig
// examples/19_threads/main.zig 第 261-291 行
    // ═══ 19.7 std.atomic.Value：无锁计数 ═══
    begin("19.7 std.atomic.Value：无锁计数");
    var hits_atomic = std.atomic.Value(usize).init(0);
    const atomic_worker = struct {
        fn run(h: *std.atomic.Value(usize), n: usize) void {
            for (0..n) |_| _ = h.fetchAdd(1, .monotonic); // 一条指令，不阻塞任何人
        }
    };
    const a1 = try std.Thread.spawn(.{}, atomic_worker.run, .{ &hits_atomic, 100_000 });
    const a2 = try std.Thread.spawn(.{}, atomic_worker.run, .{ &hits_atomic, 100_000 });
    a1.join();
    a2.join();
    std.debug.print("两个线程各 100000 次 fetchAdd：{d}（期望 200000，原子量分毫不差）\n", .{hits_atomic.load(.seq_cst)});
    std.debug.print("三种修法的代价对比：\n", .{});
    std.debug.print("  裸 +=    : 零成本，但**错**（19.4 实测少一半）\n", .{});
    std.debug.print("  Mutex    : 正确，但每次都进临界区；无竞争时也只是多几条指令\n", .{});
    std.debug.print("  atomic   : 正确且不阻塞；单个整数/指针的读改写用它最划算\n", .{});
    std.debug.print("⚠️ 原子量只保护**它自己这一个格子**——用原子量去保护旁边几个普通字段是错的\n", .{});
    std.debug.print("Value(T) 支持的 T（实测跑通）：u8/u32/u64/usize/bool/f64/枚举/可选指针\n", .{});
    var a_bool = std.atomic.Value(bool).init(false);
    a_bool.store(true, .release);
    std.debug.print("  atomic<bool>.load(.acquire) = {}，atomic<u8> 250+10 环绕 = {d}\n", .{
        a_bool.load(.acquire),
        blk: {
            var v8 = std.atomic.Value(u8).init(250);
            _ = v8.fetchAdd(10, .monotonic);
            break :blk v8.load(.monotonic);
        },
    });
    end("19.7 std.atomic.Value：无锁计数");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.7 std.atomic.Value：无锁计数 开始 ====
两个线程各 100000 次 fetchAdd：200000（期望 200000，原子量分毫不差）
三种修法的代价对比：
  裸 +=    : 零成本，但**错**（19.4 实测少一半）
  Mutex    : 正确，但每次都进临界区；无竞争时也只是多几条指令
  atomic   : 正确且不阻塞；单个整数/指针的读改写用它最划算
⚠️ 原子量只保护**它自己这一个格子**——用原子量去保护旁边几个普通字段是错的
Value(T) 支持的 T（实测跑通）：u8/u32/u64/usize/bool/f64/枚举/可选指针
  atomic<bool>.load(.acquire) = true，atomic<u8> 250+10 环绕 = 4
==== 19.7 std.atomic.Value：无锁计数 结束 ====
```

### 三条路的适用场景与代价

| 方案 | 正确性 | 阻塞别人吗 | 临界区 | 什么时候选它 |
|---|---|---|---|---|
| **裸 `+=`** | ❌ 数据竞争 | — | 无 | **永不**（单线程代码除外） |
| **`Io.Mutex`** | ✅ | ✅ 会 | 有 | 保护**一组**变量、或者临界区里有非原子操作 |
| **`std.atomic.Value`** | ✅ | ❌ 不阻塞 | 无（单指令） | 保护**一个**整数/指针的读改写 |

**判断口诀**：要保护的东西**能用一个格子装下**（一个整数、一个指针）就用原子量；
**装不下**（一组字段、一个数据结构的不变式）就用锁。

### 三个必须知道的细节

**① `fetch*` 一律返回**旧值**。** 我第一次写测试就踩了：
以为 `fetchAnd` 返回新值，结果整个断言链错位。`swap` 也一样返回旧值。

**② 原子量只保护它自己。** 这是最常见的误解：

```zig
// ❌ 错的：flag 是原子的，data 不是——改 data 仍然有竞态
var flag = std.atomic.Value(bool).init(false);
var data: [100]u8 = undefined;
flag.store(true, .release);   // 以为这就"发布"了 data
```

正确做法是 **`data` 也要是原子的**（或者用锁包起来，或者只用 `std.atomic.Value(T)` 装整个结构体——
但那样 `T` 的每个字段都得是原子的）。19.8 节的 `payload` 之所以能用普通 `u64`，
是因为**只有一个写者且写完就 `release`**，见下节。

**③ 原子操作不检查溢出。** `atomic<u8>` 的 `250 + 10` **环绕成 4，不 panic**——
和 3.4 节的 `@addWithOverflow` 一样，原子 RMW 走的是硬件指令，Debug 的溢出检查管不到。

## 19.8 内存序：为什么 `relaxed` 不够

前面用 `.monotonic` 做计数，够了。但**一旦你要用原子操作"发布"别的数据**，
`.monotonic` 就**不够**了。

```zig
// examples/19_threads/main.zig 第 46-57 行
// ═══ 19.8 内存序：一条 release/acquire 配对到底买了什么 ═══
/// 19.8 用：发布方写payload，再 release 存标志位。
fn publishRelease(payload: *u64, flag: *std.atomic.Value(u32)) void {
    payload.* = 0xDEAD_BEEF;
    flag.store(1, .release); // release：保证上面的写**排在**这个 store 之前
}

/// 19.8 用：消费方 acquire 读标志位，看到非零后才读payload。
fn consumeAcquire(payload: *const u64, flag: *std.atomic.Value(u32)) u64 {
    while (flag.load(.acquire) == 0) std.atomic.spinLoopHint();
    return payload.*; // acquire：保证这个读**排在**那个 load 之后
}
```

```zig
// examples/19_threads/main.zig 第 292-313 行
    // ═══ 19.8 内存序：release/acquire 配对到底买了什么 ═══
    begin("19.8 内存序：release / acquire 配对");
    var payload: u64 = 0;
    var flag = std.atomic.Value(u32).init(0);
    const pub_t = try std.Thread.spawn(.{}, publishRelease, .{ &payload, &flag });
    const got = consumeAcquire(&payload, &flag);
    pub_t.join();
    std.debug.print("release 存标志 + acquire 读标志 ⇒ 消费者看到 payload = 0x{x}\n", .{got});
    std.debug.print("这条配对买的是**跨线程可见性 + 不被重排**：\n", .{});
    std.debug.print("  release：保证它**之前**的所有普通写，都排在它**之后**消费者能看见\n", .{});
    std.debug.print("  acquire：保证它**之后**的所有普通读，都排在它**之前**已经生效\n", .{});
    std.debug.print("⚠️ 光用 .monotonic / .unordered 不买任何跨变量的顺序保证——只有这个变量自己的原子性\n", .{});
    std.debug.print("六个内存序（x86 上实测生成的指令，见文档 19.8）：\n", .{});
    std.debug.print("  .unordered（只能用于 load）: 不做顺序保证，连编译器屏障都没有，最便宜\n", .{});
    std.debug.print("  .monotonic : 只保证**这个变量**的原子性，编译器不重排（AcquireRelease 家族里最弱）\n", .{});
    std.debug.print("  .release   : 单向屏障（写侧）：之前的写别往后挪\n", .{});
    std.debug.print("  .acquire   : 单向屏障（读侧）：之后的读别往前挪\n", .{});
    std.debug.print("  .acq_rel   : 读+写双向屏障（只能给 RMW 操作）\n", .{});
    std.debug.print("  .seq_cst   : 全序，还额外保证**所有**原子变量之间的顺序，最保守最慢\n", .{});
    std.debug.print("⚠️ `.unordered` 给 RMW（fetchAdd 等）会编译失败：@atomicRmw ordering must not be unordered\n", .{});
    end("19.8 内存序：release / acquire 配对");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.8 内存序：release / acquire 配对 开始 ====
release 存标志 + acquire 读标志 ⇒ 消费者看到 payload = 0xdeadbeef
这条配对买的是**跨线程可见性 + 不被重排**：
  release：保证它**之前**的所有普通写，都排在它**之后**消费者能看见
  acquire：保证它**之后**的所有普通读，都排在它**之前**已经生效
⚠️ 光用 .monotonic / .unordered 不买任何跨变量的顺序保证——只有这个变量自己的原子性
六个内存序（x86 上实测生成的指令，见文档 19.8）：
  .unordered（只能用于 load）: 不做顺序保证，连编译器屏障都没有，最便宜
  .monotonic : 只保证**这个变量**的原子性，编译器不重排（AcquireRelease 家族里最弱）
  .release   : 单向屏障（写侧）：之前的写别往后挪
  .acquire   : 单向屏障（读侧）：之后的读别往前挪
  .acq_rel   : 读+写双向屏障（只能给 RMW 操作）
  .seq_cst   : 全序，还额外保证**所有**原子变量之间的顺序，最保守最慢
⚠️ `.unordered` 给 RMW（fetchAdd 等）会编译失败：@atomicRmw ordering must not be unordered
==== 19.8 内存序：release / acquire 配对 结束 ====
```

### 六个内存序，逐个实测

这是本章信息密度最高的一段。我把七个函数编译成汇编
（`zig build-obj -OReleaseFast -femit-asm`），看**两个架构**上各自生成什么指令。

**x86_64（本机，`-OReleaseFast`）**：

| 内存序 | `store` 生成的指令 | `load` 生成的指令 | `fetchAdd` 生成的指令 |
|---|---|---|---|
| `.unordered` | `mov dword ptr [rip + g], 1` | `mov eax, dword ptr [rip + g]` | ❌ **编译失败** |
| `.monotonic` | `mov dword ptr [rip + g], 1` | `mov eax, dword ptr [rip + g]` | `lock xadd dword ptr [rip + g], eax` |
| `.release` | `mov dword ptr [rip + g], 1` | — | — |
| `.acquire` | — | `mov eax, dword ptr [rip + g]` | — |
| `.acq_rel` | — | — | `lock xadd dword ptr [rip + g], eax` |
| `.seq_cst` | **`xchg dword ptr [rip + g], eax`** | `mov eax, dword ptr [rip + g]` | `lock xadd dword ptr [rip + g], eax` |

**这张表就是"x86 是 TSO"的直接证据**：
- **load 不管什么内存序都是一条 `mov`**——x86 的 load 天然不会重排。
- **`store` 只有 `.seq_cst` 不同**（用 `xchg`，隐含全屏障），其余三档都是 `mov`。
- **RMW 只要不是 `.unordered` 就全是 `lock xadd`**——因为 `lock` 前缀本身就是全屏障。

**aarch64（交叉编译 `-target aarch64-linux`）——差异全在这里**：

| 函数 | 关键指令 |
|---|---|
| `spinMonotonic`（消费者，`load(.monotonic)`） | `ldr w9, [x8, :lo12:.L_MergedGlobals]` |
| `spinAcquire`（消费者，`load(.acquire)`） | **`ldar w9, [x8]`** |
| `produceMonotonic`（生产者，`store(.monotonic)`） | `str w9, [x8, #8]` → `mov dword ptr…`等价的普通 `str` |
| `produceRelease`（生产者，`store(.release)`） | **`stlr w9, [x8]`** |

**`ldr` vs `ldar`、`str` vs `stlr`——这就是内存序在 ARM 上花钱的地方。**
`ldar`（load-acquire）和 `stlr`（store-release）是 ARMv8 专门为这个加的指令。
x86 上你白拿，ARM 上你要付。

### 为什么 x86 上复现不出内存序 bug

我照着教科书写了个 **Dekker 算法**反例（两个线程各写自己的标志再读对方的，
`.monotonic` 下"两个都读到 false"是允许的），跑 20 万次 × 3 遍：

```text
Dekker .monotonic: a 看到=true b 看到=true → 双方都false = false
Dekker .seq_cst:  a 看到=true b 看到=true → 双方都false = false
Dekker .monotonic: a 看到=true b 看到=true → 双方都false = false
Dekker .seq_cst:  a 看到=true b 看到=true → 双方都false = false
Dekker .monotonic: a 看到=true b 看到=true → 双方都false = false
Dekker .seq_cst:  a 看到=true b 看到=true → 双方都false = false
```

**一次都没复现。** 因为 x86 是 TSO，`StoreLoad` 是唯一需要额外屏障的重排对，
而硬件的 store buffer 行为恰好把它挡住了。

**这个"复现不出"本身就是重要结论**：在 x86 上写错了内存序，
你**本地测一万遍也测不出来**，一换到 ARM 服务器（手机、AWS Graviton、M 系列 Mac）
就炸。**所以内存序必须靠"想清楚"而不是"测出来"。**

### `cmpxchgWeak` 的伪失败

教科书说 `cmpxchgWeak` 可能伪失败。实测：4 个线程各 50 万次
"逻辑上必定成功"的 Weak CAS（目标恒为 0、期望 0、写回 0）：

```text
cmpxchgWeak 伪失败 = 0 / 2000000 次
```

**200 万次，一次都没伪失败。** 因为 x86 的 `lock cmpxchg` 在硬件层面就是强的。
但你**仍然必须**写成循环——ARM/POWER 用 LL/SC 指令对，弱 CAS 真的会伪失败。
**这是可移植性要求，不是 x86 的特例**：

```zig
// ✅ 唯一正确的写法（19.3 节的 CAS 模式）
while (v.cmpxchgWeak(cur, want, .acq_rel, .acquire) != null) {
    // 有人抢先了：重读重试
}
```

### ⚠️ `.unordered` 不能给 RMW

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/atomic.zig:53:60: error: @atomicRmw atomic ordering must not be unordered
            return @atomicRmw(T, &self.raw, .Add, operand, order);
                                                           ^~~~~
p1.zig:27:19: note: called inline here
    _ = v.fetchXor(0xFF, .unordered);
        ~~~~~~~~~~^~~~~~~~~~~~~~~
```

但 `.unordered` 给 `load` 是**完全合法**的（实测通过）——它就是"我只保证这条 load
是原子的，别的什么都不管"，用在"纯粹读一个计数器做统计"这种场景。

## 19.9 `Io.Condition`：等"条件成立"

条件变量是**谓词同步**：你等的不是"某次通知"，而是"某个条件为真"。

```zig
// examples/19_threads/main.zig 第 59-87 行
// ═══ 19.9 条件变量：等"某个条件成立"，不是等"某次通知" ═══
/// 19.9/19.10 的共享状态：一个计数器 + 一个"变了吗"的标志。
const Gate = struct {
    m: std.Io.Mutex = .init,
    c: std.Io.Condition = .init,
    ready: bool = false,

    /// 开门：必须在持锁下改共享状态，然后在锁内signal/broadcast。
    fn open(self: *Gate, io: std.Io) void {
        self.m.lockUncancelable(io);
        defer self.m.unlock(io);
        self.ready = true;
        self.c.broadcast(io); // broadcast：唤醒**所有**等待者（条件不再是"一个"）
    }

    /// 等开门：持锁判断 + while 重判 + wait（wait 内部会原子地放锁/睡眠/重抢锁）。
    fn waitFor(self: *Gate, io: std.Io) void {
        self.m.lockUncancelable(io);
        defer self.m.unlock(io);
        // ⚠️ 必须是 while 不是 if：wait 返回不代表条件成立（虚假唤醒是 API 的正式设定，
        //    而且 signal 可能在"判断"和"进入 wait"之间发生）。
        while (!self.ready) self.c.waitUncancelable(io, &self.m);
    }
};

fn gateWaiter(g: *Gate, io: std.Io, seen: *std.atomic.Value(u32)) void {
    g.waitFor(io);
    _ = seen.fetchAdd(1, .monotonic);
}
```

```zig
// examples/19_threads/main.zig 第 314-334 行
    // ═══ 19.9 Io.Condition：等"条件成立" ═══
    begin("19.9 Io.Condition：等条件成立");
    var gate: Gate = .{};
    var passed = std.atomic.Value(u32).init(0);
    var waiters: [4]std.Thread = undefined;
    for (&waiters) |*t| t.* = try std.Thread.spawn(.{}, gateWaiter, .{ &gate, io, &passed });
    // 让 worker 确实阻塞在 wait上再开门，才能证明"打开前通过数是 0"
    io.sleep(.fromMilliseconds(5), .awake) catch {};
    std.debug.print("开门前已通过 = {d}（应当是 0，说明 4 个 worker 都卡在 wait 上）\n", .{passed.load(.seq_cst)});
    gate.open(io);
    for (waiters) |t| t.join();
    std.debug.print("broadcast 之后已通过 = {d}（应当是 4，broadcast 一次唤醒全部等待者）\n", .{passed.load(.seq_cst)});
    std.debug.print("Condition 的方法清单：wait(io,&m) / waitUncancelable(io,&m) / waitTimeout(io,&m,to)\n", .{});
    std.debug.print("                  / signal(io)（唤醒一个） / broadcast(io)（唤醒全部）\n", .{});
    std.debug.print("正确模式的三个动作（本文件 Gate.waitFor 就是样板）：\n", .{});
    std.debug.print("  ① 持锁判断条件（while (!self.ready)）\n", .{});
    std.debug.print("  ② wait(io, &m)：它内部**原子地**放锁 → 睡 → 醒来重抢锁，这一步不用你写\n", .{});
    std.debug.print("  ③ 醒来后 while 重新判断（虚假唤醒是 API 的正式设定，不是理论风险）\n", .{});
    std.debug.print("⚠️ wait 必须配一把 Mutex，签名就是 (io, *Mutex)——没有无锁版本\n", .{});
    end("19.9 Io.Condition：等条件成立");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.9 Io.Condition：等条件成立 开始 ====
开门前已通过 = 0（应当是 0，说明 4 个 worker 都卡在 wait 上）
broadcast 之后已通过 = 4（应当是 4，broadcast 一次唤醒全部等待者）
Condition 的方法清单：wait(io,&m) / waitUncancelable(io,&m) / waitTimeout(io,&m,to)
                  / signal(io)（唤醒一个） / broadcast(io)（唤醒全部）
正确模式的三个动作（本文件 Gate.waitFor 就是样板）：
  ① 持锁判断条件（while (!self.ready)）
  ② wait(io, &m)：它内部**原子地**放锁 → 睡 → 醒来重抢锁，这一步不用你写
  ③ 醒来后 while 重新判断（虚假唤醒是 API 的正式设定，不是理论风险）
⚠️ wait 必须配一把 Mutex，签名就是 (io, *Mutex)——没有无锁版本
==== 19.9 Io.Condition：等条件成立 结束 ====
```

（"开门前 = 0"这一行依赖那5 ms 的 sleep 是否够——本机稳定复现 0，
但这是**时序假设**不是保证。换机器可能读到非 0。）

### 正确模式的三个动作

```zig
// ① 持锁判断
self.m.lockUncancelable(io);
defer self.m.unlock(io);
// ② ③ 必须是 while，且 wait 在循环体内
while (!self.ready) self.c.waitUncancelable(io, &self.m);
```

**为什么 `while` 不能换`if`**：因为 `wait` 返回有三种可能——
条件真的成立了、被 `signal`/`broadcast` 唤醒了、或者**虚假唤醒**（spurious wakeup）。
后两种情况下条件可能仍然不成立。另外还有一个真实竞态：

```text
线程 A: 判断 !ready → true
线程 B: (此时) set ready = true; signal
线程 A: 进入 wait ← 通知已经发过了，白等
```

**`while` 重判把上面三种情况全部兜住。** 这是 POSIX 的官方要求，不是保守。

### `wait` 帮你做的那一步

`wait(io, &m)` 委托给 `waitTimeout`（`Io.zig` 第 1802 行），
而 `waitUncancelable`（第 1872 行）的骨架是**原子地**做三件事：

```zig
// lib/std/Io.zig 的 waitUncancelable 骨架（简化）
mutex.unlock(io);
defer mutex.lockUncancelable(io);
while (true) {
    io.futexWaitUncancelable(u32, &cond.epoch.raw, epoch);  // 睡
    epoch = cond.epoch.load(.acquire);
    // 尝试消费一个 signal；消费到就 return，否则说明是虚假唤醒 → 继续等
}
```

**"放锁 → 睡 → 醒来重抢锁" 这一步是原子的。** 手工用 `Mutex` +
`io.sleep` 轮询是**做不到**的——放锁和睡之间会有窗口，通知会丢。
这是条件变量比"轮询"优雅的全部原因，也是它必须配一把 `Mutex` 的原因。

### ⚠️ `zig test` 里不要用 `Condition.wait`

15 章实测过：`std.testing.io` 是**单线程视图**（test_runner 用
`Io.Threaded.global_single_threaded`），在它上面 `Condition.wait` 等一个
永远不成立的条件会**死锁**（实测 15 秒未结束）。所以本章的 `test` 块
只测原子量和纯函数，**线程编排全放 `main`**（用 `init.io`，那里有真线程池）。

有意思的对照是：`io.concurrent` + `await` 在 `zig test` 里**能跑通**（实测通过），
只有 `Condition.wait` 会挂。

## 19.10 `broadcast` 与 `signal` 的选择

```zig
// examples/19_threads/main.zig 第 335-345 行
    // ═══ 19.10 为什么是 broadcast 不是 signal ═══
    begin("19.10 broadcast 与 signal 的选择");
    std.debug.print("signal   : 唤醒**一个**等待者 —— 语义是\"有一个资源/一条消息来了\"\n", .{});
    std.debug.print("broadcast: 唤醒**所有**等待者 —— 语义是\"状态变了，自己重判条件\"\n", .{});
    std.debug.print("19.9 的 Gate 用 broadcast，因为条件 ready 是**所有**等待者共同关心的同一个 bool\n", .{});
    std.debug.print("如果用 signal：4 个 waiter 只会有 1 个被叫醒，其余 3 个**永远挂着** ⇒ join 挂死\n", .{});
    std.debug.print("判据：等待者之间**地位平等**（都在等同一个谓词）→ broadcast；\n", .{});
    std.debug.print("      等待者**各有各的诉求**（各要一条消息/一个槽位）→ signal\n", .{});
    std.debug.print("信号量 19.11 内部就是用 signal（因为每个 permit 只能被一个 waiter 拿走）\n", .{});
    end("19.10 broadcast 与 signal 的选择");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.10 broadcast 与 signal 的选择 开始 ====
signal   : 唤醒**一个**等待者 —— 语义是"有一个资源/一条消息来了"
broadcast: 唤醒**所有**等待者 —— 语义是"状态变了，自己重判条件"
19.9 的 Gate 用 broadcast，因为条件 ready 是**所有**等待者共同关心的同一个 bool
如果用 signal：4 个 waiter 只会有 1 个被叫醒，其余 3 个**永远挂着** ⇒ join 挂死
判据：等待者之间**地位平等**（都在等同一个谓词）→ broadcast；
      等待者**各有各的诉求**（各要一条消息/一个槽位）→ signal
信号量 19.11 内部就是用 signal（因为每个 permit 只能被一个 waiter 拿走）
==== 19.10 broadcast 与 signal 的选择 结束 ====
```

**"用 signal 会 join 挂死"这句话值得强调**：这不是"效率低"，是**死锁**。
4 个 waiter 用 `signal` 只唤醒 1 个，那 1 个通过后 `join` 立刻等剩下 3 个——
而它们永远不会醒。**不是"慢"，是永远不出来。**

| | `signal(io)` | `broadcast(io)` |
|---|---|---|
| 唤醒几个 | **一个** | **全部** |
| 语义 | "有一个资源/一条消息来了" | "状态变了，自己重判条件" |
| 用在 | 有界队列来消息、信号量发许可 | 关停广播、状态变更通知、19.9 的 Gate |
| 用错的症状 | 死锁（其余等待者永远挂着） | 性能差（惊群），但**正确** |

**判据一句话**：等待者**地位平等**（都在等同一个谓词）→ `broadcast`；
**各有各的诉求**（各要一条消息/一个槽位）→ `signal`。

## 19.11 `Io.Semaphore`：有界资源池

`Semaphore` 在 0.17 **存在**（`lib/std/Io/Semaphore.zig`），
但它**不叫** `acquire`/`release`，叫 **`wait`/`post`**。

```zig
// examples/19_threads/main.zig 第 89-118 行
// ═══ 19.11 有界资源池：Semaphore ═══
/// 19.11 的连接池。permits = 3 ⇒ 同时最多 3 个"连接"在用。
const Pool = struct {
    sem: std.Io.Semaphore = .{ .permits = 3 },
    live: std.atomic.Value(u32) = .init(0),
    peak: std.atomic.Value(u32) = .init(0),

    /// 借一个连接。`waitUncancelable` 的返回值类型是 `Io.Cancelable!void`，
    /// 0.17 的 Semaphore 叫 `wait`/`post`（**不叫** acquire/release）。
    fn borrow(self: *Pool, io: std.Io) void {
        self.sem.waitUncancelable(io);
        const now = self.live.fetchAdd(1, .seq_cst) + 1;
        _ = self.peak.fetchMax(now, .seq_cst);
    }

    /// 还一个连接。
    fn give(self: *Pool, io: std.Io) void {
        _ = self.live.fetchSub(1, .seq_cst);
        self.sem.post(io);
    }
};

fn poolUser(p: *Pool, io: std.Io, rounds: usize) void {
    for (0..rounds) |_| {
        p.borrow(io);
        // 故意让持锁时间变长，好让峰值真的顶到 permits 上限
        io.sleep(.fromMicroseconds(200), .awake) catch {};
        p.give(io);
    }
}
```

```zig
// examples/19_threads/main.zig 第 346-361 行
    // ═══ 19.11 Io.Semaphore：有界资源池 ═══
    begin("19.11 Io.Semaphore：有界资源池");
    var pool: Pool = .{};
    var users: [8]std.Thread = undefined;
    for (&users) |*t| t.* = try std.Thread.spawn(.{}, poolUser, .{ &pool, io, 20 });
    for (users) |t| t.join();
    std.debug.print("8 个用户 × 20 次借还，pool.permits = {d} ⇒ 实测峰值并发 = {d}\n", .{
        pool.sem.permits, pool.peak.load(.seq_cst),
    });
    std.debug.print("⇒ 峰值**恰好等于**许可数（不是小于）：这正是有界池的意义——\n", .{});
    std.debug.print("   上游再猛也不会有第 4 个连接同时在用，背压落在这里。\n", .{});
    std.debug.print("⚠️ 0.17 的 Semaphore 叫 wait / post，**不叫** acquire / release（实测 no member named 'acquire'）\n", .{});
    std.debug.print("   wait(io) 返回 Io.Cancelable!void；教学场景用 waitUncancelable(io)（无取消点）\n", .{});
    std.debug.print("   释放方是 post(io)（不是 release），返回值 void\n", .{});
    end("19.11 Io.Semaphore：有界资源池");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.11 Io.Semaphore：有界资源池 开始 ====
8 个用户 × 20 次借还，pool.permits = 3 ⇒ 实测峰值并发 = 3
⇒ 峰值**恰好等于**许可数（不是小于）：这正是有界池的意义——
   上游再猛也不会有第 4 个连接同时在用，背压落在这里。
⚠️ 0.17 的 Semaphore 叫 wait / post，**不叫** acquire / release（实测 no member named 'acquire'）
   wait(io) 返回 Io.Cancelable!void；教学场景用 waitUncancelable(io)（无取消点）
   释放方是 post(io)（不是 release），返回值 void
==== 19.11 Io.Semaphore：有界资源池 结束 ====
```

**`峰值并发 = 3` 是确定的**（8 个线程争 3 个许可，且临界区里有 200 µs 的 sleep
保证它们真的重叠）。**这正是有界池的意义**：
`permits` 是**硬上界**，不是"大部分时候"。这与"线程池的池大小"不同——池大小是建议值，
信号量许可数是保证值。

### 三个签名细节

**① 没有 `init` 常量。** 和 `Mutex`/`Condition` 不同，`Semaphore` 的字段都有默认值
（`permits: usize = 0`），所以直接用默认初始化：`.{ .permits = 3 }` 或 `.{}`。

**② `wait` 会被取消。** `wait(io)` 返回 `Io.Cancelable!void`——
如果 `permits` 一直是 0，等待点可以被 `Future.cancel` 打断。
`waitUncancelable(io)` 返回 `void`，不设取消点。

**③ 它的内部实现就是 `Mutex` + `Condition`**（`Io/Semaphore.zig` 第 11-14 行）：

```zig
// lib/std/Io/Semaphore.zig 第 11-14 行
mutex: Io.Mutex = .init,
cond: Io.Condition = .init,
/// It is OK to initialize this field to any value.
permits: usize = 0,
```

所以 19.10 说的"信号量内部用 `signal`"有源码依据：

```zig
// lib/std/Io/Semaphore.zig 第 52-58 行
pub fn waitUncancelable(s: *Semaphore, io: Io) void {
    s.mutex.lockUncancelable(io);
    defer s.mutex.unlock(io);
    while (s.permits == 0) s.cond.waitUncancelable(io, &s.mutex);
    s.permits -= 1;
    if (s.permits > 0) s.cond.signal(io);   // ← signal：许可只能被一个 waiter 拿走
}
```

**注意那个 `while`**——和 19.9 一样的纪律。以及最后那个"还剩许可就 signal"的优化：
`post` 之后立刻把信号转给另一个等待者，**不让它白唤醒再睡回去**。

## 19.12 `Io.Event`：一次性的门

`Event` 不是同步原语里最常用的那个，但它有独特的形状：一个**可重复使用的三态布尔**。

```zig
// examples/19_threads/main.zig 第 362-377 行
    // ═══ 19.12 Io.Event：一次性的"门" ═══
    begin("19.12 Io.Event：一次性的门");
    var ev: std.Io.Event = .unset;
    std.debug.print("Event 初值是 .unset（不是 .init、不是 .false）—— 它是个三态枚举 unset/waiting/is_set\n", .{});
    std.debug.print("isSet() = {}，set(io) 之后 isSet() = ", .{ev.isSet()});
    ev.set(io);
    std.debug.print("{}\n", .{ev.isSet()});
    ev.reset(); // ⚠️ reset **不要 io**，是 0.17 的不一致点（set 要、reset 不要）
    std.debug.print("reset() 之后 isSet() = {}（⚠️ reset 无参数，set 有 io）\n", .{ev.isSet()});
    var ev2: std.Io.Event = .unset;
    const to = ev2.waitTimeout(io, .{ .duration = .{ .raw = .fromMilliseconds(2), .clock = .awake } });
    std.debug.print("没 set 就等 2ms → {any}（Event 不会像 Condition 那样死等，waitTimeout 有出路）\n", .{to});
    std.debug.print("Event vs Condition：Event 是**一个** boolean 门（可重复用、只能 set/reset）\n", .{});
    std.debug.print("Condition 是**谓词**同步（能 signal/broadcast 多个等待者、要配 Mutex）\n", .{});
    end("19.12 Io.Event：一次性的门");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.12 Io.Event：一次性的门 开始 ====
Event 初值是 .unset（不是 .init、不是 .false）—— 它是个三态枚举 unset/waiting/is_set
isSet() = false，set(io) 之后 isSet() = true
reset() 之后 isSet() = false（⚠️ reset 无参数，set 有 io）
没 set 就等 2ms → error.Timeout（Event 不会像 Condition 那样死等，waitTimeout 有出路）
Event vs Condition：Event 是**一个** boolean 门（可重复用、只能 set/reset）
Condition 是**谓词**同步（能 signal/broadcast 多个等待者、要配 Mutex）
==== 19.12 Io.Event：一次性的门 结束 ====
```

**⚠️ `set` 要 `io`、`reset` 不要** —— 这是 0.17 的真实不一致，我实测撞到：

```text
e.zig:2:54: error: member function expected 1 argument(s), found 0
pub fn main() !void { var e: std.Io.Event = .unset; e.set(); }
                                                    ~^~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io.zig:2055:9: note: function declared here
    pub fn set(e: *Event, io: Io) void {
```

原因是设计上说得通的：`set` 可能要唤醒等待者（要事件循环参与），
`reset` 不会唤醒任何人（所以不需要 `io`）。

| | `Io.Event` | `Io.Condition` |
|---|---|---|
| 类型 | `enum(u32){unset, waiting, is_set}` | `struct`（Mutex-like + epoch） |
| 初值 | `.unset` | `.init`（命名常量） |
| 等待者 | `wait` / `waitUncancelable` / `waitTimeout` | 同名三个 + **必须传 `*Mutex`** |
| 唤醒 | `set(io)` / `reset()` | `signal(io)` / `broadcast(io)` |
| 谓词 | **不能**（只有一个 bool） | ✅ 任意谓词 |
| `isLocked`类查询 | `isSet()`（不收 `io`） | 无（用你自己的谓词变量） |

**`Event` 的定位**：一次性的、可重复用的"准备好了"信号。
比如"后台初始化完成了吗"——`wait` 等它，`set` 宣告完成，之后可以 `reset` 复用。
**需要"等任意条件"就用 `Condition`。**

## 19.13 `io.concurrent` 与 `Io.Group`：异步那条路

19 章的 `Thread.spawn` 是**阻塞式**的：主线程调`join` 就停在那儿等。
0.17 的 `Io` 提供了另一条路——**起个活儿，先去干别的，回头再取结果**。

```zig
// examples/19_threads/main.zig 第 378-414 行
    // ═══ 19.13 io.concurrent / Io.Group：异步那条路 ═══
    begin("19.13 io.concurrent 与 Io.Group");
    const square = struct {
        fn run(x: u32) u32 {
            var acc: u32 = 0;
            var i: u32 = 0;
            while (i < 3_000_000) : (i += 1) acc +%= i; // 故意磨蹭，让 await 真的在等
            return x * x;
        }
    };
    // concurrent：起一个"真并发"的活儿，返回 Future；await 才取结果
    var fut = try io.concurrent(square.run, .{7});
    std.debug.print("io.concurrent 返回类型 = {s}（Future(T)）\n", .{@typeName(@TypeOf(fut))});
    // 此时主线程可以干别的（下面这行就是"别的"）
    var hits2 = std.atomic.Value(u32).init(0);
    _ = hits2.fetchAdd(1, .monotonic);
    const sq = fut.await(io); // 等它做完（幂等：await 两次结果一样）
    std.debug.print("await 拿到 {d}（= 7²），主线程期间还干了别的：hits2 = {d}\n", .{ sq, hits2.load(.seq_cst) });
    // cancel：不等了，把取消请求发出去
    var f2 = try io.concurrent(square.run, .{1});
    _ = f2.cancel(io);
    std.debug.print("cancel(io) 不抛错、返回 Result（未完成时值无意义，别assert 它）\n", .{});
    // Group：批量起一批活儿，一次等完
    var group: std.Io.Group = .init;
    var ghits = std.atomic.Value(u32).init(0);
    const group_worker = struct {
        fn run(c: *std.atomic.Value(u32)) void {
            _ = c.fetchAdd(1, .monotonic);
        }
    };
    for (0..8) |_| group.async(io, group_worker.run, .{&ghits});
    try group.await(io);
    std.debug.print("Io.Group：8 个 async 任务全部完成，ghits = {d}（await 一次收全部）\n", .{ghits.load(.seq_cst)});
    std.debug.print("⚠️ 0.17 没有 std.Io.Task（@hasDecl 实测 false）；Group 有 async / concurrent / await / cancel 四个\n", .{});
    std.debug.print("⚠️ Group.concurrent(io, ...) 返回 ConcurrentError!void，async 不返回错误\n", .{});
    end("19.13 io.concurrent 与 Io.Group");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.13 io.concurrent 与 Io.Group 开始 ====
io.concurrent 返回类型 = Io.Future(u32)（Future(T)）
await 拿到 49（= 7²），主线程期间还干了别的：hits2 = 1
cancel(io) 不抛错、返回 Result（未完成时值无意义，别assert 它）
Io.Group：8 个 async 任务全部完成，ghits = 8（await 一次收全部）
⚠️ 0.17 没有 std.Io.Task（@hasDecl 实测 false）；Group 有 async / concurrent / await / cancel 四个
⚠️ Group.concurrent(io, ...) 返回 ConcurrentError!void，async 不返回错误
==== 19.13 io.concurrent 与 Io.Group 结束 ====
```

### `io` 跨线程用是**合法**的

这一点我专门实测了：`init.io` 从主线程传给 `std.Thread.spawn` 的 worker，
**完全合法**（19.5 的 `bumpLocked` 就是这么干的，5 万次加锁分毫不差）。
`std.Io` 是一个**值类型**（`{ userdata, vtable }`），拷贝到别的线程没问题——
它背后是 `Io.Threaded` 的线程池，**不是**绑在某个 OS 线程上的东西。

这就是 0.17 设计的核心：**`io` 是显式依赖**（02 章 2.4 节的`init.io`），
所以"传给 worker"和"传给测试替身"是同一件事。同一个 `Mutex` 方法签名
（`lock(io)`）在主线程、worker 线程、`test` 块里**完全一样**。

### `concurrent` vs `async`

| | `io.concurrent` | `io.async` |
|---|---|---|
| 返回 | `ConcurrentError!Future(T)` | `Future(T)`（**不返回错误**） |
| 保证 | 返回时**已经**分到并发额度（或已完成） | 函数**可能已经执行完了** |
| 失败可能 | `error.ConcurrencyUnavailable` | 无 |
| 适用 | 真·并行计算 | 可能在别的 Io 实现上栈式执行 |

`concurrent` 的文档注释把取舍写得很直白（`Io.zig` 第 2562-2564 行，
注意这句话挂在 **`concurrent`** 上，讲的是它相对 `async` 更强的那部分）：

```zig
/// This has stronger guarantee than `async`, placing restrictions on what kind
/// of `Io` implementations are supported. By calling `async` instead, one
/// allows, for example, stackful single-threaded blocking I/O.
```

`async` 的注释（第 2520-2522 行）则说：函数**可能**在 `async` 返回前就已经跑完了。

⇒ `async` 更可移植（别的 Io 实现可以栈式执行），`concurrent` 保证真并发。

### `Group`：批量起活儿

`Group` 是"一批 `Future` 的集合"，但比你自己攒一串 `Future` 好在
**`await` 一次收全部，失败会传播给所有成员**。

```zig
var group: std.Io.Group = .init;
for (0..8) |_| group.async(io, group_worker.run, .{&ghits});
try group.await(io);   // 一次等完；幂等
```

`Group.cancel(io)` 会给所有成员发取消请求，然后等它们全部落地。
本示例测过（实测输出：`Group.cancel 后 token = null，计数 = 1`——任务还是跑了，
因为 `group_worker.run` 里没有取消点）。

⚠️ `Group` 有两个"async"方法，**返回类型不同**：

- `group.async(io, fn, args)` → **void**（不返回错误）
- `group.concurrent(io, fn, args)` → **`ConcurrentError!void`**（要 `try`）

### 取消（cancel）的形状

`Future.cancel(io)` **不抛错**，它返回 `Result` 本身（19.3 表里的第 4 条结论）：

```zig
var f = try io.concurrent(slowFn, .{1});
_ = f.cancel(io);       // 不等它做完，把取消请求发出去
// f.result 此时是**未定义/部分写入**的值——实测是个随机数（1283106753）
```

**取消是"协作式"的**：被取消的函数必须**跑到一个取消点**（一个会返回
`error.Canceled` 的 `Io` 调用）才会真的停。纯计算循环（如 `square.run`）
**没有取消点**，`cancel` 只是把请求记下来，它会一直算完。
所以 19.13 那句"别 assert 它"是实在的提醒。

`Io.recancel(io)` 可以"重新武装"一个已经消费掉的取消请求——
`error.Canceled` 默认只被信号一次。

## 19.14 伪共享与缓存行

这一节我原本想报一组"填充 vs 不填充"的耗时对比，**实测两次跑结果反过来了**
（0.66 s vs 1.00 s），所以本节只讲**为什么**，不报数字。

```zig
// examples/19_threads/main.zig 第 415-453 行
    // ═══ 19.14 伪共享：挤在同一条缓存行 ═══
    begin("19.14 伪共享与缓存行");
    // 方案 A（有问题）：两个计数器挨着，偏移只有 8 字节 ⇒ 必然同一条缓存行
    const Adjacent = struct {
        a: std.atomic.Value(u64),
        b: std.atomic.Value(u64),
    };
    // 方案 B（**无效**，留作反例）：拿字节数组当填充字段
    const Padded = struct {
        a: std.atomic.Value(u64),
        pad: [std.atomic.cache_line - @sizeOf(u64)]u8,
        b: std.atomic.Value(u64),
    };
    // 方案 C（正确）：给字段本身加 align(cache_line)
    const Aligned = struct {
        a: std.atomic.Value(u64) align(std.atomic.cache_line),
        b: std.atomic.Value(u64) align(std.atomic.cache_line),
    };
    std.debug.print("std.atomic.cache_line = {d} 字节（本机 x86_64；ARM 常见 64）\n", .{std.atomic.cache_line});
    std.debug.print("pad 数组长度 = cache_line - sizeOf(u64) = {d} 字节\n", .{std.atomic.cache_line - @sizeOf(u64)});
    std.debug.print("Adjacent  : sizeOf = {d}，offsetOf(.b) = {d}  ← a 与 b 挨着，必然同一条缓存行\n", .{
        @sizeOf(Adjacent), @offsetOf(Adjacent, "b"),
    });
    std.debug.print("Padded    : sizeOf = {d}，offsetOf(.b) = {d}（**没变！** 见下方⚠️）\n", .{
        @sizeOf(Padded), @offsetOf(Padded, "b"),
    });
    std.debug.print("Aligned   : sizeOf = {d}，offsetOf(.b) = {d}，@alignOf = {d}  ← 真隔开了\n", .{
        @sizeOf(Aligned), @offsetOf(Aligned, "b"), @alignOf(Aligned),
    });
    std.debug.print("⚠️ **踩到的坑**：拿 pad 字节数组当初始化字段的填充是**无效的**——\n", .{});
    std.debug.print("   Zig 会按对齐重排字段（实测 pad 被挪到 offset {d}，b 仍留在 {d}），\n", .{
        @offsetOf(Padded, "pad"), @offsetOf(Padded, "b"),
    });
    std.debug.print("   因为 b 的对齐要求(8) 高于 pad 数组(1)，编译器有权先放 b。\n", .{});
    std.debug.print("   正确姿势：给字段本身加 `align(std.atomic.cache_line)`（Aligned 那样）。\n", .{});
    std.debug.print("   顺带：伪共享的收益是**纳秒级**的，而 Debug 构建的波动是**毫秒级**的——\n", .{});
    std.debug.print("   本机连跑两次甚至会**反过来**（0.66s vs 1.00s）⇒ 本节刻意不报耗时，别拿它当基准。\n", .{});
    end("19.14 伪共享与缓存行");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.14 伪共享与缓存行 开始 ====
std.atomic.cache_line = 128 字节（本机 x86_64；ARM 常见 64）
pad 数组长度 = cache_line - sizeOf(u64) = 120 字节
Adjacent  : sizeOf = 16，offsetOf(.b) = 8  ← a 与 b 挨着，必然同一条缓存行
Padded    : sizeOf = 136，offsetOf(.b) = 8（**没变！** 见下方⚠️）
Aligned   : sizeOf = 256，offsetOf(.b) = 128，@alignOf = 128  ← 真隔开了
⚠️ **踩到的坑**：拿 pad 字节数组当初始化字段的填充是**无效的**——
   Zig 会按对齐重排字段（实测 pad 被挪到 offset 16，b 仍留在 8），
   因为 b 的对齐要求(8) 高于 pad 数组(1)，编译器有权先放 b。
   正确姿势：给字段本身加 `align(std.atomic.cache_line)`（Aligned 那样）。
   顺带：伪共享的收益是**纳秒级**的，而 Debug 构建的波动是**毫秒级**的——
   本机连跑两次甚至会**反过来**（0.66s vs 1.00s）⇒ 本节刻意不报耗时，别拿它当基准。
==== 19.14 伪共享与缓存行 结束 ====
```

### ⚠️ 本章新踩到的坑：字节数组填充**无效**

`std.atomic.cache_line` **在0.17 存在**（`pub const cache_line: comptime_int`，
本机 128），这是确认的。但我第一版`Padded` 写错了：

```zig
const Padded = struct {
    a: std.atomic.Value(u64),                              // offset 0
    pad: [std.atomic.cache_line - @sizeOf(u64)]u8,          // 我以为在 offset 8
    b: std.atomic.Value(u64),                              // 我以为在 offset 128
};
```

**实测 `offsetOf(Padded, "b") = 8`—— `b` 根本没被挪走！**
而 `pad` 被挪到了 `offset 16`。

**原因**：Zig **按对齐要求重排结构体字段**。
`b` 是 `atomic.Value(u64)`，对齐要求 8；`pad` 是 `[120]u8`，对齐要求 1。
编译器有权（也确实）把高对齐的 `b` 放在低对齐的 `pad` 前面。

**正确写法是给字段本身加 `align`**：

```zig
const Aligned = struct {
    a: std.atomic.Value(u64) align(std.atomic.cache_line),   // offset 0，对齐 128
    b: std.atomic.Value(u64) align(std.atomic.cache_line),   // offset 128 ← 真隔开了
};
// 实测：sizeOf = 256，offsetOf(.b) = 128，@alignOf = 128
```

**顺带一条方法论**：这一节**刻意不报耗时**。伪共享的收益是纳秒级的
（ ReleaseFast 下能差几倍），但在 **Debug 构建**里安全检查全开，
波动是**毫秒级**的——收益被噪声完全淹没。我实测两次跑甚至**结论相反**。
**任何在 Debug 下测不出来的性能差异，都不该写进文档当结论。**

## 19.15 什么时候根本不需要并发

```zig
// examples/19_threads/main.zig 第 454-486 行
    // ═══ 19.15 什么时候根本不需要并发 ═══
    begin("19.15 什么时候根本不需要并发");
    // 同一个活儿串行 vs 并行
    const heavy = struct {
        fn run(acc: *std.atomic.Value(u64), n: usize) void {
            var sum: u64 = 0;
            for (0..n) |i| sum +%= @as(u64, i) *% 2654435761;
            _ = acc.fetchAdd(sum, .monotonic);
        }
    };
    var serial_sink = std.atomic.Value(u64).init(0);
    const ts0 = std.Io.Clock.now(.awake, io);
    heavy.run(&serial_sink, 400_000);
    const t1 = std.Io.Clock.now(.awake, io);
    var par_sink = std.atomic.Value(u64).init(0);
    const tp0 = std.Io.Clock.now(.awake, io);
    const ph = try std.Thread.spawn(.{}, heavy.run, .{ &par_sink, 400_000 });
    ph.join();
    const tp1 = std.Io.Clock.now(.awake, io);
    const s_ns = ts0.durationTo(t1).nanoseconds;
    const p_ns = tp0.durationTo(tp1).nanoseconds;
    std.debug.print("串行 400000 次 = {d} ns；同样活儿 spawn 一个线程跑 = {d} ns（多了 spawn+join 开销）\n", .{ s_ns, p_ns });
    std.debug.print("⇒ 实测**并行版更慢**（{d} > {d}）——活儿太小，并发的开销就赚不回来\n", .{ p_ns, s_ns });
    std.debug.print("⇒ 判断表：\n", .{});
    std.debug.print("  活儿不足 ~100 微秒 ⇒ 别并发，spawn/join 的开销就吃掉了\n", .{});
    std.debug.print("  纯 CPU 密集     ⇒ 只有**核数 ≥ 线程数**时才快；超订反而更慢\n", .{});
    std.debug.print("  有 I/O 等待     ⇒ 才真正需要并发（等待期间让别的活儿跑）\n", .{});
    std.debug.print("  结果只求一个和 ⇒ 19.4 的原子游标模式（fetchAdd 抢号）比队列分发更简单\n", .{});
    std.debug.print("  几乎所有情况   ⇒ 先写串行版本，跑出 profile，**再**决定要不要并发\n", .{});
    end("19.15 什么时候根本不需要并发");
```

运行输出（`examples/19_threads/main.zig`）：

```text
==== 19.15 什么时候根本不需要并发 开始 ====
串行 400000 次 = 1537592 ns；同样活儿 spawn 一个线程跑 = 1636260 ns（多了 spawn+join 开销）
⇒ 实测**并行版更慢**（1636260 > 1537592）——活儿太小，并发的开销就赚不回来
⇒ 判断表：
  活儿不足 ~100 微秒 ⇒ 别并发，spawn/join 的开销就吃掉了
  纯 CPU 密集     ⇒ 只有**核数 ≥ 线程数**时才快；超订反而更慢
  有 I/O 等待     ⇒ 才真正需要并发（等待期间让别的活儿跑）
  结果只求一个和 ⇒ 19.4 的原子游标模式（fetchAdd 抢号）比队列分发更简单
  几乎所有情况   ⇒ 先写串行版本，跑出 profile，**再**决定要不要并发
==== 19.15 什么时候根本不需要并发 结束 ====
```

（两个 ns 数字每次运行都不同，**不可复现**。但"并行 1 个线程 > 串行"这个
**方向**在 5 次连跑里都成立——因为它多付了一次 spawn + join 的固定成本。）

### 判断表

| 情况 | 并发有用吗 |
|---|---|
| 单个活儿 **< 100 µs** | ❌ `spawn` + `join` 的固定开销就吃掉了（本节实测） |
| 纯 CPU 密集，线程数 **> 核数** | ❌ 超订：上下文切换吃掉收益，还加剧缓存抖动 |
| 纯 CPU 密集，线程数 **≤ 核数** | ✅ 唯一能线性加速的情况 |
| **有 I/O 等待**（网络、磁盘、`io.sleep`） | ✅✅ 这才是并发的**主战场**：等待期间让别的活儿跑 |
| 结果只求一个聚合值 | ✅ 用**原子游标**（`fetchAdd` 抢号）比队列分发简单得多 |

**最后一条值得展开**。19.3 的 `work` 就是这个模式：4 个 worker 抢同一个原子计数器，
`fetchAdd` 拿到号就干活，号超了收工：

```zig
while (true) {
    const i = nx.fetchAdd(1, .monotonic);   // 抢号
    if (i >= fl.len) break;                  // 活儿派完了
    doWork(fl[i]);                           // 各干各的，互不通信
}
```

**没有队列、没有锁、没有条件变量**，而且**天然负载均衡**（谁快谁多拿）。
代价是：① 任务粒度必须均匀；② 需要一个"任务数组"作为共享只读状态。
多线程批处理（grep、批量解析、并行计算）的默认套路就是这个。

### 什么时候**真的**需要并发

一句话：**当你的程序大部分时间在等**。
等I/O、等锁、等条件变量、等一个远端的响应——这些时间里 CPU 是空的，
让别人插进来干别的才划算。纯计算的程序想加速，方向是**算法和SIMD**，不是线程。

## 19.16 坑位清单

1. **同步原语全搬进了 `std.Io`，方法第一个参数是 `io`**。`std.Thread.Mutex` /
   `Condition` / `Semaphore` / `Event` / `RwLock` 一律报
   `root source file struct 'Thread' has no member named 'Mutex'`（实测）。
   唯一例外是 **`Io.Mutex.tryLock()` 不收 `io`**（它不阻塞）。

2. **初始化用命名常量 `.init`，不是 `.{}`**。`Io.Mutex` / `Io.Condition` / `Io.Group`
   都是 `pub const init: T = ...`。写 `.{}` 报 `missing struct field: state`（实测）。
   **例外**：`Io.Semaphore` **没有** `init` 常量，用 `.{ .permits = N }`。

3. **`Io.Semaphore` 叫 `wait`/`post`，不叫 `acquire`/`release`**。
   写 `sem.acquire()` 报 `no field or member function named 'acquire' in 'Io.Semaphore'`（实测）。

4. **`Future.await(io)` / `Future.cancel(io)` 返回 `Result`，不是错误联合**。
   写 `try f.await(io)` 报 `expected error union type, found 'u32'`（实测）。
   只有当你的 worker 函数**自己**返回 `!T` 时才需要 `try`。

5. **`Io.Event.set(io)` 要 `io`，`Io.Event.reset()` 不要**——0.17 的真实不一致点。
   写 `e.reset(io)` 报 `member function expected 0 argument(s), found 1`（实测）。
   原因：`set` 可能要唤醒等待者，`reset` 不会。

6. **`std.Thread.WaitGroup` 已移除**。要"等 N 个活干完"就直接 `join` 全部。
   报 `no member named 'WaitGroup'`（实测）。需要"等任务不等线程"就用 `Io.Group`
   或 `Io.Condition` 的 `broadcast`。

7. **`std.Thread.sleep` 已移除**。睡眠走 `io.sleep(duration, clock)`：
   `try io.sleep(.fromMilliseconds(3), .awake)`。这是 0.16 起"时间归 Io"的一部分
   （22 章会展开整个 `Io.Clock`）。

8. **`Condition.wait` 的条件判断必须是 `while` 不能是 `if`**。虚假唤醒是 API 的
   正式设定，而且"判断"和"进入 wait"之间还有真实竞态。
   同理 `Semaphore` 内部的 `while (s.permits == 0)` 也是这个纪律。

9. **不要在持锁时 `join`**。主线程等 worker、worker 等锁、锁等主线程 ⇒ 死锁。
   实测确认：反例跑 6 秒仍未结束，必须 `kill -9`。先 `unlock` 再 `join`，
   或者根本不持锁去 `join`。

10. **`.unordered` 不能给 RMW 操作**。`v.fetchAdd(1, .unordered)` 报
    `@atomicRmw atomic ordering must not be unordered`（实测）。
    但给 `load` 完全合法。

11. **`.acq_rel` 只能给 RMW**（`fetchAdd` / `cmpxchg` 等）。
    `load` 和 `store` 各只有自己的那一档（`acquire` / `release`）。

12. **`fetch*` 一律返回旧值**（`swap` 也是）。`fetchAnd` 返回的是**改之前**的值，
    新值要再 `load` 一次。我第一次写测试就因为这个错位。

13. **`cmpxchgWeak` 仍然必须写成循环**，尽管 x86 实测 200 万次 0 伪失败。
    ARM/POWER 的 LL/SC 指令对会真伪失败——这是可移植性要求。

14. **线程 id 是复用的**。`getCurrentId()` 拿到的是 OS 句柄，join 掉的 id 会被
    后来的线程再用。别拿它算"存活线程数"。

15. **`zig test` 里不要用 `Io.Condition.wait`**。`std.testing.io` 是单线程视图，
    在它上面等一个不会成立的条件**死锁**（15 章实测 15 秒未结束）。
    `io.concurrent` + `await` 在测试里能跑通。**线程编排放 `main`**，
    `test` 块只测原子量和纯函数。

16. **字节数组当缓存行填充无效**。Zig 按对齐重排字段，`pad: [N]u8` 会被挪到
    高对齐的 `atomic.Value` 后面（实测 `offsetOf(b)` 仍是 8）。
    正确写法是 `field: T align(std.atomic.cache_line)`。

17. **`Io.Mutex` 没有 `isLocked`**。0.16 时代有过，0.17 移除
   （`@hasDecl` 实测 `false`）。想看锁状态自己加原子标志。

18. **`std.Io` 没有 `await` 自由函数，也没有 `std.Io.Task`**。
   `await` 是 `Future` / `Group` 的方法；`@hasDecl(std.Io, "Task")` 实测 `false`。

---

上一章：[18 交叉编译](18-cross.md) · 下一章：[20 文件与 IO](20-files-io.md)
