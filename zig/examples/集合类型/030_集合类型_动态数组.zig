const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    list.append(allocator, 10) catch unreachable;
    list.append(allocator, 20) catch unreachable;

    std.debug.print("Length: {}\n", .{list.items.len});
}
