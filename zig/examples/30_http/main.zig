//! 30 HTTP 服务与客户端：手写报文解析/构造 + 路由 + JSON + 完整往返（std.Io.net 运输层）
//! 取材：Systems Programming with Zig ch6（minimal web server / 随机数 JSON 服务）
//!
//! 运输层沿用 29 章结论，但本章**不再带 Windows 分支**：29_netecho 已经实测
//! 0.17 的 std.Io.net TCP 在 POSIX 上可用（0.16 的 AFD 缺陷是 0.16 独有的），
//! 所以这里直接用 std.Io.net，示例聚焦在 HTTP 协议本身。
//!
//! HTTP 是**基于行的文本协议**：请求行/状态行 + 头部 + 空行 + 体，每行以 CRLF 结尾。
//! 本章亲手把这一层写一遍——亲手写过一次之后，任何 HTTP 框架都不再是黑盒。

const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ══════════════════════════════════════════════════════════════════
// 运输层：把 std.Io.net.Stream 包成"按行读、按块写"的连接对象
//
// 三个坑，逐个对应文档 30.2：
//
// 坑① `stream.read(io, [][]u8)` 在 0.17.0 编译不过（标准库自己的 bug）。
//     实测报错在 lib/std/Io/net.zig:1286："type 'Io.net.Stream.ReadResult'
//     cannot be destructured"。所以读路径全部走 `stream.reader(io, buf)`。
//
// 坑② **`takeDelimiterExclusive` 在网络 Reader 上不阻塞**——它只扫已经
//     缓冲在手里的字节，手上没有 '\n' 就立刻返回**空片**、不做底层读。
//     症状是服务端陷入"读到空行 → 写 OK → 再读到空行"的死循环。
//     `recvLine` 因此自己写：fillMore（做一次底层读）+ indexOfScalarPos
//     （在已就绪字节里找 CRLF）+ toss（丢弃已取走的部分）。
//
// 坑③ **自引用 struct 不能按值拷贝**：Reader 内部持有缓冲的指针，缓冲是本
//     对象的字段。在 init() 里就地绑定，绑到的是 init 的栈帧，`return self`
//     一拷贝就悬垂。改成**懒绑定**——每次收发前确保已绑定，拷多少次都对。
// ══════════════════════════════════════════════════════════════════

const Conn = struct {
    io: std.Io,
    stream: std.Io.net.Stream,
    rbuf: [8192]u8 = undefined,
    r: std.Io.net.Stream.Reader,
    wbuf: [8192]u8 = undefined,
    w: std.Io.net.Stream.Writer,
    bound: bool = false,

    pub fn init(io: std.Io, stream: std.Io.net.Stream) Conn {
        // ⚠️ 这里**不能**顺手写 `r = stream.reader(io, &rbuf)`。
        // 那行代码编译通过、小报文也能跑，但 self.r 里的缓冲指针指向的是
        // 这个 init 的栈帧；`return self` 一拷贝，Reader 就指向已销毁的临时。
        // 症状极其阴：小报文偶尔对、缓冲区一大就乱序或直接读脏数据。
        // 改成懒绑定（见 ensureBound），值拷贝多少次都指向最终那份字段。
        return .{ .io = io, .stream = stream, .r = undefined, .w = undefined };
    }

    fn ensureBound(self: *Conn) void {
        if (self.bound) return;
        self.r = self.stream.reader(self.io, &self.rbuf);
        self.w = self.stream.writer(self.io, &self.wbuf);
        self.bound = true;
    }

    /// 关连接。⚠️ `Stream.close` **不幂等**——显式 close 之后别再 `defer close`，
    /// 第二次会报 BADF（Threaded.zig 里是 recoverableOsBugDetected）。
    pub fn close(self: *Conn) void {
        self.stream.close(self.io);
    }

    pub fn sendAll(self: *Conn, data: []const u8) !void {
        self.ensureBound();
        try self.w.interface.writeAll(data);
        try self.w.interface.flush();
    }

    /// 读一行（以 CRLF 结尾），**把行拷进调用方缓冲 `out`**，返回其切片。
    ///
    /// 为什么不 `return self.r.interface.buffered()[0..at]`？那是**指向内部缓冲的
    /// 切片**，随下一次 fillMore/toss 立刻失效。本教程 29 章 agent 实测踩过：
    /// 打印时内容已变成被复写的乱码。这里改成拷进 `out`——所有权归调用方。
    ///
    /// `max_line` 是防 DoS 的闸门：恶意对端发一个 1MB 的请求行，
    /// 没有这道闸就是一次 OOM。
    pub fn recvLine(self: *Conn, out: []u8, max_line: usize) ![]u8 {
        self.ensureBound();
        const r = &self.r.interface;
        var scanned: usize = 0; // 已扫过但不属于本行的字节数
        while (true) {
            const avail = r.buffered();
            // HTTP 行尾是 CRLF。搜 '\r' 定位行尾（头部里不会出现裸 '\r'），
            // 切出来的行天然不含结尾的 '\r'。
            if (std.mem.indexOfScalarPos(u8, avail, scanned, '\r')) |at| {
                const line = avail[scanned..at];
                // ⚠️⚠️ **必须吃掉 CRLF 两个字节**，只 `toss(at + 1)` 会把 '\n'
                // 留给下一次 recvLine，于是下一行变成 "\nHost: x"，而**空行
                // 判断 `len == 0` 永远不成立**（"\r\n" 那行读出来是 "\n"，
                // 长度 1）→ 头部循环一路读到 LineTooLong。
                // 这是本章实测踩到的第一个真bug（30.4 的服务端日志里
                // 全是 "解析失败 → 400 MalformedHeader"）。
                if (at + 1 < avail.len and avail[at + 1] == '\n') {
                    r.toss(at + 2);
                } else {
                    // '\n' 还没进缓冲（分片到达）：先吃 '\r'，补一次读再吃 '\n'。
                    // 对端用裸 CR 收尾（HTTP/0.9 老写法）时容忍缺失。
                    r.toss(at + 1);
                    r.fillMore() catch |err| switch (err) {
                        error.EndOfStream => {},
                        error.ReadFailed => return error.ReadFailed,
                    };
                    const rest = r.buffered();
                    if (rest.len > 0 and rest[0] == '\n') r.toss(1);
                }
                if (line.len > max_line) return error.LineTooLong;
                @memcpy(out[0..line.len], line);
                return out[0..line.len];
            }
            scanned = avail.len;
            if (scanned > max_line) return error.LineTooLong; // 超长行：直接断连
            r.fillMore() catch |err| switch (err) {
                error.EndOfStream => return error.ConnectionClosed,
                error.ReadFailed => return error.ReadFailed,
            };
        }
    }

    /// 读**恰好** out.len 字节（body 用）。
    /// ⚠️ 不能用 `readSliceShort`——它的语义是"填满缓冲或读到 EOF"，
    /// 当单次 recv 用会让服务端在对端没打算发满时挂死。
    pub fn recvExact(self: *Conn, out: []u8) !usize {
        self.ensureBound();
        const r = &self.r.interface;
        var got: usize = 0;
        while (got < out.len) {
            const avail = r.buffered();
            if (avail.len == 0) {
                r.fillMore() catch |err| switch (err) {
                    error.EndOfStream => return error.ConnectionClosed,
                    error.ReadFailed => return error.ReadFailed,
                };
                continue;
            }
            const n = @min(out.len - got, avail.len);
            @memcpy(out[got..][0..n], avail[0..n]);
            r.toss(n);
            got += n;
        }
        return got;
    }

    /// 一行都不解析、只管有多少读多少（客户端"读到 EOF 为止"那条路径用）。
    pub fn recvSome(self: *Conn, buf: []u8) !usize {
        self.ensureBound();
        const r = &self.r.interface;
        r.fillMore() catch |err| switch (err) {
            error.EndOfStream => return 0,
            error.ReadFailed => return 0,
        };
        const avail = r.buffered();
        const n = @min(buf.len, avail.len);
        @memcpy(buf[0..n], avail[0..n]);
        r.toss(n);
        return n;
    }
};

/// 服务端监听器：从 `base` 起**高位非 0** 端口向上扫 `probe_count` 个。
///
/// ⚠️ **绝不能从 0 开始**：0 端口的意思是"让内核挑一个临时端口"，
/// bind 立刻成功，你拿到的是 49152 之类的随机端口——端口冲突不是问题，
/// 问题是**你以为扫了 20 个端口其实一次都没扫**。
///
/// 扫高位（如 48000 起）是为了避开 ephemeral 区间（macOS 默认 49152–65535，
/// Linux 32768–60999），否则"扫 20 个"里可能大部分是别人正在用的端口。
const probe_count = 20;
const port_base = 48011;

fn listenFrom(io: std.Io, base: u16) !struct { server: std.Io.net.Server, port: u16 } {
    var p: u16 = base;
    while (p < base + probe_count) : (p += 1) {
        const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", p);
        // `listen` 失败就换下一个端口。失败原因可能是 EADDRINUSE（占了）
        // 也可能是别的，但 20 个连续高位端口全失败基本就是环境问题。
        if (addr.listen(io, .{ .reuse_address = true })) |s| {
            return .{ .server = s, .port = p };
        } else |_| {}
    }
    return error.NoFreePort;
}

fn connectTo(io: std.Io, port: u16) !std.Io.net.Stream {
    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", port);
    // ⚠️ `ConnectOptions.mode` **无默认值**：写 `connect(io, .{})` 编译不过，
    // 必须是 `.{ .mode = .stream }`。
    return addr.connect(io, .{ .mode = .stream });
}

// ══════════════════════════════════════════════════════════════════
// 请求的最小建模
// ══════════════════════════════════════════════════════════════════

/// 允许的方法白名单。**不在表里的一律 501**——方法白名单是最便宜的
/// 输入消毒：畸形方法名进不到业务代码里。
/// ⚠️ HTTP 方法**区分大小写**：`get` 不是 `GET`。
const Methods = [_][]const u8{ "GET", "HEAD", "POST" };

fn isAllowedMethod(m: []const u8) bool {
    for (Methods) |x| {
        if (std.mem.eql(u8, x, m)) return true;
    }
    return false;
}

const Limits = struct {
    /// 单行上限（请求行/头部行都算）。防"一个超长请求行打爆内存"。
    line: usize = 1024,
    /// 头部行数上限。防"一万个 X-Header"。
    headers: usize = 16,
    /// 体上限。**这是必须的**——Content-Length 是对端说了算的数字，
    /// 不 clamp 就等于让对端决定你 alloc 多少。
    body: usize = 4096,
};

const Header = struct {
    name: []const u8,
    value: []const u8,
};

const Request = struct {
    method: []const u8 = "",
    target: []const u8 = "",
    path: []const u8 = "/",
    query: []const u8 = "",
    version: []const u8 = "",
    headers: []Header = &.{}, // 指向调用方数组，不拥有
    body: []const u8 = "", // 指向调用方缓冲，不拥有

    /// 按名字找请求头（**大小写不敏感**——HTTP 头字段名不区分大小写）。
    fn header(self: *const Request, name: []const u8) ?[]const u8 {
        for (self.headers) |h| {
            if (std.ascii.eqlIgnoreCase(h.name, name)) return h.value;
        }
        return null;
    }

    fn keepAlive(self: *const Request) bool {
        const c = self.header("Connection") orelse return true; // HTTP/1.1 默认 keep-alive
        return !std.ascii.eqlIgnoreCase(c, "close");
    }
};

const ParseError = error{
    ConnectionClosed,
    LineTooLong,
    ReadFailed,
    MalformedRequestLine,
    TooManyHeaders,
    MalformedHeader,
    BodyTooLarge,
};

/// **请求解析状态机**：读首行 → 逐行读头部直到空行 → 按 Content-Length 读体。
///
/// 写成 `comptime C: type` 的泛型而不是收 `*Conn`，是为了让这段状态机
/// **零 IO 就能测**（30.11 测试节）：任何有 `recvLine`/`recvExact` 两个方法的
/// 类型都能驱动它——真实连接 `Conn`，测试里用`FixedConn`。
///
/// 每一步都有上限，这是它作为"面向不可信输入的解析器"的根本属性：
///
///   1. 读首行（`METHOD SP TARGET SP HTTP/1.1 CRLF`）
///      tokenizeScalar 切三段。切不出三段 → `MalformedRequestLine`（400）。
///      为什么要切三段而不是两段？`GET /` 只有两段是**畸形**的，
///      而 `GET / HTTP/1.1` 才是合法的最小请求行——不检查版本号，
///      就把 HTTP/0.9 和垃圾数据当成了合法请求。
///   2. 循环读头部行，`line.len == 0` 就是**空行 = 头部结束**。
///      `Key: Value` 形式，找不到 ':' → `MalformedHeader`（400）。
///      行数超 `limits.headers` → `TooManyHeaders`（431）。
///   3. 查 Content-Length。**有体才读体**，读满即止，
///      `> limits.body` 直接拒（413）。
///
/// 结果里的所有切片都指向 `scratch`/`head_buf`/`body_buf`——**不拥有内存**。
/// 调用方保证这三个缓冲在 Request 还活着期间有效。
///
/// ⚠️ **scratch 是"只进不退"的bump 区，绝不能复用**。第一版这里只有一块
/// `line_buf`，每读一行就从头覆盖——于是 `req.method`（指向首行）在读完
/// 第一个头之后变成 `"Hos"`，而所有头的 name/value 也全都指向最后一行。
/// 症状是"解析成功但字段全是垃圾"，且**测试会稳定地复现**（不 flaky）。
/// bump 区把这个整类别名 bug 从根上消掉：写过的字节永不被覆盖。
fn parseRequest(
    comptime C: type,
    conn: *C,
    scratch: []u8,
    head_buf: []Header,
    body_buf: []u8,
    limits: Limits,
) ParseError!Request {
    var req = Request{};
    var used: usize = 0; // scratch 里已用掉的字节数（bump 指针）

    // ── 状态 1：请求行
    {
        if (scratch.len < limits.line) return error.LineTooLong;
        const line = try conn.recvLine(scratch[used..][0..limits.line], limits.line);
        used += line.len;
        if (line.len == 0) return error.MalformedRequestLine;
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const method = it.next() orelse return error.MalformedRequestLine;
        const target = it.next() orelse return error.MalformedRequestLine;
        const version = it.next() orelse return error.MalformedRequestLine;
        if (it.next() != null) return error.MalformedRequestLine; // 第四段 = 畸形
        if (version.len < 5 or !std.mem.startsWith(u8, version, "HTTP/")) return error.MalformedRequestLine;

        req.method = method;
        req.target = target;
        req.version = version;
        // target 拆成 path + query。`/api/rand?n=5` → path=/api/rand, query=n=5
        if (std.mem.indexOfScalar(u8, target, '?')) |q| {
            req.path = target[0..q];
            req.query = target[q + 1 ..];
        } else {
            req.path = target;
            req.query = "";
        }
    }

    // ── 状态 2：头部，直到空行
    var n: usize = 0;
    while (true) {
        if (used + limits.line > scratch.len) return error.LineTooLong; // bump 区满
        const hl = try conn.recvLine(scratch[used..][0..limits.line], limits.line);
        if (hl.len == 0) break; // 空行 = 头部结束
        used += hl.len;
        if (n >= limits.headers) return error.TooManyHeaders;
        const colon = std.mem.indexOfScalar(u8, hl, ':') orelse return error.MalformedHeader;
        // 冒号后的前导空白要去掉（HTTP 允许 `Key: Value` 和 `Key:Value` 两种）
        var v = hl[colon + 1 ..];
        while (v.len > 0 and (v[0] == ' ' or v[0] == '\t')) v = v[1..];
        head_buf[n] = .{ .name = hl[0..colon], .value = v };
        n += 1;
    }
    req.headers = head_buf[0..n];

    // ── 状态 3：体（只有声明了 Content-Length 才读）
    if (req.header("Content-Length")) |cl_str| {
        const cl = std.fmt.parseInt(usize, cl_str, 10) catch return error.MalformedHeader;
        if (cl > limits.body) return error.BodyTooLarge; // 413
        if (cl > 0) {
            const got = try conn.recvExact(body_buf[0..cl]);
            req.body = body_buf[0..got];
        }
    }
    return req;
}

/// 从查询串取参数值（`"n=5&x=1"` 查 n 得 `"5"`）。极简版，不做百分号解码。
fn queryParam(query: []const u8, key: []const u8) ?[]const u8 {
    var it = std.mem.splitScalar(u8, query, '&');
    while (it.next()) |pair| {
        const eq = std.mem.indexOfScalar(u8, pair, '=') orelse continue;
        if (std.mem.eql(u8, pair[0..eq], key)) return pair[eq + 1 ..];
    }
    return null;
}

/// 测试用的"假连接"：从一段固定字节里按 CRLF 切行。
/// 它让`parseRequest` 的状态机可以零 socket、零 sleep 地被测试驱动。
const FixedConn = struct {
    raw: []const u8,
    pos: usize = 0,

    fn recvLine(self: *FixedConn, out: []u8, max_line: usize) ParseError![]u8 {
        if (self.pos >= self.raw.len) return error.ConnectionClosed;
        const e = std.mem.indexOf(u8, self.raw[self.pos..], "\r\n") orelse return error.LineTooLong;
        const line = self.raw[self.pos .. self.pos + e];
        self.pos += e + 2;
        if (line.len > max_line) return error.LineTooLong;
        @memcpy(out[0..line.len], line);
        return out[0..line.len];
    }

    /// 必须与 `Conn.recvExact` **同语义**：读满`out.len` 才成功，
    /// 数据不够就 ConnectionClosed。返回一个短计数会让"体被截断"
    /// 这种bug 在测试里伪装成成功——两个实现必须一致才能互换。
    fn recvExact(self: *FixedConn, out: []u8) ParseError!usize {
        const avail = self.raw.len - self.pos;
        if (avail < out.len) return error.ConnectionClosed;
        @memcpy(out[0..out.len], self.raw[self.pos..][0..out.len]);
        self.pos += out.len;
        return out.len;
    }
};

/// 用固定字节驱动状态机。测试与 main 的纯逻辑演示都走这里。
fn parseFixed(raw: []const u8, limits: Limits, scratch: []u8, head_buf: []Header, body_buf: []u8) ParseError!Request {
    var fc = FixedConn{ .raw = raw };
    return parseRequest(FixedConn, &fc, scratch, head_buf, body_buf, limits);
}

// ══════════════════════════════════════════════════════════════════
// 响应构造：状态行 + 头部 + 空行 + 体
// ══════════════════════════════════════════════════════════════════

const Response = struct {
    code: u16 = 200,
    reason: []const u8 = "OK",
    content_type: []const u8 = "text/plain; charset=utf-8",
    body: []const u8 = "",
    /// close = 发完就关连接（客户端读到 EOF 即响应完整）；
    /// false = keep-alive，客户端**必须**按 Content-Length 数字节。
    close: bool = true,
    /// 只给"故意写错 Content-Length"的演示用；null = 按 body.len 算。
    /// 生产代码里**永远不该有这个东西**——它存在的唯一目的是让本章能演示
    /// 长度写错会怎样（见30.4）。
    content_length_override: ?usize = null,
};

/// 把响应序列化成线上的字节。
///
/// **`Content-Length` 是本章最要命的一行**：客户端严格按它数字节，
/// 写大了一直等、写小了一截被当下一个响应的开头——两种都表现为「挂死」，
/// 而且是**在客户端挂死、服务端日志一切正常**。永远用 `body.len` 算，别手输。
fn serialize(a: std.mem.Allocator, rep: *const Response) ![]u8 {
    const len = rep.content_length_override orelse rep.body.len;
    // ⚠️ reason 是**状态行的一部分**，不是可选的装饰。漏填就会发出
    // "HTTP/1.1 404 OK" 这种自相矛盾的行——本节第一版就是这样，
    // 客户端拿到的 404 理由写着 OK。这里兜底查表，别依赖每个调用点记得填。
    const reason = if (rep.reason.len == 0) reasonPhrase(rep.code) else rep.reason;
    return std.fmt.allocPrint(
        a,
        "HTTP/1.1 {d} {s}\r\n" ++
            "Content-Type: {s}\r\n" ++
            "Content-Length: {d}\r\n" ++
            "Connection: {s}\r\n" ++
            "\r\n" ++
            "{s}",
        .{ rep.code, reason, rep.content_type, len, if (rep.close) "close" else "keep-alive", rep.body },
    );
}

/// 状态行的 reason 短语表（只列本章用得上的）。
fn reasonPhrase(code: u16) []const u8 {
    return switch (code) {
        200 => "OK",
        400 => "Bad Request",
        404 => "Not Found",
        405 => "Method Not Allowed",
        413 => "Payload Too Large",
        431 => "Request Header Fields Too Large",
        500 => "Internal Server Error",
        501 => "Not Implemented",
        else => "Unknown",
    };
}

// ══════════════════════════════════════════════════════════════════
// 路由：精确匹配 + 前缀匹配 + 404/405
// ══════════════════════════════════════════════════════════════════

const RouteKind = enum { exact, prefix };

const Route = struct {
    method: []const u8,
    kind: RouteKind,
    path: []const u8,
    name: []const u8,
};

/// 手写路由表。**顺序敏感**：第一条匹配的赢。
/// 前缀路由天然更宽，所以注册顺序直接决定优先级——
/// 想清楚这一点很省事：精确路由注册在动态之前即可。
const routes = [_]Route{
    .{ .method = "GET", .kind = .exact, .path = "/", .name = "home" },
    .{ .method = "GET", .kind = .exact, .path = "/api/rand", .name = "rand" },
    .{ .method = "GET", .kind = .exact, .path = "/api/info", .name = "info" },
    .{ .method = "POST", .kind = .exact, .path = "/api/echo", .name = "echo" },
    // 故意失败的处理器，用来演示 500（见 route 里的说明）
    .{ .method = "GET", .kind = .exact, .path = "/api/boom", .name = "boom" },
    // 前缀路由：`/static/` 开头的任何路径都命中
    .{ .method = "GET", .kind = .prefix, .path = "/static/", .name = "static" },
};

/// 路由查找结果返回**三态**而不是 bool，这是 404 / 405 的分界线：
///
/// - `.none`（没有任何路由的 path 匹配）→ **404** 资源不存在
/// - `.method_mismatch`（path 匹配了但方法不对）→ **405**
///   两者区别是真实的：405 应该带 `Allow` 头告诉客户端"用这些方法重试"；
///   404 则不该泄露"这个路径存在，只是你不能这样访问"。
/// - `.route` → 命中
const Match = union(enum) { route: Route, method_mismatch: bool, none: void };

fn lookup(method: []const u8, path: []const u8) Match {
    var path_seen = false; // 有没有哪个路由的 path 匹配上了（不管方法）
    for (routes) |r| {
        const hit = switch (r.kind) {
            .exact => std.mem.eql(u8, r.path, path),
            .prefix => std.mem.startsWith(u8, path, r.path),
        };
        if (!hit) continue;
        if (std.mem.eql(u8, r.method, method)) return .{ .route = r };
        path_seen = true;
    }
    if (path_seen) return .{ .method_mismatch = true };
    return .none;
}

/// 路由 → 响应。所有分配都来自传入的 arena（每连接一个，30.7 讲）。
fn route(a: std.mem.Allocator, req: *const Request) !Response {
    // 方法白名单先过：不在白名单里 → 501（不是 405：405 说的是"这些方法行"，
    // 501 说的是"这个方法我不认识"）
    if (!isAllowedMethod(req.method)) {
        return .{ .code = 501, .reason = reasonPhrase(501), .body = "method not implemented" };
    }

    switch (lookup(req.method, req.path)) {
        .none => return .{ .code = 404, .reason = reasonPhrase(404), .body = "not found" },
        .method_mismatch => return .{ .code = 405, .reason = reasonPhrase(405), .body = "method not allowed" },

        // ⚠️ 0.17 **不能 switch 字符串**（error: cannot switch on strings）。
        // 路由名用 `if + eql` 链分发。枚举化（`enum { home, rand, ... }`）也行，
        // 但注册表和名字都是数据、写成字符串更好读——代价就是这条 if 链。
        .route => |r| {
            if (std.mem.eql(u8, r.name, "home")) {
                return .{
                    .code = 200,
                    .content_type = "text/html; charset=utf-8",
                    .body = "<h1>zhttp</h1><p>routes: / /api/rand?n= /api/info /api/echo /api/boom /static/*</p>",
                };
            }

            if (std.mem.eql(u8, r.name, "rand")) {
                // ⚠️ `parseInt` 会抛错（`?n=abc`）、`?n=999` 会越界。
                // 两个都要处理：catch 给默认 1，`@min` clamp 到 16。
                // **网络输入永远先消毒再使用**——这是本章第一实践要点。
                const n = blk: {
                    const raw = queryParam(req.query, "n") orelse break :blk 1;
                    const parsed = std.fmt.parseInt(u32, raw, 10) catch break :blk 1;
                    break :blk @min(parsed, 16);
                };
                const Rand = struct { n: u32, values: []const u32, service: []const u8 };
                var values: [16]u32 = undefined;
                var prng = std.Random.DefaultPrng.init(0xF00D); // 定种子 → 输出可复现
                for (values[0..n]) |*v| v.* = prng.random().uintLessThan(u32, 100);
                var jw = std.Io.Writer.Allocating.init(a);
                // ⚠️ `Stringify.value(value, options, writer)` —— **writer 在最后**。
                // 写成 `value(value, writer, options)` 的实测编译错是
                // "expected type 'json.Stringify.Options', found pointer"。
                try std.json.Stringify.value(
                    Rand{ .n = n, .values = values[0..n], .service = "zhttp" },
                    .{},
                    &jw.writer,
                );
                return .{ .code = 200, .content_type = "application/json", .body = jw.written() };
            }

            if (std.mem.eql(u8, r.name, "info")) {
                const Info = struct { name: []const u8, version: []const u8, routes: []const []const u8 };
                var jw = std.Io.Writer.Allocating.init(a);
                try std.json.Stringify.value(
                    Info{
                        .name = "zhttp",
                        .version = "0.1",
                        .routes = &.{ "/", "/api/rand?n=", "/api/info", "/api/echo", "/api/boom", "/static/*" },
                    },
                    .{},
                    &jw.writer,
                );
                return .{ .code = 200, .content_type = "application/json", .body = jw.written() };
            }

            // POST 路由：演示**按 Content-Length 读体**并把体回显成 JSON。
            // 这是"体"存在的意义——GET 的体是空的，POST 才让请求有状态。
            if (std.mem.eql(u8, r.name, "echo")) {
                const Echo = struct { method: []const u8, path: []const u8, body_len: usize, body: []const u8 };
                var jw = std.Io.Writer.Allocating.init(a);
                try std.json.Stringify.value(
                    Echo{ .method = req.method, .path = req.path, .body_len = req.body.len, .body = req.body },
                    .{},
                    &jw.writer,
                );
                return .{ .code = 200, .content_type = "application/json", .body = jw.written() };
            }

            // 故意失败的处理器：演示 **500**。
            // ⚠️ 它**不是**靠 panic 实现的——路由处理函数出错时 `route` 返回
            // 一个 error，`serve` 的 catch 把它变成 500 响应。整个进程毫发无伤，
            // 下一个连接还能正常服务。（panic 会带走整个进程，那不叫错误处理。）
            if (std.mem.eql(u8, r.name, "boom")) return error.HandlerFailed;

            // 前缀路由：命中 `/static/` 开头的任何路径。
            if (std.mem.eql(u8, r.name, "static")) {
                const raw_n = queryParam(req.query, "n") orelse "1";
                const n = std.fmt.parseInt(usize, raw_n, 10) catch 1;
                var bytes: [256]u8 = @splat('.');
                bytes[0] = '0' + @as(u8, @intCast(n % 10));
                var jw = std.Io.Writer.Allocating.init(a);
                try std.json.Stringify.value(.{ .n = n, .head = bytes[0..4] }, .{}, &jw.writer);
                return .{ .code = 200, .content_type = "application/json", .body = jw.written() };
            }

            return .{ .code = 500, .reason = reasonPhrase(500), .body = "no handler for this route name" };
        },
    }
}

// ══════════════════════════════════════════════════════════════════
// 客户端：两种读响应的方式
// ══════════════════════════════════════════════════════════════════

const Reply = struct {
    version: []const u8 = "",
    code: u16 = 0,
    reason: []const u8 = "",
    content_type: []const u8 = "",
    content_length: ?usize = null,
    body: []const u8 = "",
};

/// 把"状态行 + 头部 + 空行"这段头部从 raw 里解出来。
/// `raw` 是调用方缓冲，body 切片**指向 raw**——不 dupe，所以调用方
/// 必须保证 raw 比 Reply 活得久（下面两个 fetch 都满足）。
fn splitHead(raw: []const u8) !struct { head: []const u8, body: []const u8 } {
    const sep = std.mem.indexOf(u8, raw, "\r\n\r\n") orelse return error.BadResponse;
    return .{ .head = raw[0..sep], .body = raw[sep + 4 ..] };
}

fn parseStatusLine(head: []const u8) !Reply {
    const eol = std.mem.indexOf(u8, head, "\r\n") orelse head.len;
    const line = head[0..eol];
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    const ver = it.next() orelse return error.BadResponse;
    const code_str = it.next() orelse return error.BadResponse;
    const code = std.fmt.parseInt(u16, code_str, 10) catch return error.BadResponse;
    // ⚠️ reason phrase **可以含空格**（"Not Found"、"Method Not Allowed"、
    // "Request Header Fields Too Large"）。所以不能 `it.next()`——
    // 那只会拿到 "Not" / "Method" / "Request"，剩下半截被丢掉。
    // 正确做法是**第二个空格之后的整段**都是 reason。
    // （本示例第一版就踩了：客户端打印出 "404 Not"、"405 Method"。）
    return .{
        .version = ver,
        .code = code,
        .reason = reasonAfterCode(line),
    };
}

/// 取状态行里第三段起的**全部剩余内容**作为 reason（保留内部空格）。
fn reasonAfterCode(line: []const u8) []const u8 {
    var i: usize = 0;
    var spaces: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == ' ') {
            spaces += 1;
            if (spaces == 2) return std.mem.trim(u8, line[i + 1 ..], " ");
        }
    }
    return "";
}

/// 扫头部里的 `Key: Value` 行，回调式（省掉"头数量上限"这层间接）。
fn forEachHeader(head: []const u8, ctx: anytype, comptime f: fn (@TypeOf(ctx), []const u8, []const u8) void) void {
    var it = std.mem.splitSequence(u8, head, "\r\n");
    _ = it.next(); // 状态行
    while (it.next()) |line| {
        if (line.len == 0) continue;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        var v = line[colon + 1 ..];
        while (v.len > 0 and (v[0] == ' ' or v[0] == '\t')) v = v[1..];
        f(ctx, line[0..colon], v);
    }
}

const HeadCtx = struct { rep: *Reply, bad_length: bool = false };

fn onHeader(ctx: *HeadCtx, name: []const u8, value: []const u8) void {
    if (std.ascii.eqlIgnoreCase(name, "Content-Type")) {
        ctx.rep.content_type = value;
    } else if (std.ascii.eqlIgnoreCase(name, "Content-Length")) {
        ctx.rep.content_length = std.fmt.parseInt(usize, value, 10) catch {
            ctx.bad_length = true;
            return;
        };
    }
}

/// **客户端 A：读到 EOF 为止**（`Connection: close` 的配套读法）。
///
/// 优点：不需要信任 Content-Length，对端崩在半路也能收到已有字节。
/// 缺点：一条连接只能一个请求，keep-alive 失效。
/// 唯一的坑：`recvSome` 返回 0 表示对端关闭，**必须 break**——
/// 忘了 break 就是 30.10 演示的经典死循环。
fn fetchToEof(a: std.mem.Allocator, io: std.Io, port: u16, method: []const u8, target: []const u8, body: []const u8) !Reply {
    var conn = Conn.init(io, try connectTo(io, port));
    defer conn.close();
    try sendRequest(&conn, method, target, body, true);

    var raw: [4096]u8 = undefined;
    var total: usize = 0;
    while (true) {
        const n = try conn.recvSome(raw[total..]);
        if (n == 0) break; // ← 对端关闭。少了这一行就是死循环
        total += n;
    }
    // ⚠️⚠️ **先把整个响应 dupe 进 `a`，再从副本上解析**。
    // 本函数第一版只 dupe 了 body，结果 `Reply.reason` / `content_type`
    // 仍然指向**栈上**的 `raw`——函数一返回它们就是悬垂切片。
    // 症状极阴：`code` 是 u16（按值拷贝，没事），`reason` 是切片（悬垂），
    // 打印出来是 "404 Not" 这种被腰斩的内容——因为栈帧被复写了。
    // **教训：一个返回结构体里的所有切片字段，必须统一指向同一份所有权。**
    const owned = try a.dupe(u8, raw[0..total]);
    const parts = try splitHead(owned);
    var rep = try parseStatusLine(parts.head);
    var ctx = HeadCtx{ .rep = &rep };
    forEachHeader(parts.head, &ctx, onHeader);
    rep.body = parts.body;
    return rep;
}

/// **客户端 B：按 Content-Length 读**（keep-alive 连接的标准读法）。
///
/// `Content-Length` 写对了这就是正解；**写错了就挂死**——`recvExact`
/// 一直等剩下的字节。这里对端会 `close`，所以 `fillMore` 拿到 EndOfStream
/// 后我们把它翻译成 `error.TruncatedBody`：能报错退出。
/// **真实的挂死发生在对端不关闭连接时**（keep-alive 下等下一条响应），
/// 那时没有任何机制能救你——所以长度必须一次写对。
fn fetchByLength(a: std.mem.Allocator, io: std.Io, port: u16, method: []const u8, target: []const u8) !Reply {
    var conn = Conn.init(io, try connectTo(io, port));
    defer conn.close();
    try sendRequest(&conn, method, target, "", false);

    var raw: [4096]u8 = undefined;
    var total: usize = 0;
    // 第一步：把头部读出来（状态行 + 头直到空行）
    while (std.mem.indexOf(u8, raw[0..total], "\r\n\r\n") == null) {
        const n = try conn.recvSome(raw[total..]);
        if (n == 0) return error.ConnectionClosed;
        total += n;
    }
    // ⚠️ 同 fetchToEof：先 dupe 整个响应再解析，否则 reason / content_type
    // 会指向栈上的 raw（悬垂切片），打印时被腰斩成 "404 Not"。
    const owned = try a.dupe(u8, raw[0..total]);
    const parts = try splitHead(owned);
    var rep = try parseStatusLine(parts.head);
    var ctx = HeadCtx{ .rep = &rep };
    forEachHeader(parts.head, &ctx, onHeader);
    if (ctx.bad_length) return error.BadResponse;

    // ⚠️ **返回栈上缓冲的切片 = 悬垂**。`raw` 和下面要分配的 `body` 一旦
    // 函数返回就没了，所以 body 必须 alloc 进调用方的分配器。
    // 这是本教程 29 章 agent 实测踩过的坑（打印看似正常、实则乱码）。
    const cl = rep.content_length orelse return error.BadResponse;
    const body = try a.alloc(u8, cl);
    errdefer a.free(body);

    // 头部之后已读的字节就是 body 的开头，剩下的按 Content-Length 补齐
    const got_already = parts.body.len;
    const n0 = @min(cl, got_already);
    @memcpy(body[0..n0], parts.body[0..n0]);
    if (n0 < cl) {
        // ⚠️ 这里就是「长度写大」的位置：等 cl-n0 字节，永远等不到。
        // 本函数把 EndOfStream 翻成 TruncatedBody，所以示例不会挂死。
        _ = conn.recvExact(body[n0..cl]) catch |e| switch (e) {
            error.ConnectionClosed => return error.TruncatedBody,
            else => return e,
        };
    }
    rep.body = body;
    return rep;
}

/// 发请求。`close=true` 让服务端发完就关（客户端好读到 EOF）。
fn sendRequest(conn: *Conn, method: []const u8, target: []const u8, body: []const u8, close: bool) !void {
    var buf: [1024]u8 = undefined;
    const req = if (body.len == 0)
        try std.fmt.bufPrint(
            &buf,
            "{s} {s} HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: {s}\r\n\r\n",
            .{ method, target, if (close) "close" else "keep-alive" },
        )
    else
        try std.fmt.bufPrint(
            &buf,
            "{s} {s} HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n" ++
                "Content-Length: {d}\r\n\r\n{s}",
            .{ method, target, body.len, body },
        );
    try conn.sendAll(req);
}

// ══════════════════════════════════════════════════════════════════
// 服务线程
// ══════════════════════════════════════════════════════════════════

/// 服务端实际绑定的端口。用原子发布给客户端线程——
/// 端口是"扫出来的"，客户端必须等它确定。
var srv_port: std.atomic.Value(u16) = std.atomic.Value(u16).init(0);

const ServerCtx = struct {
    /// 由 `startServer` 填。给默认值是为了让 `var ctx: ServerCtx = .{}` 能编译
    ///（`io` 是必填字段，而 main 里到处写 `.{}` 初始化 ctx）。
    io: std.Io = undefined,
    quota: usize = 1,
    limits: Limits = .{},
    /// 响应里Content-Length 故意写错（30.4 演示用），null = 按 body.len。
    bad_length: ?usize = null,
    /// 已服务连接数，供 main 断言。
    served: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    /// 见到的方法名（"GET"/"POST"/"HEAD"），供 main 断言。
    seen_method: [8]u8 = @splat(0),
    /// 请求体长度，供 main 断言。
    seen_body_len: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    /// bump 区：请求行 + 所有头部行的落地缓冲（**只进不退**）
    scratch: [8192]u8 = undefined,
    head_buf: [16]Header = undefined,
    body_buf: [4096]u8 = undefined,
};

/// 服务端线程主体：accept → 解析 → 路由 → 回包 →关连接。
///
/// **每连接一个 arena**：路由/序列化/JSON 的所有临时分配随连接生死，
/// 比"每处记得 free"的纪律性强一个量级。
///
/// **服务固定 quota 条连接后返回**——这是 29 章的结论：干完定量就退，
/// 比"标志位 + 强杀"干净得多（没有竞态窗口、没有悬挂句柄），
/// 而且 `join()` 就是同步点，main 不需要任何超时机制。
/// 这样 `./run-all.sh` **不可能挂死**：客户端发够 quota 条就一定收敛。
fn serve(ctx: *ServerCtx) void {
    const io = ctx.io;
    const l = listenFrom(io, port_base) catch {
        std.debug.print("  [server] listen 失败：{d}..{d} 全占\n", .{ port_base, port_base + probe_count });
        return;
    };
    var server = l.server;
    defer server.deinit(io);
    srv_port.store(l.port, .release); // 原子公布实际端口

    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();

    var n: usize = 0;
    while (n < ctx.quota) : (n += 1) {
        var conn = Conn.init(io, server.accept(io) catch return);
        defer conn.close();
        _ = arena_state.reset(.retain_capacity); // retain_capacity：复用已有页
        const a = arena_state.allocator();

        const req = parseRequest(Conn, &conn, &ctx.scratch, &ctx.head_buf, &ctx.body_buf, ctx.limits) catch |err| {
            // 解析失败：回一个状态码明确的错误响应，**别静默关连接**
            // （客户端只看到"空响应"，排查时完全看不出发生过什么）。
            const code: u16 = switch (err) {
                error.LineTooLong, error.TooManyHeaders => 431,
                error.BodyTooLarge => 413,
                error.ConnectionClosed => 0, // 对端自己跑了，别回包（回包会 EPIPE）
                else => 400,
            };
            if (code != 0) {
                var rep = Response{ .code = code, .reason = reasonPhrase(code), .body = @errorName(err) };
                if (ctx.bad_length) |bad| rep.content_length_override = bad;
                const raw = serialize(a, &rep) catch return;
                conn.sendAll(raw) catch return;
                std.debug.print("  [server] 解析失败 → {d} {s}（{s}）\n", .{ code, rep.reason, @errorName(err) });
            }
            continue;
        };

        var rep = route(a, &req) catch |err| blk: {
            // 路由处理函数出错 → **500，不是崩溃**。这是"每请求一个 arena +
            // catch 兜底"的标准姿势：单个坏请求不该带走整个服务。
            std.debug.print("  [server] 路由异常 → 500（{s}）\n", .{@errorName(err)});
            break :blk Response{ .code = 500, .reason = reasonPhrase(500), .body = "internal error" };
        };
        if (ctx.bad_length) |bad| rep.content_length_override = bad;
        const raw = serialize(a, &rep) catch return;
        conn.sendAll(raw) catch continue;

        @memcpy(ctx.seen_method[0..@min(req.method.len, ctx.seen_method.len)], req.method);
        ctx.seen_body_len.store(req.body.len, .release);
        ctx.served.store(n + 1, .release);
        std.debug.print(
            "  [server] {s} {s} → {d} {s}（体 {d} 字节，Content-Length={d}）\n",
            .{ req.method, req.path, rep.code, rep.reason, rep.body.len, rep.content_length_override orelse rep.body.len },
        );
    }
}

// ══════════════════════════════════════════════════════════════════
// URL 解析（30.8）
// ══════════════════════════════════════════════════════════════════

const Url = struct {
    scheme: []const u8,
    host: []const u8,
    port: u16,
    path: []const u8,
    query: []const u8,
};

/// `Uri.Component` 是 `union(enum) { raw, percent_encoded }`。
/// ⚠️ 它**没有 format 方法**——`{f}` 会编译错
/// ("no field or member function named 'format' in 'Uri.Component'")。
/// 要拿字符串只有两条路：`switch` 取 `.raw`/`.percent_encoded`（不解码）
/// 或 `toRawMaybeAlloc(arena)`（只在含 `%` 时才分配，会解码）。
fn uriRaw(c: std.Uri.Component) []const u8 {
    return switch (c) {
        .raw => |r| r,
        .percent_encoded => |r| r,
    };
}

fn parseUrl(a: std.mem.Allocator, text: []const u8) !Url {
    const u = try std.Uri.parse(text);
    const port: u16 = u.port orelse if (std.mem.eql(u8, u.scheme, "http")) 80 else 443;
    return .{
        .scheme = u.scheme,
        .host = if (u.host) |h| a.dupe(u8, uriRaw(h)) catch unreachable else "127.0.0.1",
        .port = port,
        .path = a.dupe(u8, uriRaw(u.path)) catch unreachable,
        .query = if (u.query) |q| a.dupe(u8, uriRaw(q)) catch unreachable else "",
    };
}

// ══════════════════════════════════════════════════════════════════
// main：11 个小节
// ══════════════════════════════════════════════════════════════════

/// 把响应的 CRLF 换成可见的 `\r\n` 记号，方便在终端里逐字节看报文。
fn showCrLf(a: std.mem.Allocator, raw: []const u8) ![]u8 {
    return std.mem.replaceOwned(u8, a, raw, "\r\n", "\\r\\n");
}

/// 起一个只服务 quota 条连接的服务端线程，等它把端口敲定，返回端口。
fn startServer(io: std.Io, quota: usize, limits: Limits, bad_length: ?usize, ctx: *ServerCtx) !std.Thread {
    ctx.io = io;
    ctx.quota = quota;
    ctx.limits = limits;
    ctx.bad_length = bad_length;
    srv_port.store(0, .release);
    const th = try std.Thread.spawn(.{}, serve, .{ctx});
    while (srv_port.load(.acquire) == 0) std.Thread.yield() catch {};
    return th;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const a = init.arena.allocator();
    const err = std.debug;

    // ── 30.1 报文解剖：一个请求的字节长什么样
    begin("30.1 报文解剖：CRLF 是结构的一部分");
    {
        const sample = "POST /api/echo HTTP/1.1\r\n" ++
            "Host: 127.0.0.1\r\n" ++
            "Content-Type: text/plain\r\n" ++
            "Content-Length: 5\r\n" ++
            "Connection: close\r\n" ++
            "\r\n" ++
            "hello";
        err.print("  原文（CRLF 用 ␍␊ 显示，\\0用␀）：\n    ", .{});
        for (sample) |ch| {
            // ⚠️ 直接 `print("{c}")` 会把 CR/LF 原样输出到终端——
            // 光标回车 / 换行，屏幕上什么都看不出来。控制字符必须转义显示。
            switch (ch) {
                '\r' => err.print("␍", .{}),
                '\n' => err.print("␊\n", .{}),
                0 => err.print("␀", .{}),
                else => err.print("{c}", .{ch}),
            }
        }
        err.print("\n", .{});
        // 按 CRLF 逐段拆解。⚠️ `tokenizeSequence` 会跳过空段，所以这里
        // **手工切**——而"头部结束的空行"恰恰就是要观察的那个空段。
        {
            var rest: []const u8 = sample;
            var idx: usize = 0;
            while (std.mem.indexOf(u8, rest, "\r\n")) |e| {
                const line = rest[0..e];
                if (line.len == 0) {
                    err.print("    [{d}] ␍␊← **空行**：头部到此结束，剩下的是体\n", .{idx});
                } else {
                    err.print("    [{d}] {s}␍␊\n", .{ idx, line });
                }
                idx += 1;
                rest = rest[e + 2 ..];
            }
            if (rest.len > 0) err.print("    [{d}] {s}← 体（后面没有 CRLF，它不是行）\n", .{ idx, rest });
        }
        err.print("\n  CRLF 的作用是**行分隔符**：没有它就无法从字节流里切出边界。\n", .{});
        err.print("  HTTP/1.1 规定：每个头以 CRLF 结束，CRLF CRLF 的第二个 CRLF 是空行、分隔头与体。\n", .{});
        err.print("  ⚠️ recvLine 必须**吃掉 CRLF 两个字节**——只吃 '\\r' 会让下一行\n", .{});
        err.print("     带上残留的 '\\n'，于是空行读出来长度是 1 而不是 0，\n", .{});
        err.print("     「读到空行就停」的头部循环直接失效（本章实测踩过）。\n", .{});
    }
    end("30.1 报文解剖：CRLF 是结构的一部分");

    // ── 30.2 手写行读取：三件套 vs takeDelimiterExclusive
    begin("30.2 手写行读取：fillMore + indexOfScalarPos + toss");
    {
        // 缓冲 Reader（数据已在手里）上 takeDelimiterExclusive 很好用
        var fr = std.Io.Reader.fixed("GET / HTTP/1.1\r\nHost: x\r\n\r\n");
        const l1 = fr.takeDelimiterExclusive('\n') catch "ERR";
        err.print("  缓冲 Reader 上 takeDelimiterExclusive：\n", .{});
        err.print("    第一行 = {x}\n", .{l1});
        err.print("    ↑结尾的 0d 就是 '\\r'——调用者得自己剔（这就是手写行解析的日常）\n", .{});

        // ⚠️ 但在**网络 Reader** 上它不阻塞：手上没数据就立刻返回空片。
        // 这个坑在 29 章 agent 实测里死过——服务端陷入
        //「读到空行 → 写 OK → 再读到空行」的死循环，日志里一片空行。
        // 空 Reader 上这个"不等数据"的语义最直观：
        var empty_r = std.Io.Reader.fixed("");
        if (empty_r.takeDelimiterExclusive('\n')) |_| {
            err.print("    空 Reader → 返回了切片\n", .{});
        } else |e| {
            err.print("    空 Reader → 立刻报 {s}（**它不会替你等数据**）\n", .{@errorName(e)});
        }
        err.print("\n  正确姿势（Conn.recvLine，三件套）：\n", .{});
        err.print("    ① fillMore()做一次底层读（唯一会阻塞的一步）\n", .{});
        err.print("    ② buffered() 看已就绪的字节（**不阻塞**）\n", .{});
        err.print("    ③ indexOfScalarPos(avail, scanned, '\\r') 找行尾\n", .{});
        err.print("    ④ toss(at + 2) 丢掉整对 CRLF —— **两个字节**（只吃 '\\r' 会留 '\\n' 害死下一行）\n", .{});
        err.print("  只有 ① 会等；② 看到的就是① 的成果，所以不会刷空行。\n", .{});
    }
    end("30.2 手写行读取：fillMore + indexOfScalarPos + toss");

    // ── 30.3 请求解析状态机（纯内存，可精确断言）
    begin("30.3 请求解析状态机：三步 + 三个上限");
    {
        const raw = "POST /api/echo?x=1 HTTP/1.1\r\n" ++
            "Host: 127.0.0.1\r\n" ++
            "Content-Type: text/plain\r\n" ++
            "Content-Length: 5\r\n" ++
            "\r\n" ++
            "hello";
        var sc: [8192]u8 = undefined;
        var hb: [16]Header = undefined;
        var bb: [4096]u8 = undefined;
        const req = try parseFixed(raw, .{}, &sc, &hb, &bb);
        err.print("  方法   = {s}\n", .{req.method});
        err.print("  目标   = {s}\n", .{req.target});
        err.print("  版本   = {s}\n", .{req.version});
        err.print("  path   = {s}（'?' 之前）\n", .{req.path});
        err.print("  query  = {s}（'?' 之后）\n", .{req.query});
        err.print("  头部   = {d} 行：", .{req.headers.len});
        for (req.headers) |h| err.print(" [{s}: {s}]", .{ h.name, h.value });
        err.print("\n  体     = {s}（按 Content-Length=5 读，不是把空行之后的全拿走）\n", .{req.body});
        err.print("  keepAlive = {}（Connection 缺省 = true）\n", .{req.keepAlive()});

        // 三个上限各自的触发点。⚠️ 0.17 里 `**` 运算符已移除，
        // 而 `++` 拼接要求两边都是 comptime 已知切片——所以"构造超长行"
        // 这种测试基础设施得自己写（见 makeLongLine / errNameOf）。
        err.print("\n  上限一 line={d}：请求行 138 字符，把 line 上限调到 64 → {s}\n", .{
            (Limits{}).line,
            errNameOf(makeLongLine(117), .{ .line = 64 }, &sc, &hb, &bb),
        });
        err.print("           同样的行，默认上限 {d} → {s}（合法）\n", .{
            (Limits{}).line,
            errNameOf(makeLongLine(117), .{}, &sc, &hb, &bb),
        });
        err.print("  上限二 headers={d}：20 个头（每个 \"x-hN: v\"）→ {s}\n", .{ (Limits{}).headers, errNameOf(manyHeadersRaw(), .{}, &sc, &hb, &bb) });
        err.print("  上限三 body  = {d}：Content-Length:999999 → {s}\n", .{
            (Limits{}).body,
            errNameOf("GET / HTTP/1.1\r\nContent-Length: 999999\r\n\r\n", .{}, &sc, &hb, &bb),
        });
    }
    end("30.3 请求解析状态机：三步 + 三个上限");

    // ── 30.4 响应构造与 Content-Length 的致命性
    begin("30.4 响应构造：Content-Length 写错就挂死客户端");
    {
        const good = Response{ .code = 200, .body = "hello" };
        err.print("  ✓ 正确：体 5 字节，Content-Length 也写 5\n", .{});
        err.print("    {s}\n", .{try showCrLf(a, try serialize(a, &good))});

        // 长度写**大**：客户端按 CL 等 20 字节，服务端只发了 5 个就close
        // → 若连接不关（keep-alive），客户端永远等那 15 个 → 挂死。
        const big = Response{ .code = 200, .body = "hello", .content_length_override = 20 };
        err.print("\n  ✗ 写大：Content-Length=20 但体只有 5 字节\n", .{});
        err.print("    {s}\n", .{try showCrLf(a, try serialize(a, &big))});
        err.print("    → 客户端 recvExact 等剩余 15 字节。⚠️ 若服务端不 close 连接（keep-alive）它就挂死。\n", .{});

        // 长度写**小**：客户端数够 CL 就停，剩下的字节被当下一个响应的开头
        // → keep-alive 下彻底错位。
        const small = Response{ .code = 200, .body = "hello", .content_length_override = 2, .close = false };
        err.print("\n  ✗ 写小：Content-Length=2 但体有 5 字节（keep-alive）\n", .{});
        err.print("    {s}\n", .{try showCrLf(a, try serialize(a, &small))});
        err.print("    → 客户端读完 2 字节就停，剩下 \"llo\" 被当下一条响应的状态行 → 解析失败。\n", .{});

        // 两种"正确"姿势
        err.print("\n  ⇒ Content-Length 的唯一正确算法：`body.len`。永远别手输这个数字。\n", .{});
        err.print("  ⇒ 另一种正确姿势：不发 Content-Length，改用 Connection: close + 读到 EOF。\n", .{});

        // 真往返两次：让服务端故意写错的 CL，看客户端分别拿到什么。
        {
            // ① CL 写**大**（2000，真实体约 120 字节）→ 客户端永远等不到 → TruncatedBody
            var ctx: ServerCtx = .{};
            const th = try startServer(io, 1, .{}, 2000, &ctx);
            const port = srv_port.load(.acquire);
            if (fetchByLength(a, io, port, "GET", "/api/info")) |ok| {
                err.print("\n  实测① CL 写大：客户端读到 {d} 字节就停下\n", .{ok.body.len});
            } else |e| {
                err.print("\n  实测① CL 写大（2000，真实体约 120 字节）：\n", .{});
                err.print("    按 CL 读的客户端拿到 {s} —— **没有挂死**，因为对端 close 了，\n", .{@errorName(e)});
                err.print("    fillMore 返回 EndOfStream，我们把它翻译成一个可诊断的错误。\n", .{});
            }
            th.join();
            err.print("    ⚠️ 若服务端**不** close（keep-alive），同一个客户端就永久等待——\n", .{});
            err.print("       没有任何超时机制能救你。这就是「长度必须一次写对」的全部理由。\n", .{});
        }
        {
            // ② CL 写**小**（5）→ 客户端数够就停，**静默截断**，连错误都不报
            var ctx2: ServerCtx = .{};
            const th2 = try startServer(io, 1, .{}, 5, &ctx2);
            const port2 = srv_port.load(.acquire);
            if (fetchByLength(a, io, port2, "GET", "/api/info")) |ok| {
                err.print("\n  实测② CL 写小（5，真实体约 120 字节）：\n", .{});
                err.print("    客户端拿到 {d} 字节：{s}\n", .{ ok.body.len, ok.body });
                err.print("    ⚠️ **静默截断，连错误都没有** —— 比挂死更难查：JSON 解析在半路炸，\n", .{});
                err.print("       而报错的栈指向客户端，跟真正的原因隔着一条网络。\n", .{});
            } else |e| {
                err.print("\n  实测② CL 写小 → {s}\n", .{@errorName(e)});
            }
            th2.join();
        }
    }
    end("30.4 响应构造：Content-Length 写错就挂死客户端");

    // ── 30.5 路由：精确 / 前缀 / 404 / 405
    begin("30.5 路由：精确匹配、前缀匹配、404/405");
    {
        const cases = [_]struct { m: []const u8, p: []const u8 }{
            .{ .m = "GET", .p = "/" },
            .{ .m = "GET", .p = "/api/rand" },
            .{ .m = "GET", .p = "/static/css/main.css" },
            .{ .m = "GET", .p = "/api/echo" }, // path 命中，方法不对
            .{ .m = "GET", .p = "/nope" },
        };
        for (cases) |c| {
            switch (lookup(c.m, c.p)) {
                .route => |r| err.print("  {s: <5} {s: <24} → 命中 {s}\n", .{ c.m, c.p, r.name }),
                .method_mismatch => err.print("  {s: <5} {s: <24} → 405 method not allowed\n", .{ c.m, c.p }),
                .none => err.print("  {s: <5} {s: <24} → 404 not found\n", .{ c.m, c.p }),
            }
        }
        err.print("\n  405 与 404 的区别是真实的：405 该带 Allow 头说\"用这些方法重试\"，\n", .{});
        err.print("  404 不该泄露\"这个路径存在，只是你不能这样访问\"。\n", .{});
        err.print("  方法不在白名单（DELETE）走的是 **501**，不是 405：\n", .{});
        err.print("    lookup 只看已注册路由，DELETE 压根没注册任何 path → 404；\n", .{});
        err.print("    501 来自 route() 开头的方法白名单，它在路由之前。\n", .{});
    }
    end("30.5 路由：精确匹配、前缀匹配、404/405");

    // ── 30.6 JSON 响应：参数顺序
    begin("30.6 JSON 响应：Stringify.value 的 writer 在最后");
    {
        const Payload = struct { n: u32, values: []const u32, service: []const u8 };
        var jw = std.Io.Writer.Allocating.init(a);
        try std.json.Stringify.value(Payload{ .n = 3, .values = &.{ 7, 8, 9 }, .service = "zhttp" }, .{}, &jw.writer);
        err.print("  签名：Stringify.value(value, options, writer) ← **writer 在最后**\n", .{});
        err.print("  写错顺序的实测报错：\n", .{});
        err.print("    error: expected type 'json.Stringify.Options', found pointer\n", .{});
        err.print("    note: address-of operator always returns a pointer\n", .{});
        err.print("  输出：{s}\n", .{jw.written()});

        var jw2 = std.Io.Writer.Allocating.init(a);
        try std.json.Stringify.value("a\"b\n", .{}, &jw2.writer);
        err.print("  转义：{s}（引号与换行被转义，客户端不用再处理）\n", .{jw2.written()});

        var jw3 = std.Io.Writer.Allocating.init(a);
        try std.json.Stringify.value(.{ .a = 1, .b = "x" }, .{ .whitespace = .indent_2 }, &jw3.writer);
        err.print("  缩进选项 .whitespace = .indent_2：\n    {s}\n", .{jw3.written()});
    }
    end("30.6 JSON 响应：Stringify.value 的 writer 在最后");

    // ── 30.7 keep-alive vs close
    begin("30.7 keep-alive vs close：两种读法");
    {
        err.print("  Connection: close\n", .{});
        err.print("    读法：读到 EOF（fetchToEof）\n", .{});
        err.print("    优点：不需要信任 Content-Length，对端崩在半路也收到已有字节\n", .{});
        err.print("    缺点：一条连接一个请求，每次都要 TCP 三次握手\n", .{});
        err.print("  Connection: keep-alive\n", .{});
        err.print("    读法：按 Content-Length 数字节（fetchByLength）\n", .{});
        err.print("    优点：连接复用（Nginx / 浏览器都走这条）\n", .{});
        err.print("    缺点：CL 写错就错位或挂死，还要处理 pipelining 与空闲超时\n", .{});
        err.print("\n  本示例两种都实现，下面 30.9 各跑一次。\n", .{});
        err.print("  真正生产服务还有第三条路：chunked 编码（长度未知时的流式体），\n", .{});
        err.print("  std.http.ChunkParser 就是它——手写版没做，这是省略而非不存在。\n", .{});
    }
    end("30.7 keep-alive vs close：两种读法");

    // ── 30.8 URL 解析
    begin("30.8 URL 解析：std.Uri 的形状");
    {
        const abs1 = try parseUrl(a, "http://127.0.0.1:8080/api/rand?n=5");
        err.print("  http://127.0.0.1:8080/api/rand?n=5\n", .{});
        err.print("    scheme={s} host={s} port={d} path={s} query={s}\n", .{ abs1.scheme, abs1.host, abs1.port, abs1.path, abs1.query });

        const abs2 = try parseUrl(a, "http://example.com/x");
        err.print("  http://example.com/x（无端口）→ port={d}（http 缺省 80）\n", .{abs2.port});

        const abs3 = try parseUrl(a, "http://h/a%20b");
        err.print("  http://h/a%20b（百分号编码）→ path={s}（raw 不解码）\n", .{abs3.path});
        err.print("    要解码用 toRawMaybeAlloc(arena)，它只在含 '%' 时才分配\n", .{});

        const bad_cases = [_][]const u8{ "not a url at all", "/just/a/path", "", "*", "http://h:99999/", "ht tp://x" };
        err.print("  错误实测（std.Uri 只吃**绝对** URL）：\n", .{});
        for (bad_cases) |bad| {
            const code = if (std.Uri.parse(bad)) |_| @as([]const u8, "ok") else |e| @errorName(e);
            err.print("    {s: <22} → {s}\n", .{ bad, code });
        }
        err.print("  ⚠️ Uri.Component **没有 format 方法** —— {{f}} 编译不过：\n", .{});
        err.print("     error: no field or member function named 'format' in 'Uri.Component'\n", .{});
        err.print("     取字符串只有两条路：switch .raw/.percent_encoded，或 toRawMaybeAlloc(arena)。\n", .{});
        err.print("  ⚠️ parseIp4 的错误名也不是 InvalidAddress，实测是：\n", .{});
        err.print("     999.1.1.1 → Overflow   1.2.3 → Incomplete   localhost → InvalidCharacter\n", .{});
    }
    end("30.8 URL 解析：std.Uri 的形状");

    // ── 30.9 完整往返：服务端线程 + 客户端 + 断言
    begin("30.9 完整往返：服务端线程 + 客户端请求 + 断言");
    {
        // 往返 1：GET / —— 读到 EOF
        var ctx: ServerCtx = .{};
        const th = try startServer(io, 1, .{}, null, &ctx);
        const port = srv_port.load(.acquire);
        err.print("  服务端就绪 127.0.0.1:{d}（从 {d} 起扫 {d} 个高位端口）\n", .{ port, port_base, probe_count });

        const home = try fetchToEof(a, io, port, "GET", "/", "");
        err.print("\n  GET /（读到 EOF）→ {d} {s}，体 {d} 字节\n", .{ home.code, home.reason, home.body.len });
        err.print("    {s}\n", .{home.body});
        try expectEq(@as(u16, 200), home.code);
        try expectContains(home.body, "zhttp");
        th.join();
        try expectEq(@as(usize, 1), ctx.served.load(.acquire));

        // 往返 2：GET /api/rand?n=5 —— 按 Content-Length 读
        var ctx2: ServerCtx = .{};
        const th2 = try startServer(io, 1, .{}, null, &ctx2);
        const port2 = srv_port.load(.acquire);
        const rnd = try fetchByLength(a, io, port2, "GET", "/api/rand?n=5");
        err.print("\n  GET /api/rand?n=5（按 Content-Length={d} 读）→ {d} {s}\n", .{ rnd.content_length.?, rnd.code, rnd.reason });
        err.print("    {s}\n", .{rnd.body});
        try expectEq(@as(u16, 200), rnd.code);
        try expectContains(rnd.body, "\"values\"");
        try expectContains(rnd.body, "\"service\":\"zhttp\"");
        try expectEq(@as(usize, 1), ctx2.served.load(.acquire));
        // GET 没有 Content-Length → 服务端看到的体是空的（这是 30.3 的断言，
        // 放到真实 socket 上再验一次）
        try expectEq(@as(usize, 0), ctx2.seen_body_len.load(.acquire));
        th2.join();

        // 往返 3：POST /api/echo —— 请求带体，验证"按 Content-Length 读体"
        var ctx3: ServerCtx = .{};
        const th3 = try startServer(io, 1, .{}, null, &ctx3);
        const port3 = srv_port.load(.acquire);
        const echo = try fetchToEof(a, io, port3, "POST", "/api/echo", "hello");
        err.print("\n  POST /api/echo，体 \"hello\" → {d} {s}\n", .{ echo.code, echo.reason });
        err.print("    {s}\n", .{echo.body});
        try expectEq(@as(u16, 200), echo.code);
        try expectContains(echo.body, "\"body\":\"hello\"");
        // 服务端确实按 Content-Length 收到了 5 字节
        try expectEq(@as(usize, 5), ctx3.seen_body_len.load(.acquire));
        try expectEqualStrings("POST", std.mem.sliceTo(&ctx3.seen_method, 0));
        th3.join();

        err.print("\n  ✓ 全链路：解析请求 → 路由 → 序列化响应 → 客户端解析，三个断言全过。\n", .{});
        err.print("  ✓ 服务端各服务 1 条连接即退（quota），join() 即同步——不会挂死。\n", .{});
    }
    end("30.9 完整往返：服务端线程 + 客户端请求 + 断言");

    // ── 30.10 错误处理
    begin("30.10 错误处理：404 / 405 / 501 / 畸形头 / 超长行");
    {
        // 路由层的错误：每一个用独立的一次连接（quota=1）
        const cases = [_]struct { m: []const u8, t: []const u8, label: []const u8, expect: u16 }{
            .{ .m = "GET", .t = "/nope", .label = "路径不存在", .expect = 404 },
            .{ .m = "GET", .t = "/api/echo", .label = "path 存在方法不对", .expect = 405 },
            .{ .m = "DELETE", .t = "/", .label = "方法不在白名单", .expect = 501 },
            .{ .m = "GET", .t = "/static/css/a.css", .label = "前缀路由命中", .expect = 200 },
        };
        for (cases) |c| {
            var ctx: ServerCtx = .{};
            const th = try startServer(io, 1, .{}, null, &ctx);
            const p = srv_port.load(.acquire);
            const rep = try fetchToEof(a, io, p, c.m, c.t, "");
            th.join();
            // ⚠️ 0.17 的 `{s:<N}` 是**截断**到 N 字节，不是"至少 N 宽"的最小宽度——
            // "Not Found" 写成 `{s: <26}` 会被腰斩成 "Not"。要最小宽度就别加 `<`。
            err.print("  {s: <7} {s: <22} → {d} {s}  体={s}\n", .{ c.m, c.label, rep.code, rep.reason, rep.body });
            try expectEq(c.expect, rep.code);
        }

        // 解析层的错误：裸 TCP 发畸形请求，看服务端回什么
        const malformed = [_]struct { raw: []const u8, label: []const u8, expect: u16 }{
            .{ .raw = "GET / HTTP/1.1 extra\r\nHost: x\r\n\r\n", .label = "请求行四个分段", .expect = 400 },
            .{ .raw = "GET /\r\n\r\n", .label = "请求行只有两段", .expect = 400 },
            .{ .raw = "GET / SPDY/3\r\n\r\n", .label = "版本号不对", .expect = 400 },
            .{ .raw = "GET / HTTP/1.1\r\nBADHEADER\r\n\r\n", .label = "头部行无冒号", .expect = 400 },
            .{ .raw = "GET / HTTP/1.1\r\nContent-Length: 999999\r\n\r\n", .label = "体超上限", .expect = 413 },
            .{ .raw = "GET /aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa HTTP/1.1\r\n\r\n", .label = "请求行 120 字符 >上限 64", .expect = 431 },
        };
        for (malformed) |m| {
            var ctx: ServerCtx = .{ .limits = .{ .line = 64 } };
            const th = try startServer(io, 1, ctx.limits, null, &ctx);
            const p = srv_port.load(.acquire);
            var conn = Conn.init(io, try connectTo(io, p));
            try conn.sendAll(m.raw);
            var buf: [512]u8 = undefined;
            const n = try conn.recvSome(&buf);
            conn.close(); // 显式关；**不能**再 defer close（Stream.close 不幂等）
            th.join();
            err.print("  {s: <20} → {s}\n", .{ m.label, firstLine(buf[0..n]) });
            try expect(containsCode(buf[0..n], m.expect));
        }

        err.print("\n  关键设计：解析失败**也要回一个带状态码的响应**。\n", .{});
        err.print("  静默 close 的话客户端只看到\"空响应\"，排查时完全看不出发生过什么。\n", .{});
        err.print("  唯一例外是对端自己跑了（ConnectionClosed）——回包会 EPIPE。\n", .{});
    }
    end("30.10 错误处理：404 / 405 / 501 / 畸形头 / 超长行");

    // ── 30.11 为什么生产环境不要自己写 HTTP
    begin("30.11 生产环境：std.http.Client / Server 实测存在");
    {
        err.print("  std.http.Client 存在 = {}\n", .{@hasDecl(std.http, "Client")});
        err.print("  std.http.Server  存在 = {}\n", .{@hasDecl(std.http, "Server")});
        err.print("  其它部件：HeadParser={} ChunkParser={} HeaderIterator={}\n", .{
            @hasDecl(std.http, "HeadParser"),
            @hasDecl(std.http, "ChunkParser"),
            @hasDecl(std.http, "HeaderIterator"),
        });
        err.print("  Client 关键方法：fetch={} request={} connect={} initDefaultProxies={}\n", .{
            @hasDecl(std.http.Client, "fetch"),
            @hasDecl(std.http.Client, "request"),
            @hasDecl(std.http.Client, "connect"),
            @hasDecl(std.http.Client, "initDefaultProxies"),
        });
        err.print("  Server 关键方法：init={} receiveHead={} Request={} WebSocket={}\n", .{
            @hasDecl(std.http.Server, "init"),
            @hasDecl(std.http.Server, "receiveHead"),
            @hasDecl(std.http.Server, "Request"),
            @hasDecl(std.http.Server, "WebSocket"),
        });
        err.print("  std.http.Method（{d} 个）：", .{@typeInfo(std.http.Method).@"enum".field_names.len});
        inline for (@typeInfo(std.http.Method).@"enum".field_names) |f| {
            std.debug.print(" {s}", .{f});
        }
        std.debug.print("\n", .{});
        err.print("  std.http.Status 有 {d} 个成员（含 teapot / loop_detected / im_used…）\n", .{
            @typeInfo(std.http.Status).@"enum".field_names.len,
        });
        err.print("  fetch 的返回：FetchResult = {{ .status: http.Status }}\n", .{});
        err.print("\n  ⇒ 生产环境该用 std.http：它已经处理了keep-alive 连接池、重定向、\n", .{});
        err.print("    chunked 编码、gzip/zstd 解压、TLS、超时。\n", .{});
        err.print("  ⇒ 本章手写版只为了让你看懂报文——**两者处理的是同一个协议**，\n", .{});
        err.print("    不是两种协议。框架没魔法，只是把这些边界替你写了。\n", .{});
    }
    end("30.11 生产环境：std.http.Client / Server 实测存在");

    err.print("\n自检通过\n", .{});
}

// ══════════════════════════════════════════════════════════════════
// 小工具
// ══════════════════════════════════════════════════════════════════

fn firstLine(raw: []const u8) []const u8 {
    const e = std.mem.indexOf(u8, raw, "\r\n") orelse raw.len;
    return raw[0..e];
}

/// 把 `s` 重复 `n` 次拼成新串。
/// ⚠️ 0.17 移除了 `**` 运算符（`"ab" ** 3` 没了），这类"构造超长输入"
/// 的活儿得自己写——而且**测试里构造畸形输入正需要它**。
fn repeat(s: []const u8, n: usize) []u8 {
    const out = std.heap.page_allocator.alloc(u8, s.len * n) catch unreachable;
    for (0..n) |i| @memcpy(out[i * s.len ..][0..s.len], s);
    return out;
}

/// 造一条路径里有 `pad` 个 'a' 的 GET 请求行（用来触发 line 上限）。
/// ⚠️ `++` 的两边都必须是 **comptime 已知**切片，所以运行时 `repeat()` 的
/// 结果不能直接 `++` 字面量——0.17 报
/// "slice being concatenated must be comptime-known"。只能逐段 memcpy。
fn makeLongLine(pad: usize) []u8 {
    const head = "GET /";
    const tail = " HTTP/1.1\r\n\r\n";
    const out = std.heap.page_allocator.alloc(u8, head.len + pad + tail.len) catch unreachable;
    @memcpy(out[0..head.len], head);
    @memset(out[head.len..][0..pad], 'a');
    @memcpy(out[head.len + pad ..][0..tail.len], tail);
    return out;
}

fn containsCode(raw: []const u8, code: u16) bool {
    var buf: [8]u8 = undefined;
    const want = std.fmt.bufPrint(&buf, "{d} ", .{code}) catch return false;
    return std.mem.indexOf(u8, raw, want) != null;
}

/// 造一条带 20 个头的请求（用来触发 headers 上限）。
fn manyHeadersRaw() []const u8 {
    var raw: [512]u8 = undefined;
    var w = std.Io.Writer.fixed(&raw);
    w.writeAll("GET / HTTP/1.1\r\n") catch unreachable;
    for (0..20) |i| {
        w.print("x-h{d}: v\r\n", .{i}) catch unreachable;
    }
    w.writeAll("\r\n") catch unreachable;
    return w.buffered();
}

/// 把 `parseFixed` 的结果压成**错误名字符串**：成功返回 "OK"。
///
/// ⚠️ 这里体现了 0.17 的一条硬约束：`catch |e| e` 的类型是
/// `anyerror || Request`——**错误联合与结构体不能 switch/统一**。
/// 所以别想把"成功值"和"错误"塞进同一个联合里让 print 统一处理，
/// 必须在这里就把成功分支塌成字符串。
fn errNameOf(
    raw: []const u8,
    limits: Limits,
    scratch: []u8,
    head_buf: []Header,
    body_buf: []u8,
) []const u8 {
    const res = parseFixed(raw, limits, scratch, head_buf, body_buf) catch |e| return @errorName(e);
    _ = res;
    return "OK（解析成功）";
}

fn expect(ok: bool) !void {
    if (!ok) return error.AssertionFailed;
}

fn expectEq(expected: anytype, actual: @TypeOf(expected)) !void {
    if (expected != actual) return error.AssertionFailed;
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    if (std.mem.indexOf(u8, haystack, needle) == null) return error.MarkerMissing;
}

fn expectEqualStrings(expected: []const u8, actual: []const u8) !void {
    if (!std.mem.eql(u8, expected, actual)) return error.StringsDiffer;
}

// ══════════════════════════════════════════════════════════════════
// 测试：全部零 IO —— 状态机靠 FixedConn，路由 / 序列化 / URL 靠纯函数
// ══════════════════════════════════════════════════════════════════

test "请求行解析：方法/目标/版本/path/query 切分" {
    const raw = "GET /api/rand?n=5&x=1 HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n";
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    const req = try parseFixed(raw, .{}, &sc, &hb, &bb);
    try std.testing.expectEqualStrings("GET", req.method);
    try std.testing.expectEqualStrings("/api/rand?n=5&x=1", req.target);
    try std.testing.expectEqualStrings("HTTP/1.1", req.version);
    try std.testing.expectEqualStrings("/api/rand", req.path);
    try std.testing.expectEqualStrings("n=5&x=1", req.query);
    try std.testing.expectEqual(@as(usize, 1), req.headers.len);
    try std.testing.expectEqualStrings("127.0.0.1", req.headers[0].value);
    try std.testing.expect(req.keepAlive());
    try std.testing.expectEqualStrings("5", queryParam(req.query, "n").?);
}

test "请求头：大小写不敏感 + 冒号后空白被剔除 + Connection: close" {
    const raw = "POST /x HTTP/1.1\r\ncontent-LENGTH: 3\r\nX-A:   v  \r\nConnection: close\r\n\r\nabc";
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    const req = try parseFixed(raw, .{}, &sc, &hb, &bb);
    try std.testing.expectEqualStrings("3", req.header("Content-Length").?);
    try std.testing.expectEqualStrings("3", req.header("content-length").?);
    try std.testing.expectEqualStrings("v  ", req.header("x-a").?);
    try std.testing.expectEqualStrings("abc", req.body);
    try std.testing.expect(!req.keepAlive());
}

test "GET 无 Content-Length 时体为空" {
    const raw = "GET / HTTP/1.1\r\nHost: x\r\n\r\n";
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    const req = try parseFixed(raw, .{}, &sc, &hb, &bb);
    try std.testing.expectEqual(@as(usize, 0), req.body.len);
}

test "状态机拒绝：畸形请求行（四段/ 两段 / 版本错）" {
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    try std.testing.expectError(error.MalformedRequestLine, parseFixed("GET / HTTP/1.1 x\r\n\r\n", .{}, &sc, &hb, &bb));
    try std.testing.expectError(error.MalformedRequestLine, parseFixed("GET /\r\n\r\n", .{}, &sc, &hb, &bb));
    try std.testing.expectError(error.MalformedRequestLine, parseFixed("GET / SPDY/3\r\n\r\n", .{}, &sc, &hb, &bb));
    // 只有请求行、没有空行 → 对端先跑了
    try std.testing.expectError(error.ConnectionClosed, parseFixed("GET / HTTP/1.1\r\n", .{}, &sc, &hb, &bb));
    // 恰好三段是**合法**的：HTTP/1.1 的最小请求行就是 "GET / HTTP/1.1"
    const ok_req = try parseFixed("GET / HTTP/1.1\r\n\r\n", .{}, &sc, &hb, &bb);
    try std.testing.expectEqualStrings("GET", ok_req.method);
}

test "上限一：请求行超 line 上限" {
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    // 请求行 138 字符 < 默认上限 1024 →合法；
    // 把 line 上限调到 64 →立刻 LineTooLong。这正是"上限是配置项"的含义。
    const huge = makeLongLine(117);
    // 默认上限 1024：138 字符的请求行合法
    _ = try parseFixed(huge, .{}, &sc, &hb, &bb);
    // 上限调到 64 →立刻 LineTooLong
    try std.testing.expectError(error.LineTooLong, parseFixed(huge, .{ .line = 64 }, &sc, &hb, &bb));
}

test "状态机拒绝：头部无冒号 / Content-Length 非法" {
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    try std.testing.expectError(error.MalformedHeader, parseFixed("GET / HTTP/1.1\r\nBADHEADER\r\n\r\n", .{}, &sc, &hb, &bb));
    try std.testing.expectError(error.MalformedHeader, parseFixed("GET / HTTP/1.1\r\nContent-Length: abc\r\n\r\n", .{}, &sc, &hb, &bb));
}

test "上限二：头部行数超 headers 上限" {
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    const raw = "GET / HTTP/1.1\r\na: 1\r\nb: 2\r\nc: 3\r\nd: 4\r\ne: 5\r\n\r\n";
    try std.testing.expectError(error.TooManyHeaders, parseFixed(raw, .{ .headers = 4 }, &sc, &hb, &bb));
}

test "上限三：Content-Length 超 body 上限" {
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    try std.testing.expectError(
        error.BodyTooLarge,
        parseFixed("GET / HTTP/1.1\r\nContent-Length: 99999\r\n\r\n", .{}, &sc, &hb, &bb),
    );
    // 恰好等于上限则**通过上限检查**（随后因体没到而 ConnectionClosed）
    try std.testing.expectError(
        error.ConnectionClosed,
        parseFixed("POST / HTTP/1.1\r\nContent-Length: 4096\r\n\r\n", .{}, &sc, &hb, &bb),
    );
}

test "对端提前关闭 → ConnectionClosed" {
    var sc: [8192]u8 = undefined;
    var hb: [16]Header = undefined;
    var bb: [4096]u8 = undefined;
    try std.testing.expectError(error.ConnectionClosed, parseFixed("", .{}, &sc, &hb, &bb));
    // 头有体但体没到
    try std.testing.expectError(
        error.ConnectionClosed,
        parseFixed("POST / HTTP/1.1\r\nContent-Length: 10\r\n\r\nabc", .{}, &sc, &hb, &bb),
    );
}

test "查询参数：多键 / 空值 / 缺省" {
    try std.testing.expectEqualStrings("5", queryParam("n=5", "n").?);
    try std.testing.expectEqualStrings("1", queryParam("a=1&b=2", "a").?);
    try std.testing.expectEqualStrings("2", queryParam("a=1&b=2", "b").?);
    try std.testing.expectEqualStrings("", queryParam("a=&b=2", "a").?);
    try std.testing.expect(queryParam("a=1", "z") == null);
    try std.testing.expect(queryParam("", "a") == null);
}

test "响应序列化：状态行 + CL 算对 + close 头" {
    const a = std.testing.allocator;
    const rep = Response{ .code = 200, .reason = "OK", .content_type = "text/plain", .body = "hi" };
    const raw = try serialize(a, &rep);
    defer a.free(raw);
    try std.testing.expect(std.mem.startsWith(u8, raw, "HTTP/1.1 200 OK\r\n"));
    try std.testing.expect(std.mem.indexOf(u8, raw, "Content-Length: 2\r\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, raw, "\r\n\r\nhi"));
    try std.testing.expect(std.mem.indexOf(u8, raw, "Connection: close\r\n") != null);
}

test "响应序列化：keep-alive 时无 close 头" {
    const a = std.testing.allocator;
    const rep = Response{ .code = 404, .reason = "Not Found", .close = false, .body = "nope" };
    const raw = try serialize(a, &rep);
    defer a.free(raw);
    try std.testing.expect(std.mem.indexOf(u8, raw, "Connection: keep-alive\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, raw, "Content-Length: 4\r\n") != null);
}

test "Content-Length 写大 → 客户端按 CL 要 20 字节，实际只有 5" {
    const a = std.testing.allocator;
    // 服务端声称 20 字节但只发 5 字节
    const rep = Response{ .code = 200, .body = "hello", .content_length_override = 20 };
    const raw = try serialize(a, &rep);
    defer a.free(raw);
    const parts = try splitHead(raw);
    try std.testing.expectEqualStrings("hello", parts.body);
    // 客户端按 CL 要 20 字节，实际只有 5 → 差 15 字节永远等不到
    var parsed = Reply{};
    var ctx = HeadCtx{ .rep = &parsed };
    forEachHeader(parts.head, &ctx, onHeader);
    try std.testing.expectEqual(@as(usize, 20), parsed.content_length.?);
    try std.testing.expectEqual(@as(usize, 15), parsed.content_length.? - parts.body.len);
}

test "Content-Length 写小 → 客户端静默截断（更隐蔽）" {
    const a = std.testing.allocator;
    const rep = Response{ .code = 200, .body = "hello", .content_length_override = 2, .close = false };
    const raw = try serialize(a, &rep);
    defer a.free(raw);
    const parts = try splitHead(raw);
    var parsed = Reply{};
    var ctx = HeadCtx{ .rep = &parsed };
    forEachHeader(parts.head, &ctx, onHeader);
    // 客户端数够 2 就停 → 只拿到 "he"，剩下 "llo" 被当下一条响应的开头
    try std.testing.expectEqual(@as(usize, 2), parsed.content_length.?);
    try std.testing.expect(parts.body.len > parsed.content_length.?);
    try std.testing.expectEqualStrings("he", parts.body[0..2]);
}

test "路由：精确 / 前缀 / 405 / 404" {
    switch (lookup("GET", "/")) {
        .route => |r| try std.testing.expectEqualStrings("home", r.name),
        else => return error.TestUnexpectedResult,
    }
    switch (lookup("GET", "/static/css/a.css")) {
        .route => |r| try std.testing.expectEqualStrings("static", r.name),
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expect(lookup("GET", "/api/echo") == .method_mismatch);
    try std.testing.expect(lookup("GET", "/nope") == .none);
}

/// 测试里 `route`/`parseUrl` 会分配（JSON 缓冲、dupe 出来的字符串）。
/// 用 arena 包一层 `std.testing.allocator`：**泄漏检测依然有效**——
/// `arena.deinit()` 会把底下所有块还给 SafeAllocator，一块漏掉照样报。
/// 但不用为每处 JSON 缓冲写 `defer free`，测试读起来干净得多。
/// 这也正是生产代码里"每请求一个 arena"（30.7）的同一套姿势。
fn testArena() std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(std.testing.allocator);
}

test "路由：501 来自方法白名单，在路由之前" {
    var arena = testArena();
    defer arena.deinit();
    const a = arena.allocator();
    var req = Request{ .method = "DELETE", .path = "/" };
    const rep = try route(a, &req);
    try std.testing.expectEqual(@as(u16, 501), rep.code);
    // 小写的 get 不是 GET（HTTP 方法区分大小写）
    var req2 = Request{ .method = "get", .path = "/" };
    const rep2 = try route(a, &req2);
    try std.testing.expectEqual(@as(u16, 501), rep2.code);
}

test "路由：JSON 响应体正确（含 clamp 与 parseInt 失败兜底）" {
    var arena = testArena();
    defer arena.deinit();
    const a = arena.allocator();
    var req = Request{ .method = "GET", .path = "/api/rand", .query = "n=3" };
    const rep = try route(a, &req);
    try std.testing.expectEqual(@as(u16, 200), rep.code);
    try std.testing.expect(std.mem.indexOf(u8, rep.body, "\"n\":3") != null);

    var req2 = Request{ .method = "GET", .path = "/api/rand", .query = "n=999" };
    const rep2 = try route(a, &req2);
    try std.testing.expect(std.mem.indexOf(u8, rep2.body, "\"n\":16") != null);

    var req3 = Request{ .method = "GET", .path = "/api/rand", .query = "n=abc" };
    const rep3 = try route(a, &req3);
    try std.testing.expect(std.mem.indexOf(u8, rep3.body, "\"n\":1") != null);

    var req4 = Request{ .method = "GET", .path = "/api/rand", .query = "" };
    const rep4 = try route(a, &req4);
    try std.testing.expect(std.mem.indexOf(u8, rep4.body, "\"n\":1") != null);
}

test "路由：POST /api/echo 回显体" {
    var arena = testArena();
    defer arena.deinit();
    const a = arena.allocator();
    var req = Request{ .method = "POST", .path = "/api/echo", .body = "hello" };
    const rep = try route(a, &req);
    try std.testing.expectEqual(@as(u16, 200), rep.code);
    try std.testing.expect(std.mem.indexOf(u8, rep.body, "\"body\":\"hello\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rep.body, "\"body_len\":5") != null);
}

test "路由：/api/boom 返回 error，由 serve 的 catch 变成 500" {
    var arena = testArena();
    defer arena.deinit();
    const a = arena.allocator();
    var req = Request{ .method = "GET", .path = "/api/boom" };
    // ⚠️ 这条断言是本章"错误处理"的核心：路由处理函数出错时
    // `route` 返回 error，**不是** panic。整个进程毫发无伤。
    try std.testing.expectError(error.HandlerFailed, route(a, &req));
    // 而 404/405 是**正常返回**的 Response，不是 error——别把两者混起来
    var req404 = Request{ .method = "GET", .path = "/nope" };
    try std.testing.expectEqual(@as(u16, 404), (try route(a, &req404)).code);
}

test "URL 解析：绝对 URL / 缺省端口 / 错误集" {
    var arena = testArena();
    defer arena.deinit();
    const a = arena.allocator();
    const abs1 = try parseUrl(a, "http://127.0.0.1:8080/a/b?x=1");
    try std.testing.expectEqualStrings("http", abs1.scheme);
    try std.testing.expectEqualStrings("127.0.0.1", abs1.host);
    try std.testing.expectEqual(@as(u16, 8080), abs1.port);
    try std.testing.expectEqualStrings("/a/b", abs1.path);
    try std.testing.expectEqualStrings("x=1", abs1.query);

    // http 缺省 80
    const abs2 = try parseUrl(a, "http://h/");
    try std.testing.expectEqual(@as(u16, 80), abs2.port);
    // https 缺省 443
    const abs3 = try parseUrl(a, "https://h/");
    try std.testing.expectEqual(@as(u16, 443), abs3.port);

    // 错误：std.Uri 只吃绝对 URL
    try std.testing.expectError(error.InvalidFormat, std.Uri.parse("not a url"));
    try std.testing.expectError(error.InvalidFormat, std.Uri.parse("/rel/path"));
    try std.testing.expectError(error.InvalidFormat, std.Uri.parse(""));
    try std.testing.expectError(error.InvalidPort, std.Uri.parse("http://h:99999/"));
    try std.testing.expectError(error.UnexpectedCharacter, std.Uri.parse("ht tp://x"));
}

test "parseIp4 的三个错误名实测：Overflow / Incomplete / InvalidCharacter" {
    try std.testing.expectError(error.Overflow, std.Io.net.IpAddress.parseIp4("999.1.1.1", 80));
    try std.testing.expectError(error.Incomplete, std.Io.net.IpAddress.parseIp4("1.2.3", 80));
    try std.testing.expectError(error.InvalidCharacter, std.Io.net.IpAddress.parseIp4("localhost", 80));
}

test "std.http.Client / Server 在 0.17 存在" {
    try std.testing.expect(@hasDecl(std.http, "Client"));
    try std.testing.expect(@hasDecl(std.http, "Server"));
    try std.testing.expect(@hasDecl(std.http.Client, "fetch"));
    try std.testing.expect(@hasDecl(std.http.Client, "request"));
    try std.testing.expect(@hasDecl(std.http.Server, "init"));
    try std.testing.expect(@hasDecl(std.http.Server, "receiveHead"));
    try std.testing.expect(@hasDecl(std.http, "ChunkParser"));
    // Status 是 enum(u10)，.ok 的backingInt 就是 200
    try std.testing.expectEqual(@as(u10, 200), @backingInt(std.http.Status.ok));
    try std.testing.expectEqualStrings("teapot", @tagName(std.http.Status.teapot));
}

test "方法白名单区分大小写" {
    try std.testing.expect(isAllowedMethod("GET"));
    try std.testing.expect(isAllowedMethod("HEAD"));
    try std.testing.expect(isAllowedMethod("POST"));
    try std.testing.expect(!isAllowedMethod("DELETE"));
    try std.testing.expect(!isAllowedMethod("get"));
}

test "reasonPhrase 覆盖本章用到的全部状态码" {
    try std.testing.expectEqualStrings("OK", reasonPhrase(200));
    try std.testing.expectEqualStrings("Not Found", reasonPhrase(404));
    try std.testing.expectEqualStrings("Method Not Allowed", reasonPhrase(405));
    try std.testing.expectEqualStrings("Payload Too Large", reasonPhrase(413));
    try std.testing.expectEqualStrings("Request Header Fields Too Large", reasonPhrase(431));
    try std.testing.expectEqualStrings("Not Implemented", reasonPhrase(501));
    try std.testing.expectEqualStrings("Unknown", reasonPhrase(999));
}

test "探针端口从高位非 0 起（30.x 的硬性约束）" {
    // ⚠️ 从 0 开始会立即 bind 成功拿到 ephemeral 端口，"扫 20 个"形同虚设。
    try std.testing.expect(port_base != 0);
    try std.testing.expect(port_base >= 1024); // 高位：避开 ephemeral 区间
    try std.testing.expectEqual(@as(usize, 20), probe_count);
}
