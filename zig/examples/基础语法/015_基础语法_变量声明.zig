const std = @import("std");

pub fn main() void {
    // 常量
    const pi: f64 = 3.14159;

    // 变量 (使用 var)
    var count: i32 = 10;
    count = 20;

    // 类型推断
    const name = "Zig";
    const active = true;

    std.debug.print("PI: {}, Count: {}, Name: {s}, Active: {}\n", .{ pi, count, name, active });
}
