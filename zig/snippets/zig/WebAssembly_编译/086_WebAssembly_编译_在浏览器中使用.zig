const std = @import("std");

// 导出函数供 JavaScript 调用
export fn fibonacci(n: u32) u32 {
    if (n <= 1) return n;
    var a: u32 = 0;
    var b: u32 = 1;
    for (2..n + 1) |_| {
        const temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}

export fn compute_sum(n: u32) u32 {
    var sum: u32 = 0;
    for (0..n) |i| {
        sum +%= @intCast(u32, i);
    }
    return sum;
}
