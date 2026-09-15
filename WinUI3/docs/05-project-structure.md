# 5. 工程分层：App / Window / Page / ViewModel / Model / Service

模板工程的 MainWindow 里塞几个控件就能跑，但真实应用必须分层。这一篇讲清每一层的职责边界、页面导航怎么做、IDL 声明哪些成员。

## 5.1 各层职责

| 层 | 职责 | 生命周期 | 不该做的事 |
|----|------|---------|-----------|
| **App** | 应用对象：全局资源、异常处理、启动逻辑 | 整个进程 | 界面细节、业务逻辑 |
| **Window（MainWindow）** | 窗口壳：标题栏、导航容器、全局快捷键 | 窗口期间 | 业务逻辑、数据操作 |
| **Page** | 一个页面的布局 + 把用户动作转交给 ViewModel | 页面在导航栈中期间 | 直接读写文件/网络 |
| **ViewModel** | 页面状态 + 动作逻辑，可观察（INotifyPropertyChanged） | 跟随页面 | 直接引用 UI 控件 |
| **Model** | 纯数据对象（runtimeclass），描述业务实体 | 由拥有者决定 | 界面相关内容 |
| **Service** | 文件、网络、注册表、数据库等真实 IO | 应用级（可复用） | 了解 UI 的存在 |

判断"某段代码放哪"的试金石：

> 这段代码如果界面从 Window 换成 CLI，还需要吗？需要 → Service/Model。只跟界面状态有关 → ViewModel。只跟某个控件布局有关 → Page 的 XAML/code-behind。

## 5.2 目录组织

在模板结构上扩展：

```text
MyApp/
├── App.xaml / App.idl / App.xaml.h / App.xaml.cpp
├── MainWindow.xaml / MainWindow.idl / MainWindow.xaml.h / .cpp
├── Pages/
│   ├── HomePage.xaml / HomePage.idl / HomePage.xaml.h / .cpp
│   ├── TasksPage.xaml / TasksPage.idl / ...
│   └── SettingsPage.xaml / SettingsPage.idl / ...
├── ViewModels/
│   └── TasksViewModel.idl / TasksViewModel.h / .cpp
├── Models/
│   └── TaskItem.idl / TaskItem.h / TaskItem.cpp
├── Services/
│   └── TaskStore.idl / TaskStore.h / TaskStore.cpp
├── Styles/
│   └── CardStyles.xaml
└── Assets/
```

**每个 runtimeclass 都要有自己的 `.idl`**——这是 C++/WinRT 与 C# WinUI 3 最大的工程差异。凡是要被 XAML 绑定、被其他 runtimeclass 引用的类型，必须先进 IDL。

## 5.3 Window 只做壳：Frame + NavigationView

多页面应用的标准结构：`MainWindow` 里放一个 `NavigationView`（侧边栏）加一个 `Frame`（页面容器）：

```xml
<!-- MainWindow.xaml -->
<Window x:Class="MyApp.MainWindow" ...>
    <NavigationView x:Name="Nav" SelectionChanged="OnNavSelectionChanged">
        <NavigationView.MenuItems>
            <NavigationViewItem Content="Home" Tag="home" Icon="Home" />
            <NavigationViewItem Content="Tasks" Tag="tasks" Icon="List" />
            <NavigationViewItem Content="Settings" Tag="settings" Icon="Setting" />
        </NavigationView.MenuItems>

        <Frame x:Name="ContentFrame" />
    </NavigationView>
</Window>
```

```cpp
// MainWindow.xaml.cpp
#include "pch.h"
#include "MainWindow.xaml.h"
#include "Pages/HomePage.h"
#include "Pages/TasksPage.h"
#include "Pages/SettingsPage.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace winrt::MyApp::implementation;

namespace winrt::MyApp::implementation
{
    void MainWindow::OnNavSelectionChanged(
        IInspectable const&, NavigationViewSelectionChangedEventArgs const& args)
    {
        auto tag = winrt::unbox_value<winrt::hstring>(
            args.SelectedItemContainer().Tag());

        if (tag == L"home") {
            ContentFrame().Navigate(winrt::xaml_typename<winrt::MyApp::HomePage>());
        }
        else if (tag == L"tasks") {
            ContentFrame().Navigate(winrt::xaml_typename<winrt::MyApp::TasksPage>());
        }
        else if (tag == L"settings") {
            ContentFrame().Navigate(winrt::xaml_typename<winrt::MyApp::SettingsPage>());
        }
    }
}
```

要点：

- `winrt::xaml_typename<T>()` 把 runtimeclass 类型转成框架使用的类型名；**要求页面在 IDL 里声明过**——这也是页面必须有 IDL 的原因之一
- `Frame.Navigate` 会创建新的页面对象（可配合 `NavigationCacheMode` 复用，见 5.5）
- `Tag` 用 `unbox_value<hstring>` 取——`Tag` 的类型是 `IInspectable`，字符串要先 `box_value` 放进去

## 5.4 Page 的真实样子

一个页面由四个文件组成（IDL + XAML + h + cpp）：

```xml
<!-- Pages/TasksPage.xaml -->
<Page
    x:Class="MyApp.TasksPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:vm="using:MyApp">

    <Grid Padding="24" RowSpacing="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
        </Grid.RowDefinitions>

        <TextBox x:Name="NewTaskInput" Header="New task"
                 PlaceholderText="What do you want to do?" />

        <ListView Grid.Row="1" ItemsSource="{x:Bind ViewModel.Tasks, Mode=OneWay}" />
    </Grid>
</Page>
```

```cpp
// TasksPage.xaml.h（节选）
struct TasksPage : TasksPageT<TasksPage>
{
    TasksPage();

    // 把 ViewModel 暴露给 x:Bind（必须是 IDL 声明的属性）
    winrt::MyApp::TasksViewModel ViewModel();

private:
    winrt::MyApp::TasksViewModel m_viewModel{ nullptr };
};
```

```cpp
// TasksPage.xaml.cpp
TasksPage::TasksPage()
{
    InitializeComponent();
    m_viewModel = winrt::make<TasksViewModel>();
}

winrt::MyApp::TasksViewModel TasksPage::ViewModel() { return m_viewModel; }
```

注意模式：**页面持有 ViewModel 引用并通过只读属性暴露**，XAML 的 `x:Bind` 路径 `ViewModel.Tasks` 就是从这个属性出发的。ViewModel 里没有一行 UI 代码。

## 5.5 页面生命周期

```text
Frame.Navigate(type)
  ↓
页面构造函数（InitializeComponent、创建 ViewModel）
  ↓
Loading → Loaded 事件（可安全访问控件、发起异步加载）
  ↓
用户交互 / x:Bind 刷新
  ↓
Frame 导航离开
  ↓
（默认）页面对象销毁 —— 返回导航会重新构造
  ↓
Unloaded 事件
```

两个工程决定要做：

- **状态是否要跨导航保留**：默认不保留（重新构造）。设 `NavigationCacheMode="Enabled"` 让 Frame 缓存页面实例，ViewModel 状态随之保留
- **异步加载的时机**：构造函数里不能 `co_await`（构造函数不是协程）。标准做法是订阅 `Loaded` 事件后启动异步加载：

```cpp
TasksPage::TasksPage()
{
    InitializeComponent();
    Loaded([](IInspectable const& sender, RoutedEventArgs const&)
    {
        sender.as<TasksPage>()->StartLoadingAsync();
    });
}
```

## 5.6 ViewModel 与 Model 的边界

容易混淆的一对，用任务应用举例：

```cpp
// Models/TaskItem —— 数据本身（IDL: runtimeclass TaskItem）
runtimeclass TaskItem
{
    String Title;
    Boolean Done;
};

// ViewModels/TasksViewModel —— 页面看到的世界（IDL: runtimeclass TasksViewModel）
runtimeclass TasksViewModel
{
    TasksViewModel();

    // 状态：给界面看的
    Windows.Foundation.Collections.IObservableVector<MyApp.TaskItem> Tasks { get; };
    Boolean HasTasks { get; };
    String Status { get; };

    // 动作：界面触发的
    void AddTask(String title);
    void RemoveSelected();
};
```

区分标准：

- `TaskItem`（Model）：一条任务**是什么**——删掉界面它依然成立
- `TasksViewModel`（ViewModel）：**这个页面**怎么呈现任务——有没有选中项、按钮该不该禁用、状态栏显示什么，这些只属于"这个页面"的世界

Model 里出现 `IsSelected`（选中态）这类字段时要警惕：选中态是界面概念，多数情况应放 ViewModel 或容器层。

## 5.7 Service 层

Service 封装真实 IO，对上只暴露业务语义的接口：

```cpp
// Services/TaskStore.idl
runtimeclass TaskStore
{
    TaskStore();

    Windows.Foundation.IAsyncOperation<
        Windows.Foundation.Collections.IVectorView<MyApp.TaskItem>>
        LoadAsync();
    Windows.Foundation.IAsyncAction SaveAsync(
        Windows.Foundation.Collections.IVectorView<MyApp.TaskItem> tasks);
}
```

调用链永远是单向的：

```text
Page（界面/事件） → ViewModel（状态/动作） → Service（IO） → 磁盘/网络/注册表
                                    ↓
                          ViewModel 更新可观察状态
                                    ↓
                          x:Bind 刷新界面
```

Page 永远不直接调 Service，ViewModel 永远不碰 UI 对象。保持这两条，单元测试 ViewModel 时就不需要界面的存在。

---

上一篇：[04-first-app.md](./04-first-app.md) ｜ 下一篇：[06-controls.md](./06-controls.md)
