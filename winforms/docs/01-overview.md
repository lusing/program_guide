# 01 · WinForms 全景与三语言路线

> 本教程无独立示例——从[第 02 章](02-hello.md)开始每章一个可运行工程。

> **本章你将学会**：WinForms 在现代 .NET 里的位置、C#/F#/C++/CLI 三条路线的分工、构建工具链、C++/CLI 路线的五条硬事实。
> **前置**：会任何一个 .NET 语言的基础语法（[csharp](../../csharp/README.md) / [fsharp](../../fsharp/README.md) / [dotnet](../../dotnet/README.md) 教程任一）。

## 1. WinForms 是什么

WinForms 是 .NET 最老的 UI 框架（2002 年随 .NET Framework 发布），封装的是 **Win32 控件**——按钮、文本框、列表都是真正的系统控件。它的模型极其直白：

- **窗体即对象**：一个 `Form`，往里 `Controls.Add(...)` 控件
- **属性摆外观，事件接行为**：`btn.Text = "点我"`、`btn.Click += ...`
- **消息循环驱动**：`Application.Run(form)` 推入循环，直到窗体关闭

没有 XAML、没有数据模板、没有视觉树——代价是定制能力有限，换来的是**学习曲线最平**和**对 Win32 生态的直接映射**（和 [win32](../../win32/README.md) 教程互为参照）。

### 与其它桌面框架的分工

| 框架 | 渲染 | 强项 | 本仓库教程 |
|---|---|---|---|
| WinForms | 系统控件 | 表单类应用、开发速度 | 本教程 |
| WPF | 自绘（DirectX） | 数据绑定/MVVM、富定制 | [wpf](../../wpf/README.md) |
| WinUI 3 | 自绘（Composition） | 现代 Windows 11 外观 | [WinUI3](../../WinUI3/README.md) |
| Win32 原生 | 系统控件 | 无运行时依赖、极致控制 | [win32](../../win32/README.md) |

**选型口诀**：内部工具/表单/改老项目 → WinForms；外观与绑定是主角 → WPF；要上架商店 → WinUI 3。

### 从"被淘汰"到回归

.NET Core 2.x 时代 WinForms/WPF 曾被排除在跨平台之外；**.NET Core 3.0（2019）起两者回归**，仅限 Windows 但持续维护到 .NET 10（本教程主线）。参考书《.NET Core实战——380个精彩案例》（2019）整本只讲控制台与 ASP.NET Core——恰好是那个"桌面缺席"时期的写照；而《WinForm程序设计与实践》（清华，2018）教的 API 到 .NET 10 依然有效，这正是本教程按它重构的底气：**传输层十年的稳定**。

## 2. 三语言路线

本教程每章示例都有三份实现，功能一致：

| | C# | F# | C++/CLI |
|---|---|---|---|
| 位置 | `examples/NN/csharp/` | `examples/NN/fsharp/` | `examples/NN/cpp/` + `cpp/host/` |
| 窗体 | `class MainForm : Form` | 平铺 `let` 或 `type ... inherit Form` | `public ref class MainForm : public Form` |
| 事件接线 | `btn.Click += (s,e) => …` | `btn.Click.Add(fun _ -> …)` | `gcnew EventHandler(this, &T::OnX)` |
| 工程文件 | `.csproj`（`dotnet build`） | `.fsproj`（`dotnet build`） | `.vcxproj`（**VS MSBuild**） |
| 入口 | `Program.Main` | `[<EntryPoint>]` | **混合模式 DLL + C# 启动器** |

三语言的 WinForms API 是同一套（`System.Windows.Forms` + `System.Drawing`），差异全在语言接线层——每章文档都有三语言对照小节。

## 3. 工具链与构建

```powershell
cd G:\code\guide\winforms
pwsh -ExecutionPolicy Bypass -File build.ps1            # 全部示例（约 5 分钟，C++ 部分较慢）
pwsh -ExecutionPolicy Bypass -File build.ps1 -Chapter 14_binding
pwsh -ExecutionPolicy Bypass -File build.ps1 -Lang fsharp
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean
pwsh -ExecutionPolicy Bypass -File smoke.ps1             # 冒烟：每个 exe 拉起 3 秒不崩
```

- **C#/F#**：`dotnet build -c Release`，产物在 `examples/NN/{csharp,fsharp}/bin/Release/net10.0-windows/`
- **C++/CLI**：VS 2026 MSBuild（v145 工具集 + `Microsoft.VisualStudio.Component.VC.CLI.Support` 组件），host 工程经 ProjectReference 把 vcxproj 一起编出来
- 冒烟判据与 [wpf](../../wpf/README.md) 一致：**进程 3 秒不退出 = 窗体正常显示**

## 4. C++/CLI 是什么

C++/CLI 是 C++ 的托管扩展：`^` 句柄（托管堆指针）、`gcnew`（托管分配）、`ref class`（托管类）。它能**在同一程序集里混编原生 C++ 与托管代码**（"混合模式程序集"），是 C++ 侧使用 .NET 的正统通道（`/clr` 编译开关，工程里体现为 `<CLRSupport>NetCore</CLRSupport>`）。

WinForms 三语言里它的语法噪音最大（见每章对照），但它是**唯一的原生互操作答案**：现有 C++ 代码库想加个 .NET UI、或者要 P/Invoke 塞不下的原生结构——就是它。

## 5. C++/CLI 路线的五条硬事实（全部实测）

**① .NET Core/.NET 10 上的 C++/CLI 只能产 DLL。** exe 直接报：

```text
error NETSDK1116: 面向 .NET Core 的 C++/CLI 项目必须是动态库。
```

所以每个 cpp 示例是"混合模式 DLL（真正的 UI 代码）+ C# 启动器 exe（10 行）"：

```text
cpp/
├── HelloCpp.vcxproj     混合模式 DLL
├── HelloCpp.cpp         namespace HelloCpp { public ref class App { static void Run() … } }
└── host/
    ├── HelloHost.csproj ProjectReference → vcxproj
    └── Program.cs       [STAThread] static void Main() => HelloCpp.App.Run();
```

**② 裸 `<Reference Include="System.Windows.Forms"/>` 会解析到 .NET Framework 2.0 的旧程序集。** 编译期一串 C4691 警告（版本 2.0.0.0），运行时行为不可预期。必须 HintPath 指向 WindowsDesktop **目标包**（ref pack）：

```xml
<Reference Include="System.Windows.Forms">
  <HintPath>C:\Program Files\dotnet\packs\Microsoft.WindowsDesktop.App.Ref\10.0.12\ref\net10.0\System.Windows.Forms.dll</HintPath>
</Reference>
```

本教程统一放在根目录 [Cpp.Common.props](../Cpp.Common.props)，需要一揽子引用（见下一条）。

**③ 现代程序集拆分把类型打散了，编译器会点名要程序集。** 实测至少要引 6 个：`System.Windows.Forms`、`System.Windows.Forms.Primitives`（Padding 在这）、`System.Drawing`（门面）、`System.Drawing.Common`、`System.Drawing.Primitives`（Point/Color/ContentAlignment）、`System.Private.Windows.Core`（AddRange 的签名牵出的模块）。C3465/C3624 错误信息会直接告诉你缺哪个。

**④ 源码含中文必须给 cl 传 `/utf-8`**（无 BOM 文件按 ANSI 读会出 C2001"字符串字面量中的换行符"之类怪错）。已写进 Cpp.Common.props。

**⑤ 一批"属性名遮蔽类型名"的坑。** Form 子类内部，属性 `FormBorderStyle`、`DialogResult`、`AutoScaleMode`、`ContextMenuStrip`、`MouseButtons` 会遮蔽**同名枚举类型**，写 `FormBorderStyle::FixedDialog` 直接报错，要 `System::Windows::Forms::FormBorderStyle::FixedDialog` 全限定。同名的还有两个 Timer（`System::Threading` vs `System::Windows::Forms`，见 16 章）。

另外：C++/CLI 没有lambda，闭包场景用"Tag 随身带数据 + 成员函数处理器"或小状态类（17 章有完整示例）。

## 6. 目录结构

```text
winforms/
├── README.md               本教程索引
├── build.ps1 / smoke.ps1   构建 / 冒烟（须 PowerShell 7）
├── global.json             SDK 钉在 10.0.*
├── Cpp.Common.props        所有 vcxproj 的公共引用与开关
└── examples/               02 → 20（章号 = 示例号）
    └── 14_binding/         每章：csharp/ fsharp/ cpp/（+ cpp/host/）
```

## 自测

1. WinForms 与 WPF 最根本的差别是什么？（提示：谁在画控件）
2. .NET Core 从哪个版本起重新支持 WinForms？跨平台吗？
3. C++/CLI 在 .NET 10 上能直接产出 exe 吗？本教程用什么结构绕过？
4. vcxproj 里裸写 `<Reference Include="System.Windows.Forms"/>` 会发生什么？正确写法？
5. 为什么 `Padding` 要引 `System.Windows.Forms.Primitives`？

---

下一章：[02 第一个程序](02-hello.md)
