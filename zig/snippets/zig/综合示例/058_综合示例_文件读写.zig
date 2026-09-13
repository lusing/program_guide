const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // 写入文件
    {
        const file = try std.fs.cwd().createFile("test.txt", .{});
        defer file.close();
        try file.writeAll("Hello, Zig File!\n");
    }

    // 读取文件
    {
        const file = try std.fs.cwd().openFile("test.txt", .{});
        defer file.close();
        const data = try file.readToEndAlloc(allocator, 1024);
        defer allocator.free(data);
        std.debug.print("File content: {s}\n", .{data});
    }
}
