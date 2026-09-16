//! 03 基础类型：任意位宽整数、溢出运算符、comptime 整数、转型家族
const std = @import("std");

pub fn main() !void {
    // ═══ 3.1 const/var：不可变是默认，可变要申请 ═══
    const answer: u32 = 42; // const：赋值后不可改
    var count: i32 = 10; // var：可改（从不修改会编译错）
    count += 5;
    std.debug.print("answer={d} count={d}\n", .{ answer, count });

    // ═══ 3.2 任意位宽整数：u3、i128、usize ═══
    const small: u3 = 5; // 3 位无符号：只能装 0..7
    const wide: u128 = @as(u128, 1) << 100; // 128 位也内建
    const ptr_sized: usize = 1000; // 指针宽度，平台相关
    std.debug.print("u3={d} usize={d} u128>>100={d}\n", .{ small, ptr_sized, wide >> 100 });

    // ═══ 3.3 溢出运算符：+ 与 +% 的区别 ═══
    var byte: u8 = 255;
    // byte += 1;        // 编译可过，Debug 运行 panic：整数溢出（安全检查）
    byte +%= 1; // 环绕语义：255 → 0，永不出错
    var debt: i8 = -128;
    debt -%= 1; // 环绕：-128 → 127
    std.debug.print("255 +%= 1 → {d}；-128 -%= 1 → {d}\n", .{ byte, debt });

    // ═══ 3.4 comptime_int：没有类型的字面量 ═══
    const big = 123_456_789; // comptime_int：任意精度，用到时才定类型
    const hex = 0xFF; // 十六进制
    const oct = 0o77; // 八进制
    const bin = 0b1010; // 二进制
    std.debug.print("big={d} hex={d} oct={d} bin={d}\n", .{ big, hex, oct, bin });

    // ═══ 3.5 浮点与布尔 ═══
    const pi: f64 = 3.14159265358979;
    const half: f32 = 0.5;
    const flag: bool = true;
    std.debug.print("pi={d:.4} half={d} flag={}\n", .{ pi, half, flag });

    // ═══ 3.6 转型家族：每次转换都要点名 ═══
    const a: i32 = 300;
    const b = @as(u8, @truncate(@as(u32, @intCast(a)))); // 截断：只留低 8 位（300 → 44）
    // @intCast 越界会 panic；若值在编译期已知且越界，连编译都过不了（直接报错）
    const fits: i32 = 200;
    const c = @as(u8, @intCast(fits)); // 安全转型：在值域内，OK
    const f = @as(i32, @intFromFloat(3.7)); // 浮→整：截断小数
    const g = @as(f64, @floatFromInt(fits)); // 整→浮
    std.debug.print("truncate={d} intCast={d} intFromFloat={d} floatFrom={d:.1}\n", .{ b, c, f, g });

    // ═══ 3.7 @bitCast：同宽 reinterpret ═══
    const u: u32 = 0x41424344;
    const raw: [4]u8 = @bitCast(u); // 逐字节看内存
    std.debug.print("0x{x:0>8} 的字节序：{any}\n", .{ u, raw });

    std.debug.print("自检通过\n", .{});
}

test "溢出与转型语义" {
    var x: u8 = 255;
    x +%= 1;
    try std.testing.expectEqual(@as(u8, 0), x);
    try std.testing.expectEqual(@as(u8, 44), @as(u8, @truncate(@as(u32, 300))));
    try std.testing.expectEqual(@as(u8, 2), 0b1010 & 0b0110);
}
