# 43. 生态巡礼：WCT、Template Studio、Blazor、Uno 的 C++ 视角

> 对应《Learn WinUI 3》第 9、10、12（Blazor 部分）、13 章的"外围生态"。这些工具链几乎全部以 C#/.NET 为第一公民——本章不逐个复述书里的操作，而是回答一个 C++ 工程师的问题：**每样东西我能不能用？不能用的话对应物是什么？**

## 43.1 一张总表

| 生态件 | 书的用法 | C++/WinRT 可用性 | C++ 对应物 |
|---|---|---|---|
| Windows Community Toolkit 控件 | DataGrid/SettingsCard 等 NuGet 直装 | ❌ NU1202（[20 章](20-datagrid-itemsrepeater.md)实测：7.x 无 native 目标） | 自制路线（各控件章）+ Win32 互操作 |
| WCT 辅助件（动画/光照/唤醒） | NuGet + C# API | ❌（同包） | Composition/Win32 自写（[29](29-animation.md)/[30](30-drawing-media.md)/[34](34-os-integration.md)） |
| .NET Community Toolkit（MVVM 等） | ObservableObject/RelayCommand | ❌ .NET 专属 | [32 章](32-binding-mvvm.md) INPC 基类 + [36 章](36-mvvm-commands-di.md) XamlUICommand |
| Template Studio | VS 向导生成 MVVM 骨架 | ❌ 只出 C# 工程 | 本教程 examples/ 骨架 + `tools/register-page.py` |
| Blazor（在 WebView2 里） | Wasm 部署后 WebView2 指向 | ⚠️ 宿主侧可用，Blazor 本身写不了 | Web 侧用任意 JS 框架，[40 章](40-webview2.md) 通道 |
| Uno Platform | WinUI XAML 跨平台到 iOS/Android/Wasm | ❌ C# 编译链 | 无直接对应（43.5 讨论） |
| WinUI 3 Gallery | 控件试验场 | ✅ 与语言无关 | 同一个应用 |
| Fluent XAML Theme Editor | 主题资源导出 | ✅ XAML 通用 | [38 章](38-fluent-materials.md) |
| Rapid XAML Toolkit | XAML 静态分析 | ✅ 分析 XAML 文本 | [41 章](41-debugging.md) |

## 43.2 Windows Community Toolkit（书 9 章）

WCT 的价值主张：官方（微软开源）维护的控件与辅助件补 WinUI 原生空白。书 9.3 走 WCT Gallery 认识控件清单，9.4 过辅助件。**C++ 工程的 NuGet 一关就过不去**：包的 target 只扫 .NET 平台（net6.0-windows10...），native vcxproj 解析直接 NU1202"项目与包不兼容"——20 章为 DataGrid 实测过，结论推广到整个 7.x 控件包。

逐件对应（书里的明星控件 → 本教程的路线）：

| WCT 控件 | 本教程路线 | 章节 |
|---|---|---|
| DataGrid | 自制表格（Grid/ListView 混合） | [20](20-datagrid-itemsrepeater.md) |
| SettingsCard/SettingsExpander | 自制设置行（Grid + ToggleSwitch 等） | [07](07-button.md)（SettingsHub 工程整体） |
| TokenView/Charts 等 | ItemsRepeater + 自绘 | [20](20-datagrid-itemsrepeater.md)/[30](30-drawing-media.md) |
| AnimationSet/Light 等 | Storyboard/Composition 自写 | [29](29-animation.md) |

**辅助件**（书 9.4：BackgroundTask、Storage、Notification 等）多为 WinRT API 的 C# 便利封装——C++ 直接调底层 WinRT（BackgroundTaskBuilder、ApplicationData、[39 章](39-app-notifications.md)的 AppNotifications）反而少一层间接。

## 43.3 Template Studio（书 10 章）

书 10 章用它两分钟生成"MVVM + DI + 导航 + 测试"四件套骨架。VS 扩展只出 C# 工程——**它的产物恰好是 36 章手写的那些东西**（导航服务、DI、页面注册），对照阅读有意外收获：TS 生成的 NavigationService 与 36.6 的 C++ 翻译结构逐函数对应，等于一份"官方答案"。

C++ 侧的对应工作流是本教程自建的：

- **工程骨架**：拷 `examples/` 最近的工程（34/37 的形态最全），改 GUID/命名空间/工程文件名。
- **页面登记**：`tools/register-page.py` 四处登记（vcxproj ClInclude/ClCompile/Midl/Page + pch.h + 导航项）——这是 C++ 版"向导"的全部，30 行脚本。
- **测试**：TS 的 MSTest 工程对应 C++ 的 GoogleTest + C++/WinRT（数据层单测已可行：`LibraryStore` 刻意零 WinRT 依赖就是为此，[37.9](37-sqlite-storage.md)）。

## 43.4 Blazor 与混合 Web（书 12 章）

书 12 章全链路：Blazor Wasm 应用 → Azure Static Web Apps → WinUI WebView2 指向 URL。拆开看语言依赖：

- **宿主侧（WinUI）**：`<WebView2 Source="https://..."/>` 与语言无关，[40 章](40-webview2.md) 已全解——**Blazor 部署出来的站点对 C++ 宿主毫无特殊性**。
- **Web 侧（Blazor）**：C# 编译到 Wasm——C++ 工程师写不了。等价能力：任何 JS/TS 框架（React/Vue/Svelte）产物同样是静态文件，部署到同一家 Azure Static Web Apps/GitHub Pages。
- **混合的意义**（书 12.1 的论证在 C++ 侧完全成立）：Web UI 的迭代速度 + 桌面壳的原生能力（文件/通知/离线分发）。宿主↔Web 通信就是 40.5/40.6 的两条通道。

裁决表：想把 **Web 团队的产出**装进桌面壳 → WebView2 直指部署 URL（零额外概念）；想 **一个人全栈** → C++ 壳 + JS 前端；想要书里的 Blazor 体验 → 那是在选 C#，不是在选 WinUI。

## 43.5 Uno Platform（书 13 章）

Uno 把 WinUI/WinRT XAML 编译到 iOS/Android/Wasm/Linux/macOS。**编译链是 C# 的**（Uno 自己是 Roslyn 上的源生成器族），C++/WinRT 工程没有入口。书 13.3 的"WinUI 代码迁移到 Uno"步骤（改 csproj、修平台分支）全部发生在 C# 层。

C++ 的跨平台现实分两答：

1. **UI 层跨平台**：没有官方路线。社区方案（Skia 自绘、Qt、或 Web 壳 + [40 章](40-webview2.md)）各有哲学；用 WinUI 3 就接受了 Windows-only 的 UI。
2. **非 UI 层跨平台**：C++ 的传统强项——本教程的 `LibraryStore`（[37](37-sqlite-storage.md)）模式（零 WinRT 依赖的数据层）就是为"逻辑层随便搬到哪"设计的。C++/WinRT 甚至支持用标准 C++ 写 WinRT 组件给 C# 调（反方向互操作，[02 章](02-winrt.md)的投影机制两端对称）。

书的 WSA（Android 子系统）路线（13.4）已随微软停服 WSA 成为历史注脚，跳过。

## 43.6 选型决策：什么时候不该选 C++/WinRT

诚实收盘。如果你/你的团队：

- **重度依赖生态控件**（DataGrid、图表、富文本栏）且不想自绘 → C# + WCT 少一个月工期；
- **要跨平台 UI** → Uno/MAUI（C#）或 Web；
- **全栈 Web 技能想复用** → Blazor Hybrid；
- **要源生成器级 MVVM 甜头** → CommunityToolkit.Mvvm。

反过来，C++/WinRT 的甜点区：**与原生 C++ 代码库同进程**（游戏引擎工具、工业软件、音视频管线）、**无 .NET 运行时分发的裸部署**（42 章的自包含 MSIX 尺寸优势）、**对内存/启动延迟敏感**的常驻工具。本教程的存在证明这条路能走通——代价是每样生态便利都要自己造，收益是整条栈没有你看不见的黑盒。

## 43.7 练习与思考

1. 对照书 9.3 的 WCT 控件清单，把"你最想要的三件"在本教程目录里找到对应章——哪一件真的没有替代？
2. 跑一遍 WinUI 3 Gallery（商店应用），找出两个"本教程没讲到的控件"，各写 50 行 XAML 试验它们的 C++ 可用性（投影在 `Generated Files/winrt` 里查）。
3. 思考：`LibraryStore` 若要同时服务 WinUI 界面与一个 CLI 导入工具，工程结构怎么分？（提示：静态库 + 两个 exe，37.9 第 5 题的延伸。）
4. 辩论题：团队里已有 C# WinUI 应用与 C++ 算法库，新工具该用 C#/WinRT（互操作调 C++/WinRT 组件）还是 C++/WinRT 全自研？列出至少三条论据各方向。
