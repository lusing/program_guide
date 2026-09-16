//! 23 调试与工具链：assert、panic 开关、io.now 计时、@breakpoint
const std = @import("std");
const builtin = @import("builtin");

fn risky(x: u32) u32 {
    std.debug.assert(x != 0); // Debug/ReleaseSafe 生效，ReleaseFast 编译掉
    return 100 / x;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // ═══ 23.1 构建模式与 assert 生死
    std.debug.print("构建模式：{s}\n", .{@tagName(builtin.mode)});
    std.debug.print("risky(4) = {d}\n", .{risky(4)});

    // ═══ 23.2 单调钟做微基准（0.16：std.time 的计时函数已并入 io）
    var sink: u64 = 0;
    const t0 = std.Io.Timestamp.now(io, .awake);
    for (0..1_000_000) |i| sink +%= @intCast(i % 7);
    const t1 = std.Io.Timestamp.now(io, .awake);
    std.debug.print("百万次循环 {d} ns（sink={d}，防优化）\n", .{ t0.durationTo(t1).nanoseconds, sink });

    // ═══ 23.3 可开关的 panic / @breakpoint / 错误跟踪演示（build.ps1 不设这些变量）
    if (init.environ_map.get("ZIG_PANIC") != null) {
        @panic("演示 panic：看栈跟踪（正文贴真实输出）");
    }
    if (init.environ_map.get("ZIG_BREAK") != null) {
        @breakpoint(); // 调试器里等价 int3；无调试器会崩——正文说明
    }
    if (init.environ_map.get("ZIG_ERT") != null) {
        return error.DemoErrorReturnTrace; // Debug 下 stderr 打印完整来路
    }

    std.debug.print("自检通过\n", .{});
}

test "risky 正常路径" {
    try std.testing.expectEqual(@as(u32, 25), risky(4));
}
