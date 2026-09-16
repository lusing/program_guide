//! 13 comptime I：编译期求值——同一份代码的两个世界
const std = @import("std");

// ═══ 13.1 普通函数 + const 实参 = 编译期算完
fn fibonacci(n: usize) usize {
    if (n < 2) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
const fib10 = fibonacci(10); // 55：const 初始化必须编译期可得 → 在编译期算

// ═══ 13.2 comptime 参数：参数本身必须编译期已知（泛型基石）
fn pow(comptime base: u64, comptime exp: u32) u64 {
    return std.math.pow(u64, base, exp);
}
const kib = pow(2, 10); // 1024

// ═══ 13.7 编译期断言：构建期就爆错（不用等运行）
comptime {
    if (fib10 != 55) @compileError("fibonacci 算错了");
}

// ═══ 13.3 容器级 const 本身就在编译期执行（这里写 comptime 关键字反而冗余报错）
const table = blk: {
    @setEvalBranchQuota(10000); // 编译期循环配额（防死循环，超了要申请）
    var t: [16]u16 = undefined;
    for (0..16) |i| t[i] = i * i;
    break :blk t;
};

// ═══ 13.4 comptime var：编译期的"变量"（while 也要配额）
const checksum = blk: {
    @setEvalBranchQuota(100000);
    var acc: u32 = 0;
    var i: usize = 0;
    while (i < 1000) : (i += 1) acc +%= @intCast(i);
    break :blk acc;
};

pub fn main() !void {
    // ═══ 13.1 同一函数，运行期也能调（一份代码两个世界）
    var n: usize = 20; // 假装来自运行期输入
    n += 1;
    std.debug.print("fib(10) 编译期={d}，fib(21) 运行期={d}\n", .{ fib10, fibonacci(n) });

    // ═══ 13.3/13.4 常量已在编译期算好
    std.debug.print("平方表：{any}\n", .{table});
    std.debug.print("0..999 求和（编译期）= {d}\n", .{checksum});

    // ═══ 13.5 inline for：编译期展开循环（序列须编译期已知；不支持索引捕获）
    inline for (.{ "alpha", "beta", "gamma" }) |name| {
        std.debug.print("inline 展开 {s}\n", .{name});
    }

    // ═══ 13.6 编译期内省一眼（@sizeOf 等本身就是 comptime）
    comptime std.debug.assert(@sizeOf(u64) == 8);
    std.debug.print("Kib={d}，自检通过\n", .{kib});
}

test "comptime 与运行期同源" {
    try std.testing.expectEqual(@as(usize, 55), fibonacci(10));
    try std.testing.expectEqual(@as(u64, 1024), kib);
    try std.testing.expectEqual(@as(u16, 9), table[3]);
    try std.testing.expectEqual(@as(u32, 499500), checksum);
}
