const std = @import("std");

fn maxValue(comptime T: type, arr: []const T) T {
    var max = arr[0];
    for (arr) |val| {
        if (val > max) max = val;
    }
    return max;
}

pub fn main() void {
    const arr1 = [_]i32{ 1, 5, 3, 9, 2 };
    std.debug.print("Max i32: {}\n", .{maxValue(i32, &arr1)});

    const arr2 = [_]f64{ 1.5, 5.2, 3.8, 9.1, 2.4 };
    std.debug.print("Max f64: {}\n", .{maxValue(f64, &arr2)});
}

