//! 41 · 实战：随机数与密码生成器 —— PRNG/CSPRNG/模偏差/UUID v4
//! 取材：《Systems Programming with Zig》ch1/ch2 的随机数 API，按 0.17.0 实测重写：
//! 原书用 std.crypto.random / std.time.milliTimestamp，0.17 均已移除，
//! 对应替换为 init.io.randomSecure(&buf) 与 std.Io.Timestamp.now(io, .real)。
//! 全章一条主线：随机源的三种取法 → 模偏差理论 → 无偏拒绝采样 →
//! 两个实战产物（zpass 密码生成器 + UUID v4）→ 随机时间序列（数据处理工具的积木）。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 41.1 三种随机源
// ══════════════════════════════════════════════════════════════════

/// 把前 n 个字节格式化成 "xx xx xx ..." 的十六进制串（纯演示用，不走分配器）。
fn hexPrefix(buf: []const u8, comptime n: usize) [n * 3 - 1]u8 {
    var out: [n * 3 - 1]u8 = undefined;
    for (buf[0..n], 0..) |b, i| {
        out[i * 3 + 0] = std.fmt.hex_charset[b >> 4];
        out[i * 3 + 1] = std.fmt.hex_charset[b & 15];
        if (i + 1 < n) out[i * 3 + 2] = ' ';
    }
    return out;
}

fn section41_1(io: std.Io, w: *std.Io.Writer) !void {
    begin("41.1 三种随机源");

    // 源 1：DefaultPrng（Xoshiro256++）—— 软件 PRNG，吃 seed，可复现。
    // 固定 seed 的产出永远一致：测试友好，但**不能**当密码学随机用。
    var prng = std.Random.DefaultPrng.init(0xdeadbeef);
    const r = prng.random();
    const b0: [8]u8 = .{
        r.int(u8), r.int(u8), r.int(u8), r.int(u8),
        r.int(u8), r.int(u8), r.int(u8), r.int(u8),
    };
    try w.print("DefaultPrng(seed=0xdeadbeef) 前 8 字节: {s}\n", .{hexPrefix(&b0, 8)});
    // intRangeAtMost 是闭区间 [at_least, at_most]，内部走拒绝采样（见 41.2）。
    const dice = r.intRangeAtMost(u8, 1, 6);
    try w.print("intRangeAtMost(u8, 1, 6) 掷一次骰子: {d}\n", .{dice});

    // 源 2：io.random(&buf) —— 0.17 的"接口播种"：让 Io 实现用 randomSecure
    // （或其退化机制）填一块种子内存。比裸 PRNG 多一层 OS 熵，比 CSPRNG 便宜。
    var seed_buf: [32]u8 = undefined;
    io.random(&seed_buf);
    var prng2 = std.Random.DefaultPrng.init(std.mem.readInt(u64, seed_buf[0..8], .little));
    const r2 = prng2.random();
    const b1: [8]u8 = .{
        r2.int(u8), r2.int(u8), r2.int(u8), r2.int(u8),
        r2.int(u8), r2.int(u8), r2.int(u8), r2.int(u8),
    };
    try w.print("io.random 播种的 PRNG   前 8 字节: {s}\n", .{hexPrefix(&b1, 8)});

    // 源 3：io.randomSecure(&buf) —— 每次调用都向 OS 要新的密码学安全随机字节。
    // 0.17 里 std.crypto.random 已删，这是唯一正确的 CSPRNG 取法。
    var csprng_buf: [8]u8 = undefined;
    try io.randomSecure(&csprng_buf);
    try w.print("io.randomSecure(CSPRNG) 前 8 字节: {s}\n", .{hexPrefix(&csprng_buf, 8)});

    try w.writeAll("结论：三种源都能产字节；PRNG 可复现、CSPRNG 不可复现但抗预测。\n");
    end("41.1");
}

// ══════════════════════════════════════════════════════════════════
// 41.2 模偏差（modulo bias）—— 纯数学演示，不依赖任何随机源
// ══════════════════════════════════════════════════════════════════

/// 统计 0..range 中每个值 v 的 v % mod 落在哪个桶，返回各桶计数。
/// 这是确定性的：不掷随机数，直接数论。
/// range 用 u32：演示里要表达 2^8 = 256，u8 装不下。
fn biasedCounts(comptime range: u32, comptime mod: u32) [mod]u32 {
    var counts = std.mem.zeroes([mod]u32);
    var v: u32 = 0;
    while (v < range) : (v += 1) {
        counts[v % mod] += 1;
    }
    return counts;
}

/// 拒绝采样：从 [0, 256) 里拒绝 v >= bound 的值，直到取到 < bound 的。
/// bound 必须是 mod 的整数倍（调用方保证），这样 mod 之后各桶概率严格相等。
fn rejectionSampleMod100(r: std.Random) u8 {
    // floor(256/100)*100 = 200：只接受 0..199，模 100 后 0..99 各恰好 2 次机会。
    while (true) {
        const v = r.int(u8);
        if (v < 200) return v % 100;
    }
}

fn section41_2(io: std.Io, w: *std.Io.Writer) !void {
    _ = io;
    begin("41.2 模偏差");

    // 256 % 100 = 56 ≠ 0 → 残差 0..55 各 3 次机会，56..99 各 2 次。
    // 出现概率 3/256 vs 2/256，前者是后者的 1.5 倍。
    const counts = comptime biasedCounts(256, 100);
    try w.print("256 个 u8 值 % 100 的桶计数：残差 0..55 各 {d} 次，残差 56..99 各 {d} 次\n", .{ counts[0], counts[56] });
    try w.print("偏差比 = {d}/{d} = {d:.2}\n", .{ counts[0], counts[56], @as(f64, @floatFromInt(counts[0])) / @as(f64, @floatFromInt(counts[56])) });

    // 用固定 seed 的 PRNG 实测一次：掷 25600 次，看残差 0 和残差 99 的命中差。
    var prng = std.Random.DefaultPrng.init(42);
    const r = prng.random();
    var hit0: u32 = 0;
    var hit99: u32 = 0;
    var i: u32 = 0;
    while (i < 25600) : (i += 1) {
        const v = r.int(u8) % 100;
        if (v == 0) hit0 += 1;
        if (v == 99) hit99 += 1;
    }
    try w.print("实测（seed=42，25600 次 u8 % 100）：残差 0 命中 {d} 次，残差 99 命中 {d} 次\n", .{ hit0, hit99 });

    // 拒绝采样修复：拒绝 v >= 200 的值。
    var prng2 = std.Random.DefaultPrng.init(42);
    const r2 = prng2.random();
    var rhit0: u32 = 0;
    var rhit99: u32 = 0;
    i = 0;
    while (i < 25600) : (i += 1) {
        const v = rejectionSampleMod100(r2);
        if (v == 0) rhit0 += 1;
        if (v == 99) rhit99 += 1;
    }
    try w.print("拒绝采样后（同样 25600 次）：残差 0 命中 {d} 次，残差 99 命中 {d} 次\n", .{ rhit0, rhit99 });
    try w.writeAll("拒绝采样后每个残差概率相等。\n");
    end("41.2");
}

// ══════════════════════════════════════════════════════════════════
// 41.3 zpass 密码生成器
// ══════════════════════════════════════════════════════════════════

/// 字符集：大小写字母 + 数字 + 常用符号。
/// 长度 26+26+10+22 = 84，84 不整除 256（256 % 84 = 4），
/// 所以必须拒绝采样 —— 这正是 41.2 理论的实际用武之地。
const PASSWORD_CHARSET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{}";

/// 用 CSPRNG 字节 + 拒绝采样，无偏地从 PASSWORD_CHARSET 里挑 length 个字符。
/// 返回调用方拥有的切片（用同一 allocator free）。
fn generatePassword(io: std.Io, allocator: std.mem.Allocator, length: usize) ![]u8 {
    const charset_len = PASSWORD_CHARSET.len;
    // 最大的 256 的倍数 <= 256：floor(256/charset_len)*charset_len。
    // charset_len=84 → bound=252（84*3），拒绝 v >= 252 的字节。
    const bound: u16 = @as(u16, 256 / charset_len) * charset_len;

    const pw = try allocator.alloc(u8, length);
    var filled: usize = 0;
    while (filled < length) {
        var byte: [1]u8 = undefined;
        try io.randomSecure(&byte);
        const v: u16 = byte[0];
        if (v >= bound) continue; // 拒绝采样：丢弃会引入模偏差的尾部
        pw[filled] = PASSWORD_CHARSET[v % charset_len];
        filled += 1;
    }
    return pw;
}

fn section41_3(io: std.Io, w: *std.Io.Writer, gpa: std.mem.Allocator) !void {
    begin("41.3 zpass 密码生成");

    const lengths = [_]usize{ 12, 16, 20 };
    for (lengths) |len| {
        const pw = try generatePassword(io, gpa, len);
        defer gpa.free(pw);
        // 断言：长度正确 + 每个字符都在字符集里。
        std.debug.assert(pw.len == len);
        for (pw) |c| std.debug.assert(std.mem.indexOfScalar(u8, PASSWORD_CHARSET, c) != null);
        try w.print("长度 {d: >2}: {s}\n", .{ len, pw });
    }
    try w.writeAll("结论：3 个密码均满足长度与字符集约束（断言通过）。\n");
    end("41.3");
}

// ══════════════════════════════════════════════════════════════════
// 41.4 UUID v4 生成
// ══════════════════════════════════════════════════════════════════

/// 生成一个 UUID v4：16 个 CSPRNG 字节，
/// byte6 高 4 位写成 0b0100（版本 4），byte8 高 2 位写成 0b10（variant 2）。
fn uuidV4(io: std.Io) ![16]u8 {
    var b: [16]u8 = undefined;
    try io.randomSecure(&b);
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx（即 RFC 的 0b10）
    return b;
}

/// 格式化成标准形 "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"（36 字符 + 4 个连字符）。
/// 连字符位置：8/13/18/23 字符处，对应字节 3、5、7、9 之后。
fn uuidToString(b: [16]u8) [36]u8 {
    var out: [36]u8 = undefined;
    var oi: usize = 0;
    for (b, 0..) |byte, i| {
        // UUID 的连字符位置：byte 3、5、7、9 之后（8-4-4-4-12 分组）。
        if (i == 4 or i == 6 or i == 8 or i == 10) {
            out[oi] = '-';
            oi += 1;
        }
        out[oi] = std.fmt.hex_charset[byte >> 4];
        out[oi + 1] = std.fmt.hex_charset[byte & 15];
        oi += 2;
    }
    return out;
}

/// 解析回 16 字节（测试用）：跳过连字符，每两个十六进制字符还原一字节。
fn uuidParse(s: []const u8) ![16]u8 {
    if (s.len != 36) return error.BadLength;
    var out: [16]u8 = undefined;
    var oi: usize = 0; // 输出字节索引
    var i: usize = 0; // 输入字符索引
    while (i < s.len) {
        if (s[i] == '-') {
            i += 1;
            continue;
        }
        if (oi >= 16) return error.BadLength;
        const hi = std.mem.indexOfScalar(u8, std.fmt.hex_charset, s[i]) orelse return error.BadChar;
        i += 1;
        if (i >= s.len or s[i] == '-') return error.BadChar;
        const lo = std.mem.indexOfScalar(u8, std.fmt.hex_charset, s[i]) orelse return error.BadChar;
        i += 1;
        out[oi] = (@as(u8, @intCast(hi)) << 4) | @as(u8, @intCast(lo));
        oi += 1;
    }
    if (oi != 16) return error.BadLength;
    return out;
}

fn section41_4(io: std.Io, w: *std.Io.Writer) !void {
    begin("41.4 UUID v4");

    var i: usize = 0;
    while (i < 2) : (i += 1) {
        const b = try uuidV4(io);
        const s = uuidToString(b);
        // 断言：版本/变体位正确，字符串长度 36。
        std.debug.assert((b[6] >> 4) == 4);
        std.debug.assert((b[8] >> 6) == 0b10);
        std.debug.assert(s.len == 36);
        try w.print("UUID v4 #{d}: {s}\n", .{ i + 1, s });
    }
    try w.writeAll("结论：version nibble = 4，variant bits = 0b10，字符串定长 36。\n");
    end("41.4");
}

// ══════════════════════════════════════════════════════════════════
// 41.5 随机时间序列生成器
// ══════════════════════════════════════════════════════════════════

const TimePoint = struct {
    /// 毫秒时间戳（epoch 起）。0.17 用 std.Io.Timestamp.now(io, .real).toMilliseconds()。
    ts_ms: i64,
    /// 测量值，[0, 100] 区间。
    value: f64,
};

/// 生成 n 个点的随机时间序列：起点 t0，步长 step_ms，值在 [0, 100]。
/// 形状确定（点数/步长/起点），只有 value 是随机的 —— 数据处理工具的输入积木。
fn generateTimeSeries(
    io: std.Io,
    n: usize,
    t0_ms: i64,
    step_ms: i64,
    out: []TimePoint,
) !void {
    var seed: [8]u8 = undefined;
    try io.randomSecure(&seed);
    var prng = std.Random.DefaultPrng.init(std.mem.readInt(u64, &seed, .little));
    const r = prng.random();
    for (out[0..n], 0..) |*p, i| {
        p.ts_ms = t0_ms + @as(i64, @intCast(i)) * step_ms;
        // intRangeAtMost 内部已拒绝采样，[0,100] 无偏。
        p.value = @floatFromInt(r.intRangeAtMost(u8, 0, 100));
    }
}

fn section41_5(io: std.Io, w: *std.Io.Writer) !void {
    begin("41.5 随机时间序列");

    // 形状完全确定：5 个点，epoch 起点，60 秒一步；只有 value 随机。
    var points: [5]TimePoint = undefined;
    try generateTimeSeries(io, 5, 0, 60_000, &points);

    try w.writeAll("  idx | timestamp(ms) | value\n");
    try w.writeAll("------+---------------+------\n");
    for (points, 0..) |p, i| {
        // 0.17 的 {d:>w} 对 i64 会带 + 号，转成 u64 规避。
        try w.print("  {d}   | {d: >13} | {d:.1}\n", .{ i, @as(u64, @intCast(p.ts_ms)), p.value });
    }
    try w.writeAll("结论：时间轴确定（epoch + 60s 步进），只有 value 随机。\n");
    end("41.5");
}

// ══════════════════════════════════════════════════════════════════
// 41.6 坑位清单
// ══════════════════════════════════════════════════════════════════

fn section41_6(w: *std.Io.Writer) !void {
    begin("41.6 坑位清单");
    try w.writeAll(
        \\1. std.crypto.random 在 0.17 不存在 —— 用 init.io.randomSecure(&buf)
        \\2. std.time.milliTimestamp 在 0.17 不存在 —— 用 std.Io.Timestamp.now(io, .real).toMilliseconds()
        \\3. 模偏差：% N 当 2^bits % N != 0 时有偏；拒绝采样是无偏的标准解法
        \\4. PRNG 需要 seed：固定 seed 可复现（测试友好），io.random 每次不同
        \\5. r.intRangeAtMost 内部已处理无偏，手写 % 才踩坑
        \\
    );
    end("41.6");
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

    try section41_1(io, w);
    try section41_2(io, w);
    try section41_3(io, w, gpa);
    try section41_4(io, w);
    try section41_5(io, w);
    try section41_6(w);
}

// ══════════════════════════════════════════════════════════════════
// Tests
// ══════════════════════════════════════════════════════════════════

test "biasedCounts 数论：256 % 100 → 残差 0..55 各 3 次，56..99 各 2 次" {
    const counts = comptime biasedCounts(256, 100);
    try std.testing.expectEqual(@as(u32, 3), counts[0]);
    try std.testing.expectEqual(@as(u32, 3), counts[55]);
    try std.testing.expectEqual(@as(u32, 2), counts[56]);
    try std.testing.expectEqual(@as(u32, 2), counts[99]);
    // 总数守恒：3*56 + 2*44 = 168 + 88 = 256。
    var total: u32 = 0;
    for (counts) |c| total += c;
    try std.testing.expectEqual(@as(u32, 256), total);
}

test "拒绝采样：永不返回 >= bound 的值，且多次抽取覆盖所有残差" {
    var prng = std.Random.DefaultPrng.init(7);
    const r = prng.random();
    // 单值约束：rejectionSampleMod100 的返回值必在 [0, 100)。
    var i: u32 = 0;
    while (i < 10000) : (i += 1) {
        const v = rejectionSampleMod100(r);
        try std.testing.expect(v < 100);
    }
    // 覆盖性：1000 次内 0..99 每个残差都至少出现一次（固定 seed，确定性）。
    var prng2 = std.Random.DefaultPrng.init(7);
    const r2 = prng2.random();
    var seen = std.mem.zeroes([100]bool);
    i = 0;
    while (i < 1000) : (i += 1) {
        seen[rejectionSampleMod100(r2)] = true;
    }
    for (seen) |s| try std.testing.expect(s);
}

test "UUID v4：version nibble == 4，variant bits == 0b10，字符串长 36" {
    // 不走 OS 熵：手工构造 16 字节，走 uuidToString / uuidParse 验证格式逻辑。
    var b: [16]u8 = .{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10 };
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    const s = uuidToString(b);
    try std.testing.expectEqual(@as(usize, 36), s.len);
    try std.testing.expectEqual(@as(u4, 4), @as(u4, @truncate(b[6] >> 4)));
    try std.testing.expectEqual(@as(u2, 0b10), @as(u2, @truncate(b[8] >> 6)));
    // 解析回 16 字节应逐字节一致。
    const back = try uuidParse(&s);
    try std.testing.expectEqualSlices(u8, &b, &back);
}

test "zpass 密码：长度正确，所有字符都在字符集内（固定 seed，100 次迭代）" {
    var prng = std.Random.DefaultPrng.init(12345);
    const r = prng.random();
    const charset_len = PASSWORD_CHARSET.len;
    const bound: u16 = @as(u16, 256 / charset_len) * charset_len;
    var iter: u32 = 0;
    while (iter < 100) : (iter += 1) {
        // 复刻 generatePassword 的采样逻辑，但用固定 seed 的 PRNG 保证确定性。
        var pw: [20]u8 = undefined;
        var filled: usize = 0;
        while (filled < pw.len) {
            const v: u16 = r.int(u8);
            if (v >= bound) continue;
            pw[filled] = PASSWORD_CHARSET[v % charset_len];
            filled += 1;
        }
        // 长度天然是 20（数组定长）；验证字符集归属。
        for (pw) |c| {
            try std.testing.expect(std.mem.indexOfScalar(u8, PASSWORD_CHARSET, c) != null);
        }
    }
}
