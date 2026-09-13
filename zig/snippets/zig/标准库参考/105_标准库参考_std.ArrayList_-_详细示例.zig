const std = @import("std");

pub fn main() void {
    var allocator = std.heap.page_allocator;

    // 初始化
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    // 添加元素
    list.append('a') catch unreachable;
    list.appendSlice("bcde") catch unreachable;

    // 插入
    list.insert(2, 'X') catch unreachable;

    // 访问
    std.debug.print("Length: {}\n", .{list.items.len});
    std.debug.print("First: {}\n", .{list.items[0]});

    // 修改
    list.items[0] = 'z';

    // 删除
    list.pop();  // 删除最后一个
    list.orderedRemove(0);  // 删除指定位置

    // 清空
    list.clearRetainingCapacity();
}
