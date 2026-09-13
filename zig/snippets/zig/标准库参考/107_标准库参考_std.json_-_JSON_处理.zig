const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 解析 JSON
    const json_text = "{ \"name\": \"Alice\", \"age\": 25 }";
    const parsed = try std.json.parseFromSlice(allocator, []const u8, json_text, .{});
    defer parsed.deinit();

    // 访问值
    if (parsed.value.object.get("name")) |name| {
        std.debug.print("Name: {s}\n", .{name.string});
    }

    // 生成 JSON
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    try std.json.stringify(parsed.value, .{}, buffer.writer());
    std.debug.print("JSON: {s}\n", .{buffer.items});
}
