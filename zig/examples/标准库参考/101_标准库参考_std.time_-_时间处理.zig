const std = @import("std");

pub fn main() void {
    // 时间单位常量
    std.debug.print("1 second = {} nanoseconds\n", .{std.time.ns_per_s});
    std.debug.print("1 ms = {} nanoseconds\n", .{std.time.ns_per_ms});
}
