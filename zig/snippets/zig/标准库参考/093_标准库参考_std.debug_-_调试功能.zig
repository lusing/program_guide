const std = @import("std");

pub fn main() void {
    // 打印调试信息
    std.debug.print("Hello\n", .{});
    std.debug.print("Value: {}\n", .{42});
    std.debug.print("Float: {:.2}\n", .{3.14159});

    // 打印到标准错误（使用 stderr）
    const stderr = std.io.getStdErr().writer();
    stderr.print("Warning message\n", .{}) catch {};

    // 打印调用栈
    std.debug.print("File: {}, Line: {}\n", .{ @src().file, @src().line });

    // 打印类型信息
    std.debug.print("Type: {}\n", .{@typeName(i32)});
}
