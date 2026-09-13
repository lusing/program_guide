const std = @import("std");

pub fn main() !void {
    // 获取进程 ID
    const pid = std.os.linux.getpid();
    std.debug.print("PID: {}\n", .{pid});

    // 获取环境变量
    const env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();
    if (env_map.get("HOME")) |home| {
        std.debug.print("HOME: {s}\n", .{home});
    }

    // 睡眠
    std.time.sleep(1000 * std.time.ns_per_ms);  // 1秒
}
