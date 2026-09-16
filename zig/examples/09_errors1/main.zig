//! 09 可选类型与错误处理 I：?T、error set、!T、try/catch
const std = @import("std");

// ═══ 9.1 ?T：可能缺席的值（null 是类型，不是万恶空指针）
fn findFirst(hay: []const u8, needle: u8) ?usize {
    for (hay, 0..) |b, i| {
        if (b == needle) return i;
    }
    return null;
}

// ═══ 9.3 错误集合：编译期的"错误名字集合"
const ParseError = error{
    Empty,
    NotDigit,
    TooLong,
};

// ═══ 9.4 错误联合 !T：值，或者错误
fn parseScore(s: []const u8) ParseError!u8 {
    if (s.len == 0) return error.Empty;
    if (s.len > 3) return error.TooLong;
    var v: u16 = 0;
    for (s) |ch| {
        if (ch < '0' or ch > '9') return error.NotDigit;
        v = v * 10 + (ch - '0');
    }
    return @intCast(v);
}

// ═══ 9.5 try：出错就向上抛（catch |e| return e 的语法糖）
fn showScore(s: []const u8) ParseError!void {
    const score = try parseScore(s);
    std.debug.print("得分 {d}\n", .{score});
}

pub fn main() !void {
    // ═══ 9.2 解包三件套：if 捕获 / orelse / .?
    const idx = findFirst("zig-lang", '-');
    if (idx) |i| {
        std.debug.print("'-' 在下标 {d}\n", .{i});
    } else {
        std.debug.print("没找到\n", .{});
    }
    const fallback = findFirst("zig", '-') orelse 999; // 缺席给默认
    const sure = findFirst("zig", 'z').?; // 确信非 null（null 则 panic）
    std.debug.print("fallback={d} sure={d}\n", .{ fallback, sure });

    // ═══ 9.6 catch：就地处理（给后备值）
    const a = parseScore("88") catch 0;
    const b = parseScore("8x8") catch 0;
    std.debug.print("a={d} b={d}\n", .{ a, b });

    // ═══ 9.7 if/else 捕获错误：值或错误二选一
    if (parseScore("")) |v| {
        std.debug.print("值 {d}\n", .{v});
    } else |err| {
        std.debug.print("错误名：{s}\n", .{@errorName(err)});
    }

    // try 传播：showScore 自己不处理，抛给 main
    showScore("95") catch |err| std.debug.print("showScore 失败：{s}\n", .{@errorName(err)});
    showScore("95x") catch |err| std.debug.print("showScore 失败：{s}\n", .{@errorName(err)});

    // ═══ 9.8 推断错误集：签名只写 !T，集合编译器算
    const inferred = try parseScore("1"); // ParseError!u8
    std.debug.print("inferred={d}；错误集合还能做并集（见 test）\n", .{inferred});
    std.debug.print("自检通过\n", .{});
}

test "可选与错误" {
    try std.testing.expectEqual(@as(?usize, 3), findFirst("zig-lang", '-'));
    try std.testing.expectEqual(@as(?usize, null), findFirst("zig", '-'));
    try std.testing.expectEqual(@as(u8, 88), try parseScore("88"));
    try std.testing.expectError(error.NotDigit, parseScore("8x"));
    try std.testing.expectError(error.Empty, parseScore(""));
    try std.testing.expectError(error.TooLong, parseScore("1234"));
    // 错误集合并集：E1 || E2
    const Mixed = ParseError || error{Boom};
    try std.testing.expectError(error.Boom, @as(Mixed!void, error.Boom));
    try std.testing.expectError(error.NotDigit, @as(Mixed!void, error.NotDigit));
}
