const std = @import("std");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    _ = arena.allocator();
    const text = "apple,banana,orange";
    var it = std.mem.tokenizeAny(u8, text, ",");
    while (it.next()) |token| {
        std.debug.print("{s}\n", .{token});
    }
}
