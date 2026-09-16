const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    const x: i32 = 42;

    // 跨平台断点：推荐使用 @breakpoint()
    // 等效于 x86_64 的 int3、ARM64 的 brk #1
    @breakpoint();

    std.debug.print("x = {}\n", .{x});
}
