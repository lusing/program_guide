const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 格式化到字符串
    const str = try std.fmt.allocPrint(allocator, "Hello, {}!", .{"World"});
    defer allocator.free(str);

    // 格式化数字
    const num_str = try std.fmt.allocPrint(allocator, "Number: {}", .{42});
    defer allocator.free(num_str);

    // 格式化浮点数
    const float_str = try std.fmt.allocPrint(allocator, "Pi: {:.2}", .{3.14159});
    defer allocator.free(float_str);

    // 解析字符串
    const parsed = try std.fmt.parseInt(i32, "123", 10);
    std.debug.print("Parsed: {}\n", .{parsed});

    // 格式化输出
    std.fmt.print("Format: {}\n", .{42});
    std.fmt.println("Line: {}", .{123});
}
