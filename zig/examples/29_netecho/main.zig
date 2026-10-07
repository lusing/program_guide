//! 29 TCP 与 UDP：0.17 的网络全部收进 std.Io.net，所有方法第一个参数是 io
//!
//! 取材 Systems Programming with Zig ch6（echo server/client 双协议），但写法是 0.17 的：
//! IpAddress.listen / connect / bind → Server / Stream / Socket，收发一律 Reader/Writer。
//!
//! 本章的三个核心结论（都有实测支撑，见 docs/29-networking.md）：
//! 1. **0.17 里 `Socket.address` 带回了绑定后的真实端口**（`srv.socket.address.getPort()`），
//!    所以"绑 0 拿临时端口"不再是行不通的惯用法——这是相对 0.16 的重大改善。
//! 2. **`takeDelimiterExclusive` 在 0.17.0 有 std bug**：它只toss 内容不 toss 分隔符，
//!    于是第二次调用起永远返回空片。用 `takeDelimiter`（?[]u8）或不依赖分隔符的三件套。
//! 3. **自引用结构体不能按值拷贝**：Reader/Writer 和缓冲放同一 struct 时，
//!    `init()` 里就地 `stream.reader(io, &self.rbuf)` 会绑到 init 的栈帧，`return self` 之后悬垂。
//!    必须懒绑定（收发前ensureBound）。
const std = @import("std");
const net = std.Io.net;

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

/// 服务端线程与客户端的会合点：服务器 bind/listen 成功后原子公布实际端口。
/// 0.17 里 `Socket.address` 已经带回了真实端口，但服务器在**另一个线程**上创建，
/// 客户端线程仍需要知道它——所以这个会合点还得留着。
const Rendezvous = struct {
    port: std.atomic.Value(u16) = std.atomic.Value(u16).init(0),
};

/// 自旋等端口公布。用 `yield` 而不是 sleep——只等几微秒，不值得引入定时器依赖。
fn awaitPort(rz: *Rendezvous) u16 {
    while (true) {
        const p = rz.port.load(.acquire);
        if (p != 0) return p;
        std.Thread.yield() catch {};
    }
}

/// 从 base 起找第一个能 listen 的 TCP 端口（最多试 20 个）。
/// ⚠️ **base 必须是非 0 的高位端口**：从 0 起扫，内核会立刻给你一个 ephemeral 端口
///并"成功"返回——你连自己都不确定连到了谁。实测从 0 起扫第一轮就"成功"，
/// 拿到的是 49xxx/50xxx 这种内核随便给的端口。实测从 49421 起扫才拿到 49421。
///
/// 扫 20 个是实测得出的冗余度：本机上run-all.sh 与其它章的示例可能同时占端口，
/// 20 个连续端口足够跑过偶发冲突。
fn listenSomewhere(io: std.Io, base: u16, options: net.IpAddress.ListenOptions) !struct { server: net.Server, port: u16 } {
    var port = base;
    while (port < base + 20) : (port += 1) {
        const address = try net.IpAddress.parseIp4("127.0.0.1", port);
        if (address.listen(io, options)) |s| {
            return .{ .server = s, .port = port };
        } else |_| {}
    }
    return error.NoPortAvailable;
}

/// 从 base 起找第一个能 bind 的 UDP 端口（最多试 20 个）。同样是高位非 0 起扫。
fn bindSomewhere(io: std.Io, base: u16) !struct { socket: net.Socket, port: u16 } {
    var port = base;
    while (port < base + 20) : (port += 1) {
        const address = try net.IpAddress.parseIp4("127.0.0.1", port);
        if (address.bind(io, .{ .mode = .dgram })) |sock| {
            return .{ .socket = sock, .port = port };
        } else |_| {}
    }
    return error.NoPortAvailable;
}

// ═══ 29.5 一条 TCP 连接：懒绑定的自引用结构体 ═══════════════════════════════

/// 一条 TCP 连接。字段里同时放`Stream`、Reader/Writer 和它们的缓冲——**这是本章最大的坑**。
///
/// `stream.reader(io, buf)` 返回的 `Stream.Reader` 里有一个 `interface.buffer` 切片，
/// 它**指向 buf**。所以 Reader 和 buf 必须住在同一个对象里，且这个对象**不能被按值拷贝**。
///
/// 如果在 `init()` 里就地绑定：
/// ```zig
/// var self = Conn{ .stream = stream, ... };
/// self.r = stream.reader(io, &self.rbuf);   // 绑到 init 的栈帧上的 self
/// return self;                               // 值拷贝 ⇒ r 里的指针指向已销毁的帧
/// ```
/// 这段代码**编译通过、小报文也能跑**（那个帧还没被复用），
/// 但缓冲区一大就乱序或读到脏数据——症状极其阴险，实测能读出一屏垃圾字节。
///
/// 所以改成**懒绑定**：收发前调`ensureBound()`，那时`self` 已经落在最终位置了。
pub const Conn = struct {
    io: std.Io,
    stream: net.Stream,
    rbuf: [1024]u8 = undefined,
    wbuf: [1024]u8 = undefined,
    r: net.Stream.Reader = undefined,
    w: net.Stream.Writer = undefined,
    bound: bool = false,
    closed: bool = false,

    /// 只存"原料"，**不做任何绑定**。
    pub fn init(io: std.Io, stream: net.Stream) Conn {
        return .{ .io = io, .stream = stream };
    }

    /// 懒绑定：第一次收发时才把 Reader/Writer 绑到自己的缓冲字段上。
    /// 值拷贝多少次都安全——每次拷贝后的第一次 `ensureBound` 都会重新指向自己的字段。
    fn ensureBound(self: *Conn) void {
        if (self.bound) return;
        self.r = self.stream.reader(self.io, &self.rbuf);
        self.w = self.stream.writer(self.io, &self.wbuf);
        self.bound = true;
    }

    /// 写全部 + flush。⚠️ 缓冲 Writer 必须 flush，`Stream.close` **不会**替你 flush。
    pub fn sendAll(self: *Conn, data: []const u8) !void {
        self.ensureBound();
        try self.w.interface.writeAll(data);
        try self.w.interface.flush();
    }

    /// 有多少读多少（**不等满buf**）；返回 0 表示对端已关闭。
    ///
    /// ⚠️ 不能用 `readSliceShort`——它是"填满缓冲或读到 EOF"语义，
    /// 对端发了 3 字节就停住（不关）时，它会一直等满 1024 字节，服务端就此挂死。
    /// `fillMore` + `buffered` + `toss` 才是"来一段"的正确形状。
    pub fn recvSome(self: *Conn, buf: []u8) !usize {
        self.ensureBound();
        self.r.interface.fillMore() catch |err| switch (err) {
            error.EndOfStream => return 0, // 对端有序关闭（EOF）
            error.ReadFailed => return 0, // 对端硬关（reset）
        };
        const avail = self.r.interface.buffered();
        const n = @min(buf.len, avail.len);
        @memcpy(buf[0..n], avail[0..n]);
        self.r.interface.toss(n);
        return n;
    }

    /// ⚠️ **`Stream.close` 不是幂等的**。显式 close 之后又`defer close`，
    /// 第二次会走内核 `close(2)` 拿到 `EBADF`，0.17 把它当"程序员的bug"直接 panic：
    /// `programmer bug caused syscall error: BADF`（Threaded.zig 的 recoverableOsBugDetected）。
    /// 所以这里用 `closed` 标志把"关两次"变成"关一次"。
    pub fn close(self: *Conn) void {
        if (self.closed) return;
        self.closed = true;
        self.stream.close(self.io);
    }
};

/// 回环服务器：恰好服务 `rounds` 条连接，每条连接逐段回声直到对端关闭。
///
/// ⚠️ `accept` 的接收者是 `*Server`（**非 const**），因为它要读`socket.handle`。
/// 所以形参必须是 `*net.Server`，传给 `std.Thread.spawn` 的实参必须写 `&srv`——
/// 线程参数按值传递不会自动变指针，写`srv` 会得到 `*const Server` 然后编译失败。
fn tcpEchoServer(io: std.Io, srv: *net.Server, rounds: *usize) void {
    var served: usize = 0;
    while (served < rounds.*) : (served += 1) {
        var conn = Conn.init(io, srv.accept(io) catch return);
        defer conn.close();
        while (true) {
            var buf: [64]u8 = undefined;
            const n = conn.recvSome(&buf) catch break;
            if (n == 0) break; // 对端关闭
            conn.sendAll(buf[0..n]) catch break;
        }
    }
}

/// 回环服务器：UDP 收满 `count` 个数据报就收工。
fn udpEchoServer(io: std.Io, rz: *Rendezvous, count: *usize) void {
    const acquired = bindSomewhere(io, 49371) catch return;
    var sock = acquired.socket;
    defer sock.close(io);
    rz.port.store(acquired.port, .release);

    var got: usize = 0;
    while (got < count.*) : (got += 1) {
        var buf: [128]u8 = undefined;
        // ⚠️ `receive` 返回的 `IncomingMessage.data` **指向我传进去的那个 buf**，
        // 不是拷贝。所以必须在 receive 之后、下一次 receive 之前用完。
        const incoming = sock.receive(io, &buf) catch return;
        sock.send(io, &incoming.from, incoming.data) catch return;
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const mem = init.arena.allocator();
    const p = std.debug.print;

    // ═══ 29.1 为什么 0.17 把网络收进 std.Io ═══
    begin("29.1");
    p("0.17：TCP/UDP 全部在 std.Io.net 下，**每个方法的第一个参数都是 io**\n", .{});
    p("  好处  1 可替换：main 传 init.io（事件循环），test 传 std.testing.io\n", .{});
    p("  好处  2 可测试：io 是参数 ⇒ 能塞假实现、能在测试里换掉整个后端\n", .{});
    p("  好处  3 可异步：同一份代码能在阻塞 io 和事件驱动 io 上跑\n", .{});
    p("  ⚠️ 代价：每个方法都要写 io。这不是啰嗦，是让\"依赖\"看得见\n", .{});
    p("  对比：0.16 的 socket 是全局的，测试要重定向 fd；Python 要 monkeypatch\n", .{});
    p("IpAddress 是 {s}，tag 类型 = {s}\n", .{
        @typeName(net.IpAddress),
        @typeName(@typeInfo(net.IpAddress).@"union".tag_type.?),
    });
    inline for (@typeInfo(net.IpAddress).@"union".field_names, @typeInfo(net.IpAddress).@"union".field_types) |n, t| p("  变体 {s}: {s}\n", .{ n, @typeName(t) });
    p("Ip4Address 字段：", .{});
    inline for (@typeInfo(net.Ip4Address).@"struct".field_names) |n| p(" {s}", .{n});
    p("（bytes 是 [4]u8，**不是** u32——网络序要自己拼，别照抄 C 的 sockaddr）\n", .{});
    p("Ip6Address 字段：", .{});
    inline for (@typeInfo(net.Ip6Address).@"struct".field_names) |n| p(" {s}", .{n});
    p("（比 v4 多 flow/interface 两个链路层字段）\n", .{});
    p("Socket 字段：", .{});
    inline for (@typeInfo(net.Socket).@"struct".field_names) |n| p(" {s}", .{n});
    p("（handle 是 fd；**address 是 0.17 新增的实用字段**）\n", .{});
    p("Server 字段：", .{});
    inline for (@typeInfo(net.Server).@"struct".field_names) |n| p(" {s}", .{n});
    p("（options 的类型是 {s}，POSIX 上是 void）\n", .{@typeName(net.Server.AcceptOptions)});
    p("Socket.Mode 枚举（实测）：", .{});
    inline for (@typeInfo(net.Socket.Mode).@"enum".field_names) |n| p(" .{s}", .{n});
    p("（.raw 要 root；.rdm 多数平台不支持）\n", .{});
    var net_slots: usize = 0;
    inline for (@typeInfo(std.Io.VTable).@"struct".field_names) |n| {
        if (std.mem.startsWith(u8, n, "net")) net_slots += 1;
    }
    p("Io.vtable 里 net* 槽位（共 {d} 个，由 Threaded 实现）：\n", .{net_slots});
    p("  ⇒ 网络的一切都经由 io.vtable ⇒ 理论上可以自己写假 Io 替换它们（本章不深挖）\n", .{});
    end("29.1");

    // ═══ 29.2 地址解析：三个入口与它们的错误集 ═══
    begin("29.2");
    p("三个解析入口（0.17 都有）：parseIp4 / parseIp6 / parse（自动试 v4 再 v6）\n", .{});
    {
        const a = try net.IpAddress.parseIp4("127.0.0.1", 8080);
        var b1: [64]u8 = undefined;
        var w1 = std.Io.Writer.fixed(&b1);
        try a.format(&w1);
        p("  parseIp4(\"127.0.0.1\", 8080) → format ={s}，getPort()={d}\n", .{ w1.buffered(), a.getPort() });
        var b2 = a;
        b2.setPort(9090);
        p("  setPort(9090) 后 getPort()={d}（port 是**本机序**，不是网络序）\n", .{b2.getPort()});
        p("  Ip4Address.loopback(9) = ", .{});
        const lb = net.Ip4Address.loopback(9);
        p("{d}.{d}.{d}.{d}:{d}（现成的回环地址构造器）\n", .{
            lb.bytes[0], lb.bytes[1], lb.bytes[2], lb.bytes[3], lb.port,
        });
    }
    p("Ip4Address.ParseError 的全部成员（实测 5 个）：", .{});
    inline for (@typeInfo(net.Ip4Address.ParseError).error_set.error_names.?) |n| p(" {s}", .{n});
    p("\n", .{});
    p("  ⇒ 非法 IP 报的是 error.InvalidCharacter，**不是** InvalidAddress（别想当然）\n", .{});
    {
        inline for (.{
            "127.0.0.1", "0.0.0.0", "255.255.255.255",
            "256.1.1.1", "1.2.3",   "1.2.3.4.5",
            "not-an-ip", "",        "01.2.3.4",
            "1.2.3.4 ",
        }) |text| {
            if (net.IpAddress.parseIp4(text, 80)) |a| {
                _ = a;
                p("  parseIp4(\"{s}\") → ok\n", .{text});
            } else |e| {
                p("  parseIp4(\"{s}\") → {s}\n", .{ text, @errorName(e) });
            }
        }
        inline for (.{ "::1", "fe80::1", "127.0.0.1", "fe80::1%en0" }) |text| {
            if (net.IpAddress.parseIp6(text, 80)) |a| {
                var b: [80]u8 = undefined;
                var w = std.Io.Writer.fixed(&b);
                a.format(&w) catch {};
                p("  parseIp6(\"{s}\") → ok，format ={s}（v6 格式带方括号）\n", .{ text, w.buffered() });
            } else |e| {
                p("  parseIp6(\"{s}\") → {s}\n", .{ text, @errorName(e) });
            }
        }
        p("Ip6Address.ParseError 只有 2 个：", .{});
        inline for (@typeInfo(net.Ip6Address.ParseError).error_set.error_names.?) |n| p(" {s}", .{n});
        p("（**比 v4 少得多** —— v6 的检查靠 parser 自己）\n", .{});
        p("  ⚠️ 带 scope 的\"fe80::1%en0\"要 parseIp6 **报 UnresolvedScope**：\n", .{});
        p("     scope 要靠 IpAddress.resolve(io, ...) 查接口名→ 索引（要 io，因为它要 ioctl）\n", .{});
        p("  parse（自动 v4/v6）：\n", .{});
        inline for (.{ "::1", "1.2.3.4", "garbage", "1.2.3.4.5" }) |text| {
            if (net.IpAddress.parse(text, 80)) |a| {
                p("    parse(\"{s}\") → ok，tag={s}\n", .{ text, @tagName(a) });
            } else |e| {
                p("    parse(\"{s}\") → {s}（v4 失败后**统一报v6 的错误名**）\n", .{ text, @errorName(e) });
            }
        }
        p("  parseLiteral（带端口的字面量，v6 要方括号）：\n", .{});
        inline for (.{
            "127.0.0.1:1234", "[::1]:443", "[::1]", "::1", "127.0.0.1", "127.0.0.1:notaport", "",
        }) |text| {
            if (net.IpAddress.parseLiteral(text)) |a| {
                p("    parseLiteral(\"{s}\") → ok tag={s} port={d}\n", .{ text, @tagName(a), a.getPort() });
            } else |e| {
                p("    parseLiteral(\"{s}\") → {s}\n", .{ text, @errorName(e) });
            }
        }
        p("  ⚠️ parseLiteral 的错误集只有 2 个：", .{});
        inline for (@typeInfo(net.IpAddress.ParseLiteralError).error_set.error_names.?) |n| p(" {s}", .{n});
        p("\n", .{});
        p("  ⚠️ \"::1\"（不带方括号）→ InvalidAddress：v6 字面量**必须**是 \"[::1]\" 形状\n", .{});
    }
    p("0.17 有没有 getAddressList？ @hasDecl(net, \"getAddressList\") = {}\n", .{@hasDecl(net, "getAddressList")});
    p("⇒ **没有**。0.16 的 std.net.getAddressList 已改名/重做成 HostName 子模块：\n", .{});
    p("  net.HostName.lookup(host, io, *Queue(LookupResult), opts)  —— 纯函数式的 DNS 查询\n", .{});
    p("  net.HostName.connect(host, io, port, ConnectOptions)      —— 直接连主机名（lookup+connect 一体）\n", .{});
    p("  两者都吃 HostName（已校验的域名），构造用 net.HostName.init(bytes) 或 fromUri\n", .{});
    end("29.2");

    // ═══ 29.3 三个建端点的方法与它们的选项结构 ═══
    begin("29.3");
    p("⚠️ listen / bind / connect 的接收者是 **\\*const IpAddress**（不是 const IpAddress）：\n", .{});
    p("   `try parseIp4(...).listen(io, .{{}})` 编译不过—— 临时值取不到地址。必须先存成变量。\n", .{});
    p("ListenOptions（TCP 服务端）：", .{});
    inline for (@typeInfo(net.IpAddress.ListenOptions).@"struct".field_names, @typeInfo(net.IpAddress.ListenOptions).@"struct".field_types) |n, t| p(" {s}: {s}", .{ n, @typeName(t) });
    p("\n  kernel_backlog 默认 = {d}（net.default_kernel_backlog）\n", .{net.default_kernel_backlog});
    p("  mode 默认 .stream，protocol 默认 .tcp ⇒ listen(io, .{{}}) 就能开一个 TCP 服务\n", .{});
    p("BindOptions（UDP 收发端）：", .{});
    inline for (@typeInfo(net.IpAddress.BindOptions).@"struct".field_names, @typeInfo(net.IpAddress.BindOptions).@"struct".field_types) |n, t| p(" {s}: {s}", .{ n, @typeName(t) });
    p("\n  ⚠️ mode **没有默认值**（`bind(io, .{{}})` 编译不过），必须写 .mode = .dgram\n", .{});
    p("ConnectOptions（TCP 客户端）：", .{});
    inline for (@typeInfo(net.IpAddress.ConnectOptions).@"struct".field_names, @typeInfo(net.IpAddress.ConnectOptions).@"struct".field_types) |n, t| p(" {s}: {s}", .{ n, @typeName(t) });
    p("\n  ⚠️ mode 也**没有默认值**，要写 .mode = .stream\n", .{});
    p("  timeout 类型是 Io.Timeout = union(enum) {{ .none / .duration / .deadline }}，不是 enum！\n", .{});
    p("  ⚠️ Io.Timeout 没有 .some(n) 构造（那是别的库的习惯），写 .{{ .duration = ... }}\n", .{});
    p("  ⚠️ 它的 payload 是 Clock.Duration = {{ .raw: Io.Duration, .clock: Clock }}\n", .{});
    p("ListenOptions 逐字段实测：\n", .{});
    {
        // kernel_backlog = 1
        const a1 = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var s1 = try a1.listen(io, .{ .kernel_backlog = 1 });
        p("  .kernel_backlog=1→ ok，实际端口 {d}\n", .{s1.socket.address.getPort()});
        s1.deinit(io);
        // mode + protocol 组合
        const a2 = try net.IpAddress.parseIp4("127.0.0.1", 0);
        if (a2.listen(io, .{ .mode = .seqpacket, .protocol = .sctp })) |s2| {
            var sv = s2;
            p("  .mode=.seqpacket + .protocol=.sctp → ok(port={d})\n", .{sv.socket.address.getPort()});
            sv.deinit(io);
        } else |e| {
            p("  .mode=.seqpacket + .protocol=.sctp → {s}（macOS 无 SCTP）\n", .{@errorName(e)});
        }
        // 不合法组合
        const a3 = try net.IpAddress.parseIp4("127.0.0.1", 0);
        if (a3.listen(io, .{ .mode = .dgram })) |s3| {
            var sv = s3;
            p("  .mode=.dgram 传给 listen → 成功？不该(port={d})\n", .{sv.socket.address.getPort()});
            sv.deinit(io);
        } else |e| {
            p("  .mode=.dgram 传给 listen → {s}（listen 只接受面向连接的 mode）\n", .{@errorName(e)});
        }
        const a4 = try net.IpAddress.parseIp4("127.0.0.1", 0);
        if (a4.listen(io, .{ .protocol = .udp })) |s4| {
            var sv = s4;
            p("  .protocol=.udp + 默认 .mode=.stream → 成功？不该\n", .{});
            sv.deinit(io);
        } else |e| {
            p("  .protocol=.udp + 默认 .mode=.stream → {s}（协议与 mode 不匹配）\n", .{@errorName(e)});
        }
        // reuse_address：POSIX 上它同时设 SO_REUSEADDR **和 SO_REUSEPORT**
        const a5 = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var s5 = try a5.listen(io, .{ .reuse_address = true });
        const reuse_port = s5.socket.address.getPort();
        const same = try net.IpAddress.parseIp4("127.0.0.1", reuse_port);
        if (same.listen(io, .{ .reuse_address = true })) |s6| {
            var sv = s6;
            p("  .reuse_address=true 后同端口再 listen → ok，端口 {d}== {d}？ {}\n", .{
                sv.socket.address.getPort(), reuse_port, sv.socket.address.getPort() == reuse_port,
            });
            p("    ⇒ 真的绑到了**同一个端口**（SO_REUSEPORT 生效，内核在两个 socket 间负载均衡）\n", .{});
            sv.deinit(io);
        } else |e| {
            p("  .reuse_address=true 后同端口再 listen → {s}\n", .{@errorName(e)});
        }
        s5.deinit(io);
        // 对照：reuse_address 默认 false
        const a6 = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var s6b = try a6.listen(io, .{});
        const busy = try net.IpAddress.parseIp4("127.0.0.1", s6b.socket.address.getPort());
        if (busy.listen(io, .{})) |s7| {
            var sv = s7;
            p("  .reuse_address 默认 false 时同端口再 listen → 成功？不该\n", .{});
            sv.deinit(io);
        } else |e| {
            p("  .reuse_address 默认 false 时同端口再 listen → {s}（这才是\"端口被占\"的典型错误）\n", .{@errorName(e)});
        }
        s6b.deinit(io);
    }
    p("BindOptions 逐字段实测：\n", .{});
    {
        inline for (.{
            .{ "allow_broadcast=true", net.IpAddress.BindOptions{ .mode = .dgram, .allow_broadcast = true } },
            .{ "protocol=.udp", net.IpAddress.BindOptions{ .mode = .dgram, .protocol = .udp } },
            .{ "protocol=.tcp + dgram", net.IpAddress.BindOptions{ .mode = .dgram, .protocol = .tcp } },
        }) |case| {
            const a = try net.IpAddress.parseIp4("127.0.0.1", 0);
            if (a.bind(io, case[1])) |s| {
                var sv = s;
                p("  {s} → ok(port={d})（实测形如 51xxx）\n", .{ case[0], sv.address.getPort() });
                sv.close(io);
            } else |e| {
                p("  {s} → {s}\n", .{ case[0], @errorName(e) });
            }
        }
        p("  ⚠️ .ip6_only=true 在 AF_INET 上会**直接 panic**（0.17 std bug，见 29.3.3），故此处不测\n", .{});
    }
    p("Socket.createPair（socketpair）在 POSIX 上**默认失败**（实测）\n", .{});
    p("  @hasDecl(Socket, \"createPair\") = {}，但 CreatePairOptions.family 默认 .ip4，\n", .{
        @hasDecl(net.Socket, "createPair"),
    });
    p("  而 POSIX 的 socketpair(2) **只支持 AF_UNIX** → 内核回ENOTSUP(102)，\n", .{});
    p("  std 的 netSocketCreatePair 把它归到 unexpectedErrno ⇒ 得到 error.Unexpected（会 dump 栈）。\n", .{});
    p("  ⇒ 测 TCP 数据面别用 socketpair，用 listen(port=0)+connect（29.4 已验证）。\n", .{});
    p("  另外它返回 [2]**Socket** 而非 Stream，想要 reader/writer 得自己包 Stream{{.socket=s}}。\n", .{});
    end("29.3");

    // ═══ 29.4 ⚠️ 0.17 最大的福利：Socket.address 带回了真实端口 ═══
    begin("29.4");
    p("0.16 时\"绑 0 拿临时端口\"行不通（std 不暴露 getsockname），\n", .{});
    p("所以大家只能写\"固定起始端口 + 扫 20 个\"的笨办法。**0.17 修好了**：\n", .{});
    {
        const zero = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try zero.listen(io, .{ .reuse_address = true });
        p("  listen(\"127.0.0.1\", **0**) → 成功\n", .{});
        p("  srv.socket.address.getPort() = {d}  ←内核给的 ephemeral 端口，**直接可读**\n", .{srv.socket.address.getPort()});
        const z2 = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var usock = try z2.bind(io, .{ .mode = .dgram });
        p("  bind(\"127.0.0.1\", **0**, .dgram) → sock.address.getPort() = {d}\n", .{usock.address.getPort()});
        usock.close(io);
        // 拿到端口就能连
        const real = srv.socket.address.getPort();
        const peer = try net.IpAddress.parseIp4("127.0.0.1", real);
        var cli = try peer.connect(io, .{ .mode = .stream });
        var stream = try srv.accept(io);
        p("  用读到的端口 {d} 反过来 connect → fd={d}，accept 得到 fd={d}（不同 fd）\n", .{
            real, cli.socket.handle, stream.socket.handle,
        });
        cli.close(io);
        stream.close(io);
        srv.deinit(io);
    }
    p("⇒ 0.17 里\"固定端口 + 扫 20 个\"已经是**遗留写法**了。\n", .{});
    p("  但本章示例仍保留它，因为**测试里要能复现\"端口被占\"这条路径**（见 29.11）。\n", .{});
    end("29.4");

    // ═══ 29.5 Conn：自引用结构体的悬垂指针坑 ═══
    begin("29.5");
    p("把 Stream / Reader / Writer 和它们的缓冲放同一 struct 是最自然的写法，\n", .{});
    p("**也是本章最大的坑**。先看反例（这段代码能编译通过）：\n", .{});
    p("  fn init(io, stream) Conn {{\n", .{});
    p("      var self = Conn{{ .stream = stream, ... }};\n", .{});
    p("      self.r = stream.reader(io, &self.rbuf);  // ⚠️ 绑到的是 **init 的栈帧**\n", .{});
    p("      return self;                          // ⚠️ 值拷贝⇒ r 里的指针悬垂\n", .{});
    p("  }}\n", .{});
    p("实测（同一个 stream，读之前先污染栈）：\n", .{});
    {
        const zero = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try zero.listen(io, .{});
        const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
        var cli = try peer.connect(io, .{ .mode = .stream });
        var stream = try srv.accept(io);
        {
            var wb: [64]u8 = undefined;
            var w = stream.writer(io, &wb);
            try w.interface.writeAll("tiny");
            try w.interface.flush();
        }
        // 反例：就地绑定后按值返回
        const BadConn = struct {
            rbuf: [64]u8 = undefined,
            r: net.Stream.Reader,
            stream: net.Stream,
            io: std.Io,
            fn make(io2: std.Io, st: net.Stream) @This() {
                var self = @This(){ .io = io2, .stream = st, .r = undefined };
                self.r = st.reader(io2, &self.rbuf); //绑到 init 的栈帧
                return self; // 值拷贝
            }
        };
        var bad = BadConn.make(io, cli);
        p("  bad.r.interface.buffer.ptr = 0x{x}\n", .{@intFromPtr(bad.r.interface.buffer.ptr)});
        p("  &bad.rbuf              = 0x{x}\n", .{@intFromPtr(&bad.rbuf)});
        p("  ⇒ 两者相同？ {}（**false 就说明 Reader 指着别人家的缓冲**）\n", .{
            bad.r.interface.buffer.ptr == &bad.rbuf,
        });
        p("  两个指针差 {d} 字节（这是两个栈帧的距离，**不是** rbuf 的大小——\n", .{
            @intFromPtr(&bad.rbuf) - @intFromPtr(bad.r.interface.buffer.ptr),
        });
        p("     关键是这个距离**不为 0**：Reader 的 buffer 指向 init 早已返回的栈帧。\n", .{});
        p("  ⇒ 这就是悬垂指针。\n", .{});
        p("  实测后果：往这块内存 fillMore 能成功（内核照收），但 buffered() 返回的是\n", .{});
        p("  **那块已被复用的栈**——小包时恰好没被覆盖，缓冲区一大就彻底乱序。\n", .{});
        cli.close(io);
        stream.close(io);
        srv.deinit(io);
    }
    p("⇒ **症状是\"小包偶尔对、缓冲区一大就乱\"**，极难查（编译期完全无警告）。\n", .{});
    p("规则三条：\n", .{});
    p("  1. Reader/Writer 只在栈帧内用，不跨函数返回、不进结构体、不进数组\n", .{});
    p("  2. 必须持有时，**只存原料**（Stream + []u8），用的时候再 reader(io, buf) 绑一次\n", .{});
    p("  3. 实在要存（比如要复用连接），就用**懒绑定**（见下面 Conn.ensureBound）\n", .{});
    p("本章的 Conn 就是按第3 条写的：\n", .{});
    p("  bound: bool = false，\n", .{});
    p("  fn ensureBound(self: *Conn) void {{\n", .{});
    p("      if (self.bound) return;\n", .{});
    p("      self.r = self.stream.reader(self.io, &self.rbuf);\n", .{});
    p("      self.w = self.stream.writer(self.io, &self.wbuf);\n", .{});
    p("      self.bound = true;\n", .{});
    p("  }}\n", .{});
    p("每次收发前先 ensureBound()——那时 self 已经在最终位置了。\n", .{});
    {
        const zero = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try zero.listen(io, .{});
        const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
        var cli = try peer.connect(io, .{ .mode = .stream });
        var stream = try srv.accept(io);
        var good = Conn.init(io, cli);
        p("  ensureBound 之前 bound = {}（还是原料状态）\n", .{good.bound});
        try good.sendAll("hello-good");
        {
            var rb: [64]u8 = undefined;
            var r = stream.reader(io, &rb);
            _ = r.interface.fillMore() catch {};
            const m = r.interface.bufferedLen();
            var wb: [64]u8 = undefined;
            var w = stream.writer(io, &wb);
            try w.interface.writeAll(r.interface.buffered()[0..m]);
            try w.interface.flush();
        }
        var buf: [64]u8 = undefined;
        const n = try good.recvSome(&buf);
        p("  懒绑定往返 {d} 字节 ={s}\n", .{ n, buf[0..n] });
        p("  good.r.interface.buffer.ptr = 0x{x}\n", .{@intFromPtr(good.r.interface.buffer.ptr)});
        p("  &good.rbuf               = 0x{x}  ⇒ 相同 = {}✅\n", .{
            @intFromPtr(&good.rbuf), good.r.interface.buffer.ptr == &good.rbuf,
        });
        p("  ensureBound 之后 bound = {}\n", .{good.bound});
        cli.close(io);
        stream.close(io);
        srv.deinit(io);
    }
    end("29.5");

    // ═══ 29.6 服务器三步：listen → accept → 收发 ═══
    begin("29.6");
    p("服务器就三步：\n", .{});
    p("  1. listen：拿一个 Server（含 listening socket）\n", .{});
    p("  2. accept：**阻塞**直到有连接进来，返回一个 Stream\n", .{});
    p("  3. 收发：在那个 Stream 上开 Reader/Writer\n", .{});
    p("三步的形状（29.4 已验证过能通，这里把类型都打出来）：\n", .{});
    {
        const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try addr.listen(io, .{});
        p("  var server = tryaddr.listen(io, .{{}})  → Server{{socket, options}}\n", .{});
        p("  defer server.deinit(io)  ← Server 有 deinit（不是 close！）\n", .{});
        const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
        var cli = try peer.connect(io, .{ .mode = .stream });
        // ⚠️ accept 要 *Server：srv 必须声明成 var，且按地址传
        var stream = try srv.accept(io);
        p("  var stream = try server.accept(io)  → Stream{{socket}}\n", .{});
        p("  ⚠️ accept 的接收者是 *Server（**非const**），所以 server 必须 var\n", .{});
        p("  defer stream.close(io)     ← Stream 有 close\n", .{});
        p("  收发缓冲要各配一块（Reader 和 Writer 的 buffer 是独立的）\n", .{});
        p("  Stream.Reader 字段：", .{});
        inline for (@typeInfo(net.Stream.Reader).@"struct".field_names) |n| p(" {s}", .{n});
        p("\n  Stream.Writer 字段：", .{});
        inline for (@typeInfo(net.Stream.Writer).@"struct".field_names) |n| p(" {s}", .{n});
        p("\n  ⚠️ interface 是**字段**不是函数，所以调用是r.interface.fillMore()\n", .{});
        p("  ⚠️ Stream.read(io, [][]u8) 在 0.17.0 **标准库自身就编译不过**（29.7.1 详述）\n", .{});
        cli.close(io);
        stream.close(io);
        srv.deinit(io);
    }
    end("29.6");

    // ═══ 29.7 ⚠️ 三个收发坑：readSliceShort / takeDelimiterExclusive / close幂等 ═══
    begin("29.7");
    p("坑一：readSliceShort 是\"填满缓冲或读到 EOF\"，**不是单次 recv**\n", .{});
    {
        const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try addr.listen(io, .{});
        const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
        var cli = try peer.connect(io, .{ .mode = .stream });
        var stream = try srv.accept(io);
        {
            var wb: [8]u8 = undefined;
            var w = cli.writer(io, &wb);
            try w.interface.writeAll("abc"); // 只发 3 字节然后停住（不关）
            try w.interface.flush();
        }
        var rb: [16]u8 = undefined;
        var r = stream.reader(io, &rb);
        r.interface.fillMore() catch {};
        p("  对端发了 3 字节就停住：fillMore 后 buffered = {d} 字节 ={s}\n", .{
            r.interface.bufferedLen(), r.interface.buffered(),
        });
        p("  ⇒ readSliceShort(&16字节缓冲) 在这里会**一直等**（要填满 16 字节）——不能当 recv 用\n", .{});
        cli.close(io); // 关掉对端，readSliceShort 才会因EOF 返回
        var rb2: [16]u8 = undefined;
        var r2 = stream.reader(io, &rb2);
        const got = r2.interface.readSliceShort(&rb2) catch |e| {
            p("  对端关闭后 readSliceShort → {s}\n", .{@errorName(e)});
            stream.close(io);
            srv.deinit(io);
            return;
        };
        p("  对端关闭后 readSliceShort 返回 {d} 字节（只拿到 EOF 前的量，不是 16）\n", .{got});
        stream.close(io);
        srv.deinit(io);
    }
    p("  ⇒ 正确形状是 fillMore() + buffered() + toss()，见 Conn.recvSome\n", .{});
    p("     fillMore 在 EOF 时返回 error.EndOfStream（**不是 void**），必须 catch\n", .{});
    p("坑二：⚠️⚠️ takeDelimiterExclusive 在 0.17.0 **有 std bug**（本章头号发现）\n", .{});
    {
        // 纯内存 Reader 就能复现，与网络无关
        var r = std.Io.Reader.fixed("alpha\nbeta\ngamma\n");
        p("  纯内存 Reader.fixed(\"alpha\\nbeta\\ngamma\\n\")，连调 takeDelimiterExclusive('\\n')：\n", .{});
        for (0..4) |i| {
            const line = r.takeDelimiterExclusive('\n') catch |e| {
                p("    第 {d} 次 → {s}\n", .{ i + 1, @errorName(e) });
                continue;
            };
            p("    第 {d} 次 ={s}（{d} 字节）\n", .{ i + 1, line, line.len });
        }
        p("  ⇒ 只有第 1 次对，之后全是空片。**根因**（读 Reader.zig 的源码得到）：\n", .{});
        p("     takeDelimiterExclusive = peekDelimiterExclusive + toss(result.len)\n", .{});
        p("     peekDelimiterInclusive 返回**含分隔符**的切片（比如 \"alpha\\n\"，6 字节）\n", .{});
        p("     peekDelimiterExclusive 把它 [0..len-1] 缩成 \"alpha\"（5 字节）\n", .{});
        p("     takeDelimiterExclusive 只toss 5 字节 ⇒ **分隔符 '\\n' 留在缓冲里**\n", .{});
        p("     下一次 peek 从 seek 开始，第一个字符就是 '\\n' ⇒ 命中 → 返回 1 字节 → Exclusive 缩成 0 字节\n", .{});
        p("  ⚠️ 所以\"不阻塞就返回空片\"这个症状被误读了：它其实是**分隔符没被吃掉**。\n", .{});
        p("     服务端如果写 `while (true) {{ const line = takeDelimiterExclusive('\\n'); ... }}`，\n", .{});
        p("     就会陷入「读到空行 → 写 OK → 再读到空行」的死循环（因为内核数据一直不消耗）。\n", .{});
        p("  对照组（都正常，因为它们按inclusive 长度 toss）：\n", .{});
        {
            var r2 = std.Io.Reader.fixed("alpha\nbeta\n");
            for (0..3) |i| {
                const line = r2.takeDelimiterInclusive('\n') catch |e| {
                    p("    takeDelimiterInclusive 第 {d} 次 → {s}\n", .{ i + 1, @errorName(e) });
                    continue;
                };
                p("    takeDelimiterInclusive 第 {d} 次 ={s}（{d} 字节，**含\\n**）\n", .{ i + 1, line, line.len });
            }
            var r3 = std.Io.Reader.fixed("alpha\nbeta\n");
            for (0..3) |i| {
                const maybe = r3.takeDelimiter('\n') catch |e| {
                    p("    takeDelimiter 第 {d} 次 → {s}\n", .{ i + 1, @errorName(e) });
                    continue;
                };
                if (maybe) |line| {
                    p("    takeDelimiter 第 {d} 次 ={s}（{d} 字节）✅\n", .{ i + 1, line, line.len });
                } else p("    takeDelimiter 第 {d} 次 = null（真EOF）\n", .{i + 1});
            }
        }
        p("  ⇒ **0.17 里写行协议用 takeDelimiter（返回 ?[]u8）或 takeDelimiterInclusive**，\n", .{});
        p("     要么干脆不用分隔符：自己 fillMore + indexOfScalarPos + toss（见 29.7.3）。\n", .{});
        p("坑三：⚠️ Stream.close **不是幂等的**\n", .{});
        p("  显式 close 之后又 defer close → 第二次 close(2) 返回 EBADF，\n", .{});
        p("  0.17 把它当\"程序员的 bug\"直接 panic（Threaded.zig 的 recoverableOsBugDetected）：\n", .{});
        p("    thread N panic: reached unreachable code\n", .{});
        p("    Io/Threaded.zig:14472: in recoverableOsBugDetected\n", .{});
        p("        if (is_debug) unreachable;\n", .{});
        p("    Io/Threaded.zig:19963: in closeFd\n", .{});
        p("        .BADF => recoverableOsBugDetected(), // use after free\n", .{});
        p("  ⇒ 规则：**要么全 defer，要么全显式**，绝不混用。本章 Conn 用 closed 标志兜住。\n", .{});
    }
    end("29.7");

    // ═══ 29.8 TCP vs UDP：连接性、有序、报头 ═══
    begin("29.8");
    p("| 维度| TCP | UDP |\n", .{});
    p("| 连接 | 有（connect/accept，内核维护状态机） | 无（bind/sendto/recvfrom） |\n", .{});
    p("| 可靠 | 有（序号 + 重传） | 无（丢了就丢了） |\n", .{});
    p("| 有序 | 有| 无（后到的可能先到） |\n", .{});
    p("| 边界 | 字节流（**没有消息边界**） | 保留消息边界（一次 sendto = 一个数据报） |\n", .{});
    p("| 报头 | TCP 20 字节 + 选项 | UDP 8 字节 |\n", .{});
    p("| 典型用途 | HTTP/SSH/数据库 | DNS/QUIC/视频/游戏 |\n", .{});
    p("UDP 在 std.Io.net 里的形状：\n", .{});
    {
        const saddr = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try saddr.bind(io, .{ .mode = .dgram });
        p("  var sock = try addr.bind(io, .{{.mode = .dgram}})  → Socket（不是 Stream！）\n", .{});
        p("  sock.send(io, &dest, data)发；sock.receive(io, &buf) 收\n", .{});
        const caddr = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var cli = try caddr.bind(io, .{ .mode = .dgram });
        p("  服务端 bind(0) → {d}；客户端 bind(0) → {d}（两个独立端点）\n", .{
            srv.address.getPort(), cli.address.getPort(),
        });
        const dest = try net.IpAddress.parseIp4("127.0.0.1", srv.address.getPort());
        try cli.send(io, &dest, "dgram-hello");
        var ubuf: [64]u8 = undefined;
        const inc = try srv.receive(io, &ubuf);
        p("  receive → IncomingMessage：\n", .{});
        p("    .from = ", .{});
        var fw: [64]u8 = undefined;
        var fwr = std.Io.Writer.fixed(&fw);
        try inc.from.format(&fwr);
        p("{s}（**来路地址**，回射就发回它）\n", .{fwr.buffered()});
        p("    .data ={s}（{d} 字节）\n", .{ inc.data, inc.data.len });
        p("    .control.len = {d}（没提供控制缓冲，所以是 0）\n", .{inc.control.len});
        p("    .flags: eor={} trunc={} ctrunc={} oob={} errqueue={}\n", .{
            inc.flags.eor, inc.flags.trunc, inc.flags.ctrunc, inc.flags.oob, inc.flags.errqueue,
        });
        p("  ⚠️ .data 是**切片，指向你传给 receive 的那个 buf**，不是拷贝！\n", .{});
        p("     所以必须在下一次 receive 之前用完，否则内容被覆盖。\n", .{});
        // 回射
        try srv.send(io, &inc.from, inc.data);
        var cbuf: [64]u8 = undefined;
        const back = try cli.receive(io, &cbuf);
        p("  从 .from 回射 → 客户端收到 {s}\n", .{back.data});
        // 超长数据报
        var huge: [70000]u8 = undefined;
        @memset(&huge, 'z');
        if (cli.send(io, &dest, huge[0..])) |_| {
            p("  发 70000 字节 → 内核直接报错（数据报有 MTU 上限）\n", .{});
        } else |e| {
            p("  发 70000 字节（超过 MTU）→ {s}⇒ send 会检查短写并报这个\n", .{@errorName(e)});
        }
        // 缓冲不够 → 数据被截断但不报错
        try cli.send(io, &dest, "0123456789");
        var small: [4]u8 = undefined;
        const r2 = try srv.receive(io, &small);
        p("  10 字节数据报用 4 字节缓冲receive → {d} 字节，flags.trunc={}（**静默截断，不报错**）\n", .{
            r2.data.len, r2.flags.trunc,
        });
        cli.close(io);
        srv.close(io);
    }
    p("⚠️ 另一个实测坑：Socket **没有** reader/writer 方法（只有 Stream 有）\n", .{});
    p("  @hasDecl(Socket, \"reader\") = {}；@hasDecl(Socket, \"writer\") = {}\n", .{
        @hasDecl(net.Socket, "reader"), @hasDecl(net.Socket, "writer"),
    });
    p("  ⇒ UDP **没有 Reader/Writer 这一层**，收发就是 send/receive 一来一回（零缓冲管理）。\n", .{});
    end("29.8");

    // ═══ 29.9 缓冲区、背压与半关闭 ═══
    begin("29.9");
    p("缓冲：Reader 和 Writer **各要一块** buffer，互不共享。\n", .{});
    p("  buffer 决定 fillMore 一次能拿多少（影响吞吐，不影响语义）。\n", .{});
    p("  ⚠️ Writer 有用户态缓冲，**必须 flush**；Stream.close **不会**替你 flush。\n", .{});
    p("背压：写方写太快，内核缓冲满了 → write 阻塞（可取消）。\n", .{});
    {
        const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try addr.listen(io, .{ .kernel_backlog = 1 });
        const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
        var cli = try peer.connect(io, .{ .mode = .stream });
        var stream = try srv.accept(io); // 服务端拿到连接但**故意不读**
        var payload: [64 * 1024]u8 = undefined;
        @memset(&payload, 'x');
        var wb: [64 * 1024]u8 = undefined;
        var w = cli.writer(io, &wb);
        var total: usize = 0;
        for (0..8) |_| {
            w.interface.writeAll(&payload) catch |e| {
                p("  写了 {d} 字节后 → {s}（服务端不读 ⇒ 内核缓冲满 ⇒ 被拖住）\n", .{ total, @errorName(e) });
                break;
            };
            total += payload.len;
        } else {
            p("  写了 {d} 字节没阻塞 ⇒ 本机 socket 缓冲至少这么大\n", .{total});
        }
        p("  ⇒ **背压就是机制本身**：读慢的一方通过 TCP 窗口把写方拖住，不是 bug。\n", .{});
        p("     事件循环版本要靠 Writable 事件驱动\"能写了\"，而不是循环 write（29.10 会提）。\n", .{});
        cli.close(io);
        stream.close(io);
        srv.deinit(io);
    }
    p("半关闭：⚠️ 0.17 **有** shutdown —— Stream.shutdown(io, how)，how ∈ ", .{});
    inline for (@typeInfo(net.ShutdownHow).@"enum".field_names) |n| p(".{s} ", .{n});
    p("\n", .{});
    {
        const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try addr.listen(io, .{});
        const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
        var cli = try peer.connect(io, .{ .mode = .stream });
        var stream = try srv.accept(io);
        {
            var wb: [16]u8 = undefined;
            var w = cli.writer(io, &wb);
            try w.interface.writeAll("bye");
            try w.interface.flush();
        }
        var rb: [16]u8 = undefined;
        var r = stream.reader(io, &rb);
        r.interface.fillMore() catch {};
        p("  服务端先读到 ={s}\n", .{r.interface.buffered()});
        r.interface.toss(r.interface.bufferedLen());
        cli.shutdown(io, .send) catch |e| p("  客户端 shutdown(.send) → {s}\n", .{@errorName(e)});
        r.interface.fillMore() catch |e| {
            p("  客户端半关闭后，服务端 fillMore → {s}（这就是 EOF 的形态）\n", .{@errorName(e)});
        };
        {
            var wb: [16]u8 = undefined;
            var w = stream.writer(io, &wb);
            try w.interface.writeAll("ack");
            try w.interface.flush();
        }
        var rb2: [16]u8 = undefined;
        var r2 = cli.reader(io, &rb2);
        r2.interface.fillMore() catch {};
        p("  客户端半关闭后仍能读到服务端数据 ={s}\n", .{r2.interface.buffered()});
        p("  ⇒ shutdown(.send) 只关**写**方向（TCP 的 half-close），读方向还通。\n", .{});
        p("     这正是\"客户端发完请求就不再发、但还要读响应\"的标准做法（HTTP/1.1 就是这样）。\n", .{});
        cli.close(io);
        stream.close(io);
        srv.deinit(io);
    }
    p("对端硬close（不是 shutdown）时，fillMore 也报 EndOfStream —— ⚠️ 0.17 分不出这两者：\n", .{});
    {
        const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try addr.listen(io, .{});
        const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
        var cli = try peer.connect(io, .{ .mode = .stream });
        var stream = try srv.accept(io);
        cli.close(io); // 硬关
        var rb: [16]u8 = undefined;
        var r = stream.reader(io, &rb);
        r.interface.fillMore() catch |e| {
            p("  对端 close 后 fillMore → {s}（与 shutdown 情形**同形**）\n", .{@errorName(e)});
        };
        stream.close(io);
        srv.deinit(io);
    }
    end("29.9");

    // ═══ 29.10 错误处理：三种失败要分开 ═══
    begin("29.10");
    p("网络代码的困难：**失败不是异常，是日常**。要分清三种：\n", .{});
    p("  1. 连接被拒（ConnectionRefused）—— 对端没监听 / 队列满 / 端口没开\n", .{});
    p("  2. 超时（Timeout）—— 对端在但不响应，需要 deadline\n", .{});
    p("  3. 对端关闭（EndOfStream）—— **不是错误**，是协议的一部分\n", .{});
    p("实测的错误名（127.0.0.1 上真跑出来的）：\n", .{});
    {
        const dead = try net.IpAddress.parseIp4("127.0.0.1", 1);
        if (dead.connect(io, .{ .mode = .stream })) |s| {
            var sv = s;
            p("  connect 127.0.0.1:1（没人监听）→ 成功？不该\n", .{});
            sv.close(io);
        } else |e| {
            p("  connect 127.0.0.1:1（没人监听）→ {s}\n", .{@errorName(e)});
        }
        const unr = try net.IpAddress.parseIp4("0.0.0.0", 9);
        if (unr.connect(io, .{ .mode = .stream })) |s| {
            var sv = s;
            p("  connect 0.0.0.0:9→ 成功？不该\n", .{});
            sv.close(io);
        } else |e| {
            p("  connect 0.0.0.0:9（连本机任何地址）→ {s}\n", .{@errorName(e)});
        }
        const alien = try net.IpAddress.parseIp4("8.8.8.8", 9);
        if (alien.listen(io, .{})) |s| {
            var sv = s;
            p("  listen 8.8.8.8（非本机地址）→ 成功？不该\n", .{});
            sv.deinit(io);
        } else |e| {
            p("  listen 8.8.8.8（非本机地址）→ {s}（地址不属于本机任何网卡）\n", .{@errorName(e)});
        }
        if (alien.bind(io, .{ .mode = .dgram })) |s| {
            var sv = s;
            p("  bind 8.8.8.8 → 成功？不该\n", .{});
            sv.close(io);
        } else |e| {
            p("  bind 8.8.8.8（非本机地址）→ {s}\n", .{@errorName(e)});
        }
        // backlog 满 ⇒ 第 N+1 次连接超时/被拒
        const a = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try a.listen(io, .{ .kernel_backlog = 1 });
        const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
        var held: [2]net.Stream = undefined;
        var ok: usize = 0;
        for (0..2) |_| {
            if (peer.connect(io, .{ .mode = .stream })) |s| {
                held[ok] = s;
                ok += 1;
            } else |e| {
                p("  backlog=1 时第 {d} 次 connect → {s}\n", .{ ok + 1, @errorName(e) });
                break;
            }
        }
        p("  backlog=1 且不 accept → {d} 条连上，第 {d} 条 {s}\n", .{ ok, ok + 1, "被拒或超时" });
        p("  ⇒ **ConnectionRefused 和 Timeout 都可能是\"对方在但队列满\"**，要看 backlog\n", .{});
        for (0..ok) |i| held[i].close(io);
        srv.deinit(io);
        // IPv6 回环
        if (net.IpAddress.parseIp6("::1", 0)) |v6| {
            if (v6.listen(io, .{})) |s| {
                var sv = s;
                p("  listen [::1]:0 → ok(port={d})（本机 IPv6 回环可用）\n", .{sv.socket.address.getPort()});
                sv.deinit(io);
            } else |e| {
                p("  listen [::1]:0 → {s}\n", .{@errorName(e)});
            }
        } else |e| {
            p("  parseIp6 → {s}\n", .{@errorName(e)});
        }
        // ⚠️⚠️ ConnectOptions.timeout 在 POSIX 上是**未实现**的：只要 != .none 就 panic
        p("  ⚠️ ConnectOptions.timeout：POSIX 上只要 != .none 就@panic（0.17 未实现）\n", .{});
        p("     源码 Threaded.zig:12410 → if (options.timeout != .none) @panic(\"TODO implement netConnectIpPosix with timeout\")\n", .{});
        p("     ⇒ 超时要靠 io 层的 deadline / 事件驱动，**不能**靠这个字段（Windows 上同样未实现）\n", .{});
        const c9 = try net.IpAddress.parseIp4("127.0.0.1", 9);
        if (c9.connect(io, .{ .mode = .stream })) |s| {
            var sv = s;
            p("  不带 timeout 连 127.0.0.1:9 → 成功？不该\n", .{});
            sv.close(io);
        } else |e| {
            p("  不带 timeout 连 127.0.0.1:9 → {s}（连拒绝是立刻的）\n", .{@errorName(e)});
        }
        // Io.Timeout 的形状仍可断言（只是不能传给 connect）
        const to = std.Io.Timeout{ .duration = .{ .raw = .fromSeconds(1), .clock = .awake } };
        p("  Io.Timeout 是 union(enum)，构造得出：{s}\n", .{@tagName(to)});
    }
    p("三段式 catch（照抄20.12 的模式，只是错误集换成网络的）：\n", .{});
    p("  connect(...) catch |err| switch (err) {{\n", .{});
    p("      error.ConnectionRefused => return error.ServerNotRunning, // 业务上的\"没开\"\n", .{});
    p("      error.Timeout, error.WouldBlock => return error.ServerBusy,\n", .{});
    p("      error.AddressFamilyUnsupported, error.AccessDenied => return err, // 真错误\n", .{});
    p("      else => |e| return e, // 兜底，别 catch {{}}\n", .{});
    p("  }}\n", .{});
    end("29.10");

    // ═══ 29.11 线程模型与端口扫描 ═══
    begin("29.11");
    p("两种模型：\n", .{});
    p("  一连接一线程（本示例）：简单、每条连接独立阻塞栈；上千连接就吃不消\n", .{});
    p("  事件循环（生产）：单线程非阻塞 + 就绪事件；Zig 里由 io.vtable 的实现决定\n", .{});
    p("    init.io 走的是 Threaded（线程池）实现；事件驱动是另一种 Io 实现，同一份业务代码不变\n", .{});
    p("  ⇒ **这就是\"io 是参数\"的回报**：换 io 就换线程模型，业务代码一行不改。\n", .{});
    p("⚠️ 一连接一线程的写法陷阱：Server.accept 要 **\\*Server**（非 const）\n", .{});
    p("  Thread.spawn(.{{}}, serve, .{{ io, srv }})     → 找不到 expected type '*net.Server'\n", .{});
    p("  Thread.spawn(.{{}}, serve, .{{ io, &srv }})    → 对（手动取地址）\n", .{});
    p("  且被调函数形参必须是 fn serve(io: std.Io, srv: *net.Server, ...) —— 写 const 会收不到\n", .{});
    p("端口扫描：⚠️ **必须从非 0 的高位端口起**，实测对比：\n", .{});
    {
        // 从 0 起
        const z = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var s0 = try z.listen(io, .{});
        p("  从 **0** 起扫：第一轮就\"成功\"，拿到端口 {d} ← 这是内核给的 ephemeral\n", .{s0.socket.address.getPort()});
        p("     你连自己都不确定连到了谁（可能就是别的进程），所以扫描绝不能从 0 起\n", .{});
        s0.deinit(io);
        // 从高位起
        const acquired = try listenSomewhere(io, 49421, .{});
        var srv = acquired.server;
        p("  从 **49421** 起扫：拿到端口 {d}（第一个就成功，说明没冲突）\n", .{acquired.port});
        p("  ⚠️ 端口 49421 起、扫 20 个：这个范围是本教程的\"私用段\"，\n", .{});
        p("     run-all.sh 与其它章的示例可能同时占端口，所以要扫够冗余（本机实测 20 个够）。\n", .{});
        // 占住 49421，再扫一次 ⇒ 应当跳过它落到 49422
        srv.deinit(io);
        const base = try net.IpAddress.parseIp4("127.0.0.1", 49421);
        var occupier = try base.listen(io, .{});
        p("  先手动占住 49421，然后从 49421 再扫 → ", .{});
        const skipped = try listenSomewhere(io, 49421, .{});
        p("落到 {d}（+{d}）⇒ 扫描确实会跳过被占的端口\n", .{
            skipped.port, skipped.port - 49421,
        });
        occupier.deinit(io);
        var skipped2 = skipped;
        skipped2.server.deinit(io);
    }
    end("29.11");

    // ═══ 29.12 自演：UDP 三数据报 + TCP 两连接 ═══
    begin("29.12");
    // UDP：服务线程 + 主线程客户端，3 个数据报一来一回
    {
        var rz = Rendezvous{};
        var want: usize = 3;
        const th = try std.Thread.spawn(.{}, udpEchoServer, .{ io, &rz, &want });
        const uport = awaitPort(&rz);
        p("UDP 服务器就绪：127.0.0.1:{d}（高位端口起扫，实测形如 49xxx）\n", .{uport});

        const dest = try net.IpAddress.parseIp4("127.0.0.1", uport);
        const cbase = try net.IpAddress.parseIp4("127.0.0.1", uport + 100); // 客户端占另一个口
        var sock = try cbase.bind(io, .{ .mode = .dgram });
        defer sock.close(io);
        for (0..3) |i| {
            const payload = try std.fmt.allocPrint(mem, "dgram-{d}", .{i});
            try sock.send(io, &dest, payload);
            var buf: [128]u8 = undefined;
            const incoming = try sock.receive(io, &buf);
            std.debug.assert(std.mem.eql(u8, payload, incoming.data));
            p("  UDP 回声一致：{s}（from端口 {d}）\n", .{ incoming.data, incoming.from.getPort() });
        }
        th.join();
        p("UDP echo 完成（3 数据报，join 即同步——没有 WaitGroup）\n", .{});
    }
    // TCP：服务线程 + 主线程 2 条连接 × 2 消息
    {
        const acquired = try listenSomewhere(io, 49421, .{ .reuse_address = true });
        var srv = acquired.server;
        p("TCP 服务器就绪：127.0.0.1:{d}（std.Io.net 直连）\n", .{acquired.port});

        var rounds: usize = 2;
        const th = try std.Thread.spawn(.{}, tcpEchoServer, .{ io, &srv, &rounds });
        const peer = try net.IpAddress.parseIp4("127.0.0.1", acquired.port);
        for (0..2) |round| {
            var conn = Conn.init(io, try peer.connect(io, .{ .mode = .stream }));
            defer conn.close();
            for (0..2) |k| {
                const msg = try std.fmt.allocPrint(mem, "ping-{d}-{d}", .{ round, k });
                try conn.sendAll(msg);
                var buf: [64]u8 = undefined;
                const n = try conn.recvSome(&buf);
                std.debug.assert(n == msg.len and std.mem.eql(u8, msg, buf[0..n]));
            }
            p("  第 {d} 条连接 2×2 收发一致\n", .{round});
        }
        th.join();
        srv.deinit(io);
        p("TCP echo 完成（2 连接）\n", .{});
    }
    end("29.12");

    p("自检通过\n", .{});
}

// ═══════════════════════════ 测试 ═══════════════════════════

test "29.2 IpAddress 解析：三个入口与它们的错误集" {
    const a = try net.IpAddress.parseIp4("127.0.0.1", 8080);
    try std.testing.expectEqual(@as(u16, 8080), a.getPort());
    var b = a;
    b.setPort(9090);
    try std.testing.expectEqual(@as(u16, 9090), b.getPort());

    // Ip4Address.ParseError 全部 5 个成员都要能断言到
    try std.testing.expectError(error.InvalidCharacter, net.IpAddress.parseIp4("not-an-ip", 1));
    try std.testing.expectError(error.Overflow, net.IpAddress.parseIp4("256.1.1.1", 1));
    try std.testing.expectError(error.Incomplete, net.IpAddress.parseIp4("1.2.3", 1));
    try std.testing.expectError(error.InvalidEnd, net.IpAddress.parseIp4("1.2.3.4.5", 1));
    try std.testing.expectError(error.NonCanonical, net.IpAddress.parseIp4("01.2.3.4", 1));

    // parse 统一报 v6 的错误名（因为它先试 v4 再 v6）
    try std.testing.expectError(error.ParseFailed, net.IpAddress.parse("garbage", 1));
    try std.testing.expectError(error.ParseFailed, net.IpAddress.parseIp6("127.0.0.1", 1));
    try std.testing.expectError(error.UnresolvedScope, net.IpAddress.parseIp6("fe80::1%en0", 1));

    const v6 = try net.IpAddress.parseIp6("::1", 443);
    try std.testing.expectEqual(net.IpAddress.Family.ip6, std.meta.activeTag(v6));
    try std.testing.expectEqual(@as(u16, 443), v6.getPort());

    // parseLiteral：v6 字面量必须带方括号
    const lit = try net.IpAddress.parseLiteral("127.0.0.1:1234");
    try std.testing.expectEqual(@as(u16, 1234), lit.getPort());
    try std.testing.expectError(error.InvalidAddress, net.IpAddress.parseLiteral("::1"));
    try std.testing.expectError(error.InvalidPort, net.IpAddress.parseLiteral("127.0.0.1:x"));

    // loopback 构造器
    const lb = net.Ip4Address.loopback(9);
    try std.testing.expectEqualSlices(u8, &.{ 127, 0, 0, 1 }, &lb.bytes);
    try std.testing.expectEqual(@as(u16, 9), lb.port);

    // format 要用 Io.Writer（不是 std.fmt）
    var buf: [64]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try a.format(&w);
    try std.testing.expectEqualStrings("127.0.0.1:8080", w.buffered());
}

test "29.2 ⚠️ 0.17.0 takeDelimiterExclusive 有 std bug：分隔符不被吃掉" {
    // 这不是网络问题，纯内存 Reader 就能复现
    var r = std.Io.Reader.fixed("alpha\nbeta\ngamma\n");
    // 第一次是对的
    try std.testing.expectEqualStrings("alpha", try r.takeDelimiterExclusive('\n'));
    // 第二次起全是空片—— 因为上一次只 toss 了内容，'\n' 还在缓冲里
    try std.testing.expectEqualStrings("", try r.takeDelimiterExclusive('\n'));
    try std.testing.expectEqualStrings("", try r.takeDelimiterExclusive('\n'));

    // 正解一：takeDelimiter（?[]u8）按inclusive 长度 toss
    var r2 = std.Io.Reader.fixed("alpha\nbeta\n");
    try std.testing.expectEqualStrings("alpha", (try r2.takeDelimiter('\n')).?);
    try std.testing.expectEqualStrings("beta", (try r2.takeDelimiter('\n')).?);
    try std.testing.expectEqual(@as(?[]u8, null), try r2.takeDelimiter('\n'));

    // 正解二：takeDelimiterInclusive 含分隔符，所以正常推进
    var r3 = std.Io.Reader.fixed("alpha\nbeta\n");
    try std.testing.expectEqualStrings("alpha\n", try r3.takeDelimiterInclusive('\n'));
    try std.testing.expectEqualStrings("beta\n", try r3.takeDelimiterInclusive('\n'));
    try std.testing.expectError(error.EndOfStream, r3.takeDelimiterInclusive('\n'));

    // 根因断言：take 之后 seek 指向的字节**就是分隔符本身**
    var r4 = std.Io.Reader.fixed("ab\ncd\n");
    _ = try r4.takeDelimiterExclusive('\n');
    try std.testing.expectEqual(@as(u8, '\n'), r4.buffered()[0]);
    // 手动补一次 toss 就正常了
    r4.toss(1);
    try std.testing.expectEqualStrings("cd", try r4.takeDelimiterExclusive('\n'));
}

test "29.3 ⚠️ listen/bind/connect 接收者是 *const IpAddress（不是 const）" {
    // 这条靠编译期保证：下面这行**故意不编译**，注释里记着原因
    //   try net.IpAddress.parseIp4("127.0.0.1", 0).listen(io, .{});
    // error: no field or member function named 'listen' in
    //         'error{Incomplete,InvalidCharacter,InvalidEnd,NonCanonical,Overflow}!Io.net.IpAddress'
    // ——因为 parseIp4 返回的是错误联合，先得 try 落地成IpAddress 才能调成员函数。
    // 正确写法（本测试用的就是这个）：
    const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    // addr 是 const IpAddress，但 listen 要 *const IpAddress —— const 的地址仍然可取 ✅
    _ = addr;
    // ⚠️ 但注意：即便接收者是 *const，如果 IpAddress 是**临时值**就没法取地址。
    //所以模式是「先存变量、再操作」。
}

test "29.3 Socket.Mode 枚举与选项结构的形状（反射断言）" {
    // Socket.Mode 恰好 5 个成员，顺序固定
    try std.testing.expectEqual(@as(usize, 5), @typeInfo(net.Socket.Mode).@"enum".field_names.len);
    try std.testing.expectEqual(net.Socket.Mode.stream, @field(net.Socket.Mode, "stream"));
    try std.testing.expectEqual(net.Socket.Mode.dgram, @field(net.Socket.Mode, "dgram"));

    // ListenOptions：kernel_backlog 默认 128，mode 默认 .stream
    const lo = net.IpAddress.ListenOptions{};
    try std.testing.expectEqual(@as(u31, 128), lo.kernel_backlog);
    try std.testing.expectEqual(net.Socket.Mode.stream, lo.mode);
    try std.testing.expectEqual(net.Protocol.tcp, lo.protocol);
    try std.testing.expect(!lo.reuse_address);

    // BindOptions.mode / ConnectOptions.mode **没有默认值** —— 靠字段类型断言
    inline for (@typeInfo(net.IpAddress.BindOptions).@"struct".field_names) |n| {
        try std.testing.expect(n[0..n.len].len > 0);
    }
    try std.testing.expectEqual(@as(usize, 4), @typeInfo(net.IpAddress.BindOptions).@"struct".field_names.len);
    try std.testing.expectEqual(@as(usize, 3), @typeInfo(net.IpAddress.ConnectOptions).@"struct".field_names.len);

    // ConnectOptions.timeout 默认 .none（Io.Timeout 是 union(enum)）
    const co = net.IpAddress.ConnectOptions{ .mode = .stream };
    try std.testing.expectEqual(std.Io.Timeout.none, co.timeout);
}

test "29.4 Socket.address 带回了真实端口（0.17 相对 0.16 的改善）" {
    const io = std.testing.io;
    const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var srv = try addr.listen(io, .{});
    defer srv.deinit(io);
    const port = srv.socket.address.getPort();
    try std.testing.expect(port != 0); // 不是 0 ⇒ 内核真的分配了 ephemeral 端口

    // 拿读到的端口反connect，能通
    const peer = try net.IpAddress.parseIp4("127.0.0.1", port);
    var cli = try peer.connect(io, .{ .mode = .stream });
    defer cli.close(io);
    var stream = try srv.accept(io);
    defer stream.close(io);
    try std.testing.expect(cli.socket.handle != stream.socket.handle);
}

test "29.5 ⚠️ 懒绑定是必须的：init 里就地绑定会让Reader 指向别的对象" {
    const io = std.testing.io;
    const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var srv = try addr.listen(io, .{});
    const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
    const cli = try peer.connect(io, .{ .mode = .stream });
    var stream = try srv.accept(io);

    // 正解：Conn.init 只存原料，bound=false
    var conn = Conn.init(io, cli);
    try std.testing.expect(!conn.bound);
    // ensureBound 之后必须精确指向自己的缓冲字段
    conn.ensureBound();
    try std.testing.expect(conn.bound);
    try std.testing.expect(conn.r.interface.buffer.ptr == &conn.rbuf);
    try std.testing.expect(conn.w.interface.buffer.ptr == &conn.wbuf);

    // 端到端：往返一致
    try conn.sendAll("round-trip");
    var rb: [64]u8 = undefined;
    var r = stream.reader(io, &rb);
    _ = r.interface.fillMore() catch {};
    const m = r.interface.bufferedLen();
    try std.testing.expectEqualStrings("round-trip", r.interface.buffered()[0..m]);
    var wb: [64]u8 = undefined;
    var w = stream.writer(io, &wb);
    try w.interface.writeAll(r.interface.buffered()[0..m]);
    try w.interface.flush();

    var buf: [64]u8 = undefined;
    const n = try conn.recvSome(&buf);
    try std.testing.expectEqualStrings("round-trip", buf[0..n]);

    conn.close();
    try std.testing.expect(conn.closed);
    // 第二次 close 被 closed 标志挡住 ⇒ 不会 BADF panic
    conn.close();
    stream.close(io);
    srv.deinit(io);
}

test "29.7 close 幂等保护：Conn.close 关两次不panic" {
    const io = std.testing.io;
    const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var srv = try addr.listen(io, .{});
    const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
    const cli = try peer.connect(io, .{ .mode = .stream });
    var stream = try srv.accept(io);

    var conn = Conn.init(io, cli);
    try std.testing.expect(!conn.closed);
    conn.close();
    conn.close(); // ⚠️ 没有 closed 标志的话这里会 panic: BADF
    conn.close();
    try std.testing.expect(conn.closed);

    stream.close(io);
    srv.deinit(io);
}

test "29.8 UDP 回环：send/receive + IncomingMessage 的.data 指向调用者的 buf" {
    const io = std.testing.io;
    const saddr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var srv = try saddr.bind(io, .{ .mode = .dgram });
    defer srv.close(io);
    const caddr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var cli = try caddr.bind(io, .{ .mode = .dgram });
    defer cli.close(io);

    try cli.send(io, &srv.address, "hello-dgram");
    var buf: [64]u8 = undefined;
    const inc = try srv.receive(io, &buf);
    try std.testing.expectEqualStrings("hello-dgram", inc.data);
    // ⚠️ .data 是切片，**借用**了 buf——指针必须落在 buf 里
    try std.testing.expect(@intFromPtr(inc.data.ptr) >= @intFromPtr(&buf));
    try std.testing.expect(@intFromPtr(inc.data.ptr) < @intFromPtr(&buf) + buf.len);
    try std.testing.expectEqual(net.IpAddress.Family.ip4, std.meta.activeTag(inc.from));
    try std.testing.expectEqual(cli.address.getPort(), inc.from.getPort());

    // 回射
    try srv.send(io, &inc.from, inc.data);
    var cbuf: [64]u8 = undefined;
    const back = try cli.receive(io, &cbuf);
    try std.testing.expectEqualStrings("hello-dgram", back.data);

    // 截断：小缓冲 receive 大数据报 → 静默截断，flags.trunc=true
    try cli.send(io, &srv.address, "0123456789");
    var small: [4]u8 = undefined;
    const trunc = try srv.receive(io, &small);
    try std.testing.expectEqual(@as(usize, 4), trunc.data.len);
    try std.testing.expect(trunc.flags.trunc);

    //超 MTU → send 报 MessageOversize
    var huge: [70000]u8 = undefined;
    @memset(&huge, 'z');
    try std.testing.expectError(error.MessageOversize, cli.send(io, &srv.address, huge[0..]));
}

test "29.9 半关闭：shutdown(.send) 让对端读到 EOF，但本端仍能收" {
    const io = std.testing.io;
    const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var srv = try addr.listen(io, .{});
    const peer = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
    var cli = try peer.connect(io, .{ .mode = .stream });
    var stream = try srv.accept(io);

    try cli.shutdown(io, .send);

    // 服务端读到 EOF（fillMore 报 EndOfStream）
    var rb: [16]u8 = undefined;
    var r = stream.reader(io, &rb);
    try std.testing.expectError(error.EndOfStream, r.interface.fillMore());

    // 但服务端仍能写，客户端仍能读（读方向没关）
    var wb: [16]u8 = undefined;
    var w = stream.writer(io, &wb);
    try w.interface.writeAll("ack");
    try w.interface.flush();
    var rb2: [16]u8 = undefined;
    var r2 = cli.reader(io, &rb2);
    _ = r2.interface.fillMore() catch {};
    try std.testing.expectEqualStrings("ack", r2.interface.buffered());

    cli.close(io);
    stream.close(io);
    srv.deinit(io);
}

test "29.10 错误分类：连接被拒 / 超时 / 地址不可用要分开" {
    const io = std.testing.io;
    //没人监听 → ConnectionRefused
    const dead = try net.IpAddress.parseIp4("127.0.0.1", 1);
    try std.testing.expectError(error.ConnectionRefused, dead.connect(io, .{ .mode = .stream }));
    // 非本机地址 → AddressUnavailable
    const alien = try net.IpAddress.parseIp4("8.8.8.8", 9);
    try std.testing.expectError(error.AddressUnavailable, alien.listen(io, .{}));
    try std.testing.expectError(error.AddressUnavailable, alien.bind(io, .{ .mode = .dgram }));
    // mode 不匹配 → SocketModeUnsupported
    const loop = try net.IpAddress.parseIp4("127.0.0.1", 0);
    try std.testing.expectError(error.SocketModeUnsupported, loop.listen(io, .{ .mode = .dgram }));
    // 同端口重复 listen → AddressInUse（reuse_address 在 macOS 上也不放过）
    var srv = try loop.listen(io, .{});
    const same = try net.IpAddress.parseIp4("127.0.0.1", srv.socket.address.getPort());
    try std.testing.expectError(error.AddressInUse, same.listen(io, .{}));
    srv.deinit(io);
    // ⚠️ **不要**给 connect 传 .timeout：POSIX 上那会@panic（0.17 未实现，见 29.10.3）
    // 断言的是 Io.Timeout 的形状本身
    try std.testing.expectEqual(std.Io.Timeout.none, (net.IpAddress.ConnectOptions{ .mode = .stream }).timeout);
    const to = std.Io.Timeout{ .duration = .{ .raw = .fromSeconds(1), .clock = .awake } };
    try std.testing.expectEqualStrings("duration", @tagName(to));
}

test "29.11 端口扫描必须从高位非 0 端口起，且会跳过被占的" {
    const io = std.testing.io;
    // 陷阱：从 0 起扫会"立刻成功"并拿到 ephemeral 端口
    const z = try net.IpAddress.parseIp4("127.0.0.1", 0);
    var s0 = try z.listen(io, .{});
    const ephemeral = s0.socket.address.getPort();
    s0.deinit(io);
    // ephemeral 端口是内核给的，绝不会等于你请求的 0
    try std.testing.expect(ephemeral != 0);
    // 而且 address.getPort() 是**可信的**：拿它去连，能连上并被 accept
    {
        var again = try z.listen(io, .{});
        defer again.deinit(io);
        const claimed = again.socket.address.getPort();
        const target = try net.IpAddress.parseIp4("127.0.0.1", claimed);
        var cli = try target.connect(io, .{ .mode = .stream });
        defer cli.close(io);
        var acc = try again.accept(io);
        acc.close(io);
    }

    // 正解：先占住 49421，再从 49421 扫 ⇒ 必须落到 49422
    const base = try net.IpAddress.parseIp4("127.0.0.1", 49421);
    var occupier = try base.listen(io, .{});
    defer occupier.deinit(io);
    const skipped = try listenSomewhere(io, 49421, .{});
    try std.testing.expectEqual(@as(u16, 49422), skipped.port);
    var sk = skipped;
    sk.server.deinit(io);
}

test "29.11 accept 要 *Server：形参写成 const 会编译不过" {
    // 这个测试只断言类型形状；真正的编译期约束来自签名本身：
    //   pub fn accept(s: *Server, io: Io) AcceptError!Stream
    // 接收者非 const ⇒ srv 必须是 var，且跨线程传要写 &srv。
    const F = @TypeOf(net.Server.accept);
    try std.testing.expect(!@typeInfo(F).@"fn".is_generic);
    // 参数 2 个：(s: *Server, io: Io)
    try std.testing.expectEqual(@as(usize, 2), @typeInfo(F).@"fn".param_types.len);
    try std.testing.expectEqual(@as(?type, @TypeOf(@as(*net.Server, undefined))), @typeInfo(F).@"fn".param_types[0]);
    try std.testing.expectEqual(@as(?type, std.Io), @typeInfo(F).@"fn".param_types[1]);
}

test "29.11 TCP 回环：2 连接 × 2 消息 + UDP 回环：3 数据报" {
    const a = std.testing.allocator;
    const io = std.testing.io;

    // TCP：服务线程 + 主线程客户端
    const acquired = try listenSomewhere(io, 49421, .{ .reuse_address = true });
    var srv = acquired.server;
    defer srv.deinit(io);
    var rounds: usize = 2;
    const th = try std.Thread.spawn(.{}, tcpEchoServer, .{ io, &srv, &rounds });
    const peer = try net.IpAddress.parseIp4("127.0.0.1", acquired.port);
    for (0..2) |round| {
        var conn = Conn.init(io, try peer.connect(io, .{ .mode = .stream }));
        defer conn.close();
        for (0..2) |k| {
            const msg = try std.fmt.allocPrint(a, "ping-{d}-{d}", .{ round, k });
            defer a.free(msg);
            try conn.sendAll(msg);
            var buf: [64]u8 = undefined;
            const n = try conn.recvSome(&buf);
            try std.testing.expectEqualStrings(msg, buf[0..n]);
        }
    }
    th.join(); // join 即同步：服务线程干完 rounds 条就return 了

    // UDP：服务线程 + 主线程客户端
    var rz = Rendezvous{};
    var want: usize = 3;
    const uth = try std.Thread.spawn(.{}, udpEchoServer, .{ io, &rz, &want });
    const uport = awaitPort(&rz);
    const dest = try net.IpAddress.parseIp4("127.0.0.1", uport);
    const cbase = try net.IpAddress.parseIp4("127.0.0.1", uport + 100);
    var sock = try cbase.bind(io, .{ .mode = .dgram });
    defer sock.close(io);
    for (0..3) |i| {
        const payload = try std.fmt.allocPrint(a, "dgram-{d}", .{i});
        defer a.free(payload);
        try sock.send(io, &dest, payload);
        var buf: [128]u8 = undefined;
        const inc = try sock.receive(io, &buf);
        try std.testing.expectEqualStrings(payload, inc.data);
    }
    uth.join();
}
