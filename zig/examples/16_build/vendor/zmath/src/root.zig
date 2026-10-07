//! 子包 zmath 的根源文件。它是一个「模块」的根：模块 = 这个文件 + build.zig 里
//! 给它配的 target/optimize/imports。
const std = @import("std");

/// 包级常量：模块的"公共头文件"里能看到的编译期数据。
pub const pi: f64 = 3.141592653589793;

/// 故意用 usize 返回长度，提醒调用方这是"Zig 原生宽度"而非 C 的 size_t。
pub fn triple(x: i32) i32 {
    return x * 3;
}

/// 带一点真实逻辑的函数，main.zig 用来证明它确实跨模块编进来了。
pub fn sum_to(n: u32) u64 {
    var total: u64 = 0;
    var i: u32 = 1;
    while (i <= n) : (i += 1) total += i;
    return total;
}

test "zmath.sum_to" {
    try std.testing.expectEqual(@as(u64, 55), sum_to(10));
}

test "zmath.triple" {
    try std.testing.expectEqual(@as(i32, 21), triple(7));
}
