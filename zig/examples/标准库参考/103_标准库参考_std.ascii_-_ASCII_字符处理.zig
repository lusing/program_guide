const std = @import("std");

pub fn main() void {
    // 字符检查
    std.debug.print("'a' is alpha: {}\n", .{std.ascii.isAlphabetic('a')});
    std.debug.print("'1' is digit: {}\n", .{std.ascii.isDigit('1')});
    std.debug.print("' ' is space: {}\n", .{std.ascii.isWhitespace(' ')});

    // 转换
    std.debug.print("Upper: {}\n", .{std.ascii.toUpper('a')});
    std.debug.print("Lower: {}\n", .{std.ascii.toLower('A')});

    // 字符串转换
    var buf: [10]u8 = undefined;
    const upper = std.ascii.upperString(&buf, "hello");
    std.debug.print("Upper: {s}\n", .{upper});
}
