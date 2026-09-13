pub fn main() void {
    // 遍历数组
    const arr = [_]i32{1, 2, 3, 4, 5};
    for (arr) |value| {
        std.debug.print("{} ", .{value});
    }
    std.debug.print("\n", .{});

    // 遍历索引和值
    for (arr, 0..) |value, index| {
        std.debug.print("arr[{}] = {}\n", .{index, value});
    }
}
