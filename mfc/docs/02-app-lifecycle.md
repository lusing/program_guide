# 02 · 应用骨架与消息循环

> 对应示例：`examples/01_hello_mfc`

## 1. 一个 MFC 程序到底是怎么跑起来的

没有 `main`，没有 `WinMain`，只有一行 `CMyApp theApp;`。但程序确实跑起来了。实际顺序是：

```text
exe 启动
  └─ CRT 入口 wWinMainCRTStartup
       └─ wWinMain（由 MFC 的 mfc140u.dll 提供，不是你写的）
            ├─ AfxWinInit：初始化 MFC 框架
            ├─ 构造全局对象 theApp（CWinApp 构造函数把自己登记为"当前应用"）
            ├─ theApp->InitInstance()      ← 你的代码：建窗口
            ├─ theApp->Run()               ← 消息循环，直到 WM_QUIT
            └─ theApp->ExitInstance()      ← 你的清理代码
```

理解三个事实，MFC 就不神秘了：

1. **`WinMain` 在 MFC 库里**。框架自己实现了入口，你的机会只有 `InitInstance` / `ExitInstance` / `Run` 这几个虚函数。
2. **全局对象 `theApp` 是注册机制**。MFC 通过全局构造找到你的应用类，一切"框架回调你"都从它开始。
3. **MFC 程序骨子里还是 Win32 程序**。`CWinApp::Run()` 内部就是标准的 `GetMessage / TranslateMessage / DispatchMessage` 循环。

## 2. InitInstance：程序入口

```cpp
BOOL CMyApp::InitInstance() {
    m_pMainWnd = new CMainWindow();      // 框架接管该指针的生命周期
    m_pMainWnd->ShowWindow(m_nCmdShow);  // 用命令行参数决定初始显示状态
    m_pMainWnd->UpdateWindow();
    return TRUE;   // 返回 FALSE = 程序直接退出
}
```

要点：

- `m_pMainWnd` 必须赋值。框架用它判断"主窗口关了没有"，主窗口销毁后消息循环自动结束、程序退出——**这就是 MFC 程序的退出机制**，你不需要写退出代码。
- `m_nCmdShow` 来自系统，通常原样传给 `ShowWindow`。
- 返回 `FALSE` 表示初始化失败（比如发现单实例已运行），程序静默退出。

实际项目里 `InitInstance` 还常做：加载配置、解析命令行（`ParseCommandLine`）、检查单实例（`CreateMutex` 判断 `ERROR_ALREADY_EXISTS`）。

## 3. 消息循环里发生了什么

`CWinApp::Run()` 的循环大致是：

```text
while (GetMessage(&msg, ...)) {        // 从队列取消息，WM_QUIT 时返回 0
    TranslateMessage(&msg);            // 键盘消息翻译成 WM_CHAR
    DispatchMessage(&msg);             // 分发到目标窗口的 WndProc
}
```

消息的两种来源决定了两种处理路径：

- **队列消息**（鼠标、键盘、重绘）：先进系统队列，被 DispatchMessage 分发
- **非队列消息**（`SendMessage`、控件通知）：直接调用目标窗口的 WndProc

MFC 在 `DispatchMessage` 和你的处理函数之间插了一层：每个 `CWnd` 挂着一个 `WndProc`（`AfxWndProc`），它查消息映射表找到对应 C++ 成员函数。这张表就是下一章的消息映射。

## 4. CWinApp 的重要成员速查

| 成员 | 用途 |
|---|---|
| `m_pMainWnd` | 主窗口指针，控制程序退出时机 |
| `m_nCmdShow` | 初始窗口显示方式 |
| `m_pszAppName` | 应用名（默认取 exe 名） |
| `SetRegistryKey("公司名")` | 切换到注册表存配置（否则用 .ini 文件） |
| `GetProfileInt / WriteProfileInt` | 读写配置项（配合上一条） |
| `LoadStdProfileSettings(n)` | 加载标准配置 + 最近文件列表 |

## 5. 程序什么时候退出

标准退出链路：

```text
用户点 X / 菜单退出
  → 主窗口收到 WM_CLOSE
  → 默认 DefWindowProc 调 DestroyWindow
  → 窗口销毁，WM_DESTROY
  → 框架检测到 m_pMainWnd 销毁
  → PostQuitMessage → 消息循环收到 WM_QUIT → Run 返回
  → ExitInstance() → 进程结束
```

想"程序化退出"就 `PostMessage(WM_CLOSE)`（走确认流程）或 `AfxGetMainWnd()->PostMessage(WM_CLOSE)`；粗暴的 `ExitProcess` 会跳过析构，别用。

## 6. 常见坑

**窗口一闪而过**：`InitInstance` 里 `new` 完窗口没 `ShowWindow`，或者返回了 `FALSE`。MFC 不会自动显示窗口。

**内存泄漏误报**：`m_pMainWnd` 指向的对象框架会 `delete`，自己再 delete 就双重释放。但**其他** new 出来的 `CWnd` 派生对象，销毁路径要自己想清楚（见第 06 章非模态对话框的 `PostNcDestroy` 套路）。

**在 InitInstance 里做耗时操作**：窗口还没建，程序看起来像死了。耗时初始化放到后台线程（第 20 章）或启动画面里。

**子类化窗口后忘了调基类**：重写 `OnInitDialog`、`OnCreate`、`OnSize` 等时，第一行必须调基类版本，否则框架内部状态没建立。

## 7. 实战建议

- 把 `InitInstance` 保持在 20 行以内：建窗口、显示、返回。其他逻辑下沉
- 需要自定义消息循环行为（比如给某些窗口特殊预处理）时重写 `CWinApp::PreTranslateMessage`，但要明白它是全局钩子，别在里面写业务
- 配置持久化优先 `SetRegistryKey` + `GetProfileInt`，简单可靠

---
上一章：[01 MFC 概述与开发环境](01-overview.md) ｜ 下一章：[03 消息映射机制](03-message-map.md)
