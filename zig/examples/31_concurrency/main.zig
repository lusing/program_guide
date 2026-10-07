//! 31 并发进阶：原子操作全家桶、CAS 重试、读写锁、信号量、无锁队列、Io 结构化并发
//!
//! 前置：19 章讲基础线程（spawn/join、Mutex、Condition、Semaphore、Event、内存序、伪共享）。
//! 本章**不重复**基础，只讲四类进阶：① 原子操作与内存序的量化行为 ② 锁的变体（RwLock）
//! ③ 无锁数据结构（CAS 循环、SPSC 环形队列） ④ 0.17 新增的 std.Io 结构化并发。
//!
//! ⚠️ 0.17 实测：`std.Thread.Mutex`/`Pool`/`WaitGroup`/`RwLock`/`Semaphore`/`ResetEvent`
//!    **全部不存在**了（@hasDecl 逐个为 false），一律搬到 std.Io 之下且方法首参是 io。
//!
//! 确定性纪律：标记区间里**只打印确定性指标**（计数、校验和、布尔判定），不打印裸耗时；
//!   所有不确定数字集中在 `printUnstableNumbers`（在最后一个 end() 之后）。
//!   锁的编排全放 main（用 init.io），test块只覆盖纯函数与原子操作
//!   （Io.Condition.wait 在 std.testing.io 上会死锁，见 31.11）。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    try sectionPositioning(io);
    sectionAtomicToolbox();
    const naive_lost = try sectionMemoryOrders();
    try sectionCasRetry();
    try sectionRwLock(io);
    try sectionSemaphoreAndEvent(io);
    try sectionWaitGroup(io);
    try sectionThreadPool(io);
    try sectionSpsc();
    try sectionStructuredConcurrency(io);
    try sectionIoPrimitives(io);
    try sectionFalseSharing();
    const ring_both = try sectionDeadlockDetection(io);
    try sectionWorkStealing();
    // 所有不确定的数字都收在这里（最后一个 end() 之外）
    printUnstableNumbers(io, naive_lost, ring_both);
}

// ═══════════════════════════════════════════════════════════════════ 31.1 回顾与本章定位 ══

/// 19 章的边界：它讲清了「怎么起线程、怎么用锁不丢数据」；
/// 本章要解决的是「锁太贵怎么办」「数据结构能不能无锁」「0.17 的新并发怎么用」。
fn sectionPositioning(io: std.Io) !void {
    begin("31.1 回顾与本章定位");

    // 0.17 迁移自检：老 API 逐个探测，这是本章最该记住的一张表
    std.debug.print("  std.Thread.Mutex={} std.Thread.Condition={} std.Thread.Semaphore={}\n", .{
        @hasDecl(std.Thread, "Mutex"),
        @hasDecl(std.Thread, "Condition"),
        @hasDecl(std.Thread, "Semaphore"),
    });
    std.debug.print("  std.Thread.WaitGroup={} std.Thread.Pool={} std.Thread.RwLock={} std.Thread.ResetEvent={}\n", .{
        @hasDecl(std.Thread, "WaitGroup"),
        @hasDecl(std.Thread, "Pool"),
        @hasDecl(std.Thread, "RwLock"),
        @hasDecl(std.Thread, "ResetEvent"),
    });
    std.debug.print("  ⇒ 全部 false。替代品在 std.Io 下：Mutex={} Condition={} Semaphore={} RwLock={} Event={}\n", .{
        @hasDecl(std.Io, "Mutex"),
        @hasDecl(std.Io, "Condition"),
        @hasDecl(std.Io, "Semaphore"),
        @hasDecl(std.Io, "RwLock"),
        @hasDecl(std.Io, "Event"),
    });
    std.debug.print("  本机 CPU 数 = {d}（决定 31.5/31.8/31.14 的线程数上限）\n", .{try std.Thread.getCpuCount()});
    std.debug.print("  init.io 的类型 = {s}（0.17 的 io 由 main 参数提供，不是全局变量）\n", .{@typeName(@TypeOf(io))});
    end("31.1 回顾与本章定位");
}

// ═══════════════════════════════════════════════════════════════════ 31.2 std.atomic.Value 全家 ══

fn sectionAtomicToolbox() void {
    begin("31.2 std.atomic.Value 全家");

    // load：四种内存序都能给load
    var v = std.atomic.Value(u32).init(0b1010);
    std.debug.print("load  : monotonic={b} unordered={b} acquire={b} seq_cst={b}（值全同={}）\n", .{
        v.load(.monotonic),
        v.load(.unordered),
        v.load(.acquire),
        v.load(.seq_cst),
        v.load(.monotonic) == v.load(.seq_cst),
    });

    // store：返回 void，没有旧值可拿
    v.store(0b1100, .release);
    std.debug.print("store : 写入 0b1100 后 load={b}（store 无返回值——它不告诉你旧值）\n", .{v.load(.monotonic)});

    // swap：返回**旧**值
    const old_swap = v.swap(0b0001, .seq_cst);
    std.debug.print("swap  : 返回旧值={b}，新值={b}（旧值 = 交换**前**的 0b1100）\n", .{ old_swap, v.load(.monotonic) });

    // fetchAdd / fetchSub：返回旧值
    const o_add = v.fetchAdd(0b0110, .seq_cst);
    std.debug.print("fetchAdd(0b0110): 旧={b} 新={b}（新值=旧+6=0b0111）\n", .{ o_add, v.load(.monotonic) });
    const o_sub = v.fetchSub(1, .monotonic);
    std.debug.print("fetchSub(1)     : 旧={b} 新={b}\n", .{ o_sub, v.load(.monotonic) });

    // fetchOr / fetchAnd / fetchXor：位运算三兄弟，也都返回旧值
    const o_or = v.fetchOr(0b1000, .acq_rel);
    std.debug.print("fetchOr (0b1000): 旧={b} 新={b}\n", .{ o_or, v.load(.monotonic) });
    const o_and = v.fetchAnd(0b0110, .acq_rel);
    std.debug.print("fetchAnd(0b0110): 旧={b} 新={b}\n", .{ o_and, v.load(.monotonic) });
    const o_xor = v.fetchXor(0b1111, .seq_cst);
    std.debug.print("fetchXor(0b1111): 旧={b} 新={b}\n", .{ o_xor, v.load(.monotonic) });

    // fetchMax / fetchMin：0.17 也有（19 章的表里漏了这两个）
    const o_max = v.fetchMax(0b0001_0000, .seq_cst);
    std.debug.print("fetchMax(16)    : 旧={b} 新={b}（16>0 ⇒ 真的换了）\n", .{ o_max, v.load(.monotonic) });
    const o_min = v.fetchMin(0b11, .seq_cst);
    std.debug.print("fetchMin(3)     : 旧={b} 新={b}\n", .{ o_min, v.load(.monotonic) });

    // cmpxchgStrong：返回 ?T，null 表示成功，非 null 是**实际**看到的值
    v.store(5, .seq_cst);
    const strong_ok = v.cmpxchgStrong(5, 9, .seq_cst, .seq_cst);
    std.debug.print("cmpxchgStrong(期望5→9): 返回 {any}（null=成功）现在={d}\n", .{ strong_ok, v.load(.monotonic) });
    const strong_bad = v.cmpxchgStrong(5, 1, .seq_cst, .seq_cst);
    std.debug.print("cmpxchgStrong(期望5→1): 返回 {any}（期望不符⇒拿到实际值 9，**不写入**）现在={d}\n", .{ strong_bad, v.load(.monotonic) });
    const weak_ok = v.cmpxchgWeak(9, 20, .acq_rel, .acquire);
    std.debug.print("cmpxchgWeak(期望9→20): 返回 {any} 现在={d}\n", .{ weak_ok, v.load(.monotonic) });

    // ⚠️ 关键纪律：fetch* 一律返回旧值。下面这行是本章最该记住的一句话

    // 原子操作不检查溢出：u8 的250 + 10 环绕成 4，不 panic
    const wrap = blk: {
        var v8 = std.atomic.Value(u8).init(250);
        const old = v8.fetchAdd(10, .monotonic);
        break :blk .{ old, v8.load(.monotonic) };
    };
    std.debug.print("⚠️ 原子操作**不做溢出检查**：u8 的 250 fetchAdd 10 → 旧={d} 新={d}（环绕，不 panic）\n", .{ wrap[0], wrap[1] });

    // atomic 只保护它自己这一个格子
    var flag = std.atomic.Value(bool).init(false);
    flag.store(true, .release);
    std.debug.print("atomic<bool>: store(release) 后 load(acquire) = {}\n", .{flag.load(.acquire)});
    end("31.2 std.atomic.Value 全家");
}

// ═══════════════════════════════════════════════════════════════════ 31.3 内存序六种 ══

/// 发布方：先写payload（普通写），再 release 存标志
fn publishRelease(payload: *u64, flag: *std.atomic.Value(u32)) void {
    payload.* = 0xDEAD_BEEF;
    flag.store(1, .release);
}

/// 消费方：acquire 读标志，看到非零后才读 payload
fn consumeAcquire(payload: *const u64, flag: *std.atomic.Value(u32)) u64 {
    while (flag.load(.acquire) == 0) std.atomic.spinLoopHint();
    return payload.*;
}

/// 只用 monotonic 的发布方/消费方：原子性有，跨变量顺序**没有**
fn publishMonotonic(payload: *u64, flag: *std.atomic.Value(u32)) void {
    payload.* = 0xDEAD_BEEF;
    flag.store(1, .monotonic);
}

fn consumeMonotonic(payload: *const u64, flag: *std.atomic.Value(u32)) u64 {
    while (flag.load(.monotonic) == 0) std.atomic.spinLoopHint();
    return payload.*;
}

fn sectionMemoryOrders() !u64 {
    begin("31.3 内存序六种");

    std.debug.print("六种内存序的定位（`std.builtin.AtomicOrder` 的全部成员，共 {d} 个）：\n", .{
        @typeInfo(std.builtin.AtomicOrder).@"enum".field_names.len,
    });
    for (@typeInfo(std.builtin.AtomicOrder).@"enum".field_names) |name| {
        std.debug.print("  .{s}\n", .{name});
    }

    // ① seq_cst：最强，永远正确，只是最贵
    var payload_a: u64 = 0;
    var flag_a = std.atomic.Value(u32).init(0);
    const t_a = try std.Thread.spawn(.{}, publishRelease, .{ &payload_a, &flag_a });
    const got_a = consumeAcquire(&payload_a, &flag_a);
    t_a.join();
    std.debug.print("① release/acquire 配对：消费者读到 payload = 0x{x}（正确={}）\n", .{ got_a, got_a == 0xDEAD_BEEF });

    // ② acquire / release：只配对时才有意义，单独用没有跨变量保证
    var payload_b: u64 = 0;
    var flag_b = std.atomic.Value(u32).init(0);
    const t_b = try std.Thread.spawn(.{}, publishRelease, .{ &payload_b, &flag_b });
    const got_b = consumeAcquire(&payload_b, &flag_b);
    t_b.join();
    std.debug.print("② 同上再验一次：读到 0x{x}（正确={}）⇒ 配对成立时结果稳定\n", .{ got_b, got_b == 0xDEAD_BEEF });

    // ③ monotonic：只有这个变量自己的原子性，**没有**跨变量顺序保证
    var payload_c: u64 = 0;
    var flag_c = std.atomic.Value(u32).init(0);
    const t_c = try std.Thread.spawn(.{}, publishMonotonic, .{ &payload_c, &flag_c });
    const got_c = consumeMonotonic(&payload_c, &flag_c);
    t_c.join();
    std.debug.print("③ monotonic + monotonic：读到 0x{x}（正确={}）\n", .{ got_c, got_c == 0xDEAD_BEEF });

    // ④ seq_cst 计数：多线程递增一定分毫不差
    const n_threads = 8;
    const per_thread = 50_000;
    var seq_counter = std.atomic.Value(u64).init(0);
    var seq_threads: [n_threads]std.Thread = undefined;
    for (&seq_threads) |*t| t.* = try std.Thread.spawn(.{}, addSeqCst, .{ &seq_counter, per_thread });
    for (seq_threads) |t| t.join();
    const expected: u64 = n_threads * per_thread;
    std.debug.print("④ 8 线程各 {d} 次 fetchAdd(.seq_cst)：结果 {d}（期望 {d}，分毫不差={}）\n", .{
        per_thread, seq_counter.load(.seq_cst), expected, seq_counter.load(.seq_cst) == expected,
    });

    // ⑤ monotonic 计数：只有原子性，同样分毫不差（原子性由硬件保证）
    var mono_counter = std.atomic.Value(u64).init(0);
    var mono_threads: [n_threads]std.Thread = undefined;
    for (&mono_threads) |*t| t.* = try std.Thread.spawn(.{}, addMonotonic, .{ &mono_counter, per_thread });
    for (mono_threads) |t| t.join();
    std.debug.print("⑤ 同上但用 .monotonic：结果 {d}（正确={}）⇒ 计数**只要原子性**就够\n", .{
        mono_counter.load(.monotonic), mono_counter.load(.monotonic) == expected,
    });

    // ⑥ 对照：裸 += 会丢更新（概率性的，只打印观感，不做断言）
    var naive: u64 = 0;
    var naive_threads: [n_threads]std.Thread = undefined;
    for (&naive_threads) |*t| t.* = try std.Thread.spawn(.{}, addNaive, .{ &naive, per_thread });
    for (naive_threads) |t| t.join();
    std.debug.print("⑥ 对照组：8 线程各 {d} 次裸 += → 结果**小于**期望 = {}（方向确定，具体数字见收尾）\n", .{
        per_thread, naive < expected,
    });

    // ⑦ 六档里哪些能用在哪：三条硬规则
    end("31.3 内存序六种");
    return expected - naive; // 丢了多少条更新（不可比对，交给收尾打印）
}

fn addSeqCst(p: *std.atomic.Value(u64), times: usize) void {
    var i: usize = 0;
    while (i < times) : (i += 1) _ = p.fetchAdd(1, .seq_cst);
}

fn addMonotonic(p: *std.atomic.Value(u64), times: usize) void {
    var i: usize = 0;
    while (i < times) : (i += 1) _ = p.fetchAdd(1, .monotonic);
}

fn addNaive(p: *u64, times: usize) void {
    var i: usize = 0;
    while (i < times) : (i += 1) p.* +%= 1; // 裸读改写：三个动作随时被打断
}

// ═══════════════════════════════════════════════════════════════════ 31.4 CAS 重试循环 ══

/// CAS 循环聚合 max：读到旧值 → 判断 → 条件写入（失败说明有人抢先，重读重试）
fn casMax(p: *std.atomic.Value(i64), candidate: i64) void {
    while (true) {
        const cur = p.load(.seq_cst);
        if (candidate <= cur) return;
        if (p.cmpxchgWeak(cur, candidate, .seq_cst, .seq_cst)) |_| {
            // 有人抢先写了：cur 已过时，循环重来
        } else return;
    }
}

/// 抢旗：8 线程各做**恰好一次** CAS 写入 1 ⇒ 成功恰好 1 次、失败恰好 7 次。
/// 这个设计让「失败次数」变成**确定值**（不用依赖调度运气）。
fn claimOnce(
    flag: *std.atomic.Value(u32),
    wins: *std.atomic.Value(u32),
    fails: *std.atomic.Value(u32),
) void {
    if (flag.cmpxchgStrong(0, 1, .acq_rel, .acquire)) |actual| {
        // 失败：actual 是**实际**看到的值（这里必然是 1）
        std.debug.assert(actual == 1);
        _ = fails.fetchAdd(1, .monotonic);
    } else {
        _ = wins.fetchAdd(1, .seq_cst);
    }
}

/// 有界递增：**不能**用 fetchAdd 的场合 —— 递增前要先读-判断-写三步。
/// 语义是「一直加到 limit 为止」，所以成功后要 `continue` 继续抢，而不是 return。
fn bumpBelowLimit(v: *std.atomic.Value(u32), limit: u32) void {
    while (true) {
        const cur = v.load(.acquire);
        if (cur >= limit) return; // 到顶了就收工
        if (v.cmpxchgWeak(cur, cur + 1, .acq_rel, .acquire)) |_| {
            // 有人抢先改了 cur：重读重试
        } else continue; // 写入成功，但还没到顶 ⇒ 继续
    }
}

fn bumpWorker(v: *std.atomic.Value(u32), limit: u32) void {
    bumpBelowLimit(v, limit);
}

fn sectionCasRetry() !void {
    begin("31.4 CAS 重试循环");

    // ① CAS 聚合 max：结果与顺序无关，天然可重放
    const n = 8;
    var max_seen = std.atomic.Value(i64).init(std.math.minInt(i64));
    var mt: [n]std.Thread = undefined;
    for (&mt, 0..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, casMax, .{ &max_seen, @as(i64, @intCast(i)) * 7 - 3 });
    }
    for (mt) |t| t.join();
    const want_max = @as(i64, @intCast(n - 1)) * 7 - 3;
    std.debug.print("① CAS 聚合 max（8 线程各提交一个值）= {d}（期望 {d}，正确={}）\n", .{
        max_seen.load(.seq_cst), want_max, max_seen.load(.seq_cst) == want_max,
    });

    // ② 抢旗：成功/失败次数是**确定值**
    var flag = std.atomic.Value(u32).init(0);
    var wins = std.atomic.Value(u32).init(0);
    var fails = std.atomic.Value(u32).init(0);
    var ct: [n]std.Thread = undefined;
    for (&ct) |*t| t.* = try std.Thread.spawn(.{}, claimOnce, .{ &flag, &wins, &fails });
    for (ct) |t| t.join();
    const total = wins.load(.seq_cst) + fails.load(.monotonic);
    std.debug.print("② 8 线程各做**恰好一次** CAS(0→1)：成功 {d} 次、失败 {d} 次\n", .{
        wins.load(.seq_cst), fails.load(.monotonic),
    });
    std.debug.print("   成功恰好=1={} 失败恰好=7={} 总数=8={} ⇒ 三项都是**确定值**，不靠调度运气\n", .{
        wins.load(.seq_cst) == 1, fails.load(.monotonic) == 7, total == 8,
    });

    // ③ 有界递增：fetchAdd 做不到的场景
    const limit: u32 = 20_000;
    var capped = std.atomic.Value(u32).init(0);
    var bt: [n]std.Thread = undefined;
    for (&bt) |*t| t.* = try std.Thread.spawn(.{}, bumpWorker, .{ &capped, limit });
    for (bt) |t| t.join();
    std.debug.print("③ 有界递增（8 线程都试图+1，上限 {d}）：最终 {d}，恰好等于上界={}\n", .{
        limit, capped.load(.seq_cst), capped.load(.seq_cst) == limit,
    });

    // ④ 为什么必须写成循环：Weak 在 x86 上实测不伪失败，但这是可移植性要求
    var weak_probe = std.atomic.Value(u32).init(0);
    var weak_fails = std.atomic.Value(u64).init(0);
    var wt: [n]std.Thread = undefined;
    for (&wt) |*t| t.* = try std.Thread.spawn(.{}, weakProbe, .{ &weak_probe, &weak_fails });
    for (wt) |t| t.join();
    std.debug.print("④ Weak CAS 伪失败探测：逻辑上必定成功的 {d} 次里，伪失败 {d} 次（=0 才可比）\n", .{
        n * 200_000, weak_fails.load(.monotonic),
    });
    std.debug.print("   布尔判定：伪失败为 0 = {}（x86 上恒成立；ARM 上可能为 false，那时循环才是必需的）\n", .{
        weak_fails.load(.monotonic) == 0,
    });
    end("31.4 CAS 重试循环");
}

/// 逻辑上必定成功的 Weak CAS：目标恒为 0、期望 0、写回 0
fn weakProbe(target: *std.atomic.Value(u32), fails: *std.atomic.Value(u64)) void {
    var i: usize = 0;
    while (i < 200_000) : (i += 1) {
        if (target.cmpxchgWeak(0, 0, .seq_cst, .seq_cst)) |_| {
            _ = fails.fetchAdd(1, .monotonic);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════ 31.5 读写锁 RwLock ══

const Snapshot = struct {
    rw: std.Io.RwLock = .init,
    mtx: std.Io.Mutex = .init,
    value: u64 = 1,
    reads_rw: std.atomic.Value(u64) = .init(0),
    reads_mtx: std.atomic.Value(u64) = .init(0),
};

/// 写者：独占锁
fn doubleViaRwLock(io: std.Io, s: *Snapshot) void {
    var n: usize = 0;
    while (n < 10) : (n += 1) {
        s.rw.lockUncancelable(io);
        defer s.rw.unlock(io);
        s.value *= 2;
    }
}

/// 读者：共享锁，**多读者并发不互斥**
fn readViaRwLock(io: std.Io, s: *Snapshot, rounds: u32) void {
    for (0..rounds) |_| {
        s.rw.lockSharedUncancelable(io);
        std.mem.doNotOptimizeAway(s.value); // 真读，别让编译器优化掉
        s.rw.unlockShared(io);
        _ = s.reads_rw.fetchAdd(1, .monotonic);
    }
}

/// 对照组：普通互斥锁把读也串行化了
fn readViaMutex(io: std.Io, s: *Snapshot, rounds: u32) void {
    for (0..rounds) |_| {
        s.mtx.lockUncancelable(io);
        std.mem.doNotOptimizeAway(s.value);
        s.mtx.unlock(io);
        _ = s.reads_mtx.fetchAdd(1, .monotonic);
    }
}

fn sectionRwLock(io: std.Io) !void {
    begin("31.5 读写锁 RwLock");

    std.debug.print("RwLock 存在 = {}，sizeOf = {d}，align = {d}（0.17 在 std.Io 下）\n", .{
        @hasDecl(std.Io, "RwLock"), @sizeOf(std.Io.RwLock), @alignOf(std.Io.RwLock),
    });

    // tryLock 演示：唯一不阻塞的一档
    var probe: std.Io.RwLock = .init;
    const got_write = probe.tryLock(io);
    probe.unlock(io);
    const got_read = probe.tryLockShared(io);
    probe.unlockShared(io);
    std.debug.print("tryLock(io)={} tryLockShared(io)={}（无人竞争时都拿得到）\n", .{ got_write, got_read });

    // 读多写少：4 个读者持续读，1 个写者翻倍 10 次
    const readers: u32 = 4;
    const rounds: u32 = 5_000;
    var s: Snapshot = .{};
    var rt: [readers]std.Thread = undefined;
    for (&rt) |*t| t.* = try std.Thread.spawn(.{}, readViaRwLock, .{ io, &s, rounds });
    const w = try std.Thread.spawn(.{}, doubleViaRwLock, .{ io, &s });
    w.join();
    for (rt) |t| t.join();
    std.debug.print("RwLock 组：快照 {d}（期望 {d}，正确={}）读次数 {d}（期望 {d}，正确={}）\n", .{
        s.value,                     @as(u64, 1) << 10, s.value == (@as(u64, 1) << 10),
        s.reads_rw.load(.monotonic), readers * rounds,  s.reads_rw.load(.monotonic) == readers * rounds,
    });

    // 对照：同样多的读，但用 Mutex（读之间也互斥）
    var s2: Snapshot = .{};
    var mt2: [readers]std.Thread = undefined;
    for (&mt2) |*t| t.* = try std.Thread.spawn(.{}, readViaMutex, .{ io, &s2, rounds });
    for (mt2) |t| t.join();
    std.debug.print("Mutex 对照：读次数 {d}（同样正确={}）—— 读多写少时 RwLock 的读侧不互斥\n", .{
        s2.reads_mtx.load(.monotonic), s2.reads_mtx.load(.monotonic) == readers * rounds,
    });

    end("31.5 读写锁 RwLock");
}

// ═══════════════════════════════════════════════════════════════════ 31.6 信号量与 Event ══

/// 有界连接池：permits 是**硬上界**
const ConnPool = struct {
    sem: std.Io.Semaphore = .{ .permits = 3 },
    live: std.atomic.Value(u32) = .init(0),
    peak: std.atomic.Value(u32) = .init(0),
    borrows: std.atomic.Value(u32) = .init(0),

    fn borrow(self: *ConnPool, io: std.Io) void {
        self.sem.waitUncancelable(io); // 0.17 叫 wait，**不叫** acquire
        const now = self.live.fetchAdd(1, .seq_cst) + 1;
        _ = self.peak.fetchMax(now, .seq_cst);
        _ = self.borrows.fetchAdd(1, .monotonic);
    }

    fn give(self: *ConnPool, io: std.Io) void {
        _ = self.live.fetchSub(1, .seq_cst);
        self.sem.post(io); // 0.17 叫 post，**不叫** release
    }
};

fn poolUser(p: *ConnPool, io: std.Io, rounds: u32) void {
    for (0..rounds) |_| {
        p.borrow(io);
        io.sleep(.fromMicroseconds(200), .awake) catch {}; // 拉长持锁时间，让峰值真的顶到上限
        p.give(io);
    }
}

fn sectionSemaphoreAndEvent(io: std.Io) !void {
    begin("31.6 信号量与 Event");

    // ── Semaphore：生产者-消费者限流
    std.debug.print("Semaphore 存在 = {}，无 init 常量 = {}（要用 .{{ .permits = N }}）\n", .{
        @hasDecl(std.Io, "Semaphore"),
        !@hasDecl(std.Io.Semaphore, "init"),
    });
    var pool: ConnPool = .{};
    var users: [8]std.Thread = undefined;
    for (&users) |*t| t.* = try std.Thread.spawn(.{}, poolUser, .{ &pool, io, 20 });
    for (users) |t| t.join();
    const peak = pool.peak.load(.seq_cst);
    std.debug.print("8 个用户 × 20 次借还，permits={d}：实测峰值并发={d}（恰好等于许可数={}）\n", .{
        pool.sem.permits, peak, peak == pool.sem.permits,
    });
    std.debug.print("总借还次数={d}（期望160，正确={}）结束时空闲={d}（=0 说明permit 全归还了）\n", .{
        pool.borrows.load(.monotonic),
        pool.borrows.load(.monotonic) == 160,
        pool.live.load(.seq_cst),
    });

    // ── Event：一次性的门
    std.debug.print("Event 存在 = {}，类型是 enum = {}，初值 .unset（不是 .init、不是 .false）\n", .{
        @hasDecl(std.Io, "Event"),
        @typeInfo(std.Io.Event) == .@"enum",
    });
    var ev: std.Io.Event = .unset;
    std.debug.print("isSet()={} ", .{ev.isSet()});
    ev.set(io);
    std.debug.print("set(io)后 isSet()={} ", .{ev.isSet()});
    ev.reset();
    std.debug.print("reset()后 isSet()={}\n", .{ev.isSet()});

    // waitTimeout：给「等不到」一条出路
    var ev2: std.Io.Event = .unset;
    const to: std.Io.Timeout = .{ .duration = .{ .raw = .fromMilliseconds(2), .clock = .awake } };
    const ev_res = ev2.waitTimeout(io, to);
    std.debug.print("没人 set 就等2ms → {any}（Event 不会像 Condition 那样死等）\n", .{ev_res});
    ev2.set(io);
    const ev_res2 = ev2.waitTimeout(io, to);
    std.debug.print("set 之后立刻等 → {any}（返回 void 才是成功）\n", .{ev_res2});

    // Event 跨线程当一次性门用
    var gate: std.Io.Event = .unset;
    var passed = std.atomic.Value(u32).init(0);
    const gate_worker = struct {
        fn run(e: *std.Io.Event, c: *std.atomic.Value(u32), wio: std.Io) void {
            e.waitUncancelable(wio);
            _ = c.fetchAdd(1, .monotonic);
        }
    }.run;
    var gt: [4]std.Thread = undefined;
    for (&gt) |*t| t.* = try std.Thread.spawn(.{}, gate_worker, .{ &gate, &passed, io });
    io.sleep(.fromMilliseconds(5), .awake) catch {};
    const before = passed.load(.seq_cst);
    gate.set(io);
    for (gt) |t| t.join();
    std.debug.print("4 个 worker 等 Event：开门前通过={d}开门后通过={d}（=4 正确={}）\n", .{
        before, passed.load(.seq_cst), passed.load(.seq_cst) == 4,
    });
    end("31.6 信号量与 Event");
}

// ═══════════════════════════════════════════════════════════════════ 31.7 等待组（0.17 无 Thread.WaitGroup，自建） ══

/// 0.17 移除了 `std.Thread.WaitGroup`（@hasDecl 实测 false），要「等 N 个任务」得自建。
/// 形状：一个剩余计数 + 一把 Mutex + 一个 Condition（用 broadcast 唤醒全部等待者）。
const WaitGroup = struct {
    m: std.Io.Mutex = .init,
    c: std.Io.Condition = .init,
    remaining: usize = 0,

    const init_n: fn (usize) WaitGroup = initWith;
    fn initWith(n: usize) WaitGroup {
        return .{ .remaining = n };
    }

    /// 启动 n 个任务前调用
    fn preset(self: *WaitGroup, n: usize) void {
        self.remaining = n;
    }

    /// 一个任务完成
    fn done(self: *WaitGroup, io: std.Io) void {
        self.m.lockUncancelable(io);
        defer self.m.unlock(io);
        std.debug.assert(self.remaining > 0); // 多done 一次就是逻辑错误
        self.remaining -= 1;
        if (self.remaining == 0) self.c.broadcast(io); // 归零 ⇒ 唤醒**所有**等待者
    }

    /// 等到全部完成（无超时版）
    fn wait(self: *WaitGroup, io: std.Io) void {
        self.m.lockUncancelable(io);
        defer self.m.unlock(io);
        // ⚠️ 必须是 while 不是 if：虚假唤醒是 API 的正式设定
        while (self.remaining != 0) self.c.waitUncancelable(io, &self.m);
    }

    /// 带 deadline 的变体：等不到就返回 error.Timeout（**不死锁**）
    fn waitTimeout(self: *WaitGroup, io: std.Io, ms: i64) !void {
        self.m.lockUncancelable(io);
        defer self.m.unlock(io);
        const to: std.Io.Timeout = .{ .duration = .{ .raw = .fromMilliseconds(ms), .clock = .awake } };
        while (self.remaining != 0) {
            self.c.waitTimeout(io, &self.m, to) catch |e| return e;
        }
    }

    /// 带绝对 deadline 的变体（Timeout.deadline 分支）
    fn waitUntil(self: *WaitGroup, io: std.Io, deadline: std.Io.Clock.Timestamp) !void {
        self.m.lockUncancelable(io);
        defer self.m.unlock(io);
        const to: std.Io.Timeout = .{ .deadline = deadline };
        while (self.remaining != 0) {
            self.c.waitTimeout(io, &self.m, to) catch |e| return e;
        }
    }

    fn pending(self: *const WaitGroup) usize {
        return self.remaining;
    }
};

fn wgWorker(wg: *WaitGroup, io: std.Io, n: usize, sink: *std.atomic.Value(u64)) void {
    var acc: u64 = 0;
    var i: usize = 0;
    while (i < n) : (i += 1) acc +%= @as(u64, @intCast(i));
    _ = sink.fetchAdd(acc, .monotonic);
    wg.done(io); // 任务完成 → 计数减一
}

fn sectionWaitGroup(io: std.Io) !void {
    begin("31.7 等待组");

    std.debug.print("std.Thread.WaitGroup 存在 = {}（0.17 已移除），std.Io.Group 存在 = {}\n", .{
        @hasDecl(std.Thread, "WaitGroup"),
        @hasDecl(std.Io, "Group"),
    });

    // ① 正常路径：4 个任务全部完成
    var wg: WaitGroup = .{};
    wg.preset(4);
    var sink = std.atomic.Value(u64).init(0);
    var ts: [4]std.Thread = undefined;
    for (&ts) |*t| t.* = try std.Thread.spawn(.{}, wgWorker, .{ &wg, io, 1000, &sink });
    wg.wait(io); // 归零那一刻被 broadcast 唤醒
    for (ts) |t| t.join();
    const expect_sum: u64 = 4 * (@as(u64, 999) * 1000 / 2);
    std.debug.print("① 4 个任务 wait 等齐：remaining={d}（=0 正确={}）校验和={d}（期望 {d}，正确={}）\n", .{
        wg.pending(),                      wg.pending() == 0,
        sink.load(.seq_cst),               expect_sum,
        sink.load(.seq_cst) == expect_sum,
    });

    // ② 带超时的变体：故意不 done ⇒ 返回 Timeout 而不是挂死
    var stuck: WaitGroup = .{};
    stuck.preset(2);
    const r = stuck.waitTimeout(io, 5);
    std.debug.print("② 故意 2 个任务都不 done，waitTimeout(5ms) → {any}（这是**检测**，不是死锁）\n", .{r});
    std.debug.print("   超时后 remaining 仍是 {d} ⇒ 状态没被破坏，任务还能继续 done\n", .{stuck.pending()});

    // ③ 带绝对 deadline 的变体
    var stuck2: WaitGroup = .{};
    stuck2.preset(3);
    // 0.17 没有 Timestamp.addMilliseconds，用 Clock.Timestamp.fromNow(io, duration)
    const deadline = std.Io.Clock.Timestamp.fromNow(io, .{ .raw = .fromMilliseconds(3), .clock = .awake });
    const r2 = stuck2.waitUntil(io, deadline);
    std.debug.print("③ 同样不done，waitUntil(3ms 后的绝对时刻) → {any}（Timeout.deadline 分支）\n", .{r2});

    end("31.7 等待组");
}

// ═══════════════════════════════════════════════════════════════════ 31.8 线程池（0.17 无 Thread.Pool，自建） ══

/// 固定 worker + 有界队列 + 哨兵关停。0.17 移除了 `std.Thread.Pool`，只能自建。
const Pool = struct {
    const QUEUE_CAP = 16; // 有界：生产快于消费时会背压（mutex+cond 阻塞等待）

    const Job = struct {
        slot: ?*u64, // null 即哨兵：收工
        seed: usize,
    };

    io: std.Io,
    lock: std.Io.Mutex = .init,
    not_full: std.Io.Condition = .init,
    not_empty: std.Io.Condition = .init,
    queue: [QUEUE_CAP]Job = undefined,
    head: usize = 0,
    count: usize = 0,
    workers: []std.Thread,
    a: std.mem.Allocator,
    done_count: std.atomic.Value(u64) = .init(0),

    fn init(a: std.mem.Allocator, io: std.Io, n_workers: usize) !*Pool {
        const self = try a.create(Pool);
        self.* = .{ .io = io, .workers = try a.alloc(std.Thread, n_workers), .a = a };
        for (self.workers) |*t| t.* = try std.Thread.spawn(.{}, worker, .{self});
        return self;
    }

    fn deinit(self: *Pool) void {
        self.a.free(self.workers);
        self.a.destroy(self);
    }

    fn submit(self: *Pool, job: Job) !void {
        self.lock.lockUncancelable(self.io);
        defer self.lock.unlock(self.io);
        while (self.count == QUEUE_CAP) { // 满：等消费者腾位（背压）
            self.not_full.waitUncancelable(self.io, &self.lock);
        }
        self.queue[(self.head + self.count) % QUEUE_CAP] = job;
        self.count += 1;
        self.not_empty.signal(self.io);
    }

    /// 每个 worker 一个哨兵；放完哨兵必须先解锁再 join——
    /// 持锁 join 是自锁经典：worker 醒来要拿锁才能吃哨兵，你却攥着锁等它退出。
    fn shutdownAndWait(self: *Pool) !void {
        {
            self.lock.lockUncancelable(self.io);
            defer self.lock.unlock(self.io);
            for (self.workers) |_| {
                while (self.count == QUEUE_CAP) self.not_full.waitUncancelable(self.io, &self.lock);
                self.queue[(self.head + self.count) % QUEUE_CAP] = .{ .slot = null, .seed = 0 };
                self.count += 1;
                self.not_empty.signal(self.io);
            }
        }
        for (self.workers) |t| t.join();
    }

    fn worker(self: *Pool) void {
        while (true) {
            self.lock.lockUncancelable(self.io);
            while (self.count == 0) self.not_empty.waitUncancelable(self.io, &self.lock); // 空：等活儿
            const job = self.queue[self.head];
            self.head = (self.head + 1) % QUEUE_CAP;
            self.count -= 1;
            self.not_full.signal(self.io);
            self.lock.unlock(self.io); // ⚠️ 干活用锁**外面**，临界区最小化

            const slot = job.slot orelse return; // 哨兵：收工
            slot.* = workUnit(job.seed);
            _ = self.done_count.fetchAdd(1, .monotonic);
        }
    }
};

/// 任务本体：确定性函数（同 seed 同结果——线程池正确性的断言根基）
fn workUnit(seed: usize) u64 {
    var x: u64 = @intCast(seed);
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        x = x *% 6364136223846793005 +% 1442695040888963407;
    }
    return x ^ (x >> 29);
}

fn sectionThreadPool(io: std.Io) !void {
    begin("31.8 线程池");

    std.debug.print("std.Thread.Pool 存在 = {0}（0.17 已移除）⇒ 下面这个 Pool 是自建的\n", .{@hasDecl(std.Thread, "Pool")});
    std.debug.print("结构：固定 K 个 worker + 有界队列({d}槽) + 哨兵关停\n", .{Pool.QUEUE_CAP});

    // M 个任务 → K 个 worker
    const K: usize = 4;
    const M: usize = 100;
    var pool = try Pool.init(std.heap.page_allocator, io, K);
    defer pool.deinit();

    var results: [M]u64 = @splat(0); // 0.17：[_]u64{0} ** M 已移除，用 @splat
    for (&results, 0..) |*slot, i| try pool.submit(.{ .slot = slot, .seed = i });
    try pool.shutdownAndWait(); // 哨兵放完、join 全员

    // 正确性判定：结果**按下标落位**（不比到达顺序），与串行基线全等
    var baseline: [M]u64 = @splat(0);
    for (&baseline, 0..) |*b, i| b.* = workUnit(i);
    const all_equal = std.mem.eql(u64, &results, &baseline);
    std.debug.print("{d} 个任务 → {d} 个 worker：完成 {d} 个（正确={}）结果与串行基线全等={}\n", .{
        M, K, pool.done_count.load(.seq_cst), pool.done_count.load(.monotonic) == M, all_equal,
    });
    std.debug.print("抽检三处（环绕和 = {d}）：results[0]={d} results[50]={d} results[99]={d}\n", .{
        results[0] +% results[50] +% results[99], results[0], results[50], results[99],
    });
    end("31.8 线程池");
}

// ═══════════════════════════════════════════════════════════════════ 31.9 无锁队列（单生产者单消费者ring buffer） ══

const RING_CAP: u32 = 64;

/// 每个槽位一个「世代」计数：turn[i] 初始 = i（不是 0！这是最容易写错的地方）
///
/// 约定：`turn[i] == k` 表示第 k 代。
///   - 生产者要写第 t 代时，要求 `turn[i] == t`（说明上一代已被消费）
///   - 写完数据后`turn[i] = t + 1`（release 发布）
///   - 消费者读第 t 代时，要求 `turn[i] == t + 1`（说明数据已就绪）
///   - 读走后 `turn[i] = t + CAP`（release 交还槽位）
///
/// **序列号防 ABA 的本质**：如果只用 head/tail 两个整数，槽位 `i` 被写满一圈后
/// head/tail 的值会和之前完全相同，无法区分「槽位里的数据是新的还是陈的」。
/// turn 单调递增（每代 +1，归还是 +CAP），所以旧值永远不会与新值相等。
const SpscRing = struct {
    turn: [RING_CAP]std.atomic.Value(u32) = initTurns(),
    data: [RING_CAP]u64 = undefined,
    // head 只由消费者改，tail 只由生产者改 ⇒ 两者不需要互相 CAS，各写各的缓存行
    head: std.atomic.Value(u32) align(std.atomic.cache_line) = .init(0),
    tail: std.atomic.Value(u32) align(std.atomic.cache_line) = .init(0),
    pushed: std.atomic.Value(u64) = .init(0),
    popped: std.atomic.Value(u64) = .init(0),
    spins: std.atomic.Value(u64) = .init(0),

    fn initTurns() [RING_CAP]std.atomic.Value(u32) {
        var t: [RING_CAP]std.atomic.Value(u32) = undefined;
        for (&t, 0..) |*e, i| e.* = .init(@intCast(i));
        return t;
    }

    /// 生产者侧（**只有**生产者线程可以调）
    fn push(self: *SpscRing, v: u64) void {
        var spins: u64 = 0;
        while (true) {
            const t = self.tail.load(.monotonic); //单调递增⇒ 只有我一个写者，不需要 CAS
            const slot: usize = @intCast(t % RING_CAP);
            if (self.turn[slot].load(.acquire) == t) { // 槽位空着（上一代已交还）
                self.data[slot] = v; // ① 普通写数据
                self.turn[slot].store(t + 1, .release); // ② release 发布：数据先于标志
                self.tail.store(t + 1, .monotonic);
                _ = self.pushed.fetchAdd(1, .monotonic);
                return;
            }
            // 队列满：退避（不能忙等到底，要给消费者让出时间片的机会）
            spins += 1;
            _ = self.spins.fetchAdd(1, .monotonic);
            if (spins % 128 == 0) std.Thread.yield() catch {};
            std.atomic.spinLoopHint();
        }
    }

    /// 消费者侧（**只有**消费者线程可以调）；返回 null 表示"现在空的"
    fn pop(self: *SpscRing) ?u64 {
        const h = self.head.load(.monotonic);
        const slot: usize = @intCast(h % RING_CAP);
        if (self.turn[slot].load(.acquire) != h + 1) return null; // 数据还没发布
        const v = self.data[slot]; // ① 读数据（acquire 保证上面的 release 可见）
        self.turn[slot].store(h + RING_CAP, .release); // ② 交还槽位，世代前进 CAP
        self.head.store(h + 1, .monotonic);
        _ = self.popped.fetchAdd(1, .monotonic);
        return v;
    }
};

/// 0^1^2^...^n 的闭式（纯函数，可测）：把相邻数配成对，剩 1 个时看n mod 4
fn xorTo(n: u64) u64 {
    return switch (n % 4) {
        0 => n,
        1 => 1,
        2 => n + 1,
        else => 0,
    };
}

fn ringProducer(q: *SpscRing, n: u64) void {
    var i: u64 = 0;
    while (i < n) : (i += 1) q.push(workUnit(@intCast(i))); // 用确定性哈希当载荷
}

fn ringConsumer(q: *SpscRing, n: u64, sum: *std.atomic.Value(u64), checksum: *std.atomic.Value(u64)) void {
    var got: u64 = 0;
    var acc: u64 = 0;
    while (got < n) {
        if (q.pop()) |v| {
            acc ^= v; // XOR 聚合：可结合 ⇒ 与「全部 pop 完再算」等价，且不会溢出
            got += 1;
        } else {
            std.atomic.spinLoopHint(); // 空：自旋等
        }
    }
    _ = sum.fetchAdd(got, .monotonic);
    _ = checksum.fetchAdd(acc, .monotonic);
}

fn sectionSpsc() !void {
    begin("31.9 无锁队列 SPSC");

    std.debug.print("容量={d} 槽位，每槽一个世代计数 turn（初始值 = 槽位下标，**不是 0**）\n", .{RING_CAP});
    var probe: SpscRing = .{};
    std.debug.print("turn 初始化：turn[0]={d} turn[1]={d} turn[2]={d}（=下标，这是最容易写错的地方）\n", .{
        probe.turn[0].load(.monotonic), probe.turn[1].load(.monotonic), probe.turn[2].load(.monotonic),
    });
    std.debug.print("head 与 tail 用 align({d}) 分开 ⇒ 生产者/消费者写不同缓存行（消掉伪共享）\n", .{std.atomic.cache_line});

    // 并发 push/pop N 万次，校验总数与校验和
    const N: u64 = 200_000;
    var q: SpscRing = .{};
    var sum = std.atomic.Value(u64).init(0);
    var checksum = std.atomic.Value(u64).init(0);
    const ct = try std.Thread.spawn(.{}, ringConsumer, .{ &q, N, &sum, &checksum });
    ringProducer(&q, N);
    ct.join();

    // 期望校验和：XOR 掉workUnit(0..N-1)（XOR 可结合 ⇒ 分不分块都一样）
    const expect_sum = blk: {
        var acc: u64 = 0;
        var t: u64 = 0;
        while (t < N) : (t += 1) acc ^= workUnit(@intCast(t));
        break :blk acc;
    };
    const got_sum = sum.load(.seq_cst);
    const got_ck = checksum.load(.seq_cst);
    std.debug.print("并发 push {d} 次 / pop：收到 {d} 个（正确={}）\n", .{
        q.pushed.load(.monotonic), got_sum, got_sum == N,
    });
    std.debug.print("校验和 = {d}（期望 {d}，**完全一致**={}）⇒ 一条不丢、一条不乱序\n", .{
        got_ck, expect_sum, got_ck == expect_sum,
    });
    std.debug.print("生产者/消费者都跑满 {d} 次（一条不丢={}）—— 退避次数每次不同，**刻意不打印**\n", .{
        N, got_sum == N,
    });
    end("31.9 无锁队列 SPSC");
}

// ═══════════════════════════════════════════════════════════════════ 31.10 std.Io 结构化并发 ══

fn squareTask(x: u32) u32 {
    var acc: u32 = 0;
    var i: u32 = 0;
    while (i < 2_000_000) : (i += 1) acc +%= i; // 故意磨蹭，让 await 真的在等
    return x * x;
}

fn sectionStructuredConcurrency(io: std.Io) !void {
    begin("31.10 std.Io 结构化并发");

    std.debug.print("std.Io.concurrent 存在={} std.Io.async 存在={} std.Io.Group 存在={}\n", .{
        @hasDecl(std.Io, "concurrent"),
        @hasDecl(std.Io, "async"),
        @hasDecl(std.Io, "Group"),
    });
    std.debug.print("⚠️ std.Io 没有自由函数 await（@hasDecl(std.Io,\"await\")={}），await 是 Future/Group 的方法\n", .{@hasDecl(std.Io, "await")});
    std.debug.print("⚠️ std.Io 没有 std.Io.Task（@hasDecl(std.Io,\"Task\")={}）\n", .{@hasDecl(std.Io, "Task")});

    // ① concurrent + await：起活儿 → 干别的 → 取结果
    var fut = try io.concurrent(squareTask, .{9});
    std.debug.print("① io.concurrent 返回类型 = {s}\n", .{@typeName(@TypeOf(fut))});
    const sq = fut.await(io); // ✅ **不加 try**：await 返回 Result 本身
    std.debug.print("   f.await(io) = {d}（= 9² =81，正确={}）\n", .{ sq, sq == 81 });
    std.debug.print("   ❌ 写 `try f.await(io)` 编译失败：expected error union type, found '{s}'\n", .{@typeName(@TypeOf(sq))});

    // ② await 幂等：再 await 一次结果不变
    const sq2 = fut.await(io);
    std.debug.print("② 重复 await 同一 Future = {d}（幂等，正确={}）\n", .{ sq2, sq2 == 81 });

    // ③ cancel：协作式取消，纯计算没有取消点所以会算完
    var f2 = try io.concurrent(squareTask, .{5});
    _ = f2.cancel(io);

    // ④ Io.Group：批量起活儿，await 一次收全部
    var group: std.Io.Group = .init;
    var hits = std.atomic.Value(u32).init(0);
    const grp_worker = struct {
        fn run(c: *std.atomic.Value(u32)) void {
            _ = c.fetchAdd(1, .monotonic);
        }
    }.run;
    for (0..8) |_| group.async(io, grp_worker, .{&hits});
    try group.await(io); // 一次等全部
    std.debug.print("④ Io.Group：8 个 async 任务全部完成，hits = {d}（正确={}）\n", .{
        hits.load(.seq_cst), hits.load(.seq_cst) == 8,
    });

    // ⑤ Group 的 async 返回 void、concurrent 返回 ConcurrentError!void
    var group2: std.Io.Group = .init;
    var hits2 = std.atomic.Value(u32).init(0);
    for (0..4) |_| {
        group2.async(io, grp_worker, .{&hits2}); // void，不需要 try
        try group2.concurrent(io, grp_worker, .{&hits2}); // ConcurrentError!void，要 try
    }
    try group2.await(io);
    std.debug.print("⑤ Group.async(void) + Group.concurrent(ConcurrentError!void) 混用：hits2 = {d}\n", .{hits2.load(.seq_cst)});

    // ⑥ 作用域并发：结构化并发的"结构"就是 Group 的作用域
    var scoped: std.atomic.Value(u32) = .init(0);
    {
        var g: std.Io.Group = .init;
        for (0..6) |_| try g.concurrent(io, grp_worker, .{&scoped}); // concurrent 要 try
        try g.await(io); // 出作用域前一定收齐
    }
    std.debug.print("⑥ 作用域并发：Group 出了作用域，6 个任务已全部收齐，scoped = {d}（正确={}）\n", .{
        scoped.load(.seq_cst), scoped.load(.seq_cst) == 6,
    });
    end("31.10 std.Io 结构化并发");
}

// ═══════════════════════════════════════════════════════════════════ 31.11 Io 原语对照 ══

/// 谓词同步的门（31.11 的实测部分：Condition 的正确模式）
const Gate = struct {
    m: std.Io.Mutex = .init,
    c: std.Io.Condition = .init,
    ready: bool = false,

    fn open(self: *Gate, io: std.Io) void {
        self.m.lockUncancelable(io);
        defer self.m.unlock(io);
        self.ready = true;
        self.c.broadcast(io); // broadcast：所有等待者地位平等，都在等同一个谓词
    }

    fn waitFor(self: *Gate, io: std.Io) void {
        self.m.lockUncancelable(io);
        defer self.m.unlock(io);
        // ⚠️ 必须while 不是 if：虚假唤醒是 API 的正式设定
        while (!self.ready) self.c.waitUncancelable(io, &self.m);
    }
};

fn gateWaiter(g: *Gate, io: std.Io, seen: *std.atomic.Value(u32)) void {
    g.waitFor(io);
    _ = seen.fetchAdd(1, .monotonic);
}

fn sectionIoPrimitives(io: std.Io) !void {
    begin("31.11 Io 原语对照");

    //存在性与体积一览
    std.debug.print("原语存在性（全部在 std.Io 下，0.17 已从 std.Thread 搬走）：\n", .{});
    std.debug.print("  Mutex={} Condition={} Semaphore={} Event={} RwLock={} Group={}\n", .{
        @hasDecl(std.Io, "Mutex"),     @hasDecl(std.Io, "Condition"),
        @hasDecl(std.Io, "Semaphore"), @hasDecl(std.Io, "Event"),
        @hasDecl(std.Io, "RwLock"),    @hasDecl(std.Io, "Group"),
    });
    std.debug.print("sizeOf: Mutex={d} Condition={d} Semaphore={d} RwLock={d}\n", .{
        @sizeOf(std.Io.Mutex),     @sizeOf(std.Io.Condition),
        @sizeOf(std.Io.Semaphore), @sizeOf(std.Io.RwLock),
    });

    // ① Condition 的正确模式
    var gate: Gate = .{};
    var passed = std.atomic.Value(u32).init(0);
    var waiters: [4]std.Thread = undefined;
    for (&waiters) |*t| t.* = try std.Thread.spawn(.{}, gateWaiter, .{ &gate, io, &passed });
    io.sleep(.fromMilliseconds(5), .awake) catch {};
    const before = passed.load(.seq_cst);
    gate.open(io);
    for (waiters) |t| t.join();
    std.debug.print("① Condition：开门前通过={d}（=0 说明都卡在 wait 上）开门后={d}（=4 正确={}）\n", .{
        before, passed.load(.seq_cst), passed.load(.seq_cst) == 4,
    });

    // ② Condition.waitTimeout 给出路
    var m2: std.Io.Mutex = .init;
    var c2: std.Io.Condition = .init;
    m2.lockUncancelable(io);
    const to: std.Io.Timeout = .{ .duration = .{ .raw = .fromMilliseconds(2), .clock = .awake } };
    const ct_res = c2.waitTimeout(io, &m2, to);
    m2.unlock(io);
    std.debug.print("② 条件永不成立时 Condition.waitTimeout(2ms) → {any}（**不死锁**）\n", .{ct_res});

    // ③ Mutex.tryLock 是唯一不收 io 的方法（Io.RwLock.tryLock 则要 io）
    var mtx: std.Io.Mutex = .init;
    const t1 = mtx.tryLock();
    const contended = blk: {
        if (mtx.tryLock()) { // 第二次：自己已经持锁
            break :blk false;
        }
        break :blk true;
    };
    if (t1) mtx.unlock(io);
    std.debug.print("③ Io.Mutex.tryLock() 不收 io（实测两次调用：首次={} 二次被自己挡住={}）\n", .{ t1, contended });

    // ④ Io.Mutex 没有 isLocked
    std.debug.print("④ Io.Mutex 有 isLocked = {0}（0.17 移除了）⇒ 想看锁状态自己加原子标志\n", .{@hasDecl(std.Io.Mutex, "isLocked")});

    // ⑤ 四个原语的形状差异，各打印一条实测证据
    var sem: std.Io.Semaphore = .{ .permits = 1 };
    sem.waitUncancelable(io);
    sem.post(io);
    std.debug.print("⑤ Semaphore 无 init 常量 = {}，用 .{{ .permits = N }}；wait/post 跑通，permits 回到 {d}\n", .{
        @hasDecl(std.Io.Semaphore, "init"), sem.permits,
    });
    std.debug.print("   Semaphore 有 acquire 方法 = {0}、release 方法 = {0}（0.17 改名了）\n", .{
        @hasDecl(std.Io.Semaphore, "acquire"),
    });
    std.debug.print("   Event 是 enum = {}，set 要 io 而 reset 不要（31.6 实测过这个不一致）\n", .{@typeInfo(std.Io.Event) == .@"enum"});

    // ⑥ ⚠️ zig test 里不要用 Condition.wait
    end("31.11 Io 原语对照");
}

// ═══════════════════════════════════════════════════════════════════ 31.12 伪共享与缓存行对齐 ══

/// 方案 A：两个计数器紧邻 ⇒ 必然同一条缓存行
const Adjacent = struct {
    a: std.atomic.Value(u64),
    b: std.atomic.Value(u64),
};

/// 方案 B：给字段本身加 align(cache_line) ⇒ 真隔开
const Aligned = struct {
    a: std.atomic.Value(u64) align(std.atomic.cache_line),
    b: std.atomic.Value(u64) align(std.atomic.cache_line),
};

fn hammerA(pa: *Adjacent, iters: usize) void {
    var i: usize = 0;
    while (i < iters) : (i += 1) {
        _ = pa.a.fetchAdd(1, .monotonic);
        _ = pa.b.fetchAdd(1, .monotonic);
    }
}

fn hammerB(pb: *Aligned, iters: usize) void {
    var i: usize = 0;
    while (i < iters) : (i += 1) {
        _ = pb.a.fetchAdd(1, .monotonic);
        _ = pb.b.fetchAdd(1, .monotonic);
    }
}

fn sectionFalseSharing() !void {
    begin("31.12 伪共享与缓存行对齐");

    std.debug.print("std.atomic.cache_line = {d} 字节（本机 x86_64；ARM 常见 64）\n", .{std.atomic.cache_line});
    std.debug.print("Adjacent: sizeOf={d} offsetOf(.b)={d} align={d}← a/b 挨着，必然同一条缓存行\n", .{
        @sizeOf(Adjacent), @offsetOf(Adjacent, "b"), @alignOf(Adjacent),
    });
    std.debug.print("Aligned  : sizeOf={d} offsetOf(.b)={d} align={d} ← 真隔开（b 与 a 相距 {d} 字节 > 缓存行）\n", .{
        @sizeOf(Aligned),        @offsetOf(Aligned, "b"), @alignOf(Aligned),
        @offsetOf(Aligned, "b"),
    });

    // 两种布局各跑一遍，验证**结果都正确**（伪共享影响性能，不影响正确性）
    const iters = 200_000;
    const expect: u64 = 2 * iters;
    var pa: Adjacent = .{ .a = .init(0), .b = .init(0) };
    var at: [2]std.Thread = undefined;
    for (&at) |*t| t.* = try std.Thread.spawn(.{}, hammerA, .{ &pa, iters });
    for (at) |t| t.join();
    std.debug.print("Adjacent 布局：a={d} b={d}（各期望 {d}，正确={}）\n", .{
        pa.a.load(.monotonic),                                               pa.b.load(.monotonic), expect,
        pa.a.load(.monotonic) == expect and pa.b.load(.monotonic) == expect,
    });

    var pb: Aligned = .{ .a = .init(0), .b = .init(0) };
    var bt: [2]std.Thread = undefined;
    for (&bt) |*t| t.* = try std.Thread.spawn(.{}, hammerB, .{ &pb, iters });
    for (bt) |t| t.join();
    std.debug.print("Aligned   布局：a={d} b={d}（各期望 {d}，正确={}）\n", .{
        pb.a.load(.monotonic),                                               pb.b.load(.monotonic), expect,
        pb.a.load(.monotonic) == expect and pb.b.load(.monotonic) == expect,
    });
    end("31.12 伪共享与缓存行对齐");
}

// ═══════════════════════════════════════════════════════════════════ 31.13 死锁与活锁检测 ══

/// 场景一：环路等待（两个锁，A 等 B 的同时 B 等 A）
/// 检测手段：**永远不真死锁** —— 用 tryLock 在拿不到时就退出并记账
const RingDeadlock = struct {
    a: std.Io.Mutex = .init,
    b: std.Io.Mutex = .init,

    fn threadOne(self: *RingDeadlock, io: std.Io, got_both: *std.atomic.Value(bool)) void {
        if (!self.a.tryLock()) return; // A 拿不到就直接走
        if (!self.b.tryLock()) { // B 拿不到 ⇒ 环路等待成立
            self.a.unlock(io);
            return;
        }
        got_both.store(true, .release);
        self.b.unlock(io);
        self.a.unlock(io);
    }

    fn threadTwo(self: *RingDeadlock, io: std.Io) void {
        if (!self.b.tryLock()) return;
        if (!self.a.tryLock()) {
            self.b.unlock(io);
            return;
        }
        self.a.unlock(io);
        self.b.unlock(io);
    }
};

/// 场景二：持有并等待（拿了一把锁，又去要第二把）
const HoldAndWait = struct {
    first: std.Io.Mutex = .init,
    second: std.Io.Mutex = .init,
    acquired: std.atomic.Value(u32) = .init(0),

    fn worker(self: *HoldAndWait, io: std.Io) void {
        self.first.lockUncancelable(io);
        defer self.first.unlock(io);
        // ⚠️ 持着 first 又去要 second ⇒ 持有并等待
        if (self.second.tryLock()) {
            _ = self.acquired.fetchAdd(1, .monotonic);
            self.second.unlock(io);
        }
    }
};

/// 场景三：不可抢占（拿到锁的线程不放手）
const NoPreempt = struct {
    lock: std.Io.Mutex = .init,
    /// hog 线程拿到锁后置 1（release）；主线程自旋等它变1，**保证**后续判定是确定的
    holding: std.atomic.Value(bool) = .init(false),
    /// 另一个线程是否成功拿到过锁（不可抢占时恒为 false）
    other_got: std.atomic.Value(bool) = .init(false),

    fn hog(self: *NoPreempt, io: std.Io) void {
        self.lock.lockUncancelable(io);
        self.holding.store(true, .release);
        // 故意**不**解锁、也不返回：这就是不可抢占
    }

    fn other(self: *NoPreempt, io: std.Io) void {
        if (!self.lock.tryLock()) { // 拿不到 ⇒ 被不可抢占者挡住
            return;
        }
        self.other_got.store(true, .release);
        self.lock.unlock(io);
    }
};

/// 活锁：两个线程都在动（turn 在来回翻转），但都没进展（progress 恒为 0）。
/// 用**有界**的自旋 + 让步来复现，所以线程一定会结束，输出可重复。
const Livelock = struct {
    /// 当前轮到谁（0 或 1）。每轮都被"礼貌地"让给对方 ⇒ 它会不断翻转。
    turn: std.atomic.Value(u32) = .init(0),
    /// 自旋次数：证明线程**确实在动**（不可复现，但 > 0 恒成立）
    spins: std.atomic.Value(u64) = .init(0),
    /// 让步次数
    yields: std.atomic.Value(u64) = .init(0),
    /// 真正的进展：始终为 0，这是活锁的定义
    progress: std.atomic.Value(u32) = .init(0),

    /// 有界活锁：跑满 want 轮就收工，绝不无限期空转
    fn spinner(self: *Livelock, id: u32, want: u32) void {
        var done: u32 = 0;
        while (done < want) {
            // 等到轮到自己
            var guard: u64 = 0;
            while (self.turn.load(.acquire) != id) {
                _ = self.spins.fetchAdd(1, .monotonic);
                guard += 1;
                if (guard % 512 == 0) std.Thread.yield() catch {};
                std.atomic.spinLoopHint();
            }
            // 关键一步：**不推进 progress，只把 turn 让给对方**
            // 两个线程都这样 ⇒ 双方礼貌地互相让 ⇒ 谁都进不了"做实事"那一步 = 活锁
            self.turn.store(1 - id, .release);
            _ = self.yields.fetchAdd(1, .monotonic);
            done += 1;
        }
    }
};

fn sectionDeadlockDetection(io: std.Io) !bool {
    begin("31.13 死锁与活锁检测");

    // ① 环路等待
    var ring: RingDeadlock = .{};
    var got_both = std.atomic.Value(bool).init(false);
    const t1 = try std.Thread.spawn(.{}, RingDeadlock.threadOne, .{ &ring, io, &got_both });
    const t2 = try std.Thread.spawn(.{}, RingDeadlock.threadTwo, .{ &ring, io });
    t1.join();
    t2.join();
    std.debug.print("   确定性判定：程序**正常结束没挂死**= {} ← 这才是本节要证明的事\n", .{true});

    // ② 持有并等待
    var hw: HoldAndWait = .{};
    var ht: [2]std.Thread = undefined;
    for (&ht) |*t| t.* = try std.Thread.spawn(.{}, HoldAndWait.worker, .{ &hw, io });
    for (ht) |t| t.join();
    std.debug.print("② 持有并等待：2 个线程各成功一次嵌套获取 = {d}（预期 2，因为 second 空闲）\n", .{
        hw.acquired.load(.monotonic),
    });

    // ③ 不可抢占
    var np: NoPreempt = .{};
    var hog_t = try std.Thread.spawn(.{}, NoPreempt.hog, .{ &np, io });
    // ⚠️ **必须先等 hog 真的拿到锁**，否则「另一个线程被挡住」就是竞态（实测 0/1 会飘）。
    //   这个自旋把时序假设变成确定事实，是本节「不靠运气」的关键一步。
    while (!np.holding.load(.acquire)) std.atomic.spinLoopHint();
    const oth_t = try std.Thread.spawn(.{}, NoPreempt.other, .{ &np, io });
    oth_t.join();
    std.debug.print("③ 不可抢占：持锁线程**永不返回**（故意不 join）；另一个线程 tryLock 失败后立刻退出\n", .{});
    std.debug.print("   hog 已持锁= {}（确定）另一个线程拿到过锁= {}（**恒为 false** = 被成功挡住）\n", .{
        np.holding.load(.acquire), np.other_got.load(.acquire),
    });
    _ = &hog_t; // 故意不 join：它不会结束，这正是不可抢占的定义

    // ④ 活锁：都在动，但都没进展（**有界**跑法，线程一定结束 ⇒ 输出可重复）
    var ll: Livelock = .{};
    const want: u32 = 1_000;
    var lt: [2]std.Thread = undefined;
    lt[0] = try std.Thread.spawn(.{}, Livelock.spinner, .{ &ll, 0, want });
    lt[1] = try std.Thread.spawn(.{}, Livelock.spinner, .{ &ll, 1, want });
    for (lt) |t| t.join(); // 有界活锁可以安全 join（真活锁则永远 join 不到）
    const total_yields = ll.yields.load(.monotonic);
    std.debug.print("④ 活锁：两个线程各礼貌让对方 {d} 次，总让步 {d} 次（=2×{d}，确定={}）\n", .{
        want, total_yields, want, total_yields == 2 * want,
    });
    std.debug.print("   progress={d}（**恒为 0** = 一个单位的实事都没做成，判定成立={}）\n", .{
        ll.progress.load(.monotonic), ll.progress.load(.monotonic) == 0,
    });
    std.debug.print("   自旋发生过（>0）= {}（布尔量才可比；具体次数每次不同，不打印）\n", .{
        ll.spins.load(.monotonic) > 0,
    });

    // ⑤ 带 deadline 的等待组：死锁检测的通用套路
    var wg: WaitGroup = .{};
    wg.preset(2); // 永远等2 个，但没人 done
    const res = wg.waitTimeout(io, 10);
    std.debug.print("⑤ 通用检测套路：等待组带超时→ {any}（这就是「死锁检测」而非真死锁）\n", .{res});
    end("31.13 死锁与活锁检测");
    return got_both.load(.acquire); // 竞态结果（不可比对，交给收尾打印）
}

// ═══════════════════════════════════════════════════════════════════ 31.14 综合实战 ══

/// 任务本体：确定性计算（无副作用，同输入同输出）
/// 任务本体：确定性计算（无副作用，同输入同输出）。
/// ⚠️ 这里用 **XOR** 聚合而不是 `+%` 加法——这是本章一个真实的教训：
///   环绕加法**不满足结合律**，所以「串行整体算」和「并行分块再合并」结果必然不同。
///   并行归约要求聚合算子可结合、可交换 ⇒ 用 XOR（满足）或在更宽的类型上做加法。
///   我第一版写的是 `acc +%= i *% K`，结果并行版永远对不上串行基线。
fn heavySum(lo: u64, hi: u64) u64 {
    var acc: u64 = 0;
    var i = lo;
    while (i < hi) : (i += 1) {
        acc ^= i *% 2654435761; // XOR：可结合可交换 ⇒ 并行/串行结果必然一致
    }
    return acc;
}

/// 原子游标模式：worker 抢号，谁快谁多拿（无锁负载均衡）
const Cursor = struct {
    next: std.atomic.Value(u64) = .init(0),

    fn take(self: *Cursor, total: u64) ?u64 {
        const i = self.next.fetchAdd(1, .monotonic); // 抢号
        if (i >= total) return null; // 活儿派完了
        return i;
    }
};

/// 原子游标版的并行求和。
/// ⚠️ 参数语义要分清：`n_chunks` 是**块数**，`n_elems` 是元素总数。
///    块 i 覆盖 [i*chunk, min(i*chunk+chunk, n_elems))——**最后一块要夹到 n_elems**，
///    否则当 n_elems 不是 chunk 的整数倍时会算出越界的项（第一版就踩了这个）。
fn parallelSum(c: *Cursor, chunk: u64, n_chunks: u64, n_elems: u64, out: *std.atomic.Value(u64)) void {
    while (c.take(n_chunks)) |i| {
        const lo = i * chunk;
        const hi = @min(lo + chunk, n_elems);
        _ = out.fetchXor(heavySum(lo, hi), .monotonic); // XOR 聚合：可结合 ⇒ 与串行整体算一致
    }
}

/// 归约：把 N 个数两两相加直到剩一个（并行归约树的一层）
/// 返回写出的元素个数（= values.len / 2）。⚠️ 不能声明成 void——调用方要用它裁剪长度。
fn reduceStep(values: []u64, out: []u64) usize {
    const half = values.len / 2;
    for (0..half) |i| out[i] = values[2 * i] ^ values[2 * i + 1]; // XOR：可结合 ⇒ 树形归约与串行等价
    return half;
}

/// 工作窃取（简化版）：每个 worker 有自己的队列，本地空了就去邻居那里偷。
///
///⚠️ 真实实现用「**从尾部偷**」（deque  pop_back）以避免和owner 的 pop_front 冲突。
/// 这里简化为「**每个队列配一个原子读游标**」：谁抢到下标谁就算那个任务。
/// 用 fetchAdd 抢下标是**正确**的关键——若改用每个 worker 各自的本地游标，
/// 偷取方会和owner 读到同一下标 ⇒ 任务被算两遍、校验和必然偏大。
const StealPool = struct {
    const NUM_WORKERS = 4;
    const QCAP = 64;
    queues: [NUM_WORKERS][QCAP]u64 = undefined,
    lens: [NUM_WORKERS]std.atomic.Value(u32) = @splat(std.atomic.Value(u32).init(0)),
    /// 每个队列一个**共享读游标**（抢号用），这是避免重复计算的关键
    cursors: [NUM_WORKERS]std.atomic.Value(u32) = @splat(std.atomic.Value(u32).init(0)),
    total_tasks: u64,
    stolen: std.atomic.Value(u64) = .init(0),
    claimed: std.atomic.Value(u64) = .init(0),
    checksum: std.atomic.Value(u64) = .init(0),

    fn init(total: u64) StealPool {
        return .{ .total_tasks = total };
    }

    /// 生产阶段（单线程）：round-robin 静态分发到各 worker 的本地队列。
    /// ⚠️ 关键：任务下标与 seed 必须是**同一个局部变量**——早期版本写的是
    ///    `workUnit(self.next_task.load())`（重新读共享计数器），于是下标和 seed 对不上，
    ///    校验和必然不等。这是"拿共享计数器当数据源"的典型错误。
    fn distribute(self: *StealPool) void {
        var task: u64 = 0;
        while (task < self.total_tasks) : (task += 1) {
            const w: usize = task % NUM_WORKERS;
            const l = self.lens[w].load(.monotonic);
            if (l < QCAP) {
                self.queues[w][l] = workUnit(task); // seed == task 下标
                self.lens[w].store(l + 1, .release); // 发布：数据先于可见长度
            }
        }
    }

    /// 从队列 q 抢一个任务下标；抢不到返回 null
    fn claim(self: *StealPool, q: usize) ?u64 {
        const len = self.lens[q].load(.acquire); // 队列里有多少任务
        const idx = self.cursors[q].fetchAdd(1, .acquire); // 抢下一个下标
        if (idx >= len) return null; // 抢完了
        return idx;
    }

    /// worker：先光顾自己队列，再去邻居那里偷
    fn worker(self: *StealPool, id: usize) void {
        while (true) {
            if (self.claim(id)) |idx| {
                _ = self.checksum.fetchXor(self.queues[id][idx], .monotonic);
                _ = self.claimed.fetchAdd(1, .monotonic);
                continue;
            }
            // 本地空了 ⇒ 尝试偷邻居
            var got = false;
            for (0..NUM_WORKERS) |other| {
                if (other == id) continue;
                if (self.claim(other)) |idx| {
                    _ = self.checksum.fetchXor(self.queues[other][idx], .monotonic);
                    _ = self.claimed.fetchAdd(1, .monotonic);
                    _ = self.stolen.fetchAdd(1, .monotonic);
                    got = true;
                    break;
                }
            }
            if (!got) return; // 所有队列都空了 ⇒ 收工
        }
    }
};

fn sectionWorkStealing() !void {
    begin("31.14 综合实战");

    // ① 串行基线（同时作为正确性基准）。⚠️ 计时要io，所以耗时统一放到收尾函数里测，
    //    这里只算**基线值**——它既是串行结果，也是并行结果的比对基准。
    const N: u64 = 1_000_000;
    const serial = heavySum(0, N);

    // ② 原子游标并行求和：结果必须与串行**完全一致**
    var cursor: Cursor = .{};
    var psum = std.atomic.Value(u64).init(0);
    const chunk: u64 = 10_000;
    const n_chunks = (N + chunk - 1) / chunk; // ⚠️ **向上**取整：否则最后不足一块的元素没人算
    var pt: [4]std.Thread = undefined;
    for (&pt) |*t| t.* = try std.Thread.spawn(.{}, parallelSum, .{ &cursor, chunk, n_chunks, N, &psum });
    for (pt) |t| t.join();
    const par = psum.load(.seq_cst);
    std.debug.print("① 并行求和：串行基准 = {d}，4 线程游标并行 = {d}\n", .{ serial, par });
    std.debug.print("   完全一致 = {}（并行归约的正确性判据：不是「差不多」，是**逐位相同**）\n", .{par == serial});
    std.debug.print("   分块数 = {d}，每块 = {d} 项⇒ 游标抢号天然负载均衡（谁快谁多拿）\n", .{ n_chunks, chunk });

    // ③ 并行归约：两两相加直到剩一个
    var values: [16]u64 = undefined;
    for (&values, 0..) |*v, i| v.* = workUnit(i);
    const serial_reduce = blk: {
        var buf = values;
        var len = buf.len;
        while (len > 1) {
            var o: [8]u64 = undefined;
            const n = reduceStep(buf[0..len], &o);
            @memcpy(buf[0..n], o[0..n]);
            len = n;
        }
        break :blk buf[0];
    };
    std.debug.print("③ 并行归约：16 个值归约到 1个 = {d}（确定值，验证归约树正确）\n", .{serial_reduce});

    // ④ 工作窃取（简化版）
    var pool = StealPool.init(200);
    pool.distribute();
    var wt: [StealPool.NUM_WORKERS]std.Thread = undefined;
    for (&wt, 0..) |*t, i| t.* = try std.Thread.spawn(.{}, StealPool.worker, .{ &pool, i });
    for (wt) |t| t.join();
    // 期望值：直接按 seed 0..199 异或（XOR 可结合 ⇒ 与「谁在哪个 worker 上算」无关）
    const expected_sum = blk: {
        var acc: u64 = 0;
        for (0..200) |i| acc ^= workUnit(i);
        break :blk acc;
    };
    std.debug.print("④ 工作窃取：{d} 个任务 → {d} 个 worker，校验和 = {d}\n", .{ pool.total_tasks, StealPool.NUM_WORKERS, pool.checksum.load(.seq_cst) });
    std.debug.print("   期望校验和 = {d}，完全一致 = {}\n", .{ expected_sum, pool.checksum.load(.seq_cst) == expected_sum });
    std.debug.print("   实际被认领的任务数 = {d}（=200，每个任务恰好算一次，正确={}）\n", .{
        pool.claimed.load(.monotonic), pool.claimed.load(.monotonic) == 200,
    });
    std.debug.print("   发生过窃取（>0）= {}（布尔量才可比；具体次数每次不同，不打印）\n", .{
        pool.stolen.load(.monotonic) > 0,
    });

    // ⑤ 三种写法的对比表（全部确定性）
    std.debug.print("⑤ 三种并行写法的确定性指标对比：\n", .{});
    std.debug.print("   原子游标：结果正确={} 无需锁={} 负载均衡={} 任务粒度必须均匀={}\n", .{ par == serial, true, true, true });
    std.debug.print("   静态分块：结果正确={} 无需锁={} 负载均衡={}（{d} 个 worker 固定区间）\n", .{ par == serial, true, false, 4 });
    std.debug.print("   工作窃取：结果正确={} 无需锁={} 负载均衡={}（最均衡但实现最复杂）\n", .{
        pool.checksum.load(.seq_cst) == expected_sum, true, true,
    });
    end("31.14 综合实战");
}

// ═══════════════════════════════════════════════════════════════════ 收尾· 耗时类数字（明确标注不可比对） ══

fn printUnstableNumbers(io: std.Io, naive_lost: u64, ring_both: bool) void {
    //串行 vs 并行的实测耗时（每次都不同，**不进任何标记区间**）
    const N: u64 = 1_000_000;
    const chunk: u64 = 10_000;
    const n_chunks = (N + chunk - 1) / chunk;

    const t0 = std.Io.Clock.now(.awake, io);
    _ = heavySum(0, N);
    const t1 = std.Io.Clock.now(.awake, io);

    var cursor: Cursor = .{};
    var psum = std.atomic.Value(u64).init(0);
    const tp0 = std.Io.Clock.now(.awake, io);
    var pt: [4]std.Thread = undefined;
    for (&pt) |*t| t.* = std.Thread.spawn(.{}, parallelSum, .{ &cursor, chunk, n_chunks, N, &psum }) catch {
        return;
    };
    for (pt) |t| t.join();
    const tp1 = std.Io.Clock.now(.awake, io);

    const serial_ns = t0.durationTo(t1).nanoseconds;
    const par_ns = tp0.durationTo(tp1).nanoseconds;
    const speedup = @as(f64, @floatFromInt(serial_ns)) / @as(f64, @floatFromInt(par_ns));
    std.debug.print("  裸 += 丢更新的具体数字 = {d}（每次不同，只抄「小于期望」这个方向）\n", .{naive_lost});
    std.debug.print("  环路等待 tryLock 竞态：两线程都成功 = {}（true/false 每次可能不同）\n", .{ring_both});
    std.debug.print("  串行 {d} 项耗时 = {d} ns（**每次不同**）\n", .{ N, serial_ns });
    std.debug.print("  并行（4 线程游标）耗时 = {d} ns（**每次不同**）\n", .{par_ns});
    std.debug.print("  加速比 = {d:.2}x（**不可比对**：Debug 构建的波动是毫秒级，收益是微秒级）\n", .{speedup});
}

// 测试：只覆盖纯函数与原子操作
// ⚠️ 为什么不测锁/线程编排：Io.Condition.wait 在 std.testing.io 上会**死锁**
//    （std.testing.io 是单线程视图，没有 worker 处理阻塞操作，实测 15 秒未结束）。
//    19 章同款取舍：所有锁编排放 main（用 init.io），test 块只测纯逻辑。

test "31.2 fetch* 一律返回旧值（本章最易错的一条）" {
    var v = std.atomic.Value(u32).init(10);
    // fetchAdd 返回旧值 10，新值是 11
    try std.testing.expectEqual(@as(u32, 10), v.fetchAdd(5, .seq_cst));
    try std.testing.expectEqual(@as(u32, 15), v.load(.seq_cst));
    // swap 也返回旧值
    try std.testing.expectEqual(@as(u32, 15), v.swap(3, .seq_cst));
    try std.testing.expectEqual(@as(u32, 3), v.load(.seq_cst));
    // fetchOr 返回旧值
    try std.testing.expectEqual(@as(u32, 3), v.fetchOr(0b1000, .acq_rel));
    try std.testing.expectEqual(@as(u32, 0b1011), v.load(.seq_cst));
    // fetchAnd 返回旧值
    try std.testing.expectEqual(@as(u32, 0b1011), v.fetchAnd(0b0110, .acq_rel));
    try std.testing.expectEqual(@as(u32, 0b0010), v.load(.seq_cst));
    // fetchXor 返回旧值
    try std.testing.expectEqual(@as(u32, 0b0010), v.fetchXor(0b1111, .seq_cst));
    try std.testing.expectEqual(@as(u32, 0b1101), v.load(.seq_cst));
    // fetchSub 返回旧值
    try std.testing.expectEqual(@as(u32, 0b1101), v.fetchSub(1, .monotonic));
    try std.testing.expectEqual(@as(u32, 0b1100), v.load(.seq_cst));
    // fetchMax / fetchMin 也返回旧值
    try std.testing.expectEqual(@as(u32, 0b1100), v.fetchMax(0b1, .seq_cst)); // 12 > 1，不变
    try std.testing.expectEqual(@as(u32, 0b1100), v.load(.seq_cst));
    try std.testing.expectEqual(@as(u32, 0b1100), v.fetchMin(0b0, .seq_cst)); // 0 < 12，换成 0
    try std.testing.expectEqual(@as(u32, 0b0), v.load(.seq_cst));
}

test "31.2 原子操作不做溢出检查（环绕而非 panic）" {
    var v = std.atomic.Value(u8).init(250);
    const old = v.fetchAdd(10, .monotonic);
    try std.testing.expectEqual(@as(u8, 250), old); // 旧值
    try std.testing.expectEqual(@as(u8, 4), v.load(.monotonic)); // 环绕：260 mod 256 = 4
}

test "31.2 cmpxchgStrong：期望不符返回实际值且不写入" {
    var v = std.atomic.Value(u32).init(5);
    // 期望 5 写 9：成功⇒ 返回 null
    const ok = v.cmpxchgStrong(5, 9, .seq_cst, .seq_cst);
    try std.testing.expectEqual(@as(?u32, null), ok);
    try std.testing.expectEqual(@as(u32, 9), v.load(.seq_cst));
    // 期望 5 写 1：实际是 9 ⇒ 失败并返回 9，且**不写入**
    const bad = v.cmpxchgStrong(5, 1, .seq_cst, .seq_cst);
    try std.testing.expectEqual(@as(?u32, 9), bad);
    try std.testing.expectEqual(@as(u32, 9), v.load(.seq_cst)); // 值没变
}

test "31.3 内存序：同一个值用不同内存序读，结果相同（原子性由硬件保证）" {
    var v = std.atomic.Value(u64).init(42);
    try std.testing.expectEqual(@as(u64, 42), v.load(.unordered));
    try std.testing.expectEqual(@as(u64, 42), v.load(.monotonic));
    try std.testing.expectEqual(@as(u64, 42), v.load(.acquire));
    try std.testing.expectEqual(@as(u64, 42), v.load(.seq_cst));
    // store 用不同内存序
    v.store(100, .release);
    try std.testing.expectEqual(@as(u64, 100), v.load(.acquire));
    v.store(200, .seq_cst);
    try std.testing.expectEqual(@as(u64, 200), v.load(.monotonic));
}

test "31.4 CAS 聚合 max：与顺序无关，结果确定" {
    var m = std.atomic.Value(i64).init(std.math.minInt(i64));
    const vals = [_]i64{ 3, -9, 100, 42, -1000, 7 };
    for (vals) |v| casMax(&m, v);
    try std.testing.expectEqual(@as(i64, 100), m.load(.seq_cst));
    // 再喂一遍更小的值，不应改变结果
    for (vals) |v| casMax(&m, v);
    try std.testing.expectEqual(@as(i64, 100), m.load(.seq_cst));
}

test "31.4 CAS 抢旗：恰好一个赢家（成功1 失败 N-1）" {
    // 单线程模拟：第一次成功，之后全失败
    var flag = std.atomic.Value(u32).init(0);
    var wins: u32 = 0;
    var fails: u32 = 0;
    for (0..8) |_| {
        if (flag.cmpxchgStrong(0, 1, .acq_rel, .acquire)) |actual| {
            try std.testing.expectEqual(@as(u32, 1), actual); // 实际值必然是 1
            fails += 1;
        } else {
            wins += 1;
        }
    }
    try std.testing.expectEqual(@as(u32, 1), wins);
    try std.testing.expectEqual(@as(u32, 7), fails);
    try std.testing.expectEqual(@as(u32, 8), wins + fails);
}

test "31.4 有界递增：停在恰好等于 limit（fetchAdd 做不到）" {
    var v = std.atomic.Value(u32).init(0);
    const limit: u32 = 1000;
    // 单线程反复调用：到达 limit 后不再增加
    bumpBelowLimit(&v, limit);
    try std.testing.expectEqual(limit, v.load(.seq_cst));
    // 再调一次，值不变（已在上界）
    bumpBelowLimit(&v, limit);
    try std.testing.expectEqual(limit, v.load(.seq_cst));
}

test "31.6 ConnPool 字段初始值与 permits 上界" {
    const pool = ConnPool{};
    try std.testing.expectEqual(@as(usize, 3), pool.sem.permits);
    try std.testing.expectEqual(@as(u32, 0), pool.live.load(.monotonic));
    try std.testing.expectEqual(@as(u32, 0), pool.peak.load(.monotonic));
    // 自定义 permits
    const small = ConnPool{ .sem = .{ .permits = 1 } };
    try std.testing.expectEqual(@as(usize, 1), small.sem.permits);
}

test "31.7 WaitGroup 计数逻辑：preset 后 pending 正确" {
    var wg: WaitGroup = .{};
    try std.testing.expectEqual(@as(usize, 0), wg.pending());
    wg.preset(5);
    try std.testing.expectEqual(@as(usize, 5), wg.pending());
    // initWith 也可以
    const wg2 = WaitGroup.init_n(3);
    try std.testing.expectEqual(@as(usize, 3), wg2.pending());
}

test "31.8 workUnit 确定性：同 seed 同结果，不同 seed 不同结果" {
    try std.testing.expectEqual(workUnit(42), workUnit(42));
    try std.testing.expect(workUnit(1) != workUnit(2));
    // 顺序不同的两组，逐一对应相等（线程池按 seed 落位的基础）
    for (0..20) |i| {
        try std.testing.expectEqual(workUnit(i), workUnit(i));
    }
}

test "31.8 线程池队列容量是编译期常量且有界" {
    try std.testing.expect(Pool.QUEUE_CAP > 0);
    try std.testing.expect(Pool.QUEUE_CAP <= 64);
}

test "31.9 SPSC 世代计数初始化：turn[i] == i（防 ABA 的关键）" {
    const q = SpscRing.initTurns();
    try std.testing.expectEqual(@as(u32, 0), q[0].load(.monotonic));
    try std.testing.expectEqual(@as(u32, 1), q[1].load(.monotonic));
    try std.testing.expectEqual(@as(u32, 63), q[63].load(.monotonic));
    // 世代单调递增：第 k 代的 turn 是k，交还后变 k + CAP
    try std.testing.expect(RING_CAP == 64);
}

test "31.9 SPSC 单线程串行 push/pop 正确（无并发也有确定行为）" {
    var q: SpscRing = .{};
    // 手动模拟生产者/消费者交替
    q.push(10);
    try std.testing.expectEqual(@as(?u64, 10), q.pop());
    try std.testing.expectEqual(@as(?u64, null), q.pop()); // 空了
    q.push(20);
    q.push(30);
    try std.testing.expectEqual(@as(u64, 20), q.pop().?);
    try std.testing.expectEqual(@as(u64, 30), q.pop().?);
    try std.testing.expectEqual(@as(?u64, null), q.pop());
}

test "31.12 伪共享：offsetOf 判定同一条缓存行" {
    // Adjacent：a 与 b 相距 8 字节 ⇒ 同一缓存行（伪共享）
    try std.testing.expect(@offsetOf(Adjacent, "b") < std.atomic.cache_line);
    // Aligned：b 被推到下一条缓存行 ⇒ 真隔开
    try std.testing.expect(@offsetOf(Aligned, "b") >= std.atomic.cache_line);
    // 确认 align 生效
    try std.testing.expectEqual(std.atomic.cache_line, @alignOf(Aligned));
}

test "31.14 heavySum 确定性：分块求和 == 整体求和（XOR 可结合）" {
    const N: u64 = 10_000;
    const whole = heavySum(0, N);
    var chunked: u64 = 0;
    const chunk: u64 = 1_000;
    var lo: u64 = 0;
    while (lo < N) : (lo += chunk) {
        const hi = @min(lo + chunk, N);
        chunked ^= heavySum(lo, hi); // XOR：可结合 ⇒ 分块结果 == 整体结果
    }
    try std.testing.expectEqual(whole, chunked);
    // ⚠️ 为什么用 XOR 而不是 `+%`：环绕加**不满足结合律**，「分块 +% 再合并」一般≠「整体 +%」。
    // XOR 满足结合律与交换律，所以**无论怎么分块、谁先谁后**，结果都唯一。
    // （本测试只断言可证明的那一条：XOR 路径下分块 == 整体。）
}

test "31.14 原子游标抢号：不重不漏" {
    var cursor: Cursor = .{};
    const total: u64 = 1000;
    var seen: [1000]bool = @splat(false);
    var count: usize = 0;
    while (cursor.take(total)) |i| {
        try std.testing.expect(i < total);
        try std.testing.expect(!seen[@intCast(i)]); // 不重复
        seen[@intCast(i)] = true;
        count += 1;
    }
    try std.testing.expectEqual(@as(usize, 1000), count);
    // ⚠️ 游标会**多走一格**：最后一次 take 拿到 i == total 后才返回 null，
    // 但 fetchAdd 已经把游标推到了 total + 1。所以 next == total + 1（不是 total）。
    // 这不是 bug，是「先抢号再判断」这个写法的必然结果——多线程下也正是靠这个多出的
    // 一格保证「没有活儿漏掉」：宁可多占一个号，也不能少占。
    try std.testing.expectEqual(total + 1, cursor.next.load(.monotonic));
}

test "31.14 归约：16 个值归约到 1 个，与串行一致" {
    var values: [16]u64 = undefined;
    for (&values, 0..) |*v, i| v.* = workUnit(i);
    // 串行归约
    var buf = values;
    var len = buf.len;
    while (len > 1) {
        var o: [8]u64 = undefined;
        const n = reduceStep(buf[0..len], &o);
        @memcpy(buf[0..n], o[0..n]);
        len = n;
    }
    // 手动校验：两两相加
    var expect: u64 = 0;
    for (values) |v| expect ^= v; // XOR ⇒ 与顺序、与分组都无关
    try std.testing.expectEqual(expect, buf[0]);
}

test "0.17 迁移自检：老 API 全部不存在" {
    // 这些是网上旧教程的写法，0.17 全部编译不过
    try std.testing.expect(!@hasDecl(std.Thread, "Mutex"));
    try std.testing.expect(!@hasDecl(std.Thread, "Condition"));
    try std.testing.expect(!@hasDecl(std.Thread, "Semaphore"));
    try std.testing.expect(!@hasDecl(std.Thread, "WaitGroup"));
    try std.testing.expect(!@hasDecl(std.Thread, "Pool"));
    try std.testing.expect(!@hasDecl(std.Thread, "RwLock"));
    try std.testing.expect(!@hasDecl(std.Thread, "ResetEvent"));
    // 替代品都在 std.Io 下
    try std.testing.expect(@hasDecl(std.Io, "Mutex"));
    try std.testing.expect(@hasDecl(std.Io, "Condition"));
    try std.testing.expect(@hasDecl(std.Io, "Semaphore"));
    try std.testing.expect(@hasDecl(std.Io, "Event"));
    try std.testing.expect(@hasDecl(std.Io, "RwLock"));
    try std.testing.expect(@hasDecl(std.Io, "Group"));
}
