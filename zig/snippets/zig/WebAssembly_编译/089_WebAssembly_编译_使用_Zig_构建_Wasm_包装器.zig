const std = @import("std");

// 导入的 JS 模块
extern fn js_add(a: i32, b: i32) i32;

// 导出给 JS 调用
export fn zig_add(a: i32, b: i32) i32 {
    return js_add(a, b);
}

// 复杂计算
export fn complex_calc(x: i32) i32 {
    var result: i32 = 1;
    for (1..x + 1) |i| {
        result *= i;
    }
    return result;
}
