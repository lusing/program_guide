const std = @import("std");

pub fn main() void {
    var a: i32 = 10;
    var b: i32 = 20;
    var result: i32 = 0;

    // 内联汇编 - 添加两个数
    asm volatile (
        \\add {result}, {a}, {b}
        :
        : [a] "r" (a),
          [b] "r" (b)
        : [result] "r" (result)
        , "cc"
    );

    std.debug.print("Result: {}\n", .{result});
}
