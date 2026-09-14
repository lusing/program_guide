# Win32 API 开发指南示例集

本目录按 `guide` 统一标准整理了 Win32 API 教程中的可编译示例，并使用本机 Visual Studio VC 工具链进行验证。

## 目录结构

```text
win32/
├── README.md
├── Win32 API开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello_window/
│   │   └── main.cpp
│   ├── 02_message_loop/
│   │   └── main.cpp
│   ├── 03_controls/
│   │   └── main.cpp
│   ├── 04_gdi_drawing/
│   │   └── main.cpp
│   ├── 05_mini_calculator/
│   │   └── main.cpp
│   ├── 06_text_editor/
│   │   └── main.cpp
│   ├── 07_paint_app/
│   │   └── main.cpp
│   ├── 08_process_manager/
│   │   └── main.cpp
│   ├── 09_memory_monitor/
│   │   └── main.cpp
│   ├── 10_file_manager/
│   │   └── main.cpp
│   └── 11_thread_sync_demo/
│       └── main.cpp
├── build/
└── ...
```

## 工具链

- Visual Studio VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`
- MSVC SDK：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\include`
- Windows SDK：`C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0`

## 编译与验证

```powershell
cd G:\code\guide\win32
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -File 02_message_loop\main.cpp
```

清理：

```powershell
.\build.ps1 -Clean
```

## 示例说明

- `01_hello_window`：WinMain + RegisterClass + CreateWindow + 消息循环的最小窗口应用。
- `02_message_loop`：处理 `WM_LBUTTONDOWN`、`WM_MOUSEMOVE`、`WM_CHAR` 等消息示例。
- `03_controls`：使用 `CreateWindowW` 创建按钮、编辑框和静态文本控件。
- `04_gdi_drawing`：使用 GDI 在 `WM_PAINT` 中绘制矩形、圆形和文本。
- `05_mini_calculator`：完整的简单计算器，展示窗口布局、按钮事件与计算逻辑。
- `06_text_editor`：完整的文本编辑器，展示菜单、编辑框、打开/保存文件与文件 I/O。
- `07_paint_app`：完整的绘图程序，展示鼠标拖拽、连续线条和 GDI 重绘。
- `08_process_manager`：基于 `CreateToolhelp32Snapshot` 和 `Process32First/Next` 的进程枚举示例。
- `09_memory_monitor`：使用 `GlobalMemoryStatusEx`、`VirtualAlloc` 和 `VirtualFree` 的内存状态与分配示例。
- `10_file_manager`：演示 `CreateFileW`、`WriteFile`、`FindFirstFileW` 等文件管理 API 的实际用法。
- `11_thread_sync_demo`：演示 `CreateThread`、`CRITICAL_SECTION`、事件对象和 `WaitForSingleObject` 的线程同步与 UI 消息回传模式。

## 说明

- Win32 API 是 Windows 平台上的底层编程接口，适合理解窗口消息、控件和 GDI 的核心机制。
- 本目录采用本机 MSVC 工具链进行编译验证，保证示例在当前环境中能通过实际编译。
- 由于窗口程序依赖桌面环境，本文档以编译验证为主；在无桌面会话环境下不直接运行窗口，但确保代码可通过本机编译器成功构建。
