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

它的典型特点是：

- 使用 XAML 声明界面结构和布局
- 使用 C++/WinRT、C# 或其他语言连接业务逻辑
- 更适合 Fluent Design 风格和现代桌面程序
- 更适合 Windows 11 及后续版本的桌面开发生态

它的核心不是“控件本身”，而是“如何组织一个现代 GUI 应用”：

- 页面是什么结构
- 数据怎么流动
- 事件怎么触发
- 状态怎么管理
- 业务逻辑怎么和 UI 分层

也就是说，WinUI 3 更像一套“桌面应用开发模型”，不只是控件列表。

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

WinRT（Windows Runtime）是 Windows 的一套运行时对象模型。它的重点不是“一个控件库”，而是：

- 定义对象、接口、方法、属性如何在系统中暴露
- 让不同编程语言都能访问 Windows 平台能力
- 提供统一的对象模型和 ABI 兼容性

简单来说，WinRT 是 Windows 平台提供给应用程序的“对象运行时接口层”。

它的特点是：

- 面向对象且跨语言
- 不依赖单一语言
- 可以被 C++、C#、Rust 等语言访问
- 适合现代 Windows 应用架构

在 WinUI 3 中，C++/WinRT 是对 WinRT 的 C++ 投影（projection）。也就是说：

- WinRT 定义了运行时对象规范
- C++/WinRT 让 C++ 程序员可以更自然地使用它

例如：

```cpp
winrt::Windows::Foundation::IAsyncAction DoWorkAsync();
```

这段代码并不是普通的裸 C++ 语法，而是在使用 WinRT 定义的对象和异步接口模型。

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

WinUI 3 实际上最重要的工程组合不是控件，而是：

- 数据对象
- ViewModel
- 绑定
- 命令

### 10.1 示例：任务列表数据模型

```cpp
struct TaskItem {
    std::string title;
    bool is_done = false;
};
```

```cpp
struct TaskViewModel {
    std::vector<TaskItem> items;
    std::string filter_text;
};
```

UI 中，可以通过绑定到：

- 任务总数
- 当前已完成数
- 列表展示项
- 新任务文本输入框

做法是：

- 数据模型是纯数据
- ViewModel 对数据做计算、过滤和状态更新
- 界面绑定到 ViewModel

这样代码可维护性会大幅提升。

---

## 11. 异步任务：后台工作和 UI 更新

WinUI 3 中任何耗时操作都必须注意：

- 不要长时间阻塞 UI 线程
- 后台线程做计算
- UI 线程更新界面

### 11.1 典型异步模式

```cpp
IAsyncAction LoadAsync()
{
    co_await winrt::resume_background();
    // long-running task

    co_await winrt::resume_foreground(Dispatcher());
    // update UI here
}
```

常见场景：

- 下载文件
- 读取配置
- 网络请求
- 加载大集合
- 扫描目录

如果不区分后台与前台，程序很容易出现界面卡顿和状态异常。

---

## 12. 资源与主题：Fluent Design

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

