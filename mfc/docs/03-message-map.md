# 03 · 消息映射机制

> 对应示例：`examples/03_message_map`

> **本章你将学会**：消息映射宏背后是什么数据结构、`AfxWndProc` 如何从 `HWND` 找回 C++ 对象并按签名调用你的函数、三类消息各用哪种宏、以及 `ON_COMMAND` 与 `ON_UPDATE_COMMAND_UI` 这对搭档怎么让界面状态自动跟着数据走。
> **前置知识**：第 02 章的消息循环。若对 `WndProc` 与 `HWND` 还不熟，见本仓库《Win32 API 桌面编程指南》第 04、05 章。

## 1. 为什么需要消息映射

纯 Win32 写窗口是这样的：

```cpp
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_PAINT:   ...; return 0;
    case WM_CHAR:    ...; return 0;
    case WM_SIZE:    ...; return DefWindowProc(...);
    default: return DefWindowProc(...);
    }
}
```

一个中型程序的 WndProc 有几千行 switch。MFC 的消息映射把 switch 变成**声明式的表**：

```cpp
BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_PAINT()
    ON_WM_LBUTTONDOWN()
    ON_MESSAGE(WM_APP_TICK, OnAppTick)
END_MESSAGE_MAP()
```

## 2. 宏展开原理（不需要会写，需要能看懂）

所有消息映射宏最终都展开成一张**静态表 + 一个覆盖版 `GetMessageMap`**：

```cpp
// 概念等价物
const AFX_MSGMAP_ENTRY CMainWindow::_messageEntries[] = {
    { WM_PAINT,      0, 0, 0, AfxSig_vv,     (AFX_PMSG)&OnPaint    },
    { WM_LBUTTONDOWN,0, 0, 0, AfxSig_vwp,    (AFX_PMSG)&OnLButtonDown },
    { WM_APP_TICK,   0, 0, 0, AfxSig_lwl,    (AFX_PMSG)&OnAppTick  },
    { 0, 0, 0, 0, AfxSig_end, nullptr }   // 结束标记
};
const AFX_MSGMAP* CMainWindow::GetMessageMap() const {
    return &CMainWindow::_messageEntries;
}
```

`GetMessageMap` 的链式查找是理解**命令路由**的钥匙：先查自己的表，没有就沿基类链（`CMainWindow → CFrameWnd → CWnd → CCmdTarget`）向上找。所以 `ON_WM_PAINT()` 这类宏你不需要写进自己的类——基类的表里已经有对应关系，派生类只需覆盖同名的 `afx_msg` 函数。

`afx_msg` 本身是个**空宏**，只是给人类标注"这是消息处理函数"。参数签名写错是编译期报错（好消息），因为原始签名完整写在宏展开的 `static_cast` 里，转换不过就编不过。

## 3. 消息映射的底层实现

上面那张表有六个字段（`afxwin.h` 里的 `AFX_MSGMAP_ENTRY`），各有分工：

| 字段 | 含义 | 谁在用 |
|---|---|---|
| `nMessage` | 消息号，如 `WM_PAINT` | 所有消息 |
| `nCode` | 通知码 | `ON_NOTIFY`（如 `LVN_COLUMNCLICK`） |
| `nID` | 控件 / 命令 ID | `ON_COMMAND`、`ON_NOTIFY` |
| `nLastID` | ID 区间上界 | `ON_COMMAND_RANGE`（单 ID 时与 `nID` 相等） |
| `nSig` | 签名枚举，如 `AfxSig_vv` | 决定 `pfn` 怎么转型 |
| `pfn` | 函数指针（统一转成 `AFX_PMSG`） | 最终被调用 |

`nSig` 是整套机制的枢纽。C++ 的成员函数指针类型各不相同，没法塞进同一个数组——所以 MFC 把它们**统一转成 `AFX_PMSG` 存起来，同时记下原始签名**，调用时再转回去。枚举大致按"返回值 + 参数"拼接（`v` = void、`w` = UINT、`l` = LONG、`p` = 指针，长参数另有 `up`、`wp` 之类写法）：

| 宏 | `nSig` | 还原出的签名 |
|---|---|---|
| `ON_WM_PAINT()` | `AfxSig_vv` | `void()` |
| `ON_WM_LBUTTONDOWN()` | `AfxSig_vwp` | `void(UINT, CPoint)` |
| `ON_WM_TIMER()` | `AfxSig_v_up_v` | `void(UINT_PTR)` |
| `ON_MESSAGE(...)` | `AfxSig_lwl` | `LRESULT(WPARAM, LPARAM)` |

消息到达时的完整链路：

```text
HWND 收到消息（操作系统只认句柄，不知道 C++ 对象的存在）
  │  WndProc 是 MFC 装的 AfxWndProc
  ▼
CWnd::FromHandlePermanent(hwnd)   ← 查"永久句柄表"，句柄换回 C++ 对象
  ▼
pWnd->OnWndMsg(msg, wParam, lParam)
  │  沿 messageMap 链线性查表：自己的表 → 基类的表 → … → CCmdTarget
  ▼
命中 AFX_MSGMAP_ENTRY，按 nSig 把 pfn 转回正确签名调用
  ├─ 命中   → 返回 TRUE，不再走默认处理
  └─ 未命中 → CWnd::DefWindowProc（系统默认行为）
```

两点值得记住：查表是**线性**的（从数组头逐个比对，不是哈希），但一张表几十项，开销可忽略；`FromHandlePermanent` 只认"永久"对象（成员变量或 `new` 出来的），所以 `CWnd` 派生类**不能放栈上**——局部对象一离开作用域，`HWND` 还在，C++ 对象却没了。

## 4. 三类消息，三种宏

### 4.1 标准 Windows 消息：`ON_WM_*`

`WM_LBUTTONDOWN` → `OnLButtonDown`。**消息名决定函数名，函数名固定不能改**。MFC 已把 WPARAM/LPARAM 拆解成有意义的参数：

| 消息 | 处理函数签名 |
|---|---|
| `ON_WM_PAINT()` | `afx_msg void OnPaint()` |
| `ON_WM_LBUTTONDOWN()` | `afx_msg void OnLButtonDown(UINT nFlags, CPoint point)` |
| `ON_WM_CHAR()` | `afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)` |
| `ON_WM_SIZE()` | `afx_msg void OnSize(UINT nType, int cx, int cy)` |
| `ON_WM_CREATE()` | `afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct)` |
| `ON_WM_CLOSE()` | `afx_msg void OnClose()` |

`nFlags` 常用值：`MK_CONTROL`、`MK_SHIFT`；`nType` 常用值：`SIZE_RESTORED`、`SIZE_MAXIMIZED`。

### 4.2 自定义消息：`ON_MESSAGE`

```cpp
#define WM_APP_TICK (WM_APP + 1)     // WM_APP 区间保证不撞系统消息
afx_msg LRESULT OnAppTick(WPARAM wParam, LPARAM lParam);
ON_MESSAGE(WM_APP_TICK, OnAppTick)
```

返回值是 `LRESULT`，会作为消息处理的返回值；参数就是原始的 WPARAM/LPARAM，自己解释。发送方用 `PostMessage`（异步）或 `SendMessage`（同步）。跨进程不能这么干，要用 `RegisterWindowMessage` + `ON_REGISTERED_MESSAGE`。

**线程间通信就是靠它**（第 20 章）：worker 线程 `PostMessage(WM_APP_PROGRESS, ...)` 回 UI 线程，是 MFC 多线程的标准姿势。

### 4.3 命令消息：`ON_COMMAND` / `ON_COMMAND_RANGE`

菜单点击、工具栏按钮、加速键翻译出来的 `WM_COMMAND` 叫命令消息。它和标准消息的区别是**可以路由**——不绑定在产生它的控件上，而是沿对象链找一个愿意处理的接收者：

```text
控件/菜单 → 主框架(CFrameWnd) → 应用(CWinApp)
（有 Doc/View 时是：视图 → 文档 → 框架 → 应用）
```

```cpp
ON_COMMAND(IDM_FILE_NEW, OnFileNew)                   // 单个命令
ON_COMMAND_RANGE(IDM_MRU_1, IDM_MRU_4, OnOpenRecent)  // 连续区间（最近文件）
```

控件通知（`WM_NOTIFY`，如 `CListCtrl` 的列头点击）用 `ON_NOTIFY`，参数里能拿到具体哪个控件、什么事件：

```cpp
ON_NOTIFY(LVN_COLUMNCLICK, IDC_LIST, OnColumnClick)
// 处理函数：afx_msg void OnColumnClick(NMHDR* pNMHDR, LRESULT* pResult)
```

## 5. 命令消息与更新 UI

菜单"保存"什么时候应该置灰？——文件没打开的时候。如果每个改动数据的地方都手动去改菜单状态，代码很快烂掉。MFC 的做法是反过来：**框架在空闲时主动问你**"这个命令现在可用吗"：

```cpp
ON_COMMAND(IDM_FILE_SAVE, OnFileSave)                  // ① 命令执行
ON_UPDATE_COMMAND_UI(IDM_FILE_SAVE, OnUpdateFileSave)  // ② 状态更新

afx_msg void OnFileSave() {
    // 真正干活。这里不需要判断"能不能存"——不能存时菜单是灰的，点不到
    m_doc.Save(m_filePath);
}
afx_msg void OnUpdateFileSave(CCmdUI* pCmdUI) {
    pCmdUI->Enable(!m_filePath.IsEmpty());   // 一处代码，菜单+工具栏同时生效
}
```

| 宏 | 什么时候被调 | 干什么 |
|---|---|---|
| `ON_COMMAND` | 用户点击 / 按下加速键时 | 执行命令本身 |
| `ON_UPDATE_COMMAND_UI` | **空闲时**（消息队列空） | 设置该命令的可用 / 勾选 / 文案状态 |

关键在于 ② 的调用时机：它挂在 `CFrameWnd::OnIdleUpdateCmdUI` 上，由第 02 章讲过的 `OnIdle` 驱动。所以**不需要在数据变化的地方手动刷新菜单**——数据改了，下一个空闲周期框架自然会来问；代价是界面状态最多滞后一个空闲周期，肉眼察觉不到。同一个 ID 只需一份更新代码，菜单项和工具栏按钮会一起被更新。

`CCmdUI` 的常用方法：`Enable(BOOL)` 置灰 / 启用（菜单项与工具栏按钮同步）、`SetCheck(int)` 设勾选状态（`0` 不勾、`1` 勾、`2` 不确定态）、`SetText(LPCTSTR)` 动态改菜单文案，以及 `m_nID`——当前命令 ID，多个命令共用一个更新函数时靠它区分。第 11 章处理工具栏按钮状态时大量使用 `m_nID`。

## 6. 消息处理函数的正确写法

声明在类里（带 `afx_msg`），实现在 `.cpp` 里，两头靠 `DECLARE_MESSAGE_MAP()` / `BEGIN_MESSAGE_MAP` 配对——第 1 节的例子已经展示了完整形态。唯一要强调的是：这些函数**不是虚函数**（除了 `OnDraw`、`OnInitDialog` 等少数），写 `override` 会编译失败——消息是靠表查的，不是靠虚表。

## 常见坑

1. **改了消息，忘了删映射**
   删了 `OnPaint` 函数但 `ON_WM_PAINT()` 还在，链接报错找不到函数。宏和函数要成对增删。

2. **`ON_COMMAND` 的 ID 与资源里不一致**
   最阴的一类 bug：**编译链接全过，点了菜单就是没反应，也不报任何错**——路由找不到接收者时会继续往上传递，最后被 `CWinApp` 丢掉。资源编辑器改了 ID 后，记得同步 `.cpp` 里的 `ON_COMMAND`。

3. **`afx_msg` 函数写了 `override`**
   报 C3668（"未找到重写虚函数的成员"）。消息处理函数不是虚函数，`afx_msg` 只是标注；去掉 `override` 即可。

4. **`DECLARE_MESSAGE_MAP()` 放错位置**
   放在 `private` 段**仍然有效**，因为宏展开时自带访问说明符：它展开成 `protected: static const AFX_MSGMAP* …`，会在**原地插一个 `protected:`**——夹在类声明中间的话，写在它后面的成员会意外变成 `protected`。所以习惯上放在类声明末尾。

5. **处理函数返回 `void` 却写了 `return` 值**
   `afx_msg void OnClose()` 里写 `return 0;` 直接编译不过。要返回值的是 `ON_MESSAGE` 的处理函数（`LRESULT`）和 `ON_NOTIFY` 的处理函数（通过 `LRESULT* pResult` 出参）。

6. **`PostMessage` 传指针**
   跨线程 `PostMessage(msg, 0, (LPARAM)new Data)` 后，接收方负责 `delete`。发送方绝不能在 post 之后立刻 delete——消息可能还没被处理。

## 实战建议

- 命令处理写在哪个类，取决于"谁拥有那份数据"。菜单命令先落在框架，再转发给真正干活的成员（第 25 章实战项目就是这么组织编辑命令的）
- 消息处理函数保持薄：拆出 `DoXxx()` 普通成员函数，处理函数只做参数转换和调用，方便测试和复用
- **能用 `ON_UPDATE_COMMAND_UI` 就别手动改菜单状态**。把"界面能不能点"集中在一处声明式地表达出来，是 MFC 里少有的、接近现代框架体验的部分
- 用 `SPY++`（VS 自带工具）观察真实消息流，是调试消息类问题最快的方法

## 自测

1. **消息映射宏展开后是什么？** —— 一张 `AFX_MSGMAP_ENTRY` 静态数组（六个字段：`nMessage`/`nCode`/`nID`/`nLastID`/`nSig`/`pfn`，以 `AfxSig_end` 结尾），加一个覆盖版 `GetMessageMap` 返回它的地址。
2. **`afx_msg` 函数为什么不能写 `override`？** —— 它们不是虚函数。消息靠查表分发，不靠虚表；写 `override` 报 C3668。
3. **`ON_COMMAND` 与 `ON_UPDATE_COMMAND_UI` 的分工是什么？后者何时执行？** —— 前者执行命令本身（用户点击 / 按加速键时），后者在**空闲时**被框架询问以设置菜单 / 工具栏的可用与勾选状态。
4. **自定义消息为什么用 `WM_APP + n` 而不是 `WM_USER + n`？** —— `WM_USER` 区间被控件内部占用，`WM_APP` 区间留给应用程序，避免撞车。

---
上一章：[02 应用骨架与消息循环](02-app-lifecycle.md) ｜ 下一章：[04 资源文件入门](04-resources.md)
