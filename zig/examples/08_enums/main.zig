//! 08 枚举与联合：enum 的基整型与非穷尽、0.17 的 @backingInt/@fromBackingInt 改名链、tagged union 的布局、switch 穷尽性、packed struct 位域、packed union、位运算、消息协议、union 与错误联合
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 8.1 节的枚举：不写基整型，编译器挑能装下全部成员的最小类型
const Color = enum {
    red,
    green,
    blue,

    /// 枚举也能有方法，和 struct 一样
    fn hex(self: Color) u32 {
        return switch (self) {
            .red => 0xFF0000,
            .green => 0x00FF00,
            .blue => 0x0000FF,
        };
    }
};

/// 8.2 节：显式基整型 + 显式赋值（C 互操作），末位 `_` 声明非穷尽
const Level = enum(u8) {
    low = 10,
    mid = 50,
    high = 90,
    _, // 非穷尽：未声明的整数值也能装进来
};

/// 8.2 节用：非穷尽枚举的 switch 必须留else，否则漏了"其它值"的处理
fn levelName(lv: Level) []const u8 {
    return switch (lv) {
        .low => "低",
        .mid => "中",
        .high => "高",
        else => "未知", // 非穷尽 → 必须有 else
    };
}

/// 8.3 节的 tagged union（`union(enum)` 在 0.17 仍然可用）
const Value = union(enum) {
    int: i64,
    text: []const u8,
    list: []const f64,

    fn kind(self: Value) []const u8 {
        return switch (self) {
            .int => "整数",
            .text => "文本",
            .list => "列表",
        };
    }
};

/// 8.4 节用：`union(显式标签枚举)` 语法也还在，标签类型由你指定
const Payload = union(enum) {
    none,
    small: u8,
    big: []const u8,
};

/// 8.5 节的位域：1 + 1 + 6 = 8 位，正好一个字节
const Flags = packed struct {
    bold: bool = false, // 1 bit，占 bit0
    italic: bool = false, // 1 bit，占 bit1
    size: u6 = 0, // 6 bits，占 bit2..bit7
};

/// 8.6 节用：跨字段的位模式（硬件寄存器画像）
const Reg = packed struct {
    a: u4, // bit0..bit3
    b: u4, // bit4..bit7
    c: u8, // bit8..bit15
};

/// 8.7 节用：packed union 的所有字段**位宽必须相同**（u16 与 packed struct{u8,u8} 都是 16 位）
const Pair = packed struct { hi: u8, lo: u8 };
const Word = packed union {
    bits: u16,
    pair: Pair,
};

/// 8.9 节用：把 union 变成一条协议消息（30 章 HTTP 解析同构）
const Message = union(enum) {
    ping: u64,
    text: []const u8,
    coords: struct { x: i32, y: i32 },
    bye: void,

    /// 编码：每种形态自己决定字节布局
    fn encode(self: Message, buf: []u8) EncodeError!usize {
        switch (self) {
            .ping => |v| {
                if (buf.len < 9) return error.NoSpace;
                buf[0] = 1;
                std.mem.writeInt(u64, buf[1..9], v, .big); // 网络字节序，一律大端
                return 9;
            },
            .text => |s| {
                if (buf.len < 1 + s.len) return error.NoSpace;
                buf[0] = 2;
                @memcpy(buf[1 .. 1 + s.len], s);
                return 1 + s.len;
            },
            .coords => |c| {
                if (buf.len < 9) return error.NoSpace;
                buf[0] = 3;
                std.mem.writeInt(i32, buf[1..5], c.x, .big);
                std.mem.writeInt(i32, buf[5..9], c.y, .big);
                return 9;
            },
            .bye => {
                buf[0] = 4;
                return 1;
            },
        }
    }

    /// 解码：tag 是整数，用普通 switch 分派；这里靠 union 的穷尽性兜底
    fn decode(buf: []const u8) DecodeError!Message {
        if (buf.len < 1) return error.Empty;
        return switch (buf[0]) {
            1 => if (buf.len < 9) error.Short else Message{ .ping = std.mem.readInt(u64, buf[1..9], .big) },
            2 => Message{ .text = buf[1..] },
            3 => if (buf.len < 9) error.Short else Message{ .coords = .{
                .x = std.mem.readInt(i32, buf[1..5], .big),
                .y = std.mem.readInt(i32, buf[5..9], .big),
            } },
            4 => Message{ .bye = {} },
            else => error.UnknownTag,
        };
    }

    /// 打印也写成一次穷尽匹配——漏一种形态编译器会拦
    fn label(self: Message) []const u8 {
        return switch (self) {
            .ping => "ping",
            .text => "text",
            .coords => "coords",
            .bye => "bye",
        };
    }
};

const EncodeError = error{NoSpace};
const DecodeError = error{ Empty, Short, UnknownTag };

/// 8.3 节用：让未知值来自运行期（编译期已知的话 @tagName 会被编译器拦下）
fn levelFromByte(n: u8) Level {
    return @fromBackingInt(n);
}

pub fn main() !void {
    // ═══ 8.1 enum：封闭集合 + 方法 + @tagName═══
    begin("8.1");
    const c: Color = .green; // 目标类型明确时 `.` 前缀可省类型名
    std.debug.print("Color 成员数={d} 基整型={s} @sizeOf={d} @bitSizeOf={d}\n", .{
        @typeInfo(Color).@"enum".field_names.len,
        @typeName(@typeInfo(Color).@"enum".tag_type),
        @sizeOf(Color),
        @bitSizeOf(Color),
    });
    std.debug.print("@tagName(.green)={s}，.green.hex()=0x{x:0>6}\n", .{ @tagName(c), c.hex() });
    // 枚举就是整数：字节视角里只有基整数值，没有 tag、没有指针
    const cbytes = std.mem.asBytes(&c);
    std.debug.print(".green 的字节={any}（首字节就是基整数值）\n", .{cbytes});
    // 反射枚举成员：field_values 元素是 comptime_int，只能 inline for
    inline for (@typeInfo(Color).@"enum".field_names, @typeInfo(Color).@"enum".field_values) |fname, fval| {
        std.debug.print("  {s} = {d}\n", .{ fname[0..fname.len], fval });
    }
    end("8.1");

    // ═══ 8.2 基整型 + 非穷尽 `_` ═══
    begin("8.2");
    const lv: Level = @fromBackingInt(@intCast(50));
    std.debug.print("Level 基整型={s}，lv={s}({d})\n", .{ @typeName(@typeInfo(Level).@"enum".tag_type), @tagName(lv), @backingInt(lv) });
    const unknown = levelFromByte(42); // 42 不在声明里，但有 `_` 所以装得下
    std.debug.print("未知值 {d} 也装得下：{s}\n", .{ @backingInt(unknown), levelName(unknown) });
    // ⚠️ 对未知值取名字：值编译期已知 → 编译错
    //   @tagName(@fromBackingInt(@intCast(42)))
    //   → error: no field with value '@fromBackingInt(42)' in enum 'main.Level'
    // 值运行期才知道 → 运行期 panic：thread ... panic: invalid enum value
    //
    // 正确姿势：先switch 归类，再 @tagName
    const raws = [_]u8{ 10, 50, 90, 42 };
    for (raws) |raw| {
        const lv2 = levelFromByte(raw);
        // ⚠️ 非穷尽枚举的 switch 必须留 else，否则 42 那个值会让编译失败
        std.debug.print("  原始 {d:>3} → {s}（backing {d}）\n", .{ raw, levelName(lv2), @backingInt(lv2) });
    }
    end("8.2");

    // ═══ 8.3 0.17 改名链：@backingInt / @fromBackingInt / @enumFromInt ═══
    begin("8.3");
    // ≤0.16 的 @intFromEnum → 0.17 的 @backingInt
    std.debug.print("@backingInt(.green)={d}（类型 {s}）\n", .{ @backingInt(c), @typeName(@TypeOf(@backingInt(c))) });
    // @fromBackingInt 要求操作数**恰好是基整型**，所以字面量要 @intCast
    const from_lit: Level = @fromBackingInt(50);
    const from_cast: Level = @fromBackingInt(@intCast(50));
    std.debug.print("@fromBackingInt(50)={s}；@fromBackingInt(@intCast(50))={s}\n", .{ @tagName(from_lit), @tagName(from_cast) });
    // ⚠️ 传 u16 给 @fromBackingInt 编译错：expected type 'u8', found 'u16'
    // ⚠️ 而 0.17 的 @enumFromInt 接受任意整数宽度（它做的是 @intCast 语义）。
    // 下面这行就是"@enumFromInt(@as(u16, 2))"经 zig fmt 自动迁移后的等价写法——
    // 源码里不能直接写 @enumFromInt，否则 fmt --check 不过（见 8.3 节正文）。
    const widened: Color = @fromBackingInt(@intCast(@as(u16, 2)));
    std.debug.print("@enumFromInt(@as(u16, 2)) 等价写法 = {s}（原本接受非基整型）\n", .{@tagName(widened)});
    // ⚠️ 名字被回收：0.17 里 @enumFromInt 是合法名字但语义不同于老教程。
    // 老教程 @intToEnum(E, n) → 0.17 直接 @enumFromInt(n)（照抄会编译错：
    //   error: invalid builtin function: '@intToEnum'）
    //
    // zig fmt 会自动迁移前两处：@intFromEnum(x) → @backingInt(x)，
    // @enumFromInt(n) → @fromBackingInt(@intCast(n))。
    // 但它**不改** builtin.mode == .Debug 这类枚举取值（0.17 是小写 .debug）。
    std.debug.print("builtin.mode={s}\n", .{@typeName(@TypeOf(@import("builtin").mode))});
    end("8.3");

    // ═══ 8.4 tagged union：安全的多选一 + 布局实测 ═══
    begin("8.4");
    std.debug.print("Value sizeOf={d} alignOf={d}，字段数={d}\n", .{ @sizeOf(Value), @alignOf(Value), @typeInfo(Value).@"union".field_names.len });
    const vtag = @typeInfo(Value).@"union".tag_type.?;
    std.debug.print("标签类型={s}，占 {d} 位\n", .{ @typeName(vtag), @bitSizeOf(vtag) });
    // 布局是"tag + 最大负载"再按对齐补齐，不是"指针 + tag"
    const Small = union(enum) { a: u8, b: u32, c: u64 };
    std.debug.print("{{a:u8,b:u32,c:u64}} sizeOf={d} alignOf={d}（u64=8，tag 的 2 位塞进尾部 padding）\n", .{ @sizeOf(Small), @alignOf(Small) });
    const WithSlice = union(enum) { s: []const u8, n: usize };
    std.debug.print("{{s:[]const u8,n:usize}} sizeOf={d}（16 负载 + tag，按对齐补到 8 的倍数）\n", .{@sizeOf(WithSlice)});
    // 裸 union 没有标签类型
    const Raw = union { a: u8, b: u16 };
    if (@typeInfo(Raw).@"union".tag_type) |t| {
        std.debug.print("Raw tag_type={s}\n", .{@typeName(t)});
    } else {
        std.debug.print("裸 union 的 tag_type=null（读错字段没人拦）\n", .{});
    }
    // union(显式标签枚举) 语法也还在
    const p_none: Payload = .{ .none = {} };
    std.debug.print("Payload(.none) 的 tag名={s}，sizeOf={d}\n", .{ @tagName(p_none), @sizeOf(Payload) });
    const p_small: Payload = .{ .small = 200 };
    std.debug.print("Payload(.small=200) tag名={s}\n", .{@tagName(p_small)});
    end("8.4");

    // ═══ 8.5 switch 捕获负载：tagged union 的正确打开方式 ═══
    begin("8.5");
    const w: Value = .{ .list = &.{ 1.5, 2.5, 3.5 } };
    // 联合体的 switch 必须处理每一种可能，漏一种就是编译错：
    //   error: switch must handle all possibilities
    //   note: unhandled enumeration value: 'text'
    switch (w) {
        .int => |i| std.debug.print("整数 {d}\n", .{i}),
        .text => |t| std.debug.print("文本 {s}\n", .{t}),
        .list => |ls| std.debug.print("列表 {d} 项，首项 {d:.1}\n", .{ ls.len, ls[0] }),
    }
    // 换形态就是整体换值
    var val: Value = .{ .int = 42 };
    std.debug.print("kind={s}\n", .{val.kind()});
    val = .{ .text = "hi" };
    std.debug.print("kind={s}，取值 {s}\n", .{ val.kind(), val.text });
    // 读错激活字段：标签是编译期已知 → 直接编译错（不是运行期panic！）
    //   v.int 其中 v = Value{ .text = "hi" }
    //   → error: access of union field 'int' while field 'text' is active
    // 标签运行期才知道（来自函数参数）才会变成 panic，同一句错误信息。
    end("8.5");

    // ═══ 8.6 packed struct：精确到位 ═══
    begin("8.6");
    std.debug.print("Flags sizeOf={d} bitSizeOf={d}（1+1+6=8 位，装进 1 字节）\n", .{ @sizeOf(Flags), @bitSizeOf(Flags) });
    const f = Flags{ .bold = true, .size = 12 };
    const bits: u8 = @bitCast(f); // packed struct 是 @bitCast 唯一能吃的结构体
    std.debug.print("Flags{{bold=true,size=12}} → 0b{b:0>8}（bold=bit0，size=bit2..7）\n", .{bits});
    // 反向：整数造packed struct
    const from_int: Flags = @bitCast(@as(u8, 0b0011_0001));
    std.debug.print("0b00110001 反解：bold={} italic={} size={d}\n", .{ from_int.bold, from_int.italic, from_int.size });
    // 全1 验证位顺序
    const all1: u8 = @bitCast(Flags{ .bold = true, .italic = true, .size = 0b111111 });
    std.debug.print("bold+italic+size=63 → 0b{b:0>8}\n", .{all1});
    // packed struct 里的 enum 字段按 bitSizeOf 算位
    const Mode = enum(u2) { off, on };
    const Ctl = packed struct { en: bool, mode: Mode, level: u5 };
    std.debug.print("Ctl bitSizeOf={d}（bool 1 位 + enum(u2) 2 位 + u5 = 8）\n", .{@bitSizeOf(Ctl)});
    const ctl: Ctl = .{ .en = true, .mode = .on, .level = 3 };
    std.debug.print("Ctl{{en=true,mode=on,level=3}} → 0x{x:0>2}\n", .{@as(u8, @bitCast(ctl))});
    // ⚠️ packed struct 不能放指针
    //   packed struct { ptr: *const u8 }
    //   → error: packed structs cannot contain fields of type '*const u8'
    //     note: pointers cannot be directly bitpacked
    end("8.6");

    // ═══ 8.7 packed union 与位运算 ═══
    begin("8.7");
    std.debug.print("Word sizeOf={d} bitSizeOf={d} alignOf={d}（u16 与 packed struct{{hi,lo}} 都是 16 位）\n", .{ @sizeOf(Word), @bitSizeOf(Word), @alignOf(Word) });
    // ⚠️ packed union 的所有字段位宽必须相同，否则编译错：
    //   packed union { a: u8, b: u16 }
    //   → error: field bit width does not match earlier field
    //     note: all fields in a packed union must have the same bit width
    const wv: Word = .{ .bits = 0xBEEF };
    std.debug.print("Word{{.bits=0xBEEF}} @bitCast 回 u16 = 0x{x:0>4}\n", .{@as(u16, @bitCast(wv))});
    const wp: Word = .{ .pair = .{ .hi = 0xBE, .lo = 0xEF } };
    std.debug.print("换成 .pair 视角bits = 0x{x:0>4}（hi 在高字节）\n", .{wp.bits});
    // extern union 对照：按对齐走，不是按位
    const EU = extern union { a: u8, b: u16 };
    std.debug.print("extern union sizeOf={d} alignOf={d}（对齐到 2 字节）\n", .{ @sizeOf(EU), @alignOf(EU) });
    // 位操作家族
    std.debug.print("popCount(0xF0F0)={d}；0b1011<<2={b:0>6}；@ctz(0b1000_0000)={d}\n", .{
        @popCount(@as(u16, 0xF0F0)),
        @as(u8, 0b1011) << 2,
        @ctz(@as(u8, 0b1000_0000)),
    });
    // 用位运算直接从 packed struct 读写单个字段（不@bitCast 整块）
    var rf = Flags{ .size = 0 };
    rf.italic = true;
    rf.size = @truncate(@as(u16, 0b11_0001) >> 2); // 手工算：借 u16 中转再截断
    std.debug.print("手工位运算：italic={} size={d} → 0x{x:0>2}\n", .{ rf.italic, rf.size, @as(u8, @bitCast(rf)) });
    end("8.7");

    // ═══ 8.8 Reg：跨字节的位域 ═══
    begin("8.8");
    std.debug.print("Reg sizeOf={d} bitSizeOf={d}\n", .{ @sizeOf(Reg), @bitSizeOf(Reg) });
    const r = Reg{ .a = 0xF, .b = 0x1, .c = 0x23 };
    const rb: u16 = @bitCast(r);
    std.debug.print("Reg{{a=0xF,b=0x1,c=0x23}} → 0x{x:0>4}（a 在 bit0-3，b 在 bit4-7，c 在高字节）\n", .{rb});
    // @offsetOf 对 packed struct 恒为 0（没有字节偏移概念）
    std.debug.print("@offsetOf(Flags, \"size\")={d}（packed 没有字节偏移）\n", .{@offsetOf(Flags, "size")});
    end("8.8");

    // ═══ 8.9 用union 表达"消息" ═══
    begin("8.9");
    var buf: [32]u8 = undefined;
    const outbox = [_]Message{
        .{ .ping = 0xDEADBEEF },
        .{ .text = "hello" },
        .{ .coords = .{ .x = -3, .y = 42 } },
        .{ .bye = {} },
    };
    for (outbox) |m| {
        const n = try m.encode(&buf);
        std.debug.print("编码 {s} → {d} 字节 {any}\n", .{ m.label(), n, buf[0..n] });
        const back = try Message.decode(buf[0..n]);
        // 解码回来还是同一个 union，形态一致
        std.debug.print("  解码 → {s}", .{back.label()});
        switch (back) {
            .ping => |v| std.debug.print("（{d}）", .{v}),
            .text => |t| std.debug.print("（{s}）", .{t}),
            .coords => |xy| std.debug.print("（{d},{d}）", .{ xy.x, xy.y }),
            .bye => std.debug.print("（无负载）", .{}),
        }
        std.debug.print("\n", .{});
    }
    // 未知 tag：解码函数自己返回 error.UnknownTag（错误联合，不是 panic）
    // ⚠️ 这里必须写 &.{99}：数组字面量要 coerce 成切片得加 &，
    //    `zig test` 能过但 `zig build-exe` 会报 array literal requires address-of operator
    const bad_tag = Message.decode(&.{99});
    if (bad_tag) |m| {
        std.debug.print("喂一个未知 tag 99 → 意外解出 {s}\n", .{m.label()});
    } else |e| {
        std.debug.print("喂一个未知 tag 99 → {s}（错误联合，不是 panic）\n", .{@errorName(e)});
    }
    end("8.9");

    // ═══ 8.10 union 与错误联合 !T 的关系 ═══
    begin("8.10");
    // ⚠️ 0.17 的大变化：`||` 变成**错误集并集**运算，不再是"造错误联合"。
    //   error{A} || Val(union) → error: expected error set type, found 'main.Val'
    // 造错误联合要用 `E!T` 语法：
    const MyErr = error{ Oops, Bad };
    std.debug.print("MyErr || error{{Boom}} = {s}（集合并集）\n", .{@typeName(MyErr || error{Boom})});
    std.debug.print("MyErr!i64 = {s}（错误联合类型）\n", .{@typeName(MyErr!i64)});
    std.debug.print("anyerror!Value = {s}（错误联合的 payload 可以是 union）\n", .{@typeName(anyerror!Value)});
    std.debug.print("anyerror!?Value = {s}（? 在外、! 在内，sizeOf={d}）\n", .{ @typeName(anyerror!?Value), @sizeOf(anyerror!?Value) });
    const ei = @typeInfo(MyErr!i64);
    std.debug.print("error_union 分支：error_set={s} payload={s}\n", .{ @typeName(ei.error_union.error_set), @typeName(ei.error_union.payload) });
    // 区别：tagged union 用**类型系统**穷尽；错误联合运行时才决定是值还是错误
    std.debug.print("Value 是 {d} 字节，MyErr!Value 是 {d} 字节（多了错误通道）\n", .{ @sizeOf(Value), @sizeOf(MyErr!Value) });
    end("8.10");

    std.debug.print("自检通过\n", .{});
}

test "enum 的基整型、@tagName 与 @backingInt" {
    // 不写基整型 → 编译器挑能装下 3 个成员的最小类型（2 位）
    try std.testing.expectEqual(@as(u16, 2), @bitSizeOf(@typeInfo(Color).@"enum".tag_type));
    try std.testing.expectEqualStrings("green", @tagName(Color.green));
    try std.testing.expectEqual(@as(u2, 1), @backingInt(Color.green));
    try std.testing.expectEqual(@as(u32, 0x00FF00), Color.green.hex());
    // 枚举就是整数
    const bytes = std.mem.asBytes(&Color.blue);
    try std.testing.expectEqualSlices(u8, &.{2}, bytes);
}

test "非穷尽枚举能装未知值，但取不到名字" {
    try std.testing.expectEqual(@as(u8, 10), @backingInt(Level.low));
    try std.testing.expectEqualStrings("中", levelName(Level.mid));
    // 42 不在声明的三个值里，有 `_` 所以装得下
    const unknown = levelFromByte(42);
    try std.testing.expectEqual(@as(u8, 42), @backingInt(unknown));
    try std.testing.expectEqualStrings("未知", levelName(unknown));
    // @fromBackingInt 字面量直接给就行（comptime_int 会被定型到基整型）
    try std.testing.expectEqual(Level.mid, @as(Level, @fromBackingInt(50)));
}

test "0.17 改名：@fromBackingInt 要精确基整型" {
    // ⚠️ 这里写不出 @enumFromInt —— zig fmt 会把它自动改写成
    //    @fromBackingInt(@intCast(...))，`fmt --check` 就不通过了（见 8.3 节）。
    // @fromBackingInt 传 u16 是编译错，所以只能给精确的 u8
    try std.testing.expectEqual(Level.high, @as(Level, @fromBackingInt(@as(u8, 90))));
    // Color 不写赋值 → 隐式 0/1/2，所以 2 是 blue
    try std.testing.expectEqual(Color.blue, @as(Color, @fromBackingInt(@intCast(@as(u16, 2)))));
    try std.testing.expectEqual(Color.blue, @as(Color, @fromBackingInt(@intCast(@as(u32, 2)))));
}

test "tagged union 的布局与穷尽 switch" {
    // 布局 = tag + 最大负载，按对齐补齐
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(Value));
    // tag 是编译器自动生成的 enum，3 个形态 → 2 位
    try std.testing.expectEqual(@as(u16, 2), @bitSizeOf(@typeInfo(Value).@"union".tag_type.?));
    const v: Value = .{ .int = 42 };
    try std.testing.expectEqualStrings("整数", v.kind());
    // 穷尽匹配：漏一种形态就编译不过，所以这里能拿到值
    const got: i64 = switch (v) {
        .int => |i| i,
        .text => |t| @intCast(t.len),
        .list => |ls| @intCast(ls.len),
    };
    try std.testing.expectEqual(@as(i64, 42), got);
    // 换形态
    const t2: Value = .{ .text = "hi" };
    try std.testing.expectEqualStrings("文本", t2.kind());
}

test "union(显式标签枚举) 与 payload: void" {
    const p: Payload = .{ .none = {} };
    try std.testing.expectEqualStrings("none", @tagName(p));
    const s: Payload = .{ .small = 7 };
    try std.testing.expectEqualStrings("small", @tagName(s));
    try std.testing.expectEqual(@as(u8, 7), s.small);
}

test "packed struct 的位布局：@bitCast 是它唯一的往返方式" {
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(Flags));
    try std.testing.expectEqual(@as(u16, 8), @bitSizeOf(Flags));
    const f = Flags{ .bold = true, .size = 12 };
    // bold=bit0，italic=bit1，size 占 bit2..7= 0b001100<<2 = 0x31
    try std.testing.expectEqual(@as(u8, 0b0011_0001), @as(u8, @bitCast(f)));
    // 反向：整数 → packed struct
    const back: Flags = @bitCast(@as(u8, 0b0011_0001));
    try std.testing.expect(back.bold);
    try std.testing.expect(!back.italic);
    try std.testing.expectEqual(@as(u6, 12), back.size);
    // 跨字节位域
    const r = Reg{ .a = 0xF, .b = 0x1, .c = 0x23 };
    try std.testing.expectEqual(@as(u16, 0x231F), @as(u16, @bitCast(r)));
}

test "packed union 要求所有字段位宽相同" {
    try std.testing.expectEqual(@as(usize, 2), @sizeOf(Word));
    try std.testing.expectEqual(@as(u16, 16), @bitSizeOf(Word));
    const w: Word = .{ .bits = 0xBEEF };
    try std.testing.expectEqual(@as(u16, 0xBEEF), @as(u16, @bitCast(w)));
    // ⚠️ 也不能一次初始化两个字段：
    //   .{ .hi = 0xBE, .lo = 0xEF }
    //   → error: cannot initialize multiple union fields at once;
    //     unions can only have one active field
    // 位操作
    try std.testing.expectEqual(@as(u32, 8), @popCount(@as(u16, 0xF0F0)));
    try std.testing.expectEqual(@as(u32, 3), @popCount(@as(u8, 0b1011)));
    try std.testing.expectEqual(@as(u32, 7), @ctz(@as(u8, 0b1000_0000)));
}

test "union 表达消息：编码解码往返" {
    var buf: [32]u8 = undefined;
    // ping：大端写u64
    const n1 = try (Message{ .ping = 0xDEADBEEF }).encode(&buf);
    try std.testing.expectEqual(@as(usize, 9), n1);
    try std.testing.expectEqual(@as(u8, 1), buf[0]);
    const back1 = try Message.decode(buf[0..9]);
    try std.testing.expectEqual(@as(u64, 0xDEADBEEF), back1.ping);

    // text：1 字节 tag + 内容
    const n2 = try (Message{ .text = "hello" }).encode(&buf);
    try std.testing.expectEqual(@as(usize, 6), n2);
    const back2 = try Message.decode(buf[0..n2]);
    try std.testing.expectEqualStrings("hello", back2.text);

    // coords：两个 i32 大端
    const n3 = try (Message{ .coords = .{ .x = -3, .y = 42 } }).encode(&buf);
    try std.testing.expectEqual(@as(usize, 9), n3);
    const back3 = try Message.decode(buf[0..n3]);
    try std.testing.expectEqual(@as(i32, -3), back3.coords.x);
    try std.testing.expectEqual(@as(i32, 42), back3.coords.y);

    // bye：无负载，1 字节
    const n4 = try (Message{ .bye = {} }).encode(&buf);
    try std.testing.expectEqual(@as(usize, 1), n4);
    try std.testing.expectEqualStrings("bye", (try Message.decode(buf[0..1])).label());

    // 缓冲不够→ 错误联合返回 error
    var tiny: [4]u8 = undefined;
    try std.testing.expectError(error.NoSpace, (Message{ .ping = 1 }).encode(&tiny));
    // 未知 tag → 错误联合
    try std.testing.expectError(error.UnknownTag, Message.decode(&.{99}));
    try std.testing.expectError(error.Empty, Message.decode(&.{}));
    try std.testing.expectError(error.Short, Message.decode(&.{ 1, 2, 3 }));
}

test "错误联合：0.17 用 E!T，|| 只合并错误集" {
    const MyErr = error{ Oops, Bad };
    // || 是集合并集
    try std.testing.expectEqual(@as(usize, 3), @typeInfo(MyErr || error{Boom}).error_set.error_names.?.len);
    // E!T 造错误联合，payload 可以是 union
    // Value 是 24 字节，套上错误联合变32：多出的字节是"这是值还是错误"的判别位+对齐
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(Value));
    try std.testing.expectEqual(@as(usize, 32), @sizeOf(@TypeOf(@as(MyErr!Value, error.Oops))));
    const ei = @typeInfo(MyErr!i64);
    try std.testing.expectEqual(@as(usize, @sizeOf(MyErr)), @sizeOf(ei.error_union.error_set));
    try std.testing.expectEqualStrings("i64", @typeName(ei.error_union.payload));
}
