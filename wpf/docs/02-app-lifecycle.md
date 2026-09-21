# 02 · 应用骨架与生命周期

> 对应示例：`examples/03_hello_wpf`（复用）

> **本章你将学会**：WPF 程序由哪几个文件构成、分部类如何把 XAML 和 C# 缝在一起、程序从启动到退出的完整时序、窗口生命周期事件怎么用。
> **前置章节**：[01 概述](01-overview.md)。

## 1. 两对文件，一棵对象树

`dotnet new wpf` 给你四个文件，正好分成两对：

```text
App.xaml           应用级 XAML：资源字典、启动配置
App.xaml.cs        App 的分部类：你的启动/退出逻辑
MainWindow.xaml    窗口级 XAML：界面对象树
MainWindow.xaml.cs MainWindow 的分部类：事件处理
```

**分部类（partial class）是理解 XAML 的钥匙**。你写的 `MainWindow.xaml.cs` 看起来只有几行：

```csharp
public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }
}
```

但这个类还有另一半——XAML 编译器把 `MainWindow.xaml` 翻译成一个 `MainWindow.g.cs` 文件（在 obj 目录下），里面声明了 `x:Name` 对应的字段和 `InitializeComponent` 方法。编译时两半合成一个类：

```text
   MainWindow.xaml                    MainWindow.xaml.cs
          │                                    │
          │ XAML 编译器（编译期）                │ 你写的
          ▼                                    ▼
   MainWindow.g.cs  ──── partial ────  MainWindow.cs
   （生成字段 NameTextBox、                  （Button_Click、
     InitializeComponent 方法）               以后还有你的逻辑）
                          │
                          ▼ 编译合并
                    MainWindow 完整类
```

所以 XAML 里写的 `x:Name="NameTextBox"` 能直接被 C# 当字段用——**那个字段不是魔法，是生成的代码**。这也解释了一个经典现象：改了 XAML 里的名字后 C# 报"找不到"，重新生成（Rebuild）一次就好，因为 .g.cs 还没更新。

## 2. App.xaml：程序的启动配置

逐行看 `03_hello_wpf` 的 App.xaml：

```xml
<Application x:Class="HelloWpfApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources />
</Application>
```

- `x:Class="HelloWpfApp.App"`：把这份 XAML 连到 `App.xaml.cs` 里的 `App` 类（同一个分部类机制）
- `StartupUri="MainWindow.xaml"`：**框架启动时自动 new 这个窗口并显示**——这是"程序从哪个窗口开始"的答案
- `Application.Resources`：全局资源字典（第 13 章的主角），现在先空着

`App.xaml.cs` 里什么都没有，但空类也必须有：

```csharp
public partial class App : Application { }
```

想做启动逻辑（读配置、注册编码、记录日志）时，覆写 `OnStartup`：

```csharp
protected override void OnStartup(StartupEventArgs e)
{
    base.OnStartup(e);
    // e.Args 是命令行参数（string[]）；全局初始化放这里，第 25 章实战在这注册 GB18030 编码
}
```

## 3. 生命周期：从 Main 到退出

你写的代码里没有 `Main`——入口方法也是编译器生成的。完整时序：

```text
Main()                        ← 生成代码
 └─ App()                     构造 Application 对象
 └─ InitializeComponent()     加载 BAML（编译后的 App.xaml）、注册资源
 └─ OnStartup()               ★ 你的启动钩子（最先能安全写逻辑的地方）
 └─ StartupUri 生效           new MainWindow() → Show()
 └─ Run()                     ★ 消息循环（Dispatcher），程序"停"在这里
 │     └─ 循环处理：输入、渲染、绑定更新、定时器、异步续体……
 └─ 所有窗口关闭 / Shutdown() 被调用
 └─ OnExit()                  你的退出钩子
```

这个骨架和 MFC 的 `InitInstance → Run → ExitInstance` 完全同构，只是名字换了。消息循环由 **Dispatcher** 实现：WPF 把用户输入、渲染回调、绑定更新统统排进 Dispatcher 队列逐个执行——第 21 章讲异步时，"队列被堵住 = 界面卡死"就是从这来的。

### 退出模式：ShutdownMode

| 模式 | 行为 | 适用 |
|---|---|---|
| `OnLastWindowClose`（默认） | 最后一个窗口关闭即退出 | 多数程序 |
| `OnMainWindowClose` | 主窗口关闭即退出 | 主窗口 + 工具窗口的程序 |
| `OnExplicitShutdown` | 必须代码调 `Shutdown()` | 托盘常驻程序 |

```xml
<Application x:Class="..." ShutdownMode="OnExplicitShutdown" ...>
```

## 4. 放弃 StartupUri：手动编排启动流程

`StartupUri` 是"单窗口直达"的写法。要编排"先登录再进主窗口"这类流程，删掉 StartupUri，自己在 OnStartup 里写：

```csharp
protected override void OnStartup(StartupEventArgs e)
{
    base.OnStartup(e);

    var login = new LoginWindow();
    var ok = login.ShowDialog();          // 模态：阻塞到登录窗口关闭（第 22 章）

    if (ok == true)
    {
        var main = new MainWindow();
        MainWindow = main;                // 告诉框架"这是主窗口"（ShutdownMode 会用到）
        main.Show();
    }
    else
    {
        Shutdown();                       // 登录取消：必须手动退出，否则消息循环空转
    }
}
```

记住配套规则：**删了 StartupUri 就必须自己 Show 窗口并考虑退出路径**——只删不加是初学者最常见的"程序闪退"原因（见常见坑第 1 条）。

## 5. Window 的生命周期事件

窗口这一侧，常用事件按时间排序：

| 事件 | 时机 | 典型用途 |
|---|---|---|
| 构造函数 + `InitializeComponent` | new 时 | `DataContext = new VM()`（第 11 章） |
| `Loaded` | 布局完成、即将显示 | 需要实际尺寸的初始化 |
| `ContentRendered` | 首帧渲染完 | 埋点/启动计时 |
| `Closing` | 用户请求关闭，**可取消** | 脏文档保存确认 |
| `Closed` | 已关闭，不可逆 | 释放资源 |

`Closing` 最重要，签名带取消位：

```csharp
protected override void OnClosing(CancelEventArgs e)
{
    if (有未保存修改)
        e.Cancel = true;   // true = 拦下这次关闭
}
```

第 25 章实战项目用它做"文档已修改，保存吗？"三选一（取消 / 不保存 / 保存后关闭）。

注意 `Closing` 与 `Closed` 的区别：前者还来得及反悔，后者木已成舟。清理资源放 `Closed`，拦截用户放 `Closing`。

## 6. 事件处理：最原始的交互方式

hello 示例用的是"事件直连"写法：

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

两个参数的含义要现在就说清，后面所有事件处理都是这个签名：

- `sender`：触发事件的对象（这里是 Button）
- `e`：事件参数，`RoutedEventArgs` 是路由事件参数（第 08 章细讲为什么会"路由"）

这个写法直观，但把"界面"和"逻辑"焊在了一起——逻辑没法脱离界面做单元测试。**教程前几章刻意用事件写，是为了让你亲眼看见它痛在哪里**；第 11-12 章的 MVVM 与命令会解开这根焊点。

## 7. 常见坑

**删了 StartupUri 窗口不显示**：注释掉 `StartupUri` 又没在 `OnStartup` 里手动 `new MainWindow().Show()`，进程起来就退出（消息循环没有窗口可等）。两条路选一条，别两条都不做。

**手动 Show 忘了设 MainWindow**：`ShutdownMode=OnMainWindowClose` 时，框架认的是 `Application.MainWindow` 属性——手动创建窗口要赋值（上一节代码第 8 行），否则退出判定失效。

**Application.Current 为 null**：只有在 Application 构造完成之后才可用。静态字段初始化器里访问它会踩空——静态初始化的执行时机早于 App 构造。

**后台线程更新界面崩异常**：报错 `The calling thread cannot access this object because a different thread owns it`。WPF 的 UI 对象有线程亲和性，跨线程更新必须 `Dispatcher.Invoke`（第 21 章）。

**全局异常静默退出**：Dispatcher 消息循环里抛出的异常默认直接崩。上线前在 OnStartup 挂钩子记日志：

```csharp
DispatcherUnhandledException += (_, ex) =>
{
    // 记日志；ex.Handled = true 可吞掉异常继续运行（慎用）
};
```

## 8. 实战建议

- 启动慢的初始化（数据库、配置文件）放 `OnStartup`，别放 `App` 构造函数——构造函数里抛异常时连日志钩子都还没挂上
- 一个应用只编排在 `App` 一处：登录 → 主窗 → 托盘这类顺序写在 OnStartup 里，别散落在各窗口的构造函数
- `MainWindow` 的 `DataContext` 在构造函数里赋值，保证 XAML 绑定从第一帧就生效（第 11 章的模式）
- 想看清 `Main` 与 .g.cs 的真面目：构建后打开 `obj/Debug/net10.0-windows/App.g.cs` 和 `MainWindow.g.cs` 读一遍——亲眼看过生成代码，"XAML 就是 C#" 从此不再是口号

## 自测

1. **XAML 与 C# 文件靠什么机制合并成一个类？** —— partial 分部类；XAML 编译器生成 `*.g.cs` 与你手写的另一半编译合并。
2. **程序入口 `Main` 是谁写的？启动时序中 `Run()` 之前发生哪几步？** —— 编译器生成；App 构造 → InitializeComponent → OnStartup → StartupUri 建主窗 → Run 进入消息循环。
3. **`Closing` 与 `Closed` 有什么区别？拦截关闭怎么写？** —— Closing 可取消（`e.Cancel = true`），Closed 不可逆。
4. **什么时候需要放弃 `StartupUri`？** —— 需要编排启动流程（如先登录）或 `OnExplicitShutdown` 托盘程序时，改为 OnStartup 手动创建。

---
上一章：[01 WPF 概述与架构](01-overview.md) ｜ 下一章：[03 XAML 语言基础](03-xaml-basics.md)
