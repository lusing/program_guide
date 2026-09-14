# MFC 开发指南

> 本教程面向 Windows 桌面开发，使用 Microsoft Foundation Classes（MFC）来构建基于窗口的应用程序。

## 1. 什么是 MFC

MFC 是 Microsoft Foundation Classes 的缩写，提供了一组 C++ 封装类，用于快速构建 Win32 窗体程序。它在 Windows 平台上抽象了窗口、消息、资源、对话框和文档/视图等概念。

MFC 的核心特点：

- 基于 Windows 消息循环
- 统一封装 Win32 API
- 提供 `CWinApp`、`CFrameWnd`、`CDialog` 等核心类
- 适合传统桌面应用开发
- 与 Visual Studio 集成度高

## 2. 典型 MFC 程序结构

最小的 MFC 程序通常至少包含：

1. 一个继承自 `CWinApp` 的应用对象
2. 一个继承自 `CFrameWnd` 的主窗口类
3. `InitInstance()` 中创建窗口并显示
4. `Run()` 由 MFC 自动管理消息循环

示例代码：

```cpp
#include <afxwin.h>

class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        Create(NULL, _T("MFC Hello"));
    }
};

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMainWindow();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
```

这段代码展示了 MFC 的最小骨架：应用对象 `theApp`、框架窗口 `CFrameWnd` 和窗口初始化流程。

## 3. MFC 中的基本对象

### 3.1 `CWinApp`

`CWinApp` 表示整个应用程序。它负责全局初始化、资源加载、消息循环入口等。通常只需要派生一个应用类，并在其中覆写 `InitInstance()`。

### 3.2 `CFrameWnd`

`CFrameWnd` 是主窗口类。它提供窗口标题栏、系统菜单、边框和标准的窗体行为。应用程序中通常会通过它创建和管理主窗体。

### 3.3 `CDialog`

`CDialog` 用于对话框类，适合做设置页、输入对话、确认框等界面。MFC 还支持资源脚本和对话框模板。

## 4. Windows 消息与消息映射

MFC 最重要的设计之一是消息映射机制。它不要求手工写大量 `WndProc`，而是采用宏来生成消息处理入口。

例如：

```cpp
BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_PAINT()
    ON_WM_LBUTTONDOWN()
END_MESSAGE_MAP()
```

这些消息映射会让 MFC 自动分发 `WM_PAINT`、`WM_LBUTTONDOWN` 等消息到对应函数。

## 5. 资源与对话框

MFC 常见项目类型包括：

- SDI / MDI 程序
- 对话框应用
- 文档/视图架构（Doc/View）
- 资源文件（*.rc）

MFC 对资源文件的支持非常成熟，尤其适用于传统 Windows 桌面界面应用。

## 6. 常见开发模式

### 6.1 单文档界面（SDI）

适合单窗口编辑或展示型应用。

### 6.2 多文档界面（MDI）

适合多个文档窗口并排显示的应用。

### 6.3 对话框应用

适合向用户收集输入，配置参数或执行简单任务。

### 6.4 文档/视图架构

适合复杂桌面软件，能够清晰分离数据和显示逻辑。

## 7. 一个更完整的 “Hello MFC” 示例

```cpp
#include <afxwin.h>

class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        Create(NULL, _T("Hello MFC"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 500, 350));
    }

    afx_msg void OnLButtonDown(UINT, CPoint point) {
        MessageBox(_T("鼠标点击窗口!"));
    }

    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_LBUTTONDOWN()
END_MESSAGE_MAP()

class CApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMainWindow();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CApp theApp;
```

这个示例展示了：

- 主窗口创建
- 标题设置
- 消息处理
- 应用启动入口

## 8. MFC 开发建议

- 先理解 Win32 消息模型，再学习 MFC 封装
- 以 `CWinApp` / `CFrameWnd` / `CDialog` 作为基础对象建立认知
- 关注资源管理、消息映射和控件生命周期
- 在 Windows 桌面应用中保持 UI 与业务逻辑分离

## 9. 适用场景

MFC 适用于：

- 传统 Windows 桌面应用
- 企业管理软件
- 工具类应用
- 需要兼容旧版 Windows 程序的场景

## 10. 本目录中的示例

本目录中的示例会逐步展示：

- `01_hello_mfc`：最小 MFC 程序骨架
- `02_dialog_demo`：对话框与消息处理基础

这些示例都按本机 Visual Studio 工具链进行编译验证，尽量保持与当前安装版本兼容。
