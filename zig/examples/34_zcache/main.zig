//! 34 实战：内存 KV 缓存服务器 zcache——LRU 淘汰 + TCP 文本协议 + 并发访问
//! 取材：Systems Programming with Zig ch10（zcache：LRU = HashMap + 双向链表，为何两个都要）
//! 运输层沿用 29/30 章结论：Windows 0.16.0 的 std.Io.net TCP 数据面不可用，直调 ws2_32。
//! 服务器串行 accept（书上事件驱动/线程池变体见 docs/34-zcache.md 练习）；正确性全靠确定性自演断言。
const std = @import("std");
const builtin = @import("builtin");

// ═══ 34.1 运输层：ws2_32 extern（29 章同款，压缩版；非 Windows 空壳）
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
        pub fn sendLine(self: Conn, line: []const u8) !void {
            var buf: [600]u8 = undefined;
            if (line.len + 2 > buf.len) return error.SendFailed;
            @memcpy(buf[0..line.len], line);
            buf[line.len] = '\r';
            buf[line.len + 1] = '\n';
            try self.sendAll(buf[0 .. line.len + 2]);
        }
        /// 读一行（\r\n 收尾），返回不含定界符的切片（借用内部行缓冲）
        pub fn recvLine(self: Conn, buf: []u8) ![]const u8 {
            var len: usize = 0;
            while (true) {
                if (len >= 2 and buf[len - 2] == '\r' and buf[len - 1] == '\n') return buf[0 .. len - 2];
                if (len == buf.len) return error.LineTooLong;
                const n = c.recv(self.handle, buf[len..].ptr, @intCast(buf.len - len), 0);
                if (n == SOCKET_ERROR) return error.RecvFailed;
                if (n == 0) return error.Closed;
                len += @intCast(n);
            }
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
};

// ═══ 34.2 LRU 核：HashMap 定位 O(1) + 双向链表记新旧序 O(1)——两个结构各司其职
pub const Lru = struct {
    const Entry = struct {
        key: []u8, // 自有
        value: []u8, // 自有
        link: std.DoublyLinkedList.Node = .{}, // 侵入式链表节点（@fieldParentPtr 反查宿主）
    };

    a: std.mem.Allocator,
    capacity: usize,
    map: std.StringHashMap(*Entry),
    order: std.DoublyLinkedList = .{}, // first = 最新，last = 最旧（淘汰候选）
    hits: usize = 0,
    misses: usize = 0,
    evictions: usize = 0,

    fn init(a: std.mem.Allocator, capacity: usize) Lru {
        return .{ .a = a, .capacity = capacity, .map = std.StringHashMap(*Entry).init(a) };
    }

    fn deinit(l: *Lru) void {
        var node = l.order.first;
        while (node) |n| {
            const next = n.next;
            const entry: *Entry = @fieldParentPtr("link", n);
            l.a.free(entry.key);
            l.a.free(entry.value);
            l.a.destroy(entry);
            node = next;
        }
        l.map.deinit();
    }

    /// 命中：值 + 该项搬到队首；未命中：null（并计数）
    fn get(l: *Lru, key: []const u8) ?[]const u8 {
        if (l.map.get(key)) |entry| {
            l.hits += 1;
            l.touch(entry);
            return entry.value;
        }
        l.misses += 1;
        return null;
    }

    fn touch(l: *Lru, entry: *Entry) void {
        l.order.remove(&entry.link);
        l.order.prepend(&entry.link);
    }

    /// 插入/更新；超容量淘汰队尾（最久未用）
    fn put(l: *Lru, key: []const u8, value: []const u8) !void {
        if (l.map.get(key)) |entry| { // 更新已有键：换值 + 提新
            const nv = try l.a.dupe(u8, value);
            l.a.free(entry.value);
            entry.value = nv;
            l.touch(entry);
            return;
        }
        const entry = try l.a.create(Entry);
        errdefer l.a.destroy(entry);
        entry.* = .{ .key = try l.a.dupe(u8, key), .value = try l.a.dupe(u8, value) };
        errdefer {
            l.a.free(entry.key);
            l.a.free(entry.value);
        }
        try l.map.put(entry.key, entry);
        l.order.prepend(&entry.link);

        while (l.map.count() > l.capacity) { // 淘汰：链表尾巴就是答案——不用扫描
            const victim_node = l.order.last.?;
            const victim: *Entry = @fieldParentPtr("link", victim_node);
            _ = l.map.remove(victim.key);
            l.order.remove(victim_node);
            l.a.free(victim.key);
            l.a.free(victim.value);
            l.a.destroy(victim);
            l.evictions += 1;
        }
    }

    fn del(l: *Lru, key: []const u8) bool {
        const entry = l.map.get(key) orelse return false;
        _ = l.map.remove(key);
        l.order.remove(&entry.link);
        l.a.free(entry.key);
        l.a.free(entry.value);
        l.a.destroy(entry);
        return true;
    }
};

// ═══ 34.3 服务器：串行 accept，一条连接服务到对端关闭；协议一行命令一行应答
const ServerCtx = struct {
    lru: Lru,
    io: std.Io,
    lock: std.Io.Mutex = .init,
    port: std.atomic.Value(u16) = std.atomic.Value(u16).init(0),
    n_conns_served: usize = 0,

    fn handleCommand(self: *ServerCtx, conn: tcp.Conn, line: []const u8) !void {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const cmd = it.next() orelse return conn.sendLine("ERR empty");
        if (std.mem.eql(u8, cmd, "GET")) {
            const key = it.next() orelse return conn.sendLine("ERR usage GET k");
            self.lock.lockUncancelable(self.io);
            const v = self.lru.get(key);
            self.lock.unlock(self.io);
            if (v) |val| {
                var buf: [520]u8 = undefined;
                const resp = std.fmt.bufPrint(&buf, "VALUE {s}", .{val}) catch return conn.sendLine("ERR long");
                return conn.sendLine(resp);
            }
            return conn.sendLine("MISS");
        }
        if (std.mem.eql(u8, cmd, "SET")) {
            const key = it.next() orelse return conn.sendLine("ERR usage SET k v");
            const val = it.rest();
            self.lock.lockUncancelable(self.io);
            const r = self.lru.put(key, val);
            self.lock.unlock(self.io);
            r catch return conn.sendLine("ERR oom");
            return conn.sendLine("OK");
        }
        if (std.mem.eql(u8, cmd, "DEL")) {
            const key = it.next() orelse return conn.sendLine("ERR usage DEL k");
            self.lock.lockUncancelable(self.io);
            const removed = self.lru.del(key);
            self.lock.unlock(self.io);
            return conn.sendLine(if (removed) "OK" else "MISS");
        }
        if (std.mem.eql(u8, cmd, "STATS")) {
            self.lock.lockUncancelable(self.io);
            var buf: [128]u8 = undefined;
            const resp = std.fmt.bufPrint(&buf, "STATS hits={d} misses={d} evictions={d} entries={d}", .{
                self.lru.hits, self.lru.misses, self.lru.evictions, self.lru.map.count(),
            }) catch unreachable;
            self.lock.unlock(self.io);
            return conn.sendLine(resp);
        }
        return conn.sendLine("ERR unknown");
    }
};

fn serverMain(ctx: *ServerCtx) void {
    var server = tcp.Server.listenOn(49401) catch |e| {
        std.debug.print("listen 失败：{s}\n", .{@errorName(e)});
        return;
    };
    defer server.deinit();
    ctx.port.store(server.port, .release);

    while (ctx.n_conns_served < 4) : (ctx.n_conns_served += 1) { // 恰好 4 条连接：演示脚本定长
        var conn = server.accept() catch return;
        defer conn.close();
        var buf: [1024]u8 = undefined;
        while (true) {
            const line = conn.recvLine(&buf) catch break; // 对端关闭 → 下一条连接
            ctx.handleCommand(conn, line) catch break;
        }
    }
}

// ═══ 34.4 自演：确定性脚本（语义断言）+ 双线程并发连接（响应形状断言）
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const io = init.io;
    const err = std.debug.print;
    try tcp.init();
    defer tcp.deinit();

    var ctx = ServerCtx{ .lru = Lru.init(a, 3), .io = io };
    const th = try std.Thread.spawn(.{}, serverMain, .{&ctx});
    while (ctx.port.load(.acquire) == 0) std.Thread.yield() catch {};
    const port = ctx.port.load(.acquire);
    err("zcache 就绪：127.0.0.1:{d}（容量 3）\n", .{port});

    // 第一幕：单连接语义脚本
    {
        var conn = try tcp.connectTo(port);
        defer conn.close();
        var buf: [1024]u8 = undefined;
        try expect(&conn, &buf, "SET a 1", "OK");
        try expect(&conn, &buf, "GET a", "VALUE 1");
        try expect(&conn, &buf, "SET b 2", "OK");
        try expect(&conn, &buf, "SET c 3", "OK");
        try expect(&conn, &buf, "SET d 4", "OK"); // 容量 4 > 3：淘汰最久未用的 a
        try expect(&conn, &buf, "GET a", "MISS");
        try expect(&conn, &buf, "GET d", "VALUE 4");
        try expect(&conn, &buf, "DEL b", "OK");
        try expect(&conn, &buf, "GET b", "MISS");
        try expect(&conn, &buf, "STATS", "STATS hits=2 misses=2 evictions=1 entries=2");
        err("  语义脚本 10 条全对（命中/未中/淘汰/删除/统计）\n", .{});
        conn.close(); // 显式关闭让服务器进入下一条连接
    }

    // 第二幕：两条并发连接打同一个键——应答必须是 VALUE（谁的新值不确定，断言形状）
    {
        var t0 = try std.Thread.spawn(.{}, concurrentClient, .{ port, "v0" });
        var t1 = try std.Thread.spawn(.{}, concurrentClient, .{ port, "v1" });
        t0.join();
        t1.join();
        err("  并发两连接各 SET+GET 完成\n", .{});
    }

    // 尾声：最终统计（hits 4 = 第一幕 2 + 第二幕 2）
    {
        var conn = try tcp.connectTo(port);
        defer conn.close();
        var buf: [1024]u8 = undefined;
        try expect(&conn, &buf, "STATS", "STATS hits=4 misses=2 evictions=1 entries=3");
        err("  终态统计核对通过\n", .{});
    }
    th.join();
    err("自检通过\n", .{});
}

fn concurrentClient(port: u16, tag: []const u8) void {
    var conn = tcp.connectTo(port) catch return;
    defer conn.close();
    var sbuf: [128]u8 = undefined;
    var rbuf: [1024]u8 = undefined;
    const set_cmd = std.fmt.bufPrint(&sbuf, "SET shared {s}", .{tag}) catch return;
    conn.sendLine(set_cmd) catch return;
    const r1 = conn.recvLine(&rbuf) catch return;
    if (!std.mem.eql(u8, r1, "OK")) std.process.abort();
    conn.sendLine("GET shared") catch return;
    const r2 = conn.recvLine(&rbuf) catch return;
    if (!std.mem.startsWith(u8, r2, "VALUE ")) std.process.abort(); // 值内容不确定，形状必须对
}

fn expect(conn: *tcp.Conn, buf: []u8, cmd: []const u8, want: []const u8) !void {
    try conn.sendLine(cmd);
    const got = try conn.recvLine(buf);
    if (!std.mem.eql(u8, got, want)) {
        std.debug.print("协议失配：{s} → 期望 {s} 实得 {s}\n", .{ cmd, want, got });
        return error.ProtocolMismatch;
    }
}

// ═══ 34.5 测试：LRU 核的确定性（不碰网络）
test "LRU 淘汰序：最久未用先走" {
    const a = std.testing.allocator;
    var lru = Lru.init(a, 3);
    defer lru.deinit();
    try lru.put("a", "1");
    try lru.put("b", "2");
    try lru.put("c", "3");
    try std.testing.expectEqualStrings("1", lru.get("a").?); // 访问 a：b 变最旧
    try lru.put("d", "4"); // 淘汰 b（不是 a）
    try std.testing.expect(lru.get("b") == null);
    try std.testing.expectEqualStrings("1", lru.get("a").?);
    try std.testing.expectEqualStrings("4", lru.get("d").?);
    try std.testing.expectEqual(@as(usize, 1), lru.evictions);
}

test "LRU 更新已有键不扩容" {
    const a = std.testing.allocator;
    var lru = Lru.init(a, 2);
    defer lru.deinit();
    try lru.put("k", "old");
    try lru.put("k", "new");
    try lru.put("x", "1");
    try std.testing.expectEqualStrings("new", lru.get("k").?); // 更新不占新位
    try std.testing.expectEqual(@as(usize, 0), lru.evictions);
}

test "命中未中计数" {
    const a = std.testing.allocator;
    var lru = Lru.init(a, 4);
    defer lru.deinit();
    _ = lru.get("nothing"); // miss
    try lru.put("a", "1");
    _ = lru.get("a"); // hit
    _ = lru.get("b"); // miss
    try std.testing.expectEqual(@as(usize, 1), lru.hits);
    try std.testing.expectEqual(@as(usize, 2), lru.misses);
}

test "删除后可重插" {
    const a = std.testing.allocator;
    var lru = Lru.init(a, 2);
    defer lru.deinit();
    try lru.put("a", "1");
    try std.testing.expect(lru.del("a"));
    try std.testing.expect(!lru.del("a")); // 二次删：MISS
    try lru.put("a", "2");
    try std.testing.expectEqualStrings("2", lru.get("a").?);
}
