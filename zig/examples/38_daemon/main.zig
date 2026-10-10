//! 38 · 实战：守护进程与信号 —— fork/setsid/execve/waitpid/守护进程化/zcron
//! 取材：Systems Programming with Zig 第 7 章（信号与守护进程），按 0.17.0 实测重写。
//! 0.17 关键变化：std.posix.sigaction 返回 void（失败 unreachable）；
//! std.Io.sleep(io, Duration, .awake) 取代 std.time.sleep；
//! waitpid 用 std.c.waitpid（std.posix 没有安全的 waitpid 包装）。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 38.1 信号处理基础：sigaction + 原子标志位
// ══════════════════════════════════════════════════════════════════

/// 全局原子标志：信号处理器唯一允许写的状态。
/// 必须是全局变量——信号处理器不接收用户指针（SA_SIGINFO 除外），
/// 只能写模块级变量。这是本章唯一允许的全局状态。
var g_sigint_received: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

/// SIGINT 处理器：async-signal-safe 的唯一正确写法。
/// 规则：只写 lock-free 原子变量，不 malloc、不 print、不拿锁。
fn handleSigint(sig: std.c.SIG) callconv(.c) void {
    _ = sig;
    // .monotonic 足够：处理器里不需要同步顺序，只需要原子性
    g_sigint_received.store(true, .monotonic);
}

// ══════════════════════════════════════════════════════════════════
// 38.5 守护进程化（教学用，不在 main 中调用）
// ══════════════════════════════════════════════════════════════════

/// 完整守护进程化五步法。编译期存在、运行期不调用——
/// 真调用了进程就从终端消失，演示就没法继续了。
fn daemonizeSteps() !void {
    // 第 1 步：第一次 fork，脱离 shell 的 job control
    const pid1 = std.c.fork();
    if (pid1 < 0) return error.ForkFailed;
    if (pid1 > 0) std.c._exit(0); // 父进程立即退出，子进程被 init 收养

    // 第 2 步：setsid()，成为新会话首进程，脱离控制终端
    if (std.c.setsid() < 0) return error.SetsidFailed;

    // 第 3 步：第二次 fork，确保不是会话首进程，无法再获得控制终端
    const pid2 = std.c.fork();
    if (pid2 < 0) return error.ForkFailed;
    if (pid2 > 0) std.c._exit(0);

    // 第 4 步：chdir("/")，避免占用可卸载的文件系统
    if (std.c.chdir("/") != 0) return error.ChdirFailed;

    // 第 5 步：把 /dev/null  dup2 到 0/1/2，切断终端 I/O
    const devnull = std.c.open("/dev/null", .{ .ACCMODE = .RDWR });
    if (devnull < 0) return error.OpenDevNullFailed;
    _ = std.c.dup2(devnull, 0);
    _ = std.c.dup2(devnull, 1);
    _ = std.c.dup2(devnull, 2);
    if (devnull > 2) _ = std.c.close(devnull);
}

// ══════════════════════════════════════════════════════════════════
// 38.7 zcron：迷你调度器的纯逻辑
// ══════════════════════════════════════════════════════════════════

const Job = struct {
    name: []const u8,
    interval_ms: i64,
    last_run_ms: i64,
};

/// 纯函数：判断某 job 是否到期。抽出来是为了可测试。
fn isDue(now_ms: i64, last_run_ms: i64, interval_ms: i64) bool {
    return now_ms - last_run_ms >= interval_ms;
}

// ══════════════════════════════════════════════════════════════════
// main
// ══════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var out_buf: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &out_buf);
    const w = &stdout_impl.interface;
    defer w.flush() catch {};

    // ── 38.1 信号处理基础 ─────────────────────────────────────────
    begin("38.1 信号处理基础");
    try w.print("安装 SIGINT handler...\n", .{});
    const act: std.posix.Sigaction = .{
        .handler = .{ .handler = handleSigint },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    // 0.17：sigaction 返回 void，失败直接 unreachable（EINVAL = 程序员错误）
    std.posix.sigaction(std.c.SIG.INT, &act, null);
    try w.print("SIGINT handler 安装成功\n", .{});
    try w.print("handler 类型: {s}\n", .{@typeName(@TypeOf(handleSigint))});
    try w.print("规则: handler 里只写原子变量，不 malloc / 不 print / 不拿锁\n", .{});
    // 不真的发 SIGINT（不确定时序）；演示优雅退出路径靠手动置位
    g_sigint_received.store(true, .release);
    var spins: usize = 0;
    while (!g_sigint_received.load(.acquire)) {
        try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(50), .awake);
        spins += 1;
        if (spins > 100) break;
    }
    try w.print("SIGINT 已捕获，优雅退出\n", .{});
    end("38.1");

    // ── 38.2 fork 与 waitpid ──────────────────────────────────────
    begin("38.2 fork 与 waitpid");
    const pid = std.c.fork();
    if (pid == 0) {
        // 子进程分支：打印自己的 PID，以 42 退出
        try w.print("  子进程: 我的 PID = {d}，即将 _exit(42)\n", .{std.c.getpid()});
        w.flush() catch {};
        std.c._exit(42);
    }
    // 父进程分支
    try w.print("父进程: 我的 PID = {d}，子进程 PID = {d}\n", .{ std.c.getpid(), pid });
    var status: c_int = 0;
    _ = std.c.waitpid(pid, &status, 0);
    const ustatus: u32 = @bitCast(status);
    try w.print("waitpid 返回: W.IFEXITED = {}，exit status = {d}\n", .{
        std.posix.W.IFEXITED(ustatus),
        std.posix.W.EXITSTATUS(ustatus),
    });
    end("38.2");

    // ── 38.3 僵尸进程与 SIGCHLD ───────────────────────────────────
    begin("38.3 僵尸进程与 SIGCHLD");
    const zpid = std.c.fork();
    if (zpid == 0) {
        std.c._exit(0); // 子进程立即退出
    }
    try w.print("子进程 PID = {d} 已退出但尚未 wait\n", .{zpid});
    try w.print("→ /proc 里会是 Z 状态（Linux）；macOS 用 `ps -o stat` 也能看到\n", .{});
    // 给子进程一点时间变成僵尸
    try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(200), .awake);
    // WNOHANG 轮询收割
    var reap_status: c_int = 0;
    var reap_count: usize = 0;
    while (true) {
        const r = std.c.waitpid(zpid, &reap_status, std.posix.W.NOHANG);
        if (r == zpid) {
            reap_count += 1;
            break;
        }
        try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(10), .awake);
    }
    try w.print("已收割（WNOHANG 轮询 {d} 次）\n", .{reap_count});
    end("38.3");

    // ── 38.4 fork + execve 执行命令 ──────────────────────────────
    begin("38.4 fork + execve 执行命令");
    const epath: [*:0]const u8 = "/bin/echo";
    const argv = [_:null]?[*:0]const u8{ epath, "hello", "from", "execve", null };
    const envp = [_:null]?[*:0]const u8{ "PATH=/bin:/usr/bin", null };
    const epid = std.c.fork();
    if (epid == 0) {
        // 子进程：execve 替换镜像。成功则不返回，失败返回 -1
        _ = std.c.execve(epath, &argv, &envp);
        std.c._exit(127); // execve 失败才走到这里
    }
    var exec_status: c_int = 0;
    _ = std.c.waitpid(epid, &exec_status, 0);
    const uexec: u32 = @bitCast(exec_status);
    try w.print("execve 完成, status={d}\n", .{std.posix.W.EXITSTATUS(uexec)});
    end("38.4");

    // ── 38.5 守护进程化（讲解，不实际执行） ──────────────────────
    begin("38.5 守护进程化 (daemonize)");
    try w.print("完整 recipe 见 daemonizeSteps()（编译期存在，运行期不调用——\n", .{});
    try w.print("真调用了进程就脱离终端，演示没法继续）。五个步骤：\n", .{});
    try w.print("  1. fork → 父进程 _exit(0)，子进程被 init 收养\n", .{});
    try w.print("  2. setsid() → 新会话首进程，脱离控制终端\n", .{});
    try w.print("  3. 再 fork → 不是会话首进程，无法再获得终端\n", .{});
    try w.print("  4. chdir(\"/\") → 不占用可卸载的文件系统\n", .{});
    try w.print("  5. dup2 /dev/null 到 0/1/2 → 切断终端 I/O\n", .{});
    try w.print("为什么 double-fork：setsid 后仍是会话首进程，再 fork 一次确保不是，\n", .{});
    try w.print("从而任何 open() 终端设备的行为都不会把它绑回终端。\n", .{});
    end("38.5");

    // ── 38.6 信号安全规则总结 ─────────────────────────────────────
    begin("38.6 信号安全规则总结");
    try w.print("handler 里允许做的事（async-signal-safe）：\n", .{});
    try w.print("  ✓ lock-free 原子变量读写（std.atomic.Value）\n", .{});
    try w.print("  ✓ 写一段预分配的静态缓冲（不分配内存）\n", .{});
    try w.print("  ✓ 调用 async-signal-safe 的 C 函数（write、_exit 等）\n", .{});
    try w.print("handler 里禁止做的事：\n", .{});
    try w.print("  ✗ malloc / free（堆锁可能已被持有）\n", .{});
    try w.print("  ✗ print / format（内部可能 malloc）\n", .{});
    try w.print("  ✗ 拿 mutex / rwlock（非递归，可能死锁）\n", .{});
    try w.print("  ✗ 调非 async-signal-safe 的库函数\n", .{});
    try w.print("唯一正确模式（本章 handler 的写法）：\n", .{});
    try w.print("  fn handler(sig: c.SIG) callconv(.c) void {{\n", .{});
    try w.print("      flag.store(true, .monotonic);  // 只写原子变量\n", .{});
    try w.print("  }}\n", .{});
    end("38.6");

    // ── 38.7 zcron 迷你调度器 ─────────────────────────────────────
    begin("38.7 zcron 迷你调度器");
    var jobs: [3]Job = .{
        .{ .name = "backup", .interval_ms = 60, .last_run_ms = 0 },
        .{ .name = "cleanup", .interval_ms = 90, .last_run_ms = 0 },
        .{ .name = "heartbeat", .interval_ms = 30, .last_run_ms = 0 },
    };
    const tick_ms: i64 = 30;
    var now_ms: i64 = 0;
    var tick: usize = 0;
    while (tick < 5) : (tick += 1) {
        now_ms += tick_ms;
        try w.print("tick {d} (t={d}ms):\n", .{ tick + 1, now_ms });
        for (&jobs) |*job| {
            if (isDue(now_ms, job.last_run_ms, job.interval_ms)) {
                try w.print("  运行 job {s}\n", .{job.name});
                job.last_run_ms = now_ms;
            }
        }
        try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(30), .awake);
    }
    try w.print("5 tick 完成，调度器退出\n", .{});
    end("38.7");

    // ── 38.8 坑位清单 ────────────────────────────────────────────
    begin("38.8 坑位清单");
    try w.print("1. std.posix.waitpid 在 0.17 不存在；std.c.waitpid 才是安全选择\n", .{});
    try w.print("   （errno 路径会把 ECHILD 当 unreachable，收割未知子进程会崩）\n", .{});
    try w.print("2. handler 必须是 callconv(.c) fn，不能有 error union\n", .{});
    try w.print("3. std.c.fork 返回 pid_t (c_int)，用 == 0 判断子进程分支\n", .{});
    try w.print("4. 原子序：handler 里 .monotonic 足够；主循环用 .acquire\n", .{});
    try w.print("5. std.Io.sleep 签名: sleep(io, Duration, .awake)\n", .{});
    try w.print("6. sigaction 在 0.17 返回 void——失败即 unreachable，传参前自查合法性\n", .{});
    end("38.8");

    try w.print("全部章节完成。\n", .{});
}

// ══════════════════════════════════════════════════════════════════
// 测试
// ══════════════════════════════════════════════════════════════════

test "W exit status 解码宏" {
    // 构造合成 status：exit code 42 → status = 42 << 8
    const status: u32 = 42 << 8;
    try std.testing.expect(std.posix.W.IFEXITED(status));
    try std.testing.expectEqual(@as(u8, 42), std.posix.W.EXITSTATUS(status));

    // exit code 0
    const zero: u32 = 0;
    try std.testing.expect(std.posix.W.IFEXITED(zero));
    try std.testing.expectEqual(@as(u8, 0), std.posix.W.EXITSTATUS(zero));

    // exit code 255（u8 上限）
    const max: u32 = 255 << 8;
    try std.testing.expect(std.posix.W.IFEXITED(max));
    try std.testing.expectEqual(@as(u8, 255), std.posix.W.EXITSTATUS(max));
}

test "原子标志位 store/load" {
    var flag = std.atomic.Value(bool).init(false);
    try std.testing.expect(!flag.load(.monotonic));
    flag.store(true, .monotonic);
    try std.testing.expect(flag.load(.monotonic));
    flag.store(false, .release);
    try std.testing.expect(!flag.load(.acquire));
}

test "isDue 调度逻辑" {
    // 刚跑过，未到期
    try std.testing.expect(!isDue(50, 30, 60));
    // 恰好到达间隔
    try std.testing.expect(isDue(90, 30, 60));
    // 超过间隔
    try std.testing.expect(isDue(100, 0, 30));
    // interval 为 0 永远到期
    try std.testing.expect(isDue(1, 1, 0));
    // 起点 0 第一次必到期
    try std.testing.expect(isDue(30, 0, 30));
}

test "null 结尾 argv 构造" {
    const argv = [_:null]?[*:0]const u8{ "/bin/echo", "hello", null };
    try std.testing.expectEqual(@as(usize, 3), argv.len);
    try std.testing.expect(argv[0] != null);
    try std.testing.expect(argv[1] != null);
    try std.testing.expect(argv[2] == null);
    try std.testing.expectEqualStrings("/bin/echo", std.mem.span(argv[0].?));
    try std.testing.expectEqualStrings("hello", std.mem.span(argv[1].?));
}

test "daemonizeSteps 函数引用（防止被优化掉）" {
    // 只取函数指针，不调用——验证函数签名可编译
    const fn_ptr: *const fn () anyerror!void = &daemonizeSteps;
    try std.testing.expect(@intFromPtr(fn_ptr) != 0);
}
