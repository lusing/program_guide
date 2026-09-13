const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 分配内存
    var data = try allocator.alloc(u8, 100);
    defer allocator.free(data);

    // 初始化内存
    @memset(data, 0);

    // 检查内存
    std.debug.print("Memory content: {}\n", .{data[0]});

    // 使用 @as 检查类型
    const size = @as(usize, @intCast(data.len));
    std.debug.print("Size: {}\n", .{size});
}
