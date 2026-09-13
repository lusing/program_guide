const std = @import("std");

pub fn main() void {
    const a: i32 = 10;
    const b: i32 = 20;
    const result = a + b;
    std.debug.print("Result: {}\n", .{result});
}
