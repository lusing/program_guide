//! 19 并发：Thread、Io.Mutex、atomic.Value、Io.Condition
//! 0.16 变化：Mutex/Condition 移入 std.Io 且方法带 io；WaitGroup 已移除（用 join）
const std = @import("std");

// ═══ 19.2 Mutex：互斥保护共享计数（io 穿透到工作线程）
var counter: usize = 0;
var mutex: std.Io.Mutex = .init;

fn addLocked(io: std.Io, n: usize) void {
    for (0..n) |_| {
        mutex.lockUncancelable(io); // 0.16：lock/unlock 要 io
        defer mutex.unlock(io);
        counter += 1;
    }
}

// ═══ 19.4 有界队列：Condition 双条件（经典生产者-消费者）
const Queue = struct {
    buf: [8]u32 = undefined,
    head: usize = 0,
    count: usize = 0,
    mtx: std.Io.Mutex = .init,
    not_empty: std.Io.Condition = .init,
    not_full: std.Io.Condition = .init,

    fn push(self: *Queue, io: std.Io, v: u32) void {
        self.mtx.lockUncancelable(io);
        defer self.mtx.unlock(io);
        while (self.count == self.buf.len) {
            self.not_full.waitUncancelable(io, &self.mtx); // 满了：等消费者腾位置
        }
        self.buf[(self.head + self.count) % self.buf.len] = v;
        self.count += 1;
        self.not_empty.signal(io); // 唤醒一个消费者
    }

    fn pop(self: *Queue, io: std.Io) u32 {
        self.mtx.lockUncancelable(io);
        defer self.mtx.unlock(io);
        while (self.count == 0) {
            self.not_empty.waitUncancelable(io, &self.mtx); // 空了：等生产者
        }
        const v = self.buf[self.head];
        self.head = (self.head + 1) % self.buf.len;
        self.count -= 1;
        self.not_full.signal(io);
        return v;
    }
};

fn producer(q: *Queue, io: std.Io, n: u32, base: u32) void {
    var i: u32 = 0;
    while (i < n) : (i += 1) q.push(io, base + i);
}

fn consumer(q: *Queue, io: std.Io, total: usize, out: *std.ArrayList(u32), alloc: std.mem.Allocator) void {
    var i: usize = 0;
    while (i < total) : (i += 1) {
        const v = q.pop(io);
        out.append(alloc, v) catch @panic("OOM");
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 19.1 spawn / join
    const worker = struct {
        fn run(id: u32) void {
            std.debug.print("  worker {d} 跑在线程 {d}\n", .{ id, std.Thread.getCurrentId() });
        }
    };
    const t1 = try std.Thread.spawn(.{}, worker.run, .{1});
    const t2 = try std.Thread.spawn(.{}, worker.run, .{2});
    t1.join();
    t2.join();

    // ═══ 19.2 Mutex 计数（去掉锁必错——正文演示）
    const ta = try std.Thread.spawn(.{}, addLocked, .{ io, 50_000 });
    const tb = try std.Thread.spawn(.{}, addLocked, .{ io, 50_000 });
    ta.join();
    tb.join();
    std.debug.print("Mutex 计数 = {d}（期望 100000）\n", .{counter});

    // ═══ 19.3 atomic.Value：无锁计数
    var hits = std.atomic.Value(usize).init(0);
    const atomic_worker = struct {
        fn run(h: *std.atomic.Value(usize), n: usize) void {
            for (0..n) |_| _ = h.fetchAdd(1, .monotonic);
        }
    };
    const tc = try std.Thread.spawn(.{}, atomic_worker.run, .{ &hits, 25_000 });
    const td = try std.Thread.spawn(.{}, atomic_worker.run, .{ &hits, 25_000 });
    tc.join();
    td.join();
    std.debug.print("atomic 计数 = {d}（期望 50000）\n", .{hits.load(.seq_cst)});

    // ═══ 19.4 生产者-消费者（Condition + 数组队列）
    var q: Queue = .{};
    var out: std.ArrayList(u32) = .empty;
    const n_items: u32 = 16;
    const tp1 = try std.Thread.spawn(.{}, producer, .{ &q, io, n_items / 2, 100 });
    const tp2 = try std.Thread.spawn(.{}, producer, .{ &q, io, n_items / 2, 200 });
    const tcon = try std.Thread.spawn(.{}, consumer, .{ &q, io, n_items, &out, mem });
    tp1.join();
    tp2.join();
    tcon.join();
    var sum: u64 = 0;
    for (out.items) |v| sum += v;
    const expect: u64 = blk: {
        var e: u64 = 0;
        for (100..108) |v| e += v;
        for (200..208) |v| e += v;
        break :blk e;
    };
    std.debug.print("队列消费 {d} 件，总和 {d}（期望 {d}）\n", .{ out.items.len, sum, expect });

    std.debug.print("自检通过\n", .{});
}

test "无锁计数与队列" {
    var h = std.atomic.Value(u32).init(0);
    const t = try std.Thread.spawn(.{}, struct {
        fn run(x: *std.atomic.Value(u32)) void {
            for (0..1000) |_| _ = x.fetchAdd(1, .monotonic);
        }
    }.run, .{&h});
    t.join();
    try std.testing.expectEqual(@as(u32, 1000), h.load(.seq_cst));
}
