const std = @import("std");

pub fn main() void {
    var allocator = std.heap.page_allocator;

    // 动态分配
    var slice = allocator.alloc(i32, 10) catch unreachable;
    defer allocator.free(slice);

    // 重新分配
    slice = allocator.realloc(slice, 20) catch unreachable;
    defer allocator.free(slice);
}
