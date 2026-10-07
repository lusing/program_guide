//! 04 控制流：if 是表达式、while 的 continue 表达式、循环作为表达式、for 的四种迭代形态、标签三兄弟（loop/block/switch）、switch 的穷尽性与负载捕获、orelse/catch、defer/errdefer、@branchHint、inline for
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 4.2/4.3 节的分派对象：一个自己声明的错误集（不是 anyerror）
const ParseError = error{ Empty, BadDigit, Overflow };

/// 4.2 节：把"字符→数值"的失败做成错误联合，而不是返回哨兵值
fn parseHexDigit(ch: u8) ParseError!u8 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        'a'...'f' => ch - 'a' + 10,
        'A'...'F' => ch - 'A' + 10,
        else => error.BadDigit,
    };
}

/// 4.2 节：调用方用 try 往上抛，决策留给调用者
fn sumHex(text: []const u8) ParseError!u32 {
    var acc: u32 = 0;
    for (text) |ch| {
        const digit = try parseHexDigit(ch);
        const wide: u32 = digit; // 算术不宽化（03 章 3.5节）：先点出u32
        if (acc > (std.math.maxInt(u32) - wide) / 16) return error.Overflow;
        acc = acc * 16 + wide;
    }
    return acc;
}

/// 4.10/4.11 节：枚举 switch 的穷尽性、union(enum) 的负载捕获
const Color = enum(u8) { red, green, blue };

/// 4.11 节的测试用：给 union(enum) 的 rect 形态起个名字，好写 ?Dims
const Dims = struct { w: f64, h: f64 };

const Shape = union(enum) {
    dot,
    circle: f64,
    rect: Dims,
};

fn areaOf(s: Shape) f64 {
    return switch (s) {
        .dot => 0,
        .circle => |r| 3.0 * r * r,
        .rect => |rect| rect.w * rect.h,
    };
}

/// 4.12 节：状态机的三个状态
const St = enum { idle, running, done };

pub fn main() !void {
    // ═══ 4.1 if 是表达式：Zig 没有三元运算符 ═══
    begin("4.1");
    const a: u32 = 5;
    const b: u32 = 4;
    // if 直接产出值，出现在赋值右边
    const result: u32 = if (a != b) 47 else 3089;
    std.debug.print("if 表达式 = {d}\n", .{result});
    // else if 链同样是表达式：把 if-else 赋值写成一个 return
    std.debug.print("85 → {s}，59 → {s}\n", .{ gradeLabel(85), gradeLabel(59) });
    // 嵌套 if 也是表达式——想写"合并两个可选"时最自然的形态
    const m1: ?u8 = 3;
    const m2: ?u8 = null;
    const merged: u8 = if (m1) |x| if (m2) |y| x + y else x else 0;
    std.debug.print("合并 {any} 与 {any} = {d}（m2 是 null，退回 m1）\n", .{ m1, m2, merged });
    // if 的条件必须是 bool：`if (1)` 编译不过（03 章 3.5 节：bool 不能当数字用）
    std.debug.print("条件类型 = {s}\n", .{@typeName(@TypeOf(a != b))});
    end("4.1");

    // ═══ 4.2 if 捕获可选与错误联合：0.17 分派的唯一入口 ═══
    begin("4.2");
    const maybe: ?u8 = 7;
    if (maybe) |v| {
        std.debug.print("可选有值：{d}\n", .{v});
    } else {
        std.debug.print("可选是 null\n", .{});
    }
    // 错误联合：成功走 |v|，失败走 |err|，err 是 error set 值
    if (sumHex("1a2b")) |v| {
        std.debug.print("sumHex(\"1a2b\") = 0x{x} = {d}\n", .{ v, v });
    } else |err| {
        std.debug.print("sumHex 失败：{s}\n", .{@errorName(err)});
    }
    if (sumHex("zz")) |v| {
        std.debug.print("不该走到这：{d}\n", .{v});
    } else |err| {
        std.debug.print("sumHex(\"zz\") 失败：{s}\n", .{@errorName(err)});
    }
    if (sumHex("1ffffffff")) |v| {
        std.debug.print("不该走到这：{d}\n", .{v});
    } else |err| {
        std.debug.print("sumHex(\"1ffffffff\") 失败：{s}\n", .{@errorName(err)});
    }
    // ⚠️ 0.17 **不再支持**一次捕获多个：`if (mx and my) |x, y|` 报
    //     error: expected '|', found ','
    // 正解是嵌套（见 4.1 节的 merged），或者先把其中一个 orelse 掉。
    std.debug.print("错误集大小 = {d}，声明顺序 = {s}\n", .{ @typeInfo(ParseError).error_set.error_names.?.len, @typeName(ParseError) });
    end("4.2");

    // ═══ 4.3 orelse / catch / catch |err|：给"可能没有"兜底 ═══
    begin("4.3");
    const missing: ?u8 = null;
    const present: ?u8 = 5;
    std.debug.print("null orelse 0 = {d}；有值 orelse 0 = {d}（有值时 orelse 根本不参与）\n", .{ missing orelse 0, present orelse 0 });
    // catch 处理错误联合；`catch |err|` 拿到错误值
    std.debug.print("失败 catch 0 = {d} ", .{sumHex("zz") catch 0});
    std.debug.print("成功 catch 0 = {d}\n", .{sumHex("1a") catch 0});
    std.debug.print("catch |err| 区分错误 = {d}\n", .{
        sumHex("zz") catch |err| @as(u32, if (err == error.BadDigit) 16 else 32),
    });
    // ⚠️ 0.17：{d} 不能直接打印错误联合（error: invalid format string 'd' for type
    //     'ParseError!i32'），要先把成功/失败拆开，再决定用哪个格式符
    if (firstEvenOrFail(&[_]i32{ 1, 2, 4 })) |v| {
        std.debug.print("firstEvenOrFail([1,2,4]) = {d}\n", .{v});
    } else |err| {
        std.debug.print("不该到这：{s}\n", .{@errorName(err)});
    }
    if (firstEvenOrFail(&[_]i32{ 1, 3, 5, 7 })) |v| {
        std.debug.print("不该到这：{d}\n", .{v});
    } else |err| {
        std.debug.print("firstEvenOrFail([1,3,5,7]) 失败 = {s}\n", .{@errorName(err)});
    }
    end("4.3");

    // ═══ 4.4 while 与 continue 表达式 ═══
    begin("4.4");
    var i: usize = 0;
    var sum: usize = 0;
    while (i < 5) : (i += 1) {
        if (i == 2) continue; // continue 也会先跑 : (i += 1)，所以不会死循环
        sum += i;
    }
    std.debug.print("0..4 去掉 2 = {d}；循环结束时 i = {d}\n", .{ sum, i });
    // while 可以直接迭代"可空序列的元素"，遇到 null 自然停
    const opt_iter = [_]?u8{ 7, null, 9 };
    var oi: usize = 0;
    while (opt_iter[oi]) |v| : (oi += 1) {
        std.debug.print("  可选元素 {d}\n", .{v});
    }
    std.debug.print("停在第 {d} 个（null 处停住，后面的 9 没被看到）\n", .{oi});
    // ⚠️ 0.17 的 `while (expr) |v|` **只吃可选**，不吃错误联合：
    //     `while (sumHex("f")) |v| {}` → error: expected optional type, found 'ParseError!u32'
    //     + note: consider using 'try', 'catch', or 'if'
    //     错误联合请用 4.2 节的 if/else 形态。
    var n: u8 = 0;
    while (n < 8) : (n += 1) {
        if (parseHexDigit('0' + n)) |d| {
            std.debug.print("  数字 {d}\n", .{d});
        } else |err| {
            std.debug.print("  在 '{c}' 处停止：{s}\n", .{ @as(u8, '0' + n), @errorName(err) });
            break;
        }
    }
    end("4.4");

    // ═══ 4.5 循环也是表达式：for/while ... else 与 break value ═══
    begin("4.5");
    // else 分支的语义是"**没有因为 break 提前退出**"——包括一次都没迭代的情况
    var acc: u32 = 0;
    const stopped_early = for ("7f") |ch| {
        const digit = try parseHexDigit(ch);
        acc = acc * 16 + digit;
        if (acc > 0x10) break true; // break 带值 → 整个 for 表达式的值
    } else false;
    std.debug.print("累加到 0x{x}，超过 0x10 就停 = {}（走了 break 分支）\n", .{ acc, stopped_early });
    acc = 0;
    const ran_to_end = for ("12") |ch| {
        const digit = try parseHexDigit(ch);
        acc = acc * 16 + digit;
        if (acc > 0xFFFF) break true;
    } else false;
    std.debug.print("累加到 0x{x}，跑完没 break = {}（走了 else 分支）\n", .{ acc, ran_to_end });
    // 一次都没迭代也算"没 break"→ else 照样执行
    var touched: usize = 0;
    _ = for ([_]u8{}) |_| {
        touched += 1;
        unreachable; // 永不执行
    } else true;
    std.debug.print("空序列：循环体执行 {d} 次，else 仍然执行\n", .{touched});
    // while 也有 else
    var k: u8 = 0;
    const hit_two = while (k < 5) : (k += 1) {
        if (k == 2) break true;
    } else false;
    std.debug.print("while-else：k 停在 {d}，hit={}\n", .{ k, hit_two });
    // break 带值 + 没有 else 时，循环的"走完"出口是 void → 类型冲突。
    // 要么补 else 给值，要么包一层 labeled block（见 4.9 节）。
    end("4.5");

    // ═══ 4.6 for 的四种迭代形态 ═══
    begin("4.6");
    const names = [_][]const u8{ "C", "Zig", "Rust" };
    const years = [_]u16{ 1972, 2016, 2015 };
    // ① 多序列 zip + 0.. 当下标
    for (names, years, 0..) |name, year, idx| {
        std.debug.print("  [{d}] {s} 诞生于 {d}\n", .{ idx, name, year });
    }
    // ② 范围：0..5 左闭右开
    var range_sum: usize = 0;
    for (0..5) |idx_k| range_sum += idx_k;
    std.debug.print("0..5 的和 = {d}\n", .{range_sum});
    // ③ 切片：遍历一部分（冒号后两个点才是切片语法）
    var head: i32 = 0;
    for (names[0..2]) |name| {
        std.debug.print("  前两个：{s}（{d} 字节）\n", .{ name, name.len });
        head += 1;
    }
    std.debug.print("names[0..2] 长度 = {d}\n", .{head});
    // ④ 按下标：拿不到下标就多写一个序列
    var idx_sum: usize = 0;
    for (0..names.len) |idx| idx_sum += idx;
    std.debug.print("下标之和 = {d}\n", .{idx_sum});
    // 没有 C 风格 for (i = 0; i < n; i++)：需要复杂步进就写 while + continue 表达式
    var rev: usize = 0;
    var down: usize = names.len;
    while (down > 0) : (down -= 1) rev = rev * 10 + down;
    std.debug.print("倒着数 = {d}\n", .{rev});
    end("4.6");

    // ═══ 4.7 指针捕获：改元素，而不是改副本 ═══
    begin("4.7");
    var nums = [_]u8{ 1, 2, 3 };
    for (nums) |v| {
        _ = v; // v 是拷贝，改它没用
    }
    for (&nums) |*p| p.* *%= 10; // p 是 *u8，改的是数组本身
    std.debug.print("for (&nums) |*p| 改完 = {any}\n", .{nums});
    for (&nums) |*p| {
        if (p.* == 20) p.* = 99;
    }
    std.debug.print("再改一个 = {any}\n", .{nums});
    // ⚠️ `for (nums) |*v|`（不带 &）报 error: pointer capture of non pointer type '[3]u8'
    //     + note: consider using '&' here
    // 指针捕获 + 下标组合：这就是"边遍历边改元素"的标准写法
    var flags = [_]bool{ false, true, false };
    for (&flags, 0..) |*flag, idx_f| {
        if (flag.*) continue;
        flag.* = @as(bool, idx_f == 2);
    }
    std.debug.print("flags = {any}（下标 2 的 false 被翻成 true）\n", .{flags});
    end("4.7");

    // ═══ 4.8 标签一：labeled loop 跨层跳出 ═══
    begin("4.8");
    var visited: usize = 0;
    outer: for (1..4) |x| {
        for (1..4) |y| {
            if (y > x) continue :outer; // 跳到外层下一轮
            visited += 1;
        }
    }
    std.debug.print("continue :outer → visited = {d}\n", .{visited});
    // break :label value 想产出值时，走完的出口也要给值 → 用 else 补
    var pairs: usize = 0;
    const found: usize = find: for (0..5) |row| {
        for (0..5) |col| {
            pairs += 1;
            if (row * row + col * col == 9) break :find @as(usize, row * 10 + col);
        }
    } else 0;
    std.debug.print("break :find → 找到 {d}，用了 {d} 次迭代（找到就一层跳出）\n", .{ found, pairs });
    end("4.8");

    // ═══ 4.9 标签二：labeled block，块也有值和 defer ═══
    begin("4.9");
    const first_even = blk: {
        var idx: usize = 0;
        while (idx < 10) : (idx += 1) {
            if (@mod(idx, 2) == 0) break :blk idx; // 从 while 内部跳出任意多层
        }
        break :blk @as(usize, 999); // 兜底出口：块必须有值
    };
    std.debug.print("第一个偶数下标 = {d}\n", .{first_even});
    // labeled block 能把 defer 圈在局部：块结束 = defer 触发
    const rect_area = blk: {
        defer std.debug.print("  （块里的 defer，块结束就跑）\n", .{});
        break :blk areaOf(.{ .rect = .{ .w = 3, .h = 4 } });
    };
    std.debug.print("labeled block 的值 = {d:.1}\n", .{rect_area});
    // labeled block 的第二个用途：给多语句一个结果位置（Zig 没有逗号表达式）
    const swapped = blk: {
        const x: i32 = 3;
        const y: i32 = 4;
        break :blk .{ y, x };
    };
    std.debug.print("交换两个常量 = {any}\n", .{swapped});
    end("4.9");

    // ═══ 4.10 switch：多值、范围（三个点）、穷尽性 ═══
    begin("4.10");
    for ([_]u8{ 1, 3, 5, 9, 200 }) |v| {
        // u8 值域 256 个，编译器无法证明穷尽 → 必须写 else
        const desc = switch (v) {
            1, 2, 3 => "低", // 多值并列，不用 fallthrough
            4...9 => "中", // 范围是三个点；写1..3 报 error: expected '=>', found '..'
            10...99 => "高",
            else => "爆表",
        };
        std.debug.print("{d}→{s} ", .{ v, desc });
    }
    std.debug.print("\n", .{});
    // 枚举不需要 else：写多了反而报 error: unreachable else prong; all cases already handled
    const c: Color = .green;
    const color_name = switch (c) {
        .red => "红",
        .green => "绿",
        .blue => "蓝",
    };
    std.debug.print("Color 穷尽 = {s}；Color 有 {d} 个成员\n", .{ color_name, @typeInfo(Color).@"enum".field_names.len });
    // 范围可以带负数，端点必须同类
    for ([_]i32{ -100, -1, 0, 5, 50 }) |v| {
        const bucket = switch (v) {
            -100...0 => "负或零",
            1...9 => "个位",
            10...99 => "两位",
            else => "三位以上",
        };
        std.debug.print("{d}→{s} ", .{ v, bucket });
    }
    std.debug.print("\n", .{});
    // switch 也是表达式，每个分支必须同类型
    const grade: u8 = 77;
    const verdict = switch (grade) {
        90...100 => "A+",
        60...89 => "及格",
        else => "要补考",
    };
    std.debug.print("77 分 → {s}\n", .{verdict});
    end("4.10");

    // ═══ 4.11 switch 捕获 union(enum) 的负载 ═══
    begin("4.11");
    std.debug.print("dot   面积 = {d:.1}\n", .{areaOf(.{ .dot = {} })});
    std.debug.print("circle 面积 = {d:.2}（3.0 * 2 * 2）\n", .{areaOf(.{ .circle = 2 })});
    std.debug.print("rect   面积 = {d:.1}（3 * 4）\n", .{areaOf(.{ .rect = .{ .w = 3, .h = 4 } })});
    // 捕获的载荷是"该形态字段的**副本**"，类型就是字段类型（这里 |r| 是 f64，|rect| 是那个匿名 struct）
    std.debug.print("载荷类型：|r| 是 {s}，|rect| 是 {s}\n", .{ @typeName(@TypeOf(@as(Shape, undefined).circle)), @typeName(@TypeOf(@as(Shape, undefined).rect)) });
    end("4.11");

    // ═══ 4.12 标签三：labeled switch做状态机 ═══
    begin("4.12");
    var st: St = .idle;
    const ticks: u8 = 2; // 状态机走过的步数（写法二里手工数）
    // 写法一：枚举操作数 + continue :label（不包 while）
    const walk = sw: switch (st) {
        .idle => {
            st = .running;
            continue :sw st;
        },
        .running => {
            st = .done;
            continue :sw st;
        },
        .done => break :sw ticks,
    };
    std.debug.print("枚举版：idle→running→done，终值 {d}，st 现在是 {t}\n", .{ walk, st });
    // 写法二：整数操作数（0.14+：continue :label 后面不必是枚举值）
    var code: u8 = 1;
    var seen: [8]u8 = undefined;
    var seen_len: usize = 0;
    const final_code: u8 = code_sw: switch (code) {
        1 => {
            seen[seen_len] = 1;
            seen_len += 1;
            code = 2;
            continue :code_sw code;
        },
        2 => {
            seen[seen_len] = 2;
            seen_len += 1;
            code = 9;
            continue :code_sw code;
        },
        9 => break :code_sw 99,
        else => break :code_sw 0,
    };
    std.debug.print("整数版：见过 {any}，终值 {d}（9 不是枚举成员，靠 else 兜底）\n", .{ seen[0..seen_len], final_code });
    // 对照：同样的状态机用 "while 包 switch" 写要多少层
    var op: u8 = 1;
    var steps: u8 = 0;
    while (true) {
        switch (op) {
            1 => {
                op = 2;
                steps += 1;
                continue;
            },
            2 => {
                op = 3;
                steps += 1;
                continue;
            },
            3 => break,
            else => break,
        }
    }
    std.debug.print("对照写法：while 包 switch 要额外管一个 op 变量，步数 {d}\n", .{steps});
    end("4.12");

    // ═══ 4.13 defer / errdefer：控制流的倒序退出 ═══
    begin("4.13");
    defer std.debug.print("main 的 defer：main 退出时才跑（全程序最后一行）\n", .{});
    deferOrder();
    _ = scoped() catch {};
    end("4.13");

    // ═══ 4.14 @branchHint：给分支预测器一个提示 ═══
    begin("4.14");
    const flag: u8 = 7;
    if (flag > 3) {
        // ⚠️ 0.17 的 @branchHint 是**独立语句**，且必须放在分支体的第一句。
        //    写成 `if (@branchHint(.likely) flag > 3)` 报 error: expected ')', found 'an identifier'
        //    写在 if 之前独立一行报 error: '@branchHint' must appear as the first statement
        //              in a function or conditional branch
        @branchHint(.likely);
        std.debug.print("flag > 3：大概率分支\n", .{});
    }
    if (flag > 1000) {
        @branchHint(.unlikely);
        std.debug.print("flag > 1000（小概率分支，不会执行到这里）\n", .{});
    }
    // 它不改语义，只影响 LLVM 生成的分支权重与代码布局。
    end("4.14");

    // ═══ 4.15 inline for：循环体在编译期展开 ═══
    begin("4.15");
    // 普通 for 的迭代值是运行期的；inline for 让每次迭代都是编译期常量，
    // 于是循环体里可以用 switch 按值挑**类型**（03 章 3.10 节）
    comptime var name_bytes: usize = 0;
    inline for ([_]type{ u8, i32, f64 }) |T| {
        name_bytes += @typeName(T).len;
    }
    std.debug.print("u8/i32/f64 的类型名长度之和 = {d}（2+3+3，编译期算好）\n", .{name_bytes});
    // 同样的形状写普通 for 就编译不过：普通 for 的 T 是运行期的，
    // 而"类型"是编译期实体 → error: values of type 'type' must be comptime-known
    comptime var sizes: usize = 0;
    inline for ([_]type{ u8, i32, f64 }) |T| sizes += @sizeOf(T);
    std.debug.print("sizeOf 之和 = {d}\n", .{sizes});
    end("4.15");

    std.debug.print("自检通过\n", .{});
}

/// 4.3 节：把"没有就往上抛"写成一个词（Zig 不允许在函数体里嵌套 fn 声明）
fn firstEvenOrFail(xs: []const i32) ParseError!i32 {
    for (xs, 0..) |x, i| {
        if (@mod(x, 2) == 0) return x;
        if (i == 3) return error.Empty;
    }
    return error.Empty;
}

/// 4.3 节测试用：orelse 的"惰性"证明——带副作用的运行期函数
fn mkFallback(flag: *bool) u8 {
    flag.* = true;
    return 0;
}

/// if-else 链当表达式用：整个函数体就是一个 return，没有临时变量
fn gradeLabel(score: u8) []const u8 {
    return if (score >= 90) "优秀" else if (score >= 60) "及格" else "不及格";
}

/// defer 是后进先出：两个 defer 按注册顺序的**逆序**执行
fn deferOrder() void {
    std.debug.print("deferOrder：\n", .{});
    defer std.debug.print("  defer A\n", .{}); // 后注册
    defer std.debug.print("  defer B\n", .{}); // 先注册
    std.debug.print("  body\n", .{});
}

/// errdefer 只在本函数**以错误返回**时执行；defer 无论成败都执行
fn scoped() ParseError!u8 {
    errdefer std.debug.print("  errdefer：只在出错时跑\n", .{});
    defer std.debug.print("  scoped 的 defer：无论成败都跑\n", .{});
    return error.Empty;
}

test "if 是表达式：整条if-else 链可以是一个值" {
    try std.testing.expectEqualStrings("优秀", gradeLabel(95));
    try std.testing.expectEqualStrings("及格", gradeLabel(70));
    try std.testing.expectEqualStrings("不及格", gradeLabel(59));
    // 边界值：90 优秀、60 及格，说明比较用的是 >=
    try std.testing.expectEqualStrings("优秀", gradeLabel(90));
    try std.testing.expectEqualStrings("及格", gradeLabel(60));
    // 嵌套 if 做表达式
    const a: u32 = 5;
    const b: u32 = 4;
    try std.testing.expectEqual(@as(u32, 47), if (a != b) 47 else 3089);
    try std.testing.expectEqual(@as(u32, 3089), if (a == b) 47 else 3089);
}

test "if 捕获可选与错误联合" {
    try std.testing.expectEqual(@as(u8, 3), parseHexDigit('3'));
    try std.testing.expectEqual(@as(u8, 10), parseHexDigit('a'));
    try std.testing.expectEqual(@as(u8, 15), parseHexDigit('F'));
    try std.testing.expectError(error.BadDigit, parseHexDigit('z'));
    // if/else 两个分支都能观察到：成功拿到值、失败拿到 error set 值
    var ok_path: ?u32 = null;
    if (sumHex("1a2b")) |v| {
        ok_path = v;
    } else |err| {
        // ⚠️ 0.17 里 `_ = err;` 报 error: error set is discarded
        //错误值只能被比较、switch、@errorName 这些真正消费它的操作使用
        if (err == error.Overflow) ok_path = null;
    }
    try std.testing.expectEqual(@as(u32, 0x1a2b), ok_path.?);
    var err_name: []const u8 = "";
    if (sumHex("zz")) |v| {
        _ = v;
    } else |err| err_name = @errorName(err);
    try std.testing.expectEqualStrings("BadDigit", err_name);
    // 三个 catch 分支互斥
    try std.testing.expectEqual(@as(u32, 0x1a2b), try sumHex("1a2b"));
    try std.testing.expectEqual(@as(u32, 0), sumHex("zz") catch 0);
}

test "orelse / catch / catch |err|" {
    const missing: ?u8 = null;
    const present: ?u8 = 5;
    try std.testing.expectEqual(@as(u8, 0), missing orelse 0);
    // 有值时 orelse 右边不被求值（下面用带副作用的运行期函数证明这一点）
    var evaluated = false;
    // orelse 的右边只在左边为 null 时才求值。用带副作用的运行期函数调用做证明：
    // 直接写进orelse 表达式里（先存进const 的话调用本身就已经执行了）。
    try std.testing.expectEqual(@as(u8, 5), present orelse mkFallback(&evaluated));
    try std.testing.expect(!evaluated);
    // 反过来左边是 null 时一定走右边
    try std.testing.expectEqual(@as(u8, 0), missing orelse mkFallback(&evaluated));
    try std.testing.expect(evaluated);
    try std.testing.expectEqual(@as(u32, 0x1a2b), sumHex("1a2b") catch 0);
    const mapped: u32 = sumHex("zz") catch |err| @as(u32, if (err == error.BadDigit) 16 else 32);
    try std.testing.expectEqual(@as(u32, 16), mapped);
    const mapped2: u32 = sumHex("1ffffffff") catch |err| @as(u32, if (err == error.Overflow) 64 else 0);
    try std.testing.expectEqual(@as(u32, 64), mapped2);
}

test "continue 表达式在 continue 时也会执行" {
    var i: usize = 0;
    var sum: usize = 0;
    while (i < 5) : (i += 1) {
        if (i == 2) continue; // 步进依然执行，所以不会死循环
        sum += i;
    }
    try std.testing.expectEqual(@as(usize, 8), sum);
    try std.testing.expectEqual(@as(usize, 5), i);
    // while 迭代可选元素：null 处自然停止
    const seq = [_]?u8{ 7, null, 9 };
    var seen: u8 = 0;
    var idx: usize = 0;
    while (seq[idx]) |v| : (idx += 1) {
        seen += v;
    }
    try std.testing.expectEqual(@as(usize, 1), idx); // 只走到第 1 个
    try std.testing.expectEqual(@as(u8, 7), seen);
}

test "循环 else：有 break 走 break，没 break（含 0 次迭代）走 else" {
    var acc: u32 = 0;
    const stopped = for ("7f") |ch| {
        acc = acc * 16 + @as(u32, try parseHexDigit(ch));
        if (acc > 0x10) break true;
    } else false;
    try std.testing.expect(stopped);
    try std.testing.expectEqual(@as(u32, 0x7f), acc);
    // 没 break → else
    var acc2: u32 = 0;
    const ran_out = for ("12") |ch| {
        acc2 = acc2 * 16 + @as(u32, try parseHexDigit(ch));
        if (acc2 > 0xFFFF) break true;
    } else false;
    try std.testing.expect(!ran_out);
    try std.testing.expectEqual(@as(u32, 0x12), acc2);
    // 一次都没迭代：else 依然执行（这是原书Q9 答案b 的准确表述）
    var touched: usize = 0;
    const empty = for ([_]u8{}) |_| {
        touched += 1;
        break true;
    } else true;
    try std.testing.expect(empty);
    try std.testing.expectEqual(@as(usize, 0), touched);
    // while 也有 else
    var k: u8 = 0;
    const hit = while (k < 5) : (k += 1) {
        if (k == 2) break true;
    } else false;
    try std.testing.expect(hit);
    try std.testing.expectEqual(@as(u8, 2), k);
}

test "for 的四种迭代形态" {
    const names = [_][]const u8{ "C", "Zig", "Rust" };
    const years = [_]u16{ 1972, 2016, 2015 };
    // zip 多序列
    var seen: usize = 0;
    for (names, years, 0..) |name, year, idx| {
        try std.testing.expect(idx == seen);
        try std.testing.expect(year > 1900);
        try std.testing.expect(name.len > 0);
        seen += 1;
    }
    try std.testing.expectEqual(@as(usize, 3), seen);
    // 范围左闭右开
    var k_sum: usize = 0;
    for (0..5) |k| k_sum += k;
    try std.testing.expectEqual(@as(usize, 10), k_sum);
    // 切片长度：两个点才是切片语法
    try std.testing.expectEqual(@as(usize, 2), names[0..2].len);
    try std.testing.expectEqual(@as(usize, 3), names.len);
    // 切出来的切片仍然能for
    var joined: usize = 0;
    for (names[0..2]) |name| joined += name.len;
    try std.testing.expectEqual(@as(usize, 4), joined); // "C"=1 + "Zig"=3
}

test "指针捕获改的是元素本身" {
    var nums = [_]u8{ 1, 2, 3 };
    for (&nums) |*p| p.* *%= 10;
    try std.testing.expectEqualSlices(u8, &.{ 10, 20, 30 }, &nums);
    // 对照：值捕获拿到的是副本
    var copy = nums;
    for (copy) |v| {
        _ = v;
    }
    try std.testing.expectEqualSlices(u8, &nums, &copy);
    // 指针捕获 + 下标
    var flags = [_]bool{ false, true, false };
    for (&flags, 0..) |*flag, idx_f| {
        if (flag.*) continue;
        flag.* = idx_f == 2;
    }
    try std.testing.expectEqual(@as(bool, true), flags[2]);
    try std.testing.expectEqual(@as(bool, false), flags[0]);
}

test "labeled loop：跨层 break 与 continue" {
    var visited: usize = 0;
    outer: for (1..4) |x| {
        for (1..4) |y| {
            if (y > x) continue :outer;
            visited += 1;
        }
    }
    // 每轮x 有x 个y 不大于 x：1+2+3 = 6
    try std.testing.expectEqual(@as(usize, 6), visited);
    // break :label value 一层跳出两层
    var pairs: usize = 0;
    const found: usize = find: for (0..5) |row| {
        for (0..5) |col| {
            pairs += 1;
            if (row * row + col * col == 9) break :find @as(usize, row * 10 + col);
        }
    } else 0;
    try std.testing.expectEqual(@as(usize, 3), found); // 3*3+0*0 = 9
    try std.testing.expectEqual(@as(usize, 4), pairs);
}

test "labeled block：从深层跳出 + 圈住 defer" {
    const first_even = blk: {
        var idx: usize = 0;
        while (idx < 10) : (idx += 1) {
            if (@mod(idx, 2) == 0) break :blk idx;
        }
        break :blk @as(usize, 999);
    };
    try std.testing.expectEqual(@as(usize, 0), first_even);
    // defer 挂到块上：块一结束就跑
    var ran = false;
    const v = blk: {
        defer ran = true;
        break :blk @as(u8, 42);
    };
    try std.testing.expectEqual(@as(u8, 42), v);
    try std.testing.expect(ran);
}

test "switch 的range 是三个点，且要穷尽" {
    const bucket = struct {
        fn of(v: u8) []const u8 {
            return switch (v) {
                1...3 => "低",
                4...9 => "中",
                10...99 => "高",
                else => "爆表",
            };
        }
    }.of;
    try std.testing.expectEqualStrings("低", bucket(1));
    try std.testing.expectEqualStrings("低", bucket(3)); // 左端点闭
    try std.testing.expectEqualStrings("中", bucket(4));
    try std.testing.expectEqualStrings("中", bucket(9)); // 右端点闭
    try std.testing.expectEqualStrings("高", bucket(10));
    try std.testing.expectEqualStrings("高", bucket(99));
    try std.testing.expectEqualStrings("爆表", bucket(100));
    try std.testing.expectEqualStrings("爆表", bucket(0));
    // 负数范围
    const neg = struct {
        fn of(v: i32) []const u8 {
            return switch (v) {
                -100...0 => "非正",
                1...9 => "个位",
                else => "大",
            };
        }
    }.of;
    try std.testing.expectEqualStrings("非正", neg(-1));
    try std.testing.expectEqualStrings("个位", neg(1));
    try std.testing.expectEqualStrings("大", neg(100));
}

test "switch 对枚举穷尽：不需要 else" {
    const name = struct {
        fn of(c: Color) []const u8 {
            return switch (c) {
                .red => "红",
                .green => "绿",
                .blue => "蓝",
            };
        }
    }.of;
    try std.testing.expectEqualStrings("红", name(.red));
    try std.testing.expectEqualStrings("绿", name(.green));
    try std.testing.expectEqualStrings("蓝", name(.blue));
}

test "switch 捕获 union(enum) 负载" {
    try std.testing.expectEqual(@as(f64, 0), areaOf(.{ .dot = {} }));
    try std.testing.expectEqual(@as(f64, 12), areaOf(.{ .circle = 2 }));
    try std.testing.expectEqual(@as(f64, 12), areaOf(.{ .rect = .{ .w = 3, .h = 4 } }));
    // 捕获到的载荷可以整体取出、传给别的函数
    const sh = Shape{ .rect = .{ .w = 5, .h = 6 } };
    const dims = switch (sh) {
        .dot => @as(?Dims, null),
        .circle => |r| if (r > 0) @as(?Dims, .{ .w = r, .h = r }) else null,
        .rect => |rect| @as(?Dims, rect),
    };
    try std.testing.expectEqual(@as(f64, 5), dims.?.w);
    try std.testing.expectEqual(@as(f64, 6), dims.?.h);
}

test "labeled switch 走完状态机" {
    // 枚举操作数
    var st: St = .idle;
    const walk = sw: switch (st) {
        .idle => {
            st = .running;
            continue :sw st;
        },
        .running => {
            st = .done;
            continue :sw st;
        },
        .done => break :sw @as(u8, 2),
    };
    try std.testing.expectEqual(@as(u8, 2), walk);
    try std.testing.expectEqual(St.done, st);
    // 整数操作数 + else 兜底
    const final: u8 = code_sw: switch (@as(u8, 1)) {
        1 => continue :code_sw @as(u8, 2),
        2 => continue :code_sw @as(u8, 9),
        9 => break :code_sw 99,
        else => break :code_sw 0,
    };
    try std.testing.expectEqual(@as(u8, 99), final);
}

test "defer 后进先出，errdefer 只在出错时跑" {
    var order: u8 = 0;
    const f = struct {
        fn run(a: *u8, b: *u8) void {
            defer a.* = 1; // 后注册 → 先跑
            defer b.* = 2; // 先注册 → 后跑
        }
    }.run;
    f(&order, &order);
    try std.testing.expectEqual(@as(u8, 1), order);
    var flag = false;
    const g = struct {
        fn go(should_fail: bool, out: *bool) ParseError!u8 {
            errdefer out.* = true;
            if (should_fail) return error.Empty;
            return 0;
        }
    }.go;
    _ = try g(false, &flag);
    try std.testing.expect(!flag);
    _ = g(true, &flag) catch {};
    try std.testing.expect(flag);
}

test "inline for 在编译期展开" {
    comptime var bytes: usize = 0;
    inline for ([_]type{ u8, i32, f64 }) |T| {
        bytes += @typeName(T).len;
    }
    try std.testing.expectEqual(@as(usize, 8), bytes); // 2 + 3 + 3
    comptime var sizes: usize = 0;
    inline for ([_]type{ u8, i32, f64 }) |T| sizes += @sizeOf(T);
    try std.testing.expectEqual(@as(usize, 13), sizes); // 1 + 4 + 8
}

test "@branchHint 不改语义，只改分支权重" {
    var ran_likely = false;
    const c: u8 = 7;
    if (c > 3) {
        @branchHint(.likely);
        ran_likely = true;
    } else {
        @branchHint(.unlikely);
    }
    try std.testing.expect(ran_likely);
    var ran_unlikely = false;
    if (c > 1000) {
        @branchHint(.unlikely);
        ran_unlikely = true;
    }
    try std.testing.expect(!ran_unlikely);
}
