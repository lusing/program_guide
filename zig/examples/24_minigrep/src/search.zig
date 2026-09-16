//! 24 实战：搜索核心（纯逻辑，好测试——不碰线程和 IO）
const std = @import("std");

pub const Match = struct {
    path: []const u8,
    line_no: usize,
    line: []const u8,
};

/// 在多行文本中找 needle，返回全部命中（line 借用 text 的内存）
pub fn searchLines(allocator: std.mem.Allocator, text: []const u8, needle: []const u8) ![]Match {
    var hits: std.ArrayList(Match) = .empty;
    errdefer hits.deinit(allocator);
    var line_it = std.mem.splitScalar(u8, text, '\n');
    var n: usize = 0;
    while (line_it.next()) |line| {
        n += 1;
        if (needle.len == 0) continue;
        if (std.mem.indexOf(u8, line, needle) != null) {
            try hits.append(allocator, .{ .path = "", .line_no = n, .line = line });
        }
    }
    return hits.toOwnedSlice(allocator);
}

/// 高亮打印：path:行号: 行内容（命中段红色加粗，ANSI 转义）
pub fn printHighlighted(w: *std.Io.Writer, path: []const u8, m: Match, needle: []const u8) !void {
    try w.print("{s}:{d}: ", .{ path, m.line_no });
    var rest = m.line;
    while (std.mem.indexOf(u8, rest, needle)) |at| {
        try w.print("{s}\x1b[1;31m{s}\x1b[0m", .{ rest[0..at], rest[at .. at + needle.len] });
        rest = rest[at + needle.len ..];
    }
    try w.print("{s}\n", .{rest});
}

test "searchLines 行号正确" {
    const a = std.testing.allocator;
    const hits = try searchLines(a, "aa\nbb\naa", "aa");
    defer a.free(hits);
    try std.testing.expectEqual(@as(usize, 2), hits.len);
    try std.testing.expectEqual(@as(usize, 1), hits[0].line_no);
    try std.testing.expectEqual(@as(usize, 3), hits[1].line_no);
    const one = try searchLines(a, "aa\nbb\naa", "bb");
    defer a.free(one);
    try std.testing.expectEqualStrings("bb", one[0].line);
}

test "printHighlighted 含 ANSI 转义" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try printHighlighted(&w, "f.txt", .{ .path = "f.txt", .line_no = 1, .line = "abxcd" }, "x");
    const out = w.buffered();
    try std.testing.expect(std.mem.indexOf(u8, out, "\x1b[1;31mx\x1b[0m") != null);
    try std.testing.expect(std.mem.startsWith(u8, out, "f.txt:1: "));
}
