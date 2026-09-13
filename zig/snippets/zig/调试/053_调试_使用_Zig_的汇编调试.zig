const std = @import("std");

pub fn main() void {
    var x: i32 = 42;

    // 使用汇编设置断点
    asm volatile (
        "int3"  // x86_64 断点指令
        :
        : [x] "r" (x)
        :
    );

    std.debug.print("x = {}\n", .{x});
}
