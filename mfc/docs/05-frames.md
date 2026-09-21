# 05 · 窗口与框架类：创建、布局与生命周期

> 对应示例：`examples/05_frame_layout`

> **本章你将学会**：`CWnd` 与 `HWND` 的关系、窗口类是怎么注册的、子控件该在什么时候创建、手工布局的两道必备守卫、三种客户区布局方案的取舍，以及窗口销毁与 C++ 对象销毁的配对规则。
> **前置知识**：第 02 章的生命周期。若对"窗口类（`WNDCLASS`）"这个概念不熟，见本仓库《Win32 API 桌面编程指南》第 04 章。

## 1. CWnd 体系

MFC 所有窗口类的基类是 `CWnd`，它就是一个 `HWND` 的 C++ 包装——`CWnd` 对象和 Windows 窗口**不是同一个东西**：对象是 C++ 层的壳，窗口是系统内核对象，两者在 `Create` 时通过句柄关联、在销毁时解除。

```
CWnd                       // 一切窗口的基础：句柄管理、消息映射、子窗口
├── CFrameWnd              // 框架窗口：菜单、工具栏停靠、SDI 主窗口
│   ├── CMDIFrameWnd       // MDI 主框架
│   └── COleFrameWnd
├── CDialog                // 对话框（第 06 章）
│   └── CPropertySheet     // 属性表
├── 控件类                 // CButton/CEdit/CListBox/CListCtrl...（第 07 章）
└── CView                  // Doc/View 的视图（第 15 章）
```

最常用的 `CWnd` 成员：

| 成员 | 用途 |
|---|---|
| `Create()` | 创建窗口（控件用 `Create`，框架窗口也用 `Create`） |
| `GetSafeHwnd()` | 拿 HWND；对象可能还没建窗口，先判空防崩溃 |
| `GetDlgItem(id) / SetDlgItemText` | 按控件 ID 访问子控件 |
| `MoveWindow / SetWindowPos` | 移动缩放（布局的核心） |
| `Invalidate(bErase)` | 请求重绘 → 触发 `WM_PAINT` |
| `SendMessage / PostMessage` | 发消息（同步/异步） |
| `SetCapture()` | 让鼠标消息持续发给自己（拖拽必需） |
| `ClientToScreen / ScreenToClient` | 坐标系转换 |

## 2. 创建时机：OnCreate

子控件的标准创建位置是框架的 `OnCreate`——此时窗口本体已建立、尚未显示，在这里建子控件可以避免闪烁：

```cpp
afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
    if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
        return -1;              // 基类失败则终止窗口创建

    m_edit.Create(WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
                  CRect(0, 0, 0, 0), this, IDC_INPUT);   // 尺寸先给 0
    ...
    return 0;                   // 0 继续；-1 会销毁窗口
}
```

三个关键点：

1. **`WS_CHILD | WS_VISIBLE`**：控件是子窗口，必须带 `WS_CHILD`；`WS_VISIBLE` 让它随父窗口一起显示
2. **`this` 是父窗口**：控件的所有权、坐标基准、消息通知目标都归它
3. **初始尺寸给 0 没关系**——真正的尺寸在 `OnSize` 里布

## 3. 窗口类的注册与 MFC 的封装

纯 Win32 里，创建窗口前必须先注册一个"窗口类"（`WNDCLASS`），它规定了这套窗口共用的**类样式、光标、背景刷、图标**：

```cpp
WNDCLASS wc = { 0 };
wc.style         = CS_HREDRAW | CS_VREDRAW;      // 类样式
wc.lpfnWndProc   = WndProc;                      // 窗口过程
wc.hCursor       = ::LoadCursor(NULL, IDC_ARROW); // 鼠标指针
wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);    // 背景刷
wc.lpszClassName = _T("MyWindowClass");
::RegisterClass(&wc);                             // 注册，同名只注册一次
```

MFC 把这件事包掉了，两个入口：

```cpp
// ① 一句话注册一个类，返回可直接用的类名
LPCTSTR cls = AfxRegisterWndClass(CS_HREDRAW | CS_VREDRAW,   // 类样式
                                  ::LoadCursor(NULL, IDC_ARROW), // 光标
                                  (HBRUSH)(COLOR_WINDOW + 1),    // 背景刷
                                  nullptr);                      // 图标

// ② 需要自己填 WNDCLASS 结构时用这个（它会计入 MFC 的类表，退出时自动反注册）
WNDCLASS wc = { 0 };
wc.style = CS_DBLCLKS;
wc.lpfnWndProc = ::DefWindowProc;   // MFC 会替换成 AfxWndProc
wc.hInstance = AfxGetInstanceHandle();
wc.lpszClassName = _T("MyClass");
AfxRegisterClass(&wc);
```

`AfxRegisterWndClass` 的四个参数对应类样式、光标、背景刷、图标；它生成的类名是**带哈希的长串**（形如 `Afx:00400000:b:00010003:...`），这样不同参数组合自然得到不同的类名，不会互相覆盖——这正是它的价值：你不用自己起名字、也不用操心重名。

**惰性注册**是 MFC 的另一层封装。当你写 `m_edit.Create(...)` 而不指定类名时，MFC 会按 `CEdit` 这个运行时类去查一个缓存的类名，没有就现场注册一个（`AfxRegisterClass`），有就直接复用。所以**同一个 `CWnd` 派生类的所有实例共用一个窗口类**——类样式、背景刷也就跟着共用了。

需要绕过封装、直接用 `::CreateWindowEx` 时，用 `CWnd::CreateEx`，参数序列与 Win32 一一对应：

```cpp
BOOL CreateEx(DWORD dwExStyle,      // 扩展样式，如 WS_EX_CLIENTEDGE
              LPCTSTR lpszClassName,// 类名；传 NULL 就用 MFC 惰性注册的那个
              LPCTSTR lpszWindowName,
              DWORD dwStyle,        // 样式，如 WS_CHILD | WS_VISIBLE
              int x, int y, int nWidth, int nHeight,
              HWND hWndParent,      // 父窗口句柄
              HMENU nIDorHMenu,     // 子窗口传控件 ID，顶层窗口传菜单句柄
              LPVOID lpParam = NULL);
```

注意最后一个参数 `nIDorHMenu` 是**双重身份**：子窗口传控件 ID，顶层窗口传菜单句柄——这就是为什么 `CFrameWnd::Create` 的第 6 个参数能同时表示"菜单"。

## 4. 自适应布局：OnSize 模式

MFC 没有 layout 引擎，可变尺寸窗口的布局就是**在 OnSize 里手工算**：

```cpp
afx_msg void OnSize(UINT nType, int cx, int cy) {
    CFrameWnd::OnSize(nType, cx, cy);

    // 两道守卫，缺一不可
    if (nType == SIZE_MINIMIZED || m_edit.GetSafeHwnd() == nullptr)
        return;

    const int margin = 12, editH = 28, btnW = 100, btnH = 30, gap = 8;
    int y = margin;
    m_edit.MoveWindow(margin, y, cx - 2 * margin, editH);
    y += editH + gap;
    m_log.MoveWindow(margin, y, cx - 2 * margin, (cy - margin - btnH) - y);
    m_btn.MoveWindow(cx - margin - btnW, cy - margin - btnH, btnW, btnH);
}
```

两道守卫各自防的是什么：

- **`nType == SIZE_MINIMIZED`**：最小化时 `cx`/`cy` 都是 **0**。`cx - 2 * margin` 会变成负数，`MoveWindow` 收到负宽高会得到无效矩形，控件被挤没；如果布局代码里有除法（按比例分配），还会直接**除零崩溃**
- **`m_edit.GetSafeHwnd() == nullptr`**：窗口创建过程中 `WM_SIZE` 可能先于 `OnCreate` 到达，此时控件还不存在，直接 `MoveWindow` 是空指针崩溃

另外 **`OnSize` 里别做重活**：拖拽窗口时它每秒触发几十次。

## 5. 客户区布局的三种做法

| 做法 | 机制 | 适合 | 代价 |
|---|---|---|---|
| **`OnSize` 手算 `MoveWindow`** | 收到尺寸 → 自己算每个子控件的矩形 | 子控件少（十来个以内）、布局规则简单 | 布局逻辑全在手写代码里，控件一多就难维护 |
| **`CControlBar` 停靠栏** | 框架窗口自动为停靠栏预留边缘空间，客户区自动避让 | 工具栏、状态栏、可停靠面板 | 只能贴边；`CControlBar`/`CToolBar`/`CStatusBar` 在 `<afxext.h>` |
| **`CSplitterWnd` 分割** | 把一个客户区分成多个可拖拽调整的窗格，每个窗格挂一个视图 | 资源管理器式的左右/上下分栏 | 每个窗格得是一个 `CView`，要 Doc/View 配合（第 16 章） |

关键区别在于**"谁负责避让"**：

- 手算模式下，**你**要记住"状态栏占了底部 24 像素"，在算客户区高度时减掉
- 停靠栏模式下，**框架**会调 `CFrameWnd::RecalcLayout` 先给停靠栏分配空间，再把你客户区限制在剩余矩形里——所以你用 `GetClientRect` 拿到的已经是"扣除停靠栏之后"的区域，不用自己减

这也是新手常踩的坑：明明用 `GetClientRect` 拿了客户区，为什么还和状态栏重叠？——因为你用的是 `CWnd::GetClientRect`（整个客户区），而框架布局用的是 `CFrameWnd::GetClientRect` 之后的 `RepositionBars`。用停靠栏时，布局代码应该放在 `CFrameWnd::OnSize` 的**基类调用之后**，让框架先把停靠栏摆好。

三种做法可以混用：工具栏 + 状态栏用停靠栏，中间客户区用 `CSplitterWnd` 分两栏，每栏内部再手算布局。

## 6. 控件字体：默认字体很丑

手工创建的控件默认是粗老的 System 字体。统一设置 GUI 字体：

```cpp
wnd.SendMessage(WM_SETFONT, (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
```

真实工程一般建一个 `CFont` 成员（`CreatePointFont(90, _T("微软雅黑"))`），在 `OnCreate` 里发给每个控件，`ExitInstance` 前保持存活——注意 `GetStockObject` 拿到的不用删除，自建的 `CFont` 要在所有控件销毁后才能释放。

## 7. 控件通知怎么回到父窗口

控件与父窗口通信靠**通知消息**，MFC 映射宏按通知类型分：

| 事件 | 宏 | 处理函数 |
|---|---|---|
| 按钮点击 | `ON_BN_CLICKED(IDC_ADD, OnAdd)` | `afx_msg void OnAdd()` |
| 编辑框文本变化 | `ON_EN_CHANGE(IDC_EDIT, OnChange)` | `afx_msg void OnChange()` |
| 组合框选择变化 | `ON_CBN_SELCHANGE(IDC_COMBO, OnSel)` | `afx_msg void OnSel()` |
| 列表控件复杂通知 | `ON_NOTIFY(LVN_XXX, IDC_LIST, OnXxx)` | `afx_msg void OnXxx(NMHDR*, LRESULT*)` |

`ON_BN_CLICKED` / `ON_EN_*` 这类是 `WM_COMMAND` 的语法糖；`ON_NOTIFY` 处理 `WM_NOTIFY`（能携带更丰富的信息）。都是**子 → 父**的单向通知，父窗口想控制子控件就用成员变量的方法（`m_edit.SetWindowText`）。

## 8. 窗口生命周期与对象生命周期

```text
Create 时序：  C++ 对象构造 → Create/OnCreate → 显示 → 使用
销毁时序：    WM_CLOSE → DestroyWindow → WM_DESTROY → WM_NCDESTROY → PostNcDestroy
```

关键规则：

- **CFrameWnd 派生窗口**：框架在 `PostNcDestroy` 里 `delete this`——所以 `new CMainWindow()` 之后不用管释放（第 01 章示例没写任何 delete 是对的）
- **控件（CButton 等）**：作为 `WS_CHILD` 子窗口随父窗口销毁，但 **C++ 对象不自动 delete**——控件通常做成成员变量（如 `CEdit m_edit;`），跟随宿主类析构，最省心
- **对话框**：模态在栈上；非模态需要 `PostNcDestroy` 套路（第 06 章详解）

**绝不手工调用 `delete` 去销毁一个还有窗口的 CWnd**，先 `DestroyWindow()` 让窗口走完销毁链路。

## 常见坑

1. **`WM_SIZE` 先于 `OnCreate`**
   窗口创建过程中 `WM_SIZE` 可能先到达，此时成员控件还不存在。`OnSize` 开头判 `GetSafeHwnd()`，见第 4 节。

2. **最小化时按 0 尺寸计算**
   最小化时 `cx`/`cy` 为 0，负宽高会让控件消失，有除法则直接崩溃。`if (nType == SIZE_MINIMIZED) return;` 一行解决。

3. **`GetClientRect` 之后又 `ScreenToClient`**
   重复换算。`GetClientRect` 给的**已经是客户区坐标**（左上角恒为 0,0），只有 `GetWindowRect` 给的是屏幕坐标、才需要 `ScreenToClient` 转换。混用会把布局算偏一个窗口边框的宽度。

4. **控件 ID 重复**
   两个控件用同一 ID，通知路由错乱。ID 段位分配好（第 04 章）。

5. **在 `OnCreate` 里全量 `MoveWindow` 后仍闪烁**
   控件多时逐个移动会闪。先 `SetRedraw(FALSE)`，布局完 `SetRedraw(TRUE)` + `Invalidate`。

6. **`SetCapture` 配对遗忘**
   `SetCapture()` 后必须在 `WM_LBUTTONUP`（或中途判断按键抬起）时 `ReleaseCapture()`，否则鼠标被独占，别的程序收不到。

## 实战建议

- 把布局逻辑抽成 `void LayoutChildren(int cx, int cy)`，`OnSize` 和初始化都调它，避免两处算尺寸不一致
- 控件一律做成员变量（值语义、自动析构），只有动态创建的一组控件才用容器管理
- **`OnSize` 的第一行永远是基类调用 + 两道守卫**，把它当成肌肉记忆——这两行省掉的调试时间远超写它的成本
- 用停靠栏时，客户区布局代码放在 `CFrameWnd::OnSize` 基类调用**之后**，让框架先摆好停靠栏

## 自测

1. **`CWnd` 对象和 `HWND` 是同一个东西吗？** —— 不是。`CWnd` 是 C++ 层的包装壳，`HWND` 是系统内核对象；两者在 `Create` 时关联、销毁时解除，生命周期可以不同步。
2. **`OnSize` 里的两道守卫分别防什么？** —— `nType == SIZE_MINIMIZED` 防最小化时 `cx`/`cy` 为 0 导致的负尺寸或除零；`GetSafeHwnd() == nullptr` 防 `WM_SIZE` 早于 `OnCreate` 到达时的空指针崩溃。
3. **`AfxRegisterWndClass` 生成的类名为什么是带哈希的长串？** —— 让不同参数组合（类样式/光标/背景刷/图标）自然得到不同类名，避免互相覆盖，开发者不必自己起名也不必操心重名。
4. **`GetClientRect` 和 `GetWindowRect` 的区别是什么？** —— `GetClientRect` 返回客户区坐标（左上角恒为 0,0，不含边框标题栏）；`GetWindowRect` 返回屏幕坐标的整个窗口矩形，需要 `ScreenToClient` 转换后才能用于子控件定位。

---
上一章：[04 资源文件入门](04-resources.md) ｜ 下一章：[06 对话框](06-dialogs.md)
