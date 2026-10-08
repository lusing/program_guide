//! 13 comptime I：编译期求值——同一份代码的两个世界
//! 分节打印约定：每个小节用 ==== 13.N 开始 ==== / ==== 13.N 结束 ==== 圈出
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 支撑类型与函数（被后面各节反复调用）
// ══════════════════════════════════════════════════════════════════

/// 13.1 节：普通函数（没有 comptime 关键字），编译期与运行期都能调。
fn fibonacci(n: usize) usize {
    if (n < 2) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

/// 13.2 节：comptime 参数 —— 参数本身必须在编译期已知。
fn pow(comptime base: u64, comptime exp: u32) u64 {
    comptime var acc: u64 = 1;
    comptime var i: u32 = 0;
    inline while (i < exp) : (i += 1) acc *%= base;
    return acc;
}

/// 13.2 节：普通参数版——同一个算法，运行期输入也能调（两栖）。
fn powRuntime(base: u64, exp: u8) u64 {
    var acc: u64 = 1;
    var i: u8 = 0;
    while (i < exp) : (i += 1) acc *%= base;
    return acc;
}

/// 13.3 节：编译期递归 + 分支配额。cfib(25) 光靠默认 1000 配额会爆（见 13.6 节）。
fn cfib(comptime n: u32) comptime_int {
    if (n < 2) return n;
    return cfib(n - 1) + cfib(n - 2);
}

/// 13.5 节：13.5 节的struct 样本——编译期造一份、运行期造一份，类型完全相同。
const Conf = struct {
    name: []const u8,
    count: u32,
};

/// 13.5 节：comptime 参数把两个编译期字面量塞进一个 struct。
fn makeConf(comptime name: []const u8, comptime count: u32) Conf {
    return .{ .name = name, .count = count };
}

/// 13.5 节：泛型 —— 没有显式 comptime 参数表，类型从实参推导。
fn genericSum(values: anytype) @TypeOf(values[0]) {
    comptime var acc: @TypeOf(values[0]) = 0;
    for (values) |v| acc +|= v;
    return acc;
}

/// 13.7 节：inline fn（强制内联），运行期也能调。
inline fn twice(x: u32) u32 {
    return x * 2;
}

/// 13.8 节要反射的结构体。
const Header = struct {
    magic: u32,
    len: u16 = 0,
    ok: bool,
};

/// 13.8 节：造函数类型用 @TypeOf —— ⚠️ 0.17 不许在函数体里声明 fn，必须放容器级。
fn addThenNarrow(a: u32, b: u32) u8 {
    return @intCast(a + b);
}

/// 13.8 节：13.8 的枚举样本，@tagName 只能作用于它的**值**。
const Stage = enum { alpha, beta, gamma };

/// 13.8 节：按类型分派 —— 证明 comptime 反射能写普通代码。
fn kindName(comptime T: type) []const u8 {
    return switch (@typeInfo(T)) {
        .int => "整数",
        .float => "浮点",
        .@"struct" => "结构体",
        .@"enum" => "枚举",
        .array => "数组",
        .pointer => "指针",
        else => "其它",
    };
}

/// 13.10 节：编译期筛出的素数表（埃氏筛，0..255 全覆盖）。
/// 这是"编译期算、运行期只查表"最典型的例子：约 3 万次编译期迭代，
/// 换来运行期每次判定只需一次数组索引。
/// ⚠️ 容器级已经是编译期作用域，所以这里**不需要** comptime / inline 关键字
///（写了会报 redundant comptime / redundant inline）。
const PrimeFlags = blk: {
    @setEvalBranchQuota(10_000_000); // 见 13.6 节：默认 1000 远远不够
    var flags: [256]bool = @splat(true); // ⚠️ 0.17 没有 [_]T{x} ** n 重复填充（见 13.11 节）
    flags[0] = false;
    flags[1] = false;
    var n: u16 = 2;
    while (n * n < 256) : (n += 1) {
        if (flags[n]) {
            var m: u16 = n * n;
            while (m < 256) : (m += n) flags[m] = false;
        }
    }
    break :blk flags;
};

/// 13.10 节：从筛表里再编译期抽出前 8 个素数（演示表可以由表生成）。
const Primes = blk: {
    var buf: [8]u32 = undefined;
    var count: usize = 0;
    for (PrimeFlags, 0..) |is_p, idx| {
        if (count == 8) break;
        if (is_p) {
            buf[count] = @intCast(idx);
            count += 1;
        }
    }
    break :blk buf;
};

/// 13.11 节：编译期生成的 CRC-32 查找表（标准 256 项多项式表）。
/// 这是"编译期算大数组、运行期只查表"最经典的例子：一段 2048 次迭代的编译期计算，
/// 换来运行期每字节一次查表 + 一次异或。
const CrcTable = blk: {
    @setEvalBranchQuota(10_000_000);
    var buf: [256]u32 = undefined;
    for (&buf, 0..) |*slot, idx| {
        var c: u32 = @intCast(idx);
        for (0..8) |_| {
            // ⚠️ 0.17 没有 ** 幂运算符，也没有 @clamp（见 13.12 节）
            if (c & 1 != 0) c = (c >> 1) ^ 0xEDB88320 else c >>= 1;
        }
        slot.* = c;
    }
    break :blk buf;
};

comptime {
    // 13.3 节：编译期断言 —— @compileError / @setEvalBranchQuota 的用法
    if (fibonacci(10) != 55) @compileError("fibonacci 算错了");
    if (pow(2, 10) != 1024) @compileError("pow 算错了");
    // 13.7 节：inline fn 在编译期也能调
    if (twice(21) != 42) @compileError("twice 算错了");
    // 13.10 节：编译期断言一条结构体布局假设
    if (@sizeOf(Header) != 8) @compileError("Header 的sizeOf 变了，需要复核内存布局");
    if (@offsetOf(Header, "len") != 4) @compileError("Header.len 的偏移变了");
    // 13.8 节：反射结果本身在编译期就能断言
    if (@typeInfo(Header).@"struct".field_names.len != 3) @compileError("Header 字段数变了");
    if (!std.mem.eql(u8, kindName(u8), "整数")) @compileError("kindName 分派坏了");
    if (!std.mem.eql(u8, @tagName(Stage.beta), "beta")) @compileError("@tagName 用法错了");
}

pub fn main() !void {
    // 本函数里所有编译期求值共享同一份分支配额，13.4/13.6 节的循环会消耗它。
    // 默认 1000 本来够用，但 13.6 节要显式演示抬高配额的效果，所以先抬高。
    @setEvalBranchQuota(2_000_000);

    // ═══ 13.1 一份代码，两个世界：const 实参 = 编译期算完 ═══
    begin("13.1");
    // 顶层 const 的初始化必须编译期可得 → fibonacci(10) 在编译期算成 55 塞进二进制
    const fib10 = fibonacci(10);
    std.debug.print("fibonacci(10) 编译期常量= {d}\n", .{fib10});
    // 同一个函数，运行期照常调（n 来自运行期，没有任何编译期信息）
    var n: usize = 20; // 假装来自用户输入
    n += 1;
    std.debug.print("fibonacci({d}) 运行期调用 = {d}\n", .{ n, fibonacci(n) });
    // 关键：函数体里没有一行 comptime 关键字，两栖资格是"默认的"
    std.debug.print("对照：{d} < 2 == {}（判断本身没变）\n", .{ fib10, fib10 < 2 });
    // const vs comptime var：const 是"编译期可算"，不是"只在编译期存在"
    const runtime_also: usize = fibonacci(n); // 运行期算的值也能被 const 装
    std.debug.print("运行期值也能被 const 装 = {d}（const ≠ comptime）\n", .{runtime_also});
    end("13.1");

    // ═══ 13.2 comptime 参数：参数本身必须编译期已知 ═══
    begin("13.2");
    std.debug.print("pow(2,10) 编译期 = {d}\n", .{pow(2, 10)});
    std.debug.print("pow(3,5) 编译期 = {d}\n", .{pow(3, 5)});
    std.debug.print("pow(2,10) 类型 = {s}\n", .{@typeName(@TypeOf(pow(2, 10)))});
    // ⚠️ 传运行期值编译错：unable to resolve comptime value
    //      note: argument to comptime parameter must be comptime-known
    //   var e: u8 = 3; e += 1;
    //   const v = pow(2, e);          ← 编译错，报错见正文
    //
    // 要两栖就把参数改成普通参数——同一个算法，两种写法：
    var e: u8 = 3;
    e += 1;
    std.debug.print("运行期 pow(2,{d}) = {d}（普通参数版，两栖）\n", .{ e, powRuntime(2, e) });
    end("13.2");

    // ═══ 13.3 comptime 块与容器级 const：两种"块"的写法 ═══
    begin("13.3");
    // 带标签的块表达式：blk: { ... break :blk 值; }
    const square_table = blk: {
        var buf: [8]u16 = undefined;
        for (0..8) |i| buf[i] = @intCast(i * i);
        break :blk buf;
    };
    std.debug.print("square_table = {any}\n", .{square_table});
    // 容器级 const 本身就在编译期求值，所以那里写 comptime 是多余的：
    //   const x = comptime blk: {...};  → error: redundant comptime keyword in
    //                                        already comptime scope
    // 而函数体内必须显式写 comptime 才行：
    const func_local = comptime blk: {
        var acc: usize = 0;
        for (0..8) |k| acc += k;
        break :blk acc;
    };
    std.debug.print("func_local = {d}（函数体里加了 comptime 才被强制求值）\n", .{func_local});
    // comptime 块在函数体里也可以不写 labeled block，直接给const：
    const another = comptime r: {
        const a = 1 + 1;
        break :r a * 20;
    };
    std.debug.print("another = {d}\n", .{another});
    end("13.3");

    // ═══ 13.4 comptime 变量：编译期的"可变"绑定 ═══
    begin("13.4");
    // ⚠️ 核心坑：改 comptime 变量的循环**必须是 inline while**。
    // 普通 while 会报：error: cannot store to comptime variable in non-inline loop
    comptime var acc: u32 = 0;
    comptime var i: u32 = 0;
    inline while (i < 1000) : (i += 1) acc +%= i;
    std.debug.print("inline while 0..999 求和 = {d}（i 最终 = {d}）\n", .{ acc, i });
    // 为什么必须 inline：inline 循环在编译期**完全展开**，每轮的i 都有确定值，
    // 所以编译器知道写进 acc 的是编译期常量；普通 while 的迭代次数运行期才知道，
    // 编译器无法确认这次赋值安全。
    //
    // 同理，普通 for 里改 comptime 变量报的是另一个错（即使赋的是常量 0）：
    //   error: store to comptime variable depends on runtime condition
    //     note: runtime condition here
    //
    // ⚠️ 而在**容器级**（顶层 const 初始化）这些关键字全是多余的：
    //   const x = comptime blk: {...}   → error: redundant comptime keyword in
    //                                       already comptime scope
    //   comptime var acc: u32 = 0;      → error: 'comptime var' is redundant in
    //                                       comptime scope
    //   inline while (...) ...          → error: redundant inline keyword in
    //                                       comptime scope
    // 容器级已经是编译期作用域，直接写 var + while 即可（见 Primes 的写法）。
    //
    // comptime var 可以取地址（读），那个地址只在编译期有意义：
    comptime var boxed: u32 = 7;
    const addr = &boxed;
    std.debug.print("comptime var 取地址读回来= {d}\n", .{addr.*});
    end("13.4");

    // ═══ 13.5 comptime 参数 vs 泛型：两个都是"编译期输入" ═══
    begin("13.5");
    //显式版：comptime T: type + comptime values
    std.debug.print("genericSum(u8切片) = {d}\n", .{genericSum(&.{ 1, 2, 3, 4 })});
    std.debug.print("genericSum(u64 切片) = {d}\n", .{genericSum(&.{ 10, 20, 30 })});
    // 显式 comptime 参数版：makeConf("alpha", 3) 的两个实参都在编译期
    const c1 = makeConf("alpha", 3);
    std.debug.print("makeConf(\"alpha\",3) = {s} {d}\n", .{ c1.name, c1.count });
    // 同一个 Conf 类型，运行期手写一份（证明类型完全一样）
    var rt: u32 = 1;
    rt += 2;
    const c2: Conf = .{ .name = "beta", .count = rt };
    std.debug.print("运行期手写Conf= {s} {d}\n", .{ c2.name, c2.count });
    // comptime 参数不只接收类型，也能接收普通编译期值（这里两个都是字面量）
    std.debug.print("两处 count 都是编译期常量：{d} 与 {d}，加起来 = {d}\n", .{ c1.count, c2.count, c1.count + c2.count });
    end("13.5");

    // ═══ 13.6 @setEvalBranchQuota：编译期循环配额 ═══
    begin("13.6");
    // 默认配额是 **1000 个"向后跳转"**（backwards branches），且**按作用域累计**：
    // 不是每个循环各给1000，而是同一个作用域里所有编译期循环共用这1000。
    //
    // 实测边界：容器级一个普通 while 跑 1000 次不爆；函数体内两个 600 次的
    // inline while 连着写就爆（600+600=1200 > 1000），报错是：
    //   error: evaluation exceeded 1000 backwards branches
    //   note: use @setEvalBranchQuota() to raise the branch limit from 1000
    //
    // 本函数开头已经抬高到 2_000_000，所以这里可以放心跑 10 万次：
    comptime var big_sum: u64 = 0;
    comptime var k: u32 = 0;
    inline while (k < 100_000) : (k += 1) big_sum +%= k;
    std.debug.print("抬高配额后 inline while 0..99999 求和 = {d}\n", .{big_sum});
    // 想验证"默认配额就是 1000"：在**没有**@setEvalBranchQuota 的作用域里跑
    // 2000 次 inline while，会编译失败（正文贴了完整报错）。
    //
    // ⚠️ 实测：@setEvalBranchQuota **可以往小调**，不报错——在同一作用域里先写
    //   100_000 再写 100，编译照样通过。所以它不是"护栏"，只是"预算申请"。
    //
    // 代价：编译期算 10 万次 inline 迭代把编译时间从约 0.3 s 拉到约 4 s。
    // 这就是 comptime 的账单（见 13.12 节）。
    end("13.6");

    // ═══ 13.7 inline fn：强制内联，描述"函数体怎么处理" ═══
    begin("13.7");
    // ⚠️ inline fn 在**运行期也能调**（实测见正文）—— inline 说的是
    //    "函数体如何处理"（强制在调用点展开），不是"只在编译期调用"。
    std.debug.print("twice(21) 编译期 = {d}\n", .{twice(21)});
    const rt_in: u32 = 21;
    std.debug.print("twice(运行期 21) = {d}\n", .{twice(rt_in)});
    // @inComptime() 在普通函数里是 false。注意函数体里有 comptime 参数**也不改变**这一点——
    // comptime 参数只保证"实参在编译期已知"，不等于"函数体在编译期执行"。
    // ⚠️ 0.17 里它必须写成**无参** @inComptime()：写 @inComptime(x) 报
    //   error: expected 0 arguments, found 1
    // 而在 comptime 块里写 @inComptime() 反而报
    //   error: redundant '@inComptime' in comptime scope
    std.debug.print("inComptime：普通函数 = {}；带 comptime 参数的函数 = {}\n", .{
        probeInComptime(1),
        probeGenericInComptime(u8),
    });
    end("13.7");

    // ═══ 13.8 类型作为编译期数据：type 是一等值 ═══
    begin("13.8");
    // type 是编译期值：能当参数传给 comptime T: type
    std.debug.print("kindName(u8)={s} kindName(Header)={s}\n", .{ kindName(u8), kindName(Header) });
    // 能装进容器 —— 但遍历必须 inline for（元素是 type，运行期不存在）：
    const types = [_]type{ u8, u16, u32, u64 };
    comptime var total: usize = 0;
    inline for (types) |T| total += @sizeOf(T);
    std.debug.print("[_]type{{u8,u16,u32,u64}} 的 @sizeOf 之和 = {d}\n", .{total});
    // ⚠️ @Type 在 0.17 已被移除（error: invalid builtin function: '@Type'），
    // 所以"从 @typeInfo 的结果反向造类型"这条老路走不通了。
    // 造函数类型用 @TypeOf（见容器级的 addThenNarrow）：
    // 注意 @TypeOf(&f) 拿到的是**指针**类型，要函数类型本身得去掉 &。
    const FnPtr = @TypeOf(&addThenNarrow);
    const Fn = @typeInfo(FnPtr).pointer.child;
    std.debug.print("@TypeOf(&addThenNarrow) = {s}；剥掉指针 = {s}\n", .{ @typeName(FnPtr), @typeName(Fn) });
    // ⚠️ 0.17 不许在函数体里声明 fn（实测报expected ',' after initializer），
    // 所以上面的 addThenNarrow 必须放在容器级。
    // ⚠️ 反射类型名一律 @typeName。@tagName 只能作用于枚举/联合的**值**：
    //   @tagName(Header) → error: expected enum or union; found 'type'
    std.debug.print("typeName(Header) = {s}；typeName(u24) = {s}\n", .{ @typeName(Header), @typeName(u24) });
    std.debug.print("tagName(Stage.beta) = {s}（@tagName 只能吃枚举/联合的值）\n", .{@tagName(Stage.beta)});
    end("13.8");

    // ═══ 13.9 inline for / inline while：编译期展开循环 ═══
    begin("13.9");
    // inline for 在编译期把循环体展开 N 份（N = 序列长度）
    const names = [_][]const u8{ "alpha", "beta", "gamma" };
    inline for (names) |name| {
        std.debug.print("  inline for 展开：{s}\n", .{name});
    }
    // ⚠️ 0.17 **支持索引捕获**（旧教程说"不支持"已过时）：多写一个 `0..`
    comptime var idx_sum: usize = 0;
    comptime var joined: []const u8 = "";
    inline for (names, 0..) |name, idx| {
        idx_sum += idx;
        joined = joined ++ name ++ ";"; // ++ 拼接仍可用
    }
    std.debug.print("索引之和 = {d}；拼起来 = {s}\n", .{ idx_sum, joined });
    // 但 field_types（元素是 type）**必须** inline for，普通 for 编译失败：
    //   error: values of type 'type' must be comptime-known,
    //          but index value is runtime-known
    //   note: types are not available at runtime
    // 理由：类型是编译期实体，运行期根本没有"类型"这个值。
    const hi = @typeInfo(Header);
    std.debug.print("Header layout={t} 字段数={d}\n", .{ hi.@"struct".layout, hi.@"struct".field_names.len });
    // ⚠️ 三条平行数组（0.17 没有 .fields了）：field_names / field_types / field_attrs
    inline for (hi.@"struct".field_names, hi.@"struct".field_types, hi.@"struct".field_attrs) |fname, ftype, attrs| {
        // field_names 的元素是 [:0]const u8（哨兵切片），打印要写 fname[0..fname.len]
        std.debug.print("  字段 {s}: {s} 显式对齐={any} 有默认值={}\n", .{
            fname[0..fname.len],
            @typeName(ftype),
            attrs.@"align", // ⚠️ 0.17 里是 .@"align"（?usize），不是 .alignment
            attrs.default_value_ptr != null,
        });
    }
    std.debug.print("@offsetOf(Header, \"len\") = {d}\n", .{@offsetOf(Header, "len")});
    // error_names 是**可空**的 ?[]const [:0]const u8，得先 if (x) |y|
    const StoreError = error{ NotFound, Corrupted };
    if (@typeInfo(StoreError).error_set.error_names) |enames| {
        for (enames) |ename| std.debug.print("  错误名{s}\n", .{ename[0..ename.len]});
    }
    // ⚠️ @hasDecl 的第二个参数在 0.17 **必须给字符串**：
    //   @hasDecl(std.mem, copyForwards) → error: use of undeclared identifier
    std.debug.print("@hasDecl(std.mem, \"copyForwards\")={}；不存在的名字={}\n", .{
        @hasDecl(std.mem, "copyForwards"),
        @hasDecl(std.mem, "noSuchThingAtAll"),
    });
    end("13.9");

    // ═══ 13.10 编译期数据结构：构造查表 ═══
    begin("13.10");
    // PrimeFlags 是埃氏筛：编译期约 3 万次迭代，编译时间只多零点几秒，
    // 二进制里只剩 256 个 bool。运行期判定变成 O(1) 数组索引。
    std.debug.print("筛表覆盖 0..{d}；241 是素数吗？{}；247 是素数吗？{}\n", .{
        PrimeFlags.len - 1, isPrime(241), isPrime(247),
    });
    std.debug.print("0/1 的标记 = {} / {}（筛法要特判头两个）\n", .{ isPrime(0), isPrime(1) });
    // 表可以由表生成：Primes 就是从 PrimeFlags 里编译期抽出来的前 8 个素数
    std.debug.print("从筛表抽出的前 8 个素数 = {any}\n", .{Primes});
    inline for (Primes, 0..) |p, idx| {
        std.debug.print("  Primes[{d}] = {d}\n", .{ idx, p });
    }
    // CRC-32 表：8 轮移位异或 × 256 项 = 2048 次编译期迭代，纯编译期产物
    std.debug.print("CRC-32 幂表前 4 项 = 0x{x:0>8}, 0x{x:0>8}, 0x{x:0>8}, 0x{x:0>8}...\n", .{
        CrcTable[0], CrcTable[1], CrcTable[2], CrcTable[3],
    });
    // 用它算标准校验值：说明这张表真的对
    std.debug.print("crc32(\"123456789\") = 0x{x:0>8}（标准 CRC-32 校验值）\n", .{crc32("123456789")});
    // 编译期递归也要配额：cfib(25) 不抬配额会撞 1000 分支上限（见 13.6 节）
    const f25 = comptime blk: {
        @setEvalBranchQuota(1_000_000);
        break :blk cfib(25);
    };
    std.debug.print("cfib(25) 编译期 = {d}（类型 {s}，没定型）\n", .{ f25, @typeName(@TypeOf(f25)) });
    end("13.10");

    // ═══ 13.11 编译期算术：comptime_int 的任意精度 ═══
    begin("13.11");
    const huge = 1 << 200; // 远超 u64 的上限（约 1.8e19），这里约 1.6e60
    std.debug.print("1 << 200 = {d}\n", .{huge});
    std.debug.print("  类型 = {s}（字面量没类型，用到时才定）\n", .{@typeName(@TypeOf(huge))});
    // ⚠️ 落地时必须装得下：给 u8 就编译错
    //   const small: u8 = 300;  → error: type 'u8' cannot represent integer value '300'
    const fits: u8 = 200;
    std.debug.print("200 装进 u8 = {d}；@bitSizeOf(u8) = {d}\n", .{ fits, @bitSizeOf(u8) });
    // 编译期算阶乘：20! 装得进 u64（20! ≈ 2.4e18，u64 上限 ≈ 1.8e19）
    comptime var fact: u64 = 1;
    comptime var fi: u32 = 1;
    inline while (fi <= 20) : (fi += 1) fact *= fi;
    std.debug.print("20! = {d}（编译期算，运行期零开销）\n", .{fact});
    // ⚠️ 0.17 没有 ** 幂运算符，也没有 [_]T{x} ** n 重复填充：
    //   `2 ** 3` → error: binary operator '*' has whitespace on one side,
    //                   but not the other（报错文案有点误导）
    //   [_]u8{7} ** 4 → @splat(7) 或 @memset
    const sp: [4]u8 = @splat(7);
    std.debug.print("@splat(7) = {any}（替代 ** 重复填充）\n", .{sp});
    // @clamp 已移除（error: invalid builtin function: '@clamp'），用 @min / @max
    const a: i32 = -5;
    const b: i32 = 12;
    std.debug.print("@max(a,b)={d} @min(a,b)={d}（替代 @clamp）\n", .{ @max(a, b), @min(a, b) });
    end("13.11");

    // ═══ 13.12 comptime 的代价：编译变慢 vs 运行变快 ═══
    begin("13.12");
    // 同一个判定，两种写法：查表版 O(1)（表在编译期算）vs 试除版 O(√n)（循环在二进制里）
    std.debug.print("查表版 isPrime(241)={} isPrime(247)={}；试除版 = {} / {}\n", .{
        isPrime(241),        isPrime(247),
        isPrimeRuntime(241), isPrimeRuntime(247),
    });
    // 编译期算 vs 运行期算：两者结果相同，代价分布不同
    const rt_n: usize = 30;
    std.debug.print("fibonacci({d})：编译期常量 = {d}（运行期 0 条指令）\n", .{ rt_n, fibonacci(25) });
    std.debug.print("fibonacci({d})：运行期递归 = {d}（几十条 call 指令）\n", .{ rt_n, fibonacci(rt_n) });
    // @sizeOf / @typeName / @typeInfo / @offsetOf 全都是 comptime 内建——
    // 写它们**不需要**"进编译期"，也不需要 comptime 关键字：
    std.debug.print("@sizeOf(Conf)={d} @typeName(u24)={s} @bitSizeOf(u24)={d}\n", .{
        @sizeOf(Conf),
        @typeName(u24),
        @bitSizeOf(u24),
    });
    // 编译期的红线：IO 与堆内存不行。
    //   comptime { std.debug.print(...); }
    //   → error: unable to resolve comptime value
    //     note: called at comptime from here（std/Io/Threaded.zig 里Thread.current 求值失败）
    std.debug.print("comptime 里不能 print（unable to resolve comptime value），也不能分配堆内存\n", .{});
    end("13.12");

    std.debug.print("自检通过\n", .{});
}

/// 13.7 节用：@inComptime() 在普通函数里恒为 false。
fn probeInComptime(x: u32) bool {
    _ = x;
    return @inComptime();
}

/// 13.7 节用：带 comptime 参数的函数里 @inComptime() **也是** false——
/// comptime 参数只约束实参，不等于函数体在编译期执行。
inline fn probeGenericInComptime(comptime T: type) bool {
    _ = T;
    return @inComptime();
}

/// 13.10 节用：运行期查表版素数判定（表在编译期生成，判定 O(1)）。
fn isPrime(n: u16) bool {
    if (n >= PrimeFlags.len) return false; // 表只覆盖 0..255
    return PrimeFlags[n];
}

/// 13.12 节用：运行期试除版素数判定（完整循环在二进制里，O(√n)）。
fn isPrimeRuntime(n: u16) bool {
    if (n < 2) return false;
    var d: u16 = 2;
    while (d * d <= n) : (d += 1) {
        if (n % d == 0) return false;
    }
    return true;
}

/// 13.10 节用：标准 CRC-32，验证编译期生成的表是对的。
fn crc32(data: []const u8) u32 {
    var crc: u32 = 0xFFFFFFFF;
    for (data) |byte| {
        const idx: u32 = (crc ^ @as(u32, byte)) & 0xFF;
        crc = (crc >> 8) ^ CrcTable[idx];
    }
    return crc ^ 0xFFFFFFFF;
}

// ══════════════════════════════════════════════════════════════════
// 测试：把本章的语义钉死
// ══════════════════════════════════════════════════════════════════

test "13.1 一份代码两个世界：fibonacci 两栖" {
    try std.testing.expectEqual(@as(usize, 55), fibonacci(10));
    try std.testing.expectEqual(@as(usize, 1), fibonacci(1));
    var rt: usize = 30;
    rt += 1;
    try std.testing.expectEqual(@as(usize, 1346269), fibonacci(rt));
    // const 能装运行期算出来的值 → const ≠ comptime
    const from_runtime: usize = fibonacci(rt);
    try std.testing.expectEqual(@as(usize, 1346269), from_runtime);
}

test "13.2 comptime 参数在编译期求值，传运行期值编译不过" {
    try std.testing.expectEqual(@as(u64, 1024), pow(2, 10));
    try std.testing.expectEqual(@as(u64, 243), pow(3, 5));
    try std.testing.expectEqual(@as(u64, 1), pow(5, 0));
    // 结果类型由参数类型决定（u64），不是 comptime_int
    try std.testing.expectEqualStrings("u64", @typeName(@TypeOf(pow(2, 10))));
}

test "13.3 labeled block 是块表达式；容器级写 comptime 是冗余的" {
    const t = blk: {
        var buf: [4]u8 = undefined;
        for (0..4) |i| buf[i] = @intCast(i * 3);
        break :blk buf;
    };
    try std.testing.expectEqualSlices(u8, &.{ 0, 3, 6, 9 }, &t);
    // 函数体里加 comptime 强制求值
    const v = comptime blk: {
        var acc: usize = 0;
        for (0..5) |k| acc += k;
        break :blk acc;
    };
    try std.testing.expectEqual(@as(usize, 10), v);
}

test "13.4 改 comptime 变量的循环必须是 inline while" {
    comptime var acc: u32 = 0;
    comptime var i: u32 = 0;
    inline while (i < 10) : (i += 1) acc +%= i;
    try std.testing.expectEqual(@as(u32, 45), acc);
    try std.testing.expectEqual(@as(u32, 10), i);
    // inline for 同理
    comptime var s2: usize = 0;
    inline for (.{ 3, 5, 7 }) |v| s2 += v;
    try std.testing.expectEqual(@as(usize, 15), s2);
}

test "13.5 泛型与显式 comptime 参数是同一个机制" {
    try std.testing.expectEqual(@as(u8, 10), genericSum(&.{ 1, 2, 3, 4 }));
    try std.testing.expectEqual(@as(u64, 60), genericSum(&.{ 10, 20, 30 }));
    const c = makeConf("gamma", 9);
    try std.testing.expectEqualStrings("gamma", c.name);
    try std.testing.expectEqual(@as(u32, 9), c.count);
    // Conf 的运行期实例类型完全相同
    var n: u32 = 4;
    n += 1;
    const c2: Conf = .{ .name = "delta", .count = n };
    try std.testing.expectEqual(@as(usize, @sizeOf(Conf)), @sizeOf(@TypeOf(c2)));
}

test "13.7 inline fn 运行期也能调；@inComptime() 无参且在普通函数为 false" {
    try std.testing.expectEqual(@as(u32, 42), twice(21));
    const rt: u32 = 21;
    try std.testing.expectEqual(@as(u32, 42), twice(rt));
    try std.testing.expect(!probeInComptime(1));
    // 带 comptime 参数的函数体内@inComptime() 也是 false
    try std.testing.expect(!probeGenericInComptime(u8));
}

test "13.8 type是一等值；@Type 已移除，@tagName 不能作用于类型" {
    try std.testing.expectEqualStrings("结构体", kindName(Header));
    try std.testing.expectEqualStrings("整数", kindName(u8));
    // type 能装进容器（遍历要inline for：元素是 type，运行期不存在）
    const types = [_]type{ u8, u32, u64 };
    comptime var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);
    try std.testing.expectEqual(@as(usize, 1 + 4 + 8), sum);
    // @TypeOf 拿函数类型（@Type 在 0.17 已移除；函数体里也不能声明 fn）
    try std.testing.expectEqualStrings("fn (u32, u32) u8", @typeName(@TypeOf(addThenNarrow)));
    try std.testing.expectEqualStrings("fn (u32, u32) u8", @typeName(@typeInfo(@TypeOf(&addThenNarrow)).pointer.child));
    try std.testing.expectEqual(@as(u8, 7), addThenNarrow(3, 4));
    // 反射类型名一律 @typeName
    try std.testing.expectEqualStrings("main.Header", @typeName(Header));
}

test "13.9 反射三条平行数组 + inline for；@hasDecl 必须给字符串" {
    const hi = @typeInfo(Header);
    try std.testing.expectEqual(@as(usize, 3), hi.@"struct".field_names.len);
    // field_names 的元素是哨兵切片
    try std.testing.expectEqualStrings("magic", hi.@"struct".field_names[0][0..5]);
    try std.testing.expectEqualStrings("len", hi.@"struct".field_names[1][0..3]);
    try std.testing.expectEqualStrings("ok", hi.@"struct".field_names[2][0..2]);
    // .layout 不是 .tag（枚举类型是 std.lang.ContainerLayout）
    try std.testing.expectEqualStrings("lang.Type.ContainerLayout", @typeName(@TypeOf(hi.@"struct".layout)));
    try std.testing.expect(hi.@"struct".layout == .auto);
    // field_types 元素是 type，可以直接下标断言
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(hi.@"struct".field_types[0]));
    try std.testing.expectEqual(@as(usize, 2), @sizeOf(hi.@"struct".field_types[1]));
    // field_attrs 的显式对齐是 ?usize
    try std.testing.expect(hi.@"struct".field_attrs[0].@"align" == null);
    try std.testing.expect(hi.@"struct".field_attrs[1].default_value_ptr != null);
    // 索引捕获在 0.17 可用
    comptime var joined: []const u8 = "";
    inline for (.{ "a", "b", "c" }, 0..) |name, idx| {
        _ = idx;
        joined = joined ++ name;
    }
    try std.testing.expectEqualStrings("abc", joined);
    // @hasDecl 第二个参数必须是字符串
    try std.testing.expect(@hasDecl(std.mem, "copyForwards"));
    try std.testing.expect(!@hasDecl(std.mem, "noSuchThingAtAll"));
    // error_names 是可空的
    const ei = @typeInfo(error{ NotFound, Corrupted });
    try std.testing.expect(ei.error_set.error_names != null);
    try std.testing.expectEqualStrings("NotFound", ei.error_set.error_names.?[0][0..8]);
}

test "13.10 编译期算出的数据表能直接用于运行期查询" {
    try std.testing.expectEqual(@as(u32, 2), Primes[0]);
    try std.testing.expectEqual(@as(u32, 19), Primes[7]);
    try std.testing.expect(isPrime(2));
    try std.testing.expect(isPrime(19));
    try std.testing.expect(isPrime(241));
    try std.testing.expect(!isPrime(247));
    try std.testing.expect(!isPrime(0));
    try std.testing.expect(!isPrime(1));
    // 表覆盖范围外一律 false（不猜）
    try std.testing.expect(!isPrime(256));
    try std.testing.expect(!isPrime(1000));
    // CRC 表验证：标准 CRC-32 的已知答案
    try std.testing.expectEqual(@as(u32, 0xCBF43926), crc32("123456789"));
    // 编译期递归
    const f25 = comptime blk: {
        @setEvalBranchQuota(1_000_000);
        break :blk cfib(25);
    };
    try std.testing.expectEqual(@as(comptime_int, 75025), f25);
}

test "13.11 comptime_int 任意精度但落地要装得下" {
    const huge = 1 << 200;
    try std.testing.expectEqualStrings("comptime_int", @typeName(@TypeOf(huge)));
    try std.testing.expect(huge > std.math.maxInt(u64));
    // 装得下才合法
    const fits: u8 = 200;
    try std.testing.expectEqual(@as(u8, 200), fits);
    // 20! 编译期算得出来
    comptime var fact: u64 = 1;
    comptime var fi: u32 = 1;
    inline while (fi <= 20) : (fi += 1) fact *= fi;
    try std.testing.expectEqual(@as(u64, 2432902008176640000), fact);
    // @splat 替代 ** 重复填充
    const sp: [4]u8 = @splat(7);
    try std.testing.expectEqualSlices(u8, &.{ 7, 7, 7, 7 }, &sp);
    // @min / @max 替代 @clamp
    try std.testing.expectEqual(@as(i32, 12), @max(@as(i32, -5), @as(i32, 12)));
    try std.testing.expectEqual(@as(i32, -5), @min(@as(i32, -5), @as(i32, 12)));
}

test "13.12 查表版与试除版结果一致，但成本不同" {
    for ([_]u16{ 0, 1, 2, 3, 4, 31, 33, 97, 100, 241, 247, 255 }) |n| {
        try std.testing.expectEqual(isPrimeRuntime(n), isPrime(n));
    }
    // 编译期断言也守着 0.17 的若干版本敏感点
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Header));
    try std.testing.expectEqual(@as(usize, 4), @offsetOf(Header, "len"));
    // @addWithOverflow 的标志位是 u1不是 bool
    const ov = @addWithOverflow(@as(u8, 250), @as(u8, 10));
    try std.testing.expectEqual(@as(u8, 4), ov[0]);
    try std.testing.expect(ov[1] == 1);
    // undefined 的内容是**未指定**：macOS 0.17 实测填 0x00，Windows 0.17.0 实测是 0x04——
    // 只能演示不能断言（这正是"别读 undefined"的活教材）
    const u: u32 = undefined;
    _ = u;
}
