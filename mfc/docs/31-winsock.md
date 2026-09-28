# 31 · WinSock：CSocket、序列化通道与 UDP

> 对应示例：`examples/31_winsock`

> **本章你将学会**：AfxSocketInit 前置条件、CSocket 阻塞模型的服务端/客户端写法、CSocketFile + CArchive 的“对象上网”通道、UDP 数据报回声。
> **前置知识**：第 17 章的 CArchive、第 20 章的 worker 线程。

《Visual C++ MFC 扩展编程实例》把套接字放在通信章（3.5 节）讲机制、第 13 章实例 51/52 给完整实现——实例 51 是“多应用间通信”的套接字对，实例 52 是全章最惊艳的一手：**用 CArchive 串行化 I/O 套接字**。MFC 的套接字封装到今天没变过，这两条路线依然是标准答案。

## 1. 两层封装与一个前提

```cpp
class CSockApp : public CWinApp {
    BOOL InitInstance() override {
        if (!AfxSocketInit())       // ← 忘了它，CSocket::Create 必失败
            return FALSE;
        ...
    }
};
```

- **CAsyncSocket**：薄封装，事件模型（FD_READ/FD_ACCEPT 回调走窗口消息）——异步、不阻塞，但要自己管理状态机；
- **CSocket**：CAsyncSocket 的阻塞封装——`Accept/Receive/Send` 阻塞直到有事干，代码读起来像伪代码。

教学与中小工具首选 **CSocket**；它唯一的原罪是“阻塞”——把阻塞调用挪进 worker 线程（第 20 章的纪律）就功德圆满。示例 31 的服务端全部跑在 worker 线程里。

## 2. TCP 文本回声：最小可跑对

```cpp
// —— 服务端（worker 线程）——
CSocket listener;
listener.Create(31530);          // 绑定 + 监听一步到位（端口自选避开 1024 以下）
listener.Listen(4);
for (;;) {
    CSocket client;
    if (!listener.Accept(client))       // 阻塞：直到有连接
        break;
    wchar_t buf[256] = {};
    int n;
    while ((n = client.Receive(buf, sizeof(buf) - sizeof(wchar_t))) > 0) {
        CString text(buf, n / sizeof(wchar_t));
        CString echo = _T("回声: ") + text;
        client.Send((LPCWSTR)echo, (int)((echo.GetLength() + 1) * sizeof(wchar_t)));
    }
    client.Close();
}

// —— 客户端 ——
CSocket sock;
sock.Create();                          // 系统分配端口
sock.Connect(_T("127.0.0.1"), 31530);
sock.Send((LPCWSTR)text, bytes);
sock.ShutDown(1);                       // 1 = SD_SEND：半关闭，告诉服务端"我发完了"
sock.Receive(buf, sizeof(buf) - sizeof(wchar_t));
sock.Close();
```

六个要点：

1. **字符串自己定边界**：本例发 `(len+1)*sizeof(wchar_t)` 含结尾零——单发单收不粘包；真实协议要么定长头（长度前缀），要么分隔符，要么就是下一节的 CArchive。
2. **`ShutDown(1)`（SD_SEND）**：发完主动半关闭，服务端的 `Receive` 循环才能收到 0 退出——不发这个，服务端挂着等下一段，客户端挂着等服务端，双双卡死（TCP 的经典死锁）。
3. **服务端串行模型**：Accept → 处理到断开 → 再 Accept。并发要每连接一线程（老书实例 51 的做法）——骨架同第 20 章。
4. **Create/Listen/Accept 的失败都要接**：端口被占（10048）、连接被拒（10061）——WSAGetLastError 拿码，别让异常裸奔。
5. **127.0.0.1 是最好的实验床**：单机自演自收，防火墙都不惊动（示例 31 全程本机回环）。
6. **字节序**：端口与地址交给 API 结构体（Create 的端口参数、Connect 的地址串）处理， historic 的 htonl/htons 只在自己打包协议头时才登场。

## 3. CSocketFile + CArchive：对象上网（实例 52 的招牌）

老书实例 52 的思路一句话：**CSocket 套上 CSocketFile，再架上 CArchive——socket 就长出了 Serialize 的脸**：

```cpp
// 要发的对象：第 17 章的序列化写法原封不动
class CNetMessage : public CObject {
    DECLARE_SERIAL(CNetMessage)
public:
    CString m_from, m_text;
    CTime   m_at;
    void Serialize(CArchive& ar) override {
        if (ar.IsStoring()) ar << m_from << m_text << (int)m_at.GetTime();
        else { int t; ar >> m_from >> m_text >> t; m_at = CTime((time_t)t); }
    }
};
IMPLEMENT_SERIAL(CNetMessage, CObject, 1)

// 服务端（accept 之后）
CSocketFile file(&client);
CArchive arIn(&file, CArchive::load);
CArchive arOut(&file, CArchive::store);
CObject* pRaw = nullptr;
arIn >> pRaw;                        // 连类名带 schema 带字段，从网络上直接长出对象
CNetMessage* pMsg = dynamic_cast<CNetMessage*>(pRaw);

// 客户端
CSocketFile file(&sock);
CArchive arOut(&file, CArchive::store);
arOut << &msg;                       // 对象序列化直通对端
arOut.Flush();                       // ★ 不 Flush 缓冲不走，对端干等
```

美在**协议复用**：第 17 章学的 CArchive 世界（`<<`/`>>` CObject*、schema 版本、CRuntimeClass 反射）零修改搬到网络两端。加字段 = 改 Serialize 一处；两端版本兼容 = schema 门槛（第 17 章的双层版本化直接适用）。

三条专属纪律：

- **arOut.Flush() 是命门**：CArchive 有内部缓冲，不 Flush 数据还在缓冲区里，对端 `arIn >>` 阻塞干等——这是该模式第一大坑。
- **双向就配一对 archive**（一个 load 一个 store 共享同一个 CSocketFile），别复用一个既读又写。
- **CSocketFile 只配 CSocket**（阻塞）；配 CAsyncSocket 是类型不匹配的错配。

## 4. UDP：数据报回声

```cpp
// 服务端
CSocket udp;
udp.Create(31531, SOCK_DGRAM);                 // 第二参数换数据报类型
wchar_t buf[256] = {};
CString fromIp; UINT fromPort = 0;
int n = udp.ReceiveFrom(buf, sizeof(buf) - sizeof(wchar_t), fromIp, fromPort);
udp.SendTo(buf, n, fromPort, fromIp);          // 按来的地址打回去

// 客户端
CSocket udp;
udp.Create(0, SOCK_DGRAM);                     // 0 = 系统分配端口
udp.SendTo((LPCWSTR)text, bytes, PORT_UDP, _T("127.0.0.1"));
udp.Receive(buf, sizeof(buf) - sizeof(wchar_t));
```

UDP 与 TCP 的差别在通道模型：**报文有边界、不保序不保达、无连接**。本地回环之外丢包几乎不存在，跨网就要自己做序号/重传——那是 QUIC/UDT 时代的轮子，别手搓。MFC 层面注意：SOCK_DGRAM 的 Create/`SendTo`/`ReceiveFrom` 与 TCP 版 API 同名不同义，模式别混。

## 5. 事件模型一瞥

CAsyncSocket 的位置（不展开，知道路标即可）：`AsyncSelect(FD_READ | FD_ACCEPT | FD_CLOSE)` 把事件注册到某窗口，事件发生时 `OnReceive/OnAccept/OnClose` 虚函数被调——**回调在 UI 线程**，天然免 PostMessage。代价是状态机复杂（半个连接写一半时又来 OnReceive）。现代取舍：要高并发用完成端口/IOCP（原生或 ASIO），要简单用 CSocket + 线程，中间态 CAsyncSocket 的生态位已经不大。

## 实战建议

- 协议对象做成**值语义的消息类**（字段全 POD/CString + Serialize），别把窗口句柄、指针塞进去——序列化的是数据，不是身份。
- 端口选 49152–65535（动态/私有段），并在文档里登记；产品化加配置项。
- 调网络程序先 `netstat -ano | findstr <端口>` 看占用，再回环测试，最后才跨机——一半的“网络问题”是端口占用和防火墙。
- WSAGetLastError 的码比 GetErrorMessage 直白（10048 端口占用、10061 拒连、10054 对端硬断）——日志里打码不打"失败"俩字。

## 常见坑（实测）

1. **忘了 AfxSocketInit**：`Create` 直接失败，错误还没头绪——MFC 套接字的第一坑，示例 31 在代码里留了大字注释。
2. **arOut 不 Flush**：对端永远等不到数据；发完每条消息就 Flush 一次，形成“消息边界”。
3. **TCP 当有边界通道用**：连发三段当三条收——要么长度前缀，要么用第 3 节的 CArchive（它自带帧化）。
4. **客户端不发 ShutDown**：服务端 Receive 循环不退，连接挂着占资源——单连接教学程序里表现为“第二个请求没响应”。
5. **服务端 Accept 后用 listener 收发**：收发要用 Accept 出来的 client 对象；listener 只管接客。
