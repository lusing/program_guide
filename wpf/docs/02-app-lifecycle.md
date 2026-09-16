# 02 · 应用骨架与生命周期：App.xaml 在跑什么

> 对应示例：`examples/01_hello_wpf`

## 1. 两对文件，一棵对象树

`dotnet new wpf` 给你四个文件，分成两对：

```text
App.xaml          应用级 XAML：资源字典、启动配置
App.xaml.cs       App 的分部类：你的启动/退出逻辑
MainWindow.xaml   窗口级 XAML：界面对象树
MainWindow.xaml.cs MainWindow 的分部类：事件处理
```

"分部类"（partial class）是理解 XAML 的钥匙：你写的 `MainWindow.xaml.cs` 只有事件处理，界面部分由 XAML 编译器生成到另一个分部文件（`MainWindow.g.cs`，obj 目录下）里，编译时合成一个类。所以 `MainWindow.xaml` 里写的 `x:Name="NameTextBox"` 能直接被代码当字段用——**那个字段是生成的**。

## 2. App.xaml：程序的启动配置

```xml
<Application x:Class="HelloWpfApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources />
</Application>
```

关键就一行：`StartupUri="MainWindow.xaml"`——框架启动时自动 new 这个窗口并显示。`Application.Resources` 是全局资源字典（第 08 章的主角），现在先空着。

`App.xaml.cs` 里什么都没有：

```csharp
public partial class App : Application
{
}
```

空类也要有：`x:Class` 把 XAML 和这个类连起来。想做启动逻辑时覆写 `OnStartup`：

```csharp
protected override void OnStartup(StartupEventArgs e)
{
    base.OnStartup(e);
    // 命令行参数在 e.Args；全局初始化放这里
}
```

## 3. 生命周期：从 Main 到退出

你写的代码里没有 `Main`——它是编译器生成的，时序如下：

```text
Main()
 └─ App.ctor()                构造 Application
 └─ InitializeComponent()     加载 BAML（编译后的 XAML）、注册资源
 └─ OnStartup                 你的启动钩子
 └─ StartupUri → new MainWindow() → Show()
 └─ Run()                     ★ 消息循环（Dispatcher），阻塞到这里
 └─ 所有窗口关闭 / Shutdown() 被调
 └─ OnExit                    你的退出钩子
```

这和 MFC 的 `InitInstance → Run → ExitInstance` 是同一个骨架，只是名字换了。消息循环由 `Dispatcher` 实现：WPF 把用户输入、渲染回调、绑定更新统统排队到 Dispatcher 上逐个执行。

默认 `ShutdownMode="OnLastWindowClose"`：最后一个窗口关闭就退出。可改成 `OnMainWindowClose`（主窗口关就退）或 `OnExplicitShutdown`（托盘程序用）。

## 4. Window 的生命周期事件

窗口这一侧，常用的事件按时间排：

| 事件 | 时机 | 典型用途 |
|---|---|---|
| 构造函数 + `InitializeComponent` | new 时 | `DataContext = new VM()`（第 07 章） |
| `Loaded` | 布局完成、即将显示 | 需要实际尺寸的初始化 |
| `Closing` | 用户请求关闭，**可取消** | 脏文档保存确认 |
| `Closed` | 已关闭，不可逆 | 释放资源 |
| `ContentRendered` | 首帧渲染完 | 埋点/启动计时 |

`Closing` 是最重要的一个，签名带取消位：

```csharp
protected override void OnClosing(CancelEventArgs e)
{
    if (有未保存修改)
        e.Cancel = true;   // true = 拦下这次关闭
}
```

第 12 章实战项目用它做"文档已修改，保存吗？"三选一。

## 5. 事件处理：最原始的交互方式

hello 示例用的是 WinForms 式的事件处理：

```xml
<Button Content="打招呼" Width="120" Height="36" Click="Button_Click" />
```

```csharp
private void Button_Click(object sender, RoutedEventArgs e)
{
    var name = string.IsNullOrWhiteSpace(NameTextBox.Text) ? "朋友" : NameTextBox.Text.Trim();
    MessageBox.Show($"Hello, {name}!", "Greeting");
}
```

`sender` 是触发事件的控件，`RoutedEventArgs` 是路由事件参数（第 05 章细讲）。这个写法直观，但把"界面"和"逻辑"焊在了一起：逻辑没法脱离界面测试。第 07 章的命令系统就是为了解开这根焊点。**教程前几章先用事件写，是为了让你看清"事件写法痛在哪里"**。

## 6. 常见坑

**删了 StartupUri 窗口不显示**：`StartupUri` 注释掉后又没在 `OnStartup` 里手动 `new MainWindow().Show()`，进程起来就退出（消息循环没有窗口可等）。两条路选一条，别两条都删。

**OnStartup 里窗口一闪而过**：手动创建窗口时忘了 `Show()`，或 `ShutdownMode` 在窗口创建前就判定退出。先设 `MainWindow` 再 `Show`。

**Application.Current 为 null**：只有在 Application 构造完成之后才可用。静态字段初始化器里访问它会踩空。

**后台线程更新界面崩异常**：`The calling thread cannot access this object`。WPF 的 UI 对象有线程亲和性，跨线程更新必须 `Dispatcher.Invoke`（第 09 章）。

**全局异常静默退出**：Dispatcher 消息循环里抛出的异常默认直接崩。上线前在 OnStartup 挂 `DispatcherUnhandledException` 记日志。

## 7. 实战建议

- 启动慢的初始化（数据库、配置文件）放 `OnStartup`，别放 `App` 构造函数——构造函数里抛异常连日志钩子都还没挂上
- 需要手动管理窗口顺序的应用（登录窗 → 主窗），放弃 `StartupUri`，在 `OnStartup` 里自己编排：`LoginWindow.ShowDialog()` 成功后再 `new MainWindow().Show()`
- `MainWindow` 的 `DataContext` 在构造函数里赋值，保证 XAML 绑定从第一帧就生效（第 07 章模式，第 12 章实战遵循）

---
上一章：[01 WPF 概述与架构](01-overview.md) ｜ 下一章：[03 XAML 语言](03-xaml.md)
