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

| 示例 | 对应章节 | 演示内容 | 形态 |
|------|---------|---------|------|
| `01_hello_window` | 02 | WinMain + RegisterClass + CreateWindow + 消息循环的最小窗口应用 | GUI |
| `02_message_loop` | 04 | `WM_LBUTTONDOWN`、`WM_MOUSEMOVE`、`WM_CHAR` 等消息处理 | GUI |
| `03_controls` | 05 | 按钮、编辑框、静态文本等原生控件的创建与 `WM_COMMAND` 事件 | GUI |
| `04_gdi_drawing` | 09 | GDI 在 `WM_PAINT` 中绘制矩形、圆形和文本 | GUI |
| `05_mini_calculator` | 11 | 完整计算器：窗口布局、按钮事件与状态机式计算逻辑 | GUI |
| `06_text_editor` | 10/11 | RichEdit 编辑器：菜单、文件对话框、文件 I/O、编码转换 | GUI |
| `07_paint_app` | 09/11 | 绘图程序：线段状态列表 + `WM_PAINT` 全量重绘 | GUI |
| `08_process_manager` | 13 | 进程快照枚举、`CreateProcessW` 启动、终止进程 | GUI |
| `09_memory_monitor` | 15 | `GlobalMemoryStatusEx` 内存状态 + 基本 `VirtualAlloc` | GUI |
| `10_file_manager` | 16 | `CreateFileW`、`WriteFile`、`FindFirstFileW` 文件管理基础 | GUI |
| `11_thread_sync_demo` | 14 | `CRITICAL_SECTION`、`CreateThread`、`PostMessageW` 跨线程回传 | GUI |
| `12_memory_deep_dive` | 15 | `VirtualAlloc`/`VirtualProtect`/堆/文件映射 | 控制台 |
| `13_file_system_deep_dive` | 16 | 文件元数据、真实路径反查、目录枚举 | 控制台 |
| `14_srwlock_demo` | 14 | SRWLock + 条件变量的生产者/消费者 | 控制台 |
| `15_dpi_modern_window` | 09 | Per-Monitor V2 DPI 感知 + Win11 圆角 | GUI |
| `16_error_handling` | 03 | GetLastError → FormatMessageW、HRESULT、SEH 四件套 | 控制台 |
| `17_listview_treeview` | 06 | ListView 报表视图 + TreeView 层级 + ImageList 共享 | GUI |
| `18_common_controls` | 07 | 工具栏/状态栏/进度条/Tab/RichEdit 五件套 | GUI |
| `19_custom_draw` | 08 | Owner Draw 按钮 + Custom Draw 隔行变色 + 子类化大写输入 | GUI |
| `20_encoding_convert` | 12 | 代码页/UTF-8 互转、非法序列检测、StrSafe | 控制台 |
| `21_security_descriptors` | 17 | 令牌/完整性级别 + 给文件写 DACL 并读回 | 控制台 |
| `22_sysinfo_timers` | 18 | 版本/系统信息/环境/QPC/可等待定时器/电源 | 控制台 |
| `23_dll_math` | 19 | 数学 DLL + 隐式链接消费者 | DLL+EXE |
| `24_dll_plugin` | 20 | 插件契约 + 双插件 DLL + 扫描加载宿主 | DLL×2+EXE |
| `25_registry_tool` | 21 | HKCU 增删改查/枚举/整树清场 | 控制台 |
| `26_com_file_dialog` | 23 | CoInitializeEx + ComPtr + IFileOpenDialog | GUI |
| `27_com_server` | 24 | 手写 COM 服务器：HKCU 注册→创建→注销全链路 | DLL+EXE |
| `28_direct2d_hello` | 25 | D2D 渐变/抗锯齿 + DWrite 文本 + resize/重建 | GUI |
| `29_winrt_modern` | 26 | C++/WinRT 投影 + C++20 协程异步 | 控制台 |
| `30_windows_service` | 27 | 最小服务五要素 + 事件日志 + console/list 双模式 | 服务 |
| `31_shell_tray` | 28 | 托盘图标 + 右键菜单 + 气泡 + Explorer 重启自愈 | GUI |
| `32_clipboard_dnd` | 29 | 剪贴板全链路 + WM_DROPFILES + 手写 IDropTarget | GUI |

## 工具链

- Visual Studio VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat`
- MSVC SDK：`G:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.51.36231\include`
- Windows SDK：`C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0`

编译统一使用：`/std:c++20 /EHsc /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0A00 /utf-8`，链接 `user32 gdi32 kernel32 shell32 comctl32 psapi comdlg32 dwmapi ole32 oleaut32 uuid advapi32 d2d1 dwrite`。定义 `wmain` 的示例按 CONSOLE 子系统编译，其余按 WINDOWS 子系统（GUI）编译。

**多目标工程**：23/24/27/29 号示例（DLL/COM/WinRT 工程）自带子 `build.ps1`（纯 ASCII，无 BOM 依赖），根脚本遍历时自动委托——子脚本负责"DLL→导入库→消费者 exe"的多步构建并内含运行验证。29 号额外使用 SDK 的 cppwinrt 头与 `WindowsApp.lib`（子脚本自动探测 SDK）。

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

- Win32 API 是 Windows 平台的系统服务接口，UI 部分之外，进程/线程/内存/文件/DLL/COM/安全等能力至今没有任何替代品——本教程按这个定位组织内容（见 docs/01 章）。
- 本目录采用本机 MSVC 工具链进行编译验证，保证示例在当前环境中能通过实际编译。
- 验证分级：控制台示例（12/13/14/16/20/21/22/25/29/30）实际运行核对输出；多目标工程（23/24/27）内含运行验证（DLL 消费者实跑、COM 注册→创建→注销全链路，HKCU 免管理员、环境自还原）；GUI 程序编译验证。
- 服务示例（30）支持 `console`/`list` 双模式（标准用户可跑），安装/启动/停止需管理员。
- 示例目标系统为 Windows 10 1703+；涉及 Windows 11 专属视觉的调用（圆角）在老系统上自动降级。
