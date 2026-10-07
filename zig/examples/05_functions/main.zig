//! 05 函数：声明与返回值、?T 可选、!T 错误联合与错误集合推导、没有重载（comptime T / anytype）、defer 与 errdefer、匿名结构体参数、函数指针、递归、comptime 参数函数、泛型、元组多返回值、noreturn/unreachable、inline fn、参数传递语义（值拷贝 / 指针 / 切片）
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 5.1 用到的函数（都是普通具名函数）═══
/// 最基础的形态：参数按值传，返回值按值回
fn add(a: i64, b: i64) i64 {
    return a + b;
}

/// 返回类型**必须写出来**：0.17 里`fn f(x: i32) { ... }`（省略）直接编译错
fn greet(name: []const u8) void {
    std.debug.print("  你好，{s}\n", .{name});
}

/// 参数在函数体内是**不可变**的：想改先复制一份
fn increment(n: i32) i32 {
    // n += 1; // error: cannot assign to constant —— 参数天生是 const
    var copy = n; // 想改就自己复制一份
    copy += 1;
    return copy;
}

// ═══ 5.2 可选返回值═══
/// ?T：成功给值，失败给 null。用 for-return 提前返回
fn firstEven(xs: []const i32) ?i32 {
    for (xs) |x| {
        if (@mod(x, 2) == 0) return x; // 注意：i32 的 % 要写 @mod，不能写 %
    }
    return null; // 一个都没找到
}

/// 可选的 optional：查不到就 null
fn findByte(haystack: []const u8, needle: u8) ?usize {
    for (haystack, 0..) |b, i| {
        if (b == needle) return i;
    }
    return null;
}

// ═══ 5.3 错误返回值与错误集合推导═══
/// 无参 `!`：让编译器**从函数体推导**出一个只含实际出现过的那几个错误的集合。
/// 注意它**不等于** anyerror（下面 main 里有断言）。
fn inferredFail(ok: bool) !void {
    if (!ok) return error.Boom;
    if (ok) {} // 成功路径什么都不做
}

/// 具名错误集：写死"这个函数可能报哪几种错"，可被 @typeInfo 列出成员
const ParseError = error{ Empty, BadDigit };

/// 具名错误集 + 返回值：ParseError!u32
fn parseDigits(s: []const u8) ParseError!u32 {
    if (s.len == 0) return error.Empty;
    var acc: u32 = 0;
    for (s) |c| {
        // 有符号 % 要@mod；这里用无符号 u8 的 % 是合法的
        if (c < '0' or c > '9') return error.BadDigit;
        acc = acc * 10 + @as(u32, c - '0');
    }
    return acc;
}

/// anyerror!T：最宽松，"任何错误都可能出现"。库内部常用，公开 API 不该用
fn anythingGoesWrong() anyerror!u8 {
    return error.Mystery;
}

/// 双重失败：! 叠 ? —— "!?T" 读作"可能报错；不报错的话还可能没有值"
fn findPositive(xs: []const i32) !?i32 {
    for (xs) |x| {
        if (x > 0) return x;
    }
    if (xs.len == 0) return error.EmptyInput; // 第一层失败：错误
    return null; // 第二层失败：没找到值，但不算错误
}

/// 取出被推导的错误集的类型，供 main 打印
fn errorSetOf(comptime f: anytype) type {
    const ret = @typeInfo(@TypeOf(f)).@"fn".return_type.?;
    return @typeInfo(ret).error_union.error_set;
}

// ═══ 5.4 没有重载：comptime T 与 anytype═══
/// 泛型：comptime T: type 把"类型"本身当编译期参数传进来。
/// 每个不同的 T 都会让编译器**特化出一份独立的函数**。
fn maxOf(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

/// anytype：对每个实际传入的类型自动特化一份，函数体里用 @TypeOf 适配。
/// 这就是 std.debug.print 格式串能编译期检查的原理。
fn describe(value: anytype) void {
    const T = @TypeOf(value);
    std.debug.print("  类型 {s} → 值 {any}\n", .{ @typeName(T), value });
}

/// anytype 的多参数版：同一次调用里多个参数可以是不同类型
fn firstOf2(a: anytype, b: anytype) @TypeOf(a) {
    _ = b;
    return a;
}

// ═══ 5.5 没有默认参数：匿名结构体═══
/// 参数结构体：默认值长在字段上，调用处用 .{}只覆盖要改的
const DrawOpts = struct {
    color: []const u8 = "black",
    bold: bool = false,
    size: u8 = 1,
};

fn rect(o: DrawOpts) void {
    std.debug.print("  rect color={s} bold={} size={d}\n", .{ o.color, o.bold, o.size });
}

// ═══ 5.6 defer / errdefer 的执行时机═══
/// 记录执行轨迹的全局缓冲。每一格是 64 字节的**定长数组**，
/// 这样格式化结果直接写进格子里，不存在"指向已销毁栈帧的切片"问题。
/// ⚠️ 必须同时记住实际长度：靠找 0 结束符是不行的——
/// 同一格被写过长串后再写短串，旧的尾巴还在。
var trace_slots: [8][64]u8 = undefined;
var trace_lens: [8]usize = undefined;
var trace_n: usize = 0;

fn note(s: []const u8) void {
    @memcpy(trace_slots[trace_n][0..s.len], s);
    trace_lens[trace_n] = s.len;
    trace_n += 1;
}

/// 带格式的 note：格式化结果写进当前格子的前s.len 字节
fn noteFmt(comptime fmt: []const u8, args: anytype) void {
    const s = std.fmt.bufPrint(&trace_slots[trace_n], fmt, args) catch unreachable;
    trace_lens[trace_n] = s.len;
    trace_n += 1;
}

fn showTrace() void {
    for (trace_slots[0..trace_n], trace_lens[0..trace_n]) |slot, len| {
        std.debug.print(" [{s}]", .{slot[0..len]});
    }
    std.debug.print("\n", .{});
    trace_n = 0;
}

/// 模拟"获取资源→可能失败→释放"。
/// defer 无条件跑；errdefer 只在**返回错误**时跑。
fn acquireResource(should_fail: bool) !u8 {
    note("acquire");
    defer note("defer(一定跑)");
    errdefer note("errdefer(出错才跑)");
    if (should_fail) return error.NoResource;
    return 42;
}

/// defer 的LIFO：后注册的先跑
fn deferLifo() void {
    defer note("第1个注册的defer");
    defer note("第2个注册的defer");
    defer note("第3个注册的defer");
    note("函数体");
}

/// defer 挂在**每一次迭代**上，不是循环结束后跑一次
fn deferInLoop() void {
    for (0..3) |i| {
        const tag = "第{d}次迭代";
        defer noteFmt(tag ++ "的defer", .{i});
        noteFmt(tag ++ "的本体", .{i});
    }
}

/// defer 在return 的值**求值之后**、真正返回之前执行——所以改不动返回值
var defer_trace: i32 = 0;
fn returnThenDefer() i32 {
    defer defer_trace += 1;
    return defer_trace; // 先把 0 取出来，defer 之后再 +1
}

/// 嵌套块：内层的 defer 只在内层块结束时跑
fn nestedScope() void {
    note("外层-进入");
    defer note("外层-退出");
    {
        defer note("内层-退出");
        note("内层-本体");
    }
    note("外层-尾巴");
}

// ═══ 5.7 函数指针：一等函数═══
const BinOp = *const fn (i32, i32) i32;

fn sub(a: i32, b: i32) i32 {
    return a - b;
}
fn mul(a: i32, b: i32) i32 {
    return a * b;
}
fn apply(op: BinOp, a: i32, b: i32) i32 {
    return op(a, b); // 直接调用指针
}

const CmpFn = *const fn (i32, i32) bool;
fn less(a: i32, b: i32) bool {
    return a < b;
}
fn greater(a: i32, b: i32) bool {
    return a > b;
}

/// Zig **没有嵌套函数**。需要"局部函数"时用匿名 struct 当命名空间。
/// 注意：它捕获不了外层变量，参数必须显式传。
fn outer(x: i64) i64 {
    const helper = struct {
        fn square(v: i64) i64 {
            return v * v;
        }
    }.square;
    return helper(x) + helper(@divTrunc(x, 2));
}

// ═══ 5.8 递归 ═══
/// 递归函数**必须写全返回类型**：推导返回类型需要函数体，
/// 而函数体又要调用自己 → 循环依赖，编译器直接报错：
///   fn countdown(n: u32) { ... countdown(n - 1); }
///   → error: expected return type expression, found '{'
fn countdown(n: u32) u32 {
    if (n == 0) return 0;
    return 1 + countdown(n - 1);
}

/// 斐波那契：朴素递归（指数级慢，只作教学演示）
fn fib(n: u32) u64 {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

// ═══ 5.9 comptime 参数的函数 ═══
/// comptime 值参数：调用处必须给编译期已知的值，整个函数在编译期求值一次
fn squareArea(comptime w: u32, comptime h: u32) u32 {
    return w * h;
}

/// 纯编译期阶乘：comptime 变量 + inline while
fn factorial(comptime n: u32) u64 {
    comptime var acc: u64 = 1;
    comptime var k: u32 = 2;
    // ⚠️ 改comptime 变量的循环**必须**是 inline while，
    // 普通 while 会报 error: cannot store to comptime variable in non-inline loop
    inline while (k <= n) : (k += 1) acc *= k;
    return acc;
}

/// comptime 参数 + 运行期参数混合
fn scaleBy(comptime k: u32, v: u32) u32 {
    return v * k;
}

// ═══ 5.10 泛型函数 ═══
/// 泛型 + 泛型返回值：返回结构体的字段类型就是 T
fn makePair(comptime T: type, a: T, b: T) struct { a: T, b: T } {
    return .{ .a = a, .b = b };
}

/// 泛型求和：同一份代码对 u8 / i64 各特化一份
fn sumOf(comptime T: type, xs: []const T) T {
    var acc: T = 0;
    for (xs) |x| acc += x;
    return acc;
}

/// 泛型的类型约束靠"body 里用了什么类型操作"隐式表达：
/// `a > b` 要求 T 支持 `>`。传一个不支持的类型就在编译期炸。
fn needsComparable(comptime T: type, a: T, b: T) bool {
    return a < b;
}

// ═══ 5.11 多返回值：元组 ═══
/// 具名字段元组：有自解释性
fn divmod(a: i32, b: i32) struct { q: i32, r: i32 } {
    return .{ .q = @divTrunc(a, b), .r = a - @divTrunc(a, b) * b };
}

/// 匿名元组 struct { i32, i32 }：只能按 [0]/[1] 访问
fn minmax(a: i32, b: i32) struct { i32, i32 } {
    return .{ if (a < b) a else b, if (a < b) b else a };
}

// ═══ 5.12 noreturn 与 unreachable ═══
/// 返回类型是 noreturn：告诉编译器"这个函数不会正常返回"
fn mustNotReach() noreturn {
    std.debug.print("  mustNotReach() 真的被调用了\n", .{});
    unreachable; // Debug/safe 下 panic: reached unreachable code
}

/// noreturn可以用在任何需要值的位置——它与所有类型兼容
fn classify(code: u8) u8 {
    return switch (code) {
        1 => 42,
        2 => 84,
        else => mustNotReach(),
    };
}

// ═══ 5.13 inline fn ═══
/// inline fn：函数体在被调用处**展开**（像宏），而不是走一次函数调用。
/// 运行期也能调（编译器照样可以内联），但 comptime 调用才显出"展开"的本质。
inline fn triple(x: i32) i32 {
    return x * 3;
}

// ═══ 5.14 参数传递语义 ═══
/// 结构体：匿名 struct 声明，带一个 format 方法供 {f} 用
const Point = struct {
    x: i32,
    y: i32,

    pub fn format(self: Point, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("({d}, {d})", .{ self.x, self.y });
    }
};

/// 值传递：Point 是 8 字节，传进来的是**拷贝**。返回新值，原值不动
fn translateByValue(p: Point, dx: i32, dy: i32) Point {
    return .{ .x = p.x + dx, .y = p.y + dy };
}

/// 指针传递：改的是调用方的那份
fn translateByPointer(p: *Point, dx: i32, dy: i32) void {
    p.x += dx;
    p.y += dy;
}

/// 数组按值传 = 拷贝，参数是 const，**改不了元素**
fn firstOfArray(arr: [3]i32) i32 {
    // arr[0] = 99; // error: cannot assign to constant
    return arr[0];
}

/// 想改数组元素，要么传 *[N]，要么传切片
fn bumpPtr(arr: *[3]i32) void {
    arr[0] += 100;
}
fn bumpSlice(xs: []i32) void {
    for (xs) |*x| x.* += 100;
}

// ═══ 5.15 调用约定与 pub ═══
/// callconv(.c)：0.17 是 .c（小写），老代码写 .C 会被拒
fn cAdd(a: i32, b: i32) callconv(.c) i32 {
    return a + b;
}

pub fn main() !void {
    // ═══ 5.1 声明与返回值 ═══
    begin("5.1 声明与返回值");
    std.debug.print("add(3, 4)={d}  返回类型={s}\n", .{ add(3, 4), @typeName(@TypeOf(add(0, 0))) });
    greet("Zig");
    greet("函数");
    std.debug.print("increment(10)={d}（参数是 const，函数内改的是副本）\n", .{increment(10)});
    // 返回类型**不能省略**，0.17 直接报错：
    //   fn noRet(x: i32) { ... }
    //   → error: expected return type expression, found '{'
    end("5.1 声明与返回值");

    // ═══ 5.2 可选返回值 ?T ═══
    begin("5.2 可选返回值 ?T");
    const with_even = [_]i32{ 1, 3, 4, 5 };
    const all_odd = [_]i32{ 1, 3, 5 };
    std.debug.print("firstEven([1,3,4,5]) = {any}（找到4）\n", .{firstEven(&with_even)});
    std.debug.print("firstEven([1,3,5])   = {any}（全是奇数 → null）\n", .{firstEven(&all_odd)});
    std.debug.print("findByte(\"zig\", 'g')  = {any}\n", .{findByte("zig", 'g')});
    std.debug.print("findByte(\"zig\", 'x')  = {any}\n", .{findByte("zig", 'x')});
    // 用 if-catch 解包可选值（也可以用 `orelse` 给默认值）
    const found = if (firstEven(&all_odd)) |v| v else -1;
    std.debug.print("解包失败用 -1兜底 = {d}\n", .{found});
    std.debug.print("?i32 类型名 = {s}\n", .{@typeName(@TypeOf(firstEven(&all_odd)))});
    end("5.2 可选返回值 ?T");

    // ═══ 5.3 错误返回值 !T ═══
    begin("5.3 错误返回值 !T");
    std.debug.print("inferredFail(true)  = {any}\n", .{inferredFail(true)});
    std.debug.print("inferredFail(false) = {any}\n", .{inferredFail(false)});
    // 无参 ! 的错误集是"推导出来的最小集合"，**不是** anyerror
    const I = errorSetOf(inferredFail);
    const Ni = @typeInfo(I);
    std.debug.print("inferredFail 的错误集 == anyerror ? {}  成员数={d}\n", .{
        I == anyerror,
        if (Ni.error_set.error_names) |ns| ns.len else 0,
    });
    // 具名错误集能被列出成员
    const P = @typeInfo(@typeInfo(@TypeOf(parseDigits)).@"fn".return_type.?).error_union.error_set;
    if (@typeInfo(P).error_set.error_names) |ns| {
        std.debug.print("parseDigits 的错误集成员数={d}：", .{ns.len});
        for (ns) |nm| std.debug.print(" {s}", .{nm[0..nm.len]});
        std.debug.print("\n", .{});
    }
    std.debug.print("parseDigits(\"1234\") = {d}\n", .{try parseDigits("1234")});
    std.debug.print("parseDigits(\"\")= {any}\n", .{parseDigits("")});
    std.debug.print("parseDigits(\"12a\")    = {any}\n", .{parseDigits("12a")});
    std.debug.print("anythingGoesWrong()      = {any}（anyerror!u8）\n", .{anythingGoesWrong()});
    std.debug.print("anythingGoesWrong 类型   = {s}\n", .{@typeName(@TypeOf(anythingGoesWrong()))});
    // !?T 双层：先错→错误；没错但没值→null
    const mixed = findPositive(&[_]i32{ -1, -2 });
    std.debug.print("findPositive([负数]) = {any}（不报错，只是 null）\n", .{mixed});
    const empty_in = findPositive(&[_]i32{});
    std.debug.print("findPositive([])    = {any}（这是错误）\n", .{empty_in});
    const pos = findPositive(&[_]i32{ -1, 7 });
    std.debug.print("findPositive([-1,7]) = {any}\n", .{pos});
    // ⚠️ 推导出来的错误集是**匿名**的，@typeName 打不出好名字——
    // 直接打印只会得到编译器内部表达式（下面这行就是证据）。
    // 要好看的类型名必须用具名错误集。
    std.debug.print("!?i32 打印出来的类型名 = {s}\n", .{@typeName(@TypeOf(mixed))});
    std.debug.print("（这一长串就是 0.17 的坑：推导错误集无名字，只能这么打）\n", .{});
    // 用 catch 把错误就地变成值
    const safe = parseDigits("") catch 0;
    std.debug.print("parseDigits(\"\") catch 0 = {d}（错误就地兜底）\n", .{safe});
    end("5.3 错误返回值 !T");

    // ═══ 5.4 没有重载 ═══
    begin("5.4 没有重载：comptime T 与 anytype");
    std.debug.print("maxOf(i32, 3, 9)   = {d}（类型 {s}）\n", .{ maxOf(i32, 3, 9), @typeName(@TypeOf(maxOf(i32, 0, 0))) });
    std.debug.print("maxOf(f64, 2.5, 1.5) = {d:.1}（类型 {s}）\n", .{ maxOf(f64, 2.5, 1.5), @typeName(@TypeOf(maxOf(f64, 0.0, 0.0))) });
    std.debug.print("两种 T 各特化一份，函数地址不同？ {}\n", .{@TypeOf(maxOf(i32, 0, 0)) != @TypeOf(maxOf(f64, 0.0, 0.0))});
    describe(42);
    describe(3.5);
    describe(true);
    describe("abc");
    describe(@as(u8, 7));
    std.debug.print("firstOf2(9, \"str\") = {any}（anytype 允许不同类型）\n", .{firstOf2(9, "str")});
    // 重载是**直接编译错**的，不是"选一个"：
    //   fn f(a: i32) i32 {...}
    //   fn f(a: f64) f64 {...}
    //   → error: duplicate struct member name 'f'
    end("5.4 没有重载：comptime T 与 anytype");

    // ═══ 5.5 匿名结构体参数 ═══
    begin("5.5 匿名结构体参数");
    rect(.{}); // 全默认
    rect(.{ .color = "red" }); // 只覆盖 color
    rect(.{ .color = "green", .bold = true }); // 覆盖两个
    rect(.{ .size = 3 }); // 只覆盖 size
    end("5.5 匿名结构体参数");

    // ═══ 5.6 defer / errdefer ═══
    begin("5.6 defer 与 errdefer");
    const got = try acquireResource(false);
    std.debug.print("acquireResource(false)={d} 轨迹", .{got});
    showTrace();
    const failed = acquireResource(true);
    std.debug.print("acquireResource(true) = {any} 轨迹", .{failed});
    showTrace();
    deferLifo();
    showTrace();
    deferInLoop();
    showTrace();
    nestedScope();
    showTrace();
    defer_trace = 0;
    std.debug.print("returnThenDefer()={d}，之后 defer_trace={d}（返回值先求值）\n", .{ returnThenDefer(), defer_trace });
    end("5.6 defer 与 errdefer");

    // ═══ 5.7 函数指针 ═══
    begin("5.7 函数指针");
    const ops = [_]BinOp{ add2, sub, mul };
    for (ops, 0..) |op, i| {
        std.debug.print("  ops[{d}](10, 3) = {d}\n", .{ i, apply(op, 10, 3) });
    }
    std.debug.print("BinOp 类型名 = {s}\n", .{@typeName(BinOp)});
    const cmps = [_]CmpFn{ less, greater };
    for (cmps, 0..) |c, i| {
        std.debug.print("  cmps[{d}](3, 9) = {}\n", .{ i, c(3, 9) });
    }
    // @call 的 0.17 签名是三参数：@call(调用约定, 函数, 参数元组)
    const fp: BinOp = sub;
    std.debug.print("@call(.auto, sub, .{{10, 3}}) = {d}\n", .{@call(.auto, fp, .{ 10, 3 })});
    std.debug.print("outer(8) = {d}（匿名 struct 模拟局部函数）\n", .{outer(8)});
    // 函数体内直接写 fn 是**语法错**（报错很迷惑）：
    //   pub fn main() void { fn local() void {} ... }
    //   → error: expected ';' after statement
    end("5.7 函数指针");

    // ═══ 5.8 递归 ═══
    begin("5.8 递归");
    std.debug.print("countdown(5) = {d}\n", .{countdown(5)});
    std.debug.print("fib(20)     = {d}（朴素递归，指数级）\n", .{fib(20)});
    std.debug.print("fib(25)     = {d}（还能跑，但已经很慢了）\n", .{fib(25)});
    end("5.8 递归");

    // ═══ 5.9 comptime 参数函数 ═══
    begin("5.9 comptime 参数的函数");
    std.debug.print("squareArea(6, 7)   = {d}（编译期算好的常量）\n", .{squareArea(6, 7)});
    std.debug.print("factorial(10)      = {d}（inline while 在编译期展开）\n", .{factorial(10)});
    std.debug.print("scaleBy(3, 100)    = {d}（k 是comptime，v 是运行期）\n", .{scaleBy(3, 100)});
    // comptime 参数传运行期值 → 编译错：
    //   const n: u32 = 5; squareArea(n, 7)
    //   → error: argument to comptime parameter must be comptime-known
    end("5.9 comptime 参数的函数");

    // ═══ 5.10 泛型函数 ═══
    begin("5.10 泛型函数");
    const pu8 = makePair(u8, 1, 2);
    const pi64 = makePair(i64, -1, -2);
    std.debug.print("makePair(u8, 1, 2)   = {any}（类型 {s}）\n", .{ pu8, @typeName(@TypeOf(pu8)) });
    std.debug.print("makePair(i64, -1, -2)= {any}（类型 {s}）\n", .{ pi64, @typeName(@TypeOf(pi64)) });
    std.debug.print("sumOf(u8, [1,2,3])   = {d}（类型 {s}）\n", .{ sumOf(u8, &[_]u8{ 1, 2, 3 }), @typeName(@TypeOf(sumOf(u8, &[_]u8{0}))) });
    std.debug.print("sumOf(i64, [10,20])  = {d}（类型 {s}）\n", .{ sumOf(i64, &[_]i64{ 10, 20 }), @typeName(@TypeOf(sumOf(i64, &[_]i64{0}))) });
    std.debug.print("needsComparable(u8, 1, 2) = {}\n", .{needsComparable(u8, 1, 2)});
    std.debug.print("needsComparable(f64, 1, 2) = {}\n", .{needsComparable(f64, 1, 2)});
    // 传不支持 `>` 的类型会在编译期炸（约束是隐式的）：
    //   needsComparable([]const u8, "a", "b")
    //   → error: operator comptime_int '<' not allowed for type '[]const u8'
    end("5.10 泛型函数");

    // ═══ 5.11 多返回值：元组 ═══
    begin("5.11 多返回值：元组");
    const dm = divmod(17, 5);
    std.debug.print("divmod(17,5): q={d} r={d}（具名字段，类型 {s}）\n", .{ dm.q, dm.r, @typeName(@TypeOf(dm)) });
    const mm = minmax(3, 9);
    std.debug.print("minmax(3,9): mm[0]={d} mm[1]={d} len={d}（匿名元组，类型 {s}）\n", .{ mm[0], mm[1], mm.len, @typeName(@TypeOf(mm)) });
    const lo, const hi = minmax(3, 9); // 解构声明
    std.debug.print("解构const lo, const hi = {d}, {d}\n", .{ lo, hi });
    std.debug.print("具名元组也能按 [0] 访问？见 test 块\n", .{});
    end("5.11 多返回值：元组");

    // ═══ 5.12 noreturn 与 unreachable ═══
    begin("5.12 noreturn 与 unreachable");
    std.debug.print("classify(1) = {d}\n", .{classify(1)});
    std.debug.print("classify(2) = {d}\n", .{classify(2)});
    std.debug.print("noreturn 类型名 = {s}（与所有类型兼容）\n", .{@typeName(noreturn)});
    std.debug.print("unreachable 在 Debug/safe 下 panic：reached unreachable code\n", .{});
    // classify(3) 会真的走到 unreachable → panic，所以这里不调用
    end("5.12 noreturn 与 unreachable");

    // ═══ 5.13 inline fn ═══
    begin("5.13 inline fn");
    std.debug.print("triple(4) = {d}（运行期调用也合法）\n", .{triple(4)});
    std.debug.print("comptime triple(5) = {d}（编译期展开成常量）\n", .{comptime triple(5)});
    end("5.13 inline fn");

    // ═══ 5.14 参数传递语义 ═══
    begin("5.14 参数传递语义");
    const p = Point{ .x = 3, .y = 4 };
    const moved = translateByValue(p, 5, -2);
    std.debug.print("按值：原 {f} → 返回 {f}（原值一个字节没变）\n", .{ p, moved });
    var q = Point{ .x = 3, .y = 4 };
    translateByPointer(&q, 5, -2);
    std.debug.print("按指针：{f}（就地改了调用方那份）\n", .{q});
    std.debug.print("Point 占{d} 字节 → 按值传就是拷这 {d} 字节\n", .{ @sizeOf(Point), @sizeOf(Point) });
    // 数组 vs 切片 vs 指针
    const arr = [_]i32{ 1, 2, 3 };
    std.debug.print("数组按值传：firstOf([1,2,3])={d}，原数组仍是 {any}\n", .{ firstOfArray(arr), arr });
    var ap = [_]i32{ 1, 2, 3 };
    bumpPtr(&ap);
    std.debug.print("传 *[3]：{any}\n", .{ap});
    var sl = [_]i32{ 1, 2, 3 };
    const view: []i32 = &sl; // 切片是"指针 + 长度"的视图，不拷贝
    bumpSlice(view);
    std.debug.print("传切片：{any}（切片本身只占 {d} 字节 = 指针+长度）\n", .{ sl, @sizeOf(@TypeOf(view)) });
    // 切片长度 vs 数组长度
    std.debug.print("数组类型 {s} 长度 {d}；切片类型 {s} 长度 {d}\n", .{ @typeName(@TypeOf(arr)), arr.len, @typeName(@TypeOf(view)), view.len });
    end("5.14 参数传递语义");

    // ═══ 5.15 调用约定与 pub ═══
    begin("5.15 调用约定与 pub");
    std.debug.print("cAdd(2, 3) = {d}（callconv(.c)，0.17 是小写 .c）\n", .{cAdd(2, 3)});
    std.debug.print("⚠️ main 必须是 `pub fn main`，漏掉 pub 会报std 内部一个看不懂的错：\n", .{});
    std.debug.print("   struct 'elf.AT__struct_XXX' has no member named 'HWCAP'\n", .{});
    end("5.15 调用约定与 pub");

    std.debug.print("自检通过\n", .{});
}

/// 供函数指针数组用的加法（放在 main 之后定义——Zig 不要求先声明）
fn add2(a: i32, b: i32) i32 {
    return a + b;
}

// ═══════════════ 测试 ═══════════════

test "函数声明：参数按值传、返回类型可反射" {
    try std.testing.expectEqual(@as(i64, 7), add(3, 4));
    try std.testing.expectEqualStrings("i64", @typeName(@TypeOf(add(0, 0))));
    // 参数是const：函数内改的是副本，调用方看不到
    try std.testing.expectEqual(@as(i32, 11), increment(10));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(i64));
}

test "可选返回值：找到给值，找不到给 null" {
    try std.testing.expectEqual(@as(?i32, 4), firstEven(&[_]i32{ 1, 3, 4 }));
    try std.testing.expectEqual(@as(?i32, null), firstEven(&[_]i32{ 1, 3, 5 }));
    try std.testing.expectEqual(@as(?usize, 2), findByte("zig", 'g'));
    try std.testing.expectEqual(@as(?usize, null), findByte("zig", 'x'));
    // orelse 给默认值
    try std.testing.expectEqual(@as(usize, 0), findByte("zig", 'x') orelse 0);
}

test "错误返回值：无参! 推导出的集合不含 anyerror" {
    const I = errorSetOf(inferredFail);
    // 关键断言：推导出来的**不是** anyerror
    try std.testing.expect(I != anyerror);
    // ⚠️ 注意：函数值**不能**从推导错误集 coerce 成 anyerror 函数指针
    //   const as_any: anyerror!void = inferredFail;
    //   → error: expected type 'anyerror!void', found 'fn (bool) ...error_set!void'
    // 但函数**返回值**可以（小错误集 → anyerror 是允许的向上 coerce）
    const r: anyerror!void = inferredFail(true);
    // 成功的错误联合，payload 是 void 而不是 null
    try std.testing.expectEqual(@as(anyerror!void, {}), r);
    // 具名错误集同理：Named!void 的函数值能塞进 anyerror!void 槽位吗？也不能
    try std.testing.expectError(error.Boom, inferredFail(false));
}

test "具名错误集能被@typeInfo 列出成员" {
    const P = @typeInfo(@typeInfo(@TypeOf(parseDigits)).@"fn".return_type.?).error_union.error_set;
    try std.testing.expect(P != anyerror);
    const info = @typeInfo(P);
    try std.testing.expect(info.error_set.error_names != null);
    const ns = info.error_set.error_names.?;
    try std.testing.expectEqual(@as(usize, 2), ns.len);
    try std.testing.expectEqualStrings("Empty", ns[0][0..5]);
    try std.testing.expectEqualStrings("BadDigit", ns[1][0..8]);
}

test "!?T 双层：先错误后无值" {
    try std.testing.expectEqual(@as(?i32, null), try findPositive(&[_]i32{ -1, -2 }));
    try std.testing.expectEqual(@as(?i32, 7), try findPositive(&[_]i32{ -1, 7 }));
    try std.testing.expectError(error.EmptyInput, findPositive(&[_]i32{}));
}

test "没有重载：泛型与 anytype 都按类型特化" {
    try std.testing.expectEqual(@as(i32, 9), maxOf(i32, 3, 9));
    try std.testing.expectEqual(@as(f64, 2.5), maxOf(f64, 2.5, 1.5));
    try std.testing.expectEqualStrings("i32", @typeName(@TypeOf(maxOf(i32, 0, 0))));
    try std.testing.expectEqualStrings("f64", @typeName(@TypeOf(maxOf(f64, 0.0, 0.0))));
    // anytype 允许多个参数类型不同
    try std.testing.expectEqual(@as(i32, 9), firstOf2(9, "str"));
}

test "匿名结构体参数：默认值 + 只覆盖个别字段" {
    //默认值来自字段声明，调用处 .{} 走全默认
    const all_default: DrawOpts = .{};
    try std.testing.expectEqualStrings("black", all_default.color);
    try std.testing.expectEqual(false, all_default.bold);
    // 只覆盖一个字段，其余仍取默认
    const partial: DrawOpts = .{ .color = "red" };
    try std.testing.expectEqualStrings("red", partial.color);
    try std.testing.expectEqual(false, partial.bold);
    try std.testing.expectEqual(@as(u8, 1), partial.size);
}

test "defer 逆序（LIFO）执行" {
    // 用一个"记录执行次序"的辅助结构：每次 defer 就往尾部追加一个字符
    const Recorder = struct {
        var buf: [8]u8 = undefined;
        var n: usize = 0;

        fn tick(tag: u8) void {
            buf[n] = tag;
            n += 1;
        }
    };
    Recorder.n = 0;
    {
        defer Recorder.tick('1'); // 第1个注册
        defer Recorder.tick('2'); // 第2个注册
        defer Recorder.tick('3'); // 第3个注册
        Recorder.tick('b'); // 函数体
    }
    // 退出作用域时逆序跑：3 → 2 → 1，函数体的 b 在最前
    try std.testing.expectEqual(@as(usize, 4), Recorder.n);
    try std.testing.expectEqualStrings("b321", Recorder.buf[0..4]);
}

test "errdefer 只在返回错误时执行，defer 无条件执行" {
    var ran_defer = false;
    var ran_errdefer = false;

    const S = struct {
        fn body(fail: bool, d: *bool, e: *bool) !u8 {
            defer d.* = true;
            errdefer e.* = true;
            if (fail) return error.Nope;
            return 1;
        }
    };
    // 成功路径：只有 defer
    _ = try S.body(false, &ran_defer, &ran_errdefer);
    try std.testing.expect(ran_defer);
    try std.testing.expect(!ran_errdefer);
    // 失败路径：两个都跑（errdefer 先，因为它先注册）
    try std.testing.expectError(error.Nope, S.body(true, &ran_defer, &ran_errdefer));
    try std.testing.expect(ran_defer);
    try std.testing.expect(ran_errdefer);
}

test "defer 在返回值求值之后执行，改不动返回值" {
    defer_trace = 0;
    const ret = returnThenDefer();
    try std.testing.expectEqual(@as(i32, 0), ret); // return 先把 0 取出来
    try std.testing.expectEqual(@as(i32, 1), defer_trace); // defer 之后才 +1
    defer_trace = 0;
}

test "函数指针：存进数组再间接调用" {
    const ops = [_]BinOp{ add2, sub, mul };
    try std.testing.expectEqual(@as(usize, 3), ops.len);
    try std.testing.expectEqual(@as(i32, 13), apply(ops[0], 10, 3));
    try std.testing.expectEqual(@as(i32, 7), apply(ops[1], 10, 3));
    try std.testing.expectEqual(@as(i32, 30), apply(ops[2], 10, 3));
    // @call 的 0.17 签名：@call(调用约定, 函数, 参数元组)
    try std.testing.expectEqual(@as(i32, 7), @call(.auto, ops[1], .{ 10, 3 }));
    // 函数指针类型本身是可写的类型
    try std.testing.expectEqualStrings("*const fn (i32, i32) i32", @typeName(BinOp));
}

test "递归：必须写全返回类型" {
    try std.testing.expectEqual(@as(u32, 5), countdown(5));
    try std.testing.expectEqual(@as(u32, 0), countdown(0));
    try std.testing.expectEqual(@as(u64, 6765), fib(20));
}

test "comptime 参数函数：编译期求值，运行期零开销" {
    try std.testing.expectEqual(@as(u32, 42), squareArea(6, 7));
    try std.testing.expectEqual(@as(u64, 3628800), factorial(10));
    try std.testing.expectEqual(@as(u64, 1), factorial(0));
    // comptime 值 + 运行期值混合
    try std.testing.expectEqual(@as(u32, 300), scaleBy(3, 100));
}

test "泛型：同一份代码对不同类型各特化一份" {
    const pu8 = makePair(u8, 1, 2);
    try std.testing.expectEqual(@as(u8, 1), pu8.a);
    try std.testing.expectEqual(@as(u8, 2), pu8.b);
    // 字段类型跟着 T 走
    try std.testing.expectEqual(@as(u8, 1), @field(pu8, "a"));
    const pi64 = makePair(i64, -1, -2);
    try std.testing.expectEqual(@as(i64, -1), pi64.a);
    try std.testing.expect(sumOf(u8, &[_]u8{ 1, 2, 3 }) == 6);
    try std.testing.expect(sumOf(i64, &[_]i64{ 10, 20 }) == 30);
    try std.testing.expect(needsComparable(u8, 1, 2));
    try std.testing.expect(needsComparable(f64, 1, 2));
}

test "多返回值：具名字段与匿名元组" {
    const dm = divmod(17, 5);
    try std.testing.expectEqual(@as(i32, 3), dm.q);
    try std.testing.expectEqual(@as(i32, 2), dm.r);
    const mm = minmax(3, 9);
    try std.testing.expectEqual(@as(usize, 2), mm.len);
    try std.testing.expectEqual(@as(i32, 3), mm[0]);
    try std.testing.expectEqual(@as(i32, 9), mm[1]);
    // ⚠️ 具名字段"结构体"**不能**按 [0] 访问——它不是元组
    //   dm[0] → error: type 'main.divmod__struct_XXXX' does not support indexing
    //   note: operand must be an array, slice, tuple, or vector
    // 匿名元组（struct { i32, i32 }）才可以，差别就在字段名。
}

test "noreturn 与 unreachable：noreturn 与所有类型兼容" {
    try std.testing.expectEqual(@as(u8, 42), classify(1));
    try std.testing.expectEqual(@as(u8, 84), classify(2));
    // classify 的返回类型就是 u8，不是 noreturn——因为只靠参数值决定不了
    try std.testing.expectEqualStrings("u8", @typeName(@TypeOf(classify(1))));
    try std.testing.expectEqualStrings("noreturn", @typeName(noreturn));
    // unreachable 在Debug/safe 下 panic，所以只在 test 里断言它"是个值位置"不炸：
    // 下面这行把 unreachable 放在需要值的位置，类型检查通过即说明 noreturn 兼容 u8
    const f: *const fn () u8 = struct {
        fn g() u8 {
            return if (false) unreachable else 1;
        }
    }.g;
    try std.testing.expectEqual(@as(u8, 1), f());
}

test "inline fn：运行期与编译期都能调" {
    try std.testing.expectEqual(@as(i32, 12), triple(4));
    try std.testing.expectEqual(@as(i32, 15), comptime triple(5));
}

test "参数传递语义：值拷贝 vs 指针 vs 切片" {
    // 值传递：改不动调用方的
    const p = Point{ .x = 1, .y = 2 };
    const moved = translateByValue(p, 1, 1);
    try std.testing.expectEqual(@as(i32, 1), p.x); // 原值没变
    try std.testing.expectEqual(@as(i32, 2), moved.x);
    // 指针传递：就地改
    var q = Point{ .x = 1, .y = 2 };
    translateByPointer(&q, 1, 1);
    try std.testing.expectEqual(@as(i32, 2), q.x);
    // 数组按值传 = 拷贝 + const
    const arr = [_]i32{ 1, 2, 3 };
    try std.testing.expectEqual(@as(i32, 1), firstOfArray(arr));
    try std.testing.expectEqual(@as(i32, 1), arr[0]); // 没被改
    // 指针 / 切片：能改到调用方
    var ap = [_]i32{ 1, 2, 3 };
    bumpPtr(&ap);
    try std.testing.expectEqual(@as(i32, 101), ap[0]);
    var sl = [_]i32{ 1, 2, 3 };
    const view: []i32 = &sl;
    bumpSlice(view);
    try std.testing.expectEqual(@as(i32, 101), sl[0]);
    // 切片本身的大小是指针(8) + 长度(8)，与元素个数无关
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(@TypeOf(view)));
}

test "callconv(.c) 可调用（0.17 是小写 .c）" {
    try std.testing.expectEqual(@as(i32, 5), cAdd(2, 3));
}
