const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    // 添加元素
    list.append(allocator, 10) catch unreachable;
    list.append(allocator, 20) catch unreachable;
    list.append(allocator, 30) catch unreachable;

    // 访问元素
    std.debug.print("Length: {}\n", .{list.items.len});
    std.debug.print("First: {}\n", .{list.items[0]});

    // 遍历
    for (list.items) |value| {
        std.debug.print("{}\n", .{value});
    }

    // 插入和删除
    list.insert(allocator, 0, 5) catch unreachable;  // 在索引0插入
    _ = list.pop();  // 删除最后一个
}
