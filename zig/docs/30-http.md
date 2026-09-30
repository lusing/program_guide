# 30 · HTTP 服务与客户端

> 对应示例：`examples/30_http/`
>
> HTTP 是文本协议——亲手读一遍"请求行 + 头部 + 空行 + 体"，比任何框架都学得快。取材 Tsoukalos ch6（minimal web server、随机数 JSON 服务）。运输层沿用 29 章结论（Windows 下 ws2_32 直调）。

## 30.1 报文解剖：一个请求长什么样

```text
GET /api/rand?n=5 HTTP/1.1\r\n     ← 请求行：方法 SP 目标 SP 版本
Host: 127.0.0.1\r\n                ← 头部：名: 值（一行一个）
Connection: close\r\n
\r\n                               ← 空行 = 头部结束（GET 无体）
```

响应同构：状态行（`HTTP/1.1 200 OK`）+ 头部 + 空行 + 体。示例的 `Request.parse` 用 `tokenizeScalar(u8, line, ' ')` 切请求行、`indexOf('?')` 分路径与查询串——十行讲完 HTTP 的骨架。

## 30.2 服务器：读到空行，路由，回包

```zig
while (std.mem.indexOf(u8, buf[0..len], "\r\n\r\n") == null) {   // 头部没读完继续收
    const n = try conn.recvSome(buf[len..]);
    if (n == 0) return;
    len += n;
}
const req = try Request.parse(buf[0..len]);
const rep = try route(a, &req);                                    // / /api/rand /api/info
try conn.sendAll(try serialize(a, &rep));
```

`Connection: close` 让"读完即完整"成立——客户端收到 EOF 就是响应结束，不用解析 Content-Length 计数（生产服务器当然要支持 keep-alive，见练习）。响应构造：

```zig
std.fmt.allocPrint(a, "HTTP/1.1 {s}\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}", .{...})
```

Content-Length 必须与体等长——差一个字节，客户端要么等要么截断。

## 30.3 JSON 响应：std.json.Stringify

```zig
var jw = std.Io.Writer.Allocating.init(a);
try std.json.Stringify.value(.{ .n = n, .values = values[0..n], .service = "zhttp" }, .{}, &jw.writer);
```

匿名结构体直接序列化（20 章的 API，服务器场景复用）。查询参数 `?n=5` 用 `queryParam` 拆 `&` 与 `=`，`parseInt` 后 **clamp 到 1..16**——网络输入永远先消毒再使用。

## 30.4 std.http：官方 API 形态（Linux/macOS）

`std.http.Server.init(&in, &out).receiveHead()` → `request.head.target` → `request.respond(.{...})`，挂在 TCP Stream 的 reader/writer 上；`std.http.Client` 管连接池与重定向。这套 API 在 Windows 上同样受 29.0 节 AFD 问题拖累（它的运输就是 std.Io.net TCP），所以本教程的 HTTP 实测走手写报文 + ws2_32。手写的额外收益：你对协议的理解不再隔着一层抽象。

## 30.5 坑位清单

1. **返回栈上缓冲的切片 = 悬空**：示例 `get()` 最初直接 `return buf[sep+4..len]`——函数返回即栈帧死亡，打印时内容已是被复写的垃圾（本教程实测现场：头部断言碰巧过了，肉眼才见乱码）。**dupe 进调用方分配器**，所有权随调用方。
2. **每请求一个 arena**：`arena_state.reset(.retain_capacity)` 让路由/序列化的所有临时分配随请求蒸发——HTTP 服务的标准内存姿势，比"每处记得 free"纪律性强一个量级。
3. **头部读一半**：`recvSome` 一次未必收全请求——循环到 `\r\n\r\n` 出现；同时给缓冲上限（示例 2048），恶意超长头部直接断连。
4. **查询参数不做消毒**：`parseInt` 会抛错、数组长度不 clamp——DoS 与越界都从这里进。
5. **线程里共享 `std.debug.print`**：格式化参数求值与输出原子性无保证，多线程日志可能交错——正经服务用带锁的日志队列（练习）。

---

上一章：[29 TCP 与 UDP](29-networking.md) · 下一章：[31 并发进阶](31-concurrency.md)
