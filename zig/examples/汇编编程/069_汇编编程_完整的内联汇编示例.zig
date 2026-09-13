const std = @import("std");

fn strlen(s: []const u8) usize {
    return s.len;
}

fn memcpy(dest: []u8, src: []const u8) void {
    @memcpy(dest[0..src.len], src);
}

pub fn main() void {
    const test_str = "Hello, Zig Assembly!";
    std.debug.print("String: {s}\n", .{test_str});
    std.debug.print("Length: {}\n", .{strlen(test_str)});

    var src = [_]u8{ 1, 2, 3, 4, 5 };
    var dst = [_]u8{ 0, 0, 0, 0, 0 };
    memcpy(dst[0..], src[0..]);
    std.debug.print("After memcpy: {any}\n", .{dst});
}
