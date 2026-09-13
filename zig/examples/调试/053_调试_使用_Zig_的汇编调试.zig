const std = @import("std");

pub fn main() void {
    const x: i32 = 42;

    // 使用 Zig 内置断点指令
    @breakpoint();

    std.debug.print("x = {}\n", .{x});
}
