# 1. 概念总览：WinRT / WinUI 3 / XAML / Windows App SDK

学 WinUI 3 最容易犯的错误，是一上来就背控件名和 XAML 语法，却不知道这套技术栈里每个组件到底负责什么。这一篇先把地基打好，后面所有章节都建立在它之上。

## 1.1 分层架构：谁负责什么

把整个技术栈从下到上画出来：

```text
┌─────────────────────────────────────────────┐
│  你的应用                                    │
│  XAML（界面声明）+ C++/WinRT（逻辑）          │
├─────────────────────────────────────────────┤
│  WinUI 3 —— UI 框架                          │
│  窗口、控件、布局、样式、绑定、动画             │
├─────────────────────────────────────────────┤
│  Windows App SDK —— 分发单元                 │
│  把 WinUI 3、应用生命周期、打包等 API          │
│  从操作系统里拆出来，随应用一起分发             │
├─────────────────────────────────────────────┤
│  WinRT —— 运行时对象模型                     │
│  对象、接口、属性、事件、异步、元数据、ABI      │
├─────────────────────────────────────────────┤
│  Win32 / COM —— 系统底座                     │
│  进程、线程、内存、句柄、消息循环              │
├─────────────────────────────────────────────┤
│  Windows OS                                 │
└─────────────────────────────────────────────┘
```

每一层的职责可以用一句话说清：

| 组件 | 一句话定位 | 详细内容 |
|------|-----------|---------|
| **Win32 / COM** | 系统底座：进程、线程、内存、句柄、C 风格函数 API | — |
| **WinRT** | Windows 给应用暴露能力的**统一对象模型**：对象 + 接口 + 事件 + 异步，跨语言，有标准 ABI 和元数据 | 见 [02-winrt.md](./02-winrt.md) |
| **Windows App SDK** | 一个 NuGet 包/运行时分发单元，把原本烧录在 OS 里的平台 API（含 WinUI 3）解耦出来，让应用自带而不是依赖系统版本 | 见本文 1.5 |
| **WinUI 3** | 现代 Windows 的 UI 框架：XAML 解析器 + 控件库 + 布局 + 样式 + 绑定引擎 | 见本文 1.3 |
| **XAML** | 声明式 UI 标记语言，描述界面树；**会被编译器翻译成真正的代码** | 见 [03-xaml.md](./03-xaml.md) |

## 1.2 WinRT：Windows 能力的对象模型

Win32 时代，系统能力暴露成 C 函数：`CreateWindow`、`SendMessage`、`RegOpenKey`。你操作的是句柄和消息。

WinRT 把同一批系统能力重新组织成**对象**：

- 对象有属性：`Title()`、`IsEnabled()`
- 对象有方法：`Open()`、`SaveAsync()`
- 对象发事件：`Click`、`Closed`
- 对象之间通过**接口**（如 `IInspectable`）被统一识别和调用
- 一切调用都走同一套二进制协议（ABI），所以 C++、C#、Rust 都能用同一批 API

WinRT **不是某个 UI 框架**，也不是一个类库那么简单——它是 Windows 平台的运行时契约。WinUI 3 的每一个控件、每一处存储 API，都是 WinRT 对象。机制细节见 [02-winrt.md](./02-winrt.md)。

## 1.3 WinUI 3：从 UWP XAML 拆出来的 UI 框架

WinUI 3 的前身是 UWP 的 XAML 框架（`Windows.UI.Xaml`）。UWP 时代，XAML 框架是操作系统的一部分：系统带什么版本，你就只能用什么版本，迭代被 OS 更新周期锁死。

WinUI 3 做的事情是**把 XAML 框架从操作系统里拆出来**：

- 命名空间从 `Windows.UI.Xaml` 变成 `Microsoft.UI.Xaml`
- 框架随 **Windows App SDK**（NuGet 包）一起分发，不再依赖系统版本
- 应用模型从 UWP 变回普通 Win32 桌面进程：你的 WinUI 3 应用就是一个 `wWinMain` 入口的 Win32 程序
- 支持**打包**（MSIX）和**非打包**（unpackaged，直接跑 exe）两种部署方式

所以准确的定义是：

> **WinUI 3 = Windows App SDK 分发的、运行在 Win32 进程里的现代 XAML UI 框架。**

它不是"新一代 WPF"（WPF 绑定在 .NET/CLR 上），也不是"UWP 复活"（应用模型完全不同）。它是把 XAML 这套 UI 表达能力放回到原生 Windows 平台上。

### WPF 和 WinUI 3 的关系

WPF 是 .NET 时代的优秀桌面 UI 框架，至今仍在维护。但它和 WinUI 3 是两回事：

- WPF 绑定 .NET 运行时和自己的渲染/应用模型；WinUI 3 建立在 WinRT 对象模型上，与系统平台能力（Composition、MSIX、DPI、窗口生命周期）原生集成
- 两者的 XAML 语法相似，但**不是同一种方言**：控件集不同、绑定语法不同（WinUI 3 用 `x:Bind` 优先）、属性系统实现不同
- 微软的桌面开发主线投资在 WinUI 3 / Windows App SDK 这一边

本教程使用 **C++/WinRT** 作为开发语言——它是 WinRT 的官方 C++17 投影，也是 WinUI 3 的一等公民语言。

## 1.4 XAML：被编译的界面声明

XAML（Extensible Application Markup Language）用 XML 语法描述界面树：

```xml
<StackPanel Spacing="12">
    <TextBlock x:Name="StatusText" Text="Ready" />
    <Button Content="Click me" Click="OnClick" />
</StackPanel>
```

关键认知：**XAML 不是运行时解析的模板，而是被编译成 C++ 代码的源文件**。构建时，XAML 编译器会：

1. 把上面的标记编译成等价的 C++ 对象创建代码（放进 `.g.h` / `.g.cpp`）
2. 为 `x:Name="StatusText"` 生成一个访问器函数 `StatusText()`
3. 把 `Click="OnClick"` 编译成事件订阅代码，连接到你的 C++ 成员函数
4. 生成类型信息（XamlTypeInfo）供运行时反射使用

运行时 `InitializeComponent()` 执行的就是这批生成代码，把界面树真实地构建出来。XAML 与 C++ 不是"两个世界"，而是**同一个类被拆写在两个文件里**（`.xaml` + `.h/.cpp`）。编译流程细节见 [03-xaml.md](./03-xaml.md)。

## 1.5 Windows App SDK：平台能力的分发单元

Windows App SDK 不是一个框架，而是一个**装着平台 API 的 NuGet 包 + 运行时**。它包含：

- WinUI 3（UI 框架本体）
- 应用生命周期、窗口管理（`AppWindow`）、`DispatcherQueue`
- 打包/部署支持（MSIX、bootstrapper）
- 其他从 OS 解耦出来的 WinRT API

写 WinUI 3 应用时你必然在用 Windows App SDK，但反过来 Windows App SDK 还包含大量与 UI 无关的 API。二者的关系是"UI 框架装在平台包里"，不是同一个东西。

## 1.6 历史脉络：为什么会有这么多代 XAML

XAML 家族几经演化，理解这条线可以避免"为什么语法看起来像又不像"的困惑：

```text
2006  WPF XAML         —— .NET/CLR 上的 UI 标记，桌面
2007  Silverlight XAML —— 浏览器轻量版，已死
2012  WinRT / Windows 8 —— Windows 获得运行时对象模型
2012  UWP XAML          —— Windows.UI.Xaml，烧录在 OS 里
2018  WinUI 2           —— UWP 的控件库更新包（Toolkit 性质）
2021  WinUI 3 / Windows App SDK
                        —— Microsoft.UI.Xaml，从 OS 拆出，
                           随应用分发，跑在 Win32 进程里
```

一句话总结这条演化线：

> XAML 这个"界面描述语言"一直活着，但它的宿主换了三代运行时：.NET → UWP/OS → Windows App SDK。今天学 WinUI 3，学的是**第三代宿主**上的 XAML。

## 1.7 桌面应用模型：打包与非打包

WinUI 3 应用是普通 Win32 进程，但部署有两种形态：

| | 打包（MSIX） | 非打包（unpackaged） |
|---|---|---|
| 部署方式 | `.msix` 安装包 / Store | 直接运行 `.exe` |
| 运行时依赖 | 自动，MSIX 保证 Windows App SDK 运行时可用 | 需要 bootstrapper 自动初始化或自包含部署 |
| 身份 | 有包身份（可用全部平台 API） | 部分需要包身份的 API 受限 |
| 适用 | 正式分发、Store 上架 | 开发调试、内部工具 |

Visual Studio 的 WinUI 3 模板默认生成打包应用。两种形态的工程结构完全一样，详见 [09-theming-packaging.md](./09-theming-packaging.md)。

## 1.8 关键名词速查

| 名词 | 含义 |
|------|------|
| WinRT | Windows 运行时对象模型（对象/接口/事件/异步/元数据/ABI） |
| C++/WinRT | WinRT 的官方 C++17 投影，header-only，`winrt::` 命名空间 |
| 投影（projection） | 把 WinRT 类型翻译成某语言的自然 API 的生成层 |
| Windows App SDK | 分发平台 API（含 WinUI 3）的 NuGet 包 + 运行时 |
| WinUI 3 | Windows App SDK 里的现代 XAML UI 框架 |
| XAML | 声明式 UI 标记，编译成代码 |
| `.g.h` / `.g.cpp` | XAML/C++/WinRT 编译器生成的代码文件 |
| IDL（MIDL 3.0） | 声明 WinRT runtimeclass 公共接口的源文件 |
| MSIX | 现代 Windows 应用安装包格式 |
| Fluent Design | Windows 的现代设计语言，由主题资源系统落地 |

---

下一篇：[02-winrt.md](./02-winrt.md) —— 深入 WinRT 的运行机制。
