const std = @import("std");

pub fn main() void {
    const x: i32 = 10;
    const y: i32 = 20;

    // basic print debugging
    std.debug.print("x = {}, y = {}\n", .{x, y});

    // 使用调试级别
    std.debug.print("Debug: x = {}\n", .{x});
    std.debug.print("Info: result = {}\n", .{x + y});

    // 打印结构体
    const Person = struct {
        name: []const u8,
        age: u32,
    };

    const p = Person{ .name = "Alice", .age = 25 };
    std.debug.print("Person: {s}, {} years old\n", .{ p.name, p.age });
}
