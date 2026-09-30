//! 29 网络编程：UDP 用 0.16 原生 std.Io.net；TCP 用 ws2_32 extern 直调
//! 取材：Systems Programming with Zig ch6（echo server/client 双协议）
//! ⚠️ 实测结论（Windows / 0.16.0）：std.Io.net 的 UDP 回环一切正常；
//! TCP 走 AFD 内核路径，listen/accept/connect 均可，但数据面 recv 拿不到数据 / 对端被重置——
//! 属 0.16.0 已知缺陷域（AFD 绕过 Winsock，错误映射与数据面问题，详见 docs/29-networking.md 坑位）。
//! Linux/macOS 上书本的 TCP 写法可直接用；Windows 的逃生门是 C ABI 直调 ws2_32——17 章互操作的进阶实战。
const std = @import("std");
const builtin = @import("builtin");

// ═══ 29.1 UDP：std.Io.net 原生姿势（跨平台 API 面，本机 Windows 实测可用）
/// 服务线程与客户端的会合点：服务器 bind 成功后公布实际端口
const Rendezvous = struct {
    port: std.atomic.Value(u16) = std.atomic.Value(u16).init(0),
};

/// 从 base 起找第一个能 bind 的 UDP 端口（最多 20 个）
fn bindSomewhere(io: std.Io, base: u16) !struct { socket: std.Io.net.Socket, port: u16 } {
    var port = base;
    while (port < base + 20) : (port += 1) {
        const address = std.Io.net.IpAddress.parseIp4("127.0.0.1", port) catch unreachable;
        if (address.bind(io, .{ .mode = .dgram })) |sock| {
            return .{ .socket = sock, .port = port };
        } else |_| {}
    }
    return error.NoPortAvailable;
}

fn awaitPort(rz: *Rendezvous) u16 {
    while (true) {
        const p = rz.port.load(.acquire);
        if (p != 0) return p;
        std.Thread.yield() catch {};
    }
}

/// UDP echo 服务器：收满 n 个数据报就收工（干完活自然退出，join 即同步——0.16 无 WaitGroup）
fn udpEchoServer(io: std.Io, rz: *Rendezvous) void {
    const acquired = bindSomewhere(io, 49371) catch |e| {
        std.debug.print("bind 失败：{s}\n", .{@errorName(e)});
        return;
    };
    var sock = acquired.socket;
    defer sock.close(io);
    rz.port.store(acquired.port, .release);

    var got: usize = 0;
    while (got < 3) : (got += 1) {
        var buf: [128]u8 = undefined;
        const incoming = sock.receive(io, &buf) catch return; // .from 记着来路
        sock.send(io, &incoming.from, incoming.data) catch return;
    }
}

// ═══ 29.2 TCP：ws2_32 extern 层（Windows 专用；非 Windows 编译成空壳，书本的 std.Io.net 写法即正解）
const tcp = if (builtin.os.tag == .windows) struct {
    const win = std.os.windows;

    /// extern 声明收进 c 命名空间：符号名必须与 DLL 导出名一字不差（没有别名机制），
    /// 而裸名 socket/bind/accept 会与本 struct 的包装方法撞名——隔一层即解
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

    /// sockaddr_in：C ABI 的"外交护照"（extern struct——25 章的知识在这里长出骨头）
    pub const SockAddrIn = extern struct {
        family: u16 = 2, // AF_INET
        port: u16, // 网络序（大端）：htons 转换，别手写位移
        addr: u32, // 网络序；127.0.0.1 即 0x0100007f
        zero: [8]u8 = @splat(0),
    };

    const AF_INET: i32 = 2;
    const SOCK_STREAM: i32 = 1;
    const IPPROTO_TCP: i32 = 6;
    const SOCKET_ERROR: i32 = -1;

    pub fn htons(h: u16) u16 {
        return (@as(u16, @intCast(h & 0xff)) << 8) | (h >> 8);
    }

    /// 进程级初始化：用 Winsock 前必须 WSAStartup（一次即可）
    pub fn init() !void {
        var wsa: WSAData = undefined;
        if (c.WSAStartup(0x0202, &wsa) != 0) return error.WSAStartup;
    }
    pub fn deinit() void {
        _ = c.WSACleanup();
    }

    /// 一条 TCP 连接（客户端 connect 或服务端 accept 的产物）
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
            return @intCast(n); // 0 = 对端关闭
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

        pub fn accept(s: *Server) !Conn {
            const conn = c.accept(s.handle, null, null);
            if (conn == win.INVALID_HANDLE_VALUE) return error.AcceptFailed;
            return .{ .handle = conn };
        }
        pub fn deinit(s: *Server) void {
            _ = c.closesocket(s.handle);
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

    /// TCP echo 服务线程：恰好服务 2 条连接；每条连接逐段回声直到对端关闭
    fn echoServer(rz: *Rendezvous) void {
        var server = Server.listenOn(49321) catch |e| {
            std.debug.print("listen 失败：{s}\n", .{@errorName(e)});
            return;
        };
        defer server.deinit();
        rz.port.store(server.port, .release);

        var served: usize = 0;
        while (served < 2) : (served += 1) {
            var conn = server.accept() catch return;
            defer conn.close();
            while (true) {
                var buf: [64]u8 = undefined;
                const n = conn.recvSome(&buf) catch break;
                if (n == 0) break; // 对端关闭
                conn.sendAll(buf[0..n]) catch break;
            }
        }
    }

    /// TCP echo 客户端自演：2 条连接 × 2 消息，逐条核对回声
    pub fn runDemo(a: std.mem.Allocator) !void {
        var rz = Rendezvous{};
        const th = std.Thread.spawn(.{}, echoServer, .{&rz}) catch return error.SpawnFailed;
        const port = awaitPort(&rz);
        std.debug.print("TCP 服务器就绪：127.0.0.1:{d}（ws2_32 直调）\n", .{port});

        for (0..2) |round| {
            var conn = try connectTo(port);
            defer conn.close();
            for (0..2) |k| {
                const msg = try std.fmt.allocPrint(a, "ping-{d}-{d}", .{ round, k });
                defer a.free(msg);
                try conn.sendAll(msg);
                var buf: [64]u8 = undefined;
                const n = try conn.recvSome(&buf);
                std.debug.assert(n == msg.len and std.mem.eql(u8, msg, buf[0..n]));
            }
            std.debug.print("  第 {d} 条连接 2×2 收发一致\n", .{round});
        }
        th.join();
        std.debug.print("TCP echo 完成（2 连接）\n", .{});
    }
} else struct {
    pub const SockAddrIn = extern struct { family: u16, port: u16, addr: u32, zero: [8]u8 };
    pub fn htons(h: u16) u16 {
        return h; // 大端主机上什么都不用换（教学占位；真实现用 @byteSwap 条件编译）
    }
    pub fn init() !void {}
    pub fn deinit() void {}
    pub fn runDemo(a: std.mem.Allocator) !void {
        _ = a;
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const a = init.arena.allocator();
    const err = std.debug.print;

    // ═══ 29.3 UDP echo 自演：服务线程 + 主线程客户端，3 个数据报一来一回
    var rz = Rendezvous{};
    const udp_thread = try std.Thread.spawn(.{}, udpEchoServer, .{ io, &rz });
    const uport = awaitPort(&rz);
    err("UDP 服务器就绪：127.0.0.1:{d}\n", .{uport});

    const dest = try std.Io.net.IpAddress.parseIp4("127.0.0.1", uport);
    const caddr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", uport + 100); // 客户端占另一个口
    var sock = try caddr.bind(io, .{ .mode = .dgram });
    defer sock.close(io);
    for (0..3) |i| {
        const payload = try std.fmt.allocPrint(a, "dgram-{d}", .{i});
        try sock.send(io, &dest, payload);
        var buf: [128]u8 = undefined;
        const incoming = try sock.receive(io, &buf);
        std.debug.assert(std.mem.eql(u8, payload, incoming.data));
        err("  UDP 回声一致：{s}\n", .{incoming.data});
    }
    udp_thread.join();
    err("UDP echo 完成（3 数据报）\n", .{});

    // ═══ 29.4 TCP echo 自演（winsock extern；非 Windows 走空壳）
    try tcp.init();
    defer tcp.deinit();
    try tcp.runDemo(a);
    err("自检通过\n", .{});
}

// ═══ 29.5 测试：纯逻辑部分（网络回环在 main 自演——join 即同步、零计时依赖）
test "htons 字节序" {
    try std.testing.expectEqual(@as(u16, 0x3930), tcp.htons(12345)); // 12345=0x3039，交换得 0x3930
    try std.testing.expectEqual(@as(u16, 0x0000), tcp.htons(0));
    try std.testing.expectEqual(@as(u16, 0x0039), tcp.htons(0x3900)); // 交换是 involution：再来一次回原值
}

test "IpAddress 解析与端口" {
    const a = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8080);
    try std.testing.expectEqual(@as(u16, 8080), a.getPort());
    var b = a;
    b.setPort(9090);
    try std.testing.expectEqual(@as(u16, 9090), b.getPort());
    try std.testing.expectError(error.InvalidCharacter, std.Io.net.IpAddress.parseIp4("not-an-ip", 1));
    const c = try std.Io.net.IpAddress.parseLiteral("127.0.0.1:1234");
    try std.testing.expectEqual(@as(u16, 1234), c.getPort());
}
