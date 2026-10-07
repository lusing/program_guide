//! 16.8 第二个可执行文件：src/tool.zig。
//!
//! 它和 src/main.zig 共享同一个 `zmath` 模块实例（build.zig 里只
//! `dep.module("zmath")` 取了一次，两个产物各自 import）。
//! 共享 Module 实例意味着 zmath 的机器码只编一次、两份产物各自链接。
//!
//! 注意它**没有** import `build16_lib` 和 `build_options`——
//! 模块的 imports 表是逐模块声明的，不是全工程可见的。
const std = @import("std");
const zmath = @import("zmath");

pub fn main(init: std.process.Init) !void {
    _ = init;
    std.debug.print("16_build_tool：第二个可执行文件\n", .{});
    std.debug.print("  zmath.triple(7)  = {d}\n", .{zmath.triple(7)});
    std.debug.print("  zmath.sum_to(10) = {d}\n", .{zmath.sum_to(10)});
    std.debug.print("  zmath.pi         = {d:.5}\n", .{zmath.pi});
}

test "tool 引用的依赖模块在测试里同样可用" {
    try std.testing.expectEqual(@as(i32, 21), zmath.triple(7));
}
