const std = @import("std");

// 导出函数给 JavaScript 调用
pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub export fn subtract(a: i32, b: i32) i32 {
    return a - b;
}

pub export fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

// 导入 JavaScript 函数
extern fn console_log(msg: [*]const u8) void;

pub fn main() void {
    const result = add(10, 20);
    // 这里需要通过某种方式调用 console.log
}
