# 02 · 第一个 WinForms 程序

> 对应示例：`examples/02_hello/{csharp,fsharp,cpp}`（三语言同功能：一个带按钮的窗体，点击改标签文字并计数）

> **本章你将学会**：窗体与控件的最小骨架、消息循环、事件接线、三语言工程形态。
> **前置章节**：[01 全景](01-overview.md)。

## 1. C#：30 行的完整程序

```csharp
using System.Drawing;
using System.Windows.Forms;

namespace HelloWin;

internal class MainForm : Form
{
    private int _count = 0;
    private readonly Label _label = new();
    private readonly Button _button = new();

    public MainForm()
    {
        Text = "你好，WinForms（C#）";          // 标题栏
        Width = 420; Height = 170;
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        _label.Text = "等你点击下面的按钮";
        _label.Dock = DockStyle.Top;           // 贴顶
        _button.Text = "点我一下";
        _button.Dock = DockStyle.Bottom;       // 贴底
        _button.Click += (sender, e) =>        // 事件接线：委托挂到 Click
        {
            _count++;
            _label.Text = $"第 {_count} 次点击";
        };

        Controls.Add(_label);                  // 挂到父容器才可见
        Controls.Add(_button);
    }
}

internal static class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
    }
}
```

四个要点：

1. **窗体是一个类**。设计器生成的 `Form1.cs + InitializeComponent()` 与手写构造函数等价——本教程全部手写，看得见每一行。
2. **控件三步曲**：`new` → 设属性 → `Controls.Add`。忘掉第三步是新手第一大坑（不报错、就是不显示）。
3. **`Application.Run(form)` 是消息循环**：显示窗体、分发鼠标键盘消息，直到窗体关闭才返回。这行之前你的代码跑一遍，之后的代码在循环里。
4. **`[STAThread]` 不可省**：剪贴板、文件对话框等 Shell 功能要求 UI 线程是单线程单元。

## 2. 三个 Application 调用的顺序铁律

```csharp
Application.EnableVisualStyles();                     // 系统视觉样式（按钮的现代外观）
Application.SetCompatibleTextRenderingDefault(false); // 文本统一 GDI 渲染
Application.Run(new MainForm());
```

前两个必须在**创建任何窗体/控件之前**调用。C# 的习惯写法天然满足（窗体在 `Run(...)` 的参数里才构造）。F# 平铺风格则会踩坑——见下。

### 实测坑（F# 专属）：顺序反了直接崩

F# 的顶层 `let` 按顺序执行，顺手写成：

```fsharp
let main _ =
    let form = new Form(Text = "…")       // ① 先建了窗体
    …
    Application.EnableVisualStyles()       // ② 再调这两个 → 运行时炸
    Application.SetCompatibleTextRenderingDefault false
    Application.Run form
```

启动即抛 `InvalidOperationException: 调用 SetCompatibleTextRenderingDefault 之前，应用程序中已创建了一个 IWin32Window`（退出码 -532462766）。更阴的是：**部分控件组合碰巧不触发**——曾出现四个示例崩、五个正常的"灵异"局面。正解是把两个调用放到 `let main _ =` 的第一行：

```fsharp
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    let form = new Form(…)                 // 窗体在后面
```

本教程所有 F# 示例开头都有这两行 + 注释。

## 3. F# 版

```fsharp
module HelloFs.Program

open System.Drawing
open System.Windows.Forms

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "你好，WinForms（F#）", Width = 420, Height = 170)
    form.StartPosition <- FormStartPosition.CenterScreen

    let label = new Label(Text = "等你点击下面的按钮", Dock = DockStyle.Top, Height = 60)
    let button = new Button(Text = "点我一下", Dock = DockStyle.Bottom, Height = 45)

    let mutable count = 0
    button.Click.Add(fun _ ->              // F# 事件接线用 .Add
        count <- count + 1
        label.Text <- $"第 {count} 次点击")

    form.Controls.Add label
    form.Controls.Add button

    Application.Run form
    0
```

差异速记：

| C# | F# |
|---|---|
| `class MainForm : Form` | 小例子直接 `let form = new Form(属性初始化器)` |
| `btn.Click += (s,e) => …` | `btn.Click.Add(fun _ -> …)` |
| 属性初始化器 `{ Text = "…" }` | 构造参数 `new Form(Text = "…")` |
| `$"第 {n} 次"` | 同款 `$"第 {n} 次"`（规则有差异，见 06 章） |

事件还有 F# 独有的 `Observable.subscribe` 管道——[11 章](11-events.md)细讲。

## 4. C++/CLI 版

```cpp
using namespace System;
using namespace System::Windows::Forms;

namespace HelloCpp {

    public ref class MainForm : public Form
    {
    public:
        MainForm()
        {
            Text = L"你好，WinForms（C++/CLI）";
            _button->Click += gcnew EventHandler(this, &MainForm::OnClick);
            …
        }
    private:
        void OnClick(Object^ sender, EventArgs^ e) { … }
    };

    public ref class App
    {
    public:
        static void Run()
        {
            Application::EnableVisualStyles();
            Application::SetCompatibleTextRenderingDefault(false);
            Application::Run(gcnew MainForm());
        }
    };
}
```

语法地图（后面每一章都在用）：

| 概念 | C# | C++/CLI |
|---|---|---|
| 托管分配 | `new T(...)` | `gcnew T(...)`，变量类型 `T^` |
| 成员访问 | `btn.Text` | `btn->Text` |
| 宽字符串 | `"中文"` | `L"中文"` |
| 事件挂成员函数 | `this.OnClick +=`（方法组） | `gcnew EventHandler(this, &T::OnClick)` |
| 程序入口 | `Program.Main` | **DLL 没有 exe 入口** → `cpp/host/` 的 C# 启动器调 `HelloCpp.App.Run()` |

`.cpp` 文件无 BOM 且含中文时，vcxproj 必须带 `/utf-8`（本教程由 `Cpp.Common.props` 统一注入，[01 章 §5-④](01-overview.md)）。

## 5. 跑起来

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -Chapter 02_hello
pwsh -ExecutionPolicy Bypass -File smoke.ps1        # OK 三个 exe
```

或直接：`cd examples/02_hello/csharp; dotnet run`。

## 坑位清单

1. **控件忘了 `Controls.Add`**：不显示、不报错。
2. **F#：`EnableVisualStyles`/`SetCompatibleTextRenderingDefault` 放在窗体创建之后**：启动即 InvalidOperationException（部分控件组合"侥幸"通过，别赌）。
3. **C++/CLI：host 工程忘了 `-p:Platform=x64`**：混合模式 DLL 是 x64，host 按 AnyCPU 装载失败。
4. **C++/CLI：源码中文无 BOM 且没传 `/utf-8`**：C2001"字符串字面量中的换行符"等怪错。

## 自测

1. `Application.Run` 前后代码的执行时机有什么本质区别？
2. `[STAThread]` 服务于哪些功能？
3. F# 版为什么把两个 Application 调用放最前？报错的异常类型是什么？
4. C++/CLI 版的 exe 入口在哪？它如何进入 `HelloCpp.App.Run()`？
5. `DockStyle.Top` 和 `DockStyle.Bottom` 同时用在本例里，控件上下位置为什么不会重叠？

---

上一章：[01 全景与三语言路线](01-overview.md) · 下一章：[03 窗体与生命周期](03-forms.md)
