//! 16 构建系统：被 main 相对导入的模块
const std = @import("std");

pub fn hello(allocator: std.mem.Allocator, who: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "你好，{s}！", .{who});
}

test "hello 拼接" {
    const a = std.testing.allocator;
    const m = try hello(a, "Z");
    defer a.free(m);
    try std.testing.expectEqualStrings("你好，Z！", m);
}
