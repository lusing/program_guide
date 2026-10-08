//! 35 · ZLS 与编辑器工具链 —— check 步骤的演示对象。
//!
//! 这个程序本身故意写得很小：本章的主角不是它，
//! 而是 build.zig 里那个名为 "check" 的步骤——
//! ZLS 保存文件时替你跑的就是 `zig build check`。

const std = @import("std");

/// 给 comptime 已知宽度求"十进制位数"。
/// 故意写成递归：类型不同 N 就各实例化一份，单态化看得见。
fn digits(comptime N: usize) usize {
    if (N < 10) return 1;
    return 1 + digits(N / 10);
}

pub fn main(init: std.process.Init) !void {
    var buf: [128]u8 = undefined;
    var w = std.Io.File.stdout().writer(init.io, &buf);
    const out = &w.interface;
    try out.print("digits(7)={d} digits(42)={d} digits(1000)={d}\n", .{
        digits(7), digits(42), digits(1000),
    });
    try out.flush();
}

test "digits 的边界" {
    try std.testing.expectEqual(@as(usize, 1), digits(0));
    try std.testing.expectEqual(@as(usize, 1), digits(9));
    try std.testing.expectEqual(@as(usize, 2), digits(10));
    try std.testing.expectEqual(@as(usize, 4), digits(1000));
}
