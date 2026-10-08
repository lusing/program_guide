//! 36 指针与内存深水区：volatile / 指针↔整数 / ptrCast+alignCast / bitCast 判据 /
//! 零尺寸类型 / anyopaque / coercion 与 peer 类型解析 / [*c]T / 位对齐指针
//! 取材：Learning Zig ch9（Memory Management）+ ch12（Sophisticated Topics 的指针半区），
//! 全部按 Zig 0.17.0 实测重写（原书是 0.15 时代写法）。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 36.1 指针四形态与"显式可变性"
// ══════════════════════════════════════════════════════════════════

/// *const T 是类型级的"我只看"承诺；想写，函数签名里必须是 *T。
fn total(items: []const i32) i32 {
    var s: i32 = 0;
    for (items) |x| s += x;
    return s;
}

fn bump(p: *i32) void {
    p.* += 1;
}

// ══════════════════════════════════════════════════════════════════
// 36.2 volatile：给"内存之外的世界"看的读写
// ══════════════════════════════════════════════════════════════════

/// 模拟一个"硬件寄存器"：两块内存，一块是设备状态字，一块是主机命令字。
/// 设备线程不存在——用普通指针从"设备侧"改状态，来演示 volatile 的意义：
/// 编译器不许把对 status 的读取缓存进寄存器，每次都真去内存拿。
const Device = struct {
    status: u32,
    command: u32,
};

/// 等待设备就绪。status 参数是 volatile 指针：
/// 没有 volatile，ReleaseFast 下编译器会把 `status.* == 0` 提出循环
/// （它证明不了循环体内有谁能改这块内存），死等变成死循环。
fn waitReady(status: *volatile u32, max_spin: usize) bool {
    var i: usize = 0;
    while (i < max_spin) : (i += 1) {
        if (status.* != 0) return true; // 每一圈都是一次真内存读
    }
    return false;
}

// ══════════════════════════════════════════════════════════════════
// 36.4 @ptrCast + @alignCast：按别的类型重解释**内存**
// ══════════════════════════════════════════════════════════════════

/// 小端字节序缓冲区上按 u32 读前 4 字节。
/// buf 声明成 align(4)，所以 @alignCast 不是撒谎——是"我知道对齐够"。
fn readU32LE(buf: *align(4) const [8]u8) u32 {
    const p: *align(4) const u8 = &buf[0];
    const w: *const u32 = @ptrCast(@alignCast(p));
    return w.*;
}

// ══════════════════════════════════════════════════════════════════
// 36.5 @bitCast：按别的类型重解释**值**（不动内存）
// ══════════════════════════════════════════════════════════════════

/// f32 的位模式当 u32 看。同宽、复制语义、编译期就能算——这三个特征
/// 就是"该用 @bitCast 而不是 @ptrCast"的判据。
fn f32Bits(x: f32) u32 {
    return @bitCast(x);
}

// ══════════════════════════════════════════════════════════════════
// 36.8 anyopaque：类型擦除的"通用指针"
// ══════════════════════════════════════════════════════════════════

/// 一个最小"异质登记处"：存任意对象的指针 + 它的类型名。
/// 找回原类型时必须由调用方保证——anyopaque 自己什么都不记得。
const Entry = struct {
    ptr: *anyopaque,
    type_name: []const u8,
};

// ══════════════════════════════════════════════════════════════════
// 36.9 peer 类型解析：七种能成的格局 + 一种必败
// ══════════════════════════════════════════════════════════════════

var runtime_flag: struct { v: bool } = .{ .v = true };

test "36.9 peer 七种格局" {
    // ① 同型：平凡
    const a = if (runtime_flag.v) @as(u8, 1) else @as(u8, 2);
    try std.testing.expectEqual(@as(u8, 1), a);
    // ② comptime_int 折向另一支的具体类型
    const b = if (runtime_flag.v) @as(u8, 10) else 20;
    try std.testing.expectEqual(@as(u8, 10), b);
    // ③ 窄→宽：i16 与 u8 的共同类型是 i16
    const c = if (runtime_flag.v) @as(i16, -3) else @as(u8, 7);
    try std.testing.expectEqual(@as(i16, -3), c);
    try std.testing.expectEqual(i16, @TypeOf(c));
    // ④ int→float：u8 与 f32 的共同类型是 f32
    const d = if (runtime_flag.v) @as(u8, 1) else @as(f32, 1.5);
    try std.testing.expectEqual(f32, @TypeOf(d));
    // ⑤ T→?T：值与 null 的共同类型是可选
    const e = if (runtime_flag.v) @as(u8, 5) else null;
    try std.testing.expectEqual(?u8, @TypeOf(e));
    // ⑥ T→E!T：值与错误的共同类型是错误联合
    const f = if (runtime_flag.v) @as(u8, 9) else error.Boom;
    try std.testing.expectEqual(@as(u8, 9), try f);
    // ⑦ 可变性宽化：[]u8 折向 []const u8
    var buf = [_]u8{ 1, 2 };
    const g: []const u8 = if (runtime_flag.v) buf[0..] else "xy";
    try std.testing.expectEqual(@as(usize, 2), g.len);
}

// ══════════════════════════════════════════════════════════════════
// 36.10 [*c]T：C 指针的四宗罪（能编译 ≠ 该这么写）
// ══════════════════════════════════════════════════════════════════

test "36.10 [*c] 的放纵与进门转换纪律" {
    var buf = [_]c_int{ 1, 2, 3 };
    const p: [*c]c_int = &buf;
    // 罪一：可下标，越界没人拦
    try std.testing.expectEqual(@as(c_int, 2), p[1]);
    // 罪二：可算术
    try std.testing.expectEqual(@as(c_int, 3), (p + 2).*);
    // 罪三：可空——null 检查全靠自觉
    const nul: [*c]c_int = null;
    try std.testing.expect(nul == null);
    // 纪律：[*c] 一进 Zig 边界就转成带长度的切片，之后按 Zig 规矩玩
    const s: []c_int = p[0..3];
    try std.testing.expectEqual(@as(usize, 3), s.len);
}

// ══════════════════════════════════════════════════════════════════
// 36.11 位对齐指针：packed 结构体字段的地址
// ══════════════════════════════════════════════════════════════════

const Flags = packed struct {
    a: u3,
    b: u5,
};

test "36.11 *align(1:0:1) 位对齐指针" {
    var f: Flags = .{ .a = 5, .b = 17 };
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(Flags));
    const pa = &f.a;
    // 类型里带三重信息：字节对齐 1、位偏移 0、宿主位宽 1 字节
    try std.testing.expectEqual(*align(1:0:1) u3, @TypeOf(pa));
    try std.testing.expectEqual(@as(u3, 5), pa.*);
    pa.* = 6; // 通过位对齐指针写回：编译器生成"读-改-写"位操作
    try std.testing.expectEqual(@as(u3, 6), f.a);
    try std.testing.expectEqual(@as(u5, 17), f.b); // 邻居字段没被撞
}

// ══════════════════════════════════════════════════════════════════
// 36.7 零尺寸类型
// ══════════════════════════════════════════════════════════════════

test "36.7 零尺寸类型与 HashMap(K, void) 集合" {
    try std.testing.expectEqual(@as(usize, 0), @sizeOf(void));
    try std.testing.expectEqual(@as(usize, 0), @sizeOf(struct {}));
    try std.testing.expectEqual(@as(usize, 0), @sizeOf([0]u8));
    try std.testing.expectEqual(@as(usize, 0), @sizeOf(u0));

    // HashMap 的值位填 void，就是零成本的 Set
    var set = std.StringHashMap(void).init(std.testing.allocator);
    defer set.deinit();
    try set.put("apple", {});
    try set.put("banana", {});
    try std.testing.expect(set.contains("apple"));
    try std.testing.expect(!set.contains("cherry"));
    try std.testing.expectEqual(@as(u32, 2), set.count());
}

test "36.1 显式可变性" {
    var n: i32 = 41;
    bump(&n);
    try std.testing.expectEqual(@as(i32, 42), n);
    try std.testing.expectEqual(@as(i32, 42), total(&.{ 40, 2 }));
}

test "36.2 volatile 每次都真读" {
    var dev: Device = .{ .status = 0, .command = 0 };
    // 前 3 次读都是 0；然后"设备侧"（普通指针）把状态写成 1
    var reads: usize = 0;
    const status: *volatile u32 = &dev.status;
    while (reads < 3) : (reads += 1) {
        try std.testing.expectEqual(@as(u32, 0), status.*);
    }
    dev.status = 1; // 模拟硬件异步改值
    try std.testing.expect(waitReady(status, 100));
}

test "36.3 指针↔整数互转" {
    var x: u64 = 42;
    const addr = @intFromPtr(&x);
    const back: *u64 = @ptrFromInt(addr);
    try std.testing.expectEqual(@as(u64, 42), back.*);
}

test "36.4 ptrCast+alignCast 正例" {
    const buf: [8]u8 align(4) = .{ 0x78, 0x56, 0x34, 0x12, 0, 0, 0, 0 };
    try std.testing.expectEqual(@as(u32, 0x12345678), readU32LE(&buf));
}

test "36.5 bitCast 重解释值" {
    try std.testing.expectEqual(@as(u32, 0x3F800000), f32Bits(1.0));
    // 编译期也能算——这是"值重解释"的身份证
    const bits = comptime f32Bits(2.0);
    try std.testing.expectEqual(@as(u32, 0x40000000), bits);
}

test "36.6 多项指针：0.17 必须下标语法" {
    var arr = [_]i32{ 10, 20, 30, 40 };
    const p: [*]i32 = &arr;
    try std.testing.expectEqual(@as(i32, 30), p[2]); // p[2],不能写 (p+2).*
    const s: []i32 = p[1..3];
    try std.testing.expectEqual(@as(usize, 2), s.len);
}

test "36.8 anyopaque 擦除与找回" {
    var answer: i32 = 42;
    var ratio: f64 = 2.5;
    const entries = [_]Entry{
        .{ .ptr = &answer, .type_name = @typeName(@TypeOf(answer)) },
        .{ .ptr = &ratio, .type_name = @typeName(@TypeOf(ratio)) },
    };
    try std.testing.expectEqualStrings("i32", entries[0].type_name);
    // 找回：调用方对类型负责
    const back: *i32 = @ptrCast(@alignCast(entries[0].ptr));
    try std.testing.expectEqual(@as(i32, 42), back.*);
}

// ══════════════════════════════════════════════════════════════════
// main：把能"看见"的几件事打印出来
// ══════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();

    begin("36.2 volatile");
    var dev: Device = .{ .status = 0, .command = 0 };
    const status: *volatile u32 = &dev.status;
    std.debug.print("上电 status={d}\n", .{status.*});
    dev.status = 1;
    std.debug.print("设备就绪={}（等待在第 100 圈内返回）\n", .{waitReady(status, 100)});
    end("36.2 volatile");

    begin("36.3 地址与整数");
    var x: u64 = 42;
    std.debug.print("&x = 0x{x}，@ptrFromInt 回来仍是 {d}\n", .{
        @intFromPtr(&x), @as(*u64, @ptrFromInt(@intFromPtr(&x))).*,
    });
    end("36.3 地址与整数");

    begin("36.4/36.5 两种重解释");
    const buf: [8]u8 align(4) = .{ 0x78, 0x56, 0x34, 0x12, 0, 0, 0, 0 };
    std.debug.print("内存重解释：前 4 字节当 u32 = 0x{x:0>8}\n", .{readU32LE(&buf)});
    std.debug.print("值重解释：f32(1.0) 的位 = 0x{x:0>8}\n", .{f32Bits(1.0)});
    end("36.4/36.5 两种重解释");

    begin("36.7 零尺寸类型");
    var z1: struct {} = .{};
    var z2: struct {} = .{};
    std.debug.print("@sizeOf(void)={d}；两个零尺寸变量地址：0x{x} / 0x{x}\n", .{
        @sizeOf(void), @intFromPtr(&z1), @intFromPtr(&z2),
    });
    var set = std.StringHashMap(void).init(a);
    try set.put("zig", {});
    try set.put("c", {});
    std.debug.print("HashMap(K,void) 当 Set：{d} 个元素，含 zig={}\n", .{
        set.count(), set.contains("zig"),
    });
    end("36.7 零尺寸类型");

    begin("36.9 peer 类型解析");
    const mixed = if (x != 0) @as(u8, 1) else @as(f32, 1.5);
    std.debug.print("u8 与 f32 的 peer 结果类型：{s}\n", .{@typeName(@TypeOf(mixed))});
    end("36.9 peer 类型解析");

    begin("36.11 位对齐指针");
    var f: Flags = .{ .a = 5, .b = 17 };
    std.debug.print("&f.a 的类型：{s}，值={d}\n", .{ @typeName(@TypeOf(&f.a)), f.a });
    f.b = 31;
    std.debug.print("改 b 后整字节=0x{x:0>2}\n", .{@as(u8, @bitCast(f))});
    end("36.11 位对齐指针");

    std.debug.print("自检通过\n", .{});
}
