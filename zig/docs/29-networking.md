# 29 · TCP 与 UDP

> 对应示例：`examples/29_netecho/`
>
> echo 是网络编程的 "hello world"——服务器回射一切。取材 Tsoukalos ch6（TCP/UDP echo 双实现，0.16 原生 `std.Io.net` 写法）。**本章含一个重要的实测坏消息**，先说结论再学写法。

## 29.0 ⚠️ 实测结论：Windows 0.16.0 的 std.Io.net TCP 数据面不可用

本教程所有代码在 Windows 11 + Zig 0.16.0 实测。结论分两半：

- **UDP：一切正常**——bind/send/receive 回环全通，示例的 UDP 部分就用它。
- **TCP：控制面能通、数据面坏**——`listen/accept/connect` 都返回成功，但流上 `readSliceShort` 永远等不到数据（同进程双线程），跨进程则读到 `CONNECTION_RESET`。最小复现五行的 echo 也会挂。

这不是用法问题。0.16 的 Windows 网络改走 AFD（Ancillary Function Driver）内核接口、绕过 Winsock，社区已知其缺陷域：[AFD 绕过 Winsock 导致 socket 选项失效（ziggit）](https://ziggit.dev/t/zig-0-16-setting-socket-options-on-windows/15929)、[Windows 网络错误映射缺失（marler8997 的分析）](https://gist.github.com/marler8997/5ab75f9e90f68edef1cecaa1d1979060)、[Io.Evented 尚无网络支持（zig #31723）](https://codeberg.org/ziglang/zig/issues/31723)。`std/Io/net/test.zig` 在 0.16.0 里是个**空文件**——上游没在这条路上设防。

**对策**：Linux/macOS 照书用 `std.Io.net`（下节写法即正解）；Windows 的 TCP 走 ws2_32 extern 直调（29.3 节）——正好是 17 章 C 互操作的实战延伸。等上游修好 AFD 路径，示例的 extern 层可以整体删掉换回 std。

## 29.1 std.Io.net：书本写法（Linux/macOS 正解，UDP 则三平台通吃）

```zig
// TCP 服务端（Linux/macOS）
const address = try std.Io.net.IpAddress.parseIp4("127.0.0.1", port);
var server = try address.listen(io, .{});
defer server.deinit(io);
const stream = try server.accept(io);
defer stream.close(io);

// TCP 客户端
var stream = try address.connect(io, .{ .mode = .stream });
var r_impl = stream.reader(io, &rbuf);       // 缓冲 Reader/Writer 各配一块
var w_impl = stream.writer(io, &wbuf);
```

UDP 则是 `address.bind(io, .{ .mode = .dgram })` 拿 `Socket`，`send(io, &dest, data)` 发、`receive(io, &buf)` 收——返回的 `IncomingMessage` 带 `.from`（来路地址，回射就发回它）和 `.data`。**本机 Windows 实测 UDP 回环全通**，示例的 UDP echo 就是它：

```zig
const incoming = try sock.receive(io, &buf);
try sock.send(io, &incoming.from, incoming.data);   // 从哪来回哪去
```

## 29.2 关停策略：干完定量就退

示例的服务器线程**只服务预定条数**（3 个数据报 / 2 条连接），干完活 return——`join()` 即同步（0.16 没有 WaitGroup）。比"标志位 + 强杀"干净得多：没有竞态窗口，没有悬挂句柄。

## 29.3 Windows 逃生门：ws2_32 extern 层

```zig
const tcp = if (builtin.os.tag == .windows) struct {
    const c = struct {
        extern "ws2_32" fn socket(af: i32, type: i32, protocol: i32) callconv(.winapi) w.HANDLE;
        extern "ws2_32" fn bind(...) callconv(.winapi) i32;
        // 十个函数，一个不多
    };
    pub const Conn = struct { handle: w.HANDLE, ... };     // sendAll/recvSome
    pub const Server = struct { handle: w.HANDLE, port: u16, ... }; // listenOn/accept
} else struct { /* 空壳 */ };
```

要点：

- **extern 符号名必须与 DLL 导出名一字不差**——没有别名机制；为避免与包装方法撞名（`Server.accept` vs `extern accept`），extern 收进内层 `c` 命名空间。
- **先 `WSAStartup(0x0202, &wsa)`** 才能用任何 Winsock 函数（进程级一次），收尾 `WSACleanup`。
- **`sockaddr_in` 是 extern struct**（25 章）：family/port/addr/zero，端口**网络序**——`htons` 转换别手写位移。
- `recv` 返回 0 = 对端关闭；`SOCKET_ERROR`(-1) 才是错。

## 29.4 坑位清单

1. **`std.Io.net` 的 TCP 在 Windows 0.16.0 数据面坏**（29.0 节）——UDP 可用，TCP 走 ws2_32；这是本章第一大坑，网上几乎没有现成结论，实测五小时换来的。
2. **`ConnectOptions.mode` 无默认值**：`connect(io, .{})` 编译不过，要 `.mode = .stream`；UDP 的 `bind` 要 `.mode = .dgram`（不是 `.datagram`）。
3. **拿不到绑定后的实际端口**：std 没暴露 getsockname——绑 0 取临时端口的惯用法行不通；用"固定起始端口 + 探测 20 个"的笨办法，实际端口原子公布给客户端线程。
4. **`parseIp4` 的错误名**：非法 IP 报 `error.InvalidCharacter`（不是 InvalidAddress）——断言错误集别想当然。
5. **extern "ws2_32" 与 callconv(.winapi)**：两样都要；函数名撞车时装进内层命名空间（`c.socket` 而不是裸 `socket`）。

---

上一章：[28 文件监视](28-watch.md) · 下一章：[30 HTTP 服务与客户端](30-http.md)
