const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var map = std.AutoHashMap(i32, []const u8).init(allocator);
    defer map.deinit();

    map.put(1, "one") catch unreachable;

    if (map.get(1)) |value| {
        std.debug.print("map[1] = {s}\n", .{value});
    }
}
