//! 03 类型与转型：const/var、任意位宽整数、comptime_int、溢出运算符、宽化规则、转型家族、@bitCast、类型自省、枚举基整型、编译期算术
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 演示用的小结构体：字段名与字段类型在 3.8 节被反射出来
const Header = extern struct {
    magic: u32,
    len: u16,
};

/// 3.9 节的枚举：显式指定基整型/ 不写基整型，由编译器挑最小的
const Color = enum(u8) { red = 1, green = 2, blue = 4 };
const Level = enum { low, high };

/// 3.8 节的错误集：@typeInfo 能列出全部名字
const StoreError = error{ NotFound, Corrupted };

/// 3.8 节用：按类型分派的函数，证明 comptime 反射可以写正常代码
fn kindName(comptime T: type) []const u8 {
    return switch (@typeInfo(T)) {
        .int => "整数",
        .float => "浮点",
        .comptime_int => "comptime_int",
        .@"struct" => "结构体",
        .@"enum" => "枚举",
        .pointer => "指针",
        .array => "数组",
        .optional => "可选",
        .error_union => "错误联合",
        .error_set => "错误集",
        .bool => "布尔",
        .void => "空",
        else => "其它",
    };
}

/// 3.10 节用：纯编译期函数，调用点没有一行运行期代码
fn factorial(comptime n: u32) u64 {
    comptime var acc: u64 = 1;
    comptime var k: u32 = 2;
    inline while (k <= n) : (k += 1) acc *= k;
    return acc;
}

pub fn main() !void {
    // ═══ 3.1 const 是默认，var 要申请；undefined 的 0x00 陷阱 ═══
    begin("3.1");
    const answer: u32 = 42; // const：初始化后不可改
    var count: i32 = 10; // var：可改；写了 var 却从不改会编译报错
    count += 5;
    std.debug.print("answer={d} count={d}\n", .{ answer, count });

    // `var x: i32;`（不写初值）本身就是语法错误，必须给初值或显式 undefined。
    // 显式 undefined 是"我明确知道这内存是脏的"的声明；Debug 下未初始化内存被填成 0x00。
    const u8_undef: u8 = undefined;
    const u32_undef: u32 = undefined;
    const bool_undef: bool = undefined;
    std.debug.print("undefined: u8=0x{x:0>2} u32=0x{x:0>8} bool={}\n", .{ u8_undef, u32_undef, bool_undef });
    end("3.1");

    // ═══ 3.2 任意位宽整数：u3、i19、u128、usize ═══
    begin("3.2");
    const small: u3 = 5; // 3 位无符号，值域 0..7
    const neg: i19 = -100000; // 19 位有符号
    const wide: u128 = @as(u128, 1) << 100; // 128 位内建，移位不会丢位
    const ptr_sized: usize = 1000; // 指针宽度，下标/长度都用它
    std.debug.print("u3={d} i19={d} usize={d}\n", .{ small, neg, ptr_sized });
    std.debug.print("1<<100 = {d}（0x{x}）\n", .{ wide, wide });
    // @sizeOf 是"占多少字节"，@bitSizeOf 才是"有多少位"——u3 只占 1 字节但只有 3 位
    std.debug.print("sizeOf: u3={d} u128={d} usize={d} bool={d}\n", .{ @sizeOf(u3), @sizeOf(u128), @sizeOf(usize), @sizeOf(bool) });
    std.debug.print("bitSizeOf: u3={d} i19={d} u128={d} usize={d}\n", .{ @bitSizeOf(u3), @bitSizeOf(i19), @bitSizeOf(u128), @bitSizeOf(usize) });
    end("3.2");

    // ═══ 3.3 comptime_int：数字字面量没有类型 ═══
    begin("3.3");
    const dec = 123_456_789; // 十进制，下划线是给人看的
    const hex = 0xFF; // 十六进制
    const oct = 0o77; // 八进制，前缀是 0o不是 0
    const bin = 0b1010; // 二进制
    const ch = 'A'; // comptime_int（字符字面量也是整数）
    std.debug.print("dec={d} hex={d} oct={d} bin={d} ch={d}\n", .{ dec, hex, oct, bin, ch });
    std.debug.print("字面量类型：dec={s} hex={s} bin={s}\n", .{
        @typeName(@TypeOf(dec)),
        @typeName(@TypeOf(hex)),
        @typeName(@TypeOf(bin)),
    });
    const f = 3.5; // 浮点字面量是 comptime_float
    std.debug.print("浮点字面量类型={s}；5/2 类型={s} 值={d}\n", .{ @typeName(@TypeOf(f)), @typeName(@TypeOf(5 / 2)), 5 / 2 });
    end("3.3");

    // ═══ 3.4 溢出：安全运算符 vs 环绕运算符 vs 带溢出返回值 ═══
    begin("3.4");
    var byte: u8 = 255;
    byte +%= 1; // 环绕加：255 → 0，四种模式都不出错
    var debt: i8 = -128;
    debt -%= 1; // 环绕减：-128 → 127（无符号的 128 解释成 i8）
    std.debug.print("255 +%= 1 → {d}；-128 -%= 1 → {d}\n", .{ byte, debt });
    // 安全版 `+` 在 Debug/safe 模式越界就 panic（实测：thread ... panic: integer overflow）。
    // 想要"不 panic 也不丢信息"就用 @addWithOverflow：它把溢出当成返回值。
    // ⚠️ 0.17 的溢出标志是 **u1**（0 或 1），不是 bool——
    // `try std.testing.expect(ov[1])` 会报 expected type 'bool', found 'u1'，得写 `ov[1] == 1`。
    const add_ov = @addWithOverflow(@as(u8, 250), @as(u8, 10));
    const sub_ov = @subWithOverflow(@as(u8, 5), @as(u8, 10));
    const mul_ov = @mulWithOverflow(@as(u8, 16), @as(u8, 16));
    std.debug.print("250+10={d}溢出={}  5-10={d}溢出={}  16*16={d}溢出={}\n", .{
        add_ov[0], add_ov[1] == 1,
        sub_ov[0], sub_ov[1] == 1,
        mul_ov[0], mul_ov[1] == 1,
    });
    // u32 累加 10 万次会 panic（u32 只装得下约 42 亿，累加没问题——
    // 这里换成 u8 就会在第 256 次炸掉，见 3.5 节算术不宽化的解释）
    var acc: u32 = 0;
    var step: u32 = 0;
    while (step < 100_000) : (step += 1) acc += 1;
    std.debug.print("u32累加 100000 次 = {d}\n", .{acc});
    end("3.4");

    // ═══ 3.5 唯一允许的隐式转换：宽化（以及它的陷阱）═══
    begin("3.5");
    const a8: u8 = 200;
    var a16: u16 = 0;
    a16 = a8; // 隐式宽化：目标类型能表示源的所有值，编译器放行
    std.debug.print("u8 → u16 隐式宽化 = {d}\n", .{a16});
    const f32v: f32 = 1.5;
    const f64v: f64 = f32v; // 浮点同理：f32 → f64 放行
    std.debug.print("f32 → f64 隐式宽化 = {d}\n", .{f64v});
    // 反方向一律拒绝：u16 → u8、f64 → f32、bool → u8 都编译失败
    //   const q: u8 = a16;   error: expected type 'u8', found 'u16'
    //   const s: f32 = f64v; error: expected type 'f32', found 'f64'
    //   const i: u8 = flag;   error: expected type 'u8', found 'bool'
    //
    // ⚠️ 陷阱：**算术结果永远不宽化**。u8 + u8 的结果类型还是 u8，不是 u16。
    const e8: u8 = 100;
    const diff = e8 -% a8; // 100 - 200：必须用环绕减，否则 Debug panic
    std.debug.print("u8 -% u8 → 类型 {s} 值 {d}\n", .{ @typeName(@TypeOf(diff)), diff });
    const g16: u16 = 30000;
    const sum16 = g16 + g16; // 60000 装得进 u16；换成 g16=60000 就 panic
    std.debug.print("u16 + u16 → 类型 {s} 值 {d}\n", .{ @typeName(@TypeOf(sum16)), sum16 });
    // u8 + comptime_int 也**不会**宽化：a8 + 1000 直接编译错（u8 装不下 1000）
    const widened = a8 + @as(u16, 1000); // 想要宽化就自己点名
    std.debug.print("u8 + u16(1000) → 类型 {s} 值 {d}\n", .{ @typeName(@TypeOf(widened)), widened });
    // 浮点除法两边类型不同也要点名：7.0 / 2 编译错（comptime_float vs comptime_int 二义）
    const q = @as(f32, 7.0) / 2;
    std.debug.print("@as(f32, 7.0) / 2 → 类型 {s} 值 {d}\n", .{ @typeName(@TypeOf(q)), q });
    end("3.5");

    // ═══ 3.6 转型家族：@as / @intCast / @truncate / @intFromFloat / @floatFromInt / @floatCast ═══
    begin("3.6");
    const wide_val: i32 = 300;
    // @truncate：只保留低位，无视值域是否装得下
    const t = @as(u8, @truncate(@as(u32, @bitCast(wide_val))));
    std.debug.print("i32 300 的低 8 位 = {d}\n", .{t});
    // @truncate 的**操作数必须是无符号整数**，有符号要先 @bitCast 过去
    //   @truncate(@as(i32, 300)) → error: expected unsigned integer type, found 'i32'
    //
    // @intCast：值域检查版。值在编译期已知且越界，连编译都过不了
    //   const bad: u8 = @intCast(@as(i32, 300));
    //   → error: type 'u8' cannot represent integer value '300'
    const fits: i32 = 200;
    const c = @as(u8, @intCast(fits)); // 200 在 u8 值域内，OK
    std.debug.print("@intCast(i32 200 → u8) = {d}\n", .{c});
    //
    // @intFromFloat：浮点 → 整数，**直接截断小数**（不是四舍五入）
    const i_from_f: i32 = @intFromFloat(3.7);
    // @floatFromInt：整数 → 浮点
    const f_from_i: f64 = @floatFromInt(200);
    // @floatCast：浮点之间改精度
    const narrowed: f32 = @floatCast(@as(f64, 1.0 / 3.0));
    std.debug.print("@intFromFloat(3.7)={d} @floatFromInt(200)={d:.1} @floatCast(1/3)={d}\n", .{ i_from_f, f_from_i, narrowed });
    // @intFromBool / @intFromPtr / @ptrFromInt
    const flag: bool = true;
    const b1: u1 = @intFromBool(flag);
    const n: u32 = 42;
    const ptr_val = @intFromPtr(&n);
    const back: *const u32 = @ptrFromInt(ptr_val);
    std.debug.print("@intFromBool(true)={d} @ptrFromInt+@ptrFromInt 往返={d}\n", .{ b1, back.* });
    // 位操作家族（0.17 没有 ** 幂运算符了，移位和 @popCount 顶上）
    std.debug.print("0b1010 & 0b0110 = {d}；@popCount(0xF0F0)={d}；@ctz(0x10)={d}；@clz(0x10)={d}\n", .{ @as(u8, 0b1010) & @as(u8, 0b0110), @popCount(@as(u16, 0xF0F0)), @ctz(@as(u32, 0x10)), @clz(@as(u32, 0x10)) });
    end("3.6");

    // ═══ 3.7 @bitCast：同宽重解释，以及为什么结构体要走字节 ═══
    begin("3.7");
    const u: u32 = 0x41424344;
    const raw: [4]u8 = @bitCast(u); // u32 ↔ [4]u8：两边 @sizeOf 相等即可
    std.debug.print("0x{x:0>8} 的字节序（小端）= {any}\n", .{ u, raw });
    // 0.17 的坑：@bitCast **不接受裸结构体**（extern struct 也不行）
    //   const x: u64 = @bitCast(header);
    //   → error: cannot @bitCast from 'main.Header'
    //   哪怕 @sizeOf 相等也不行（6 个字节 ≠ 8，而且 padding 也不参与）
    // 正确姿势：asBytes + readInt/writeInt，按字节走
    const header = Header{ .magic = 0x41424344, .len = 0x0102 };
    const hbytes = std.mem.asBytes(&header);
    std.debug.print("Header sizeOf={d} 字节={any}\n", .{ @sizeOf(Header), hbytes[0..@sizeOf(Header)] });
    const magic_le = std.mem.readInt(u32, hbytes[0..4], .little);
    const magic_be = std.mem.readInt(u32, hbytes[0..4], .big);
    std.debug.print("readInt 小端=0x{x:0>8} 大端=0x{x:0>8}\n", .{ magic_le, magic_be });
    var out: [4]u8 = undefined;
    std.mem.writeInt(u32, &out, 0xAABBCCDD, .little);
    std.debug.print("writeInt 小端 0xAABBCCDD → {any}\n", .{out});
    end("3.7");

    // ═══ 3.8 类型自省：@TypeOf / @typeName / @typeInfo / @sizeOf / @alignOf / @offsetOf ═══
    begin("3.8");
    const v32: u32 = 7;
    std.debug.print("@TypeOf(v32)={s}；表达式 v32 * 2 的类型={s}\n", .{ @typeName(@TypeOf(v32)), @typeName(@TypeOf(v32 * 2)) });
    std.debug.print("kindName(u8)={s} kindName(f64)={s} kindName([]u8)={s} kindName(?u8)={s}\n", .{ kindName(u8), kindName(f64), kindName([]u8), kindName(?u8) });
    std.debug.print("kindName(Header)={s} kindName(Color)={s} kindName(StoreError)={s} kindName(anyerror!u8)={s}\n", .{ kindName(Header), kindName(Color), kindName(StoreError), kindName(anyerror!u8) });
    std.debug.print("kindName(3)={s}（字面量在运行期会变成 u8）kindName(void)={s}\n", .{ kindName(@TypeOf(3)), kindName(void) });
    // 反射结构体字段：0.17 是 field_names / field_types / layout（.tag 已改名）
    const hi = @typeInfo(Header);
    std.debug.print("Header layout={t}字段数={d}\n", .{ hi.@"struct".layout, hi.@"struct".field_names.len });
    inline for (hi.@"struct".field_names, hi.@"struct".field_types) |fname, ftype| {
        // field_names 的元素是 [:0]const u8（带哨兵）；写成 fname[0..fname.len]
        // 得到的是 *const [N:0]u8，{s} 能直接吃。踩坑：写 fname[0..4 :0] 会报
        //   error: value in memory does not match slice sentinel
        // 因为哨兵在末尾第5 字节，不是第 4 字节。
        // field_types 的元素是 `type`——编译期实体，运行期不存在，
        // 必须 inline for逐个展开才能 @typeName（普通 for 会报 types are not available at runtime）。
        std.debug.print("  字段 {s} 类型={s}\n", .{ fname[0..fname.len], @typeName(ftype) });
    }
    std.debug.print("@alignOf(u32)={d} @offsetOf(Header, len)={d}\n", .{ @alignOf(u32), @offsetOf(Header, "len") });
    // 反射枚举字段与值
    const ce = @typeInfo(Color);
    std.debug.print("Color 基整型={s} 字段数={d}\n", .{ @typeName(ce.@"enum".tag_type), ce.@"enum".field_names.len });
    // field_values 的元素类型是 **comptime_int**（不是 u8）——普通 for 会报
    // values of type 'comptime_int' must be comptime-known，但 index value is runtime-known。
    // 枚举成员值本质是编译期常量，只能 inline for 展开。
    inline for (ce.@"enum".field_names, ce.@"enum".field_values) |fname, fval| {
        std.debug.print("  {s} = {d}\n", .{ fname[0..fname.len], fval });
    }
    // 反射错误集：0.17 的 error_names 是**可空**的 ?[]const [:0]const u8
    const se = @typeInfo(StoreError);
    if (se.error_set.error_names) |enames| {
        std.debug.print("StoreError 错误数={d}\n", .{enames.len});
        for (enames) |ename| std.debug.print("  {s}\n", .{ename[0..ename.len]});
    }
    end("3.8");

    // ═══ 3.9 枚举 ↔ 整数：@backingInt / @fromBackingInt / @enumFromInt ═══
    begin("3.9");
    const g: Color = .green;
    std.debug.print("@backingInt(Color.green)={d} @sizeOf(Color)={d}\n", .{ @backingInt(g), @sizeOf(Color) });
    const blue: Color = @fromBackingInt(@as(u8, 4)); // 安全版：值域检查
    const c2: Color = @fromBackingInt(@intCast(1)); // 0.17 的名字，值域仍然检查
    std.debug.print("@fromBackingInt(4)={t} @enumFromInt(1)={t}\n", .{ blue, c2 });
    const lv: Level = .high;
    std.debug.print("Level 基整型={s} @sizeOf={d} @backingInt(.high)={d}\n", .{ @typeName(@typeInfo(Level).@"enum".tag_type), @sizeOf(Level), @backingInt(lv) });
    // 枚举 ↔ 整数 走字节视角
    const cbytes = std.mem.asBytes(&g);
    std.debug.print("Color.green 的字节={any}（首字节就是基整数值）\n", .{cbytes});
    // ⚠️ 0.17 改名：@intFromEnum → @backingInt，@intToEnum → @enumFromInt。
    // 照抄旧代码报no field named / invalid builtin function。
    end("3.9");

    // ═══ 3.10 编译期算术：comptime 变量与纯编译期函数 ═══
    begin("3.10");
    comptime var sum: u32 = 0;
    inline for (0..8) |i| sum += i; // inline for：循环体在编译期展开
    std.debug.print("inline for 0..8 累加 = {d}（类型 {s}）\n", .{ sum, @typeName(@TypeOf(sum)) });
    std.debug.print("factorial(10) = {d}（编译期算好的常量）\n", .{factorial(10)});
    // 编译期块（labeled block）：普通块也可以整体在编译期求值
    const area = comptime blk: {
        var partial: usize = 0;
        for (0..8) |k| partial += @sizeOf(u8) * k;
        break :blk partial;
    };
    std.debug.print("编译期求和 = {d}（0+1+…+7 字节）\n", .{area});
    end("3.10");

    std.debug.print("自检通过\n", .{});
}

test "任意位宽整数与环绕运算符" {
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(u3));
    try std.testing.expectEqual(@as(u16, 3), @bitSizeOf(u3));
    const small: u3 = 5;
    try std.testing.expect(small < 8);
    const neg: i19 = -100000;
    try std.testing.expect(neg < 0);
    var b: u8 = 255;
    b +%= 1;
    try std.testing.expectEqual(@as(u8, 0), b);
    var d: i8 = -128;
    d -%= 1;
    try std.testing.expectEqual(@as(i8, 127), d);
}

test "带溢出返回值的三个内建（标志位是 u1 不是 bool）" {
    // 0.17：标志位是 u1，要写 a[1] == 1 才能喂给 expect(bool)
    const a = @addWithOverflow(@as(u8, 250), @as(u8, 10));
    try std.testing.expectEqual(@as(u8, 4), a[0]);
    try std.testing.expect(a[1] == 1);
    const s = @subWithOverflow(@as(u8, 5), @as(u8, 10));
    try std.testing.expectEqual(@as(u8, 251), s[0]);
    try std.testing.expect(s[1] == 1);
    const m = @mulWithOverflow(@as(u8, 16), @as(u8, 16));
    try std.testing.expectEqual(@as(u8, 0), m[0]);
    try std.testing.expect(m[1] == 1);
    const ok = @addWithOverflow(@as(u8, 1), @as(u8, 2)); // 不溢出时标志是 0
    try std.testing.expectEqual(@as(u8, 3), ok[0]);
    try std.testing.expect(ok[1] == 0);
}

test "@truncate 只看低位，@intCast 看值域，浮点互转截断小数" {
    try std.testing.expectEqual(@as(u8, 44), @as(u8, @truncate(@as(u32, 300))));
    try std.testing.expectEqual(@as(u8, 0x34), @as(u8, @truncate(@as(u32, 0x1234))));
    try std.testing.expectEqual(@as(u8, 200), @as(u8, @intCast(@as(i32, 200))));
    try std.testing.expectEqual(@as(i32, 3), @as(i32, @intFromFloat(@as(f64, 3.7))));
    try std.testing.expectEqual(@as(i32, -3), @as(i32, @intFromFloat(@as(f64, -3.7))));
    try std.testing.expectEqual(@as(f64, 200), @as(f64, @floatFromInt(@as(i32, 200))));
    const narrowed: f32 = @floatCast(@as(f64, 1.0 / 3.0));
    try std.testing.expect(narrowed > 0.333 and narrowed < 0.334);
}

test "@bitCast 同宽重解释，以及结构体走 asBytes + readInt" {
    const u: u32 = 0x41424344;
    const raw: [4]u8 = @bitCast(u);
    try std.testing.expectEqualSlices(u8, &.{ 0x44, 0x43, 0x42, 0x41 }, &raw);
    // @bitCast 不接受裸结构体，按字节走
    const h = Header{ .magic = 0x41424344, .len = 0x0102 };
    const bytes = std.mem.asBytes(&h);
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Header));
    try std.testing.expectEqual(@as(u32, 0x41424344), std.mem.readInt(u32, bytes[0..4], .little));
    try std.testing.expectEqual(@as(u16, 0x0102), std.mem.readInt(u16, bytes[4..6], .little));
}

test "writeInt 与 readInt 互为逆运算" {
    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, 0xAABBCCDD, .little);
    try std.testing.expectEqualSlices(u8, &.{ 0xDD, 0xCC, 0xBB, 0xAA }, &buf);
    try std.testing.expectEqual(@as(u32, 0xAABBCCDD), std.mem.readInt(u32, &buf, .little));
    std.mem.writeInt(u32, &buf, 0xAABBCCDD, .big); // 大端写出来字节序反过来
    try std.testing.expectEqualSlices(u8, &.{ 0xAA, 0xBB, 0xCC, 0xDD }, &buf);
}

test "类型自省：kindName 与 @typeInfo 的三类元数据" {
    try std.testing.expectEqualStrings("整数", kindName(u8));
    try std.testing.expectEqualStrings("浮点", kindName(f64));
    try std.testing.expectEqualStrings("comptime_int", kindName(@TypeOf(3)));
    try std.testing.expectEqualStrings("结构体", kindName(Header));
    try std.testing.expectEqualStrings("枚举", kindName(Color));
    try std.testing.expectEqualStrings("错误集", kindName(StoreError));
    try std.testing.expectEqualStrings("错误联合", kindName(anyerror!u8));
    const hi = @typeInfo(Header);
    try std.testing.expectEqual(@as(usize, 2), hi.@"struct".field_names.len);
    try std.testing.expectEqualStrings("magic", hi.@"struct".field_names[0][0..5]);
    try std.testing.expectEqualStrings("len", hi.@"struct".field_names[1][0..3]);
    // 枚举成员值能反射出来
    const ce = @typeInfo(Color);
    try std.testing.expectEqual(@as(u8, 4), ce.@"enum".field_values[2]);
    // 错误集的名字能列出来（0.17 的 error_names 是可空的）
    const se = @typeInfo(StoreError);
    try std.testing.expect(se.error_set.error_names != null);
    const names = se.error_set.error_names.?;
    try std.testing.expectEqual(@as(usize, 2), names.len);
    try std.testing.expectEqualStrings("NotFound", names[0][0..8]);
    try std.testing.expectEqualStrings("Corrupted", names[1][0..9]);
}

test "枚举与基整型互转" {
    const g: Color = .green;
    try std.testing.expectEqual(@as(u8, 2), @backingInt(g));
    const b: Color = @fromBackingInt(@as(u8, 4));
    try std.testing.expectEqual(Color.blue, b);
    const c: Color = @fromBackingInt(@intCast(1));
    try std.testing.expectEqual(Color.red, c);
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(Color));
    // 不写基整型时编译器挑**能装下所有成员的最小类型**：2 个成员 → u1（1 位就够）
    try std.testing.expectEqual(@as(u16, 1), @bitSizeOf(@typeInfo(Level).@"enum".tag_type));
}

test "编译期算术与宽化规则" {
    comptime var sum: u32 = 0;
    inline for (0..8) |i| sum += i;
    try std.testing.expectEqual(@as(u32, 28), sum);
    try std.testing.expectEqual(@as(u64, 3628800), factorial(10));
    // 宽化是唯一允许的隐式转换
    const a8: u8 = 200;
    var a16: u16 = 0;
    a16 = a8; // u8 → u16 不用写任何转型
    try std.testing.expectEqual(@as(u16, 200), a16);
    // 但算术不宽化：u16 + u16 仍是 u16（30000+30000 = 60000 刚好装得下）
    const g: u16 = 30000;
    try std.testing.expectEqual(@as(u16, 60000), g + g);
    // 想要更宽的结果就自己点名
    try std.testing.expectEqual(@as(u16, 1200), a8 + @as(u16, 1000));
}

test "指针往返：@intFromPtr 与 @ptrFromInt" {
    var n: u32 = 42;
    const addr = @intFromPtr(&n);
    const back: *const u32 = @ptrFromInt(addr);
    try std.testing.expectEqual(@as(u32, 42), back.*);
    n = 43;
    try std.testing.expectEqual(@as(u32, 43), back.*);
}
