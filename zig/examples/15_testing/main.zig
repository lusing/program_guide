//! 15 测试：test 块、std.testing 断言、testing.allocator 泄漏检测
const std = @import("std");
const util = @import("util.zig");

// 被测函数：把字符串重复 n 遍（分配失败要回滚）
fn repeat(allocator: std.mem.Allocator, s: []const u8, n: usize) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (0..n) |_| try out.appendSlice(allocator, s);
    return out.toOwnedSlice(allocator);
}

const parseLike = struct {
    fn f(x: u8) error{TooBig}!u8 {
        return if (x > 3) error.TooBig else x;
    }
}.f;

pub fn main() !void {
    const a = std.heap.page_allocator;
    const r = try repeat(a, "ab", 3);
    defer a.free(r);
    std.debug.print("repeat(ab,3) = {s}\n", .{r});
    const slug = try util.sluggify(a, "Hello World!");
    defer a.free(slug);
    std.debug.print("sluggify = {s}\n", .{slug});
    std.debug.print("本文件的全部断言用 zig test 运行（自检通过）\n", .{});
}

test "repeat 重复拼接" {
    const a = std.testing.allocator;
    const r = try repeat(a, "ab", 3);
    defer a.free(r);
    try std.testing.expectEqualStrings("ababab", r);
}

test "repeat 零次得到空串" {
    const a = std.testing.allocator;
    const r = try repeat(a, "x", 0);
    defer a.free(r);
    try std.testing.expectEqual(@as(usize, 0), r.len);
}

test "断言族速览" {
    try std.testing.expect(true);
    try std.testing.expectEqual(@as(u8, 4), 2 + 2);
    try std.testing.expectEqualStrings("zig", "z" ++ "ig");
    try std.testing.expectEqualSlices(u8, "abc", "abc");
    try std.testing.expectError(error.TooBig, parseLike(9));
    const opt: ?u8 = null;
    try std.testing.expect(opt == null); // 0.16 没有 expectNull，直接判空
}

test "testing.allocator 抓泄漏" {
    const a = std.testing.allocator;
    const buf = try a.alloc(u8, 10);
    a.free(buf); // ← 注释掉这行再 zig test：直接判泄漏失败
}

test {
    _ = util; // 引用其它文件的测试（不引用就不跑）
}
