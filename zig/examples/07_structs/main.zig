//! 07 结构体：字段与声明、字段默认值与 undefined、方法（self）、结构体当命名空间、嵌套结构体、init/deinit 惯例、匿名结构体与元组、按值 vs 按指针传递、@field/@fieldParentPtr、可选字段、auto/extern/packed 布局、comptime 反射、文件即 struct 与 usingnamespace 的下场
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 7.1 的主角：一个字段带默认值的结构体 ═══
/// 点。注意 y 有默认值 0，所以实例化时可以省掉。
pub const Point = struct {
    x: f64,
    y: f64 = 0,

    // 7.3：方法就是"第一个参数叫 self 的普通函数"，self 只是惯用名
    pub fn dist(self: Point) f64 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }
    /// 想改字段就必须收指针。调用写 p.translate(...) 即可，编译器自动取址
    pub fn translate(self: *Point, dx: f64, dy: f64) void {
        self.x += dx;
        self.y += dy;
    }
    /// 返回新值，不动原实例
    pub fn moved(self: Point, dx: f64, dy: f64) Point {
        return .{ .x = self.x + dx, .y = self.y + dy };
    }
};

// ═══ 7.5：结构体当命名空间 ═══
/// 这个 struct 一个字段都没有，纯命名空间。
pub const Config = struct {
    pub const version = "1.0";
    pub const max_entities = 1024;

    pub fn describe() []const u8 {
        return "Config v" ++ version;
    }
    /// 关联常量参与运算：当成类型的一部分来算
    pub fn entityLimit() u32 {
        return max_entities;
    }
};

// ═══ 7.5：Point.create 风格的具名构造器 ═══
pub const Vec2 = struct {
    x: f32,
    y: f32,

    /// 具名构造器。惯例上放在结构体命名空间里，而不是全局 free 函数
    pub fn create(sx: f32, sy: f32) Vec2 {
        return .{ .x = sx, .y = sy };
    }
    pub fn origin() Vec2 {
        return create(0, 0);
    }
    /// 嵌套类型：struct 里还能再放 struct，形成命名空间层级
    pub const Info = struct {
        count: usize = 0,
        pub fn of(n: usize) Info {
            return .{ .count = n };
        }
    };
    /// 注意这个 stats 没有 self：它属于**类型** Vec2，不属于某个实例。
    pub fn stats() Info {
        return Info.of(2);
    }
};

// ═══ 7.6：嵌套结构体 ═══
pub const Inner = struct {
    v: i32,
    label: []const u8 = "inner",
};

pub const Outer = struct {
    inner: Inner,
    tag: u8,
};

// ═══ 7.7：init / deinit 惯例 ═══
pub const Session = struct {
    id: u32,
    slots: u32 = 4,

    /// init 不会被自动调用（Zig 没有构造函数），就是一个返回 Self 的普通函数
    pub fn init(id: u32) Session {
        return .{ .id = id };
    }
    /// 需要分配器时惯用 `fn init(allocator: std.mem.Allocator) !Self`
    pub fn initWithSlots(id: u32, slots: u32) Session {
        return .{ .id = id, .slots = slots };
    }
    /// deinit 同样不会被自动调用，靠调用方 defer
    pub fn deinit(self: *Session) void {
        self.* = undefined;
    }
    pub fn describe(self: Session) []const u8 {
        _ = self;
        return "session";
    }
};

// ═══ 7.8：接收匿名结构体的函数 ═══
/// 参数写成 anytype，调用处传 `.{ ... }` 字面量，编译器现场造类型
pub fn checkSettings(settings: anytype) u32 {
    // settings 的类型是调用方那个字面量的类型，所以字段可能是 comptime_int，
    // 得在这里点名成 u32 再算（算术结果永不宽化，03 章 3.5 节）。
    const retries: u32 = settings.retries;
    return @as(u32, @intFromBool(settings.enabled)) + retries;
}

/// 参数写成显式匿名结构体类型：类型名可写出来，但每个字面量都是各自的新类型
fn sumXY(a: struct { x: i32, y: i32 }) i32 {
    return a.x + a.y;
}

/// 返回元组而不是结构体
fn divmod(a: i32, b: i32) struct { i32, i32 } {
    return .{ @divTrunc(a, b), @rem(a, b) };
}

// ═══ 7.11：@fieldParentPtr 需要知道宿主类型 ═══
pub const Creature = struct {
    name: []const u8,
    health: f32,
    mana: u32,
};

/// 只拿到字段指针时，用 @fieldParentPtr 反推回宿主指针
fn healMana(mana_ptr: *u32, amount: u32) void {
    // ⚠️ 0.17 的坑：mana 落在偏移 20 上，只需 4 字节对齐；而 Creature 因为
    //   name 是切片（16 字节指针对）要 8 字节对齐。父指针的对齐要求比子指针更高，
    //   不写 @alignCast 就报：error: @fieldParentPtr increases pointer alignment
    const self: *Creature = @alignCast(@fieldParentPtr("mana", mana_ptr));
    self.mana += amount;
    self.health += @floatFromInt(amount / 10);
}

// ═══ 7.12：布局三兄弟 ═══
/// auto：字段顺序由编译器重排以填满对齐空隙
pub const Auto = struct { a: u8, b: u32, c: u8 };
/// extern：严格按声明顺序排列，字段类型必须是 0 或 2 的幂次位宽
pub const Wire = extern struct { a: u32, b: u16 };
/// packed：位级打包，没有 padding
pub const Reg = packed struct { flag: u1, rest: u15 };

// ═══ 7.13：反射 ═══
/// 通用打印：把 T 的所有字段名与字段类型列出来，再把值逐个打出来
pub fn dumpFields(comptime T: type, value: T) void {
    const info = @typeInfo(T).@"struct";
    inline for (info.field_names, info.field_types, 0..) |fname, ftype, i| {
        // field_names 的元素是 [:0]const u8（带哨兵），打印要写全长度
        // field_types 的元素是 type，必须 inline for 展开才能 @typeName
        std.debug.print("    [{d}] {s}: {s} = {any}\n", .{ i, fname[0..fname.len], @typeName(ftype), @field(value, fname) });
    }
}

/// 反射驱动的通用求和：只累加整型字段，跳过其它类型
pub fn sumIntFields(comptime T: type, value: T) u64 {
    const info = @typeInfo(T).@"struct";
    var acc: u64 = 0;
    inline for (info.field_names, info.field_types) |fname, ftype| {
        switch (@typeInfo(ftype)) {
            .int => acc += @as(u64, @intCast(@field(value, fname))),
            else => {},
        }
    }
    return acc;
}

/// 字段类型是类型、值是编译期常量，所以 @intCast 能在这里用
pub fn sumFieldSizes(comptime T: type) usize {
    const info = @typeInfo(T).@"struct";
    var total: usize = 0;
    // field_attrs 与前两条平行数组等长，按下标配对
    inline for (info.field_types, info.field_attrs) |ftype, attr| {
        _ = attr;
        total += @sizeOf(ftype);
    }
    return total;
}

pub fn main() !void {
    // ═══ 7.1 定义与实例化：字段名初始化，漏字段是编译错 ═══
    begin("7.1");
    var p = Point{ .x = 3, .y = 4 }; // 具名字段初始化
    const origin = Point{ .x = 0 }; // y 用默认值 0
    std.debug.print("p=({d:.1},{d:.1}) origin=({d:.1},{d:.1})\n", .{ p.x, p.y, origin.x, origin.y });
    std.debug.print("Point sizeOf={d} @alignOf={d} @offsetOf(y)={d}\n", .{ @sizeOf(Point), @alignOf(Point), @offsetOf(Point, "y") });
    // ⚠️ 漏掉没有默认值的字段直接编译错，不是运行期问题：
    //   const bad = Point{ .y = 1 };
    //   → error: missing struct field: x
    // ⚠️ 写不存在的字段也编译错：
    //   const bad2 = Point{ .x = 1, .z = 2 };   → error: no field named 'z'
    // ⚠️ 具名字段结构体不能用位置初始化：
    //   const bad3 = Point{ 3, 4 };              → error: ... does not support array initialization syntax
    std.debug.print("p.dist()={d:.1}（方法已定义在上面）\n", .{p.dist()});
    end("7.1");

    // ═══ 7.2 字段没有 const/var 之分，可变性由绑定决定 ═══
    begin("7.2");
    const cp = Point{ .x = 1, .y = 2 };
    std.debug.print("const 绑定的 Point: x={d:.1}（读得到，改不了）\n", .{cp.x});
    // cp.x = 9;  → error: cannot assign to constant
    var mp = Point{ .x = 1, .y = 2 };
    mp.x = 9; // var 绑定 → 字段可写
    std.debug.print("var 绑定的 Point: x={d:.1}\n", .{mp.x});
    // ⚠️ 结构体字段**不能**写 var / const：
    //   const Bad = struct { var x: i32 = 0, y: i32 };
    //   → error: expected ';' after declaration
    //   字段永远是"可写的位"，能不能写取决于你手里这个值是 const 还是 var。
    end("7.2");

    // ═══ 7.3 方法：self 是普通参数，不是关键字 ═══
    begin("7.3");
    var q = Point{ .x = 3, .y = 4 };
    std.debug.print("q.dist()={d:.1}\n", .{q.dist()});
    q.translate(1, 1);
    std.debug.print("translate(1,1) 后 q=({d:.1},{d:.1})\n", .{ q.x, q.y });
    const q2 = q.moved(10, 10); // 值 self 方法：返回新实例，原实例不动
    std.debug.print("moved(10,10): q2=({d:.1},{d:.1}) q 不变=({d:.1},{d:.1})\n", .{ q2.x, q2.y, q.x, q.y });
    // 方法名可以随便起，self 也可以写成别的名字：
    //   fn norm(myself: Point) f64 { ... }   然后 p.norm() 照样能用
    //   —— 点号调用不检查第一个参数叫什么，只检查它是不是该类型。
    // ⚠️ 值 self 想改字段编译不过：self 是 const 绑定
    //   fn set(self: Point) void { self.x = 1; }
    //   → error: cannot assign to constant
    // ⚠️ const 实例不能调 *self 方法：
    //   const c = Point{ .x = 1, .y = 2 }; c.translate(1, 1);
    //   → error: expected type '*Point', found '*const Point' + note: cast discards const qualifier
    end("7.3");

    // ═══ 7.4 按值传递 vs 按指针传递 ═══
    begin("7.4");
    var src = Point{ .x = 1, .y = 1 };
    var copy = src; // var 赋值 = 完整拷贝
    copy.x = 100;
    std.debug.print("copy.x={d:.1} 但 src.x 仍是 {d:.1}（结构体是值语义）\n", .{ copy.x, src.x });
    std.debug.print("byValue 返回 {d:.1}，原实例 {d:.1}\n", .{ movedOf(src).x, src.x });
    translatePtr(&src, 5, 5);
    std.debug.print("translatePtr(&src,5,5) 后 src=({d:.1},{d:.1})（指针改的是原实例）\n", .{ src.x, src.y });
    std.debug.print("Point 占 {d} 字节；传 *Point 只传 {d} 字节地址\n", .{ @sizeOf(Point), @sizeOf(*Point) });
    end("7.4");

    // ═══ 7.5 结构体当命名空间 ═══
    begin("7.5");
    std.debug.print("Config.describe() = {s}\n", .{Config.describe()});
    std.debug.print("Config.version = {s}，max_entities = {d}\n", .{ Config.version, Config.max_entities });
    std.debug.print("Config.entityLimit() = {d}\n", .{Config.entityLimit()});
    std.debug.print("Config sizeOf={d}（没有字段的 struct 是 0 字节，纯命名空间）\n", .{@sizeOf(Config)});
    const v = Vec2.create(1.5, 2.5);
    const z = Vec2.origin();
    std.debug.print("Vec2.create(1.5,2.5)=({d},{d})  Vec2.origin()=({d},{d})\n", .{ v.x, v.y, z.x, z.y });
    std.debug.print("Vec2.Info.of(3).count = {d}；Vec2.stats().count = {d}\n", .{ Vec2.Info.of(3).count, Vec2.stats().count });
    std.debug.print("类型全名：{s} / {s}\n", .{ @typeName(Vec2), @typeName(Vec2.Info) });
    // 没有 static 关键字：写在 struct 里的 decl 属于**类型**，不在实例里。
    // 实例里只有字段。所以 Point{ .x = 1 }.dist 是方法，但不存在"实例上的 dist 字段"。
    end("7.5");

    // ═══ 7.6 嵌套结构体 ═══
    begin("7.6");
    var o = Outer{ .inner = .{ .v = 1, .label = "deep" }, .tag = 9 };
    std.debug.print("o.inner.v={d} o.inner.label={s} o.tag={d}\n", .{ o.inner.v, o.inner.label, o.tag });
    o.inner.v = 42; // 逐层走
    std.debug.print("改完 o.inner.v={d}；Outer sizeOf={d}（内层 {d} + tag 1 字节 + 补齐对齐）\n", .{ o.inner.v, @sizeOf(Outer), @sizeOf(Inner) });
    const inner_only = Outer{ .inner = .{ .v = 5 }, .tag = 1 }; // 内层的 label 用默认值
    std.debug.print("inner.label 默认值 = {s}\n", .{inner_only.inner.label});
    end("7.6");

    // ═══ 7.7 init / deinit 惯例，以及 init 不自动调用 ═══
    begin("7.7");
    const direct = Session{ .id = 1 }; // 直接字面量：init 根本不在调用链上
    std.debug.print("直接字面量 Session{{.id = 1}}: id={d} slots={d}\n", .{ direct.id, direct.slots });
    var s = Session.init(7); // 显式调 init
    defer s.deinit();
    std.debug.print("Session.init(7): id={d} slots={d}\n", .{ s.id, s.slots });
    const s2 = Session.initWithSlots(8, 64);
    std.debug.print("Session.initWithSlots(8,64): id={d} slots={d}\n", .{ s2.id, s2.slots });
    std.debug.print("describe()={s}\n", .{s.describe()});
    // Zig 没有构造函数 / 析构函数，也不会自动调 init。上面 direct 那一行就是证据：
    // 如果 init 是构造函数，direct 的 slots 会被 init 里的值覆盖。
    end("7.7");

    // ═══ 7.8 匿名结构体：.{} 的真身 ═══
    begin("7.8");
    // 字面量被目标类型强制转换（coerce）。anytype = "什么类型都行"
    std.debug.print("checkSettings({{ .enabled = true, .retries = 3 }}) = {d}\n", .{checkSettings(.{ .enabled = true, .retries = 3 })});
    const anon = .{ .name = "Zig", .born = 2016 };
    std.debug.print("匿名 struct 当轻量记录用: name={s} born={d}\n", .{ anon.name, anon.born });
    std.debug.print("匿名 struct 的类型名 = {s}（编译器生成的内部名）\n", .{@typeName(@TypeOf(anon))});
    // 函数返回结构体 vs 返回元组
    std.debug.print("sumXY({{ .x = 10, .y = 20 }}) = {d}\n", .{sumXY(.{ .x = 10, .y = 20 })});
    const dm = divmod(17, 5);
    std.debug.print("divmod(17,5) = {{ {d}, {d} }}（元组：商与余数没有名字）\n", .{ dm[0], dm[1] });
    const opt_anon = makeAnonOrNull();
    if (opt_anon) |a| {
        std.debug.print("返回 ?匿名 struct: x={d} y={d}\n", .{ a.x, a.y });
    } else {
        std.debug.print("返回 null\n", .{});
    }
    end("7.8");

    // ═══ 7.9 元组：字段名就是 "0" "1" ═══
    begin("7.9");
    const tup = .{ "Zig", 2016, true };
    std.debug.print("tup.len = {d}\n", .{tup.len});
    std.debug.print("tup[0]={s} tup[1]={d} tup[2]={}\n", .{ tup[0], tup[1], tup[2] });
    std.debug.print("tup.@\"0\"={s}（字段名写法：数字 0 变成字段名 \"0\"）\n", .{tup.@"0"});
    std.debug.print("元组的类型名 = {s}\n", .{@typeName(@TypeOf(tup))});
    // ⚠️ 运行期索引编译错：tup[i] 里 i 必须编译期已知
    //   var i: usize = 0; _ = tup[i];
    //   → error: unable to resolve comptime value
    //   note: tuple field index must be comptime-known
    var rt = makeTriple(1);
    rt[0] = 99; // 运行期元组可以按常量下标改（写死了0，所以合法）
    std.debug.print("运行期元组 makeTriple(1) 改[0]后 = ({d},{d},{d})\n", .{ rt[0], rt[1], rt[2] });
    end("7.9");

    // ═══ 7.10 可选字段 ?T ═══
    begin("7.10");
    var usr = User{ .name = "ada" };
    std.debug.print("新建 User: email={any}（默认值 null）\n", .{usr.email});
    usr.email = "ada@example.com";
    usr.login_count = 7;
    std.debug.print("填完后: email={s} login_count={d}\n", .{ usr.email.?, usr.login_count.? });
    // ⚠️ 可选字段的默认值必须是 null，否则它就是个"必填字段"：
    //   const Bad = struct { v: ?u32 };  const b = Bad{};
    //   → error: missing struct field: v
    const anon_user = User{ .name = "bob" };
    std.debug.print("orelse 兜底: {s}\n", .{anon_user.email orelse "<未设置>"});
    if (usr.email) |e| std.debug.print("if (可选) |值| 取出: {s}\n", .{e});
    std.debug.print("User sizeOf={d}（name16 + email16 + count8）\n", .{@sizeOf(User)});
    end("7.10");

    // ═══ 7.11 @field 与 @fieldParentPtr ═══
    begin("7.11");
    var cr = Creature{ .name = "elf", .health = 150, .mana = 10 };
    healMana(&cr.mana, 40);
    std.debug.print("healMana(&cr.mana,40) 后 mana={d} health={d:.0}（@fieldParentPtr 反推宿主）\n", .{ cr.mana, cr.health });
    // @field：按名字读写字段，名字必须编译期已知
    @field(cr, "health") = 175;
    std.debug.print("@field(cr,\"health\")=175 后 health={d:.0}\n", .{cr.health});
    inline for (.{ "name", "mana" }) |fname| {
        std.debug.print("  inline for 展开 @field(cr, \"{s}\") = {any}\n", .{ fname, @field(cr, fname) });
    }
    // ⚠️ 名字运行期才知道就编译错：
    //   @field(cr, someRuntimeString)
    //   → error: unable to resolve comptime value / note: field name must be comptime-known
    end("7.11");

    // ═══ 7.12 布局：auto / extern / packed ═══
    begin("7.12");
    std.debug.print("Auto{{a:u8,b:u32,c:u8}} sizeOf={d} align={d}：a@{d} b@{d} c@{d}\n", .{
        @sizeOf(Auto),        @alignOf(Auto),
        @offsetOf(Auto, "a"), @offsetOf(Auto, "b"),
        @offsetOf(Auto, "c"),
    });
    // ↑ 注意 a 的偏移是 4 不是 0：编译器把 u32 挪到最前面去了，
    //   这样 a 和 c 才能挤进同一组 padding 空隙。别依赖字段的内存顺序。
    std.debug.print("Wire extern sizeOf={d} align={d}：a@{d} b@{d}\n", .{
        @sizeOf(Wire), @alignOf(Wire), @offsetOf(Wire, "a"), @offsetOf(Wire, "b"),
    });
    const w = Wire{ .a = 0x11223344, .b = 0x5566 };
    const wbytes = std.mem.asBytes(&w);
    std.debug.print("Wire 数据 6 字节但 sizeOf={d}：{any}（末尾 2 字节是 padding）\n", .{ @sizeOf(Wire), wbytes });
    const magic_le = std.mem.readInt(u32, wbytes[0..4], .little);
    std.debug.print("按字节读回 a（小端）= 0x{x:0>8}\n", .{magic_le});
    std.debug.print("Reg packed{{flag:u1,rest:u15}} sizeOf={d} bitSize={d} align={d}\n", .{ @sizeOf(Reg), @bitSizeOf(Reg), @alignOf(Reg) });
    const reg = Reg{ .flag = 1, .rest = 0x7FFF };
    const reg_word: u16 = @bitCast(reg); // packed struct 允许 @bitCast
    std.debug.print("flag=1 rest=0x7FFF → u16 = 0x{x:0>4}\n", .{reg_word});
    std.debug.print("layout 标签：Auto={t} Wire={t} Reg={t}\n", .{
        @typeInfo(Auto).@"struct".layout,
        @typeInfo(Wire).@"struct".layout,
        @typeInfo(Reg).@"struct".layout,
    });
    // ⚠️ 0.17 的坑：@bitCast **不接受裸结构体**（extern struct 也不行）
    //   const x: u64 = @bitCast(wire);
    //   → error: cannot @bitCast from 'main.Wire'
    //   packed struct 是例外（上一行成功了）。走字节请用 asBytes + readInt。
    // ⚠️ extern struct 不许含 u24 这类非 2 的幂次位宽字段：
    //   const E = extern struct { a: u24 };
    //   → error: extern structs cannot contain fields of type 'u24'
    // ⚠️ packed struct 里不能取字段地址（对齐只有 2 字节，rest 还在第1 位的偏移上）：
    //   const p: *u15 = &reg.rest;
    //   → error: expected type '*u15', found '*align(2:1:2) u15'
    //   note: pointer host size '2' cannot cast into pointer host size '0'
    //   note: pointer bit offset '1' cannot cast into pointer bit offset '0'
    // 要改单个字段请用 @field 按值读写（7.11 节）。
    end("7.12");

    // ═══ 7.13 comptime 反射：三条平行数组 ═══
    begin("7.13");
    const c = Creature{ .name = "goblin", .health = 30, .mana = 7 };
    const info = @typeInfo(Creature).@"struct";
    std.debug.print("Creature layout={t} is_tuple={} 字段数={d} decl数={d}\n", .{ info.layout, info.is_tuple, info.field_names.len, info.decl_names.len });
    dumpFields(Creature, c);
    std.debug.print("sumFieldSizes(Creature) = {d}（{d}+{d}+{d}）\n", .{ sumFieldSizes(Creature), @sizeOf([]const u8), @sizeOf(f32), @sizeOf(u32) });
    const stats = Stats{ .hp = 10, .mp = 20, .atk = 12, .name = "hero" };
    std.debug.print("sumIntFields(Stats) = {d}（只累加整型字段，跳过 name）\n", .{sumIntFields(Stats, stats)});
    // field_attrs：与 field_names / field_types 平行，按下标配对
    const withDefaults = @typeInfo(Point).@"struct";
    inline for (withDefaults.field_names, withDefaults.field_attrs, 0..) |fname, attr, i| {
        std.debug.print("  Point 字段[{d}] {s} 有默认值={}\n", .{ i, fname[0..fname.len], attr.default_value_ptr != null });
    }
    // 元组也是 struct，is_tuple = true，字段名是 "0"/"1"/"2"
    const tinfo = @typeInfo(@TypeOf(tup)).@"struct";
    std.debug.print("元组 is_tuple={} 字段名[1]={s} 类型[1]={s}\n", .{ tinfo.is_tuple, tinfo.field_names[1][0..1], @typeName(tinfo.field_types[1]) });
    end("7.13");

    // ═══ 7.14 文件即 struct；usingnamespace 在 0.17 已被移除 ═══
    begin("7.14");
    std.debug.print("本文件的 main 与 helper2 都是「文件 struct」的字段：helper2.twice(21)={d}\n", .{helper2.twice(21)});
    const empty_table = helper2.Table{};
    std.debug.print("helper2.Answer={d} helper2.Table 的 keys={d}\n", .{ helper2.Answer, empty_table.keys });
    // 注意 @TypeOf(helper2) 的结果是 "type" —— @import 拿回的是**一个类型**，
    // 不是一个模块对象。要看它的成员就写 helper2.xxx，编译器在编译期解析。
    std.debug.print("@TypeOf(helper2)={s}；helper2.twice 的类型 = {s}\n", .{ @typeName(@TypeOf(helper2)), @typeName(@TypeOf(helper2.twice)) });
    // ⚠️ 0.17 已移除 usingnamespace。老教程里的
    //     const A = struct { pub const v = 7; };
    //     usingnamespace A;      // 把 A 的 decl 摊到当前作用域
    //   在 0.17 编译失败：error: expected ',' after field
    //   （它被当成结构体字段解析了）。替代品是显式导入：
    //     const a = @import("a.zig");  然后写 a.v
    // 这样"名字从哪来"永远写在源码里，不会被一个远处的 usingnamespace 改掉。
    end("7.14");

    // ═══ 7.15 禁止遮蔽：同名 shadow 是编译错 ═══
    begin("7.15");
    const tmp = Point{ .x = 1, .y = 2 };
    const total = tmp.dist();
    if (total > 0) {
        // 内层想再用 total 这个名字 → 编译错：
        //   error: local constant 'total' shadows local constant from outer scope
        //   note: previous declaration here
        // 变通做法：换个名字
        const total_sq = total * total;
        std.debug.print("内层用 total_sq={d:.1}（不能叫 total）\n", .{total_sq});
    }
    // 字段名与方法名属于不同命名空间，互不干扰
    const same = Point{ .x = 2, .y = 0 };
    std.debug.print("字段 x 与方法互不干扰：x={d:.1} dist={d:.1}\n", .{ same.x, same.dist() });
    end("7.15");

    std.debug.print("自检通过\n", .{});
}

// ═══ 7.10 的可选字段类型 ═══
pub const User = struct {
    name: []const u8,
    email: ?[]const u8 = null,
    login_count: ?u32 = null,
};

// ═══ 7.13 的反射目标：混合字段类型 ═══
pub const Stats = struct {
    hp: u32,
    mp: u32,
    atk: u32,
    name: []const u8,
};

fn movedOf(p: Point) Point {
    var local = p;
    local.x = 999;
    return local;
}

fn translatePtr(p: *Point, dx: f64, dy: f64) void {
    p.x += dx;
    p.y += dy;
}

fn makeAnonOrNull() ?struct { x: i32, y: i32 } {
    return .{ .x = 7, .y = 8 };
}

fn makeTriple(n: i32) struct { i32, i32, i32 } {
    return .{ n, n + 1, n + 2 };
}

const helper2 = @import("helper2.zig");

test "7.1 字段初始化、默认值与漏字段" {
    const p = Point{ .x = 3, .y = 4 };
    try std.testing.expectEqual(@as(f64, 5), p.dist());
    const origin = Point{ .x = 0 }; // y 走默认值
    try std.testing.expectEqual(@as(f64, 0), origin.y);
    const defaulted = Point{ .x = 1 };
    try std.testing.expectEqual(@as(f64, 0), defaulted.y);
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(Point));
    // 布局不等于声明顺序：x 和 y 都是 f64，各占 8 字节，y 的偏移就是 8
    try std.testing.expectEqual(@as(usize, 8), @offsetOf(Point, "y"));
}

test "7.3 方法：值 self 只读，指针 self 才改" {
    var p = Point{ .x = 3, .y = 4 };
    const before = p.dist();
    p.translate(1, 1);
    try std.testing.expectEqual(@as(f64, 4), p.x);
    try std.testing.expectEqual(@as(f64, 5), p.y);
    try std.testing.expectEqual(@as(f64, 5), before); // before 是改之前的拷贝
    // 值 self 方法返回新值
    const moved = p.moved(10, 10);
    try std.testing.expectEqual(@as(f64, 14), moved.x);
    try std.testing.expectEqual(@as(f64, 4), p.x);
}

test "7.4 值语义：赋值与传参都是拷贝" {
    const a = Point{ .x = 1, .y = 1 };
    var b = a;
    b.x = 100;
    try std.testing.expectEqual(@as(f64, 1), a.x);
    try std.testing.expectEqual(@as(f64, 100), b.x);
    var c = Point{ .x = 1, .y = 1 };
    const returned = movedOf(c); // 内部改了拷贝
    try std.testing.expectEqual(@as(f64, 999), returned.x);
    try std.testing.expectEqual(@as(f64, 1), c.x); // 原实例没变
    translatePtr(&c, 5, 5);
    try std.testing.expectEqual(@as(f64, 6), c.x);
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(*Point));
}

test "7.5 结构体是命名空间" {
    try std.testing.expectEqualStrings("Config v1.0", Config.describe());
    try std.testing.expectEqual(@as(u32, 1024), Config.entityLimit());
    try std.testing.expectEqual(@as(usize, 0), @sizeOf(Config)); // 纯命名空间 0 字节
    const v = Vec2.create(1.5, 2.5);
    try std.testing.expectEqual(@as(f32, 1.5), v.x);
    try std.testing.expectEqual(@as(f32, 0), Vec2.origin().x);
    try std.testing.expectEqual(@as(usize, 3), Vec2.Info.of(3).count);
    try std.testing.expectEqual(@as(usize, 2), Vec2.stats().count);
}

test "7.6 嵌套结构体与逐层访问" {
    var o = Outer{ .inner = .{ .v = 1, .label = "deep" }, .tag = 9 };
    try std.testing.expectEqual(@as(i32, 1), o.inner.v);
    try std.testing.expectEqualStrings("deep", o.inner.label);
    const inner_only = Outer{ .inner = .{ .v = 5 }, .tag = 1 };
    try std.testing.expectEqualStrings("inner", inner_only.inner.label); // 走内层默认值
    o.inner.v = 42;
    try std.testing.expectEqual(@as(i32, 42), o.inner.v);
    // Inner 自身 24 字节（i32 4 + padding 4 + 切片 16），加 tag 1 字节 → 25，
    // 但 Outer 的对齐是 8（跟着切片字段），所以补到 32。
    try std.testing.expectEqual(@as(usize, 32), @sizeOf(Outer));
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(Inner));
}

test "7.7 init 不自动调用" {
    // 直接字面量不会走 init
    const direct = Session{ .id = 1 };
    try std.testing.expectEqual(@as(u32, 4), direct.slots); // init 里没有覆写 slots
    const via_init = Session.init(7);
    try std.testing.expectEqual(@as(u32, 7), via_init.id);
    try std.testing.expectEqual(@as(u32, 64), Session.initWithSlots(8, 64).slots);
    var s = Session.init(1);
    s.deinit();
}

test "7.8 匿名结构体与 anytype" {
    try std.testing.expectEqual(@as(u32, 4), checkSettings(.{ .enabled = true, .retries = 3 }));
    try std.testing.expectEqual(@as(u32, 0), checkSettings(.{ .enabled = false, .retries = 0 }));
    try std.testing.expectEqual(@as(i32, 30), sumXY(.{ .x = 10, .y = 20 }));
    const dm = divmod(17, 5);
    try std.testing.expectEqual(@as(i32, 3), dm[0]);
    try std.testing.expectEqual(@as(i32, 2), dm[1]);
    const a = makeAnonOrNull().?;
    try std.testing.expectEqual(@as(i32, 7), a.x);
}

test "7.9 元组：.len、下标、@\"0\" 字段名" {
    const t = .{ 1, 2, 3 };
    try std.testing.expectEqual(@as(usize, 3), t.len);
    try std.testing.expectEqual(@as(comptime_int, 2), t[1]);
    try std.testing.expectEqual(@as(comptime_int, 1), t.@"0");
    var rt = makeTriple(1);
    rt[0] = 99;
    try std.testing.expectEqual(@as(i32, 99), rt[0]);
    try std.testing.expectEqual(@as(i32, 2), rt[1]);
}

test "7.10 可选字段" {
    const ua = User{ .name = "a" };
    try std.testing.expect(ua.email == null);
    try std.testing.expect(ua.login_count == null);
    var ub = User{ .name = "b", .email = "b@x", .login_count = 3 };
    try std.testing.expectEqualStrings("b@x", ub.email.?);
    try std.testing.expectEqual(@as(u32, 3), ub.login_count.?);
    ub.email = null; // 可以随时退回 null
    try std.testing.expect(ub.email == null);
    try std.testing.expectEqualStrings("<none>", ub.email orelse "<none>");
    if (ub.login_count) |n| try std.testing.expectEqual(@as(u32, 3), n);
}

test "7.11 @field 与 @fieldParentPtr" {
    var c = Creature{ .name = "elf", .health = 150, .mana = 10 };
    healMana(&c.mana, 40);
    try std.testing.expectEqual(@as(u32, 50), c.mana);
    try std.testing.expectEqual(@as(f32, 154), c.health); // 150 + (40/10)
    @field(c, "health") = 175;
    try std.testing.expectEqual(@as(f32, 175), @field(c, "health"));
    // 直接从字段指针反推宿主
    const parent: *Creature = @alignCast(@fieldParentPtr("mana", &c.mana));
    try std.testing.expectEqual(@as(u32, 50), parent.mana);
}

test "7.12 auto/extern/packed 布局" {
    // auto：编译器重排字段填 padding
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Auto));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(Auto, "b")); // u32 被挪到最前
    try std.testing.expectEqual(@as(usize, 4), @offsetOf(Auto, "a"));
    // extern：严格按声明顺序，数据 6 字节但占 8（对齐到 4 的倍数）
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Wire));
    try std.testing.expectEqual(@as(usize, 4), @offsetOf(Wire, "b"));
    // packed：位级布局，正好 2 字节
    try std.testing.expectEqual(@as(usize, 2), @sizeOf(Reg));
    try std.testing.expectEqual(@as(u16, 16), @bitSizeOf(Reg));
    const r = Reg{ .flag = 1, .rest = 0x7FFF };
    const rword: u16 = @bitCast(r);
    try std.testing.expectEqual(@as(u16, 0xFFFF), rword);
    // @bitCast 不接受裸结构体（非packed）：走字节
    const w = Wire{ .a = 0x11223344, .b = 0x5566 };
    try std.testing.expectEqual(@as(u32, 0x11223344), std.mem.readInt(u32, std.mem.asBytes(&w)[0..4], .little));
    // layout 标签
    try std.testing.expect(@typeInfo(Auto).@"struct".layout == .auto);
    try std.testing.expect(@typeInfo(Wire).@"struct".layout == .@"extern");
    try std.testing.expect(@typeInfo(Reg).@"struct".layout == .@"packed");
}

test "7.13 comptime 反射" {
    const info = @typeInfo(Creature).@"struct";
    try std.testing.expectEqual(@as(usize, 3), info.field_names.len);
    // 三条平行数组长度一致，按下标配对
    try std.testing.expectEqual(info.field_names.len, info.field_types.len);
    try std.testing.expectEqual(info.field_names.len, info.field_attrs.len);
    try std.testing.expectEqualStrings("name", info.field_names[0][0..4]);
    try std.testing.expectEqualStrings("[]const u8", @typeName(info.field_types[0]));
    try std.testing.expect(info.layout == .auto);
    try std.testing.expect(!info.is_tuple);
    try std.testing.expect(info.backing_integer == null);
    // 只有方法 decl，没有 pub 常量 → decl_names 为空
    try std.testing.expectEqual(@as(usize, 0), info.decl_names.len);
    // 通用求和
    try std.testing.expectEqual(@as(u64, 42), sumIntFields(Stats, Stats{ .hp = 10, .mp = 20, .atk = 12, .name = "hero" }));
    // 字段默认值探测
    const pinfo = @typeInfo(Point).@"struct";
    inline for (pinfo.field_names, pinfo.field_attrs, 0..) |fname, attr, i| {
        if (i == 0) {
            try std.testing.expectEqualStrings("x", fname[0..1]);
            try std.testing.expect(attr.default_value_ptr == null); // x 没有默认值
        } else {
            try std.testing.expectEqualStrings("y", fname[0..1]);
            try std.testing.expect(attr.default_value_ptr != null); // y 有默认值 0
        }
    }
    // 元组的 is_tuple = true，字段名是数字字符串
    const tinfo = @typeInfo(@TypeOf(.{ "Zig", 2016, true })).@"struct";
    try std.testing.expect(tinfo.is_tuple);
    try std.testing.expectEqual(@as(usize, 3), tinfo.field_names.len);
    try std.testing.expectEqualStrings("1", tinfo.field_names[1][0..1]);
    try std.testing.expectEqualStrings("comptime_int", @typeName(tinfo.field_types[1]));
}

test "7.14 文件即 struct" {
    try std.testing.expectEqual(@as(u32, 42), helper2.twice(21));
    try std.testing.expectEqual(@as(u32, 42), helper2.Answer);
    const tbl = helper2.Table{};
    try std.testing.expectEqual(@as(usize, 0), tbl.keys);
}

test "7.15 方法名与字段名属于不同命名空间" {
    // 字段 x 和方法 dist() 互不冲突：字段在实例上，方法在类型上
    const p = Point{ .x = 2, .y = 0 };
    try std.testing.expectEqual(@as(f64, 2), p.x);
    try std.testing.expectEqual(@as(f64, 2), p.dist());
}
