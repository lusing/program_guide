const std = @import("std");

// 带返回值的函数
fn add(a: i32, b: i32) i32 {
    return a + b;
}

// 无返回值函数
fn printHello() void {
    std.debug.print("Hello!\n", .{});
}

pub fn main() void {
    std.debug.print("add(3, 5) = {}\n", .{add(3, 5)});
    printHello();
}
