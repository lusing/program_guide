const std = @import("std");
const builtin = @import("builtin");

comptime {
    if (builtin.cpu.arch != .aarch64) {
        @compileError("This example requires aarch64 (ARM64) architecture");
    }
}

pub fn get_tpidr() u64 {
    var value: u64 = undefined;

    asm volatile (
        "mrs {0}, TPIDR_EL0"
        : "=r" (value)
        :
        :
    );

    return value;
}

// 简单的 ARM64 算术运算
pub fn arm_add(a: i32, b: i32) i32 {
    var result: i32 = undefined;

    asm volatile (
        "add {r:w}, {a:w}, {b:w}"
        : [r] "=r" (result)
        : [a] "r" (a),
          [b] "r" (b)
        :
    );

    return result;
}
