//! 24.3 / 24.7 逐行读取与输出格式化：把"文件字节流"变成"带高亮的命中行列表"
//!
//! 这一层刻意**不含正则、不含目录遍历**——它只回答两件事：
//!   1. 怎么在固定内存上限内正确切出任意长的行？（24.3）
//!   2. 怎么把命中区间渲染成带 ANSI 颜色的字符串？（24.7）
//! 正则在 regex.zig，遍历在 main.zig。分层是为了让这一层能被单独测。
const std = @import("std");
const regex = @import("regex.zig");

/// 一条命中。`line` **借用**底层缓冲，调用方负责让它活到打印结束。
pub const Hit = struct {
    path: []const u8,
    line_no: usize,
    line: []const u8,
    /// 该行内的命中区间（可能有多段，`-c` 高亮用）
    spans: []const regex.Span,
};

pub const Stats = struct {
    /// 命中的行数
    matched_lines: usize = 0,
    /// 扫过的字节数（不是"读过的字节数"——超长行也算）
    scanned_bytes: u64 = 0,
    /// 扫过的文件数
    files: usize = 0,
    /// 出错的文件数（权限/编码等，跳过而不是整体失败）
    failed_files: usize = 0,
};

/// 24.3 的核心：一个**流式**逐行读取器。
///
/// 为什么不能用 `readFileAlloc` + `splitScalar`：
///   1. 16MB 的日志文件要一次性吃进内存，而 grep 应该只占 O(行长) 内存；
///   2. 0.17 里 `File.readAll` **不存在**（实测 @hasDecl = false），
///      一次性读完的 API 叫 `Dir.readFileAlloc(io, path, gpa, .limited(n))`，
///      而 `.limited` 是 `Io.Limit` 枚举，不是 usize。
///
/// 但流式的代价是：**行边界可能落在缓冲区的任意位置**。
/// `Reader.fillMore/buffered/toss` 三件套就是解决这个的：
///   - `fillMore()`：把底层缓冲填满（EOF 时报 EndOfStream）
///   - `buffered()`：当前"已读但还没消费"的字节
///   - `toss(n)`：消费掉 n 字节（不是 n 字节的**拷贝**，是移动读游标）
///
/// 我们在 20 章的 4 字节缓冲例子上做过一次；这里补上生产代码要的三件事：
///   1. 行超长时**自动扩容**（用 ArrayList，不设上限——上限由 max_line_bytes 决定）
///   2. 文件末尾没有换行时的收尾（最后一行也要算）
///   3. `\r\n` 的处理（只切 `\n`，把 `\r` 留在行尾——保持与 grep 一致）
pub const LineReader = struct {
    /// 底层字节流（来自 File.reader，24.3 的"流"）
    reader: *std.Io.Reader,
    /// 当前行累积区，**自动增长**
    line: std.ArrayList(u8) = .empty,
    /// 本轮读到的字节数
    scanned: u64 = 0,
    /// 单行字节上限；超了报 error.LineTooLong 而不是继续吃内存
    max_line_bytes: usize = 4 * 1024 * 1024,
    /// 已读到 EOF
    eof: bool = false,

    pub fn init(reader: *std.Io.Reader) LineReader {
        return .{ .reader = reader };
    }

    pub fn deinit(self: *LineReader, gpa: std.mem.Allocator) void {
        self.line.deinit(gpa);
    }

    /// 取下一行（不含行尾的 `\n`）。返回的切片**借用**内部缓冲，
    /// 下一次调用 `nextLine` 就会被覆盖——所以要长期持有就自己 dupe。
    pub fn nextLine(self: *LineReader, gpa: std.mem.Allocator) !?[]const u8 {
        if (self.eof and self.line.items.len == 0) return null;

        self.line.clearRetainingCapacity();
        while (true) {
            // ① 把缓冲填满。EndOfStream 时缓冲里可能还留着没有换行结尾的零头，
            //    那正是**最后一行**，不能丢。
            if (!self.eof) {
                self.reader.fillMore() catch |err| switch (err) {
                    error.EndOfStream => self.eof = true,
                    else => |e| return e,
                };
            }
            const avail = self.reader.buffered();
            if (avail.len == 0) {
                // 缓冲空了：要么刚到 EOF 且没有残留行，要么还有行没读完
                if (self.eof) {
                    if (self.line.items.len == 0) return null;
                    return self.line.items;
                }
                continue;
            }

            // ② 在**当前可用字节**里找行尾
            const idx = std.mem.indexOfScalarPos(u8, avail, 0, '\n');
            const cut = idx orelse avail.len;
            try self.appendChecked(gpa, avail[0..cut]);

            // ③ 只在**真的找到分隔符**时才多消费 1 字节（含那个 \n）。
            //    无脑写 toss(idx.? + 1) 是 0.17 的经典 panic：
            //    assert(r.seek <= r.end) failed（20 章实测）
            self.reader.toss(if (idx) |k| k + 1 else avail.len);

            if (idx != null) return self.line.items;
            // 没找到换行 ⇒ 这一段只是行的一部分，回到 ① 继续读
        }
    }

    fn appendChecked(self: *LineReader, gpa: std.mem.Allocator, bytes: []const u8) !void {
        if (self.line.items.len + bytes.len > self.max_line_bytes) return error.LineTooLong;
        try self.line.appendSlice(gpa, bytes);
    }
};

/// 24.7 的颜色表。用常量而不是散落的字面量，
/// 这样"哪些字节会被写进终端"在一个地方就能看全。
pub const Color = struct {
    /// 重置
    pub const reset = "\x1b[0m";
    /// 红色加粗——命中片段
    pub const hit = "\x1b[1;31m";
    /// 黄色——文件名
    pub const path = "\x1b[1;33m";
    /// 青色——行号
    pub const line_no = "\x1b[36m";
    /// 灰色加粗——统计行
    pub const dim = "\x1b[2m";

    /// 终端是否支持颜色。**非 TTY 时必须关色**——
    /// 否则重定向到文件时会留下一堆 ^[ 字面量（本章坑位清单第 3 条）。
    pub fn enabledFor(f: std.Io.File, io: std.Io) bool {
        return f.isTty(io) catch false;
    }
};

/// 把一行按 spans 上色后写进 w。
///
/// 用"**游标式**推进"而不是"每段都从头 indexOf"：
/// 每段只处理 [from, to) 之间的字节，写完把 from 推到 to。
/// 复杂度是 O(行宽)，与命中段数无关。
///
/// 当 spans 为空（`-v` 反向命中）时原样输出整行，不加任何转义。
pub fn writeHighlighted(
    w: *std.Io.Writer,
    line: []const u8,
    spans: []const regex.Span,
    color: bool,
) !void {
    if (spans.len == 0 or !color) {
        try w.writeAll(line);
        return;
    }
    var from: usize = 0;
    for (spans) |s| {
        // 防御：越界或逆序的区间直接跳过，不让一个坏 span 毁掉整行输出
        if (s.start > s.end or s.end > line.len) continue;
        if (s.start < from) continue; // 重叠区间：跳过（findAll 已保证不重叠）
        try w.writeAll(line[from..s.start]);
        try w.writeAll(Color.hit);
        try w.writeAll(line[s.start..s.end]);
        try w.writeAll(Color.reset);
        from = s.end;
    }
    try w.writeAll(line[from..]);
}

/// 24.6 的"匹配执行"在 grep 语境下的封装：给一行找出全部命中。
///
/// 注意这里用的是 `findAll` 而不是 `find`：
/// 高亮要标出**一行里的每一处**命中，不是只找第一处。
/// 另外 `a*` 这类模式会产生零宽匹配，`findAll` 内部已处理推进规则
/// （见 regex.zig 的对应注释），所以这里不会死循环。
pub fn allSpans(
    gpa: std.mem.Allocator,
    prog: *const regex.Program,
    line: []const u8,
    opt: regex.Options,
) ![]regex.Span {
    return regex.findAll(gpa, prog, line, opt);
}

test "LineReader：4 字节缓冲也能读出 6 字节的行（24.3 的核心用例）" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "l.txt", .data = "alpha\nbeta\ngamma" });
    const f = try tmp.dir.openFile(io, "l.txt", .{});
    defer f.close(io);

    var buf: [4]u8 = undefined; // 故意远小于行宽
    var fr = f.reader(io, &buf);
    var lr = LineReader.init(&fr.interface);
    defer lr.deinit(a);

    var got: [64]u8 = undefined;
    var acc: usize = 0;
    var n: usize = 0;
    while (try lr.nextLine(a)) |line| {
        n += 1;
        // 借用语义：立刻拷走，模拟调用方要长期持有的情形
        @memcpy(got[acc..][0..line.len], line);
        acc += line.len;
    }
    try std.testing.expectEqual(@as(usize, 3), n);
    try std.testing.expectEqualStrings("alphabetagamma", got[0..acc]);
}

test "LineReader：末行无换行也要算一行（差一个 \n 就少一行的经典 bug）" {
    const a = std.testing.allocator;
    const src = "one\ntwo\nthree"; // 注意结尾没有 \n
    var r = std.Io.Reader.fixed(src);
    var lr = LineReader.init(&r);
    defer lr.deinit(a);

    var n: usize = 0;
    var last: [16]u8 = undefined;
    while (try lr.nextLine(a)) |line| {
        n += 1;
        @memcpy(last[0..line.len], line);
    }
    try std.testing.expectEqual(@as(usize, 3), n);
    try std.testing.expectEqualStrings("three", last[0..5]);
}

test "LineReader：单行超长报错而不是无限吃内存" {
    const a = std.testing.allocator;
    var long: [300]u8 = undefined;
    @memset(&long, 'x');
    var r = std.Io.Reader.fixed(&long);
    var lr = LineReader.init(&r);
    lr.max_line_bytes = 64;
    defer lr.deinit(a);
    try std.testing.expectError(error.LineTooLong, lr.nextLine(a));
}

test "LineReader：空文件与纯换行文件" {
    const a = std.testing.allocator;
    { // 空文件 ⇒ 零行
        var r = std.Io.Reader.fixed("");
        var lr = LineReader.init(&r);
        defer lr.deinit(a);
        try std.testing.expect((try lr.nextLine(a)) == null);
    }
    { // "\n" ⇒ 一行空行（grep 会认为有个空行）
        var r = std.Io.Reader.fixed("\n");
        var lr = LineReader.init(&r);
        defer lr.deinit(a);
        const line = (try lr.nextLine(a)).?;
        try std.testing.expectEqualStrings("", line);
        try std.testing.expect((try lr.nextLine(a)) == null);
    }
}

test "writeHighlighted：命中段被包上转义，其余原样" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    // "abxcd" 的 [2,4) 是 "xc"（下标从 0 数：a=0 b=1 x=2 c=3 d=4）
    const spans = [_]regex.Span{.{ .start = 2, .end = 4 }};
    try writeHighlighted(&w, "abxcd", &spans, true);
    try std.testing.expectEqualStrings("ab\x1b[1;31mxc\x1b[0md", w.buffered());
}

test "writeHighlighted：一行多处命中按顺序上色" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    const spans = [_]regex.Span{
        .{ .start = 0, .end = 1 },
        .{ .start = 2, .end = 3 },
    };
    try writeHighlighted(&w, "aXbXc", &spans, true);
    try std.testing.expectEqualStrings(
        "\x1b[1;31ma\x1b[0mX\x1b[1;31mb\x1b[0mXc",
        w.buffered(),
    );
}

test "writeHighlighted：关色时输出与原文逐字节相同（重定向文件的正确行为）" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    const spans = [_]regex.Span{.{ .start = 3, .end = 5 }};
    try writeHighlighted(&w, "abxcd", &spans, false);
    try std.testing.expectEqualStrings("abxcd", w.buffered());
}

test "writeHighlighted：坏区间（越界/重叠）被跳过，不毁掉整行" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    const spans = [_]regex.Span{
        .{ .start = 2, .end = 4 },
        .{ .start = 3, .end = 5 }, // 与上一段重叠
        .{ .start = 9, .end = 12 }, // 越界
    };
    try writeHighlighted(&w, "abcd", &spans, true);
    try std.testing.expectEqualStrings("ab\x1b[1;31mcd\x1b[0m", w.buffered());
}

test "allSpans：交给 regex.findAll，行内多处命中都能取到" {
    const a = std.testing.allocator;
    const prog = try regex.compile(a, "ab");
    defer prog.deinit(a);
    const spans = try allSpans(a, &prog, "ab-ab-ab", .{});
    defer a.free(spans);
    try std.testing.expectEqual(@as(usize, 3), spans.len);
}
