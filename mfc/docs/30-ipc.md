# 30 · 进程间通信：WM_COPYDATA、邮槽、命名管道、共享内存

> 对应示例：`examples/30_ipc`

> **本章你将学会**：四种 IPC 通道的机制与选型、跨进程的命名约定（内核对象命名空间）、共享内存 + 命名互斥体的正确组合、以及“服务端跑 worker 线程 + PostMessage 回传”的 IPC 程序骨架。
> **前置知识**：第 20 章的 worker 线程与 PostMessage 回传、第 12 章的剪贴板。

《Visual C++ MFC 扩展编程实例》第 3 章把 Windows 的通信方式摆成一桌：剪贴板、DDE、邮槽（mailslot）、Windows 套接字、命名/匿名管道、Internet（WinInet）、命名共享内存、文件映射、客户机/服务器模型。DDE 已是博物馆展品，Internet/套接字单独立章（第 31 章），剩下的本地 IPC 四件套就是本章——按“数据量、方向、是否要同步”选型：

| 通道 | 方向 | 数据量 | 同步性 | 一句话定位 |
|---|---|---|---|---|
| WM_COPYDATA | 单向/次 | 小～中（建议 <64KB） | 同步 SendMessage | 求人办事：系统代拷一次 |
| 邮槽 mailslot | 单向广播 | 小（报文 ≤64KB） | 异步 fire-and-forget | 广播站：一写多读 |
| 命名管道 | 双向流 | 任意 | 阻塞/重叠可选 | 电话线：稳定可靠可跨机 |
| 共享内存 | 双向 | 大 | 无（自带同步要配锁） | 白板：最快，纪律自负 |

## 1. WM_COPYDATA：最简单的跨进程搬内存

`SendMessage(WM_COPYDATA)` 的特别之处：**系统在内核里替接收方映射你的缓冲区**，接收方在处理期间能安全读——平时跨进程传指针毫无意义（地址空间隔离），COPYDATASTRUCT 是官方例外：

```cpp
COPYDATASTRUCT cds = {};
cds.dwData = 0x49504330;                    // 'IPC0'：先验戳
cds.cbData = (DWORD)((text.GetLength() + 1) * sizeof(wchar_t));
cds.lpData = (PVOID)(LPCTSTR)text;
::SendMessageTimeoutW(hwndOther, WM_COPYDATA,
                      (WPARAM)GetSafeHwnd(), (LPARAM)&cds,
                      SMTO_BLOCK, 800, nullptr);
```

接收端：

```cpp
afx_msg BOOL OnCopyData(CWnd* pFrom, COPYDATASTRUCT* pcd) {
    if (pcd->dwData != 0x49504330)
        return FALSE;                        // 戳不对：拒收，绝不碰 lpData
    CString text((const wchar_t*)pcd->lpData, pcd->cbData / sizeof(wchar_t) - 1);
    return TRUE;
}
```

四条纪律（老书“数据调用”一节强调的都在这）：

1. **接收方只读 lpData，且只在处理函数内有效**——函数返回后系统解除映射。要留着用就拷贝。
2. **dwData 当协议戳/版本号**：陌生发送方、恶意构造的包，先验戳再动数据。
3. **同步语义**：SendMessage 会阻塞发送方直到接收方处理完——用 `SendMessageTimeout` 兜底（示例 30 用 800ms），防对方消息循环卡死拖死你。
4. **消息只能发给窗口**：找目标窗口是前置问题（`FindWindow`/`EnumWindows` 按类名+标题过滤，示例 30 的做法）。

## 2. 邮槽：单向广播

邮槽像电台：**一个服务端创建、多个客户端写**，报文小、不保序、不保达（像 UDP 的本地版）：

```cpp
// 服务端（worker 线程里）
HANDLE slot = CreateMailslotW(L"\\\\.\\mailslot\\mfc_guide_30", 0, 2000, nullptr);
// 2 秒读超时：让循环有机会查“退出”事件
for (;;) {
    DWORD msgCount = 0;
    GetMailslotInfo(slot, nullptr, nullptr, &msgCount, nullptr);
    if (msgCount == 0) { if (退出) break; continue; }
    wchar_t buf[256] = {};
    DWORD br = 0;
    ReadFile(slot, buf, sizeof(buf) - sizeof(wchar_t), &br, nullptr);
    // ...回传 UI...
}

// 客户端：像打开文件一样写
HANDLE h = CreateFileW(L"\\\\.\\mailslot\\mfc_guide_30", GENERIC_WRITE,
                       FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr);
WriteFile(h, text, bytes, &written, nullptr);
CloseHandle(h);
```

要点：

- 名字 `\\.\mailslot\<名字>` 只在**本机域名**下；跨网段的邮槽要 `\\<域名>\mailslot\...`（今天的网络环境基本别指望了，当本地广播用）。
- 服务端读超时（CreateMailslot 第 3 参）是**线程退出机制的关键**：ReadFile 无限阻塞的线程没法优雅收摊。
- 报文是“整条”的：一次 WriteFile 一次 ReadFile，没有流的概念。

适用：状态心跳、日志汇聚、单实例通知第二实例退出（第 13 章单实例的通信面）。不适用：要确认送达的任何场景。

## 3. 命名管道：可靠的流

管道是老书第 11 章实例 38-40 的主角（匿名管道/命名管道）。命名管道双向、可跨机、有消息模式——本地 IPC 的“重武器”：

```cpp
// 服务端：一问一答的 echo（worker 线程里，示例 30 的完整版）
HANDLE pipe = CreateNamedPipeW(L"\\\\.\\pipe\\mfc_guide_30",
                               PIPE_ACCESS_DUPLEX,
                               PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
                               1,               // 单实例：串行接待
                               4096, 4096, 0, nullptr);
ConnectNamedPipe(pipe, nullptr);       // 阻塞等客户端
ReadFile(pipe, ...); WriteFile(pipe, ...);   // 消息模式：一条一条收发
DisconnectNamedPipe(pipe);
CloseHandle(pipe);

// 客户端
HANDLE h = CreateFileW(L"\\\\.\\pipe\\mfc_guide_30", GENERIC_READ | GENERIC_WRITE,
                       0, nullptr, OPEN_EXISTING, 0, nullptr);
DWORD mode = PIPE_READMODE_MESSAGE;
SetNamedPipeHandleState(h, &mode, nullptr, nullptr);
```

要点：

- `PIPE_TYPE_MESSAGE + PIPE_READMODE_MESSAGE`：按消息收发（有边界）；默认流模式（像 TCP，要自己切包）。
- `CreateNamedPipe` 的实例数 1 + 循环 `ConnectNamedPipe` = **串行服务器**：一次服务一个客户端，处理完再来。并发服务要多实例 + 每连接一线程（或 OVERLAPPED + 完成端口——超出了老书的年代，现代原生代码的主流做法）。
- 客户端连不上（服务端没起）`CreateFile` 直接失败——错误码 231（管道忙）时可以 `WaitNamedPipe` 重试。
- 匿名管道（`CreatePipe`）只能父子进程间传句柄用，场景窄，示例不展开。

## 4. 共享内存 + 文件映射 + 命名互斥体：最快的通道

两块金牌组合（老书 3.10/3.11 两节）：

```cpp
// 同一块内存，两个进程各自拿到视图 —— “文件映射到 INVALID_HANDLE_VALUE”
HANDLE map = CreateFileMappingW(INVALID_HANDLE_VALUE, nullptr, PAGE_READWRITE,
                                0, sizeof(ShmBlock), L"Local\\mfc_guide_30_shm");
bool first = GetLastError() != ERROR_ALREADY_EXISTS;   // 第二个进程拿到的是同一块
ShmBlock* blk = (ShmBlock*)MapViewOfFile(map, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(ShmBlock));

// 命名互斥体：跨进程的锁（两个进程拿到的是同一个内核对象）
CMutex mutex(FALSE, L"Local\\mfc_guide_30_mutex");
CSingleLock lock(&mutex, FALSE);
if (lock.Lock(2000)) {          // 限时加锁：对方崩了也不至于卡死 UI
    // ...读写 blk...
    lock.Unlock();
}
```

三条纪律：

1. **结构定版本**：共享内存裸字节起步，头部放 magic + size + seq（示例 30 的 ShmBlock 有 `seq` 计数——读端能看出对方还在不在写）。
2. **锁是必须的**，不是可选的——“我这边只有主线程写”不构成免锁理由，对面进程有它自己的线程模型。
3. **限时加锁**（`Lock(2000)`）：跨进程的持锁方可能死、可能卡，无限等 = 你的 UI 也冻住。

命名空间的坑：`Local\` 前缀 = 每会话独立（同机多用户安全）；`Global\` = 全系统（服务与桌面会话互通，需要权限）。裸名字（无前缀）在服务/会话混用时行为微妙——**显式写前缀**是卫生习惯。

## 5. 选型与骨架

把四个通道组装成一个程序的骨架（示例 30 的做法）：

- **服务端都跑 worker 线程**（第 20 章的 AfxBeginThread/CreateThread + `PostMessage(WM_APP+N)` 回传日志）——阻塞调用绝不进 UI 线程；
- **名字集中定义**（文件顶部 const 字符串数组）：通道名是协议的一部分，散落各处必改漂移；
- **WM_QUIT/事件收摊**：邮槽靠读超时、管道靠循环间检查停止事件、线程退出前 `WaitForSingleObject` 等一下。

选型口诀：**小消息找窗口（COPYDATA）、广播用邮槽、要可靠上管道、大数据共享内存**。真实系统常常是组合：管道做控制通道、共享内存做数据面（这也是老书“客户机/服务器”一节的架构思想）。

## 实战建议

- 调 IPC 程序的标配：两个实例对着跑 + 各自日志窗口（示例 30 的编辑框就是为此准备的）。
- 内核对象名带产品前缀 + 版本（`Local\MyApp4\…`），避免和别的软件撞名——撞了不报错，行为诡异。
- WM_COPYDATA 的目标窗口查找别用裸 `FindWindow(nullptr, "标题")`——标题一改就失联；窗口属性（`SetProp`/`GetProp` 放 GUID）或注册消息（`RegisterWindowMessage`）做身份标识更稳。
- 权限：默认内核对象跨会话可见性受 DACL 限制；提权进程与非提权进程互通需要 `SetSecurityInfo` 放宽（先把架构改成不需要再说）。

## 常见坑（实测）

1. **枚举窗口时 `GetWindowTextW` 调到了成员函数**：CWnd 有同名成员（参数不同），lambda 回调里要写 `::GetWindowTextW(hwnd, ...)`——编译错还算幸运，编译过的重载解析错更隐蔽。
2. **邮槽服务端无限阻塞**：`ReadFile` 没超时（CreateMailslot 第三参给了 0）+ 线程永不退出；给 1-2 秒超时并在循环里查停止事件。
3. **共享内存读了刚写的值，以为通了**：单进程自测不算数——第二个进程、另一份 exe 才是真考验（命名对象在单进程里“碰巧”都指向同一份）。
4. **管道消息模式下用流式读取**：`PIPE_READMODE_BYTE` 读 `PIPE_TYPE_MESSAGE` 写的数据，边界全糊——两端模式要配对。
5. **`Local\` 前缀缺失**：管理员/普通用户两个实例互相看不见对方的命名对象——一个是会话命名空间一个是全局，"明明在同机却连不上”。
