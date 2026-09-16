//! 04 控制流：if/while/for 的表达式语义、label、switch 穷尽与捕获
const std = @import("std");

fn gradeLabel(score: u8) []const u8 {
    // ═══ 4.1 if 是表达式：没有三元运算符 ?: ═══
    return if (score >= 90) "优秀" else if (score >= 60) "及格" else "不及格";
}

pub fn main() !void {
    // ═══ 4.1 if/else 表达式 ═══
    std.debug.print("85 → {s}，59 → {s}\n", .{ gradeLabel(85), gradeLabel(59) });

    // ═══ 4.2 while 与 continue 表达式 : (i += 1) ═══
    var i: usize = 0;
    var sum: usize = 0;
    while (i < 5) : (i += 1) {
        if (i == 2) continue; // 跳过 2，continue 表达式仍执行
        sum += i;
    }
    std.debug.print("sum(0..4 去 2) = {d}\n", .{sum}); // 0+1+3+4 = 8

    // ═══ 4.3 for：数组、范围、zip 多序列、带索引 ═══
    const names = [_][]const u8{ "C", "Zig", "Rust" };
    const years = [_]u16{ 1972, 2016, 2015 };
    for (names, years, 0..) |n, y, idx| { // 三序列并行迭代
        std.debug.print("[{d}] {s} 诞生于 {d}\n", .{ idx, n, y });
    }
    for (0..3) |k| std.debug.print("k={d} ", .{k});
    std.debug.print("\n", .{});

    // ═══ 4.4 label：从内层循环直接跳出外层 ═══
    outer: for (0..3) |row| {
        for (0..3) |col| {
            if (col == 2) continue :outer; // 直接进入外层下一轮
            if (row == 2) break :outer; // 直接终止外层
            std.debug.print("({d},{d}) ", .{ row, col });
        }
    }
    std.debug.print("\n", .{});

    // ═══ 4.5 switch：穷尽性检查是编译期保证 ═══
    for ([_]u8{ 3, 7, 20 }) |v| {
        const desc = switch (v) {
            1, 2, 3 => "低", // 多值并列
            4...9 => "中", // 范围
            10...99 => "高",
            else => "爆表", // 非穷尽类型必须 else
        };
        std.debug.print("{d}→{s} ", .{ v, desc });
    }
    std.debug.print("\n", .{});

    // ═══ 4.6 switch 也是表达式 + 捕获枚举负载（枚举见第 08 章）═══
    const Shape = union(enum) { circle: f64, rect: struct { w: f64, h: f64 } };
    const s = Shape{ .rect = .{ .w = 3, .h = 4 } };
    const area: f64 = switch (s) {
        .circle => |r| 3.14159 * r * r,
        .rect => |d| d.w * d.h,
    };
    std.debug.print("面积 = {d:.1}\n", .{area});

    // ═══ 4.7 labeled switch：状态机式 continue ═══
    const State = enum { start, running, done };
    var st: State = .start;
    var ticks: usize = 0;
    const total = sw: switch (st) {
        .start => {
            ticks += 1;
            st = .running;
            continue :sw .running; // 就地换分支继续
        },
        .running => {
            ticks += 1;
            st = .done;
            continue :sw .done;
        },
        .done => break :sw ticks,
    };
    std.debug.print("状态机走 {d} 步\n", .{total});

    std.debug.print("自检通过\n", .{});
}

test "控制流语义" {
    try std.testing.expectEqualStrings("及格", gradeLabel(70));
    var total: usize = 0;
    for (0..5) |i| total += i;
    try std.testing.expectEqual(@as(usize, 10), total);
    const d = switch (2) {
        1...2 => 100,
        else => 0,
    };
    try std.testing.expectEqual(@as(u32, 100), d);
}
