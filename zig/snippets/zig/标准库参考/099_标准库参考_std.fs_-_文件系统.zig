const std = @import("std");

pub fn main() !void {
    const cwd = std.fs.cwd();

    // 写入文件
    {
        const file = try cwd.createFile("test.txt", .{});
        defer file.close();
        try file.writeAll("Hello, Zig!\n");
    }

    // 读取文件
    {
        const file = try cwd.openFile("test.txt", .{});
        defer file.close();
        const data = try file.readToEndAlloc(std.heap.page_allocator, 1024);
        defer std.heap.page_allocator.free(data);
        std.debug.print("File content: {s}\n", .{data});
    }

    // 遍历目录
    var dir = cwd.openDir(".", .{}) catch unreachable;
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        std.debug.print("{s}\n", .{entry.name});
    }

    // 文件信息
    const stat = try cwd.stat("test.txt");
    std.debug.print("Size: {} bytes\n", .{stat.size});
}
