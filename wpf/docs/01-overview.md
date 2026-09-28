# 01 · WPF 概述与架构

> 对应示例：`examples/03_hello_wpf`（第 9 节逐行走读；02–23 章示例每章都有 **C# / F# / C++/CLI 三份同功能实现**）

> **本章你将学会**：WPF 是什么、它与其他 Windows UI 技术的关系、五个贯穿全书的核心概念、三语言（C#/F#/C++/CLI）路线各走哪条路、如何用纯命令行构建第一个 WPF 程序。
> **前置知识**：C# 基本语法（本仓库《C# 语言教程》前几章的深度即可）；读 F# / C++ 章节另需 [fsharp](../../fsharp/README.md) / 对应语言教程的前几章。

## 1. WPF 是什么

Windows Presentation Foundation（WPF）是微软 2006 年随 .NET Framework 3.0 发布的桌面 UI 框架，至今仍是 Windows 桌面开发的主力技术之一。它做了一件在此之前没人做过的事：**把"界面长什么样"和"程序做什么"彻底分成两种文件**——

- 界面用 **XAML** 声明（一种 XML 方言，写起来像 HTML）
- 逻辑用 **C#** 编写

渲染也不再走 Win32 时代的 GDI/GDI+，而是基于 **DirectX 的硬件加速管线**。一句话定位：

> **WPF 是 .NET 平台上"声明式界面 + 数据绑定驱动"的 Windows 桌面框架。**

对初学者有三句话值得先记住，后面每一章都在展开：

1. 窗口和控件不是操作系统句柄的包装，而是 .NET 对象组成的**可视化树**
2. 控件外观不是写死的，可以被**模板**整个重写
3. 界面更新的主驱动力不是事件处理函数，而是**数据绑定**——数据变了，界面自己变

本教程基于 .NET 10。WPF 自 .NET Core 3.0（2019）起随开源 .NET 发布，微软持续维护，API 与 .NET Framework 4.8 时代基本一致。

## 2. WPF 在 Windows UI 谱系中的位置

初学者常困惑：Win32、MFC、WinForms、WPF、WinUI 3，学哪个？先看对照表：

| | Win32 | MFC | WinForms | WPF | WinUI 3 |
|---|---|---|---|---|---|
| 语言 | C/C++ | C++ | C# | C# | C#/C++ |
| 渲染 | GDI/User32 | GDI | GDI+ | **DirectX** | Composition |
| 界面描述 | 手工/资源脚本 | 资源脚本 | 代码 | **XAML** | XAML |
| 数据绑定 | 无 | 无（DDX 是快照式） | 简陋 | **强** | 强 |
| 自定义外观 | 自绘 | 自绘 | 困难 | **模板重写** | 模板重写 |
| 运行时依赖 | 无 | 无/VC 运行库 | .NET | .NET | .NET + Windows App SDK |
| 诞生年 | 1985 | 1992 | 2002 | 2006 | 2021 |

两条演化主线帮你建立坐标系：

1. **WPF 是对 WinForms 的反思**。WinForms 只是 Win32 控件的薄包装，控件外观、布局、绑定处处受限；WPF 重造了整个渲染与控件体系——所以它的属性、事件、布局和 Win32 世界几乎完全不同，学习曲线更陡，但天花板高得多
2. **WinUI 3 是 XAML 语法的后代**。学懂 WPF 的 XAML、绑定、样式体系，迁移到 WinUI 3/UWP 几乎是平移；反过来则不成立

如果本仓库的其他教程（win32、mfc、WinUI3）你也读过，本书会频繁与它们对照——同一件事在不同框架里的做法差异，恰恰是理解每个框架设计意图的捷径。

## 3. 架构鸟瞰：从 XAML 到屏幕

一个 WPF 程序运行起来，数据流大致是：

```text
你写的 XAML 文件
   │  编译时：XAML → BAML（二进制压缩格式）嵌入程序集
   ▼
程序启动，加载 BAML
   │  运行时：解析器按声明构建对象树
   ▼
┌───────────────────────────────────┐
│  可视化树（Visual Tree）            │
│  Window → Grid → TextBox → …      │  ← 全是 .NET 对象，可代码访问
└───────────────────────────────────┘
   │  每帧：Measure → Arrange → 渲染指令（第 05 章）
   ▼
DirectX 硬件加速绘制到屏幕
```

理解这张图，就理解了 WPF 与 Win32 程序的根本区别：**界面即对象**。MFC 里改一个静态文本要 `SetDlgItemText(hDlg, IDC_LABEL, ...)`（拿句柄、发消息）；WPF 里就是 `label.Text = "..."`（对象改属性）。句柄消失了，剩下的全是你可以用普通 C# 操作的对象。

## 4. 五个核心概念（全书骨架）

后面每一章都在展开这五件事，先混个脸熟：

| 概念 | 一句话 | 详见 |
|---|---|---|
| XAML | 用 XML 声明对象树，编译进程序集 | 第 03 章 |
| 依赖属性 | 支持"由外部决定值"的属性系统，绑定/样式/动画的地基 | 第 04 章 |
| 布局 | 每帧两遍测量（Measure→Arrange），面板递归协商尺寸 | 第 05 章 |
| 数据绑定 | `界面属性 ↔ 数据对象属性` 的自动同步管道 | 第 09、10 章 |
| MVVM | 把界面状态抽到 ViewModel 类，界面只剩声明 | 第 11、12 章 |

还有一条贯穿全书的铁律：**UI 元素只能被创建它的那个线程访问**。WPF 应用本质是一个 STA 线程上的消息循环（Dispatcher），任何后台线程想更新界面都要回到这个线程——第 21 章的主题，与 MFC 的 `PostMessage` 回 UI 线程是同一个思想。

## 5. 2026 年还该学/用 WPF 吗

该用的场合：

- **企业内部工具、生产力桌面软件**：WPF 至今是 Windows 上"重逻辑、长周期"桌面应用的主力框架（Visual Studio 自己就是 WPF 写的）
- **维护存量代码**：大量金融、医疗、工业软件是 WPF 的
- **需要深度定制外观**：模板体系可以重写任何控件的任何部位，不需要自绘
- **想学 XAML 家族**：WinUI 3、MAUI、UWP 全是同一套语法

不该用的场合：

- 跨平台 → MAUI / Qt / Electron / Web
- 极小体积的原生 exe → MFC / Win32（WPF 程序至少带 .NET 运行时）
- 追求最新 Fluent 视觉风格开箱即用 → WinUI 3

## 6. 开发环境

本教程使用的本机工具链：

| 组件 | 路径 / 版本 |
|---|---|
| .NET SDK | `G:\scoop\apps\dotnet-sdk\current\dotnet.exe`（.NET 10，`global.json` 钉 10.0.*） |
| 构建方式 | C#/F#：`dotnet build`；C++/CLI：VS 2026 MSBuild（v145 工具集） |
| C++/CLI 组件 | VS 安装 `Microsoft.VisualStudio.Component.VC.CLI.Support`（脚本经 vswhere 自动定位 MSBuild） |
| 编辑器 | 任意；VS 2026 / VS Code + C# Dev Kit 体验更好 |
| 运行平台 | Windows（WPF 不跨平台，这是它与 MAUI 的分界） |

只读 C# 章节的话，唯一硬性要求是 .NET SDK（SDK 安装包自带 Windows Desktop 运行时）。验证安装：

```powershell
dotnet --version   # 输出 10.x
```

## 7. 用命令行构建 WPF 程序

Visual Studio 向导生成的工程文件很多，但 WPF 程序的本质只需要**一个 csproj + App.xaml + MainWindow.xaml**。本目录的 `build.ps1` 自动发现并构建全部示例（C#/F# 走 dotnet build，C++/CLI 走 VS MSBuild）：

```powershell
cd G:\code\guide\wpf
.\build.ps1                              # 构建全部（C# + F# + C++/CLI）
.\build.ps1 -Lang fsharp                 # 只构建某一语言：csharp | fsharp | cpp
.\build.ps1 -Chapter 15_templates        # 只构建某一章
.\build.ps1 -Clean                       # 清理 bin/obj/x64（脚本用安全的目录名比对，勿手写 -Include）
```

示例工程 `examples/03_hello_wpf/HelloWpfApp.csproj` 的全貌，每一行都有注释：

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>                    <!-- GUI 程序：不弹控制台黑窗 -->
    <TargetFramework>net10.0-windows</TargetFramework> <!-- -windows 后缀 = 允许 Windows 专属 API -->
    <UseWPF>true</UseWPF>                              <!-- 引入 WPF 程序集 + XAML 编译管线 -->
    <Nullable>enable</Nullable>                        <!-- 可空引用类型检查（C# 现代默认） -->
    <ImplicitUsings>enable</ImplicitUsings>            <!-- 常用命名空间自动 using -->
    <RootNamespace>HelloWpfApp</RootNamespace>         <!-- 代码的默认命名空间 -->
  </PropertyGroup>
</Project>
```

对 WPF 而言三行是开关：`OutputType=WinExe`、`net10.0-windows`、`UseWPF`。没有其他魔法。手写这三个文件（csproj + App.xaml + MainWindow.xaml）就能构建出可运行的 GUI 程序——本教程所有示例都保持这种"最小工程"形态，方便你看清每个零件。

## 8. 三语言路线：C# / F# / C++/CLI

本教程 03–23 章的每章示例都有三份**同功能实现**（csharp / fsharp / cpp 三个目录）。三条路线的分野一句话：**XAML 是 C# 的专属红利**——XAML 编译器只生成 C# 分部类，F# 和 C++/CLI 都写不了 XAML 代码后置，因此走"纯代码 UI"路线。

| | C#（主线） | F# | C++/CLI |
|---|---|---|---|
| 工程文件 | `.csproj` | `.fsproj` | `.vcxproj`（VS MSBuild，v145） |
| 构建命令 | `dotnet build` | `dotnet build` | host.csproj → ProjectReference 连带 vcxproj |
| 界面描述 | **XAML**（+ 代码后置） | 纯代码（对象初始化器） | 纯代码（gcnew 三步：建 → 设属性 → Add） |
| 产物 | exe | exe | **混合模式 DLL + C# 启动器 exe** |
| 事件接线 | `Click += (s,e) => …` | `btn.Click.Add(fun _ -> …)` | `gcnew RoutedEventHandler(this, &T::OnX)` |
| 特色章节 | 全部 | 11 章（命令是函数值） | 17 章（Tag 传状态）、21 章（无 async 的三连等价物） |

### 8.1 C++/CLI 路线的五条硬事实（全部本机实测）

1. **NETSDK1116：.NET Core/.NET 10 的 C++/CLI 只能产动态库** → 每章"混合模式 DLL（UI 代码）+ `cpp/host/` 的 10 行 C# 启动器（ProjectReference 引 vcxproj）"。启动器上的 `[STAThread]` 服务整个 UI 线程，C++ 侧的窗口同样受益。
2. **裸写 `<Reference Include="PresentationFramework"/>` 会解析到 GAC 的旧程序集**（C4691 警告 + 类型错配）→ HintPath 指向 WindowsDesktop 目标包（`C:\Program Files\dotnet\packs\Microsoft.WindowsDesktop.App.Ref\10.0.12\ref\net10.0\`），且 **Binding 的基类 MarkupExtension 本体在 System.Xaml**（编译器点名 C3624）——WPF 引用集固定为 4 个：WindowsBase、PresentationCore、PresentationFramework、System.Xaml，统一放在 `wpf/Cpp.Common.props`。
3. **中文源码必须给 cl 传 `/utf-8`**（无 BOM 文件被按 ANSI 读，吐 C2001 怪错）——同样在 Cpp.Common.props。
4. **属性名遮蔽同名类型**（本路线头号坑，比 WinForms 更凶）：
   - 枚举类：`WindowStartupLocation` / `VerticalAlignment` / `Stretch`（Viewbox 的）等属性名会遮蔽同名枚举类型，赋值右侧必须全限定 `System::Windows::VerticalAlignment::Center`；
   - 类名：Window 子类里裸写 `Style^` / `Trigger^` 被解析成 `FrameworkElement::Style` 属性 / 别的成员——`System::Windows::Style^` 全限定；
   - 连 C# 都会中招：Window 子类里 `Duration(...)` 被解析成不可调用的成员（CS1955），要 `new System.Windows.Duration(...)`；
   - **`template` 是 C++ 关键字**，不能当变量名（存 ControlTemplate 的变量请叫 ctrlTemplate）。
5. **没有 lambda 捕获**：事件处理器只能是"目标对象 + 方法组"委托（`gcnew RoutedEventHandler(this, &T::OnX)`）；循环里挂处理器要带上下文就用 `Tag` 存状态、处理器里 `safe_cast` 取回（17 章 RadioButton 的做法）；`BeginStoryboard`、`FindName`（返 `Object^`）等名字要小心与成员查找打架，必要时全限定。

### 8.2 F# 路线的三条要点

1. **INPC 接口成员必须 `[<CLIEvent>]`]**（FS0859）：`Event<PropertyChangedEventHandler, _>()` + `pc.Publish` 暴露，触发用 `pc.Trigger(this, PropertyChangedEventArgs "Name")`；ICommand / INotifyDataErrorInfo 同理（10、11、16 章）。
2. **XAML 三件套的代码等价物**要背下来：`{StaticResource k}` → 字典取值；`{DynamicResource k}` → `SetResourceReference(属性, k)`；`{TemplateBinding X}` → `Binding("X", RelativeSource = RelativeSource.TemplatedParent)`；`Storyboard.TargetName` → `Storyboard.SetTarget(动画, 对象)`。
3. **可空与判空是方言区**：`IsChecked` 是 `Nullable<bool>`（判真 `GetValueOrDefault()`）；自定义类没有 `AllowNullLiteral` 就不能用 `isNull`（用 `obj.ReferenceEquals(x, null)`）；`ShowDialog()` 的返回同样判 `GetValueOrDefault()`。

三语言的完整坑位清单散布在各章正文（每章"三语言落地"一节），速查见 `wpf/README.md`。

## 9. 第一个程序：逐文件走读

`examples/03_hello_wpf` 是最小的可运行 WPF 程序。C# 版 5 个文件：

```text
03_hello_wpf/
├── csharp/
│   ├── HelloWpfApp.csproj     # 工程定义（上一节）
│   ├── App.xaml               # 应用对象声明：StartupUri 指向主窗口
│   ├── App.xaml.cs            # App 的 C# 部分（初始为空）
│   ├── MainWindow.xaml        # 主窗口的界面（本节主体）
│   └── MainWindow.xaml.cs     # 主窗口的逻辑（事件处理）
├── fsharp/                    # 同功能纯代码版（Program.fs 一个文件）
└── cpp/                       # 同功能 C++/CLI 版（vcxproj + .cpp + host/ 启动器）
```

三版的差异一眼看穿：C# 版靠 XAML 声明界面；F# / C++ 版"创建控件 → 设属性 → Children.Add"三步搭出同一棵对象树——**对象树殊途同归**，这正是"界面即对象"的活证明。

主窗口 XAML——现在看不懂每个细节没关系，第 03、05 章会逐个拆开：

```xml
<Window x:Class="HelloWpfApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Hello WPF" Height="220" Width="400">
    <Grid Margin="20">
        <StackPanel VerticalAlignment="Center">
            <TextBlock Text="请输入你的名字：" FontSize="18" Margin="0,0,0,12" />
            <TextBox x:Name="NameTextBox" Width="220" Height="32" Margin="0,0,0,12" />
            <Button Content="打招呼" Width="120" Height="36" Click="Button_Click" />
        </StackPanel>
    </Grid>
</Window>
```

代码后置（code-behind）——按钮被点后做的事：

```csharp
private void Button_Click(object sender, RoutedEventArgs e)
{
    var name = string.IsNullOrWhiteSpace(NameTextBox.Text) ? "朋友" : NameTextBox.Text.Trim();
    MessageBox.Show($"Hello, {name}!", "Greeting");
}
```

四个角色各就各位：

| 角色 | 谁 | 职责 |
|---|---|---|
| 应用对象 | `App`（App.xaml） | 入口，管生命周期与全局资源（第 02 章） |
| 主窗口 | `MainWindow` | XAML 声明界面树，分部类接事件 |
| 布局 | `Grid` + `StackPanel` | 嵌套面板负责子元素排布（第 05 章） |
| 交互 | `Click` 事件 | 最原始的处理方式（第 12 章会被命令取代） |

注意 `Button_Click` 里直接用了 `NameTextBox.Text`——XAML 里写的 `x:Name="NameTextBox"` 会生成一个同名字段，这是 XAML 与 C# 的第一根连接线，第 02、03 章细讲。

## 10. 本教程的结构与用法

- 每章正文在 `docs/`，**章号与示例号对应**：第 06 章讲 `examples/06_layout_lab`，以此类推
- **03–23 章每章示例都有 csharp / fsharp / cpp 三份同功能实现**；01、02、04、24 为概念/发布章，25 实战项目为 C# 专属（F# 接手思路见该章）
- 示例代码全部被 `build.ps1` 编译验证（61 个 exe），且做过启动冒烟测试（拉起 3 秒不崩）
- 第 25 章是完整实战项目 `25_notepad_plus`（MVVM 架构的记事本+），把全书知识串起来
- 学习路线按章顺序走：02 骨架 → 03-04 XAML 与依赖属性 → 05-06 布局 → 07-08 控件与事件 → 09-10 绑定 → 11-12 MVVM（**核心两连**）→ 13-15 样式触发器模板 → 16-20 专题 → 21-23 异步/对话框/导航 → 24 部署 → 25 实战
- 只学 C# 主线的读者可以完全无视另外两份；对照阅读的最佳时机是第二遍

每章末尾有"自测"，答不上来自测题就回读对应小节——比一路顺读的留存率高得多。

## 自测

1. **WPF 渲染基于什么技术？与 Win32 时代有何本质不同？** —— DirectX 硬件加速；控件是 .NET 对象树而非 GDI 句柄包装。
2. **"界面即对象"在代码上意味着什么？** —— 改界面 = 改对象属性（`label.Text = "…"`），不需要句柄 + 消息。
3. **全书五个核心概念是什么？** —— XAML、依赖属性、布局、数据绑定、MVVM。
4. **csproj 里让工程变成 WPF 程序的三行是什么？** —— `OutputType=WinExe`、`TargetFramework=net10.0-windows`、`UseWPF=true`。
5. **为什么 F# / C++/CLI 版不能用 XAML？各走什么替代路线？** —— XAML 编译器只生成 C# 分部类；两者都走纯代码 UI（对象初始化器 / gcnew 三步），C++/CLI 还要外加"混合模式 DLL + C# 启动器"解决 NETSDK1116。

---
上一章：无 ｜ 下一章：[02 应用骨架与生命周期](02-app-lifecycle.md)
