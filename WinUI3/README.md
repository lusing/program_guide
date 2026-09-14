# WinUI 3 C++/WinRT 编程指南

> 这是面向“从零到工程”学习 WinUI 3 的完整教程，不再停留在表面概念介绍。
> 本教程的重点是：理解 WinUI 3 的真正工程结构、XAML + C++/WinRT 的协作方式、主要控件的使用方法，以及如何组织一个真实的桌面应用。

## 1. 课程目标

本教程适合：

- 想学习 WinUI 3 的开发者
- 已经了解 Win32 / MFC / WPF 但希望掌握现代 Windows UI
- 计划使用 C++/WinRT 开发 Windows 桌面应用者

目标能力：

- 理解 WinUI 3 的应用架构
- 熟悉 XAML 和 C++/WinRT 的协作方式
- 掌握常见控件的实际使用
- 能够组织 ViewModel / 命令 / 状态管理
- 能处理异步任务、导航、对话框和资源主题
- 能从逻辑上构建可维护的桌面应用

---

## 2. WinUI 3 是什么

如果你还在学 WinUI 3，最容易犯的错误就是：一上来就看控件名、事件名、XAML 语法，完全不知道这套技术到底在干什么。这个问题的根源就是：很多概念本来就没有讲清楚。

所以我们先把最基础的问题说透：

- 什么是 WinUI 3？
- 什么是 XAML？
- 什么是 WinRT？
- 什么是 Windows App SDK？
- 它们之间是什么关系？

### 2.1 先说结论：它们是一套“现代 Windows 应用开发栈”

可以把它们理解成下面这层关系：

```text
Windows OS
   ↓
Win32 / COM / Runtime 基础设施
   ↓
WinRT（Windows Runtime 对象模型）
   ↓
Windows App SDK（统一开发平台、运行时、打包能力）
   ↓
WinUI 3（UI 框架）
   ↓
你的应用（XAML + C++/WinRT / C# / 业务代码）
```

这说明：

- WinUI 3 不是凭空出现的 UI 库，它依赖 Windows 运行时代码模型和平台能力
- XAML 不是操作系统本身的一部分，而是 WinUI 3 使用的一种声明式 UI 语言
- WinRT 不是某个单独的控件框架，而是 Windows 运行时的对象模型和 ABI 机制
- Windows App SDK 则是统一封装这些能力、让开发者更容易做应用的开发平台包

### 2.2 什么是 WinUI 3

WinUI 3 是 Microsoft 推出的现代 Windows UI 开发框架，目标是让桌面应用（尤其是 Windows 11 及更高版本）拥有更统一、更现代、更容易扩展的界面模型。

但这里的“统一、现代、扩展”不能只当口号理解，必须把它落到真实问题上：

- WPF / Silverlight 时代的 XAML 很强，但它深深绑定在 .NET 运行时和一套固定的应用模型中
- Windows 平台需要一套更贴近系统运行时的 UI 方案
- 桌面开发不仅要做界面，还要做应用生命周期、部署、资源、主题、交互、状态管理、原生 API 集成
- 现代应用要求 UI 与平台能力更紧密、更统一，而不是一套框架在一套运行时里自娱自乐

所以 WinUI 3 不只是“换了一套控件和 XAML 语法”，而是要把 XAML 重新放回到一个更统一的 Windows 平台模型中。

它的典型特点是：

- 使用 XAML 声明界面结构和布局
- 使用 C++/WinRT、C# 或其他语言连接业务逻辑
- 更适合 Fluent Design 风格和现代桌面程序
- 更适合 Windows 11 及后续版本的桌面开发生态
- 更强调以 WinRT / Windows App SDK / 平台能力为基础的统一应用模型

### 2.2.1 为什么 Silverlight、WPF 不再是“统一的现代模型”

这要从“技术栈”和“平台现实”两个层面看。

#### 1）WPF 的底层渲染栈已经是老一代 Windows 图形模型

WPF 的 UI 是通过 WPF 运行时和 .NET 统一的渲染路径来完成的，它在历史上很好用，但它并不是面向现代 Windows 平台能力设计的。

关键问题包括：

- 它很强地绑定在 .NET / CLR / Dispatcher 这套模型上
- 它的图形和窗口模型并不是现代 WinRT/Windows App SDK 体系中的第一等公民
- 现代 Windows 应用越来越依赖 WinRT、Composition、DPI aware、窗口生命周期、MSIX 安装/更新和统一平台能力
- 对于现代桌面软件来说，UI 只是一个部分；应用打包、资源、主题、部署、系统集成也都需要统一支持

简单说：

- WPF 很强，但它更像一个“优秀的 .NET 桌面 UI 框架”
- WinUI 3 更像一个“现代 Windows 平台 UI 框架”

这两者不是一回事。

#### 2）Silverlight 早就没有成为桌面平台方案了

Silverlight 的问题更直接：

- 它不是 Windows 桌面应用的主力开发模型
- 它重点偏向轻量交互和浏览器/轻应用场景
- 它没有真正成为一个长期稳定、统一、原生集成的桌面应用体系
- 其生态最终被更现代的 Windows 应用模型替代了

因此它不能当作“现代桌面开发统一方案”的参照物。

#### 3）真正的根本原因：平台要求不一样了

今天的 Windows 桌面应用，不再只需要“有控件、有绑定、有动画”这么简单。

现代开发更多需要：

- WinRT 运行时对象模型
- 更统一的应用生命周期管理
- 更好的 App 安装和更新方案（MSIX / Windows App SDK）
- Fluent 主题和资源系统
- 更强的平台集成能力
- 更合适的高 DPI / 现代输入 / 窗口体验
- 同时兼顾本机能力和跨语言开发

WPF 在当时非常成功，但它解决的是一个比较明确的 .NET 桌面 UI 问题；WinUI 3 解决的是“现代 Windows 应用平台的 UI + 运行时 + 工程模型”这个更大范围的问题。

#### 4）所以，不是 XAML 失败了，而是老方案被平台进化抛下了

XAML 并没有消失，它只是从“ .NET 时代的 UI 语言”变成了“Windows 平台上的一层 UI 描述技术”。

也就是说：

- WPF 里用 XAML，是 .NET 体系下的 UI 表达
- WinUI 3 里用 XAML，是 Windows 平台应用模型下的 UI 表达

二者要看的是系统环境、运行时模型和工程结构，而不是仅仅看 XAML 语法还长什么样。

### 2.2.2 所以 WinUI 3 的“统一”是从什么地方来的

它不是口号，而是来自平台层面的统一：

- XAML 仍然负责界面描述
- WinRT 负责对象模型和平台能力
- Windows App SDK 提供统一运行时和应用平台
- WinUI 3 负责现代窗口和控件体系
- 主题、资源、布局、命令、绑定、异步任务都是在同一套模型里工作

这就比“只是一个 .NET UI 框架”要统一得多。

### 2.2.3 不是 WPF 没价值，而是它不再是现代平台的主线方案

WPF 仍然是很重要的历史技术，它在企业应用和桌面开发中影响深远。

但它不是现代 Windows 应用开发的主线平台方案，原因很直接：

- 它不是现代 WinRT 平台的一部分
- 它更偏 .NET 时代运行时模型
- 它不再是 Microsoft 推进的现代桌面应用主架构

换句话说：

> WPF 是一个伟大的时代产物，不是现代 Windows 平台的最终答案。

WinUI 3 的意义就在于：

- 它不是重打 WPF 的老剧本
- 而是把 XAML 重新放回到更现代、更统一、更贴近 Windows 的平台架构中

### 2.2.4 一句话总结

> XAML 没有失败，老一代方案被平台演化超越了；WPF 和 Silverlight 解决的是过去的桌面 UI 问题，而 WinUI 3 试图解决的是现代 Windows 应用开发所需的统一平台模型。

---

### 2.3 什么是 WinUI 3

### 2.3 什么是 XAML

XAML（Extensible Application Markup Language）是一种声明式标记语言，语法和 XML 很像，用来描述界面结构。

它的作用是：

- 写出界面的树形结构
- 定义控件、布局、样式、资源、绑定等
- 把“界面是什么”描述清楚，而不是把所有逻辑都塞进代码里

例如：

```xml
<StackPanel>
    <TextBlock Text="Hello WinUI 3" />
    <Button Content="Click me" Click="OnClick" />
</StackPanel>
```

这段 XAML 表示：

- 页面里有一个 `StackPanel`
- 里面放了两个控件：`TextBlock` 和 `Button`
- 按钮点击时，调用 `OnClick` 这个处理函数

XAML 的意义在于：

- 界面结构直观、可读
- 适合设计器和布局工作
- 和代码解耦，便于 UI 与业务逻辑分工

### 2.4 什么是 WinRT

WinRT（Windows Runtime）不是“一个很抽象的运行时概念”，它其实就是 Windows 平台向应用提供“对象接口”的统一方式。

它最核心的意义是：

- Windows 系统能力不再只暴露成 C 风格函数
- 它们被封装成对象、接口、属性、方法、事件
- 不同语言都能访问这些能力
- 不同语言之间的调用方式可以一致

如果你把 Win32 理解为“系统 API 的最底层 C 接口”，那 WinRT 就更像是：

- 把系统能力整理成更现代的对象模型
- 让开发者按对象/接口的方法去调用系统能力
- 并且把跨语言兼容、异步、对象生命周期这些问题标准化

#### 2.4.1 例子：不是直接写函数，而是调用对象

在 Win32 时代，你经常会看到类似这种思路：

- `CreateWindow`
- `RegisterClass`
- `SendMessage`
- `OpenFile`

这些本质上是函数型 API。

而 WinRT 更像：

- 对象有属性：`Name`, `Size`, `IsEnabled`
- 对象有方法：`Open()`, `Save()`, `Start()`
- 对象有事件：`Click`, `SelectionChanged`, `Loaded`
- 对象自身也有生命周期和接口契约

例如：

```cpp
winrt::Windows::Storage::StorageFile file;
```

或者：

```cpp
winrt::Windows::Foundation::IAsyncAction DoWorkAsync();
```

这里的重点不是“看起来像 C++ 代码”，而是：

- `StorageFile` 是一个对象
- `DoWorkAsync` 是异步对象方法
- 这些 API 在 runtime 层都有统一的调用协议

#### 2.4.2 为什么要有 WinRT

因为现代 Windows 应用不是简单的“调用几个函数”，而是：

- 需要和系统资源打交道
- 需要跨语言访问
- 需要支持异步编程
- 需要统一对象模型和 ABI 兼容性
- 需要将接口、事件和对象做成标准化能力

WinRT 就是为了满足这些需求而设计的。

#### 2.4.3 为什么 C++/WinRT 是 WinUI 3 里最重要的桥接方式

在 C++ 里，直接用 WinRT API 时，通常会看到 `winrt::` 这种命名空间和类型。它的作用是：

- 把 WinRT 的对象模型映射成 C++ 可用的类型
- 让 C++ 代码可以自然地创建对象、调用方法、处理异步
- 让 WinUI 3 的 XAML 代码和底层平台能力连接起来

例如：

```cpp
auto file = co_await winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(path);
```

它不是“C++ 语法特例”，而是对 WinRT 接口的正常调用方式。

#### 2.4.4 WinRT 和 Win32 的关系

最简单的理解是：

- Win32：底层系统 API，偏函数和句柄，老式 C 方式
- WinRT：更现代的对象和接口模型，跨语言、统一运行时

WinUI 3 不是直接把所有 Win32 代码搬到 XAML 里，而是：

- UI 层使用 XAML
- 逻辑层使用 C++/WinRT
- 平台能力来自 WinRT
- 一切都在统一的对象/接口模型下工作

这就是 WinUI 3 为什么能比老式 Windows UI 更现代。

#### 2.4.5 一句话总结

> WinRT 不是抽象概念，它就是 Windows 平台给应用提供的一套统一对象接口模型：对象、方法、属性、事件、异步能力都在里面，C++/C# 等语言都能按同一套规则访问 Windows 能力。

---

### 2.5 什么是 Windows App SDK

很多人一听到 WinUI 3，就会想“这不就是 Windows App SDK 吗？”，其实它们不是一回事。

Windows App SDK 是一个开发平台包，提供了：

- WinUI 3
- 应用生命周期管理
- 打包和部署能力
- 通知、窗口、资源、文件、后台能力等现代应用能力

换句话说：

- WinUI 3 是 UI 框架
- Windows App SDK 是“整个平台的开发运行时包”

因此：

- 你写 WinUI 3 程序时，通常也在使用 Windows App SDK
- 但 WinUI 3 本身不是 Windows App SDK 的全部

### 2.6 WinUI 3 和这些概念的关系

最容易记住的一种理解方式是：

- XAML：描述“界面长什么样”
- C++/WinRT：写“交互和业务逻辑”
- WinRT：定义底层对象模型和运行时能力
- Windows App SDK：提供统一开发和运行时平台
- WinUI 3：提供现代 Windows 的 UI 框架

它们配合起来，形成了现代 Windows 桌面程序的工程模型：

```text
XAML 负责界面
C++/WinRT 负责代码
WinRT 负责运行时对象模型
Windows App SDK 负责平台能力
WinUI 3 负责 UI 设计和控件体系
```

### 2.7 先理解这些概念，再学控件

很多人学 WinUI 3 时，一直停在 Button、TextBox、ComboBox、Image 这些控件层面，但这些都只是“表面语法”。真正重要的是：

- UI 是怎么声明出来的
- WinRT 对象是怎么暴露出来的
- 事件是怎么串起界面和业务逻辑的
- XAML 和代码是如何协作的

只有先理解了这些底层概念，后面的控件用法、绑定、导航、异步更新、命令、MVVM 才会真正有意义。

### 2.8 为什么从 .NET 又回到 C++？

这是很多初学者最容易困惑的地方。要知道，XAML 不是“只属于 .NET 的一个东西”，它本来就有多个分支路线，而且它和 Microsoft 的平台战略一起走过了不少变化。

#### 2.8.1 一开始，XAML 是和 .NET 强绑定的

在早期，XAML 的名气主要来自：

- WPF（Windows Presentation Foundation）
- Silverlight
- .NET Framework 的 UI 方案

这一套设计里，XAML 更像是“.NET 生态中的 UI 描述语言”：

- 设计器和界面描述都在 .NET 体系里
- 绑定、样式、资源、动画都与 CLR 结合较深
- 语法和工程模型也更偏应用框架思路

因此，很多人会形成一个印象：

> XAML = .NET 的 UI 标记，写 XAML 就应该是 .NET 项目。

这个印象在早期确实成立，但它只覆盖了一个时代。

#### 2.8.2 之后，Windows 平台开始要求更强的本机能力和更统一的应用模型

真正的问题不是“XAML 不好”，而是：

- Windows 需要更强的 native runtime 能力
- Win32 / COM / WinRT 体系继续是底层真实的系统能力
- .NET Framework 在可移植性、部署、UWP 生态、桌面开发体验上并不总是最适合的
- 用户需要的是“现代 Windows 应用”，而不是“某个单一框架自娱自乐”

于是微软开始推进：

- WinRT：更现代、更跨语言的 Windows 运行时对象模型
- UWP：统一应用模型
- Windows App SDK：把 platform capability 和 UI 能力统一起来
- WinUI：把 XAML 从 .NET 语境中抽离出来，重新变成依赖 Windows 平台能力的 UI 框架

#### 2.8.3 所以，回到 C++，不是“否定 .NET”，而是“把 XAML 放回到原生 Windows 平台中”

WinUI 3 在工程上更接近下面这种思路：

- XAML 仍然负责界面声明
- C++/WinRT 负责和 WinRT 交互
- Windows App SDK 提供统一平台能力
- 运行时对象不再完全依赖 CLR 运行时的那套思路

也就是说，C++ 不是反向退步，而是：

- 更贴近 Windows 本身的对象模型
- 更适合高性能、低延迟、原生 API 集成
- 更适合系统集成和桌面应用生态
- 能把 XAML 与 Windows 平台能力真正绑定起来

C# 仍然可以用，但它不再是唯一或默认的 XAML 入口；WinUI 3 的设计目标是让 XAML 成为一个更通用、更现代、更贴近平台的 UI 层，而不是只服务某个 .NET 运行时。

#### 2.8.4 听起来像“又退回到了原生 C++”，但本质上是重新统一了平台架构

一句话总结：

> XAML 并没有失败；它只是从“单一的 .NET UI 叙事”演化成了“Windows 平台的一部分”。

WinUI 3 不是在反对 XAML，而是在把 XAML 重新放回到 Windows 的运行时和应用模型中，用更适合现代 Windows 的方式实现它。

### 2.9 XAML 当年吹的牛为什么实现不了？

这个问题的答案，关键在于：它当时吹的很多内容，往往把“一个设计理念”和“一个能真正落地的统一平台”混在一起了。

#### 2.9.1 一开始的思路很美：一套 XAML，很多平台都能用

XAML 在一开始确实带来了很强的想象力：

- 一个界面语言描述 UI
- 设计器和开发者可以共享同一份结构
- 代码和界面可以分开
- WPF / Silverlight / 其他平台都能采用一致写法

这确实很诱人，因为它看起来像一种统一的界面层方案。

#### 2.9.2 但现实世界中，平台不是一张纸

真正限制它落地的，主要有几个因素：

1. Windows 平台本身并不是单一的 .NET 环境
   - Win32、COM、WinRT、传统桌面程序、系统组件，都是不同层面的事实

2. 不同应用模型竞争过于复杂
   - WPF 是桌面
   - Silverlight 是浏览器/轻应用方向
   - UWP 是新应用模型
   - Win32 仍然是大量系统和企业软件根基

3. .NET 运行时和平台要求并不完全一致
   - 设计很美，但部署、兼容性、平台能力、性能、版本管理等都非常复杂

4. 统一 UI 方案一定要和底层能力、资源管理、渲染模型、界面线程、应用生命周期一起设计
   - 仅仅有 XAML 不够
   - 还要有对应的运行时、组件模型、打包模型、样式和主题模型

因此，XAML 不是“实现不了”，而是“它不能在所有平台和应用模型下都成为单一真相”。

#### 2.9.3 实际上，它实现了，但不是以原来那种想象方式实现

今天的现实是：

- XAML 依然存在
- 但它不是“只属于 .NET 的 XAML”
- 它已经成为 Windows 平台中的 UI 描述语言之一
- WinUI 3 把它重新嵌入到 WinRT + Windows App SDK 体系中

也就是说，XAML 的故事并不是失败，而是发生了分层：

- 早期：XAML 作为 .NET UI 叙事
- 现在：XAML 作为 Windows 平台 UI 描述技术的一部分

这就是为什么你会看到：

- WPF 里有 XAML
- WinUI 3 里也有 XAML
- 但它们不再是同一个技术栈、同一层模型

### 2.10 一句话总结

如果要一句话总结这部分：

> XAML 从来没有消失，只是它不再是“ .NET 的唯一 UI 语言”；在 WinUI 3 中，它被重新放回到 Windows 的原生平台架构中，而 C++/WinRT 则成为它更现代、更贴合平台的运行时桥接方式。

理解了这一点，后面你就不会再觉得“WinUI 3 直接从 .NET 跳回 C++ 是反复横跳”，它其实是在做平台统一和工程合理化。

## 3. WinUI 3 的想法：你不能只会写控件

很多人学 WinUI 3 时容易停留在“知道 Button、TextBox、ComboBox 怎么写”，但这只是一层表面。

真正的 WinUI 3 开发重点在于：

- 界面是什么结构
- 状态如何管理
- 事件如何分发
- 谁负责业务逻辑
- 数据如何绑定到控件
- 异步任务如何更新 UI

理解这些之后，你才会真正写出像样的 WinUI 应用，而不是“控件拼接器”。

---

## 4. WinUI 3 的常见工程结构

一个成熟的 WinUI 3 C++/WinRT 应用通常包括：

```text
MyApp/
├── App.xaml
├── App.h
├── App.cpp
├── MainWindow.xaml
├── MainWindow.h
├── MainWindow.cpp
├── Models/
│   ├── TaskItem.h
│   └── TaskItem.cpp
├── ViewModels/
│   ├── MainViewModel.h
│   └── MainViewModel.cpp
├── Pages/
│   ├── HomePage.xaml
│   ├── SettingsPage.xaml
│   └── AboutPage.xaml
├── Resources/
│   └── Styles.xaml
└── Helpers/
    └── JsonConfig.h
```

工程组织中最核心的思想是：

- Models：数据对象
- ViewModels：界面状态与逻辑
- Pages：页面界面
- App：应用全局生命周期
- Resources：主题和样式

这也是现代 GUI 应用工程中最常见的思想。WinUI 3 很多时候不是单文件编程，而是“分层开发”。

---

## 5. 典型的 WinUI 3 程序流程

一个 WinUI 3 程序通常走这个流程：

```text
应用启动
  ↓
App 初始化
  ↓
MainWindow 创建
  ↓
页面或导航视图加载
  ↓
控件生成
  ↓
用户事件触发
  ↓
ViewModel 更新状态
  ↓
UI 通过绑定刷新
  ↓
异步任务或对话框更新状态
  ↓
应用退出
```

这里最重要的是：

- 用户从来不是直接操作“底层对象”
- 用户和界面交互，最终通过事件、命令和状态更新，驱动 UI
- 数据绑定是连接 UI 和状态的一种桥梁

---

## 6. XAML 与 C++/WinRT 的协作方式

WinUI 3 最关键的理解点：

- XAML 是界面声明层
- C++/WinRT 是代码逻辑层
- 事件、绑定和命令把二者串起来

### 6.1 一个最简单的界面

```xml
<StackPanel>
    <TextBlock Text="Hello WinUI 3" />
    <Button Content="Click me" Click="OnClick" />
</StackPanel>
```

```cpp
void MainWindow::OnClick(IInspectable const&, RoutedEventArgs const&)
{
    auto text = TextBlock().Text();
    StatusText().Text(L"Hello from C++/WinRT");
}
```

这段代码说明：

- XAML 负责界面布局和元素结构
- C++ 回调负责处理用户事件
- UI 状态通过控件属性更新

### 6.2 绑定和状态

更高级的写法是：

```xml
<TextBox Text="{x:Bind ViewModel.UserName, Mode=TwoWay}" />
<TextBlock Text="{x:Bind ViewModel.Message, Mode=OneWay}" />
```

```cpp
struct MainViewModel {
    winrt::hstring UserName{ L"Alice" };
    winrt::hstring Message{ L"Ready" };
};
```

这种方式让 UI 和数据状态相互关联。这里的核心思想是：

- UI 控件不依赖大量硬编码
- 状态变化可以反映到界面
- 业务逻辑更容易维护和测试

---

## 7. 事件、命令与状态管理

WinUI 3 中最重要的三件事是：

- 事件：用户做了什么
- 命令：什么动作该执行
- 状态：界面现在是什么情况

### 7.1 事件处理示例

```cpp
void MainPage::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
{
    auto text = InputBox().Text();
    ResultText().Text(L"Saved: " + text);
}
```

### 7.2 命令封装

```cpp
class RelayCommand {
public:
    explicit RelayCommand(std::function<void()> execute)
        : execute_(std::move(execute)) {}

    void Execute() const { if (execute_) execute_(); }

private:
    std::function<void()> execute_;
};
```

```cpp
struct TaskViewModel {
    std::string title;
    RelayCommand add_task_command;
};
```

这种写法让界面事件不再直接塞满业务逻辑，而是更像：

- 用户点击按钮
- 按钮调用命令
- 命令修改 ViewModel
- UI 反映状态变化

这是一种非常典型的现代 UI 架构思维。

---

## 8. 常见控件：实战教程

下面这些控件是 WinUI 3 的主力控件，掌握它们就已经能写出大部分桌面应用界面。

### 8.1 Button：动作触发器

Button 是最基础、最常用的 WinUI 3 控件之一。它的关键不是“能不能显示一个按钮”，而是：

- 用户点击后，触发什么动作
- 这个动作是直接写在代码里，还是走命令/VM
- 是否需要禁用、等待、错误反馈

最典型的写法是：XAML 里声明按钮，事件回调里处理逻辑。

```xml
<StackPanel Spacing="12">
    <TextBlock x:Name="StatusText" Text="Ready" />
    <Button x:Name="SaveButton" Content="Save" Click="OnSaveClicked" />
</StackPanel>
```

```cpp
void MainWindow::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
{
    StatusText().Text(L"Saved");
}
```

这是最基础的使用方式：

- `Content` 决定按钮显示文字
- `Click` 指定点击事件
- 代码里更新状态文本，说明 UI 已经响应事件

如果是更工程化的写法，通常不是直接在窗口代码里写业务逻辑，而是：

- 按钮点击 → 命令执行
- 命令修改 ViewModel
- UI 通过绑定刷新

例如：

```cpp
void MainViewModel::save()
{
    status_ = L"Saved";
}
```

不要只记住控件名，最重要的是：按钮是“用户动作入口”，它背后通常要连接一个状态更新或者命令。

示例源码：
- [09_button_control](G:/code/guide/WinUI3/cpp_examples/09_button_control/button_control.cpp)

### 8.2 TextBox：文本输入与校验

TextBox 是输入控件，最常见的工作流程是：

1. 用户输入内容
2. 读取 `Text` 属性
3. 进行校验
4. 根据结果更新状态或禁用按钮

```xml
<StackPanel Spacing="12">
    <TextBox x:Name="NameBox" Header="Name" PlaceholderText="请输入用户名" />
    <Button x:Name="SubmitButton" Content="Submit" IsEnabled="False" />
</StackPanel>
```

```cpp
void MainWindow::OnTextChanged(IInspectable const&, TextChangedEventArgs const&)
{
    auto value = NameBox().Text();
    bool isValid = value.Length() > 2;
    SubmitButton().IsEnabled(isValid);
}
```

这里你要掌握几个核心点：

- `Text` 是当前输入文本
- `TextChanged` 是最常见的事件
- `IsEnabled` 可以用来控制是否允许提交
- “校验逻辑”通常不是直接写在控件上，而是由 ViewModel 或页面逻辑负责

这类代码很容易写成“控件装配器”，但你应该这样思考：

- 输入框负责收集数据
- 页面/VM 负责判断是否合法
- UI 负责展示提示和状态

这才是工程正确姿势。

示例源码：
- [10_textbox_control](G:/code/guide/WinUI3/cpp_examples/10_textbox_control/textbox_control.cpp)

### 8.3 CheckBox 与 RadioButton：选择状态

这俩控件都属于“状态表达器”，意思是：

- 它们本身不负责业务计算
- 它们负责把用户选择的状态表现出来
- 业务逻辑再根据这个状态做分支判断

#### CheckBox

```xml
<CheckBox Content="Enable notifications" IsChecked="True" />
```

```cpp
if (NotifyBox().IsChecked().Value()) {
    // 开启通知逻辑
}
```

#### RadioButton

```xml
<StackPanel>
    <RadioButton Content="Light" GroupName="ThemeGroup" IsChecked="True" />
    <RadioButton Content="Dark" GroupName="ThemeGroup" />
    <RadioButton Content="System" GroupName="ThemeGroup" />
</StackPanel>
```

这里的关键是：

- `IsChecked` 表示当前状态
- `GroupName` 决定它们属于同一组单选
- `Checked` / `Unchecked` 事件可以用来反应状态变化

真正生产环境中，通常不是直接判断某个控件是否勾选，而是：

- 读取状态
- 将状态写入 ViewModel
- 根据状态改变对应配置

示例源码：
- [11_checkbox_radio_control](G:/code/guide/WinUI3/cpp_examples/11_checkbox_radio_control/checkbox_radio_control.cpp)

### 8.4 ComboBox：下拉选择

ComboBox 是“单选列表的输入控件”。和简单的 RadioButton 不同，它适合：

- 项目很多
- 需要节省界面空间
- 需要由数据集合动态生成选项

最典型的用法：

```xml
<ComboBox x:Name="ThemeComboBox" Header="Theme">
    <x:String>Light</x:String>
    <x:String>Dark</x:String>
    <x:String>System</x:String>
</ComboBox>
```

```cpp
void MainWindow::OnThemeChanged(IInspectable const&, SelectionChangedEventArgs const&)
{
    auto item = ThemeComboBox().SelectedItem().as<IPropertyValue>();
    // 根据 item 处理主题切换
}
```

更工程化的做法是：

```xml
<ComboBox ItemsSource="{x:Bind ViewModel.Items, Mode=OneWay}"
          SelectedItem="{x:Bind ViewModel.SelectedItem, Mode=TwoWay}" />
```

这里要注意：

- `ItemsSource` 负责提供数据源
- `SelectedItem` 负责记录当前选中项
- `SelectionChanged` 是事件入口，通常用来做响应逻辑

ComboBox 的本质是：

- 用户从列表里选一个值
- 程序把这个值映射成某个配置或状态

示例源码：
- [12_combobox_listview_control](G:/code/guide/WinUI3/cpp_examples/12_combobox_listview_control/combobox_listview_control.cpp)

### 8.5 ListView：数据集合展示

ListView 是 WinUI 3 中最关键的展示控件之一。它展示的不是单个值，而是“集合”。

它的典型结构是：

```xml
<ListView x:Name="TaskListView" ItemsSource="{x:Bind ViewModel.Tasks}">
    <ListView.ItemTemplate>
        <DataTemplate x:DataType="local:TaskItem">
            <TextBlock Text="{x:Bind Title}" />
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

```cpp
std::vector<TaskItem> tasks = {
    { L"Review design", false },
    { L"Write code", false },
    { L"Test build", true }
};
```

关键点：

- `ItemsSource` 是数据源
- `ItemTemplate` 定义每一项长什么样
- `SelectionChanged` 让你知道用户选中了哪一项
- ListView 适合任务列表、文件列表、通知列表、日志列表

它和 ComboBox 的差别在于：

- ComboBox 更适合“单选值”
- ListView 更适合“展示很多项并允许选择、浏览和编辑”

在工程中，ListView 一般和 ViewModel/集合一起使用，数据更新更稳定，UI 更容易维护。

示例源码：
- [12_combobox_listview_control](G:/code/guide/WinUI3/cpp_examples/12_combobox_listview_control/combobox_listview_control.cpp)

### 8.6 ToggleSwitch / Slider：状态和数值反馈

这两类控件不是用于“做复杂业务逻辑”，而是“表达状态”和“接受数值输入”。

#### ToggleSwitch

```xml
<ToggleSwitch Header="Notifications" IsOn="True" />
```

```cpp
bool enabled = NotificationsSwitch().IsOn();
```

它适合：

- 开关控制
- 实时开关状态
- 功能启用/禁用

#### Slider

```xml
<Slider Minimum="0" Maximum="100" Value="50" />
```

```cpp
double value = VolumeSlider().Value();
```

它适合：

- 音量
- 亮度
- 质量设置
- 进度控制

这类控件非常适合“模型驱动 UI”：状态在 ViewModel 里，控件只是展示并采集输入。

示例源码：
- [13_slider_toggle_control](G:/code/guide/WinUI3/cpp_examples/13_slider_toggle_control/slider_toggle_control.cpp)

### 8.7 ContentDialog：临时交互窗口

ContentDialog 不是页面本身，而是“临时弹窗”。它适合：

- 确认删除
- 保存修改
- 输入一些必须确认的信息
- 显示一次性提示

```cpp
ContentDialog dialog;
dialog.Title(L"Delete item");
dialog.Content(L"Do you want to delete this task?");
dialog.PrimaryButtonText(L"Delete");
dialog.SecondaryButtonText(L"Cancel");

auto result = dialog.ShowAsync();
```

你要特别注意：

- 这是“临时交互”，不是整个页面
- 适合单次确认，而不是复杂流程
- 只是把用户决策收集到代码中，然后由页面逻辑处理结果

示例源码：
- [14_dialog_navigation_control](G:/code/guide/WinUI3/cpp_examples/14_dialog_navigation_control/dialog_navigation_control.cpp)

### 8.8 NavigationView：页面导航

NavigationView 让应用从“单页界面”升级成“多页面应用”。它并不是给某个小按钮用的，而是：

- 左菜单 / 侧边栏导航
- 切换设置页、主页、分析页
- 形成完整的应用结构

典型思路：

```xml
<NavigationView x:Name="RootNav" SelectionChanged="OnSelectionChanged">
    <NavigationView.MenuItems>
        <NavigationViewItem Content="Home" Tag="Home" />
        <NavigationViewItem Content="Tasks" Tag="Tasks" />
        <NavigationViewItem Content="Settings" Tag="Settings" />
    </NavigationView.MenuItems>
</NavigationView>
```

```cpp
void MainWindow::OnSelectionChanged(IInspectable const&, NavigationViewSelectionChangedEventArgs const& args)
{
    auto selected = args.SelectedItemContainer().Tag();
    // 根据 Tag 切换页面内容
}
```

这里最关键的是：

- 导航控件只是“入口”
- 页面本身还是靠 `Frame`、页面对象或自定义状态切换来实现
- App 架构中，导航不是万能的，关键还是页面状态和 ViewModel 分层

这类控件本质上代表“应用结构”，不是单纯的 UI 装饰。

示例源码：
- [14_dialog_navigation_control](G:/code/guide/WinUI3/cpp_examples/14_dialog_navigation_control/dialog_navigation_control.cpp)

---

### 8.9 你真正需要知道的不是“控件表”，而是“控件使用模式”

最容易学偏的地方，是把控件当成孤立部件，而不是应用状态的一部分。正确的学习路径应该是：

- 先看控件有什么用途
- 再看它的最核心属性和事件
- 再看它如何联动 ViewModel
- 最后看一个真实页面怎么把它组织起来

也就是说：

- Button = 触发动作
- TextBox = 收集输入
- CheckBox / RadioButton = 表达选择
- ComboBox = 选择枚举值
- ListView = 展示集合
- ToggleSwitch / Slider = 表达状态和数值
- ContentDialog = 临时确认交互
- NavigationView = 页面切换入口

一旦你把这个“使用模式”理解清楚，后面再学更复杂的控件和架构，就不会再是死记控件名了。

---

## 9. XAML 布局基础：Grid / StackPanel / Border / RelativePanel

布局不是“把控件摆到页面上”这么简单。真正要理解的是：

- 页面中有哪些区域
- 这些区域分别怎么扩展和收缩
- 哪些控件需要靠左、靠右、上下排列
- 某个界面是列表型、表单型，还是工具栏型

如果布局写错，界面会很难维护，后面再加功能时也会非常痛苦。

### 9.1 先看布局的目的

在 WinUI 3 中，最常见的布局思路是：

- `StackPanel`：顺序排布，适合单列或单行简单界面
- `Grid`：最常用，适合表单、列表、工具栏、主内容区的组合布局
- `Border`：给区域加边框、背景、间距或容器限制
- `RelativePanel`：适合一些相对位置依赖的布局
- `ScrollViewer`：内容超长时提供滚动

也就是说：

- 只需要垂直堆几个控件，用 `StackPanel`
- 感觉像“表格”、需要分栏和分区，用 `Grid`
- 想给一块区域加边框或容器背景，用 `Border`
- 要做相对位置关系，用 `RelativePanel`

### 9.2 StackPanel：最适合顺序排列

适合：

- 登录框
- 表单字段
- 工具栏按钮组
- 一个列表头和几个按钮的串行排列

示例：

```xml
<StackPanel Orientation="Vertical" Spacing="12">
    <TextBlock Text="Create task" FontSize="24" />
    <TextBox Header="Title" PlaceholderText="Enter task name" />
    <TextBox Header="Description" PlaceholderText="Optional notes" />
    <Button Content="Add task" HorizontalAlignment="Right" />
</StackPanel>
```

这里的关键是：

- 它会按顺序一行一行排下来
- `Spacing` 控制每个子元素之间的距离
- `HorizontalAlignment` 控制按钮是否靠右

如果你只是要“一个表单从上到下排起来”，`StackPanel` 是最直接的选择。

### 9.3 Grid：真正的主力布局

`Grid` 是 WinUI 3 里最常用、最核心的布局容器。它就像一个二维表格：

- 有行 `RowDefinition`
- 有列 `ColumnDefinition`
- 每个元素通过 `Grid.Row` / `Grid.Column` 放到指定位置

#### 9.3.1 一个常见的任务列表布局

```xml
<Grid ColumnSpacing="12" RowSpacing="12">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto" />
        <RowDefinition Height="*" />
    </Grid.RowDefinitions>

    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*" />
        <ColumnDefinition Width="220" />
    </Grid.ColumnDefinitions>

    <TextBox Grid.Row="0" Grid.Column="0" Header="New task" PlaceholderText="Add a new task" />
    <Button Grid.Row="0" Grid.Column="1" Content="Add" VerticalAlignment="Bottom" />

    <ListView Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" />
</Grid>
```

这个界面说明了一个真实布局思路：

- 第一行：输入框 + 添加按钮
- 第二行：列表占满剩余空间
- `Grid.ColumnSpan="2"` 让列表横跨两列

这个布局很像一个任务管理器主界面。

#### 9.3.2 Grid 的真实价值

很多人看到 `Grid` 就觉得“很复杂”，其实它本身并不难，难的是你要知道什么时候该用它。

它最适合下面这些场景：

- 主页面布局：顶部工具栏 + 左侧菜单 + 右侧内容区
- 表单布局：字段排列在 2 列/3 列中
- 数据列表 + 按钮工具栏组合
- 复杂页面中需要精确控制区域

如果页面结构变复杂，`Grid` 往往是最稳定、最可维护的选择。

### 9.4 Border：给一块区域加容器和边框

`Border` 不是“布局器”的核心作用，它更像一个“容器包裹层”。常见用途：

- 给某一块内容加边框
- 给一段区域加背景色
- 对内部内容做统一间距和外观控制

示例：

```xml
<Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
        CornerRadius="8"
        Padding="12"
        BorderThickness="1"
        BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">
    <StackPanel Spacing="8">
        <TextBlock Text="Quick actions" FontWeight="SemiBold" />
        <Button Content="Open" />
        <Button Content="Save" />
    </StackPanel>
</Border>
```

它的关键作用是：

- 让一块区域看起来像一个卡片
- 让界面层次更清晰
- 不必把所有样式都散落到每个控件上

很多真实应用里，页面就是由多个 `Border` 包裹的区域拼起来的。

### 9.5 RelativePanel：适合依赖位置的界面

`RelativePanel` 适合：

- 一个控件在左边，一个在右边
- 一个控件在上方，另一个在下方
- 某个按钮需要相对标题或图标定位

例如：

```xml
<RelativePanel Width="400" Height="120">
    <TextBlock x:Name="TitleText" Text="Settings" FontSize="32" />
    <Button Content="Save" RelativePanel.RightOf="TitleText" RelativePanel.AlignBottomWith="TitleText" />
</RelativePanel>
```

它的意义是：

- 不强调表格，而强调“相对位置关系”
- 适合较小区域的微布局
- 但一旦页面复杂，通常还是 `Grid` 更可靠

### 9.6 ScrollViewer：内容太多时的布局节点

页面中经常会出现内容超出可视区域的情况，比如：

- 设置项很多
- 长列表
- 多行日志
- 表单很长

这时就需要 `ScrollViewer`：

```xml
<ScrollViewer>
    <StackPanel Spacing="12">
        <TextBox Header="Name" />
        <TextBox Header="Email" />
        <TextBox Header="Address" />
        <Button Content="Submit" />
    </StackPanel>
</ScrollViewer>
```

它解决的不是“布局复杂”，而是：“内容太多，窗口不够大，需要滚动展示”。

### 9.7 一段真实的页面布局：任务管理主界面

这才是最有用的理解方式。看下面一个页面结构：

```xml
<Grid>
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="220" />
        <ColumnDefinition Width="*" />
    </Grid.ColumnDefinitions>

    <Border Grid.Column="0" Background="LightGray" Padding="12">
        <StackPanel Spacing="8">
            <TextBlock Text="Menu" FontSize="20" />
            <Button Content="Tasks" />
            <Button Content="Calendar" />
            <Button Content="Settings" />
        </StackPanel>
    </Border>

    <Grid Grid.Column="1" Padding="12" RowSpacing="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
        </Grid.RowDefinitions>

        <Grid ColumnSpacing="12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="120" />
            </Grid.ColumnDefinitions>

            <TextBox Grid.Column="0" Header="Add task" PlaceholderText="What do you want to do?" />
            <Button Grid.Column="1" Content="Add" VerticalAlignment="Bottom" />
        </Grid>

        <ListView Grid.Row="1" />
    </Grid>
</Grid>
```

这段代码的意义不是“它很炫”，而是：

- 左边是菜单区域，右边是主内容
- 输入区和按钮在同一行
- 列表区占据剩余空间
- `Grid` 控制了主要结构
- `Border` 把菜单区包起来

这才是你在真实应用里真正需要的布局能力。

### 9.8 你要记住的不是容器名，而是布局思想

最重要的不是背 `Grid` / `StackPanel` / `Border` 的定义，而是培养这种判断：

- 这是一个垂直表单，用 `StackPanel`
- 这是一个主页面结构，用 `Grid`
- 这是一个带边框的区域，用 `Border`
- 这是一个相对位置布局，用 `RelativePanel`
- 这是长内容，需要滚动，用 `ScrollViewer`

一旦你掌握了这种思路，后面写 WinUI 3 页面就不再是“代码堆积”，而是“布局设计”。

---

---

## 10. 数据绑定和 ViewModel：真正的工程思路

这一节是很多人真正卡住的地方：

- 你知道控件怎么写
- 你知道页面怎么排版
- 但你不知道“为什么 UI 会跟着数据变化”

这个关键点，就是数据绑定和 ViewModel。

### 10.1 先说最核心的概念：绑定的目的

绑定的本质不是“让一个字段看起来自动更新”，而是：

- 视图层（UI）和数据层解耦
- 界面不需要自己手动去改一堆控件状态
- 数据变化后，UI 自动反映
- 用户操作后，状态更新后，界面自动刷新

如果没有绑定：

- 每次状态变化都得显式改控件属性
- 代码会散落到很多事件里
- 业务状态和 UI 状态混在一起

这就会导致程序很快变脏、难维护。

### 10.2 什么是 ViewModel

ViewModel（视图模型）是“给页面看的数据和状态容器”。

它通常负责：

- 持有页面状态
- 计算当前显示内容
- 连接用户动作和业务逻辑
- 在数据变化后通知 UI 更新

例如：

```cpp
struct TaskItem {
    std::string title;
    bool is_done = false;
};

class TaskViewModel {
public:
    void AddTask(std::string title)
    {
        if (!title.empty()) {
            tasks_.push_back(TaskItem{std::move(title), false});
        }
    }

    const std::vector<TaskItem>& tasks() const
    {
        return tasks_;
    }

    std::size_t completed_count() const
    {
        std::size_t count = 0;
        for (const auto& task : tasks_) {
            if (task.is_done) {
                ++count;
            }
        }
        return count;
    }

private:
    std::vector<TaskItem> tasks_;
};
```

这说明：

- `TaskItem` 是数据模型，只描述任务本身
- `TaskViewModel` 是页面状态的核心，负责管理任务列表和计算状态
- UI 不直接管理任务数据，而是绑定到这个 ViewModel

### 10.3 绑定到底绑定什么

在 WinUI 3 中，最常见的绑定对象是：

- 一个字符串：显示当前状态文本
- 一个集合：显示任务列表
- 一个布尔值：决定按钮是否启用
- 一个选中项：显示当前选中任务

比如：

```cpp
class MainViewModel {
public:
    void SetMessage(std::wstring msg)
    {
        message_ = std::move(msg);
    }

    const std::wstring& message() const
    {
        return message_;
    }

private:
    std::wstring message_ = L"Ready";
};
```

`TextBlock` 可以绑定到这个 `message`：

```xml
<TextBlock Text="{x:Bind ViewModel.Message, Mode=OneWay}" />
```

这里的关键是：

- `ViewModel.Message` 变了
- UI 自动跟着变
- 你不需要手动写 `TextBlock.Text = ...` 一大堆代码

这就是绑定的价值。

### 10.4 为什么需要区分 Model / ViewModel

很多人会把数据和界面状态混在一起，这是错误的。真正的工程思路是：

- Model：数据对象本身
- ViewModel：为页面准备的数据、状态和动作

例如：

```cpp
struct TaskItem {
    std::string title;
    bool done;
};
```

这是“任务对象”，它只是描述一个任务。

但页面不仅要显示任务，还要知道：

- 当前输入框里写了什么
- 当前是否正在加载
- 当前筛选条件是什么
- 当前已完成多少个
- 当前是否允许提交

这些状态都不是 `TaskItem` 自己拥有的，而是 `ViewModel` 负责。

因此：

- `Model` 负责“数据是什么”
- `ViewModel` 负责“页面要怎么用这些数据”

### 10.5 一个实际的数据流：从输入到列表更新

这是最重要的工程例子：

```text
用户在 TextBox 输入："写 WinUI 教程"
    ↓
点击 Add 按钮
    ↓
按钮事件触发
    ↓
ViewModel.AddTask("写 WinUI 教程")
    ↓
任务加入 tasks_ 集合
    ↓
绑定到 ListView 的集合变了
    ↓
ListView 自动刷新显示新任务
```

这说明：

- 不是控件自己维护数据
- 不是按钮直接操纵列表
- 而是 ViewModel 作为中间层

这就是典型的 WinUI 3 工程结构，是真正“从零到工程”的核心。

### 10.6 一个最典型的误区：把所有状态写在控件里

下面这种写法是典型问题：

```cpp
void MainPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
{
    auto title = TaskTextBox().Text();
    if (!title.empty()) {
        TaskList().Items().Append(title);
    }
}
```

这虽然能跑，但问题在于：

- 状态分散在控件里
- 列表和输入逻辑耦合严重
- 页面越来越大，功能越来越多就很难维护
- 没有统一“数据源”

更合理的方式是：

- 控件负责展示和输入
- ViewModel 负责任务集合
- 页面只负责连接命令和绑定

### 10.7 命令：把用户动作和 ViewModel 连接起来

数据绑定解决的是“数据怎么显示”，命令解决的是“用户怎么触发行为”。

典型思路：

```cpp
class RelayCommand {
public:
    explicit RelayCommand(std::function<void()> execute)
        : execute_(std::move(execute)) {}

    void Execute() const
    {
        if (execute_) {
            execute_();
        }
    }

private:
    std::function<void()> execute_;
};
```

```cpp
TaskViewModel vm;
vm.set_add_command(RelayCommand([&]() {
    vm.AddTask("New task");
}));
```

这里的关键：

- Button 点击不直接改 UI
- 命令去调用 ViewModel 的方法
- ViewModel 改数据
- UI 通过绑定刷新

这才是现代 UI 的工程化做法。

### 10.8 绑定和 ViewModel 一起解决什么问题

总结一句话：

> 绑定让界面自动跟随数据变化，ViewModel 让数据和状态保持统一，而命令把用户动作连接到状态更新。

这三者合在一起，就是现代 WinUI 3 工程的核心。

如果没有它们，WinUI 3 程序很容易变成：

- 事件多到爆炸
- 状态散落在控件之间
- 界面逻辑和业务逻辑混在一起
- 修改一个功能要改很多地方

### 10.9 真正要学的是“数据流”，不是“写一个 x:Bind 例子”

很多教程把绑定讲成：

- `Text="{x:Bind ViewModel.Name}"`
- `ItemsSource="{x:Bind ViewModel.Tasks}"`

这很表面。真正要理解的是：

- 数据在哪里
- 页面怎么跟随数据变化
- 命令怎么改变数据
- 视图怎么自动刷新

这才是工程思维。

---

---

## 11. 异步任务：后台工作和 UI 更新

异步是 WinUI 3 中非常关键的一环，因为桌面应用的 UI 线程不能被长时间阻塞。否则用户一点击按钮，窗口就会卡住，界面看起来像“假死”。

这里要先讲清一个真正的原则：

- 耗时工作要放后台
- UI 更新一定要在 UI 线程上做
- 不能在后台线程直接改界面控件

### 11.1 为什么异步是必需的

很多应用看似简单：

- 读文件
- 下载内容
- 加载列表
- 访问网络
- 扫描目录

但这些操作都可能慢。如果直接在 UI 线程里做，程序会出现：

- 按钮点击后界面无响应
- 窗口无法重绘
- 用户以为程序崩了
- 进度条不会更新

所以异步的核心不是“让代码写起来更高级”，而是：

- 让界面保持响应
- 把耗时任务和 UI 更新分开

### 11.2 典型模式：后台执行，前台更新

WinUI 3 / C++/WinRT 中最常见的写法是：

```cpp
IAsyncAction LoadAsync()
{
    co_await winrt::resume_background();

    // 1. 后台执行：读取文件、访问网络、计算大数据等
    // 这里不能直接操作 UI 控件

    co_await winrt::resume_foreground(Dispatcher());

    // 2. 前台执行：更新 TextBlock、ListView、按钮状态等
    StatusText().Text(L"Load complete");
}
```

这段代码说明了真正的异步思路：

1. `resume_background()`：切到后台线程，做耗时工作
2. `resume_foreground(Dispatcher())`：切回 UI 线程，更新界面
3. 不能把后台线程操作直接写到 UI 控件上

这是 WinUI 3 最核心的异步工作方式之一。

### 11.3 一个更直观的例子：加载任务列表

```cpp
IAsyncAction LoadTasksAsync()
{
    co_await winrt::resume_background();

    std::vector<TaskItem> items = {
        {L"Download update", false},
        {L"Analyze logs", false},
        {L"Sync data", true}
    };

    co_await winrt::resume_foreground(Dispatcher());

    TaskList().ItemsSource(items);
    StatusText().Text(L"Loaded 3 tasks");
}
```

这里的关键点是：

- 先在后台计算/准备数据
- 再切回 UI 线程更新 `ListView` 和状态文本

如果你在后台线程直接写：

```cpp
TaskList().ItemsSource(items);
```

那就不对了，因为 `TaskList` 属于 UI 对象，应该只在前台线程更新。

### 11.4 当异步出现问题时，通常是这几类错误

最常见的错误有：

1. 在后台线程访问 UI 控件
2. UI 更新和后台计算混在同一个函数里
3. 没有区分长时间任务和界面刷新时机
4. 任务完成后忘记回到 UI 线程
5. 异步操作重入导致状态竞争

例如：

```cpp
// 错误：后台线程更新 UI
co_await winrt::resume_background();
StatusText().Text(L"done");
```

这会导致线程访问错误和 UI 异常。

### 11.5 一个更现实的开发模式：开始 / 结束 / 错误状态

真实异步界面一般会包含：

- 开始加载：禁用按钮、显示 Loading
- 后台执行：执行任务
- 完成：更新列表和状态
- 错误：显示异常提示

示例：

```cpp
IAsyncAction RefreshAsync()
{
    LoadingText().Text(L"Loading...");
    SaveButton().IsEnabled(false);

    co_await winrt::resume_background();
    // 模拟网络/文件操作
    auto result = 42;

    co_await winrt::resume_foreground(Dispatcher());
    LoadingText().Text(L"Finished");
    SaveButton().IsEnabled(true);
}
```

这类模式非常常见：

- 请求开始时，UI 进入加载态
- 业务任务后台执行
- 完成时切回 UI 线程更新状态

### 11.6 什么时候该使用异步

典型场景：

- 下载文件
- 读取配置
- 网络请求
- 加载大集合
- 扫描目录
- 处理大文件
- 访问数据库或后台服务

如果一个操作可能卡住几百毫秒到几秒钟，就应该考虑异步。若直接塞进 UI 线程，最终用户体验会很差。

### 11.7 记住一句话：异步不是为了炫技，而是为了保证 UI 和业务逻辑分开

真正的核心思想是：

- UI 线程负责界面响应
- 后台线程负责耗时任务
- UI 线程更新状态和控件

如果你能把这个思路记住，后面不论是网络请求、文件 IO，还是复杂列表加载，都不会再搞混。

---

---

## 12. 真实 WinUI 3 页面工程结构：从页面到应用

很多人学 WinUI 3，最后的困难不是“控件怎么用了”，而是“一个真实页面怎么组织”。

真正的应用通常不是一个页面里塞满所有代码，而是要分成清晰的层：

- App：应用入口和全局状态
- Window：主窗口
- Page：页面内容和布局
- ViewModel：界面状态、命令和数据处理
- Model：数据对象
- Services：网络、文件、配置、存储等依赖

如果没有这种结构，界面很快就会变成一堆事件处理函数和控件状态散落在一起，最后根本无法维护。

### 12.1 一个真实 WinUI 3 页面，不是“控件拼装机”

一个典型的任务管理页面，逻辑可以分成这么几层：

1. 用户在页面中输入新任务名
2. 点击“Add”按钮
3. 按钮触发命令
4. ViewModel 把任务加入列表
5. `ListView` 自动刷新显示
6. 需要时异步更新存储或网络数据

这不是“控件直接互相操作”的思路，而是：

- `TextBox` 负责输入
- `Button` 负责触发动作
- `ViewModel` 负责维护状态
- `ListView` 负责展示集合
- `Services` 负责数据持久化或远程访问

也就是说，页面与业务逻辑之间是分层的，而不是混在一起。

### 12.2 一个真实页面的工程结构示意

```text
MyApp/
├── App.xaml
├── App.h
├── App.cpp
├── MainWindow.xaml
├── MainWindow.h
├── MainWindow.cpp
├── Models/
│   └── TaskItem.h
├── ViewModels/
│   └── MainViewModel.h
├── Pages/
│   ├── TaskPage.xaml
│   ├── SettingsPage.xaml
│   └── HomePage.xaml
├── Services/
│   └── TaskService.h
├── Resources/
│   └── Styles.xaml
└── Helpers/
    └── FileHelper.h
```

这个结构的意义在于：

- `App` 管理应用生命周期和全局配置
- `MainWindow` 承担窗口和导航容器
- `Page` 负责界面布局，也就是 XAML 让我们看见的页面
- `ViewModel` 负责界面状态和用户动作
- `Model` 负责业务对象
- `Services` 负责真正的 IO、网络、存储等能力

如果你把一切都塞进 `MainWindow.cpp`，很快就会出现：

- 一个函数里有 200 行逻辑
- 一个按钮事件处理器里同时写校验、网络请求、状态更新
- 一个页面中的所有状态都散落在控件属性中
- 排查问题要从几十个控件和事件里翻代码

这就是工程结构的价值。

### 12.3 一个真实页面的状态流

让我们看一个“任务列表页面”的状态流：

```text
用户输入任务标题
    ↓
TextBox 收集文本
    ↓
Add 按钮点击
    ↓
Command/事件触发
    ↓
ViewModel 在任务集合中添加一个 TaskItem
    ↓
ListView 绑定到任务集合
    ↓
UI 自动刷新，显示新增任务
```

注意这里的关键：

- 用户不直接改 `ListView`
- 用户不直接改数据集合
- 用户通过事件和命令驱动 ViewModel
- ViewModel 更新数据
- UI 通过绑定自动刷新

这就是“页面工程结构”的核心。

### 12.4 一个真实页面的代码思路

下面是一种非常典型的结构：

```cpp
struct TaskItem {
    std::string title;
    bool done = false;
};

class TaskViewModel {
public:
    void AddTask(std::string title)
    {
        if (!title.empty()) {
            tasks_.push_back(TaskItem{std::move(title), false});
        }
    }

    const std::vector<TaskItem>& tasks() const { return tasks_; }

private:
    std::vector<TaskItem> tasks_;
};
```

然后页面中：

```cpp
void MainPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
{
    auto title = TaskInput().Text();
    view_model_.AddTask(to_string(title));
    TaskList().ItemsSource(view_model_.tasks());
}
```

这段代码虽然仍然比较简化，但已经体现了工程结构：

- `TaskItem` 是数据模型
- `TaskViewModel` 负责管理列表
- 页面只是收集输入并连接逻辑

真正成熟的项目里，页面、ViewModel、Model 会进一步分离。比如：

- `Model` 只描述数据对象
- `ViewModel` 管理状态和命令
- `Page` 只负责布局和绑定
- `Service` 负责真实 IO

### 12.5 一个页面层和业务层如何分离

最常见的错误是：

- 页面代码里直接读取文件
- 页面代码里直接请求网络
- 页面代码里直接改数据结构
- 页面代码里直接处理所有状态

这会导致页面代码极难维护。正确分层是：

- Page：界面和布局，描述“界面长什么样”
- ViewModel：界面状态和动作逻辑，描述“界面当前是什么状态”
- Service：真正实现文件、网络、数据库等操作

例如：

- Page 负责显示：`TextBox`、`ListView`、`Button`
- ViewModel 负责：新增任务、删除任务、过滤任务、状态计算
- Service 负责：保存到文件、查询数据库、访问网络

### 12.6 真实项目中的页面生命周期

一个页面通常有这样的生命周期：

```text
页面创建
  ↓
初始化 ViewModel
  ↓
绑定数据源
  ↓
用户交互
  ↓
事件触发
  ↓
ViewModel 处理状态
  ↓
UI 自动更新
  ↓
页面关闭 / 卸载
```

这说明页面并不是“显示控件”的静态体，而是：

- 负责UI承载
- 连接数据和用户动作
- 管理生命周期
- 让状态变化可观察并更新到界面

### 12.7 为什么这个结构很重要

在 WinUI 3 中，如果没有这种结构，程序会非常快变成“代码难看、调试困难、状态混乱”的状态。比如：

- 数据和 UI 混在一起
- 一处更改需要到多个地方同步
- 事件处理器越来越长
- 新增功能时要改很多控件名和逻辑

而分层结构可以解决这些问题：

- 逻辑清晰
- 状态集中
- 数据流更直观
- 页面更容易扩展

### 12.8 一个更接近真实应用的理解方式

你可以把 WinUI 3 页面理解为：

- 不是“一个代码文件里塞进所有东西”
- 而是“一个页面 + 一个模型 + 一组状态 + 一些命令”

它的核心就是：

- 页面负责展示
- ViewModel 负责状态和动作
- Model 负责数据
- Service 负责工作

一旦你真的按这个结构组织项目，后续做导航、异步、数据库、设置页、任务管理器等都不会变成“无序拼接”。

---

## 13. 资源与主题：Fluent Design

WinUI 3 的主题系统非常重要，常用机制：

- 资源字典：统一颜色和风格
- 主题切换：浅色 / 深色 / 跟随系统
- 样式复用：通用按钮样式、标题样式
- 资源访问：`Application::Current().Resources()`

典型思路：

- 统一颜色和字体
- 让不同页面保持一致视觉风格
- 方便切换深浅主题

示例源码：
- [05_resource_dictionary](G:/code/guide/WinUI3/cpp_examples/05_resource_dictionary/resource_dictionary.cpp)

---

## 13. 一个完整的 WinUI 3 案例：任务管理器

下面给出一个更贴近真实项目的结构思路。它不是一个完整 XAML 工程，而是展示如何从工程组织到状态流转、命令和界面更新的思路。

```cpp
#include <functional>
#include <iostream>
#include <string>
#include <vector>

struct TaskItem {
    std::string title;
    bool done = false;
};

class RelayCommand {
public:
    explicit RelayCommand(std::function<void()> execute)
        : execute_(std::move(execute)) {}

    void Execute() const {
        if (execute_) execute_();
    }

private:
    std::function<void()> execute_;
};

class TaskViewModel {
public:
    TaskViewModel()
        : add_command_([this]() { add_task(); })
    {
        tasks_ = {
            {"Plan WinUI app", false},
            {"Design page layout", false},
            {"Review data binding", true}
        };
    }

    void set_new_title(std::string title)
    {
        new_title_ = std::move(title);
    }

    const RelayCommand& add_command() const
    {
        return add_command_;
    }

    const std::vector<TaskItem>& tasks() const
    {
        return tasks_;
    }

private:
    void add_task()
    {
        if (!new_title_.empty()) {
            tasks_.push_back(TaskItem{new_title_, false});
            new_title_.clear();
        }
    }

    std::vector<TaskItem> tasks_;
    std::string new_title_;
    RelayCommand add_command_;
};
```

这一段代码的意义是：

- TaskItem 是数据模型
- TaskViewModel 负责管理任务列表
- RelayCommand 负责把按钮点击转换为业务动作
- 状态和行为是分离的

这是 WinUI 3 真正的工程思维：

- UI 控件负责显示
- ViewModel 负责数据和行为
- 命令连接事件与动作

一个真实的 WinUI 应用很大程度上就是由这样的对象组合而成的。

示例源码：
- [15_complete_task_app](G:/code/guide/WinUI3/cpp_examples/15_complete_task_app/task_app.cpp)

---

## 14. 典型的常见错误

学习 WinUI 3 时，最容易出问题的地方是：

1. 把所有逻辑写进事件处理器里
2. 不做 ViewModel，导致状态散落在多个控件中
3. 程序里直接写死数据，没有抽象数据模型
4. 没有区分后台任务和 UI 线程
5. 过度依赖控件内部状态，而不维护统一的数据源

这些问题会让一个 WinUI 3 应用很快变得无法维护。

---

## 15. 适合学习的顺序

建议按下面顺序逐步学习：

1. App / Window / Page 基础结构
2. Button / TextBox / CheckBox / RadioButton
3. ComboBox / ListView / ToggleSwitch / Slider
4. NavigationView / ContentDialog
5. ViewModel / 命令 / 数据绑定
6. 异步更新与后台任务
7. 资源与主题
8. 一个真实功能型应用：任务管理器 / 设置页 / 日志页

这个顺序和真实项目开发越来越接近，不会只停留在“知道控件属性”。

---

## 16. 编译验证

在 [WinUI3/](G:/code/guide/WinUI3/) 执行：

```powershell
.\build.ps1
```

清理输出：

```powershell
.\build.ps1 -Clean
```

当前目录中的示例代码都使用 C++ 形式组织，重点是传达正确的 WinUI 3 结构、控件用法、状态管理和工程思想，并保持可编译验证。

---

## 17. 示例索引

基础篇：
- [01_hello_event](G:/code/guide/WinUI3/cpp_examples/01_hello_event/hello_event.cpp)
- [02_mvvm_command](G:/code/guide/WinUI3/cpp_examples/02_mvvm_command/mvvm_command.cpp)
- [03_navigation_state](G:/code/guide/WinUI3/cpp_examples/03_navigation_state/navigation_state.cpp)
- [04_async_dispatch](G:/code/guide/WinUI3/cpp_examples/04_async_dispatch/async_dispatch.cpp)
- [05_resource_dictionary](G:/code/guide/WinUI3/cpp_examples/05_resource_dictionary/resource_dictionary.cpp)
- [06_collection_binding](G:/code/guide/WinUI3/cpp_examples/06_collection_binding/collection_binding.cpp)
- [07_dependency_injection](G:/code/guide/WinUI3/cpp_examples/07_dependency_injection/dependency_injection.cpp)
- [08_lifecycle_events](G:/code/guide/WinUI3/cpp_examples/08_lifecycle_events/lifecycle_events.cpp)

控件篇：
- [09_button_control](G:/code/guide/WinUI3/cpp_examples/09_button_control/button_control.cpp)
- [10_textbox_control](G:/code/guide/WinUI3/cpp_examples/10_textbox_control/textbox_control.cpp)
- [11_checkbox_radio_control](G:/code/guide/WinUI3/cpp_examples/11_checkbox_radio_control/checkbox_radio_control.cpp)
- [12_combobox_listview_control](G:/code/guide/WinUI3/cpp_examples/12_combobox_listview_control/combobox_listview_control.cpp)
- [13_slider_toggle_control](G:/code/guide/WinUI3/cpp_examples/13_slider_toggle_control/slider_toggle_control.cpp)
- [14_dialog_navigation_control](G:/code/guide/WinUI3/cpp_examples/14_dialog_navigation_control/dialog_navigation_control.cpp)
- [15_complete_task_app](G:/code/guide/WinUI3/cpp_examples/15_complete_task_app/task_app.cpp)

---

## 18. 后续扩展建议

本教程后续可以继续扩展为更高级的内容：

- 实战版任务管理器（增删改查）
- 设置页 + 多页导航 + 深色主题
- 数据持久化与 JSON 配置
- 网络请求 + 异步加载列表
- 自定义控件和样式资源
- DataGrid / 复杂表格界面
- WinUI 3 与 WinRT API 的综合应用

这部分内容可以进一步把教程推进到真正的生产级应用开发。

