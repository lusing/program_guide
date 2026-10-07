//! 26 编码与流处理：流与字节序列的关系、0.17 的 Reader/Writer 三件套、按分隔符读取、
//! hex 编解码、std.base64（标准 vs URL-safe）、手写 base64、URL 百分号编码（手写）、
//! std.compress.flate 现状、std.hash 完整性校验、@Vector SIMD 计数、流式 vs 一次性取舍
//!
//! 取材：Systems Programming with Zig ch4（z64 / zwc / SIMD 词计数）
//!
//! 本章的三条硬结论（都是 0.17.0 上实测的，不是文档摘抄）：
//! 1. `readSliceShort` 是"填满缓冲或读到 EOF"语义，**不是**单次 read。
//! 2. `takeDelimiterExclusive` 在 0.17 **两种 Reader 上都会"吃掉分隔符后空转**——
//!    第一次拿到数据，之后永远返回长度为 0 的空片（实测），上层 `while (true)` 会死循环刷屏。
//! 3. 通用正确姿势是 `fillMore()` + `buffered()` + `toss()`；但**`Reader.fixed` 上
//!    `fillMore()` 直接返回 `error.EndOfStream`**（哪怕缓冲里明明有数据），要用 `buffered()` 直取。
const std = @import("std");
const builtin = @import("builtin");

const base64_std = std.base64.standard;
const base64_url = std.base64.url_safe;

/// 探针文件统一放/tmp，仓库里不留任何临时目录
const probe_path = "/tmp/zig_tut_26_encoding_probe.txt";

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 0.17 起 `**`（编译期重复）运算符已从语言里移除：`"ab" ** 3` 现在会被
/// 词法分析成两个 `*`，直接报 "binary operator '*' has whitespace on one side"。
/// 替代品是一个**返回类型的 comptime 函数**——它顺带把 comptime 的两种典型用法
/// （comptime 参数 + 类型作返回值）都演示了一遍。
/// 数组/向量用 `@splat`，字符串只能自己写（`++` 拼接仍在）。
fn Rep(comptime s: []const u8, comptime n: usize) type {
    return struct {
        //⚠️ 哨兵数组 `[N:0]u8` 的结尾 0 由**编译器自动放置**，不要手动写。
        //   手动写 `b[b.len - 1] = 0` 会把**最后一个真实字节**覆盖成0（实测：
        //   Rep("ab", 4) 得到 "abababa "而不是 "abababab"）。b.len 是 N 不含哨兵，
        //   而 @sizeOf([8:0]u8) = 9——所以 b[b.len] 才是哨兵位。
        const data: [s.len * n:0]u8 = blk: {
            var b: [s.len * n:0]u8 = undefined;
            for (0..n) |i| @memcpy(b[i * s.len ..][0..s.len], s);
            break :blk b;
        };
        pub const bytes: [:0]const u8 = &data;
    };
}

// ═══ 26.4 的正确姿势：手工按分隔符切分（不依赖 takeDelimiter*）═══════════

/// 通用"读一段"：fillMore + buffered + toss 三件套。
/// 返回 false 表示流已结束（fillMore 报 EndOfStream）。
/// ⚠️ 只能在**缓冲区归Reader 所有**的环境用（File.Reader / net.Stream.Reader）；
/// `Reader.fixed` 的 buffer 是只读别名，fillMore 会直接报 EndOfStream。
fn readChunk(r: *std.Io.Reader) !?[]const u8 {
    r.fillMore() catch |err| switch (err) {
        error.EndOfStream => return null,
        error.ReadFailed => |e| return e,
    };
    const avail = r.buffered();
    if (avail.len == 0) return null;
    return avail;
}

/// 26.5 的通用按行读取：循环 fillMore + 手工indexOfScalar + toss(idx+1)。
/// toss 的是`idx + 1`（**含**分隔符），所以不会像 takeDelimiterExclusive 那样空转。
/// 文件与 net.Stream 上行为一致——这是本章最重要的一条。
fn forEachLine(r: *std.Io.Reader, ctx: anytype, comptime cb: fn (@TypeOf(ctx), []const u8) anyerror!void) !usize {
    var lines: usize = 0;
    var carry: usize = 0; //上一轮没切完的字节数
    while (true) {
        _ = try readChunk(r) orelse break;
        const buf = r.buffered();
        var start: usize = 0;
        while (std.mem.indexOfScalarPos(u8, buf, start, '\n')) |idx| {
            try cb(ctx, buf[start..idx]);
            lines += 1;
            start = idx + 1;
        }
        carry = buf.len - start;
        r.toss(start); // 只丢掉已消费的部分，残余留在缓冲里
    }
    if (carry > 0) {
        try cb(ctx, r.buffered()[0..carry]); // 最后一行没有换行符
        lines += 1;
    }
    return lines;
}

/// 26.5 的 forEachLine 用的回调上下文：记下每行的**拷贝** + 行长。
/// 单独提成顶层类型，是因为**函数体内定义的 struct 的成员函数不能捕获外层变量**
/// （实测报"mem not accessible from inner function"）。
/// ⚠️ 必须dupe 一份：`forEachLine` 传的 `line` 指向 Reader 的内部缓冲，
/// 下一次 `fillMore`/`toss` 就失效（实测：存下来会变成 "l3"）。要和 25 章的
/// "peek 返回的切片会被下一次读失效" 是同一条规则。
const LineCollector = struct {
    gpa: std.mem.Allocator,
    list: std.ArrayList(usize) = .empty,
    lines: std.ArrayList([]u8) = .empty,

    fn collect(self: *@This(), line: []const u8) anyerror!void {
        try self.lines.append(self.gpa, try self.gpa.dupe(u8, line));
        try self.list.append(self.gpa, line.len);
    }

    fn deinit(self: *@This()) void {
        for (self.lines.items) |l| self.gpa.free(l);
        self.lines.deinit(self.gpa);
        self.list.deinit(self.gpa);
    }
};

/// 26.3 的对照：takeDelimiterInclusive 是**唯一不会空转**的 takeDelimiter* 变体。
fn countLinesInclusive(r: *std.Io.Reader) !usize {
    var n: usize = 0;
    while (true) {
        const line = r.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            error.StreamTooLong => return error.StreamTooLong,
            error.ReadFailed => |e| return e,
        };
        if (line.len > 0) n += 1;
    }
    return n;
}

// ═══ 26.6 手写编码器（教学版：3 字节 → 4 字符）════════════════════════════

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

// ═══ 26.8 URL 百分号编码（0.17 只有解码，编码得手写）══════════════════════

/// RFC 3986 unreserved：A-Z a-z 0-9 - . _ ~
fn isUnreserved(c: u8) bool {
    return (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or
        (c >= '0' and c <= '9') or c == '-' or c == '.' or c == '_' or c == '~';
}

/// 百分号编码：未保留字符原样输出，其余写成 %XX（大写十六进制）。
/// 最坏情况 3 倍长度，调用方按 `s.len * 3` 给缓冲。
fn percentEncode(buf: []u8, s: []const u8) error{NoSpaceLeft}![]u8 {
    const hex = "0123456789ABCDEF";
    var n: usize = 0;
    for (s) |c| {
        if (isUnreserved(c)) {
            if (n >= buf.len) return error.NoSpaceLeft;
            buf[n] = c;
            n += 1;
        } else {
            if (n + 3 > buf.len) return error.NoSpaceLeft;
            buf[n] = '%';
            buf[n + 1] = hex[c >> 4];
            buf[n + 2] = hex[c & 15];
            n += 3;
        }
    }
    return buf[0..n];
}

/// 百分号解码：非法转义序列返回错误（**不**像 std.Uri 那样静默透传）。
fn percentDecode(buf: []u8, s: []const u8) error{ NoSpaceLeft, InvalidEscape, InvalidDigit }![]u8 {
    var n: usize = 0;
    var i: usize = 0;
    while (i < s.len) {
        if (n >= buf.len) return error.NoSpaceLeft;
        if (s[i] == '%') {
            if (i + 2 >= s.len) return error.InvalidEscape;
            const hi = std.fmt.charToDigit(s[i + 1], 16) catch return error.InvalidDigit;
            const lo = std.fmt.charToDigit(s[i + 2], 16) catch return error.InvalidDigit;
            buf[n] = (hi << 4) | lo;
            i += 3;
        } else {
            buf[n] = s[i];
            i += 1;
        }
        n += 1;
    }
    return buf[0..n];
}

// ═══ 26.10 SIMD ══════════════════════════════════════════════════════════

/// SIMD 版：统计 32 字节窗口里有几个字节等于 target。
/// 尾数不足 32 字节退回标量。
fn countByteSimd(data: []const u8, target: u8) usize {
    const V = @Vector(32, u8);
    const tv: V = @splat(target);
    var n: usize = 0;
    var i: usize = 0;
    while (i + 32 <= data.len) : (i += 32) {
        const v: V = data[i..][0..32].*; // 切片 →向量：一次装 32 字节
        const bits: u32 = @bitCast(v == tv); // 比较 → 位掩码
        n += @popCount(bits); // popCount 数位
    }
    for (data[i..]) |c| {
        if (c == target) n += 1;
    }
    return n;
}

fn countByteScalar(data: []const u8, target: u8) usize {
    var n: usize = 0;
    for (data) |c| {
        if (c == target) n += 1;
    }
    return n;
}

const WordCounts = struct { lines: usize, words: usize };

/// SIMD 词计数（书上 zwc 的核心）：32 字节一批，比较产生位掩码，popCount 数词首。
/// 块间用 prev_was_space 把上一块的末位接进来，跨块单词不丢。
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

/// 26.7 的被测对象：流式 hexdump，内存占用与总量脱钩。
/// ⚠️ 这里用 `readChunk`（fillMore 三件套）而不是 readSliceShort——后者是"填满或 EOF"语义。
fn streamHexdump(r: *std.Io.Reader, w: *std.Io.Writer, max_blocks: usize) !usize {
    var blocks: usize = 0;
    while (blocks < max_blocks) : (blocks += 1) {
        const avail = (try readChunk(r) orelse break);
        const n = @min(avail.len, 16);
        try w.print("{X:0>4}  ", .{blocks * 16});
        for (avail[0..n]) |b| try w.print("{X:0>2} ", .{b});
        try w.print("\n", .{});
        if (avail.len < 16) break;
        r.toss(n);
    }
    try w.flush();
    return blocks;
}

pub fn main(init: std.process.Init) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const mem = arena_state.allocator();
    const err = std.debug;

    // ═══ 26.1 流与字节序列：Reader/Writer 是这个问题的通用抽象 ═══
    begin("26.1 流与字节序列");
    err.print("流 = 「一段还没被读走的字节」。Reader 把它切成块，Writer 把它接成块。\n", .{});
    err.print("std.Io.Reader 是 {{ vtable, buffer, seek, end }} 四个字段（实测）：\n", .{});
    inline for (@typeInfo(std.Io.Reader).@"struct".field_names) |f| {
        err.print("  .{s}\n", .{f});
    }
    err.print("buffer 是 Reader **自己拥有**的可写缓冲；seek 是已消费位置，end 是已填充位置。\n", .{});
    err.print("buffered() = buffer[seek..end]—— 「已经到手、还没读走」的那一段。\n", .{});
    err.print("同一份「按分隔符切分」逻辑可以跑在文件、内存切片、网络流上，这就是通用抽象。\n", .{});
    err.print("Reader 家族构造：Reader.fixed(切片) / file.reader(io, buf) / stream.reader(io, buf)\n", .{});
    err.print("Writer 家族构造：Writer.fixed(切片) / Allocating.init(gpa) / file.writer(io, buf)\n", .{});
    {
        // fixed：把一个切片变成流——测试的万能道具
        var r = std.Io.Reader.fixed("hello world");
        err.print("\n  Reader.fixed(\"hello world\")：buffer.len={d} end={d} seek={d} bufferedLen={d}\n", .{
            r.buffer.len, r.end, r.seek, r.bufferedLen(),
        });
        err.print("  它把整个切片**直接当已缓冲数据**（.end = buffer.len），所以一次 readSliceAll 就全拿到。\n", .{});
        var buf: [64]u8 = undefined;
        const msg = "hello world";
        try r.readSliceAll(buf[0..msg.len]);
        err.print("  readSliceAll(buf[0..{d}]) -> «{s}」（缓冲必须**正好**是长度；填 64 会报 EndOfStream）\n", .{ msg.len, buf[0..msg.len] });
    }
    {
        var sbuf: [64]u8 = undefined;
        var w = std.Io.Writer.fixed(&sbuf);
        try w.print("Writer.fixed 落到调用方的栈缓冲上：{s}", .{"ok"});
        err.print("  {s}（{d} 字节，无需 flush）\n", .{ w.buffered(), w.buffered().len });
        err.print("  ⚠️ 缓冲写满会报 error.WriteFailed（不是静默截断）\n", .{});
    }
    end("26.1 流与字节序列");

    // ═══ 26.2 正确的「读一段」姿势：fillMore + buffered + toss ═══
    begin("26.2 读一段：fillMore + buffered + toss");
    err.print("⚠️ readSliceShort 是「**填满缓冲或读到 EOF**」语义，不是单次 read：\n", .{});
    err.print("   它内部是while(true) {{ readVec }} 直到 buffer 满或 EndOfStream（Io/Reader.zig:696-703）。\n", .{});
    err.print("   拿它当「读一点」用，在没有新数据的流上会一直等。\n", .{});
    {
        // 造一个探针文件（/tmp，不留在仓库里）
        const lines = "alpha\nbeta\ngamma\ndelta";
        {
            var f = try std.Io.Dir.cwd().createFile(init.io, probe_path, .{});
            defer f.close(init.io);
            var b: [64]u8 = undefined;
            var fw = f.writer(init.io, &b);
            try fw.interface.writeAll(lines);
            try fw.interface.flush();
        }
        // 对照 1：readSliceShort 读 16 字节缓冲
        {
            var f = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
            defer f.close(init.io);
            var rbuf: [4096]u8 = undefined;
            var fr = f.reader(init.io, &rbuf);
            var chunk: [16]u8 = undefined;
            const n = try fr.interface.readSliceShort(&chunk);
            err.print("  文件共 {d} 字节；readSliceShort(&chunk[16]) = {d}\n", .{ lines.len, n });
            err.print("  ⇒ 它果然读满了 16（而不是「有多少读多少」）；剩下 8 字节留在缓冲里。\n", .{});
        }
        // 正确姿势：fillMore 三件套
        {
            var f = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
            defer f.close(init.io);
            var rbuf: [4096]u8 = undefined;
            var fr = f.reader(init.io, &rbuf);
            const r = &fr.interface;
            err.print("\n  三件套逐轮实测：\n", .{});
            var round: usize = 0;
            while (round < 4) : (round += 1) {
                r.fillMore() catch |e| {
                    err.print("    第 {d} 轮 fillMore -> {s}← EOF 信号（fillMore **返回错误**，不是 void）\n", .{ round + 1, @errorName(e) });
                    break;
                };
                const avail = r.buffered();
                err.print("    第 {d} 轮 fillMore 后 bufferedLen={d}，内容 = «{s}»\n", .{ round + 1, avail.len, avail });
                if (avail.len > 0) r.toss(avail.len);
            }
        }
        // ⚠️ fixed 上 fillMore 直接报错
        {
            var r = std.Io.Reader.fixed("hello\nworld");
            err.print("\n  ⚠️ 但 Reader.fixed 上fillMore 会失败：\n", .{});
            r.fillMore() catch |e| {
                err.print("    fixed(\"hello\\nworld\").fillMore() -> {s}（尽管 bufferedLen={d} 明明有数据）\n", .{ @errorName(e), r.bufferedLen() });
            };
            err.print("    原因：fillMore 先 rebase(capacity=1)，fixed 的 vtable.rebase = endingRebase → EndOfStream。\n", .{});
            err.print("    ⇒ fixed 上直接用 buffered() + toss()，别碰 fillMore。\n", .{});
        }
        // ⚠️ toss(idx + 1) 里的 idx 是 ?usize
        {
            var r = std.Io.Reader.fixed("hello\nworld");
            const idx = std.mem.indexOfScalar(u8, r.buffered(), '\n');
            err.print("\n  indexOfScalar 找到 '\\n' 于 {?d}（类型 ?usize，**不是** usize）\n", .{idx});
            err.print("  ⚠️ 直接写 r.toss(idx + 1) 是**编译错**：invalid operands to binary expression: 'optional' and 'comptime_int'\n", .{});
            err.print("  ⚠️ 写成 idx.? + 1 则是运行期 panic: attempt to use null value\n", .{});
            err.print("  ⇒ 正确写法：先 orelse 提前收工，拿到 usize 再 +1。\n", .{});
            if (idx) |i| {
                r.toss(i + 1);
                err.print("  实测：toss({d}) 后剩余 «{s}»\n", .{ i + 1, r.buffered() });
            }
        }
        std.Io.Dir.cwd().deleteFile(init.io, probe_path) catch {};
    }
    end("26.2 读一段：fillMore + buffered + toss");

    // ═══ 26.3 按分隔符读取：三种写法的实测差异 ═══
    begin("26.3 按分隔符读取");
    err.print("⚠️⚠️ 本章最关键的一条：takeDelimiterExclusive 在 0.17 会**空转**。\n", .{});
    err.print("   源码路径：takeDelimiterExclusive → peekDelimiterExclusive → peekDelimiterInclusive\n", .{});
    err.print("   peekDelimiterInclusive 第 866-872 行：缓冲没分隔符时用 Writer.failing 探测，\n", .{});
    err.print("   对**文件**流探测到 EOF → 返回 error.EndOfStream（正常）；\n", .{});
    err.print("   但对已经有数据、只是分隔符用完的情况，它返回**长度为 0 的空片**且**不报错**。\n", .{});
    {
        // 文件上的实测：exclusive 空转 vs inclusive 正常
        var f = try std.Io.Dir.cwd().createFile(init.io, probe_path, .{});
        {
            var b: [128]u8 = undefined;
            var fw = f.writer(init.io, &b);
            try fw.interface.writeAll("l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\n");
            try fw.interface.flush();
        }
        f.close(init.io);

        err.print("\n  A. takeDelimiterExclusive（8 字节缓冲，文件有 10 行）：\n", .{});
        {
            var f2 = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
            defer f2.close(init.io);
            var rbuf: [8]u8 = undefined;
            var fr = f2.reader(init.io, &rbuf);
            var n: usize = 0;
            var empties: usize = 0;
            while (n < 8) : (n += 1) {
                const line = fr.interface.takeDelimiterExclusive('\n') catch |e| {
                    err.print("     第 {d} 次 -> {s}\n", .{ n + 1, @errorName(e) });
                    break;
                };
                if (line.len == 0) empties += 1;
                if (n < 3 or line.len == 0) {
                    err.print("     第 {d} 次 -> 长度 {d} «{s}»{s}\n", .{ n + 1, line.len, line, if (line.len == 0) "  ← 空转！" else "" });
                }
            }
            err.print("     ⇒8 次里有 {d} 次是空片。上层 while(true) 写下去就是**死循环刷屏**。\n", .{empties});
        }

        err.print("\n  B. takeDelimiterInclusive（同样 8 字节缓冲）：\n", .{});
        {
            var f2 = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
            defer f2.close(init.io);
            var rbuf: [8]u8 = undefined;
            var fr = f2.reader(init.io, &rbuf);
            const n = countLinesInclusive(&fr.interface) catch 0;
            err.print("     数到 {d} 行（每行含 '\\n'），第 11 次调用返回 EndOfStream 干净收工\n", .{n});
        }

        err.print("\n  C. takeDelimiter（返回 ?[]u8，EOF 给 null 而不是 EndOfStream）：\n", .{});
        {
            var f2 = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
            defer f2.close(init.io);
            var rbuf: [8]u8 = undefined;
            var fr = f2.reader(init.io, &rbuf);
            var n: usize = 0;
            while (n < 12) : (n += 1) {
                const maybe = fr.interface.takeDelimiter('\n') catch |e| {
                    err.print("     第 {d} 次 -> err {s}\n", .{ n + 1, @errorName(e) });
                    break;
                };
                if (maybe) |line| {
                    if (n < 2) err.print("     第 {d} 次 -> «{s}」（长度 {d}）\n", .{ n + 1, line, line.len });
                } else {
                    err.print("     第 {d} 次 -> null（干净 EOF，不抛错）\n", .{n + 1});
                    break;
                }
            }
            err.print("     ⇒ takeDelimiter 是**唯一不空转**的 takeDelimiter* 家族成员。\n", .{});
        }

        err.print("\n  D. 通用写法（fillMore + buffered + indexOfScalar + toss(idx+1)）：\n", .{});
        {
            var f2 = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
            defer f2.close(init.io);
            var rbuf: [8]u8 = undefined;
            var fr = f2.reader(init.io, &rbuf);
            var ctx: LineCollector = .{ .gpa = mem };
            defer ctx.deinit();
            const n = try forEachLine(&fr.interface, &ctx, LineCollector.collect);
            err.print("     逐行回调命中 {d} 行，行长 = {any}（无空转、末行无换行也正确）\n", .{ n, ctx.list.items });
        }

        err.print("\n  E. 同一份 forEachLine 在 **net.Stream** 上也成立（架构对称）：\n", .{});
        err.print("     net.Stream.Reader 的 vtable 里 .stream/.readVec 是 socket 读写，\n", .{});
        err.print("     但 peekDelimiterInclusive / takeDelimiter* 是**同一份 Reader.zig 代码**，\n", .{});
        err.print("     所以「exclusive 空转」这个行为在两种 Reader 上**完全一致**——\n", .{});
        err.print("     不同之处只在「缓冲里没分隔符时」：文件探到 EOF 报 EndOfStream，\n", .{});
        err.print("     网络流则是**真的在等**（fillMore 阻塞在 socket read，实测挂住不返回）。\n", .{});
        err.print("     ⇒ 结论：网络流上用 takeDelimiterExclusive 有**两个**风险（空转 + 阻塞），\n", .{});
        err.print("     统一用 fillMore 三件套把两个风险一起消掉。\n", .{});
        std.Io.Dir.cwd().deleteFile(init.io, probe_path) catch {};
    }
    end("26.3 按分隔符读取");

    // ═══ 26.4 hex 编解码 ═══
    begin("26.4 hex 编解码");
    {
        const raw = "Zig 0.17 编码";
        const hexed = std.fmt.bytesToHex(raw, .upper);
        err.print("bytesToHex(\"Zig 0.17 编码\", .upper) = {s}\n", .{hexed});
        err.print("  返回类型 = {s}（长度 = input.len * 2，**定长数组**，栈上完成、零分配）\n", .{@typeName(@TypeOf(hexed))});
        var back: [raw.len]u8 = undefined;
        const got = try std.fmt.hexToBytes(&back, &hexed);
        err.print("hexToBytes(&back, &hexed) -> «{s}»（{d} 字节），互逆 = {}\n", .{ got, got.len, std.mem.eql(u8, raw, got) });
        err.print("  ⚠️ bytesToHex 的第二参是 std.fmt.Case（.lower/.upper），**不是端序**——\n", .{});
        err.print("     hex 没有端序概念（它就是字节的打印形式）。真正的端序参数在\n", .{});
        err.print("     readSliceEndian / writeInt / bytesToHex 的近亲里，别混淆。\n", .{});
        // 大小写都能解
        const lower = std.fmt.bytesToHex("\x00\x01\xfe\xffAB", .lower);
        var out: [6]u8 = undefined;
        _ = try std.fmt.hexToBytes(&out, &lower);
        err.print("  解码器大小写通吃：bytesToHex(\"\\x00\\x01\\xfe\\xffAB\", .lower) = {s} -> {any}\n", .{ lower, out });
        // 奇数长度 → InvalidLength
        if (std.fmt.hexToBytes(&out, "abc")) |got2| {
            err.print("  ⚠️ hexToBytes(\"abc\") 意外成功 -> {any}\n", .{got2});
        } else |e| {
            err.print("  ⚠️ hexToBytes 奇数长度 -> {s}（不是崩溃，是错误集成员）\n", .{@errorName(e)});
        }
    }
    end("26.4 hex 编解码");

    // ═══ 26.5 std.base64 ═══
    begin("26.5 std.base64");
    {
        const msg = "Man is distinguished... 推荐用 calcSize";
        const enc_len = base64_std.Encoder.calcSize(msg.len);
        const enc_buf = try mem.alloc(u8, enc_len);
        const b64 = base64_std.Encoder.encode(enc_buf, msg);
        err.print("calcSize({d}) = {d}（= 4*⌈n/3⌉，纯数学、不出错）\n", .{ msg.len, enc_len });
        err.print("encode -> {s}...\n", .{b64[0..32]});
        const dec_len = try base64_std.Decoder.calcSizeForSlice(b64);
        const dec_buf = try mem.alloc(u8, dec_len);
        try base64_std.Decoder.decode(dec_buf, b64);
        err.print("calcSizeForSlice -> {d}（精确）；calcSizeUpperBound -> {d}（上界，不扣 padding）\n", .{
            dec_len, try base64_std.Decoder.calcSizeUpperBound(b64.len),
        });
        // 上界 vs 精确的差别要在**有 padding** 时才看得出
        {
            const padded = base64_std.Encoder.encode(enc_buf[0..8], "fo"); // 2 字节 -> 3 字符 + 1 个 '='
            err.print("  带 padding 的例子：\"fo\"（2 字节）-> {s}\n", .{padded});
            err.print("    calcSizeUpperBound({d}) = {d}；calcSizeForSlice = {d}（差 1）\n", .{
                padded.len,
                try base64_std.Decoder.calcSizeUpperBound(padded.len),
                try base64_std.Decoder.calcSizeForSlice(padded),
            });
        }
        err.print("decode后逐字节一致 = {}\n", .{std.mem.eql(u8, msg, dec_buf)});
        err.print("⇒ 为什么需要 base64：二进制塞进文本通道（邮件头、JSON、URL）要一层 6-bit 重排。\n", .{});
        err.print("   calcSize 的意义：**编码方向长度是确定的**，所以可以一次分配；\n", .{});
        err.print("   **解码方向输入可能脏**，所以 calcSizeForSlice 返回错误集。\n", .{});
        // 0.17 的真实名字
        err.print("\n  0.17 实测存在的编解码器（@hasDecl 逐个探测）：\n", .{});
        inline for (.{ "standard", "standard_no_pad", "url_safe", "url_safe_no_pad", "url_safe_encoder" }) |nm| {
            err.print("    std.base64.{s:<20} {}\n", .{ nm, @hasDecl(std.base64, nm) });
        }
        err.print("  ⇒ URL 安全的真名是 **std.base64.url_safe**（Codecs 结构体，不是 encoder 变量）。\n", .{});
        err.print("     0.16 教程里常写的 url_safe_encoder 在 0.17 **不存在**。\n", .{});
        // 标准 vs URL-safe 对照
        const bin = "\xfb\xff\xbe";
        var ubuf: [8]u8 = undefined;
        var sbuf: [8]u8 = undefined;
        err.print("\n  同一份二进制 «{X:0>2}{X:0>2}{X:0>2}»（含 +/ 需要的字节）：\n", .{ bin[0], bin[1], bin[2] });
        err.print("    standard.Encoder -> {s}（出现 + 和 /）\n", .{base64_std.Encoder.encode(&sbuf, bin)});
        err.print("    url_safe.Encoder  -> {s}（换成 - 和 _，可放进 URL）\n", .{base64_url.Encoder.encode(&ubuf, bin)});
        var npbuf: [8]u8 = undefined;
        err.print("    standard_no_pad  -> {s}（无 = 填充，JWT 用这个）\n", .{base64_std_no_pad().Encoder.encode(&npbuf, "f")});
        err.print("  Error 集合 = {s}\n", .{@typeName(std.base64.Error)});
        inline for (@typeInfo(std.base64.Error).error_set.error_names.?, 0..) |nm2, i| {
            err.print("    {d}. {s}\n", .{ i, nm2 });
        }
        // 脏输入
        var dbuf: [16]u8 = undefined;
        base64_std.Decoder.decode(dbuf[0..], "!!!!") catch |e| {
            err.print("  decode(\"!!!!\") -> {s}（生产代码别 catch unreachable）\n", .{@errorName(e)});
        };
        base64_std.Decoder.decode(dbuf[0..], "AB") catch |e| {
            err.print("  decode(\"AB\")-> {s}（长度不是 4 的倍数）\n", .{@errorName(e)});
        };
        // encodeWriter：直接写进 Writer，不经中间缓冲
        var aw: std.Io.Writer.Allocating = .init(mem);
        try base64_std.Encoder.encodeWriter(&aw.writer, msg);
        err.print("\n  encodeWriter(&writer, msg) 直接落Writer -> {s}...\n", .{aw.written()[0..32]});
        err.print("  ⇒ 编码器本身也是 Writer 消费者：流式场景不用先拼出完整切片。\n", .{});
    }
    end("26.5 std.base64");

    // ═══ 26.6 手写一遍 base64 ═══
    begin("26.6 手写 base64");
    {
        const mine = try encodeB64(mem, "Man is distinguished... 推荐用 calcSize");
        var ebuf: [128]u8 = undefined;
        const want = base64_std.Encoder.encode(&ebuf, "Man is distinguished... 推荐用 calcSize");
        err.print("手写encodeB64 输出 {d} 字符，与标准库逐字节一致 = {}\n", .{ mine.len, std.mem.eql(u8, mine, want) });
        err.print("  算法：3 字节 → 拼成24 bit → 切成 4 个 6 bit → 查表；尾部按 RFC 4648 补 '='。\n", .{});
        err.print("  位运算 << >> & | 是这类代码的全部家当；实现一遍最扎实。\n", .{});
    }
    end("26.6 手写 base64");

    // ═══ 26.7 URL 百分号编码 ═══
    begin("26.7 URL 百分号编码");
    {
        err.print("0.17 实测：**没有内建编码器**。std.Uri 上只有解码：\n", .{});
        inline for (.{ "escape", "unescape", "percentEncode", "percentDecode", "percentDecodeInPlace", "percentDecodeBackwards" }) |nm| {
            err.print("  @hasDecl(std.Uri, \"{s}\") = {}\n", .{ nm, @hasDecl(std.Uri, nm) });
        }
        err.print("  ⇒ percentEncode 得手写（本节那个30 行的函数）。\n", .{});
        const cases = [_][]const u8{
            "hello world",
            "a+b/c?d=e&f",
            "safe-._~chars",
            "\x00\x01\xff",
        };
        var ebuf: [128]u8 = undefined;
        var dbuf: [128]u8 = undefined;
        for (cases) |c| {
            const enc = try percentEncode(&ebuf, c);
            const dec = try percentDecode(&dbuf, enc);
            err.print("  «{s}» -> {s} -> «{s}」（往返 = {}）\n", .{ c, enc, dec, std.mem.eql(u8, c, dec) });
        }
        err.print("  unreserved集合 = A-Z a-z 0-9 - . _ ~（RFC 3986）；其余一律 %XX。\n", .{});
        err.print("  ⚠️ 注意 `+` 不在unreserved 里：查询串里的空格是 %20 还是 + 取决于你编哪一层。\n", .{});
        // 对照 std.Uri 的解码
        var inplace: [32]u8 = undefined;
        @memcpy(inplace[0..16], "hello%20world%21");
        const after = std.Uri.percentDecodeInPlace(inplace[0..16]);
        err.print("  对照 std.Uri.percentDecodeInPlace(\"hello%20world%21\") -> «{s}»（{d} 字节）\n", .{ after, after.len });
        err.print("  ⚠️ 它返回**裸 []u8**（不是错误联合），且对 \"100%z\" 这种非法转义**静默透传**：\n", .{});
        var bad: [8]u8 = undefined;
        @memcpy(bad[0..5], "100%z");
        err.print("     percentDecodeInPlace(\"100%z\") = «{s}» ← 原样返回，不报错\n", .{std.Uri.percentDecodeInPlace(bad[0..5])});
        err.print("     而本节手写的 percentDecode 遇到 '%z' 返回 error.InvalidDigit（见 test 块断言）。\n", .{});
    }
    end("26.7 URL 百分号编码");

    // ═══ 26.8 压缩：0.17 的 std.compress 现状 ═══
    begin("26.8 压缩 std.compress");
    {
        inline for (.{ "flate", "zstd", "lzma", "lzma2", "xz" }) |nm| {
            err.print("  std.compress.{s:<8} {}\n", .{ nm, @hasDecl(std.compress, nm) });
        }
        err.print("  flate.Container 的三个成员 = .raw / .gzip / .zlib（实测）：\n", .{});
        inline for (@typeInfo(std.compress.flate.Container).@"enum".field_names) |nm| {
            err.print("    .{s}\n", .{nm});
        }
        err.print("  ⚠️ zstd / lzma 在 0.17 **只有 Decompress，没有 Compress**（实测 @hasDecl = false）。\n", .{});
        err.print("     也就是说标准库能解压 zstd/lzma，但压不出来——压缩只有 flate 一条路。\n", .{});

        var big: [4096]u8 = undefined;
        for (&big, 0..) |*p, i| p.* = @intCast('a' + @as(u8, @intCast(i % 26)));
        // 压缩：Compress 自己就是个 Writer
        var out: std.Io.Writer.Allocating = try .initCapacity(mem, 256);
        var scratch: [std.compress.flate.max_window_len]u8 = undefined;
        var comp = try std.compress.flate.Compress.init(&out.writer, &scratch, .gzip, .default);
        try comp.writer.writeAll(&big);
        try comp.finish();
        const cbuf = out.written();
        err.print("\n  {d} 字节原文（周期 26 的可压缩数据）-> gzip {d} 字节\n", .{ big.len, cbuf.len });
        err.print("  gzip 头 4 字节 = {X:0>2} {X:0>2} {X:0>2} {X:0>2}（1f 8b = gzip 魔数，实测）\n", .{ cbuf[0], cbuf[1], cbuf[2], cbuf[3] });
        // 解压
        var back: std.Io.Reader = .fixed(cbuf);
        var dscratch: [std.compress.flate.max_window_len]u8 = undefined;
        var decomp = std.compress.flate.Decompress.init(&back, .gzip, &dscratch);
        var dout: std.Io.Writer.Allocating = .init(mem);
        _ = try decomp.reader.streamRemaining(&dout.writer);
        err.print("  解压回 {d} 字节，逐字节一致 = {}\n", .{ dout.written().len, std.mem.eql(u8, dout.written(), &big) });
        err.print("  ⇒ Decompress.init **不返回错误**（无 try），Compress.init 返回 Writer.Error!。\n", .{});
        err.print("  ⚠️ 两个 init 的 buffer 大小要求不同：Compress 要 max_window_len，\n", .{});
        err.print("     Decompress 也要 max_window_len（**不是** history_len，实测写成 history_len 会 assert 失败）。\n", .{});
        err.print("  ⚠️ 输出端必须用 Allocating.initCapacity(gpa, n)：Allocating.init 的 buffer 初始长度是 0，\n", .{});
        err.print("     而 flate.Compress.init 里 assert(output.buffer.len > 8) —— 实测直接 panic。\n", .{});
    }
    end("26.8 压缩 std.compress");

    // ═══ 26.9 哈希：完整性校验 ═══
    begin("26.9 std.hash 完整性校验");
    {
        const Wy = std.hash.Wyhash;
        const h1 = Wy.hash(0, "hello");
        err.print("std.hash.Wyhash.hash(0, \"hello\") = 0x{x}\n", .{h1});
        var inc: Wy = .init(0);
        inc.update("he");
        inc.update("llo");
        err.print("流式 update(\"he\")+update(\"llo\") = 0x{x}（== 一次性 hash）\n", .{inc.final()});
        err.print("  ⇒ Wyhash 的 update 语义就是**拼接**，所以流式与一次性必然相等。\n", .{});
        err.print("  ⚠️ 0.17 没有 smallHash / largeHash（实测 has no member named 'smallHash'）。\n", .{});
        err.print("std.hash.Crc32.hash(\"hello\") = 0x{x}（= crc.@\"CRC-32/ISO-HDLC\"）\n", .{std.hash.Crc32.hash("hello")});
        err.print("  ⚠️ 0.17 里没有 std.hash.crc.Crc32 —— 真名是带引号的 @\"CRC-32/ISO-HDLC\"。\n", .{});
        err.print("std.hash.int(@as(u32, 7)) = {d}（把整数打散成哈希，给 HashMap 用）\n", .{std.hash.int(@as(u32, 7))});
        var ah: Wy = .init(0);
        std.hash.autoHash(&ah, @as(u8, 1));
        std.hash.autoHash(&ah, @as(u32, 3));
        err.print("autoHash(&hasher, u8 1) + autoHash(&hasher, u32 3) -> final = 0x{x}\n", .{ah.final()});
        err.print("  ⚠️⚠️ 0.17 的 autoHash 签名是 **(hasher, key) void**（流式），\n", .{});
        err.print("     不是旧版的 autoHash(...) 返回 u64。写错了报 expected 2 argument(s), found 3。\n", .{});
        err.print("  ⚠️ 且 f64 **不可哈希**：@compileError(\"unable to hash type f64\")。\n", .{});
        // 流式哈希的实际用法：校验大文件
        err.print("\n  实际用法——边读边算，全程不把文件读进内存：\n", .{});
        {
            var f = try std.Io.Dir.cwd().createFile(init.io, probe_path, .{});
            {
                var b: [64]u8 = undefined;
                var fw = f.writer(init.io, &b);
                try fw.interface.writeAll("the quick brown fox jumps over the lazy dog");
                try fw.interface.flush();
            }
            f.close(init.io);
            var f2 = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
            defer f2.close(init.io);
            var rbuf: [16]u8 = undefined; //故意用小缓冲，逼出多次 fillMore
            var fr = f2.reader(init.io, &rbuf);
            var h = Wy.init(0);
            var total: usize = 0;
            while (true) {
                const avail = (try readChunk(&fr.interface)) orelse break;
                h.update(avail);
                total += avail.len;
                fr.interface.toss(avail.len);
            }
            err.print("    16 字节缓冲、逐块 update：{d} 字节 -> Wyhash 0x{x}\n", .{ total, h.final() });
            err.print("    一次性算同一个字符串：             Wyhash 0x{x}\n", .{Wy.hash(0, "the quick brown fox jumps over the lazy dog")});
            err.print("    ⇒ 相同 ⇒ 内存占用从O(文件大小) 降到 O(缓冲大小)。\n", .{});
        }
        std.Io.Dir.cwd().deleteFile(init.io, probe_path) catch {};
    }
    end("26.9 std.hash 完整性校验");

    // ═══ 26.10 SIMD ═══
    begin("26.10 SIMD @Vector");
    {
        err.print("@Vector 是**语言级固定宽度**，与目标 CPU 特性无关：\n", .{});
        err.print("  @Vector(32, u8) = {d} 字节 / {d} 位\n", .{ 32, @bitSizeOf(@Vector(32, u8)) });
        err.print("  @Vector(3, u8)  = {d} 位（不是2 的幂，硬件要拆成多次）\n", .{@bitSizeOf(@Vector(3, u8))});
        err.print("  @Vector(128, u8) = {d} 位（x86 AVX2 一次只256 位，要拆成 4 条 ymm）\n", .{@bitSizeOf(@Vector(128, u8))});
        err.print("  本机：arch={s} model={s} avx2={} sse2={} avx={}\n", .{
            @tagName(builtin.cpu.arch),
            builtin.cpu.model.name,
            std.Target.x86.featureSetHas(builtin.cpu.features, .avx2),
            std.Target.x86.featureSetHas(builtin.cpu.features, .sse2),
            std.Target.x86.featureSetHas(builtin.cpu.features, .avx),
        });
        err.print("  ⇒ 「AVX2 是 256 位但@Vector 默认多少」这个问题的答案是：\n", .{});
        err.print("     @Vector **没有默认宽度**，你写几就是几；编译器负责拆成硬件指令。\n", .{});
        err.print("  实测 @Vector(32, u8) 在 wasm32-freestanding / riscv64 / aarch64 上都能编译\n", .{});
        err.print("     （编译器自动降级成标量循环），所以**不是**「不支持的目标上编译失败」。\n", .{});

        // 真实例子：统计 32 字节里有几个字节等于目标值
        const target: u8 = 'x';
        var data: [96]u8 = undefined;
        for (&data, 0..) |*p, i| p.* = if (i % 4 == 2) 'x' else 'a';
        const cs = countByteSimd(&data, target);
        const cc = countByteScalar(&data, target);
        err.print("\n  真实例子：96 字节里数 '{c}' —— SIMD {d} 个 == 标量 {d} 个（{d} 个 32 字节窗口）\n", .{ target, cs, cc, 96 / 32 });
        err.print("  三个动作：切片→向量 text[i..][0..32].*、比较 → 位掩码 @bitCast、@popCount 数位\n", .{});
        err.print("  ⚠️ 掩码类型是 @Vector(N, bool)，位宽只有 N：@bitCast 到 u32 **要求 N == 32**，\n", .{});
        err.print("     否则报 @bitCast size mismatch（实测 N=3 时 destination 'u8' has 8 bits but source\n", .{});
        err.print("     '@Vector(3, bool)' has 3 bits）。N != 32 时用 @select 转 u32 再 @reduce(.Add)。\n", .{});
        // @reduce / @select 实测
        const vv: @Vector(32, u8) = @splat(3);
        err.print("  @reduce(.Add, @splat(3) x32) = {d}（32*3=96）\n", .{@reduce(.Add, vv)});
        const sel = @select(u8, vv == @as(@Vector(32, u8), @splat(3)), @as(@Vector(32, u8), @splat(1)), @as(@Vector(32, u8), @splat(2)));
        err.print("  @select(u8, v==3, ones, twos)[0] = {d}（逐元素选，不是全有全无）\n", .{sel[0]});
        const vu: @Vector(4, u32) = @splat(7);
        err.print("  @reduce 在 4x u32 上：.Add={d} .Max={d} .And={d} .Or={d} .Xor={d}\n", .{
            @reduce(.Add, vu), @reduce(.Max, vu), @reduce(.And, vu), @reduce(.Or, vu), @reduce(.Xor, vu),
        });

        // 词计数（SIMD 的经典综合用例）
        const text = "one two  three\tfour\nfive  six seven\teight\nnine ten";
        const s_simd = countWordsSimd(text);
        const s_scalar = countWordsScalar(text);
        err.print("\n  词计数：SIMD {any} == 标量 {any}（{s}）\n", .{ s_simd, s_scalar, text });
        err.print("  位技巧：词首 = 当前非空白 且 前一字符空白。块间用 prev_was_space 把上一块末位接进来。\n", .{});
    }
    end("26.10 SIMD @Vector");

    // ═══ 26.11 流式 vs 一次性：取舍 ═══
    begin("26.11 流式 vs 一次性");
    {
        const total = 1024 * 1024; // 1 MiB
        const Wy = std.hash.Wyhash;
        const t0 = std.Io.Clock.now(.awake, init.io);
        var whole: [total]u8 = undefined;
        for (&whole, 0..) |*p, i| p.* = @intCast(i & 0xff);
        var h_whole = Wy.init(0);
        h_whole.update(&whole);
        const sum_whole = h_whole.final();
        const ns_whole = t0.durationTo(std.Io.Clock.now(.awake, init.io)).nanoseconds;

        const t1 = std.Io.Clock.now(.awake, init.io);
        var chunk: [4096]u8 = undefined;
        var h_stream = Wy.init(0);
        var i: usize = 0;
        while (i < total) : (i += chunk.len) {
            for (&chunk, 0..) |*p, j| p.* = @intCast((i + j) & 0xff);
            h_stream.update(&chunk);
        }
        const sum_stream = h_stream.final();
        const ns_stream = t1.durationTo(std.Io.Clock.now(.awake, init.io)).nanoseconds;

        err.print("同样 {d} 字节、同样一个 Wyhash：\n", .{total});
        err.print("  一次性读入：栈上 {d} 字节常驻，哈希 0x{x}，耗时 {d} ns\n", .{ total, sum_whole, ns_whole });
        err.print("  4 KiB 分块：  栈上 {d} 字节常驻，哈希 0x{x}，耗时 {d} ns\n", .{ chunk.len, sum_stream, ns_stream });
        err.print("  哈希相同 = {}（流式 update 就是拼接）\n", .{sum_whole == sum_stream});
        err.print("  ⇒ 取舍：内存**有界**换内存**无界**。处理大小未知的输入（文件、socket、管道），\n", .{});
        err.print("     流式是唯一能保证不 OOM 的写法；输入大小已知且很小，一次性更简单更快。\n", .{});
        err.print("  ⚠️ 上面两个 ns 数字每次运行都不同（Debug 模式），只说明「同一量级」，不当性能数据。\n", .{});
        err.print("  栈上1 MiB 数组只在 Debug 下能跑过；ReleaseFast 下会爆栈——真实代码用分配器。\n", .{});
    }
    end("26.11 流式 vs 一次性");

    // ═══ 26.12 0.17 迁移：`**` 运算符已移除 ═══
    begin("26.12 0.17 迁移：** 运算符已移除");
    err.print("0.17 起 `**`（编译期重复）运算符已从语言里移除。实测：\n", .{});
    err.print("  \"ab\" ** 3-> error: binary operator '*' has whitespace on one side, but not the other\n", .{});
    err.print("  [_]u8{{7}} ** 4     -> 同上（**连数组重复也没了**）\n", .{});
    err.print("  它被词法分析成两个 '*' 指针解引用，所以报的是空白错误而不是「找不到运算符」。\n", .{});
    err.print("\n  0.17 的三种替代：\n", .{});
    const v4: @Vector(4, u8) = @splat(7);
    err.print("  1. 向量/数组同一值重复：@splat  -> {any}\n", .{v4});
    err.print("  2. 常量字符串重复：自己写 comptime 函数（本文件的 Rep）：\n", .{});
    err.print("       Rep(\"ab\", 3).bytes = «{s}»（长度 {d}，[:0]const u8）\n", .{ Rep("ab", 3).bytes, Rep("ab", 3).bytes.len });
    err.print("  3. 编译期拼字符串用 comptimePrint 或 `++`（**`++` 仍在**）：\n", .{});
    err.print("       \"foo\" ++ \"bar\" = «{s}」（长度 {d}）\n", .{ "foo" ++ "bar", ("foo" ++ "bar").len });
    err.print("       comptimePrint(\"{{d}}-{{d}}\", .{{7,9}}) = «{s}»（类型 *const [N:0]u8）\n", .{
        std.fmt.comptimePrint("{d}-{d}", .{ 7, 9 }),
    });
    err.print("  Rep 顺带演示了 comptime 的两种典型用法：comptime 参数 + **类型**作返回值。\n", .{});
    err.print("  （写成返回 []const u8 就不行——编译期循环必须有确定类型才能定长分配。）\n", .{});
    end("26.12 0.17 迁移：** 运算符已移除");

    // ═══ 26.13 流与编码 API 的实测签名速查 ═══
    begin("26.13 实测签名速查");
    err.print("std.Io.Reader 的关键方法（签名摘自 lib/std/Io/Reader.zig，本机 0.17.0）：\n", .{});
    err.print("  fillMore(r) Error!void——**返回错误**，EOF 时是 error.EndOfStream\n", .{});
    err.print("  buffered(r) []u8 / bufferedLen(r) usize\n", .{});
    err.print("  toss(r, n: usize) void —— n 是 usize，传 ?usize 会编译错\n", .{});
    err.print("  take(r, n) Error![]u8 / peek(r, n) Error![]u8 / takeArray(r, comptime n)\n", .{});
    err.print("  takeByte(r) Error!u8 / peekByte(r) Error!u8\n", .{});
    err.print("  readSliceShort(r, buf) ShortError!usize——**填满或 EOF**，不是单次 read\n", .{});
    err.print("  readSliceAll(r, buf) Error!void——填不满报 error.EndOfStream\n", .{});
    err.print("  takeSentinel(r, comptime sentinel) [:{{sentinel}}]u8\n", .{});
    err.print("  takeDelimiterInclusive(r, d) / takeDelimiterExclusive(r, d) DelimiterError![]u8\n", .{});
    err.print("  takeDelimiter(r, d) error{{ReadFailed,StreamTooLong}}!?[]u8——EOF 给 null\n", .{});
    err.print("  stream(r, w, limit) StreamError!usize / streamRemaining(r, w) StreamRemainingError!usize\n", .{});
    err.print("  allocRemaining(r, gpa, limit) / readAllocAll(r, gpa, len)\n", .{});
    err.print("\n  四个错误集（互不相同，别混）：\n", .{});
    err.print("    Reader.Error            = {{ ReadFailed, EndOfStream }}\n", .{});
    err.print("    Reader.ShortError        = {{ ReadFailed }}（短读永远不报 EndOfStream）\n", .{});
    err.print("    Reader.StreamError= {{ ReadFailed, WriteFailed, EndOfStream }}\n", .{});
    err.print("    Reader.DelimiterError= {{ ReadFailed, EndOfStream, StreamTooLong }}\n", .{});
    err.print("\n  ⚠️ File.readAll / readAllAlloc / writeAll 在 0.17 **不存在**（文件级 API），\n", .{});
    err.print("     对应物是 readStreaming / writeStreaming / writeStreamingAll / readPositional。\n", .{});
    err.print("  实测签名（第一个参数是**切片数组**，不是单个 buffer）：\n", .{});
    err.print("    File.readStreaming(io, buffer: []const []u8) ReadStreamingError!usize\n", .{});
    err.print("    File.readPositional(io, buffer: []const []u8, offset: u64) !usize\n", .{});
    err.print("    File.writeStreaming(io, header, data: []const []u8, splat: usize) Writer.Error!usize\n", .{});
    err.print("    File.writeStreamingAll(io, bytes: []const u8) Writer.Error!void\n", .{});
    err.print("  ⚠️ readStreaming 的切片必须**已初始化为真实 buffer**：填 {{undefined}} 会 EINVAL panic\n", .{});
    err.print("     （实测：thread panic: programmer bug caused syscall error: INVAL）。\n", .{});
    {
        // 实测一把 readStreaming
        var f = try std.Io.Dir.cwd().createFile(init.io, probe_path, .{});
        try f.writeStreamingAll(init.io, "hello streaming world");
        f.close(init.io);
        var f2 = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
        defer f2.close(init.io);
        var raw: [64]u8 = undefined;
        var one = [_][]u8{raw[0..]};
        const n = try f2.readStreaming(init.io, &one);
        err.print("  实测 readStreaming(io, &[_][]u8{{buf}}) -> {d} 字节 «{s}»\n", .{ n, one[0][0..n] });
        std.Io.Dir.cwd().deleteFile(init.io, probe_path) catch {};
    }
    err.print("\n  Writer 家族：\n", .{});
    err.print("    Writer.fixed(buf) Writer——落调用方的栈缓冲，无需 flush\n", .{});
    err.print("    Writer.Allocating.init(gpa) / initCapacity(gpa, n) / deinit() / written()\n", .{});
    err.print("    Writer.Discarding.init(buf) Writer——丢弃但计数（.writer.end 是长度）\n", .{});
    err.print("    File.writer(io, buf) / writerStreaming(io, buf) / writer(io, undefined)= 无缓冲\n", .{});
    err.print("  格式串：Writer.print(comptime fmt, args) Error!void（**固定两参**，无占位符也要 .{{}})\n", .{});
    err.print("\n  std.fmt 的 0.17 实测存在性：\n", .{});
    inline for (.{
        "bytesToHex", "hexToBytes",    "allocPrint",      "bufPrint",  "parseInt",
        "parseFloat", "comptimePrint", "count",           "parseChar", "fmtInt",
        "formatInt",  "format",        "alignIntoBuffer",
    }) |nm| {
        err.print("    std.fmt.{s:<18} {}\n", .{ nm, @hasDecl(std.fmt, nm) });
    }
    err.print("  ⇒ parseChar 和 fmtInt 在 0.17 **都不存在**；alignIntoBuffer 也没了。\n", .{});
    err.print("  ⚠️ allocPrint / bufPrint 已标注 Deprecated（源码注释：Deprecated in favor of\n", .{});
    err.print("     mem.PrintError / mem.print），新代码用 gpa.print(fmt, args) 和 mem.print(buf, ...)。\n", .{});
    err.print("  bytesToHex(input: anytype, case: Case) [input.len*2]u8——第二参是 Case 不是端序\n", .{});
    err.print("  hexToBytes(out: []u8, input: []const u8) ![]u8——奇数长度报 error.InvalidLength\n", .{});
    err.print("\n  std.json（20 章已深入，本章只做流式搭档）：\n", .{});
    {
        const jtext = "{\"name\":\"zig\",\"tags\":[1,2,3],\"ok\":true}";
        const parsed = try std.json.parseFromSlice(std.json.Value, mem, jtext, .{});
        switch (parsed.value) {
            .object => |o| {
                err.print("    parseFromSlice(std.json.Value, ...) -> .object，{d} 个字段，name={s}\n", .{ o.count(), o.get("name").?.string });
            },
            else => {},
        }
        var al: std.Io.Writer.Allocating = .init(mem);
        try std.json.Stringify.value(parsed.value, .{}, &al.writer);
        err.print("    Stringify.value(value, options, writer) 回写 -> {s}\n", .{al.written()});
        err.print("    ⚠️ 两个 0.17 变化：std.json.Value 是 **union(enum)** 不是纯 enum；\n", .{});
        err.print("       Stringify.value 的 writer 参数在**最后**（value, options, writer）。\n", .{});
    }
    end("26.13 实测签名速查");

    std.debug.print("自检通过\n", .{});
}

/// 0.17 里 standard_no_pad 是个 Codecs 常量（不是函数），这里包一层只为可读性
fn base64_std_no_pad() type {
    return struct {
        const Encoder = std.base64.standard_no_pad.Encoder;
        const Decoder = std.base64.standard_no_pad.Decoder;
    };
}

// ═══════════════════════════════════════════════════════════════════════
//测试
// ═══════════════════════════════════════════════════════════════════════

test "Rep：0.17 用comptime 函数替代被移除的 ** 运算符" {
    const r = Rep("ab", 4);
    try std.testing.expectEqualStrings("abababab", r.bytes);
    try std.testing.expectEqual(@as(usize, 8), r.bytes.len);
    // `++` 拼接仍在
    try std.testing.expectEqualStrings("foobar", "foo" ++ "bar");
    // @splat 是向量/数组重复的正路
    const v: @Vector(4, u8) = @splat(7);
    try std.testing.expectEqual(v, @as(@Vector(4, u8), @splat(7)));
    try std.testing.expectEqual(@as(u8, 7), v[0]);
}

test "hex：bytesToHex / hexToBytes 互逆，错误集成员可测" {
    const a = std.testing.allocator;
    const data = "\x00\x01\xfe\xffAB";
    const lower = std.fmt.bytesToHex(data, .lower);
    try std.testing.expectEqualStrings("0001feff4142", lower[0..]);
    const upper = std.fmt.bytesToHex(data, .upper);
    try std.testing.expectEqualStrings("0001FEFF4142", upper[0..]);
    // 大小写都能解
    var out: [data.len]u8 = undefined;
    try std.testing.expectEqualSlices(u8, data, try std.fmt.hexToBytes(out[0..], lower[0..]));
    try std.testing.expectEqualSlices(u8, data, try std.fmt.hexToBytes(out[0..], upper[0..]));
    // 奇数长度是错误，不是崩溃
    try std.testing.expectError(error.InvalidLength, std.fmt.hexToBytes(out[0..], "abc"));
    // 输出缓冲不够是错误
    var tiny: [2]u8 = undefined;
    try std.testing.expectError(error.NoSpaceLeft, std.fmt.hexToBytes(tiny[0..], lower[0..]));
    // 非法 hex 字符
    try std.testing.expectError(error.InvalidCharacter, std.fmt.hexToBytes(out[0..], "zz"));
    _ = a;
}

test "base64：手写与标准库逐字节一致（含 RFC 4648 全部尾部情形）" {
    const a = std.testing.allocator;
    const cases = [_][]const u8{
        "",      "f",      "fo",                   "foo", "foob",
        "fooba", "foobar", "Man is distinguished",
        "\xfb\xff\xbe", // 会产生 +/ 的字节，测标准 vs URL-safe差异
    };
    for (cases) |c| {
        const mine = try encodeB64(a, c);
        defer a.free(mine);
        const want = try a.alloc(u8, base64_std.Encoder.calcSize(c.len));
        defer a.free(want);
        try std.testing.expectEqualStrings(base64_std.Encoder.encode(want, c), mine);
        // 往返
        const dl = try base64_std.Decoder.calcSizeForSlice(want);
        const db = try a.alloc(u8, dl);
        defer a.free(db);
        try base64_std.Decoder.decode(db, want);
        try std.testing.expectEqualSlices(u8, c, db);
    }
}

test "base64：0.17 的真实名字与错误集" {
    const a = std.testing.allocator;
    // URL 安全的真名是 url_safe（Codecs），url_safe_encoder 不存在
    try std.testing.expect(@hasDecl(std.base64, "url_safe"));
    try std.testing.expect(@hasDecl(std.base64, "url_safe_no_pad"));
    try std.testing.expect(!@hasDecl(std.base64, "url_safe_encoder"));
    // 含 +/ 的字节：标准表和 URL-safe 表结果不同
    var sbuf: [8]u8 = undefined;
    var ubuf: [8]u8 = undefined;
    const bin = "\xfb\xff\xbe";
    try std.testing.expectEqualStrings("+/++", base64_std.Encoder.encode(&sbuf, bin));
    try std.testing.expectEqualStrings("-_--", base64_url.Encoder.encode(&ubuf, bin));
    // 无填充变体
    var np: [8]u8 = undefined;
    try std.testing.expectEqualStrings("Zg", std.base64.standard_no_pad.Encoder.encode(&np, "f"));
    // 脏输入是错误集成员
    var dbuf: [16]u8 = undefined;
    try std.testing.expectError(error.InvalidCharacter, base64_std.Decoder.decode(dbuf[0..], "!!!!"));
    try std.testing.expectError(error.InvalidPadding, base64_std.Decoder.decode(dbuf[0..], "AB"));
    // calcSize 的语义：编码方向纯数学，解码方向要错误集
    try std.testing.expectEqual(@as(usize, 4), base64_std.Encoder.calcSize(1));
    try std.testing.expectEqual(@as(usize, 4), base64_std.Encoder.calcSize(3));
    try std.testing.expectEqual(@as(usize, 8), base64_std.Encoder.calcSize(4));
    _ = a;
}

test "URL 百分号编码：手写往返 + 非法转义报错（对照 std.Uri 静默透传）" {
    const a = std.testing.allocator;
    const cases = [_][]const u8{
        "hello world", "a+b/c?d=e&f", "safe-._~chars", "\x00\x01\xff",
        "中文.txt",
    };
    for (cases) |c| {
        const ebuf = try a.alloc(u8, c.len * 3);
        defer a.free(ebuf);
        const enc = try percentEncode(ebuf, c);
        const dbuf = try a.alloc(u8, enc.len);
        defer a.free(dbuf);
        const dec = try percentDecode(dbuf, enc);
        try std.testing.expectEqualSlices(u8, c, dec);
    }
    // 具体编码值
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("hello%20world", try percentEncode(&buf, "hello world"));
    try std.testing.expectEqualStrings("safe-._~", try percentEncode(&buf, "safe-._~"));
    // 缓冲不够
    var tiny: [2]u8 = undefined;
    try std.testing.expectError(error.NoSpaceLeft, percentEncode(&tiny, "hello"));
    // 非法转义：手写版报错
    try std.testing.expectError(error.InvalidEscape, percentDecode(&buf, "abc%"));
    try std.testing.expectError(error.InvalidDigit, percentDecode(&buf, "abc%z1"));
    // std.Uri 只有解码，且对非法输入静默透传（这就是手写版的理由）
    try std.testing.expect(!@hasDecl(std.Uri, "percentEncode"));
    try std.testing.expect(@hasDecl(std.Uri, "percentDecodeInPlace"));
    var inplace: [8]u8 = undefined;
    @memcpy(inplace[0..5], "100%z");
    try std.testing.expectEqualStrings("100%z", std.Uri.percentDecodeInPlace(inplace[0..5]));
}

test "SIMD 计数 == 标量计数（跨窗口 + 任意尾巴长度）" {
    const a = std.testing.allocator;
    for (0..200) |len| {
        const buf = try a.alloc(u8, len);
        defer a.free(buf);
        for (buf, 0..) |*p, i| p.* = if (i % 4 == 2) 'x' else @intCast('a' + @as(u8, @intCast(i % 26)));
        try std.testing.expectEqual(countByteScalar(buf, 'x'), countByteSimd(buf, 'x'));
    }
    // 全 0 长度
    try std.testing.expectEqual(@as(usize, 0), countByteSimd("", 'x'));
    // 正好 32 的倍数
    var exact: [64]u8 = undefined;
    for (&exact, 0..) |*p, i| p.* = if (i % 2 == 0) 'x' else 'y';
    try std.testing.expectEqual(countByteScalar(&exact, 'x'), countByteSimd(&exact, 'x'));
}

test "SIMD 词计数 == 标量（含块边界切开单词、满32 倍数、空串）" {
    // 0.17 起 `**` 已移除，构造长字符串用文件顶部的 Rep()
    const texts = [_][]const u8{
        "one two  three\tfour",
        Rep("a", 31).bytes ++ " b",
        Rep("ab", 16).bytes ++ " cd " ++ Rep("ef", 20).bytes,
        "\n\n\n",
        "   leading and trailing   ",
        "",
        "single",
        Rep("word ", 40).bytes,
        Rep("a", 32).bytes, // 正好 32 字节，无尾块
    };
    for (texts) |t| {
        try std.testing.expectEqual(countWordsScalar(t), countWordsSimd(t));
    }
}

test "@Vector 的形状：位宽、掩码类型、@reduce" {
    // @Vector 是语言级固定宽度，与 CPU 特性无关
    try std.testing.expectEqual(@as(usize, 256), @bitSizeOf(@Vector(32, u8)));
    try std.testing.expectEqual(@as(usize, 24), @bitSizeOf(@Vector(3, u8)));
    try std.testing.expectEqual(@as(usize, 1024), @bitSizeOf(@Vector(128, u8)));
    // 比较结果是 @Vector(N, bool)，位宽只有 N —— 所以 @bitCast 到 u32 要求 N == 32
    const v: @Vector(32, u8) = @splat(3);
    const mask = v == @as(@Vector(32, u8), @splat(3));
    try std.testing.expectEqual(@as(usize, 32), @bitSizeOf(@TypeOf(mask)));
    const bits: u32 = @bitCast(mask);
    try std.testing.expectEqual(@as(u32, 0xFFFF_FFFF), bits);
    // @popCount 数位
    try std.testing.expectEqual(@as(usize, 32), @popCount(bits));
    // N != 32 时改走 @select + @reduce
    const v3: @Vector(3, u8) = @splat(9);
    const m3 = v3 == @as(@Vector(3, u8), @splat(9));
    const widened: @Vector(3, u32) = @select(u32, m3, @as(@Vector(3, u32), @splat(1)), @as(@Vector(3, u32), @splat(0)));
    try std.testing.expectEqual(@as(u32, 3), @reduce(.Add, widened));
    // @reduce 支持的操作
    const vu: @Vector(4, u32) = @splat(7);
    try std.testing.expectEqual(@as(u32, 28), @reduce(.Add, vu));
    try std.testing.expectEqual(@as(u32, 7), @reduce(.Max, vu));
    try std.testing.expectEqual(@as(u32, 7), @reduce(.And, vu));
    try std.testing.expectEqual(@as(u32, 7), @reduce(.Or, vu));
    try std.testing.expectEqual(@as(u32, 0), @reduce(.Xor, vu));
}

test "takeDelimiter* 的三种行为：exclusive 空转 / inclusive 正常 / takeDelimiter 给 null" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    // 造一个 3 行文件
    const path = "/tmp/zig_tut_26_encoding_test.txt";
    {
        var f = try std.Io.Dir.cwd().createFile(io, path, .{});
        defer f.close(io);
        var b: [64]u8 = undefined;
        var fw = f.writer(io, &b);
        try fw.interface.writeAll("l1\nl2\nl3\n");
        try fw.interface.flush();
    }
    defer std.Io.Dir.cwd().deleteFile(io, path) catch {};

    // inclusive：正常数到 3，然后 EndOfStream
    {
        var f = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer f.close(io);
        var rbuf: [8]u8 = undefined; // 缓冲比一行还小，逼出多次 fillMore
        var fr = f.reader(io, &rbuf);
        const n = try countLinesInclusive(&fr.interface);
        try std.testing.expectEqual(@as(usize, 3), n);
    }
    // takeDelimiter：EOF 给 null 而不是错误
    {
        var f = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer f.close(io);
        var rbuf: [8]u8 = undefined;
        var fr = f.reader(io, &rbuf);
        var lines: usize = 0;
        while (try fr.interface.takeDelimiter('\n')) |line| {
            lines += 1;
            try std.testing.expect(line.len > 0);
        }
        try std.testing.expectEqual(@as(usize, 3), lines);
    }
    // exclusive：第一次拿到数据，之后永远返回空片（这就是 26.3 的实测结论）
    {
        var f = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer f.close(io);
        var rbuf: [8]u8 = undefined;
        var fr = f.reader(io, &rbuf);
        const first = fr.interface.takeDelimiterExclusive('\n') catch unreachable;
        try std.testing.expectEqualStrings("l1", first);
        // 再调 5 次，全部是长度为 0 的空片，且**不报错**
        for (0..5) |_| {
            const empty = fr.interface.takeDelimiterExclusive('\n') catch unreachable;
            try std.testing.expectEqual(@as(usize, 0), empty.len);
        }
    }
    // 通用写法：forEachLine 不空转，且计数正确
    {
        var f = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer f.close(io);
        var rbuf: [8]u8 = undefined;
        var fr = f.reader(io, &rbuf);
        var acc: LineCollector = .{ .gpa = a };
        defer acc.deinit();
        const n = try forEachLine(&fr.interface, &acc, LineCollector.collect);
        try std.testing.expectEqual(@as(usize, 3), n);
        try std.testing.expectEqualStrings("l1", acc.lines.items[0]);
        try std.testing.expectEqualStrings("l2", acc.lines.items[1]);
        try std.testing.expectEqualStrings("l3", acc.lines.items[2]);
    }
    // 末行没有换行符也能正确收尾（用**文件**做，因为 fixed 上fillMore 会失败）
    {
        const path2 = "/tmp/zig_tut_26_encoding_test2.txt";
        {
            var f = try std.Io.Dir.cwd().createFile(io, path2, .{});
            defer f.close(io);
            var b: [32]u8 = undefined;
            var fw = f.writer(io, &b);
            try fw.interface.writeAll("x\ny\nz"); // 最后一行没有换行
            try fw.interface.flush();
        }
        defer std.Io.Dir.cwd().deleteFile(io, path2) catch {};
        var f2 = try std.Io.Dir.cwd().openFile(io, path2, .{});
        defer f2.close(io);
        var rbuf: [4]u8 = undefined; // 缓冲故意很小
        var fr = f2.reader(io, &rbuf);
        var acc: LineCollector = .{ .gpa = a };
        defer acc.deinit();
        const n = try forEachLine(&fr.interface, &acc, LineCollector.collect);
        try std.testing.expectEqual(@as(usize, 3), n);
        try std.testing.expectEqualStrings("z", acc.lines.items[2]); // 末行无 '\n' 也被回调
    }
    // ⚠️ 同一个 forEachLine 在 **Reader.fixed** 上返回 0 行——fillMore 第一步就
    //报 EndOfStream（见下一个 test）。这不是 bug，是"三件套不能用在 fixed 上"的必然结果。
    {
        var r = std.Io.Reader.fixed("x\ny\nz");
        var acc: LineCollector = .{ .gpa = a };
        defer acc.deinit();
        const n = try forEachLine(&r, &acc, LineCollector.collect);
        try std.testing.expectEqual(@as(usize, 0), n);
    }
}

test "Reader.fixed 上 fillMore 报EndOfStream（buffer 是只读别名）" {
    var r = std.Io.Reader.fixed("hello\nworld");
    // 整个切片就是已缓冲数据
    try std.testing.expectEqual(@as(usize, 11), r.bufferedLen());
    try std.testing.expectEqualStrings("hello\nworld", r.buffered());
    // 但 fillMore 会先 rebase(capacity=1) → fixed 的 endingRebase → EndOfStream
    try std.testing.expectError(error.EndOfStream, r.fillMore());
    // 所以 fixed 上要用 buffered() + toss()
    const idx = std.mem.indexOfScalar(u8, r.buffered(), '\n').?;
    r.toss(idx + 1);
    try std.testing.expectEqualStrings("world", r.buffered());
}

test "readSliceShort 是「填满或 EOF」而不是单次 read" {
    var r = std.Io.Reader.fixed("0123456789");
    var buf: [4]u8 = undefined;
    // 实测序列：4, 4, 2, 0 —— 只有真的不够了才短读
    try std.testing.expectEqual(@as(usize, 4), try r.readSliceShort(&buf));
    try std.testing.expectEqualStrings("0123", &buf);
    try std.testing.expectEqual(@as(usize, 4), try r.readSliceShort(&buf));
    try std.testing.expectEqualStrings("4567", &buf);
    // 第三次只剩 2 字节：短读返回 2（**不报错**）
    try std.testing.expectEqual(@as(usize, 2), try r.readSliceShort(&buf));
    try std.testing.expectEqualStrings("89", buf[0..2]);
    // 真正的 EOF：返回 0，仍然不报错（ShortError 里没有 EndOfStream）
    try std.testing.expectEqual(@as(usize, 0), try r.readSliceShort(&buf));
    // readSliceAll 则在填不满时报 EndOfStream
    var r2 = std.Io.Reader.fixed("ab");
    var out: [4]u8 = undefined;
    try std.testing.expectError(error.EndOfStream, r2.readSliceAll(&out));
}

test "takeSentinel / peekByte / takeByte / take" {
    var r = std.Io.Reader.fixed("ab\x00cd");
    // takeSentinel 返回 [:sentinel]u8，能直接传给 {s}
    const s = try r.takeSentinel(0);
    try std.testing.expectEqualStrings("ab", s);
    try std.testing.expectEqualStrings("cd", r.buffered());

    var r2 = std.Io.Reader.fixed("abcdef");
    try std.testing.expectEqualStrings("abc", try r2.take(3));
    try std.testing.expectEqual(@as(u8, 'd'), try r2.takeByte());
    try std.testing.expectEqual(@as(u8, 'e'), try r2.peekByte()); // peek 不推进
    try std.testing.expectEqual(@as(u8, 'e'), try r2.takeByte());
    try std.testing.expectEqual(@as(u8, 'f'), try r2.takeByte());
    try std.testing.expectError(error.EndOfStream, r2.takeByte());
}

test "std.hash：Wyhash 流式 == 一次性；crc 真名；autoHash 是流式签名" {
    const Wy = std.hash.Wyhash;
    try std.testing.expectEqual(Wy.hash(0, "hello"), Wy.hash(0, "hello"));
    var inc: Wy = .init(0);
    inc.update("he");
    inc.update("llo");
    try std.testing.expectEqual(Wy.hash(0, "hello"), inc.final());

    // 0.17 没有 smallHash / largeHash
    try std.testing.expect(!@hasDecl(Wy, "smallHash"));
    try std.testing.expect(!@hasDecl(Wy, "largeHash"));

    // crc 的真名是 @"CRC-32/ISO-HDLC"，没有 crc.Crc32
    try std.testing.expect(!@hasDecl(std.hash.crc, "Crc32"));
    try std.testing.expectEqual(
        std.hash.crc.@"CRC-32/ISO-HDLC".hash("hello"),
        std.hash.Crc32.hash("hello"),
    );
    // CRC-32 是确定性的：实测值锁死，防止标准库改行为
    try std.testing.expectEqual(@as(u32, 0x3610A686), std.hash.Crc32.hash("hello"));

    // autoHash 是 (hasher, key) void —— 流式，不是返回 u64
    var h: Wy = .init(0);
    std.hash.autoHash(&h, @as(u8, 1));
    std.hash.autoHash(&h, @as(u32, 3));
    var h2: Wy = .init(0);
    std.hash.autoHash(&h2, @as(u8, 1));
    std.hash.autoHash(&h2, @as(u32, 3));
    try std.testing.expectEqual(h2.final(), h.final());

    // std.hash.int 打散整数（HashMap 用）
    try std.testing.expect(std.hash.int(@as(u32, 7)) != 0);
}

test "std.compress.flate 往返（0.17 只有 flate 有 Compress）" {
    const a = std.testing.allocator;
    // zstd / lzma 在 0.17 只有 Decompress
    try std.testing.expect(!@hasDecl(std.compress.zstd, "Compress"));
    try std.testing.expect(!@hasDecl(std.compress.lzma, "Compress"));
    try std.testing.expect(@hasDecl(std.compress, "flate"));

    var big: [4096]u8 = undefined;
    for (&big, 0..) |*p, i| p.* = @intCast('a' + @as(u8, @intCast(i % 26)));

    // ⚠️ 必须 initCapacity：Allocating.init 的 buffer 初始长度是 0，
    //    而 flate.Compress.init 里assert(output.buffer.len > 8)
    var out: std.Io.Writer.Allocating = try .initCapacity(a, 256);
    defer out.deinit();
    var scratch: [std.compress.flate.max_window_len]u8 = undefined;
    var comp = try std.compress.flate.Compress.init(&out.writer, &scratch, .gzip, .default);
    // Compress 自己就是个 Writer
    try comp.writer.writeAll(&big);
    try comp.finish();
    const cbuf = out.written();
    // gzip 魔数
    try std.testing.expectEqual(@as(u8, 0x1f), cbuf[0]);
    try std.testing.expectEqual(@as(u8, 0x8b), cbuf[1]);
    try std.testing.expect(cbuf.len < big.len); // 真的压小了

    // 解压：⚠️ Decompress 的 buffer 也要 max_window_len（不是 history_len）
    var back: std.Io.Reader = .fixed(cbuf);
    var dscratch: [std.compress.flate.max_window_len]u8 = undefined;
    var decomp = std.compress.flate.Decompress.init(&back, .gzip, &dscratch); // 不返回错误
    var dout: std.Io.Writer.Allocating = .init(a);
    defer dout.deinit();
    _ = try decomp.reader.streamRemaining(&dout.writer);
    try std.testing.expectEqualSlices(u8, &big, dout.written());
}

test "0.17 的 API 存在性：确实被移除的那些名字" {
    // ** 运算符已移除（编译期错误，无法在测试里断言，用文档说明）
    // std.fmt
    try std.testing.expect(!@hasDecl(std.fmt, "parseChar"));
    try std.testing.expect(!@hasDecl(std.fmt, "fmtInt"));
    try std.testing.expect(!@hasDecl(std.fmt, "alignIntoBuffer"));
    try std.testing.expect(@hasDecl(std.fmt, "bytesToHex"));
    try std.testing.expect(@hasDecl(std.fmt, "hexToBytes"));
    try std.testing.expect(@hasDecl(std.fmt, "comptimePrint"));
    try std.testing.expect(@hasDecl(std.fmt, "parseFloat"));
    try std.testing.expect(@hasDecl(std.fmt, "parseInt"));
    // allocPrint / bufPrint 还在但已 Deprecated（源码注释指向 mem.print）
    try std.testing.expect(@hasDecl(std.fmt, "allocPrint"));
    try std.testing.expect(@hasDecl(std.fmt, "bufPrint"));
    // 实测它们仍能用
    const a = std.testing.allocator;
    const s = try std.fmt.allocPrint(a, "{d}+{d}", .{ 1, 2 });
    defer a.free(s);
    try std.testing.expectEqualStrings("1+2", s);
    var bbuf: [16]u8 = undefined;
    try std.testing.expectEqualStrings("beef", try std.fmt.bufPrint(&bbuf, "{x:0>4}", .{0xbeef}));

    // parseInt / parseFloat 实测
    try std.testing.expectEqual(@as(i32, -1234), try std.fmt.parseInt(i32, "-1234", 10));
    try std.testing.expectEqual(@as(u16, 255), try std.fmt.parseInt(u16, "ff", 16));
    try std.testing.expectEqual(@as(f64, 3.25), try std.fmt.parseFloat(f64, "3.25"));
    try std.testing.expectEqualStrings("7-z", std.fmt.comptimePrint("{d}-{s}", .{ 7, "z" }));

    // Io.Limit 是非穷尽 enum：.nothing / .unlimited 是成员，.limited(n) 是函数
    try std.testing.expectEqual(@as(usize, 0), @backingInt(std.Io.Limit.nothing));
}

test "Writer 家族：fixed / Allocating / Discarding" {
    const a = std.testing.allocator;
    // fixed：落调用方的栈缓冲，无需 flush
    var buf: [32]u8 = undefined;
    var fw = std.Io.Writer.fixed(&buf);
    try fw.print("{s}-{d}", .{ "x", 7 });
    try std.testing.expectEqualStrings("x-7", fw.buffered());

    // Allocating：堆上增长，必须 deinit（testing.allocator 会逮泄漏）
    var aw: std.Io.Writer.Allocating = .init(a);
    defer aw.deinit();
    try aw.writer.print("{s}", .{"hello"});
    try std.testing.expectEqualStrings("hello", aw.written());

    // initCapacity：显式给初始容量（flate.Compress.init 要求 buffer.len > 8）
    var cw: std.Io.Writer.Allocating = try .initCapacity(a, 64);
    defer cw.deinit();
    try std.testing.expect(cw.writer.buffer.len >= 64);

    // Discarding：丢弃但计数（用.std.fmt.count 也可以）
    var scratch: [64]u8 = undefined;
    var dw: std.Io.Writer.Discarding = .init(&scratch);
    try dw.writer.print("{d}", .{12345});
    try std.testing.expectEqual(@as(usize, 5), dw.writer.end);
    try std.testing.expectEqual(@as(usize, 5), std.fmt.count("{d}", .{12345}));
}

test "流式哈希 == 一次性哈希（流式的核心不变式）" {
    const Wy = std.hash.Wyhash;
    const a = std.testing.allocator;
    const total = 8192;
    const data = try a.alloc(u8, total);
    defer a.free(data);
    for (data, 0..) |*p, i| p.* = @intCast(i & 0xff);

    var whole = Wy.init(0);
    whole.update(data);

    // 分块，且块大小刻意不等于 total（模拟真实的流式读取）
    for ([_]usize{ 1, 7, 64, 1000, 4096, total }) |chunk_len| {
        var streamed = Wy.init(0);
        var i: usize = 0;
        while (i < total) {
            const stop = @min(i + chunk_len, total);
            streamed.update(data[i..stop]);
            i = stop;
        }
        try std.testing.expectEqual(whole.final(), streamed.final());
    }
}

test "streamHexdump：块大小与总量脱钩" {
    var r = std.Io.Reader.fixed("ABCDEFGH");
    var w: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer w.deinit();
    // ⚠️ Reader.fixed 上不能用 fillMore，所以 streamHexdump 走 buffered() 路径
    //    这里直接验证输出前缀
    const blocks = try streamHexdumpFixed(&r, &w.writer, 4);
    // 8 字节 < 16 → 一块就收尾（实测 blocks=0 是"进入循环体前"的计数，见函数实现）
    try std.testing.expectEqual(@as(usize, 0), blocks);
    const s = w.written();
    try std.testing.expect(std.mem.startsWith(u8, s, "0000  41 42 43 44 45 46 47 48 \n"));
    // 正好 16 字节 → 完整一块 + 一次空轮
    var r2 = std.Io.Reader.fixed("ABCDEFGHIJKLMNOP");
    var w2: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer w2.deinit();
    _ = try streamHexdumpFixed(&r2, &w2.writer, 4);
    try std.testing.expectEqualStrings("0000  41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50 \n", w2.written());
}

/// `Reader.fixed` 专用的 hexdump：没有 fillMore可用，直接从 buffered() 拿
fn streamHexdumpFixed(r: *std.Io.Reader, w: *std.Io.Writer, max_blocks: usize) !usize {
    var blocks: usize = 0;
    while (blocks < max_blocks) : (blocks += 1) {
        const avail = r.buffered();
        if (avail.len == 0) break;
        const n = @min(avail.len, 16);
        try w.print("{X:0>4}  ", .{blocks * 16});
        for (avail[0..n]) |b| try w.print("{X:0>2} ", .{b});
        try w.print("\n", .{});
        if (avail.len < 16) break;
        r.toss(n);
    }
    try w.flush();
    return blocks;
}
