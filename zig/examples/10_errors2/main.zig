//! 10 错误处理 II：errdefer、?!T、panic、安全模式
const std = @import("std");

const Thing = struct { id: u32 };

// ═══ 10.1 errdefer：失败路径才执行的回滚
var made: usize = 0;
fn makeThing(gpa: std.mem.Allocator, id: u32) !*Thing {
    made += 1; // 副作用
    errdefer made -= 1; // 失败 → 回滚副作用
    const t = try gpa.create(Thing); // try 失败会先跑上面的 errdefer
    errdefer gpa.destroy(t); // 分配成功但后续失败 → 销毁
    t.* = .{ .id = id };
    return t;
}

// ═══ 10.2 分配-初始化模式：errdefer 管失败回滚，defer 管正常清理
fn buildList(gpa: std.mem.Allocator, n: usize) ![]u32 {
    const slice = try gpa.alloc(u32, n);
    errdefer gpa.free(slice); // 失败 → 释放
    for (slice, 0..) |*p, i| p.* = @intCast(i * 2);
    if (n > 8) return error.TooBig; // 这里失败，上面 errdefer 兜住
    return slice;
}

// ═══ 10.3 ?E!T：可能缺席，也可能出错（先剥 null 再剥 error）
const OptError = error{ Empty, NotDigit };
fn parseOpt(s: ?[]const u8) ?OptError!u8 {
    const str = s orelse return null; // 缺席
    if (str.len == 0) return error.Empty;
    if (str[0] < '0' or str[0] > '9') return error.NotDigit;
    return str[0] - '0';
}

// ═══ 10.5 panic 与 unreachable：程序员的错，不是可恢复错误
fn mustPositive(x: i32) i32 {
    if (x <= 0) @panic("x 必须为正"); // 主动崩溃，带栈跟踪
    return x;
}

fn classify(x: u2) []const u8 {
    return switch (x) { // u2 只有 0..3，穷尽后 else 都不用写
        0 => "零",
        1 => "一",
        2 => "二",
        3 => unreachable, // 逻辑上到不了（编译器帮你信）
    };
}

pub fn main() !void {
    var da_state = std.heap.DebugAllocator(.{}){};
    defer {
        const st = da_state.deinit();
        std.debug.print("DebugAllocator 收尾：{s}（无泄漏）\n", .{@tagName(st)});
    }
    const gpa = da_state.allocator();

    // ═══ 10.1 演示：成功与失败两条路
    const t1 = try makeThing(gpa, 1);
    defer gpa.destroy(t1);
    const t2 = try makeThing(gpa, 99); // made=2（此路径成功）
    defer gpa.destroy(t2);
    std.debug.print("made={d}（两次成功）\n", .{made});

    // ═══ 10.2 演示：失败路径内存被 errdefer 回滚，DebugAllocator 验证无泄漏
    if (buildList(gpa, 5)) |l| {
        defer gpa.free(l);
        std.debug.print("buildList(5)={any}\n", .{l});
    } else |err| {
        std.debug.print("buildList(16) 失败：{s}（内存已回滚）\n", .{@errorName(err)});
    }

    // ═══ 10.3 ?E!T 解包顺序：orelse 先，catch 后
    const cases = [_]?[]const u8{ "7", null, "x", "" };
    for (cases) |cs| {
        const parsed = parseOpt(cs) orelse {
            std.debug.print("  缺席（null）\n", .{});
            continue;
        };
        const digit = parsed catch |e| {
            std.debug.print("  错误 {s}\n", .{@errorName(e)});
            continue;
        };
        std.debug.print("  数字 {d}\n", .{digit});
    }

    // ═══ 10.4 错误返回跟踪：Debug 模式下错误冒泡到顶会带完整来路（正文贴真实输出）
    std.debug.print("made 计数={d}\n", .{made});

    // ═══ 10.5 panic/unreachable 正常路径
    std.debug.print("mustPositive(5)={d}，classify(2)={s}\n", .{ mustPositive(5), classify(2) });

    // ═══ 10.6 安全模式：Debug/ReleaseSafe 检查溢出/越界/坏指针（正文表格）
    // 若在函数内确信不会出问题，可关检查换性能：
    const fast = struct {
        fn addWrap(a: u8, b: u8) u8 {
            @setRuntimeSafety(false); // 本函数关闭运行期检查
            return a +% b; // 环绕加本就不查；关掉后普通 + 也不查
        }
    };
    std.debug.print("addWrap(200,100)={d}\n", .{fast.addWrap(200, 100)});

    std.debug.print("自检通过\n", .{});
}

test "errdefer 与组合错误" {
    const a = std.testing.allocator;
    const l = try buildList(a, 4);
    defer a.free(l);
    try std.testing.expectEqual(@as(u32, 6), l[3]);
    try std.testing.expectError(error.TooBig, buildList(a, 16));

    // 分层解包：orelse 先剥 null 得到 E!u8，再 try/expectError 剥错误
    const seven = parseOpt("7") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(u8, 7), try seven);
    try std.testing.expectEqual(@as(?OptError!u8, null), parseOpt(null));
    try std.testing.expectError(error.NotDigit, parseOpt("x") orelse return error.TestUnexpectedResult);
}
