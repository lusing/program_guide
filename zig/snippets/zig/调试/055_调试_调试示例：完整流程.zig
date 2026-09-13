const std = @import("std");

fn divide(a: i32, b: i32) i32 {
    // 在关键位置设置断点
    std.debug.print("divide({}, {})\n", .{ a, b });

    if (b == 0) {
        @panic("Division by zero!");
    }

    const result = a / b;
    std.debug.print("result = {}\n", .{result});
    return result;
}

fn calculate(x: i32, y: i32, z: i32) i32 {
    std.debug.print("calculate({}, {}, {})\n", .{ x, y, z });

    const sum = x + y;
    std.debug.print("sum = {}\n", .{sum});

    return divide(sum, z);
}

pub fn main() void {
    var a: i32 = 10;
    var b: i32 = 20;
    var c: i32 = 5;

    std.debug.print("Starting calculation\n", .{});

    const result = calculate(a, b, c);

    std.debug.print("Final result: {}\n", .{result});
}
