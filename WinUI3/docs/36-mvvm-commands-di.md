# 36. MVVM 进阶：命令、依赖注入与导航服务

> 对应《Learn WinUI 3》第 3、4 章。书里用 CommunityToolkit.Mvvm（源生成器 ObservableProperty/RelayCommand）和 Microsoft.Extensions.Hosting 的 DI 容器——这两样都是 C# 专属。本章把同样的三个问题在 C++/WinRT 里解一遍：**动作怎么从视图送进 ViewModel（命令）**、**对象从哪里创建、依赖怎么送进去（DI）**、**ViewModel 怎么发起页面跳转而不认识 Frame（导航服务）**。

[32 章](32-binding-mvvm.md)讲了绑定与可观察对象；本章是它的续篇。两章合起来覆盖书 3-4 章的全部概念，但工具箱不同：

| 书（C#） | 本教程（C++/WinRT） |
|---|---|
| `RelayCommand : ICommand` 手写实现 | `XamlUICommand` / `StandardUICommand`（框架自带） |
| CommunityToolkit.Mvvm `[RelayCommand]` 源生成 | 不存在——宏/模板手写，或直接函数绑定 |
| `Microsoft.Extensions.Hosting` DI 容器 | 手写构造注入 + 服务定位器（100 行以内） |
| `INavigationService` + DI 容器注册页面 | 同名接口的 C++ 翻译：`std::unordered_map<hstring, ...>` + `Frame` |

## 36.1 命令三条路线，先给结论

C++/WinRT 里"按钮点击执行 ViewModel 逻辑"有三条路，**优先级从上到下**：

1. **x:Bind 函数绑定**（[32.6](32-binding-mvvm.md)）：`Click="{x:Bind ViewModel.AddItem}"`。编译期检查签名，零额外类型。**本教程四个功能工程全走这条**。
2. **XamlUICommand**：命令对象有独立身份（Label/图标/快捷键），可被按钮、菜单项、手势共用。需要 CanExecute 精细控制或跨控件复用命令时用。
3. **StandardUICommand**：预设图标的 XamlUICommand 子类（Cut/Copy/Paste/Delete...），一行构造。

书里 RelayCommand 是唯一路线，因为 C# 的 `{Binding}` 只认 `ICommand` 属性；x:Bind 函数绑定在 C# 里同样可用（书 4.3 自己也用了）。**C++ 里没有理由从命令开始**——函数绑定少一层间接、少一堆样板。但命令有它不可替代的场景，就是本章的主题。

## 36.2 XamlUICommand：框架自带的 ICommand

WPF/UWP 教科书让你手写 `RelayCommand`（书 3.5.1 整页代码）；WinUI 3 里不用——`Microsoft.UI.Xaml.Input.XamlUICommand` 已经是 `ICommand` 的官方实现，把执行逻辑做成**事件**而不是委托字段：

```cpp
// examples/32-binding-mvvm/MainWindow.xaml.cpp（36 章扩展段）
m_completeAllCommand = Microsoft::UI::Xaml::Input::XamlUICommand();
m_completeAllCommand.Label(L"Complete all");                  // 按钮自动显示的文字
auto icon = Microsoft::UI::Xaml::Controls::FontIconSource();
icon.Glyph(L"");                                       // CheckMark
m_completeAllCommand.IconSource(icon);                       // 按钮自动显示的图标
m_completeAllCommand.ExecuteRequested(                       // 对应 ICommand.Execute
    { this, &MainWindow::OnCompleteAllExecute });
m_completeAllCommand.CanExecuteRequested(                     // 对应 ICommand.CanExecute
    { this, &MainWindow::OnCanCompleteAll });

auto accelerator = Microsoft::UI::Xaml::Input::KeyboardAccelerator();
accelerator.Key(Windows::System::VirtualKey::K);
accelerator.Modifiers(Windows::System::VirtualKeyModifiers::Control);
m_completeAllCommand.KeyboardAccelerators().Append(accelerator);  // Ctrl+K 挂在命令上

CompleteAllButton().Command(m_completeAllCommand);            // 消费者只认 Command
```

XAML 侧按钮一个字都不用写内容：

```xml
<!-- examples/32-binding-mvvm/MainWindow.xaml -->
<StackPanel Orientation="Horizontal" Spacing="8">
    <Button x:Name="CompleteAllButton" />
    <Button x:Name="DeleteUiButton" />
</StackPanel>
```

命令的价值全在这段对照里：**Label/IconSource/快捷键是命令的属性**。同一个命令挂到 Button、MenuFlyoutItem、CommandBar 的 AppBarButton 上，文字图标快捷键自动一致——这正是书 3.5 想用命令达成的解耦，只是 C++ 里由控件树免费替你做了。

### 事件签名（实测形状）

```cpp
void OnCompleteAllExecute(
    IInspectable const& sender,
    Microsoft::UI::Xaml::Input::ExecuteRequestedEventArgs const& args);

void OnCanCompleteAll(
    IInspectable const& sender,
    Microsoft::UI::Xaml::Input::CanExecuteRequestedEventArgs const& args)
{
    // CanExecute 是"写回"接口：结果通过 args 交还命令，不是返回值
    args.CanExecute(m_viewModel.TaskCount() > 0);
}
```

两个签名都与 `TypedEventHandler<...>` 对齐，`{ this, &MainWindow::OnXxx }` 直接挂。**CanExecuteRequestedEventArgs.CanExecute(bool) 是赋值不是返回**——C# 里 `CanExecuteChanged` + 方法返回 bool 的习惯在这里要倒过来写。

### StandardUICommand：预设命令一行流

```cpp
m_deleteCommand = Microsoft::UI::Xaml::Input::StandardUICommand(
    Microsoft::UI::Xaml::Input::StandardUICommandKind::Delete);
m_deleteCommand.ExecuteRequested({ this, &MainWindow::OnDeleteExecute });
DeleteUiButton().Command(m_deleteCommand);
```

Delete/Cut/Copy/Paste/Save/Undo... 预设好图标与本地化标签（枚举在 1.8 投影里有完整集合）。它继承 XamlUICommand，所以 ExecuteRequested/CanExecuteRequested/KeyboardAccelerators 全部同样可用。

## 36.3 CanExecute：没有 CommandManager 的世界

书 3.5.2 的流程是：`SelectedMediaItem` 变化时手动调用 `RaiseCanExecuteChanged()`。C# 开发者常以为 WPF 的 `CommandManager` 会自动重查 CanExecute——**WinUI 没有 CommandManager，谁都不会替你重查**。按钮的启用态只在两个时机会刷新：命令属性被赋值的瞬间，和你调用 `NotifyCanExecuteChanged()` 的时候。

所以完整闭环是三件套（32 例实况）：

```cpp
// ① CanExecuteRequested 里做判定
args.CanExecute(m_viewModel.TaskCount() > 0);

// ② 监听数据源变化（VM 的 INPC）
m_vmPropertyChangedToken = m_viewModel.PropertyChanged(
    [this](auto const&, Data::PropertyChangedEventArgs const& e)
{
    if (e.PropertyName() == L"TaskCount" || e.PropertyName() == L"Tasks")
    {
        // ③ 手动通知重查
        m_completeAllCommand.NotifyCanExecuteChanged();
    }
});
```

漏掉第 ③ 步的典型症状：按钮启用态停留在初次判定，明明列表空了"全选"还亮着。函数绑定路线没有这个问题——按钮直接绑 `IsEnabled="{x:Bind ViewModel.HasSelection, Mode=OneWay}"`（[37 章](37-sqlite-storage.md)的 MediaLibrary 就这么写），一条 INPC 链自然刷到位。**这也是四工程偏爱函数绑定+IsEnabled 的原因：少一个要手动保持同步的机制**。

## 36.4 x:Bind 直绑事件：没有 Command 属性的控件怎么办

书 4.3 的问题是：`ListView.DoubleTapped` 没有 `Command` 属性，怎么把事件送进 ViewModel？C# 的两条路（EventToCommandBehavior 行为、x:Bind 事件绑定）在 C++ 里只剩一条——**行为库是 .NET 的，x:Bind 事件绑定原生可用**：

```xml
<ListView DoubleTapped="{x:Bind ViewModel.ListViewDoubleTapped}" .../>
```

```cpp
// ViewModel 上公开一个签名严格匹配的方法
void ListViewDoubleTapped(
    IInspectable const& sender,
    Microsoft::UI::Xaml::Input::DoubleTappedRoutedEventArgs const& args);
```

规则与 [32.6](32-binding-mvvm.md) 的函数绑定相同：**签名必须与事件的委托逐参数对上**，编译期即检查。注意两点：

- 事件参数类型会把 `Microsoft.UI.Xaml.Input` 等命名空间拖进 ViewModel 的头文件——ViewModel 从此"认识"UI 类型，这正是书 4.3 承认的妥协（解耦不彻底）。可以只在签名里用，不往成员里存。
- **解析期/析构期触发的事件**（SelectionChanged、ValueChanged 一族，见 [12.5](12-slider-progress.md) 深坑）走这条路要格外小心：方法体里的每个成员都要经得起"控件尚未建好/已经拆掉"的时刻。判空是铁律。

书的做法（`IsHitTestVisible=False` 让双击冒泡到行）在 C++ 同样适用，属于 XAML 层技巧，与语言无关。

## 36.5 依赖注入：.NET 有容器，C++ 有构造函数

书 4.1-4.2 的 DI 讲了三层：概念（IoC）、容器（`Host.CreateDefaultBuilder`）、生命周期（Transient/Singleton）。C++/WinRT 没有官方容器——但 DI 本身是设计模式，不依赖框架。**结论先行：小中型 C++/WinRT 应用，手写构造注入 + 一个 App 级服务定位器就够了，100 行以内**。

### 概念不变，工具换掉

| 书（.NET） | C++/WinRT 对应物 |
|---|---|
| `IServiceCollection` 注册 | `App` 类里的 `std::shared_ptr` 成员 + 初始化函数 |
| 构造函数注入 `MainViewModel(INavigationService, IDataService)` | C++ 构造函数收 `std::shared_ptr<...>` / `winrt::com_ptr<...>` |
| `GetService<T>()` 解析 | 直接调工厂函数或读 App 静态成员 |
| Transient / Singleton 生命周期 | 每次构造 / `shared_ptr` 单例成员 |

手写的最小形态（本教程 35 章 TaskFlow 与 37 章 MediaLibrary 的实际结构）：

```cpp
// App.xaml.h —— 服务定位器的全部
struct App : AppT<App>
{
    static MediaStore::LibraryStore& Store();     // 单例：数据库连接
    // ...
};

// ViewModel 构造时注入（书 4.4.6 的 MainViewModel(INavigationService, IDataService) 直译）
LibraryViewModel::LibraryViewModel()
{
    m_store = App::Store();                       // 或作为构造参数传入
}
```

要不要更正式的容器？Boost.DI 已停更、Google Fruit 可用但引入成本高。**裁决：教程不做**。C++ 的构造注入在编译期就把依赖图定死，类型安全比运行时容器强；真正的损失只有"运行时换实现"（测试替身）——需要 mock 时把 Store 做成抽象基类 + 两个实现，工厂函数按配置返回其一，仍然是手写量级。

### 一个 C++ 特有议题：对象生命周期

C# 的 DI 容器替你持有对象、决定何时释放。C++/WinRT 里这件事要自己想清楚，三条规则：

1. **WinRT 投影类型（ViewModel、Service 若为 runtimeclass）**：引用计数，事件订阅（PropertyChanged、事件到 VM 方法）会造成 **ViewModel ↔ View 强引用环**——窗体持 VM，VM 的事件表持有窗体委托。长命应用用 `winrt::weak_ref` 或事件 `auto_revoke_t`（34 例的 `m_notificationRevoker` 就是这个用途）。
2. **纯 C++ 服务层**（`LibraryStore`）：`std::shared_ptr` 单例挂在 App 上，随进程退出释放。
3. **后台线程碰服务**：先确认服务自己线程安全（sqlite 用 FULLMUTEX 打开），或把访问钉在一个线程上。

## 36.6 导航服务：让 ViewModel 发起跳转而不认识 Frame

书 4.4 的架构值得原样学习：ViewModel 不能持有 `Frame`（UI 类型），但删除按钮的回调里要"跳回列表页"。解法是抽一个接口：

```
INavigationService { NavigateTo(page, parameter); GoBack(); }
```

C++ 的翻译没有容器参与，结构反而更简单。**35 章 TaskFlow 已经实现了它的外壳**（NavigationView + 页面注册），37 章 MediaLibrary 是单页不需要；这里给出把两者接起来的参考形状：

```cpp
// Services/NavigationService.h —— 书 4.4.4 的 C++ 直译
class NavigationService
{
public:
    explicit NavigationService(Microsoft::UI::Xaml::Controls::Frame frame)
        : m_frame{ frame } {}

    void Configure(winrt::hstring const& name,
                   winrt::Microsoft::UI::Xaml::Interop::TypeName const& type)
    {
        m_pages[name] = type;    // 重复注册在 debug 下 assert
    }

    void NavigateTo(winrt::hstring const& page, Windows::Foundation::IInspectable const& parameter)
    {
        if (auto it = m_pages.find(page); it != m_pages.end())
        {
            m_frame.Navigate(it->second, parameter);
        }
    }

    void GoBack()
    {
        if (m_frame.CanGoBack()) { m_frame.GoBack(); }
    }

private:
    Microsoft::UI::Xaml::Controls::Frame m_frame{ nullptr };
    std::unordered_map<winrt::hstring, winrt::hstring,
                       winrt::impl::hash_hstring> m_pages;   // TypeName 可存字符串形式
};
```

接线在 App.OnLaunched（书 4.4.6 的 RegisterServices 直译）：

```cpp
void App::OnLaunched(LaunchActivatedEventArgs const&)
{
    m_window = make<MainWindow>();
    auto rootFrame = Microsoft::UI::Xaml::Controls::Frame{};
    m_navigation = std::make_shared<NavigationService>(rootFrame);
    m_navigation->Configure(L"TaskList", xaml_typename<winrt::TaskFlow::TaskListPage>());
    m_navigation->Configure(L"Settings", xaml_typename<winrt::TaskFlow::SettingsPage>());
    m_window.Content(rootFrame);
    rootFrame.Navigate(xaml_typename<winrt::TaskFlow::TaskListPage>(), nullptr);
    m_window.Activate();
}
```

### 参数的传递与接收（书 4.4.7）

`Frame.Navigate(type, parameter)` 的 parameter 是 `IInspectable`。整数要装箱：`box_value(42)`；接收页面重写 `OnNavigatedTo`：

```cpp
void TaskListPage::OnNavigatedTo(Microsoft::UI::Xaml::Navigation::NavigationEventArgs const& e)
{
    if (auto boxed = e.Parameter().try_as<Windows::Foundation::IReference<int32_t>>())
    {
        int32_t id = boxed.Value();
        // ViewModel 初始化（书 InitializeItemDetailData 的位置）
    }
}
```

**注意 `try_as` 而不是 `as`**：直接启动时 parameter 是 `nullptr`，`as` 会抛。书里 `(int)e.Parameter` 的强转写法在 C++ 里对应这条判空链。

### 该不该用 Frame 导航？C++ 视角的裁决

书采用 Frame + 多 Page 是 UWP 传统。本教程四工程的实况：**SettingsHub/TaskFlow 用 NavigationView + 页面切换，ScratchPad/DataExplorer/MediaLibrary 单页或 Tab**，没有一个是 Frame 栈导航。桌面应用的"返回栈"语义（GoBack）远不如移动端自然——桌面惯例是左侧导航切换、无栈。**导航服务的抽象本身值得留**（ViewModel 不碰 UI 类型），Frame 只是它的一种后端；NavigationView 的 `SelectionChanged → 切 Content` 是更常见的后端。

## 36.7 MVVM 工具箱全景：C++ 能用什么

书 3.2 盘点了三大 C# MVVM 框架。C++/WinRT 侧的诚实盘点：

| 工具 | 状态 | 替代 |
|---|---|---|
| CommunityToolkit.Mvvm | .NET 专属，**不可用** | 手写 INPC 基类（32 章 30 行）+ 函数绑定 + XamlUICommand |
| Prism（DI/EventAggregator/导航） | C# 专属 | 手写服务定位器 + 事件或消息结构 |
| MVVMCross | C# 专属 | 同上 |
| Windows Community Toolkit 控件 | 多数 NU1202（[20 章](20-datagrid-itemsrepeater.md)实测） | 自制路线（见各控件章） |

这不是劣势清单。C++/WinRT 的 MVVM 样板量比 C# 少两个来源：x:Bind 编译期绑定不需要 DataContext 管道，XamlUICommand 免掉 RelayCommand 手写。剩下的 INPC 样板（每个属性 getter/setter/字段三件套），32 章的宏方案或直接写都可控。

## 36.8 实测坑位（本章新增）

1. **`args.CanExecute(...)` 是写回不是返回值**——C# 习惯直接照搬会编译失败。
2. **投影裁剪再坑一次**：`CppWinRTOptimized=true` 的工程（32 例原配置）用 `XamlUICommand::Label/IconSource` 报 **C3779"要使用返回 auto 的函数必须先定义"**——`Microsoft.UI.Xaml.Input` 的消费函数定义没进 TU。修法：pch 显式 `#include <winrt/Microsoft.UI.Xaml.Input.h>`（[27.4](27-custom-controls.md) 同族坑）。
3. **字体图标字形写进源码要用 `` 转义**——私用区字符直接粘贴会在终端/差异工具里隐形，编辑时极易丢失。
4. **NotifyCanExecuteChanged 无人代劳**：WinUI 无 CommandManager，INPC → 命令刷新这条链要自己订阅。
5. `KeyboardAccelerator` 挂在命令上时，**快捷键只在命令的消费者获得键盘焦点树内生效**——窗口级全局快捷键仍要 Window 级 KeyboardAccelerator（ScratchPad 的 Ctrl+S 形态，见 [09](09-textbox.md)）。
6. **DI 在 C++ 的真坑是生命周期不是装配**：事件订阅造成的引用环（36.5 节第 1 条）不会在 C# 里炸（GC 收环），在 C++ 里会实打实泄漏——`weak_ref`/`auto_revoke_t` 是纪律不是可选项。

## 36.9 练习与思考

1. 把 32 例的 `DeleteUiButton` 从 StandardUICommand 换成 XamlUICommand，图标自选，保持行为不变。哪几行是必须保留的？
2. 给 `CompleteAllCommand` 加第二个消费者（MenuFlyoutItem），验证 Label/快捷键自动一致——这正是命令优于函数绑定的一点。
3. `OnCanCompleteAll` 里把判定改成 `OutstandingCount() > 0`（ViewModel 已提供），需要在哪些时机调 `NotifyCanExecuteChanged()` 才能保证启用态永远正确？（提示：勾选任务会改 OutstandingCount 但不改 TaskCount。）
4. 书 4.4 的 NavigationService 用 `ConcurrentDictionary` 存页面注册表。C++ 版本为什么可以安全地用普通 `unordered_map`？（提示：注册只发生在哪条线程。）
5. 思考：如果 ViewModel 需要弹 ContentDialog（[24.2](24-dialogs-flyouts.md) 要求 XamlRoot），服务该怎么设计才能不让 ViewModel 认识 UI 类型？（书 8 章的 NotificationShared/MainPage.NotifyUser 是一种绕法。）
