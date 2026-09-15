# 4. 第一个真实应用：文件、代码与启动流程

前三篇讲了机制，这一篇把它们落到一个真实存在的工程上：Visual Studio 的 **Blank App, Packaged (WinUI 3 in C++)** 模板生成的应用。所有代码都是模板真实代码（或注明了增改），你可以逐行对照自己创建的工程。

> **验证方式说明**：本教程的代码片段以真实 WinUI 3 / C++/WinRT 工程为准。XAML + 协程 + IDL 这套东西无法用单个 `.cpp` 文件在命令行验证——请用 Visual Studio 2022 安装 "Windows App SDK C++ 模板" 后创建工程对照。目录里的老式纯 C++ 示例已移除，因为它们演示的不是真实 WinUI 3 写法。

## 4.1 模板工程的文件结构

创建模板后，工程大致是：

```text
MyApp/
├── App.xaml               ← 应用级 XAML：资源字典
├── App.idl                ← App runtimeclass 的接口声明
├── App.xaml.h / App.xaml.cpp
├── MainWindow.xaml        ← 主窗口界面
├── MainWindow.idl         ← MainWindow runtimeclass 的接口声明
├── MainWindow.xaml.h / MainWindow.xaml.cpp
├── Package.appxmanifest   ← 包元数据（身份、图标、能力）
├── pch.h / pch.cpp        ← 预编译头（预包含 winrt 头文件）
└── Assets/                ← 图标等应用资源
```

注意 **IDL 文件**（`.idl`，MIDL 3.0 语法）：凡是需要被 XAML、绑定系统或其他模块跨 WinRT 边界访问的成员，都必须在 IDL 里声明。构建管线是：

```text
.idl ──MIDL──→ .winmd ──cppwinrt──→ *.g.h（模板基类、访问器骨架）
```

这就是 [02 篇](./02-winrt.md) 2.5 节讲的元数据/投影流程发生在你自己工程里的样子。

## 4.2 入口：wWinMain 与 Application::Start

WinUI 3 应用是普通 Win32 进程。入口函数的完整逻辑（模板由构建系统自动生成，官方文档中的等价手写版本如下）：

```cpp
#include "App.xaml.h"
#include <winrt/Microsoft.UI.Xaml.h>

int __stdcall wWinMain(HINSTANCE, HINSTANCE, PWSTR, int showCommand)
{
    winrt::init_apartment();   // 初始化 COM apartment（UI 线程是 STA）

    winrt::Microsoft::UI::Xaml::Application::Start(
        [](auto&&)
        {
            // 工厂回调：框架需要 App 对象时调用
            winrt::make<winrt::MyApp::implementation::App>();
        });

    return 0;
}
```

读法：

- `init_apartment()`：WinRT 对象模型建立在 COM 上，线程必须先加入 apartment；UI 线程加入的是单线程 apartment（STA）
- `Application::Start`：启动 XAML 框架，进入消息循环，直到应用退出才返回——**没有你自己写的 `while (GetMessage(...))`，消息循环在框架里**
- lambda 里 `winrt::make<App>()`：通过激活工厂创建 App 对象，对应 [02 篇](./02-winrt.md) 2.7 节的激活机制

## 4.3 App：应用对象与 OnLaunched

```cpp
// App.idl
namespace MyApp
{
    [default_interface]
    runtimeclass App : Microsoft.UI.Xaml.Application
    {
        App();
    }
}
```

```cpp
// App.xaml.h
#pragma once
#include "App.g.h"

namespace winrt::MyApp::implementation
{
    struct App : AppT<App>
    {
        App();
        void OnLaunched(Microsoft::UI::Xaml::LaunchActivatedEventArgs const&);

    private:
        Microsoft::UI::Xaml::Window window{ nullptr };
    };
}
```

```cpp
// App.xaml.cpp
#include "pch.h"
#include "App.xaml.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::MyApp::implementation
{
    App::App()
    {
        InitializeComponent();   // 处理 App.xaml 里的资源字典
    }

    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        window = make<MainWindow>();
        window.Activate();       // 显示窗口，开始接收消息
    }
}
```

`App` 的职责：

- 持有应用级资源（`App.xaml` 的 `Application.Resources`）
- 在 `OnLaunched` 里创建第一个窗口并 `Activate()`
- 处理应用级事件（`UnhandledException`、后台任务注册等）

`OnLaunched` 是模板约定的入口回调：框架初始化完成后调用它。之后框架接管消息循环。

## 4.4 MainWindow：窗口与界面的最小闭环

```cpp
// MainWindow.idl
namespace MyApp
{
    [default_interface]
    runtimeclass MainWindow : Microsoft.UI.Xaml.Window
    {
        MainWindow();
    }
}
```

```cpp
// MainWindow.xaml.h
#pragma once
#include "MainWindow.g.h"

namespace winrt::MyApp::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnClick(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::MyApp::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
```

```cpp
// MainWindow.xaml.cpp
#include "pch.h"
#include "MainWindow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::MyApp::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();   // 执行 XAML 编译器生成的界面构建代码
    }

    void MainWindow::OnClick(IInspectable const& sender, RoutedEventArgs const&)
    {
        // x:Name 生成的访问器：StatusText() 返回 TextBlock 对象
        StatusText().Text(L"Clicked from C++/WinRT");
    }
}
```

```xml
<!-- MainWindow.xaml -->
<Window
    x:Class="MyApp.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <StackPanel Orientation="Vertical" HorizontalAlignment="Center"
                VerticalAlignment="Center" Spacing="12">
        <TextBlock x:Name="StatusText" Text="Ready" FontSize="24" />
        <Button Content="Click me" Click="OnClick" />
    </StackPanel>
</Window>
```

### 事件签名解读

```cpp
void OnClick(IInspectable const& sender, RoutedEventArgs const& args)
```

这不是神秘参数，而是 WinRT 事件模型的标准签名：

- `sender`：事件发起者的引用，统一类型是 `IInspectable`（所有 WinRT 对象的根接口，见 [02 篇](./02-winrt.md) 2.3 节）。需要具体类型时 `sender.as<Button>()` 转换（内部是 QueryInterface）
- `args`：事件参数对象，携带这次事件的上下文（`RoutedEventArgs` 是基类，具体事件有具体参数类型，如 `SelectionChangedEventArgs`）

与 Win32 的对应：`sender` 取代了 `HWND`，`args` 取代了 `wParam/lParam`——消息模型升级成了对象模型。

## 4.5 启动时序：从进程到界面

把 4.2～4.4 串起来，一次完整启动是：

```text
进程创建
  ↓
wWinMain：init_apartment（UI 线程进 STA）
  ↓
Application::Start：初始化 XAML 框架，make<App>() 创建应用对象
  ↓
App 构造函数：InitializeComponent() 加载应用级资源
  ↓
框架调用 OnLaunched：make<MainWindow>()，window.Activate()
  ↓
MainWindow 构造：InitializeComponent() 构建 XAML 对象树、连接事件
  ↓
Activate：窗口显示，框架进入消息循环
  ↓
用户交互 → 事件回调 → 状态变化 → 界面更新
  ↓
所有窗口关闭 → 消息循环退出 → Start 返回 → wWinMain 返回 → 进程结束
```

这个时序回答了几个常见疑问：

- **第一个窗口为什么在 `OnLaunched` 创建**：框架要求先有 Application 对象，才有承载窗口
- **为什么不需要手写消息循环**：`Application::Start` 内部就是消息循环
- **窗口关闭后进程为什么还在**：WinUI 3 默认应用生命周期与窗口解耦；需要"关窗即退出"时自己跟踪窗口 `Closed` 事件调用 `Application::Current().Exit()`

## 4.6 在这个骨架上扩展

真实应用在模板骨架上的第一轮扩展通常是：

1. 把业务界面从 `MainWindow.xaml` 挪到 `Page`，`MainWindow` 只留导航壳（见 [05 篇](./05-project-structure.md)）
2. 把状态从控件挪到 ViewModel，用 `x:Bind` 连接（见 [08 篇](./08-binding-mvvm.md)）
3. 在 `App` 里注册全局异常处理：

```cpp
// App 构造函数中
this->UnhandledException([](IInspectable const&, UnhandledExceptionEventArgs const& e)
{
    // 记录日志、提示用户；此处之后进程通常无法继续
});
```

## 4.7 常见启动期错误

| 现象 | 原因 |
|------|------|
| `x:Class` 与 IDL 类型不匹配编译错误 | XAML 根元素的 `x:Class` 必须与 IDL runtimeclass 的全名一致 |
| 新成员在 XAML 里引用失败 | 被引用的成员（事件处理器、绑定属性）必须进 IDL 或生成为类成员 |
| 窗口闪退，无异常信息 | `OnLaunched` 里抛异常；在 App 构造和 `OnLaunched` 下断点逐步排查 |
| 改了 XAML 没生效 | 生成代码缓存问题：清理 `Generated Files` 后重新构建 |
| 非打包模式启动报运行时缺失 | Windows App SDK 运行时未安装或 bootstrapper 未初始化（见 [09 篇](./09-theming-packaging.md)） |

---

上一篇：[03-xaml.md](./03-xaml.md) ｜ 下一篇：[05-project-structure.md](./05-project-structure.md)
