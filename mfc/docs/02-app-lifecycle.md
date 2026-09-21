# 02 · 应用骨架与消息循环

> 对应示例：`examples/02_app_lifecycle`（第 1 节的时序表就是它的实际输出）

> **本章你将学会**：MFC 程序的四个阶段分别发生了什么、`InitInstance` 为什么是唯一必须重写的函数、消息循环内部到底在做什么、`OnIdle` 该用在哪、以及从 `WM_CLOSE` 到进程退出的完整链路。
> **前置知识**：第 01 章。若想对照纯 Win32 版本的写法，见本仓库《Win32 API 桌面编程指南》第 04 章。

## 1. 一个 MFC 程序的四个阶段

没有 `main`，没有 `WinMain`，只有一行 `CMyApp theApp;`。但程序确实跑起来了。实际顺序是：

```text
exe 启动
  └─ CRT 入口 wWinMainCRTStartup
       └─ wWinMain（由 MFC 的 mfc140u.dll 提供，不是你写的）
            ├─ AfxWinInit：初始化 MFC 框架
            ├─ 构造全局对象 theApp（CWinApp 构造函数把自己登记为"当前应用"）
            ├─ theApp->InitApplication()   ← 全局资源，每程序一次
            ├─ theApp->InitInstance()      ← 你的代码：建窗口
            ├─ theApp->Run()               ← 消息循环，直到 WM_QUIT
            ├─ theApp->ExitInstance()      ← 你的清理代码
            └─ 全局对象析构（~theApp）
```

`examples/02_app_lifecycle` 把这条链路的每一步都打了时间戳。窗口客户区里是日志，同时写一份到 exe 同目录的 `lifecycle.log`——**退出阶段窗口已经销毁，所以必须看文件才拿得到完整时序**。实测输出（时间戳已省略）：

| 序号 | 事件 | 说明 |
|---|---|---|
| 1 | `CLifecycleApp` 构造函数 | 全局对象，在 `main` 之前 |
| 2 | `InitApplication()` | 注册窗口类等全局资源，每程序一次 |
| 3 | `InitInstance()` 进入 | 唯一必须重写的函数 |
| 4 | `CMainFrame` 构造函数 | 在 `Create` 之前 |
| 5 | `CMainFrame::OnCreate` | 窗口已建，子控件在这里创建 |
| 6 | `InitInstance()` 返回 TRUE | 马上进入消息循环 `Run()` |
| 7 | `OnIdle(0)` | 消息队列空了 |
| 8 | `WM_CLOSE` | 用户点了关闭 |
| 9 | `WM_DESTROY` | 窗口正在销毁 |
| 10 | `ExitInstance()` | `Run()` 已返回，消息循环结束 |
| 11 | `ExitInstance()` 返回 | 主窗口对象由框架负责销毁 |
| 12 | `~CLifecycleApp()` | 全局对象析构，进程即将结束 |

理解三个事实，MFC 就不神秘了：

1. **`WinMain` 在 MFC 库里**。框架自己实现了入口，你的机会只有 `InitApplication` / `InitInstance` / `Run` / `ExitInstance` 这几个虚函数。
2. **全局对象 `theApp` 是注册机制**。MFC 通过全局构造找到你的应用类，一切"框架回调你"都从它开始。注意它比 `wWinMain` 更早构造——所以序号 1 排在 2 前面。
3. **MFC 程序骨子里还是 Win32 程序**。`CWinApp::Run()` 内部就是标准的 `GetMessage / TranslateMessage / DispatchMessage` 循环。

## 2. InitInstance：唯一必须重写的函数

`CWinApp` 提供的默认 `InitInstance` 什么都不做，直接返回 `TRUE`——那样程序会立刻进消息循环，然后因为没有任何窗口而永远空转。所以它是你**必须**重写的那一个。

逐行解剖 `02_app_lifecycle` 的版本：

```cpp
BOOL CLifecycleApp::InitInstance() {
    AppendLog(_T("3. InitInstance() 进入 —— 唯一必须重写的函数"));
    if (!CWinApp::InitInstance()) return FALSE;      // ① 先调基类

    g_pFrame = new CMainFrame();                     // ② 构造即 Create（见示例构造函数）
    if (!g_pFrame->GetSafeHwnd()) {                  // ③ Create 失败要收尾
        delete g_pFrame;
        g_pFrame = nullptr;
        return FALSE;
    }
    m_pMainWnd = g_pFrame;                           // ④ 交给框架托管

    m_pMainWnd->ShowWindow(m_nCmdShow);              // ⑤ 显示
    m_pMainWnd->UpdateWindow();                      // ⑥ 立即重绘一次
    AppendLog(_T("6. InitInstance() 返回 TRUE —— 马上进入消息循环 Run()"));
    return TRUE;
}
```

四件事缺一不可：

- **① 调基类**。`CWinApp::InitInstance` 负责框架内部状态的建立，忘了调它，后面的一切都建立在未初始化的基础上。
- **④ 赋值 `m_pMainWnd`**。框架用它判断"主窗口关了没有"，主窗口销毁后消息循环自动结束、程序退出——**这就是 MFC 程序的退出机制**，你不需要写退出代码。忘了赋值，症状是关掉窗口进程还在后台跑。
- **⑤ `m_nCmdShow` 而不是硬编码 `SW_SHOW`**。它来自系统，携带了"这个程序该以最大化/最小化/正常启动"的信息（比如快捷方式里设了"最大化运行"）。原样传下去即可。
- **返回 `FALSE` 的后果**：`AfxWinMain` 会**跳过整个消息循环**，直接跳到 `ExitInstance()`，然后进程退出。没有窗口、没有消息循环、没有用户交互——所以这是"初始化失败，静默退出"的标准姿势（比如检测到单实例已在运行）。

CWinApp 常用成员速查：

| 成员 | 用途 |
|---|---|
| `m_pMainWnd` | 主窗口指针，控制程序退出时机 |
| `m_nCmdShow` | 初始窗口显示方式，来自系统 |
| `m_pszAppName` | 应用名（默认取 exe 名） |
| `SetRegistryKey("公司名")` | 切换到注册表存配置（否则用 .ini 文件） |
| `GetProfileInt / WriteProfileInt` | 读写配置项（配合上一条） |
| `LoadStdProfileSettings(n)` | 加载标准配置 + 最近文件列表 |

## 3. 消息循环到底在做什么

`CWinApp::Run()` 继承自 `CWinThread::Run()`，骨架等价于：

```cpp
int CWinThread::Run() {
    for (;;) {
        while (!PeekMessage(&msg, NULL, 0, 0, PM_NOREMOVE)) {
            // 队列空了 —— 先做空闲处理
            if (!OnIdle(lCount++)) {
                // 没有空闲任务了，睡在 GetMessage 上等消息
                WaitMessage();
                lCount = 0;
            }
        }
        if (msg.message == WM_QUIT) break;   // 退出信号
        if (!PreTranslateMessage(&msg)) {    // 加速键、工具提示在这里处理
            TranslateMessage(&msg);          // 键盘消息翻译成 WM_CHAR
            DispatchMessage(&msg);           // 分发到目标窗口的 WndProc
        }
    }
    return (int)msg.wParam;
}
```

对照 Win32 教程里的经典循环：

```cpp
while (GetMessage(&msg, NULL, 0, 0)) {   // ← MFC 把它拆成了 PeekMessage + WaitMessage
    TranslateMessage(&msg);
    DispatchMessage(&msg);
}
```

MFC 多做了三件事：

1. **`PeekMessage` 而非 `GetMessage`**：先"偷看"有没有消息，没有就去跑 `OnIdle`。这是空闲处理能存在的前提
2. **`PreTranslateMessage`**：分发之前的全局拦截点，加速键表（`HACCEL`）、工具提示、对话框的 `IsDialogMessage` 都挂在这里
3. **`WM_QUIT` 单独判断**：`PeekMessage` 取到 `WM_QUIT` 时也会返回非零，所以要在分发前显式 break

消息的两种来源决定了两种处理路径：

- **队列消息**（鼠标、键盘、重绘）：先进系统队列，被 `DispatchMessage` 分发
- **非队列消息**（`SendMessage`、控件通知）：直接调用目标窗口的 `WndProc`，不经过消息循环

MFC 在 `DispatchMessage` 和你的处理函数之间插了一层：每个 `CWnd` 挂着一个 `WndProc`（`AfxWndProc`），它查消息映射表找到对应 C++ 成员函数。这张表就是下一章的消息映射。

## 4. OnIdle：空闲时机的正确用法

`OnIdle(LONG lCount)` 在**消息队列为空**时被调用，参数含义：

- **`lCount`**：连续空转的次数。队列空第一次调时是 0，返回值仍为 `TRUE` 时下一次是 1，依此类推；一旦有消息进来或返回 `FALSE`，就重置回 0
- **返回值**：`TRUE` = "我还有事要做，别睡"；`FALSE` = "没事了，可以去 `WaitMessage` 阻塞了"

示例里只在首次触发时记一行，避免刷屏：

```cpp
BOOL CLifecycleApp::OnIdle(LONG lCount) override {
    if (lCount == 0 && !m_idleLogged) {     // ← 不判断 lCount 就会每轮都执行
        m_idleLogged = true;
        AppendLog(_T("7. OnIdle(0) —— 消息队列空了；界面刷新、状态栏更新都在这个时机"));
    }
    return CWinApp::OnIdle(lCount);         // ← 基类版本负责清理临时对象、更新工具栏
}
```

典型用途：

- **延迟清理**：MFC 自己用 `lCount == 0` 来删除临时 `CWinObject` 对象（`AfxDeleteTempMap`）
- **状态栏/工具栏更新**：`CFrameWnd::OnIdleUpdateCmdUI` 在这里刷新按钮的启用状态
- **启动时的后台准备工作**：把耗时初始化拆成小片，在头几次 `OnIdle` 里逐步做完——窗口已经显示出来了，用户看到的是"正在准备"而不是"卡死"

**反例**：在 `OnIdle` 里做耗时计算。消息队列一空你就霸占 CPU，界面照样卡住，而且比放在 `InitInstance` 里更糟——用户以为程序已经就绪了。真要跑长任务，用后台线程（第 20 章），或者把工作切片、每次 `OnIdle` 做一点并返回 `TRUE`。

## 5. 关闭流程：从 WM_CLOSE 到进程退出

对应示例日志的 8 → 12 号事件：

```text
用户点 X / 菜单退出
  → 主窗口收到 WM_CLOSE
  → CFrameWnd::OnClose → DestroyWindow
  → 窗口销毁，WM_DESTROY
  → CFrameWnd::OnDestroy → PostQuitMessage(0)
  → 消息循环取到 WM_QUIT → Run 返回
  → ExitInstance() → 全局对象析构 → 进程结束
```

关键点：

- **`PostQuitMessage` 是消息循环的终止信号**。它只是往队列里投一条 `WM_QUIT`，让 `Run()` 的循环条件不成立——不是强制杀进程。所以 `ExitInstance` 和析构函数都还能正常执行
- **`WM_CLOSE` 可以被拦下**。想加"文件未保存，确定退出？"的确认，重写 `OnClose`，用户选"取消"时直接 `return`（不调基类），窗口就不会销毁，进程继续运行
- **想程序化退出**：`AfxGetMainWnd()->PostMessage(WM_CLOSE)`，走完整确认流程。粗暴的 `ExitProcess` 会跳过析构与清理，别用
- **`PostQuitMessage` 只对主线程有效**。工作线程里调它不会结束主消息循环——工作线程要用自己的消息循环或直接退出线程函数（第 20 章）

## 常见坑

1. **`new` 了窗口却没赋给 `m_pMainWnd`**
   症状：窗口关了，进程还在任务管理器里。框架靠 `m_pMainWnd` 判断"主窗口是否销毁"，没赋值就等于永远不满足退出条件。

2. **在 `ExitInstance` 里访问已销毁的窗口对象**
   `ExitInstance` 执行时主窗口已经 `DestroyWindow` 过了。此时调 `m_pMainWnd->SetWindowText(...)` 之类，轻则无效重则崩溃。退出阶段只做与窗口无关的清理（关文件、存配置）。

3. **`OnIdle` 里不判断 `lCount`**
   消息队列一空就执行一遍，用户随便动一下鼠标就触发几十次。重活会直接把界面拖卡。

4. **重写 `InitInstance` 忘记调 `CWinApp::InitInstance()`**
   框架内部状态没建立，后续 `m_pMainWnd`、配置文件、命令行解析都可能出问题。同理，重写 `OnCreate`/`OnSize`/`OnInitDialog` 时第一行也必须调基类版本。

## 实战建议

- **把 `InitInstance` 保持在 20 行以内**：建窗口、显示、返回。配置加载、日志初始化、命令行解析都下沉到私有函数里，`InitInstance` 只负责按顺序调用它们
- **耗时的启动工作放 `OnIdle` 首次触发**：窗口先显示出来，再在空闲时做重活，用户感知更好。工作量大就切片，每次做一点并返回 `TRUE`
- **用 `m_nCmdShow`，不要硬编码 `SW_SHOW`**：尊重快捷方式里的"最大化运行"设置，这是零成本的正确行为
- **退出确认写在 `OnClose` 里**，不要写在 `OnDestroy`——后者执行时窗口已经在拆了，拦不住

## 自测

1. **四个阶段按顺序是什么？全局对象 `theApp` 在什么时候构造？** —— 构造 `theApp` → `InitApplication` → `InitInstance` → `Run`（消息循环）→ `ExitInstance` → 析构。`theApp` 是全局对象，在 `wWinMain` 之前构造。
2. **`InitInstance` 返回 `FALSE` 会怎样？** —— `AfxWinMain` 跳过整个消息循环，直接进 `ExitInstance` 然后退出。用于"初始化失败，静默退出"。
3. **`OnIdle` 的参数 `lCount` 是什么？返回值 `TRUE` 表示什么？** —— 连续空转的次数（队列空第一次是 0）；返回 `TRUE` 表示"还有事要做，别睡"，框架会继续调 `OnIdle`。
4. **`PostQuitMessage` 起什么作用？为什么它不等于强制杀进程？** —— 它往队列投一条 `WM_QUIT`，使 `Run()` 的循环条件不成立；因为是消息而非强制终止，`ExitInstance` 和全局对象析构仍会正常执行。

---
上一章：[01 MFC 概述与开发环境](01-overview.md) ｜ 下一章：[03 消息映射机制](03-message-map.md)
