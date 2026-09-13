const std = @import("std");

pub fn main() void {
    // 基本 while 循环
    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        std.debug.print("{} ", .{i});
    }
    std.debug.print("\n", .{});

    // 无限循环
    var j: i32 = 0;
    while (true) {
        if (j >= 3) break;
        std.debug.print("{} ", .{j});
        j += 1;
    }
    std.debug.print("\n", .{});
}

