# Win32 API 开发指南

> Win32 API 是 Windows 操作系统暴露给应用程序的官方 C 语言服务接口——不只是"窗口库"。它覆盖两大板块：窗口、消息、控件、GDI 等界面能力（被各代 UI 框架不断封装），以及进程、线程、同步、内存、文件、DLL、COM、安全等系统服务能力（**至今没有任何替代品**）。

本教程面向初学者，按依赖链组织为 33 章（五篇 + 收束），全部示例可编译验证。通用控件部分参考《Win32 开发人员参考库·第 4 卷：Windows 通用控件》，系统服务部分（调度/内存/内核对象/DLL/SEH/消息队列）参考《Windows 核心编程》（Jeffrey Richter）整理。

## 章节索引

### 第一篇 入门

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [01 全景与发展史](docs/01-全景与发展史.md) | 操作系统服务接口定位、分层视图、1985–Win11 演化 | Win32 到底是什么、为什么现在还要学 |
| [02 环境搭建与第一个窗口](docs/02-环境搭建与第一个窗口.md) | 工具链、编译链接、`wWinMain`、宽字符、报错对照表 | 怎么把源码变成能跑的 exe |
| [03 错误处理与调试](docs/03-错误处理与调试.md) | `GetLastError`、`FormatMessageW`、`HRESULT`、SEH 三部曲（finally/过滤器/未处理异常）、调试器 | 出错了怎么查、崩了怎么收尸 |

### 第二篇 界面层

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [04 窗口与消息机制](docs/04-窗口与消息机制.md) | 句柄、窗口类、消息队列与提取优先级、`SendMessage` vs `PostMessage`、跨进程消息 | 事件驱动的程序到底怎么运转 |
| [05 控件基础](docs/05-控件基础.md) | 控件即窗口、`WM_COMMAND`、六种基础控件、布局 | 按钮输入框怎么用、事件怎么回来 |
| [06 ListView 与 TreeView](docs/06-ListView与TreeView.md) | 报表视图、项与子项、ImageList、树形层级、头标控件、`WM_NOTIFY`、comctl32 版本与通用协议 | 数据列表和树怎么展示 |
| [07 更多通用控件](docs/07-更多通用控件.md) | 工具栏、状态栏、进度条、Tab、RichEdit、可定制工具条 | 现代应用的外围控件怎么组装 |
| [08 输入与调节控件](docs/08-输入与调节控件.md) | 轨迹条、增减数与 buddy、热键、IP 地址、扩展组合框 | 数值与专门输入怎么做 |
| [09 日期时间与反馈控件](docs/09-日期时间与反馈控件.md) | 日期检出器、月历与日状态、动画控件、工具提示 | 日期怎么选、忙时怎么转、悬停怎么提示 |
| [10 Rebar 与属性页](docs/10-Rebar与属性页.md) | Rebar band 与 chevron、Pager、属性表与向导 | IE 风格工具区与设置对话框怎么搭 |
| [11 自绘与子类化](docs/11-自绘与子类化.md) | Owner Draw、Custom Draw 完整协议、`SetWindowSubclass` | 控件长得丑怎么办、行为想改怎么办 |
| [12 GDI 绘图与现代显示](docs/12-GDI绘图与现代显示.md) | 重绘模型、GDI 对象、双缓冲；DWM、Per-Monitor V2、Win11 视觉 | 屏幕内容怎么画、怎么不闪、怎么适配高分屏 |
| [13 菜单、对话框与资源](docs/13-菜单对话框与资源.md) | 命令 ID 分发、加速键、模态对话框、通用对话框、资源脚本 | 命令入口怎么做、临时交互怎么弹 |
| [14 综合应用三例](docs/14-综合应用三例.md) | 计算器、RichEdit 编辑器、绘图板 | 零件怎么组装成完整程序 |

### 第三篇 系统服务层

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [15 字符编码与字符串](docs/15-字符编码与字符串.md) | 代码页、`wchar_t`、`MultiByteToWideChar`、UTF-8 互转、StrSafe | 中文为什么乱码、编码怎么转换 |
| [16 进程与作业对象](docs/16-进程与作业对象.md) | `CreateProcessW` 参数深读、终止语义、命令行/环境块、快照枚举、Job 限制与通知 | 怎么启动和管理别的程序 |
| [17 线程与同步](docs/17-线程与同步.md) | 调度/优先级/亲缘性、竞态与互锁、等待副作用、SRWLock/条件变量/线程池 | 怎么"同时做多件事"且不崩溃 |
| [18 内存管理](docs/18-内存管理.md) | 虚拟地址空间、页与线程栈、COW、堆与自建堆、文件映射 | `new` 底下发生了什么 |
| [19 文件系统](docs/19-文件系统.md) | `CreateFileW` 详解、读写循环、目录枚举、NTFS 特性、长路径 | 可靠的文件代码怎么写 |
| [20 内核对象与安全](docs/20-内核对象与安全.md) | 句柄表、跨进程共享三法、SD/ACL、令牌、UAC、完整性级别 | 权限是怎么回事、UAC 拦了什么 |
| [21 系统信息与定时器](docs/21-系统信息与定时器.md) | 版本、环境变量、系统时间、高精度定时器、电源 | 程序怎么感知它所处的机器 |

### 第四篇 模块与 COM

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [22 DLL 基础](docs/22-DLL基础.md) | 导出表、隐式/显式/延迟加载、`DllMain` 纪律、TLS、搜索顺序 | 模块化机制怎么工作 |
| [23 DLL 进阶与插件系统](docs/23-DLL进阶与插件系统.md) | 插件架构实战、资源段、PE 与重定位、API Set、注入与防御一瞥 | 怎么做一个能加载插件的宿主 |
| [24 注册表](docs/24-注册表.md) | 键值类型、增删改查、枚举、HKCU 策略 | Windows 的配置中心怎么用 |
| [25 COM 入门](docs/25-COM入门.md) | 二进制接口、`IUnknown`、引用计数、`HRESULT`、`ComPtr` | COM 是什么、为什么到处是它 |
| [26 COM 实战](docs/26-COM实战.md) | `CoInitialize`、`CoCreateInstance`、`IFileOpenDialog` | 怎么调用系统里的 COM 组件 |
| [27 COM 实现](docs/27-COM实现.md) | 类厂、`DllGetClassObject`、`DllRegisterServer`、HKCU 注册 | 怎么手写一个 COM 组件 |
| [28 Direct2D 与 DirectWrite](docs/28-Direct2D与DirectWrite.md) | 工厂、渲染目标、画刷、DWrite 文本、与 GDI 对照 | 现代渲染怎么写 |
| [29 WinRT 与 C++/WinRT](docs/29-WinRT与CppWinRT.md) | `IInspectable`、激活工厂、投影、C++20 协程异步 | 怎么从 Win32 调用现代 API |

### 第五篇 平台专题

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [30 Windows 服务与事件日志](docs/30-Windows服务与事件日志.md) | SCM、最小服务、安装启动停止、`ReportEventW` | 后台服务怎么写 |
| [31 Shell 集成](docs/31-Shell集成.md) | 托盘图标、右键菜单、气泡通知 | 程序怎么融进桌面环境 |
| [32 剪贴板与拖放](docs/32-剪贴板与拖放.md) | `CF_UNICODETEXT` 全链路、`WM_DROPFILES`、`IDropTarget` | 复制粘贴和拖放怎么实现 |

### 收束

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [33 现代 Win32 与学习路线](docs/33-现代Win32与学习路线.md) | Win10/11 新增 API、技术栈关系图谱、避坑总表、学习地图 | 接下来去哪 |

## 示例代码

`examples/` 下每个目录对应一个可编译工程，全部经本机 MSVC 编译验证（40 个示例）：

| # | 示例 | 章 | 一句话 |
|---|------|----|----|
| 01 | `01_hello_window` | 02 | 最小窗口骨架 |
| 02 | `02_message_loop` | 04 | 鼠标/键盘消息观测器 |
| 03 | `03_controls` | 05 | 基础控件三件套 |
| 04 | `04_gdi_drawing` | 12 | GDI 基础绘制 |
| 05 | `05_mini_calculator` | 14 | 状态机计算器 |
| 06 | `06_text_editor` | 13/14 | RichEdit 编辑器 + 文件 I/O |
| 07 | `07_paint_app` | 12/14 | 会重绘的绘图板 |
| 08 | `08_process_manager` | 16 | 进程枚举/启动/终止 |
| 09 | `09_memory_monitor` | 18 | 内存状态观测 |
| 10 | `10_file_manager` | 19 | 文件创建与目录枚举 |
| 11 | `11_thread_sync_demo` | 17 | 工作线程 + PostMessage 回传 |
| 12 | `12_memory_deep_dive` | 18 | 虚拟内存/页保护/堆/映射 |
| 13 | `13_file_system_deep_dive` | 19 | 元数据与 NTFS 细节 |
| 14 | `14_srwlock_demo` | 17 | SRWLock + 条件变量 |
| 15 | `15_dpi_modern_window` | 12 | DPI V2 + Win11 圆角 |
| 16 | `16_error_handling` | 03 | 错误处理四件套 |
| 17 | `17_listview_treeview` | 06 | ListView + TreeView |
| 18 | `18_common_controls` | 07 | 通用控件五件套 |
| 19 | `19_custom_draw` | 11 | 自绘/Custom Draw/子类化 |
| 20 | `20_encoding_convert` | 15 | 编码互转 + StrSafe |
| 21 | `21_security_descriptors` | 20 | 令牌/DACL 读写 |
| 22 | `22_sysinfo_timers` | 21 | 系统信息与定时器 |
| 23 | `23_dll_math` | 22 | DLL + 隐式链接 |
| 24 | `24_dll_plugin` | 23 | 插件宿主 |
| 25 | `25_registry_tool` | 24 | 注册表全流程 |
| 26 | `26_com_file_dialog` | 26 | COM 文件对话框 |
| 27 | `27_com_server` | 27 | 手写 COM 服务器 |
| 28 | `28_direct2d_hello` | 28 | D2D + DirectWrite |
| 29 | `29_winrt_modern` | 29 | C++/WinRT + 协程 |
| 30 | `30_windows_service` | 30 | 服务 + 事件日志 |
| 31 | `31_shell_tray` | 31 | 托盘程序 |
| 32 | `32_clipboard_dnd` | 32 | 剪贴板 + 拖放 |
| 33 | `33_input_controls` | 08 | 轨迹条/增减数/热键/IP/ComboBoxEx |
| 34 | `34_datetime_feedback` | 09 | DTP/月历/动画/工具提示 |
| 35 | `35_rebar_propsheet` | 10 | Rebar 工具区 + 属性表 + 向导 |
| 36 | `36_priority_cache` | 17 | 优先级/饥饿保护实测 + 伪共享 4 倍差 |
| 37 | `37_seh_toolkit` | 03 | SEH 三部曲 + 栈溢出恢复 + 未处理过滤器 |
| 38 | `38_job_limits` | 16 | Job CPU 限额强杀（0xC0000044）+ 统计回读 |
| 39 | `39_tls_demo` | 22 | 动态/静态 TLS 三线程对照 |
| 40 | `40_copydata` | 04 | WM_COPYDATA 双实例收发 |

## 目录结构

```text
win32/
├── README.md                   # 本文件：章节索引 + 示例对照 + 构建说明
├── build.ps1                   # 编译验证脚本
├── docs/                       # 33 章（五篇 + 收束）
│   ├── 01-全景与发展史.md
│   ├── …（见上方章节索引）
│   └── 33-现代Win32与学习路线.md
├── examples/                   # 可编译示例（见上表）
└── build/                      # 编译输出
```

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
- 验证分级：控制台示例（12/13/14/16/20/21/22/25/29/30/36/37/38/39）实际运行核对输出；多目标工程（23/24/27）内含运行验证（DLL 消费者实跑、COM 注册→创建→注销全链路，HKCU 免管理员、环境自还原）；GUI 程序编译验证。
- 服务示例（30）支持 `console`/`list` 双模式（标准用户可跑），安装/启动/停止需管理员。
- 示例目标系统为 Windows 10 1703+；涉及 Windows 11 专属视觉的调用（圆角）在老系统上自动降级。
