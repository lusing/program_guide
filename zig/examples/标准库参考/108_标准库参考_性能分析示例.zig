const std = @import("std");

pub fn main() void {
    // 模拟工作
    var sum: u64 = 0;
    for (0..1000000) |i| {
        sum += i;
    }

    std.debug.print("Sum: {}\n", .{sum});
    std.debug.print("Timing example omitted for Zig 0.16 compatibility.\n", .{});
}
