//! 22 进程与系统编程：argv、环境变量、子进程、路径、时间
//! 0.16 变化：args 迭代要 initAllocator；子进程是 process.run(gpa, io, ...)；时间在 io 上
const std = @import("std");
const builtin = @import("builtin");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();

    // ═══ 22.1 argv：跨平台迭代器（Windows 原生 UTF-16 被抹平）
    var it = try std.process.Args.Iterator.initAllocator(init.minimal.args, mem);
    defer it.deinit(); // 迭代器有内部缓冲，用完要还
    var argc: usize = 0;
    while (it.next()) |arg| {
        std.debug.print("  argv[{d}] = {s}\n", .{ argc, arg });
        argc += 1;
    }

    // ═══ 22.2 环境变量（Init.environ_map：已解析好的 map）
    if (init.environ_map.get("USERNAME") orelse init.environ_map.get("USER")) |user| {
        std.debug.print("当前用户：{s}\n", .{user});
    }
    const path_len = if (init.environ_map.get("PATH")) |p| p.len else 0;
    std.debug.print("PATH 长度：{d}\n", .{path_len});

    // ═══ 22.3 子进程：跑命令收输出（run = spawn + 管道 + wait 的合体）
    // argv 不经 shell：echo 这类内建命令要套 shell——Windows 用 cmd /c，POSIX 用 sh -c
    const child_argv: []const []const u8 = switch (builtin.os.tag) {
        .windows => &.{ "cmd", "/c", "echo", "hello from child" },
        else => &.{ "sh", "-c", "echo hello from child" },
    };
    const res = try std.process.run(mem, io, .{ .argv = child_argv });
    std.debug.print("子进程 stdout：{s}", .{res.stdout});

    // ═══ 22.4 当前目录
    var pbuf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_len = try std.process.currentPath(io, &pbuf);
    std.debug.print("cwd：{s}\n", .{pbuf[0..cwd_len]});

    // ═══ 22.5 时间：io.now（.real 墙钟 / .monotonic 单调钟）
    const t0 = std.Io.Timestamp.now(io, .awake);
    try (std.Io.Clock.Duration{ .raw = std.Io.Duration.fromMilliseconds(2), .clock = .awake }).sleep(io); // 0.16 的 sleep 挂在 Duration 上
    const t1 = std.Io.Timestamp.now(io, .awake);
    const took = t0.durationTo(t1); // Duration.nanoseconds
    std.debug.print("打算睡 2ms，实测 {d} ns；墙钟纳秒 {d}\n", .{
        took.nanoseconds,
        std.Io.Timestamp.now(io, .real).nanoseconds,
    });

    std.debug.print("自检通过\n", .{});
}

test "路径与时间" {
    const a = std.testing.allocator;
    const j = try std.fs.path.join(a, &.{ "x", "y.txt" });
    defer a.free(j);
    try std.testing.expectEqualStrings("x" ++ std.fs.path.sep_str ++ "y.txt", j); // 平台分隔符：Windows \，POSIX /
    try std.testing.expectEqualStrings("y.txt", std.fs.path.basename(j));
    const io = std.testing.io;
    const t0 = std.Io.Timestamp.now(io, .awake);
    try (std.Io.Clock.Duration{ .raw = std.Io.Duration.fromNanoseconds(1), .clock = .awake }).sleep(io);
    const t1 = std.Io.Timestamp.now(io, .awake);
    try std.testing.expect(t1.nanoseconds >= t0.nanoseconds);
}
