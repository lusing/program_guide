# 20 · 多线程与后台任务

> 对应示例：`examples/20_threads`

> **本章你将学会**：`AfxBeginThread` 两种形态与 `m_bAutoDelete` 的所有权含义、为什么 MFC 对象不能跨线程用、以及"worker 线程 + 进度消息 + 取消标志"的标准闭环。
> **前置知识**：第 03 章的消息映射、第 09 章的自绘控件。

## 1. 核心纪律

Windows 的 UI 是单线程亲和的：**创建窗口的线程才能操作它**。worker 线程里直接调 `m_list.SetItemText(...)` 是数据竞争，轻则花屏、重则崩溃，而且复现随机。

MFC 多线程的三条铁律：

1. **凡是可能超过 0.1 秒的计算，挪出 UI 线程**
2. **worker 线程绝不碰控件/窗口对象**——用 `PostMessage` 把结果寄回 UI 线程
3. **线程退出靠它自己**——设标志让它跑完安全点自然返回，绝不 `TerminateThread`（资源、锁、CRT 状态全部悬空）

## 2. CWinThread 与 AfxBeginThread

MFC 两种线程：**worker 线程**（跑一个函数）和 **UI 线程**（有自己的消息循环，能创建窗口——第 09 章的浮动工具窗那种需求，实际很少见）。`AfxBeginThread` 相应有两个重载：

```cpp
// 形态一：worker 线程 —— 传函数指针 + 参数
UINT MyThreadProc(LPVOID pParam);                       // 固定签名
CWinThread* pThread = AfxBeginThread(MyThreadProc, this);

// 形态二：UI 线程 —— 传 CRuntimeClass*，框架反射创建 CWinThread 派生类
// （该类要重写 InitInstance，跑消息循环）
CWinThread* pUi = AfxBeginThread(RUNTIME_CLASS(CMyUiThread));
```

99% 的场景是 worker。线程函数收到的 `pParam` 就是 `AfxBeginThread` 的第二个参数，**传什么完全由你约定**——单值直接传；要传一组数据就 new 一个结构体，并事先说好归谁释放：

```cpp
struct ScanJob {                          // 参数包：一次扫描的输入 + 回传通道
    HWND   hNotify;                       // 往哪个窗口 PostMessage
    CStringList* pFiles;                  // worker 拥有，用完自己 delete
};

UINT ScanProc(LPVOID pParam) {
    std::unique_ptr<ScanJob> job(static_cast<ScanJob*>(pParam));  // 约定：worker 负责
    // ...干活、PostMessage(job->hNotify, ...)...
    return 0;
}
```

返回值 `UINT`（0~255 语义）几乎不用——结果一律走消息，返回值只表示"跑完没异常"。

`AfxBeginThread` 返回 `CWinThread*`，**默认 `m_bAutoDelete = TRUE`**：线程函数返回后 MFC 自动 delete 这个对象。由此得出著名结论：

> 存下这个指针**只用于判断"在不在跑"**，**绝不能手动 delete**，也不能在线程结束后再读（对象可能已经没了）。

要持有线程等它结束，就把 `m_bAutoDelete` 设为 FALSE 自己管理（结束时 `delete` 或等句柄后释放）；不持句柄、靠消息感知结束是最省事的模式（示例 20 的做法）。

## 3. 线程与 MFC 对象的边界

MFC 有一层"线程局部"的基础设施，这是很多跨线程事故的根源：

- **句柄映射表是每线程一份**——`CWnd*` 和 `HWND` 的对应关系（永久表/临时表）存在线程局部存储里。A 线程拿到的 `CWnd*`，到 B 线程去用，轻则查不到映射返回垃圾，重则两个线程同时操作同一份内部状态
- **`CWinThread` 对象本身也是线程私有视图**——每个 MFC 线程有自己的 `CWinThread`（`AfxGetThread()` 返回"当前线程"那个）

所以边界画在这里：

| 操作 | worker 里行不行 |
|---|---|
| `pWnd->SetWindowText(...)` 等一切 CWnd 成员 | **不行**——不是"慢"，是数据竞争，可能崩 |
| `CString`、`CArray` 等纯数据 MFC 类 | 可以（不碰句柄映射），但别跨线程共享同一实例 |
| `AfxGetApp()` | 可以——返回的是全局唯一的 `theApp`，进程级共享 |
| 操纵界面（任何形式） | 只能 `PostMessage`/`SendMessage` 把请求寄回创建窗口的线程 |

```cpp
// worker 线程的正确姿势：只拿 HWND（裸句柄全局有效），不碰 CWnd*
PostMessage(job->hNotify, WM_APP_PROGRESS, percent, 0);
```

记法：**`HWND` 是进程级身份证，`CWnd*` 是线程内部通讯录里的条目**。跨线程只递身份证，到了对方线程再凭身份证办事（消息处理函数里 `CWnd::FromHandle` 或直接用成员）。

## 4. 进度回传：PostMessage 模式

worker 线程向 UI 线程汇报的全部手段就是一条自定义消息：

```cpp
// 定义（WM_APP 区间）
#define WM_APP_PROGRESS (WM_APP + 1)
#define WM_APP_DONE     (WM_APP + 2)

// UI 线程：接收端
ON_MESSAGE(WM_APP_PROGRESS, OnProgress)
ON_MESSAGE(WM_APP_DONE, OnDone)

afx_msg LRESULT OnProgress(WPARAM wParam, LPARAM) {
    m_progress.SetPos((int)wParam);     // 这里是 UI 线程，随便碰控件
    return 0;
}
```

```cpp
// worker 线程：发送端
PostMessage(job->hNotify, WM_APP_PROGRESS, percent, 0);
PostMessage(job->hNotify, WM_APP_DONE, found, canceled ? 1 : 0);
```

为什么不用 `SendMessage`：它跨线程时是同步的——worker 会**等 UI 线程处理完**，如果 UI 线程又在等 worker 的下一个数据，就死锁。**一律 PostMessage**（异步，投递即返回）。

传复杂结果：消息参数只能带 32/64 位值，堆对象用指针：

```cpp
// worker：new 出来，指针塞进 LPARAM
auto* result = new StatsResult{...};
PostMessage(hwnd, WM_APP_STATS_DONE, 0, (LPARAM)result);

// UI 线程：接管并 delete
std::unique_ptr<StatsResult> r(reinterpret_cast<StatsResult*>(lParam));
```

第 25 章实战项目的统计面板（stats.cpp）是这套模式的完整范本，包括"运行中又来了新请求"的排队处理。

## 5. 取消与进度回传的完整闭环

把三样东西装进同一个窗口类，就是后台任务的标准壳：

```text
┌─ UI 线程 ─────────────────────────────────────────────┐
│  "开始"按钮 ──► new ScanJob{hNotify, 数据快照}          │
│                 AfxBeginThread(ScanProc, job)          │
│  "取消"按钮 ──► m_cancel = true                        │
│  OnProgress ──► m_progress.SetPos()    ← PostMessage   │
│  OnDone     ──► 收尾/清状态/允许再点开始 ← PostMessage  │
└───────────────────────────────────────────────────────┘
         ▲ PostMessage（异步，不阻塞）   │ 作业参数
         │                              ▼
┌─ worker 线程 ─────────────────────────────────────────┐
│  for each 项:                                          │
│      if (m_cancel) break;      ← 周期性安全点           │
│      干活 → PostMessage(WM_APP_PROGRESS, i)            │
│  PostMessage(WM_APP_DONE, ...)                         │
└───────────────────────────────────────────────────────┘
```

取消是标志位，不是命令：

```cpp
std::atomic<bool> m_cancel{ false };   // 跨线程标志必须 atomic

// worker 循环里周期性检查
for (...) {
    if (m_cancel) break;               // 安全点
    ...
}
```

线程里做循环时**主动留安全点**（每次迭代/每处理一批数据查一次标志）。`atomic<bool>` 或 Windows 事件（`CreateEvent` + `WaitForSingleObject(event, 0)` 查询）都行。

**窗口关闭与线程收尾**：线程里存着 `this` 和 HWND，窗口先死线程后活会踩空。两种做法：

1. 关窗前同步等待（示例 20）：
   ```cpp
   afx_msg void OnClose() {
       if (m_thread) {
           if (询问用户 != 同意) return;
           m_cancel = true;
           WaitForSingleObject(m_doneEvent, INFINITE);  // worker 结束前 SetEvent
       }
       CFrameWnd::OnClose();
   }
   ```
2. worker 里每次 PostMessage 前判 `GetSafeHwnd()`（非空才发），配合"通知式"收尾，窗口死了消息自然没人收

## 6. 跨线程共享数据

| 场景 | 手段 |
|---|---|
| 简单标志（取消/暂停） | `std::atomic<bool>` |
| 一批只读数据 | 提前拷贝快照，worker 只读（第 25 章 shared_ptr<wstring> 快照） |
| 复杂共享状态 | `CRITICAL_SECTION`（MFC 封装 `CCriticalSection`）+ `CSingleLock` |
| 线程间唤醒 | Windows 事件 `CEvent` / `WaitForSingleObject` |

```cpp
CCriticalSection m_cs;
...
CSingleLock lock(&m_cs, TRUE);   // 构造即加锁
// 临界区代码
lock.Unlock();                   // 或等作用域结束自动解锁
```

锁的纪律：**粒度小、持有短、层次固定**（A 持有锁 a 时绝不取锁 b，反向亦然），就不会死锁。

## 7. 常见坑

1. **worker 线程里直接 `SetWindowText`/碰控件**
   句柄映射表是每线程一份，跨线程用 `CWnd*` 是数据竞争——偶发崩溃或界面不更新，且难以复现。任何界面操作都 `PostMessage` 回 UI 线程。

2. **`PostMessage` 传了栈上对象的指针**
   消息还在队列里排队，发送方的栈帧已经退掉——接收方读到悬空指针。跨线程传数据只有两条路：堆分配（接收方负责释放）或者干脆只传值。

3. **`m_bAutoDelete = TRUE` 时又手动 `delete` 线程对象**
   MFC 在线程函数返回后自动 delete，你再 delete 就是双重释放。要自己管就先把它设成 FALSE，二选一。

4. **退出时不等 worker 结束**
   主窗口销毁、进程退出时 worker 还在跑——它存着的 `this`/HWND 全成悬空，PostMessage 发向死窗口，资源泄漏或退出时崩溃。`OnClose` 里设取消 + 等待完成事件（见第 5 节）。

5. **worker 里创建 MFC 对象**
   `CString`、`CArray` 等纯数据类没问题（这也是 `AfxBeginThread` 优于裸 `CreateThread` 的地方——它会正确初始化每线程的 MFC 状态）；但 GDI/CWnd 对象依然受限，控件操作永远回 UI 线程。

6. **等线程时死锁**
   UI 线程 `WaitForSingleObject(thread, INFINITE)` 时消息循环停了；如果 worker 里用的是 `SendMessage`（不是 Post）给 UI 线程，互相等死。混合等待场景用 `MsgWaitForMultipleObjects`，或干脆改成纯 PostMessage 架构规避。

7. **线程优先级滥用**
   默认优先级足够。调高 worker 优先级抢 UI 线程时间片，界面反而更卡。

## 8. 实战建议

- 把"worker + 进度消息 + 取消标志 + 完成消息"封装成可复用的小框架类，项目里每个后台任务都套同一个壳（第 25 章 stats.cpp 的结构可以直接抄）
- 进度消息别发太密：每 1% 或每 100ms 一条足够，PostMessage 本身有队列成本
- 任务有"最新值才重要"的语义（如统计、搜索预览）时，做"运行中收到新请求先记下，结束后补跑一轮"的合并逻辑，比盲目排队聪明
- worker 的输入尽量做成**不可变快照**（拷一份或 shared_ptr 只读），省掉整条锁的战线；锁只留给真正可变的共享状态

## 自测

1. **`AfxBeginThread` 两个重载分别创建什么线程？worker 线程函数的签名是什么？**
   —— 传函数指针创建 worker 线程（`UINT Func(LPVOID)`，第二参数原样传给函数）；传 `CRuntimeClass*` 创建 UI 线程（`CWinThread` 派生类，自带消息循环，少见）。

2. **`m_bAutoDelete` 默认值是什么？由此得出什么使用纪律？**
   —— 默认 TRUE：线程函数返回后 MFC 自动 delete `CWinThread` 对象。所以返回的指针只用来判断"在不在跑"，绝不能手动 delete，也不能在线程结束后再解引用；要持句柄等待就设 FALSE 自己管理。

3. **为什么 worker 线程不能碰 `CWnd*`，却可以 `PostMessage(hwnd, ...)`？**
   —— MFC 的句柄↔对象映射表是每线程一份，`CWnd*` 只在创建线程有效；`HWND` 是进程级裸句柄，任何线程都能拿来投递消息。界面操作全部回 UI 线程执行。

4. **取消一个后台任务的标准做法是什么？**
   —— UI 线程置 `std::atomic<bool>` 取消标志；worker 在循环里周期性检查（安全点）自行 break 返回。不是命令式掐断，也绝不用 `TerminateThread`。

5. **`PostMessage` 传指针和 `SendMessage` 跨线程各有什么风险？**
   —— PostMessage 传栈上指针会悬空（队列未处理、栈帧已退），要传堆对象并约定接收方释放；SendMessage 跨线程是同步的，UI 线程若在等 worker 就互相等死。所以结果回传一律 PostMessage。

---
上一章：[19 打印与打印预览](19-printing.md) ｜ 下一章：[21 调试与诊断](21-debugging.md)
