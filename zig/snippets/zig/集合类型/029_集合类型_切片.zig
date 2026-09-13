pub fn main() void {
    const arr = [_]i32{ 1, 2, 3, 4, 5 };

    // 创建切片
    var slice: []const i32 = arr[0..3];
    std.debug.print("slice: {}\n", .{slice});
}
