const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;

    // 分配内存
    const alloc_slice = allocator.alloc(u8, 100) catch unreachable;
    defer allocator.free(alloc_slice);

    // 内存复制
    const src = "Hello";
    const dest = allocator.alloc(u8, src.len) catch unreachable;
    @memcpy(dest, src);
    allocator.free(dest);

    // 内存比较
    const a = [_]u8{ 1, 2, 3 };
    const b = [_]u8{ 1, 2, 3 };
    const c = [_]u8{ 1, 2, 4 };
    std.debug.print("a == b: {}\n", .{std.mem.eql(u8, &a, &b)});  // true
    std.debug.print("a == c: {}\n", .{std.mem.eql(u8, &a, &c)});  // false

    // 内存设置
    var arr = [_]u8{ 1, 2, 3, 4, 5 };
    @memset(&arr, 0);

    // 内存搜索
    const data = "Hello, World";
    const pos = std.mem.indexOfScalar(u8, data, 'W');
    std.debug.print("Position: {}\n", .{pos.?});

    // 切片操作
    const hello_slice = "Hello, World"[0..5];
    std.debug.print("Slice: {s}\n", .{hello_slice});  // Hello
}
