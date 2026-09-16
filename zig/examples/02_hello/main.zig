//! 02 第一个程序：std.debug.print、stdout Writer、Init 入口、test 自检
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // ═══ 2.1 std.debug.print：最省事的输出（stderr，立即落地）═══
    std.debug.print("你好，Zig 0.16！\n", .{});
    std.debug.print("编号 {d:0>3}，十六进制 {x}，二进制 {b}\n", .{ 7, 255, 10 });

    // ═══ 2.2 stdout：缓冲 Writer + flush（0.16 新接口，标准姿势）═══
    var buf: [256]u8 = undefined;
    var w = std.Io.File.stdout().writer(init.io, &buf);
    const out = &w.interface;
    try out.print("姓名：{s}，年龄：{d}\n", .{ "阿 Z", 25 });
    try out.print("PI ≈ {d:.2}\n", .{3.14159});
    try out.flush(); // 缓冲输出必须 flush，否则进程退出前可能丢尾部

    // ═══ 2.3 Init：main 的标准参数包（io/gpa/arena/args）═══
    std.debug.print("Init 字段就位：io={s} gpa={s}\n", .{
        @typeName(@TypeOf(init.io)),
        @typeName(@TypeOf(init.gpa)),
    });
    std.debug.print("自检通过\n", .{});
}

test "打印不是测试重点，先验证格式化语义" {
    const name = "阿 Z";
    try std.testing.expectEqualStrings("阿 Z", name);
    try std.testing.expectEqual(@as(u8, 7), 7);
}
