const std = @import("std");

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub export fn subtract(a: i32, b: i32) i32 {
    return a - b;
}

pub export fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

pub fn main() void {
    const result = add(10, 20);
    std.debug.print("result = {}\n", .{result});
}
