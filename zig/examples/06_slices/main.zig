//! 06 数组、切片与字符串：长度进类型、胖指针、哨兵
const std = @import("std");

pub fn main() !void {
    // ═══ 6.1 数组 [N]T：长度是类型的一部分，本身是值
    const arr = [_]i32{ 10, 20, 30, 40, 50 }; // [_] 推断长度（也等价 [5]i32）
    var copy = arr; // 数组赋值 = 整块拷贝
    copy[0] = -1;
    std.debug.print("len={d} arr[0]={d} copy[0]={d}（赋值是拷贝）\n", .{ arr.len, arr[0], copy[0] });

    // ═══ 6.2 切片 []T：指针 + 长度的胖指针（借用的视图）
    const full: []const i32 = &arr; // 数组退化为切片
    const mid: []const i32 = arr[1..3]; // 子切片左闭右开：20, 30
    std.debug.print("full.len={d} mid=({d},{d})\n", .{ full.len, mid[0], mid[1] });
    // mid[9] —— 越界访问在 Debug/ReleaseSafe 下 panic（边界检查），正文演示

    // ═══ 6.3 字符串：没有 string 类型，就是字节切片
    const msg = "你好，Zig"; // 类型 *const [10:0]u8：UTF-8 + 末尾哨兵 0
    const s: []const u8 = msg; // 退化为切片
    std.debug.print("字节长度 {d}（UTF-8 中文每字 3 字节）\n", .{s.len});
    std.debug.print("前 3 字节：{any}（'你' 的 UTF-8 编码；s[0..3] 是数组指针）\n", .{s[0..3]});

    // ═══ 6.4 哨兵切片 [:0]：保证末尾是 0，可直接交给 C
    const cz: [:0]const u8 = msg;
    std.debug.print("哨兵字节 s[len] = {d}（0 结尾，C 可直接用）\n", .{cz[cz.len]});

    // ═══ 6.5 三种指针：*T 单项 / [*]T 多项 / [*:0]T 哨兵多项
    var x: u32 = 42;
    const p: *u32 = &x; // 单项指针：解引用用 p.*
    p.* += 1;
    const many: [*]const i32 = &arr; // 多项指针：只有起点没有长度
    std.debug.print("*p={d} many[0]={d}\n", .{ p.*, many[0] });

    // ═══ 6.6 可变切片：[]u8 才能写
    var buf = [_]u8{ 'a', 'b', 'c', 'd' };
    const mut: []u8 = buf[0..];
    mut[0] = 'A';
    std.debug.print("改后：{s}\n", .{mut});
    // const s2: []const u8 = mut;   // 只读视图随时可以要
    std.debug.print("自检通过\n", .{});
}

test "数组切片语义" {
    const a = [_]i32{ 1, 2, 3, 4 };
    var total: i32 = 0;
    for (a) |v| total += v;
    try std.testing.expectEqual(@as(i32, 10), total);
    const s = a[1..3];
    try std.testing.expectEqual(@as(usize, 2), s.len);
    try std.testing.expectEqual(@as(i32, 2), s[0]);
    const lit = "hello";
    try std.testing.expectEqual(@as(usize, 5), lit.len);
    var b = [_]u8{ 1, 2 };
    const m: []u8 = &b;
    m[1] = 9;
    try std.testing.expectEqual(@as(u8, 9), b[1]);
}
