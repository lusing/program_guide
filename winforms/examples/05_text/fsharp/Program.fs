// 05 文本类控件（F# 版）
module TextFs.Program

open System
open System.Diagnostics
open System.Drawing
open System.Windows.Forms

[<EntryPoint>]
[<STAThread>]
let main _ =
    // 顺序铁律：EnableVisualStyles / SetCompatibleTextRenderingDefault 必须先于任何窗体创建
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    let form = new Form(Text = "文本类控件", ClientSize = Size(640, 480),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    // ═══ 5.1 单行输入三件套 ═══
    let login = new GroupBox(Text = " 单行输入 ", Dock = DockStyle.Top, Height = 130)

    let user = new TextBox(Location = Point(100, 28), Width = 180, MaxLength = 12)
    let pwd = new TextBox(Location = Point(100, 64), Width = 180, UseSystemPasswordChar = true)
    let age = new NumericUpDown(Minimum = 1m, Maximum = 120m, Value = 18m)
    age.SetBounds(370, 28, 110, 30)

    let status = new Label(Dock = DockStyle.Bottom, Height = 28,
                           TextAlign = ContentAlignment.MiddleLeft, BackColor = Color.Gainsboro)

    // 注意：先设 Value 再挂事件，避免初始化期间回调读到还没创建的 status
    age.ValueChanged.Add(fun _ ->
        status.Text <- $"  年龄 = {age.Value}（NumericUpDown 自带上下箭头与校验）")

    let echo = new Button(Text = "回显", Location = Point(300, 62), Width = 90)
    echo.Click.Add(fun _ ->
        MessageBox.Show($"用户名「{user.Text}」长度 {user.Text.Length}\n密码（明文在内存里）「{pwd.Text}」",
                        "回显", MessageBoxButtons.OK, MessageBoxIcon.Information) |> ignore)

    // F# 坑：异构控件数组不会自动上转，显式标注 Control[] 才行
    let loginControls: Control[] =
        [| new Label(Text = "用户名：", AutoSize = true, Location = Point(16, 32))
           user
           new Label(Text = "密码：", AutoSize = true, Location = Point(16, 68))
           pwd
           new Label(Text = "年龄：", AutoSize = true, Location = Point(300, 32))
           age; echo |]
    login.Controls.AddRange loginControls

    // ═══ 5.2 RichTextBox ═══
    let rich = new RichTextBox(Dock = DockStyle.Fill, AcceptsTab = true,
                               ScrollBars = RichTextBoxScrollBars.Vertical,
                               Text = "普通文本一行。\n选中一段文字再点「加粗选中」试试。\n")
    let richLabel = new Label(Text = "RichTextBox（彩色追加 / 选区加粗 / 字数统计）",
                              Dock = DockStyle.Top, Height = 26)

    // 彩色追加 = 先把插入点挪到末尾，设置 SelectionColor，再 AppendText
    let appendColored (text: string) (color: Color) =
        rich.SelectionStart <- rich.Text.Length
        rich.SelectionLength <- 0
        rich.SelectionColor <- color
        rich.AppendText text
        rich.SelectionColor <- rich.ForeColor

    // ═══ 5.3 工具条 ═══
    let tools = new FlowLayoutPanel(Dock = DockStyle.Top, Height = 44)
    let mkBtn caption onClick =
        let b = new Button(Text = caption, AutoSize = true)
        b.Click.Add(onClick) ; b
    let toolControls: Control[] =
        [| mkBtn "追加红字" (fun _ -> appendColored "这是红色追加的一行\n" Color.Firebrick)
           mkBtn "追加蓝字" (fun _ -> appendColored "这是蓝色追加的一行\n" Color.RoyalBlue)
           mkBtn "加粗选中" (fun _ ->
                if rich.SelectionLength = 0 then
                    MessageBox.Show "先选中一段文字" |> ignore
                else
                    rich.SelectionFont <- new Font(rich.Font, rich.SelectionFont.Style ||| FontStyle.Bold))
           mkBtn "字数统计" (fun _ ->
                MessageBox.Show($"字符数 {rich.Text.Length}，当前选区 {rich.SelectionLength} 字", "统计") |> ignore) |]
    tools.Controls.AddRange toolControls

    // ═══ 5.4 LinkLabel ═══
    let link = new LinkLabel(Text = "遇到问题？查阅 Microsoft Learn 的 WinForms 文档",
                             Dock = DockStyle.Bottom, Height = 34,
                             LinkBehavior = LinkBehavior.HoverUnderline)
    link.Links.Add(8, 15, "https://learn.microsoft.com/dotnet/desktop/winforms/")
    link.LinkClicked.Add(fun e ->
        let url = e.Link.LinkData :?> string
        Process.Start(ProcessStartInfo(FileName = url, UseShellExecute = true)) |> ignore
        link.LinkVisited <- true)

    form.Controls.Add rich
    form.Controls.Add tools
    form.Controls.Add richLabel
    form.Controls.Add status
    form.Controls.Add login
    form.Controls.Add link

    Application.Run form
    0
