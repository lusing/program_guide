//! 15 测试：模块也带自己的测试
const std = @import("std");

/// slug 化：小写 + 空格换连字符
pub fn sluggify(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (s) |ch| {
        try out.append(allocator, if (ch == ' ') '-' else std.ascii.toLower(ch));
    }
    return out.toOwnedSlice(allocator);
}

test "sluggify 行为" {
    const a = std.testing.allocator;
    const r = try sluggify(a, "Hello World!");
    defer a.free(r);
    try std.testing.expectEqualStrings("hello-world!", r);
}
