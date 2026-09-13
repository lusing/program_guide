const std = @import("std");

fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

fn min(comptime T: type, a: T, b: T) T {
    return if (a < b) a else b;
}

fn reverse(slice: []i32) void {
    var left: usize = 0;
    var right: usize = slice.len - 1;
    while (left < right) {
        const temp = slice[left];
        slice[left] = slice[right];
        slice[right] = temp;
        left += 1;
        right -= 1;
    }
}

pub fn main() void {
    std.debug.print("max(5, 10) = {}\n", .{max(i32, 5, 10)});
    std.debug.print("min(5, 10) = {}\n", .{min(i32, 5, 10)});

    var arr = [_]i32{ 1, 2, 3, 4, 5 };
    reverse(arr[0..]);
    std.debug.print("Reversed: {any}\n", .{arr});
}

