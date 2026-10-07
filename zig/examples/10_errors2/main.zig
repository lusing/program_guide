//! 10 错误处理 II：errdefer 的回滚纪律、defer/errdefer 执行顺序实测、错误返回追踪的真实开关、@errorCast 边界、错误到退出码的映射、std.log 分级与作用域、?E!T 三态与内存代价、错误/panic/退出码的分工
const std = @import("std");
const builtin = @import("builtin");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 10.1 errdefer：只在返回错误时执行的回滚 ═══
/// 一个带身份的小对象，用来观察"分配成功但初始化失败"这类半成品
const Thing = struct { id: u32 };

/// 全局计数器：副作用的可观测证据（errdefer 要回滚的就是它）
var made: usize = 0;

/// 正例：拿到对象就立刻挂 errdefer，失败自动回滚计数
fn makeThing(gpa: std.mem.Allocator, id: u32) !*Thing {
    made += 1; // 副作用①：登记"我造了一个"
    errdefer made -= 1; //失败 → 撤销①
    const t = try gpa.create(Thing); // 这一步自己失败 → 只有① 需要撤销
    errdefer gpa.destroy(t); // 后续失败 → ② 撤销已分配的对象
    t.* = .{ .id = id };
    return t; // 成功：两条errdefer 都不跑，所有权交给调用方
}

/// 观察用：id == 0 时在"已分配、未初始化"的中途失败
fn makeThingChecked(gpa: std.mem.Allocator, id: u32) !*Thing {
    made += 1;
    errdefer made -= 1; // ①
    const t = try gpa.create(Thing);
    errdefer gpa.destroy(t); // ②
    if (id == 0) return error.BadId; // 半路失败：② 先跑（后进先出），再跑 ①
    t.* = .{ .id = id };
    return t;
}

// ═══ 10.2 多种资源同时获取：逐步挂 errdefer 的回滚纪律 ═══
/// 分配-初始化：alloc 成功就挂 errdefer，后续任何失败都有人兜底
fn buildList(gpa: std.mem.Allocator, n: usize) ![]u32 {
    const slice = try gpa.alloc(u32, n);
    errdefer gpa.free(slice); // 失败 → 归还
    for (slice, 0..) |*p, i| p.* = @intCast(i * 2);
    if (n > 8) return error.TooBig;
    return slice; // 成功 → 所有权移交，调用方负责 free
}

/// 三段资源：每成功获取一段就立刻挂一条 errdefer，纪律是"不多不少不少条"
fn buildTriple(gpa: std.mem.Allocator, n: usize) ![][]u32 {
    const a = try gpa.alloc(u32, n);
    errdefer gpa.free(a); // ①
    const b = try gpa.alloc(u32, n);
    errdefer gpa.free(b); // ②
    const out = try gpa.alloc([]u32, 2);
    errdefer gpa.free(out); // ③
    if (n > 4) return error.TooBig; // 失败 → ③②① 逆序全部回滚
    out[0] = a;
    out[1] = b;
    return out;
}

/// 部分初始化对象的清理机制：把"半成品"也当成合法返回值的一部分
/// 成功时 errdefer 全不跑；失败时对象连同已登记的行数一起消失
const Loaded = struct { rows: []u32, truncated: bool };

fn loadRamp(gpa: std.mem.Allocator, src: []const u8) !Loaded {
    // 第一步：按上界分配。选上界是"部分初始化"的关键——先占位，再逐步填
    const buf = try gpa.alloc(u32, src.len);
    errdefer gpa.free(buf); // 失败 → 释放半成品
    var n: usize = 0;
    for (src) |c| {
        if (c == 'x') {
            // 业务失败：buf 已经装了 n 个有效数字，errdefer 负责把它收掉
            return error.BadChar;
        }
        buf[n] = c;
        n += 1;
    }
    return .{ .rows = buf, .truncated = n < src.len };
}

// ═══ 10.3 defer 与 errdefer 的执行顺序（实测，不是直觉） ═══
/// 记录 cleanup 实际执行顺序的轨迹缓冲
const Trace = struct {
    buf: [16]u8 = undefined,
    len: usize = 0,

    fn mark(self: *Trace, c: u8) void {
        self.buf[self.len] = c;
        self.len += 1;
    }

    fn text(self: *const Trace) []const u8 {
        return self.buf[0..self.len];
    }

    fn reset(self: *Trace) void {
        self.len = 0;
    }
};

/// 同作用域：defer 先注册、errdefer 后注册
fn cleanupDeferFirst(ok: bool, t: *Trace) Err!u8 {
    defer t.mark('D');
    errdefer t.mark('E');
    if (!ok) return error.Nope;
    return 1;
}

/// 同作用域：errdefer 先注册、defer 后注册（只把两行调换）
fn cleanupErrdeferFirst(ok: bool, t: *Trace) Err!u8 {
    errdefer t.mark('E');
    defer t.mark('D');
    if (!ok) return error.Nope;
    return 1;
}

/// 嵌套：外层 defer 先注册、内层 errdefer 后注册
fn cleanupNested(ok: bool, t: *Trace) Err!u8 {
    defer t.mark('o'); // 外层，第 1 个注册
    errdefer t.mark('e');
    {
        defer t.mark('i'); // 内层，第 3 个注册
        errdefer t.mark('I'); // 内层，第 4 个注册
        if (!ok) return error.Nope;
    }
    return 1;
}

/// 循环里defer 的累积代价：每轮都注册，全部堆在函数出口
fn loopDeferCount(n: usize) usize {
    var fired: usize = 0;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        defer fired += 1; // 每轮一条，全在函数返回时跑
    }
    return fired;
}

/// 正确姿势：把需要每轮清理的活儿封成独立函数，让 defer 随作用域离开
fn loopScoped(n: usize, t: *Trace) void {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        deferRound(i, t); // 每轮进出一次独立作用域，defer 立即生效
    }
}

fn deferRound(i: usize, t: *Trace) void {
    defer t.mark(if (i % 2 == 0) 'e' else 'o');
}

// ═══ 10.4 错误返回追踪：产生点 → 每一层交接 ═══
const CfgError = error{ ConfigMissing, BadPort };

fn readConfigLine() CfgError![]const u8 {
    return error.ConfigMissing; // 错误的产生点
}
fn loadConfig() CfgError![]const u8 {
    return try readConfigLine(); // 第一层交接
}
fn startService() CfgError!void {
    _ = try loadConfig(); // 第二层交接
}
fn bootstrap() CfgError!void {
    try startService(); // 第三层交接
}

/// @setRuntimeSafety(false) 关不掉 error return trace（实测：trace 照样出现）
fn bootstrapNoSafety() CfgError!void {
    @setRuntimeSafety(false);
    try startService();
}

// ═══ 10.5 catch 的分类处理：把内部错误映射成应用层语义 ═══
/// 内部错误（细）：驱动库/解析层用
const StoreError = error{
    FileNotFound,
    PermissionDenied,
    DiskFull,
    ConnectionLost,
    Timeout,
};

/// 应用层错误（粗）：给用户看的语义
const AppError = error{
    ConfigInvalid,
    ResourceUnavailable,
    UpstreamFailed,
    Cancelled,
};

/// 把 5 个内部错误收敛成 4 个应用语义。switch 穷尽性由编译器守住
fn toAppError(err: StoreError) AppError {
    return switch (err) {
        error.FileNotFound, error.PermissionDenied => error.ConfigInvalid,
        error.DiskFull, error.ConnectionLost, error.Timeout => error.ResourceUnavailable,
    };
}

/// 分类处理的第二种形态：按"要不要重试"分流
const Disposition = enum { retry, give_up, abort };

fn classify(err: StoreError) Disposition {
    return switch (err) {
        error.Timeout, error.ConnectionLost => .retry, // 瞬时故障，重试有意义
        error.FileNotFound, error.PermissionDenied => .give_up, // 再试也没用
        error.DiskFull => .abort, // 资源问题，重试会 worsen
    };
}

fn fetchValue(which: u8) StoreError!u32 {
    return switch (which) {
        0 => error.FileNotFound,
        1 => error.Timeout,
        2 => error.DiskFull,
        else => 7,
    };
}

/// 完整的一层：内部错误 → 应用语义 + 处置动作
fn fetchValueAsApp(which: u8) AppError!u32 {
    // 一处switch 同时决定"给用户的话"和"该怎么处置"——映射只写一次
    const v = fetchValue(which) catch |err| return toAppError(err);
    return v;
}

// ═══ 10.6 错误 → 退出码：程序边界的最后一层 ═══
const Advice = struct { msg: []const u8, code: u8 };

fn advise(err: AppError) Advice {
    return switch (err) {
        error.ConfigInvalid => .{ .msg = "配置文件缺失或不可读", .code = 2 },
        error.ResourceUnavailable => .{ .msg = "资源不可用（磁盘/网络）", .code = 3 },
        error.Cancelled => .{ .msg = "操作被取消", .code = 4 },
        error.UpstreamFailed => .{ .msg = "上游服务失败", .code = 5 },
    };
}

/// 最后一层：把错误翻成进程退出码。这个函数是"错误 → 操作系统"的翻译器
fn runOnce(which: u8) u8 {
    const v = fetchValueAsApp(which) catch |err| {
        const a = advise(err);
        // 边界层才记日志：更下面那些层只负责传播，不刷屏
        std.log.scoped(.app).err("{s}", .{a.msg});
        return a.code;
    };
    _ = v;
    return 0; // 成功：约定 0
}

// ═══ 10.7 @errorCast：错误集降级与升级 ═══
/// 窄集合：对外承诺只会出这三种错
const PublicError = error{ Invalid, Unavailable };

/// 宽集合：内部可能出任何错
fn wideSource(kind: u8) anyerror!u8 {
    return switch (kind) {
        0 => error.Invalid,
        1 => error.Unavailable,
        else => error.SomeoneElsesError, // 不在 PublicError 里
    };
}

/// 降级姿势 A：switch 逐个认识，不认识的统一折叠成一个成员（不 panic）
fn narrowBySwitch(kind: u8) PublicError!u8 {
    const v = wideSource(kind) catch |err| switch (err) {
        error.Invalid => 1,
        error.Unavailable => 2,
        else => {
            // 关键动作：把"不认识"变成一个**有名字的**窄集合成员，
            // 而不是让 @errorCast 在运行期panic
            return error.Unavailable;
        },
    };
    return v;
}

/// 降级姿势 B：@errorCast 直传（09 章 9.10 讲过）——错误在集合内时零成本，越界 panic
fn narrowByCast(kind: u8) PublicError!u8 {
    const v = wideSource(kind) catch |err| {
        // 有已知结果类型（函数的返回类型），所以 @errorCast 能定型
        return @errorCast(err);
    };
    return v;
}

/// 升级：窄 → 宽，编译器自动 coerce，try 一下就过
fn widen(narrow: PublicError) anyerror!u8 {
    return narrow;
}

/// 错误集并集作为公开契约：把两个模块的错误集合并成一个签名
const DbError = error{ NotFound, Conflict };
const NetError = error{ Unreachable, Timeout };
const BackendError = DbError || NetError;

fn dbQuery(ok: bool) DbError!u32 {
    if (!ok) return error.NotFound;
    return 1;
}
fn netCall(ok: bool) NetError!u32 {
    if (!ok) return error.Timeout;
    return 2;
}
/// 返回类型写成并集：一次签名覆盖两个来源，调用方一个 catch 全接住
fn backend(ok_db: bool, ok_net: bool) BackendError!u32 {
    const a = try dbQuery(ok_db);
    const b = try netCall(ok_net);
    return a + b;
}

// ═══ 10.8 错误信息里带上下文：结构体载荷 vs 日志 ═══
/// 路线①：错误本身不带payload（0.17 的error 没有载荷），
/// 想带"哪个文件第几行"就用结构体把上下文攒起来，一次性写进日志
const LoadError = error{ EmptyFile, BadLine, TooManyRows };

const LoadFailure = struct {
    code: LoadError,
    path: []const u8,
    line: usize,

    /// 把上下文一次性写进日志（scoped，方便按模块过滤）
    fn report(self: LoadFailure) void {
        // ⚠️ 这个守卫是本示例里最关键的一处改动，务必保留：
        // std.log.err 会让 `zig test` 以非零码退出（test_runner 打印
        //   "N errors were logged." 然后 std.process.exit(1)）。
        // 测试里也会走这些失败路径，所以测试环境下静音，只在真实运行时记日志。
        if (builtin.is_test) return;
        const log = std.log.scoped(.loader);
        log.err("{s}:{d} 加载失败：{s}", .{ self.path, self.line, @errorName(self.code) });
    }
};

fn loadRows(text: []const u8, path: []const u8) LoadError!usize {
    if (text.len == 0) {
        const f: LoadFailure = .{ .code = error.EmptyFile, .path = path, .line = 0 };
        f.report();
        return error.EmptyFile;
    }
    var rows: usize = 0;
    var line: usize = 1;
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |row| {
        // 结尾换行会切出一个空段——那不是"一行"，别把它算成格式错误
        if (row.len == 0 and it.peek() == null) break;
        if (rows >= 3) {
            const f: LoadFailure = .{ .code = error.TooManyRows, .path = path, .line = line };
            f.report();
            return error.TooManyRows;
        }
        if (std.mem.indexOf(u8, row, ",") == null) {
            const f: LoadFailure = .{ .code = error.BadLine, .path = path, .line = line };
            f.report();
            return error.BadLine;
        }
        rows += 1;
        line += 1;
    }
    return rows;
}

/// 路线②：需要"精确定位"（第几个字符、那个字符是什么）就别用错误，
/// 改用 union(enum)自己包一个带数据的结果——错误没payload，结果可以有
const ParseResult = union(enum) {
    ok: u8,
    bad: struct { pos: u32, ch: u8 },
};

fn parseRich(s: []const u8) ParseResult {
    for (s, 0..) |c, i| {
        if (c < '0' or c > '9') return .{ .bad = .{ .pos = @intCast(i), .ch = c } };
    }
    return .{ .ok = 7 };
}

// ═══ 10.9 catch unreachable：正当与滥用 ═══
///正当用法：字面量输入，编译期就已知不可能失败
fn parseConstOK(s: []const u8) u8 {
    if (s.len == 0) return 0;
    const c = s[0];
    return if (c >= '0' and c <= '9') c - '0' else 0;
}

/// catch unreachable 的正当姿势：包一层只吃已知安全输入的函数
fn digitOfConst(text: []const u8) u8 {
    // text 来自常量表，逻辑上不可能解析失败
    return std.fmt.parseInt(u8, text, 10) catch unreachable;
}

/// 滥用：把用户输入直接喂给 catch unreachable
fn digitOfUser(text: []const u8) u8 {
    return std.fmt.parseInt(u8, text, 10) catch unreachable; // ❌ 用户能喂"abc"
}

// ═══ 10.10 ?E!T：三态与内存代价 ═══
const ParseError = error{ Empty, NotDigit };

/// 可选在外：错误在内 → 先orelse 再 catch
fn parseOuterOpt(s: ?[]const u8) ?ParseError!u8 {
    const str = s orelse return null; // 缺席
    if (str.len == 0) return error.Empty;
    if (str[0] < '0' or str[0] > '9') return error.NotDigit;
    return str[0] - '0';
}

/// 错误在外：可选在内 → 先 catch 再 orelse
fn parseOuterErr(s: ?[]const u8) ParseError!?u8 {
    const str = s orelse return null; // 缺席
    if (str.len == 0) return error.Empty;
    if (str[0] < '0' or str[0] > '9') return error.NotDigit;
    return str[0] - '0';
}

// ═══ 10.11 错误 vs panic vs 退出码的分工 ═══
/// 程序员错误（bug）用 panic：调用前就该断言，不该"处理"
fn mustPositive(x: i32) i32 {
    if (x <= 0) @panic("x 必须为正"); // 主动崩溃，带栈跟踪
    return x;
}

/// u2 只有 0..3，switch 穷尽后编译器知道3 到不了
fn classifyNibble(x: u2) []const u8 {
    return switch (x) {
        0 => "零",
        1 => "一",
        2 => "二",
        3 => unreachable, // 逻辑上到不了（但注意：这是"到不了"，不是"我保证"）
    };
}

/// 本节的错误集：供 10.1~10.3 的顺序探针与错误链路复用
const Err = error{ Nope, BadId, BadChar, TooBig };

pub fn main(init: std.process.Init) !void {
    _ = init;
    var da_state = std.heap.DebugAllocator(.{}){};
    defer {
        const st = da_state.deinit();
        std.debug.print("DebugAllocator 收尾：{s}（无泄漏）\n", .{@tagName(st)});
    }
    const gpa = da_state.allocator();

    // ═══ 10.1 errdefer：失败路径才回滚 ═══
    begin("10.1");
    std.debug.print("起始 made={d}\n", .{made});
    const t1 = try makeThing(gpa, 1);
    defer gpa.destroy(t1);
    const t2 = try makeThing(gpa, 99);
    defer gpa.destroy(t2);
    std.debug.print("两次成功 made={d}（两条 errdefer 都没跑）\n", .{made});
    if (makeThingChecked(gpa, 0)) |t| {
        gpa.destroy(t);
    } else |err| {
        std.debug.print("失败 {s} 之后 made={d}（② 销毁对象 + ① 回滚计数，都跑了）\n", .{
            @errorName(err), made,
        });
    }
    // 注入会失败的分配器：证明 errdefer 真的把内存还回去了。
    // ⚠️ std.testing.allocator **只在 zig test 下存在**（源码里是
    //   `if (builtin.is_test) ... else @compileError("not testing")`），
    //   在 main 里用会报 error: not testing。所以这里用 DebugAllocator 当底层。
    {
        var fa = std.testing.FailingAllocator.init(gpa, .{ .fail_index = 1 });
        const before = made;
        _ = buildTriple(fa.allocator(), 2) catch |err| {
            std.debug.print("注入第 2 次分配失败 → {s}：成功 {d} 次 / 归还 {d} 次 / made回到 {d}\n", .{
                @errorName(err), fa.allocations, fa.deallocations, made,
            });
            std.debug.print("  （fail_index=1 意味着第 1 块成功、第 2 块失败；deallocations=1 证明第 1 块被 errdefer 还回去了）\n", .{});
            std.debug.print("  made 守恒检查：{s}\n", .{if (made == before) "成立" else "不成立"});
        };
    }
    end("10.1");

    // ═══ 10.2 多资源回滚纪律 ═══
    begin("10.2");
    if (buildList(gpa, 5)) |l| {
        defer gpa.free(l);
        std.debug.print("buildList(5)={any}\n", .{l});
    } else |err| {
        std.debug.print("buildList 失败：{s}\n", .{@errorName(err)});
    }
    if (buildList(gpa, 16)) |l| {
        gpa.free(l);
    } else |err| {
        std.debug.print("buildList(16) 失败：{s}（16>8，errdefer 已 free）\n", .{@errorName(err)});
    }
    if (buildTriple(gpa, 8)) |p| {
        for (p) |s| gpa.free(s);
        gpa.free(p);
    } else |err| {
        std.debug.print("buildTriple(8) 失败：{s}（8>4，三条 errdefer 逆序全跑了）\n", .{@errorName(err)});
    }
    const triple = try buildTriple(gpa, 2);
    defer {
        for (triple) |s| gpa.free(s);
        gpa.free(triple);
    }
    std.debug.print("buildTriple(2) 成功：{d} 组，每组 {d} 个 u32\n", .{ triple.len, triple[0].len });
    // 部分初始化对象：成功时半成品就是成品的一部分
    if (loadRamp(gpa, "12345")) |loaded| {
        defer gpa.free(loaded.rows);
        std.debug.print("loadRamp(\"12345\") → {d} 个字节，truncated={}\n", .{ loaded.rows.len, loaded.truncated });
    } else |err| {
        std.debug.print("loadRamp 意外失败 {s}\n", .{@errorName(err)});
    }
    if (loadRamp(gpa, "12x45")) |_| {
        std.debug.print("不该到这\n", .{});
    } else |err| {
        std.debug.print("loadRamp(\"12x45\") → {s}：已装 2 个字节的半成品被 errdefer 收掉，DebugAllocator 末尾会验证无泄漏\n", .{@errorName(err)});
    }
    end("10.2");

    // ═══ 10.3 defer 与 errdefer 的执行顺序（实测） ═══
    begin("10.3");
    var t: Trace = .{};
    _ = cleanupDeferFirst(true, &t) catch unreachable;
    std.debug.print("成功路径：{s}（只有 defer 跑）\n", .{t.text()});
    t.reset();
    _ = cleanupDeferFirst(false, &t) catch {};
    std.debug.print("失败路径：{s}（defer 先注册、errdefer 后注册 → **后注册的先跑**）\n", .{t.text()});
    t.reset();
    _ = cleanupErrdeferFirst(false, &t) catch {};
    std.debug.print("把两行调换：{s}（这次 defer 后注册，于是 defer 先跑）\n", .{t.text()});
    t.reset();
    _ = cleanupNested(true, &t) catch unreachable;
    std.debug.print("嵌套成功：{s}（内层先于外层：i 然后 o）\n", .{t.text()});
    t.reset();
    _ = cleanupNested(false, &t) catch {};
    std.debug.print("嵌套失败：{s}（注册序o→e→i→I，运行序完全逆序）\n", .{t.text()});
    t.reset();
    std.debug.print("循环里 defer 的累积：loopDeferCount(5)={d}，loopDeferCount(100000)={d}（都到出口才跑）\n", .{
        loopDeferCount(5), loopDeferCount(100_000),
    });
    loopScoped(4, &t);
    std.debug.print("正确姿势：loopScoped(4) → {s}（每轮进出独立作用域，defer 立即生效）\n", .{t.text()});
    end("10.3");

    // ═══ 10.4 错误返回追踪 ═══
    begin("10.4");
    std.debug.print("构建模式 = {s}，@errorReturnTrace() != null = {}\n", .{
        @tagName(builtin.mode), @errorReturnTrace() != null,
    });
    bootstrap() catch |err| {
        std.debug.print("顶层捕获：{s}\n", .{@errorName(err)});
        if (@errorReturnTrace()) |et| {
            std.debug.print("—— 产生点到捕获点的完整路径（地址每次运行都不同）——\n", .{});
            std.debug.dumpErrorReturnTrace(et);
        } else {
            std.debug.print("（当前构建模式没有开启 return trace）\n", .{});
        }
    };
    std.debug.print("⚠️ @setRuntimeSafety(false) **关不掉** return trace：\n", .{});
    bootstrapNoSafety() catch |err| {
        std.debug.print("  同样收到 {s}，trace 长度不变（安全检查与错误追踪是两套机制）\n", .{@errorName(err)});
    };
    end("10.4");

    // ═══ 10.5 catch 的分类处理 ═══
    begin("10.5");
    for ([_]StoreError{ error.FileNotFound, error.Timeout, error.DiskFull }) |e| {
        std.debug.print("  {s:<18} → {s:<20} 处置={s}\n", .{
            @errorName(e), @errorName(toAppError(e)), @tagName(classify(e)),
        });
    }
    for ([_]u8{ 0, 1, 2, 3 }) |which| {
        // 内部错误 → 应用语义 → 处置动作 + 退出码，一条链走完
        if (fetchValueAsApp(which)) |v| {
            std.debug.print("  fetchValueAsApp({d}) → 值 {d}（后端正常）\n", .{ which, v });
        } else |err| {
            std.debug.print("  fetchValueAsApp({d}) → {s}，退出码 {d}（{s}）\n", .{
                which,
                @errorName(err),
                advise(err).code,
                advise(err).msg,
            });
        }
    }
    end("10.5");

    // ═══ 10.6 错误 → 退出码 ═══
    begin("10.6");
    for ([_]u8{ 0, 1, 2, 3 }) |which| {
        const code = runOnce(which);
        std.debug.print("  runOnce({d}) → 退出码 {d}\n", .{ which, code });
    }
    std.debug.print("  advise 穷尽性由编译器守住：漏一个成员报 switch must handle all possibilities\n", .{});
    end("10.6");

    // ═══ 10.7 @errorCast：降级与升级 ═══
    begin("10.7");
    for ([_]u8{ 0, 1, 2 }) |kind| {
        // if/else 是"就地分流"，不会像 catch 里 return 那样提前退出 main
        if (narrowBySwitch(kind)) |v| {
            std.debug.print("  narrowBySwitch({d}) → 值 {d}（不 panic）\n", .{ kind, v });
        } else |err| {
            std.debug.print("  narrowBySwitch({d}) → {s}（不认识的错误被折叠成命名成员）\n", .{ kind, @errorName(err) });
        }
    }
    for ([_]u8{ 0, 1 }) |kind| {
        if (narrowByCast(kind)) |v| {
            std.debug.print("  narrowByCast({d}) → 值 {d}（在集合内，@errorCast 零成本）\n", .{ kind, v });
        } else |err| {
            std.debug.print("  narrowByCast({d}) → {s}（在集合内，@errorCast 零成本）\n", .{ kind, @errorName(err) });
        }
    }
    if (widen(error.Invalid)) |_| {
        std.debug.print("  widen(error.Invalid) → 值（窄→宽自动 coerce，try 一下就过）\n", .{});
    } else |err| {
        std.debug.print("  widen(error.Invalid) → {s}（升级不损失错误名）\n", .{@errorName(err)});
    }
    std.debug.print("  ⚠️ narrowByCast(2) 会 panic：thread ... panic: unexpected error code, found error.SomeoneElsesError\n", .{});
    std.debug.print("     （@errorCast 的越界是 panic 不是错误，所以公开边界上 prefer narrowBySwitch）\n", .{});
    // 错误集并集作为公开契约
    std.debug.print("  DbError || NetError = {s}（成员 {d} 个，@sizeOf={d} 字节——并集不花额外空间）\n", .{
        @typeName(BackendError),
        @typeInfo(BackendError).error_set.error_names.?.len,
        @sizeOf(BackendError),
    });
    for ([_][2]bool{ .{ true, true }, .{ true, false }, .{ false, true } }) |pair| {
        if (backend(pair[0], pair[1])) |v| {
            std.debug.print("    backend(db={}, net={}) → 值 {d}\n", .{ pair[0], pair[1], v });
        } else |err| {
            std.debug.print("    backend(db={}, net={}) → {s}（一个 catch 接住两个来源）\n", .{
                pair[0], pair[1], @errorName(err),
            });
        }
    }
    end("10.7");

    // ═══ 10.8 错误带上下文 ═══
    begin("10.8");
    const csv = "a,1\nb,2\nbadline";
    _ = loadRows(csv, "data.csv") catch |err| {
        std.debug.print("loadRows 失败：{s}（上下文 path:line 已写进上面的 error(loader) 日志）\n", .{@errorName(err)});
    };
    const ok_rows = try loadRows("a,1\nb,2", "ok.csv");
    std.debug.print("loadRows 成功：{d} 行\n", .{ok_rows});
    // 路线②：需要精确位置就用 union(enum)，错误做不到
    switch (parseRich("12x")) {
        .ok => |v| std.debug.print("parseRich(\"12x\") → ok {d}\n", .{v}),
        .bad => |b| std.debug.print("parseRich(\"12x\") → bad pos={d} ch={c}（错误做不到：error 没有 payload）\n", .{ b.pos, b.ch }),
    }
    std.debug.print("代价对比：LoadFailure={d} 字节（要自己分配/传递），ParseResult={d} 字节，LoadError={d} 字节（只有名字）\n", .{
        @sizeOf(LoadFailure), @sizeOf(ParseResult), @sizeOf(LoadError),
    });
    end("10.8");

    // ═══ 10.9 catch unreachable ═══
    begin("10.9");
    std.debug.print("正当：digitOfConst(\"42\")={d}，digitOfConst(\"7\")={d}（常量表，不可能失败）\n", .{
        digitOfConst("42"), digitOfConst("7"),
    });
    std.debug.print("正当：parseConstOK(\"5\")={d}，parseConstOK(\"\")={d}（自己处理了边界）\n", .{
        parseConstOK("5"), parseConstOK(""),
    });
    std.debug.print("滥用：digitOfUser(\"42\")={d} 能过，但 digitOfUser(\"abc\") 会 panic\n", .{digitOfUser("42")});
    std.debug.print("  → 同一个函数，用户能喂的输入就是不可控输入；catch unreachable 在这里是拿 UB赌运行时\n", .{});
    end("10.9");

    // ═══ 10.10 ?E!T 三态 ═══
    begin("10.10");
    std.debug.print("大小：u8={d}  ?u8={d}  ParseError!u8={d}  ?ParseError!u8={d}  ParseError!?u8={d}\n", .{
        @sizeOf(u8),             @sizeOf(?u8),            @sizeOf(ParseError!u8),
        @sizeOf(?ParseError!u8), @sizeOf(ParseError!?u8),
    });
    std.debug.print("反射：?ParseError!u8 tag={t}，optional.child={s}\n", .{
        @typeInfo(?ParseError!u8), @typeName(@typeInfo(?ParseError!u8).optional.child),
    });
    std.debug.print("反射：ParseError!?u8 tag={t}，error_union.payload={s}\n", .{
        @typeInfo(ParseError!?u8), @typeName(@typeInfo(ParseError!?u8).error_union.payload),
    });
    const cases = [_]?[]const u8{ "7", null, "x", "" };
    for (cases) |cs| {
        const label = if (cs) |v| v else "null";
        // ?E!T：可选在外 → 先 orelse
        const a = parseOuterOpt(cs) orelse {
            std.debug.print("  in={s:<5} ?E!T  ① 缺席\n", .{label});
            continue;
        };
        // 再 catch 剥错误
        const av = a catch |e| {
            std.debug.print("  in={s:<5} ?E!T  ② 错误 {s}\n", .{ label, @errorName(e) });
            continue;
        };
        std.debug.print("  in={s:<5} ?E!T  ③ 值 {d}\n", .{ label, av });
    }
    for (cases) |cs| {
        const label = if (cs) |v| v else "null";
        // E!?T：错误在外 → 先 catch
        const a = parseOuterErr(cs) catch |e| {
            std.debug.print("  in={s:<5} E!?T  ② 错误 {s}\n", .{ label, @errorName(e) });
            continue;
        };
        const av = a orelse {
            std.debug.print("  in={s:<5} E!?T  ① 缺席\n", .{label});
            continue;
        };
        std.debug.print("  in={s:<5} E!?T  ③ 值 {d}\n", .{ label, av });
    }
    std.debug.print("  ⚠️ 两种嵌套语义完全一样（都是三态），但解包顺序相反、大小不同（6 vs 4 字节）\n", .{});
    end("10.10");

    // ═══ 10.11 错误 vs panic vs 退出码 ═══
    begin("10.11");
    std.debug.print("必须是正数：mustPositive(5)={d}，classifyNibble(2)={s}\n", .{
        mustPositive(5), classifyNibble(2),
    });
    std.debug.print("三层分工：\n", .{});
    std.debug.print("  错误E!T  —— 可预期的失败，要让调用方处理（return/try/catch）\n", .{});
    std.debug.print("  panic    —— 程序员错误，继续跑就是错的（@panic / unreachable / .?失败）\n", .{});
    std.debug.print("  退出码    —— 程序边界的最后翻译（std.process.exit(advice(e).code)）\n", .{});
    std.debug.print("  当前模式 {s} 下 catch unreachable 失败会 panic（ReleaseFast 下是 UB，没有检查）\n", .{@tagName(builtin.mode)});
    end("10.11");

    // ═══ 10.12 std.log 的分级与作用域 ═══
    begin("10.12");
    std.debug.print("log.Level 成员 {d} 个，@sizeOf={d} 字节（是 enum，ordinal 从 0 开始）\n", .{
        @typeInfo(std.log.Level).@"enum".field_names.len, @sizeOf(std.log.Level),
    });
    inline for (@typeInfo(std.log.Level).@"enum".field_names) |fname| {
        const ord: u8 = @intCast(@backingInt(@field(std.log.Level, @as([]const u8, fname[0..fname.len]))));
        const lv: std.log.Level = @fromBackingInt(@intCast(ord));
        std.debug.print("  {s:<6} ordinal={d} asText={s}\n", .{ fname[0..fname.len], ord, lv.asText() });
    }
    std.debug.print("default_level = {s}（由 builtin.mode={s} 决定：debug 模式全开，release 只到 info）\n", .{
        @tagName(std.log.default_level), @tagName(builtin.mode),
    });
    std.debug.print("下面 4 行是 defaultLog 打到 **stderr** 的四个级别（0.17 的 log 函数签名固定两个参数，格式串 + args元组）：\n", .{});
    std.log.debug("debug：排查时才看", .{});
    std.log.info("info：常规状态", .{});
    std.log.warn("warn：可疑但不致命", .{});
    std.log.err("err：出事了", .{});
    const scoped = std.log.scoped(.loader);
    std.debug.print("scoped(.loader) 会给每行加上 (loader) 前缀：\n", .{});
    scoped.warn("这是 scoped 的 warn", .{});
    scoped.err("这是 scoped 的 err", .{});
    std.debug.print("⚠️ 关键坑：std.log.err 会让 `zig test` 整体失败——\n", .{});
    std.debug.print("   test_runner 统计 err 级条数，打印 \"N errors were logged.\" 然后 exit(1)，\n", .{});
    std.debug.print("   即使 \"All N tests passed.\" 也会以非零码退出。所以 LoadFailure.report() 里有\n", .{});
    std.debug.print("   if (builtin.is_test) return; 守卫：测试走失败路径时静音，只在真实运行时记日志。\n", .{});
    end("10.12");

    std.debug.print("自检通过\n", .{});
}

test "10.1 errdefer 回滚计数与对象" {
    const a = std.testing.allocator;
    const before = made;
    const t = try makeThing(a, 5);
    defer a.destroy(t);
    try std.testing.expectEqual(@as(u32, 5), t.id);
    try std.testing.expectEqual(before + 1, made); // 成功：errdefer 没跑
    try std.testing.expectError(error.BadId, makeThingChecked(a, 0));
    try std.testing.expectEqual(before + 1, made); // 失败：计数回滚
}

test "10.2 多资源回滚与部分初始化" {
    const a = std.testing.allocator;
    const l = try buildList(a, 4);
    defer a.free(l);
    try std.testing.expectEqual(@as(u32, 6), l[3]);
    try std.testing.expectError(error.TooBig, buildList(a, 16));

    const t = try buildTriple(a, 2);
    defer {
        for (t) |s| a.free(s);
        a.free(t);
    }
    try std.testing.expectEqual(@as(usize, 2), t.len);

    // 部分初始化：成功时半成品是成品的一部分
    const loaded = try loadRamp(a, "12345");
    defer a.free(loaded.rows);
    try std.testing.expectEqual(@as(usize, 5), loaded.rows.len);
    try std.testing.expect(!loaded.truncated);
    // 失败时半成品被 errdefer 收掉——testing.allocator 会在块结束时验证无泄漏
    try std.testing.expectError(error.BadChar, loadRamp(a, "12x45"));
}

test "10.2 注入失败分配器：证明内存真的还回去了" {
    var fa = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 1 });
    try std.testing.expectError(error.OutOfMemory, buildTriple(fa.allocator(), 2));
    try std.testing.expectEqual(@as(usize, 1), fa.allocations); // 只成功一次
    try std.testing.expectEqual(@as(usize, 1), fa.deallocations); // 那一块被回滚
}

test "10.3 defer/errdefer 是纯粹的 LIFO（与直觉相反）" {
    var t: Trace = .{};
    // 成功：只有 defer 跑
    try std.testing.expectEqual(@as(u8, 1), try cleanupDeferFirst(true, &t));
    try std.testing.expectEqualStrings("D", t.text());
    // 失败：defer 先注册、errdefer 后注册 → 后者先跑
    t.reset();
    try std.testing.expectError(error.Nope, cleanupDeferFirst(false, &t));
    try std.testing.expectEqualStrings("ED", t.text());
    // 只把两行调换 → 顺序也调换（证明是注册序决定，不是 errdefer 优先）
    t.reset();
    try std.testing.expectError(error.Nope, cleanupErrdeferFirst(false, &t));
    try std.testing.expectEqualStrings("DE", t.text());
    // 嵌套：注册序 o→e→i→I，运行序完全逆序
    t.reset();
    try std.testing.expectError(error.Nope, cleanupNested(false, &t));
    try std.testing.expectEqualStrings("Iieo", t.text());
    t.reset();
    try std.testing.expectEqual(@as(u8, 1), try cleanupNested(true, &t));
    try std.testing.expectEqualStrings("io", t.text());
    // 循环里 defer 累积到出口
    try std.testing.expectEqual(@as(usize, 5), loopDeferCount(5));
    try std.testing.expectEqual(@as(usize, 1000), loopDeferCount(1000));
    // 独立作用域：每轮立即生效
    t.reset();
    loopScoped(4, &t);
    try std.testing.expectEqualStrings("eoeo", t.text());
}

test "10.4 错误链路 + return trace 的可用性" {
    try std.testing.expectError(error.ConfigMissing, bootstrap());
    try std.testing.expectError(error.ConfigMissing, bootstrapNoSafety());
    // 0.17 实测：只有 Debug 模式有 return trace
    if (builtin.mode == .debug) {
        try std.testing.expect(@errorReturnTrace() != null);
    } else {
        try std.testing.expect(@errorReturnTrace() == null);
    }
}

test "10.5 catch 的分类处理把内部错误收敛成应用语义" {
    try std.testing.expectEqual(AppError.ConfigInvalid, toAppError(error.FileNotFound));
    try std.testing.expectEqual(AppError.ConfigInvalid, toAppError(error.PermissionDenied));
    try std.testing.expectEqual(AppError.ResourceUnavailable, toAppError(error.DiskFull));
    try std.testing.expectEqual(Disposition.retry, classify(error.Timeout));
    try std.testing.expectEqual(Disposition.give_up, classify(error.FileNotFound));
    try std.testing.expectEqual(Disposition.abort, classify(error.DiskFull));
    try std.testing.expectEqual(@as(u8, 7), try fetchValueAsApp(3));
    try std.testing.expectError(error.ConfigInvalid, fetchValueAsApp(0));
    try std.testing.expectError(error.ResourceUnavailable, fetchValueAsApp(1));
}

test "10.6 错误 → 退出码" {
    try std.testing.expectEqual(@as(u8, 2), advise(error.ConfigInvalid).code);
    try std.testing.expectEqual(@as(u8, 3), advise(error.ResourceUnavailable).code);
    try std.testing.expectEqual(@as(u8, 4), advise(error.Cancelled).code);
    try std.testing.expectEqual(@as(u8, 5), advise(error.UpstreamFailed).code);
    try std.testing.expectEqualStrings("配置文件缺失或不可读", advise(error.ConfigInvalid).msg);
    // runOnce 的失败路径会调 std.log.err，那会让 zig test 整体失败（见 10.12 节），
    // 所以这里只测成功路径：0 = 一切正常
    try std.testing.expectEqual(@as(u8, 0), runOnce(3));
}

test "10.7 @errorCast 的降级与升级" {
    // switch 降级：集合内的错误映射成值，越界的折叠成命名成员（不 panic）
    try std.testing.expectEqual(@as(u8, 1), try narrowBySwitch(0)); // error.Invalid → 值 1
    try std.testing.expectEqual(@as(u8, 2), try narrowBySwitch(1)); // error.Unavailable → 值 2
    try std.testing.expectError(error.Unavailable, narrowBySwitch(2)); // 集合外 → 折叠
    // @errorCast 降级：集合内零成本，越界会 panic（所以这里只测集合内）
    try std.testing.expectError(error.Invalid, narrowByCast(0));
    try std.testing.expectError(error.Unavailable, narrowByCast(1));
    // 升级：窄 → 宽自动 coerce
    try std.testing.expectError(error.Invalid, widen(error.Invalid));
    // 并集签名：一个 catch 接住两个来源
    try std.testing.expectEqual(@as(u32, 3), try backend(true, true));
    try std.testing.expectError(error.Timeout, backend(true, false));
    try std.testing.expectError(error.NotFound, backend(false, true));
    try std.testing.expectEqual(@as(usize, 4), @typeInfo(BackendError).error_set.error_names.?.len);
}

test "10.8 上下文：结构体载荷 vs union(enum) 结果" {
    // report() 里有 builtin.is_test 守卫，所以这里不会污染 zig test 的退出码
    try std.testing.expectError(error.EmptyFile, loadRows("", "x.csv"));
    try std.testing.expectError(error.BadLine, loadRows("a,1\nbadline", "x.csv"));
    try std.testing.expectError(error.TooManyRows, loadRows("a,1\nb,2\nc,3\nd,4\n", "x.csv"));
    try std.testing.expectEqual(@as(usize, 2), try loadRows("a,1\nb,2\n", "x.csv"));

    // union(enum) 能带精确位置
    const bad = parseRich("12x");
    try std.testing.expect(bad == .bad);
    try std.testing.expectEqual(@as(u32, 2), bad.bad.pos);
    try std.testing.expectEqual(@as(u8, 'x'), bad.bad.ch);
    try std.testing.expectEqual(@as(u8, 7), parseRich("123").ok);
    // 错误本身没有 payload：LoadError 只占一个错误编号
    try std.testing.expectEqual(@as(usize, 2), @sizeOf(LoadError));
}

test "10.9 catch unreachable：正当输入通过" {
    try std.testing.expectEqual(@as(u8, 42), digitOfConst("42"));
    try std.testing.expectEqual(@as(u8, 7), digitOfConst("7"));
    try std.testing.expectEqual(@as(u8, 5), parseConstOK("5"));
    try std.testing.expectEqual(@as(u8, 0), parseConstOK(""));
    // ⚠️ 这里**故意不测** digitOfUser("abc")：它会 panic（Debug 下带栈跟踪）。
    // 正确做法是用 expectError 或者让函数返回错误，而不是 catch unreachable。
    try std.testing.expectError(error.InvalidCharacter, std.fmt.parseInt(u8, "abc", 10));
}

test "10.10 ?E!T 与 E!?T：同一三态、不同解包顺序与大小" {
    // ?E!T：orelse 剥可选 → catch 剥错误
    try std.testing.expectEqual(@as(?ParseError!u8, null), parseOuterOpt(null));
    try std.testing.expectError(error.Empty, parseOuterOpt("") orelse return error.TestUnexpectedResult);
    try std.testing.expectError(error.NotDigit, parseOuterOpt("x") orelse return error.TestUnexpectedResult);
    const seven_eu = parseOuterOpt("7") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(u8, 7), try seven_eu);
    // E!?T：try 剥错误 → orelse 剥可选
    try std.testing.expectEqual(@as(?u8, null), try parseOuterErr(null));
    try std.testing.expectError(error.NotDigit, parseOuterErr("x"));
    // 大小：可选套错误联合 = 6 字节；错误套可选 = 4 字节
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(u8));
    try std.testing.expectEqual(@as(usize, 2), @sizeOf(?u8));
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(ParseError!u8));
    try std.testing.expectEqual(@as(usize, 6), @sizeOf(?ParseError!u8));
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(ParseError!?u8));
    // 0.17 反射形状：optional.child vs error_union.payload
    try std.testing.expectEqualStrings("error{Empty,NotDigit}!u8", @typeName(@typeInfo(?ParseError!u8).optional.child));
    try std.testing.expectEqualStrings("?u8", @typeName(@typeInfo(ParseError!?u8).error_union.payload));
}

test "10.11 panic 与 unreachable 的正当输入" {
    try std.testing.expectEqual(@as(i32, 5), mustPositive(5));
    try std.testing.expectEqualStrings("二", classifyNibble(2));
    try std.testing.expectEqualStrings("零", classifyNibble(0));
    // ⚠️ 故意不测 mustPositive(0) / classifyNibble(3) 的 panic 路径
    // mustPositive(0) → panic: x 必须为正
    // classifyNibble(3) 在 u2 的值域内，**能跑**，返回 unreachable 是被断言为不可能的分支
}

test "10.12 std.log.Level 的四个级别与默认级别" {
    try std.testing.expectEqual(@as(usize, 4), @typeInfo(std.log.Level).@"enum".field_names.len);
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(std.log.Level));
    try std.testing.expectEqualStrings("error", std.log.Level.err.asText());
    try std.testing.expectEqualStrings("warning", std.log.Level.warn.asText());
    try std.testing.expectEqualStrings("info", std.log.Level.info.asText());
    try std.testing.expectEqualStrings("debug", std.log.Level.debug.asText());
    // ordinal 从 0 开始：err=0 < warn=1 < info=2 < debug=3，数字越大越啰嗦
    try std.testing.expectEqual(@as(u8, 0), @as(u8, @intCast(@backingInt(std.log.Level.err))));
    try std.testing.expectEqual(@as(u8, 3), @as(u8, @intCast(@backingInt(std.log.Level.debug))));
    // 默认级别由构建模式决定
    if (builtin.mode == .debug) {
        try std.testing.expectEqual(std.log.Level.debug, std.log.default_level);
    } else {
        try std.testing.expectEqual(std.log.Level.info, std.log.default_level);
    }
    // scoped(.loader) 存在且四个方法齐备
    const l = std.log.scoped(.loader);
    try std.testing.expect(@hasDecl(l, "err"));
    try std.testing.expect(@hasDecl(l, "warn"));
    try std.testing.expect(@hasDecl(l, "info"));
    try std.testing.expect(@hasDecl(l, "debug"));
}
