const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;

    // 初始化
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    // 添加元素
    list.append(allocator, 'a') catch unreachable;
    list.appendSlice(allocator, "bcde") catch unreachable;

    // 插入
    list.insert(allocator, 2, 'X') catch unreachable;

    // 访问
    std.debug.print("Length: {}\n", .{list.items.len});
    std.debug.print("First: {}\n", .{list.items[0]});

    // 修改
    list.items[0] = 'z';

    // 删除
    _ = list.pop();  // 删除最后一个
    _ = list.orderedRemove(0);  // 删除指定位置

    // 清空
    list.clearRetainingCapacity();
}
