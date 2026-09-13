const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    list.append(allocator, 1) catch unreachable;
    list.append(allocator, 2) catch unreachable;

    std.debug.print("count: {}\n", .{list.items.len});
    std.debug.print("first: {}\n", .{list.items[0]});
}
