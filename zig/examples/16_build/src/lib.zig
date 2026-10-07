//! 16.12 同工程多模块：src/lib.zig。
//!
//! 它被 build.zig 用 `b.createModule(.{ .root_source_file = b.path("src/lib.zig"), … })`
//! 提升成一个**具名模块** `build16_lib`，主模块通过
//! `@import("build16_lib")` 引用它。
//!
//! 关键差别：如果 main.zig 写 `@import("lib.zig")`，lib.zig 就只是
//! 「main 这个模块目录里的另一个文件」——跟着 main 的 target/optimize 走。
//! 提升成独立模块后它有自己的编译选项作用域，能被多个产物共享。
const std = @import("std");

/// 这个模块的自我标识（用它证明 @import 拿到的确实是 build16_lib）。
pub const module_name = "build16_lib";

/// 编译期版本：n 必须是编译期已知，返回哨兵切片，长度也是编译期常量。
/// 适合"分隔线""缩进"这类长度固定、调用点都写死字面量的场景。
pub fn dash_line(comptime n: usize) *const [n:0]u8 {
    comptime var buf: [n:0]u8 = undefined;
    inline for (0..n) |i| buf[i] = '-';
    return &buf;
}

/// 运行时版本：n 是普通参数，循环填 '-'。
/// 这里刻意用 `alloc` 而不是 `allocSentinel` —— 后者分配 n+1 字节
/// （哨兵不计入切片长度），把它当`[]u8` 交给 allocator.free() 会触发
/// testing.allocator 的 "free ... mismatches allocation" 报警。
/// comptime 参数 vs 运行时参数的区别见 13 章。
pub fn separator(allocator: std.mem.Allocator, n: usize) ![]u8 {
    const s = try allocator.alloc(u8, n);
    errdefer allocator.free(s);
    @memset(s, '-');
    return s;
}

/// 需要 0结尾字符串时，在separator 后面手工补一个哨兵位——
/// 这就是 06 章"哨兵切片"的用处：多分配一个字节换 strlen 能力。
pub fn separatorZ(allocator: std.mem.Allocator, n: usize) ![:0]u8 {
    const s = try allocator.allocSentinel(u8, n, 0);
    errdefer allocator.free(s[0..n :0]);
    @memset(s[0..n], '-');
    return s;
}

test "lib.dash_line 编译期算长度" {
    try std.testing.expectEqual(@as(usize, 9), dash_line(9).len);
    try std.testing.expectEqual(@as(u8, 0), dash_line(4)[4]); // 哨兵
}

test "lib.separator 运行时长度" {
    const a = std.testing.allocator;
    const s = try separator(a, 12);
    defer a.free(s);
    try std.testing.expectEqual(@as(usize, 12), s.len);
    try std.testing.expectEqualStrings("------------", s);
}

test "lib.separatorZ 哨兵版：free 要用 s[0..n :0]" {
    const a = std.testing.allocator;
    const s = try separatorZ(a, 4);
    defer a.free(s[0..s.len :0]);
    try std.testing.expectEqualStrings("----", s);
    try std.testing.expectEqual(@as(u8, 0), s[s.len]); // 哨兵位真的是 0
}
