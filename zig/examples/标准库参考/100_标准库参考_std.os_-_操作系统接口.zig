const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // 获取进程 ID
    const pid = std.os.linux.getpid();
    std.debug.print("PID: {}\n", .{pid});

    // 获取环境变量
    if (init.environ_map.get("HOME")) |home| {
        std.debug.print("HOME: {s}\n", .{home});
    }

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const len = try std.process.currentPath(io, &path_buf);
    std.debug.print("CurrentPath: {s}\n", .{path_buf[0..len]});
}
