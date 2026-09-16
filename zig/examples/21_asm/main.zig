//! 21 内联汇编与底层：asm 语法、约束、volatile、extern struct
const std = @import("std");
const builtin = @import("builtin");

comptime {
    if (builtin.cpu.arch != .x86_64) {
        @compileError("本章汇编示例针对 x86_64（其他架构思路见正文）");
    }
}

// ═══ 21.2 最小示例："+r" 读写在同一寄存器
fn addImm(x: u64) u64 {
    var r = x;
    asm volatile ("add $5, %[r]" // AT&T 语法 + LLVM 模板：具名操作数用 %[名字]
        : [r] "+r" (r), // +r：输入输出同寄存器
    );
    return r;
}

// ═══ 21.5 rdtsc：绑定固定寄存器的多输出
fn rdtsc() u64 {
    var lo: u32 = undefined;
    var hi: u32 = undefined;
    asm volatile (
        \\rdtsc
        : [lo] "={eax}" (lo), // =：只输出；{eax}：固定用 eax
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | lo;
}

pub fn main() !void {
    std.debug.print("addImm(37) = {d}（汇编 +5）\n", .{addImm(37)});

    const t0 = rdtsc();
    var sink: u64 = 0;
    for (0..1000) |i| sink +%= i;
    const t1 = rdtsc();
    std.debug.print("1000 次加法 ≈ {d} tick（rdtsc 计时）sink={d}\n", .{ t1 - t0, sink });

    // ═══ 21.6 extern struct：与 C 完全一致的内存布局
    const Pair = extern struct { a: u32, b: u32 };
    const p = Pair{ .a = 1, .b = 2 };
    const as_u64: u64 = @bitCast(p);
    std.debug.print("extern struct 位模式 0x{x:0>16}（低位是 a=1）\n", .{as_u64});

    std.debug.print("自检通过\n", .{});
}

test "汇编与位模式" {
    try std.testing.expectEqual(@as(u64, 42), addImm(37));
    const t = rdtsc();
    try std.testing.expect(t > 0);
    const Pair = extern struct { a: u32, b: u32 };
    const p = Pair{ .a = 7, .b = 0 };
    try std.testing.expectEqual(@as(u64, 7), @as(u64, @bitCast(p)));
}
