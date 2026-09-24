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

## 1.6 历史脉络：每一代 UI 技术在解决什么问题

如果你有前端或 WPF 经验，最容易困惑的是：微软为什么反复推出新 UI 技术——WinForms、WPF、Silverlight、UWP、WinUI 3，每代语法都像又都不像？

答案不是"新就是好"，而是**每一代都在解决上一代解决不了的具体问题，同时留下新的问题**。把每一代的动机和局限摆出来，这条演化线就通了。

### 先给全景表

| 技术 | 年代 | 运行时 | 当时要解决的问题 | 留下的新问题 |
|------|------|--------|-----------------|-------------|
| Win32 API | 1985– | 无（C 函数） | —（一切的基础） | 开发效率低：无布局、无绑定、无样式 |
| WinForms | 2002 | .NET Framework | Win32 太难写，要 RAD 拖控件快速出活 | 本质是 GDI+/Win32 控件包装，表现力差；难做动画、高 DPI、现代视觉 |
| WPF | 2006 | .NET Framework | WinForms 表现力不够：要 DirectX 渲染、样式、模板、绑定 | 深度绑定 CLR；启动重；自成一体的渲染和应用模型与系统脱节 |
| Silverlight | 2007 | 浏览器插件 | 把 WPF 式开发带进浏览器，对标 Flash | 生死系于插件生态；HTML5 兴起后被夹死，2012 年起死亡 |
| WinRT / UWP | 2012 | Windows OS | 触屏时代：需要跨语言对象模型、沙盒应用模型、现代输入 | 框架烧录在 OS 里，迭代被系统更新锁死；UWP 应用模型封闭，桌面开发者不买账 |
| WinUI 2 | 2018 | Windows OS（NuGet 控件包） | UWP 控件不必等系统更新 | 只解决了控件层，框架本体还在 OS 里 |
| WinUI 3 | 2021 | Windows App SDK（随应用分发） | 把 XAML 框架从 OS 拆出来，跑回 Win32 进程 | （当下的进行时）生态尚在成熟 |

### 逐代展开

#### Win32：一切的地基，但写 UI 太苦

Win32 是 C 函数 + 句柄 + 消息循环。它至今仍是所有 Windows UI 框架的底层，但直接用它做界面意味着：手动管理窗口类、消息、布局、重绘，没有任何数据绑定和样式机制。第一代托管方案针对的就是这个痛点。

#### WinForms：解决"快速出活"

WinForms 把 Win32 控件包装成 .NET 对象，拖控件、挂事件就能出应用，十年来企业内部工具的绝对主力。它的天花板也很明确：渲染走 GDI+，控件是 Win32 老控件的老皮，做不出平滑动画、缩放、现代视觉，高 DPI 支持一直半残。它本质上是"用 OO 语法写 Win32"，不是新的 UI 引擎。

#### WPF：解决"表现力"

WPF 是一次彻底重写：DirectX 渲染、依赖属性、样式模板、数据绑定、XAML——这套概念直到今天仍是微软 XAML 系的骨架。它到今天仍在维护，依然是很多桌面产品的选择。但它的局限也真实存在：

- 深度绑定 .NET/CLR：UI、渲染、应用模型、部署全部长在 .NET Framework 上
- 它的渲染和应用模型是自成一体的封闭栈，与系统新能力（Composition、现代窗口、DPI 感知、打包模型）不是原生集成，而是各自演化
- WPF 解决的是"2006 年 .NET 桌面开发的表现力问题"，而不是"现代 Windows 平台的应用形态问题"

这不是说 WPF 失败了——它是成功的，只是它的成功定义在那个时代的问题域里。

#### Silverlight：解决"浏览器里做富应用"

Silverlight 是 WPF 的浏览器插件精简版，对标 Flash。它的死因不在技术而在生态：移动时代浏览器集体驱逐插件、HTML5 接管了富 Web 应用。教训值得记住——**当宿主环境变了，再好的框架也会连坐**。这条教训在后面 UWP 身上还会应验一次。

#### WinRT + UWP：解决"触屏时代与跨语言"

Windows 8 是微软对 iPad 和触屏的回应。这场转型需要的东西远超一个 UI 库：

- 一个**跨语言**的运行时对象模型——让 C#、C++、JS 能调用同一批系统能力（这就是 WinRT：COM 的现代化 + 标准元数据 + 统一 ABI）
- 一个新的应用模型：沙盒、生命周期管理、触摸优先的交互
- 一个烧录在 OS 里的 XAML 框架（`Windows.UI.Xaml`）和 Microsoft Store 分发体系

这一代的两个遗留问题都很致命：

1. **框架在 OS 里**：XAML 框架的新特性必须等系统版本普及，开发者拿到的 UI 能力被用户的 Windows 版本锁死
2. **应用模型封闭**：强制沙盒、强制打包、以 Store 为中心——桌面开发者用脚投票，绝大多数继续留在 Win32/.NET 阵营

WinRT 对象模型本身是这一代留下的**持久资产**（它今天仍是 Windows API 的暴露方式），失败的是 UWP 应用模型和"框架住进 OS"这个分发方式。

#### WinUI 2：过渡产品

WinUI 2 只是把 UWP 的**控件库**抽成 NuGet 包（`Windows.UI.Xaml.Controls` 的更新层），让控件样式不必等系统更新。它是正确的方向，但只动了一层——XAML 框架本体还在 OS 里。

#### WinUI 3：把框架从 OS 里搬出来

WinUI 3 / Windows App SDK 是对上面两个遗留问题的直接回答：

- XAML 框架改名 `Microsoft.UI.Xaml`，作为 NuGet 包**随应用分发**，不再依赖系统版本——框架迭代和 OS 更新解耦
- 应用模型回归 **Win32 进程**：普通 `wWinMain`、普通窗口、无强制沙盒；打包（MSIX）和非打包都支持——UWP 时代桌面开发者流失的问题不复存在
- 保留 WinRT 对象模型作为 API 基础——上一代留下的资产继续用

所以 WinUI 3 的准确读法不是"又一个新框架"，而是：**WinRT 对象模型（2012 年的资产）+ 现代 XAML 框架 + Win32 应用模型的自由度，三者的合流**。

### 对前端开发者的一个参照

如果你来自 Web 前端，可以建立这样的粗略映射来降低陌生感：

| Web 前端 | XAML 系 |
|---------|---------|
| HTML 结构 | XAML 元素树 |
| CSS 样式 | Style / 资源字典 / ThemeResource |
| JS 事件处理 | code-behind / 事件处理器 |
| 框架的数据绑定 | `x:Bind`（编译期） |
| 浏览器版本碎片化 | UWP 时代"框架被 OS 版本锁死"——WinUI 3 的分发方式正是为了终结它 |

Silverlight 与 Flash 的竞争、HTML5 的胜利，也可以帮助理解微软的处境：富客户端的阵地最后在 Web 被标准赢走，在桌面则回到了"贴近操作系统的原生栈"。WinUI 3 就是微软在桌面侧给出的答案。

### 一句话总结这条演化线

> 每一代技术都在解决上一代的具体短板：WinForms 补 Win32 的效率，WPF 补 WinForms 的表现力，Silverlight 想进浏览器（被生态终结），UWP 补触屏与跨语言（被 OS 锁死和封闭模型反噬），WinUI 3 则把 UWP 时代留下的 WinRT 资产从 OS 里搬回 Win32 世界。语法相似是因为它们同宗，架构不同是因为宿主换了三代。

## 1.7 桌面应用模型：打包与非打包

WinUI 3 应用是普通 Win32 进程，但部署有两种形态：

| | 打包（MSIX） | 非打包（unpackaged） |
|---|---|---|
| 部署方式 | `.msix` 安装包 / Store | 直接运行 `.exe` |
| 运行时依赖 | 自动，MSIX 保证 Windows App SDK 运行时可用 | 需要 bootstrapper 自动初始化或自包含部署 |
| 身份 | 有包身份（可用全部平台 API） | 部分需要包身份的 API 受限 |
| 适用 | 正式分发、Store 上架 | 开发调试、内部工具 |

Visual Studio 的 WinUI 3 模板默认生成打包应用。两种形态的工程结构完全一样，详见 [33-theming-packaging.md](./33-theming-packaging.md)。

### 1.7.x 四个功能工程的架构回望

本教程的控件篇由四个功能工程承载（设置中心/编辑器/数据浏览器/主题实验室）——它们合起来是对 1 章分层图的实体回答：**每层都能在真实代码里指出来**。设置中心是"外壳+页面+持久化"的最小完整样（22 章 NavigationView + SettingsStore）；编辑器把文档模型与 UI 分离（m_docs 向量 vs TabView 视图）；数据浏览器是数据驱动 UI 的范式（单一 m_view 喂三视图）；主题实验室站在资源系统层（26 章）。**读 1 章时记不住的分层，跑四个工程各一次就长在身体里了**——这是"功能工程取代画廊"的教学论根据。

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
