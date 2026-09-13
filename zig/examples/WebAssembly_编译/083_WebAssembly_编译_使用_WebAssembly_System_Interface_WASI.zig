const std = @import("std");

pub fn main() !void {
    const argv = [_][]const u8{"program"};
    std.debug.print("Hello from WASI!\n", .{});
    std.debug.print("argv[0] = {s}\n", .{argv[0]});
}
