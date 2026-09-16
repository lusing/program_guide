# 12 · 多线程与后台任务

> 对应示例：`examples/11_threads`

## 1. 核心纪律

Windows 的 UI 是单线程亲和的：**创建窗口的线程才能操作它**。worker 线程里直接调 `m_list.SetItemText(...)` 是数据竞争，轻则花屏、重则崩溃，而且复现随机。

MFC 多线程的三条铁律：

1. **凡是可能超过 0.1 秒的计算，挪出 UI 线程**
2. **worker 线程绝不碰控件/窗口对象**——用 `PostMessage` 把结果寄回 UI 线程
3. **线程退出靠它自己**——设标志让它跑完安全点自然返回，绝不 `TerminateThread`（资源、锁、CRT 状态全部悬空）

## 2. AfxBeginThread：worker 线程

MFC 两种线程：**worker 线程**（跑函数）和 **UI 线程**（有自己的消息循环，少见）。99% 的场景是前者：

```cpp
UINT MyThreadProc(LPVOID pParam) {
    auto* self = static_cast<CMyWnd*>(pParam);   // 入参就是 AfxBeginThread 的第二个参数
    return self->DoWork();                        // 返回 0~255
}

CWinThread* pThread = AfxBeginThread(MyThreadProc, this);
```

`AfxBeginThread` 返回 `CWinThread*`，**默认 `m_bAutoDelete = TRUE`**：线程函数返回后 MFC 自动 delete 这个对象。由此得出著名结论：

> 存下这个指针**只用于判断"在不在跑"**，**绝不能手动 delete**，也不能在线程结束后再读（对象可能已经没了）。

要持有线程等它结束，就把 `m_bAutoDelete` 设为 FALSE 自己管理；不持句柄就是最省事的模式（示例 11 的做法）。

## 3. 进度回传：PostMessage 模式

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
PostMessage(WM_APP_PROGRESS, percent, 0);
PostMessage(WM_APP_DONE, found, canceled ? 1 : 0);
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

第 13 章实战项目的统计面板（stats.cpp）是这套模式的完整范本，包括"运行中又来了新请求"的排队处理。

## 4. 取消与收尾

**取消 = 标志位，不是命令**：

```cpp
std::atomic<bool> m_cancel{ false };   // 跨线程标志必须 atomic

// worker 循环里周期性检查
for (...) {
    if (m_cancel) break;               // 安全点
    ...
}

// UI 线程：点取消按钮
m_cancel = true;
```

线程里做循环时**主动留安全点**（每次迭代/每处理一批数据查一次标志）。`atomic<bool>` 或 Windows 事件（`CreateEvent` + `WaitForSingleObject(event, 0)` 查询）都行。

**窗口关闭与线程收尾**：线程里存着 `this` 和 HWND，窗口先死线程后活会踩空。两种做法：

1. 关窗前同步等待（示例 11）：
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

## 5. 跨线程共享数据

| 场景 | 手段 |
|---|---|
| 简单标志（取消/暂停） | `std::atomic<bool>` |
| 一批只读数据 | 提前拷贝快照，worker 只读（第 13 章 shared_ptr<wstring> 快照） |
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

## 6. 常见坑

**worker 线程里创建 MFC 对象**：CString、CWnd 等依赖每线程的 MFC 状态。`AfxBeginThread` 创建的线程会正确初始化（这是它优于裸 `CreateThread` 的地方）；但 worker 里再创建 GDI/CWnd 对象依然受限——控件操作永远回 UI 线程。

**PostMessage 的 LPARAM 指针在接收前失效**：发送后**绝不能**再 delete 或复用那块内存；接收方负责释放。消息被丢弃（窗口已销毁）时内存泄漏——低频路径可接受，高频路径改用环形缓冲/RAII 包裹。

**等线程时死锁**：UI 线程 `WaitForSingleObject(thread, INFINITE)` 时消息循环停了；如果 worker 里用的是 `SendMessage`（不是 Post）给 UI 线程，互相等死。混合等待场景用 `MsgWaitForMultipleObjects`，或干脆改成纯 PostMessage 架构规避。

**线程优先级滥用**：默认优先级足够。调高 worker 优先级抢 UI 线程时间片，界面反而更卡。

## 7. 实战建议

- 把"worker + 进度消息 + 取消标志 + 完成消息"封装成可复用的小框架类，项目里每个后台任务都套同一个壳（第 13 章 stats.cpp 的结构可以直接抄）
- 进度消息别发太密：每 1% 或每 100ms 一条足够，PostMessage 本身有队列成本
- 任务有"最新值才重要"的语义（如统计、搜索预览）时，做"运行中收到新请求先记下，结束后补跑一轮"的合并逻辑，比盲目排队聪明

---
上一章：[11 GDI 绘图](11-gdi.md) ｜ 下一章：[13 实战项目：记事本+](13-notepad-plus.md)
