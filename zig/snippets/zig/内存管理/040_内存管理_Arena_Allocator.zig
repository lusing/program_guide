pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // 多次分配，统一释放
    var slice1 = try allocator.alloc(u8, 100);
    var slice2 = try allocator.alloc(u8, 200);
}
