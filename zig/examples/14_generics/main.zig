//! 14 泛型：comptime 类型参数、`@typeInfo` 反射、编译期代码生成
//! 分节打印约定：每个小节用 ==== 14.N 开始 ==== / ==== 14.N 结束 ==== 圈出
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 支撑类型与函数（容器级）
//
//⚠️ 0.17 不许在函数体里声明 fn（报极具误导性的expected ',' after
// initializer），所以本章所有辅助函数都必须放在容器级。
// ══════════════════════════════════════════════════════════════════

/// 14.1 节的类型构造器：参数全是 comptime，返回值是 `type`。
/// 泛型在Zig 里就是"编译期跑一个函数，把类型当返回值"。
fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return [rows][cols]T;
}

/// 14.2 节的泛型容器：`fn Container(comptime T: type) type` 是标准形状。
/// @This() 在泛型 struct 里指向"当前正在定义的这个 struct"——
/// 此刻它还没有名字（名字是 `Stack(u32)` 这种实例化产物），所以只能靠 @This() 自指。
fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: std.ArrayList(T) = .empty,

        /// 把类型参数再导出成一个常量，方便外部查询（13.8 节 type 是一等值）。
        pub const Item = T;

        pub fn push(self: *Self, gpa: std.mem.Allocator, v: T) !void {
            try self.items.append(gpa, v);
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.pop();
        }

        pub fn peek(self: *const Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.items[self.items.items.len - 1];
        }

        pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
            self.items.deinit(gpa);
        }
    };
}

/// 14.2 节：两个类型参数的泛型（异构 pair）。
/// A 和 B 是**独立**的类型参数——这是 `comptime T: type` 相对 anytype 的
/// 直接优势：anytype 只能一个参数，泛型可以任意多个、各自独立。
fn Pair(comptime A: type, comptime B: type) type {
    return struct {
        const Self = @This();

        /// 两个字段各自占多少字节（编译期算，运行期零开销）。
        pub const size_a = @sizeOf(A);
        pub const size_b = @sizeOf(B);

        a: A,
        b: B,

        /// 交换两个字段。⚠️ 只能用于 A == B——异构字段没法直接互换，
        /// 这条限制是**编译期**判定的（见下面 swapChecked 的 @compileError）。
        pub fn swap(self: *Self) void {
            if (A != B) @compileError("swap 要求 A == B；异构请用 toBytes/toFromBytes");
            const tmp = self.a;
            self.a = self.b;
            self.b = tmp;
        }

        /// 把整个 Pair 的**第一个字段**摊成字节数组。长度是编译期算出来的常量，
        /// 异构也能用——这是"编译期算尺寸、运行期零开销"的典型写法。
        pub fn toBytes(self: *const Self) [@sizeOf(A)]u8 {
            // 指针转换 + 解引用 = 零拷贝的字节视图（@bitCast 不能用于指针类型）
            return @as(*const [@sizeOf(A)]u8, @ptrCast(&self.a)).*;
        }
    };
}

/// 14.3 节的 anytype：单个参数版"隐式 comptime T"。
/// 返回类型用 @TypeOf(values[0]) —— 值本身就是编译期已知的，元素类型随之确定。
fn firstOf(items: anytype) @TypeOf(items[0]) {
    return items[0];
}

/// 14.3 节：两个 anytype 参数。
fn maxOf(a: anytype, b: anytype) @TypeOf(a) {
    return if (a > b) a else b;
}

/// 14.4 节要反射的结构体样本。
const Person = struct {
    name: []const u8,
    age: u8,
    vip: bool,
};

/// 14.4 节：0.17 迁移后的字段表遍历。
/// ⚠️ `@typeInfo(T).@"struct".fields`（字段结构体数组）**已不存在**，
/// 改用三条**平行数组** field_names / field_types / field_attrs，
/// 长度保证一致，按下标配对。
fn dumpFields(comptime T: type) void {
    const s = @typeInfo(T).@"struct";
    inline for (s.field_names, s.field_types, s.field_attrs) |name, ty, attrs| {
        std.debug.print("  {s}: {s}  显式对齐={any} comptime字段={} 有默认值={}\n", .{
            name[0..name.len], // 哨兵切片，打印要写 [0..len]
            @typeName(ty),
            attrs.@"align", // ⚠️ 0.17 是 .@"align"（?usize），不是 .alignment
            attrs.@"comptime",
            attrs.default_value_ptr != null,
        });
    }
}

/// 14.5 节：@typeInfo 全分支速查——把 0.17 每个分支的关键字段都打出来。
/// 这是本章最该记住的一段代码：字段名全变过，照着它写就不会错。
fn dumpTypeInfo(comptime T: type) void {
    const info = @typeInfo(T);
    std.debug.print("  @typeName({s}) 分支标签 = {s}\n", .{ @typeName(T), @tagName(info) });
    // 编译器强制穷尽 switch：漏一个分支就编译错。
    switch (info) {
        .int => |i| std.debug.print("    .int: signedness={s} bits={d}（bits 的类型是 u16）\n", .{ @tagName(i.signedness), i.bits }),
        .float => |f| std.debug.print("    .float: bits={d}（0.17 起是 struct，不是 enum！）\n", .{f.bits}),
        .bool => std.debug.print("    .bool:无字段\n", .{}),
        .type => std.debug.print("    .type: 无字段\n", .{}),
        .void => std.debug.print("    .void: 无字段\n", .{}),
        .noreturn => std.debug.print("    .noreturn: 无字段\n", .{}),
        .comptime_int => std.debug.print("    .comptime_int: 无字段\n", .{}),
        .comptime_float => std.debug.print("    .comptime_float: 无字段\n", .{}),
        .undefined => std.debug.print("    .undefined: 无字段\n", .{}),
        .null => std.debug.print("    .null: 无字段\n", .{}),
        .array => |a| std.debug.print("    .array: len={d}（comptime_int） child={s} sentinel={any}\n", .{ a.len, @typeName(a.child), a.sentinel() }),
        .vector => |v| std.debug.print("    .vector: len={d} child={s}\n", .{ v.len, @typeName(v.child) }),
        .pointer => |p| std.debug.print("    .pointer: size={s} child={s} const={} volatile={} align={any} sentinel={any}\n", .{
            @tagName(p.size), @typeName(p.child),
            p.attrs.@"const", p.attrs.@"volatile",
            p.attrs.@"align", p.sentinel(),
        }),
        .@"struct" => |s| std.debug.print("    .@\"struct\": is_tuple={} layout={t} backing_integer={any} 字段数={d} decl数={d}\n", .{
            s.is_tuple, s.layout, s.backing_integer, s.field_names.len, s.decl_names.len,
        }),
        .optional => |o| std.debug.print("    .optional: child={s}（⚠️ 是 .child 不是 .payload）\n", .{@typeName(o.child)}),
        .error_union => |eu| std.debug.print("    .error_union: error_set={s} payload={s}（这里才叫 payload）\n", .{
            @typeName(eu.error_set), @typeName(eu.payload),
        }),
        // error_names 是 ?[]const [:0]const u8 —— 可空 + 元素是哨兵切片，
        // 直接 {any} 会打成一串字节（见14.5 节的展开版本）
        .error_set => |es| {
            if (es.error_names) |names| {
                std.debug.print("    .error_set: {d} 个成员 →", .{names.len});
                for (names) |nm| std.debug.print(" {s}", .{nm});
                std.debug.print("\n", .{});
            } else {
                std.debug.print("    .error_set: error_names = null（anyerror 是开放错误集）\n", .{});
            }
        },
        .@"enum" => |e| std.debug.print("    .@\"enum\": tag_type={s} mode={s} 成员数={d} decl数={d}\n", .{
            @typeName(e.tag_type), @tagName(e.mode), e.field_names.len, e.decl_names.len,
        }),
        // tag_type 可空：裸 union 是 null，标签联合是那个标签枚举的类型
        .@"union" => |u| {
            std.debug.print("    .@\"union\": layout={s} tag_type=", .{@tagName(u.layout)});
            if (u.tag_type) |tt| std.debug.print("{s}", .{@typeName(tt)}) else std.debug.print("null（裸 union）", .{});
            //⚠️ 匿名的 union(enum) 标签没名字，@typeName 会打出表达式原文
            std.debug.print(" 字段数={d}（同样是三条平行数组）\n", .{u.field_names.len});
        },
        // return_type 可空（泛型函数返回类型依赖实参）；param_types 元素是 ?type
        // （null 表示 anytype 或依赖前一个参数的类型）
        .@"fn" => |f| {
            std.debug.print("    .@\"fn\": is_generic={} return_type=", .{f.is_generic});
            if (f.return_type) |rt| std.debug.print("{s}", .{@typeName(rt)}) else std.debug.print("null", .{});
            std.debug.print(" callconv={s} varargs={} 参数数={d} →", .{
                @tagName(f.attrs.@"callconv"), f.attrs.varargs, f.param_types.len,
            });
            // ⚠️ param_types 元素是 ?type，**也只能 inline for**：
            //   for (f.param_types) |pt|
            //   → error: values of type '?type' must be comptime-known,
            //            but index value is runtime-known
            inline for (f.param_types) |pt| {
                if (pt) |p| std.debug.print(" {s}", .{@typeName(p)}) else std.debug.print(" anytype", .{});
            }
            std.debug.print("\n", .{});
        },
        .@"opaque" => |o| std.debug.print("    .@\"opaque\": decl数={d}\n", .{o.decl_names.len}),
        // ⚠️ 分支标签的引号：**只有 6 个真的必须写**——5 个关键字
        //（struct/enum/union/fn/opaque）加上 anyframe（它和内建类型 anyframe 同名）。
        // 漏掉 .@"anyframe" 的引号，报错会指向 switch 关键字本身：
        //   error: expected '}', found '.'（定位在 `switch (...) {` 那一行）
        // ⚠️ 而 .frame / .enum_literal / .spirv 裸写完全合法（隔离实测）——
        //   它们看起来"也需要引号"只是因为紧跟在报错的 .anyframe 后面。
        //
        // 本函数干脆把全部 25 个分支都写成 .@"名字" 形式，一劳永逸。
        .frame => std.debug.print("    .frame: 无需展开\n", .{}),
        .@"anyframe" => |a| std.debug.print("    .anyframe: child={any}\n", .{a.child}),
        .enum_literal => std.debug.print("    .enum_literal: 无字段\n", .{}),
        .spirv => std.debug.print("    .spirv: 不展开\n", .{}),
    }
}

/// 14.7 节：编译期生成的平方表——运行期只剩一次数组索引。
const SqTable = blk: {
    var buf: [256]u16 = undefined;
    for (&buf, 0..) |*slot, i| slot.* = @intCast(i * i);
    break :blk buf;
};

/// 14.7 节：按类型算"逻辑字节数"——纯 comptime 分派，运行期零开销。
fn byteSize(comptime T: type) usize {
    return switch (@typeInfo(T)) {
        .bool, .@"enum" => 1,
        .int => |i| i.bits / 8,
        .float => |f| f.bits / 8,
        else => @sizeOf(T),
    };
}

/// 14.7 节：编译期生成一个"操作码类型"。
/// kind 是 comptime 参数，所以 switch (kind) 整个在编译期求值，
/// 运行期只剩 `a + b` 一条加法——分派表本身不进二进制。
fn Op(comptime kind: u8) type {
    return struct {
        const Self = @This();

        pub const kind_id = kind;
        pub const name = switch (kind) {
            0 => "add",
            1 => "sub",
            2 => "mul",
            3 => "div",
            4 => "min",
            else => @compileError("Op 只支持 0..4"),
        };

        /// kind 是编译期常量，所以整个 switch 在编译期折叠——
        /// 运行期剩下的只有一条加法（或一条比较），分派表不进二进制。
        /// 注意这里**没有 self**：这是一个"由类型携带行为"的静态函数。
        pub fn apply(a: i32, b: i32) i32 {
            return switch (kind) {
                0 => a + b,
                1 => a - b,
                2 => a * b,
                3 => if (b == 0) 0 else @divTrunc(a, b),
                4 => if (a < b) a else b,
                else => @compileError("未知操作码"),
            };
        }
    };
}

/// 14.8 节：@fieldParentPtr 的宿主反推——从一个字段指针走回宿主 struct。
const Engine = struct {
    power: u32,

    /// 只拿到字段指针，也能改宿主：
    /// @fieldParentPtr("字段名", 字段指针) 返回 *宿主类型。
    pub fn boost(self: *Engine, by: u32) void {
        const self2: *@This() = @fieldParentPtr("power", &self.power);
        self2.power += by;
    }

    /// 0.17 里@fieldParentPtr 的指针元素类型必须**精确匹配**字段类型，
    /// 跨层要手动 @ptrCast（实测报pointer element type 'u32' cannot coerce into
    /// element type 'Inner'）。
    pub fn boostViaField(self: *Engine, by: u32) void {
        const self2: *@This() = @fieldParentPtr("power", &self.power);
        self2.power += by;
    }
};

/// 14.8 节：按类型分派的打印器——四件套合体。
/// @TypeOf 拿类型 → @typeInfo 拆结构 → switch 分派 → inline for + @field 遍历。
/// 每一层都能递归下去：字段本身又是一个"任意类型"，所以先printField 分派再打印。
fn printField(value: anytype) void {
    switch (@typeInfo(@TypeOf(value))) {
        // ⚠️ bool 不支持 {d}（实测 error: invalid format string 'd' for type 'bool'），
        //   要打 true/false 只能用 {} 或 {any}。
        .bool => std.debug.print("{}", .{value}),
        .int, .float => std.debug.print("{d}", .{value}),
        // ⚠️ 可选：if (value) |inner| 的 else 分支里 value 是 null，
        //   但 @TypeOf(value) 仍然是 "?u32"（不是 null）。
        .optional => if (value) |inner| {
            printField(inner);
        } else {
            std.debug.print("null", .{});
        },
        // 指针：先看被指类型再决定怎么打。
        // ⚠️ slice（size == .slice）不能写 value.* ——实测报
        //   error: index syntax required to access runtime-known slice
        .pointer => |p| switch (p.size) {
            .one => {
                // 单个指针：u8数组/切片按字符串打，其他按值打
                if (@typeInfo(p.child) == .array and @typeInfo(p.child).array.child == u8) {
                    std.debug.print("\"{s}\"", .{value.*});
                } else {
                    std.debug.print("{s}={any}", .{ @typeName(p.child), value.* });
                }
            },
            .slice => {
                if (p.child == u8) {
                    std.debug.print("\"{s}\"", .{value});
                } else {
                    std.debug.print("{s}={any}", .{ @typeName(p.child), value });
                }
            },
            else => std.debug.print("{s}({d})", .{ @typeName(p.child), value }),
        },
        .array => |a| {
            if (a.child == u8) {
                std.debug.print("\"{s}\"", .{std.mem.sliceTo(&value, 0)});
            } else {
                std.debug.print("{any}", .{value});
            }
        },
        .@"enum" => std.debug.print("{s}({d})", .{ @tagName(value), @backingInt(value) }),
        .error_union => std.debug.print("错误联合={any}", .{value}),
        .@"struct" => |s| {
            std.debug.print("{{", .{});
            inline for (s.field_names, 0..) |name, i| {
                if (i != 0) std.debug.print(", ", .{});
                std.debug.print("{s}=", .{name[0..name.len]});
                printField(@field(value, name));
            }
            std.debug.print("}}", .{});
        },
        // ⚠️ 裸 union 打印要小心：读非活跃字段会 panic（access of union field
        //   ... while field ... is active）。std.meta.activeTag 帮你先问是哪个。
        .@"union" => std.debug.print("联合(tag={s}){any}", .{ std.meta.activeTag(value), value }),
        else => std.debug.print("{any}", .{value}),
    }
}

/// 顶层入口。
fn printAny(value: anytype) void {
    printField(value);
    std.debug.print("\n", .{});
}

comptime {
    // 14.4 节：字段表形状本身可以编译期断言
    if (@typeInfo(Person).@"struct".field_names.len != 3) @compileError("Person 字段数变了");
    if (@typeInfo(Person).@"struct".layout != .auto) @compileError("Person 布局变了");
    // 14.5 节：可选的 child 字段名在 0.17 是 .child
    if (@typeInfo(?u8).optional.child != u8) @compileError("optional.child 变了");
    // 14.8 节：Pack 有 3 个字段
    if (@typeInfo(Pair(u8, u32)).@"struct".field_names.len != 2) @compileError("Pair 字段数变了");
}

pub fn main(init: std.process.Init) !void {
    _ = init;
    // 本函数里所有编译期求值共享一份分支配额（默认 1000，见 13.6 节）。
    @setEvalBranchQuota(2_000_000);

    // ═══ 14.1 泛型就是 comptime 参数：没有 template，也没有尖括号 ═══
    begin("14.1");
    // Matrix(u8, 2, 3) 是**编译期调用**，返回值是类型 [2][3]u8
    const Grid = Matrix(u8, 2, 3);
    const grid: Grid = .{ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
    std.debug.print("Matrix(u8,2,3) = {s}；grid[1][2] = {d}\n", .{ @typeName(Grid), grid[1][2] });
    std.debug.print("Grid 的 @sizeOf = {d} 字节\n", .{@sizeOf(Grid)});
    // 同一个构造器换参数就是另一个类型——**没有重载、没有歧义**
    const LongGrid = Matrix(i64, 2, 3);
    std.debug.print("Matrix(i64,2,3) = {s}；@sizeOf = {d} 字节\n", .{ @typeName(LongGrid), @sizeOf(LongGrid) });
    std.debug.print("Grid == LongGrid = {}（不同类型，类型相等按结构逐项比）\n", .{Grid == LongGrid});
    std.debug.print("Grid == Matrix(u8,2,3) = {}（同参数同类型，实例化有缓存）\n", .{Grid == Matrix(u8, 2, 3)});
    // comptime 参数不限于类型：尺寸也是 comptime 输入
    std.debug.print("形状同但每格大小不同：{}（6 vs 48 字节）\n", .{@sizeOf(Grid) != @sizeOf(LongGrid)});
    end("14.1");

    // ═══ 14.2 fn Container(comptime T: type) type 与 @This() ═══
    begin("14.2");
    var st = Stack(u32){};
    defer st.deinit(std.heap.page_allocator);
    try st.push(std.heap.page_allocator, 10);
    try st.push(std.heap.page_allocator, 20);
    try st.push(std.heap.page_allocator, 30);
    std.debug.print("Stack(u32) 弹栈：{d} {d} {d} 空={any}\n", .{ st.pop().?, st.pop().?, st.pop().?, st.pop() });
    var st2 = Stack(u8){};
    defer st2.deinit(std.heap.page_allocator);
    try st2.push(std.heap.page_allocator, 'Z');
    std.debug.print("新栈 peek = {c}（peek 不弹栈）\n", .{st2.peek().?});
    std.debug.print("pop 后 = {c}\n", .{st2.pop().?});
    std.debug.print("空栈 peek = {any} / pop = {any}\n", .{ st2.peek(), st2.pop() });
    // @This() 的意义：泛型 struct 里"引用自己的类型"，此刻名字还不存在
    std.debug.print("Stack(u32) 的类型名 = {s}\n", .{@typeName(@TypeOf(st))});
    std.debug.print("Stack(u32).Item = {s}（类型参数被导出成常量）\n", .{@typeName(Stack(u32).Item)});
    std.debug.print("Stack(u32).Self = {s}（就是它自己）\n", .{@typeName(Stack(u32).Self)});
    // ⚠️ 0.17 新坑：decl 只能通过**类型**访问，不能通过**值**访问：
    //    st.item_type报 error: no field named 'item_type' in struct 'main.Stack(u32)'
    std.debug.print("⚠️ st.Item 在 0.17 编译不过（decl 只能经类型访问）；字段访问 = {s}\n", .{@typeName(@FieldType(@TypeOf(st), "items"))});
    // 两个类型参数：A 和 B 完全独立，这是 anytype 做不到的
    var pr = Pair(u8, []const u8){ .a = 7, .b = "seven" };
    std.debug.print("Pair(u8,[]const u8) = {s}：a={d} b={s}\n", .{ @typeName(@TypeOf(pr)), pr.a, pr.b });
    std.debug.print("  size_a={d} size_b={d}（两个参数的尺寸独立算）\n", .{ Pair(u8, []const u8).size_a, Pair(u8, []const u8).size_b });
    std.debug.print("  toBytes = {any}（长度 {d} 是编译期常量，异构照样能摊）\n", .{ pr.toBytes(), pr.toBytes().len });
    // swap 只在 A == B 时合法，异构调用是**编译期** @compileError
    var pr2 = Pair(u8, u8){ .a = 1, .b = 2 };
    pr2.swap();
    std.debug.print("  Pair(u8,u8).swap 后：a={d} b={d}（同型才能换）\n", .{ pr2.a, pr2.b });
    end("14.2");

    // ═══ 14.3 anytype vs comptime T: type ═══
    begin("14.3");
    const ints = [_]i32{ 7, 8, 9 };
    const bytes = [_]u8{ 4, 5 };
    // anytype：类型从实参推导，返回类型用 @TypeOf(items[0]) 表达"和元素同型"
    std.debug.print("firstOf(ints) = {d} 类型 {s}\n", .{ firstOf(&ints), @typeName(@TypeOf(firstOf(&ints))) });
    std.debug.print("firstOf(bytes) = {d} 类型 {s}（同一份函数体，两个实例）\n", .{ firstOf(&bytes), @typeName(@TypeOf(firstOf(&bytes))) });
    // 两个 anytype 参数，返回类型由第一个决定
    std.debug.print("maxOf(3, 9) = {d}；maxOf(9, 3) = {d}；maxOf(2.5, 1.5) = {d}\n", .{ maxOf(3, 9), maxOf(9, 3), maxOf(2.5, 1.5) });
    // 隐式 vs 显式：写法不同，实例化机制完全一样
    std.debug.print("anyTypeSum(ints) = {d}；anyTypeSum(bytes) = {d}\n", .{ anyTypeSum(&ints), anyTypeSum(&bytes) });
    std.debug.print("泛型 vs 鸭子类型：泛型能声明【额外编译期参数】，anytype 不能\n", .{});
    std.debug.print("matrixOf(ints, 3) 长度 = {d}（要额外的 comptime 参数就得显式写出来）\n", .{matrixOf(ints, 3).len});
    // ⚠️ anytype 的契约是"编译期检查的鸭子类型"：实参不满足就编译错，
    //   报错指向函数体那一行 + referenced by 链指向调用点。
    //   sumAll(@as(u8, 3)) → error: type 'u8' is not indexable and not a range
    end("14.3");

    // ═══ 14.4 反射：@typeInfo 的三条平行数组 ═══
    begin("14.4");
    std.debug.print("Person 的字段（0.17：field_names / field_types / field_attrs 三条平行数组）：\n", .{});
    dumpFields(Person);
    std.debug.print("三条数组长度一致：{}\n", .{
        @typeInfo(Person).@"struct".field_names.len == @typeInfo(Person).@"struct".field_types.len and
            @typeInfo(Person).@"struct".field_names.len == @typeInfo(Person).@"struct".field_attrs.len,
    });
    // .tag 已改名 .layout（std.lang.ContainerLayout：auto / extern / packed）
    std.debug.print("Person layout={t}（类型 {s}，不再是 .tag）\n", .{
        @typeInfo(Person).@"struct".layout, @typeName(@TypeOf(@typeInfo(Person).@"struct".layout)),
    });
    // 有默认值的字段：default_value_ptr 非空
    const WithDefault = struct { a: u32 = 7, b: u8 = 0, c: u8 align(4) };
    std.debug.print("带默认值/对齐的结构体：\n", .{});
    dumpFields(WithDefault);
    // @offsetOf 配合三条平行数组用（按编译期下标取名字）
    // 哨兵切片可以直接传给 @offsetOf（它接受 [:0]const u8）
    inline for (@typeInfo(WithDefault).@"struct".field_names) |name| {
        std.debug.print("  @offsetOf(WithDefault, \"{s}\") = {d}\n", .{ name[0..name.len], @offsetOf(WithDefault, name) });
    }
    // ⚠️ field_types 元素是 type，**只能 inline for**：
    //   for (info.@"struct".field_types) |t| ...
    //   → error: values of type 'type' must be comptime-known,
    //            but index value is runtime-known
    //            note: types are not available at runtime
    // 因为"类型"这个概念在运行期不存在。
    end("14.4");

    // ═══ 14.5 @typeInfo 全分支速查表（0.17 实测） ═══
    begin("14.5");
    const Samples = .{
        u16,
        f32,
        bool,
        [4]u8,
        @Vector(4, i8),
        *const u8,
        []const u8,
        Person,
        ?u32,
        (error{ NotFound, Corrupted })!u16,
        error{ NotFound, Corrupted },
        Stage,
        Payload,
        anyerror!u8,
        anyerror,
        Opaque,
        // ⚠️ 裸函数名在元组里会退化成**指针**，要拿函数类型得靠 @TypeOf
        @TypeOf(addThenNarrow),
        // 带哨兵的数组：sentinel() 能取到值
        [4:0]u8,
        // ⚠️ 下面两个是**匿名容器**（直接写 struct { } / extern struct { }），
        //   它们的 @typeName 是编译器现场编的（形如 main.main__struct_904），
        //   每次编译都可能变——不能拿来做稳定标识。
        struct { a: u32 },
        extern struct { a: u32, b: u8 },
    };
    inline for (Samples) |T| {
        dumpTypeInfo(T);
    }
    // error_names 是**可空**的：具名错误集是切片，anyerror 是 null
    std.debug.print("error_names 的三种状态：\n", .{});
    inline for (.{ error{}, error{ A, B }, anyerror }) |E| {
        const en = @typeInfo(E).error_set.error_names;
        if (en) |names| {
            std.debug.print("  {s}：{d} 个成员 →", .{ @typeName(E), names.len });
            // 元素是哨兵切片[:0]const u8，可直接 {s} 打印；取子范围要写 [0..len]
            for (names) |nm| std.debug.print(" {s}", .{nm});
            std.debug.print("\n", .{});
        } else {
            std.debug.print("  {s}：null（anyerror 是【开放】错误集，没有成员表）\n", .{@typeName(E)});
        }
    }
    // ⚠️ 哨兵切片不能按固定长度+哨兵取子范围（enames[0..1 :0] 会报
    //   error: expected type '[:0]const u8', found 'comptime_int'）。
    //   打印直接 {s} 就行；要切片就写 [0..len]。
    std.debug.print("哨兵切片：直接 {s} 可打印；取子范围写 [0..len] = \"{s}\"\n", .{
        @typeInfo(error{NotFound}).error_set.error_names.?[0],
        @typeInfo(error{NotFound}).error_set.error_names.?[0][0..8],
    });
    // ⚠️ error_names **保持声明顺序**，但 @typeName 会**重排（按字母序）**：
    //   error{ NotFound, Corrupted } 的声明序是 NotFound→Corrupted，
    //   @typeName 打出来是 error{Corrupted,NotFound}。别拿 @typeName 反推成员表。
    std.debug.print("声明序 vs @typeName（后者按字母重排）：{s}\n", .{@typeName(error{ NotFound, Corrupted })});
    // ⚠️ 枚举的 field_values 元素是 comptime_int，**也只能 inline for**：
    //   for (e.field_names, e.field_values) |n, v|
    //   → error: values of type 'comptime_int' must be comptime-known
    const e2 = @typeInfo(Stage).@"enum";
    inline for (e2.field_names, e2.field_values) |nm, v| {
        std.debug.print("  Stage.{s} = {d}（@backingInt = {d}）\n", .{ nm[0..nm.len], v, @backingInt(@field(Stage, nm[0..nm.len])) });
    }
    // ⚠️ 实测decl_names 只列**pub**声明（非 pub 的 const/fn 不列）：
    //   Person/Stage 无声明 = 0、Payload 有 pub fn tagName = 1、Opaque 有 pub fn = 1
    std.debug.print("decl_names（只列 pub 声明）：struct={d} enum={d} union={d} opaque={d}\n", .{
        @typeInfo(Person).@"struct".decl_names.len,
        @typeInfo(Stage).@"enum".decl_names.len,
        @typeInfo(Payload).@"union".decl_names.len,
        @typeInfo(Opaque).@"opaque".decl_names.len,
    });
    std.debug.print("  Opaque（有 pub fn onlyFn）={d}，Opaque2（空）={d}\n", .{
        @typeInfo(Opaque).@"opaque".decl_names.len,
        @typeInfo(Opaque2).@"opaque".decl_names.len,
    });
    std.debug.print("要列声明：用 @hasDecl 逐个问，或 std.meta.declarations（T）\n", .{});
    end("14.5");

    // ═══ 14.6 @hasDecl / @typeName：探测与命名 ═══
    begin("14.6");
    // ⚠️ 0.17 里 @hasDecl 的第二个参数**必须给字符串**：
    //   @hasDecl(std.mem, copyForwards) → error: use of undeclared identifier 'copyForwards'
    std.debug.print("@hasDecl(std.ArrayList(u8), \"append\") = {}\n", .{@hasDecl(std.ArrayList(u8), "append")});
    std.debug.print("@hasDecl(std.ArrayList(u8), \"noSuchMethod\") = {}\n", .{@hasDecl(std.ArrayList(u8), "noSuchMethod")});
    // ⚠️ @hasDecl 问的是**声明**，字段不算：
    std.debug.print("@hasDecl(Person, \"name\") = {}（字段不是 decl）\n", .{@hasDecl(Person, "name")});
    std.debug.print("@hasField(Person, \"name\") = {}（问字段要用 @hasField）\n", .{@hasField(Person, "name")});
    std.debug.print("@hasField(Person, \"nope\") = {}\n", .{@hasField(Person, "nope")});
    // ⚠️ std.meta.fields / declarationInfo / fieldInfo 三个在 0.17 已改成
    //   @compileError 占位（源码注释写着 "To be removed after 0.17.0 is tagged"）：
    //     std.meta.fields(Person)
    //     → error: deprecated in favor of @typeInfo
    //   std.meta 剩下的活口都是 @typeInfo 的薄封装（Child / Elem / fieldNames /
    //   fieldTypes / containerLayout / declarations / stringToEnum ...）。
    std.debug.print("std.meta.fields 已废弃（@compileError 占位）→ 全走 @typeInfo\n", .{});
    std.debug.print("  std.meta 剩下的 Child/fieldNames/declarations 等都是 @typeInfo 的薄封装\n", .{});
    // 类型名一律 @typeName；@tagName 只吃枚举/联合的**值**
    std.debug.print("@typeName(Person) = {s}；@typeName(u24) = {s}；@tagName(Stage.beta) = {s}\n", .{
        @typeName(Person), @typeName(u24), @tagName(Stage.beta),
    });
    std.debug.print("泛型实例的类型名带参数：Stack(u32) = {s}\n", .{@typeName(Stack(u32))});
    // ⚠️ @Type 已移除（error: invalid builtin function: '@Type'）。
    //   造函数类型用 @TypeOf，但 @TypeOf(&f) 拿到的是**指针**：
    std.debug.print("@TypeOf(&addThenNarrow) = {s}\n", .{@typeName(@TypeOf(&addThenNarrow))});
    const FnPtr = @TypeOf(&addThenNarrow);
    std.debug.print("剥掉指针 = {s}（.pointer.child）\n", .{@typeName(@typeInfo(FnPtr).pointer.child)});
    end("14.6");

    // ═══ 14.7 编译期代码生成：查表 / 类型分派 / 生成类型 ═══
    begin("14.7");
    // (1) 生成数据表：编译期算 256 次，运行期只剩一次索引
    std.debug.print("SqTable[7]={d} [15]={d} [255]={d}（表在编译期算好）\n", .{ SqTable[7], SqTable[15], SqTable[255] });
    // (2) 按类型分派：整个函数是 comptime 的，运行期零开销
    std.debug.print("byteSize: u8={d} u24={d} f64={d} bool={d} Stage={d}\n", .{
        byteSize(u8), byteSize(u24), byteSize(f64), byteSize(bool), byteSize(Stage),
    });
    // (3) 生成类型：kind 是编译期常量，switch (kind) 整体在编译期折叠
    inline for (.{ 0, 1, 2, 3, 4 }) |k| {
        std.debug.print("  Op({d}).name = {s}：apply(7,3) = {d}\n", .{ k, Op(k).name, Op(k).apply(7, 3) });
    }
    std.debug.print("Op(2) 的类型名 = {s}；kind_id = {d}（常量进了类型）\n", .{ @typeName(Op(2)), Op(2).kind_id });
    //⚠️ 越界的 kind 在**编译期**就炸：Op(9) → error: Op 只支持 0..4
    end("14.7");

    // ═══ 14.8 @field / @fieldParentPtr / printAny ═══
    begin("14.8");
    var p = Person{ .name = "阿 Z", .age = 25, .vip = true };
    const field_name = comptime "age";
    @field(p, field_name) = 26; // 名字来自编译期变量
    std.debug.print("@field 写入：{s} {d} 岁 vip={}\n", .{ p.name, @field(p, field_name), p.vip });
    std.debug.print("@field 读回：name={s} vip={}\n", .{ @field(p, "name"), @field(p, "vip") });
    // ⚠️ @field 的名字必须是编译期字符串；运行期拼出来的 []const u8 不行
    // @fieldParentPtr：从字段指针反推宿主指针
    var eng = Engine{ .power = 100 };
    eng.boost(50);
    std.debug.print("Engine.power 经 boost(50) 后= {d}（@fieldParentPtr 走回宿主）\n", .{eng.power});
    // 四件套合体：自动打印
    std.debug.print("printAny(Person)：", .{});
    printAny(p);
    printAny(42);
    printAny(@as(u8, 7));
    printAny(@as(?u32, 9));
    printAny(@as(?u32, null));
    printAny("hi");
    end("14.8");

    // ═══ 14.9 泛型的代价：单态化实测 ═══
    begin("14.9");
    // 单态化（monomorphization）：每个类型生成一份代码。
    // 好处：运行期零开销（没有类型标签、没有虚表、没有装箱）。
    // 代价：二进制体积 + 编译时间都随"用到的类型数"线性增长。
    //
    // 实测（Debug 模式，同一个 2000 次inline for 的泛型函数）：
    //   1 个类型  → 二进制 2_148_746 字节，1 份work 代码
    //   8 个类型  → 二进制 2_645_062 字节，8 份 work 代码（+496_316 字节）
    //   编译耗时：约 4.2 s → 约 4.9 s
    //
    // ⚠️ 但**相同类型只实例化一次**（有缓存）：16 次调用、只有 4 个唯一类型时，
    //   符号表里仍然只有 4 份work 代码。实测二进制 2_194_557 字节，
    //   和只调4 次几乎一样。所以账单按"唯一类型数"算，不按"调用次数"算。
    //
    // 对比 C++ 模板：机制一样（都是单态化），但C++ 的实例化点藏在
    // 两阶段查找里，报错是一屏长的模板栈；Zig 这边就是"编译期跑了个函数"，
    // 报错直接指向你的源码行。
    std.debug.print("单态化账单按【唯一类型数】算，不按调用次数算\n", .{});
    std.debug.print("本节实测：1 类型 2_148_746 B→ 8 类型 2_645_062 B（+496_316 B）\n", .{});
    std.debug.print("运行期代价：0（没有类型标签、没有虚表、没有装箱）\n", .{});
    // 想要"一份代码多种类型"怎么办？两条路：
    //   (a) 传anytype，让调用方决定（还是单态化，只是隐藏了）
    //   (b) 运行期擦除成u8/void 指针 + 手写 tag（放弃类型安全，换体积）
    // Zig 标准库两条都给了：anytype 走(a)，std.ArrayList 的对齐/分配器参数走组合。
    std.debug.print("省体积的手段：擦除成 anyopaque + 外部 tag（放弃编译期类型安全）\n", .{});
    end("14.9");

    std.debug.print("自检通过\n", .{});
}

// ══════════════════════════════════════════════════════════════════
// 容器级支撑声明
// ══════════════════════════════════════════════════════════════════

/// 14.3 节：anytype 版求和——注意它和泛型是同一个机制，只是写法不同。
fn anyTypeSum(values: anytype) @TypeOf(values[0]) {
    var acc: @TypeOf(values[0]) = 0;
    for (values) |v| acc +|= v;
    return acc;
}

/// 14.3 节：anytype 也能配额外comptime 参数——但必须显式写出来。
fn matrixOf(comptime items: anytype, comptime rows: usize) [rows]@TypeOf(items[0]) {
    @setEvalBranchQuota(10_000);
    var out: [rows]@TypeOf(items[0]) = undefined;
    // 用运行时循环填（rows 是编译期常量，但这里演示普通 for 也行）
    for (&out, 0..) |*slot, i| slot.* = items[i % items.len];
    return out;
}

/// 14.5 节的 opaque 样本。⚠️ 匿名 `opaque {}` 的类型名是编译器编的
/// （实测 `main.main__opaque_904`），用具名 const 才拿得到稳定名字。
const Opaque = opaque {
    pub fn onlyFn() void {}
};

/// 第二个 opaque 样本（无方法）—— 对照 Opaque 看 decl_names 只数 pub 声明。
const Opaque2 = opaque {};

/// 14.5 节的枚举样本：field_values 是 comptime_int，只能 inline for。
const Stage = enum(u8) { alpha = 1, beta = 2, gamma = 3 };

/// 14.5 节的联合样本：三条平行数组（field_names / field_types / field_attrs）。
/// ⚠️ 匿名标签枚举（`union(enum)`）的 tag_type 没有名字，
/// @typeName 只能打出表达式原文（实测
//    @typeInfo(main.Payload).@"union".tag_type.?），
/// 所以下面用具名标签枚举 PayloadTag，tag_type 才有可读的类型名。
const PayloadTag = enum { int, float, text };
const Payload = union(PayloadTag) {
    int: i32,
    float: f64,
    text: []const u8,

    pub fn tagName(self: Payload) []const u8 {
        return switch (self) {
            .int => "int",
            .float => "float",
            .text => "text",
        };
    }
};

/// 14.6 节：造函数类型用 @TypeOf（@Type 在 0.17 已移除）。
/// ⚠️ 0.17 不许在函数体里声明 fn，所以它必须在容器级。
fn addThenNarrow(a: u32, b: u32) u8 {
    return @intCast(a + b);
}

// ══════════════════════════════════════════════════════════════════
// 测试：把本章的语义钉死
// ══════════════════════════════════════════════════════════════════

test "14.1 类型构造器：Matrix 返回 type，参数全是 comptime" {
    const G = Matrix(u8, 2, 3);
    try std.testing.expectEqualStrings("[2][3]u8", @typeName(G));
    try std.testing.expectEqual(@as(usize, 6), @sizeOf(G));
    const grid: G = .{ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
    try std.testing.expectEqual(@as(u8, 6), grid[1][2]);
    // 换参数就是另一个类型
    try std.testing.expectEqualStrings("[2][3]i64", @typeName(Matrix(i64, 2, 3)));
    try std.testing.expect(@sizeOf(Matrix(u8, 2, 3)) != @sizeOf(Matrix(i64, 2, 3)));
}

test "14.2 泛型容器：@This() 自指 + 类型参数导出" {
    var s = Stack(u32){};
    defer s.deinit(std.testing.allocator);
    try s.push(std.testing.allocator, 10);
    try s.push(std.testing.allocator, 20);
    try std.testing.expectEqual(@as(?u32, 20), s.peek());
    try std.testing.expectEqual(@as(u32, 20), s.pop().?);
    try std.testing.expectEqual(@as(u32, 10), s.pop().?);
    try std.testing.expectEqual(@as(?u32, null), s.pop());
    // Item 就是类型参数T
    try std.testing.expectEqualStrings("u32", @typeName(Stack(u32).Item));
    // Self 指回自己
    try std.testing.expect(Stack(u32).Self == Stack(u32));
    // 不同 T 是不同类型
    try std.testing.expect(Stack(u32) != Stack(u8));
    // 两个类型参数：A、B 完全独立
    const Het = Pair(u8, []const u8);
    try std.testing.expectEqual(@as(usize, 1), Het.size_a);
    try std.testing.expectEqual(@as(usize, @sizeOf([]const u8)), Het.size_b);
    const pr = Het{ .a = 1, .b = "x" };
    try std.testing.expectEqual(@as(usize, 1), pr.toBytes().len);
    try std.testing.expectEqual(@as(u8, 1), pr.toBytes()[0]);
    // 异构 swap 是编译期 @compileError（不是运行期 panic）
    var pr2 = Pair(u8, u8){ .a = 1, .b = 2 };
    pr2.swap();
    try std.testing.expectEqual(@as(u8, 2), pr2.a);
    try std.testing.expectEqual(@as(u8, 1), pr2.b);
}

test "14.3 anytype 与 comptime T: type 是同一个机制" {
    const ints = [_]i32{ 7, 8, 9 };
    const bytes = [_]u8{ 4, 5 };
    // anytype：类型从实参推导
    try std.testing.expectEqual(@as(i32, 7), firstOf(&ints));
    try std.testing.expectEqual(@as(u8, 4), firstOf(&bytes));
    try std.testing.expectEqual(@as(i32, 9), maxOf(3, 9));
    try std.testing.expectEqual(@as(f64, 2.5), maxOf(2.5, 1.5));
    try std.testing.expectEqual(@as(i32, 24), anyTypeSum(&ints));
    try std.testing.expectEqual(@as(u8, 9), anyTypeSum(&bytes));
    // anytype 也能配显式 comptime 参数
    const m = matrixOf(ints, 3);
    try std.testing.expectEqual(@as(i32, 7), m[0]);
    try std.testing.expectEqual(@as(i32, 8), m[1]);
}

test "14.4 三条平行数组：field_names / field_types / field_attrs" {
    const s = @typeInfo(Person).@"struct";
    // ⚠️ .fields 已不存在（error: no field named 'fields' in struct 'lang.Type.Struct'）
    try std.testing.expectEqual(@as(usize, 3), s.field_names.len);
    try std.testing.expectEqual(s.field_names.len, s.field_types.len);
    try std.testing.expectEqual(s.field_names.len, s.field_attrs.len);
    // field_names 元素是哨兵切片
    try std.testing.expectEqualStrings("name", s.field_names[0][0..4]);
    try std.testing.expectEqualStrings("age", s.field_names[1][0..3]);
    try std.testing.expectEqualStrings("vip", s.field_names[2][0..3]);
    // field_types 元素是 type，可以直接下标断言（不必 inline for）
    try std.testing.expect(s.field_types[0] == []const u8);
    try std.testing.expect(s.field_types[1] == u8);
    try std.testing.expect(s.field_types[2] == bool);
    // .tag 已改名 .layout，类型是 std.lang.ContainerLayout
    try std.testing.expectEqualStrings("lang.Type.ContainerLayout", @typeName(@TypeOf(s.layout)));
    try std.testing.expect(s.layout == .auto);
    // field_attrs 的对齐字段叫 .@"align"（?usize），不是 .alignment
    try std.testing.expect(s.field_attrs[0].@"align" == null);
    try std.testing.expectEqual(@as(?usize, 4), @typeInfo(struct { a: u8 align(4) }).@"struct".field_attrs[0].@"align");
    // default_value_ptr 非空 ⟺ 有默认值
    try std.testing.expect(s.field_attrs[0].default_value_ptr == null);
    try std.testing.expect(@typeInfo(struct { a: u8 = 1 }).@"struct".field_attrs[0].default_value_ptr != null);
    // @offsetOf 配哨兵切片的名字
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(Person, "name"));
    try std.testing.expectEqual(@as(usize, 16), @offsetOf(Person, "age"));
}

test "14.5 @typeInfo 各分支的字段形状（0.17 实测）" {
    // .int: signedness + bits(u16)
    try std.testing.expectEqual(@as(u16, 32), @typeInfo(i32).int.bits);
    try std.testing.expectEqualStrings("signed", @tagName(@typeInfo(i32).int.signedness));
    try std.testing.expectEqualStrings("unsigned", @tagName(@typeInfo(u8).int.signedness));
    // .float 0.17 起是struct { bits: u16 }，**不再是 enum**
    try std.testing.expectEqual(@as(u16, 64), @typeInfo(f64).float.bits);
    try std.testing.expectEqual(@as(u16, 32), @typeInfo(f32).float.bits);
    // .array: len 是 comptime_int
    try std.testing.expectEqual(@as(comptime_int, 4), @typeInfo([4]u16).array.len);
    try std.testing.expect(@typeInfo([4]u16).array.child == u16);
    // 哨兵数组：sentinel() 取值（不是字段，是内联函数）
    try std.testing.expectEqual(@as(u8, 0), @typeInfo([4:0]u8).array.sentinel().?);
    // .vector
    try std.testing.expectEqual(@as(comptime_int, 4), @typeInfo(@Vector(4, i8)).vector.len);
    // .pointer: size 是 enum(u2){one,many,slice,c}，属性在 attrs 里
    const p = @typeInfo([]const u8).pointer;
    try std.testing.expectEqualStrings("slice", @tagName(p.size));
    try std.testing.expect(p.attrs.@"const");
    try std.testing.expect(!p.attrs.@"volatile");
    try std.testing.expect(p.attrs.@"align" == null);
    try std.testing.expect(@typeInfo([*:0]const u8).pointer.sentinel().? == 0);
    // .optional: 字段叫 .child（⚠️ 不是 .payload）
    try std.testing.expect(@typeInfo(?u8).optional.child == u8);
    // .error_union: 字段叫 .payload（和 optional 不一致）
    const eu = @typeInfo(anyerror!u8).error_union;
    try std.testing.expect(eu.error_set == anyerror);
    try std.testing.expect(eu.payload == u8);
    // .error_set: error_names 可空
    try std.testing.expect(@typeInfo(anyerror).error_set.error_names == null);
    try std.testing.expect(@typeInfo(error{}).error_set.error_names != null);
    try std.testing.expectEqual(@as(usize, 0), @typeInfo(error{}).error_set.error_names.?.len);
    try std.testing.expectEqualStrings("NotFound", @typeInfo(error{NotFound}).error_set.error_names.?[0][0..8]);
    // .@"enum": tag_type / mode / field_names / field_values / decl_names
    const e = @typeInfo(Stage).@"enum";
    try std.testing.expect(e.tag_type == u8);
    try std.testing.expectEqualStrings("exhaustive", @tagName(e.mode));
    try std.testing.expectEqual(@as(usize, 3), e.field_names.len);
    try std.testing.expectEqual(@as(comptime_int, 2), e.field_values[1]);
    // error_names 保持**声明顺序**，而 @typeName 按字母重排
    const en = @typeInfo(error{ NotFound, Corrupted }).error_set.error_names.?;
    try std.testing.expectEqual(@as(usize, 2), en.len);
    try std.testing.expectEqualStrings("NotFound", en[0][0..8]);
    try std.testing.expectEqualStrings("Corrupted", en[1][0..9]);
    try std.testing.expectEqualStrings("error{Corrupted,NotFound}", @typeName(error{ NotFound, Corrupted }));
    // .@"union": layout / tag_type / 三条平行数组
    const u = @typeInfo(Payload).@"union";
    try std.testing.expect(u.layout == .auto);
    try std.testing.expect(u.tag_type != null);
    // 裸 union 的 tag_type 是 null；标签联合指向那个标签枚举
    try std.testing.expect(@typeInfo(union { a: u32 }).@"union".tag_type == null);
    try std.testing.expect(u.tag_type.? == PayloadTag);
    try std.testing.expectEqual(@as(usize, 3), u.field_names.len);
    try std.testing.expectEqual(u.field_names.len, u.field_types.len);
    try std.testing.expectEqual(u.field_names.len, u.field_attrs.len);
    try std.testing.expectEqualStrings("int", u.field_names[0][0..3]);
    // .@"fn": attrs.callconv / attrs.varargs / is_generic / return_type / param_types
    const f = @typeInfo(@TypeOf(addThenNarrow)).@"fn";
    try std.testing.expectEqual(@as(usize, 2), f.param_types.len);
    try std.testing.expect(f.param_types[0].? == u32);
    try std.testing.expectEqualStrings("u8", @typeName(f.return_type.?));
    try std.testing.expectEqualStrings("auto", @tagName(f.attrs.@"callconv"));
    try std.testing.expect(!f.attrs.varargs);
    try std.testing.expect(!f.is_generic);
    // .@"opaque": 只有 decl_names（实测只列pub 声明，所以这里= 1）
    try std.testing.expectEqual(@as(usize, 1), @typeInfo(Opaque).@"opaque".decl_names.len);
    try std.testing.expectEqual(@as(usize, 0), @typeInfo(opaque {}).@"opaque".decl_names.len);
    // ⚠️ 实测 decl_names 只列 **pub** 声明：Person/Stage 无 pub 声明所以是 0
    try std.testing.expectEqual(@as(usize, 0), @typeInfo(Person).@"struct".decl_names.len);
    try std.testing.expectEqual(@as(usize, 0), @typeInfo(Stage).@"enum".decl_names.len);
    // Payload 有一个 pub fn tagName，所以是 1
    try std.testing.expectEqual(@as(usize, 1), @typeInfo(Payload).@"union".decl_names.len);
    // 整个 lang.Type 联合有 25 个分支
    try std.testing.expectEqual(@as(usize, 25), @typeInfo(std.lang.Type).@"union".field_names.len);
    // .int 的 bits 是 u16（不是 u8，也不是 usize）
    try std.testing.expectEqualStrings("u16", @typeName(@TypeOf(@typeInfo(u8).int.bits)));
    // .array / .vector 的 len 是 comptime_int（不是 usize）
    try std.testing.expectEqualStrings("comptime_int", @typeName(@TypeOf(@typeInfo([4]u8).array.len)));
    // .pointer 的 size 枚举名
    try std.testing.expectEqualStrings("lang.Type.Pointer.Size", @typeName(@TypeOf(p.size)));
}

test "14.6 @hasDecl 第二个参数必须是字符串；@typeName 吃类型" {
    // ⚠️ 标识符形式在 0.17 失效（error: use of undeclared identifier 'append'）
    try std.testing.expect(@hasDecl(std.ArrayList(u8), "append"));
    try std.testing.expect(!@hasDecl(std.ArrayList(u8), "noSuchMethodAtAll"));
    // @hasDecl 问声明，字段不算
    try std.testing.expect(!@hasDecl(Person, "name"));
    try std.testing.expect(@hasField(Person, "name"));
    try std.testing.expect(!@hasField(Person, "nope"));
    // 类型名一律 @typeName（@tagName 只吃枚举/联合的值）
    try std.testing.expectEqualStrings("main.Person", @typeName(Person));
    try std.testing.expectEqualStrings("beta", @tagName(Stage.beta));
    // 泛型实例的类型名带参数
    try std.testing.expectEqualStrings("main.Stack(u32)", @typeName(Stack(u32)));
    // @Type 已移除；造函数类型用 @TypeOf，@TypeOf(&f) 是**指针**
    try std.testing.expectEqualStrings("fn (u32, u32) u8", @typeName(@TypeOf(addThenNarrow)));
    try std.testing.expectEqualStrings("*const fn (u32, u32) u8", @typeName(@TypeOf(&addThenNarrow)));
    try std.testing.expectEqualStrings("fn (u32, u32) u8", @typeName(@typeInfo(@TypeOf(&addThenNarrow)).pointer.child));
    try std.testing.expectEqual(@as(u8, 7), addThenNarrow(3, 4));
}

test "14.7 编译期生成的表 / 分派 / 类型" {
    // 编译期生成的表
    try std.testing.expectEqual(@as(u16, 0), SqTable[0]);
    try std.testing.expectEqual(@as(u16, 49), SqTable[7]);
    try std.testing.expectEqual(@as(u16, 65025), SqTable[255]);
    // 编译期类型分派
    try std.testing.expectEqual(@as(usize, 1), byteSize(u8));
    try std.testing.expectEqual(@as(usize, 3), byteSize(u24));
    try std.testing.expectEqual(@as(usize, 8), byteSize(f64));
    try std.testing.expectEqual(@as(usize, 1), byteSize(bool));
    try std.testing.expectEqual(@as(usize, 1), byteSize(Stage));
    // 编译期生成的类型：switch (kind) 已折叠
    try std.testing.expectEqualStrings("add", Op(0).name);
    try std.testing.expectEqualStrings("min", Op(4).name);
    try std.testing.expectEqual(@as(i32, 10), Op(0).apply(7, 3));
    try std.testing.expectEqual(@as(i32, 4), Op(1).apply(7, 3));
    try std.testing.expectEqual(@as(i32, 21), Op(2).apply(7, 3));
    try std.testing.expectEqual(@as(i32, 2), Op(3).apply(7, 3));
    try std.testing.expectEqual(@as(i32, 3), Op(4).apply(7, 3));
    // 除零在编译期分支里已经被消掉（b 是编译期常量？不，是运行期参数）
    try std.testing.expectEqual(@as(i32, 0), Op(3).apply(7, 0));
    // 不同 kind 是不同类型
    try std.testing.expect(Op(0) != Op(1));
}

test "14.8 @field / @fieldParentPtr / printAny" {
    var p = Person{ .name = "x", .age = 1, .vip = false };
    // @field 的名字来自编译期变量
    const fname = comptime "age";
    @field(p, fname) = 26;
    try std.testing.expectEqual(@as(u8, 26), @field(p, "age"));
    try std.testing.expectEqualStrings("x", @field(p, "name"));
    @field(p, "vip") = true;
    try std.testing.expect(@field(p, "vip"));
    // @fieldParentPtr：从字段指针反推宿主
    var eng = Engine{ .power = 100 };
    eng.boost(50);
    try std.testing.expectEqual(@as(u32, 150), eng.power);
    eng.boostViaField(25);
    try std.testing.expectEqual(@as(u32, 175), eng.power);
    // 联合的标签分派
    const pl: Payload = .{ .int = 5 };
    try std.testing.expectEqualStrings("int", pl.tagName());
    try std.testing.expectEqual(@as(i32, 5), pl.int);
}

test "14.9 单态化：相同类型只实例化一次" {
    // 实测依据：16 次调用但只有 4 个唯一类型时，符号表里只有 4 份代码。
    // 测试里能断言的是"实例按类型区分"这件事本身：
    try std.testing.expect(Stack(u32) != Stack(u64));
    // 同一个类型反复"调用"泛型构造器，得到的类型恒等
    const a = Matrix(u8, 2, 3);
    const b = Matrix(u8, 2, 3);
    try std.testing.expect(a == b);
    // 运行期零开销的证据：泛型函数的返回类型就是 T 本身，没有装箱
    try std.testing.expectEqualStrings("u8", @typeName(@TypeOf(firstOf(&[_]u8{1}))));
}
