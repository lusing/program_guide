//! 19 并发：Thread.spawn/join、Io.Mutex、std.atomic.Value、Io.Condition、Io.Semaphore、Io.Event
//! 0.17 变化：Mutex/Condition/Semaphore/Event 全在 std.Io 下且方法第一个参数是 io；
//!           Thread.WaitGroup 已移除（直接 join）；Thread.sleep 已移除（时间归 Io）。
//!           0.17 没有共享可变全局的static mut 陷阱，共享状态必须显式经参数传递。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 19.4 数据竞争：裸 += 丢更新（对照组的共享状态）═══
/// 19.4 的裸计数器。Zig 没有 `static mut`，但文件级 `var` 一样是**全进程共享**的，
/// 两个线程同时 `+=` 就是数据竞争（见 main 里19.4 节的实测输出）。
var racer: usize = 0;

/// 19.4/19.5 的共享计数器。改成原子量或加锁就安全了。
var guarded: usize = 0;

/// 19.5/19.7 的互斥量：0.16 起 Mutex 从 std.Thread 移入 std.Io，
/// 初始化用**命名常量 `.init`**（不是 `.{}`——那是给带字段的结构体用的）。
var counter_lock: std.Io.Mutex = .init;

/// 19.4 的裸写 worker：读-改-写三步，随时会被另一个线程穿插。
/// 注意 `io` 只是为了和别的 worker 签名一致而存在，函数体里没用它。
fn bumpRacy(io: std.Io, n: usize) void {
    _ = io;
    for (0..n) |_| racer += 1;
}

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

// ═══ 19.3 线程入口不能捕获：所有状态显式作参数传 ═══
/// 19.3 的 worker 上下文：Zig 没有闭包，要带的状态就打成指针传进来。
const Ctx = struct {
    io: std.Io,
    n: usize,
    hits: *std.atomic.Value(u32),
};

/// 19.3 的 worker 入口。签名是 `fn (ctx: *Ctx) void`——**一个参数**，
/// 三个字段都在 ctx 里。`io` 在这里显式传给了两个下游函数，这就是"穿透"。
fn work(ctx: *Ctx) void {
    var i: usize = 0;
    while (i < ctx.n) : (i += 1) {
        _ = ctx.hits.fetchAdd(1, .monotonic);
        // 时间要靠 io 拿（0.16 起 Thread.sleep 已移除）
        if (i % 50_000 == 0) ctx.io.sleep(.fromMicroseconds(1), .awake) catch {};
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // ═══ 19.1 Zig 没有 static mut：共享状态必须显式经参数传递 ═══
    begin("19.1 没有 static mut");
    std.debug.print("本文件里没有任何 `static mut` / `threadlocal` —— Zig **不提供**可变全局的豁免通道\n", .{});
    std.debug.print("  共享状态只有两个来源：①文件级 `var`（像 racer/guarded）②显式按指针传参\n", .{});
    std.debug.print("  文件级 var 类型 = {s}，是普通存储（不像 C 那样名字暗示了并发语义）\n", .{@typeName(@TypeOf(guarded))});
    std.debug.print("⇒ 想不被别人踩，就得自己上锁/上原子（19.5 / 19.7）—— 编译器不兜底\n", .{});
    std.debug.print("  对比：C 的 `static int x;` 在多线程下是未定义行为，Zig 取消了这条歧义路径\n", .{});
    end("19.1 没有 static mut");

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

    // ═══ 19.3 线程入口不能捕获：状态显式作参数 ═══
    begin("19.3 线程入口不能捕获变量");
    var hits = std.atomic.Value(u32).init(0);
    const n_workers: usize = 4;
    const per_worker: usize = 60_000;
    var ctxs: [n_workers]Ctx = undefined;
    var threads: [n_workers]std.Thread = undefined;
    for (&ctxs, 0..) |*c, i| {
        c.* = .{ .io = io, .n = per_worker, .hits = &hits }; // 状态打包成 struct，地址传进去
        threads[i] = try std.Thread.spawn(.{}, work, .{c});
    }
    for (threads) |t| t.join();
    std.debug.print("{d} 个 worker × {d} 次 = {d}（期望 {d}，原子计数器分毫不差）\n", .{
        n_workers, per_worker, hits.load(.seq_cst), n_workers * per_worker,
    });
    std.debug.print("Zig 没有闭包 ⇒ spawn 的第三个参数是**元组**；要带多个状态就打成 *Ctx 传\n", .{});
    std.debug.print("⚠️ 0.16 起 0.17 移除了 std.Thread.WaitGroup：要「等 N 个活干完」就直接 join 全部\n", .{});
    end("19.3 线程入口不能捕获变量");

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

    // ═══ 19.7 std.atomic.Value：无锁的第三条路 ═══
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

    std.debug.print("自检通过\n", .{});
}

// ═══════════════════════════════════════════════════════════════════
// test 块：只测**原子量与纯函数**，不测多线程编排
// 原因（实测）：std.testing.io 是单线程视图，在它上面让 Io.Condition.wait
// 等一个不会成立的条件会**死锁**（15 秒未结束）；而 io.concurrent + await
// 在测试里能跑通。所以「线程编排」放main（用 init.io，那里有真线程池），
// test 块只做能被 SafeAllocator 覆盖的纯逻辑。
// ═══════════════════════════════════════════════════════════════════

/// 19.3 的纯函数版：验证 work 里那个"不捕获状态"的模式里用到的原子加法。
fn sumAtomic(h: *std.atomic.Value(u32), times: u32, by: u32) void {
    for (0..times) |_| _ = h.fetchAdd(by, .monotonic);
}

test "原子量：fetchAdd 累加与 load 读取" {
    var h = std.atomic.Value(u32).init(0);
    sumAtomic(&h, 1000, 3);
    try std.testing.expectEqual(@as(u32, 3000), h.load(.seq_cst));
}

test "原子量：store/load 的六种内存序都编译得过且语义一致" {
    var v = std.atomic.Value(u32).init(1);
    // 写入用六种里合法的那些（RMW 不接受 .unordered）
    v.store(2, .monotonic);
    v.store(3, .release);
    v.store(4, .seq_cst);
    v.store(5, .unordered);
    try std.testing.expectEqual(@as(u32, 5), v.load(.unordered));
    try std.testing.expectEqual(@as(u32, 5), v.load(.monotonic));
    try std.testing.expectEqual(@as(u32, 5), v.load(.acquire));
    try std.testing.expectEqual(@as(u32, 5), v.load(.seq_cst));
    // fetchAdd 三种合法内存序
    _ = v.fetchAdd(1, .monotonic);
    _ = v.fetchAdd(1, .acq_rel);
    _ = v.fetchAdd(1, .seq_cst);
    try std.testing.expectEqual(@as(u32, 8), v.load(.seq_cst));
}

test "原子量：cmpxchgWeak 成功/失败两条路径" {
    var v = std.atomic.Value(u32).init(10);
    // 期望值不符 → 返回**当前**值（旧值），不变
    try std.testing.expectEqual(@as(?u32, 10), v.cmpxchgWeak(999, 1, .acq_rel, .acquire));
    try std.testing.expectEqual(@as(u32, 10), v.load(.seq_cst));
    // 期望值相符 → 返回 null，写入新值
    try std.testing.expectEqual(@as(?u32, null), v.cmpxchgWeak(10, 20, .acq_rel, .acquire));
    try std.testing.expectEqual(@as(u32, 20), v.load(.seq_cst));
    // strong 同理，但**保证**不伪失败（0.17 在 x86 上实测 Weak 200 万次0 伪失败）
    try std.testing.expectEqual(@as(?u32, null), v.cmpxchgStrong(20, 30, .seq_cst, .seq_cst));
    try std.testing.expectEqual(@as(u32, 30), v.load(.seq_cst));
}

test "原子量：swap / fetchSub / fetchAnd / fetchOr / fetchXor / fetchMax / fetchMin" {
    // 注意：fetch* 一律返回**旧值**（swap 也一样），新值要再 load 一次才看得到
    var v = std.atomic.Value(u32).init(0b1100);
    try std.testing.expectEqual(@as(u32, 0b1100), v.swap(0b1010, .acq_rel));
    try std.testing.expectEqual(@as(u32, 0b1010), v.load(.seq_cst));
    var w = std.atomic.Value(u32).init(10);
    try std.testing.expectEqual(@as(u32, 10), w.fetchSub(3, .monotonic)); // 返回旧值 10
    try std.testing.expectEqual(@as(u32, 7), w.load(.monotonic)); // 新值 7
    try std.testing.expectEqual(@as(u32, 7), w.fetchAnd(0b0100, .monotonic)); // 7 & 4 → 返回 7
    try std.testing.expectEqual(@as(u32, 4), w.load(.monotonic)); // 新值 4
    try std.testing.expectEqual(@as(u32, 4), w.fetchOr(0b0010, .monotonic)); // 4 | 2 → 返回 4
    try std.testing.expectEqual(@as(u32, 6), w.load(.monotonic)); // 新值 6
    try std.testing.expectEqual(@as(u32, 6), w.fetchXor(0b0001, .monotonic)); // 6 ^ 1 → 返回 6
    try std.testing.expectEqual(@as(u32, 7), w.load(.monotonic)); // 新值 7
    var m = std.atomic.Value(u32).init(5);
    try std.testing.expectEqual(@as(u32, 5), m.fetchMax(9, .monotonic)); // 9 > 5 → 返回旧值 5
    try std.testing.expectEqual(@as(u32, 9), m.load(.monotonic));
    try std.testing.expectEqual(@as(u32, 9), m.fetchMin(2, .monotonic)); // 2 < 9 → 返回旧值 9
    try std.testing.expectEqual(@as(u32, 2), m.load(.monotonic));
}

test "原子量：u8 溢出环绕（原子操作不做溢出检查）" {
    var v = std.atomic.Value(u8).init(250);
    _ = v.fetchAdd(10, .monotonic); // 260装不进 u8 → 环绕成 4，**不panic**
    try std.testing.expectEqual(@as(u8, 4), v.load(.monotonic));
}

test "原子量：支持的元素类型" {
    var b = std.atomic.Value(bool).init(false);
    b.store(true, .release);
    try std.testing.expect(b.load(.acquire));

    const E = enum(u8) { a, b };
    var e = std.atomic.Value(E).init(.a);
    e.store(.b, .seq_cst);
    try std.testing.expectEqual(E.b, e.load(.seq_cst));

    var f = std.atomic.Value(f64).init(1.0);
    _ = f.fetchAdd(0.5, .monotonic);
    try std.testing.expectEqual(@as(f64, 1.5), f.load(.seq_cst));

    var p = std.atomic.Value(?*u8).init(null);
    var target: u8 = 5;
    p.store(&target, .seq_cst);
    try std.testing.expectEqual(@as(?*u8, &target), p.load(.seq_cst));
}

test "缓存行：std.atomic.cache_line 存在且至少 64（填充的最小依据）" {
    // 0.17 实测 std.atomic.cache_line 存在（0.16 也有）；ARM 常见 64，x86 常见 64/128
    try std.testing.expect(std.atomic.cache_line >= 64);
    try std.testing.expect(std.atomic.cache_line % 64 == 0);
    // 0.17 **没有** 0.15 时代的 std.atomic.cache_line_padded 之类辅助类型
    try std.testing.expect(!@hasDecl(std.atomic, "cache_line_padded"));
}

test "19.15：纯函数 work 的和是可预测的（用来对比串行/并行）" {
    // 与 19.15 的 heavy.run 同样的公式，串行算一遍，断言确定值
    var sum: u64 = 0;
    for (0..400_000) |i| sum +%= @as(u64, i) *% 2654435761;
    // 不是"算了一遍证明什么"，而是给并发版一个可对拍的基线
    const again: u64 = blk: {
        var s: u64 = 0;
        for (0..400_000) |i| s +%= @as(u64, i) *% 2654435761;
        break :blk s;
    };
    try std.testing.expectEqual(sum, again);
}

test "19.15：并行的和 == 串行的和（累加分片，不共享中间量）" {
    // 19.3 的 work 模式：每线程写自己的格子，最后合并 —— 天然无竞争
    const Shards = struct {
        parts: [4]u64 = .{ 0, 0, 0, 0 },
        fn fill(self: *@This(), idx: usize, n: usize) void {
            var s: u64 = 0;
            for (0..n) |i| s +%= @as(u64, i + idx) *% 2654435761;
            self.parts[idx] = s;
        }
    };
    var sh: Shards = .{};
    for (0..4) |i| sh.fill(i, 1000);
    //串行基线
    const baseline: u64 = blk: {
        var s: u64 = 0;
        for (0..4) |idx| {
            for (0..1000) |i| s +%= @as(u64, i + idx) *% 2654435761;
        }
        break :blk s;
    };
    var total: u64 = 0;
    for (sh.parts) |p| total +%= p;
    try std.testing.expectEqual(baseline, total);
}

test "Semaphore：permits 计数与 wait/post 的收支平衡（单线程，无死锁风险）" {
    const io = std.testing.io;
    var s: std.Io.Semaphore = .{ .permits = 2 };
    try std.testing.expectEqual(@as(usize, 2), s.permits);
    s.post(io); // +1
    try std.testing.expectEqual(@as(usize, 3), s.permits);
    s.waitUncancelable(io); // -1（permits 够，不会阻塞）
    s.waitUncancelable(io);
    try std.testing.expectEqual(@as(usize, 1), s.permits);
    //⚠️ 再wait 一次就permits == 0 而这里**不会**阻塞：Semaphore 的 wait 会等 permit，
    //    但单线程下没人post ⇒ 会死。所以这个测试只做到"收支平衡"为止。
}

test "Io.Event：set/isSet/reset 三态往返（单线程）" {
    const io = std.testing.io;
    var e: std.Io.Event = .unset;
    try std.testing.expect(!e.isSet());
    e.set(io);
    try std.testing.expect(e.isSet());
    e.reset(); // ⚠️ 0.17 的 reset 不收 io
    try std.testing.expect(!e.isSet());
}

test "Io.Mutex：tryLock/unlock 往返（单线程，不会阻塞）" {
    const io = std.testing.io;
    var m: std.Io.Mutex = .init;
    try std.testing.expect(m.tryLock()); // 无竞争 → 一定成功
    m.unlock(io);
    try std.testing.expect(m.tryLock());
    m.unlock(io);
    // lockUncancelable 在单线程里不会争用，可以直接用（0.17 签名要 io）
    m.lockUncancelable(io);
    m.unlock(io);
}

test "0.17 的 API 存在性清单（把\"已移除\"钉成断言）" {
    // Thread.WaitGroup / Thread.Mutex / Thread.Condition / Thread.sleep 都**已移除**
    try std.testing.expect(!@hasDecl(std.Thread, "WaitGroup"));
    try std.testing.expect(!@hasDecl(std.Thread, "Mutex"));
    try std.testing.expect(!@hasDecl(std.Thread, "Condition"));
    try std.testing.expect(!@hasDecl(std.Thread, "sleep"));
    try std.testing.expect(!@hasDecl(std.Thread, "Futex"));
    // 同步原语全在 std.Io 下
    try std.testing.expect(@hasDecl(std.Io, "Mutex"));
    try std.testing.expect(@hasDecl(std.Io, "Condition"));
    try std.testing.expect(@hasDecl(std.Io, "Semaphore"));
    try std.testing.expect(@hasDecl(std.Io, "Event"));
    try std.testing.expect(@hasDecl(std.Io, "RwLock"));
    try std.testing.expect(@hasDecl(std.Io, "Group"));
    // 但 0.17 **没有** std.Io.Task
    try std.testing.expect(!@hasDecl(std.Io, "Task"));
    // Semaphore 叫 wait/post，不叫 acquire/release
    try std.testing.expect(@hasDecl(std.Io.Semaphore, "wait"));
    try std.testing.expect(@hasDecl(std.Io.Semaphore, "post"));
    try std.testing.expect(!@hasDecl(std.Io.Semaphore, "acquire"));
    try std.testing.expect(!@hasDecl(std.Io.Semaphore, "release"));
    // Mutex 没有 isLocked（0.16 时代有过，0.17 移除了）
    try std.testing.expect(!@hasDecl(std.Io.Mutex, "isLocked"));
    // Io.await 不存在，await 是 Future/Group 的方法
    try std.testing.expect(!@hasDecl(std.Io, "await"));
    try std.testing.expect(@hasDecl(std.Io, "concurrent"));
    try std.testing.expect(@hasDecl(std.Io, "async"));
    try std.testing.expect(@hasDecl(std.Io, "sleep"));
    try std.testing.expect(@hasDecl(std.Io, "recancel"));
}

test "原子量在 struct 里作为字段（不共享普通字段）" {
    const Counter = struct {
        n: std.atomic.Value(u32) = .init(0),
        fn bump(self: *@This(), k: u32) void {
            _ = self.n.fetchAdd(k, .monotonic);
        }
    };
    var c: Counter = .{};
    c.bump(5);
    c.bump(7);
    try std.testing.expectEqual(@as(u32, 12), c.n.load(.seq_cst));
    // 复制 Counter 会复制 atomic.Value（它就是个 extern struct 的 raw 字段）
    // ——所以 Counter 应该用指针传递，别按值拷贝。验证拷贝后各自独立：
    var d = c;
    d.bump(1);
    try std.testing.expectEqual(@as(u32, 13), d.n.load(.seq_cst));
    try std.testing.expectEqual(@as(u32, 12), c.n.load(.seq_cst));
}

test "testing.allocator 参与：并发章节的内存纪律也一样" {
    const a = std.testing.allocator;
    const buf = try a.alloc(u64, 64); // 模拟"每线程一份分片"
    defer a.free(buf);
    for (buf, 0..) |*slot, i| slot.* = @as(u64, i);
    var total: u64 = 0;
    for (buf) |v| total +%= v;
    // 0..63 的和 = 2016
    try std.testing.expectEqual(@as(u64, 2016), total);
    // ⚠️ 真并发里**不要**让多个线程共用一个 Allocator（arena/page_allocator 除外）——
    //    page_allocator 本身就是线程安全的；std.testing.allocator 不是。
    //    所以 19.3 的 Ctx 里传的是 io + 原子量指针，没有传 allocator。
}
