const std = @import("std");

pub fn main() void {
    // 寄存器操作数
    var reg_val: i32 = 100;
    asm volatile (
        "add %0, %0, 10"
        : "+r" (reg_val)
        :
        : "cc"
    );
    std.debug.print("Register operation: {}\n", .{reg_val});

    // 内存操作数
    var mem_val: i32 = 50;
    asm volatile (
        "mov %0, %1"
        : "=r" (reg_val)
        : "m" (mem_val)
        :
    );
    std.debug.print("Memory operation: {}\n", .{reg_val});

    // 立即数操作数
    var immed: i32 = undefined;
    asm volatile (
        "mov %0, #42"
        : "=r" (immed)
        :
        :
    );
    std.debug.print("Immediate: {}\n", .{immed});
}
