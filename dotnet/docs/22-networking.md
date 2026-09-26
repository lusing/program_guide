# 22 · 网络编程：TCP、UDP 与字节序

> 对应示例：`examples/22_networking`

## 1. 心智模型：HTTP 之下的那一层

第 16 章站在 HTTP 上（请求-响应、状态码、JSON）；本章降一层到**传输层**——TCP 与 UDP，你面对的不再是"API"，而是**字节流与数据报**。选型表：

| 类型 | 层次 | 语义 | 典型用途 |
|---|---|---|---|
| `TcpListener` / `TcpClient` | TCP | 可靠、有序、面向连接的字节**流** | 自定义协议、内部服务 |
| `UdpClient` | UDP | 无连接数据报，可丢可乱序 | 广播、探测、游戏/实时 |
| `Socket` | 两者底层 | 上面三类的共同底座 | 精细控制（超时、广播位） |

写 HTTP 用 `HttpClient`（第 16 章）；只有协议不被 HTTP 覆盖时才落到这一层。

## 2. 字节序与编码：协议的第一课

网络字节序是**大端**，x86/ARM 本机序是**小端**。`BitConverter` 转出来的是**本机序**——直接发它，对端读出来是反的。用 `System.Buffers.Binary.BinaryPrimitives`：

```csharp
BinaryPrimitives.WriteInt32BigEndian(frame.AsSpan(0, 4), payload.Length);  // 写
int size = BinaryPrimitives.ReadInt32BigEndian(len);                        // 读
```

文本则统一 `Encoding.UTF8.GetBytes/GetString`（编码的坑见第 12 章）。所谓协议，就是双方约定的**字节布局**：前 4 字节长度 + N 字节内容——这句话就是下面 TCP 分帧的全部。

## 3. TCP 是流，不是消息：分帧

`TcpClient` 的 `Read` 语义是"把当前缓冲区里有的字节给我"——**一次 Read 不等于对端一次 Write**。两条消息可能粘成一次到达（粘包），一条也可能分两次到达（半包）。发"hello"和"socket"，读端可能拿到 "hellosock" 或 "he"。三种解法：

1. **长度前缀**（最常用，示例的做法）：先读定长 4 字节长度，再按长度读正文。
2. **分隔符**：`\n` 结尾，文本协议（Redis、SMTP 都是）。
3. **定长帧**：每帧等长，简单但浪费。

配套工具：`ReadExactlyAsync`（.NET 7+）把"读满 N 字节，不够抛 `EndOfStreamException`"封装好；`Read` 返回 0 表示**对端已关闭**——不是错误，是收场信号。

## 4. UDP：数据报与 WOL 魔术包

UDP 保留消息边界（一次 Send 对一次 Receive），代价是不保证送达与顺序——应用自己管重传与排序。

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

## 5. 协议设计一瞥：别自造，先找现成的

UDP 上做可靠文件传输（分块编号 + 确认应答 + 超时重传）是经典练习——它帮你理解 TCP 在替你做什么。但工程结论相反：**先找现成协议**。断点续传用 HTTP `Range` 请求（`HttpClient` 加 `Range` 头），RPC 用 gRPC，消息用 MQTT——每一个都比手搓协议被坑得少。

## 6. 从 APM 到 await：一部微缩史

2016 年的教材里，Socket 异步长这样：`BeginReceiveFrom` + 回调 + 回调里 `EndReceiveFrom`，一次收包横跨三个线程（主线程发起、OS 线程回调、工作线程处理），状态靠手工接力。今天同样的事：

```csharp
var result = await socket.ReceiveFromAsync(buf, SocketFlags.None, remoteEP);
```

一个 await，编译器生成状态机（第 13 章讲过它对 continuations 做的事）。Begin/End 这套 **APM（Asynchronous Programming Model）** 你只会在老代码里见到——认得它，然后改写成 await。

## 7. 坑位清单

1. **把 TCP 当消息读**：不分手帧直接 `Read`，测试机好好的，网络一抖就粘包/半包——第 3 节的三种分帧任选其一。
2. **`BitConverter` 发网络字节**：本机序直发，跨机器读反；用 `BinaryPrimitives` 大端族。
3. **监听地址选错**：`IPAddress.Loopback`（127.0.0.1）只有本机能连；对外服务监听 `IPAddress.Any`——后者立刻暴露给局域网，防火墙/安全就是你的事了。
4. **端口写死**：示例与测试用端口 0（系统分配），避免撞端口；写死的端口是 CI 脑溢血常因。
5. **不设超时/不传 CancellationToken**：对端僵死则 `ReadAsync` 永远挂着，`CancellationToken` 配 `CTS(TimeSpan)` 一起用。
6. **IPv6 双栈混淆**：`localhost` 可能解析成 `::1`，而监听在 IPv4——connect 被拒；测试直接写 `IPAddress.Loopback` 明确族别。
7. **UDP 假定送达**：丢包乱序是常态不是异常，协议层必须有确认/重传或干脆容忍丢失。
