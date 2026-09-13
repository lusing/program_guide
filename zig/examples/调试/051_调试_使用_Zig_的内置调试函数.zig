const std = @import("std");

pub fn main() void {
    std.debug.print("Current function: {s}\n", .{@src().fn_name});
    std.debug.print("File: {s}, Line: {}\n", .{ @src().file, @src().line });
    std.debug.print("Debug helpers are available\n", .{});
}
