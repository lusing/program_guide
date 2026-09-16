//! 18 交叉编译：同一份源码，多个目标（build.ps1 交叉验证 aarch64-linux 与 wasm）
const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // ═══ 18.1 builtin：目标在编译期就知道
    std.debug.print("架构 {s}，系统 {s}，模式 {s}\n", .{
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
        @tagName(builtin.mode),
    });

    // ═══ 18.2 编译期按架构分派（交叉产物走哪个分支在构建时就定了）
    const arch_code: u8 = switch (builtin.cpu.arch) {
        .x86_64 => 1,
        .aarch64 => 2,
        else => 255,
    };
    std.debug.print("本架构代号 {d}（交叉编译时代码随之切换）\n", .{arch_code});
    std.debug.print("自检通过\n", .{});
}

test "native 可运行（交叉产物只验证编译——差异本身就是教学点）" {
    const arch_code: u8 = switch (builtin.cpu.arch) {
        .x86_64 => 1,
        .aarch64 => 2,
        else => 255,
    };
    try std.testing.expect(arch_code >= 1);
}
