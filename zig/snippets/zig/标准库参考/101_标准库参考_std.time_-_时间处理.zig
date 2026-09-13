const std = @import("std");

pub fn main() void {
    // 获取当前时间戳
    const timestamp = std.time.timestamp();
    std.debug.print("Timestamp: {}\n", .{timestamp});

    // 获取纳秒时间
    const nanos = std.time.nanoTimestamp();
    std.debug.print("Nanos: {}\n", .{nanos});

    // 时间单位常量
    std.debug.print("1 second = {} nanoseconds\n", .{std.time.ns_per_s});
    std.debug.print("1 ms = {} nanoseconds\n", .{std.time.ns_per_ms});
}
