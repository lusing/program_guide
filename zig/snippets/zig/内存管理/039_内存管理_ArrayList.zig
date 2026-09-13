pub fn main() void {
    var allocator = std.heap.page_allocator;
    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    list.append(1) catch unreachable;
    list.append(2) catch unreachable;

    std.debug.print("Items: {}\n", .{list.items});
}
