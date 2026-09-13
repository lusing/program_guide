const std = @import("std");

pub fn main() void {
    const age: i32 = 18;

    if (age >= 18) {
        std.debug.print("成年人\n", .{});
    } else {
        std.debug.print("未成年人\n", .{});
    }

    // if 作为表达式
    const result = if (age >= 18) "can vote" else "cannot vote";
    std.debug.print("Result: {s}\n", .{result});
}
