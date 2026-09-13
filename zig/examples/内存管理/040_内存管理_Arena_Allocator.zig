const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // 多次分配，统一释放
    const slice1 = try allocator.alloc(u8, 100);
    const slice2 = try allocator.alloc(u8, 200);
    _ = slice1;
    _ = slice2;
}

