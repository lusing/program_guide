const std = @import("std");

fn divide(a: i32, b: i32) i32 {
    std.debug.print("divide({}, {})\n", .{ a, b });

    if (b == 0) {
        @panic("Division by zero!");
    }

    const result = @divTrunc(a, b);
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
    const a: i32 = 10;
    const b: i32 = 20;
    const c: i32 = 5;

    std.debug.print("Starting calculation\n", .{});

    const result = calculate(a, b, c);

    std.debug.print("Final result: {}\n", .{result});
}
