# 01 · MFC 概述与开发环境

## 1. MFC 是什么

MFC（Microsoft Foundation Classes）是微软提供的 C++ 类库，把 Win32 API 封装成一套面向对象的框架。它诞生于 1992 年，比 Qt、WPF 都早，至今仍随 Visual Studio 发布并持续维护。

一句话定位：**MFC 是 Win32 API 的 C++ 外壳 + 一套现成的应用骨架**。

- 窗口不是你写的，而是 `CWnd` 包装的 `HWND`
- 消息循环不用你写，`CWinApp::Run()` 提供
- `WndProc` 的巨型 switch 不用你写，消息映射机制替你分发
- 打开/保存文件的菜单命令（Doc/View 下）不用你写，框架自带

MFC 本身**不新造概念**：你在 MFC 里写的每一个类，背后都是第 12 章之前的那个纯 Win32 世界。所以 MFC 是理解 Windows 窗口机制最好的跳板——API 没有藏起来，只是被组织好了。

## 2. 2026 年还该学/用 MFC 吗

该用的场合：

- 维护存量代码。大量企业内部软件、工业软件、医疗影像、金融终端还是 MFC 写的
- 需要一个**极小的原生 exe**：MFC 静态链接可以做几百 KB 的完整 GUI 程序，没有 .NET 运行时、没有浏览器内核
- 和 Win32 API 深度交互的场景（钩子、自绘、驱动配套工具）

不该用的场合：

- 全新互联网产品、跨平台需求 → Qt / Electron / Web
- 现代触控风格 UI → WinUI 3 / WPF

学习价值：MFC 是"穿着面向对象外衣的 Win32"，学懂它，你就同时懂了消息循环、GDI、资源、DLL 和 C++ 对象生命周期管理。

## 3. 开发环境

本教程使用的本机工具链：

| 组件 | 路径 / 版本 |
|---|---|
| Visual Studio | G:\Program Files\Microsoft Visual Studio\18\Community |
| MSVC | 14.51.36231 |
| Windows SDK | 10.0.26100.0 |
| MFC 头文件/库 | MSVC 目录下 `atlmfc\include`、`atlmfc\lib\x64` |

MFC 是 VS 的可选组件，安装时勾选 "适用于最新 v143 生成工具的 C++ MFC" 即可（VS18 版本号不同但选项类似）。

## 4. 用命令行构建 MFC 程序

VS 向导生成的工程有几百行 vcxproj，但 MFC 程序的本质只需要：**cl 编译 → rc 编资源 → link 链接**。本目录的 `build.ps1` 就是这么做的：

```powershell
cd G:\code\guide\mfc
.\build.ps1 -All              # 构建全部示例（编译 + 资源 + 链接）
.\build.ps1 -File 03_resources   # 只构建一个示例
.\build.ps1 -Clean            # 清理 build 目录
```

产物在 `build\<示例名>.exe`，可以直接双击运行。

关键的编译选项及其含义：

```text
cl /std:c++20 /EHsc /DUNICODE /D_UNICODE /D_AFXDLL /MD /utf-8 /D_WIN32_WINNT=0x0A00 /c main.cpp

/D_AFXDLL    使用 MFC 动态库（mfc140u.dll），exe 小；去掉则用静态 MFC
/DUNICODE    Unicode 构建，TCHAR = wchar_t，这是现代 MFC 的默认姿势
/MD          使用多线程 DLL 运行时（与 _AFXDLL 配套）
/utf-8       源码按 UTF-8 解析，中文注释和字符串不再依赖系统代码页
```

链接阶段两个容易踩的坑：

1. **入口点**：Unicode MFC 的入口是 `wWinMainCRTStartup`（`_tWinMain` 在 Unicode 下就是 `wWinMain`），必须显式 `/ENTRY:wWinMainCRTStartup`，否则报"无法解析的外部符号 WinMain"
2. **资源编译器**：rc.exe 在 Windows SDK 的 `bin\<版本>\x64` 下；`.rc` 文件含中文时用 `/c65001` 指定 UTF-8 代码页

## 5. 本教程的结构

- 每章一个目录 `examples/NN_<名字>/`，构建脚本会编译它并生成 exe
- `docs/` 是各章正文，示例代码全部在正文中讲解过
- 第 13 章是一个完整实战项目 `12_notepad_plus`，把所有知识点串起来

## 6. 第一个程序

`examples/01_hello_mfc` 是最小的可运行 MFC 程序（60 行）：

```cpp
#include <afxwin.h>

class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        Create(NULL, _T("MFC Hello"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 640, 420));
    }
    afx_msg void OnPaint() {
        CPaintDC dc(this);
        dc.DrawText(_T("Hello, MFC!"), -1, CRect(24, 24, 400, 200), DT_LEFT);
    }
    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_PAINT()
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMainWindow();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
```

三个关键角色：

| 角色 | 谁 | 职责 |
|---|---|---|
| 应用对象 | `CMyApp theApp`（全局） | 程序入口，管理消息循环 |
| 主窗口 | `CMainWindow`（框架窗口） | 标题栏/边框/客户区容器 |
| 绘制 | `OnPaint` + `CPaintDC` | 每次需要重绘时被调用 |

下一章详细拆解这个骨架的启动流程。

---
上一章：无 ｜ 下一章：[02 应用骨架与消息循环](02-app-lifecycle.md)
