const std = @import("std");

pub fn main() void {
    const reg_val: i32 = 100;
    const mem_val: i32 = 50;
    const immed: i32 = 42;

    std.debug.print("Register operation: {}\n", .{reg_val});
    std.debug.print("Memory operation: {}\n", .{mem_val});
    std.debug.print("Immediate: {}\n", .{immed});
}
