# Win32 API 开发指南

> Win32 API 是 Windows 操作系统暴露给应用程序的官方 C 语言服务接口——不只是"窗口库"。它覆盖两大板块：窗口、消息、控件、GDI 等界面能力（被各代 UI 框架不断封装），以及进程、线程、同步、内存、文件、DLL、COM、安全等系统服务能力（**至今没有任何替代品**）。

本教程面向初学者，按依赖链组织为 30 章（五篇 + 收束），全部示例可编译验证。

## 目录

### 第一篇 入门

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [01 全景与发展史](docs/01-全景与发展史.md) | 操作系统服务接口定位、分层视图、1985–Win11 演化 | Win32 到底是什么、为什么现在还要学 |
| [02 环境搭建与第一个窗口](docs/02-环境搭建与第一个窗口.md) | 工具链、编译链接、`wWinMain`、宽字符、报错对照表 | 怎么把源码变成能跑的 exe |
| [03 错误处理与调试](docs/03-错误处理与调试.md) | `GetLastError`、`FormatMessageW`、`HRESULT`、`OutputDebugString`、SEH、调试器 | 出错了怎么查、怎么不被错误码淹没 |

### 第二篇 界面层

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [04 窗口与消息机制](docs/04-窗口与消息机制.md) | 句柄、窗口类、消息的完整旅程、`SendMessage` vs `PostMessage` | 事件驱动的程序到底怎么运转 |
| [05 控件基础](docs/05-控件基础.md) | 控件即窗口、`WM_COMMAND`、六种基础控件、布局 | 按钮输入框怎么用、事件怎么回来 |
| [06 ListView 与 TreeView](docs/06-ListView与TreeView.md) | 报表视图、项与子项、ImageList、树形层级、`WM_NOTIFY` | 数据列表和树怎么展示 |
| [07 更多通用控件](docs/07-更多通用控件.md) | 工具栏、状态栏、进度条、Tab、RichEdit | 现代应用的外围控件怎么组装 |
| [08 自绘与子类化](docs/08-自绘与子类化.md) | Owner Draw、Custom Draw、`SetWindowSubclass` | 控件长得丑怎么办、行为想改怎么办 |
| [09 GDI 绘图与现代显示](docs/09-GDI绘图与现代显示.md) | 重绘模型、GDI 对象、双缓冲；DWM、Per-Monitor V2、Win11 视觉 | 屏幕内容怎么画、怎么不闪、怎么适配高分屏 |
| [10 菜单、对话框与资源](docs/10-菜单对话框与资源.md) | 命令 ID 分发、加速键、模态对话框、通用对话框、资源脚本 | 命令入口怎么做、临时交互怎么弹 |
| [11 综合应用三例](docs/11-综合应用三例.md) | 计算器、RichEdit 编辑器、绘图板 | 零件怎么组装成完整程序 |

### 第三篇 系统服务层

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [12 字符编码与字符串](docs/12-字符编码与字符串.md) | 代码页、`wchar_t`、`MultiByteToWideChar`、UTF-8 互转、StrSafe | 中文为什么乱码、编码怎么转换 |
| [13 进程与作业对象](docs/13-进程与作业对象.md) | `CreateProcessW`、快照枚举、Job 对象 | 怎么启动和管理别的程序 |
| [14 线程与同步](docs/14-线程与同步.md) | `CreateThread`、竞态、`CRITICAL_SECTION` 到 SRWLock/条件变量/线程池 | 怎么"同时做多件事"且不崩溃 |
| [15 内存管理](docs/15-内存管理.md) | 虚拟地址空间、页、堆、文件映射 | `new` 底下发生了什么 |
| [16 文件系统](docs/16-文件系统.md) | `CreateFileW` 详解、读写循环、目录枚举、NTFS 特性、长路径 | 可靠的文件代码怎么写 |
| [17 内核对象与安全](docs/17-内核对象与安全.md) | 句柄表、句柄复制、SD/ACL、令牌、UAC、完整性级别 | 权限是怎么回事、UAC 拦了什么 |
| [18 系统信息与定时器](docs/18-系统信息与定时器.md) | 版本、环境变量、系统时间、高精度定时器、电源 | 程序怎么感知它所处的机器 |

### 第四篇 模块与 COM

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [19 DLL 基础](docs/19-DLL基础.md) | 导出表、隐式/显式链接、`DllMain` 纪律、搜索顺序 | 模块化机制怎么工作 |
| [20 DLL 进阶与插件系统](docs/20-DLL进阶与插件系统.md) | 插件架构实战、资源段、PE 速览、API Set | 怎么做一个能加载插件的宿主 |
| [21 注册表](docs/21-注册表.md) | 键值类型、增删改查、枚举、HKCU 策略 | Windows 的配置中心怎么用 |
| [22 COM 入门](docs/22-COM入门.md) | 二进制接口、`IUnknown`、引用计数、`HRESULT`、`ComPtr` | COM 是什么、为什么到处是它 |
| [23 COM 实战](docs/23-COM实战.md) | `CoInitialize`、`CoCreateInstance`、`IFileOpenDialog` | 怎么调用系统里的 COM 组件 |
| [24 COM 实现](docs/24-COM实现.md) | 类厂、`DllGetClassObject`、`DllRegisterServer`、HKCU 注册 | 怎么手写一个 COM 组件 |
| [25 Direct2D 与 DirectWrite](docs/25-Direct2D与DirectWrite.md) | 工厂、渲染目标、画刷、DWrite 文本、与 GDI 对照 | 现代渲染怎么写 |
| [26 WinRT 与 C++/WinRT](docs/26-WinRT与CppWinRT.md) | `IInspectable`、激活工厂、投影、C++20 协程异步 | 怎么从 Win32 调用现代 API |

### 第五篇 平台专题

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [27 Windows 服务与事件日志](docs/27-Windows服务与事件日志.md) | SCM、最小服务、安装启动停止、`ReportEventW` | 后台服务怎么写 |
| [28 Shell 集成](docs/28-Shell集成.md) | 托盘图标、右键菜单、气泡通知 | 程序怎么融进桌面环境 |
| [29 剪贴板与拖放](docs/29-剪贴板与拖放.md) | `CF_UNICODETEXT` 全链路、`WM_DROPFILES`、`IDropTarget` | 复制粘贴和拖放怎么实现 |

### 收束

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [30 现代 Win32 与学习路线](docs/30-现代Win32与学习路线.md) | Win10/11 新增 API、技术栈关系图谱、避坑总表、学习地图 | 接下来去哪 |

## 示例代码

`examples/` 下每个目录对应一个可编译工程，全部经本机 MSVC 编译验证（见 [README](README.md)）。示例对照表以 README 为准。
