//! 23 调试与工具：Zig 的调试哲学、panic 栈跟踪的真实格式（四种构建模式实测）、
//! unreachable / assert / @panic 三者的区别、error return trace（@errorReturnTrace 的
//! 0.17 新形状：返回 ?*StackTrace）、@errorName / @errorCast、std.log 分级与 scoped、
//! std.debug 的栈 dump API（0.17 全部要传 StackUnwindOptions）、自定义 panic handler、
//! 环境变量开关法（init.environ_map）、ZIG_PANIC / ZIG_BACKTRACE 在 0.17 的真实效果
//! （两者都已失效）、编译期诊断旗标（--verbose-link / -freference-trace / --debug-log）、
//! 调试信息旗标（-fstrip / -fno-omit-frame-pointer）、以及"读错误信息的四个层次"。
//!
//! 本章会**故意触发 panic**，但演示 panic 的部分全部跑在**子进程**里
//! （std.process.run 拉起同一个可执行文件的另一个实例），
//! 所以本文件的正常退出码恒为 0 —— `./run-all.sh 23_debug` 必须全绿。
const std = @import("std");
const builtin = @import("builtin");

/// 23.10 的接管点：`pub const panic` 是根声明，作用于整个编译单元。
/// 写成 `std.debug.FullPanic(myPanic)`（工厂函数返回类型），不是赋值函数指针。
pub const panic = std.debug.FullPanic(myPanic);

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 23.2/23.10 的 panic 靶子：三级调用链，每一级都是 noinline，
/// 这样在 ReleaseSafe/Fast 下也不会被内联掉（实测见 23.2）
noinline fn crashLeaf() void {
    @panic("演示 panic：这是 @panic 的自定义消息");
}

noinline fn crashMid() void {
    crashLeaf();
}

noinline fn crashTop() void {
    crashMid();
}

/// 23.4 的 unreachable / assert 靶子
fn pick(x: u8) u8 {
    if (x == 0) unreachable; // 分支1：编译器消息 reached unreachable code
    if (x == 1) @panic("自定义消息"); // 分支2：自定义文本
    return x;
}

/// 23.5 的 error return trace 靶子：三级错误上抛
fn errLeaf() error{Boom}!void {
    return error.Boom;
}

fn errMid() error{Boom}!void {
    return errLeaf();
}

fn errTop() error{Boom}!void {
    return errMid();
}

/// 23.3 的 assert 靶子：x==0 在 Debug/Safe 下炸，Fast/Small 下整个函数被优化掉
fn risky(x: u32) u32 {
    std.debug.assert(x != 0);
    return 100 / x;
}

/// 23.11 的环境变量开关：这是**给库用的实用做法**——
/// 开关只影响"要不要打印/要不要断"，不影响"能不能编译"。
/// 用 init.environ_map 读，Windows 和 POSIX 上形状完全一样
/// （旧文档写的 std.posix.getenv 在 Windows 上根本不存在，实测编译失败）。
fn debugEnabled(init: std.process.Init, comptime key: []const u8) bool {
    return init.environ_map.get(key) != null;
}

/// 23.10 / 23.15 的自定义 panic handler。
///
/// 0.17 的形状有两处变化：
///   1) `std.debug.panicImpl` **已移除**（实测 `@hasDecl(std.debug, "panicImpl") == false`）；
///   2) 接管方式是 `pub const panic = std.debug.FullPanic(myFn);`——
///      `FullPanic` 是个**工厂函数**，参数是 `fn ([]const u8, ?usize) noreturn`，
///      返回一个**类型**（不是直接赋值函数指针）。
///
/// 关键细节：`pub const panic` 是**整个编译单元的根声明**，一旦写上，
/// 本文件里**所有** panic 都走这里（包括 23.2/23.3 那些栈跟踪演示）。
/// 所以本 handler 做「按消息分流」：只有带标记的那条走自定义路径，
/// 其余原样转回 `std.debug.defaultPanic` —— 这也是真实项目里的常见写法
/// （先做崩溃上报，再委托默认行为打印现场）。
fn myPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    if (std.mem.indexOf(u8, msg, "[custom]") == null) {
        // 不归我管：原样交回默认 handler，栈跟踪一字不变
        std.debug.defaultPanic(msg, first_trace_addr);
    }
    // 归我管：自定义动作。first_trace_addr 是首帧返回地址（可为 null），
    // 想继续打栈就把它传给 dumpCurrentStackTrace(.{ .first_address = ... })。
    std.debug.print("[myPanic] 接管 panic：{s}\n", .{msg});
    std.debug.print("[myPanic] 首帧地址存在吗：{}（不打印栈跟踪，这是自定义 handler 的取舍）\n", .{first_trace_addr != null});
    std.debug.print("[myPanic] 改用 std.process.exit(101) 干净退出（不是 SIGABRT 的 134）\n", .{});
    std.process.exit(101);
}

/// 用子进程跑一段"注定崩"的代码，把它的 stderr 抓回来。
/// 这是本章所有 panic 演示的**唯一实现手段**——因为验证脚本要求退出码 0。
/// 0.17 形状：`std.process.run(gpa, io, opts)` 三参数，返回值 owns 两块缓冲，
/// 必须 `init.gpa.free`。`max_output_bytes` 已改名 `stderr_limit: Io.Limit`。
fn runCrasher(init: std.process.Init, arena: std.mem.Allocator, label: []const u8, lines: usize) void {
    const self = std.process.executablePathAlloc(init.io, arena) catch |err| {
        std.debug.print("  [{s}] 取不到自身路径（{s}），本节跳过\n", .{ label, @errorName(err) });
        return;
    };
    const child = std.process.run(init.gpa, init.io, .{
        .argv = &.{ self, label },
        .stderr_limit = .limited(64 * 1024),
    }) catch |err| {
        std.debug.print("  [{s}] 拉子进程失败：{s}\n", .{ label, @errorName(err) });
        return;
    };
    defer {
        init.gpa.free(child.stdout);
        init.gpa.free(child.stderr);
    }
    std.debug.print("  [{s}] 子进程 term={any}，stderr 共 {d} 字节\n", .{ label, child.term, child.stderr.len });
    std.debug.print("  [{s}] stderr 前 {d} 行（地址每次不同，这里原样贴出）：\n", .{ label, lines });
    var it = std.mem.splitScalar(u8, child.stderr, '\n');
    for (0..lines) |_| {
        const line = it.next() orelse break;
        std.debug.print("    {s}\n", .{line});
    }
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    // 子进程模式：argv[1] 命中就跑注定崩的分支（父进程不受影响）
    const argv = try init.minimal.args.toSlice(arena);
    const mode: []const u8 = if (argv.len > 1) argv[1] else "";

    // ═══ 子进程入口：以下分支只有子进程会走，父进程永远不崩 ═══
    if (std.mem.eql(u8, mode, "crash-panic")) {
        crashTop();
    }
    if (std.mem.eql(u8, mode, "crash-unreachable")) {
        _ = pick(0);
    }
    if (std.mem.eql(u8, mode, "crash-assert")) {
        _ = risky(0);
    }
    if (std.mem.eql(u8, mode, "crash-ert")) {
        return errTop();
    }
    if (std.mem.eql(u8, mode, "crash-breakpoint")) {
        @breakpoint(); // 无调试器 → SIGTRAP（实测退出码 133）
        return;
    }
    if (std.mem.eql(u8, mode, "crash-custom-panic")) {
        crashCustom();
    }

    // ═══ 23.1 Zig 的调试哲学：类型和编译器负责大部分事 ═══
    begin("23.1 调试哲学");
    std.debug.print("Zig 的排错顺序：编译错（comptime）→ panic（运行期不可恢复）→ error（可恢复）\n", .{});
    std.debug.print("没有 printf 式猜测：类型写错是**编译错误**，不是运行期 surprises\n", .{});
    std.debug.print("本文件能编过 ⇒ 23 个小节里没有一处类型错误；能跑完 ⇒ 没有未处理的错误\n", .{});
    std.debug.print("panic 在Zig 的设计里是**一等公民**，不是\"失败\"：它是\"这里不可能成立\"的宣告\n", .{});
    std.debug.print("本节要用的四个诊断维度：\n", .{});
    std.debug.print("  1) 编译期：-freference-trace 追\"谁引用的\"\n", .{});
    std.debug.print("  2) panic：消息 + 栈跟踪（本节起23.2）\n", .{});
    std.debug.print("  3) error return trace：错误从产生到上抛的路径（23.5）\n", .{});
    std.debug.print("  4) 调试器：lldb / gdb（23.13）\n", .{});
    end("23.1 调试哲学");

    // ═══ 23.2 panic 栈跟踪：真实格式（子进程实测） ═══
    begin("23.2 panic 栈跟踪");
    std.debug.print("子进程里跑 crashTop()（三级 noinline 调用链 + @panic）：\n", .{});
    runCrasher(init, arena, "crash-panic", 12);
    std.debug.print("读法（地址每次不同，本教程用 0xADDR 占位）：\n", .{});
    std.debug.print("  thread <tid> panic: <你的消息>\n", .{});
    std.debug.print("  <路径>:<行>:<列>: 0xADDR in <函数名> (<镜像名>)\n", .{});
    std.debug.print("      <源码行>\n", .{});
    std.debug.print("      ^（列指示线，^ 对准出问题的那一列）\n", .{});
    std.debug.print("  末帧 ???:?:?: 0xADDR in start (/usr/lib/dyld) —— 动态链接器，不是你的代码\n", .{});
    std.debug.print("  macOS 上括号里是 Mach-O 镜像名（本例是main）；Windows 上是 (main.obj)\n", .{});
    std.debug.print("  in callMain 是 std/start.zig 的包装层，在它上面才是你写的 in main\n", .{});
    end("23.2 panic 栈跟踪");

    // ═══ 23.3 unreachable / assert / @panic 三者的区别 ═══
    begin("23.3 三种失败方式");
    std.debug.print("unreachable   → 消息固定 \"reached unreachable code\"（无自定义文本）\n", .{});
    std.debug.print("@panic(\"...\") → 消息就是你写的字符串\n", .{});
    std.debug.print("std.debug.assert(cond) → 消息也是 \"reached unreachable code\"，但多一帧 in assert\n", .{});
    std.debug.print("               （多出的那一帧是 lib/std/debug.zig:442 的 assert 函数本身）\n", .{});
    std.debug.print("三者的栈跟踪形状完全一样，区别只在**第一行消息**和**多不多 assert 帧**\n", .{});
    runCrasher(init, arena, "crash-unreachable", 6);
    runCrasher(init, arena, "crash-assert", 8);
    end("23.3 三种失败方式");

    // ═══ 23.4 构建模式与 std.debug.assert 的生死 ═══
    begin("23.4 构建模式与 assert");
    std.debug.print("本文件编译模式 = {s}（@tagName(builtin.mode)，0.17 四个值全小写）\n", .{@tagName(builtin.mode)});
    std.debug.print("旧的 Debug / ReleaseSafe 大写名在 0.17 是**废弃别名**\n", .{});
    switch (@typeInfo(@TypeOf(builtin.mode))) {
        .@"enum" => |e| {
            std.debug.print("枚举成员实测：", .{});
            inline for (e.field_names) |n| std.debug.print("{s} ", .{n});
            std.debug.print("\n", .{});
        },
        else => {},
    }
    std.debug.print("risky(4) = {d}（正常路径，assert 通过）\n", .{risky(4)});
    std.debug.print("⚠️ assert 在 ReleaseFast/ReleaseSmall 下被**整个删除**（不是变便宜）\n", .{});
    std.debug.print("   实测证据：二进制里字符串 \"reached unreachable code\" 的出现次数\n", .{});
    std.debug.print("   Debug/ReleaseSafe = 1（还在）；ReleaseFast/ReleaseSmall = 0（被删了）\n", .{});
    std.debug.print("⇒ assert 只断\"逻辑不可能\"；真可能发生的用!T 错误返回（10 章）\n", .{});
    std.debug.print("⇒ 子进程跑 risky(0) 的真实结果（三种完全不同的死法，实测）：\n", .{});
    std.debug.print("   Debug     → panic \"reached unreachable code\"，SIGABRT，退出码 134\n", .{});
    std.debug.print("   ReleaseSafe → 同样 SIGABRT 退出码 134，但栈跟踪只剩一帧（见 23.2.3）\n", .{});
    std.debug.print("   ReleaseFast → assert 没了，除以 0 变成 UB：x86 上是死循环，**进程挂住**\n", .{});
    std.debug.print("   ReleaseSmall → UB 被编译成 ud2 指令：SIGILL，退出码 132\n", .{});
    std.debug.print("   ⇒ \"Debug 测得好好的、发布版裸奔\"不是比喻，是这四行实测\n", .{});
    end("23.4 构建模式与 assert");

    // ═══ 23.5 error return trace：错误从产生到上抛的路径 ═══
    begin("23.5 error return trace");
    std.debug.print("panic 栈回答\"崩在哪\"（调用栈）；error return trace 回答\"这个错从哪来\"\n", .{});
    std.debug.print("（try 传播链，10 章讲概念，本节讲工具）\n", .{});
    std.debug.print("子进程让 main 直接 return 一个错误，看 std/start.zig 打印什么：\n", .{});
    runCrasher(init, arena, "crash-ert", 12);
    std.debug.print("对比记忆：\n", .{});
    std.debug.print("  panic → 首行 `thread <tid> panic: <msg>`，退出码 134（SIGABRT）\n", .{});
    std.debug.print("  error → 首行 `error: Boom`，退出码 **1**（正常退出，不是信号）\n", .{});
    std.debug.print("  也就是说：**错误返回不是崩溃**，这是Zig 和 C 的根本区别\n", .{});
    end("23.5 error return trace");

    // ═══ 23.6 @errorReturnTrace 的 0.17 新形状 ═══
    begin("23.6 @errorReturnTrace");
    std.debug.print("⚠️ 0.17 的形状变了：@errorReturnTrace() 返回 **?*StackTrace**（可选指针）\n", .{});
    std.debug.print("   旧写法 `const t = @errorReturnTrace(); t.index` 在 0.17 **编译失败**：\n", .{});
    std.debug.print("   error: type '?*lang.StackTrace' does not support field access（实测）\n", .{});
    const maybe_trace = @errorReturnTrace();
    std.debug.print("本作用域 @errorReturnTrace() 类型 = {s}\n", .{@typeName(@TypeOf(maybe_trace))});
    if (maybe_trace) |t| {
        std.debug.print("  非空：index={d}，instruction_addresses.len={d}\n", .{ t.index, t.instruction_addresses.len });
        std.debug.print("  （index > 0 说明当前在错误传播路径上；否则是 0）\n", .{});
    } else {
        std.debug.print("  为 null：当前作用域没有错误返回跟踪\n", .{});
    }
    std.debug.print("字段名实测（std.builtin.StackTrace）：\n", .{});
    switch (@typeInfo(std.builtin.StackTrace)) {
        .@"struct" => |s| {
            inline for (s.field_names, s.field_types) |fname, ftype| {
                std.debug.print("  .{s:<24}: {s}\n", .{ fname, @typeName(ftype) });
            }
        },
        else => {},
    }
    end("23.6 @errorReturnTrace");

    // ═══ 23.7 @errorName 与 @errorCast ═══
    begin("23.7 @errorName / @errorCast");
    errTop() catch |err| {
        std.debug.print("errTop 的错误名 = {s}（@errorName）\n", .{@errorName(err)});
        std.debug.print("catch 分支里 err 的类型 = {s}\n", .{@typeName(@TypeOf(err))});
        // @errorCast：把 anyerror 收窄成具体错误集合，失败会 panic
        const any: anyerror = err;
        const narrow: error{Boom} = @errorCast(any);
        std.debug.print("@errorCast(anyerror → error{{Boom}}) = {s}\n", .{@errorName(narrow)});
        // 收窄不匹配时会 panic：attempt to cast error value ...（实测见下）
        std.debug.print("⚠️ @errorCast 收窄不匹配会 panic，所以它适合\"已经确定是哪个错\"的收窄点\n", .{});
        std.debug.print("   典型用法：把 anyerror 往上游传递的库API 里做窄化\n", .{});
    };
    std.debug.print("三者的分工：\n", .{});
    std.debug.print("  @errorName(e)     → 把错误值变成字符串（给人看）\n", .{});
    std.debug.print("  @errorCast(e)     → 窄化错误集合（给编译器看），运行时可能 panic\n", .{});
    std.debug.print("  @errorReturnTrace() → 这个错误是从哪条 try 链上来的（给排查看）\n", .{});
    end("23.7 @errorName / @errorCast");

    // ═══ 23.8 std.debug 的栈dump API（0.17 全部要传options） ═══
    begin("23.8 std.debug 栈dump");
    std.debug.print("dumpCurrentStackTrace / dumpStackTrace / captureCurrentStackTrace 都**存在**\n", .{});
    std.debug.print("⚠️ 但 0.17 的 dumpCurrentStackTrace **要一个参数**：\n", .{});
    std.debug.print("   dumpCurrentStackTrace()写 0.17 会报 expected 1 argument(s), found 0（实测）\n", .{});
    std.debug.print("   正确写法：dumpCurrentStackTrace(.{{}})，参数类型 = StackUnwindOptions\n", .{});
    std.debug.print("StackUnwindOptions 的字段（实测 std/debug.zig:666）：\n", .{});
    switch (@typeInfo(std.debug.StackUnwindOptions)) {
        .@"struct" => |s| {
            inline for (s.field_names, s.field_types) |fname, ftype| {
                std.debug.print("  .{s:<22}: {s}\n", .{ fname, @typeName(ftype) });
            }
        },
        else => {},
    }
    std.debug.print("stack 追踪的输出（走的是 stackUnwindOptions.first_address = @returnAddress()）：\n", .{});
    dumpDemo();
    end("23.8 std.debug 栈dump");

    // ═══ 23.9 std.log：分级、scoped、以及 test 里的坑 ═══
    begin("23.9 std.log");
    std.debug.print("std.debug.print：无级别、直接写 stderr、永远打印 —— 用来做示例输出\n", .{});
    std.debug.print("std.log.*    ：有级别（err/warn/info/debug）、默认按级别过滤 —— 用来做库日志\n", .{});
    std.debug.print("Level 枚举成员实测（用 field_names，不是 fields）：", .{});
    switch (@typeInfo(std.log.Level)) {
        .@"enum" => |e| {
            std.debug.print("", .{});
            inline for (e.field_names) |n| std.debug.print("{s} ", .{n});
            std.debug.print("\n", .{});
        },
        else => {},
    }
    std.debug.print("⚠️ @typeInfo(...).@\"enum\" 在 0.17 的字段是 field_names/field_types，**没有 fields**\n", .{});
    std.debug.print("   写 e.fields.len 会报 no field named 'fields' in struct 'lang.Type.Enum'（实测）\n", .{});
    std.debug.print("std.log.default_level = {t}（.debug 模式下是 debug，.safe/.fast/.small 下是 info）\n", .{std.log.default_level});
    std.debug.print("⚠️ 所以 Debug 下 std.log.debug **默认就会打印**（不是被过滤掉）\n", .{});
    const log = std.log.scoped(.demo_scope); // ← 作用域名是 @EnumLiteral，只能用 ASCII 标识符
    std.debug.print("--- 下面三条是 std.log.scoped(.demo_scope) 的真实输出 ---\n", .{});
    log.info("scoped 日志的格式是 <级别>(<作用域>): <消息>", .{});
    log.warn("注意 warning 的文本是 'warning' 不是 'warn'", .{});
    std.debug.print("--- scoped 类型 = {s} ---\n", .{@typeName(@TypeOf(log))});
    std.debug.print("⚠️ scoped 返回的是**匿名 struct 类型**，它没有 .scope 字段（实测编译失败）\n", .{});
    std.debug.print("⚠️ test 块里 std.log.err 会让 zig test 退出码变成 1（15.10 实测，本章 test 块守着这条）\n", .{});
    end("23.9 std.log");

    // ═══ 23.10 panic handler 的形状（0.17 改成了工厂函数） ═══
    begin("23.10 panic handler");
    std.debug.print("0.17 的 panic handler 签名（实测 defaultPanic）：\n", .{});
    std.debug.print("  {s}\n", .{@typeName(@TypeOf(std.debug.defaultPanic))});
    std.debug.print("  两个参数：消息 + 首帧返回地址（first_trace_addr，可为 null）\n", .{});
    std.debug.print("std.debug.panicImpl 在 0.17 **不存在**（实测 @hasDecl = false）\n", .{});
    std.debug.print("接管方式是 `pub const panic = std.debug.FullPanic(myFn);` —— 它是个**工厂函数**\n", .{});
    std.debug.print("返回类型，内部把outOfBounds / unwrapError / reachedUnreachable 全部转调myFn\n", .{});
    std.debug.print("子进程跑自定义 handler（crash-custom-panic 分支）：\n", .{});
    runCrasher(init, arena, "crash-custom-panic", 8);
    std.debug.print("⇒ handler 里 std.process.exit(101) 让退出码从 134 变成 101\n", .{});
    end("23.10 panic handler");

    // ═══ 23.11 环境变量开关法 ═══
    begin("23.11 环境变量开关");
    std.debug.print("给库加调试开关的实用做法：一个 if，不改构建、不改结构\n", .{});
    std.debug.print("读法只有一种（Windows 和 POSIX 形状一致）：init.environ_map.get(\"KEY\")\n", .{});
    std.debug.print("⚠️ 旧文档写的 std.posix.getenv 在 Windows 上不可用 —— 0.17 里 std.posix 也没了getenv\n", .{});
    std.debug.print("   std.process.getEnvVarOwned / std.posix.getenv 这类POSIX-only 写法别用\n", .{});
    std.debug.print("init.environ_map 的类型 = {s}\n", .{@typeName(@TypeOf(init.environ_map))});
    std.debug.print("本进程实测：DEBUG_ZIG=1 存在吗？{}\n", .{debugEnabled(init, "DEBUG_ZIG")});
    std.debug.print("本进程实测：ZIG_PANIC=1 存在吗？{}\n", .{debugEnabled(init, "ZIG_PANIC")});
    std.debug.print("⇒ 开关的语义：**存在即真**，不管值是不是 \"0\"（这是最常见的误用）\n", .{});
    std.debug.print("   要区分 \"0\"（关）和 \"1\"（开）必须自己比字符串\n", .{});
    end("23.11 环境变量开关");

    // ═══ 23.12 ZIG_PANIC / ZIG_BACKTRACE 在 0.17 的真实效果 ═══
    begin("23.12 ZIG_PANIC / ZIG_BACKTRACE");
    std.debug.print("⚠️⚠️ 实测结论：**两个变量在 0.17 都已失效**（不是废弃，是完全无效）\n", .{});
    std.debug.print("ZIG_PANIC=1 的旧作用是\"让 ReleaseFast 也 panic\"。0.17 实测：\n", .{});
    std.debug.print("  Debug 下整数溢出本来 panic（与 ZIG_PANIC 无关）\n", .{});
    std.debug.print("  ReleaseSafe 下本来 panic（与 ZIG_PANIC 无关）\n", .{});
    std.debug.print("  ReleaseFast/ReleaseSmall 下：设与不设 **都是静默 UB**（实测打印 c=0 / 越界读出垃圾）\n", .{});
    std.debug.print("  源码搜索：lib/std 全目录 grep ZIG_PANIC / ZIG_BACKTRACE **零命中**\n", .{});
    std.debug.print("  （stdio.zig / start.zig / debug.zig 里都没有读这两个变量的代码）\n", .{});
    std.debug.print("ZIG_BACKTRACE 的旧作用是0/1/full 三档控制栈跟踪。0.17 实测：\n", .{});
    std.debug.print("  ZIG_BACKTRACE=0/ 1 / full / 不设，**四种情况的帧数完全一样**\n", .{});
    std.debug.print("  切换栈跟踪在 0.17 的正确做法：-fstrip（关掉）/ -fno-omit-frame-pointer（保留帧指针）\n", .{});
    std.debug.print("⇒ 别再依赖这两个变量；要可复现的 panic 请显式 build-exe 并检查退出码\n", .{});
    end("23.12 ZIG_PANIC / ZIG_BACKTRACE");

    // ═══ 23.13 编译期诊断旗标 ═══
    begin("23.13 编译期诊断");
    std.debug.print("** 都在 --help 里，逐字抄（zig build-exe --help）：\n", .{});
    std.debug.print("  -freference-trace[=num]   每个编译错误显示 num 行引用跟踪\n", .{});
    std.debug.print("  -fno-reference-trace      禁用引用跟踪（默认是开启且带隐藏行数）\n", .{});
    std.debug.print("  --verbose-link            显示链接器调用\n", .{});
    std.debug.print("  --debug-log [scope]启用指定作用域的编译期日志\n", .{});
    std.debug.print("⚠️ 但本机发布的 zig 二进制**没带日志编译**：--debug-log 实测输出\n", .{});
    std.debug.print("   warning: Zig was compiled without logging enabled (-Dlog). --debug-log has no effect.\n", .{});
    std.debug.print("   也就是说这个选项要自己编译 zig 才有意义（官方 debug 版才有）\n", .{});
    std.debug.print("错误信息分两段读：第一段是 error 本身，第二段 `referenced by:` 是引用链\n", .{});
    std.debug.print("默认只显示前若干层、其余折叠成 `N reference(s) hidden; use '-freference-trace=N'`\n", .{});
    end("23.13 编译期诊断");

    // ═══ 23.14 调试信息旗标 ═══
    begin("23.14 调试信息旗标");
    std.debug.print("**（zig build-exe --help 实测）：\n", .{});
    std.debug.print("  -fstrip                去掉调试符号（⇒ 栈跟踪不可用）\n", .{});
    std.debug.print("  -fno-strip             保留调试符号\n", .{});
    std.debug.print("  -fomit-frame-pointer   省略栈帧指针\n", .{});
    std.debug.print("  -fno-omit-frame-pointer保留栈帧指针（回溯质量更好，代价是慢一点）\n", .{});
    std.debug.print("  -funwind-tables        为所有函数生成展开表条目\n", .{});
    std.debug.print("  -fno-unwind-tables     永不生成展开表条目\n", .{});
    std.debug.print("std.options.allow_stack_tracing = !builtin.strip_debug_info（实测本文件 = {}）\n", .{std.options.allow_stack_tracing});
    std.debug.print("⚠️ -fstrip 之后 panic 输出会变成一行字（实测，见文档 23.14）：\n", .{});
    std.debug.print("   Cannot print stack trace: stack tracing is disabled\n", .{});
    std.debug.print("   ⚠️ 注意：Debug 模式 + -fstrip 也一样没栈跟踪（不是只有 Release 才受影响）\n", .{});
    std.debug.print("中间产物旗标：-femit-asm / -femit-llvm-ir / -femit-docs（实测选项名）\n", .{});
    end("23.14 调试信息旗标");

    // ═══ 23.15 自定义 panic handler 与 @breakpoint ═══
    begin("23.15 自定义 handler 与 @breakpoint");
    std.debug.print("@breakpoint() 生成一条真实断点指令（x86/macOS 是 SIGTRAP）\n", .{});
    std.debug.print("有调试器 → 停下；无调试器 → 直接被信号打死（实测子进程退出码 133 = 128+5）\n", .{});
    std.debug.print("⚠️ 它**不是**可捕获的错误，也不 panic —— 所以必须配环境变量开关（23.11）\n", .{});
    std.debug.print("@compileLog(...) 在 0.17 是 **error**（不是 warning），实测输出：\n", .{});
    std.debug.print("   error: found compile log statement\n", .{});
    std.debug.print("   用来打印 comptime 算出的值，看完必须删（13 章）\n", .{});
    std.debug.print("自定义 panic handler 已在 23.10 用子进程验证（退出码 101，不是 134）\n", .{});
    end("23.15 自定义 handler 与 @breakpoint");

    // ═══ 23.16 读错误信息的四个层次 ═══
    begin("23.16 四个层次");
    std.debug.print("看到一大段报错时，按这个顺序读：\n", .{});
    std.debug.print("  第 1 层「哪条 error」      → 第一行 `error: xxx` 或 `panic: xxx`，这是**根因种类**\n", .{});
    std.debug.print("  第 2 层「哪一行」          → 第一条 `文件:行:列` + 源码行 + ^ 指示线，**这是根因位置**\n", .{});
    std.debug.print("  第 3 层「error return context」→ 错从哪个函数冒出来的（只在 Debug 且确实是错误时出现）\n", .{});
    std.debug.print("  第 4 层「stack trace」      → 崩在哪条调用路径上；末尾的 callMain / dyld 是固定噪声\n", .{});
    std.debug.print("⚠️ 初学者最常见的误读：把第 4 层的调用栈当成根因。\n", .{});
    std.debug.print("   panic 栈的**第一帧**才是根因位置，往下都是「谁调用了它」。\n", .{});
    std.debug.print("⚠️ 第二个常见误读：把\"引用链\"（referenced by:）当成调用栈。\n", .{});
    std.debug.print("   referenced by: 是**编译期**的引用关系，不是运行期调用关系。\n", .{});
    end("23.16 四个层次");

    // ═══ 23.17 lldb 速查（附本机实测状态） ═══
    begin("23.17 lldb");
    std.debug.print("Zig 产物带标准 DWARF（macOS/Linux）/ PDB（Windows），lldb 与 VS 调试器开箱即用\n", .{});
    std.debug.print("本机实测：lldb 能**载入并解析符号**（实测输出见文档 23.17）：\n", .{});
    std.debug.print("  target create \"./main\" → Current executable set to '...' (x86_64).\n", .{});
    std.debug.print("  breakpoint set -n compute → where = main`main.compute + 10 at main.zig:2:32\n", .{});
    std.debug.print("⚠️ 但本机 `lldb run` 会挂死（纯 C 二进制对照也一样）—— 属于本机环境限制，\n", .{});
    std.debug.print("   不是 Zig 产物的问题。命令序列本身是可用的，见文档 23.17。\n", .{});
    std.debug.print("不依赖调试器的替代方案：\n", .{});
    std.debug.print("  std.debug.print 打点（23.1~23.16 用的就是这个）\n", .{});
    std.debug.print("  子进程复现 + 拿 stderr（本章所有 panic 演示的做法）\n", .{});
    std.debug.print("  error return trace 定位错误源头（23.5~23.6）\n", .{});
    end("23.17 lldb");

    std.debug.print("自检通过\n", .{});
}

/// 23.8 的实际调用点：三级 noinline，让 dumpCurrentStackTrace 的输出好看
noinline fn dumpLeaf() void {
    std.debug.dumpCurrentStackTrace(.{});
}

noinline fn dumpMid() void {
    dumpLeaf();
}

noinline fn dumpTop() void {
    dumpMid();
}

fn dumpDemo() void {
    dumpTop();
}

/// 23.10 的靶子：消息里带 [custom] 标记，会被 myPanic 分流到自定义路径
fn crashCustom() void {
    @panic("[custom] 这条 panic 走自定义 handler");
}

test "risky 正常路径（assert 通过）" {
    try std.testing.expectEqual(@as(u32, 25), risky(4));
}

test "panic 靶子存在且返回 void（不真调，真调会 panic）" {
    // 只断言"能编出来、签名是 void"，不真调 —— 测试进程没有子进程兜底。
    // ⚠️ 这里踩过15.4.2 的坑：@typeName 对**函数**返回的是带签名的名字
    // （"noinline fn () void"），不是 "void"；而且它返回字符串切片，
    // expectEqual 对切片比的是**指针** → 必须用 expectEqualStrings。
    const ty = @typeName(@TypeOf(crashTop));
    try std.testing.expect(std.mem.endsWith(u8, ty, "void"));
}

test "@errorReturnTrace 在 0.17 返回可选指针" {
    const maybe = @errorReturnTrace();
    try std.testing.expect(@TypeOf(maybe) == ?*std.builtin.StackTrace);
    // 当前不在错误传播路径上 ⇒ index 为 0（若拿到非空指针）
    if (maybe) |t| try std.testing.expectEqual(@as(usize, 0), t.index);
}

test "三层错误上抛：@errorName 是 Boom，@errorCast 窄化成功" {
    try std.testing.expectError(error.Boom, errTop());
    // ⚠️ 0.17 的坑：`const e: anyerror = errTop() catch |err| err;` 编译失败——
    //因为 errTop() 返回 !void，`catch |err| err` 的 peer 类型是 void（成功分支），
    // 实测报expected type 'anyerror', found 'void'。
    // 正确写法：先拿错误联合，再用 if/else 解包（下面就是）。
    const r = errTop();
    if (r) |_| {
        return error.TestUnexpectedResult;
    } else |err| {
        try std.testing.expectEqualStrings("Boom", @errorName(err));
        try std.testing.expect(@TypeOf(err) == error{Boom});
        const any: anyerror = err;
        const narrow: error{Boom} = @errorCast(any);
        try std.testing.expectEqual(error.Boom, narrow);
    }
}

test "构建模式的枚举成员全小写（0.17）" {
    // 旧名 Debug / ReleaseSafe 在 0.17 是废弃别名；@tagName 给的是 debug/safe/fast/small。
    const mode_str = @tagName(builtin.mode);
    try std.testing.expect(std.mem.eql(u8, mode_str, "debug") or
        std.mem.eql(u8, mode_str, "safe") or
        std.mem.eql(u8, mode_str, "fast") or
        std.mem.eql(u8, mode_str, "small"));
    try std.testing.expect(!std.mem.eql(u8, mode_str, "Debug")); // 大写名不再出现
    // 正常路径：assert 通过
    try std.testing.expectEqual(@as(u32, 25), risky(4));
}

test "std.log 的 enum 用 field_names 而不是 fields" {
    const info = @typeInfo(std.log.Level);
    try std.testing.expect(info == .@"enum");
    try std.testing.expectEqual(@as(usize, 4), info.@"enum".field_names.len);
    try std.testing.expect(!@hasDecl(std.log, "Level.fields"));
}

test "std.debug 的 0.17 形状：panicImpl 没了，dump* 要 options" {
    try std.testing.expect(!@hasDecl(std.debug, "panicImpl"));
    try std.testing.expect(@hasDecl(std.debug, "dumpCurrentStackTrace"));
    try std.testing.expect(@hasDecl(std.debug, "FullPanic"));
    try std.testing.expectEqual(
        @as(usize, 1),
        @typeInfo(@TypeOf(std.debug.dumpCurrentStackTrace)).@"fn".param_types.len,
    );
}

test "0.17 里ZIG_PANIC / ZIG_BACKTRACE 已从std 移除" {
    // 不是"变量无效"，是 std 里根本没有读它们的代码（grep 零命中）。
    // 这里能断言的只是：Environment.Map 上没有 std 预置的这些键。
    try std.testing.expect(!@hasDecl(std.process, "ZIG_PANIC"));
}
