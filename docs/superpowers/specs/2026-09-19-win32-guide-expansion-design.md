# Win32 API 开发指南扩充设计（12 章 → 30 章）

> 日期：2026-09-19　状态：已获用户批准的设计，待写实施计划
> 范围：G:\code\guide\win32（docs/ 章节正文、examples/ 可编译示例、build.ps1、README、目录页）

## 1. 背景与目标

现有教程 12 章 / 15 示例（2026-09-16 重构版），写得紧凑但有两类缺口：

- **初学者支撑不足**：概念密、代码片段多、缺少成果先行与章末练习；
- **平台内容缺口**：DLL 仅 1 章概念性内容且无示例；COM、注册表、服务、Shell、Direct2D、WinRT、编码、安全、系统信息全部缺失或仅在学习地图提一句。

用户决策（2026-09-19 对话确认）：

1. 现有 12 章**全面重写**为初学者标准（不是只写新章）；
2. DLL 拆 2 章讲透；COM 讲到"使用 + 手写进程内服务器"；
3. 平台专题全选：注册表、错误处理与调试、Windows 服务、Shell 集成、事件日志；
4. 加厚两个方向：**标准控件**（1 章拆 4 章）、**系统细节**（编码/安全/系统信息专章）；
5. **DirectX**：Direct2D + DirectWrite 进正文实操章；Direct3D 12 留学习地图（过深）；
6. **WinRT**：C++/WinRT 实操章（已本机验证可行）。

## 2. 新目录结构（30 章，★ = 新增）

### 第一篇 入门

| 章 | 标题 | 来源 |
|---|------|------|
| 01 | 全景与发展史 | 重写（原 01） |
| 02 | 环境搭建与第一个窗口 | 重写（原 02） |
| 03 | ★ 错误处理与调试基础 | 新增：GetLastError / FormatMessageW / HRESULT 概念（为 COM 铺路）/ 输出调试串 / 断点与调试器入门 / SEH 语法 |

### 第二篇 界面层

| 章 | 标题 | 来源 |
|---|------|------|
| 04 | 窗口与消息机制 | 原 03 重写 |
| 05 | 控件基础：按钮、编辑框、列表框与事件 | 原 04 扩写 |
| 06 | ★ 列表与树：ListView 与 TreeView | 新增：imagelist、项数据、通知消息、虚拟模式简介 |
| 07 | ★ 更多通用控件：工具栏、状态栏、进度条、Tab、RichEdit | 新增 |
| 08 | ★ 自定义控件外观：自绘与子类化 | 新增：Owner Draw / Custom Draw / SetWindowSubclass |
| 09 | GDI 绘图与现代显示 | 原 05 重写；末尾加"现代继任见 25 章"引子 |
| 10 | 菜单、对话框与资源 | 原 06 重写（工具栏细节移入 07 章） |
| 11 | 综合应用三例 | 原 07 大幅扩写（现仅 118 行）；编辑器升级 RichEdit |

### 第三篇 系统服务层

| 章 | 标题 | 来源 |
|---|------|------|
| 12 | ★ 字符编码与字符串深入 | 新增：代码页、MultiByteToWideChar/WideCharToMultiByte、UTF-8 互转、StrSafe |
| 13 | 进程与作业对象 | 原 08 拆分（原章 357 行全书最长） |
| 14 | 线程与同步 | 原 08 拆分（CRITICAL_SECTION → SRWLock → 条件变量 → 线程池） |
| 15 | 内存管理 | 原 09 重写 |
| 16 | 文件系统 | 原 10 重写 |
| 17 | ★ 内核对象、安全与权限 | 新增：句柄表、句柄复制、SD/ACL、令牌、UAC 虚拟化、完整性级别、SetProcessMitigationPolicy |
| 18 | ★ 系统信息、定时器与电源 | 新增：版本/环境变量/系统时间/高精度定时器/电源与设备通知 |

### 第四篇 模块与 COM

| 章 | 标题 | 来源 |
|---|------|------|
| 19 | DLL 基础：创建、导出与链接 | 原 11 拆分：两种链接、DllMain 纪律、搜索顺序 |
| 20 | DLL 进阶：插件系统与 PE | 原 11 拆分：插件架构实战、资源段、PE 速览、API Set |
| 21 | ★ 注册表 | 新增（排在 COM 实现前——COM 服务器靠注册表登记） |
| 22 | ★ COM 入门：对象模型与 IUnknown | 新增：二进制接口、引用计数、HRESULT 回顾、ComPtr |
| 23 | ★ COM 实战：调用系统组件 | 新增：CoInitialize、IFileOpenDialog 等 |
| 24 | ★ COM 实现：手写进程内服务器 | 新增：类厂、DllGetClassObject、HKCU\Software\Classes 注册（免管理员） |
| 25 | ★ Direct2D 与 DirectWrite | 新增：工厂→渲染目标→画刷→DWrite 文本，渲染进 HWND；与 09 章 GDI 对照 |
| 26 | ★ WinRT 与 C++/WinRT | 新增：IInspectable/激活工厂/.winmd、init_apartment、投影类型、C++20 协程消费 IAsyncOperation |

### 第五篇 平台专题

| 章 | 标题 | 来源 |
|---|------|------|
| 27 | ★ Windows 服务与事件日志 | 新增（服务写日志，天然配对） |
| 28 | ★ Shell 集成：托盘与通知 | 新增：托盘图标、右键菜单、通知 |
| 29 | ★ 剪贴板与拖放 | 新增；放 COM 后因为拖放（IDropTarget）是 COM 接口 |

### 收束

| 章 | 标题 | 来源 |
|---|------|------|
| 30 | 现代 Win32 与学习路线 | 原 12 重写：更新全图，Direct3D 12 在学习地图指路并说明为何不进正文 |

## 3. 章内模板（初学者标准，全章统一）

1. **开篇三件**：本章回答的问题 / 前置章节 / 你将做出什么（成果先行）
2. **概念铺垫**：新概念先给类比与"为什么需要它"，再给定义
3. **完整可编译代码**：核心示例为完整程序 + 分段解剖（不只片段）
4. **ASCII 图解**：消息流转、内存布局、PE 结构、COM 调用链、D2D 渲染管线等
5. **易错清单**：症状→原因→解法 对照表
6. **章末**：小结 3~5 条 + 动手练习 1~3 题（带提示）

篇幅目标：重写章 300~450 行；新章 350~500 行。全书预计 10000~14000 行。

## 4. 示例清单（32 个 = 15 旧 + 17 新）

旧示例编号与目录不动（内容随章节重写小修引用）；新示例追加：

| 示例 | 章 | 内容 | 形态 |
|------|---|------|------|
| 16_error_handling | 03 | 失败 API + GetLastError→FormatMessageW + SEH | 控制台 |
| 17_listview_treeview | 06 | ListView + TreeView + imagelist | GUI |
| 18_common_controls | 07 | 工具栏/状态栏/进度条/Tab/RichEdit | GUI |
| 19_custom_draw | 08 | 自绘按钮 + Custom Draw 列表 + 子类化 | GUI |
| 20_encoding_convert | 12 | 代码页/UTF-8 互转 + StrSafe | 控制台 |
| 21_security_descriptors | 17 | 令牌/完整性级别查询 + 简单 SD | 控制台 |
| 22_sysinfo_timers | 18 | 系统信息/环境变量/高精度定时器 | 控制台 |
| 23_dll_math | 19 | 数学 DLL + 隐式链接消费者 | DLL + EXE |
| 24_dll_plugin | 20 | 插件接口头 + 2 插件 DLL + 宿主 EXE | DLL×2 + EXE |
| 25_registry_tool | 21 | 注册表增删改查 + 类型遍历 | 控制台 |
| 26_com_file_dialog | 23 | CoInitialize + ComPtr + IFileOpenDialog | GUI |
| 27_com_server | 24 | 手写 COM DLL + 消费者（注册→创建→注销全链路） | DLL + EXE |
| 28_direct2d_hello | 25 | D2D 渐变 + 抗锯齿图形 + DWrite 文本 + resize | GUI |
| 29_winrt_modern | 26 | init_apartment + DateTimeFormatter + 协程异步 | 控制台 |
| 30_windows_service | 27 | 最小服务（安装/启动/停止）+ ReportEventW | 服务 EXE |
| 31_shell_tray | 28 | 托盘图标 + 右键菜单 + 通知 | GUI |
| 32_clipboard_dnd | 29 | 剪贴板读写 + IDropTarget 文件拖放 | GUI |

旧示例 → 新章号映射（重排后同步更新文档引用）：01→02、02→04、03→05、04→09、05→11、06→10/11、07→09/11、08→13、09→15、10→16、11→14、12→15、13→16、14→14、15→09。

## 5. build.ps1 改造

- 默认链接库追加：`ole32 oleaut32 uuid advapi32 d2d1 dwrite`（未用到的库链接器自动忽略）
- WinRT 示例（29）额外：`/I <SDK>\Include\<ver>\cppwinrt` + 链接 `WindowsApp.lib`
- **多目标工程支持**：示例目录自带 `build.ps1` 时根脚本委托给它（DLL→dll+lib→消费者 exe 的多步构建写在子脚本内）；单 main.cpp 目录走现有路径不变
- 防线保持：UTF-8 BOM（PS5.1 中文脚本必需，改完必须确认 `EF BB BF` 仍在）、输出按父目录命名、wmain 子系统探测
- 已知环境差异：git-bash 直接 spawn cmd 跑 vcvars 需先 `set PATH=%PATH%;C:\Program Files (x86)\Microsoft Visual Studio\Installer`（vswhere 所在）；build.ps1 经 PowerShell 调用不受影响

## 6. 验证标准（每批次收口，全部满足才提交）

1. `.\build.ps1 -All` 全绿（最终 32 个示例）
2. 控制台示例实际运行验证输出（17 类新示例中约半数为控制台）
3. DLL 消费者实际运行证明加载链路（23/24）
4. COM 服务器全链路实跑：HKCU 注册 → CoCreateInstance → 注销（免管理员，环境可还原）（27）
5. GUI 程序编译验证（沿用现有约定），关键新示例（28 D2D）加 3 秒冒烟存活测试
6. 每批 git 提交，提交信息说明批次内容

## 7. 实施批次（14 批）

| # | 内容 | 新示例 |
|---|------|--------|
| 1 | 骨架重排：git mv 章节重编号、目录页/README 章节表、build.ps1 改造（库列表+委托机制），旧示例全绿 | — |
| 2 | 入门篇 01–03 重写 | 16 |
| 3 | 界面层 I：04–05 | — |
| 4 | 界面层 II：06–08 新控件三章 | 17/18/19 |
| 5 | 界面层 III：09–11（含 RichEdit 编辑器升级） | — |
| 6 | 系统层 I：12 编码新章 + 13/14 进程线程拆分 | 20 |
| 7 | 系统层 II：15–16 内存/文件 | — |
| 8 | 系统层 III：17–18 安全/系统信息 | 21/22 |
| 9 | DLL：19–20 | 23/24 |
| 10 | 注册表：21 | 25 |
| 11 | COM：22–24 | 26/27 |
| 12 | 现代渲染与 WinRT：25–26 | 28/29 |
| 13 | 平台专题：27–29 | 30/31/32 |
| 14 | 收束章 30 + README/目录页终稿 + 记忆更新 | — |

## 8. 已验证的技术事实（设计期 spike，2026-09-19）

1. **C++/WinRT 可行**：SDK 10.0.26100.0 自带 `Include\10.0.26100.0\cppwinrt\winrt\*.h`；`Lib\10.0.26100.0\um\x64\WindowsApp.lib` 存在；`cl /std:c++20 /EHsc /utf-8 /I <cppwinrt目录>` + 链接 WindowsApp.lib 编译运行成功（DateTimeFormatter 输出 `today = 2026-09-19`）。无需显式 /permissive-。
2. **Direct2D/DirectWrite 可行**：现有教程编译参数 + `d2d1.lib dwrite.lib` 编译零错误；GUI 冒烟 3 秒存活（工厂/渲染目标/画刷/文本格式全部真实创建）。
3. **MSVC 工具链**：VS 18 Community，vcvars64.bat 路径与 build.ps1 现值一致。

## 9. 风险与对策

| 风险 | 对策 |
|------|------|
| 章节重编号导致交叉引用遗漏 | 批 1 完成后全文 grep 旧章号引用；每批收口再 grep 一次 |
| build.ps1 丢失 BOM 引发 PS5.1 语法错误 | 每次改动后检查文件头 EF BB BF（记忆已载） |
| COM 注册污染系统 | 只用 HKCU\Software\Classes；示例自带注销路径；验证后清理 |
| 服务安装需管理员 | 服务示例编译验证为主，文档给手动 sc.exe 步骤；示例内提供只读枚举演示（标准用户可跑） |
| WinRT Toast 需 AUMID+快捷方式 | 教程讲原理不实跑 Toast；29 示例用 DateTimeFormatter + 协程（已验证可跑） |
| RichEdit 控件需显式 LoadLibrary | 实现时按 msftedit.dll（RichEdit 4.1）处理并在文中说明各版本差异 |
| 一次性 30 章上下文超限 | 14 批分批推进，每批独立收口提交；单批内先写章后写示例再验证 |

## 10. 不做清单（明确出界）

- Direct3D 11/12 实操（学习地图指路）
- XAML Islands / Windows App SDK / MSIX 打包实操（收束章概览）
- IME 深入、键盘/鼠标钩子、驱动、内核
- ATL/WRL 全面教程（ComPtr 用 WRL 头文件引入即可，不展开）
- 多显示器完整专题（09 章 DPI 部分覆盖基础）
