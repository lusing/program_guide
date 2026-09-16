# 19 · 桌面 GUI：WinForms 与 WPF

> 对应示例：examples/19_gui（嵌套 winforms / wpf 双工程，仅构建验证）

## 19.1 解决什么问题

F# 做桌面工具完全可行：.NET 的两大 UI 栈（WinForms 拖控件、WPF 数据绑定）都能用 F# 驱动。本章各写一个最小可交互窗口，讲清 fsproj 配置、控件树、事件三件事，并给"函数式怎么想 UI"的视角。

## 19.2 fsproj 配置

| | WinForms | WPF |
|---|---|---|
| 开关 | `<UseWindowsForms>true</UseWindowsForms>` | `<UseWPF>true</UseWPF>` |
| 框架 | `net10.0-windows` | `net10.0-windows` |
| 输出 | `WinExe`（无控制台窗） | `WinExe` |

`net10.0-windows` 的 `-windows` 后缀是桌面 API 的钥匙，忘写直接报类型不存在。GUI 工程只在 Windows 桌面跑——build.ps1 对它们**只构建不运行**（弹窗口没法自动化验证），两个示例都实际编译通过。

## 19.3 WinForms：控件树 + Location 布局

`examples/19_gui/winforms/Program.fs` 全景（节选）：

```fsharp
[<EntryPoint>]
[<STAThread>]
let main _ =

    // ═══ 19.1 窗体与控件 ═══
    let form = new Form(Text = "F# WinForms Demo", Width = 420, Height = 260)
    form.StartPosition <- FormStartPosition.CenterScreen

    let titleLabel = new Label(Text = "F# WinForms 基础示例", Location = Point(24, 24), Width = 220)
    let input = new TextBox(Text = "hello from F#", Location = Point(24, 60), Width = 250)
    let button = new Button(Text = "点击", Location = Point(24, 100), Width = 120)
    let result = new Label(Text = "等待点击...", ForeColor = Color.DarkBlue, Location = Point(24, 150), Width = 300)

    // ═══ 19.2 事件处理：Click.Add ═══
    button.Click.Add(fun _ ->
        let message = if String.IsNullOrWhiteSpace input.Text then "输入为空" else sprintf "你好，%s" input.Text
        result.Text <- message)

    form.Controls.Add(titleLabel)
    form.Controls.Add(input)
    form.Controls.Add(button)
    form.Controls.Add(result)

    Application.EnableVisualStyles()
    Application.Run(form)
    0
```

要点：`[<STAThread>]` 必须（COM/剪贴板线程模型）；控件属性在构造器里一次给（F# 对象初始化语法）；布局用 `Location = Point(x, y)` 绝对坐标（简单工具够用，复杂表单上 TableLayoutPanel）；`Controls.Add` 挂控件树。

## 19.4 WPF：内容模型 + 面板布局

`examples/19_gui/wpf/Program.fs`（节选）：

```fsharp
// ═══ 19.3 Application、Window 与内容模型 ═══
let app = new Application()
let window = new Window(Title = "F# WPF Demo", Width = 460.0, Height = 260.0)

// ═══ 19.4 面板布局与控件树 ═══
let stack = new StackPanel(Orientation = Orientation.Vertical, Margin = Thickness(20.0))
let title = new TextBlock(Text = "F# WPF 基础示例", FontSize = 20.0)
let input = new TextBox(Text = "hello from F#", Width = 260.0)
let button = new Button(Content = "点击", Width = 120.0, Margin = Thickness(0.0, 12.0, 0.0, 0.0))
let result = new TextBlock(Text = "等待点击...", Margin = Thickness(0.0, 12.0, 0.0, 0.0), Foreground = Brushes.DarkBlue)

// ═══ 19.5 事件处理：Click.Add（与 WinForms 同源，连第 18 章）═══
button.Click.Add(fun _ ->
    let text = if String.IsNullOrWhiteSpace input.Text then "输入为空" else sprintf "你好，%s" input.Text
    result.Text <- text)

stack.Children.Add(title) |> ignore
// …
window.Content <- stack
let _ = app.Run(window)
```

与 WinForms 的三处不同：`Content` 单子内容模型（Window.Content = 一个面板，面板再装孩子）；`StackPanel` 流式布局（不用坐标）；`Children.Add` 返回被加的元素要 `|> ignore`。XAML 文件与 C# 的 MVVM 全家桶在 F# 里可用但繁琐——纯代码建 UI 反而 F# 味道更正。

## 19.5 函数式视角：事件 → 新状态 → 渲染

两个示例里 `Click.Add` 的 lambda 就是"事件处理器"：读输入 → 算新文本 → 写回控件。函数式的推广是把中间那步做成**纯函数**（输入 record → 输出 record），事件处理器只做 IO 中转——这正是 MVU/Elmish 架构（F# 社区流行）的骨架，复杂 UI 的正解。

## 19.6 选型：WinForms 还是 WPF

| | WinForms | WPF |
|---|---|---|
| 上手 | 快（拖控件即所见） | 需懂布局/绑定模型 |
| 表达力 | 像素级简单 UI | 样式、模板、动画、复杂绑定 |
| 数据驱动 | 手写同步 | MVVM/绑定天然支持 |
| F# 手感 | 代码建 UI 顺畅 | 纯代码可行，XAML 麻烦 |

一句话：内部小工具用 WinForms 半天出活；面向用户的正式产品上 WPF（或跨平台的 Avalonia）。两个示例都在，跑一下（手动，脚本不弹窗）：

```bash
dotnet run --project examples/19_gui/winforms
dotnet run --project examples/19_gui/wpf
```

## 19.7 坑位清单

- **忘 `[<STAThread>]`**：运行时才炸，报错还不在明显位置——模板先写上。
- **忘 `-windows` 后缀 / UseWPF**：编译错误"类型未定义"，先查 fsproj 再查代码。
- **WPF `Children.Add` 忘 ignore**：返回值警告，加 `|> ignore`。
- **`EnableVisualStyles` 时机**：WinForms 要在 `Application.Run` 前调，否则控件朴素难看。
- **跨平台**：这两栈只在 Windows；要跨平台桌面看 Avalonia（生态推荐，超出本书范围）。
