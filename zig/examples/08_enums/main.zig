//! 08 枚举与联合：enum、tagged union、packed struct
const std = @import("std");

// ═══ 8.1 enum：封闭集合 + 方法
const Color = enum {
    red,
    green,
    blue,

    fn hex(self: Color) u32 {
        return switch (self) {
            .red => 0xFF0000,
            .green => 0x00FF00,
            .blue => 0x0000FF,
        };
    }
};

// ═══ 8.2 指定 tag 类型 + 非穷尽 `_`（与 C 枚举互操作）
const Level = enum(u8) {
    low = 10,
    mid = 50,
    high = 90,
    _, // 允许未知值进来
};

// ═══ 8.3 tagged union：安全的多选一（Zig 的代数数据类型）
const Value = union(enum) {
    int: i64,
    text: []const u8,
    list: []const f64,

    fn kind(self: Value) []const u8 {
        return switch (self) {
            .int => "整数",
            .text => "文本",
            .list => "列表",
        };
    }
};

// ═══ 8.5 packed struct：精确到位的内存布局
const Flags = packed struct {
    bold: bool = false, // 1 bit
    italic: bool = false, // 1 bit
    size: u6 = 0, // 6 bits —— 整体正好 1 字节
};

pub fn main() !void {
    const c = Color.green;
    std.debug.print("{s} = 0x{x:0>6}\n", .{ @tagName(c), c.hex() });

    const lv: Level = @enumFromInt(50);
    const unknown: Level = @enumFromInt(42); // 非穷尽：42 也能装
    // 注意：未知值不能 @tagName（没有对应名字），只能取整数
    std.debug.print("lv={s}({d})，未知值也能装：{d}\n", .{ @tagName(lv), @intFromEnum(lv), @intFromEnum(unknown) });

    var v: Value = .{ .int = 42 }; // 推断：union 字面量
    std.debug.print("kind={s}\n", .{v.kind()});
    v = .{ .text = "hi" }; // 换标签 = 换形态
    std.debug.print("kind={s}，取值 {s}\n", .{ v.kind(), v.text });
    // 读错激活字段（如 v.int）→ Debug/ReleaseSafe 下 panic，正文演示

    // ═══ 8.4 switch 捕获负载：tagged union 的正确打开方式
    const w: Value = .{ .list = &.{ 1.5, 2.5, 3.5 } };
    switch (w) {
        .int => |i| std.debug.print("整数 {d}\n", .{i}),
        .text => |t| std.debug.print("文本 {s}\n", .{t}),
        .list => |ls| std.debug.print("列表 {d} 项：首项 {d:.1}\n", .{ ls.len, ls[0] }),
    }

    // ═══ 8.5 packed struct（续）：整块位布局
    const f = Flags{ .bold = true, .size = 12 };
    const bits: u8 = @bitCast(f);
    std.debug.print("Flags 位布局 0b{b:0>8}（1 字节装 3 字段，bold 占 bit0）\n", .{bits});

    std.debug.print("自检通过\n", .{});
}

test "枚举与联合" {
    try std.testing.expectEqual(@as(u32, 0x00FF00), Color.green.hex());
    try std.testing.expectEqual(@as(u8, 50), @intFromEnum(Level.mid));
    const v: Value = .{ .int = 7 };
    try std.testing.expectEqualStrings("整数", v.kind());
    const got: i64 = switch (v) {
        .int => |i| i,
        else => 0,
    };
    try std.testing.expectEqual(@as(i64, 7), got);
    const f = Flags{ .italic = true };
    const bits: u8 = @bitCast(f);
    try std.testing.expectEqual(@as(u8, 0b10), bits);
}
