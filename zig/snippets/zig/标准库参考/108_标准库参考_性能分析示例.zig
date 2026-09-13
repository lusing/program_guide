const std = @import("std");

pub fn main() void {
    const start = std.time.nanoTimestamp();

    // 模拟工作
    var sum: u64 = 0;
    for (0..1000000) |i| {
        sum += i;
    }

    const end = std.time.nanoTimestamp();
    std.debug.print("Duration: {} ns\n", .{end - start});
    std.debug.print("Sum: {}\n", .{sum});
}
