//! 20 文件与 IO：std.Io.Dir、读写、目录遍历、std.json
//! 0.16 变化：Dir/File 从 std.fs 移入 std.Io，几乎全部方法带 io 参数
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();
    const cwd = std.Io.Dir.cwd();

    // ═══ 20.1 写文件：Dir.writeFile 一行落地（data 直接给）
    try cwd.writeFile(io, .{
        .sub_path = "build_demo.txt",
        .data = "第一行：Zig 写文件\n第二行：fin",
    });

    // ═══ 20.2 读文件：readFileAlloc（上限用 Io.Limit 防失控）
    const text = try cwd.readFileAlloc(io, "build_demo.txt", mem, .limited(1024 * 1024));
    std.debug.print("读回 {d} 字节，前 12 字节：{s}\n", .{ text.len, text[0..12] });

    // ═══ 20.3 元数据
    const st = try cwd.statFile(io, "build_demo.txt", .{});
    std.debug.print("文件大小 {d} 字节\n", .{st.size});

    // ═══ 20.4 目录：createDirPath（旧名 makePath）+ iterate（next 也要 io）
    try cwd.createDirPath(io, "build_demo_dir/sub");
    try cwd.writeFile(io, .{ .sub_path = "build_demo_dir/sub/a.txt", .data = "A" });
    try cwd.writeFile(io, .{ .sub_path = "build_demo_dir/b.txt", .data = "B" });
    var dir = try cwd.openDir(io, "build_demo_dir", .{ .iterate = true }); // Windows 下不开 iterate 会 AccessDenied
    defer dir.close(io);
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        std.debug.print("  [{s}] {s}\n", .{ @tagName(entry.kind), entry.name });
    }

    // ═══ 20.5 路径工具（跨平台分隔符；std.fs.path 仍在）
    const joined = try std.fs.path.join(mem, &.{ "build_demo_dir", "sub", "a.txt" });
    std.debug.print("join：{s}，basename={s}\n", .{ joined, std.fs.path.basename(joined) });

    // ═══ 20.6 新 Writer 写文件（Io 接口 + 缓冲 + flush）
    {
        const f = try cwd.createFile(io, "build_demo_w.txt", .{});
        defer f.close(io);
        var fbuf: [128]u8 = undefined;
        var fw = f.writer(io, &fbuf);
        const w = &fw.interface;
        try w.print("缓冲写入 {s}\n", .{"OK"});
        try w.flush(); // 忘了 flush 是新手第一大坑
    }

    // ═══ 20.7 std.json：结构 ↔ JSON 互转
    const Score = struct { name: []const u8, points: u32 };
    const s1 = Score{ .name = "阿 Z", .points = 99 };
    var jbuf: [256]u8 = undefined;
    var jw = std.Io.Writer.fixed(&jbuf); // 内存缓冲当 Writer（测试/拼接常用）
    try std.json.Stringify.value(s1, .{}, &jw);
    std.debug.print("JSON：{s}\n", .{jw.buffered()});
    const back = try std.json.parseFromSlice(Score, mem, jw.buffered(), .{});
    defer back.deinit();
    std.debug.print("回读：{s} {d} 分\n", .{ back.value.name, back.value.points });

    // ═══ 20.8 清理演示产物（deleteTree 递归删）
    cwd.deleteFile(io, "build_demo.txt") catch {};
    cwd.deleteFile(io, "build_demo_w.txt") catch {};
    cwd.deleteTree(io, "build_demo_dir") catch {};
    std.debug.print("自检通过\n", .{});
}

test "读写与 JSON 回环" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "x.txt", .data = "abc" });
    const got = try tmp.dir.readFileAlloc(io, "x.txt", a, .limited(64));
    defer a.free(got);
    try std.testing.expectEqualStrings("abc", got);

    const P = struct { n: u8 };
    var jbuf: [64]u8 = undefined;
    var jw = std.Io.Writer.fixed(&jbuf);
    try std.json.Stringify.value(P{ .n = 3 }, .{}, &jw);
    const back = try std.json.parseFromSlice(P, a, jw.buffered(), .{});
    defer back.deinit();
    try std.testing.expectEqual(@as(u8, 3), back.value.n);
}
