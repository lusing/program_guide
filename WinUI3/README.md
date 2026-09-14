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

适用场景：

- 保存
- 取消
- 提交
- 打开文件
- 切换状态

示例：

```cpp
void MainViewModel::save()
{
    status_ = "Saved";
}
```

示例源码：
- [09_button_control](G:/code/guide/WinUI3/cpp_examples/09_button_control/button_control.cpp)

### 8.2 TextBox：文本输入与校验

适用场景：

- 用户名、密码、搜索文本
- 简单表单输入
- 收集命令参数

核心跟踪：

- 输入值变化事件：`TextChanged`
- 验证规则：长度、格式、必填
- 反馈状态：红色提示、错误文本、禁用按钮

示例源码：
- [10_textbox_control](G:/code/guide/WinUI3/cpp_examples/10_textbox_control/textbox_control.cpp)

### 8.3 CheckBox 与 RadioButton：选择状态

适用场景：

- 勾选项
- 勾选协议
- 选择应用模式
- 单选配置项

这类控件本质上是“状态表达器”：

- 选中/未选中
- 单/多选
- 不同分支逻辑

示例源码：
- [11_checkbox_radio_control](G:/code/guide/WinUI3/cpp_examples/11_checkbox_radio_control/checkbox_radio_control.cpp)

### 8.4 ComboBox：下拉选择

适用场景：

- 主题选择
- 角色选择
- 区域选择
- 图表维度切换

典型做法：

- `ItemsSource` 绑定数据集合
- `SelectedIndex` / `SelectedItem` 标识当前选项
- `SelectionChanged` 处理变化事件

示例源码：
- [12_combobox_listview_control](G:/code/guide/WinUI3/cpp_examples/12_combobox_listview_control/combobox_listview_control.cpp)

### 8.5 ListView：数据集合展示

适用场景：

- 列表展示
- 任务列表
- 用户列表
- 文件清单
- 日志窗口

ListView 是 WinUI 3 中最关键的数据展示控件之一，因为它展示的是“集合”，而不是单个值。

关键知识：

- `ItemsSource` 绑定集合
- `ItemTemplate` 指定每项的可视化方式
- `SelectionChanged` 处理选中项
- `ObservableCollection` 常见于动态数据更新

示例源码：
- [12_combobox_listview_control](G:/code/guide/WinUI3/cpp_examples/12_combobox_listview_control/combobox_listview_control.cpp)

### 8.6 ToggleSwitch / Slider / ProgressBar：交互反馈

适用场景：

- 通知开关
- 音量调节
- 下载进度显示
- 运行状态反馈

这几类控件体现的是“动态状态”和“反馈机制”：

- ToggleSwitch 展示状态
- Slider 表示值调整
- ProgressBar 提醒任务执行进度

示例源码：
- [13_slider_toggle_control](G:/code/guide/WinUI3/cpp_examples/13_slider_toggle_control/slider_toggle_control.cpp)

### 8.7 ContentDialog：对话框交互

适用场景：

- 确认删除
- 修改设置
- 选择保存路径
- 需要用户输入确认的操作

它实际上是 WinUI 3 中的“临时交互窗口”，非常适合：

- 单次问题确认
- 动态表单输入
- 结果反馈

示例源码：
- [14_dialog_navigation_control](G:/code/guide/WinUI3/cpp_examples/14_dialog_navigation_control/dialog_navigation_control.cpp)

### 8.8 NavigationView：页面导航

适用场景：

- 设置程序
- 多页面应用
- 工具箱式应用
- 主菜单型软件

NavigationView 让界面从“单页应用”扩展成“多页面应用”。这是 WinUI 3 很重要的一环。

示例源码：
- [14_dialog_navigation_control](G:/code/guide/WinUI3/cpp_examples/14_dialog_navigation_control/dialog_navigation_control.cpp)

---

## 9. XAML 布局基础：Grid / StackPanel / Border / RelativePanel

WinUI 3 的布局容器非常关键。常见布局容器：

- `StackPanel`：按顺序叠放
- `Grid`：表格布局，适合复杂界面
- `Border`：装饰边框和容器
- `RelativePanel`：相对定位布局
- `Canvas`：绝对定位

### 9.1 StackPanel

```xml
<StackPanel Orientation="Vertical" Spacing="12">
    <TextBox Header="Name" />
    <Button Content="Submit" />
</StackPanel>
```

### 9.2 Grid

```xml
<Grid>
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto" />
        <RowDefinition Height="*" />
    </Grid.RowDefinitions>

    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*" />
        <ColumnDefinition Width="220" />
    </Grid.ColumnDefinitions>

    <TextBlock Grid.Row="0" Grid.Column="0" Text="Title" />
    <ListView Grid.Row="1" Grid.Column="0" />
    <Button Grid.Row="1" Grid.Column="1" Content="Add" />
</Grid>
```

这类布局是 WinUI 3 中最常见的结构。

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

