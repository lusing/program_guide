open System
open System.Drawing
open System.Windows.Forms

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
