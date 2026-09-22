# 3. XAML 机制：从标记到运行代码

上一篇讲清了 WinRT 对象模型，这一篇讲清 XAML——不是"它长什么样"（网上到处都是），而是"它怎么工作"。理解了编译流程和属性系统，你看任何 XAML 报错都能定位到原因。

## 3.1 XAML 文件的生命周期

一个 `MainWindow.xaml` 从源码到界面，经过两个阶段：

### 3.1.1 编译期：XAML 编译器生成代码

构建时，XAML 编译器（XamlCompiler）解析标记，生成真实的 C++ 代码：

```text
MainWindow.xaml
  ↓ XAML 编译器
Generated Files/
├── MainWindow.g.h        ← 生成的类声明：InitializeComponent 声明、
│                            x:Name 访问器、x:Bind 绑定函数
├── MainWindow.g.cpp      ← InitializeComponent 的实现：构建对象树、
│                            连接事件、注册 XamlTypeInfo
└── XamlTypeInfo.g.h/.cpp ← 类型信息，供运行时反射（样式、绑定解析）
```

也就是说，这段 XAML：

```xml
<StackPanel>
    <TextBlock x:Name="StatusText" Text="Ready" />
    <Button Content="Click me" Click="OnClick" />
</StackPanel>
```

在生成的代码里，本质等价于（示意）：

```cpp
// 生成代码示意，非原文
auto panel = winrt::Microsoft::UI::Xaml::Controls::StackPanel();
auto text  = winrt::Microsoft::UI::Xaml::Controls::TextBlock();
text.Text(L"Ready");
panel.Children().Append(text);
auto button = winrt::Microsoft::UI::Xaml::Controls::Button();
button.Content(winrt::box_value(L"Click me"));
button.Click({ this, &MainWindow::OnClick });   // 事件连接
```

**XAML 和 C++ 不是两个世界**：XAML 是"会被翻译成对象创建代码的源文件"，和你的 `.h/.cpp` 一起编译进同一个类。

### 3.1.2 运行期：InitializeComponent

类的构造函数里那行 `InitializeComponent()` 执行的就是上面生成的代码：

```cpp
MainWindow::MainWindow()
{
    InitializeComponent();   // 构建界面树、连接事件、应用资源
}
```

执行完后，`x:Name` 声明的控件都以真实对象的形式挂在界面上，可以立刻访问。

## 3.2 x:Class：XAML 与 C++ 的配对契约

每个 XAML 文件根元素上有 `x:Class`：

```xml
<Window
    x:Class="MyApp.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
```

含义：这个 XAML 描述的界面树，属于命名空间 `MyApp` 里的 runtimeclass `MainWindow`。XAML 编译器据此：

- 生成 `MainWindowT<>` 模板基类（你的 `implementation::MainWindow` 继承它）
- 把你在 XAML 里写的 `Click="OnClick"` 连接到 `implementation::MainWindow` 的同名成员函数
- 把 `x:Name` 生成为该类的访问器

**`x:Class` 名字必须和 IDL 里声明的 runtimeclass 完全一致**，否则报"无法找到类型"。

## 3.3 x:Name：访问器，不是变量

```xml
<TextBlock x:Name="StatusText" Text="Ready" />
```

编译器为它在生成头文件里产生一个**访问器函数**：

```cpp
// 生成的代码
winrt::Microsoft::UI::Xaml::Controls::TextBlock StatusText() const;
```

所以在 C++ 里访问控件的写法是**调用函数**：

```cpp
StatusText().Text(L"done");              // 读属性也要调用
auto t = StatusText().Text();            // t 是 winrt::hstring
```

注意两个易错点：

- 控件属性大多是**方法对**：`Text()` 读取，`Text(value)` 写入。C++/WinRT 用重载代替 C# 的 property 语法。
- `x:Name` 只在**声明它的那个 XAML 文件对应的类里**可见。跨页面访问控件是设计错误——需要共享的数据应该走 ViewModel（见 [32-binding-mvvm.md](./32-binding-mvvm.md)）。

## 3.4 XAML 语法要素

### 3.4.1 特性语法与属性元素语法

简单值用特性（attribute）：

```xml
<Button Content="Save" Width="120" />
```

复杂值（对象、多行文本、集合）用属性元素（property element）：

```xml
<Button>
    <Button.Content>
        <StackPanel>
            <FontIcon Glyph="&#xE74E;" />
            <TextBlock Text="Save" />
        </StackPanel>
    </Button.Content>
</Button>
```

### 3.4.2 附加属性（Attached Property）

```xml
<TextBlock Grid.Row="1" Grid.Column="2" />
```

`Grid.Row` 不是 `TextBlock` 自己的属性，而是 `Grid` 定义、由容器读取的布局信息。语法 `容器名.属性名`。这就是依赖属性系统的跨类型扩展能力。

### 3.4.3 标记扩展（Markup Extension）

`{...}` 语法是标记扩展，在编译/加载期被求值，不是字面字符串：

| 扩展 | 作用 |
|------|------|
| `{StaticResource Key}` | 从资源字典查找一次，之后不变 |
| `{ThemeResource Key}` | 查找资源，**主题切换时自动重取**（见 [33 篇](./33-theming-packaging.md)） |
| `{x:Bind Path=..., Mode=...}` | 编译期绑定（WinUI 3 首选） |
| `{Binding Path=...}` | 运行期绑定（遗留，一般不用） |
| `{TemplateBinding X}` | 控件模板内引用模板宿主的属性 |

## 3.5 依赖属性系统

XAML 控件的属性（`Width`、`Text`、`Background`…）不是普通 C++ 成员变量，而是**依赖属性（Dependency Property）**。为什么要有这套系统：

- **内存**：海量控件的属性大多取默认值，依赖属性只在被设置时存储
- **继承**：`FontSize`、`DataContext` 等可以沿可视树向下继承
- **样式/主题**：Style 的 Setter、ThemeResource 都作用于依赖属性
- **绑定**：绑定引擎观察依赖属性的变化
- **动画**：动画系统直接驱动依赖属性

在 C++/WinRT 里自定义依赖属性（一般只在写自定义控件时才需要）：

```cpp
// 声明
static winrt::Microsoft::UI::Xaml::DependencyProperty s_titleProperty;

// 注册（通常在类构造前的静态初始化中）
s_titleProperty = winrt::Microsoft::UI::Xaml::DependencyProperty::Register(
    L"Title",
    winrt::xaml_typename<winrt::hstring>(),
    winrt::xaml_typename<winrt::MyApp::MyControl>(),
    winrt::Microsoft::UI::Xaml::PropertyMetadata{ winrt::box_value(L"") });

// 读/写一律经过依赖属性系统，不能绕过
winrt::hstring Title()
{
    return winrt::unbox_value<winrt::hstring>(GetValue(s_titleProperty));
}
void Title(winrt::hstring const& value)
{
    SetValue(s_titleProperty, winrt::box_value(value));
}
```

工程含义：**凡是 XAML 能设置的属性，都必须走依赖属性**。这也是为什么 ViewModel 层不用依赖属性——它不参与 XAML 布局，用 `INotifyPropertyChanged` 就够了（两种"可观察"机制的区别见 8 篇）。

## 3.6 x:Bind 与 Binding：编译期绑定 vs 运行期绑定

WinUI 3 有两种数据绑定，区别是本质性的：

| | `{x:Bind}` | `{Binding}` |
|---|---|---|
| 求值时机 | **编译期**，生成真实 C++ 代码 | 运行期，按字符串路径反射查找 |
| 类型检查 | 编译期检查，写错直接编译失败 | 运行期静默失败（绑定输出空） |
| 性能 | 接近直接调用 | 反射开销 |
| 默认 Mode | `OneTime` | `OneWay` |
| 数据上下文 | 绑定到**声明它的类自身**（页面/窗口的成员） | 绑定到 `DataContext` |
| 集合模板中 | 需要 `x:DataType` 声明项类型 | 不需要 |

**WinUI 3 里一律优先用 `x:Bind`**。`Binding` 主要为兼容遗留 XAML 存在。

`x:Bind` 的关键理解：它绑定的是**页面类的成员路径**，不是 DataContext：

```xml
<!-- 绑定到 MainWindow/Page 类的 ViewModel() 属性 -->
<TextBlock Text="{x:Bind ViewModel.Status, Mode=OneWay}" />

<!-- 函数绑定到事件：被绑方法的签名必须与事件委托一致 -->
<Button Click="{x:Bind ViewModel.AddTask}" />

<!-- 命令对象走 Command 属性（参数是 IInspectable），不要绑到事件上 -->
<Button Content="Add" Command="{x:Bind ViewModel.AddTaskCommand}" />
```

函数绑定的约束：**方法签名要和事件委托逐参数对得上**。`Click` 的委托是 `TypedEventHandler<IInspectable, RoutedEventArgs>`，所以被绑方法必须收这两个参数（或不带参数——投影层允许省略尾部参数）；`ICommand.Execute(object)` 只有一个参数，绑到 `Click` 上会直接编译失败。

`Mode` 是必须主动想清楚的事：

```xml
<!-- OneTime：初始化读一次（x:Bind 默认） -->
<TextBlock Text="{x:Bind AppTitle}" />

<!-- OneWay：源变化时刷新界面，要求源实现 INotifyPropertyChanged -->
<TextBlock Text="{x:Bind ViewModel.Status, Mode=OneWay}" />

<!-- TwoWay：界面改动也写回源 -->
<TextBox Text="{x:Bind ViewModel.Query, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" />
```

常见坑：写了 `Mode=OneWay` 但 ViewModel 忘了实现 `INotifyPropertyChanged`，界面永远不刷新且**没有任何报错**——因为 OneWay 的通知是源主动推送的。排查思路见 [32 篇](./32-binding-mvvm.md)。

## 3.7 资源系统与查找顺序

资源字典存储可复用的对象（画刷、样式、字符串），按键引用：

```xml
<Page.Resources>
    <SolidColorBrush x:Key="AccentBrush" Color="#0063B1" />
</Page.Resources>

<Border Background="{StaticResource AccentBrush}" />
```

查找顺序是沿树向上：

```text
控件自身 Resources
  ↓ 逐层向上经过父容器
页面 Resources
  ↓
App.xaml 的 Application.Resources
  ↓
框架内置主题资源（ThemeDictionaries：Light/Dark/HighContrast）
```

找到第一个匹配的键就停止。含义：

- 页面资源可以覆盖应用资源，实现局部定制
- 任何资源最终都能回退到框架主题资源——这就是 Fluent 控件"自动适配深浅色"的机制
- `ThemeResource` 和 `StaticResource` 的区别在于主题切换时是否重新求值，细节在 [33 篇](./33-theming-packaging.md)

## 3.8 可视树与逻辑树

XAML 定义的是**逻辑树**（元素嵌套关系），渲染时框架会展开出更深的**可视树**（控件内部模板结构）。例如一个 `Button` 在可视树里包含边框、内容呈现器等内部部件。

工程上需要知道这件事的场景：

- `VisualTreeHelper` / `FindName` 类操作作用于可视树
- 控件模板（ControlTemplate）重定义的是可视树
- `ContentDialog`、`Flyout` 等弹层会被挂到弹层根，而不是声明位置——这就是 `ContentDialog` 必须设置 `XamlRoot` 的原因（见 [24 篇](./24-dialogs-flyouts.md)）

## 3.9 DataTemplate 与 x:DataType

列表控件的每一项长什么样，由 `DataTemplate` 描述。用 `x:Bind` 时必须声明项类型：

```xml
<Page ... xmlns:vm="using:MyApp">
    <ListView ItemsSource="{x:Bind ViewModel.Tasks, Mode=OneWay}">
        <ListView.ItemTemplate>
            <DataTemplate x:DataType="vm:TaskItem">
                <TextBlock Text="{x:Bind Title, Mode=OneWay}" />
            </DataTemplate>
        </ListView.ItemTemplate>
    </ListView>
</Page>
```

`x:DataType` 告诉编译器每一项的类型，于是模板内的 `x:Bind` 也变成编译期检查、生成直接调用的代码。`vm:TaskItem` 必须是 IDL 里声明的 runtimeclass（比如实现 `INotifyPropertyChanged` 的数据对象），不能是普通 `struct`——因为绑定要跨 WinRT 边界调用它的属性。

前缀名（`vm` / `local` / 任意）随你起，但它映射的必须是 **runtimeclass 的命名空间**，也就是 IDL 里 `namespace MyApp { ... }` 那个名字——和 `.idl` 文件放在哪个目录（`Models/`、`ViewModels/`）无关。本教程统一用 `xmlns:vm="using:MyApp"`。

---

上一篇：[02-winrt.md](./02-winrt.md) ｜ 下一篇：[04-first-app.md](./04-first-app.md)
