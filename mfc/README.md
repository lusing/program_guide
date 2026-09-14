# MFC 开发指南示例集

本目录按 `guide` 统一标准整理了 MFC（Microsoft Foundation Classes）教程中的可编译示例，并使用本机 Visual Studio VC 工具链进行验证。

## 目录结构

```text
mfc/
├── README.md
├── MFC开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello_mfc/
│   │   └── main.cpp
│   ├── 02_dialog_demo/
│   │   └── main.cpp
│   ├── 03_controls_demo/
│   │   └── main.cpp
│   ├── 04_docview_demo/
│   │   └── main.cpp
│   ├── 05_menu_toolbar_demo/
│   │   └── main.cpp
│   └── 06_graphics_demo/
│       └── main.cpp
├── build/
└── ...
```

## 工具链

- Visual Studio VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`
- MFC 库：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\atlmfc\lib\x64`
- Windows SDK：`C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0`

## 编译与验证

```powershell
cd G:\code\guide\mfc
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -File 03_controls_demo\main.cpp
```

清理：

```powershell
.\build.ps1 -Clean
```

## 示例说明

- `01_hello_mfc`：MFC 最小窗口骨架，展示 `CWinApp` + `CFrameWnd` 的典型结构。
- `02_dialog_demo`：对话框、消息处理和窗口初始化基础。
- `03_controls_demo`：演示主要控件的创建和布局，包括 `CButton`、`CEdit`、`CComboBox`、`CListBox`、`CSliderCtrl` 与 `CProgressCtrl`。
- `04_docview_demo`：展示 `CDocument` / `CView` / `CFrameWnd` / `CWinApp` 的完整架构思路，以及 `Serialize()` 与 `OnDraw()` 的职责分工。
- `05_menu_toolbar_demo`：演示菜单、命令处理和工具栏的创建方式，以及命令消息映射。
- `06_graphics_demo`：展示 GDI 绘图基础，包括 `CPaintDC`、矩形、圆形、字体和颜色填充。

## 说明

- MFC 是微软提供的 C++ 窗体开发框架，适合 Windows 桌面应用开发。
- 本目录采用本机 MSVC / MFC 工具链进行编译验证，确保示例在当前 Windows 环境中能正确通过语法和类型检查。
- 由于 MFC 是典型的桌面 GUI 框架，本文档以编译验证为主；在无桌面会话的环境中不直接运行窗口程序，但保证代码能被本机编译器成功编译。
- 目前的示例重点放在“核心框架 + 主流控件 + 菜单/工具栏 + 对话框 + 图形绘制 + Doc/View 设计”几部分，以便形成系统的 MFC 学习路径。
