# 22 · 网络编程：从套接字到应用层

> 对应示例：`examples/22_networking`

> 本章按《C#网络程序开发（第二版）》（何波/傅由甲，清华，2019）的骨架展开：它的第 1-2 章（通信模型、System.Net 基础类）→ 本章第 1-2 节；第 3-4 章（TCP/UDP）→ 第 4-5 节；第 7 章（POP3 手写客户端）→ 第 7 节原样继承；第 6/8/9 章的 FTP/HttpWebRequest/WebService 老写法 → 第 8 节的迁移表。API 全部换成 .NET 10 的现代形态。

## 1. 心智模型：HTTP 之下的那一层

教材开篇先分**三种通信架构**——它决定你的代码落在哪一层：

| 架构 | 形态 | 网络上的对应 |
|---|---|---|
| **C/S** | 胖客户端直连服务端 | 自定义 TCP/UDP 协议（本章主场） |
| **B/S** | 浏览器 + Web 服务 | HTTP（第 16 章 Minimal API + 本章第 6 节客户端） |
| **P2P** | 对等节点互为客户/服务 | 应用层自建发现与打洞（见第 8 节，教材的 PNRP 已退场） |

传输层选型：

| 类型 | 层次 | 语义 | 典型用途 |
|---|---|---|---|
| `TcpListener` / `TcpClient` | TCP | 可靠、有序、面向连接的字节**流** | 自定义协议、内部服务 |
| `UdpClient` | UDP | 无连接数据报，可丢可乱序 | 广播、组播、探测、游戏/实时 |
| `Socket` | 两者底层 | 上面三类的共同底座 | 精细控制（超时、广播位） |

**套接字（socket）= IP + 端口**的编程抽象：IP 定主机，端口定进程（0~1023 是系统保留段）。`127.0.0.1` 上 `8080` 端口的一个 TCP 连接，加上两端的地址，就是教材说的「五元组」（协议、源 IP、源端口、目的 IP、目的端口）。

## 2. System.Net 的地基：IPAddress / IPEndPoint / Dns / Ping

传输层的四个地基类型（示例实测输出）：

```csharp
var v4 = IPAddress.Parse("192.168.1.10");
IPAddress.Parse("::ffff:192.168.1.10").MapToIPv4()      // → 192.168.1.10：IPv6 映射地址折回 v4
var ep = new IPEndPoint(v4, 8080);                       // ep.ToString() → "192.168.1.10:8080"
var hostEntry = await Dns.GetHostEntryAsync("localhost");// 名字 → 地址（IPHostEntry）
using var ping = new Ping();
var reply = await ping.SendPingAsync(IPAddress.Loopback, 500);
```

```text
ipaddress: 192.168.1.10 family=InterNetwork；IPv6 映射地址 MapToIPv4 → 192.168.1.10
ipendpoint: 192.168.1.10:8080 = IP 定主机 + 端口定进程（套接字的编程抽象）
dns: localhost → xulun-main [::1, 127.0.0.1]
ping: 127.0.0.1 → Success，往返 0ms
```

四个要点：

- `Dns.GetHostEntryAsync` 是**名字 → 地址**的唯一正道；返回的 `IPHostEntry` 里 `AddressList` 可能同时有 `::1` 和 `127.0.0.1`（双栈机器）——顺序平台相关，别假定第一个是 v4（坑位清单第 6 条的根源）
- `Ping` 在 .NET 里是完整的 ICMP 客户端（构造-发送-读状态）；Unix 上发裸 ICMP 可能要特权，`try/catch` 包住打印环境限制而不是崩
- `IPAddress.Any`（监听所有 v4）/ `IPAddress.IPv6Any` 是服务端监听地址；`Loopback` 只收本机
- 端口 0 = 「系统给我分配一个空闲端口」——示例与测试的标准做法（坑位清单第 4 条）

## 3. 字节序与编码：协议的第一课

网络字节序是**大端**，x86/ARM 本机序是**小端**。`BitConverter` 转出来的是**本机序**——直接发它，对端读出来是反的。用 `System.Buffers.Binary.BinaryPrimitives`：

```csharp
BinaryPrimitives.WriteInt32BigEndian(frame.AsSpan(0, 4), payload.Length);  // 写
int size = BinaryPrimitives.ReadInt32BigEndian(len);                        // 读
```

文本则统一 `Encoding.UTF8.GetBytes/GetString`（编码的坑见第 12 章）。所谓协议，就是双方约定的**字节布局**：前 4 字节长度 + N 字节内容——这句话就是下面 TCP 分帧的全部。

## 4. TCP 是流，不是消息：分帧

`TcpClient` 的 `Read` 语义是"把当前缓冲区里有的字节给我"——**一次 Read 不等于对端一次 Write**。两条消息可能粘成一次到达（粘包），一条也可能分两次到达（半包）。发"hello"和"socket"，读端可能拿到 "hellosock" 或 "he"。三种解法：

1. **长度前缀**（最常用，示例的做法）：先读定长 4 字节长度，再按长度读正文。
2. **分隔符**：`\n` 结尾，文本协议（Redis、SMTP、POP3 都是——第 7 节你会亲手写一个）。
3. **定长帧**：每帧等长，简单但浪费。

配套工具：`ReadExactlyAsync`（.NET 7+）把"读满 N 字节，不够抛 `EndOfStreamException`"封装好；`Read` 返回 0 表示**对端已关闭**——不是错误，是收场信号。

## 5. UDP：数据报、组播与广播

UDP 保留消息边界（一次 Send 对一次 Receive），代价是不保证送达与顺序——应用自己管重传与排序。

**组播**：目标地址在 224.0.0.0 ~ 239.255.255.255 段（224.0.0.x 保留给路由协议），只有 `JoinMulticastGroup` 入了组的成员才收得到——比广播（255.255.255.255，打扰全网段所有主机）斯文得多。示例本机自演：

```csharp
var group = IPAddress.Parse("239.1.2.3");
using var member = new UdpClient(new IPEndPoint(IPAddress.Any, 0));
member.JoinMulticastGroup(group);                        // 入组
await sender.SendAsync(payload, new IPEndPoint(group, port));   // 发给组，成员全收
member.DropMulticastGroup(group);                       // 离组要还
```

```text
udp-multicast: hello 239.1.2.3 ← 加入 239.1.2.3 组的成员都收得到
```

它最有趣的用法是**广播**：目标机连 IP 都没有也能被叫醒。Wake-on-LAN：魔术包 = 6 字节 `0xFF` + 目标 MAC 地址重复 16 次，共 102 字节，封在 UDP 广播里发给局域网。示例只构造不广播：

```csharp
static byte[] BuildMagicPacket(string mac)
{
    var macBytes = mac.Split('-').Select(h => (byte)Convert.ToInt32(h, 16)).ToArray();
    return [.. Enumerable.Repeat((byte)0xFF, 6),
            .. Enumerable.Repeat(macBytes, 16).SelectMany(x => x)];
}
```

真要发送是 `new UdpClient().Connect(broadcast, 9)` 后 `SendAsync`——目标机 BIOS/网卡在关机状态下侦听的是链路层 MAC，不吃 IP，所以广播是唯一入口。

## 6. 应用层的正门：HttpClient

教材第 8 章的 `HttpWebRequest`/`WebClient` 已经整体过时（第 8 节迁移表），现代客户端只有一个入口——**`HttpClient`**。示例用本地 `HttpListener` 当靶子（真实服务端是第 16 章的 Kestrel）：

```csharp
using var http = new HttpClient();                       // 单例复用！见坑位清单第 8 条
var page = await http.GetStringAsync($"http://127.0.0.1:{port}/");     // 最短路径

var req = new HttpRequestMessage(HttpMethod.Get, url);   // 要控制头/方法/内容时的完整形态
req.Headers.TryAddWithoutValidation("X-Client", "demo");
using var resp = await http.SendAsync(req);
resp.StatusCode                                          // 200 OK
resp.Headers.GetValues("X-Teaching")                    // 响应头
```

```text
http-get: hello over HTTP (GET /)
http-send: 200 OK，X-Teaching=22-networking
```

要点：`GetStringAsync`/`GetByteArrayAsync` 是"只要正文"的捷径；要状态码、响应头、超时控制就走 `SendAsync` + `HttpRequestMessage`；每个请求 `new HttpClient()` 是教科书级大坑（第 8 条）。

## 7. 文本协议实战：手写 POP3 客户端

POP3 在 BCL 里**从来没有**客户端类——教材第 7 章的做法就是教你拿 `TcpClient` 手写，这个传统一直有效（现代等价物是 MailKit 库）。POP3 是行协议：命令一行、响应一行，多行响应用**单独一行点号 `.`** 结束——正是第 4 节分帧法 2（分隔符）的真实用户。

示例起一个本地假服务器（真邮箱不用出网），客户端走完整会话：`USER`/`PASS` 登录 → `STAT` 看信箱 → `RETR 1` 取信 → `QUIT`：

```text
pop3: 服务器说「+OK 假 POP3 服务器就绪」
pop3: USER → +OK
pop3: PASS → +OK
pop3: STAT → +OK 2 封邮件
pop3: RETR → +OK 第 1 封的内容
pop3:   From: alice@example.com  Subject: 周报提醒
pop3: QUIT → +OK bye
```

三个实现细节（示例里都踩过）：

- 双方都用 `StreamReader`/`StreamWriter` 包住 `NetworkStream`，`NewLine = "\r\n"`——RFC 5321 家族的行终结符
- `StreamWriter` 用无参编码构造（默认 UTF-8 **无 BOM**）；传 `Encoding.UTF8` 会把 BOM 写进协议首行，对端第一行就解析歪
- 多行响应读到 `.` 为止（`for (var l = await ReadLineAsync(); l != "."; ...)`）——这就是「按分隔符分帧」的全部

真实的 POP3（端口 995）先要 `SslStream` + `AuthenticateAsClient` 做 TLS，再在同一套 StreamReader/StreamWriter 上说同样的行——**加密换管道，协议不变**。

## 8. 教材老 API 的现代下场

教材后半本（第 6-9 章：FTP、SMTP/POP3、HttpWebRequest、Web Service）的 API 大多没活到现代 .NET，或已被劝退。对照表（写新代码前先查这里）：

| 教材（2019）写法 | .NET 10 状态 | 现代做法 |
|---|---|---|
| `FtpWebRequest` / `WebRequest.Create("ftp://…")` | **[Obsolete] SYSLIB0014**，编译就给警告 | FluentFTP 库；或干脆走对象存储 SDK |
| `HttpWebRequest` / `WebClient` | 同属 WebRequest 家族（SYSLIB0014） | `HttpClient`（第 6 节） |
| `SmtpClient` 发信 | 可用但官方文档标注"不推荐" | MailKit；内部工具用 SmtpClient 仍能跑 |
| POP3 收信 | BCL 从未有过 | 手写 over `TcpClient`（第 7 节）或 MailKit |
| asmx / SOAP Web Service（`*.asmx`、WSDL 生成客户端） | ASP.NET Core 不支持 | Minimal API（第 16 章）/ gRPC / WSCF 旧服务用 `System.ServiceModel` 的社区包 |
| PNRP / `System.Net.PeerToPeer`（P2P 命名空间，教材第 5 章） | 未进入现代 .NET（Windows 时代特性） | 服务发现用 Consul/etcd；消息拓扑用 MQTT/NATS |
| 多线程下载器（教材 8.3） | — | `HttpClient` + `Task.WhenAll` 分段 `Range` 请求（第 14 章的并行原语） |

规律：**传输层 API（Socket/TcpClient/UdpClient/Dns/Ping）十年没变，应用层老 API 全军覆没**——因为传输层是稳定的协议抽象，应用层换了一轮安全与编程模型（TLS 默认、async/await、JSON over XML）。老教材里传输层的内容至今能抄，应用层的内容只配进迁移表。

## 9. 协议设计一瞥：别自造，先找现成的

UDP 上做可靠文件传输（分块编号 + 确认应答 + 超时重传）是经典练习——它帮你理解 TCP 在替你做什么。但工程结论相反：**先找现成协议**。断点续传用 HTTP `Range` 请求（`HttpClient` 加 `Range` 头），RPC 用 gRPC，消息用 MQTT——每一个都比手搓协议被坑得少。

## 10. 从 APM 到 await：一部微缩史

2019 年的教材里，Socket 异步长这样：`BeginReceiveFrom` + 回调 + 回调里 `EndReceiveFrom`，一次收包横跨三个线程（主线程发起、OS 线程回调、工作线程处理），状态靠手工接力。今天同样的事：

```csharp
var result = await socket.ReceiveFromAsync(buf, SocketFlags.None, remoteEP);
```

一个 await，编译器生成状态机（第 13 章讲过它对 continuations 做的事）。Begin/End 这套 **APM（Asynchronous Programming Model）** 你只会在老代码里见到——认得它，然后改写成 await。

## 11. 坑位清单

1. **把 TCP 当消息读**：不分手帧直接 `Read`，测试机好好的，网络一抖就粘包/半包——第 4 节的三种分帧任选其一。
2. **`BitConverter` 发网络字节**：本机序直发，跨机器读反；用 `BinaryPrimitives` 大端族。
3. **监听地址选错**：`IPAddress.Loopback`（127.0.0.1）只有本机能连；对外服务监听 `IPAddress.Any`——后者立刻暴露给局域网，防火墙/安全就是你的事了。
4. **端口写死**：示例与测试用端口 0（系统分配），避免撞端口；写死的端口是 CI 脑溢血常因。
5. **不设超时/不传 CancellationToken**：对端僵死则 `ReadAsync` 永远挂着，`CancellationToken` 配 `CTS(TimeSpan)` 一起用。
6. **IPv6 双栈混淆**：`localhost` 可能解析成 `::1`，而监听在 IPv4——connect 被拒；测试直接写 `IPAddress.Loopback` 明确族别（`GetHostEntryAsync` 返回的 `AddressList` 顺序平台相关，别赌第一个）。
7. **UDP 假定送达**：丢包乱序是常态不是异常，协议层必须有确认/重传或干脆容忍丢失。
8. **每个请求 `new HttpClient()`**：每个实例占一个独立连接池，高频创建会**耗尽套接字**（TIME_WAIT 堆积，`SocketException` 貌似随机出现）。做成单例或用 `IHttpClientFactory`（16 章的 DI 容器注册它）。
9. **`StreamWriter` 带着协议跑却传了 `Encoding.UTF8`**：首行多了 BOM，对端解析歪；行协议用无参构造（UTF-8 无 BOM）+ `NewLine="\r\n"`。
10. **组播忘了 `DropMulticastGroup` / 忽略防火墙**：跨机组播常被防火墙或路由 TTL 拦下——先本机组验证，跨机组部署时检查 TTL（`UdpClient.Ttl`）与组播路由。
