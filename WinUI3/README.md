# WinUI 3 C++/WinRT 编程指南

> 本教程已经从“概念介绍”升级成“实战导向”的 WinUI 3 学习指南。
> 重点不是列举 API，而是通过 XAML + C++/WinRT 的真实使用方式，理解 WinUI 3 应用如何构建、如何管理界面状态、如何响应用户事件、如何处理导航和数据绑定。

## 1. 课程目标

本教程适合想学 WinUI 3 的开发者，目标是建立如下能力：

- 理解 WinUI 3 与传统 Win32 / WPF / MFC 的差异
- 熟练使用 C++/WinRT 编写 WinUI 3 应用
- 掌握主要控件的创建、绑定和事件处理
- 能使用 MVVM / ViewModel 组织复杂界面逻辑
- 能在实际项目中理解导航、状态管理和异步 UI 更新

本书强调“可直接照着写”的代码思路，而不仅仅是解释概念。

---

## 2. WinUI 3 是什么

WinUI 3 是 Windows 11 / 新版 Windows 平台下的现代 UI 框架，其核心特点包括：

- 基于 XAML 进行界面声明
- 使用 C++/WinRT 或 C# 连接运行时代码
- 适配 Fluent Design 设计语言
- 可以和 Windows 运行时能力深度集成
- 更适合现代桌面应用的界面布局和状态管理

从工程角度，它可以理解成：

- XAML 负责“界面长什么样”
- C++/WinRT 负责“界面怎么动、怎么响应用户、怎么管理状态”

因此，WinUI 3 不是“只画界面”，而是一个完整的桌面开发模型。

---

## 3. WinUI 3 与传统框架的区别

### 3.1 WinUI 3 与 Win32 的区别

- Win32 是底层原生 API，比较接近系统层
- WinUI 3 是现代桌面 UI 框架，抽象层更高
- Win32 更偏底层控制；WinUI 3 更偏现代应用工程化

### 3.2 WinUI 3 与 WPF 的区别

- WPF 是 .NET 框架
- WinUI 3 是基于 Windows Runtime 设计的现代 UI 框架
- WinUI 3 更适合 Win11 生态、现代 Fluent UI 和新平台能力

### 3.3 WinUI 3 与 MFC 的区别

- MFC 主要是 Win32 的 C++ 封装
- WinUI 3 更强调现代界面设计、XAML 声明式布局和 WinRT 运行时对象模型

如果你已经熟悉 Win32，那么理解 WinUI 3 会更容易，因为很多概念都可以对应：

- 窗口 = App + Window
- 控件 = XAML 控件
- 事件 = Click / SelectionChanged / TextChanged
- 消息分发 = XAML 事件路由

---

## 4. 学习路线建议

建议按下面顺序学习：

1. 创建最小 WinUI 3 应用
2. 理解 Window / Page / Frame / NavigationView
3. 学习 Button、TextBox、CheckBox、RadioButton 等基础控件
4. 学习 ComboBox、ListView、DataGrid 等数据展示控件
5. 理解 MVVM 和 ViewModel
6. 学习异步编程和后台任务
7. 处理对话框、导航、状态管理与资源主题

这一趟路线比“单独背 API”更有效，因为 WinUI 3 的核心是：

- 组件组合
- 数据绑定
- 事件驱动
- 状态流转

---

## 5. WinUI 3 的常见结构

一个典型的 WinUI 3 应用通常包含：

- App 类：应用启动入口
- MainWindow：主窗口
- Page：页面容器
- ViewModel：界面状态和业务逻辑
- XAML 文件：UI 布局
- C++/WinRT 事件处理：事件处理器 / 命令绑定

典型结构如下：

```cpp
struct MainViewModel {
    winrt::hstring title{ L"Demo" };
    int counter = 0;
};
```

对应的 XAML：

```xml
<StackPanel>
    <TextBlock Text="{x:Bind ViewModel.Title, Mode=OneWay}" />
    <Button Content="点击我" Click="OnClick" />
</StackPanel>
```

这里要理解的关键是：

- XAML 定义界面结构
- C++ 对象通过绑定和事件来驱动行为
- ViewModel 负责状态管理

---

## 6. WinUI 3 的事件模型

WinUI 3 的事件处理通常分成两种：

- 控件事件，例如 `Click`、`TextChanged`、`SelectionChanged`
- 自定义命令或 ViewModel 逻辑封装

### 6.1 事件处理示例

```cpp
void MainPage::OnSaveClick(IInspectable const&, RoutedEventArgs const&)
{
    auto text = NameBox().Text();
    OutputText().Text(text);
}
```

这说明：

- 控件事件最终由事件处理函数处理
- 事件处理函数中读取输入或写入状态
- UI 视图和逻辑代码是分离的，但也可以在代码中协调

### 6.2 命令与 ViewModel

更工程化的写法是：

```cpp
class SaveCommand {
public:
    explicit SaveCommand(std::function<void()> execute)
        : execute_(std::move(execute)) {}

    void Execute() const { execute_(); }

private:
    std::function<void()> execute_;
};
```

这种方式的好处：

- 逻辑更容易测试
- 事件代码更轻量
- 界面只负责绑定和交互

---

## 7. 主要控件导读：从最常用控件开始

WinUI 3 最常见的控件包括：

- Button：触发动作
- TextBox：文本输入
- PasswordBox：密码输入
- CheckBox：单项勾选
- RadioButton：单选
- ComboBox：下拉选择
- ListView：列表展示和选择
- ToggleSwitch：开关控制
- Slider：数值调整
- ProgressBar：进度显示
- DatePicker / TimePicker：日期与时间选择
- ContentDialog：弹窗交互
- NavigationView：导航容器

这些控件是现代桌面应用的核心构件，几乎所有实际软件都会用到它们。

---

## 8. 主要控件与例程

下面各章节都配有对应例程，源码位于 `cpp_examples/` 下。

### 8.1 Button：点击事件与动作触发

Button 是最基础的交互控件，适合做：

- 保存
- 提交
- 取消
- 关闭
- 发送请求

XAML 示例：

```xml
<Button x:Name="SaveButton"
        Content="保存"
        Click="OnSaveClick" />
```

对应的逻辑：

```cpp
void MainPage::OnSaveClick(IInspectable const&, RoutedEventArgs const&)
{
    auto text = NameBox().Text();
    StatusText().Text(L"已保存：" + text);
}
```

示例源码：
- [button_control.cpp](G:/code/guide/WinUI3/cpp_examples/09_button_control/button_control.cpp)

### 8.2 TextBox：文本输入与验证

TextBox 是最常见的输入控件，通常用于：

- 用户名
- 搜索框
- 多行文本输入
- 表单字段

XAML 示例：

```xml
<TextBox x:Name="NameBox"
         Header="用户名"
         PlaceholderText="请输入用户名" />
```

事件处理：

```cpp
void MainPage::OnNameChanged(IInspectable const&, TextChangedEventArgs const&)
{
    auto value = NameBox().Text();
    if (value.Length() < 3) {
        ErrorText().Text(L"用户名不能少于 3 个字符");
    }
}
```

示例源码：
- [textbox_control.cpp](G:/code/guide/WinUI3/cpp_examples/10_textbox_control/textbox_control.cpp)

### 8.3 CheckBox / RadioButton：选择状态

这类控件用于：

- 同意协议
- 记住我
- 单项选择
- 策略设置

XAML 示例：

```xml
<CheckBox Content="记住我" IsChecked="true" />
<RadioButton GroupName="Mode" Content="开发模式" IsChecked="true" />
<RadioButton GroupName="Mode" Content="生产模式" />
```

典型逻辑：

```cpp
if (RememberMeBox().IsChecked().Value()) {
    // enable save credentials
}
```

示例源码：
- [checkbox_radio_control.cpp](G:/code/guide/WinUI3/cpp_examples/11_checkbox_radio_control/checkbox_radio_control.cpp)

### 8.4 ComboBox：下拉选择

ComboBox 适合：

- 语言选择
- 主题选择
- 角色选择
- 模式切换

XAML 示例：

```xml
<ComboBox x:Name="ThemeComboBox"
          SelectedIndex="0">
    <x:String>浅色</x:String>
    <x:String>深色</x:String>
    <x:String>跟随系统</x:String>
</ComboBox>
```

事件：

```cpp
void MainPage::OnThemeChanged(IInspectable const&, SelectionChangedEventArgs const&)
{
    auto text = ThemeComboBox().SelectedItem().as<IInspectable>();
}
```

示例源码：
- [combobox_listview_control.cpp](G:/code/guide/WinUI3/cpp_examples/12_combobox_listview_control/combobox_listview_control.cpp)

### 8.5 ListView：展示集合数据

ListView 是 WinUI 3 中非常核心的列表控件，适合：

- 任务列表
- 用户列表
- 日志展示
- 设置项清单

XAML 示例：

```xml
<ListView ItemsSource="{x:Bind ViewModel.Tasks}">
    <ListView.ItemTemplate>
        <DataTemplate>
            <TextBlock Text="{Binding Title}" />
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

这一部分非常关键，因为它体现了 WinUI 3 的数据绑定能力。

示例源码：
- [combobox_listview_control.cpp](G:/code/guide/WinUI3/cpp_examples/12_combobox_listview_control/combobox_listview_control.cpp)

### 8.6 ToggleSwitch / Slider / ProgressBar：状态调节与反馈

这组控件常用于：

- 开关设置
- 音量与亮度控制
- 进度显示
- 任务状态反馈

XAML 示例：

```xml
<ToggleSwitch Header="通知" OnContent="开启" OffContent="关闭" />
<Slider Minimum="0" Maximum="100" Value="40" />
<ProgressBar Value="70" />
```

示例源码：
- [slider_toggle_control.cpp](G:/code/guide/WinUI3/cpp_examples/13_slider_toggle_control/slider_toggle_control.cpp)

### 8.7 ContentDialog：弹框交互

ContentDialog 是 WinUI 3 中很常见的“临时交互”组件：

- 确认删除
- 选择保存方式
- 输入表单

逻辑上非常像 Win32 的对话框，但它更适合 Fluent UI 风格。

XAML 示例：

```cpp
ContentDialog dialog;
dialog.Title(L"确认");
dialog.Content(L"是否删除该项？");
dialog.PrimaryButtonText(L"删除");
dialog.SecondaryButtonText(L"取消");
```

示例源码：
- [dialog_navigation_control.cpp](G:/code/guide/WinUI3/cpp_examples/14_dialog_navigation_control/dialog_navigation_control.cpp)

### 8.8 NavigationView：页面导航

NavigationView 适合：

- 侧边栏导航
- 设置页结构
- 主菜单式应用
- 多页面应用

它是 WinUI 3 应用中最典型的导航模式之一。

示例源码：
- [dialog_navigation_control.cpp](G:/code/guide/WinUI3/cpp_examples/14_dialog_navigation_control/dialog_navigation_control.cpp)

---

## 9. C++/WinRT 实战模式

### 9.1 事件绑定

```cpp
button.Click([&](auto const&, auto const&)
{
    StatusText().Text(L"Button clicked");
});
```

### 9.2 数据绑定

```cpp
box.Text(ViewModel().UserName());
```

### 9.3 ViewModel 组织逻辑

```cpp
struct UserProfileViewModel {
    winrt::hstring username;
    bool remember_me = false;
    int theme_index = 0;
};
```

### 9.4 异步任务

```cpp
IAsyncAction LoadAsync()
{
    co_await winrt::resume_background();
    // background work
    co_await winrt::resume_foreground(Dispatcher());
    // update UI
}
```

这种写法是 WinUI 3 C++/WinRT 中最常见的工作流：

- 后台执行
- 结束后返回主线程更新 UI

---

## 10. 推荐的工程结构

一个中等规模的 WinUI 3 C++/WinRT 项目推荐这样组织：

```text
MyApp/
├── App.idl
├── App.xaml
├── App.h
├── App.cpp
├── MainWindow.xaml
├── MainWindow.h
├── MainWindow.cpp
├── ViewModels/
│   ├── MainViewModel.h
│   └── MainViewModel.cpp
├── Pages/
│   ├── HomePage.xaml
│   ├── SettingsPage.xaml
│   └── AboutPage.xaml
├── Models/
│   ├── TaskItem.h
│   └── TaskItem.cpp
└── Resources/
    └── Styles.xaml
```

这种结构让项目：

- 更适合维护
- 更容易做 ViewModel 分层
- 更容易扩展功能模块
- 更适合团队协作

---

## 11. 编译验证

在 [WinUI3/](G:/code/guide/WinUI3/) 目录执行：

```powershell
.\build.ps1
```

如果想清理输出：

```powershell
.\build.ps1 -Clean
```

本目录中的示例代码都以 C++ 形式组织，重点是体现 WinUI 3 的设计思路、控件组合方式和状态管理方式，并保持编译验证可重复执行。

---

## 12. 示例源码索引

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

---

## 13. 学习建议：如何把教程真正用起来

学习 WinUI 3 时，最容易踩的坑不是语法，而是思路：

1. 先理解界面结构，再理解业务状态。
2. 不要把所有逻辑塞进事件处理器里。
3. 复杂 UI 应该使用 ViewModel 变成可维护结构。
4. 对于异步任务，要记得更新 UI 前返回主线程。
5. 需要良好命名和状态对象，否则界面逻辑会很快失控。

如果你能把这些原则融入实践，你就已经不是在“看教程”，而是在写真实的 WinUI 3 应用了。

---

## 14. 后续扩展建议

更进一步的章节可以继续扩展：

- WinRT 事件退订（RAII / revoker）
- 多页面导航栈与参数传递
- 本地存储和 JSON 配置
- HttpClient 网络请求与异步分页
- DataGrid 与复杂表格应用
- 自定义控件与样式资源
- WinUI 3 里集成第三方组件与 XAML 自定义控件

这部分内容可以作为本教程的第二阶段内容，适合把学习推进到真实项目开发。

