const std = @import("std");

// WASI 程序入口
pub fn main() !void {
    const argv: [][]u8 = &[_][]u8{ "program" };
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Hello from WASI!\n", .{});

    // 读取环境变量
    const env = std.process.envAlloc(std.heap.page_allocator, argv) catch unreachable;
    defer std.process.freeEnv(std.heap.page_allocator, env);

    for (env) |e| {
        try stdout.print("{} = {}\n", .{ e.key, e.value });
    }
}
