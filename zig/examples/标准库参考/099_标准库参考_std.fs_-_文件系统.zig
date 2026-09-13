const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    // 写入文件
    var file = try cwd.createFile(io, "test.txt", .{});
    defer file.close(io);

    var file_buffer: [128]u8 = undefined;
    var writer = file.writer(io, &file_buffer);
    try writer.interface.print("Hello, Zig!\n", .{});

    const stat = try file.stat(io);
    std.debug.print("Size: {} bytes\n", .{stat.size});

    // 遍历目录
    var iter = cwd.iterate();
    while (try iter.next(io)) |entry| {
        std.debug.print("{s}\n", .{entry.name});
    }
}
