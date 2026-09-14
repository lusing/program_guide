# MFC 开发指南

> 本教程面向 Windows 桌面开发，使用 Microsoft Foundation Classes（MFC）来构建基于窗口的应用程序。它适合传统 Win32 环境、企业管理软件、文本编辑器、工具类程序和大型桌面应用。由于 MFC 示例本质上是桌面 GUI 程序，本目录以本机编译验证为主，保证在当前 Visual Studio / VC 环境中可以正确编译。

## 1. 什么是 MFC

MFC 是 Microsoft Foundation Classes 的缩写，是一套面向 Windows 的 C++ 类库。它基于 Win32 API 之上，进一步封装了窗口、消息、资源、菜单、对话框、控件和文档/视图架构。

MFC 的核心特点：

- 基于消息驱动的程序模型
- 统一封装 Win32 API
- 提供 `CWinApp`、`CFrameWnd`、`CDialog`、`CView`、`CDocument` 等核心对象
- 易于维护大型桌面应用程序
- 与 Visual Studio 完整集成，适合传统 Windows 业务软件开发

## 2. 典型 MFC 程序结构

最小的 MFC 程序通常至少包含：

1. 一个继承自 `CWinApp` 的应用对象
2. 一个继承自 `CFrameWnd` 或 `CDialog` 的窗口对象
3. `InitInstance()` 中创建和显示主窗口
4. `Run()` 由 MFC 框架管理消息循环

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

## 3. MFC 核心对象

### 3.1 `CWinApp`

`CWinApp` 表示整个应用程序。它负责：

- 程序初始化
- 主消息循环入口
- 资源与命令行参数入口
- 应用全局状态管理

一个典型的 MFC 应用一般只有一个全局应用对象：

```cpp
class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        // 创建窗口、加载配置、设置全局状态
        return TRUE;
    }
};

CMyApp theApp;
```

### 3.2 `CFrameWnd`

`CFrameWnd` 是主窗口类。它封装了 Windows 框架窗口的行为：

- 标题栏与菜单
- 任务栏绑定
- 窗口大小与位置
- 系统消息处理

`Create()` 用于创建窗口实例，`ShowWindow()` 用于显示。

### 3.3 `CDialog`

`CDialog` 是对话框类，用于：

- 设置页
- 文件/路径对话框
- 确认对话框
- 配置表单

它通常通过资源模板进行布局，也可通过编程创建。

### 3.4 `CButton` / `CEdit` / `CStatic` / `CListBox` / `CComboBox`

这些都是 MFC 控件类，代表标准 Windows 控件。控件通常：

- 在窗口中创建
- 绑定资源 ID
- 通过消息处理函数响应事件
- 在 `Create()` 中指定位置、样式和父窗口

## 4. Windows 消息与消息映射

MFC 最核心的思想之一是消息映射（message map）。它避免了手工写 `WndProc` 这种冗长代码。

示例：

```cpp
BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_PAINT()
    ON_WM_LBUTTONDOWN()
    ON_COMMAND(ID_FILE_NEW, OnFileNew)
END_MESSAGE_MAP()
```

这里的宏声明了：

- `WM_PAINT` 发送到 `OnPaint()`
- `WM_LBUTTONDOWN` 发送到 `OnLButtonDown()`
- 菜单命令 `ID_FILE_NEW` 发送到 `OnFileNew()`

这种模式非常适合桌面程序的事件处理。

## 5. MFC 常见控件与事件模型

### 5.1 按钮（`CButton`）

按钮用于用户确认，通常通过 `BN_CLICKED` 处理点击事件：

```cpp
BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_BN_CLICKED(IDC_OK_BUTTON, OnOkClicked)
END_MESSAGE_MAP()
```

### 5.2 编辑框（`CEdit`）

编辑框用于输入文本，常见样式：

- `ES_AUTOHSCROLL`
- `ES_MULTILINE`
- `ES_PASSWORD`
- `ES_READONLY`

适合收集用户输入、搜索文本、日志显示等场景。

### 5.3 静态控件（`CStatic`）

静态控件通常显示标题、说明文字、状态标签等，不参与用户输入。

### 5.4 列表框（`CListBox`）

列表框适合显示候选项，支持：

- `AddString()`
- `SetCurSel()`
- `GetCurSel()`
- 单选/多选模式

### 5.5 组合框（`CComboBox`）

组合框既可作为输入框，也可作为下拉列表。常用于：

- 选择省份/城市
- 选择文件类型
- 预设参数项

### 5.6 滑块控件（`CSliderCtrl`）

滑块控件适合：

- 音量调节
- 透明度控制
- 进度控制
- 图像缩放比调节

### 5.7 进度条（`CProgressCtrl`）

用于显示后台任务执行状态，常见 API：

- `SetRange()`
- `SetPos()`
- `StepIt()`

## 6. 主要控件的详细例程

下面给出一个较完整的控件组合示例，展示主要控件的常规创建方式。

```cpp
#include <afxwin.h>

class CControlDemoWnd : public CFrameWnd {
public:
    CControlDemoWnd() {
        Create(NULL, _T("MFC Controls Demo"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 700, 500));
    }

    int OnCreate(LPCREATESTRUCT lpCreateStruct) override {
        CFrameWnd::OnCreate(lpCreateStruct);

        CStatic* label = new CStatic();
        label->Create(_T("用户名："), WS_CHILD | WS_VISIBLE | SS_LEFT,
                      CRect(20, 20, 120, 40), this, 1001);

        CEdit* edit = new CEdit();
        edit->Create(WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
                     CRect(130, 20, 260, 40), this, 1002);

        CButton* btn = new CButton();
        btn->Create(_T("确认"), WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                    CRect(270, 20, 340, 42), this, 1003);

        CComboBox* combo = new CComboBox();
        combo->Create(WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST,
                      CRect(20, 70, 180, 150), this, 1004);
        combo->AddString(_T("Windows"));
        combo->AddString(_T("MFC"));
        combo->AddString(_T("Doc/View"));
        combo->SetCurSel(0);

        CListBox* list = new CListBox();
        list->Create(WS_CHILD | WS_VISIBLE | LBS_NOTIFY,
                     CRect(200, 70, 360, 180), this, 1005);
        list->AddString(_T("Button"));
        list->AddString(_T("Edit"));
        list->AddString(_T("ListBox"));

        CSliderCtrl* slider = new CSliderCtrl();
        slider->Create(WS_CHILD | WS_VISIBLE | TBS_HORZ,
                      CRect(20, 210, 260, 240), this, 1006);

        CProgressCtrl* progress = new CProgressCtrl();
        progress->Create(WS_CHILD | WS_VISIBLE | PBS_SMOOTH,
                         CRect(20, 250, 260, 280), this, 1007);
        progress->SetRange(0, 100);
        progress->SetPos(65);

        return 0;
    }

    afx_msg void OnClickedButton() {
        AfxMessageBox(_T("确认按钮已点击"));
    }

    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CControlDemoWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_BN_CLICKED(1003, OnClickedButton)
END_MESSAGE_MAP()

class CApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CControlDemoWnd();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CApp theApp;
```

这个例子展示：

- 窗口创建与控件布局
- `OnCreate()` 中初始化子控件
- 命令事件 `ON_BN_CLICKED`
- `CComboBox`、`CListBox`、`CSliderCtrl`、`CProgressCtrl` 的常见用法

## 7. 对话框与资源绑定

MFC 的对话框通常和资源文件绑定。典型做法是：

1. 在资源编辑器中设计对话框模板
2. 生成 `IDD_*` 资源 ID
3. 创建一个 `CDialog` 派生类
4. 通过 `DoModal()` 显示对话框

示例：

```cpp
class CMyDialog : public CDialog {
public:
    CMyDialog() : CDialog(IDD_DIALOG1) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        SetWindowText(_T("设置对话框"));
        return TRUE;
    }
};
```

### `DoModal()` 的典型用法

```cpp
CMyDialog dlg;
if (dlg.DoModal() == IDOK) {
    // 用户点击 OK
}
```

这使得 MFC 非常适合做配置窗口、参数输入窗口和工具设置窗口。

## 8. MFC 的文档 / 视图（Doc/View）结构

### 8.1 设计背景

MFC 的文档/视图结构是面向“数据 + 展示 + 编辑”的典型架构。它适合：

- 文本编辑器
- 图形绘制程序
- CAD/图像浏览器
- 数据表格程序
- 简单的桌面设计工具

它把程序拆分成三部分：

- `CDocument`：文档数据模型
- `CView`：视图显示层
- `CFrameWnd`：主窗口框架

### 8.2 分层职责

#### `CDocument`

负责维护“数据状态”，例如：

- 当前文档内容
- 配置参数
- 文件内容
- 需要序列化保存的数据

关键方法：

- `Serialize(CArchive&)`
- `OnNewDocument()`
- `OnOpenDocument()`
- `UpdateAllViews()`

#### `CView`

负责“显示和编辑”，例如：

- 绘制图形
- 处理鼠标事件
- 显示文档状态
- 调用 `GetDocument()` 获取数据

关键方法：

- `OnDraw(CDC*)`
- `OnUpdate()`
- `OnInitialUpdate()`
- `GetDocument()`

#### `CFrameWnd`

负责：

- 主窗口布局
- 菜单和工具栏
- 视图容器
- 状态栏与命令入口

### 8.3 Doc/View 工作流

典型流程：

1. 用户打开文件，`CDocument` 读取数据
2. `CView` 通过 `GetDocument()` 读取数据
3. `CView::OnDraw()` 渲染内容
4. 用户编辑数据时，文档更新
5. `UpdateAllViews()` 通知所有视图刷新

### 8.4 Serialize 与持久化

MFC 用 `Serialize()` 来实现对象持久化：

```cpp
void CMyDoc::Serialize(CArchive& ar) {
    if (ar.IsStoring()) {
        ar << m_text;
    } else {
        ar >> m_text;
    }
}
```

如果做文本编辑器、配置编辑器或自定义数据文件，可以把对象持久化写到这里。

### 8.5 一个完整的 Doc/View 结构例程

```cpp
#include <afxwin.h>

class CMyDocument : public CDocument {
public:
    CString m_text = _T("Hello Doc/View");

    void Serialize(CArchive& ar) override {
        if (ar.IsStoring()) {
            ar << m_text;
        } else {
            ar >> m_text;
        }
    }
};

class CMyView : public CView {
public:
    DECLARE_DYNCREATE(CMyView)

    void OnDraw(CDC* pDC) override {
        CString msg = _T("Doc/View Demo");
        pDC->TextOut(20, 20, msg);
    }

    void OnInitialUpdate() override {
        CView::OnInitialUpdate();
    }

    void Serialize(CArchive& ar) override {
        GetDocument()->Serialize(ar);
    }
};

IMPLEMENT_DYNCREATE(CMyView, CView)

class CMyFrame : public CFrameWnd {
public:
    CMyFrame() {
        Create(NULL, _T("Doc/View Demo"), WS_OVERLAPPEDWINDOW,
               CRect(120, 120, 700, 500));
    }
};

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMyFrame();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
```

这个例程说明：

- 应用对象负责启动
- 框架窗口负责显示
- 文档对象负责保存数据
- 视图对象负责绘制和展示

## 9. Doc/View 设计的优点

Doc/View 架构特别适合：

- 多视图同一数据源
- 数据与界面分离
- 文件打开/保存与绘图逻辑结构清晰
- 后续扩展表格、树控件、绘图窗口更加方便

## 10. 菜单、工具栏和命令处理

菜单和工具栏是桌面应用最基础、最重要的交互入口之一。MFC 提供了完整的命令消息机制：菜单项和工具栏按钮都可以映射到相同的命令 ID，再由 `ON_COMMAND` / `ON_UPDATE_COMMAND_UI` 等宏统一分发。

### 10.1 菜单的职责

菜单通常承担：

- 文件操作：新建、打开、保存、退出
- 编辑操作：复制、粘贴、撤销
- 视图切换：显示/隐藏工具栏、状态栏
- 帮助命令：关于、说明

在 MFC 中，最典型的菜单结构是：

```cpp
class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        Create(NULL, _T("Menu Demo"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 600, 420));
    }

    afx_msg void OnFileOpen() {
        AfxMessageBox(_T("打开文件"));
    }

    afx_msg void OnFileExit() {
        PostMessage(WM_CLOSE);
    }

    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_COMMAND(ID_FILE_OPEN, OnFileOpen)
    ON_COMMAND(ID_APP_EXIT, OnFileExit)
END_MESSAGE_MAP()
```

这里 `ID_FILE_OPEN`、`ID_APP_EXIT` 是命令 ID。用户点击菜单项时，系统会自动触发对应消息映射。这样做的好处是：

- 命令行为集中在一个地方维护
- 菜单、工具栏、快捷键可共用同一命令 ID
- 代码结构更清晰，利于扩展

### 10.2 工具栏的职责

工具栏用于提供快捷操作入口，通常和菜单项对应：

- 新建
- 打开
- 保存
- 打印
- 复制/粘贴

工具栏的优势是：

- 操作更快
- 可视化入口更明确
- 不需要用户记住菜单层级

MFC 中工具栏通常由 `CToolBar` 创建，并通过 `CreateEx()`、`SetButtons()` 或 `AddButtons()` 安装按钮。每个按钮推荐绑定一个命令 ID，和菜单保持一致，这样工具栏点击和菜单点击会执行同一段逻辑。

### 10.3 菜单和工具栏的统一思想

一个成熟的 MFC 应用中，菜单与工具栏不是两套独立代码，而是同一组命令的不同展示形式：

- 菜单体现完整功能列表
- 工具栏体现最常用快捷功能
- 快捷键体现高频操作语义

对程序架构来说，这保证了：

- 用户体验一致
- 命令逻辑被复用
- 维护成本大幅下降

### 10.4 一个完整的菜单和工具栏例程

```cpp
#include <afxwin.h>
#include <afxext.h>

#define IDM_FILE_NEW  1001
#define IDM_FILE_OPEN 1002
#define IDM_FILE_SAVE 1003
#define IDM_FILE_EXIT 1004

class CMenuToolbarWnd : public CFrameWnd {
public:
    CMenuToolbarWnd() {
        Create(NULL, _T("Menu and Toolbar Demo"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 720, 500));
    }

    int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        CFrameWnd::OnCreate(lpCreateStruct);

        CMenu menu;
        menu.CreateMenu();
        menu.AppendMenu(MF_STRING, IDM_FILE_NEW, _T("新建(&N)"));
        menu.AppendMenu(MF_STRING, IDM_FILE_OPEN, _T("打开(&O)"));
        menu.AppendMenu(MF_STRING, IDM_FILE_SAVE, _T("保存(&S)"));
        menu.AppendMenu(MF_SEPARATOR, 0, NULL);
        menu.AppendMenu(MF_STRING, IDM_FILE_EXIT, _T("退出(&X)"));
        SetMenu(&menu);

        if (!m_toolbar.CreateEx(this, TBSTYLE_FLAT, WS_CHILD | WS_VISIBLE | CBRS_TOP | CBRS_TOOLTIPS,
                                CRect(0, 0, 0, 0), 0x9999)) {
            return -1;
        }

        TBBUTTON btns[] = {
            { MAKELONG(0, 0), IDM_FILE_NEW, TBSTATE_ENABLED, TBSTYLE_BUTTON, 0, 0, 0 },
            { MAKELONG(0, 0), IDM_FILE_OPEN, TBSTATE_ENABLED, TBSTYLE_BUTTON, 0, 0, 0 },
            { MAKELONG(0, 0), IDM_FILE_SAVE, TBSTATE_ENABLED, TBSTYLE_BUTTON, 0, 0, 0 },
            { MAKELONG(0, 0), IDM_FILE_EXIT, TBSTATE_ENABLED, TBSTYLE_BUTTON, 0, 0, 0 }
        };

        m_toolbar.AddButtons(_countof(btns), btns);
        m_toolbar.EnableWindow(TRUE);
        return 0;
    }

    afx_msg void OnFileNew() { AfxMessageBox(_T("新建命令")); }
    afx_msg void OnFileOpen() { AfxMessageBox(_T("打开命令")); }
    afx_msg void OnFileSave() { AfxMessageBox(_T("保存命令")); }
    afx_msg void OnFileExit() { PostMessage(WM_CLOSE); }

    DECLARE_MESSAGE_MAP()

private:
    CToolBar m_toolbar;
};

BEGIN_MESSAGE_MAP(CMenuToolbarWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_COMMAND(IDM_FILE_NEW, OnFileNew)
    ON_COMMAND(IDM_FILE_OPEN, OnFileOpen)
    ON_COMMAND(IDM_FILE_SAVE, OnFileSave)
    ON_COMMAND(IDM_FILE_EXIT, OnFileExit)
END_MESSAGE_MAP()

class CMenuToolbarApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMenuToolbarWnd();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMenuToolbarApp theApp;
```

这段示例说明了：

- 菜单项与命令 ID 的绑定方式
- 工具栏按钮与命令 ID 的绑定方式
- 事件处理如何集中在 `ON_COMMAND` 中
- 让菜单和工具栏共享同一套逻辑

## 11. 对话框与数据交换

对话框是 MFC 最常见的交互单元之一。它用于：

- 用户输入
- 参数设置
- 确认和错误提示
- 搜索/过滤器配置
- 分页任务窗口

### 11.1 对话框的核心角色

对话框通常承担以下职责：

- 收集用户输入
- 校验字段合法性
- 反馈状态信息
- 在用户确认后把数据回传到主窗口或文档

### 11.2 `CDialog` 与消息映射

最常见的方式是：

```cpp
class CSettingDialog : public CDialog {
public:
    CSettingDialog() : CDialog(IDD_SETTINGS) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        SetWindowText(_T("设置"));
        return TRUE;
    }
};
```

用户点击 `OK` 或 `Cancel` 会触发标准对话框消息，而你可以在派生类中处理 `OnOK()`、`OnCancel()` 或自定义按钮事件。

### 11.3 对话框数据交换（DDX）

MFC 的对话框能力非常强大，尤其是 DDX（Dialog Data Exchange）机制。它允许你：

- 把控件值绑定到 C++ 变量
- 让窗口中输入和代码变量同步
- 简化配置窗口实现

例子：

```cpp
class CConfigDialog : public CDialog {
public:
    CConfigDialog() : CDialog(IDD_CONFIG) {}

    int m_port = 8080;
    CString m_title;

    void DoDataExchange(CDataExchange* pDX) override {
        CDialog::DoDataExchange(pDX);
        DDX_Text(pDX, IDC_EDIT_PORT, m_port);
        DDX_Text(pDX, IDC_EDIT_TITLE, m_title);
    }
};
```

DDX 的价值在于：

- 让窗口和数据对象保持一致
- 减少手工读取/写入控件值的代码
- 让对话框更像真正的“表单窗口”

### 11.4 对话框与主窗口配合流程

典型流程：

1. 主窗口响应菜单命令或按钮点击
2. 创建 `CDialog` 派生类对象
3. 调用 `DoModal()` 进入模态对话框
4. 用户输入完成，确认或取消
5. 主窗口读取对话框数据并更新状态

这使 MFC 非常适合：

- 设置窗口
- 预设参数窗口
- 过滤器窗口
- 批量编辑表单

## 12. 图形绘制与 GDI

图形绘制是桌面应用核心能力之一。MFC 使用 GDI（Graphics Device Interface）绘制图形、文本和可视化元素。

### 12.1 `OnPaint` 与 `CPaintDC`

所有窗口绘制都依赖消息循环中的 `WM_PAINT`，通常代码写在 `OnPaint()` 中：

```cpp
afx_msg void OnPaint() {
    CPaintDC dc(this);
    CRect rect;
    GetClientRect(&rect);
    dc.FillSolidRect(rect, RGB(240, 245, 255));
}
```

`CPaintDC` 是 MFC 对 GDI 的封装，负责：

- 进入绘图上下文
- 处理无效区域重绘
- 支持对窗口区域进行绘制

### 12.2 常见绘图对象

GDI 中常见对象包括：

- `CBrush`：填充刷子
- `CPen`：线条笔
- `CFont`：字体对象
- `CBitmap`：位图对象
- `CRect`：矩形对象

### 12.3 基本绘图示例

```cpp
class CGraphicsWnd : public CFrameWnd {
public:
    CGraphicsWnd() {
        Create(NULL, _T("Graphics Demo"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 650, 420));
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect client;
        GetClientRect(&client);

        dc.FillSolidRect(client, RGB(245, 245, 245));

        CBrush brush(RGB(70, 130, 180));
        dc.SelectObject(&brush);
        dc.Ellipse(60, 60, 240, 180);

        CPen pen(PS_SOLID, 3, RGB(255, 100, 0));
        dc.SelectObject(&pen);
        dc.Rectangle(300, 80, 520, 220);

        dc.SetTextColor(RGB(30, 30, 30));
        dc.TextOutW(80, 220, _T("MFC GDI 绘图"));
    }

    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CGraphicsWnd, CFrameWnd)
    ON_WM_PAINT()
END_MESSAGE_MAP()
```

这个例子展示了：

- 背景填充
- 圆形绘制
- 矩形绘制
- 文本输出
- 颜色和笔刷/画笔使用

### 12.4 为什么图形绘制很重要

在桌面应用中，几乎所有的视图和编辑器都依赖图形绘制：

- 文本编辑器中的光标和选区
- CAD/图像查看器中的图元绘制
- 数据曲线图表
- 统计图表、仪表盘、控件主题

如果没有 `OnPaint` 和 GDI，在 MFC 中很难做出优雅的可视化界面。

### 12.5 实战建议

- 不要在 `OnPaint` 中做过重逻辑，避免重复绘制
- 对可变内容使用模型驱动更新
- 对复杂 UI 采用缓存绘制思路
- 在 `CView::OnDraw()` 中组织业务数据和绘图逻辑

## 13. 一个实战式的 MFC 开发思路

如果要开发一个真实桌面应用，通常推荐：

1. 用 `CWinApp` 启动应用
2. 用 `CFrameWnd` 或 `CDialog` 建立主窗口
3. 用菜单和工具栏暴露功能入口
4. 用控件实现用户交互
5. 用 `CDocument` / `CView` 维护数据与展示分离
6. 对配置项使用对话框收集输入
7. 定期通过 `OnPaint` / `OnDraw` 刷新视图

这套顺序很接近典型 Windows 桌面开发实践，也能帮助你从“会写一个窗口”逐步成长为“能做一个工程项目”的开发者。

## 14. 本目录中的示例

本目录中的示例会逐步展示：

- `01_hello_mfc`：最小 MFC 程序骨架
- `02_dialog_demo`：对话框与消息处理基础
- `03_controls_demo`：主要控件的组合示例
- `04_docview_demo`：完整的 Doc/View 结构思路与骨架实现
- `05_menu_toolbar_demo`：菜单、工具栏和命令处理详解
- `06_graphics_demo`：GDI 图形绘制基础

这些示例都按本机 Visual Studio 工具链进行编译验证，并尽量保持与当前安装版本兼容。
