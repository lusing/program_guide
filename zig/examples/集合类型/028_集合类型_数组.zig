const std = @import("std");

pub fn main() void {
    // 固定大小数组
    const arr1: [5]i32 = .{ 1, 2, 3, 4, 5 };

    // 推断大小数组
    const arr2 = [_]i32{ 1, 2, 3 };
    _ = arr2;

    // 可变数组
    var arr3 = [_]i32{ 10, 20, 30 };
    arr3[0] = 100;

    std.debug.print("arr1[0] = {}\n", .{arr1[0]});
}
