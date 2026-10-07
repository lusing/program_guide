//! 17 C 互操作：extern 手写声明、b.addTranslateC 翻译头文件、export 反向导出
//!
//! ⚠️ 0.17 迁移要点：`@cImport` 已从语言里**移除**（编译器报
//! "invalid builtin function: '@cImport'"）。C 头文件改由**构建系统**翻译：
//! `b.addTranslateC(...)` 产出一个 Zig 模块，源码里用 `@import("模块名")` 引入。
//! 这不是倒退，而是把"C 头文件处理"从编译期搬到了构建期——可控、可缓存、可复现。
const std = @import("std");

// ═══ 17.7 translate-c CLI 版的产物：手工裁剪后提交进源码树，当普通 .zig 文件 import
const bindings = @import("bindings_ci.zig"); // CLI 的产物（源码树里）

// ═══ 17.1 extern fn：手写 C 函数声明（直接链接 libc，不经过任何头文件翻译）
extern fn printf(format: [*:0]const u8, ...) c_int; // 变参 C 函数

// ═══ 17.2 b.addTranslateC 的产物：include/ci.h 被翻译成的 Zig 模块
//     里面的类型/函数/宏全部落在 `ci` 命名空间下（宏变成 comptime 常量）。
const ci = @import("ci"); // addTranslateC 的产物（.zig-cache/）

// ═══ 17.4 include/ci_ext.h 被翻译成的第二个模块：结构体 / 数组 / 函数指针
const ci_ext = @import("ci_ext");

// ═══ 17.3 export fn：Zig 函数按 C ABI 导出，供 csrc/ci.c 这类 C 代码调用
export fn zig_add(a: i32, b: i32) callconv(.c) i32 {
    return a + b;
}

// 导出字符串：返回全局常量的裸指针。C 没有所有权概念，谁分配谁释放。
const version: [:0]const u8 = "0.17.0";

export fn zig_version() callconv(.c) [*:0]const u8 {
    return version.ptr;
}

// 17.3 的另一半：C 定义函数指针类型（ci_op_t），Zig 提供实现，把指针交给 C 去调。
// 这个 export fn 的签名必须和 C 侧 typedef 逐个类型对上。
export fn zig_op_max(a: i32, b: i32) callconv(.c) i32 {
    return if (a > b) a else b;
}

// ═══ 17.4 Zig 侧手写的 extern struct：镜像 C 的 ci_box_t
//     声明序 + 字段类型与 C 完全一致 → 布局逐字节相同 → 可以共享同一块内存。
//     最小形态（u32 版本，两个字段天然 4 字节对齐、size 8）：
//         const CFoo = extern struct {
//             a: u32,
//             b: u32,
//         };
//     本例用 c_int（对应 C 的 int）演示有符号的 C 整型。
const Box = extern struct {
    x: c_int,
    y: c_int,
};

// 17.3/17.4 用：把 C 的函数指针类型翻译成 Zig 的函数指针类型。
// ci_op_t 已经是 `?*const fn (c_int, c_int) callconv(.c) c_int`，直接取它的非空形式。
const Op = *const fn (a: c_int, b: c_int) callconv(.c) c_int;

// ═══ 手写声明 vs 翻译头文件：两者可以并存，各自负责不同场景
extern fn ci_call_zig_add(a: i32, b: i32) callconv(.c) c_int;

fn begin(comptime tag: []const u8) void {
    std.debug.print("\n==== {s} 开始 ====\n", .{tag});
}
fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

pub fn main() !void {
    // ═══ 17.1 手写 extern：普通字符串字面量就是 0 结尾，直接传 ═══
    begin("17.1 手写 extern + libc");
    _ = printf("printf 直连：zig_add(3,4)=%d\n", zig_add(3, 4));
    _ = printf("libc strlen(\"hello\")=%zu\n", ci.ci_strlen("hello"));
    end("17.1");

    // ═══ 17.2 翻译头文件得到的模块 ═══
    begin("17.2 addTranslateC 翻译的模块");
    std.debug.print("ci_add(3,4)        = {d}\n", .{ci.ci_add(3, 4)});
    std.debug.print("ci_triple(7)       = {d}\n", .{ci.ci_triple(7)});
    std.debug.print("ci_strlen(\"hello\") = {d}\n", .{ci.ci_strlen("hello")});
    std.debug.print("ci_strcmp(\"ab\",\"ab\") = {d}（相等为 0）\n", .{ci.ci_strcmp("ab", "ab")});
    // 头文件里的 #include 被展开，size_t 翻译成 usize
    std.debug.print("size_t 在 Zig 侧的类型 = {s}\n", .{@typeName(@TypeOf(ci.ci_strlen("x")))});
    end("17.2");

    // ═══ 17.3 反向：Zig 导出给 C 用 ═══
    begin("17.3 export 给 C 调");
    std.debug.print("zig_version() 返回 {s}\n", .{std.mem.span(zig_version())});
    std.debug.print("C 侧回调 zig_add(20,22) = {d}\n", .{@as(i32, @intCast(ci_call_zig_add(20, 22)))});
    // 函数指针：Zig 的实现 → 指针 → C 的 ci_apply_op
    const op: Op = &zig_op_max;
    std.debug.print("C 侧用 Zig 函数指针 zig_op_max(3,9) = {d}\n", .{ci_ext.ci_apply_op(op, 3, 9)});
    end("17.3");

    // ═══ 17.4 extern struct：和 C 共享同一块内存 ═══
    begin("17.4 extern struct 共享内存");
    // 布局对照：Zig 的 @offsetOf 与 C 的 offsetof 必须逐个相同。
    // 两边都是 { c_int, c_int }，都是 x 在 0、y 在 4、size 8 —— 镜像写对了。
    std.debug.print("Zig 侧 @offsetOf: x={d} y={d} size={d} align={d}\n", .{
        @offsetOf(Box, "x"), @offsetOf(Box, "y"), @sizeOf(Box), @alignOf(Box),
    });
    std.debug.print("C   侧 offsetof : x={d} y={d} size={d}\n", .{
        ci_ext.ci_box_off_x(), ci_ext.ci_box_off_y(), ci_ext.ci_box_size(),
    });
    // 手写的 Box 与翻译出来的 ci_box_t 是两个不同的 Zig 类型，但布局逐字节相同，
    // 所以指针可以用 @ptrCast 互换 —— 这正是"手写镜像"能替代翻译的前提。
    std.debug.print("翻译出的 ci_box_t 与手写 Box 布局相同 = {}\n", .{
        @sizeOf(ci_ext.ci_box_t) == @sizeOf(Box) and
            @offsetOf(ci_ext.ci_box_t, "x") == @offsetOf(Box, "x") and
            @offsetOf(ci_ext.ci_box_t, "y") == @offsetOf(Box, "y"),
    });

    // Zig 侧分配 → C 侧通过指针改 → Zig 侧读回，同一块内存
    var b: Box = .{ .x = 10, .y = 20 };
    const p: [*c]ci_ext.ci_box_t = @ptrCast(&b);
    ci_ext.ci_box_print("C 读到 Zig 写的", p);
    ci_ext.ci_box_shift(p, 5, -3);
    std.debug.print("Zig 读到 C 改完 : x={d} y={d}\n", .{ b.x, b.y });

    // @bitCast 在 0.17 拒绝裸结构体（连 extern struct 也不行）：
    //     const v: u64 = @bitCast(b);
    //   error: cannot @bitCast from 'main.Box'
    // 正确写法：显式走字节 + 显式写端序
    const raw = std.mem.asBytes(&b);
    const lo = std.mem.readInt(u32, raw[0..4], .little);
    const hi = std.mem.readInt(u32, raw[4..8], .little);
    std.debug.print("asBytes+readInt  : x={d} y={d}（raw.len={d}）\n", .{ lo, hi, raw.len });
    end("17.4");

    // ═══ 17.5 哨兵切片 ↔ C 字符串 ═══
    begin("17.5 哨兵切片 ↔ C 字符串");
    const zig_str = "哨兵切片互转";
    const c_ptr: [*:0]const u8 = zig_str.ptr; // 哨兵保证 0 结尾 → 直接给 C
    const back: [:0]const u8 = std.mem.span(c_ptr); // C 指针 → 哨兵切片（带长度）
    std.debug.print("span 回来长度 {d}（两侧字节一致）\n", .{back.len});
    std.debug.print("C 侧 strlen 同一块内存 = {d}\n", .{ci.ci_strlen(c_ptr)});
    // 翻译出来的 C 字符串指针在 0.17 是 [*c]const u8（不是 [:0]const u8）。
    // 同一个 C 指针，两种哨兵类型随便换：赋值处对齐一下就行。
    // 反向也一样：const a: [:0]const u8 = "x";  const b: [*c]const u8 = a;
    const from_c: [*c]const u8 = c_ptr; // [:0] 的指针，标注成 [*c] 给 C 用
    std.debug.print("const char* 在翻译模块里的类型 = {s}，span 长度 {d}\n", .{
        @typeName(@TypeOf(from_c)), std.mem.span(from_c).len,
    });
    end("17.5");

    // ═══ 17.6 结构体数组 / 指针数组 ═══
    begin("17.6 结构体数组与指针数组");
    const pairs = ci_ext.ci_pairs(); // [*c]const ci_pair_t
    const n: usize = @intCast(ci_ext.ci_pairs_len());
    var total: c_int = 0;
    for (pairs[0..n]) |it| {
        // key 是 [*c]const u8，要 std.mem.span 才有长度
        std.debug.print("  pair {s} = {d}\n", .{ std.mem.span(it.key), it.val });
        total += it.val;
    }
    std.debug.print("C 侧静态数组 {d} 项求和 = {d}（元素 {d} 字节，key 在偏移 {d}）\n", .{
        n, total, @sizeOf(ci_ext.ci_pair_t), @offsetOf(ci_ext.ci_pair_t, "key"),
    });
    end("17.6");

    // ═══ 17.7 所有权：结构体里带 char * ═══
    begin("17.7 谁分配谁释放");
    const owner = ci_ext.ci_owner_new("owned-by-c", 42);
    // name 字段是 [*c]u8（C 的 char* 可写），Zig 侧只读。
    // owner 的类型是 [*c]ci_owner_t（"多指针"），不能直接 owner.name，
    // 要用 owner.* 取出指针指向的那一个元素。
    std.debug.print("C 分配的 name = {s}（id={d}）\n", .{ std.mem.span(owner.*.name), owner.*.id });
    // 释放必须回 C 侧：malloc 的东西要用 free，不能交给 Zig 的 allocator
    ci_ext.ci_owner_free(owner);
    end("17.7");

    // ═══ 17.8 预生成绑定：同一个头文件，两条路拿到同样的声明 ═══
    begin("17.8 translate-c 预生成绑定");
    // ci 是 addTranslateC 的产物（构建期翻译，落 .zig-cache/）
    // bindings 是 CLI 的产物（提交进源码树的 src/bindings_ci.zig）
    // 两者对同一份 include/ci.h 给出完全一致的签名 —— 同一个翻译器。
    std.debug.print("addTranslateC   : ci_add(3,4)={d} ci_strlen(\"hello\")={d}\n", .{
        ci.ci_add(3, 4), ci.ci_strlen("hello"),
    });
    std.debug.print("translate-c CLI : ci_add(3,4)={d} ci_strlen(\"hello\")={d}\n", .{
        bindings.ci_add(3, 4), bindings.ci_strlen("hello"),
    });
    end("17.8");

    // ═══ 17.9 变参 printf：%d 与 usize 的类型陷阱 ═══
    begin("17.9 变参的类型陷阱");
    const big: usize = 0x1_0000_0001; // 4294967297，32 位槽装不下
    // ⚠️ 下面三行故意用 extern printf（不是 std.debug.print）：
    // extern 变参放弃类型检查，usize 直塞 %d 就是 UB —— 实测只打出低 32 位的 1。
    // std.debug.print 有编译期检查，写错格式串/类型根本编译不过，所以它发现不了这个坑。
    _ = printf("%%d  直塞 usize = %d   ← 被截断，只剩低 32 位\n", big);
    _ = printf("%%zu 直塞 usize = %zu  ← size_t 的正确格式串\n", big);
    _ = printf("%%d  显式收窄     = %d   ← @as(c_int, @intCast(x)) 之后是对的\n", @as(c_int, @intCast(big & 0xff)));
    // 另外：字面量连 0.17 都会拦你一手
    //     _ = printf("%d\n", 42);
    //   error: integer and float literals passed to variadic function
    //          must be casted to a fixed-size number type
    end("17.9");

    std.debug.print("自检通过\n", .{});
}

test "C ABI 与翻译头文件都可用" {
    try std.testing.expectEqual(@as(i32, 7), zig_add(3, 4));
    try std.testing.expectEqual(@as(usize, 5), ci.ci_strlen("hello"));
    try std.testing.expectEqual(@as(i32, 7), ci.ci_add(3, 4));
    try std.testing.expectEqual(@as(i32, 21), ci.ci_triple(7));
    try std.testing.expectEqualStrings("0.17.0", std.mem.span(zig_version()));
    // C 回调 Zig：两个方向都通了
    try std.testing.expectEqual(@as(i32, 42), @as(i32, @intCast(ci_call_zig_add(20, 22))));
}

test "17.4 extern struct 与 C 的 ci_box_t 布局完全一致" {
    // 布局一致是共享内存的前提，两边对不上就是静默的数据损坏
    try std.testing.expectEqual(@sizeOf(Box), ci_ext.ci_box_size());
    try std.testing.expectEqual(@offsetOf(Box, "x"), ci_ext.ci_box_off_x());
    try std.testing.expectEqual(@offsetOf(Box, "y"), ci_ext.ci_box_off_y());

    // 同一块内存：Zig 写 → C 改 → Zig 读
    var b: Box = .{ .x = 10, .y = 20 };
    ci_ext.ci_box_shift(@ptrCast(&b), 5, -3);
    try std.testing.expectEqual(@as(c_int, 15), b.x);
    try std.testing.expectEqual(@as(c_int, 17), b.y);

    // asBytes + readInt 能按字节读回两个字段
    const raw = std.mem.asBytes(&b);
    try std.testing.expectEqual(@as(u32, 15), std.mem.readInt(u32, raw[0..4], .little));
    try std.testing.expectEqual(@as(u32, 17), std.mem.readInt(u32, raw[4..8], .little));
}

test "17.3 函数指针：Zig 的实现能被 C 通过指针调用" {
    const op: Op = &zig_op_max;
    try std.testing.expectEqual(@as(c_int, 9), ci_ext.ci_apply_op(op, 3, 9));
    try std.testing.expectEqual(@as(c_int, 9), ci_ext.ci_apply_op(op, 9, 3));
    // C 侧收到 NULL 指针时的行为（ci_apply_op 里判了空）
    try std.testing.expectEqual(@as(c_int, 0), ci_ext.ci_apply_op(null, 3, 9));
}

test "17.6 结构体数组：指针 + 长度可以安全遍历" {
    const pairs = ci_ext.ci_pairs();
    const n: usize = @intCast(ci_ext.ci_pairs_len());
    try std.testing.expectEqual(@as(usize, 3), n);

    var total: c_int = 0;
    for (pairs[0..n]) |it| total += it.val;
    try std.testing.expectEqual(@as(c_int, 15), total);
    try std.testing.expectEqualStrings("red", std.mem.span(pairs[0].key));
    try std.testing.expectEqualStrings("blue", std.mem.span(pairs[2].key));
}

test "17.5 哨兵类型：[:0] 与 [*c] 可以双向互转" {
    const a: [:0]const u8 = "x";
    const b: [*c]const u8 = a; // [:0] → [*c]：可以
    const back: [:0]const u8 = std.mem.span(b); // [*c] → [:0]：也可以
    try std.testing.expectEqual(@as(usize, 1), back.len);
    try std.testing.expectEqualStrings("x", back);
}

test "17.7 所有权：C 分配 C 释放，Zig 侧只读" {
    const owner = ci_ext.ci_owner_new("owned-by-c", 42);
    try std.testing.expectEqual(@as(c_int, 42), owner.*.id);
    try std.testing.expectEqualStrings("owned-by-c", std.mem.span(owner.*.name));
    // 释放必须走 C 的 free：这块内存是 C 的 malloc 出来的，
    // 交给 Zig 的 allocator 去 free 就是跨分配器错误（17.7 的核心）。
    ci_ext.ci_owner_free(owner);
}
