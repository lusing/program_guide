# 4. 第一个真实应用：文件、代码与启动流程

前三篇讲了机制，这一篇把它们落到一个真实存在的工程上：Visual Studio 的 **Blank App, Packaged (WinUI 3 in C++)** 模板生成的应用。所有代码都是模板真实代码（或注明了增改），你可以逐行对照自己创建的工程。

> **验证方式说明**：本篇的工程就是仓库里的 `examples/01-first-app/`（命名空间 `MyApp`），在 `WinUI3/` 下跑 `.\build.ps1` 即可从零编译；`tools/ui-smoke/` 会启动它、截图、合成一次真实点击并再截图，确认 `Click` 处理器真的把文本改成了 "Clicked from C++/WinRT"。XAML + 协程 + IDL 这套东西无法用单个 `.cpp` 在命令行验证，但**可以**用这里的完整工程验证——下面 4.8 节列出了模板之外必须补上的工程细节。

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
2. 把状态从控件挪到 ViewModel，用 `x:Bind` 连接（见 [32 篇](./32-binding-mvvm.md)）
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
| `x:Bind` 引用的属性/方法编译报"找不到成员" | 只有 **`x:Bind` 可见的成员**（绑定路径上的属性、方法）必须在 IDL 里声明；用 `Click="OnClick"` 这种**按名字挂接的事件处理器不需要进 IDL**，只要它是 `x:Class` 实现类上的成员函数即可（本篇 `OnClick` 就没在 `MainWindow.idl` 里，编译验证通过） |
| 窗口闪退，无异常信息 | `OnLaunched` 里抛异常；在 App 构造和 `OnLaunched` 下断点逐步排查 |
| 改了 XAML 没生效 | 生成代码缓存问题：清理 `Generated Files` 后重新构建 |
| 非打包模式启动报运行时缺失 | Windows App SDK 运行时未安装或 bootstrapper 未初始化（见 [33 篇](./33-theming-packaging.md)） |

### 4.7.x 从模板到功能工程的距离

01 的 MyApp 到四个功能工程的差异清单：App 自定义方法（SettingsHub 的 ApplyTheme 走 IDL + factory_implementation）、多页面/多文档状态、持久化层、窗口自定位（31.5 的 MoveAndResize 纪律）。**每一步都是 04 章骨架的加法而非重写**——四个工程的 App.xaml.cpp 与 MyApp 的差异只有 OnLaunched 前的一个方法与成员。教学含义：**04 章的模板就是你的终身起点**，功能长在骨架上。

## 4.8 命令行构建：模板之外必须补上的工程细节

VS 模板替你把这些都配好了，所以你从没注意过它们存在。`examples/01-first-app/` 是**手写的 `.vcxproj`**，靠 `WinUI3/build.ps1` 从命令行编译——下面每一条都是让它真正编过时踩出来的，逐条对照你自己的工程能省掉一整天的试错。

### 1. 源码用 UTF-8 无 BOM，编译器开 `/utf-8`

XAML 里常有中文/特殊字符，MSVC 默认按本地代码页解析源文件会乱码或报错。工程统一加 `/utf-8`（源字符集和执行字符集都按 UTF-8），文件存成**无 BOM 的 UTF-8**。不要靠 BOM 让编译器猜——无 BOM + `/utf-8` 是干净组合。

### 2. `pch.h` 必须包含每个 `x:Class` 的实现头

XAML 编译器生成一个 `XamlMetaDataProvider`，它的 `XamlTypeInfo.g.cpp` 里有一句 `static_assert`，要求能看到所有 `x:Class` 的**实现类型**（不是投影类型）。所以 `pch.h` 里除了 winrt 头，还要：

```cpp
#include "App.xaml.h"
#include "MainWindow.xaml.h"   // 每个带 x:Class 的页面/窗口都要在这里出现
```

漏掉一个，报错信息（`XamlTypeInfo.g.cpp` 里的 `static_assert` 失败）离真正的根因隔了好几层，很难往回找。

### 3. 每个页面的 `<Page>.xaml.g.hpp` 要喂给第二次编译迭代

C++ XAML 是**两趟**构建：

```text
第一趟：编译用户源码（此时 <Page>.xaml.g.hpp 还不存在）
   ↓
MarkupCompilePass2：XAML 编译器写出 <Page>.xaml.g.hpp（InitializeComponent 的实现体）
   ↓
第二趟：必须有人把这些 .g.hpp 编译进去 —— 默认没人管！
```

模板用 MSBuild 的 `CompilerIteration=XamlGenerated` 机制补上第二趟。手写工程要在 `.vcxproj` 里放这个 target：

```xml
<Target Name="CompileXamlPageImplementationFiles" AfterTargets="MarkupCompilePass2">
  <ItemGroup>
    <ClCompile Include="@(Page->'$(XamlGeneratedOutputPath)%(Filename).xaml.g.hpp')">
      <CompilerIteration>XamlGenerated</CompilerIteration>
      <PreprocessorDefinitions>@(ClCompile->WithMetadataValue('Filename', 'App.xaml')->'%(PreprocessorDefinitions)')</PreprocessorDefinitions>
    </ClCompile>
  </ItemGroup>
</Target>
```

少了它，链接期报 `InitializeComponent` 未定义——代码全对，就是没人编译那份生成实现。

### 4. `App.xaml.g.hpp` 里定义了 `wWinMain`，别再编译一份

`ApplicationDefinition`（`App.xaml`）生成的 `App.xaml.g.hpp` **自带 `wWinMain` 入口**。如果你的工程另有 `main.cpp` 写了入口，两者会冲突（重复定义 `wWinMain`）。规则：

- 用模板风格、没有独立 `main.cpp` → 让 `App.xaml.g.hpp` 提供入口；
- 像 `examples/` 这样有显式 `main.cpp` → 上面那个 target 要把 `App.xaml.g.hpp` 排除在 `XamlGenerated` 迭代之外（靠 `PreprocessorDefinitions` 那行的 `Filename='App.xaml'` 过滤实现），入口以 `main.cpp` 为准。

### 5. `<windows.h>` 的 `GetCurrentTime` 宏要 `#undef`

`<windows.h>` 定义了宏 `GetCurrentTime`，会和 WinUI/XAML 头里的同名成员函数冲突，编译期报莫名其妙的语法错误。`pch.h` 里包含完 Windows 头之后补一句：

```cpp
#undef GetCurrentTime
```

### 6. MIDL 不能跨 `.idl` 文件解析 runtimeclass 引用

如果一个 `.idl` 里的 runtimeclass 引用了**另一个 `.idl`** 里声明的类型，MIDL 会报 `MIDL2011` 未解析类型。模板工程类少碰不到；一旦像 [32 篇](./32-binding-mvvm.md) 那样有 `MainWindow → TasksViewModel → TaskItem` 的引用链，**必须把这条链上的所有 runtimeclass 合并进同一个 `.idl`**（`App.idl` 因为不引用它们，可以独立留着）。

---

上一篇：[03-xaml.md](./03-xaml.md) ｜ 下一篇：[05-project-structure.md](./05-project-structure.md)
