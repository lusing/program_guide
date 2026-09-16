# 03 · 消息映射机制

> 对应示例：`examples/02_message_map`

## 1. 为什么需要消息映射

纯 Win32 写窗口是这样的：

```cpp
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_PAINT:   ...; return 0;
    case WM_CHAR:    ...; return 0;
    case WM_SIZE:    ...; return DefWindowProc(...);
    ...
    case WM_USER + 1: ...; return 0;
    default: return DefWindowProc(...);
    }
}
```

一个中型程序的 WndProc 有几千行 switch。MFC 的消息映射把 switch 变成**声明式的表**：

```cpp
BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_PAINT()
    ON_WM_LBUTTONDOWN()
    ON_WM_CHAR()
    ON_MESSAGE(WM_APP_TICK, OnAppTick)
END_MESSAGE_MAP()
```

## 2. 宏展开原理（不需要会写，需要能看懂）

所有消息映射宏最终都展开成一张**静态表 + 一个覆盖版 `WindowProc`**：

```cpp
// 概念等价物
const AFX_MSGMAP_ENTRY CMainWindow::_messageEntries[] = {
    { WM_PAINT,      0, 0, 0, AfxSig_vv,     (AFX_PMSG)&OnPaint    },
    { WM_LBUTTONDOWN,0, 0, 0, AfxSig_vwp,    (AFX_PMSG)&OnLButtonDown },
    { WM_APP_TICK,   0, 0, 0, AfxSig_lwl,    (AFX_PMSG)&OnAppTick  },
    { 0, 0, 0, 0, AfxSig_end, nullptr }   // 结束标记
};
const AFX_MSGMAP* CMainWindow::GetMessageMap() const {
    return &CMainWindow::_messageEntries;   // 运行期也可查询
}
```

`GetMessageMap` 的链式查找是理解**命令路由**的钥匙：先查自己的表，没有就沿基类链（`CMainWindow → CFrameWnd → CWnd → CCmdTarget`）向上找。所以 `ON_WM_PAINT()` 这类宏你不需要写进自己的类——基类的表里已经有对应关系，派生类只需覆盖同名的 `afx_msg` 函数。

`afx_msg` 本身是个**空宏**，只是给人类标注"这是消息处理函数"。参数签名必须严格匹配宏的要求（如 `OnLButtonDown(UINT nFlags, CPoint pt)`），写错是编译期报错（好消息），写错签名则消息静默不到达（注意 MFC 会用签名枚举 `AfxSig_xx` 做函数指针转换检查）。

## 3. 三类消息，三种宏

### 3.1 标准 Windows 消息：`ON_WM_*`

`WM_LBUTTONDOWN` → `OnLButtonDown`。**消息名决定函数名，函数名固定不能改**。MFC 已把 WPARAM/LPARAM 拆解成有意义的参数：

| 消息 | 处理函数签名 |
|---|---|
| `ON_WM_PAINT()` | `afx_msg void OnPaint()` |
| `ON_WM_LBUTTONDOWN()` | `afx_msg void OnLButtonDown(UINT nFlags, CPoint point)` |
| `ON_WM_CHAR()` | `afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)` |
| `ON_WM_SIZE()` | `afx_msg void OnSize(UINT nType, int cx, int cy)` |
| `ON_WM_CREATE()` | `afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct)` |
| `ON_WM_CLOSE()` | `afx_msg void OnClose()` |
| `ON_WM_TIMER()` | `afx_msg void OnTimer(UINT_PTR nIDEvent)` |

`nFlags` 常用值：`MK_CONTROL`、`MK_SHIFT`（修饰键）；`nType` 常用值：`SIZE_RESTORED`、`SIZE_MAXIMIZED`。

### 3.2 自定义消息：`ON_MESSAGE`

```cpp
#define WM_APP_TICK (WM_APP + 1)     // WM_APP 区间保证不撞系统消息

afx_msg LRESULT OnAppTick(WPARAM wParam, LPARAM lParam);

ON_MESSAGE(WM_APP_TICK, OnAppTick)
```

- 返回值是 `LRESULT`，会作为消息处理的返回值
- 参数就是原始的 WPARAM/LPARAM，自己解释
- 发送方用 `PostMessage`（异步，发完就走）或 `SendMessage`（同步，等到处理完）
- 跨进程不能这么干，要用 `RegisterWindowMessage` + `ON_REGISTERED_MESSAGE`

**线程间通信就是靠它**（第 12 章）：worker 线程 `PostMessage(WM_APP_PROGRESS, ...)` 回 UI 线程，是 MFC 多线程的标准姿势。

### 3.3 命令消息：`ON_COMMAND` / `ON_COMMAND_RANGE`

菜单点击、工具栏按钮、加速键翻译出来的 `WM_COMMAND` 叫命令消息。它和标准消息的区别是**可以路由**——不绑定在产生它的控件上，而是沿对象链找一个愿意处理的接收者：

```text
控件/菜单 → 主框架(CFrameWnd) → 应用(CWinApp)
（有 Doc/View 时是：视图 → 文档 → 框架 → 应用）
```

```cpp
ON_COMMAND(IDM_FILE_NEW, OnFileNew)              // 单个命令
ON_COMMAND_RANGE(IDM_MRU_1, IDM_MRU_4, OnOpenRecent)  // 连续区间（最近文件）
```

控件通知（`WM_NOTIFY`，如 `CListCtrl` 的列头点击）用 `ON_NOTIFY`，参数里能拿到具体哪个控件、什么事件：

```cpp
ON_NOTIFY(LVN_COLUMNCLICK, IDC_LIST, OnColumnClick)
// 处理函数：afx_msg void OnColumnClick(NMHDR* pNMHDR, LRESULT* pResult)
```

## 4. 让界面状态跟着数据走：`ON_UPDATE_COMMAND_UI`

菜单"保存"什么时候应该置灰？——文件没打开的时候。如果每个改动数据的地方都手动去改菜单状态，代码很快烂掉。MFC 的做法是反过来：**框架在空闲时主动问你**"这个命令现在可用吗"：

```cpp
ON_UPDATE_COMMAND_UI(IDM_FILE_SAVE, OnUpdateFileSave)

afx_msg void OnUpdateFileSave(CCmdUI* pCmdUI) {
    pCmdUI->Enable(!m_filePath.IsEmpty());   // 一处代码，菜单+工具栏同时生效
}
```

`CCmdUI` 还能 `SetText`（动态菜单文案）、`SetCheck`（勾选状态）。这是 MFC 命令架构最省心的设计，第 09 章大量使用。

## 5. 消息处理函数的正确写法

```cpp
class CMainWindow : public CFrameWnd {
public:
    ...
    afx_msg void OnPaint();          // 声明带 afx_msg
    afx_msg LRESULT OnAppTick(WPARAM wp, LPARAM lp);
    DECLARE_MESSAGE_MAP()            // 类声明最后加这个

protected:
    ...
};

BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)   // .cpp 里实现表
    ON_WM_PAINT()
    ON_MESSAGE(WM_APP_TICK, OnAppTick)
END_MESSAGE_MAP()
```

注意：这些函数**不是虚函数**（除了 `OnDraw`、`OnInitDialog` 等少数），写 `override` 会编译失败——消息是靠表查的，不是靠虚表。

## 6. 常见坑

**改了消息，忘了删映射**：删了 `OnPaint` 函数但 `ON_WM_PAINT()` 还在，链接报错找不到函数。宏和函数要成对增删。

**自定义消息撞车**：`WM_USER` 区间是控件内部用的，用户代码必须用 `WM_APP + n`。

**PostMessage 传指针**：跨线程 `PostMessage(msg, 0, (LPARAM)new Data)` 后，接收方负责 `delete`。发送方绝不能在 post 之后立刻 delete——消息可能还没被处理。

**在处理函数里死循环**：`OnSize` 里 `SetWindowPos` 自己 → 又触发 `OnSize`。加状态标志或先判断尺寸是否真的变化。

## 7. 实战建议

- 命令处理写在哪个类，取决于"谁拥有那份数据"。菜单命令先落在框架，再转发给真正干活的成员（第 13 章实战项目就是这么组织编辑命令的）
- 消息处理函数保持薄：拆出 `DoXxx()` 普通成员函数，处理函数只做参数转换和调用，方便测试和复用
- 用 `SPY++`（VS 自带工具）观察真实消息流，是调试消息类问题最快的方法

---
上一章：[02 应用骨架与消息循环](02-app-lifecycle.md) ｜ 下一章：[04 资源文件入门](04-resources.md)
