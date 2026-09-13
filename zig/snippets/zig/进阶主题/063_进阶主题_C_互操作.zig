const std = @import("std");

extern "libc" fn printf(format: [*:0]const u8, ...) c_int;

pub fn main() !void {
    const msg = "Hello from Zig!\n";
    printf("{}", msg);
}
