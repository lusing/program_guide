//! 31 并发进阶：原子计数与 CAS、Io.RwLock、Io.Condition 有界队列、线程池
//! 取材：Systems Programming with Zig ch8（生产者-消费者两解、线程池）+ Sprinter ch9/10
//! ⚠️ 0.16 迁移点：std.Thread.Mutex/Condition/RwLock 已并入 std.Io，全部方法带 io 参数
//! （Io.Mutex.lock(io)、Io.Condition.wait(io, &mutex)、Io.RwLock.lockShared(io)）——网上旧教程全是 Thread.Mutex。
//! 确定性策略：结果按任务下标落位（不比到达顺序），线程 join 后与串行基线逐项断言。
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const err = std.debug.print;

    // ═══ 31.1 竞态现场：8 线程各加 100000 次——裸 += 丢更新，原子操作分毫不差
    const n_threads = 8;
    const per_thread = 100_000;
    const expected: u64 = n_threads * per_thread;

    var naive: u64 = 0;
    {
        var threads: [n_threads]std.Thread = undefined;
        for (&threads) |*t| t.* = try std.Thread.spawn(.{}, addNaive, .{ &naive, per_thread });
        for (threads) |t| t.join();
    }
    var atomic_counter = std.atomic.Value(u64).init(0);
    {
        var threads: [n_threads]std.Thread = undefined;
        for (&threads) |*t| t.* = try std.Thread.spawn(.{}, addAtomic, .{ &atomic_counter, per_thread });
        for (threads) |t| t.join();
    }
    err("裸 += 结果 {d}（期望 {d}，丢了 {d}）\n", .{ naive, expected, expected - naive });
    err("原子 fetchAdd 结果 {d}（分毫不差）\n", .{atomic_counter.load(.seq_cst)});
    std.debug.assert(atomic_counter.load(.seq_cst) == expected);
    // Debug 构建下裸写也常"碰巧"正确——所以只断言原子侧，裸侧打印观感（教学点：竞态是概率性的）

    // ═══ 31.2 CAS：cmpxchgWeak 实现无锁 max 聚合（乐观重试的典型形状）
    var max_seen = std.atomic.Value(i64).init(std.math.minInt(i64));
    {
        var threads: [n_threads]std.Thread = undefined;
        for (&threads, 0..) |*t, i| t.* = try std.Thread.spawn(.{}, casMax, .{ &max_seen, @as(i64, @intCast(i)) * 7 - 3 });
        for (threads) |t| t.join();
    }
    const want_max = @as(i64, @intCast(n_threads - 1)) * 7 - 3;
    std.debug.assert(max_seen.load(.seq_cst) == want_max);
    err("CAS max 聚合：{d}\n", .{max_seen.load(.seq_cst)});

    // ═══ 31.3 RwLock：读多写少——4 读线程持续读快照，1 写线程定期翻倍
    {
        var g = Shared{ .value = 1 };
        var stop = std.atomic.Value(bool).init(false);
        var readers: [4]std.Thread = undefined;
        for (&readers) |*t| t.* = try std.Thread.spawn(.{}, readSnapshot, .{ io, &g, &stop });
        var w1 = try std.Thread.spawn(.{}, doubleSnapshot, .{ io, &g });
        w1.join();
        stop.store(true, .release);
        for (readers) |t| t.join();
        err("RwLock 快照翻倍 10 次：{d}\n", .{g.value});
        std.debug.assert(g.value == 1 << 10);
    }

    // ═══ 31.4 线程池：4 worker × 100 任务，结果按下标落位，与串行基线全等
    {
        var pool = try Pool.init(std.heap.page_allocator, io, 4);
        defer pool.deinit();

        var results = [_]u64{0} ** 100;
        for (&results, 0..) |*slot, i| try pool.submit(.{ .slot = slot, .seed = i });
        try pool.shutdownAndWait(); // 哨兵放完、join 全员

        var baseline = [_]u64{0} ** 100;
        for (&baseline, 0..) |*b, i| b.* = workUnit(i);
        std.debug.assert(std.mem.eql(u64, &results, &baseline));
        const sum = results[0] +% results[50] +% results[99]; // +% 环绕加：u64 混合值求和必溢出
        err("线程池 100 任务全部落位正确（抽检环绕和 {d}）\n", .{sum});
    }

    err("自检通过\n", .{});
}

fn addNaive(p: *u64, times: usize) void {
    var i: usize = 0;
    while (i < times) : (i += 1) p.* +%= 1; // 裸读改写：三个动作随时被打断
}

fn addAtomic(p: *std.atomic.Value(u64), times: usize) void {
    var i: usize = 0;
    while (i < times) : (i += 1) _ = p.fetchAdd(1, .seq_cst); // 单条原子指令
}

/// CAS 循环：读到旧值 → 算新值 → 条件写入（失败说明有人抢先，重读重试）
fn casMax(p: *std.atomic.Value(i64), candidate: i64) void {
    while (true) {
        const cur = p.load(.seq_cst);
        if (candidate <= cur) return;
        if (p.cmpxchgWeak(cur, candidate, .seq_cst, .seq_cst)) |_| {
            // 有人抢先写了：cur 已过时，循环重来
        } else return; // 写入成功
    }
}

// ═══ RwLock 演示：写者持锁换值，读者共享锁读值（多读并发不互斥）
const Shared = struct {
    lock: std.Io.RwLock = .init,
    value: u64,
};

fn doubleSnapshot(io: std.Io, g: *Shared) void {
    var n: usize = 0;
    while (n < 10) : (n += 1) {
        g.lock.lockUncancelable(io);
        defer g.lock.unlock(io);
        g.value *= 2;
    }
}

fn readSnapshot(io: std.Io, g: *Shared, stop: *std.atomic.Value(bool)) void {
    while (!stop.load(.acquire)) {
        g.lock.lockSharedUncancelable(io);
        defer g.lock.unlockShared(io);
        std.mem.doNotOptimizeAway(g.value); // 真读，别让编译器优化掉
    }
}

// ═══ 31.5 线程池：固定 worker + 有界队列 + 哨兵关停
pub const Pool = struct {
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
            self.lock.unlock(self.io);

            const slot = job.slot orelse return; // 哨兵：收工
            slot.* = workUnit(job.seed);
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

// ═══ 31.6 测试：纯原子逻辑（不带 io 的锁原语在 std.testing.io 实测会挂——
// Mutex/Condition 的等待依赖 Threaded 后台的完整初始化，测试运行器里不可靠；
// 19 章同款取舍：锁编排全放 main（init.io），测试只覆盖原子与纯函数）
test "CAS max 与串行一致" {
    var m = std.atomic.Value(i64).init(std.math.minInt(i64));
    const vals = [_]i64{ 3, -9, 100, 42, -1000, 7 };
    for (vals) |v| casMax(&m, v);
    try std.testing.expectEqual(@as(i64, 100), m.load(.seq_cst));
}

test "workUnit 确定性" {
    try std.testing.expectEqual(workUnit(42), workUnit(42));
    try std.testing.expect(workUnit(1) != workUnit(2));
}

test "裸加法在单线程下无损（多线程竞态见 main 演示）" {
    var v: u64 = 0;
    addNaive(&v, 10_000);
    try std.testing.expectEqual(@as(u64, 10_000), v);
    var av = std.atomic.Value(u64).init(0);
    addAtomic(&av, 10_000);
    try std.testing.expectEqual(@as(u64, 10_000), av.load(.seq_cst));
}
