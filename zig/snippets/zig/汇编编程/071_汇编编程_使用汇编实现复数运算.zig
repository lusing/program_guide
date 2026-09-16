const std = @import("std");
const builtin = @import("builtin");

comptime {
    if (builtin.cpu.arch != .x86_64) {
        @compileError("This example requires x86_64 architecture with SSE2 support");
    }
}

const Complex = struct {
    re: f64,
    im: f64,

    fn add(self: Complex, other: Complex) Complex {
        var result: Complex = undefined;

        // 使用 SSE2 指令进行并行加法
        asm volatile (
            // 加载第一个复数
            \\movsd xmm0, {self_re}
            \\movhpd xmm0, {self_im}
            // 加载第二个复数
            \\movsd xmm1, {other_re}
            \\movhpd xmm1, {other_im}
            // 相加
            \\addpd xmm0, xmm1
            // 存储结果
            \\movsd {result_re}, xmm0
            \\movhpd {result_im}, xmm0
            :
            : [self_re] "m" (self.re),
              [self_im] "m" (self.im),
              [other_re] "m" (other.re),
              [other_im] "m" (other.im)
            : [result_re] "m" (result.re),
              [result_im] "m" (result.im)
            , "xmm0", "xmm1"
        );

        return result;
    }
};

pub fn main() void {
    var c1 = Complex{ .re = 1.0, .im = 2.0 };
    var c2 = Complex{ .re = 3.0, .im = 4.0 };
    var c3 = c1.add(c2);
    std.debug.print("({} + {}i) + ({} + {}i) = ({} + {}i)\n", .{
        c1.re, c1.im, c2.re, c2.im, c3.re, c3.im
    });
}
