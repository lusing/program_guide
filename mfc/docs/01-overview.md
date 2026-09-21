# 01 · MFC 概述与开发环境

> 对应示例：`examples/01_hello_mfc`（第 7 节逐行走读）

> **本章你将学会**：MFC 是什么、它在 Windows UI 技术谱系里的位置、怎么用纯命令行构建第一个 MFC 程序，以及这条路上最容易绊倒人的三个坑。
> **前置知识**：C++ 基础语法与 Win32 窗口概念，可对照本仓库《Win32 API 桌面编程指南》第 04 章（窗口与消息循环）。

## 1. MFC 是什么

MFC（Microsoft Foundation Classes）是微软提供的 C++ 类库，把 Win32 API 封装成一套面向对象的框架。它诞生于 1992 年，比 Qt、WPF 都早，至今仍随 Visual Studio 发布并持续维护。

一句话定位：**MFC 是 Win32 API 的 C++ 外壳 + 一套现成的应用骨架**。

- 窗口不是你写的，而是 `CWnd` 包装的 `HWND`
- 消息循环不用你写，`CWinApp::Run()` 提供
- `WndProc` 的巨型 switch 不用你写，消息映射机制替你分发
- 打开/保存文件的菜单命令（Doc/View 下）不用你写，框架自带

MFC 本身**不新造概念**：你在 MFC 里写的每一个类，背后都是本仓库《Win32 API 桌面编程指南》里的那个纯 Win32 世界。所以 MFC 是理解 Windows 窗口机制最好的跳板——API 没有藏起来，只是被组织好了。

## 2. MFC 在 Windows UI 谱系中的位置

初学者常困惑：Win32、MFC、WinForms、WPF、WinUI 3，到底学哪个？先看对照表：

| | Win32 | MFC | WinForms | WPF | WinUI 3 |
|---|---|---|---|---|---|
| 语言 | C/C++ | **C++** | C# | C# | C#/C++ |
| 渲染 | GDI/User32 | **GDI** | GDI+ | DirectX | Composition |
| 界面描述 | 手工/资源脚本 | **资源脚本** | 代码 | XAML | XAML |
| 数据绑定 | 无 | **无（DDX 是快照式）** | 简陋 | 强 | 强 |
| 自定义外观 | 自绘 | **自绘** | 困难 | 模板重写 | 模板重写 |
| 运行时依赖 | 无 | **无/VC 运行库** | .NET | .NET | .NET + Windows App SDK |
| 诞生年 | 1985 | **1992** | 2002 | 2006 | 2021 |

两条演化主线帮你建立坐标系：

1. **MFC 是 Win32 的面向对象化**。它没有换渲染引擎，也没有换编程模型——消息、句柄、GDI 全都还在，只是被 `CWnd`、消息映射、Doc/View 包了起来。所以 MFC 的知识几乎可以无损地映射回 Win32，反之亦然
2. **MFC 是"声明式 UI"出现之前的最后一代**。WinForms/WPF 之后，界面描述逐渐从"资源脚本 + 代码"走向 XAML，数据绑定从"没有"变成"核心机制"。MFC 的 DDX/DDV 只是控件与变量的**一次性快照同步**，不是持续绑定——这是它与后三代最本质的差距

如果本仓库的其他教程（win32、wpf、WinUI3）你也读过，本书会频繁与它们对照——同一件事在不同框架里的做法差异，恰恰是理解每个框架设计意图的捷径。

## 3. 2026 年还该学/用 MFC 吗

该用的场合：

- 维护存量代码。大量企业内部软件、工业软件、医疗影像、金融终端还是 MFC 写的
- 需要一个**极小的原生 exe**：MFC 静态链接可以做几百 KB 的完整 GUI 程序，没有 .NET 运行时、没有浏览器内核
- 和 Win32 API 深度交互的场景（钩子、自绘、驱动配套工具）

不该用的场合：

- 全新互联网产品、跨平台需求 → Qt / Electron / Web
- 现代触控风格 UI → WinUI 3 / WPF

学习价值：MFC 是"穿着面向对象外衣的 Win32"，学懂它，你就同时懂了消息循环、GDI、资源、DLL 和 C++ 对象生命周期管理。

## 4. 开发环境

本教程使用的本机工具链：

| 组件 | 路径 / 版本 |
|---|---|
| Visual Studio | G:\Program Files\Microsoft Visual Studio\18\Community |
| MSVC | 14.51.36231 |
| Windows SDK | 10.0.26100.0 |
| MFC 头文件/库 | MSVC 目录下 `atlmfc\include`、`atlmfc\lib\x64` |

MFC 是 VS 的可选组件，安装时勾选 "适用于最新 v143 生成工具的 C++ MFC" 即可（VS18 版本号不同但选项类似）。

## 5. 用命令行构建 MFC 程序

VS 向导生成的工程有几百行 vcxproj，但 MFC 程序的本质只需要：**cl 编译 → rc 编资源 → link 链接**。本目录的 `build.ps1` 就是这么做的：

```powershell
cd G:\code\guide\mfc
.\build.ps1 -All                 # 构建全部示例（编译 + 资源 + 链接）
.\build.ps1 -File 04_resources   # 只构建一个示例
.\build.ps1 -File 25_notepad_plus -Static   # 静态链接 MFC（第 23 章详解）
.\build.ps1 -Clean               # 清理 build 目录
.\smoke.ps1                      # 冒烟：逐个拉起 exe，3 秒不崩算通过
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

## 常见坑

命令行构建 MFC 的路上，下面三个错误几乎人人都会撞一次：

1. **"无法解析的外部符号 WinMain"**
   链接时忘了 `/ENTRY:wWinMainCRTStartup`。默认入口是 `main`/`WinMain`，而 Unicode MFC 程序真正的入口是 `wWinMain`——`mfc140u.lib` 里提供了 `wWinMainCRTStartup`，但链接器不会自动去找它，必须显式指定。

2. **"无法打开文件 afxres.h" / rc.exe 找不到**
   `rc.exe` 有两个可能的来源：MSVC 自带的（在 `VC\Tools\MSVC\<ver>\bin\Hostx64\x64`）和 Windows SDK 里的（在 `Windows Kits\10\bin\<ver>\x64`）。编译 MFC 资源要用 **SDK 那份**，并且用 `/I` 显式补上 `atlmfc\include` 与 SDK 的 `um`、`shared` 目录——`afxres.h` 在 atlmfc 下，`winres.h` 系列在 SDK 下，缺一不可。

3. **"运行库不匹配"（LNK2038 / 运行时库冲突）**
   `/D_AFXDLL` 与 `/MD` 是**配套**的：动态 MFC 要求动态 CRT。只写 `/D_AFXDLL` 不写 `/MD`（或反过来写 `/MT`），链接器会在 `_ITERATOR_DEBUG_LEVEL`、`RuntimeLibrary` 这类标记上直接报错。静态 MFC 则要同时去掉 `/D_AFXDLL` 并把 `/MD` 换成 `/MT`——`build.ps1 -Static` 做的就是这件事。

## 7. 第一个程序

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

注意全篇没有 `WinMain`，也没有 `GetMessage` 循环——这两样东西都被 `CWinApp` 藏起来了。下一章把这份骨架拆开，看它们到底藏在哪一步。

## 8. 本教程的结构

- 每章一个目录 `examples/NN_<名字>/`，**章号与示例号对应**：第 04 章讲 `examples/04_resources`
- `docs/` 是各章正文，示例代码全部在正文中讲解过
- 示例代码全部被 `build.ps1` 编译验证，且用 `smoke.ps1` 做过启动冒烟（拉起 3 秒不崩）
- 第 25 章是一个完整实战项目 `25_notepad_plus`，把所有知识点串起来

学习路线按章顺序走：01-02 骨架 → 03-04 消息映射与资源 → 05-07 窗口与控件 → 08-09 控件进阶与自绘 → 10-14 对话框、剪贴板、Shell、DPI → 15-17 Doc/View → 18-19 GDI 与打印 → 20-22 多线程、调试、现代绘图 → 23-24 部署与工程化 → 25 实战。

每章末尾有"自测"，答不上来自测题就回读对应小节——比一路顺读的留存率高得多。

## 实战建议

1. **一开始就用 Unicode**。新项目直接 `/DUNICODE /D_UNICODE`，字符串一律 `_T("…")`、字符类型一律 `TCHAR`/`CString`。先写 ANSI 版再迁移是纯粹的返工——Windows 上 ANSI 代码页的坑（中文变问号、跨机器表现不一致）远比 Unicode 多
2. **源码存 UTF-8，编译加 `/utf-8`**。本仓库所有 `.cpp` 都是无 BOM 的 UTF-8，靠 `/utf-8` 告诉编译器；`.rc` 里含中文时额外给 rc.exe 加 `/c65001`。不这么做，中文会随系统区域设置时好时坏
3. **先跑通最小骨架，再往上加**。每个示例目录都是一个独立的"能编译能跑"的程序，这是刻意的：出问题时把范围缩到一个目录，比在几千行的工程里大海捞针快得多
4. **把冒烟测试当习惯**。GUI 程序的很多错误（断言、资源缺失、初始化顺序）只在启动瞬间暴露。改完代码跑一次 `smoke.ps1`，比双击 exe 靠眼睛看可靠

## 自测

1. **MFC 与 Win32 是什么关系？** —— MFC 是 Win32 API 的 C++ 封装 + 一套应用骨架，不新造概念；消息、句柄、GDI 都还在。
2. **Unicode MFC 程序的入口点是什么？为什么必须显式指定？** —— `wWinMainCRTStartup`；链接器默认找 `main`/`WinMain`，而 Unicode MFC 的入口是 `wWinMain`。
3. **`/D_AFXDLL` 与 `/MD` 是什么关系？** —— 配套关系。动态 MFC 必须配动态 CRT；混用 `/MT` 会报运行库冲突。静态 MFC 则要同时去掉 `/D_AFXDLL` 并把 `/MD` 换成 `/MT`。
4. **`.rc` 文件含中文时，rc.exe 要加什么参数？** —— `/c65001`，把资源脚本按 UTF-8 代码页解析。

---
上一章：无 ｜ 下一章：[02 应用骨架与消息循环](02-app-lifecycle.md)
