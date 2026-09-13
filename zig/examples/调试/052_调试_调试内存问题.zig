const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var data = try allocator.alloc(u8, 100);
    defer allocator.free(data);

    @memset(data, 0);
    data[0] = 42;

    std.debug.print("Memory content: {}\n", .{data[0]});
    std.debug.print("Size: {}\n", .{data.len});
}
