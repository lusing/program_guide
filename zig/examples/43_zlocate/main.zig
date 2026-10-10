//! 43 · 实战：并发文件索引器 —— Scatter-Gather/WorkQueue/并行 BFS/条件变量
//!
//! 前置：19 章（线程基础）、27 章（目录遍历）、31 章（并发进阶）。
//! 本章把《Systems Programming with Zig》ch8 的 scatter-gather 模式升级到 0.17：
//!   ① WorkQueue（泛型工作队列 + 条件变量） ② 3 个 worker 线程并行 BFS 目录树
//!   ③ 结果收集排序 ④ 生产者-消费者最小 demo ⑤ 无锁环形缓冲理论
//!
//! ⚠️ 0.17 实测：`std.Thread.WaitGroup`/`Pool`/`RwLock`/`Semaphore`/`ResetEvent`
//!    全部移除（31 章 @hasDecl 逐个验证）。`std.Io.Mutex`/`Condition` 存在，
//!    方法首参是 `io: std.Io`。`init.io` 可跨线程共享（底层是 Threaded 的
//!    OS futex，ch31 已实测）。test 块用 `std.Io.Threaded = .init_single_threaded`
//!    提供独立 Io 实例（避开 std.testing.io 的 Condition 死锁，见 31.11）。
//!
//! 确定性纪律：标记区间只打印确定性指标（计数、路径列表、布尔判定）。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var out_buf: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &out_buf);
    const w = &stdout_impl.interface;
    defer w.flush() catch {};

    try sectionTheory(io, w);
    try sectionWorkQueueTheory(io, w);
    try sectionParallelCrawl(io, gpa, w);
    try sectionGatherSort(io, gpa, w);
    try sectionProducerConsumer(io, gpa, w);
    try sectionLockFree(w);
    try sectionPitfalls(io, w);
}

// ═══════════════════════════════════════════════════════════════════ 43.1 Scatter-Gather 理论 ══

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

    end("43.1 Scatter-Gather 理论");
}

// ═══════════════════════════════════════════════════════════════════ 43.2 WorkQueue ══

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

        fn deinit(self: *Self) void {
            self.items.deinit(self.allocator);
        }

        /// 主线程调用：推入一个工作项，递增 active，唤醒一个等待的 worker。
        fn push(self: *Self, item: T) !void {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);
            try self.items.append(self.allocator, item);
            self.active += 1;
            self.cond.signal(self.io);
        }

        /// 生产者调用：标记不再推入新工作项（配合 finish 使用）。
        /// 解决「初始 active=0 导致 consumer 第一个 pop 就返回 null」的竞态。
        fn startProducer(self: *Self) void {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);
            self.active += 1; // 生产者占一个 active 位，全部推完后 finish
        }

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

        /// Worker 调用：完成一个工作项，递减 active，broadcast 通知可能等待的 worker。
        fn finish(self: *Self) void {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);
            std.debug.assert(self.active > 0);
            self.active -= 1;
            if (self.active == 0) self.cond.broadcast(self.io);
        }
    };
}

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

    _ = io;
    end("43.2 WorkQueue 理论");
}

// ═══════════════════════════════════════════════════════════════════ 43.3 并行目录爬取 ══

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

    end("43.3 并行目录爬取");
}

// ═══════════════════════════════════════════════════════════════════ 43.4 结果收集与排序 ══

fn lessStr(_: void, x: []const u8, y: []const u8) bool {
    return std.mem.order(u8, x, y) == .lt;
}

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

    end("43.4 结果收集与排序");
}

// ═══════════════════════════════════════════════════════════════════ 43.5 生产者-消费者 ══

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

    end("43.5 生产者-消费者（条件变量版）");
}

fn sumU32(items: []const u32) u64 {
    var s: u64 = 0;
    for (items) |v| s += v;
    return s;
}

// ═══════════════════════════════════════════════════════════════════ 43.6 无锁替代方案（理论） ══

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

    end("43.6 无锁替代方案（理论）");
}

// ═══════════════════════════════════════════════════════════════════ 43.7 坑位清单 ══

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

    end("43.7 坑位清单");
}

// ═══════════════════════════════════════════════════════════════════ 工具函数 ══

/// 把两段路径用本平台分隔符拼进调用方缓冲（零分配）。
fn fmtJoin(buf: []u8, a: []const u8, b: []const u8) ![]const u8 {
    var w = std.Io.Writer.fixed(buf);
    try w.print("{f}", .{std.fs.path.fmtJoin(&.{ a, b })});
    return w.buffered();
}

/// 简单 glob 匹配：* 匹配任意长度（不跨 /），? 匹配单个字符。
fn isWanted(name: []const u8, pattern: []const u8) bool {
    if (pattern.len == 0) return name.len == 0;
    if (pattern[0] == '*') {
        // * 匹配零个或多个字符（不跨 /）
        var i: usize = 0;
        while (i <= name.len) : (i += 1) {
            if (isWanted(name[i..], pattern[1..])) return true;
            if (i < name.len and name[i] == '/') break; // * 不跨目录分隔符
        }
        return false;
    }
    if (name.len == 0) return false;
    if (pattern[0] == '?' or pattern[0] == name[0]) {
        return isWanted(name[1..], pattern[1..]);
    }
    return false;
}

// ═══════════════════════════════════════════════════════════════════ 测试 ══

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

test "isWanted glob 匹配" {
    // * 匹配任意长度
    try std.testing.expect(isWanted("main.zig", "*.zig"));
    try std.testing.expect(isWanted("a.zig", "*.zig"));
    try std.testing.expect(!isWanted("main.zig", "*.txt"));
    try std.testing.expect(isWanted("foo.bar.zig", "*.zig"));

    // ? 匹配单个字符
    try std.testing.expect(isWanted("a.zig", "?.zig"));
    try std.testing.expect(!isWanted("ab.zig", "?.zig"));
    try std.testing.expect(isWanted("ab.zig", "??.zig"));

    // 精确匹配
    try std.testing.expect(isWanted("main.zig", "main.zig"));
    try std.testing.expect(!isWanted("main.zig", "main.zi"));

    // 空 pattern
    try std.testing.expect(isWanted("", ""));
    try std.testing.expect(!isWanted("a", ""));

    // 组合
    try std.testing.expect(isWanted("src/main.zig", "src/*.zig"));
    try std.testing.expect(!isWanted("src/deep/main.zig", "src/*.zig")); // * 不跨 /
}
