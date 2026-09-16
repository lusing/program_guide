//! 05 函数：defer、anytype、comptime 参数、没有重载怎么办
const std = @import("std");

// ═══ 5.1 基本形态：参数与返回类型显式写
fn add(a: i64, b: i64) i64 {
    return a + b;
}

// ═══ 5.2 defer：作用域退出时执行（LIFO 逆序）
fn deferDemo() void {
    std.debug.print("进入函数\n", .{});
    defer std.debug.print("defer A（先注册，最后跑）\n", .{});
    defer std.debug.print("defer B（后注册，先跑）\n", .{});
    {
        defer std.debug.print("块级 defer（出了块就跑）\n", .{});
        std.debug.print("块内\n", .{});
    }
    std.debug.print("函数体末尾\n", .{});
}

// ═══ 5.3 comptime 参数：让"重载"变成类型分派
fn maxOf(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

// ═══ 5.4 anytype：编译期鸭子类型（print 的实现原理）
fn describe(value: anytype) void {
    const T = @TypeOf(value);
    std.debug.print("类型 {s}，值 {any}\n", .{ @typeName(T), value });
}

// ═══ 5.5 没有嵌套函数：本地函数用"匿名 struct 命名空间"模拟（不能捕获外层变量）
fn outer(x: i64) i64 {
    const square = struct { // struct 是容器，容器里才能放 fn
        fn call(v: i64) i64 {
            return v * v;
        }
    }.call;

    return square(x) + square(@divTrunc(x, 2)); // 有符号除法必须点名：@divTrunc/@divFloor/@divExact
}

pub fn main() !void {
    std.debug.print("add(3,4)={d}\n", .{add(3, 4)});
    deferDemo();

    // ═══ 5.6 没有重载：同名不同参直接编译错 → 用 comptime T / anytype 替代
    std.debug.print("max i32={d} f64={d:.1}\n", .{ maxOf(i32, 3, 9), maxOf(f64, 2.5, 1.5) });

    describe(42);
    describe(3.14);
    describe("字符串也行");
    describe(true);

    std.debug.print("outer(8)={d}\n", .{outer(8)});

    // ═══ 5.7 没有默认参数 → 用"参数结构体"惯用法
    const DrawOpts = struct {
        color: []const u8 = "黑",
        bold: bool = false,
    };
    const draw = struct {
        fn rect(opts: DrawOpts) void {
            std.debug.print("画矩形：{s} {}（参数结构体给默认值）\n", .{ opts.color, opts.bold });
        }
    };
    draw.rect(.{}); // 全默认
    draw.rect(.{ .color = "红", .bold = true }); // 覆盖个别

    std.debug.print("自检通过\n", .{});
}

test "函数语义" {
    try std.testing.expectEqual(@as(i64, 7), add(3, 4));
    try std.testing.expectEqual(@as(i32, 9), maxOf(i32, 3, 9));
    try std.testing.expectEqual(@as(f64, 2.5), maxOf(f64, 2.5, 1.5));
    try std.testing.expectEqual(@as(i64, 80), outer(8));
}
