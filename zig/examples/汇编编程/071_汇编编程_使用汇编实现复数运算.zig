const std = @import("std");

const Complex = struct {
    re: f64,
    im: f64,

    fn add(self: Complex, other: Complex) Complex {
        return .{
            .re = self.re + other.re,
            .im = self.im + other.im,
        };
    }
};

pub fn main() void {
    const c1 = Complex{ .re = 1.0, .im = 2.0 };
    const c2 = Complex{ .re = 3.0, .im = 4.0 };
    const c3 = c1.add(c2);
    std.debug.print("({} + {}i) + ({} + {}i) = ({} + {}i)\n", .{
        c1.re, c1.im, c2.re, c2.im, c3.re, c3.im,
    });
}
