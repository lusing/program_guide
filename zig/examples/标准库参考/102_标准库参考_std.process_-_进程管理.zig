const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();

    // 获取命令行参数
    const argv = try init.minimal.args.toSlice(arena);
    for (argv, 0..) |arg, i| {
        std.debug.print("Arg[{}]: {s}\n", .{ i, arg });
    }

    // 获取环境变量
    if (init.environ_map.get("PATH")) |path| {
        std.debug.print("PATH: {s}\n", .{path});
    }
}
