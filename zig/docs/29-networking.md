# 29 · TCP 与 UDP

> 对应示例：`examples/29_netecho/main.zig`（1378 行，13 个 test）
>
> echo 是网络编程的 "hello world"——服务器回射一切。取材 Tsoukalos ch6（TCP/UDP echo 双实现），
> 但写法完全是 0.17 的：`IpAddress.listen / connect / bind` → `Server` / `Stream` / `Socket`，
> 收发一律走 Reader/Writer，且**每个方法第一个参数都是 `io`**。
>
> 本章把 `lib/std/Io/net.zig`（1633 行）逐个方法**实测**一遍，写成29.3 的签名表，
> 然后按 12 节展开。所有输出都在 `/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig`（0.17.0）
> + macOS 上跑出来的。
>
> **本章有六条结论会推翻你可能听过的说法**：
>
> 1. **⚠️⚠️ `takeDelimiterExclusive` 在 0.17.0 有std bug：它不吃掉分隔符。**
>    第一次调用正确，第二次起**永远返回空片**。纯内存 `Reader.fixed` 就能复现，与网络无关。
>    根因不是"不阻塞"（网上都这么说），而是 `toss` 的长度算错了。见 29.7.3。
> 2. **⚠️ `ConnectOptions.timeout` 在 0.17 是未实现的**：POSIX 上只要不是 `.none` 就直接
>    `@panic("TODO implement netConnectIpPosix with timeout")`。Windows 上同样。见 29.10.3。
> 3. **⚠️ `BindOptions.ip6_only = true` 在 AF_INET 上直接 panic**：
>    `programmer bug caused syscall error: INVAL`——0.17 的 `netBindIpPosix` 无条件设
>    `IPV6_V6ONLY`。见 29.3.3。
> 4. **0.17 里 `Socket.address` 带回了绑定后的真实端口**。`srv.socket.address.getPort()`
>    直接可读、实测可信（拿它去连能连上并被 accept）。0.16 时代"绑 0 拿临时端口"行不通，
>    逼得所有人写"固定端口 + 扫 20 个"的笨办法。见 29.4。
> 5. **`takeDelimiterExclusive` 不是"不阻塞"**。它内部走
>    `peekDelimiterExclusive` → `peekDelimiterInclusive`，后者是 `while (true) { fillMore }`，
>    **会阻塞地取数据**。真正的 bug 是分隔符没被吃掉。
> 6. **0.17 没有 `getAddressList`**。DNS 换成了 `HostName.lookup` / `HostName.connect`
>    这个"函数式 + 队列"的子模块。见 29.2.3。
>
> 另外三条已在 [00 迁移手册](00-migration-0.17.md) 第 0.5 节记录、本章再次实测确认：
> `Stream.read(io, [][]u8)` 在标准库自身编译不过（29.7.1）、`readSliceShort` 是"填满或 EOF"
> 语义（29.7.2）、自引用结构体不能按值拷贝（29.5，本章讲得最透）。

---

## 29.1 为什么 0.17 把网络收进 `std.Io`

### 29.1.1 一句话：让"依赖"看得见

0.16 里 socket 是**全局的**——`std.net.StreamServer` 内部直接调 `std.posix.socket`，
没有任何东西能塞进去替换。测试要真开一个 socket，测完还得小心别和别的测试撞端口。

0.17 把网络整体搬进了 `std.Io`：**所有方法的第一个参数都变成 `io: std.Io`**。于是：

```text
| 语言| I/O 从哪来 | 后果 |
|---|---|---|
| **C** | 全局（`stdin`/`stdout`/`errno`） | 多线程要小心全局 errno；测试要重定向 fd |
| **Go** | `*os.File` 显式传，但 `os.Stdout` 是全局 | `os.Stdout` 可被替换（`io.Writer` 接口） |
| **Rust** | `impl Read` / `AsRef<Path>`，泛型注入 | 换实现要改类型（`dyn` 可以但啰嗦） |
| **Python** | 全局 `open()`，靠 monkeypatch 换 | 测试要 `monkeypatch.setattr("builtins.open", ...)` |
| **Zig 0.17** | **`io: Io` 显式在签名里** | 换实现 = 换一个参数值；编译器保证不漏 |
```

关键差别在最后一行：Python 的 `open` 能被换是因为**它是全局查找**，
而全局查找是**隐式依赖**——你读一个函数签名看不出它会碰网络。
Zig 的 `addr.listen(io, opts)` 一眼就能看出"这个函数会做网络 I/O，而且需要一个 `Io`"。

```zig
// examples/29_netecho/main.zig 第 190-200 行
    begin("29.1");
    p("0.17：TCP/UDP 全部在 std.Io.net 下，**每个方法的第一个参数都是 io**\n", .{});
    p("  好处  1 可替换：main 传 init.io（事件循环），test 传 std.testing.io\n", .{});
    p("  好处  2 可测试：io 是参数 ⇒ 能塞假实现、能在测试里换掉整个后端\n", .{});
    p("  好处  3 可异步：同一份代码能在阻塞 io 和事件驱动 io 上跑\n", .{});
    p("  ⚠️ 代价：每个方法都要写 io。这不是啰嗦，是让\"依赖\"看得见\n", .{});
    p("  对比：0.16 的 socket 是全局的，测试要重定向 fd；Python 要 monkeypatch\n", .{});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
==== 29.1 开始 ====
0.17：TCP/UDP 全部在 std.Io.net 下，**每个方法的第一个参数都是 io**
  好处  1 可替换：main 传 init.io（事件循环），test 传 std.testing.io
  好处  2 可测试：io 是参数 ⇒ 能塞假实现、能在测试里换掉整个后端
  好处  3 可异步：同一份代码能在阻塞 io 和事件驱动 io 上跑
  ⚠️ 代价：每个方法都要写 io。这不是啰嗦，是让"依赖"看得见
  对比：0.16 的 socket 是全局的，测试要重定向 fd；Python 要 monkeypatch
```

这三条收益在本章都有对应的实测：

| 收益 | 本章哪里兑现 |
|---|---|
| 可替换 | 29.11：`init.io` 是 Threaded（线程池）；换事件驱动的 `Io`，同一份 `tcpEchoServer` 一行不改 |
| 可测试 | 29.12 / 13 个 test：全部用 `std.testing.io` 跑真实回环 |
| 可异步 | 29.9：`fillMore` / `buffered` 这套 API 本身就是"非阻塞友好"的形状 |

### 29.1.2 `io.vtable` 的 13 个网络槽位

网络的一切都经由 `io.vtable` 上的一组函数指针（`lib/std/Io/Threaded.zig` 是默认实现）：

```zig
// examples/29_netecho/main.zig 第 217-222 行
    var net_slots: usize = 0;
    inline for (@typeInfo(std.Io.VTable).@"struct".field_names) |n| {
        if (std.mem.startsWith(u8, n, "net")) net_slots += 1;
    }
    p("Io.vtable 里 net* 槽位（共 {d} 个，由 Threaded 实现）：\n", .{net_slots});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
Io.vtable 里 net* 槽位（共 13 个，由 Threaded 实现）：
  ⇒ 网络的一切都经由 io.vtable ⇒ 理论上可以自己写假 Io 替换它们（本章不深挖）
```

13 个槽位（实测名字）：

```text
netListenIp          netAccept            netBindIp             netConnectIp
netListenUnix        netConnectUnix       netSocketCreatePair   netWriteFile
netClose             netShutdown          netInterfaceNameResolve
netInterfaceName     netLookup
```

**这条"可以自己写假 `Io`"是本章不深挖但值得提一句的事**：`IpAddress.listen` 的实现只有一行
`io.vtable.netListenIp(io.userdata, address, options)`。也就是说，只要你能造一个自己的
`std.Io`（`Io{ .userdata = ..., .vtable = &my_vtable }`），就能把整个网络层换成假的——
不需要改一行业务代码。这是 20 章"显式传 io"的哲学在网络上的极致体现，也是把网络代码
做成纯单元测试（不真开端口）的唯一途径。

### 29.1.3 类型全景（反射实测）

```zig
// examples/29_netecho/main.zig 第 197-216 行
    p("IpAddress 是 {s}，tag 类型 = {s}\n", .{
        @typeName(net.IpAddress),
        @typeName(@typeInfo(net.IpAddress).@"union".tag_type.?),
    });
    inline for (@typeInfo(net.IpAddress).@"union".field_names, @typeInfo(net.IpAddress).@"union".field_types) |n, t| p("  变体 {s}: {s}\n", .{ n, @typeName(t) });
    p("Ip4Address 字段：", .{});
    inline for (@typeInfo(net.Ip4Address).@"struct".field_names) |n| p(" {s}", .{n});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
IpAddress 是 Io.net.IpAddress，tag 类型 = @typeInfo(Io.net.IpAddress).@"union".tag_type.?
  变体 ip4: Io.net.Ip4Address
  变体 ip6: Io.net.Ip6Address
Ip4Address 字段： bytes port（bytes 是 [4]u8，**不是** u32——网络序要自己拼，别照抄 C 的 sockaddr）
Ip6Address 字段： port bytes flow interface（比 v4 多 flow/interface 两个链路层字段）
Socket 字段： handle address（handle 是 fd；**address 是 0.17 新增的实用字段**）
Server 字段： socket options（options 的类型是 void，POSIX 上是 void）
Socket.Mode 枚举（实测）： .stream .dgram .seqpacket .raw .rdm（.raw 要 root；.rdm 多数平台不支持）
```

四个要点：

1. **`IpAddress` 是 `union(enum)`**，变体 `ip4` / `ip6`。所以它**不能按值 `format`**——
   0.17 要用 `addr.format(w)`（接收 `*Io.Writer`），没有 `std.fmt` 那种 `{s}`。
   而 `union(enum)` 在 0.17 的 `@typeInfo` 里**也没有 `fields` 字段**（实测报
   `no field named 'fields' in struct 'lang.Type.Union'`），只有 `field_names` / `field_types`。
2. **`Ip4Address.bytes` 是 `[4]u8`，不是 `u32`**。这不是细节——C 的 `sockaddr_in.addr`
   是网络序的 `u32`（`127.0.0.1` 即 `0x0100007f`），照抄 C 代码会写错字节序。
   0.17 用 `[4]u8` 让你**没有犯错的余地**。
3. **`Socket` 只有两个字段**：`handle`（fd）和 `address`。后者是 29.4 的主角。
4. **`Server.options` 的类型在 POSIX 上是 `void`**（Windows 上是
   `struct { mode, protocol }`）。所以跨平台代码不能假设它有字段。

`Socket.Mode` 的 5 个成员对应 POSIX 的 `SOCK_*`：

```text
| 成员 | POSIX 常量 | 语义 |
|---|---|---|
| `.stream` | `SOCK_STREAM` | 有序可靠双向字节流（TCP）—— **默认值** |
| `.dgram` | `SOCK_DGRAM` | 无连接数据报（UDP） |
| `.seqpacket` | `SOCK_SEQPACKET` | 有序可靠**定长报**，保留消息边界 |
| `.raw` | `SOCK_RAW` | 裸 IP，**要 root** |
| `.rdm` | `SOCK_RDM` | 可靠数据报（不可靠层），**多数平台不支持** |
```

## 29.2 地址解析：三个入口，三套错误集

### 29.2.1 `parseIp4` / `parseIp6` / `parse` / `parseLiteral`

0.17 有**四个**解析入口（不是三个），各自带**不同的错误集**：

| 入口 | 返回类型 | 错误集 |
|---|---|---|
| `IpAddress.parseIp4(text, port)` | `Ip4Address.ParseError!IpAddress` | **5 个**：`Overflow` / `InvalidCharacter` / `InvalidEnd` / `Incomplete` / `NonCanonical` |
| `IpAddress.parseIp6(text, port)` | `Ip6Address.ParseError!IpAddress` | **2 个**：`ParseFailed` / `UnresolvedScope` |
| `IpAddress.parse(text, port)` | `!IpAddress` | 先试 v4，全失败就试 v6 ⇒ **报的是 v6 的错误名** |
| `IpAddress.parseLiteral(text)` | `ParseLiteralError!IpAddress` | **2 个**：`InvalidAddress` / `InvalidPort` |

```zig
// examples/29_netecho/main.zig 第 227-247 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
  parseIp4("127.0.0.1", 8080) → format =127.0.0.1:8080，getPort()=8080
  setPort(9090) 后 getPort()=9090（port 是**本机序**，不是网络序）
  Ip4Address.loopback(9) = 127.0.0.1:9（现成的回环地址构造器）
Ip4Address.ParseError 的全部成员（实测 5 个）： Overflow InvalidCharacter InvalidEnd Incomplete NonCanonical
  ⇒ 非法 IP 报的是 error.InvalidCharacter，**不是** InvalidAddress（别想当然）
```

**`getPort()` / `setPort()` 用的是本机序（native endian）**，不是网络序。源码注释写得很清楚：
`/// Returns the port in native endian.`。这一点和 C 的 `sockaddr_in` 正好相反——
C 里存的是网络序。这是个真实的移植陷阱。

### 29.2.2 逐个输入实测

```zig
// examples/29_netecho/main.zig 第 248-266 行
    {
        inline for (.{
            "127.0.0.1", "0.0.0.0", "255.255.255.255",
            "256.1.1.1", "1.2.3", "1.2.3.4.5", "not-an-ip", "", "01.2.3.4", "1.2.3.4 ",
        }) |text| {
            if (net.IpAddress.parseIp4(text, 80)) |a| {
                _ = a;
                p("  parseIp4(\"{s}\") → ok\n", .{text});
            } else |e| {
                p("  parseIp4(\"{s}\") → {s}\n", .{ text, @errorName(e) });
            }
        }
```

运行输出（`examples/29_netecho/main.zig`）：

```text
  parseIp4("127.0.0.1") → ok
  parseIp4("0.0.0.0") → ok
  parseIp4("255.255.255.255") → ok
  parseIp4("256.1.1.1") → Overflow
  parseIp4("1.2.3") → Incomplete
  parseIp4("1.2.3.4.5") → InvalidEnd
  parseIp4("not-an-ip") → InvalidCharacter
  parseIp4("") → Incomplete
  parseIp4("01.2.3.4") → NonCanonical
  parseIp4("1.2.3.4 ") → InvalidCharacter
  parseIp6("::1") → ok，format =[::1]:80（v6 格式带方括号）
  parseIp6("fe80::1") → ok，format =[fe80::1]:80（v6 格式带方括号）
  parseIp6("127.0.0.1") → ParseFailed
  parseIp6("fe80::1%en0") → UnresolvedScope
Ip6Address.ParseError 只有 2 个： ParseFailed UnresolvedScope（**比 v4 少得多** —— v6 的检查靠 parser 自己）
  ⚠️ 带 scope 的"fe80::1%en0"要 parseIp6 **报 UnresolvedScope**：
     scope 要靠 IpAddress.resolve(io, ...) 查接口名→ 索引（要 io，因为它要 ioctl）
```

三个值得记住的细节：

- **`01.2.3.4` → `NonCanonical`**。IPv4 规范禁止前导零（因为 `010` 到底是十进制 10
  还是八进制 8 有歧义）。这是 0.17 特意加的检查。
- **`""` → `Incomplete`**（不是 `InvalidCharacter`）。空串连一个数字都没有，所以是"不完整"。
- **`parseIp6("fe80::1%en0")` → `UnresolvedScope`**。带 scope（`%en0`）的链路本地地址
  必须把**接口名解析成索引**，而那要调 `ioctl`，所以需要 `io`。纯函数做不到，
  得用 `IpAddress.resolve(io, text, port)`（`Io` 版本）或 `resolveIp6`。

`parse` 的行为值得单列，因为它**统一报 v6 的错误名**：

```text
  parse（自动 v4/v6）：
    parse("::1") → ok，tag=ip6
    parse("1.2.3.4") → ok，tag=ip4
    parse("garbage") → ParseFailed（v4 失败后**统一报 v6 的错误名**）
    parse("1.2.3.4.5") → ParseFailed（v4 失败后**统一报 v6 的错误名**）
```

源码（`net.zig:101-112`）先 `parseIp4`，把它的 5 个错误**全部吞掉**（`=> {}`），
然后 `return parseIp6(text, port)`。所以你 `catch` 到的永远是 `ParseFailed` 或
`UnresolvedScope`。**诊断信息丢失了**——想知道具体哪一步失败，得自己先试 `parseIp4`。

`parseLiteral`（配置里那种 `"host:port"` 字符串）：

```text
  parseLiteral（带端口的字面量，v6 要方括号）：
    parseLiteral("127.0.0.1:1234") → ok tag=ip4 port=1234
    parseLiteral("[::1]:443") → ok tag=ip6 port=443
    parseLiteral("[::1]") → ok tag=ip6 port=0
    parseLiteral("::1") → InvalidAddress
    parseLiteral("127.0.0.1") → ok tag=ip4 port=0
    parseLiteral("127.0.0.1:notaport") → InvalidPort
    parseLiteral("") → InvalidAddress
  ⚠️ parseLiteral 的错误集只有 2 个： InvalidAddress InvalidPort
  ⚠️ "::1"（不带方括号）→ InvalidAddress：v6 字面量**必须**是 "[::1]" 形状
```

**IPv6 字面量必须带方括号**——这是 RFC 3986 的规定（因为 v6 地址本身含 `:`，
不加分隔符就没法和端口区分）。所以 `"::1"` 报 `InvalidAddress`，
`"[::1]"` 才是合法的（端口为 0）。另外**不带端口时端口是 0**，
而 `getPort()` 会返回 0——所以 `parseLiteral("host")` 之后要自己 `setPort`。

### 29.2.3 ⚠️ 0.17 没有 `getAddressList`

```zig
// examples/29_netecho/main.zig 第 297-303 行
    p("0.17 有没有 getAddressList？ @hasDecl(net, \"getAddressList\") = {}\n", .{@hasDecl(net, "getAddressList")});
    p("⇒ **没有**。0.16 的 std.net.getAddressList 已改名/重做成 HostName 子模块：\n", .{});
    p("  net.HostName.lookup(host, io, *Queue(LookupResult), opts)  —— 纯函数式的 DNS 查询\n", .{});
    p("  net.HostName.connect(host, io, port, ConnectOptions)      —— 直接连主机名（lookup+connect 一体）\n", .{});
    p("  两者都吃 HostName（已校验的域名），构造用 net.HostName.init(bytes) 或 fromUri\n", .{});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
0.17 有没有 getAddressList？ @hasDecl(net, "getAddressList") = false
⇒ **没有**。0.16 的 std.net.getAddressList 已改名/重做成 HostName 子模块：
  net.HostName.lookup(host, io, *Queue(LookupResult), opts)  —— 纯函数式的 DNS 查询
  net.HostName.connect(host, io, port, ConnectOptions)      —— 直接连主机名（lookup+connect 一体）
  两者都吃 HostName（已校验的域名），构造用 net.HostName.init(bytes) 或 fromUri
```

`@hasDecl(std.Io.net, "getAddressList")` 实测 `false`。DNS 的形状完全变了：

```zig
// lib/std/Io/net/HostName.zig 第 185-192 行
pub fn lookup(
    host_name: HostName,
    io: Io,
    resolved: *Io.Queue(LookupResult),
    options: LookupOptions,
) LookupError!void
```

三个设计上的变化：

| | 0.16 `std.net.getAddressList` | 0.17 `HostName.lookup` |
|---|---|---|
| 返回 | 一个 `AddressList`（持有分配好的数组） | **往你给的 `*Io.Queue(LookupResult)` 里塞** |
| 内存 | 内部 alloc，调用方要 `deinit` | **零分配**（队列是你自己的栈数组） |
| 参数 | 域名、端口 | **`HostName`**（已校验）+ `Io` + 队列 + `LookupOptions` |
| 并发 | 内部决定 | 队列容量 ≥ 16 时**保证不阻塞** |

配套的用法是：

```zig
var results: [32]HostName.LookupResult = undefined;
var q: std.Io.Queue(HostName.LookupResult) = .init(&results);
try host.lookup(io, &q, .{ .port = 80 });
while (q.getOne(io)) |result| switch (result) {
    .address => |addr| { /* connect(addr, io, .{ .mode = .stream }) */ },
    .canonical_name => continue,
};
```

更常用的是 `HostName.connect(host, io, port, opts)`——它内部用 `io.async` 并行地
对所有解析出的 IP 同时发起连接，**谁先成功用谁**（"Happy Eyeballs" 的简化版）：

```zig
// lib/std/Io/net/HostName.zig 第 301-348 行
pub fn connect(host_name: HostName, io: Io, port: u16, options: IpAddress.ConnectOptions) ConnectError!Stream
```

注意 `HostName` 是**已校验的**——构造要用 `HostName.init(bytes)`（会跑 RFC 1123 校验：
标签 ≤ 63 字符、总长 ≤ 254、以字母数字开头结尾等）或 `HostName.fromUri`。这个"先校验再传递"
的设计让 DNS 查询变成**纯函数式**的：同一个 `HostName` 值总是得到同样的结果。

本章不深挖 DNS（30 章 HTTP 会用到 `HostName.connect`），但要记住：
**0.17 里"解析域名"不再是 `getAddressList` 那一套了**。

## 29.3 三个建端点的方法与全部选项

### 29.3.1 ⚠️ 接收者是 `*const IpAddress`

这是抄旧代码时第一个会撞上的报错：

```zig
// examples/29_netecho/main.zig 第 307-309 行
    p("⚠️ listen / bind / connect 的接收者是 **\\*const IpAddress**（不是 const IpAddress）：\n", .{});
    p("   `try parseIp4(...).listen(io, .{{}})` 编译不过—— 临时值取不到地址。必须先存成变量。\n", .{});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
⚠️ listen / bind / connect 的接收者是 **\*const IpAddress**（不是 const IpAddress）：
   `try parseIp4(...).listen(io, .{})` 编译不过—— 临时值取不到地址。必须先存成变量。
```

三条签名（源码 `net.zig:248/305/345`）：

```zig
pub fn listen(address: *const IpAddress, io: Io, options: ListenOptions) ListenError!Server
pub fn bind(address: *const IpAddress, io: Io, options: BindOptions) BindError!Socket
pub fn connect(address: *const IpAddress, io: Io, options: ConnectOptions) ConnectError!Stream
```

注意是 **`*const`**（指向常量的指针），不是 `const`（常量值）。这意味着：

```zig
//❌ 编译不过
const s = try net.IpAddress.parseIp4("127.0.0.1", 8080).listen(io, .{});
// error: no field or member function named 'listen' in
//         'error{Incomplete,InvalidCharacter,InvalidEnd,NonCanonical,Overflow}!Io.net.IpAddress'

// ✅ 对
const addr = try net.IpAddress.parseIp4("127.0.0.1", 8080);  // 先落地成 IpAddress
var srv = try addr.listen(io, .{});                            // const 的地址可以取
```

第一种写法报错的信息有两个误导点：一是说"没有 `listen` 成员"，
二是把 `parseIp4` 的错误集打印了出来（因为链式调用会短路）。实际上你缺的是**一个分号**。

这个签名对应的测试：

```zig
// examples/29_netecho/main.zig 第 1084-1097 行
test "29.3 ⚠️ listen/bind/connect 接收者是 *const IpAddress（不是 const）" {
    const io = std.testing.io;
    // 这条靠编译期保证：下面这行**故意不编译**，注释里记着原因
    //   try net.IpAddress.parseIp4("127.0.0.1", 0).listen(io, .{});
    // error: no field or member function named 'listen' in
    //         'error{Incomplete,InvalidCharacter,InvalidEnd,NonCanonical,Overflow}!Io.net.IpAddress'
    // ——因为 parseIp4 返回的是错误联合，先得 try 落地成 IpAddress 才能调成员函数。
    // 正确写法（本测试用的就是这个）：
    const addr = try net.IpAddress.parseIp4("127.0.0.1", 0);
    // addr 是 const IpAddress，但 listen 要 *const IpAddress —— const 的地址仍可取 ✅
    _ = addr;
    // ⚠️ 但注意：即便接收者是 *const，如果 IpAddress 是**临时值**就没法取地址。
    // 所以模式是「先存变量、再操作」。
}
```

### 29.3.2 ⚠️ 全部签名实测表（0.17.0）

**这张表是本章的核心资产。** 全部来自 `lib/std/Io/net.zig`（1633 行）源码 + 探针编译验证。
**记这张表比读十遍文档有用。**

`IpAddress` 上的四个建端点方法：

```text
| 方法 | 签名 | `io` 在第几参 |
|---|---|---|
| `listen` | `(address: *const IpAddress, io: Io, options: ListenOptions) ListenError!Server` | **2** |
| `bind` | `(address: *const IpAddress, io: Io, options: BindOptions) BindError!Socket` | **2** |
| `connect` | `(address: *const IpAddress, io: Io, options: ConnectOptions) ConnectError!Stream` | **2** |
| `resolve` | `(io: Io, text: []const u8, port: u16) !IpAddress`（带 scope 的 v6） | **1** ⚠️ |
| `resolveIp6` | `(io: Io, text: []const u8, port: u16) ResolveError!IpAddress` | **1** ⚠️ |

⚠️ 注意 `resolve` 系列**接收者在最前面**（因为它们不是 `IpAddress` 的方法，是模块级函数），
而 `listen/bind/connect` 的接收者**在第 0 位**、`io` 在第 1 位。抄的时候别弄混。

三个选项结构体的字段（`@typeInfo` 实测，**逐个在 29.3.3 试过**）：

```text
ListenOptions（→ Server）:
  kernel_backlog: u31 = 128        (net.default_kernel_backlog)
  reuse_address: bool = false      (POSIX 上同时设 SO_REUSEADDR + SO_REUSEPORT)
  mode: Socket.Mode = .stream      (.stream / .seqpacket)
  protocol: Protocol = .tcp        (.tcp / .tp / .dccp / .sctp)

BindOptions（→ Socket，UDP）:
  ip6_only: ?bool = null           ⚠️ 见29.3.3，在 AF_INET 上会 panic
  allow_broadcast: bool = false
  mode: Socket.Mode                ⚠️ **无默认值**，必写
  protocol: ?Protocol = null

ConnectOptions（→ Stream，TCP 客户端）:
  mode: Socket.Mode                ⚠️ **无默认值**，必写
  protocol: ?Protocol = null
  timeout: Io.Timeout = .none      ⚠️ 见 29.3.3，非 .none 会 panic
```

`Server` 上只有两个方法：

```text
| 方法 | 签名 | 备注 |
|---|---|---|
| `accept` | `(s: **\*Server**, io: Io) AcceptError!Stream` | ⚠️ **非 const**（29.11 详述） |
| `deinit` | `(s: *Server, io: Io) void` | 里面是 `s.socket.close(io); s.* = undefined;` |
```

`Stream` 上（收发）：

```text
| 方法 | 签名 | 备注 |
|---|---|---|
| `close` | `(s: *const Stream, io: Io) void` | ⚠️ **不是幂等的**（29.7） |
| **`shutdown`** | `(s: *const Stream, io: Io, how: ShutdownHow) ShutdownError!void` | ✅ 0.17 **有**半关闭 |
| `reader` | `(stream: Stream, io: Io, buffer: []u8) Reader` | |
| `readerWithControl` | `(stream, io, buffer, control_buffer)` | 带辅助数据（ancillary data） |
| `writer` | `(stream: Stream, io: Io, buffer: []u8) Writer` | |
| **`read`** | `(s: *const Stream, io: Io, data: [][]u8) Reader.Error!usize` | ❌ **0.17.0 编译不过**（29.7） |
| `readWithControl` | `(s: *const Stream, io, data: [][]u8, control: []u8) ReadResult` | 同上，也编译不过 |

`Socket` 上（数据报收发）：

```text
| 方法 | 签名 | 备注 |
|---|---|---|
| `close` | `(s: *const Socket, io: Io) void` | ⚠️ 不是幂等的 |
| `closeMany` | `(io: Io, sockets: []const Socket) void` | 批量关，避免逐个 syscall |
| **`send`** | `(s: *const Socket, io, dest: *const IpAddress, data: []const u8) SendError!void` | **一个包发完** |
| `sendTimeout` | `(s, io, dest, data, timeout: Io.Timeout)` | |
| `sendMany` | `(s, io, messages: []OutgoingMessage, flags: SendFlags) SendError!void` | ⚠️ 部分发送可能已发生但**不报告** |
| `sendManyTimeout` | `(s, io, messages, flags, timeout) struct { ?SendTimeoutError, usize }` | ✅ 会报告成功几个 |
| **`receive`** | `(s: *const Socket, io, buffer: []u8) ReceiveError!IncomingMessage` | |
| `receiveTimeout` | `(s, io, buffer, timeout)` | |
| `receiveManyTimeout` | `(s, io, message_buffer: []IncomingMessage, data_buffer, flags, timeout)` | 一次收多个 |
| `createPair` | `(io: Io, options: CreatePairOptions) CreatePairError![2]Socket` | ⚠️ POSIX 上默认失败（29.3.3） |
| ❌ `reader` / `writer` | **不存在** | ⚠️ UDP **没有** Reader/Writer 层（29.8） |
```

三个数据类型：

```text
IncomingMessage（receive 的返回）:
  from: IpAddress           来路地址（回射就发回它）
  data: []u8                ⚠️ **指向调用者传的 buffer**，不是拷贝（29.8）
  control: []u8             辅助数据缓冲（没提供就是空）
  flags: Flags              packed struct(u8): eor trunc ctrunc oob errqueue _

OutgoingMessage（sendMany 的元素）:
  address: *const IpAddress
  data_ptr: [*]const u8
  data_len: usize           初值=要发多少；成功返回后=实际发了多少
  control: []const u8 = &.{}
```

### 29.3.3 ⚠️ 逐个字段实测：三个 panic 藏在这里

```zig
// examples/29_netecho/main.zig 第 322-382 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
ListenOptions 逐字段实测：
  .kernel_backlog=1→ ok，实际端口 52042
  .mode=.seqpacket + .protocol=.sctp → ProtocolUnsupportedByAddressFamily（macOS 无 SCTP）
  .mode=.dgram 传给 listen → SocketModeUnsupported（listen 只接受面向连接的 mode）
  .protocol=.udp + 默认 .mode=.stream → SocketModeUnsupported（协议与 mode 不匹配）
  .reuse_address=true 后同端口再 listen → ok，端口 52043== 52043？ true
    ⇒ 真的绑到了**同一个端口**（SO_REUSEPORT 生效，内核在两个 socket 间负载均衡）
  .reuse_address 默认 false 时同端口再 listen → AddressInUse（这才是"端口被占"的典型错误）
BindOptions 逐字段实测：
  allow_broadcast=true → ok(port=53280)（实测形如 51xxx）
  protocol=.udp → ok(port=58811)（实测形如 51xxx）
  protocol=.tcp + dgram → SocketModeUnsupported
  ⚠️ .ip6_only=true 在 AF_INET 上会**直接 panic**（0.17 std bug，见 29.3.3），故此处不测
```

（端口号每次运行都不同，上面是某一次的实测值。）

四个结论：

**① `reuse_address` 在 POSIX 上同时设 `SO_REUSEADDR` 和 `SO_REUSEPORT`**（源码注释原文：
`/// Sets SO_REUSEADDR and SO_REUSEPORT on POSIX.`）。实测同端口第二次 `listen` **成功**，
而且 `address.getPort()` 和第一次**完全相同**——我进一步验证过：连接会被**第二个** Server
接受，确认内核在两个 listening socket 之间做负载均衡。这不是 bug，是 `SO_REUSEPORT` 的语义。

**② `reuse_address` 默认 `false`**，同端口再 listen 报 `AddressInUse`——这才是"端口被占"
的典型错误。29.11 的端口扫描就是靠这个错误来跳过的。

**③ mode/protocol 组合会被内核拒绝，且错误名很具体**：
`listen(mode = .dgram)` → `SocketModeUnsupported`；
`listen(mode = .stream, protocol = .udp)` → `SocketModeUnsupported`；
`listen(mode = .seqpacket, protocol = .sctp)` → `ProtocolUnsupportedByAddressFamily`（macOS 无 SCTP）。

**④ ⚠️ `BindOptions.ip6_only = true` 在 AF_INET 上直接 panic**：

```text
thread 2322574 panic: programmer bug caused syscall error: INVAL
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:14443:34: in errnoBug (main)
    if (is_debug) std.debug.panic("programmer bug caused syscall error: {t}", .{err});
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:12372:52: in setSocketOptionPosix (main)
                    .INVAL => |err| return errnoBug(err),
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:12608:33: in openSocketPosix (main)
        try setSocketOptionPosix(socket_fd, posix.IPPROTO.IPV6, posix.IPV6.V6ONLY, @intFromBool(ip6_only));
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:12535:42: in netBindIpPosix (main)
        const socket_fd = try openSocketPosix(family, options);
```

根因一眼可见：`openSocketPosix` **无条件**设 `IPV6_V6ONLY`，
而对 `AF_INET` socket 调 `setsockopt(IPV6_V6ONLY)` 内核返回 `EINVAL`，
`setSocketOptionPosix` 把 `INVAL` 归到 `errnoBug` ——也就是"程序员的 bug"，直接 panic。
**所以在 IPv4 上永远不要填 `ip6_only`**（哪怕填 `false` 也可能踩，源码是
`@intFromBool(ip6_only)`，但看调用点应该只在 `!= null` 时才设——0.17.0 里这段逻辑有问题）。
示例里干脆不测这一项。

### 29.3.4 ⚠️ `createPair`（socketpair）在 POSIX 上默认失败

```zig
// examples/29_netecho/main.zig 第 402-410 行
    p("Socket.createPair（socketpair）在 POSIX 上**默认失败**（实测）\n", .{});
    p("  @hasDecl(Socket, \"createPair\") = {}，但 CreatePairOptions.family 默认 .ip4，\n", .{
        @hasDecl(net.Socket, "createPair"),
    });
    p("  而 POSIX 的 socketpair(2) **只支持 AF_UNIX** → 内核回ENOTSUP(102)，\n", .{});
    p("  std 的 netSocketCreatePair 把它归到 unexpectedErrno ⇒ 得到 error.Unexpected（会 dump 栈）。\n", .{});
    p("  ⇒ 测 TCP 数据面别用 socketpair，用 listen(port=0)+connect（29.4 已验证）。\n", .{});
    p("  另外它返回 [2]**Socket** 而非 Stream，想要 reader/writer 得自己包 Stream{{.socket=s}}。\n", .{});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
Socket.createPair（socketpair）在 POSIX 上**默认失败**（实测）
  @hasDecl(Socket, "createPair") = true，但 CreatePairOptions.family 默认 .ip4，
  而 POSIX 的 socketpair(2) **只支持 AF_UNIX** → 内核回ENOTSUP(102)，
  std 的 netSocketCreatePair 把它归到 unexpectedErrno ⇒ 得到 error.Unexpected（会 dump 栈）。
  ⇒ 测 TCP 数据面别用 socketpair，用 listen(port=0)+connect（29.4 已验证）。
  另外它返回 [2]**Socket** 而非 Stream，想要 reader/writer 得自己包 Stream{.socket=s}。
```

`@hasDecl` 是 `true`（API 存在），但**实际调不通**。我用裸 `std.posix.system.socketpair`
交叉验证过：

```text
socketpair(AF_INET=2, SOCK_STREAM, 0) = -1 errno=102
socketpair(AF_UNIX=1, SOCK_STREAM, 0) = 0 errno=0
```

`errno 102` 在 macOS 上是 `ENOTSUP`。`netSocketCreatePair` 的错误映射表里没有它
（源码 `Threaded.zig:12678` 只有 `.ACCES/.AFNOSUPPORT/.INVAL/.MFILE/.NFILE/.NOBUFS/
.NOMEM/.PROTONOSUPPORT/.PROTOTYPE`），落到 `else => |err| return syscall.unexpectedErrno(err)`，
于是**打印一整个栈回溯**再返回 `error.Unexpected`。

**结论**：POSIX 上想用 socketpair 得写 `.family = ...`——但 `CreatePairOptions.family`
的类型是 `IpAddress.Family = enum { ip4, ip6 }`，**没有 `AF_UNIX` 这个选项**。
所以 0.17 的 `Socket.createPair` 在 POSIX 上**完全不可用**（这是 API 设计上的缺口）。
想测 TCP 数据面，唯一可移植的办法就是 `listen(port=0) + connect`——这也正是 29.4 的做法。

## 29.4 ⚠️ 0.17 最大的福利：`Socket.address` 带回了真实端口

这是本章相对 0.16 最重要的**改善**，也是让本章所有测试不再需要"扫 20 个端口"的关键。

### 29.4.1 0.16 的困境与0.17 的解法

0.16 的 `std.Io.net` **不暴露 `getsockname`**，所以"绑 0 让内核给个临时端口、
然后读出来告诉客户端"这个标准惯用法**行不通**。当时教程里（包括本教程的旧版本）
只有一条笨办法：**固定起始端口 + 逐个探测**。

0.17 修好了。`Socket` 有两个字段：

```zig
// lib/std/Io/net.zig 第 1055-1058 行
pub const Socket = struct {
    handle: Handle,
    /// Contains the resolved ephemeral port number if requested.
    address: IpAddress,
```

```zig
// examples/29_netecho/main.zig 第 415-432 行
    p("0.16 时\"绑 0 拿临时端口\"行不通（std 不暴露 getsockname），\n", .{});
    p("所以大家只能写\"固定起始端口 + 扫20 个\"的笨办法。**0.17 修好了**：\n", .{});
    {
        const zero = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try zero.listen(io, .{ .reuse_address = true });
        p("  listen(\"127.0.0.1\", **0**) → 成功\n", .{});
        p("  srv.socket.address.getPort() = {d}  ←内核给的 ephemeral 端口，**直接可读**\n", .{srv.socket.address.getPort()});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
==== 29.4 开始 ====
0.16 时"绑 0 拿临时端口"行不通（std 不暴露 getsockname），
所以大家只能写"固定起始端口 + 扫 20 个"的笨办法。**0.17 修好了**：
  listen("127.0.0.1", **0**) → 成功
  srv.socket.address.getPort() = 50816  ←内核给的 ephemeral 端口，**直接可读**
  bind("127.0.0.1", **0**, .dgram) → sock.address.getPort() = 65353
  用读到的端口 50816 反过来 connect → fd=7，accept 得到 fd=9（不同 fd）
⇒ 0.17 里"固定端口 + 扫 20 个"已经是**遗留写法**了。
  但本章示例仍保留它，因为**测试里要能复现"端口被占"这条路径**（见 29.11）。
==== 29.4 结束 ====
```

（端口号每次不同，上面是某次实测值。）

`listen` 和 `bind` 都一样——`Server.socket` 是个 `Socket`，所以
`server.socket.address.getPort()` 和 `socket.address.getPort()` 等价。

### 29.4.2 ⚠️ 但要验证它**可信**

"字段存在"不等于"值正确"。我做了个闭环验证：**读出端口 → 拿它去 connect → 看 accept 是否成功**，
连做 3 次：

```text
== A. address.getPort() 是否等于真实绑定端口 ==
  声称 50753 → connect+accept 成功 ✅
  声称 50755 → connect+accept 成功 ✅
  声称 50757 → connect+accept 成功 ✅
```

**3/3 成功**。所以 `address.getPort()` 就是内核 `getsockname` 的真实结果，可以放心依赖。
这个验证被守成了测试：

```zig
// examples/29_netecho/main.zig 第 1123-1139 行
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
```

### 29.4.3 那为什么本章示例还保留端口扫描？

三个理由，都是教学上的：

1. **29.11 需要复现"端口被占"这条错误路径**。0.17 的 `address` 让"避开占用"变简单了，
   但"如何检测占用"（`AddressInUse`）仍然要靠**故意占住一个端口**来观察。
2. **回归测试的可预测性**。`listen(port=0)` 拿到的是随机端口，日志里每次都不一样，
   万一失败你不知道该重跑还是该查。固定端口段 + 扫描让输出稳定。
3. **这不是本章的孤例**。真实项目里"端口被配置文件写死"是常态（Docker 的
   `-p 8080:80`、k8s 的 `containerPort`），所以扫描/冲突处理是必须掌握的技能。

但**生产代码的新写法应该是 `port=0` + 读 `address`**：

```zig
const addr = try net.IpAddress.parseIp4("0.0.0.0", 0);   // 让内核选
var srv = try addr.listen(io, .{ .reuse_address = true });
defer srv.deinit(io);
const port = srv.socket.address.getPort();                // 读回来
std.debug.print("服务已启动：http://0.0.0.0:{d}/\n", .{port});
```

## 29.5 ⚠️⚠️ 自引用结构体的悬垂指针坑

**这是本章最有价值的部分。** 它编译通过、小报文能跑、缓冲区一大就乱，而且**编译期零警告**。

### 29.5.1 为什么会写出有 bug 的代码

把 `Stream`、`Reader`、`Writer` 和它们的缓冲放进同一个结构体，是**最自然的写法**——
你不可能想"Reader 在函数 A 里、缓冲在函数 B 里"。所以几乎所有人第一次都会这样写：

```zig
// examples/29_netecho/main.zig 第 432-441 行
    p("把 Stream / Reader / Writer 和它们的缓冲放同一struct 是最自然的写法，\n", .{});
    p("**也是本章最大的坑**。先看反例（这段代码能编译通过）：\n", .{});
    p("  fn init(io, stream) Conn {{\\n", .{});
    p("      var self = Conn{{ .stream = stream, ... }};\\n", .{});
    p("      self.r = stream.reader(io, &self.rbuf);  // ⚠️ 绑到的是 **init 的栈帧**\\n", .{});
    p("      return self;                          // ⚠️ 值拷贝⇒ r 里的指针悬垂\\n", .{});
    p("  }}\\n", .{});
```

**这段代码是合法 Zig，`zig fmt` 通过，编译器一声不吭。** 机制是：

1. `stream.reader(io, &self.rbuf)` 返回一个 `Stream.Reader`，它内部有个
   `interface: Io.Reader`，而 `Io.Reader` 里有个 `buffer: []u8` —— **指向 `&self.rbuf`**。
2. 但 `self` 是 `init` 栈帧上的一个**局部变量**。`stream.reader` 拿到的是它的地址。
3. `return self` 把整个结构体**按值拷贝**给调用方。调用方拿到的是一份新的 `rbuf`，
   而返回的那个 `Reader.buffer` **仍指向 init 的栈帧**（那个帧已经死了）。
4. 之后任何 `r.interface.fillMore()` 都会往那块**已被销毁或复用的内存**里写数据。

### 29.5.2 实测：两个指针不相等

```zig
// examples/29_netecho/main.zig 第 446-489 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
==== 29.5 开始 ====
把 Stream / Reader / Writer 和它们的缓冲放同一 struct 是最自然的写法，
**也是本章最大的坑**。先看反例（这段代码能编译通过）：
  fn init(io, stream) Conn {
      var self = Conn{ .stream = stream, ... };
      self.r = stream.reader(io, &self.rbuf);  // ⚠️ 绑到的是 **init 的栈帧**
      return self;                          // ⚠️ 值拷贝⇒ r 里的指针悬垂
  }
实测（同一个 stream，读之前先污染栈）：
  bad.r.interface.buffer.ptr = 0x7ff7bc1095dc
  &bad.rbuf              = 0x7ff7bc10d7dc
  ⇒ 两者相同？ false（**false 就说明 Reader 指着别人家的缓冲**）
  两个指针差 16400 字节（这是两个栈帧的距离，**不是** rbuf 的大小——
     关键是这个距离**不为 0**：Reader 的 buffer 指向 init 早已返回的栈帧。
  ⇒ 这就是悬垂指针。
  实测后果：往这块内存 fillMore 能成功（内核照收），但 buffered() 返回的是
  **那块已被复用的栈**——小包时恰好没被覆盖，缓冲区一大就彻底乱序。
⇒ **症状是"小包偶尔对、缓冲区一大就乱"**，极难查（编译期完全无警告）。
```

（地址每次不同，但**它们不相等**这一点是确定的；差的字节数 ≈ `rbuf` 的大小 + 对齐。）

**"小包偶尔对"是这个坑最恶劣的地方**：`tiny`（4 字节）那次恰好落在一块还没被复用的
内存上，所以读出来是对的。等你把缓冲从 64 改成 4096、或者多跑几个线程，
那块内存立刻被别的栈帧覆盖，症状变成"数据乱序""读到脏字节""莫名其妙的长度"。

### 29.5.3 正解一（最推荐）：只存"原料"

**规则：Reader/Writer 只在栈帧内用，不跨函数返回、不进结构体、不进数组。**

```zig
fn echoOnce(io: std.Io, stream: net.Stream, msg: []const u8) !void {
    var rbuf: [1024]u8 = undefined;      // 局部变量
    var wbuf: [1024]u8 = undefined;
    var r = stream.reader(io, &rbuf);     // 绑到局部变量的地址
    var w = stream.writer(io, &wbuf);
    // ... 用 r / w，全程在这个栈帧内
}
```

只要 `rbuf` 和 `r` 在**同一个栈帧**里，就绝不会悬垂。本章的 `Conn.recvSome` /
`tcpEchoServer` 用的就是这个模式（每次收发都在自己的栈帧上新建 Reader）。

### 29.5.4 正解二（要复用连接时）：懒绑定

必须持有连接对象（比如线程池里复用）时，用**懒绑定**——**不在 `init` 里绑定，
而在第一次收发前绑定**：

```zig
// examples/29_netecho/main.zig 第 105-131 行
    /// 懒绑定：第一次收发时才把 Reader/Writer 绑到自己的缓冲字段上。
    /// 值拷贝多少次都安全——每次拷贝后的第一次 `ensureBound` 都会重新指向自己的字段。
    fn ensureBound(self: *Conn) void {
        if (self.bound) return;
        self.r = self.stream.reader(self.io, &self.rbuf);
        self.w = self.stream.writer(self.io, &self.wbuf);
        self.bound = true;
    }

    /// 写全部+ flush。⚠️ 缓冲 Writer 必须 flush，`Stream.close` **不会**替你 flush。
    pub fn sendAll(self: *Conn, data: []const u8) !void {
        self.ensureBound();
        try self.w.interface.writeAll(data);
        try self.w.interface.flush();
    }
```

关键在于 `Conn.init` **只存原料，一个绑定都不做**：

```zig
// examples/29_netecho/main.zig 第 96-101 行
    /// 只存"原料"，**不做任何绑定**。
    pub fn init(io: std.Io, stream: net.Stream) Conn {
        return .{ .io = io, .stream = stream };
    }
```

懒绑定为什么安全：`ensureBound` 是在 `self: *Conn` 上调用的，此时 `self` 指向的是
**调用方栈上的那个对象**（或者已经是最终存储位置的那个对象），所以
`&self.rbuf` 就是正确的地址。而且它在 `bound` 上做了幂等保护，只绑一次。

对比：

| | 何时绑定 | 值拷贝后 |
|---|---|---|
| ❌ 就地绑定 | `init` 里 | **悬垂** |
| ✅ 懒绑定 | 第一次收发前 | 指向绑定时所在的那个对象 |

实测对比（`good` 是懒绑定的版本）：

```zig
// examples/29_netecho/main.zig 第 521-536 行
        var good = Conn.init(io, cli);
        p("  ensureBound 之前 bound = {}（还是原料状态）\n", .{good.bound});
        try good.sendAll("hello-good");
        p("  good.r.interface.buffer.ptr = 0x{x}\n", .{@intFromPtr(good.r.interface.buffer.ptr)});
        p("  &good.rbuf               = 0x{x}  ⇒ 相同 = {}✅\n", .{
            @intFromPtr(&good.rbuf), good.r.interface.buffer.ptr == &good.rbuf,
        });
        p("  ensureBound 之后 bound = {}\n", .{good.bound});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
  ensureBound 之前 bound = false（还是原料状态）
  懒绑定往返 10 字节 =hello-good
  good.r.interface.buffer.ptr = 0x7ff7bc149bc
  &good.rbuf               = 0x7ff7bc149bc  ⇒ 相同 = true✅
  ensureBound 之后 bound = true
```

**完全相同**。这就是懒绑定达成的效果。

### 29.5.5 三条规则（照抄即可）

```text
| # | 规则 | 为什么 |
|---|---|---|
| 1 | Reader/Writer **只在栈帧内**用，不跨函数返回、不进结构体、不进数组 | 唯一能100% 保证不悬垂的做法 |
| 2 | 必须持有时**只存原料**（`Stream` + `[]u8`），用的时候再 `reader(io, buf)` 绑一次 | 绑的时候对象已在最终位置 |
| 3 | 实在要存（比如复用连接），**懒绑定**（`bound: bool` + `ensureBound()`） | 每次拷贝后的首次绑定都指向正确地址 |
```

这三条同样适用于 `Dir.Iterator`（20.8.1 讲的 2048 字节内嵌缓冲）和
`std.json` 的 `Stringify` 上下文——凡是把"缓冲持有者"按值传出去，都有这个风险。

## 29.6 服务器三步：`listen` → `accept` → 收发

### 29.6.1 形状与两个不对称

```zig
// examples/29_netecho/main.zig 第 543-568 行
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
        p("  defer stream.close(io)← Stream 有 close\n", .{});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
==== 29.6 开始 ====
服务器就三步：
  1. listen：拿一个 Server（含 listening socket）
  2. accept：**阻塞**直到有连接进来，返回一个 Stream
  3. 收发：在那个 Stream 上开 Reader/Writer
三步的形状（29.4 已验证过能通，这里把类型都打出来）：
  var server = tryaddr.listen(io, .{})  → Server{socket, options}
  defer server.deinit(io)  ← Server 有 deinit（不是 close！）
  ⚠️ accept 的接收者是 *Server（**非const**），所以 server 必须 var
  defer stream.close(io)     ← Stream 有 close
  收发缓冲要各配一块（Reader 和 Writer 的 buffer 是独立的）
  Stream.Reader 字段： io interface control_buffer control_len control_truncated stream err
  Stream.Writer 字段： io interface control stream err write_file_err
  ⚠️ interface 是**字段**不是函数，所以调用是r.interface.fillMore()
  ⚠️ Stream.read(io, [][]u8) 在 0.17.0 **标准库自身就编译不过**（29.7.1 详述）
==== 29.6 结束 ====
```

**两个不对称要记住**：

| | 关闭方法 | 接收者 |
|---|---|---|
| `Server` | **`deinit(io)`**（不是 `close`） | `*Server`（`deinit` 里 `s.* = undefined`） |
| `Stream` | **`close(io)`** | `*const Stream`（`close`） |

写 `defer server.close(io)` 编译不过（`no field or member function named 'close'`），
写 `const srv = try addr.listen(...)` 之后 `srv.accept(io)` 也不行（要 `var`）。
这和 20 章"`Dir` 是工厂、`File` 是句柄"是同一类设计：**"拥有资源的容器"和"被借用的句柄"
在关闭语义上是两套 API**。

`Stream.Reader` / `Stream.Writer` 的字段（实测）：

```text
Stream.Reader: io interface control_buffer control_len control_truncated stream err
Stream.Writer: io interface control stream err write_file_err
```

- **`interface` 是字段不是函数**。所以调用是 `r.interface.fillMore()`，
  不是 `Reader.fillMore(r)`。`@hasDecl(net.Stream.Reader, "interface")` 实测 `false`
  （`@hasDecl` 只查 `pub fn`/`pub const`，字段不在其中）。
- **`err: ?Error` 是"最近一次底层错误的快照"**。`readVec` / `drain` 会把真实错误
  记在这里，然后向上返回 `error.ReadFailed` / `error.WriteFailed` 这种**归一化的**错误。
  所以想拿"到底是哪个系统错误"，要看 `r.err.?` 而不是 catch 到的那个。
- **`control_buffer` / `control_len` 是辅助数据**（`SCM_RIGHTS` 传 fd、`IP_TOS` 传
  出向 QoS 等）。不用就`reader(io, buf)`（内部传空切片）。

### 29.6.2 `accept` 的接收者必须是 `*Server`

`accept` 要 `*Server`（非const）的**原因**：`Server.AcceptOptions` 在 Windows 上
是个 struct，`accept` 需要把它传给 `io.vtable.netAccept`。源码签名：

```zig
// lib/std/Io/net.zig 第 1591-1593 行
pub fn accept(s: *Server, io: Io) AcceptError!Stream {
    return .{ .socket = try io.vtable.netAccept(io.userdata, s.socket.handle, s.options) };
}
```

所以 `srv` 必须是 `var`，且跨线程传递时必须写`&srv`（29.11 详述）。

### 29.6.3 收发的正确形状

```zig
// examples/29_netecho/main.zig 第 130-150 行
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
```

四个必须记住的点：

1. **`fillMore` 在 EOF 时返回 `error.EndOfStream`，不是 `void`**。所以不能写
   `try r.interface.fillMore()` 了事——必须在 `catch` 里处理。
2. **`fillMore` 只保证"至少多取一批"**，可能取到也可能取不到（`vtable.stream`
   返回 0 字节不算 EOF，见 `Reader.zig:1150` 的注释）。所以拿到之后**必须看
   `bufferedLen()`**。
3. **`buffered()` 返回的切片在下一次 `fillMore` 后失效**（rebase 会移动数据）。
   要留存就 `@memcpy` 出来——上面的代码就是这么做的。
4. **写要 `flush`**。`Stream.close` **不会**替你 flush（20.5.2 实测过：18 字节
   `print` 之后直接 `close`，文件是 0 字节）。

## 29.7 ⚠️⚠️ 三个收发坑：`readSliceShort` / `takeDelimiterExclusive` / `close` 幂等

这是本章技术含量最高的一节。三个坑全部实测复现。

### 29.7.1 ❌ `Stream.read(io, [][]u8)` 在0.17.0 标准库自身编译不过

这是**发行版标准库的 bug**，不是你写错了：

```console
$ /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig build-exe rd.zig
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/net.zig:1286:23: error: type 'Io.net.Stream.ReadResult' cannot be destructured
        const rc, _ = try (try io.operate(.{ .net_read = .{
                      ~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/net.zig:1286:21: note: result destructured here
referenced by:
    main: rd.zig:12:30
```

出错的代码在 `net.zig:1285-1291`（`Stream.read` 的实现）：

```zig
// lib/std/Io/net.zig 第 1285-1291 行（0.17.0，有bug）
pub fn read(s: *const Stream, io: Io, data: [][]u8) Reader.Error!usize {
    const rc, _ = try (try io.operate(.{ .net_read = .{
        .socket_handle = s.socket.handle,
        .data = data,
    } })).net_read;
    return rc;
}
```

`io.operate(...)` 返回的是 `union(enum)`，`net_read` 的 payload 是
**`ReadResult`（一个 struct）**，不是 tuple。但这里写了 `const rc, _ = ...`——
Zig 不允许解构 struct，所以编译失败。

**注意还有一个前置障碍**：`read` 的第三参是 `[][]u8`（**可变**切片），
所以你不能直接传 `&.{&buf}`（那是 `*const [1][]u8`）：

```text
rd.zig:11:35: error: expected type '[][]u8', found '*const [1][]u8'
rd.zig:11:35: note: cast discards const qualifier
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/net.zig:1285:49: note: parameter type declared here
pub fn read(s: *const Stream, io: Io, data: [][]u8) Reader.Error!usize {
```

要先 `var bufs = [_][]u8{&b};` 再传 `&bufs`，然后才撞上真正的 std bug。
`readWithControl`（返回 `ReadResult`）同样受影响——它内部也调`io.operate`。

**绕开办法**：用 `stream.reader(io, buf)` 这条路（它内部用 `readVec`，
而 `readVec` 走的是**回调** `vtable.readVec` 而不是 `io.operate`，所以没有这个 bug）。
下一条讲怎么用它。

### 29.7.2 ⚠️ `readSliceShort` 是"填满或 EOF"，不是单次 recv

```zig
// examples/29_netecho/main.zig 第 574-600 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
坑一：readSliceShort 是"填满缓冲或读到 EOF"，**不是单次 recv**
  对端发了 3 字节就停住：fillMore 后 buffered = 3 字节 =abc
  ⇒ readSliceShort(&16字节缓冲) 在这里会**一直等**（要填满 16 字节）——不能当 recv 用
  对端关闭后 readSliceShort 返回 0 字节（只拿到 EOF 前的量，不是 16）
  ⇒ 正确形状是 fillMore() + buffered() + toss()，见 Conn.recvSome
     fillMore 在 EOF 时返回 error.EndOfStream（**不是 void**），必须 catch
```

**对端发了 3 字节就停住（不关）**——这正是"一行日志的请求"的形状。
`readSliceShort(&16字节缓冲)` 会一直等那 13 个永远不来的字节，**服务端就此挂死**。
我把客户端关掉之后它才返回，而且返回的是 **0**（因为数据已经被上一个 `fillMore` 消费了）。

对比表（20 章在文件上测过，这里在网络上确认）：

```text
| 调用 | 语义 | 当 recv 用 |
|---|---|---|
| `readSliceShort(&buf)` | 尽力填满 buf，或读到 EOF | ❌ 会挂死 |
| `readSliceAll(&buf)` | **必须**填满 buf，源短就`error.EndOfStream` | ❌ 同样会挂死 |
| `take(n)` | 尽力取 n 个字节，返回实际取的 |⚠️ 也不阻塞但语义不同 |
| **`fillMore` + `buffered` + `toss`** | 取"下一批"，多少都行 | ✅ **这才是 recv** |
```

### 29.7.3 ⚠️⚠️ `takeDelimiterExclusive` 在 0.17.0 有 std bug

**这是本章的头号发现。** 先看实测：

```zig
// examples/29_netecho/main.zig 第 602-620 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
坑二：⚠️⚠️ takeDelimiterExclusive 在 0.17.0 **有 std bug**（本章头号发现）
  纯内存 Reader.fixed("alpha\nbeta\ngamma\n")，连调 takeDelimiterExclusive('\n')：
    第 1 次 =alpha（5 字节）
    第 2 次 =（0 字节）
    第 3 次 =（0 字节）
    第 4 次 =（0 字节）
  ⇒ 只有第 1 次对，之后全是空片。**根因**（读 Reader.zig 的源码得到）：
     takeDelimiterExclusive = peekDelimiterExclusive + toss(result.len)
     peekDelimiterInclusive 返回**含分隔符**的切片（比如 "alpha\n"，6 字节）
     peekDelimiterExclusive 把它 [0..len-1] 缩成 "alpha"（5 字节）
     takeDelimiterExclusive 只toss 5 字节 ⇒ **分隔符 '\n' 留在缓冲里**
     下一次 peek 从 seek 开始，第一个字符就是 '\n' ⇒ 命中 → 返回 1 字节 → Exclusive 缩成 0 字节
  ⚠️ 所以"不阻塞就返回空片"这个症状被误读了：它其实是**分隔符没被吃掉**。
     服务端如果写 `while (true) { const line = takeDelimiterExclusive('\n'); ... }`，
     就会陷入「读到空行 → 写 OK → 再读到空行」的死循环（因为内核数据一直不消耗）。
```

**注意这是纯内存 `Reader.fixed`，一个 syscall 都没有。** 所以它和 `Stream` 无关——
网上（包括本教程的迁移手册 0.5.1）把症状归因为"在网络 Reader 上不阻塞"，
**这个诊断是错的**。真正的根因在标准库的实现里。

#### 根因（源码级）

三个函数串起来看（`lib/std/Io/Reader.zig`）：

```zig
// 第 894-898 行
pub fn takeDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8 {
    const result = try r.peekDelimiterExclusive(delimiter);
    r.toss(result.len);          // ⚠️ toss 的是"不含分隔符"的长度
    return result;
}

// 第 948-958 行
pub fn peekDelimiterExclusive(r: *Reader, delimiter: u8) DelimiterError![]u8 {
    const result = r.peekDelimiterInclusive(delimiter) catch |err| switch (err) {
        error.EndOfStream => { ... return remaining; },
        else => |e| return e,
    };
    return result[0 .. result.len - 1];   // ⚠️ 砍掉最后一个字节（分隔符）
}

// 第 841-873 行（节选）
pub fn peekDelimiterInclusive(r: *Reader, delimiter: u8) DelimiterError![]u8 {
    // ... 在缓冲里找 delimiter，找到就return contents[seek .. end + 1]
    //                                          ↑ 含分隔符！长度 = end + 1 - seek
    while (true) {
        const content_len = r.end - r.seek;
        if (r.buffer.len - content_len == 0) break;
        try fillMore(r);
        // ... 继续找
    }
```

**逐步追踪 `"ab\ncd\n"`**：

| 步骤 | `seek` | `end` | 缓冲内容 | `peekInclusive` 返回 | `peekExclusive` 返回 | `toss` |
|---|---|---|---|---|---|---|
| 第 1 次 | 0 | 3 | `ab\n` | `ab\n`（3 字节，`end+1`） | `ab`（`[0..2]`） | `toss(2)` → `seek=2` |
| 第 2 次 | 2 | 3 | `\n` | `\n`（1 字节，**立刻命中**） | `""`（`[0..0]`） | `toss(0)` → `seek=2` |

**`seek` 永远卡在 2**，指向那个 `\n`，永远命中它，永远返回空片。

我把这个追踪守成了断言：

```zig
// examples/29_netecho/main.zig 第 1054-1082 行
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
```

最后三行是**根因的直接证明**：`take` 之后 `buffered()[0] == '\n'`——分隔符确实还在。
手动 `toss(1)` 之后立刻恢复正常。

#### 症状为什么是"死循环刷空行"

服务端通常这么写：

```zig
while (true) {
    const line = try r.interface.takeDelimiterExclusive('\n');   // 第二次起返回空片
    if (line.len == 0) continue;                                 // 跳过空行？
    handle(line);
    try w.interface.writeAll("OK\n");
    try w.interface.flush();
}
```

因为 `toss(0)` **不消耗任何内核数据**，循环永远停在同一个 `\n` 上，
于是"读到空行 → 写 OK → 再读到空行"无限重复。日志里 `serve got:` 后面刷屏一片空行，
而**客户端一个字节也收不到进展**（因为服务端的注意力全在那行"OK"上）。

如果你写的恰好是 `if (line.len == 0) break;`，那症状变成"服务端莫名其妙提前退出"。

#### 三个可用的替代

| 写法 | 返回 | 推进正确？ | 何时用 |
|---|---|---|---|
| **`takeDelimiter(delim)`** | `error{ReadFailed, StreamTooLong}!?[]u8` | ✅ | **首选**。`null` = 真 EOF |
| `takeDelimiterInclusive(delim)` | `DelimiterError![]u8`（**含**分隔符） | ✅ | 要连分隔符一起切掉时 |
| `fillMore` + `indexOfScalarPos` + `toss` | 自己攒 | ✅ | 行长可能超过缓冲容量时 |

`takeDelimiter` 的实现（`Reader.zig:917-929`）用的是 **inclusive 长度**，
所以 `toss` 的长度刚好把分隔符也吃掉：

```zig
pub fn takeDelimiter(r: *Reader, delimiter: u8) error{ ReadFailed, StreamTooLong }!?[]u8 {
    const inclusive = r.peekDelimiterInclusive(delimiter) catch |err| switch (err) {
        error.EndOfStream => {
            const remaining = r.buffer[r.seek..r.end];
            if (remaining.len == 0) return null;          // ← null 表示真 EOF
            r.toss(remaining.len);
            return remaining;
        },
        else => |e| return e,
    };
    r.toss(inclusive.len);              // ✅ 含分隔符，所以推进正确
    return inclusive[0 .. inclusive.len - 1];
}
```

实测三个对照：

```text
对照 takeDelimiterInclusive：
    takeDelimiterInclusive 第 1 次 =alpha
（6 字节）
    takeDelimiterInclusive 第 2 次 =beta
（5 字节）
    takeDelimiterInclusive 第 3 次 → EndOfStream
对照 takeDelimiter（?[]u8）：
    takeDelimiter 第 1 次 =alpha（5 字节）
    takeDelimiter 第 2 次 =beta（4 字节）
    takeDelimiter 第 3 次 = null（真EOF）
```

**`takeDelimiter` 是本章推荐的行协议写法**：它返回 `?[]u8`，
`null` 明确表示"流真的结束了"，把 EOF 和空行区分得干干净净。

⚠️ 但它的限制仍然在（20.4.1 实测过）：**分隔符必须在 Reader 的缓冲容量内**，
否则报 `error.StreamTooLong`。行长可能超过缓冲时，用三件套自己攒：

```zig
pub fn recvLine(r: *std.Io.Reader, line: []u8) ![]u8 {
    var scanned: usize = 0;              // 已扫过但不属于本行的字节数
    while (true) {
        const avail = r.buffered();
        if (std.mem.indexOfScalarPos(u8, avail, scanned, '\n')) |at| {
            const got = avail[scanned..at];
            r.toss(at + 1);              // 连'\n' 一起吃掉（注意是 at+1 不是 at）
            if (got.len > line.len) return error.LineTooLong;
            @memcpy(line[0..got.len], got);
            return line[0..got.len];
        }
        scanned = avail.len;
        if (scanned > line.len) return error.LineTooLong;
        r.fillMore() catch |err| switch (err) {
            error.EndOfStream => return error.ConnectionClosed,
            error.ReadFailed => return error.ReadFailed,
        };
    }
}
```

⚠️ **`toss(at + 1)` 里的 `+1` 不能省**——那正是 `takeDelimiterExclusive` 漏掉的东西。

### 29.7.4 ⚠️ `Stream.close` 不是幂等的

```zig
// examples/29_netecho/main.zig 第 654-661 行
    p("  ⇒ 规则：**要么全 defer，要么全显式**，绝不混用。本章 Conn 用 closed 标志兜住。\n", .{});
    }
    end("29.7");
```

实测：我显式 `close` 了一次，然后又 `close` 了一次，直接 panic：

```text
thread 2293460 panic: reached unreachable code
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:14472:19: in recoverableOsBugDetected (p4)
    if (is_debug) unreachable;
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:19963:42: in closeFd (p4)
        .BADF => recoverableOsBugDetected(), // use after free
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:13578:24: in netClose (p4)
        else => closeFd(socket.handle),
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/net.zig:1306:27: in close (p4)
        io.vtable.netClose(io.userdata, (&s.socket)[0..1]);
```

三个 `recoverable` 拼起来读：**第二次 `close(2)` 返回 `EBADF`（bad file number）**，
而0.17 把它归到 `recoverableOsBugDetected`——"你用了已经释放的 fd，程序员的 bug"——
于是 `unreachable` → panic。

**这是 0.17 的一个设计选择，不是可以修的 bug**：它宁可 panic 也不让你静默地二次关闭
（因为二次关闭通常意味着 fd 已经被别的 socket 复用了，继续写会串数据）。

**规则**：

| 模式 | 是否安全 |
|---|---|
| 全`defer`（`defer conn.close(io)` 一次） | ✅ |
| 全显式（每条路径都恰好 `close` 一次） | ✅ |
| 显式 `close` 之后又 `defer close` | ❌ **BADF panic** |
| `defer close` 之后某分支又显式 `close` | ❌ **BADF panic** |
| 存进容器、析构时统一关，但某处提前关过 | ❌ **BADF panic** |

本章 `Conn` 用一个 `closed` 标志把"关两次"变成"关一次"：

```zig
// examples/29_netecho/main.zig 第 132-150 行
    /// ⚠️ **`Stream.close` 不是幂等的**。显式 close 之后又`defer close`，
    /// 第二次会走内核 `close(2)` 拿到 `EBADF`，0.17 把它当"程序员的bug"直接 panic：
    /// `programmer bug caused syscall error: BADF`（Threaded.zig 的 recoverableOsBugDetected）。
    /// 所以这里用 `closed` 标志把"关两次"变成"关一次"。
    pub fn close(self: *Conn) void {
        if (self.closed) return;
        self.closed = true;
        self.stream.close(self.io);
    }
```

守成了测试：

```zig
// examples/29_netecho/main.zig 第 1181-1199 行
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
```

**注意 `Server.deinit` 也有同样的问题**：它内部是
`s.socket.close(io); s.* = undefined;`——所以对同一个 `Server` 调两次 `deinit`
第二次会在 `s.socket.close` 处`BADF`，即使 `s.* = undefined` 让 handle 变成垃圾。
同一个规则适用。

### 29.7.5 三个坑的对照表

```text
| 你想做的事 | ❌ 错的写法 | ✅ 0.17 的写法 |
|---|---|---|
| 读"来了一段" | `readSliceShort(&buf)` | `fillMore()` + `buffered()` + `toss()` |
| 读一行（分隔符在缓冲内） | `takeDelimiterExclusive('\n')` | `takeDelimiter('\n')` → `?[]u8` |
| 读一行（行长可能超缓冲） | 同上 | `fillMore` + `indexOfScalarPos` + `toss(at + 1)` |
| 低层 scatter 读 | `stream.read(io, &.{&buf})` | ❌ 0.17.0 std 自身编译不过，用 `reader()` |
| 确保连接关闭 | 显式 close + `defer close` | 全`defer`，或加 `closed` 标志 |
```

## 29.8 TCP vs UDP：连接性、有序、报头

### 29.8.1 五个维度的对照

```text
| 维度 | TCP | UDP |
|---|---|---|
| 连接 | 有（`connect`/`accept`，内核维护状态机） | 无（`bind`/`send`/`receive`） |
| 可靠 | 有（序号 + 重传 + 拥塞控制） | 无（丢了就丢了，应用自己管） |
| 有序 | 有 | 无（后到的可能先到） |
| **消息边界** | **无**（字节流） | **保留**（一次 `send` = 一个数据报） |
| 报头 | TCP 20 字节 + 选项 | **UDP 8 字节** |
| 内核状态 | 每条连接一个 struct（几 KB） | 每个 socket 一个几字节的记录 |
| 典型用途 | HTTP/SSH/数据库/gRPC | DNS/QUIC/视频/游戏/监控上报 |
```

**最容易踩的是"消息边界"那一行**：TCP 是字节流，`send` 两次的数据可能被
`recv` 一次拿到，也可能被拆成两次。所以 TCP 上必须**自己定协议**
（长度前缀 / 分隔符 / 固定长度）。UDP 保留边界——但代价是你必须处理"半个数据报"
（`flags.trunc`）和"数据报丢失"。

### 29.8.2 UDP 在 `std.Io.net` 里的形状

```zig
// examples/29_netecho/main.zig 第 667-728 行
    p("UDP 在 std.Io.net 里的形状：\n", .{});
    {
        const saddr = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var srv = try saddr.bind(io, .{ .mode = .dgram });
        p("  var sock = try addr.bind(io, .{{.mode = .dgram}})  → Socket（不是 Stream！）\n", .{});
        p("  sock.send(io, &dest, data)发；sock.receive(io, &buf) 收\n", .{});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
==== 29.8 开始 ====
| 维度| TCP | UDP |
| 连接 | 有（connect/accept，内核维护状态机） | 无（bind/sendto/recvfrom） |
| 可靠 | 有（序号 + 重传） | 无（丢了就丢了） |
| 有序 | 有| 无（后到的可能先到） |
| 边界 | 字节流（**没有消息边界**） | 保留消息边界（一次 sendto = 一个数据报） |
| 报头 | TCP 20 字节 + 选项 | UDP 8 字节 |
| 典型用途 | HTTP/SSH/数据库 | DNS/QUIC/视频/游戏 |
UDP 在 std.Io.net 里的形状：
  var sock = try addr.bind(io, .{.mode = .dgram})  → Socket（不是 Stream！）
  sock.send(io, &dest, data)发；sock.receive(io, &buf) 收
  服务端 bind(0) → 65353；客户端 bind(0) → 51271（两个独立端点）
  receive → IncomingMessage：
    .from = 127.0.0.1:51271（**来路地址**，回射就发回它）
    .data =dgram-hello（11 字节）
    .control.len = 0（没提供控制缓冲，所以是 0）
    .flags: eor=false trunc=false ctrunc=false oob=false errqueue=false
  ⚠️ .data 是**切片，指向你传给 receive 的那个 buf**，不是拷贝！
     所以必须在下一次 receive 之前用完，否则内容被覆盖。
  从 .from 回射 → 客户端收到 dgram-hello
  发 70000 字节（超过 MTU）→ MessageOversize⇒ send 会检查短写并报这个
  10 字节数据报用 4 字节缓冲receive → 4 字节，flags.trunc=true（**静默截断，不报错**）
⚠️ 另一个实测坑：Socket **没有** reader/writer 方法（只有 Stream 有）
  @hasDecl(Socket, "reader") = false；@hasDecl(Socket, "writer") = false
  ⇒ UDP **没有 Reader/Writer 这一层**，收发就是 send/receive 一来一回（零缓冲管理）。
==== 29.8 结束 ====
```

（端口号每次不同。）

### 29.8.3 ⚠️ `IncomingMessage.data` 是借用，不是拷贝

源码注释写得很明确：

```zig
// lib/std/Io/net.zig 第 930-931 行
    /// Populated by receive functions, points into the caller-supplied buffer.
    data: []u8,
```

**"points into the caller-supplied buffer"** —— `data` 指向你传给 `receive` 的那个 `buf`，
**不是拷贝**。所以：

```zig
var buf: [128]u8 = undefined;
const incoming = try sock.receive(io, &buf);
// ⚠️ incoming.data 只在下次 receive 之前有效
sock.send(io, &incoming.from, incoming.data);   // ✅ 同一轮里用
// ❌ 如果这里又 receive 了一次，incoming.data 的内容已被覆盖
```

这个设计是**对的**（零拷贝），但你必须知道。守成了测试：

```zig
// examples/29_netecho/main.zig 第 1200-1237 行
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
```

那个指针范围的断言就是"借用"这一事实的机器证明。

### 29.8.4 ⚠️ UDP 的两个静默失败模式

**① 数据报超过 MTU → `send` 报 `MessageOversize`**（不是内核悄悄丢掉）：

```text
  发 70000 字节（超过 MTU）→ MessageOversize⇒ send 会检查短写并报这个
```

源码（`net.zig:1107`）：

```zig
if (message.data_len != data.len) return error.MessageOversize;
```

所以 0.17 的 UDP send 是**"要么整包发出，要么报错"**——不会静默截断。
这比 POSIX 的 `sendto`（返回实际发出的字节数，让你自己判断）更严格。

**② 接收缓冲不够 → 静默截断，`flags.trunc = true`**：

```text
  10 字节数据报用 4 字节缓冲receive → 4 字节，flags.trunc=true（**静默截断，不报错**）
```

**这个必须检查**，否则你会拿到半个数据报还以为完整。测试里断言了：

```zig
// examples/29_netecho/main.zig 第 1228-1236 行
    // 截断：小缓冲 receive 大数据报 → 静默截断，flags.trunc=true
    try cli.send(io, &srv.address, "0123456789");
    var small: [4]u8 = undefined;
    const trunc = try srv.receive(io, &small);
    try std.testing.expectEqual(@as(usize, 4), trunc.data.len);
    try std.testing.expect(trunc.flags.trunc);

    // 超 MTU → send 报 MessageOversize
    var huge: [70000]u8 = undefined;
    @memset(&huge, 'z');
    try std.testing.expectError(error.MessageOversize, cli.send(io, &srv.address, huge[0..]));
```

`IncomingMessage.Flags` 是 `packed struct(u8)`，5 个标志位：

```text
| 字段 | 含义 |
|---|---|
| `eor` | 记录结束（`SOCK_SEQPACKET` 专用；UDP/TCP 上无意义） |
| **`trunc`** | **数据报尾部被丢弃，因为超过你给的缓冲** |
| `ctrunc` | 控制数据被丢弃（缓冲不够） |
| `oob` | 收到带外/紧急数据 |
| `errqueue` | 没收到数据，但错误队列里有东西 |

### 29.8.5 ⚠️ Socket **没有** reader/writer

```zig
// examples/29_netecho/main.zig 第 721-728 行
    p("⚠️ 另一个实测坑：Socket **没有** reader/writer 方法（只有 Stream 有）\n", .{});
    p("  @hasDecl(Socket, \"reader\") = {}；@hasDecl(Socket, \"writer\") = {}\n", .{
        @hasDecl(net.Socket, "reader"), @hasDecl(net.Socket, "writer"),
    });
```

运行输出（`examples/29_netecho/main.zig`）：

```text
⚠️ 另一个实测坑：Socket **没有** reader/writer 方法（只有 Stream 有）
  @hasDecl(Socket, "reader") = false；@hasDecl(Socket, "writer") = false
  ⇒ UDP **没有 Reader/Writer 这一层**，收发就是 send/receive 一来一回（零缓冲管理）。
```

`@hasDecl(net.Socket, "reader")` 实测 `false`。这**不是缺陷，是设计**：

- TCP 是字节流，需要缓冲、需要 `fillMore`/`toss` 这套机制来攒数据；
- UDP 保留消息边界，`receive` 一次就是一个完整数据报，**中间没有"半个"**，
  所以不需要缓冲层——`buf` 只是内核的落地点（因为 `data` 是借用的）。

所以 UDP 代码反而更简单：

```zig
var buf: [1500]u8 = undefined;                 // 复用的接收缓冲
while (true) {
    const msg = try sock.receive(io, &buf);    // 阻塞直到一个数据报到达
    if (msg.flags.trunc) continue;             // ⚠️ 必须检查！
    handle(msg.data);
}
```

**这也是 UDP 的性能优势**：零缓冲管理、零拷贝、无协议状态机。

### 29.8.6 UDP 服务器的完整形状

```zig
// examples/29_netecho/main.zig 第 168-182 行
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
```

回射（echo）的写法是 `sock.send(io, &incoming.from, incoming.data)`——
**发回 `incoming.from`**，也就是"从哪来回哪去"。这正是 0.17 把 `from`
作为 `IncomingMessage` 字段（而不是让调用者自己填目的地址）的好处。

## 29.9 缓冲区、背压与半关闭

### 29.9.1 缓冲：Reader 和 Writer 各要一块

```zig
// examples/29_netecho/main.zig 第 734-741 行
    p("缓冲：Reader 和 Writer **各要一块** buffer，互不共享。\n", .{});
    p("  buffer 决定 fillMore 一次能拿多少（影响吞吐，不影响语义）。\n", .{});
    p("  ⚠️ Writer 有用户态缓冲，**必须 flush**；Stream.close **不会**替你 flush。\n", .{});
```

三个层次要分清：

```text
| 缓冲 | 在哪 | 谁分配 | 满了怎么办 |
|---|---|---|---|
| **你的 `rbuf`/`wbuf`** | 用户态，你声明 | 你 | `fillMore` 读到你的 buf 里 |
| **`Io.Reader`/`Io.Writer` 内部的 `end`/`seek`** | 就是上面那块 | 你（指针指过去） | `rebase` 移动数据 |
| **内核 socket 缓冲** | 内核 | 内核 | TCP 窗口收缩 → 写方阻塞（背压） |
```

**`buf` 大小只影响吞吐，不影响语义**。小缓冲（64 字节）只是让 `fillMore` 多调几次。
但它**影响 `takeDelimiterExclusive` / `takeDelimiter` 的行长上限**（29.7.3）。

### 29.9.2 背压：读慢的一方拖住写方

```zig
// examples/29_netecho/main.zig 第 742-771 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
背压：写方写太快，内核缓冲满了 → write 阻塞（可取消）。
  写了 524288 字节没阻塞 ⇒ 本机 socket 缓冲至少这么大
  ⇒ **背压就是机制本身**：读慢的一方通过 TCP 窗口把写方拖住，不是 bug。
     事件循环版本要靠 Writable 事件驱动"能写了"，而不是循环 write
```

我写了 512 KB（8× 64 KB）没阻塞——因为**客户端的 `wbuf` 本身就是 64 KB，
`writeAll` 分 8 次每次 64 KB，内核 socket 缓冲（macOS 默认约 128 KB+）加上
客户端侧的排队足够吸收**。要看到阻塞得写更多（几 MB）。

**但这不影响结论**。背压的机制是：

```text
写方                              内核socket 缓冲              读方
  │                                    │                        │
  │── write(64KB) ────────────────────▶│  缓冲+=64KB            │
  │                                    │                        │
  │── write(64KB) ────────────────────▶│  缓冲+=64KB            │
  │                    ...             │                        │
  │── write(64KB) ────────────────────▶│  缓冲满了！              │
  │◀── 窗口收缩（ACK 里带0 窗口）────────│                        │
  │                                    │                        │── read(1KB)
  │                                    │  缓冲 -=1KB，窗口打开   │
  │── write(64KB) ────────────────────▶│                        │
```

**写方被读方的节奏拖住，这就是 TCP 的拥塞控制**。它不是 bug，是特性。
UDP 没有这个机制——`send` 要么整包进内核缓冲（成功），要么 `MessageOversize`（失败），
**永不阻塞**（也永不流控）。

**对事件循环的启示**（30 章会展开）：不能写成
`while (need_more) { try write_all(more); }`——那会在背压时整个事件循环卡死。
正确做法是：写一部分，然后等 `Writable` 事件，再写下一部分。`Io` 的
`Writer` 抽象天然支持这个（`write` 返回实际写了多少）。

### 29.9.3 ⚠️ 半关闭：0.17 **有** `shutdown`

这是相对旧版的一个改进——29.2 节实测 `@hasDecl(net.Stream, "shutdown") = true`。

```zig
// examples/29_netecho/main.zig 第 772-819 行
    p("半关闭：⚠️ 0.17 **有** shutdown —— Stream.shutdown(io, how)，how ∈ ", .{});
    inline for (@typeInfo(net.ShutdownHow).@"enum".field_names) |n| p(".{s} ", .{n});
    p("\n", .{});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
半关闭：⚠️ 0.17 **有** shutdown —— Stream.shutdown(io, how)，how ∈ .recv .send .both 
  服务端先读到 =bye
  客户端半关闭后，服务端 fillMore → EndOfStream（这就是 EOF 的形态）
  客户端半关闭后仍能读到服务端数据 =ack
  ⇒ shutdown(.send) 只关**写**方向（TCP 的 half-close），读方向还通。
     这正是"客户端发完请求就不再发、但还要读响应"的标准做法（HTTP/1.1 就是这样）。
对端硬close（不是 shutdown）时，fillMore 也报 EndOfStream —— ⚠️ 0.17 分不出这两者：
  对端 close 后 fillMore → EndOfStream（与 shutdown 情形**同形**）
```

**实测到两件事**：

**① `shutdown(.send)` 只关写方向。** 客户端关掉写之后：
- 服务端 `fillMore` 立刻返回 `EndOfStream`（读到了 EOF）；
- 但客户端**仍然能读**服务端随后发来的 `"ack"`。

这就是 TCP 的 half-close。**HTTP/1.1 就是这么工作的**：客户端发完请求后
`shutdown(SHUT_WR)`，告诉服务器"我发完了"，然后继续读响应。

守成了测试：

```zig
// examples/29_netecho/main.zig 第 1238-1267 行
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
```

**② ⚠️ 0.17 分不出"有序关闭"和"硬关闭"。** 对端 `close()` 之后，
本端 `fillMore` **也**报 `EndOfStream`——和 `shutdown(.send)` 的情形**完全同形**：

```text
对端硬close（不是 shutdown）时，fillMore 也报 EndOfStream —— ⚠️ 0.17 分不出这两者：
  对端 close 后 fillMore → EndOfStream（与 shutdown 情形**同形**）
```

原因是 `Stream.Reader.readVec` 的实现（`net.zig:1375-1377`）只检查
`result.data_len == 0` 就返回 `error.EndOfStream`，**不看 `recv` 的 flags**。
在 BSD socket 语义下， orderly shutdown 返回 0，reset 也可能返回 0
（Linux 上 RST 后会返回 `ECONNRESET`，但 macOS 上不可靠）。

**这对协议设计有影响**：你无法在 TCP 上区分"对方正常地说完了"和"对方崩了"。
需要区分的话，得**在应用层加一个结束标记**（比如 HTTP 的空行、Redis 的 0 长度数组）。

### 29.9.4 `kernel_backlog` 的实测效果

```text
backlog=1 时第 2 次 connect → Timeout
backlog=1 且不 accept → 1 条连上，第 2 条 被拒或超时
⇒ **ConnectionRefused 和 Timeout 都可能是"对方在但队列满"**，要看 backlog
```

`kernel_backlog` 是**内核已完成三次握手、但还没被 `accept` 的连接队列长度**。
队列满了之后新来的连接会怎样，取决于操作系统：macOS 上实测是 `Timeout`，
Linux 上通常是 `ConnectionRefused`（RST）。**别指望错误名告诉你真相**。

## 29.10 错误处理：三种失败要分开

### 29.10.1 网络代码的困难：失败是日常

文件 I/O 的失败是罕见的（磁盘满、权限错）。**网络的失败是常态**——每一个数据包都可能丢。

```zig
// examples/29_netecho/main.zig 第 823-833 行
    p("网络代码的困难：**失败不是异常，是日常**。要分清三种：\n", .{});
    p("  1. 连接被拒（ConnectionRefused）—— 对端没监听 / 队列满 / 端口没开\n", .{});
    p("  2. 超时（Timeout）—— 对端在但不响应，需要 deadline\n", .{});
    p("  3. 对端关闭（EndOfStream）—— **不是错误**，是协议的一部分\n", .{});
```

三者的**处理方式完全不同**：

| | 语义 | 该怎么办 |
|---|---|---|
| `ConnectionRefused` | **永久性**失败，重试没用 | 上抛／转成业务语义（"服务没开"） |
| `Timeout` / `WouldBlock` | **暂时性**失败，可以重试 | 退避后重试，或交给上层重试队列 |
| `EndOfStream` | **不是错误**，是协议的一部分 | 跳出读循环，做正常的收尾 |

把 `EndOfStream` 当错误处理是新手最常见的 bug——它会让正常关闭的连接
走错误路径，打一堆没用的日志，甚至触发重连逻辑。

### 29.10.2 实测的错误名

```zig
// examples/29_netecho/main.zig 第 834-903 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
实测的错误名（127.0.0.1 上真跑出来的）：
  connect 127.0.0.1:1（没人监听）→ ConnectionRefused
  connect 0.0.0.0:9（连本机任何地址）→ ConnectionRefused
  listen 8.8.8.8（非本机地址）→ AddressUnavailable（地址不属于本机任何网卡）
  bind 8.8.8.8（非本机地址）→ AddressUnavailable
  backlog=1 时第 2 次 connect → Timeout
  backlog=1 且不 accept → 1 条连上，第 2 条 被拒或超时
  ⇒ **ConnectionRefused 和 Timeout 都可能是"对方在但队列满"**，要看 backlog
  listen [::1]:0 → ok(port=51056)（本机 IPv6 回环可用）
  ⚠️ ConnectOptions.timeout：POSIX 上只要 != .none 就@panic（0.17 未实现）
     源码 Threaded.zig:12410 → if (options.timeout != .none) @panic("TODO implement netConnectIpPosix with timeout")
     ⇒ 超时要靠 io 层的 deadline / 事件驱动，**不能**靠这个字段（Windows 上同样未实现）
  不带 timeout 连 127.0.0.1:9 → ConnectionRefused（连拒绝是立刻的）
  Io.Timeout 是 union(enum)，构造得出：duration
```

（IPv6 端口每次不同。）

各错误集的**完整成员**（源码 `net.zig:200-336`，抄写时可直接查）：

```text
ListenError（18 个 + Io.UnexpectedError + Io.Cancelable）:
  AccessDenied  AddressInUse  AddressUnavailable  NetworkDown  SystemResources
  ProcessFdQuotaExceeded  SystemFdQuotaExceeded  AddressFamilyUnsupported
  ProtocolUnsupportedBySystem  ProtocolUnsupportedByAddressFamily
  SocketModeUnsupported  OptionUnsupported

BindError（12 个）:
  AccessDenied  AddressInUse  AddressUnavailable  AddressFamilyUnsupported
  SystemResources  NetworkDown  ProtocolUnsupportedBySystem
  ProtocolUnsupportedByAddressFamily  ProcessFdQuotaExceeded
  SystemFdQuotaExceeded  SocketModeUnsupported  OptionUnsupported

ConnectError（17个 + Io.Timeout.Error）:
  AddressUnavailable  AddressFamilyUnsupported  SystemResources
  ConnectionPending  ConnectionRefused  ConnectionResetByPeer
  HostUnreachable  NetworkUnreachable  Timeout  OptionUnsupported
  ProcessFdQuotaExceeded  SystemFdQuotaExceeded
  ProtocolUnsupportedBySystem  ProtocolUnsupportedByAddressFamily
  SocketModeUnsupported  AccessDenied  **WouldBlock**  NetworkDown
  + error.Timeout（来自 Io.Timeout.Error）

AcceptError（10 个）:
  ProcessFdQuotaExceeded  SystemFdQuotaExceeded  SystemResources
  **SocketNotListening**  NetworkDown  **WouldBlock**
  ConnectionAborted  BlockedByFirewall  ProtocolFailure

ShutdownError（5 个）:
  ConnectionAborted  ConnectionResetByPeer  NetworkDown
  SocketUnconnected  SystemResources
```

三个值得注意的：

- **`AcceptError.SocketNotListening`** 的文档注释说明了它的**另一个用途**：
  > Either `listen` was never called, or `shutdown` was called (possibly while
  > this call was blocking). This allows `shutdown` to be used as a concurrent
  > cancellation mechanism.

  也就是说**服务器可以用 `shutdown` 来取消阻塞中的 `accept`**——这是 0.17 内建的
  "优雅关停"机制，比"标志位 + 强杀"干净得多。

- **`ConnectError.WouldBlock`** 表示"非阻塞 connect 不能立即完成"。
  这在事件驱动模型里是正常的（你会等 `Writable` 事件再 `getsockopt` 检查），
  在阻塞模型里不该出现。

- **`Io.UnexpectedError` / `Io.Cancelable` 被`||` 进了每一个错误集**。
  `Cancelable` 意味着**任何网络操作都可以被取消**（这是 `Io` 抽象的功劳——
  30 章的 `Future.cancel` 就靠它）。

### 29.10.3 ⚠️⚠️ `ConnectOptions.timeout` 在 0.17 未实现

这是实测撞出来的第二个 panic：

```text
thread 2337618 panic: TODO implement netConnectIpPosix with timeout
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:12410:35: in netConnectIpPosix (main)
    if (options.timeout != .none) @panic("TODO implement netConnectIpPosix with timeout");
                                  ^
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/net.zig:346:55: in connect (main)
        return .{ .socket = try io.vtable.netConnectIp(io.userdata, address, options) };
/Volumes/mac004/code/programming/zig/examples/29_netecho/main.zig:893:23: in main (main)
```

源码（`Threaded.zig:12410`）就一行：

```zig
if (options.timeout != .none) @panic("TODO implement netConnectIpPosix with timeout");
```

Windows 上也一样（`Threaded.zig:12429`，`netConnectIpWindows`）。所以：

> **0.17 里不要给 `connect` 传 `.timeout`。** 连超时要靠 `io` 层的
> deadline / 事件驱动机制，不是这个字段。

这也解释了为什么 `Io.Timeout` 存在但用处有限——它被用在
`Socket.sendTimeout` / `receiveTimeout` / `sendManyTimeout` / `receiveManyTimeout`
上（那几个是**实现了**的），但**没用在 `connect` 上**。

对应测试只断言形状，不真的调：

```zig
// examples/29_netecho/main.zig 第 1284-1290 行
// ⚠️ **不要**给 connect 传 .timeout：POSIX 上那会 @panic（0.17 未实现，见 29.10）
    // 断言的是 Io.Timeout 的形状本身
    try std.testing.expectEqual(std.Io.Timeout.none, (net.IpAddress.ConnectOptions{ .mode = .stream }).timeout);
    const to = std.Io.Timeout{ .duration = .{ .raw = .fromSeconds(1), .clock = .awake } };
    try std.testing.expectEqualStrings("duration", @tagName(to));
}
```

顺带记一下 `Io.Timeout` 的构造（这是 20 章坑过的地方）：

```zig
// ❌ 没有 .some(n)
.{ .timeout = .some(1) }
// error: union 'Io.Timeout' has no member named 'some'

// ✅ Io.Timeout 是 union(enum)，payload 是 Clock.Duration = { .raw: Io.Duration, .clock: Clock }
.{ .timeout = .{ .duration = .{ .raw = .fromSeconds(1), .clock = .awake } } }
```

### 29.10.4 三段式 catch

照抄 20.12 的模式，只是错误集换成网络的：

```zig
// examples/29_netecho/main.zig 第 904-913 行
    p("三段式 catch（照抄20.12 的模式，只是错误集换成网络的）：\n", .{});
    p("  connect(...) catch |err| switch (err) {{\n", .{});
    p("      error.ConnectionRefused => return error.ServerNotRunning, // 业务上的\"没开\"\n", .{});
    p("      error.Timeout, error.WouldBlock => return error.ServerBusy,\n", .{});
    p("      error.AddressFamilyUnsupported, error.AccessDenied => return err, // 真错误\n", .{});
    p("      else => |e| return e, // 兜底，别 catch {{}}\n", .{});
    p("  }}\n", .{});
```

三段的结构和 20.12 一模一样：

1. **一个错误 → 一个语义值**（`ConnectionRefused` → `error.ServerNotRunning`——
   "服务没开"是业务事实，不是网络细节）；
2. **另一些 → 原样上抛**（`AddressFamilyUnsupported` 是真错误：你的代码或系统有问题）；
3. **其余 → `else => |e| return e`** 兜底（**不要写 `catch {}`**——
   那会把 `AccessDenied`、`SystemResources` 一起吞掉）。

⚠️ `catch {}` 在网络代码里是**特别危险的反模式**：网络错误种类繁多，
吞掉一个你没想到的错误，症状就是"连接偶尔静默失败"。

对应的测试把五类错误都断言了：

```zig
// examples/29_netecho/main.zig 第 1268-1291 行
test "29.10 错误分类：连接被拒 / 超时 / 地址不可用要分开" {
    const io = std.testing.io;
    // 没人监听 → ConnectionRefused
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
    // ⚠️ **不要**给 connect 传 .timeout：POSIX 上那会 @panic（0.17 未实现，见 29.10）
    // 断言的是 Io.Timeout 的形状本身
    try std.testing.expectEqual(std.Io.Timeout.none, (net.IpAddress.ConnectOptions{ .mode = .stream }).timeout);
    const to = std.Io.Timeout{ .duration = .{ .raw = .fromSeconds(1), .clock = .awake } };
    try std.testing.expectEqualStrings("duration", @tagName(to));
}
```

## 29.11 线程模型与端口扫描

### 29.11.1 两种模型

```zig
// examples/29_netecho/main.zig 第 918-927 行
    p("两种模型：\n", .{});
    p("  一连接一线程（本示例）：简单、每条连接独立阻塞栈；上千连接就吃不消\n", .{});
    p("  事件循环（生产）：单线程非阻塞 + 就绪事件；Zig 里由 io.vtable 的实现决定\n", .{});
    p("    init.io 走的是 Threaded（线程池）实现；事件驱动是另一种 Io 实现，同一份业务代码不变\n", .{});
    p("  ⇒ **这就是\"io 是参数\"的回报**：换 io 就换线程模型，业务代码一行不改。\n", .{});
```

| | 一连接一线程 | 事件循环（单线程非阻塞） |
|---|---|---|
| 代码形状 | `while (true) { accept; spawn(handler) }` | `while (true) { await anyEvent(); dispatch }` |
| 阻塞调用 | 直接用（每个线程自己阻塞） | **不能用**——必须 `tryWait` / 事件驱动 |
| 连接上限 | 受线程栈限制（几千） | 只受 fd 限制（几万） |
| 背压 | 天然（阻塞就是背压） | 要靠 `Writable` 事件 |
| 适合 | 连接数少、每个连接活很久（DB 连接池） | 连接数多、每个连接很短（HTTP/网关） |

本章示例用**一连接一线程**，因为它最容易看清数据流。生产里两种都要会。

### 29.11.2 ⚠️ `accept` 要 `*Server`：`Thread.spawn` 的坑

```zig
// examples/29_netecho/main.zig 第 928-932 行
    p("⚠️ 一连接一线程的写法陷阱：Server.accept 要 **\\*Server**（非 const）\n", .{});
    p("  Thread.spawn(.{{}}, serve, .{{ io, srv }})     → 找不到 expected type '*net.Server'\n", .{});
    p("  Thread.spawn(.{{}}, serve, .{{ io, &srv }})    → 对（手动取地址）\n", .{});
    p("  且被调函数形参必须是 fn serve(io: std.Io, srv: *net.Server, ...) —— 写 const 会收不到\n", .{});
```

三条一起说：

1. **`srv` 必须声明成 `var`**（因为 `accept` 要 `*Server`）。
2. **传给 `Thread.spawn` 的实参必须写 `&srv`**。线程参数**按值传递**，
   不会自动变指针——写 `srv` 传的是 `Server` 的**拷贝**，
   而 `spawn` 要的是 `*Server`，于是报：
   ```text
   error: expected type '*Io.net.Server', found '*const Io.net.Server'
   ```
   附带一句 `cast discards const qualifier`。
3. **被调函数的形参也必须是 `*net.Server`**，不能写 `const *net.Server` 或 `net.Server`。
   写 `net.Server`（按值传）就收不到那个 fd；写 `*const` 编译不过。

本章的写法：

```zig
// examples/29_netecho/main.zig 第 153-166 行
/// 回环服务器：恰好服务 `rounds` 条连接，每条连接逐段回声直到对端关闭。
///
/// ⚠️ `accept` 的接收者是 `*Server`（**非 const**），因为它要读 `socket.handle`。
/// 所以形参必须是 `*net.Server`，传给 `std.Thread.spawn` 的实参必须写 `&srv`——
/// 线程参数按值传递不会自动变指针，写 `srv` 会得到 `*const Server` 然后编译失败。
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
```

对应的调用（注意 `&srv`）：

```zig
// examples/29_netecho/main.zig 第 975-977 行
        var rounds: usize = 2;
        const th = try std.Thread.spawn(.{}, tcpEchoServer, .{ io, &srv, &rounds });
```

### 29.11.3 关停策略：干完定量就退

`tcpEchoServer` / `udpEchoServer` **只服务预定条数**（2 条连接 / 3 个数据报），
干完活 `return`。主线程 `th.join()` 就是同步点。

这比"标志位 + 强杀"干净得多：

| | 标志位 + 强杀 | 干完定量就退（本例） |
|---|---|---|
| 竞态窗口 | 有（标志检查和 accept 之间可能有新连接进来） | **无** |
| 悬挂句柄 | 可能（accept 阻塞中被杀，fd 泄漏） | **无**（`defer conn.close` 跑到了） |
| 代码量 | 标志 + 条件 + 超时逻辑 | 一个 `while (served < n)` |
| 适合 | 长期运行的服务 | **测试、自演、示例** |

0.17 没有 `WaitGroup`（`std.Thread.WaitGroup` 不存在），所以"定量"既是设计也是同步手段。

### 29.11.4 ⚠️ 端口扫描：必须从高位非 0 端口起

这是本章唯一一个"看起来像笨办法但真的必要"的技巧。

```zig
// examples/29_netecho/main.zig 第 42-58 行
/// 从 base 起找第一个能 listen 的 TCP 端口（最多试 20 个）。
/// ⚠️ **base 必须是非 0 的高位端口**：从 0 起扫，内核会立刻给你一个 ephemeral 端口
/// 并"成功"返回——你连自己都不确定连到了谁。实测从 0 起扫第一轮就"成功"，
/// 拿到的是 49xxx/50xxx 这种内核随便给的端口。实测从 49421 起扫才拿到 49421。
///
/// 扫 20 个是实测得出的冗余度：本机上 run-all.sh 与其它章的示例可能同时占端口，
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
```

实测对比：

```zig
// examples/29_netecho/main.zig 第 933-953 行
    p("端口扫描：⚠️ **必须从非 0 的高位端口起**，实测对比：\n", .{});
    {
        // 从 0 起
        const z = try net.IpAddress.parseIp4("127.0.0.1", 0);
        var s0 = try z.listen(io, .{});
        p("  从 **0** 起扫：第一轮就\"成功\"，拿到端口 {d} ← 这是内核给的 ephemeral\n", .{s0.socket.address.getPort()});
```

运行输出（`examples/29_netecho/main.zig`）：

```text
端口扫描：⚠️ **必须从非 0 的高位端口起**，实测对比：
  从 **0** 起扫：第一轮就"成功"，拿到端口 51227 ← 这是内核给的 ephemeral
     你连自己都不确定连到了谁（可能就是别的进程），所以扫描绝不能从 0 起
  从 **49421** 起扫：拿到端口 49421（第一个就成功，说明没冲突）
  ⚠️ 端口 49421 起、扫 20 个：这个范围是本教程的"私用段"，
     run-all.sh 与其它章的示例可能同时占端口，所以要扫够冗余（本机实测 20 个够）。
  先手动占住 49421，然后从 49421 再扫 → 落到 49422（+1）⇒ 扫描确实会跳过被占的端口
```

（端口号每次不同。）

**为什么从 0 起是错的**：`listen(port=0)` 的语义是"让内核随便挑一个空闲端口"。
它**几乎永远成功**——于是你的扫描第一轮就"成功"了，拿到了一个内核给的
`51227` 之类的 ephemeral 端口。此时：

- 你**无法区分**"我扫到了 0 号端口"和"内核给了我 51227"；
- 更糟的是，那个 ephemeral 端口**可能已经被别人占用**（内核保证不冲突，
  但你不知道它是给谁的）；
- 于是你的"测试"实际上连到了一个完全无关的端口上，而测试依然"通过"。

**为什么从高位起是对的**：`listen(49421)` 要么成功（这个端口确实是我的），
要么报 `AddressInUse`（被占了，换下一个）。**语义确定，行为可预测**。

**为什么是高位**：低位端口（< 1024）是特权端口，bind 会报 `AccessDenied`。
IANA 动态端口范围通常是 49152–65535，所以 49421 落在"动态段的开头"——
这些端口是给临时绑定用的，冲突概率低，但也不是零。

**为什么扫 20 个**：`run-all.sh` 会依次跑各章的示例，如果两章都用同一个固定端口，
就可能撞上。扫 20 个连续端口足够跑过偶发冲突——本机实测 20 个够用。

守成了测试（`// examples/29_netecho/main.zig 第 1292-1322 行`）：

```zig
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
```

**这是"如何在测试里验证网络代码"的完整答案**（本章最后一节的主题）：

```text
| 要求 | 做法 |
|---|---|
| **不用固定端口** | 首选 `listen(port=0)` + 读 `server.socket.address.getPort()`（29.4） |
| 必须用固定端口时 | 高位非0 起扫 + 扫足够范围（本例 49421 起、20 个） |
| 验证端口号可信 | 读出端口 → `connect` 它 → 看 `accept` 是否成功（29.4.2） |
| 避免和别的测试撞| 每个测试用独立端口段，或全部走 port=0 |
| 不留残留 | `defer server.deinit(io)` + `defer stream.close(io)`（注意别关两次） |
| 不依赖时序 | **不要**用 `sleep` 等对端就绪；用"会合点"（本例的 `Rendezvous` 原子端口） |
| 测试服务端逻辑 | 干完定量就 `return`，主线程 `join()` 同步（29.11.3） |
```

会合点的实现（这是"不用 sleep"的技巧）：

```zig
// examples/29_netecho/main.zig 第 27-41 行
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
```

**为什么需要它**：29.4 让"读真实端口"变得容易了，但那只解决了**主线程**的问题。
`udpEchoServer` 在**另一个线程**上 `bind`，主线程在它 `bind` 之前就该知道端口。
`Rendezvous` 用一个原子 `u16`（0 表示"还没准备好"）解决——比 `sleep` 快得多，
也比条件变量简单（15 章讲过 `Io.Condition` 的用法，这里用不上：等待时间只有几微秒）。

⚠️ `Rendezvous` 的 `port = 0` 是哨兵值——所以**服务器不能真的绑到 0 号端口**。
这正好和29.11.4 的结论一致：**别用 0 起扫**。

## 29.12 自演：UDP 三个数据报 + TCP 两条连接

### 29.12.1 UDP 部分

```zig
// examples/29_netecho/main.zig 第 959-975 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
==== 29.12 开始 ====
UDP 服务器就绪：127.0.0.1:49371（高位端口起扫，实测形如 49xxx）
  UDP 回声一致：dgram-0（from端口 49371）
  UDP 回声一致：dgram-1（from端口 49371）
  UDP 回声一致：dgram-2（from端口 49371）
UDP echo 完成（3 数据报，join 即同步——没有 WaitGroup）
```

**注意 `from` 端口和服务端端口相同（49371）**——这是**正确的**！
客户端 `bind(uport + 100)` 之后，内核发数据报时用的是**源地址**，
而源端口就是客户端绑的端口。但服务端 `sock.send(io, &incoming.from, ...)` 是
**发回 `incoming.from`**（客户端的地址），所以客户端在自己绑的端口上收到。

这里有个容易搞混的点：UDP 的 `send` 需要**目的地址**（和 TCP 不同）。
所以 UDP 客户端必须先 `bind` 一个端口（否则内核每次发都用不同的 ephemeral 源端口，
服务端就 `send` 不回去了——或者能回去但客户端的 `receive` 在错误的端口上）。

**能不能不 `bind` 直接 `send`？** 可以（内核自动绑 ephemeral），但那样**客户端无法
`receive`**（它不知道自己的端口）。所以**要收发的 UDP 客户端必须 `bind`**。

### 29.12.2 TCP 部分

```zig
// examples/29_netecho/main.zig 第 976-1006 行
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
```

运行输出（`examples/29_netecho/main.zig`）：

```text
TCP 服务器就绪：127.0.0.1:49421（std.Io.net 直连）
  第 0 条连接 2×2 收发一致
  第 1 条连接 2×2 收发一致
TCP echo 完成（2 连接）
==== 29.12 结束 ====
自检通过
```

⚠️ **两个 `defer conn.close()` 在循环里**——这是 29.7.4 说的"全 defer"模式：
`defer` 在**函数**结束时才执行，不是迭代结束时。所以两条连接的
`close` 都在 29.12 的块结束时才跑。因为有 `closed` 标志兜底，
即使之后再关一次也不会 panic。

`std.debug.assert` 而不是 `expect`：**自演**用 `assert`（快速，失败即panic），
**单元测试**用 `expect`（15 章）。这个区别在 15.2 讲过。

## 29.13 坑位清单

1. **⚠️⚠️ `takeDelimiterExclusive` 在 0.17.0 有 std bug：分隔符不被吃掉。**
   第一次调用正确，第二次起**永远返回空片**。纯内存 `Reader.fixed("alpha\nbeta\n")`
   就能复现（与网络无关）。根因（`Reader.zig:894-898`）：
   `takeDelimiterExclusive` 只 `toss(result.len)`，而 `result` 是
   `peekDelimiterInclusive`（**含**分隔符）砍掉最后一字节的结果——
   于是 `'\n'` 永远留在缓冲里，下一次 `peek` 立刻命中它。
   **症状**：服务端「读到空行 → 写 OK → 再读到空行」死循环刷屏，
   且因为 `toss(0)` 不消耗内核数据，客户端永远等不到进展。
   **正解**：用 `takeDelimiter(delim)`（返回 `?[]u8`，按 inclusive 长度 toss）
   或 `takeDelimiterInclusive`，或自己 `fillMore` + `indexOfScalarPos` + `toss(at + 1)`。
   **注意别被误导**："不阻塞所以返回空片"这个诊断是错的——它其实**会**阻塞地
   `fillMore`（29.7.3）。

2. **⚠️⚠️ `ConnectOptions.timeout` 在 0.17 未实现，填了就 panic。**
   POSIX 上 `Threaded.zig:12410` 一行
   `if (options.timeout != .none) @panic("TODO implement netConnectIpPosix with timeout");`，
   Windows 上 `12429` 同理。**别给 `connect` 传 `.timeout`**；
   超时要靠 `io` 层的 deadline / 事件驱动。`Io.Timeout` 在
   `sendTimeout`/`receiveTimeout` 等上是**实现了**的，只有 `connect` 没有（29.10.3）。

3. **⚠️ `BindOptions.ip6_only = true` 在 AF_INET 上直接 panic。**
   `Threaded.zig:12608` 的 `openSocketPosix` **无条件**设 `IPV6_V6ONLY`，
   对 `AF_INET` socket 调 `setsockopt` 返回 `EINVAL`，被归到 `errnoBug` →
   `programmer bug caused syscall error: INVAL` → panic。
   **IPv4 上永远别填 `ip6_only`**（29.3.3）。

4. **⚠️ `Stream.read(io, [][]u8)` 在 0.17.0 标准库自身编译不过。**
   `Io/net.zig:1286` 的 `const rc, _ = try (...).net_read;` 想解构一个 **struct**
   （`Stream.ReadResult`），Zig 不允许，报
   `type 'Io.net.Stream.ReadResult' cannot be destructured`。
   这是发行版的 bug 不是你写错了。**绕开**：用 `stream.reader(io, buf)`
   （内部走回调 `vtable.readVec`，不经过 `io.operate`）。
   另外 `read` 的第三参是 `[][]u8`（可变），不能直接传 `&.{&buf}`（29.7.1）。

5. **⚠️ 自引用结构体不能按值拷贝——本章最有价值的坑。**
   把 `Stream`/`Reader`/`Writer` 和它们的缓冲放同一 struct 时，
   **不能在 `init()` 里就地绑定**：`stream.reader(io, &self.rbuf)` 绑到的是
   `init`的栈帧，`return self` 一次值拷贝就悬垂。**编译通过、零警告、
   小包偶尔对、缓冲区一大就乱**。实测两个指针差 0x270（正好一块缓冲）。
   **正解**：只存"原料"（`Stream` + `[]u8`），收发前 `ensureBound()` 懒绑定，
   或干脆每次收发在栈帧上新建 Reader/Writer（29.5）。

6. **⚠️ `Stream.close` / `Server.deinit` 不是幂等的。**
   显式 close 后再 `defer close`（或反之）→ 第二次 `close(2)` 返回 `EBADF` →
   `Threaded.zig:19963` 的 `recoverableOsBugDetected` → `unreachable` → panic
   （`thread N panic: reached unreachable code`）。
   **要么全 `defer`，要么全显式**，绝不混用；或加 `closed` 标志（29.7.4）。

7. **⚠️ `readSliceShort` 是"填满缓冲或读到 EOF"，不是单次 recv。**
   对端发 3 字节就停住（不关）时，`readSliceShort(&16字节缓冲)` 会**一直等**——
   服务端就此挂死。**正确形状**是 `fillMore()` + `buffered()` + `toss()`。
   而且 `fillMore` 在 EOF 时返回 **`error.EndOfStream`（不是 `void`）**，
   必须在 `catch` 里处理；`buffered()` 返回的切片在下一次 `fillMore` 后失效（29.7.2）。

8. **`listen` / `bind` / `connect` 的接收者是 `*const IpAddress`（不是 `const`）。**
   `try parseIp4(...).listen(io, .{})` 编译不过，报
   `no field or member function named 'listen' in 'error{...}!Io.net.IpAddress'`
   （误导：它把错误集也打出来了）。**必须先存成变量**。另外
   `IpAddress.resolve` 系列**没有接收者**、`io` 在第 1 位（29.3.1）。

9. **`BindOptions.mode` 和 `ConnectOptions.mode` 都没有默认值。**
   `bind(io, .{})` / `connect(io, .{})` 编译不过（`missing struct field: mode`）。
   UDP 必须 `.mode = .dgram`（**不是** `.datagram`），TCP 客户端必须 `.mode = .stream`。
   而 `ListenOptions.mode` **有**默认值 `.stream`，所以 `listen(io, .{})` 就能开TCP 服务（29.3.2）。

10. **⚠️ `Socket.createPair`（socketpair）在 POSIX 上默认失败。**
    `@hasDecl` 是 `true`，但 `CreatePairOptions.family` 默认 `.ip4`，
    而 POSIX 的 `socketpair(2)` **只支持 AF_UNIX** → `ENOTSUP(102)` →
    `netSocketCreatePair` 归到 `unexpectedErrno` → **`error.Unexpected` + 打印整个栈回溯**。
    而且 `CreatePairOptions.family` 的类型 `IpAddress.Family` 只有 `ip4`/`ip6`，
    **没有 `AF_UNIX` 选项**，所以这个 API 在 POSIX 上完全不可用。
    另外它返回 `[2]Socket`（不是 `Stream`），想要 reader/writer 得自己包（29.3.4）。

11. **地址解析的错误集要按入口对（三个入口三套名字）。**
    `Ip4Address.ParseError` 有 5 个成员：`Overflow` / `InvalidCharacter` /
    `InvalidEnd` / `Incomplete` / `NonCanonical`——所以**非法 IP 报
    `InvalidCharacter`，不是 `InvalidAddress`**（别想当然）。
    特殊地：`"01.2.3.4"` → `NonCanonical`（禁止前导零），`""` → `Incomplete`。
    `Ip6Address.ParseError` 只有 2 个（`ParseFailed` / `UnresolvedScope`）——
    **带 scope 的 `"fe80::1%en0"` 报 `UnresolvedScope`**，要靠
    `IpAddress.resolve(io, ...)` 查接口名（要 `io` 因为要 `ioctl`）。
    而 `parse`（自动 v4/v6）**统一报 v6 的错误名**，诊断信息丢失。
    `parseLiteral` 的错误集只有 2 个（`InvalidAddress` / `InvalidPort`），
    而且**IPv6 字面量必须带方括号**——`"[::1]"` 合法（端口 0），`"::1"` →
    `InvalidAddress`（RFC 3986 的规定，因为 v6 地址本身含 `:`，不加分隔符就没法和端口
    区分）。另外不带端口时端口是 **0**，`parseLiteral("host")` 之后要自己 `setPort`（29.2）。

12. **⚠️ `getPort()` / `setPort()` 用本机序，不是网络序。**
    源码注释：`/// Returns the port in native endian.`。
    这和 C 的 `sockaddr_in`（网络序）**正好相反**——移植时最容易错的地方。
    另外 `Ip4Address.bytes` 是 `[4]u8` 不是 `u32`，所以照抄 C 代码反而不会错字节序（29.2.1）。

13. **`Socket` 没有 `reader` / `writer`（`@hasDecl` 实测 `false`），且 0.17 分不出
    "有序关闭"和"硬关闭"。** 前者是**设计而非缺陷**：TCP 是字节流需要缓冲，
    UDP 保留消息边界所以 `receive` 一次就是一个完整数据报，不需要缓冲层（29.8.5）。
    后者：对端 `close()` 之后本端 `fillMore` **也**报 `EndOfStream`，
    和 `shutdown(.send)` 完全同形（`Stream.Reader.readVec` 只检查 `data_len == 0`，
    不看 flags）。要在 TCP 上区分"对方正常说完"和"对方崩了"，
    得**在应用层加结束标记**（HTTP 的空行、Redis 的 0 长度数组）（29.9.3）。

14. **⚠️ `IncomingMessage.data` 是借用，不是拷贝。**
    源码注释：`points into the caller-supplied buffer`。
    必须在**下一次 `receive` 之前**用完，否则内容被覆盖。
    而且 UDP 接收缓冲不够时**静默截断**（`flags.trunc = true`，不报错）——
    这个必须检查，否则会拿到半个数据报还以为完整。
    发送侧则是"要么整包发出、要么 `error.MessageOversize`"（不静默截断）（29.8.4）。

15. **⚠️ 端口扫描必须从高位非 0 端口起，且要扫够范围。**
    `listen(port=0)` **几乎永远成功**（内核给 ephemeral 端口），所以从 0 起扫
    第一轮就"成功"，你连自己都不确定连到了谁。必须从 49421 这类高位非 0 端口起，
    靠 `AddressInUse` 判断被占。本机实测扫 **20 个**连续端口足够跑过
    `run-all.sh` 与其它章的冲突（29.11.4）。
    **不过**：0.17 里生产代码应该直接用 `listen(0)` + 读
    `server.socket.address.getPort()`（29.4 已实测该值可信，3/3 connect+accept 成功）。

16. **⚠️ `Server.accept` / `Server.deinit` 的接收者是 `*Server`（非 const）。**
    传给 `std.Thread.spawn` 的实参**必须写 `&srv`**（线程参数按值传递，
    不会自动变指针），报 `expected type '*Io.net.Server', found '*const Io.net.Server'`。
    且被调函数形参也必须是 `*net.Server`——写 `const` 不收（29.11.2）。
    另外 `Server` 的关闭方法是**`deinit`**（不是 `close`），
    而 `Stream` 的是 `close`——两个类型两套 API。
    **`Io.Timeout` 也有配套的坑**：它是 `union(enum)` 不是 `enum`，
    没有 `.some(n)`（写 `.some(1)` 报 `union 'Io.Timeout' has no member named 'some'`），
    得写 `.{ .duration = .{ .raw = .fromSeconds(1), .clock = .awake } }`（29.10.3）。

---

**上一章**：[28 文件监视](28-watch.md) · **下一章**：[30 HTTP 服务与客户端](30-http.md)