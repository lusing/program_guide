//! 42 · 实战：JSON 系统监控服务 —— /proc 解析/std.json/监控循环/HTTP 接口
//! 取材：Systems Programming with Zig ch6（JSON web service / 内存监控），升级到 0.17。
//!
//! 本章把 ch6 的"内存监控 + JSON HTTP 服务"在 macOS 上完整落地：
//!   42.1 /proc/meminfo 解析（纯字符串函数，跨平台可测）+ macOS sysctl 实测
//!   42.2 std.json 序列化：MemStats → JSON 字符串
//!   42.3 std.json 反序列化：JSON 字符串 → MemStats（含 ignore_unknown_fields）
//!   42.4 内存监控循环：3 次采样 + 睡眠 100ms
//!   42.5 迷你 HTTP 内存服务：std.http.Server + std.http.Client 进程内往返
//!   42.6 坑位清单
//!
//! 跨平台策略：parseMeminfo() 是纯函数（Linux /proc/meminfo 格式），测试用硬编码样本；
//! 活体采样走 macOS 的 sysctlbyname("hw.memsize") + getrusage（Linux 上读 /proc 文件即可）。

const std = @import("std");

// ══════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════

/// 内存统计快照。字段名用 snake_case —— std.json 默认按字段名序列化。
const MemStats = struct {
    total_mb: u64,
    available_mb: u64,
    used_percent: f64,
    timestamp_ms: i64,
};

/// /proc/meminfo 解析结果（原始字节 → MB 之前的中间态）。
const RawMeminfo = struct {
    total_kb: u64 = 0,
    available_kb: u64 = 0,
};

// ══════════════════════════════════════════════════════════════════
// 42.1 /proc/meminfo 解析
// ══════════════════════════════════════════════════════════════════

/// 解析 /proc/meminfo 格式的文本（Linux 理论 + 跨平台测试）。
///
/// 格式：`Key: value kB` 每行一条，value 是十进制 kB 数。
/// 用 tokenizeScalar + tokenizeAny 逐行切，找不到的键保持默认值 0。
/// 这是**纯函数**——不碰文件系统，测试用硬编码样本驱动。
fn parseMeminfo(content: []const u8) RawMeminfo {
    var result = RawMeminfo{};
    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    while (lines.next()) |line| {
        // 行格式："MemTotal:       16384000 kB"
        // tokenizeAny 同时处理 ':' 和空白，切出 ["MemTotal", "16384000", "kB"]
        var toks = std.mem.tokenizeAny(u8, line, ": \t");
        const key = toks.next() orelse continue;
        const val_str = toks.next() orelse continue;
        const val = std.fmt.parseInt(u64, val_str, 10) catch continue;
        if (std.mem.eql(u8, key, "MemTotal")) {
            result.total_kb = val;
        } else if (std.mem.eql(u8, key, "MemAvailable")) {
            result.available_kb = val;
        }
        // 其它键（MemFree / Buffers / Cached…）本章不用，跳过
    }
    return result;
}

/// 从 RawMeminfo 计算 used_percent（纯函数，可测）。
/// used = total - available；percent = used / total * 100。
fn calcUsedPercent(raw: RawMeminfo) f64 {
    if (raw.total_kb == 0) return 0.0;
    const total = raw.total_kb;
    const avail = raw.available_kb;
    const used = total - avail;
    return @as(f64, @floatFromInt(used)) / @as(f64, @floatFromInt(total)) * 100.0;
}

/// 把 kB 转成 MB（整除，丢掉余数 —— 监控场景够用了）。
fn kbToMb(kb: u64) u64 {
    return kb / 1024;
}

/// macOS 活体采样：sysctlbyname("hw.memsize") 拿总内存（字节）。
/// ⚠️ std.posix 没有封装 sysctlbyname（0.17 实测），但 std.c 里有 extern 声明。
/// 返回字节数；失败时返回 null（调用方兜底）。
fn totalMemBytes() ?u64 {
    var size: u64 = 0;
    var len: usize = @sizeOf(u64);
    const rc = std.c.sysctlbyname("hw.memsize", &size, &len, null, 0);
    if (rc != 0) return null;
    return size;
}

/// 本进程峰值 RSS（resident set size），macOS 单位是**字节**。
/// Linux 的 /proc/self/status 里 VmHWM 单位是 kB —— 跨平台注意单位差。
fn selfPeakRssBytes() ?u64 {
    // RUSAGE_SELF = 0（POSIX 标准），0.17 的 std.posix 没有 RUSAGE 枚举
    const ru = std.posix.getrusage(0);
    const maxrss: u64 = @intCast(ru.maxrss);
    return maxrss;
}

/// 用硬编码样本构造一个确定性的 MemStats（用于 JSON 演示和 HTTP 服务）。
/// 真实监控循环里换成活体采样。
fn sampleStats() MemStats {
    // 模拟 /proc/meminfo 的采样结果（16 GB 机器，用了约 62.5%）
    const raw = RawMeminfo{
        .total_kb = 16 * 1024 * 1024, // 16 GB = 16777216 kB
        .available_kb = 6 * 1024 * 1024, // 6 GB 可用
    };
    return .{
        .total_mb = kbToMb(raw.total_kb),
        .available_mb = kbToMb(raw.available_kb),
        .used_percent = calcUsedPercent(raw),
        .timestamp_ms = 1_700_000_000_000, // 固定时间戳 → 输出可复现
    };
}

// ══════════════════════════════════════════════════════════════════
// 42.2 JSON 序列化
// ══════════════════════════════════════════════════════════════════

/// MemStats → JSON 字符串（调用方 owns 返回的切片，负责 free）。
/// ⚠️ 0.17 的签名是 `Stringify.value(value, options, writer)` —— **writer 在最后**。
/// 写错顺序的编译错："expected type 'json.Stringify.Options', found pointer"。
/// ⚠️ 用 `toOwnedSlice()` 把内部缓冲的所有权转移出来 —— `written()` 返回的是
/// 指向内部缓冲的切片，调用方不能 free（那是 Allocating 的所有权）。
fn statsToJson(a: std.mem.Allocator, stats: MemStats) ![]u8 {
    var jw = std.Io.Writer.Allocating.init(a);
    errdefer jw.deinit();
    try std.json.Stringify.value(stats, .{}, &jw.writer);
    return jw.toOwnedSlice();
}

// ══════════════════════════════════════════════════════════════════
// 42.3 JSON 反序列化
// ══════════════════════════════════════════════════════════════════

/// JSON 字符串 → MemStats。
/// ⚠️ `parseFromSlice` 返回 `Parsed(T)`，内部持有 arena —— **必须 `defer parsed.deinit()`**。
/// 否则泄漏检测（测试里的 SafeAllocator）会立刻抓到。
fn jsonToStats(a: std.mem.Allocator, json_str: []const u8) !MemStats {
    var parsed = try std.json.parseFromSlice(MemStats, a, json_str, .{});
    defer parsed.deinit();
    return parsed.value;
}

/// 带 `.ignore_unknown_fields = true` 的版本。
/// 服务端演进时老客户端收到新字段、或新客户端收到老字段 —— 不认识的键直接跳过。
fn jsonToStatsLenient(a: std.mem.Allocator, json_str: []const u8) !MemStats {
    var parsed = try std.json.parseFromSlice(MemStats, a, json_str, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();
    return parsed.value;
}

// ══════════════════════════════════════════════════════════════════
// 42.5 HTTP 服务（std.http.Server + std.http.Client 进程内往返）
// ══════════════════════════════════════════════════════════════════

/// 服务端上下文：io + 一份要服务的 JSON + 原子端口发布。
const HttpSrvCtx = struct {
    io: std.Io = undefined,
    body: []const u8 = "",
    /// 服务端实际绑定的端口。用原子发布 —— 端口是"扫出来的"，客户端必须等它确定。
    port: std.atomic.Value(u16) = std.atomic.Value(u16).init(0),
    /// 已服务请求数（quota=1 后退出）。
    served: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
};

/// 服务端线程主体：listen → accept 1 条 → std.http.Server 处理 → 退出。
fn httpServe(ctx: *HttpSrvCtx) void {
    const io = ctx.io;
    // 从高位端口开始扫，避开 ephemeral 区间（macOS 默认 49152–65535）
    var port: u16 = 48200;
    var server: std.Io.net.Server = undefined;
    while (port < 48220) : (port += 1) {
        const addr = std.Io.net.IpAddress.parseIp4("127.0.0.1", port) catch continue;
        if (addr.listen(io, .{ .reuse_address = true })) |s| {
            server = s;
            break;
        } else |_| {}
    }
    if (port >= 48220) {
        std.debug.print("  [server] 端口扫描失败\n", .{});
        return;
    }
    defer server.deinit(io);
    ctx.port.store(port, .release);

    // accept 恰好 1 条连接
    const stream = server.accept(io) catch return;
    defer stream.close(io);

    // std.http.Server 需要 std.Io.Reader 和 std.Io.Writer（裸接口，不是 net.Stream 包装）
    var rbuf: [4096]u8 = undefined;
    var wbuf: [4096]u8 = undefined;
    var stream_reader = stream.reader(io, &rbuf);
    var stream_writer = stream.writer(io, &wbuf);

    var http_server = std.http.Server.init(&stream_reader.interface, &stream_writer.interface);
    var request = http_server.receiveHead() catch return;

    // 只处理 GET /stats，其它一律 404
    if (request.head.method == .GET and std.mem.eql(u8, request.head.target, "/stats")) {
        request.respond(ctx.body, .{
            .status = .ok,
            .extra_headers = &.{.{ .name = "content-type", .value = "application/json" }},
            .keep_alive = false,
        }) catch return;
    } else {
        request.respond("{\"error\":\"not found\"}", .{
            .status = .not_found,
            .extra_headers = &.{.{ .name = "content-type", .value = "application/json" }},
            .keep_alive = false,
        }) catch return;
    }
    ctx.served.store(1, .release);
}

// ══════════════════════════════════════════════════════════════════
// 节标记
// ══════════════════════════════════════════════════════════════════

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// main
// ══════════════════════════════════════════════════════════════════

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var out_buf: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &out_buf);
    const w = &stdout_impl.interface;
    defer w.flush() catch {};

    // ── 42.1 /proc/meminfo 解析 ──
    begin("42.1 /proc/meminfo 解析（Linux 理论 + macOS 替代）");
    {
        // Linux 上的 /proc/meminfo 长这样（节选）：
        const sample =
            "MemTotal:       16384000 kB\n" ++
            "MemFree:         2048000 kB\n" ++
            "MemAvailable:    6144000 kB\n" ++
            "Buffers:          512000 kB\n" ++
            "Cached:          4096000 kB\n";
        const raw = parseMeminfo(sample);
        try w.print("  样本 MemTotal     = {d} kB → {d} MB\n", .{ raw.total_kb, kbToMb(raw.total_kb) });
        try w.print("  样本 MemAvailable = {d} kB → {d} MB\n", .{ raw.available_kb, kbToMb(raw.available_kb) });
        try w.print("  样本 used_percent = {d:.1}%\n", .{calcUsedPercent(raw)});

        // macOS 没有 /proc —— 用 sysctlbyname 拿总内存
        if (totalMemBytes()) |bytes| {
            try w.print("  本机总内存（sysctl hw.memsize）= {d} MB\n", .{bytes / (1024 * 1024)});
        } else {
            try w.print("  sysctl hw.memsize 失败\n", .{});
        }
        if (selfPeakRssBytes()) |bytes| {
            try w.print("  本进程峰值 RSS（getrusage）= {d} KB\n", .{bytes / 1024});
        }

        try w.print("\n  跨平台策略：Linux 读 /proc/meminfo，macOS 用 sysctl，Windows 用 GlobalMemoryStatusEx。\n", .{});
        try w.print("  parseMeminfo() 是纯函数 —— 不碰文件系统，测试用硬编码样本驱动。\n", .{});
    }
    end("42.1");

    // ── 42.2 JSON 序列化 ──
    begin("42.2 JSON 序列化：std.json.Stringify.value");
    {
        const stats = sampleStats();
        const json_str = try statsToJson(gpa, stats);
        defer gpa.free(json_str);
        try w.print("  MemStats → JSON：{s}\n", .{json_str});
        try w.print("  ⚠️ 0.17 签名：Stringify.value(value, options, writer) —— writer 在**最后**\n", .{});
    }
    end("42.2");

    // ── 42.3 JSON 反序列化 ──
    begin("42.3 JSON 反序列化：parseFromSlice + ignore_unknown_fields");
    {
        const stats = sampleStats();
        const json_str = try statsToJson(gpa, stats);
        defer gpa.free(json_str);

        // 往返：struct → string → struct
        const restored = try jsonToStats(gpa, json_str);
        try w.print("  往返 total_mb       = {d}（原 {d}）\n", .{ restored.total_mb, stats.total_mb });
        try w.print("  往返 available_mb   = {d}（原 {d}）\n", .{ restored.available_mb, stats.available_mb });
        try w.print("  往返 used_percent   = {d:.1}（原 {d:.1}）\n", .{ restored.used_percent, stats.used_percent });
        try w.print("  往返 timestamp_ms   = {d}（原 {d}）\n", .{ restored.timestamp_ms, stats.timestamp_ms });

        // ignore_unknown_fields 演示
        const with_extra = "{\"total_mb\":8192,\"available_mb\":4096,\"used_percent\":50.0,\"timestamp_ms\":1700000000000,\"hostname\":\"web-01\",\"extra_field\":42}";
        if (jsonToStats(gpa, with_extra)) |_| {
            try w.print("  ?? 不该成功\n", .{});
        } else |e| {
            try w.print("  默认选项 + 未知字段 → error.{s}\n", .{@errorName(e)});
        }
        const lenient = try jsonToStatsLenient(gpa, with_extra);
        try w.print("  .ignore_unknown_fields=true → total_mb={d}（多余字段被跳过）\n", .{lenient.total_mb});
        try w.print("  ⚠️ parseFromSlice 返回 Parsed(T)，必须 defer parsed.deinit()\n", .{});
    }
    end("42.3");

    // ── 42.4 内存监控循环 ──
    begin("42.4 内存监控循环：3 次采样");
    {
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            const stats = sampleStats();
            try w.print("  [{d}] total={d} MB  available={d} MB  used={d:.1}%\n", .{
                i + 1,
                stats.total_mb,
                stats.available_mb,
                stats.used_percent,
            });
            if (i < 2) {
                // std.Io.sleep(io, duration, clock) —— .awake = 单调时钟，不受系统时间跳变影响
                try std.Io.sleep(io, .fromMilliseconds(100), .awake);
            }
        }
        try w.print("  采样 3 次完成（每次间隔 100ms）\n", .{});
    }
    end("42.4");

    // ── 42.5 迷你 HTTP 内存服务 ──
    begin("42.5 迷你 HTTP 内存服务：std.http.Server + Client 进程内往返");
    {
        const stats = sampleStats();
        const json_str = try statsToJson(gpa, stats);
        defer gpa.free(json_str);

        // 起服务端线程（恰好服务 1 条请求）
        var ctx = HttpSrvCtx{ .io = io, .body = json_str };
        const th = try std.Thread.spawn(.{}, httpServe, .{&ctx});
        // 等端口确定
        while (ctx.port.load(.acquire) == 0) std.Thread.yield() catch {};

        // std.http.Client 是结构体（不是指针），直接字面量初始化
        var client: std.http.Client = .{ .allocator = gpa, .io = io };
        defer client.deinit();

        // fetch 拿响应体
        var jw = std.Io.Writer.Allocating.init(gpa);
        defer jw.deinit();
        const uri_str = try std.fmt.allocPrint(gpa, "http://127.0.0.1:{d}/stats", .{ctx.port.load(.acquire)});
        defer gpa.free(uri_str);

        const result = try client.fetch(.{
            .location = .{ .url = uri_str },
            .method = .GET,
            .response_writer = &jw.writer,
        });
        try w.print("  GET /stats → {d} {s}\n", .{ @backingInt(result.status), result.status.phrase().? });
        try w.print("  响应体：{s}\n", .{jw.written()});
        try w.print("  服务端已服务 {d} 条请求\n", .{ctx.served.load(.acquire)});
        th.join();
        try w.print("  ✓ 进程内 HTTP 往返完成\n", .{});
    }
    end("42.5");

    // ── 42.6 坑位清单 ──
    begin("42.6 坑位清单");
    {
        try w.print("  ① macOS 没有 /proc —— 跨平台要分支（Linux 读文件 / macOS sysctl / Windows GlobalMemoryStatusEx）\n", .{});
        try w.print("  ② std.json.parseFromSlice 返回 Parsed(T) 拥有内存，必须 defer parsed.deinit()\n", .{});
        try w.print("  ③ .ignore_unknown_fields = true，否则未知字段直接报错\n", .{});
        try w.print("  ④ JSON 序列化 0.17 用 std.json.Stringify.value(x, .{{}}, writer)，不是旧的 std.json.stringify\n", .{});
        try w.print("  ⑤ 浮点百分比格式化 {{d:.1}} 保留一位小数\n", .{});
    }
    end("42.6");

    try w.print("\n自检通过\n", .{});
}

// ══════════════════════════════════════════════════════════════════
// 测试
// ══════════════════════════════════════════════════════════════════

test "parseMeminfo：真实 /proc/meminfo 样本" {
    const sample =
        "MemTotal:       16384000 kB\n" ++
        "MemFree:         2048000 kB\n" ++
        "MemAvailable:    6144000 kB\n" ++
        "Buffers:          512000 kB\n" ++
        "Cached:          4096000 kB\n" ++
        "SwapTotal:       4194304 kB\n" ++
        "SwapFree:        4194304 kB\n";
    const raw = parseMeminfo(sample);
    try std.testing.expectEqual(@as(u64, 16384000), raw.total_kb);
    try std.testing.expectEqual(@as(u64, 6144000), raw.available_kb);
    // kB → MB 整除
    try std.testing.expectEqual(@as(u64, 16000), kbToMb(raw.total_kb));
    try std.testing.expectEqual(@as(u64, 6000), kbToMb(raw.available_kb));
}

test "parseMeminfo：缺键 / 空输入 / 乱序" {
    // 空输入 → 全 0
    const empty = parseMeminfo("");
    try std.testing.expectEqual(@as(u64, 0), empty.total_kb);
    try std.testing.expectEqual(@as(u64, 0), empty.available_kb);

    // 只有 MemTotal，没有 MemAvailable
    const only_total = parseMeminfo("MemTotal: 8192 kB\n");
    try std.testing.expectEqual(@as(u64, 8192), only_total.total_kb);
    try std.testing.expectEqual(@as(u64, 0), only_total.available_kb);

    // MemAvailable 在 MemTotal 之前（乱序）
    const reversed = parseMeminfo("MemAvailable: 2048 kB\nMemTotal: 8192 kB\n");
    try std.testing.expectEqual(@as(u64, 8192), reversed.total_kb);
    try std.testing.expectEqual(@as(u64, 2048), reversed.available_kb);
}

test "calcUsedPercent：纯函数" {
    // total=100, avail=25 → used=75 → 75.0%
    const r1 = RawMeminfo{ .total_kb = 100, .available_kb = 25 };
    try std.testing.expectEqual(@as(f64, 75.0), calcUsedPercent(r1));

    // total=0 → 防除零，返回 0
    const r2 = RawMeminfo{ .total_kb = 0, .available_kb = 0 };
    try std.testing.expectEqual(@as(f64, 0.0), calcUsedPercent(r2));

    // 全可用 → 0%
    const r3 = RawMeminfo{ .total_kb = 100, .available_kb = 100 };
    try std.testing.expectEqual(@as(f64, 0.0), calcUsedPercent(r3));
}

test "JSON 往返：struct → string → struct，字段相等" {
    const a = std.testing.allocator;
    const original = MemStats{
        .total_mb = 16000,
        .available_mb = 6000,
        .used_percent = 62.5,
        .timestamp_ms = 1_700_000_000_000,
    };
    const json_str = try statsToJson(a, original);
    defer a.free(json_str);

    const restored = try jsonToStats(a, json_str);
    try std.testing.expectEqual(original.total_mb, restored.total_mb);
    try std.testing.expectEqual(original.available_mb, restored.available_mb);
    try std.testing.expectEqual(original.used_percent, restored.used_percent);
    try std.testing.expectEqual(original.timestamp_ms, restored.timestamp_ms);
}

test "ignore_unknown_fields：多余字段被跳过" {
    const a = std.testing.allocator;
    const json_str = "{\"total_mb\":8192,\"available_mb\":4096,\"used_percent\":50.0,\"timestamp_ms\":1700000000000,\"hostname\":\"web-01\",\"extra\":42}";
    const stats = try jsonToStatsLenient(a, json_str);
    try std.testing.expectEqual(@as(u64, 8192), stats.total_mb);
    try std.testing.expectEqual(@as(u64, 4096), stats.available_mb);
    try std.testing.expectEqual(@as(f64, 50.0), stats.used_percent);
    try std.testing.expectEqual(@as(i64, 1_700_000_000_000), stats.timestamp_ms);
}

test "默认选项遇到未知字段报错" {
    const a = std.testing.allocator;
    const json_str = "{\"total_mb\":8192,\"available_mb\":4096,\"used_percent\":50.0,\"timestamp_ms\":1700000000000,\"hostname\":\"web-01\"}";
    try std.testing.expectError(error.UnknownField, jsonToStats(a, json_str));
}

test "sampleStats：确定性输出" {
    const s = sampleStats();
    try std.testing.expectEqual(@as(u64, 16384), s.total_mb); // 16 GB
    try std.testing.expectEqual(@as(u64, 6144), s.available_mb); // 6 GB
    try std.testing.expectEqual(@as(f64, 62.5), s.used_percent); // (16-6)/16 = 62.5%
    try std.testing.expectEqual(@as(i64, 1_700_000_000_000), s.timestamp_ms);
}
