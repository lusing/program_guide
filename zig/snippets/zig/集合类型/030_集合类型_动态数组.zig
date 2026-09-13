pub fn main() void {
    var list = std.ArrayList(i32).init(std.heap.page_allocator);
    defer list.deinit();

    list.append(10) catch unreachable;
    list.append(20) catch unreachable;

    std.debug.print("Length: {}\n", .{list.items.len});
}
