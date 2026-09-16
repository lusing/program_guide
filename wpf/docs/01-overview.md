# 01 · WPF 概述与架构

## 1. WPF 是什么

Windows Presentation Foundation (WPF) 是微软 2006 年随 .NET Framework 3.0 发布的桌面 UI 框架，也是第一个把"界面描述"与"业务逻辑"彻底分开的微软 UI 技术：界面用 XAML（一种 XML 方言）声明，逻辑用 C# 编写。渲染不再走 GDI/GDI+，而是基于 DirectX 的硬件加速管线。

一句话定位：**WPF 是 .NET 平台上"声明式界面 + 数据绑定驱动"的 Windows 桌面框架**。

- 窗口和控件不是 GDI 句柄的包装，而是"可视化树"上的 .NET 对象
- 控件外观不是固定的，可以被模板（Template）整个重写
- 界面更新的主驱动力不是消息处理函数，而是**数据绑定**：数据变了，界面自己变

本教程基于 .NET 10（当前 LTS 之后的新一代版本），WPF 自 .NET Core 3.0 起已随开源 .NET 发布，微软持续维护。

## 2. WPF 在 Windows UI 谱系中的位置

| | Win32 | MFC | WinForms | WPF | WinUI 3 |
|---|---|---|---|---|---|
| 语言 | C/C++ | C++ | C# | C# | C#/C++ |
| 渲染 | GDI/User32 | GDI | GDI+ | **DirectX** | Composition |
| 界面描述 | 手工/资源脚本 | 资源脚本 | 代码 | **XAML** | XAML |
| 数据绑定 | 无 | 无（DDX 是快照式） | 简陋 | **强** | 强 |
| 自定义外观 | 自绘 | 自绘 | 困难 | **模板重写** | 模板重写 |
| 运行时依赖 | 无 | 无/VC 运行库 | .NET | .NET | .NET + Windows App SDK |

值得注意的两条线：

1. **WPF 继承自 WinForms 之后的反思**。WinForms 是 Win32 控件的薄包装，WPF 则重造了整个渲染与控件体系——所以 WPF 控件的属性、事件、布局与 Win32 世界几乎完全不同，学习曲线更陡，但天花板也更高
2. **WinUI 3 是 XAML 语法的后代**。学懂 WPF 的 XAML、绑定、样式体系，迁移到 WinUI 3/UWP 几乎是平移；反过来不成立

## 3. 五个核心概念（全书骨架）

后面每一章都在展开这五件事，先混个脸熟：

| 概念 | 一句话 | 详见 |
|---|---|---|
| XAML | 用 XML 声明对象树，编译进程序集 | 第 03 章 |
| 依赖属性 | 支持"由外部决定值"的属性系统，绑定/样式/动画的地基 | 第 03 章 |
| 布局 | 每帧两遍测量（Measure→Arrange），面板递归协商尺寸 | 第 04 章 |
| 数据绑定 | `界面属性 ↔ 数据对象属性` 的自动同步 | 第 06 章 |
| MVVM | 把界面状态抽到 ViewModel 类，界面只剩声明 | 第 07 章 |

还有一条贯穿全书的原则：**UI 元素只能被创建它的那个线程访问**。WPF 应用本质是一个 STA 线程上的消息循环（Dispatcher），任何后台线程想更新界面都要回到这个线程——这是第 09 章的主题，也是和 MFC 的 `PostMessage` 回 UI 线程同一个思想。

## 4. 2026 年还该学/用 WPF 吗

该用的场合：

- **企业内部工具、生产力桌面软件**：WPF 至今是 Windows 上"重逻辑、长周期"桌面应用的主力框架（Visual Studio 自己就是 WPF 写的）
- **维护存量代码**：大量金融、医疗、工业软件是 WPF 的
- **需要深度定制外观**：模板体系可以重写任何控件的任何部位，不需要自绘
- **想学 XAML 家族**：WinUI 3、MAUI、UWP 全是同一套语法

不该用的场合：

- 跨平台 → MAUI / Qt / Electron / Web
- 极小体积的原生 exe → MFC / Win32（WPF 程序至少带 .NET 运行时）
- 追求最新 Fluent 视觉风格的开箱即用 → WinUI 3

## 5. 开发环境

本教程使用的本机工具链：

| 组件 | 路径 / 版本 |
|---|---|
| .NET SDK | `G:\scoop\apps\dotnet-sdk\current\dotnet.exe`（.NET 10） |
| 构建方式 | `dotnet build`（不需要 Visual Studio） |
| 编辑器 | 任意；VS 2022 / VS Code + C# Dev Kit 体验更好 |

唯一硬性要求是 .NET SDK（含 Windows Desktop 运行时，SDK 安装包自带）。验证安装：

```powershell
dotnet --version   # 输出 10.x
```

## 6. 用命令行构建 WPF 程序

Visual Studio 向导生成的工程很庞大，但 WPF 程序的本质只需要：**一个 csproj + App.xaml + MainWindow.xaml**。本目录的 `build.ps1` 逐个调用 `dotnet build` 编译全部示例：

```powershell
cd G:\code\guide\wpf
.\build.ps1        # 构建全部示例（还原依赖 + 编译）
```

示例项目文件（`01_hello_wpf/HelloWpfApp.csproj`）全貌：

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>          <!-- GUI 程序，不弹控制台 -->
    <TargetFramework>net10.0-windows</TargetFramework>  <!-- -windows 后缀 = 允许 Windows 专属 API -->
    <UseWPF>true</UseWPF>                    <!-- 引入 WPF 程序集 + XAML 编译管线 -->
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
</Project>
```

三行是 WPF 的开关：`OutputType=WinExe`、`net10.0-windows`、`UseWPF`。没有其他魔法。

## 7. 本教程的结构

- 每章正文在 `docs/`，对应示例在 `examples/NN_<名字>/`，示例代码全部在正文中讲解过，且都被 `build.ps1` 编译验证
- 第 12 章是一个完整实战项目 `10_notepad_plus`（MVVM 架构的记事本+），把全书知识串起来
- 学习路线建议按章顺序走：02 骨架 → 03 XAML → 04 布局 → 05 控件 → 06 绑定 → 07 MVVM（核心三连）→ 08 样式 → 09 异步 → 10 对话框 → 11 导航 → 12 实战

## 8. 第一个程序

`examples/01_hello_wpf` 是最小的可运行 WPF 程序，主窗口就三个控件：

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
| 应用对象 | `App`（App.xaml） | 入口，管生命周期与全局资源 |
| 主窗口 | `MainWindow` | XAML 声明界面树，分部类接事件 |
| 布局 | `Grid` + `StackPanel` | 嵌套面板负责子元素排布 |
| 交互 | `Click` 事件 | 最原始的处理方式（第 07 章会被命令取代） |

第 02~03 章把这个骨架逐行拆开。

---
上一章：无 ｜ 下一章：[02 应用骨架与生命周期](02-app-lifecycle.md)
