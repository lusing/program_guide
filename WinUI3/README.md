# WinUI 3 C++/WinRT 编程指南

面向"从零到工程"的 WinUI 3 教程。目标不是罗列控件语法，而是讲清三层东西：

1. **机制**：WinRT 对象模型、XAML 编译流程、绑定引擎——代码背后发生了什么
2. **结构**：App / Window / Page / ViewModel / Model / Service 的分层与协作
3. **交付**：主题资源、Assets、Manifest、MSIX 打包

开发语言为 **C++/WinRT**（WinRT 的官方 C++17 投影）。教程代码均为真实 WinUI 3 写法，需要 Visual Studio 2022 + Windows App SDK C++ 模板工程验证。

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
| [06 常用控件](docs/06-controls.md) | Button/TextBox/CheckBox/ComboBox/ListView/ContentDialog 等的真实写法与使用模式 | 控件在工程里扮演什么角色、哪些细节是坑 |
| [07 布局](docs/07-layout.md) | Grid/StackPanel/Border/RelativePanel/ScrollViewer 与真实页面结构 | 页面区域怎么划分和伸缩 |

### 应用篇

| 篇 | 内容 | 回答的问题 |
|---|------|-----------|
| [08 绑定、MVVM 与异步](docs/08-binding-mvvm.md) | INotifyPropertyChanged 完整实现、IObservableVector、x:Bind 模式、ICommand、协程异步模式 | 界面怎么跟随数据变、耗时工作怎么不卡 UI |
| [09 主题资源与交付](docs/09-theming-packaging.md) | ThemeResource/StaticResource、资源字典分层、主题切换、Assets/Manifest/MSIX | 深浅色怎么自动适配、应用怎么打包分发 |
| [10 OS 集成](docs/10-os-integration.md) | 线程边界与 DispatcherQueue、文件/选择器、注册表/JSON、子进程、生命周期 | UI 框架之下的系统能力怎么用 |

## 学习路线

按编号顺序读即可，它是刻意安排的依赖链：

```text
01 ── 02 ── 03        概念地基：每层组件是什么、怎么工作
        │
04 ── 05              骨架：真实应用怎么启动、代码怎么分层
   │
06 ── 07              界面能力：控件与布局
   │
08                    枢纽：绑定 / MVVM / 异步（最核心的一篇）
   │
09 ── 10              应用级：主题交付与系统能力
```

已经熟悉某个领域的读者可以跳读：

- 会 WPF/UWP → 先读 [02 WinRT 机制](docs/02-winrt.md) 和 [03 XAML 机制](docs/03-xaml.md) 3.6（`x:Bind` 与 WPF 的 `{Binding}` 差异很大），再按需查目录
- 会 Win32/C++ → [04 第一个真实应用](docs/04-first-app.md) 起步，重点体会 IDL 和投影（[02 篇](docs/02-winrt.md) 2.4）
- 只想快速上手 → [04](docs/04-first-app.md) → [06](docs/06-controls.md) → [08](docs/08-binding-mvvm.md)，出问题再回概念篇

## 环境要求

- Windows 10 1809+（建议 Windows 11）
- Visual Studio 2022，工作负载含 **Windows 应用开发**（Windows App SDK + C++ 模板）
- 工程模板：**Blank App, Packaged (WinUI 3 in C++)**

> 本目录不包含独立示例工程。教程代码片段请对照模板工程验证——XAML + IDL + 协程这套东西必须以真实工程为载体，单文件 `.cpp` 无法编译出 WinUI 3 应用。

## 常见错误速查

| 症状 | 原因与解法 | 出处 |
|------|-----------|------|
| 绑定了属性，界面不刷新 | ① `x:Bind` 默认 `OneTime`，忘加 `Mode=OneWay`；② 源没实现 `INotifyPropertyChanged`；③ 属性名与通知名不一致；④ 属性没进 IDL | [08 篇 8.3](docs/08-binding-mvvm.md#83-页面与-viewmodel-的连接) |
| `std::vector` 绑到 `ItemsSource` 列表不动 | 绑定数据源必须是 WinRT 集合接口，用 `winrt::single_threaded_observable_vector` | [08 篇 8.4](docs/08-binding-mvvm.md#84-可观察集合iobservablevector) |
| ContentDialog 抛 "XamlRoot has not been set" | WinUI 3 必须设置 `dialog.XamlRoot(...)` | [06 篇 6.7](docs/06-controls.md#67-contentdialog临时确认交互) |
| 后台线程改控件抛异常 | UI 对象只能在 UI 线程访问，`resume_foreground` 切回再改 | [08 篇 8.7](docs/08-binding-mvvm.md#87-异步后台工作与-ui-更新) |
| `IsChecked()` 当 bool 用编译不过 | 返回 `IReference<bool>` 三态，需 `.Value()` 解包 | [06 篇 6.3](docs/06-controls.md#63-checkbox-与-radiobutton状态表达) |
| XAML 引用成员报"找不到类型" | 被引用的属性/事件必须声明在 IDL，且 `x:Class` 与 runtimeclass 全名一致 | [04 篇 4.7](docs/04-first-app.md#47-常见启动期错误) |
| FileOpenPicker 运行时崩溃 | 桌面应用必须用 `IInitializeWithWindow` 绑定窗口句柄 | [10 篇 10.2.2](docs/10-os-integration.md#1022-fileopenpicker桌面应用必须传窗口句柄) |
| 逻辑上无循环引用却内存不释放 | 事件订阅未退订，或引用计数成环；用 `weak_ref` 断环 | [10 篇 10.5](docs/10-os-integration.md#105-对象生命周期引用计数--raii) |
| 改 XAML 不生效 | 清理 `Generated Files` 重新构建 | [04 篇 4.7](docs/04-first-app.md#47-常见启动期错误) |
| 事件处理器越写越长，页面成泥团 | 事件只做转交，逻辑进 ViewModel，状态进可观察属性 | [05 篇](docs/05-project-structure.md)、[06 篇 6.8](docs/06-controls.md#68-控件协作的总原则) |

## 后续扩展方向

- 实战应用：任务管理器（增删改查 + 持久化）、设置页 + 多页导航 + 深浅色切换
- 进阶机制：自定义控件与 ControlTemplate、自定义依赖属性、`x:Bind` 函数绑定进阶
- 能力集成：网络请求 + 进度、`AppWindow` 窗口定制、通知、后台任务
- 生态：CommunityToolkit 的 C++ 可用组件、WinUI 与 Win32 混合（Island 思路）
