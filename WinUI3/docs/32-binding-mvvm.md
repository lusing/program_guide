# 32. 数据绑定、MVVM 与异步

这一篇是工程的枢纽：界面为什么跟着数据变、用户动作怎么驱动状态、耗时工作怎么不卡界面。所有代码都是 C++/WinRT 真实可用的写法——包括 C++ 里实现 `INotifyPropertyChanged` 的完整样板，这是 C# 教程里查不到的部分。

## 32.1 绑定解决什么问题

没有绑定的页面是这样的：

```cpp
// 反模式：状态散落在控件里，每个事件手动搬运
void MainPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
{
    TaskList().Items().Append(TaskInput().Text());   // 界面对象即数据存储
    TaskInput().Text(L"");
    StatusText().Text(L"Added");
}
```

能跑，但状态存在控件里，多处界面读同一份数据就互相抄写，测试也离不开界面。绑定的思路是把方向反过来：

```text
状态住在 ViewModel（纯逻辑，不知道 UI 的存在）
   ↓ 变化时发出通知（INotifyPropertyChanged / IObservableVector）
绑定引擎收到通知 → 更新对应的控件属性
```

于是界面成了状态的**投影**：改状态，界面自己变。

## 32.2 可观察对象：在 C++/WinRT 里实现 INotifyPropertyChanged

XAML 绑定引擎听的是 `INotifyPropertyChanged` 接口——数据对象属性变化时触发 `PropertyChanged` 事件。C++/WinRT 的完整实现（IDL + 头 + 实现）：

```cpp
// Models/TaskItem.idl
namespace MyApp
{
    runtimeclass TaskItem : Microsoft.UI.Xaml.Data.INotifyPropertyChanged
    {
        TaskItem(String title);
        String Title;
        Boolean Done;
    }
}
```

```cpp
// Models/TaskItem.h
#pragma once
#include "TaskItem.g.h"

namespace winrt::MyApp::implementation
{
    struct TaskItem : TaskItemT<TaskItem>
    {
        TaskItem(winrt::hstring const& title);

        // INotifyPropertyChanged：订阅/退订转发给 winrt::event
        winrt::event_token PropertyChanged(
            Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler);
        void PropertyChanged(winrt::event_token const& token);

        winrt::hstring Title();
        void Title(winrt::hstring const& value);
        bool Done();
        void Done(bool value);

    private:
        winrt::event<Microsoft::UI::Xaml::Data::PropertyChangedEventHandler>
            m_propertyChanged;
        winrt::hstring m_title;
        bool m_done = false;

        void RaisePropertyChanged(winrt::hstring const& propertyName);
    };
}

namespace winrt::MyApp::factory_implementation
{
    struct TaskItem : TaskItemT<TaskItem, implementation::TaskItem>
    {
    };
}
```

```cpp
// Models/TaskItem.cpp
#include "pch.h"
#include "TaskItem.h"

using namespace winrt::MyApp::implementation;

TaskItem::TaskItem(winrt::hstring const& title) : m_title(title) {}

winrt::event_token TaskItem::PropertyChanged(
    Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler)
{
    return m_propertyChanged.add(handler);
}

void TaskItem::PropertyChanged(winrt::event_token const& token)
{
    m_propertyChanged.remove(token);
}

winrt::hstring TaskItem::Title() { return m_title; }

void TaskItem::Title(winrt::hstring const& value)
{
    if (m_title != value)
    {
        m_title = value;
        RaisePropertyChanged(L"Title");
    }
}

bool TaskItem::Done() { return m_done; }

void TaskItem::Done(bool value)
{
    if (m_done != value)
    {
        m_done = value;
        RaisePropertyChanged(L"Done");
    }
}

void TaskItem::RaisePropertyChanged(winrt::hstring const& propertyName)
{
    m_propertyChanged(*this, Microsoft::UI::Xaml::Data::PropertyChangedEventArgs(propertyName));
}
```

这套样板是 C++/WinRT MVVM 的基石，值得逐行理解：

- **setter 里比较 + 触发**：值没变不发通知，避免无意义的界面刷新
- `winrt::event<D>` 负责处理器列表的线程安全存储，`add`/`remove` 对应 ABI 的事件方法（见 [02 篇](./02-winrt.md) 2.6.3）
- `PropertyChangedEventArgs` 携带属性名，绑定引擎按名字找到要刷新的 `x:Bind` 目标
- 必须在 **IDL 里声明**：绑定要跨 WinRT 边界调用属性，普通 C++ struct 的成员绑定引擎看不见
- **`factory_implementation` 结构不能省**：`TaskItem` 的 IDL 有构造函数 `TaskItem(String title)`，cppwinrt 生成的激活工厂要靠这个结构把投影类型接到实现类型上。漏掉它不会在编译期报错，而是在链接期或首次 `winrt::make<TaskItem>()`/激活时报错——`examples/32-binding-mvvm/` 编译验证过：有这个结构才链得过

## 32.3 页面与 ViewModel 的连接

ViewModel 把可观察状态暴露为 IDL 属性：

```cpp
// ViewModels/TasksViewModel.idl
namespace MyApp
{
    runtimeclass TasksViewModel : Microsoft.UI.Xaml.Data.INotifyPropertyChanged
    {
        String Status;
        void AddTask(String title);
    }
}
```

> **IDL 必须声明 `: Microsoft.UI.Xaml.Data.INotifyPropertyChanged`**：只要这个 ViewModel 上有 `Mode=OneWay` 的属性绑定（这里的 `Status`），或它的集合会被整体替换（下面的 `Tasks`），就得让绑定引擎知道它实现了这个接口——否则 `OneWay` 绑定**静默不刷新**，编译不报错，运行也不报错，只是界面永远停在初值。`examples/32-binding-mvvm/` 编译验证过这一点。

页面持有它并通过属性暴露（见 [05 篇](./05-project-structure.md) 5.4），XAML 侧用 `x:Bind`：

```xml
<TextBlock Text="{x:Bind ViewModel.Status, Mode=OneWay}" />
```

`x:Bind` 各模式的选择（回顾 [03 篇](./03-xaml.md) 3.6，补充工程角度）：

| Mode | 用途 | 对源的要求 |
|------|------|-----------|
| `OneTime`（默认） | 初始化后不变的值 | 无 |
| `OneWay` | 状态变化自动刷界面 | 源实现 `INotifyPropertyChanged` |
| `TwoWay` | 界面输入写回状态 | 同上 |

`TwoWay` 的刷新时机用 `UpdateSourceTrigger` 控制：

```xml
<!-- LostFocus（默认）：失焦才写回 -->
<TextBox Text="{x:Bind ViewModel.Query, Mode=TwoWay}" />

<!-- PropertyChanged：每敲一个字符写回，适合"边输边搜" -->
<TextBox Text="{x:Bind ViewModel.Query, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" />
```

**排查绑定不刷新**的固定顺序：

1. 忘了 `Mode=OneWay`（`x:Bind` 默认 `OneTime`，最常见原因）
2. 源没实现 `INotifyPropertyChanged`，或 setter 里忘了触发
3. 属性名和 `RaisePropertyChanged` 的参数不一致
4. 属性没进 IDL，绑定引擎根本看不到
5. 在后台线程改了状态（通知必须回到 UI 线程发，见 32.7）

## 32.4 可观察集合：IObservableVector

列表控件（`ListView` 等）要感知"集合内容变了"，数据源需要实现 `IObservableVector<T>`。不用手写——C++/WinRT 提供现成实现：

```cpp
// ViewModels/TasksViewModel.h（节选）
#include <winrt/Windows.Foundation.Collections.h>   // IObservableVector 在这里
#include <winrt/MyApp.TaskItem.h>

struct TasksViewModel : TasksViewModelT<TasksViewModel>
{
    TasksViewModel();

    winrt::Windows::Foundation::Collections::IObservableVector<
        winrt::MyApp::TaskItem> Tasks();

    void AddTask(winrt::hstring const& title);

private:
    winrt::Windows::Foundation::Collections::IObservableVector<
        winrt::MyApp::TaskItem> m_tasks{ nullptr };
};
```

> 想手动订阅"集合变了"，WinUI 3 的 `INotifyCollectionChanged` / `NotifyCollectionChangedEventArgs` 在 **`Microsoft.UI.Xaml.Interop`** 命名空间（UWP 时代叫 `Windows.UI.Xaml.Interop`，改名了），那才需要 `#include <winrt/Microsoft.UI.Xaml.Interop.h>`。绑定引擎自己会接这个事件，多数时候你不用手写。

```cpp
// ViewModels/TasksViewModel.cpp
using namespace winrt::MyApp::implementation;

TasksViewModel::TasksViewModel()
{
    // 单线程可观察向量：Append/Remove 等操作自动触发 VectorChanged
    m_tasks = winrt::single_threaded_observable_vector<winrt::MyApp::TaskItem>();
}

void TasksViewModel::AddTask(winrt::hstring const& title)
{
    if (title.empty()) { return; }
    m_tasks.Append(winrt::make<TaskItem>(title));
    Status(L"Added: " + title);
}
```

配套的 IDL：

```idl
runtimeclass TasksViewModel
{
    Windows.Foundation.Collections.IObservableVector<MyApp.TaskItem> Tasks { get; };
    ...
}
```

XAML 侧（配合 [03 篇](./03-xaml.md) 3.9 的 DataTemplate）：

```xml
<ListView ItemsSource="{x:Bind ViewModel.Tasks, Mode=OneWay}">
    <ListView.ItemTemplate>
        <DataTemplate x:DataType="vm:TaskItem">
            <TextBlock Text="{x:Bind Title, Mode=OneWay}" />
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

数据流闭环（全教程唯一权威版本）：

```text
用户输入 / 点击
  ↓ 事件或 TwoWay 绑定
ViewModel 动作（AddTask）
  ↓ 操作 IObservableVector / setter + RaisePropertyChanged
可观察状态变化（VectorChanged / PropertyChanged）
  ↓ 绑定引擎监听
ListView / TextBlock 自动刷新
```

注意与旧教程写法的本质区别：**`std::vector<T>` 不能作为绑定数据源**。`ItemsSource` 需要的是 WinRT 集合接口；`std::vector` 只在 Service/算法层使用，进 ViewModel 边界时要转成 `IObservableVector`。

还有一个只在"换集合"时才暴露的坑：

```cpp
// 往现有集合增删 —— VectorChanged 自动驱动界面刷新，不需要额外通知
m_tasks.Append(winrt::make<TaskItem>(title));

// 整体替换集合对象 —— 必须再发一次属性通知，否则界面还盯着旧集合
void TasksViewModel::ReloadFrom(IObservableVector<TaskItem> const& replacement)
{
    m_tasks = replacement;
    RaisePropertyChanged(L"Tasks");   // 少了这行，界面永远显示旧数据
}
```

`x:Bind` 的 `Mode=OneWay` 监听的是 **`Tasks` 这个属性的变化**；集合内部的变化靠 `VectorChanged`。两条通知通道各自独立，替换对象只触发了前者才能生效。

## 32.5 Model / ViewModel / View 各管什么

以任务应用收束一遍边界：

| 对象 | 内容 | 典型成员 |
|------|------|---------|
| `TaskItem`（Model） | 一条任务**是什么** | `Title`、`Done` |
| `TasksViewModel`（ViewModel） | **这个页面**怎么呈现任务 | `Tasks`、`Status`、`HasSelection`、`AddTask()`、`DeleteSelected()` |
| `TasksPage`（View） | 布局 + 动作转交 | XAML + `OnAddClicked` 转调 ViewModel |

判断题：`TaskItem` 要不要加 `IsSelected`？如果"选中"只是 ListView 的交互态，用控件的 `SelectedItem()` 就够；如果 ViewModel 的动作需要知道选中项，页面在转交时把选中项传给 `DeleteSelected(TaskItem)`，Model 依然保持纯净。

## 32.6 动作入口：x:Bind 函数绑定优先于 ICommand

C# MVVM 用 `Command="{Binding SaveCommand}"`，C++/WinRT 里实现完整 `ICommand` 是可行的（`winrt::implements<ICommand>` + `winrt::event` 实现 `CanExecuteChanged`），但多数场景有更轻的选择——**`x:Bind` 直接绑到方法**：

```xml
<Button Content="Add" Click="{x:Bind ViewModel.AddFromInput}" />
```

编译期就生成订阅代码，不需要中间的命令对象。注意**被绑方法的签名要和 `Click` 的委托匹配**（`void AddFromInput()` 或带 `(IInspectable const&, RoutedEventArgs const&)`），否则是编译错误而不是运行错误。需要"按钮随可用性自动启停"时再上 `ICommand`：

```cpp
// Commands/RelayCommand.h（节选）
struct RelayCommand : winrt::implements<RelayCommand,
    winrt::Microsoft::UI::Xaml::Input::ICommand>
{
    RelayCommand(std::function<void()> execute) : m_execute(std::move(execute)) {}

    bool CanExecute(winrt::Windows::Foundation::IInspectable const&)
    {
        return m_canExecute();
    }

    void Execute(winrt::Windows::Foundation::IInspectable const&)
    {
        m_execute();
    }

    winrt::event_token CanExecuteChanged(
        winrt::Windows::Foundation::EventHandler<
            winrt::Windows::Foundation::IInspectable> const& handler)
    {
        return m_canExecuteChanged.add(handler);
    }
    void CanExecuteChanged(winrt::event_token const& token)
    {
        m_canExecuteChanged.remove(token);
    }

private:
    std::function<void()> m_execute;
    std::function<bool()> m_canExecute{ [] { return true; } };
    winrt::event<winrt::Windows::Foundation::EventHandler<
        winrt::Windows::Foundation::IInspectable>> m_canExecuteChanged;
};
```

原则：**先函数绑定，出现复用/可执行性需求再抽象成命令**。

用上面的 `RelayCommand` 时有两个约束要记牢：

- 它是 `winrt::implements` 的纯 C++ 类型、**没有进 IDL**，所以只能在 C++ 代码里当值传递。要让 XAML 的 `Command="{x:Bind ...}"` 绑到它，得把命令类型做成 runtimeclass，或在页面/ViewModel 上暴露一个返回它的 IDL 属性
- WinUI 3 的 `ICommand` 在 **`Microsoft.UI.Xaml.Input`** 命名空间下（C# 的 WPF/WinUI 习惯写 `System.Windows.Input`，这里是另一套）

## 32.7 异步：后台工作与 UI 更新

UI 线程被占用 = 界面假死。所有可能超过几十毫秒的工作（文件、网络、大数据量计算）必须离开 UI 线程。三条铁律：

1. 耗时工作放后台
2. UI 对象只能在 UI 线程碰
3. 后台结果必须切回 UI 线程再落地

### 32.7.1 标准模式（WinUI 3 实测写法）

> ⚠️ **先说结论**：网上和 UWP 时代教程里的 `co_await winrt::resume_foreground(m_dispatcherQueue)` **在 WinUI 3 桌面应用里是错的**，而且是"静默挂起"这种最难查的错。原因见本节末尾的说明。下面是 `examples/32-binding-mvvm/` 里**运行时验证过**的写法。

```cpp
// TasksPage.xaml.h（节选）
#include <winrt/Microsoft.UI.Dispatching.h>

struct TasksPage : TasksPageT<TasksPage>
{
    TasksPage();
    winrt::Windows::Foundation::IAsyncAction RefreshAsync();

private:
    winrt::Microsoft::UI::Dispatching::DispatcherQueue m_dispatcherQueue{ nullptr };
    // ... m_viewModel 等
};
```

```cpp
// TasksPage.xaml.cpp
using namespace winrt::Microsoft::UI::Dispatching;

TasksPage::TasksPage()
{
    InitializeComponent();
    // 在 UI 线程构造时抓取 WinUI 3 的 DispatcherQueue
    m_dispatcherQueue = DispatcherQueue::GetForCurrentThread();
}

winrt::Windows::Foundation::IAsyncAction TasksPage::RefreshAsync()
{
    // ── UI 线程：进入加载态 ──
    LoadingText().Text(L"Loading...");
    RefreshButton().IsEnabled(false);

    // ── 切到线程池 ──
    co_await winrt::resume_background();

    // 此处是后台线程：读文件、请求网络、解析数据（只产生纯数据，不碰 UI）
    std::vector<winrt::hstring> titles{ L"from store 1", L"from store 2" };

    // ── 切回 UI 线程：用 TryEnqueue，不要 co_await resume_foreground ──
    // 捕获 get_strong()：协程/队列回调跨越异步间隙时，保证 this 还活着
    m_dispatcherQueue.TryEnqueue(
        [strong = get_strong(), titles = std::move(titles)]() mutable
        {
            // 这个 lambda 在 UI 线程上跑
            strong->m_viewModel.LoadFrom(single_threaded_vector(std::move(titles)));
            strong->LoadingText().Text(L"Finished");
            strong->RefreshButton().IsEnabled(true);
        });
}
```

要点：

- **切回 UI 线程用 `Microsoft.UI.Dispatching.DispatcherQueue::TryEnqueue`**，在构造函数里 `GetForCurrentThread()` 存成成员
- 回调 lambda 捕获 **`get_strong()`**（对自身的强引用）：从后台切回 UI 之间对象可能已被销毁，强引用把它续命到回调跑完
- `resume_background()` 仍然照常用——它切到线程池是有 `Windows.System` 之外的通用支持的
- **后台段落只产生数据，UI 段落只消费数据**——分界写在注释里，一眼可查
- 更进一步：让 `ViewModel.LoadFrom()` 自己发通知，界面更新收敛到绑定，页面连 `LoadingText` 都不必手动改

#### 为什么 `resume_foreground` 在 WinUI 3 里不能用

`winrt::resume_foreground(...)` 这个 awaiter **只有两个重载**：接收 `Windows.System.DispatcherQueue` 和 `Windows.UI.Core.CoreDispatcher`（这两个是 UWP 时代的类型）。WinUI 3 桌面应用用的是**第三个、不同的**类型 `Microsoft.UI.Dispatching.DispatcherQueue`——`resume_foreground` **没有**它的重载。实测两种踩法：

| 你写的 | 结果 |
|--------|------|
| `resume_foreground(Microsoft::UI::Dispatching::DispatcherQueue)` | **编译不过**：没有匹配的重载 |
| `resume_foreground(Windows::System::DispatcherQueue)` | **编译过，运行时挂起**：这个队列在 WinUI 3 桌面 UI 线程上不被泵送，`co_await` 之后永远不恢复，界面停在 "Loading..." |

第二种尤其阴险——不崩、不报异常，只是不动。所以 WinUI 3 的标准做法是绕开 `resume_foreground`，直接 `TryEnqueue` 到 `Microsoft.UI.Dispatching` 的队列上。

### 32.7.2 带结果的异步与错误处理

```cpp
winrt::Windows::Foundation::IAsyncOperation<winrt::hstring>
LoadConfigAsync()
{
    co_await winrt::resume_background();
    // ... 读文件，返回结果
    co_return content;
}
```

错误用协程内 `try/catch`（投影层把 `HRESULT` 变成 `hresult_error`，见 [02 篇](./02-winrt.md) 2.9）：

```cpp
winrt::Windows::Foundation::IAsyncAction RefreshAsync()
{
    m_viewModel.IsLoading(true);
    try
    {
        auto content = co_await LoadConfigAsync();
        m_viewModel.LoadFrom(content);
    }
    catch (winrt::hresult_error const& e)
    {
        m_viewModel.ErrorMessage(e.message());
    }
    m_viewModel.IsLoading(false);
}
```

**调用异步函数要不要 `co_await`**：从事件处理器启动一个"发后不管"的任务（如刷新）可以不等待，但要保证：它不会在页面销毁后还访问页面成员（必要时用弱引用 `winrt::make_weak` / `winrt::weak_ref`）。需要结果、需要异常传播的调用必须 `co_await`。

### 32.7.3 常见异步错误清单

| 错误 | 后果 | 正确做法 |
|------|------|---------|
| 后台线程直接改控件属性 | 抛跨线程异常 | 用 `DispatcherQueue::TryEnqueue` 切回 UI 线程再改（见 32.7.1，别用 `resume_foreground`） |
| 后台段落持有 UI 对象引用 | 生命周期/线程边界混乱 | 后台只处理纯数据 |
| 忘记切回 UI 线程就发状态通知 | 绑定不刷新或崩溃 | 通知必须在 UI 线程触发 |
| 异步重入（连点按钮） | 状态竞争、结果错乱 | 期间 `IsEnabled(false)` 或做重入检查 |
| `co_await` 挂起后页面被销毁 | 悬空访问崩溃 | 弱引用捕获，恢复时检查存活 |

### 32.7.x 事件路线与绑定路线的分界（四工程的裁决）

四个功能工程全走**事件直写**（Click/TextChanged/ValueChanged → 处理器改状态行）——这是刻意的教学立场：控件机制先用显式代码看清（谁触发、改了什么、界面怎么知道）。**切换到绑定路线的信号**：①状态被多处消费（一个"已选数量"要喂按钮可用性+计数行+标题）——事件路线要手写三处刷新，绑定改一处自动流；②状态属于数据而非 UI（文档内容、任务列表）——事件路线让页面代码持有业务状态，越写越厚。**TaskFlow（35 章）就是切换样**：同是"列表+输入+持久化"，它用 INPC 集合让勾选自动流进计数——对照 DataExplorer 的事件版过滤管线，两版的分界读代码即懂。教学顺序（先事件后绑定）不是贬低绑定——**没写过刷新遗漏 bug 的人，体会不到绑定解决的是什么**。

### 32.7.y 协程纪律的浓缩版（四工程实测汇编）

- `co_await` 后世界已变：await 回来先判空/重查（页面可能销毁、页签可能已关）
- 事件处理器变协程：捕获一律按值（`auto tab = args.Tab()`）
- 长循环动画：每帧 `resume_after` 让出 UI 线程 + `get_strong()` 续命（ScratchPad 保存动画）
- 不 lock：UI 线程协程没有真并发，锁只会死锁自己
- fire-and-forget 的 `(void)coroutine();` 要接异常（winrt::fire_and_forget 或 try/catch 包全），否则异常吞进虚空

## 32.8 一句话总结

> 绑定让界面自动跟随状态，ViewModel 让状态有唯一权威来源，异步让耗时工作不卡 UI——三者合起来，就是把"界面"从"状态存储器"降级成"状态投影"，这是 WinUI 3 工程化的核心。



## 32.9 值转换器：IValueConverter 与它的两条使用路线

x:Bind **没有内置转换**——WPF 时代 `{Binding IsChecked, Converter=...}` 之外还能指望的 bool→Visibility 隐式行为，在 x:Bind 里不存在。绑定值需要"翻译"时有两条路线。

### 路线一：函数绑定（首选）

x:Bind 可以直接绑页面/VM 上的**函数**（8.6 的推广）：

```xml
<TextBlock Text="{x:Bind FormatCount(ViewModel.TaskCount), Mode=OneWay}"/>
```

```cpp
hstring MainWindow::FormatCount(int32_t count)
{
    return count == 0 ? L"no tasks" : to_hstring(count) + L" tasks";
}
```

编译期生成订阅，类型安全，无注册步骤——**单页面内的一次性格式化首选它**。

### 路线二：IValueConverter（跨页复用的转换逻辑）

元数据形状（1.8 核对）：`Microsoft.UI.Xaml.Data.IValueConverter` 的两个方法都是
`(Object value, TypeName targetType, Object parameter, String language) -> Object`。

```idl
// 与 ViewModel 同一个 .idl；[default_interface] 不能省（无自有成员的类不会自动生成默认接口）
[default_interface]
runtimeclass DoneToOpacityConverter : Microsoft.UI.Xaml.Data.IValueConverter
{
    DoneToOpacityConverter();
}
```

```cpp
Windows::Foundation::IInspectable DoneToOpacityConverter::Convert(
    IInspectable const& value, Interop::TypeName const&,
    IInspectable const&, hstring const&)
{
    // 装箱进出：bool 路径装箱成 IReference<bool>，解包后业务转换，再装回去
    bool done = value.as<Windows::Foundation::IReference<bool>>().Value();
    return box_value(done ? 0.55 : 1.0);
}
// ConvertBack：OneWay 用途直接 throw hresult_not_implemented()
```

XAML 侧两步：资源字典注册 + 绑定引用：

```xml
<Grid.Resources>
    <vm:DoneToTextConverter x:Key="DoneToText"/>
    <vm:DoneToOpacityConverter x:Key="DoneToOpacity"/>
</Grid.Resources>
...
<StackPanel Opacity="{Binding Done, Converter={StaticResource DoneToOpacity}}">
    <CheckBox Content="{x:Bind Title, Mode=OneWay}" IsChecked="{x:Bind Done, Mode=TwoWay}"/>
    <TextBlock Text="{Binding Done, Converter={StaticResource DoneToText}}"/>
</StackPanel>
```

### 实测坑：x:Bind + Converter 需要 FrameworkElement 根

在 **Window 直接作 x:Class 根**的工程里（本例），`{x:Bind Done, Converter=...}` 编不过——
生成代码里 `SetConverterLookupRoot` 收 `FrameworkElement`，而 Window 不是。**x:Bind+Converter
只在 Page/UserControl 根（及其 DataTemplate）里可用**；Window 根的工程走经典
`{Binding Converter=}`（运行期查找，任意根可用，本例即此）。

### 选择矩阵

| 场景 | 路线 |
|------|------|
| 单页格式化 | 函数绑定 |
| 跨页/跨工程复用的转换 | IValueConverter |
| Window 根工程 | {Binding Converter}（x:Bind 路线不可用） |
| 双向转换 | IValueConverter + 实现ConvertBack（慎用：反向语义易错） |

运行时证据：`.smoke/32-binding-mvvm/converter/click-2.png`——Refresh 后列表两行（Buy milk / Walk dog），勾选首行后该行**变暗**（Opacity 转换器）并出现强调色 **"done!"**（文本转换器），次行原样。
---

上一篇：[31 窗口与外壳](./31-window-shell.md) ｜ 下一篇：[33 主题资源与交付](./33-theming-packaging.md)
