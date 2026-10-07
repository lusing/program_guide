//! 02 第一个程序：@import / std.debug.print / 缓冲 Writer / Init 入口 / 构建模式 / test / fmt
const std = @import("std");
const builtin = @import("builtin");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

pub fn main(init: std.process.Init) !void {
    // ═══ 2.1 最小的 Zig 程序：main、@import、字节切片 ═══
    begin("2.1");
    // Zig 没有独立的 string 类型："字符串"就是指向只读字节数组的指针，用时常常退化成切片
    const greeting = "你好，Zig 0.17！";
    const slice: []const u8 = greeting;
    std.debug.print("{s}\n", .{slice});
    std.debug.print("类型={s} 长度={d} 首字节=0x{x}\n", .{
        @typeName(@TypeOf(slice)),
        slice.len,
        slice[0],
    });
    end("2.1");

    // ═══ 2.2 std.debug.print：编译期检查的格式化 ═══
    begin("2.2");
    const n: u32 = 255;
    const pi: f64 = 3.14159;
    std.debug.print("十进制 {d}、十六进制 {x}、大写 {X}、八进制 {o}、二进制 {b}\n", .{ n, n, n, n, n });
    std.debug.print("宽度/对齐：[{d:0>6}] [{d:<6}] [{d:^6}] [{d:*>6}]\n", .{ n, n, n, n });
    std.debug.print("浮点：{d}、两位 {d:.2}、科学计数 {e}\n", .{ pi, pi, pi });
    std.debug.print("字符串 {s}、布尔 {}、任意值 {any}\n", .{ "zig", true, .{ 1, 2, 3 } });
    std.debug.print("字符 {c}、码位 {u}、字节大小 {B} / {Bi}\n", .{
        @as(u8, 65),
        @as(u21, 0x4E2D),
        @as(u64, 123456),
        @as(u64, 123456),
    });
    std.debug.print("标签名 {t}、指针 {*}\n", .{ error.FileNotFound, &n });
    end("2.2");

    // ═══ 2.3 stdout 的四步：文件 → writer → interface → flush ═══
    begin("2.3");
    var buf: [256]u8 = undefined; // 缓冲区由调用方提供，可见、可控
    var w = std.Io.File.stdout().writer(init.io, &buf);
    const out = &w.interface;
    try out.print("（stdout）姓名：{s}，年龄：{d}\n", .{ "阿 Z", 25 });
    try out.print("（stdout）PI ≈ {d:.2}\n", .{pi});
    try out.flush(); // 不 flush：缓冲里的尾部内容不会落地
    end("2.3");

    // ═══ 2.4 std.process.Init：main 的运行时环境参数包 ═══
    begin("2.4");
    std.debug.print("io          : {s}\n", .{@typeName(@TypeOf(init.io))});
    std.debug.print("gpa         : {s}\n", .{@typeName(@TypeOf(init.gpa))});
    std.debug.print("arena       : {s}\n", .{@typeName(@TypeOf(init.arena))});
    std.debug.print("environ_map : {s}\n", .{@typeName(@TypeOf(init.environ_map))});
    std.debug.print("preopens    : {s}\n", .{@typeName(@TypeOf(init.preopens))});
    std.debug.print("minimal.args: {s}\n", .{@typeName(@TypeOf(init.minimal.args))});
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    std.debug.print("argv 长度   : {d}\n", .{args.len});
    for (args, 0..) |arg, i| std.debug.print("  [{d}] {s}\n", .{ i, arg });
    if (init.environ_map.get("HOME")) |home| {
        std.debug.print("HOME        : {s}\n", .{home});
    } else {
        std.debug.print("HOME        : (未设置)\n", .{});
    }
    end("2.4");

    // ═══ 2.5 构建模式：同一份源码，四种安全/性能权衡 ═══
    begin("2.5");
    std.debug.print("builtin.mode          = {t}\n", .{builtin.mode});
    std.debug.print("runtime_safety        = {}\n", .{std.debug.runtime_safety});
    std.debug.print("target                = {t}-{t}\n", .{
        builtin.target.cpu.arch,
        builtin.target.os.tag,
    });
    // 环绕运算符 +%= 在四种模式下都合法（显式承认溢出），安全版 + 在 Debug/ReleaseSafe 下会 panic
    var counter: u8 = 253;
    for (0..5) |_| {
        counter +%= 1;
        std.debug.print("  counter = {d}\n", .{counter});
    }
    end("2.5");

    std.debug.print("自检通过\n", .{});
}

test "字符串就是字节切片" {
    const s: []const u8 = "zig";
    try std.testing.expectEqual(@as(usize, 3), s.len);
    try std.testing.expectEqualStrings("zig", s);
}

test "占位符语义" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try w.print("{d} {x} {d:.2} {s} {}", .{ 255, @as(u32, 255), 3.14159, "zig", true });
    try std.testing.expectEqualStrings("255 ff 3.14 zig true", w.buffered());
}

test "Writer.fixed 直接写调用方的缓冲，不藏数据" {
    var buf: [64]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try w.print("未 flush", .{});
    // fixed writer 没有中间暂存层：print 完数据已经在调用方的 buf 里
    try std.testing.expectEqual(@as(usize, 9), w.buffered().len);
    try w.flush();
    try std.testing.expectEqualStrings("未 flush", w.buffered());
}

test "文件 Writer 不 flush 就不会落盘" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var f = try tmp.dir.createFile(std.testing.io, "t.txt", .{});
    defer f.close(std.testing.io);
    var fbuf: [64]u8 = undefined;
    var fw = f.writer(std.testing.io, &fbuf);
    const out = &fw.interface;
    try out.print("hello", .{});
    try out.flush(); // 这一行是"缓冲所有权归调用者"的代价：忘了就没有输出
    const got = try tmp.dir.readFileAlloc(std.testing.io, "t.txt", std.testing.allocator, .limited(64));
    defer std.testing.allocator.free(got);
    try std.testing.expectEqualStrings("hello", got);
}

test "构建模式元数据可用" {
    // 0.17：Optimize 枚举改名，.Debug → .debug、.ReleaseSafe → .safe
    try std.testing.expect(builtin.mode == .debug or builtin.mode == .safe);
    var c: u8 = 255;
    c +%= 1;
    try std.testing.expectEqual(@as(u8, 0), c);
}
