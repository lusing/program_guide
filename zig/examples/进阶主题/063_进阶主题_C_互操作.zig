const std = @import("std");

pub fn main() void {
    const msg = "Hello from Zig!\n";
    std.debug.print("{s}", .{msg});
}
