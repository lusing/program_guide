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

WinUI 3 不是“一个单独的控件库”那么简单，它是 Microsoft 推出的现代 Windows UI 开发框架，目标是让桌面应用（尤其是 Windows 11 及更高版本）拥有更统一、更现代、更容易扩展的界面模型。

它的典型特点是：

- 使用 XAML 声明界面结构和布局
- 使用 C++/WinRT、C#、WinUI 3 组合模型来连接业务逻辑
- 更适合 Fluent Design 风格和现代桌面程序
- 更适合 Windows 11 及后续版本的桌面开发生态

### 2.1 先理解 Windows App SDK

很多初学者容易把“WinUI 3”和“Windows App SDK”混成一回事。这里要先分清：

- Windows App SDK（Windows App SDK，常写作 Windows App SDK 或 WindowsAppSDK）是一个开发者运行时/框架包
- 它提供了很多现代 Windows 应用所需要的能力，例如：
  - WinUI 3：UI 框架
  - App 生命周期：应用启动、激活、窗口管理
  - Packaging/Deployment：打包、安装、发布相关能力
  - 辅助 API：文件、通知、窗口、资源、后台能力等

换句话说：

- Windows App SDK 是“开发者所依赖的统一平台包”
- WinUI 3 是“这个平台包中的 UI 子系统”

因此，WinUI 3 不是替代 Windows App SDK，而是 Windows App SDK 里最核心的 UI 组件之一。

### 2.2 WinUI 3 与 Win32 / MFC / WPF 的关系

如果把 Windows 桌面开发分层看，可以这样理解：

- Win32：最底层，直接面对 Windows API、消息循环、窗口句柄、线程、进程等
- MFC：C++ 的桌面应用框架，建立在 Win32 之上，封装了一部分窗口和控件模型
- WPF：基于 .NET 的桌面 UI 框架，强调数据绑定、样式、布局和图形渲染
- WinUI 3：基于现代 Windows 平台的 UI 框架，强调 XAML、Fluent Design、现代桌面应用工程组织

它们不是互相替代的关系，而是不同年代的技术栈：

- Win32 更偏底层和系统编程
- MFC 是传统桌面开发工程思路
- WPF 是 .NET 时代的桌面 UI 设计
- WinUI 3 是面向现代 Windows 生态的下一代桌面开发平台

### 2.3 WinUI 3 的本质：不是控件，而是应用模型

WinUI 3 的本质不是“一个新控件库”，而是一种现代桌面应用开发模型：

- XAML 管理页面结构和布局
- C++/WinRT 管理状态、事件和业务逻辑
- App / Window / Page 组织应用生命周期和导航
- Resource Dictionary 管理主题和样式
- Binding、Command、ViewModel 组织界面和数据之间的关系

这意味着：

- 你不只是写 `Button`、`TextBox`、`ComboBox`
- 你要思考：
  - 界面如何组织？
  - 数据如何流动？
  - 事件如何驱动状态变化？
  - 页面如何切换？
  - 任务是同步还是异步？

只有理解“应用模型”，你写出来的才是真正的 WinUI 3 程序，而不只是控件拼贴。

### 2.4 WinUI 3 在现代 Windows 开发中的位置

可以把它放在下面这个层次中看：

```text
Windows OS
   ↓
Win32 / COM / DirectX / DWrite
   ↓
Windows App SDK
   ↓
WinUI 3 + XAML + Controls + Resources
   ↓
你的桌面应用
```

这里的关键点是：

- WinUI 3 依赖 WinRT、COM 和 Windows 平台能力
- Windows App SDK 为它提供统一的运行时、打包和应用生命周期支持
- 开发者通常不直接操作最底层系统接口，而是通过 WinUI 3 的对象模型来开发界面

也就是说，WinUI 3 不是脱离系统运行的一套独立技术，它是现代 Windows 应用开发栈中非常关键的一层。

### 2.5 一句话总结

如果把它压缩成一句最核心的描述：

> WinUI 3 是现代 Windows 桌面应用的 UI 框架，而 Windows App SDK 则是它背后的统一开发运行时和应用平台；二者结合，构成了新的 Windows 应用开发模型。

理解了这一层关系，后面的 XAML、控件、事件、绑定、导航和应用结构就会更容易看懂。

---

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

