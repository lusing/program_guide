# 第 33 章 网络编程：Winsock 与本机 IPC

> **本章回答的问题**：两个程序怎么通过网络对话？`WSAStartup` 为什么必须先调？TCP 服务器五步（socket/bind/listen/accept/服务循环）各做什么？`recv` 返回 0 意味着什么？UDP 和 TCP 差在哪？一个线程怎么同时伺候多个连接？GUI 程序怎么把网络事件接进消息循环？同一台机器上的两个进程除了 `WM_COPYDATA` 还有哪些正规通道？
>
> **前置章节**：第 4 章（消息循环——`WSAAsyncSelect` 把网络事件变成消息）；第 17 章（select 模型与"等待"的思想同源）；第 19 章（管道句柄复用 `ReadFile/WriteFile`）。
>
> **你将做出什么**：一个双模式回显服务器（`examples/41_winsock_echo`）：默认启动 TCP+UDP 双协议服务器，`-c` 模式做客户端跑完整收发——一条命令自演网络全链路。

本章示例：`examples/41_winsock_echo`（TCP/UDP 回显，select 多路复用，双模式自演）。

> 本章选题参考《Mastering Windows Programming with C and C++》（Joseph ND）第 7~8 章（Winsock 与 IPC）的框架，内容按 Winsock 2.2 现行文档与本机实测整理。

## 33.1 通信手段全景：从窗口消息到跨机器

先定位。Windows 上"两个程序交换数据"的手段是一条谱系，按"跨越边界"排：

| 手段 | 边界 | 语义 | 见 |
|------|------|------|----|
| `WM_COPYDATA` | 本机，窗口间 | 一次性拷贝，`SendMessage` 同步 | 第 4 章（示例 40） |
| 命名文件映射 | 本机，共享内存 | 双方直接读写同一块内存，最快 | 第 18/20 章 |
| **命名管道** | 本机或跨机 | 可靠字节/消息流，句柄即文件句柄 | 本章 33.8 |
| 邮槽（Mailslot） | 本机或局域网广播 | 一次性小数据报，可一对多 | 本章 33.8 |
| **socket（Winsock）** | 跨机（本机回环也行） | TCP 可靠流 / UDP 数据报 | 本章主角 |

选型口诀：**同进程用变量，同机高频用共享内存，同机命令式对话用命名管道，跨机器一律 socket**。Winsock 学会了，命名管道的 API 模型几乎白送——它是"本机版的 socket"。

## 33.2 Winsock 入门：启动协议与三条纪律

Winsock（Windows Sockets）是 BSD Sockets 的 Windows 实现，多一层"启动协商"：用前先谈版本，用完收摊。

```cpp
#include <winsock2.h>      // ★ 必须在 windows.h 之前（见下）
#include <ws2tcpip.h>      // getaddrinfo/inet_pton 在这里
#pragma comment(lib, "ws2_32.lib")   // 教程统一用源内指令，build 脚本无需改

WSADATA wsa;
int err = WSAStartup(MAKEWORD(2, 2), &wsa);   // 请求 Winsock 2.2
if (err != 0) { /* err 本身就是错误码，不是 GetLastError！ */ return 1; }
// ... 全部网络工作 ...
WSACleanup();
```

三条入门纪律，每条都有人天天踩：

1. **`WSAStartup` 的返回值就是错误码**。Winsock 函数族不通过 `GetLastError` 报错（虽然 `WSAGetLastError()` 内部等价），判据也自成一族：失败返回 `INVALID_SOCKET`（socket/accept）或 `SOCKET_ERROR`（其余）——**不是 `nullptr`/`FALSE`**，别拿第 3 章的三家族判据硬套；
2. **头文件顺序**：`winsock2.h` 必须在 `windows.h` **之前**（`windows.h` 默认会捎带旧版 `winsock.h`，后到者报一堆 C2011 重定义）。要么调整顺序，要么先 `#define WIN32_LEAN_AND_MEAN` 再 include `windows.h`。见到"重定义 sockaddr"一类的编译错误，九成是这个；
3. **链接 `ws2_32.lib`**。用 `#pragma comment(lib, ...)` 写进源文件最省心（本教程 build 脚本因此不用改）。

一个程序 `WSAStartup` 一次就够（内部计数，多次调用要配对多次 `WSACleanup`——惯例是 main 开头/结尾各一次）。

## 33.3 TCP 服务器：五步流程

TCP 是"可靠字节流"：不丢、不乱、不重，代价是要先建立连接。服务器五步：

```text
socket()──→bind()──→listen()──→accept()──→ send/recv ──→ closesocket()
  买手机      办号码     开机待机    接电话      通话           挂机
```

```cpp
// ①②③ 一步到位的现代写法：getaddrinfo 替你填 sockaddr
struct addrinfo hints = {}, *res = nullptr;
hints.ai_family = AF_INET;            // IPv4（AF_UNSPEC = 不挑，v4/v6 都行）
hints.ai_socktype = SOCK_STREAM;      // TCP
hints.ai_protocol = IPPROTO_TCP;
hints.ai_flags = AI_PASSIVE;          // 服务器侧：bind 到"所有网卡"
getaddrinfo(nullptr, "5150", &hints, &res);   // 端口用字符串，"5150" 或 "http" 都行

SOCKET listener = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
bind(listener, res->ai_addr, (int)res->ai_addrlen);
listen(listener, SOMAXCONN);          // 挂起连接队列上限（系统合理值）
freeaddrinfo(res);

// ④ 接连接：accept 阻塞到有人来，返回一个"专线"socket
struct sockaddr_in peer = {}; int peerLen = sizeof(peer);
SOCKET client = accept(listener, (sockaddr*)&peer, &peerLen);
// peer 里是对端地址；client 上的收发只跟这一个对端打交道
```

两个老知识点现在有了正解：

- **地址与字节序**：老代码手填 `sockaddr_in`（`sin_addr.s_addr = htonl(INADDR_ANY); sin_port = htons(5150);`）——端口号与 IP 在网络上按**大端**传输，主机若是小端就要 `htons/htonl`（host-to-network short/long）。`getaddrinfo` 把这两步都包了，新代码别再手填；
- **`SOMAXCONN`**：现代 Windows 上它是一个"让系统自己定"的充分大值（约 0x7fffffff），比硬编码 backlog 好。

## 33.4 TCP 客户端：解析 + 连接

```cpp
struct addrinfo hints = {}, *res = nullptr;
hints.ai_family = AF_UNSPEC;          // 不挑 v4/v6，跟服务器有什么连什么
hints.ai_socktype = SOCK_STREAM;
getaddrinfo("127.0.0.1", "5150", &hints, &res);

SOCKET s = INVALID_SOCKET;
for (struct addrinfo* p = res; p; p = p->ai_next) {   // 结果是链表：逐个试
    s = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
    if (s == INVALID_SOCKET) continue;
    if (connect(s, p->ai_addr, (int)p->ai_addrlen) != SOCKET_ERROR) break;
    closesocket(s); s = INVALID_SOCKET;               // 这个地址连不上，试下一个
}
freeaddrinfo(res);
```

`connect` 是三次握手的发起端，成功即建立连接——之后 `send/recv` 不再带地址（跟 accept 返回的专线 socket 对称）。`getaddrinfo("www.example.com", "http", ...)` 同样适用：域名解析 + 端口名解析（"http"=80）一步完成，这是它淘汰 `gethostbyname` 的原因。

## 33.5 收发的完整语义：部分发送、零返回与半关闭

这是 TCP 编程正确性的核心，三条：

1. **`send` 可能只发了一部分**。返回值是"已accepted的字节数"，可能小于请求量（内核发送缓冲区满）。**循环发送**是标准姿势：

```cpp
int SendAll(SOCKET s, const char* buf, int len) {
    int total = 0;
    while (total < len) {
        int n = send(s, buf + total, len - total, 0);
        if (n == SOCKET_ERROR) return SOCKET_ERROR;
        total += n;                    // 可能一次发完，也可能分几趟
    }
    return total;
}
```

2. **`recv` 返回 0 = 对端优雅关闭**（对端调了 `shutdown` 或 `closesocket`），不是错误；`SOCKET_ERROR` 才是（查 `WSAGetLastError`：`WSAECONNRESET` = 对端被强杀/断网）。把 0 当错误处理、或把"没收到请求的字节数"当错误，都是错的——**TCP 是流，没有"消息边界"**，`recv` 一次拿到的可能比一次 `send` 发的多、少或刚好（消息边界要应用层协议自己定：长度前缀或换行符）；
3. **`shutdown` 是"我说完了"，`closesocket` 是"挂机"**。半关闭三态：

```cpp
shutdown(s, SD_SEND);      // 我不再发；但仍可 recv——听对方把话说完
// recv(s, ...) 直到返回 0 —— 等对方也关闭，优雅收尾
closesocket(s);
```

直接 `closesocket` 也能结束，但对方 `recv` 会立即拿到 `WSAECONNRESET`（"异常断开"）而不是 0（"正常关闭"）——想体面，先 `shutdown(SD_SEND)` 再等对方回 0。

## 33.6 UDP：免连接的数据报

```cpp
SOCKET s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
bind(s, ...);                        // 服务器侧仍然要 bind（别人往哪投递）

// 服务器：收报 + 回报，一问一答都要带地址
struct sockaddr_in from = {}; int fromLen = sizeof(from);
char buf[512];
int n = recvfrom(s, buf, sizeof(buf), 0, (sockaddr*)&from, &fromLen);
sendto(s, buf, n, 0, (sockaddr*)&from, fromLen);      // 原路退回

// 客户端：sendto 直发，无需 connect
sendto(s, data, len, 0, (sockaddr*)&serverAddr, sizeof(serverAddr));
int m = recvfrom(s, buf, sizeof(buf), 0, nullptr, nullptr);   // 收回显
```

UDP 是"邮局模型"：一封一封独立投递，**可能丢、可能乱序、可能重复**，换来的是免握手、免连接状态的低延迟——DNS、游戏、直播走这条路。UDP 上"发送失败"很少当场报错（投递尽力而为），可靠性要应用层自己造。一个小冷知识：UDP socket 也能 `connect`——语义不是建立连接，而是"固定默认对端"，之后可以直接 `send/recv` 不带地址，且只收这家的报。

## 33.7 一个线程伺候多个连接：select 与 GUI 集成

**阻塞模型的问题**：`accept`/`recv` 默认堵到天荒地老。一个线程一条连接撑不住真实负载，两条出路：

**出路一：`select` 多路复用**——"盯着一堆 socket，谁就绪告诉谁"：

```cpp
fd_set readfds;
FD_ZERO(&readfds);
FD_SET(listener, &readfds);
FD_SET(udpSock, &readfds);
for (SOCKET c : clients) FD_SET(c, &readfds);

struct timeval tv = { 1, 0 };        // 最多等 1 秒（nullptr = 无限期）
int n = select(0, &readfds, nullptr, nullptr, &tv);
//                ↑ Windows 上首参无意义（历史兼容 Unix 的 nfds），传 0
if (n > 0) {
    if (FD_ISSET(listener, &readfds)) { /* 有新连接：accept */ }
    if (FD_ISSET(udpSock, &readfds))   { /* 有 UDP 报文：recvfrom */ }
    for (SOCKET c : clients)
        if (FD_ISSET(c, &readfds))     { /* 该连接可读：recv */ }
}
```

`fd_set` 本质是位数组，`FD_SETSIZE` 默认 64——要盯更多 socket 得重定义或改用现代模型。select 每轮要重建集合（它是入参出参复用的），这是它被替代的原因，但作为入门模型最直观。配套概念**非阻塞**：`u_long nb = 1; ioctlsocket(s, FIONBIO, &nb);` 把 socket 设为"没数据立即返回 `WSAEWOULDBLOCK`"——`WSAEWOULDBLOCK` 不是错误，是"现在没有，稍后再来"的常态返回。

**出路二：`WSAAsyncSelect`——网络事件变窗口消息**，Win32 的特色发明，与第 4 章的消息循环无缝对接：

```cpp
constexpr UINT WM_SOCKET_NOTIFY = WM_APP + 100;   // 自定义消息（WM_APP 区）

// 网络事件全部投递到 hWnd 的消息队列，socket 自动变为非阻塞
WSAAsyncSelect(listener, hwnd, WM_SOCKET_NOTIFY, FD_ACCEPT | FD_CLOSE);
WSAAsyncSelect(clientSock, hwnd, WM_SOCKET_NOTIFY, FD_READ | FD_WRITE | FD_CLOSE);

case WM_SOCKET_NOTIFY: {
    SOCKET s = (SOCKET)wParam;                     // 哪个 socket
    WORD  err = WSAGETSELECTERROR(lParam);          // 错误（0 = 正常）
    WORD  evt = WSAGETSELECTEVENT(lParam);          // 哪个事件
    if (err) { closesocket(s); return 0; }
    switch (evt) {
    case FD_ACCEPT: { SOCKET c = accept(s, ...); /* 挂上 FD_READ */ } break;
    case FD_READ:   { /* recv——保证不会阻塞（有数据才通知你）*/ } break;
    case FD_CLOSE:  { closesocket(s); } break;
    }
    return 0;
}
```

GUI 程序"边收网络数据边不卡界面"就是这么写的——网络事件与鼠标键盘在同一队列里排队（第 4 章的模型在这里再次兑现）。更高吞吐的正规军是**重叠 I/O + 完成端口（IOCP）**——服务器级编程的地基，超出本教程边界；应用层的现代捷径见第 29 章（C++/WinRT 协程里 `async` 网络调用），概念同源。

## 33.8 本机 IPC 主力：命名管道与邮槽

回到 33.1 的谱系表，补上两个本章才讲的主角。

**命名管道**：可靠双向流，API 长得像"服务器版文件"：

```cpp
// 服务器：创建 + 等客户端来连
HANDLE pipe = CreateNamedPipeW(L"\\\\.\\pipe\\myapp.cmd",
    PIPE_ACCESS_DUPLEX,                            // 双向
    PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
    1,                                             // 最多 1 个实例
    16 * 1024, 16 * 1024, 0, nullptr);
ConnectNamedPipe(pipe, nullptr);                   // 阻塞等客户端（可配 OVERLAPPED）

// 客户端：当文件打开！
HANDLE pipe = CreateFileW(L"\\\\.\\pipe\\myapp.cmd",
    GENERIC_READ | GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0, nullptr);
// 之后两边都是 ReadFile/WriteFile——第 19 章的文件 I/O 原样适用
```

注意这份对称美：**服务器用 `CreateNamedPipe`/`ConnectNamedPipe`，客户端直接 `CreateFile`**，接通后双方统一用文件 API（`ReadFile/WriteFile`，19.4 的读写循环与短读处理原样搬来）。客户端赶上"管道忙"（实例占满）会得到 `ERROR_PIPE_BUSY`，`WaitNamedPipeW` 可限时排队。与 socket 对照：功能上是"本机 TCP + 消息模式可选"，但**它走内核对象体系**——可命名（20.2 的 `Local\`/`Global\` 规则同样适用）、可配 ACL、能被 `DuplicateHandle`；本机服务进程与用户进程对话（如 SCM 与服务进程，第 30 章）走的就是它。

**邮槽（Mailslot）**：单向小数据报，天生一对多广播：

```cpp
// 接收方（一方）
HANDLE slot = CreateMailslotW(L"\\\\.\\mailslot\\myapp.status",
                              0, MAILSLOT_WAIT_FOREVER, nullptr);
// 发送方（可多方）：本机写 \\.\mailslot\...，全网广播写 \\*\mailslot\...
HANDLE w = CreateFileW(L"\\\\*\\mailslot\\myapp.status",
                       GENERIC_WRITE, FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr);
WriteFile(w, msg, len, &written, nullptr);
```

只有接收方"拥有"邮槽；广播报文跨网段不可靠（设计如此，最长 424 字节/封）——适合"状态心跳"类的一对多通知，认真传数据请用管道或 socket。

## 33.9 完整示例：双模式回显服务器

`examples/41_winsock_echo` 把本章串成一条可运行的链路（一个 exe 两种身份，同 38 例的省工程写法）：

- **服务器模式（默认）**：`WSAStartup` → TCP `bind/listen` + UDP `bind`（同端口 5150 双协议）→ **select 循环**同时盯监听 socket、UDP socket 与已接入的 TCP 客户端——新连接 `accept` 入队、TCP 数据原样回显、UDP 报文原路退回、`recv` 返回 0 则收线；
- **客户端模式（`-c`）**：`getaddrinfo("127.0.0.1", ...)` → `connect` → 连发 3 条消息各等回显（`SendAll` 循环发送 + 定界验证）→ `shutdown(SD_SEND)` 后 `recv` 等 0（体会优雅关闭的握手）→ 再发 2 个 UDP 数据报各等回显。

验证方式（本机实测）：

```powershell
./build/41_winsock_echo.exe &          # 后台起服务器
./build/41_winsock_echo.exe -c         # 客户端跑完整链路后退出
taskkill /IM 41_winsock_echo.exe /F    # 收掉服务器
```

实测客户端输出：3 条 TCP 消息回显字节数逐条对上、`shutdown` 后 `recv` 返回 0（"服务器确认关闭"）、2 个 UDP 数据报回显一致——TCP 与 UDP 两条链路在一个 select 循环里同时活着。

## 33.10 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| 编译报 sockaddr 重定义（C2011） | `windows.h` 在 `winsock2.h` 之前 include | 调整顺序或 `WIN32_LEAN_AND_MEAN`（33.2） |
| 链接报 `WSAStartup` 未解析 | 没链 `ws2_32.lib` | `#pragma comment(lib, "ws2_32.lib")` |
| 用 `GetLastError` 查 socket 错误，码不对 | Winsock 用 `WSAGetLastError` | 紧贴失败调用查（33.2） |
| `socket` 失败判 `nullptr` | 判据是 `INVALID_SOCKET` | 按族判据（33.2） |
| 连不上自己刚写的服务器 | `bind` 端口忘 `htons`（老写法）或没 `listen` | 用 `getaddrinfo` + 五步走全（33.3） |
| 大消息偶尔"缺尾巴" | `send` 部分发送没循环 | `SendAll`（33.5） |
| 收到的数据"粘连/半条" | 把 TCP 当消息协议用 | 应用层定界：长度前缀/分隔符（33.5） |
| 对端正常退出却报错收尾 | 直接 `closesocket`，对端见 `WSAECONNRESET` | 先 `shutdown(SD_SEND)` 再等 `recv`=0（33.5） |
| 非阻塞模式下 `WSAEWOULDBLOCK` 当错误 | 它是"现在没有"的常态 | 忽略并稍后重试（33.7） |
| `select` 盯到 64 个就出问题 | `FD_SETSIZE` 默认 64 | 扩容或换 IOCP（33.7） |
| GUI 网络程序"卡在 recv" | 阻塞模型吃掉 UI 线程 | `WSAAsyncSelect` 或工作线程 + `PostMessage`（33.7、17.9） |
| 管道客户端连不上 | 实例占满（`ERROR_PIPE_BUSY`） | 加实例数或 `WaitNamedPipeW`（33.8） |

## 33.11 小结

1. 通信谱系按边界选型：同机共享内存/管道，跨机 socket；命名管道是"本机 TCP"，客户端直接 `CreateFile`、通后走文件 API。
2. Winsock 三纪律：`WSAStartup` 返回值即错误码、`winsock2.h` 在 `windows.h` 前、判据 `INVALID_SOCKET`/`SOCKET_ERROR`；错误查 `WSAGetLastError`。
3. TCP 五步（socket/bind/listen/accept/收发）+ 客户端 `getaddrinfo` 逐个试连；地址与端口交给 `getaddrinfo`，别手填 `htons`。
4. 收发三语义：`send` 可部分（循环发）、`recv`=0 是优雅关闭（不是错）、`shutdown(SD_SEND)` 先于 `closesocket`；TCP 是流，定界自己做。
5. UDP 是数据报：可能丢/乱/重，`sendto/recvfrom` 带地址，`connect` 只是固定对端。
6. 一个线程多条连接：select 多路复用（首参 Windows 传 0）+ 非阻塞；GUI 集成用 `WSAAsyncSelect` 把网络事件变窗口消息；高吞吐上 IOCP。

## 33.12 动手练习

1. 给 41 的回显协议加"长度前缀"定界：消息头 4 字节网络序长度 + 正文，客户端拆包验证——亲手体会"TCP 没有边界"。
2. 把 41 的 TCP 部分改写成 `WSAAsyncSelect` 版 GUI 聊天窗（编辑框输入 + 列表框显示），对照 33.7 的消息模型。
3. 命名管道实验：把 40_copydata 的双实例对话改用命名管道实现（服务器 `CreateNamedPipe` 循环 `ConnectNamedPipe` 接多个客户端），对比两种通道的代码量与阻塞行为。
4. 用 `getaddrinfo(AF_UNSPEC)` 解析一个真实域名（如 `localhost` 或局域网主机名），打印全部返回地址（v4/v6），逐个 `connect` 试到成功。

---

上一章：[32 · 剪贴板与拖放](32-剪贴板与拖放.md) ｜ 下一章：[34 · 部署与分发](34-部署与分发.md) ｜ 返回：[README](../README.md)
