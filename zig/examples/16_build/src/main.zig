//! 16 构建系统：工程入口（多文件模块 + 测试步骤）
const std = @import("std");
const greet = @import("greet.zig");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const gpa = da.allocator();

    const msg = try greet.hello(gpa, "构建系统");
    defer gpa.free(msg);
    std.debug.print("{s}\n", .{msg});
    std.debug.print("本工程由 build.zig 驱动：zig build / build run / build test\n", .{});
}

test "greet 模块可用" {
    const a = std.testing.allocator;
    const m = try greet.hello(a, "t");
    defer a.free(m);
    try std.testing.expectEqualStrings("你好，t！", m);
}
