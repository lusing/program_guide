pub fn main() void {
    var map = std.AutoHashMap(i32, []const u8).init(std.heap.page_allocator);
    defer map.deinit();

    map.put(1, "one") catch unreachable;

    if (map.get(1)) |value| {
        std.debug.print("map[1] = {}\n", .{value});
    }
}
