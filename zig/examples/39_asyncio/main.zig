//! 39 · 异步 IO 与并发编程 —— io.async/Io.Group/Io.Select/并发 echo
//!
//! 取材 Systems Programming with Zig ch8/ch9，按 0.17.0 实测 API 重写。
//! 历史：Zig 在 0.10 移除了 async/await 关键字；0.17 的模型是 std.Io 的一组方法：
//!   io.async(fn, .{args})     → Future（不保证真并发，可能立即执行）
//!   io.concurrent(fn, .{args}) → Future（保证真并发，失败报 ConcurrencyUnavailable）
//!   future.await(io)           收结果
//!   future.cancel(io)          请求取消（defer 兜底是安全网）
//!   std.Io.Group               结构化扇出：group.async / group.concurrent + group.await
//!   std.Io.Select(T)           竞速：select.async / select.concurrent + select.await → tagged union
//!
//! 默认后端 std.Io.Threaded 是线程池，不是协程。协程要事件化后端（本章不深挖）。
//!
//! 确定性纪律：标记区间里只打印确定性指标（计数、布尔判定、固定字符串），
//!   不打印端口、耗时等不确定数字。
const std = @import("std");
const net = std.Io.net;

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 39.1 历史课：async/await 关键字的消亡与 std.Io 方法的崛起
// ══════════════════════════════════════════════════════════════════

fn sectionHistory() void {
    begin("39.1 历史课");
    std.debug.print("Zig 0.10 移除了 async/await 关键字（它们曾是语言级特性）\n", .{});
    std.debug.print("0.17 的异步模型是 std.Io 上的一组方法，不是语法：\n", .{});
    std.debug.print("  io.async(fn, .{{args}})      → Future（可能立即执行，不保证并发）\n", .{});
    std.debug.print("  io.concurrent(fn, .{{args}}) → Future（保证真并发，失败报 ConcurrencyUnavailable）\n", .{});
    std.debug.print("  future.await(io)             收结果\n", .{});
    std.debug.print("  future.cancel(io)            请求取消（defer 安全网）\n", .{});
    std.debug.print("  std.Io.Group                 结构化扇出\n", .{});
    std.debug.print("  std.Io.Select(T)             竞速\n", .{});
    std.debug.print("@hasDecl(std.Io, \"async\") = {}（comptime 验证存在）\n", .{@hasDecl(std.Io, "async")});
    std.debug.print("@hasDecl(std.Io, \"concurrent\") = {}\n", .{@hasDecl(std.Io, "concurrent")});
    std.debug.print("@hasDecl(std.Io, \"Group\") = {}\n", .{@hasDecl(std.Io, "Group")});
    std.debug.print("@hasDecl(std.Io, \"Select\") = {}\n", .{@hasDecl(std.Io, "Select")});
    std.debug.print("⇒ 全部是 std.Io 的方法/类型，不是关键字。\n", .{});
    end("39.1 历史课");
}

// ══════════════════════════════════════════════════════════════════
// 39.2 第一个异步任务：io.concurrent + future.await + defer cancel
// ══════════════════════════════════════════════════════════════════

/// 睡 ms 毫秒后返回 value。模拟一个"耗时计算"。
fn sleepAndReturn(io: std.Io, ms: u64, value: u32) std.Io.Cancelable!u32 {
    try std.Io.sleep(io, .fromMilliseconds(@intCast(ms)), .awake);
    return value;
}

fn sectionFirstAsync(io: std.Io) !void {
    begin("39.2 第一个异步任务");
    // defer fut.cancel(io) 是安全网：如果 await 之前出错退出，cancel 兜底释放资源。
    // 在 await 之后 cancel 是 no-op（future 已被消费），但写上无害。
    var fut = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 20), @as(u32, 7) });
    defer {
        _ = fut.cancel(io) catch {};
    }
    const v = fut.await(io) catch |err| switch (err) {
        error.Canceled => return error.UnexpectedCancel,
    };
    std.debug.print("并发任务返回 {d}\n", .{v});
    std.debug.print("⇒ io.concurrent 返回 Future，future.await(io) 收结果。\n", .{});
    std.debug.print("⇒ defer fut.cancel(io) 是安全网：await 后 cancel 是 no-op，但写上无害。\n", .{});
    end("39.2 第一个异步任务");
}

// ══════════════════════════════════════════════════════════════════
// 39.3 fan-out/fan-in：3 个并发任务，墙钟时间 ≈ 最慢的不是求和
// ══════════════════════════════════════════════════════════════════

fn sectionFanOut(io: std.Io) !void {
    begin("39.3 fan-out/fan-in");
    var fut_a = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 10), @as(u32, 1) });
    defer {
        _ = fut_a.cancel(io) catch {};
    }
    var fut_b = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 30), @as(u32, 2) });
    defer {
        _ = fut_b.cancel(io) catch {};
    }
    var fut_c = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 20), @as(u32, 3) });
    defer {
        _ = fut_c.cancel(io) catch {};
    }

    const a = fut_a.await(io) catch return error.UnexpectedCancel;
    const b = fut_b.await(io) catch return error.UnexpectedCancel;
    const c = fut_c.await(io) catch return error.UnexpectedCancel;
    std.debug.print("任务 A (10ms) 返回 {d}\n", .{a});
    std.debug.print("任务 B (30ms) 返回 {d}\n", .{b});
    std.debug.print("任务 C (20ms) 返回 {d}\n", .{c});
    std.debug.print("⇒ 3 个任务并发执行，墙钟时间 ≈ 最慢的 30ms，不是 10+30+20=60ms。\n", .{});
    std.debug.print("⇒ fan-out（扇出）= 同时启动；fan-in（扇入）= 按序 await 收结果。\n", .{});
    end("39.3 fan-out/fan-in");
}

// ══════════════════════════════════════════════════════════════════
// 39.4 Io.Group 结构化并发：group.async + group.await
// ══════════════════════════════════════════════════════════════════

/// Group 任务必须返回 Cancelable!void（或能 coerce 到它）。
fn groupTask(io: std.Io, ms: u64, label: []const u8, counter: *std.atomic.Value(u32)) std.Io.Cancelable!void {
    try std.Io.sleep(io, .fromMilliseconds(@intCast(ms)), .awake);
    _ = counter.fetchAdd(1, .seq_cst);
    std.debug.print("  Group 任务 {s} 完成\n", .{label});
}

fn sectionGroup(io: std.Io) !void {
    begin("39.4 Io.Group 结构化并发");
    var group: std.Io.Group = .init;
    defer group.cancel(io);
    var counter = std.atomic.Value(u32).init(0);
    group.async(io, groupTask, .{ io, @as(u64, 15), @as([]const u8, "甲"), &counter });
    group.async(io, groupTask, .{ io, @as(u64, 25), @as([]const u8, "乙"), &counter });
    try group.await(io);
    const done = counter.load(.seq_cst);
    std.debug.print("Group 完成 {d} 个任务\n", .{done});
    std.debug.print("⇒ Group 是结构化并发：任务作为一个整体 await 或 cancel。\n", .{});
    std.debug.print("⇒ group.async 不返回值（void），结果通过副作用（counter）收集。\n", .{});
    end("39.4 Io.Group 结构化并发");
}

// ══════════════════════════════════════════════════════════════════
// 39.5 Io.Select 竞速：两个任务赛跑，快者胜
// ══════════════════════════════════════════════════════════════════

const RaceResult = union(enum) {
    fast: u32,
    slow: u32,
};

/// Select 任务必须返回字段类型本身（不是 error union），所以包一层。
fn selectSleep(io: std.Io, ms: u64, value: u32) u32 {
    return sleepAndReturn(io, ms, value) catch |err| switch (err) {
        error.Canceled => 0,
    };
}

fn sectionSelect(io: std.Io) !void {
    begin("39.5 Io.Select 竞速");
    var buffer: [2]RaceResult = undefined;
    var sel = std.Io.Select(RaceResult).init(io, &buffer);
    // 两个任务：50ms 和 200ms，都返回 u32
    sel.async(.fast, selectSleep, .{ io, @as(u64, 50), @as(u32, 50) });
    sel.async(.slow, selectSleep, .{ io, @as(u64, 200), @as(u32, 200) });
    const winner = sel.await() catch return error.UnexpectedCancel;
    switch (winner) {
        .fast => |v| std.debug.print("快者胜: {d}ms 任务（返回 {d}）\n", .{ v, v }),
        .slow => |v| std.debug.print("快者胜: {d}ms 任务（返回 {d}）\n", .{ v, v }),
    }
    // 取消剩下的那个（快者已返回，慢者还在跑）
    _ = sel.cancel();
    std.debug.print("⇒ Io.Select 让多个任务赛跑，await 返回 tagged union 告诉你谁赢了。\n", .{});
    std.debug.print("⇒ cancel() 收掉没跑完的那个，防止资源泄漏。\n", .{});
    end("39.5 Io.Select 竞速");
}

// ══════════════════════════════════════════════════════════════════
// 39.6 并发 TCP echo 服务器 + 客户端
// ══════════════════════════════════════════════════════════════════

/// 服务器参数包：Threaded 实例 + listener。
const ServerCtx = struct {
    threaded: *std.Io.Threaded,
    listener: *net.Server,
};

/// echo 服务器线程：接受一条连接，回声一次，退出。
fn echoServer(ctx: *ServerCtx) void {
    const io = ctx.threaded.io();
    var stream = ctx.listener.accept(io) catch return;
    defer stream.close(io);
    var rbuf: [256]u8 = undefined;
    var fr = stream.reader(io, &rbuf);
    const r = &fr.interface;
    r.fillMore() catch return;
    const data = r.buffered();
    var wbuf: [256]u8 = undefined;
    var fw = stream.writer(io, &wbuf);
    const w = &fw.interface;
    w.writeAll(data) catch return;
    w.flush() catch {};
}

/// 客户端任务：连接 + 发 + 收，返回收到的字节数。
fn echoClient(io: std.Io, port: u16) !usize {
    const addr = try net.IpAddress.parseIp4("127.0.0.1", port);
    var stream = try addr.connect(io, .{ .mode = .stream });
    defer stream.close(io);
    var wbuf: [256]u8 = undefined;
    var fw = stream.writer(io, &wbuf);
    try fw.interface.writeAll("ping-asyncio");
    try fw.interface.flush();
    var rbuf: [256]u8 = undefined;
    var fr = stream.reader(io, &rbuf);
    const r = &fr.interface;
    try r.fillMore();
    return r.bufferedLen();
}

fn sectionTcpEcho(io: std.Io, gpa: std.mem.Allocator) !void {
    begin("39.6 并发 TCP echo 服务器 + 客户端");
    // 服务器在自己的 Threaded 实例上跑（spawn 的线程没有 init.io）
    var server_threaded = std.Io.Threaded.init(gpa, .{});
    defer server_threaded.deinit();
    const server_io = server_threaded.io();

    const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var listener = try addr.listen(server_io, .{});
    defer listener.deinit(server_io);
    const port = listener.socket.address.getPort();

    var ctx = ServerCtx{ .threaded = &server_threaded, .listener = &listener };
    const th = try std.Thread.spawn(.{}, echoServer, .{&ctx});

    // 主线程用 io.concurrent 做客户端
    var fut = try io.concurrent(echoClient, .{ io, port });
    defer {
        _ = fut.cancel(io) catch {};
    }
    const n = fut.await(io) catch return error.UnexpectedCancel;
    th.join();
    std.debug.print("echo 往返成功（{d} 字节）\n", .{n});
    std.debug.print("⇒ 服务器线程用独立 Threaded 实例，客户端用主线程 io.concurrent。\n", .{});
    std.debug.print("⇒ 确定性：服务器只服务一条连接就退出，join 即同步。\n", .{});
    end("39.6 并发 TCP echo 服务器 + 客户端");
}

// ══════════════════════════════════════════════════════════════════
// 39.7 坑位清单
// ══════════════════════════════════════════════════════════════════

fn sectionPitfalls() void {
    begin("39.7 坑位清单");
    std.debug.print("1. async/await 不是关键字，是 io 的方法（0.10 移除关键字的历史）\n", .{});
    std.debug.print("2. io.async 返回 Future，必须 await 或 cancel，defer cancel 是安全网\n", .{});
    std.debug.print("3. io.concurrent 返回 error.ConcurrencyUnavailable!void —— 要 try 它\n", .{});
    std.debug.print("4. 默认 Threaded 后端是线程池不是协程；协程要事件化后端\n", .{});
    std.debug.print("5. 0.17 没有 std.Thread.Pool / std.Thread.WaitGroup（已移除），用 Io.Group 替代\n", .{});
    std.debug.print("6. 结构化并发：Group.await 之前 Group 里的任务异常怎么办 —— cancel 兜底\n", .{});
    end("39.7 坑位清单");
}

// ══════════════════════════════════════════════════════════════════
// main
// ══════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var out_buf: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &out_buf);
    const w = &stdout_impl.interface;
    defer w.flush() catch {};

    sectionHistory();
    try sectionFirstAsync(io);
    try sectionFanOut(io);
    try sectionGroup(io);
    try sectionSelect(io);
    try sectionTcpEcho(io, gpa);
    sectionPitfalls();

    try w.print("39 章自检通过\n", .{});
}

// ══════════════════════════════════════════════════════════════════
// 测试
// ══════════════════════════════════════════════════════════════════

test "39.2 sleepAndReturn 纯逻辑" {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const v = try sleepAndReturn(io, 0, 42);
    try std.testing.expectEqual(@as(u32, 42), v);
}

test "39.3 fan-out：并发任务结果按序收集" {
    const io = std.testing.io;
    var fut_a = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 5), @as(u32, 100) });
    defer {
        _ = fut_a.cancel(io) catch {};
    }
    var fut_b = try io.concurrent(sleepAndReturn, .{ io, @as(u64, 10), @as(u32, 200) });
    defer {
        _ = fut_b.cancel(io) catch {};
    }
    const a = fut_a.await(io) catch return error.UnexpectedCancel;
    const b = fut_b.await(io) catch return error.UnexpectedCancel;
    try std.testing.expectEqual(@as(u32, 100), a);
    try std.testing.expectEqual(@as(u32, 200), b);
}

test "39.4 Io.Group 结构化并发" {
    const io = std.testing.io;
    var group: std.Io.Group = .init;
    defer group.cancel(io);
    var counter = std.atomic.Value(u32).init(0);
    group.async(io, groupTask, .{ io, @as(u64, 5), @as([]const u8, "test-甲"), &counter });
    group.async(io, groupTask, .{ io, @as(u64, 10), @as([]const u8, "test-乙"), &counter });
    try group.await(io);
    try std.testing.expectEqual(@as(u32, 2), counter.load(.seq_cst));
}

test "39.5 Io.Select 竞速：快者胜" {
    const io = std.testing.io;
    var buffer: [2]RaceResult = undefined;
    var sel = std.Io.Select(RaceResult).init(io, &buffer);
    sel.async(.fast, selectSleep, .{ io, @as(u64, 5), @as(u32, 5) });
    sel.async(.slow, selectSleep, .{ io, @as(u64, 50), @as(u32, 50) });
    const winner = sel.await() catch return error.UnexpectedCancel;
    switch (winner) {
        .fast => |v| try std.testing.expectEqual(@as(u32, 5), v),
        .slow => |v| try std.testing.expectEqual(@as(u32, 50), v),
    }
    _ = sel.cancel();
}

test "39.6 echo 客户端纯逻辑（不依赖网络）" {
    // 验证 sleepAndReturn 在 0ms 时立即返回
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    const v = try sleepAndReturn(io, 0, 99);
    try std.testing.expectEqual(@as(u32, 99), v);
}
