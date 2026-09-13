const std = @import("std");

pub fn main() void {
    // 打印调试信息
    std.debug.print("Hello\n", .{});
    std.debug.print("Value: {}\n", .{42});
    std.debug.print("Float: {:.2}\n", .{3.14159});
    std.debug.print("Warning message\n", .{});

    // 打印调用栈
    std.debug.print("File: {s}, Line: {}\n", .{ @src().file, @src().line });

    // 打印类型信息
    std.debug.print("Type: {s}\n", .{@typeName(i32)});
}
