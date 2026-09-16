//! 14 comptime II 泛型：type 参数、@typeInfo 反射、编译期代码生成
const std = @import("std");

// ═══ 14.1 类型构造器：函数返回 type（矩阵 = 二维数组）
fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return [rows][cols]T;
}

// ═══ 14.2 泛型容器：Stack(T)——内部 ArrayList，分配器显式传
fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: std.ArrayList(T) = .empty,

        pub fn push(self: *Self, allocator: std.mem.Allocator, v: T) !void {
            try self.items.append(allocator, v);
        }
        pub fn pop(self: *Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.pop();
        }
        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.items.deinit(allocator);
        }
    };
}

// ═══ 14.3 anytype：编译期鸭子类型（std.debug.print 的实现原理）
fn sumAll(values: anytype) i64 {
    var total: i64 = 0;
    for (values) |v| total += @intCast(v);
    return total;
}

// ═══ 14.4 @typeInfo 反射：遍历结构体字段（serde/ORM 的地基）
const Person = struct {
    name: []const u8,
    age: u8,
    vip: bool,
};

fn dumpFields(comptime T: type) void {
    inline for (@typeInfo(T).@"struct".fields) |f| {
        std.debug.print("  {s}: {s}\n", .{ f.name, @typeName(f.type) });
    }
}

// ═══ 14.6 编译期代码生成：按类型生成分支
fn printAny(value: anytype) void {
    const info = @typeInfo(@TypeOf(value));
    switch (info) {
        .@"struct" => |s| inline for (s.fields) |f| {
            std.debug.print("  {s} = {any}\n", .{ f.name, @field(value, f.name) });
        },
        else => std.debug.print("  {any}\n", .{value}),
    }
}

pub fn main() !void {
    // 14.1 类型构造器
    const grid = Matrix(u8, 2, 3){ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
    std.debug.print("2x3 矩阵 [1][2]={d}\n", .{grid[1][2]});

    // 14.2 泛型容器
    var stack = Stack(u32){};
    defer stack.deinit(std.heap.page_allocator);
    try stack.push(std.heap.page_allocator, 10);
    try stack.push(std.heap.page_allocator, 20);
    std.debug.print("pop：{d} {d} {any}\n", .{ stack.pop().?, stack.pop().?, stack.pop() });

    // 14.3 anytype
    const ints = [_]i32{ 1, 2, 3 };
    const bytes = [_]u8{ 4, 5 };
    std.debug.print("sumAll：{d} {d}\n", .{ sumAll(&ints), sumAll(&bytes) });

    // 14.4 反射
    std.debug.print("Person 的字段：\n", .{});
    dumpFields(Person);

    // 14.5 @field：按编译期名字读写
    var p = Person{ .name = "阿 Z", .age = 25, .vip = true };
    const field_name = comptime "age";
    @field(p, field_name) = 26; // 等价 p.age = 26，但名字可以是编译期变量
    std.debug.print("{s} {d} 岁 vip={}\n", .{ p.name, @field(p, field_name), p.vip });

    // 14.6 代码生成
    std.debug.print("printAny(Person)：\n", .{});
    printAny(p);

    std.debug.print("自检通过\n", .{});
}

test "泛型与反射" {
    var s = Stack(u8){};
    defer s.deinit(std.testing.allocator);
    try s.push(std.testing.allocator, 'a');
    try s.push(std.testing.allocator, 'b');
    try std.testing.expectEqual(@as(u8, 'b'), s.pop().?);
    try std.testing.expectEqual(@as(u8, 'a'), s.pop().?);
    try std.testing.expectEqual(@as(?u8, null), s.pop());

    const i64s = [_]i64{ 10, 20 };
    try std.testing.expectEqual(@as(i64, 30), sumAll(&i64s));

    var p = Person{ .name = "x", .age = 1, .vip = false };
    @field(p, "vip") = true;
    try std.testing.expect(p.vip);
}
