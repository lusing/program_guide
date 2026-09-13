const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 获取命令行参数
    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    for (argv, 0..) |arg, i| {
        std.debug.print("Arg[{}]: {s}\n", .{ i, arg });
    }

    // 获取环境变量
    const env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    if (env.get("PATH")) |path| {
        std.debug.print("PATH: {s}\n", .{path});
    }
}
