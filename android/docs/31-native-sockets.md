# 24 · POSIX Socket：原生网络

> 对应示例：`compose_examples/app/src/main/cpp/native_sockets.cpp` + `jni/SocketBridge.kt`（Compose 消费层在 `samples/JniSamples.kt`）

## 1. 为什么 native 里还要 socket

先泼冷水（观点）：应用层的网络请求——HTTP API、图片下载——在 Kotlin 侧（第 08 章）做就对了，OkHttp/Retrofit 生态成熟、超时重试签名齐全，native 重写没有收益。native socket 的真实场景是：

- **native 引擎的内部通信**：音视频引擎、代理内核、数据库（SQLite 的本地 socket）这类自带网络栈的库，通信端点天然在 native
- **进程间通信**：与同机的其他进程/服务对接（第 10 章的 aidl 之外，本地 socket 是更底层的选择）
- **移植既有 C/C++ 网络代码**：协议栈现成，不可能用 Kotlin 重写

学它的价值与 JNI 一致：读懂并接得住那个世界，而不是天天手写。

## 2. TCP：完整五连与回环 echo

`socketTcpEcho` 把 TCP 服务器与客户端塞进**同一个 JNI 调用**做回环——教学上这比书里"两个 Activity 各起一个"的版本（原书第 8 章）更省，逻辑一眼读完：

```cpp
// —— 服务器侧三连 ——
int listenFd = socket(AF_INET, SOCK_STREAM, 0);        // ① 造插座
sockaddr_in addr{};
addr.sin_family = AF_INET;
addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);          // 127.0.0.1（注意字节序！）
addr.sin_port = htons((uint16_t) port);                 // 端口必须转网络字节序
bind(listenFd, (sockaddr*)&addr, sizeof(addr));         // ② 绑地址
listen(listenFd, 1);                                    // ③ 开听（backlog=1）

// —— 客户端侧两连 ——
int clientFd = socket(AF_INET, SOCK_STREAM, 0);
connect(clientFd, (sockaddr*)&addr, sizeof(addr));      // ④ 建连（内核经 backlog 完成）
send(clientFd, msg, len, 0);
shutdown(clientFd, SHUT_WR);                            // 关写端 → 服务器读到 EOF

// —— 服务器继续 ——
int serverSide = accept(listenFd, nullptr, nullptr);    // ⑤ 取出已建的连接
std::string echoed = recv_all(serverSide);              //  读到 EOF
send(serverSide, echoed.data(), echoed.size(), 0);      //  弹回去
```

一个值得点破的设计点：**connect 不需要 accept 先发生**——`listen` 之后内核就替未决连接维护 backlog，客户端 `connect` 在那里即可完成，随后 `accept` 把它"取出来"。这正是单线程回环能顺序执行的原因，也是生产环境"accept 循环跟不上"时连接 silently 堆积的机制根源。

三个 TCP 语义要点：

- **字节流不是消息**：`recv` 返回"现在恰好有的一截"，一次 send 可能要多次 recv，多次 send 可能一次 recv 到。按长度前缀或分隔符自己组帧——`recv_all` 靠对端 `shutdown(SHUT_WR)` 的 EOF 才知道读完了，这是 echo 场景的特权
- **主动关写端**是标准的"我说完了"信号（半关闭），比直接 close 温和——对端还能把最后的话说完
- 每个 fd 都是资源，**错误路径也要 close**——本例的 if/else 链虽朴素，保证每条出口都关

## 3. UDP：无连接，数据报自带回信地址

`socketUdpEcho` 同构（原书第 9 章的核心 API）：

```cpp
int serverFd = socket(AF_INET, SOCK_DGRAM, 0);         // SOCK_DGRAM
bind(serverFd, ...);                                    // 服务器仍要绑端口

sendto(clientFd, msg, len, 0, (sockaddr*)&addr, sizeof(addr));   // 发：自带目标地址
ssize_t n = recvfrom(serverFd, buf, sizeof(buf), 0,
                     (sockaddr*)&from, &fromLen);       // 收：连"谁发的"一起给你
sendto(serverFd, buf, n, 0, (sockaddr*)&from, fromLen); // 回：照回信地址弹回
```

与 TCP 的语义差异一张表：

| | TCP（SOCK_STREAM） | UDP（SOCK_DGRAM） |
|---|---|---|
| 连接 | connect/accept 建连 | 无连接，每个包独立寻址 |
| 边界 | 字节流，无消息边界 | 数据报保边界：一次 sendto 一次 recvfrom |
| 可靠 | 重传/排序内建 | 丢、乱序、重复都可能 |
| 对端地址 | connect 时定死 | 每包携带，`recvfrom` 取出 |
| 适合 | 请求响应、文件传输 | 探测、心跳、流媒体、广播 |

UDP 的"保边界"是唯一免费送的东西：**发送次序与内容本身没有任何保证**。协议层要的确认与重传，自己加。

## 4. UNIX domain socket：同机 IPC 的正解

跨网络用 AF_INET，**同机两个端点**用 AF_UNIX（原书第 10 章）——不走网络协议栈，无校验和、无路由，快且安全（文件系统权限就是访问控制）：

```cpp
int fd = socket(AF_UNIX, SOCK_STREAM, 0);
sockaddr_un addr{};
addr.sun_family = AF_UNIX;
strncpy(addr.sun_path, pathChars, sizeof(addr.sun_path) - 1);   // 绑到文件系统路径
bind(fd, (sockaddr*)&addr, sizeof(addr));
```

两个 Android 特色认知：

- **路径从 Kotlin 侧传**（本例 `filesDir/guide.sock`）：应用沙箱内的路径天然受权限保护。绑文件系统路径前先 `unlink` 残留（否则 `EADDRINUSE`），用完再 `unlink`——socket 文件不会随连接消失自动清理
- **abstract namespace**：Linux 扩展，`sun_path[0] = '\0'` 时名字不落盘（原书 10.3.2 有专节）。优点是自动随进程消失而清理；Android 内部大量使用，应用间对接也可以用——代价是没有文件权限这道闸

选型：跨设备 → TCP；同机跨进程 → UNIX domain；同进程内 → 它俩都别用（直接函数调用或第 28 章的 JNI）。

## 5. 字节序：htons/htonl 不是仪式

网络字节序规定为大端，ARM/x86 都是小端——**端口与 IP 每次跨界都要转**：

```cpp
addr.sin_port = htons(48777);              // host to network short
addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);   // host to network long
// 读回来：ntohs / ntohl
```

忘转的症状极具迷惑性：连"48777 端口"实际绑到了另一个数，连不上、也查不到谁占着。`htons` 拼错的成本是几小时，不是编译错误。

## 6. 异步 I/O 一瞥

阻塞模型（本章）一次只能等一个 fd。原书 10.6 介绍的多路复用，2026 年的坐标：

| 机制 | 年代 | 现状 |
|---|---|---|
| `select`/`FD_SET` | 书中示例所用 | 老 POSIX，fd 数量受限（1024），教学遗留 |
| `poll` | 书中顺带 | 无 fd 数限制，每次调用仍全量拷贝 |
| `epoll`（Linux） | 2002+ | **现役**：内核维护注册表，O(就绪数)；Android 同属 Linux |
| io_uring | 2019+ | NDK 未稳定暴露，应用层可忽略 |

Android 上写事件循环用 `epoll_create`/`epoll_ctl`/`epoll_wait`——这正是 Looper（第 08 章）底层用的同一机制。回调风 异步 I/O（原书的 `aio` 系列）在 Android 上从未流行，别投入。

另一个老坑的当代对照：**主线程网络禁令**对 native 同样生效——Java 层的 `NetworkOnMainThreadException` 只是 Framework 的检查器，native 在主线程 `recv` 阻塞不会抛异常，直接 ANR（第 04 章）。网络调用进工作线程/协程这条纪律，不豁免 C 代码。

## 7. 常见坑

**忘 htons/htonl**：第 5 节。端口/IP 的每一次 struct 填写都要过一遍。

**阻塞 recv 无超时**：对端不说再见，线程永远睡在 recv 里。加 `SO_RCVTIMEO` 或用 epoll 带超时——"永远等"不是策略。

**错误路径漏 close**：socket 是 fd，泄漏不是玄学。goto-cleanup 或 RAII 封装（析构里 close），选一样。

**把 TCP 当消息读**：`recv` 返回值只是"这次拿到多少"，当"一条完整消息"解析就是埋雷。先定帧（长度前缀最简单）再解析。

**UNIX socket 残留文件**：上次崩了没 unlink，这次 bind 报 EADDRINUSE。绑前 unlink、用后 unlink 养成双保险。

**主线程网络**：第 6 节。ANR 五秒线不认语言。

**本机测试连"localhost"解析都不需要**：`INADDR_LOOPBACK` 直接给数值，省一次 DNS；要连真主机才用 `inet_pton`/`getaddrinfo`。

## 8. 实战建议

- 应用层 HTTP 需求留在 Kotlin（第 08 章）；native socket 只为对接 native 引擎/本地服务/移植代码
- 协议帧格式先行：长度前缀 + 版本号，两侧（native 与对端）同一份文档定义
- fd 生命周期用 RAII 收口（`std::unique_ptr` 自定义 deleter 或薄包装类），错误路径自动 close
- socket 错误一律 `strerror(errno)` 进日志（本例的 `errno_text`），裸错误号对排障毫无帮助
- 监听端口传 0 让内核分配（`bind` 后 `getsockname` 查实际端口）——测试代码少一个"端口冲突"变量；固定端口留给正式服务
- 下一章是原生线最后一站：图形、音频与 NEON 性能——下潜的终点与"先测量"的最后提醒

---

上一章：[30 原生线程与同步](30-native-threads.md) ｜ 下一章：[32 原生图形、音频与性能](32-native-media-perf.md) ｜ 返回：[README](../README.md)
