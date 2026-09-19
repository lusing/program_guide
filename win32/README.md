# Win32 API 开发指南示例集

面向"从零到工程"的 Win32 教程。教程正文在 [docs/](docs/) 目录下按 12 章组织（目录页见 [Win32 API开发指南.md](Win32%20API开发指南.md)），本目录的可编译示例与章节一一对应，并使用本机 Visual Studio VC 工具链编译验证。

## 目录结构

```text
win32/
├── README.md                   # 本文件：结构、工具链、构建说明
├── Win32 API开发指南.md         # 教程目录页（指向 docs/ 各章）
├── build.ps1                   # 编译验证脚本
├── docs/                       # 30 章（五篇 + 收束，见目录页）
│   ├── 01-全景与发展史.md
│   ├── 02-环境搭建与第一个窗口.md
│   ├── 03-错误处理与调试.md
│   ├── 04-窗口与消息机制.md
│   ├── 05-控件基础.md
│   ├── 06-ListView与TreeView.md
│   ├── 07-更多通用控件.md
│   ├── 08-自绘与子类化.md
│   ├── 09-GDI绘图与现代显示.md
│   ├── 10-菜单对话框与资源.md
│   ├── 11-综合应用三例.md
│   ├── 12-字符编码与字符串.md
│   ├── 13-进程与作业对象.md
│   ├── 14-线程与同步.md
│   ├── 15-内存管理.md
│   ├── 16-文件系统.md
│   ├── 17-内核对象与安全.md
│   ├── 18-系统信息与定时器.md
│   ├── 19-DLL基础.md
│   ├── 20-DLL进阶与插件系统.md
│   ├── 21-注册表.md
│   ├── 22-COM入门.md
│   ├── 23-COM实战.md
│   ├── 24-COM实现.md
│   ├── 25-Direct2D与DirectWrite.md
│   ├── 26-WinRT与CppWinRT.md
│   ├── 27-Windows服务与事件日志.md
│   ├── 28-Shell集成.md
│   ├── 29-剪贴板与拖放.md
│   └── 30-现代Win32与学习路线.md
├── examples/                   # 可编译示例（见下表）
└── build/                      # 编译输出
```

## 章节与示例对照

| 示例 | 对应章节 | 演示内容 |
|------|---------|---------|
| `01_hello_window` | 02 | WinMain + RegisterClass + CreateWindow + 消息循环的最小窗口应用 |
| `02_message_loop` | 04 | `WM_LBUTTONDOWN`、`WM_MOUSEMOVE`、`WM_CHAR` 等消息处理 |
| `03_controls` | 05 | 按钮、编辑框、静态文本等原生控件的创建与 `WM_COMMAND` 事件 |
| `04_gdi_drawing` | 09 | GDI 在 `WM_PAINT` 中绘制矩形、圆形和文本 |
| `05_mini_calculator` | 11 | 完整计算器：窗口布局、按钮事件与状态机式计算逻辑 |
| `06_text_editor` | 10/11 | 完整编辑器：菜单、通用文件对话框、`CreateFileW`/`ReadFile`/`WriteFile` 文件 I/O、UTF-8 与宽字符转换 |
| `07_paint_app` | 09/11 | 绘图程序：线段状态列表 + `WM_PAINT` 全量重绘（内容不因遮挡丢失） |
| `08_process_manager` | 13 | `CreateToolhelp32Snapshot` 进程枚举、`CreateProcessW` 启动、`OpenProcess`/`TerminateProcess` 终止 |
| `09_memory_monitor` | 15 | `GlobalMemoryStatusEx` 内存状态 + 基本 `VirtualAlloc`/`VirtualFree` |
| `10_file_manager` | 16 | `CreateFileW`、`WriteFile`、`FindFirstFileW` 文件管理基础 |
| `11_thread_sync_demo` | 14 | `CRITICAL_SECTION`、`CreateThread`、`PostMessageW` 跨线程 UI 回传模式 |
| `12_memory_deep_dive` | 15 | `VirtualAlloc`/`VirtualProtect`/`HeapAlloc`/`GetProcessMemoryInfo`/文件映射 |
| `13_file_system_deep_dive` | 16 | 文件元数据、`GetFinalPathNameByHandleW`、目录枚举（大小正确拼接 High/Low） |
| `14_srwlock_demo` | 14 | 现代同步原语：SRWLock + 条件变量的生产者/消费者（控制台程序） |
| `15_dpi_modern_window` | 09 | Per-Monitor V2 DPI 感知 + Win11 圆角（DwmSetWindowAttribute） |

16~32 号示例与新增章节随扩充批次落地（共 32 个示例，终表见收束批次）。

## 工具链

- Visual Studio VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`
- MSVC SDK：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\include`
- Windows SDK：`C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0`

编译统一使用：`/std:c++20 /EHsc /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00 /utf-8`，链接 `user32 gdi32 kernel32 shell32 comctl32 psapi comdlg32 dwmapi`。定义 `wmain` 的示例按 CONSOLE 子系统编译，其余按 WINDOWS 子系统（GUI）编译。

## 编译与验证

```powershell
cd G:\code\guide\win32
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -File 02_message_loop/main.cpp
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- Win32 API 是 Windows 平台的系统服务接口，UI 部分之外，进程/线程/内存/文件等能力至今没有任何替代品——本教程按这个定位组织内容（见 docs/01 章）。
- 本目录采用本机 MSVC 工具链进行编译验证，保证示例在当前环境中能通过实际编译。
- 由于窗口程序依赖桌面环境，验证以编译为主；`14_srwlock_demo` 为控制台程序可直接运行观察输出。
- 示例目标系统为 Windows 10 1703+；涉及 Windows 11 专属视觉的调用（圆角）在老系统上自动降级。
