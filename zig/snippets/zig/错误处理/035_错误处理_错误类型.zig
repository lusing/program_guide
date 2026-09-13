const std = @import("std");

const MyError = error{
    OutOfMemory,
    FileNotFound,
    InvalidInput,
};

fn divide(a: i32, b: i32) MyError!i32 {
    if (b == 0) return MyError.InvalidInput;
    return a / b;
}

pub fn main() void {
    var result = divide(10, 2) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };
    std.debug.print("Result: {}\n", .{result});
}
