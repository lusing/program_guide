//! 26 编码与流处理：hex、std.base64、手写编码器、流式分块、@Vector SIMD 计数
//! 取材：Systems Programming with Zig ch4（z64 / zwc / SIMD 词计数）
const std = @import("std");

const base64_std = std.base64.standard;

pub fn main(_: std.process.Init) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();
    const err = std.debug;

    // ═══ 26.1 hex：bytesToHex / hexToBytes 互逆（定长数组版，栈上完成）
    const raw = "Zig 0.16 编码";
    const hexed = std.fmt.bytesToHex(raw, .upper);
    err.print("hex：{s}\n", .{hexed});
    var back: [raw.len]u8 = undefined;
    _ = try std.fmt.hexToBytes(&back, &hexed);
    std.debug.assert(std.mem.eql(u8, raw, &back));

    // ═══ 26.2 std.base64：先 calcSize 再 encode/decode（长度不猜）
    const msg = "Man is distinguished... 推荐用 calcSize";
    const enc_len = base64_std.Encoder.calcSize(msg.len);
    const enc_buf = try mem.alloc(u8, enc_len);
    const b64 = base64_std.Encoder.encode(enc_buf, msg);
    const dec_len = try base64_std.Decoder.calcSizeForSlice(b64);
    const dec_buf = try mem.alloc(u8, dec_len);
    try base64_std.Decoder.decode(dec_buf, b64);
    std.debug.assert(std.mem.eql(u8, msg, dec_buf));
    err.print("base64：{s}...\n回文一致：{d} 字节\n", .{ b64[0..24], dec_buf.len });

    // ═══ 26.3 手写 base64 编码器：3 字节 → 4 字符（表驱动，理解协议本体）
    const mine = try encodeB64(mem, msg);
    std.debug.assert(std.mem.eql(u8, mine, b64)); // 与标准库逐字节一致
    err.print("手写编码 == 标准库（{d} 字符）\n", .{mine.len});

    // ═══ 26.4 流式分块：不把"文件"整个读进内存，按块推过管道
    // 模拟一个 100KB 的"文件"——流式源用 Io.Reader.fixed，输出用 Writer.Allocating
    const big = try mem.alloc(u8, 100 * 1024);
    var rng = std.Random.DefaultPrng.init(0xC0FFEE);
    rng.random().bytes(big);
    var src = std.Io.Reader.fixed(big);
    var sink_state: std.Io.Writer.Allocating = .init(std.heap.page_allocator);
    defer sink_state.deinit();
    try streamHexdump(&src, &sink_state.writer, 32); // 只转储前 32 块演示
    err.print("流式 hexdump：产出 {d} 字节文本\n", .{sink_state.written().len});

    // ═══ 26.5 SIMD 词计数：一次看 32 字节，位技巧数"词首"
    const text = "one two  three\tfour\nfive  six seven\teight\nnine ten";
    const c_simd = countWordsSimd(text);
    const c_scalar = countWordsScalar(text);
    std.debug.assert(c_simd.lines == c_scalar.lines and c_simd.words == c_scalar.words);
    err.print("词计数：SIMD {any} == 标量 {any}\n", .{ c_simd, c_scalar });

    err.print("自检通过\n", .{});
}

/// 手写 base64（教学版）：每次吃 3 字节 → 4 个 6-bit 组 → 查表输出，尾部按 RFC 4648 补 '='
fn encodeB64(a: std.mem.Allocator, src: []const u8) ![]u8 {
    const table = std.base64.standard_alphabet_chars;
    const out = try a.alloc(u8, base64_std.Encoder.calcSize(src.len));
    var si: usize = 0;
    var oi: usize = 0;
    while (si + 3 <= src.len) : (si += 3) {
        const n: u32 = (@as(u32, src[si]) << 16) | (@as(u32, src[si + 1]) << 8) | src[si + 2];
        out[oi] = table[n >> 18 & 0x3F];
        out[oi + 1] = table[n >> 12 & 0x3F];
        out[oi + 2] = table[n >> 6 & 0x3F];
        out[oi + 3] = table[n & 0x3F];
        oi += 4;
    }
    const rem = src.len - si;
    if (rem == 1) {
        const n: u32 = @as(u32, src[si]) << 16;
        out[oi] = table[n >> 18 & 0x3F];
        out[oi + 1] = table[n >> 12 & 0x3F];
        out[oi + 2] = '=';
        out[oi + 3] = '=';
    } else if (rem == 2) {
        const n: u32 = (@as(u32, src[si]) << 16) | (@as(u32, src[si + 1]) << 8);
        out[oi] = table[n >> 18 & 0x3F];
        out[oi + 1] = table[n >> 12 & 0x3F];
        out[oi + 2] = table[n >> 6 & 0x3F];
        out[oi + 3] = '=';
    }
    return out;
}

/// 流式 hexdump：按块从 reader 拉、往 writer 写，内存占用恒定（块大小与总量无关）
fn streamHexdump(r: *std.Io.Reader, w: *std.Io.Writer, max_blocks: usize) !void {
    var chunk: [16]u8 = undefined;
    var blocks: usize = 0;
    while (blocks < max_blocks) : (blocks += 1) {
        const got = try r.readSliceShort(&chunk); // 读到多少算多少，EOF 返回 0
        if (got == 0) break;
        try w.print("{X:0>4}  ", .{blocks * 16});
        for (chunk[0..got]) |b| try w.print("{X:0>2} ", .{b});
        try w.print("\n", .{});
        if (got < chunk.len) break;
    }
    try w.flush();
}

const WordCounts = struct { lines: usize, words: usize };

/// SIMD 词计数（书上 zwc 的核心）：32 字节一批，比较产生位掩码，popCount 数词首
fn countWordsSimd(text: []const u8) WordCounts {
    const V = @Vector(32, u8);
    const B = @Vector(32, u1);
    const ones: B = @splat(1);
    const zeros: B = @splat(0);
    const sp: V = @splat(' ');
    const tab: V = @splat('\t');
    const cr: V = @splat('\r');
    const nl: V = @splat('\n');
    var lines: usize = 0;
    var words: usize = 0;
    var prev_was_space: u32 = 1; // 开头视作"空白"，首词即词首
    var i: usize = 0;
    while (i + 32 <= text.len) : (i += 32) {
        const v: V = text[i..][0..32].*;
        const is_nl = v == nl;
        lines += @popCount(@as(u32, @bitCast(@select(u1, is_nl, ones, zeros))));
        const is_white = (v == sp) | ((v >= tab) & (v <= cr)); // 空格或 \t..\r
        const curr: u32 = @bitCast(@select(u1, is_white, ones, zeros));
        const prev = (curr << 1) | prev_was_space; // 把上一块的末位接进来
        words += @popCount(~curr & prev); // 词首 = 当前非空白 且 前一字符空白
        prev_was_space = curr >> 31;
    }
    var was_space = prev_was_space == 1; // 尾巴不足 32 字节：退回标量
    while (i < text.len) : (i += 1) {
        const c = text[i];
        const ws = c == ' ' or (c >= '\t' and c <= '\r');
        if (c == '\n') lines += 1;
        if (!ws and was_space) words += 1;
        was_space = ws;
    }
    return .{ .lines = lines, .words = words };
}

fn countWordsScalar(text: []const u8) WordCounts {
    var lines: usize = 0;
    var words: usize = 0;
    var was_space = true;
    for (text) |c| {
        const ws = c == ' ' or (c >= '\t' and c <= '\r');
        if (c == '\n') lines += 1;
        if (!ws and was_space) words += 1;
        was_space = ws;
    }
    return .{ .lines = lines, .words = words };
}

// ═══ 26.6 测试
test "手写 base64 与标准库一致" {
    const a = std.testing.allocator;
    const cases = [_][]const u8{ "", "f", "fo", "foo", "foob", "fooba", "foobar", "Man is distinguished" };
    for (cases) |c| {
        const mine = try encodeB64(a, c);
        defer a.free(mine);
        const want = try a.alloc(u8, base64_std.Encoder.calcSize(c.len));
        defer a.free(want);
        try std.testing.expectEqualStrings(base64_std.Encoder.encode(want, c), mine);
    }
}

test "hex 互逆" {
    const data = "\x00\x01\xfe\xffAB";
    const h = std.fmt.bytesToHex(data, .lower);
    var out: [data.len]u8 = undefined;
    _ = try std.fmt.hexToBytes(&out, &h);
    try std.testing.expectEqualSlices(u8, data, &out);
}

test "SIMD 词计数 == 标量（含块边界与尾部）" {
    // 33+ 字节跨块；块边界正好切开单词；尾部不满 32
    const texts = [_][]const u8{
        "one two  three\tfour",
        "a" ** 31 ++ " b",
        "ab" ** 16 ++ " cd " ++ "ef" ** 20,
        "\n\n\n",
        "   leading and trailing   ",
        "",
        "single",
        "word " ** 40,
    };
    for (texts) |t| {
        try std.testing.expectEqual(countWordsScalar(t), countWordsSimd(t));
    }
}

test "流式 hexdump 输出前缀" {
    var r = std.Io.Reader.fixed("ABCDEFGH");
    var w_state: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer w_state.deinit();
    try streamHexdump(&r, &w_state.writer, 4);
    const s = w_state.written();
    try std.testing.expect(std.mem.startsWith(u8, s, "0000  41 42 43 44 45 46 47 48 \n"));
}
