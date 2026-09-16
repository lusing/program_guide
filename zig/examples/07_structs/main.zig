//! 07 结构体：字段、方法、命名空间、匿名结构与元组
const std = @import("std");

// ═══ 7.1 定义：字段 + 默认值
const Point = struct {
    x: f64,
    y: f64 = 0, // 默认值

    // ═══ 7.2 方法：第一个参数 self（惯用名，不是关键字）
    fn dist(self: Point) f64 { // 值 self：只读
        return @sqrt(self.x * self.x + self.y * self.y);
    }
    fn translate(self: *Point, dx: f64, dy: f64) void { // 指针 self：可改字段
        self.x += dx;
        self.y += dy;
    }
};

// ═══ 7.3 类型即命名空间：关联常量 / 变量 / 函数
const Config = struct {
    const version = "1.0"; // 关联常量
    fn describe() []const u8 { // 无 self = 静态函数
        return "Config v" ++ version;
    }
};

// ═══ 7.7 惯用法：init / deinit 命名约定
const Session = struct {
    id: u32,

    fn init(id: u32) Session {
        return .{ .id = id };
    }
    fn deinit(self: *Session) void {
        self.* = undefined; // 惯例上抹掉内容
    }
};

pub fn main() !void {
    var p = Point{ .x = 3, .y = 4 }; // 缺省字段可省略
    std.debug.print("dist={d:.1}\n", .{p.dist()});
    p.translate(1, 1);
    std.debug.print("translate 后 x={d:.1} y={d:.1}\n", .{ p.x, p.y });
    const origin = Point{ .x = 0 }; // y 用默认值
    std.debug.print("origin=({d:.1},{d:.1})\n", .{ origin.x, origin.y });

    std.debug.print("{s}\n", .{Config.describe()});

    // ═══ 7.4 匿名 struct：字面量形态（.{} 的真身）
    const anon = .{ .name = "Zig", .born = 2016 };
    std.debug.print("anon: name={s} born={d}\n", .{ anon.name, anon.born });

    // ═══ 7.5 元组：匿名字段的结构体（编译期已知长度）
    const tup = .{ "Zig", 2016, true };
    std.debug.print("tup[0]={s} tup[1]={d} tup.len={d}\n", .{ tup[0], tup[1], tup.len });

    // ═══ 7.6 每个文件本身是一个 struct（本文件的 main/std 都是"字段"）
    var sess = Session.init(7);
    defer sess.deinit();
    std.debug.print("session id={d}\n", .{sess.id});

    std.debug.print("自检通过\n", .{});
}

test "结构体语义" {
    const pt = Point{ .x = 3, .y = 4 };
    try std.testing.expectEqual(@as(f64, 5), pt.dist());
    const o = Point{ .x = 1 };
    try std.testing.expectEqual(@as(f64, 0), o.y);
    const tup = .{ 1, 2 };
    try std.testing.expectEqual(@as(usize, 2), tup.len);
    try std.testing.expectEqual(@as(i32, 2), tup[1]);
}
