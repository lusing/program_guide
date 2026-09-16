const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 获取进程 ID（跨平台）
    const pid = switch (builtin.os.tag) {
        .linux => std.os.linux.getpid(),
        .macos, .ios, .watchos, .tvos => std.c.getpid(),
        .windows => std.os.windows.kernel32.GetCurrentProcessId(),
        else => @compileError("Unsupported platform for getpid"),
    };
    std.debug.print("PID: {}\n", .{pid});

    // 获取环境变量
    const env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();
    if (env_map.get("HOME")) |home| {
        std.debug.print("HOME: {s}\n", .{home});
    }

    // 睡眠
    std.time.sleep(1000 * std.time.ns_per_ms); // 1秒
}
