//! 15 测试：test 块、zig test 的三层、expect* 断言族与其真实失败输出、--test-filter、
//! tmpDir 临时目录、testing.allocator 泄漏检测机制、FailingAllocator 注入 OOM、
//! log_level 与 log.err 的坑、测试替身（testing.io / testing.Reader）、测试隔离、
//! 手写基准（0.17 没有 std.testing.benchmark）、编译期测试、doctest 缺失的替代方案
const std = @import("std");
const builtin = @import("builtin");
const util = @import("util.zig");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 15.2/15.3 的被测对象：把 s 重复 n 遍（失败路径必须回滚，见 15.8）
fn repeat(allocator: std.mem.Allocator, s: []const u8, n: usize) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator); // 10 章的 errdefer 回滚模式：OOM 路径靠它
    for (0..n) |_| try out.appendSlice(allocator, s);
    return out.toOwnedSlice(allocator);
}

/// 15.3 expectError 的被测函数
fn parseLike(x: u8) error{TooBig}!u8 {
    return if (x > 3) error.TooBig else x;
}

/// 15.4 独立测试文件：根文件不引用它，它的test 块就不会跑（实测 0 个）
fn unreferenced(x: u8) u8 {
    return x + 1;
}

/// 15.11 测试替身：io 是显式参数，测试里传 std.testing.io
fn greet(io: std.Io, buf: []u8) ![]const u8 {
    _ = io; // 签名保留 io → 真实环境传 init.io，测试传 std.testing.io
    var w = std.Io.Writer.fixed(buf);
    try w.print("hello, {s}", .{"io"});
    return w.buffered();
}

/// 15.8 OOM 注入的靶子：三次固定分配，errdefer/defer 保证第k 次失败时前 k-1 次已释放
fn triple(gpa: std.mem.Allocator) !void {
    const a = try gpa.alloc(u8, 8);
    defer gpa.free(a);
    const b = try gpa.alloc(u8, 16);
    defer gpa.free(b);
    const c = try gpa.alloc(u8, 32);
    defer gpa.free(c);
}

/// 15.12手写基准的被测函数
fn work(n: usize) u64 {
    var acc: u64 = 0;
    for (0..n) |i| acc = acc *% 6364136223846793005 +% @as(u64, i);
    return acc;
}

pub fn main(init: std.process.Init) !void {
    // ═══ 15.1 测试是语言内建的：test 块 + zig test，什么都不用装 ═══
    begin("15.1");
    std.debug.print("builtin.is_test（本文件按 exe 编译，故为 {}）\n", .{builtin.is_test});
    std.debug.print("测试靠 `zig test main.zig` 跑——build.zig.zon 里没有一行测试依赖\n", .{});
    std.debug.print("test 块是**语言关键字**（不是库函数），语法和 0.16/0.15 完全一致\n", .{});
    std.debug.print("assertion 来自 std.testing.*，那是标准库的一部分，不需要外部框架\n", .{});
    end("15.1");

    // ═══ 15.2 测试清单：名字就是标识符，重名是编译错误 ═══
    begin("15.2");
    std.debug.print("具名 test：编译单元名.test.名字 → main.test.repeat 重复拼接\n", .{});
    std.debug.print("匿名 test：没有名字 → main.test_0（本文件最后那个匿名 test 块）\n", .{});
    std.debug.print("嵌在 struct 里的 test：StructName.test.名字 → util.test.sluggify 行为\n", .{});
    std.debug.print("重复名字会报 duplicate test name '...'（实测，见文档 15.2）\n", .{});
    // 重复的名字（自己试）：把同一个名字写两遍 → 编译失败
    std.debug.print("struct 里的 test 也要被引用才进清单（本文件用 `_ = 那个struct;`）\n", .{});
    end("15.2");

    // ═══ 15.3 断言族：存在什么、不存在什么 ═══
    begin("15.3");
    const names = [_]struct { n: []const u8, note: []const u8, has: bool }{
        .{ .n = "expect", .note = "布尔为真", .has = @hasDecl(std.testing, "expect") },
        .{ .n = "expectEqual", .note = "peer 类型解析后比值", .has = @hasDecl(std.testing, "expectEqual") },
        .{ .n = "expectEqualStrings", .note = "字符串，带 diff", .has = @hasDecl(std.testing, "expectEqualStrings") },
        .{ .n = "expectEqualSlices", .note = "切片逐元素（u8 走十六进制视图）", .has = @hasDecl(std.testing, "expectEqualSlices") },
        .{ .n = "expectEqualSentinel", .note = "切片 + 哨兵值", .has = @hasDecl(std.testing, "expectEqualSentinel") },
        .{ .n = "expectEqualDeep", .note = "深度比较（指针穿透）", .has = @hasDecl(std.testing, "expectEqualDeep") },
        .{ .n = "expectError", .note = "错误联合的具体错误", .has = @hasDecl(std.testing, "expectError") },
        .{ .n = "expectApproxEqAbs", .note = "浮点绝对容差", .has = @hasDecl(std.testing, "expectApproxEqAbs") },
        .{ .n = "expectApproxEqRel", .note = "浮点相对容差", .has = @hasDecl(std.testing, "expectApproxEqRel") },
        .{ .n = "expectFmt", .note = "格式化结果", .has = @hasDecl(std.testing, "expectFmt") },
        .{ .n = "expectStringStartsWith", .note = "前缀", .has = @hasDecl(std.testing, "expectStringStartsWith") },
        .{ .n = "expectStringEndsWith", .note = "后缀", .has = @hasDecl(std.testing, "expectStringEndsWith") },
        .{ .n = "checkAllAllocationFailures", .note = "穷举 OOM 路径", .has = @hasDecl(std.testing, "checkAllAllocationFailures") },
        .{ .n = "refAllDecls", .note = "引用所有声明", .has = @hasDecl(std.testing, "refAllDecls") },
        .{ .n = "failPrint", .note = "comptime 期转 @compileError", .has = @hasDecl(std.testing, "failPrint") },
        .{ .n = "expectNull", .note = "没有 → expect(opt == null)", .has = @hasDecl(std.testing, "expectNull") },
        .{ .n = "expectEqualError", .note = "没有 → 用 expectError", .has = @hasDecl(std.testing, "expectEqualError") },
        .{ .n = "expectDebugAssert", .note = "没有 → 编译器保证", .has = @hasDecl(std.testing, "expectDebugAssert") },
        .{ .n = "expectFalse", .note = "没有 → expect(!x)", .has = @hasDecl(std.testing, "expectFalse") },
        .{ .n = "expectAtLeast", .note = "没有 → 手写断言", .has = @hasDecl(std.testing, "expectAtLeast") },
        .{ .n = "expectVectorEqual", .note = "没有 → expectEqual 会走 vector 分支", .has = @hasDecl(std.testing, "expectVectorEqual") },
        .{ .n = "benchmark", .note = "0.17 已移除 → 手写 Io.Clock 计时", .has = @hasDecl(std.testing, "benchmark") },
    };
    var exist: usize = 0;
    var missing: usize = 0;
    for (names) |it| {
        std.debug.print("  {s:<30} {s}  {s}\n", .{ it.n, if (it.has) "存在  " else "不存在", it.note });
        if (it.has) exist += 1 else missing += 1;
    }
    std.debug.print("小计：{d} 个存在，{d} 个不存在\n", .{ exist, missing });
    // 没有 expectNull：判空自己写
    const opt: ?u8 = null;
    std.debug.print("判空写法：expect(opt == null)，本文件返回 {}\n", .{opt == null});
    end("15.3");

    // ═══ 15.4 expectEqual 的真实语义：peer 类型解析 + 指针比地址 ═══
    begin("15.4");
    std.debug.print("expectEqual 用 @TypeOf(expected, actual) 做 peer 类型解析（0.17）\n", .{});
    std.debug.print("  expectEqual(5, x:u8) 编译得过：comptime_int 与 u8 peer 成 u8\n", .{});
    std.debug.print("  expectEqual(a:u8, b:u16) 也编译得过：peer 成 u16\n", .{});
    std.debug.print("  但两个**不同**的结构体类型直接报 incompatible types（实测）\n", .{});
    // ⚠️ 指针/切片走的是"比地址"分支，不是比内容（实测，文档 15.4 有失败输出）
    std.debug.print("⚠️ expectEqual 对指针/切片比的是**地址**：\n", .{});
    std.debug.print("   两个内容相同、地址不同的 u32 → expected u32@... found u32@... FAIL\n", .{});
    std.debug.print("   两个内容相同的字符串字面量 → 编译器折叠成同一地址 → 假OK\n", .{});
    std.debug.print("   ⇒ 比内容必须用 expectEqualStrings / expectEqualSlices / expectEqualDeep\n", .{});
    std.debug.print("  想断言 null：expectEqual(@as(?u8, null), opt)（0.17 会打印 expected null, found ...）\n", .{});
    end("15.4");

    // ═══ 15.5 --test-filter 与测试清单核对 ═══
    begin("15.5");
    std.debug.print("--test-filter [text]  跳过名字不匹配任一 filter 的测试（子串匹配）\n", .{});
    std.debug.print("--test-no-exec           只编译不跑（配合 -femit-bin 拿到测试可执行文件）\n", .{});
    std.debug.print("--test-runner [path]     换掉默认 runner（实测：换成只打印清单的 runner）\n", .{});
    std.debug.print("--test-cmd [arg]         指定执行命令，一个 arg 一次；配 --test-cmd-bin 追加二进制路径\n", .{});
    std.debug.print("--test-execve            有 execve 时用 execve 代替 fork 子进程\n", .{});
    std.debug.print("⚠️ 没有并行选项：--test-threads=4 报 unrecognized parameter（实测）\n", .{});
    std.debug.print("⚠️ --test-cmd 不带 --test-cmd-bin 时测试**根本没跑**，退出码却是 0（实测）\n", .{});
    std.debug.print("⚠️ 传第二个根文件报 found another zig file \"...\" after root source file（实测）\n", .{});
    std.debug.print("⚠️ zig test **不分析** pub fn main：main 里的类型错测试照绿（实测）\n", .{});
    std.debug.print("⚠️ 覆盖率：zig test --help 里 0 个 coverage 选项，也没有 gcov 报告工具（实测）\n", .{});
    end("15.5");

    // ═══ 15.6 测试与源码同文件 vs 独立测试文件 ═══
    begin("15.6");
    std.debug.print("推荐：test 块写在被测代码同一个文件里，跟着代码走\n", .{});
    std.debug.print("本文件 test 块与 repeat/parseLike/greet 紧挨着 → 改函数时顺手改测试\n", .{});
    std.debug.print("多文件：test 块只对**被引用到的**文件生效（15.2 已实测：引用才进清单）\n", .{});
    std.debug.print("本文件用一个匿名 test 块把 util.zig 拽进清单（见文件末尾）\n", .{});
    std.debug.print("util.sluggify 被引用了吗？ {}\n", .{@hasDecl(util, "sluggify")});
    std.debug.print("参照：util.zig 里的测试名是 util.test.sluggify 行为\n", .{});
    end("15.6");

    // ═══ 15.7 std.testing.tmpDir：自清理临时目录 ═══
    begin("15.7");
    std.debug.print("std.testing.tmpDir(.{{}}) 返回 {s}，字段有：\n", .{@typeName(std.testing.TmpDir)});
    const T = @typeInfo(std.testing.TmpDir).@"struct";
    inline for (T.field_names, T.field_types) |fname, ftype| {
        std.debug.print("  .{s:<12} : {s}\n", .{ fname, @typeName(ftype) });
    }
    std.debug.print("⚠️ sub_path 是 [16]u8 数组（base64 随机名），不是路径字符串\n", .{});
    std.debug.print("   完整路径是 .zig-cache/tmp/<sub_path>，cleanup() 递归删整棵子树\n", .{});
    std.debug.print("⚠️ tmpDir 带 comptime assert(builtin.is_test) → 在 main 里调用**编译失败**\n", .{});
    std.debug.print("   （实测报 lib/std/testing.zig:607 reached unreachable code）\n", .{});
    std.debug.print("本节只反射类型形状；真正的调用在本文件末尾的 test 块里\n", .{});
    end("15.7");

    // ═══ 15.8 testing.allocator：泄漏即失败，但判负在最后 ═══
    begin("15.8");
    std.debug.print("std.testing.allocator 真身 = {s}\n", .{@typeName(@TypeOf(std.testing.allocator_instance))});
    std.debug.print("deinit() 返回泄漏**块数** usize，不是字节数\n", .{});
    std.debug.print("机制：每个测试跑完 runner 才 deinit 一次，计数累加到 leaks\n", .{});
    std.debug.print("⇒ 泄漏的测试自己显示 ...OK，最后统一打 `N tests leaked memory.` 并 exit(1)\n", .{});
    std.debug.print("⇒ 同一次还会打 `N errors were logged.`（泄漏日志走的是 log.err 通道）\n", .{});
    std.debug.print("所以 `All N tests passed.` 与 `N tests leaked memory.` 会**同时**出现\n", .{});
    std.debug.print("canary + check_write_after_free = true：写已释放内存立刻炸\n", .{});
    end("15.8");

    // ═══ 15.9 FailingAllocator：把 OOM 当成可注入的输入 ═══
    begin("15.9");
    std.debug.print("std.testing.FailingAllocator 存在；std.testing.failing_allocator 是全局那个\n", .{});
    std.debug.print("Config = {{ fail_index, resize_fail_index }}，第 N 次分配返回 null\n", .{});
    std.debug.print("std.testing.checkAllAllocationFailures(backing, fn, extra_args) 穷举所有 N\n", .{});
    std.debug.print("靶子 triple 有三次分配 + 三条 defer free ⇒ 0/1/2 三个失败点都不泄漏\n", .{});
    std.debug.print("⚠️ 被测函数第一个参数必须是 Allocator、返回类型必须 !void，否则 @compileError\n", .{});
    end("15.9");

    // ═══ 15.10 log_level 与 log.err 的坑 ═══
    begin("15.10");
    std.debug.print("std.testing.log_level 默认 = {t}（低于它的日志不打印）\n", .{std.testing.log_level});
    std.debug.print("测试 runner 里每跑一个测试前都会重置 log_level = .warn\n", .{});
    std.debug.print("⚠️ 但 log.err 会计数：runner 的 log 函数对 err 级无条件 log_err_count += 1\n", .{});
    std.debug.print("⚠️ 所以 test 块里 std.log.err(...) 即使断言全过也 exit(1)（实测）\n", .{});
    std.debug.print("   守卫写法：if (builtin.is_test) return;（本文件 logOrPanic 就是这么写的）\n", .{});
    std.debug.print("调高 log_level 只能让更多日志**打印**，不能阻止 err 计数\n", .{});
    end("15.10");

    // ═══ 15.11 测试替身：显式依赖 io 的回报 ═══
    begin("15.11");
    std.debug.print("greet 的 io 是**显式参数** → 同一份代码，main 传 init.io、test 传 testing.io\n", .{});
    std.debug.print("main 里传的是 init.io，类型 = {s}\n", .{@typeName(@TypeOf(init.io))});
    var buf: [64]u8 = undefined;
    const got = try greet(init.io, &buf);
    std.debug.print("greet(传 init.io) = {s}（输出落在调用方的 buf，不碰真实 stdout）\n", .{got});
    std.debug.print("std.testing.io 在**非测试编译**下是 @compileError(\"not testing\")\n", .{});
    std.debug.print("   所以本节不能直接引用它——这是 0.17 的硬边界（实测：main 里写就编译失败）\n", .{});
    std.debug.print("更彻底的替身：std.testing.Reader —— 按预设脚本喂字节，无需真实文件\n", .{});
    std.debug.print("⚠️ 别在测试里用 testing.io 做同步原语：Io.Condition.wait 在它上面**死锁**（实测挂死）\n", .{});
    std.debug.print("   线程编排类测试放 main（用 init.io），测试只覆盖纯函数与原子操作\n", .{});
    end("15.11");

    // ═══ 15.12 测试隔离：全局状态在测试间是**重置**的 ═══
    begin("15.12");
    std.debug.print("实测：全局 var 在 3 个 test 块里始终读到 1，不累加\n", .{});
    std.debug.print("机制：每个测试函数是独立的编译期实例，各自带一份那份全局的存储\n", .{});
    std.debug.print("⇒ 写「上一个测试给全局赋值、下一个读」的测试 = 顺序脆弱，别这么干\n", .{});
    std.debug.print("⇒ 共享可变状态请显式传参（进函数参数或进 struct 字段）\n", .{});
    std.debug.print("文件系统：用 tmpDir 而不是固定路径；网络：本教程坚持不测\n", .{});
    end("15.12");

    // ═══ 15.13 手写基准：0.17 没有 std.testing.benchmark ═══
    begin("15.13");
    std.debug.print("std.testing.benchmark 在 0.17 **不存在**（std.hash.benchmark 是另一个东西）\n", .{});
    std.debug.print("std.time.Timer 也没了 → 计时用 std.Io.Clock.now(.awake, io)\n", .{});
    const t0 = std.Io.Clock.now(.awake, init.io);
    var sink: u64 = 0;
    for (0..200) |_| sink +%= work(1000);
    const t1 = std.Io.Clock.now(.awake, init.io);
    const ns = t0.durationTo(t1).nanoseconds;
    std.debug.print("200 轮 work(1000)：{d} ns，约 {d} ns/轮（sink={d}）\n", .{ ns, @divTrunc(ns, 200), sink });
    std.debug.print("⚠️ 别在 Debug 模式报基准数字：安全检查全开，性能数据没意义\n", .{});
    std.debug.print("⚠️ 没有内建覆盖率：zig test --help 无 coverage 选项，也没有 gcov 报告器\n", .{});
    end("15.13");

    // ═══ 15.14 编译期测试 ═══
    begin("15.14");
    std.debug.print("comptime 块里的 std.testing.expectEqual 失败 → **编译错误**（failPrint 走 @compileError）\n", .{});
    std.debug.print("普通 test 块里的 comptime 表达式失败 → 运行期 TestExpectedEqual\n", .{});
    std.debug.print("@compileError 是表达「这段代码应该编译失败」的唯一手段\n", .{});
    std.debug.print("@setEvalBranchQuota(N) 抬高 comptime 求值配额（默认 1000）\n", .{});
    std.debug.print("深 comptime 循环不抬配额会撞上限（实测，见文档 15.14）\n", .{});
    std.debug.print("sqSum(10) = {d}（1²+...+10²，编译期算完，运行期零成本）\n", .{sqSum(10)});
    end("15.14");

    // ═══ 15.15 doctest 不存在：替代方案 ═══
    begin("15.15");
    std.debug.print("0.17 没有 doctest：文档注释里的 ```zig 代码块**不会被编译也不会被跑**\n", .{});
    std.debug.print("实测：一个只有故意写错的```zig 块的文件 → `All 0 tests passed.` 退出码 0\n", .{});
    std.debug.print("替代方案 1：文档示例同时抄一份成显式 test 块（本文件 sqSum 就是这么守着的）\n", .{});
    std.debug.print("替代方案 2：让例子本身可运行（main 跑一遍 + test 断言），本教程全书路线\n", .{});
    std.debug.print("替代方案 3：--test-no-exec -femit-bin 拿到测试二进制再单独跑（CI 里分阶段用）\n", .{});
    end("15.15");

    std.debug.print("自检通过\n", .{});
}

// ═══ 15.7 的类型说明：std.testing.TmpDir 的字段形状（在 test 块里真用一次）═══
// 注意 std.testing.tmpDir 带 `comptime assert(builtin.is_test)`，
// 在 main（按 exe 编译）里调用会编译失败：lib/std/testing.zig 的 unreachable。
// 所以本节在 main 里只反射类型形状，真正的调用放在文件末尾的 test 块里。

/// 15.10 的守卫写法示范：测试环境不记err 日志
fn logOrPanic(comptime fmt: []const u8, args: anytype) void {
    if (builtin.is_test) return; // ← 少了这行，zig test 退出码就是 1
    std.log.err(fmt, args);
}

/// 15.14 编译期递归平方和
fn sqSum(comptime n: usize) comptime_int {
    comptime var acc: comptime_int = 0;
    comptime var i: usize = 1;
    inline while (i <= n) : (i += 1) acc += i * i;
    return acc;
}

// ═══════════════════════ 15.1~15.15 的 test 块 ═══════════════════════

test "测试名就是标识符，中文直接当测试名" {
    // `zig test` 输出里逐条打1/N <编译单元>.test.<这个名字>...OK
    try std.testing.expect(1 + 1 == 2);
}

test "repeat 重复拼接" {
    const a = std.testing.allocator;
    const r = try repeat(a, "ab", 3);
    defer a.free(r);
    try std.testing.expectEqualStrings("ababab", r);
}

test "repeat 零次得到空串" {
    const a = std.testing.allocator;
    const r = try repeat(a, "x", 0);
    defer a.free(r);
    try std.testing.expectEqual(@as(usize, 0), r.len);
}

test "assertion 家族：全部期望成功的用法" {
    try std.testing.expect(true);
    try std.testing.expectEqual(@as(u8, 4), 2 + 2); // comptime_int 与 u8 peer 成 u8
    try std.testing.expectEqual(@as(u16, 5), @as(u8, 5)); // u8 与 u16 peer 成 u16
    try std.testing.expectEqualStrings("zig", "z" ++ "ig"); // ++ 拼接在 0.17 仍在
    try std.testing.expectEqualSlices(u8, "abc", "abc");
    try std.testing.expectEqualSentinel(u8, 0, "abc", "abc");
    try std.testing.expectEqualDeep(@as(?u32, 1), @as(?u32, 1));
    try std.testing.expectApproxEqAbs(@as(f64, 1.0), @as(f64, 1.0000001), 0.001);
    try std.testing.expectApproxEqRel(@as(f64, 1.0), @as(f64, 1.0000001), 0.001);
    try std.testing.expectFmt("v=3", "v={d}", .{3});
    try std.testing.expectStringStartsWith("hello world", "hello");
    try std.testing.expectStringEndsWith("hello world", "world");
}

test "assertion 家族：类型不 peer 时是编译错误" {
    const A = struct { x: u8 };
    // 下面这行编译不过（实测：incompatible types: 'A' and 'B'）：
    // const B = struct { x: u8 };
    // try std.testing.expectEqual(A{ .x = 1 }, B{ .x = 1 });
    // 字段全同也是两个不同类型 → expectEqual 拒绝（靠 @TypeOf 的 peer 解析）
    try std.testing.expectEqual(A{ .x = 1 }, A{ .x = 1 });
}

test "assertion 家族：没有 expectNull，判空自己写" {
    const opt: ?u8 = null;
    try std.testing.expect(opt == null); // 0.16/0.17 都没有 expectNull
    try std.testing.expectEqual(@as(?u8, null), opt); // 或用 expectEqual 判null
}

test "expectError 断言错误联合的**具体**错误" {
    try std.testing.expectError(error.TooBig, parseLike(9));
    try std.testing.expectError(error.TooBig, parseLike(0xFF));
}

test "指针/切片用 expectEqual 比的是地址（所以别这么用）" {
    // 这两行是本教程的**反面教材**：内容相同、地址不同 → FAIL
    // try std.testing.expectEqual(&a, &b);
    // 正确写法是逐个字段比，或者用 expectEqualSlices(u8, ...)比内容
    var a = [_]u8{ 1, 2, 3 };
    var b = [_]u8{ 1, 2, 3 };
    try std.testing.expectEqualSlices(u8, &a, &b); // 比内容，不是比地址
    try std.testing.expectEqual(@as(usize, 3), a.len);
}

test "tmpDir：自清理临时目录的三个字段" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    // .dir      : Io.Dir——已打开的临时目录
    // .sub_path : [16]u8——base64 随机名（不是路径！），完整路径是 .zig-cache/tmp/<sub_path>
    // .cleanup(): 递归删整棵子树
    var f = try tmp.dir.createFile(std.testing.io, "t.txt", .{});
    var fbuf: [32]u8 = undefined;
    var fw = f.writer(std.testing.io, &fbuf);
    try fw.interface.print("hello", .{});
    try fw.interface.flush();
    f.close(std.testing.io);

    const got = try tmp.dir.readFileAlloc(std.testing.io, "t.txt", std.testing.allocator, .limited(64));
    defer std.testing.allocator.free(got);
    try std.testing.expectEqualStrings("hello", got);
}

test "testing.allocator：deinit 返回泄漏**块数**" {
    // 真身是 heap.SafeAllocator，deinit() 返回泄漏块数 usize
    try std.testing.expect(!@hasDecl(std.testing, "print_error_trace")); // 0.17 已移除
    try std.testing.expect(@hasDecl(std.testing, "allocator_instance"));
    // 正常分配+释放 → 不泄漏
    const buf = try std.testing.allocator.alloc(u8, 16);
    defer std.testing.allocator.free(buf);
    try std.testing.expectEqual(@as(usize, 16), buf.len);
}

test "FailingAllocator：单独指定第 N 次分配失败" {
    var fa = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 1 });
    try std.testing.expectError(error.OutOfMemory, triple(fa.allocator()));
}

test "checkAllAllocationFailures：穷举每一个 OOM 点" {
    // 第一次跑确定分配次数，再对 0..N-1 每个 fail_index 各跑一遍
    // triple 的三次分配都有 defer free ⇒ 全部路径都不泄漏 ⇒ 通过
    try std.testing.checkAllAllocationFailures(std.testing.allocator, triple, .{});
}

test "checkAllAllocationFailures 能抓出漏掉的回滚" {
    // leakyTriple 故意漏掉第一笔的 free ⇒ fail_index=1 时报 error.MemoryLeakDetected。
    // backing 用 FixedBufferAllocator 而不是 testing.allocator：
    // 这样"故意漏的那 8 字节"不会污染全局测试分配器，也不会额外产生 err 日志。
    var buf: [256]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    try std.testing.expectError(
        error.MemoryLeakDetected,
        std.testing.checkAllAllocationFailures(fba.allocator(), leakyTriple, .{}),
    );
}

test "log.err 在 test 块里必须守卫" {
    logOrPanic("这行在测试环境被守卫掉了，不会计入 log_err_count", .{});
    try std.testing.expect(true);
    // 去掉 logOrPanic 里的 `if (builtin.is_test) return;` 再跑：
    // 断言仍全过，但最后会多一行 `1 errors were logged.` 且退出码 1
}

test "测试替身：testing.io + testing.Reader，输出不碰真实世界" {
    const io = std.testing.io;
    try std.testing.expectEqual(@as(?u8, null), null); // 判空

    // greet 的 io 参数在测试里传 testing.io，真实环境传 init.io —— 同一份代码
    var buf: [64]u8 = undefined;
    const got = try greet(io, &buf);
    try std.testing.expectEqualStrings("hello, io", got);

    // testing.Reader：按脚本喂字节，连文件都不用建
    var storage: [16]u8 = undefined;
    var r = std.testing.Reader.init(&storage, &.{ .{ .buffer = "abc" }, .{ .buffer = "de" } });
    var out: [8]u8 = undefined;
    var w = std.Io.Writer.fixed(&out);
    _ = try r.interface.streamRemaining(&w);
    try std.testing.expectEqualStrings("abcde", w.buffered());
}

test "测试隔离：全局 var 在测试间不共享（各测试独立实例）" {
    // 实测：三个 test 块里g始终是 1，不累加 —— 每个 test 是独立编译期实例
    globalCounter += 1;
    try std.testing.expectEqual(@as(u32, 1), globalCounter);
}

test "手写基准：std.testing.benchmark 不存在，计时用 Io.Clock" {
    try std.testing.expect(!@hasDecl(std.testing, "benchmark"));
    try std.testing.expect(!@hasDecl(std.time, "Timer"));
    try std.testing.expect(@hasDecl(std.Io, "Clock"));

    const io = std.testing.io;
    const t0 = std.Io.Clock.now(.awake, io);
    var sink: u64 = 0;
    for (0..50) |_| sink +%= work(500);
    const t1 = std.Io.Clock.now(.awake, io);
    const ns = t0.durationTo(t1).nanoseconds;
    // 只断言"耗时为正"这个事实，不锁死具体数字（Debug 模式下数字没意义）
    try std.testing.expect(ns > 0);
    try std.testing.expect(sink != 0);
}

test "编译期测试：comptime 块里断言失败会变成编译错误" {
    // 正常路径：这段在**编译期**求值，失败会变成 @compileError 而非测试失败
    comptime {
        std.testing.expectEqual(@as(u32, 385), sqSum(10)) catch unreachable; // 1²+...+10² = 385
    }
    try std.testing.expectEqual(@as(u32, 385), @as(u32, @intCast(sqSum(10))));
}

test "编译期测试：用 @compileError 表达「这段应该编译失败」" {
    // 语义约束：业务上禁掉了 i32 → 在编译期就拒绝，而不是等运行期
    rejectsInt32(f64); // f64 允许
    // rejectsInt32(i32);← 取消注释：整个 zig test 编译失败，报 i32 被明确禁止
    try std.testing.expect(true);
}

test "refAllDecls：让编译器检查所有声明都被引用过" {
    // 惯用法：在测试里引用模块的所有 pub 声明，避免"声明了没人用"的静默腐烂
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(util);
}

test "SkipZigTest：主动跳过（不是失败）" {
    // 全量跑时跳过、在 CI 的某个子集里跑（配合 --test-filter 反过来用）
    // return error.SkipZigTest;
    try std.testing.expect(true);
}

test "unreferenced 的测试故意缺席" {
    // unreferenced 这个函数在本文件里定义了但**从未被引用**
    // ⇒ 它的 test 块（如果有）不会进 `zig test` 的清单
    // 这是"子模块测试静默缺席"的根源：15.4 节实测引用才进清单
    _ = &unreferenced;
    try std.testing.expect(true);
}

test {
    // 匿名 test 块：名字是 <编译单元>.test_0（15.2 节实测）
    // 这里的作用是把 util.zig 拽进测试清单 —— 引用即生效
    _ = util;
}

// leak 靶子：故意漏掉第一笔的 free，给 checkAllAllocationFailures 抓
var globalCounter: u32 = 0;

fn leakyTriple(gpa: std.mem.Allocator) !void {
    const a = try gpa.alloc(u8, 8);
    _ = a; // ← 没有 defer gpa.free(a)
    const b = try gpa.alloc(u8, 16);
    defer gpa.free(b);
}

fn rejectsInt32(comptime T: type) void {
    if (T == i32) @compileError("i32 被明确禁止：这里用 f64");
}
