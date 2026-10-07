# 32 · UI 线程深入：自有窗口、线程间消息与竞争

> 对应示例：`examples/32_ui_threads`

> **本章你将学会**：CWinThread 派生的 UI 线程（有自己的消息循环、能建窗口）、PostThreadMessage 线程间通信、m_bAutoDelete 所有权与优雅收摊、用竞争实验亲眼看见数据竞争、CMutex/CSingleLock 的修正。
> **前置知识**：第 20 章的 AfxBeginThread 双形态、句柄映射表的线程局部性。

第 20 章把多线程的“worker 形态”讲透了。《Visual C++ MFC 扩展编程实例》第 14 章（实例 53-59）补上了另一半：**用户界面线程**——实例 56 工作线程、实例 57 用户界面线程、实例 58 给用户界面线程发消息、实例 59 线程间数据共享。加上优先级实验，就是本章。

## 1. 两种线程的分野（复习 + 深化）

```cpp
// worker：跑一个函数，函数返回线程就没了
AfxBeginThread(MyProc, pParam);

// UI 线程：跑一个"微型应用"——InitInstance → Run(消息循环) → ExitInstance
AfxBeginThread(RUNTIME_CLASS(CMonitorThread));
```

UI 线程值得存在的理由只有一个：**它能拥有窗口**。窗口的消息分发依赖线程的消息队列——定时器、绘图、输入，全在创建它的线程上运转。经典应用场景：

- 后台“监视器”小窗（独立刷新，不占用主 UI 线程）；
- 多窗口应用里每个文档窗口一个线程（罕见，谨慎）；
- 长任务的**可取消**执行器（窗口提供取消按钮，消息循环保持响应）。

不需要窗口就别用 UI 线程——worker + PostMessage 回传（第 20 章）永远是更简单的答案。

## 2. CMonitorThread：UI 线程的三段式

```cpp
class CMonitorThread : public CWinThread {
    DECLARE_DYNCREATE(CMonitorThread)         // RUNTIME_CLASS 创建需要
public:
    BOOL InitInstance() override {
        if (!m_wnd.Create()) return FALSE;    // 窗口建在本线程
        m_wnd.ShowWindow(SW_SHOW);
        m_wnd.SetTimer(1, 120, nullptr);      // 定时器属于本线程的队列
        if (m_hNotifyWnd)
            ::PostMessage(m_hNotifyWnd, WM_THREAD_TICK, 0, (LPARAM)m_nThreadID);
        return TRUE;                          // → 进入 Run() 的消息循环
    }

    int ExitInstance() override {             // 消息循环退出后到这里
        ...
        return CWinThread::ExitInstance();
    }

    afx_msg void OnThreadTask(WPARAM wParam, LPARAM lParam);   // 线程专属消息

    HWND m_hNotifyWnd = nullptr;              // 弱引用：只借 HWND，绝不存 CWnd*
    CMonitorWnd m_wnd;

    DECLARE_MESSAGE_MAP()
};

IMPLEMENT_DYNCREATE(CMonitorThread, CWinThread)
BEGIN_MESSAGE_MAP(CMonitorThread, CWinThread)
    ON_THREAD_MESSAGE(WM_THREAD_TASK, OnThreadTask)   // ← 线程消息专用宏
END_MESSAGE_MAP()
```

三个结构性要点：

1. **`OnInitInstance` 返回 FALSE 线程立刻退出**——创建失败的出口在这，不在外面判空。
2. 窗口成员 `m_wnd` 是线程对象的成员——生命周期一致（线程退出 → ExitInstance → 析构时窗口早被销毁）。
3. 通知主窗口**只借 HWND**（`m_hNotifyWnd`）：HWND 是进程级有效的，CWnd* 是线程局部的（第 20 章的句柄映射表铁律）。

## 3. PostThreadMessage：对“线程”发消息

```cpp
// 主线程派活
m_pMonitor->PostThreadMessageW(WM_THREAD_TASK, (WPARAM)++m_taskSeq, 0);

// UI 线程接：ON_THREAD_MESSAGE（窗口句柄为 NULL 的消息）
afx_msg void OnThreadTask(WPARAM wParam, LPARAM) { ... }
```

`PostMessage` 发给**窗口**，`PostThreadMessage` 发给**线程本身**（不经过任何窗口）。消息循环把它直接派给线程对象的消息映射——`ON_THREAD_MESSAGE` 是 `ON_MESSAGE` 的线程版。

一个隐藏陷阱：**线程消息没有窗口，消息队列无人过滤**。若 UI 线程的 `Run()` 被重写、或消息发出时线程已退，`PostThreadMessage` 失败（返回 FALSE）——发出后检查返回值（示例 32 的做法），别默认必达。

## 4. 所有权与优雅收摊

`AfxBeginThread(RUNTIME_CLASS(...))` 默认 `m_bAutoDelete = TRUE`：线程退出时对象自删。要 **PostThreadMessage 给它、等它退出、拿它的句柄**，就得自己接管：

```cpp
m_pMonitor = AfxBeginThread(RUNTIME_CLASS(CMonitorThread),
                            THREAD_PRIORITY_NORMAL, 0, CREATE_SUSPENDED);
m_pMonitor->m_bAutoDelete = FALSE;            // 挂起状态下改所有权才安全
static_cast<CMonitorThread*>(m_pMonitor)->m_hNotifyWnd = GetSafeHwnd();
m_pMonitor->ResumeThread();
```

收摊三步（绝不 TerminateThread——第 20 章的死刑条款）：

```cpp
m_pMonitor->PostThreadMessageW(WM_QUIT, 0, 0);        // ① 让消息循环自然退
HANDLE h = m_pMonitor->m_hThread;                     // ② 句柄先抄下来！
DWORD wait = WaitForSingleObject(h, 3000);            //    （对象可能即将自删——虽然我们关了）
if (wait == WAIT_OBJECT_0)
    delete m_pMonitor;                                // ③ m_bAutoDelete=FALSE 的代价：自己收尸
m_pMonitor = nullptr;
```

顺序是命门：**先抄句柄再等**——`m_bAutoDelete=FALSE` 下对象不会自删，但“先存句柄再等再删”的纪律让你在 TRUE/FALSE 两种模式下都不踩悬空。挂起状态改 `m_bAutoDelete`（`CREATE_SUSPENDED` + `ResumeThread`）是唯一安全窗口——跑起来之后再改，对象可能已经自删了。

## 5. 数据竞争：眼见为实

实例 59 的实验设计值得亲手跑一遍（示例 32 的“无锁竞争”按钮）：两个线程对同一计数器各加 100000 次——

```cpp
// 无锁版本：load + store 两步
long v = counter->load();
counter->store(v + 1);
```

期望 200000，实际 13 万上下浮动——**丢了几万次更新**。因为 `counter++`（哪怕是 atomic 的 ++）是三步舞：读、加、写；两个线程交错在“读”和“写”之间，后写的覆盖先写的。

修正（示例 32 的“CMutex 修正”按钮）：

```cpp
CMutex mutex(FALSE, ...);            // 或进程内 CCriticalSection
CSingleLock lock(&mutex, FALSE);
if (lock.Lock()) {
    counter->fetch_add(1);           // 原子操作 + 锁，双保险的教学写法
    lock.Unlock();
}
```

两个认识层次：

1. **原子类型不是锁**：`std::atomic` 保证单操作不可分；`load` 后 `store` 的复合序列照样竞争。要么 `fetch_add` 一招（单操作原子的读改写），要么上锁把序列圈起来。
2. **锁的粒度**：示例锁的是单次自增（教学放大开销）；真实场景锁“业务事务”——一段完整性语义的代码，同时只许一个线程执行。

另一个教学彩蛋：优先级实验（老书实例 55 的“文本优先级”）。同时间窗内 `THREAD_PRIORITY_ABOVE_NORMAL` 与 `THREAD_PRIORITY_NORMAL` 的两个空转计数线程，高者优先级多跑 20-40% 的迭代（机器负载不同数字不同，但方向稳定）。得到的工程直觉：**优先级是调度倾斜，不是吞吐保证**；拉高优先级救不了烂算法，反而容易饿死低优先级线程（Windows 有动态平衡，别赌）。

## 6. 线程安全清单

UI 线程参与的程序，收尾自查：

- [ ] 所有线程的阻塞调用有超时或退出机制（邮槽读超时、管道循环查事件……第 30 章骨架）；
- [ ] 线程对象的访问在退出竞态下安全（先抄句柄再等，`PostThreadMessage` 检查返回值）；
- [ ] 共享数据有锁或无共享（消息传递代替共享——PostMessage 本身就是“无共享”设计）；
- [ ] `ExitInstance` 里不发窗口消息给已可能销毁的目标（主窗口先死 vs 线程先死，两头都要能活）。

## 实战建议

- “UI 线程 + 监视窗”的模板结构（示例 32 的 CMonitorWnd/CMonitorThread）可以直接搬：改窗口内容、改 WM_THREAD_TASK 语义即是新产品。
- 跨线程要“操作主窗口控件”时，别把 CWnd* 递进去——定义应用消息（WM_APP 区间）+ 参数结构（new 出来传、接收方 delete），这是第 20 章套路在 UI 线程上的镜像。
- 调线程问题开 VS 的“线程窗口”（断点命中时看各线程栈）——比 printf 大法快一个数量级。
- `MsgWaitForMultipleObjects`（第 20 章提过）是 UI 线程等待 + 消息两不误的正解，需要“边等边响应”时替代 `WaitForSingleObject`。

## 常见坑（实测）

1. **`ON_THREAD_MESSAGE` 处理函数签名是 `void(WPARAM, LPARAM)`**——写成 LRESULT 版（ON_MESSAGE 的签名）消息映射表 static_cast 编译不过（C2440），报错位置在宏展开处，新手容易看懵。
2. **`CStringList` 没有 `Add`/`operator[]`**——那是 `CStringArray` 的 API；链表版要 `AddTail`/`GetNext` 迭代（示例 32 写动画日志时实测中招）。
3. **`m_bAutoDelete` 在线程跑起来后改**：对象可能已自删，改的是已释放内存——`CREATE_SUSPENDED` 时改完再 Resume。
4. **线程消息 vs 窗口消息混接**：`ON_MESSAGE` 只接窗口消息（有 hwnd），发给线程的消息（hwnd=NULL）它接不到；必须 `ON_THREAD_MESSAGE`。
5. **等线程用对象指针而不是句柄**：`WaitForSingleObject(m_pMonitor->m_hThread)` 里 `m_pMonitor` 若已自删，读 m_hThread 就是读野内存——句柄提前抄下来（第 4 节的顺序纪律）。

---

上一章：[31 WinSock：CSocket、序列化通道与 UDP](31-winsock.md) · 下一章：[33 DLL 编程：普通 / MFC 扩展 / 资源专用](33-dll.md)
