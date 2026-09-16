open System
open System.Windows
open System.Windows.Controls
open System.Windows.Media

[<EntryPoint>]
[<STAThread>]
let main _ =

    // ═══ 19.3 Application、Window 与内容模型 ═══
    let app = new Application()
    let window = new Window(Title = "F# WPF Demo", Width = 460.0, Height = 260.0)
    window.WindowStartupLocation <- WindowStartupLocation.CenterScreen

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
    stack.Children.Add(input) |> ignore
    stack.Children.Add(button) |> ignore
    stack.Children.Add(result) |> ignore
    window.Content <- stack

    let _ = app.Run(window)
    0
