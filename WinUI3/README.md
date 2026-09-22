# WinUI 3 C++/WinRT 编程指南

面向"从零到工程"的 WinUI 3 教程。目标不是罗列控件语法，而是讲清三层东西：

1. **机制**：WinRT 对象模型、XAML 编译流程、绑定引擎——代码背后发生了什么
2. **结构**：App / Window / Page / ViewModel / Model / Service 的分层与协作
3. **交付**：主题资源、Assets、Manifest、MSIX 打包

开发语言为 **C++/WinRT**（WinRT 的官方 C++17 投影）。教程代码均为真实 WinUI 3 写法，要编译运行需要 Visual Studio（17.x / 18.x 皆可）带桌面 C++ 工具链，并在可选组件里装上 **C++/WinRT 项目模板** 与 **WinUI 应用模板**，以 Windows App SDK 的 C++ 模板工程为载体。

教程里的每个关键机制都对应 `examples/` 下一个**能真编译、能真运行**的工程，在本目录跑 `.\build.ps1` 即可全部从零编过，`tools/ui-smoke/` 还会启动它们、合成点击、截图验证行为——完整清单与证据见文末 [验证状态](#验证状态)。

## 目录

### 概念篇

| 篇 | 内容 | 回答的问题 |
|---|------|-----------|
| [01 概念总览](docs/01-tech-stack.md) | 分层架构、各组件职责、Win32→WinForms→WPF→UWP→WinUI 3 各代技术的问题与演化、打包/非打包 | WinRT / WinUI 3 / XAML / Windows App SDK 各是什么、谁负责什么、为什么会有这么多代 |
| [02 WinRT 机制](docs/02-winrt.md) | IUnknown/IInspectable、.winmd 元数据、语言投影、hstring/event/异步/错误模型 | `winrt::` 代码底下发生了什么 |
| [03 XAML 机制](docs/03-xaml.md) | 标记编译、x:Class/x:Name、依赖属性、x:Bind vs Binding、资源查找、DataTemplate | XAML 怎么变成运行中的对象树 |

### 工程篇

| 篇 | 内容 | 回答的问题 |
|---|------|-----------|
| [04 第一个真实应用](docs/04-first-app.md) | 模板工程结构、App/MainWindow 真实代码、启动时序、事件签名 | 一个真实 WinUI 3 程序怎么启动、怎么跑起来 |
| [05 工程分层](docs/05-project-structure.md) | 各层职责、Frame 导航、页面生命周期、IDL 的角色、Service 边界 | 真实应用的代码怎么组织 |
| [06 布局](docs/06-layout.md) | Grid/StackPanel/Border/RelativePanel/ScrollViewer 与真实页面结构 | 页面区域怎么划分和伸缩 |
| 07–25 控件篇 | 每个核心控件一章（Button、TextBox、ListView、NavigationView、ContentDialog…），**扩充中** | 控件在工程里扮演什么角色、哪些细节是坑 |

### 应用篇

| 篇 | 内容 | 回答的问题 |
|---|------|-----------|
| [32 绑定、MVVM 与异步](docs/32-binding-mvvm.md) | INotifyPropertyChanged 完整实现、IObservableVector、x:Bind 模式、ICommand、协程异步模式 | 界面怎么跟随数据变、耗时工作怎么不卡 UI |
| [33 主题资源与交付](docs/33-theming-packaging.md) | ThemeResource/StaticResource、资源字典分层、主题切换、Assets/Manifest/MSIX | 深浅色怎么自动适配、应用怎么打包分发 |
| [34 OS 集成](docs/34-os-integration.md) | 线程边界与 DispatcherQueue、文件/选择器、注册表/JSON、子进程、生命周期 | UI 框架之下的系统能力怎么用 |

## 学习路线

按编号顺序读即可，它是刻意安排的依赖链：

```text
01 ── 02 ── 03        概念地基：每层组件是什么、怎么工作
        │
04 ── 05              骨架：真实应用怎么启动、代码怎么分层
   │
06                    布局
   │
07 ── 25              控件篇：基础 / 集合 / 导航浮层（扩充中）
   │
26 ── 31              进阶：样式模板 / 自定义控件 / VSM / 动画 / 绘图 / 窗口
   │
32                    枢纽：绑定 / MVVM / 异步（最核心的一篇）
   │
33 ── 34              应用级：主题交付与系统能力
   │
35                    实战收束
```

已经熟悉某个领域的读者可以跳读：

- 会 WPF/UWP → 先读 [02 WinRT 机制](docs/02-winrt.md) 和 [03 XAML 机制](docs/03-xaml.md) 3.6（`x:Bind` 与 WPF 的 `{Binding}` 差异很大），再按需查目录
- 会 Win32/C++ → [04 第一个真实应用](docs/04-first-app.md) 起步，重点体会 IDL 和投影（[02 篇](docs/02-winrt.md) 2.5）
- 只想快速上手 → [04](docs/04-first-app.md) → [06 布局](docs/06-layout.md) → [32 绑定](docs/32-binding-mvvm.md)，出问题再回概念篇

## 环境要求

- Windows 10 1809+（建议 Windows 11）
- Visual Studio（17.x / 18.x）+ 桌面 C++ 工具链 + C++/WinRT 与 WinUI 项目模板组件
- 工程模板：**Blank App, Packaged (WinUI 3 in C++)**

## 版本基线

教程正文的 API 签名对照本机 NuGet 缓存里的这组包核对：

| 组件 | 版本 |
|------|------|
| `Microsoft.WindowsAppSDK` | 1.8.260317003 |
| `Microsoft.WindowsAppSDK.WinUI`（含 `Microsoft.UI.Xaml.winmd` / `Microsoft.WinUI.dll`） | 1.8.260224000 |
| `Microsoft.WindowsAppSDK.Foundation`（含 `Microsoft.Windows.Storage*.winmd`） | 1.8.260222000 |
| MSVC 工具集 | 14.16 / 14.29 / 14.44 / 14.51 |

**注意文档站默认 moniker 已切到 2.0**，个别成员（如 `Window.Width` / `Window.Height`）只在 2.0 页面列出——本机 1.8 的 `Microsoft.UI.Xaml.Window` 元数据里没有它们。按 1.8 写工程时不要照抄 2.0 页面的签名。

## 验证状态

本目录**已包含可编译的示例工程，并做过端到端验证**。工程在 `examples/` 下，共五个，全部用真实 MSVC + Windows App SDK 1.8 工具链编过：

```text
examples/
├── 01-first-app/        MyApp        最小闭环：Button + Click 处理器改文本
├── 06-layout/           LayoutApp    Grid(*/Auto) + ScrollViewer + 尺寸回报
├── 32-binding-mvvm/     MvvmApp      INotifyPropertyChanged + IObservableVector + x:Bind + 协程异步
└── 34-os-integration/   OsIntApp     子进程 CreateProcessW + 应用数据目录 + WASDK picker
```

在 `WinUI3/` 目录下跑 **`.\build.ps1`** 即可从零编译全部工程（脚本用 vswhere 定位 MSBuild，`-restore` 还原 NuGet，逐个打印 `PASS`/`FAIL`）。当前全部工程 **PASS**，只剩无害告警（MSB8027/LNK4042 重复项、C4002 `GetCurrentTime`、C4100 未用形参）。

### 三条验证通道

每条断言都归属于下面某一条通道，读教程时按通道分配信任：

| 通道 | 工具 | 证明什么 | 证明不了什么 |
|------|------|---------|-------------|
| **元数据级** | `tools/winmd-probe/`（`System.Reflection.Metadata` 读真实 `.winmd`） | API 签名存在与形状 | 运行时行为 |
| **编译级** | `build.ps1` + MSVC/WinAppSDK 1.8 | 代码真能编过、链过 | 运行时是否正确 |
| **运行时级** | `tools/ui-smoke/`（启动→截图→合成真实点击→再截图） | 被点击的那条流程真的跑通 | 没被点到的流程 |

### 运行时级实测结果（附截图证据）

`tools/ui-smoke/` 会把窗口停在固定位置、合成一次真实鼠标点击、截图前后对比。已实测通过的流程：

| 工程 | 实测的流程 | 证据 |
|------|-----------|------|
| `01-first-app` | 点击 Button，`StatusText` 由 "Ready" 翻成 "Clicked from C++/WinRT" | `.smoke/01-first-app/after.png` |
| `32-binding-mvvm` | 点 Refresh → 后台协程 → `TryEnqueue` 切回 UI → 集合整体替换，列表出现 2 项、状态 "Loaded 2 tasks"/"Finished" | `.smoke/32-binding-mvvm/after.png` |
| `34-os-integration` | 点 Run tool → `CreateProcessW` 起 `cmd.exe` → 回收退出码 → 界面报 "tool succeeded"；点 Show path → `GetDefault()` **抛 "该进程没有程序包标识符"** → 兜底解析出 `%LOCALAPPDATA%\OsIntApp` | `.smoke/34-os-integration/after.png` |
| `06-layout` | Grid `*/Auto` 行列 + ScrollViewer 滚动条 + 尺寸回报正确渲染 | `.smoke/06-layout/after.png` |

### 验证推翻并改回正文的写法

三条通道合起来逼出了下面这些修正（都已写回对应章节，不是列在这儿就算了）：

- **`co_await winrt::resume_foreground(m_dispatcherQueue)` 在 WinUI 3 桌面应用里是错的**（编译级 + 运行时级）：`resume_foreground` 只有 `Windows.System.DispatcherQueue` / `Windows.UI.Core.CoreDispatcher` 两个重载，**没有** WinUI 3 的 `Microsoft.UI.Dispatching.DispatcherQueue` 重载；改用 `Windows.System` 那个同名类型能编过，但运行时协程**永不恢复**，界面死在 "Loading..."。正文改为 `DispatcherQueue::TryEnqueue` + `get_strong()`（见 [32 篇 32.7.1](docs/32-binding-mvvm.md#321-标准模式winui-3-实测写法)、[34 篇 34.1](docs/34-os-integration.md#341-线程边界ui-线程与-dispatcherqueue)）
- **非打包进程 `Microsoft.Windows.Storage.ApplicationData::GetDefault()` 同样抛 "该进程没有程序包标识符"**（运行时级）：它和 `Windows.Storage.ApplicationData::Current()` 一样依赖包身份，不是非打包的救命稻草；非打包要退回 `%LOCALAPPDATA%` 或给应用挂稀疏包（见 [34 篇 34.2.1](docs/34-os-integration.md#1021-winrt-文件-api)）
- **ViewModel 的 IDL 必须声明 `: Microsoft.UI.Xaml.Data.INotifyPropertyChanged`**（编译级 + 运行时级）：否则 `Mode=OneWay` 绑定静默不刷新（见 [32 篇 32.3](docs/32-binding-mvvm.md#323-页面与-viewmodel-的连接)）
- **有构造函数的 runtimeclass 必须写 `factory_implementation` 结构**（编译级）：漏掉是链接/激活失败（见 [32 篇 32.2](docs/32-binding-mvvm.md#322-可观察对象在-cwinrt-里实现-inotifypropertychanged)）
- **按名字挂接的事件处理器（`Click="OnX"`）不需要进 IDL**，只有 `x:Bind` 路径上的成员才需要（编译级，见 [04 篇 4.7](docs/04-first-app.md#47-常见启动期错误)、[05 篇 5.2](docs/05-project-structure.md#52-目录组织)）
- **MIDL 不能跨 `.idl` 解析 runtimeclass 引用**（编译级，`MIDL2011`）：互相引用的类要合并进同一个 `.idl`（见 [04 篇 4.8](docs/04-first-app.md#48-命令行构建模板之外必须补上的工程细节)、[05 篇 5.2](docs/05-project-structure.md#52-目录组织)）
- **命令行构建的一整套工程细节**（编译级）：`/utf-8` 无 BOM、`pch.h` 要含所有 `x:Class` 实现头、每个 `<Page>.xaml.g.hpp` 要靠 `CompileXamlPageImplementationFiles` target 喂给第二趟编译、`App.xaml.g.hpp` 自带 `wWinMain`、`#undef GetCurrentTime`——见 [04 篇 4.8](docs/04-first-app.md#48-命令行构建模板之外必须补上的工程细节)

> 诚实边界：元数据证明签名、编译证明能构建、运行时截图证明**被点到的那条流程**行为正确。没被 ui-smoke 点到的流程只有编译级证据——例如 [34 篇 34.2.2](docs/34-os-integration.md#1022-文件选择器windows-app-sdk-picker) 的 `FileOpenPicker` 会弹**系统模态对话框**，合成点击驱动不了它，因此它是"编译通过、签名对照元数据核过"，但未做运行时点击验证。

## 常见错误速查

| 症状 | 原因与解法 | 出处 |
|------|-----------|------|
| 绑定了属性，界面不刷新 | ① `x:Bind` 默认 `OneTime`，忘加 `Mode=OneWay`；② 源没实现 `INotifyPropertyChanged`；③ 属性名与通知名不一致；④ 属性没进 IDL | [32 篇 32.3](docs/32-binding-mvvm.md#323-页面与-viewmodel-的连接) |
| `std::vector` 绑到 `ItemsSource` 列表不动 | 绑定数据源必须是 WinRT 集合接口，用 `winrt::single_threaded_observable_vector` | [32 篇 32.4](docs/32-binding-mvvm.md#324-可观察集合iobservablevector) |
| ContentDialog 抛 "XamlRoot has not been set" | WinUI 3 必须 `dialog.XamlRoot(...)`，且值从**内容树根元素**取（`rootPanel().XamlRoot()`）——`Window` 自己没有 `XamlRoot` 成员 | [24 篇](docs/24-dialogs-flyouts.md) |
| 后台线程改控件抛异常 | UI 对象只能在 UI 线程访问，用 `Microsoft.UI.Dispatching.DispatcherQueue::TryEnqueue` 切回再改（**别用 `resume_foreground`**，WinUI 3 桌面线程上它永不恢复） | [32 篇 32.7](docs/32-binding-mvvm.md#327-异步后台工作与-ui-更新) |
| `IsChecked()` 当 bool 用编译不过 | 返回 `IReference<bool>` 三态，需 `.Value()` 解包 | [10 章](docs/10-checkbox-radio.md) |
| XAML 引用成员报"找不到类型" | `x:Bind` 路径上的属性/方法必须声明在 IDL，`x:Class` 与 runtimeclass 全名要一致；**按名字挂接的事件处理器（`Click="OnX"`）不需要进 IDL**。若是 `.idl` 之间互相引用报 `MIDL2011`，把相关 runtimeclass 合并进同一个 `.idl` | [04 篇 4.7](docs/04-first-app.md#47-常见启动期错误)、[04 篇 4.8](docs/04-first-app.md#48-命令行构建模板之外必须补上的工程细节) |
| 桌面应用 FileOpenPicker 弹不出来 | 首选 WASDK 的 `Microsoft.Windows.Storage.Pickers`，构造时传 `AppWindow().Id()`；旧路径才需要 `IInitializeWithWindow` + HWND | [34 篇 34.2.2](docs/34-os-integration.md#1022-文件选择器windows-app-sdk-picker) |
| `Click="{x:Bind VM.SomeMethod}"` 编译报错 | 函数绑定的方法签名必须和事件委托逐参数对上；绑 `ICommand` 要用 `Command=` 而不是 `Click=` | [03 篇 3.6](docs/03-xaml.md#36-xbind-与-binding编译期绑定-vs-运行期绑定)、[32 篇 32.6](docs/32-binding-mvvm.md#326-动作入口xbind-函数绑定优先于-icommand) |
| 集合整体换了对象，界面还显示旧数据 | `IObservableVector` 的通知只跟**内容增删**；替换集合对象本身要再 `RaisePropertyChanged(L"Tasks")` | [32 篇 32.4](docs/32-binding-mvvm.md#324-可观察集合iobservablevector) |
| 后台线程一调 WinRT 就报奇怪错误 | 任何 WinRT 调用前先 `winrt::init_apartment(winrt::apartment_type::multi_threaded)`；报错信息和真实原因差得很远 | [34 篇 34.1](docs/34-os-integration.md#341-线程边界ui-线程与-dispatcherqueue) |
| 非打包运行取应用数据目录抛异常 | `Windows.Storage.ApplicationData::Current()` **和** WASDK 的 `Microsoft.Windows.Storage.ApplicationData::GetDefault()` **都依赖包身份**，非打包进程两个都抛 "该进程没有程序包标识符"（实测）。非打包就退回 `%LOCALAPPDATA%`（`GetEnvironmentVariableW` / `SHGetKnownFolderPath`）拼应用名；想用托管语义就给应用挂稀疏包/MSIX | [34 篇 34.2.1](docs/34-os-integration.md#1021-winrt-文件-api) |
| 逻辑上无循环引用却内存不释放 | 事件订阅未退订，或引用计数成环；用 `weak_ref` 断环 | [34 篇 34.5](docs/34-os-integration.md#105-对象生命周期引用计数--raii) |
| 改 XAML 不生效 | 清理 `Generated Files` 重新构建 | [04 篇 4.7](docs/04-first-app.md#47-常见启动期错误) |
| 事件处理器越写越长，页面成泥团 | 事件只做转交，逻辑进 ViewModel，状态进可观察属性 | [05 篇](docs/05-project-structure.md)、[22 章](docs/22-navigationview.md) |

## 后续扩展方向

下面每一项都对照本机 1.8 元数据确认过"能力存在"，不是凭印象列的清单：

- **实战篇（优先级最高）**：现在教程停在"每章讲机制"，缺一个把 IDL → ViewModel → 绑定 → 导航 → 持久化 → MSIX 串起来跑通的收束章节。同类教程（`wpf`、`mfc`、`android`）都以实战篇结尾
- **窗口与外壳篇**：`Microsoft.UI.Windowing.AppWindow`（含 `AppWindowTitleBar` / `AppWindowPresenter` / `AppWindowPresenterKind`）、`Window.ExtendsContentIntoTitleBar` + `Window.SetTitleBar(UIElement)`、`Window.SystemBackdrop`（基类 `Microsoft.UI.Xaml.Media.SystemBackdrop`，派生 `MicaBackdrop` / `DesktopAcrylicBackdrop`）、多窗口与 `AppWindow.Id` → `WindowId`；单实例靠 `Microsoft.Windows.AppLifecycle.AppInstance`（`GetInstances()` / `GetActivatedEventArgs()` / `Activated` 事件）与 `ActivationRegistrationManager`
- **值转换器**：WinUI 3 的 `x:Bind` 没有内置 bool→`Visibility` 之类的转换，`IValueConverter` 是绕不开的一块，目前全教程未覆盖
- **诊断与测试**：绑定失败的定位手段（`DebugSettings` / 输出窗口）、单元测试工程怎么起（`CppUnitTest` 或 GoogleTest + C++/WinRT）、CI 里如何构建打包工程
- **能力集成**：`Microsoft.Windows.ApplicationModel.Background.BackgroundTaskBuilder` 后台任务；`Microsoft.Windows.AppNotifications.AppNotificationManager` 通知（含 `AppNotificationProgressData` 进度）；网络用 `Windows.Web.Http` 或 WinHTTP + 进度回报
- **进阶机制**：自定义控件与 `ControlTemplate`、自定义依赖属性、`VisualStateManager` + `AdaptiveTrigger`（[07 篇](docs/06-layout.md) 完全没提状态与触发器这块，自适应目前只有 Grid 拆分一档）
- **生态**：CommunityToolkit 的 C++ 可用组件、WinUI 与 Win32 混合（XAML Island 思路）

> 明确不做：**系统托盘图标**。本机 1.8 的**全部** WASDK `.winmd` 里搜不到任何 `NotifyIcon` / `SystemTray` / `TrayIcon` 类型——该能力当时仍是 preview 或未进公开元数据。真要写托盘，得走 Win32 `Shell_NotifyIcon`，那是另一套故事，别按"WinRT API 应该有一个"来找。
