const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 解析 JSON
    const json_text = "{ \"name\": \"Alice\", \"age\": 25 }";
    const parsed = try std.json.parseFromSliceLeaky(std.json.Value, allocator, json_text, .{});

    // 访问值
    if (parsed.object.get("name")) |name| {
        std.debug.print("Name: {s}\n", .{name.string});
    }
    if (parsed.object.get("age")) |age| {
        std.debug.print("Age: {}\n", .{age.integer});
    }
}
