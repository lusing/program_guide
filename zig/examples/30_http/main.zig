//! 30 HTTP 服务与客户端：手写报文解析/构造 + 路由 + JSON 响应（winsock TCP 运输层）
//! 取材：Systems Programming with Zig ch6（minimal web server / 随机数服务 / JSON）
//! 运输层沿用 29 章结论：Windows 0.16.0 的 std.Io.net TCP 数据面不可用（AFD 缺陷），
//! 故本例 TCP 直调 ws2_32；std.http.Server/Client 的官方 API 形态见 docs/30-http.md（Linux/macOS 可用）。
//! HTTP 本体是文本协议：亲手读一遍"请求行 + 头部 + 空行 + 体"，比任何框架都学得快。
const std = @import("std");
const builtin = @import("builtin");

// ═══ 30.1 运输层：ws2_32 extern（29 章同款，压缩注释版；非 Windows 空壳）
const tcp = if (builtin.os.tag == .windows) struct {
    const win = std.os.windows;

    const c = struct {
        extern "ws2_32" fn WSAStartup(wVersionRequested: u16, lpWSAData: *WSAData) callconv(.winapi) i32;
        extern "ws2_32" fn WSACleanup() callconv(.winapi) i32;
        extern "ws2_32" fn socket(af: i32, type: i32, protocol: i32) callconv(.winapi) win.HANDLE;
        extern "ws2_32" fn closesocket(s: win.HANDLE) callconv(.winapi) i32;
        extern "ws2_32" fn bind(s: win.HANDLE, name: *const SockAddrIn, namelen: i32) callconv(.winapi) i32;
        extern "ws2_32" fn listen(s: win.HANDLE, backlog: i32) callconv(.winapi) i32;
        extern "ws2_32" fn accept(s: win.HANDLE, addr: ?*SockAddrIn, addrlen: ?*i32) callconv(.winapi) win.HANDLE;
        extern "ws2_32" fn connect(s: win.HANDLE, name: *const SockAddrIn, namelen: i32) callconv(.winapi) i32;
        extern "ws2_32" fn send(s: win.HANDLE, buf: [*]const u8, len: i32, flags: i32) callconv(.winapi) i32;
        extern "ws2_32" fn recv(s: win.HANDLE, buf: [*]u8, len: i32, flags: i32) callconv(.winapi) i32;
    };

    const WSAData = extern struct {
        wVersion: u16,
        wHighVersion: u16,
        iMaxSockets: u16,
        iMaxUdpDg: u16,
        lpVendorInfo: ?[*]u8,
        szDescription: [257]u8,
        szSystemStatus: [129]u8,
    };

    pub const SockAddrIn = extern struct {
        family: u16 = 2,
        port: u16,
        addr: u32,
        zero: [8]u8 = @splat(0),
    };

    const AF_INET: i32 = 2;
    const SOCK_STREAM: i32 = 1;
    const IPPROTO_TCP: i32 = 6;
    const SOCKET_ERROR: i32 = -1;

    pub fn htons(h: u16) u16 {
        return (@as(u16, @intCast(h & 0xff)) << 8) | (h >> 8);
    }

    pub fn init() !void {
        var wsa: WSAData = undefined;
        if (c.WSAStartup(0x0202, &wsa) != 0) return error.WSAStartup;
    }
    pub fn deinit() void {
        _ = c.WSACleanup();
    }

    pub const Conn = struct {
        handle: win.HANDLE,
        pub fn close(self: Conn) void {
            _ = c.closesocket(self.handle);
        }
        pub fn sendAll(self: Conn, data: []const u8) !void {
            if (c.send(self.handle, data.ptr, @intCast(data.len), 0) == SOCKET_ERROR) return error.SendFailed;
        }
        pub fn recvSome(self: Conn, buf: []u8) !usize {
            const n = c.recv(self.handle, buf.ptr, @intCast(buf.len), 0);
            if (n == SOCKET_ERROR) return error.RecvFailed;
            return @intCast(n);
        }
    };

    pub const Server = struct {
        handle: win.HANDLE,
        port: u16,
        pub fn listenOn(base: u16) !Server {
            const s = c.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
            if (s == win.INVALID_HANDLE_VALUE) return error.SocketFailed;
            errdefer _ = c.closesocket(s);
            var p = base;
            while (p < base + 20) : (p += 1) {
                const addr = SockAddrIn{ .port = htons(p), .addr = 0x0100007f };
                if (c.bind(s, &addr, @sizeOf(SockAddrIn)) == 0) break;
            } else return error.BindFailed;
            if (c.listen(s, 5) != 0) return error.ListenFailed;
            return .{ .handle = s, .port = p };
        }
        pub fn accept(self: *Server) !Conn {
            const conn = c.accept(self.handle, null, null);
            if (conn == win.INVALID_HANDLE_VALUE) return error.AcceptFailed;
            return .{ .handle = conn };
        }
        pub fn deinit(self: *Server) void {
            _ = c.closesocket(self.handle);
        }
    };

    pub fn connectTo(port: u16) !Conn {
        const s = c.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (s == win.INVALID_HANDLE_VALUE) return error.SocketFailed;
        errdefer _ = c.closesocket(s);
        const addr = SockAddrIn{ .port = htons(port), .addr = 0x0100007f };
        if (c.connect(s, &addr, @sizeOf(SockAddrIn)) != 0) return error.ConnectFailed;
        return .{ .handle = s };
    }
} else struct {
    pub fn init() !void {}
    pub fn deinit() void {}
    pub fn runDemo(a: std.mem.Allocator) !void {
        _ = a;
    }
};

// ═══ 30.2 HTTP 报文体：请求与响应的最小建模
const Request = struct {
    method: []const u8,
    target: []const u8, // 含查询串，如 /api/rand?n=5
    path: []const u8, // 去掉查询串
    query: []const u8, // "n=5"

    /// 从原始请求字节里解出请求行（头部止于 \r\n\r\n；GET 无体）
    fn parse(raw: []const u8) !Request {
        const line_end = std.mem.indexOf(u8, raw, "\r\n") orelse return error.BadRequest;
        var it = std.mem.tokenizeScalar(u8, raw[0..line_end], ' ');
        const method = it.next() orelse return error.BadRequest;
        const target = it.next() orelse return error.BadRequest;
        const q_pos = std.mem.indexOfScalar(u8, target, '?');
        return .{
            .method = method,
            .target = target,
            .path = if (q_pos) |q| target[0..q] else target,
            .query = if (q_pos) |q| target[q + 1 ..] else "",
        };
    }
};

/// 从查询串里取参数值（"n=5&x=1" → 查 n 得 "5"；极简版，不处理编码）
fn queryParam(query: []const u8, key: []const u8) ?[]const u8 {
    var it = std.mem.splitScalar(u8, query, '&');
    while (it.next()) |pair| {
        const eq = std.mem.indexOfScalar(u8, pair, '=') orelse continue;
        if (std.mem.eql(u8, pair[0..eq], key)) return pair[eq + 1 ..];
    }
    return null;
}

// ═══ 30.3 路由与响应构造
const Response = struct {
    status: []const u8, // "200 OK" / "404 Not Found"
    content_type: []const u8,
    body: []const u8,
};

fn route(a: std.mem.Allocator, req: *const Request) !Response {
    if (std.mem.eql(u8, req.path, "/")) {
        return .{
            .status = "200 OK",
            .content_type = "text/html; charset=utf-8",
            .body = "<h1>zhttp 演示服务</h1><p>试试 /api/rand?n=5 或 /api/info</p>",
        };
    }
    if (std.mem.eql(u8, req.path, "/api/rand")) {
        const n_str = queryParam(req.query, "n") orelse "1";
        const n = std.math.clamp(try std.fmt.parseInt(u32, n_str, 10), 1, 16);
        const RandReply = struct { n: u32, values: [16]u32, service: []const u8 };
        var rep = RandReply{ .n = n, .values = undefined, .service = "zhttp" };
        var prng = std.Random.DefaultPrng.init(0xF00D);
        for (rep.values[0..n]) |*v| v.* = prng.random().uintLessThan(u32, 100);
        var jw = std.Io.Writer.Allocating.init(a);
        try std.json.Stringify.value(.{ .n = rep.n, .values = rep.values[0..n], .service = rep.service }, .{}, &jw.writer);
        return .{ .status = "200 OK", .content_type = "application/json", .body = jw.written() };
    }
    if (std.mem.eql(u8, req.path, "/api/info")) {
        const Info = struct { name: []const u8, version: []const u8, routes: []const []const u8 };
        const info = Info{
            .name = "zhttp",
            .version = "0.1",
            .routes = &.{ "/", "/api/rand?n=", "/api/info" },
        };
        var jw = std.Io.Writer.Allocating.init(a);
        try std.json.Stringify.value(info, .{}, &jw.writer);
        return .{ .status = "200 OK", .content_type = "application/json", .body = jw.written() };
    }
    return .{ .status = "404 Not Found", .content_type = "text/plain", .body = "not found" };
}

/// 响应序列化：状态行 + 头部 + 空行 + 体（Connection: close 让客户端读到 EOF 即完整）
fn serialize(a: std.mem.Allocator, rep: *const Response) ![]const u8 {
    return std.fmt.allocPrint(
        a,
        "HTTP/1.1 {s}\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
        .{ rep.status, rep.content_type, rep.body.len, rep.body },
    );
}

// ═══ 30.4 服务线程：恰好服务 3 个请求（干完就退，join 即同步）
var srv_port = std.atomic.Value(u16).init(0);

fn httpServer() void {
    var server = tcp.Server.listenOn(49341) catch |e| {
        std.debug.print("listen 失败：{s}\n", .{@errorName(e)});
        return;
    };
    defer server.deinit();
    srv_port.store(server.port, .release);

    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();

    var served: usize = 0;
    while (served < 3) : (served += 1) {
        _ = arena_state.reset(.retain_capacity); // 每请求一个 arena——响应体随请求生死
        const a = arena_state.allocator();

        var conn = server.accept() catch return;
        defer conn.close();
        var buf: [2048]u8 = undefined;
        var len: usize = 0;
        while (std.mem.indexOf(u8, buf[0..len], "\r\n\r\n") == null) { // 读到头部结束
            if (len == buf.len) return; // 头部超长：放弃本连接
            const n = conn.recvSome(buf[len..]) catch return;
            if (n == 0) return;
            len += n;
        }
        const req = Request.parse(buf[0..len]) catch continue;
        const rep = route(a, &req) catch continue;
        const raw = serialize(a, &rep) catch continue;
        conn.sendAll(raw) catch continue;
        std.debug.print("  [{s}] {s} → {s}（{d} 字节体）\n", .{ req.method, req.path, rep.status, rep.body.len });
    }
}

// ═══ 30.5 客户端：GET 一条，读到 EOF，分离头部与体
fn get(a: std.mem.Allocator, port: u16, target: []const u8) ![]const u8 {
    var conn = try tcp.connectTo(port);
    defer conn.close();
    const req = try std.fmt.allocPrint(a, "GET {s} HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n", .{target});
    try conn.sendAll(req);

    var buf: [4096]u8 = undefined;
    var len: usize = 0;
    while (true) {
        const n = try conn.recvSome(buf[len..]);
        if (n == 0) break; // 服务端 Connection: close ⇒ EOF 即完整响应
        len += n;
    }
    const sep = std.mem.indexOf(u8, buf[0..len], "\r\n\r") orelse return error.BadResponse;
    // ⚠️ buf 是本函数的栈帧——直接返回切片是悬空指针（打印看似正常、实则未定义行为）。
    // dupe 进调用方的分配器，所有权随调用方。
    return try a.dupe(u8, buf[sep + 4 .. len]);
}

pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const err = std.debug.print;
    try tcp.init();
    defer tcp.deinit();

    const th = try std.Thread.spawn(.{}, httpServer, .{});
    while (srv_port.load(.acquire) == 0) std.Thread.yield() catch {};
    const port = srv_port.load(.acquire);
    err("HTTP 服务就绪：127.0.0.1:{d}\n", .{port});

    // 三个路由各取一次，断言体里的关键标记
    const home = try get(a, port, "/");
    try expectContains(home, "zhttp");
    err("  GET /        → {d} 字节 HTML，含标记 zhttp\n", .{home.len});

    const rnd = try get(a, port, "/api/rand?n=5");
    try expectContains(rnd, "\"values\"");
    try expectContains(rnd, "\"service\":\"zhttp\"");
    err("  GET /api/rand → JSON：{s}\n", .{rnd});

    const info = try get(a, port, "/api/info");
    try expectContains(info, "\"routes\"");
    err("  GET /api/info → JSON：{s}\n", .{info});

    th.join();
    err("自检通过\n", .{});
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    if (std.mem.indexOf(u8, haystack, needle) == null) return error.MarkerMissing;
}

// ═══ 30.6 测试：请求解析、查询参数、响应序列化（纯逻辑；回环在 main 自演）
test "请求行解析与查询切分" {
    const raw = "GET /api/rand?n=5 HTTP/1.1\r\nHost: x\r\n\r\n";
    const req = try Request.parse(raw);
    try std.testing.expectEqualStrings("GET", req.method);
    try std.testing.expectEqualStrings("/api/rand", req.path);
    try std.testing.expectEqualStrings("n=5", req.query);
    try std.testing.expectEqualStrings("5", queryParam(req.query, "n").?);
    try std.testing.expect(queryParam(req.query, "x") == null);
    try std.testing.expectError(error.BadRequest, Request.parse("garbage"));
}

test "查询参数多键与空值" {
    const q = "a=1&b=&c=3";
    try std.testing.expectEqualStrings("1", queryParam(q, "a").?);
    try std.testing.expectEqualStrings("", queryParam(q, "b").?);
    try std.testing.expectEqualStrings("3", queryParam(q, "c").?);
}

test "响应序列化形状" {
    const a = std.testing.allocator;
    const rep = Response{ .status = "200 OK", .content_type = "text/plain", .body = "hi" };
    const raw = try serialize(a, &rep);
    defer a.free(raw);
    try std.testing.expect(std.mem.startsWith(u8, raw, "HTTP/1.1 200 OK\r\n"));
    try std.testing.expect(std.mem.indexOf(u8, raw, "Content-Length: 2\r\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, raw, "\r\n\r\nhi"));
}
