const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 字符串拼接
    const s1 = "Hello";
    const s2 = "World";
    const combined = try std.fmt.allocPrint(allocator, "{s}, {s}!", .{ s1, s2 });
    defer allocator.free(combined);

    // 字符串长度
    std.debug.print("Length: {}\n", .{"Hello".len});

    // 字符串比较
    std.debug.print("Equal: {}\n", .{std.mem.eql(u8, "abc", "abc")});

    // 字符串分割
    const text = "apple,banana,orange";
    var it = std.mem.tokenizeSequence(u8, text, ",");
    while (it.next()) |token| {
        std.debug.print("{s}\n", .{token});
    }

    // 字符串替换
    var buf: [100]u8 = undefined;
    const replaced = std.mem.replace(u8, "hello world", "world", "Zig", &buf);
    std.debug.print("Replaced: {s}\n", .{buf[0..replaced]});

    // 转换大小写
    var upper_buf: [10]u8 = undefined;
    const upper = std.ascii.upperString(&upper_buf, "hello");
    std.debug.print("Upper: {s}\n", .{upper});
}
