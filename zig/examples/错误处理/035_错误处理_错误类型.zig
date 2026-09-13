const std = @import("std");

const MyError = error{
    OutOfMemory,
    FileNotFound,
    InvalidInput,
};

fn divide(a: i32, b: i32) MyError!i32 {
    if (b == 0) return MyError.InvalidInput;
    return @divTrunc(a, b);
}

pub fn main() void {
    const result = divide(10, 2) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };
    std.debug.print("Result: {}\n", .{result});
}
