const std = @import("std");

pub fn main() void {
    var allocator = std.heap.page_allocator;
    var map = std.AutoHashMap(i32, []const u8).init(allocator);
    defer map.deinit();

    // 插入键值对
    map.put(1, "one") catch unreachable;
    map.put(2, "two") catch unreachable;
    map.put(3, "three") catch unreachable;

    // 查询
    if (map.get(2)) |value| {
        std.debug.print("map[2] = {}\n", .{value});
    }

    // 遍历
    var it = map.iterator();
    while (it.next()) |entry| {
        std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    // 删除
    map.remove(2);

    // 检查存在
    std.debug.print("Contains 1: {}\n", .{map.contains(1)});
}
