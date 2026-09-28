// 03 窗体属性、生命周期与两种子窗体（F# 版）
// F# 写 WinForms 窗体类：inherit Form + 构造函数里搭界面；自定义事件用 Event<string>() + [<CLIEvent>]
module FormsFs.Program

open System
open System.Drawing
open System.Windows.Forms

// ═══ 3.4 模态子窗体 ═══
type NameDialog() as this =
    inherit Form()

    let nameBox = new TextBox(Dock = DockStyle.Top)

    do
        this.Text <- "输入姓名"
        this.FormBorderStyle <- FormBorderStyle.FixedDialog
        this.MaximizeBox <- false
        this.MinimizeBox <- false
        this.ClientSize <- Size(320, 120)
        this.StartPosition <- FormStartPosition.CenterParent
        this.Font <- new Font("微软雅黑", 10F)

        let label = new Label(Text = "姓名：", Dock = DockStyle.Top, Height = 32,
                              TextAlign = ContentAlignment.MiddleLeft)
        let ok = new Button(Text = "确定", DialogResult = DialogResult.OK,
                            Dock = DockStyle.Left, Width = 96)
        let cancel = new Button(Text = "取消", DialogResult = DialogResult.Cancel,
                                Dock = DockStyle.Right, Width = 96)
        this.AcceptButton <- ok
        this.CancelButton <- cancel
        this.Controls.Add ok
        this.Controls.Add cancel
        this.Controls.Add nameBox
        this.Controls.Add label

    member _.UserName = nameBox.Text

// ═══ 3.5 非模态子窗体：Event<string> + CLIEvent 向外发消息 ═══
type FloatingWindow() as this =
    inherit Form()

    let titleChanged = Event<string>()

    do
        this.Text <- "浮动窗口"
        this.ClientSize <- Size(300, 150)
        let mutable ticks = 0
        let shout = new Button(Text = "向主窗体发消息", Dock = DockStyle.Fill)
        shout.Click.Add(fun _ ->
            ticks <- ticks + 1
            titleChanged.Trigger $"第 {ticks} 次汇报")
        this.Controls.Add shout

    /// 暴露给 C#/F# 订阅方的事件（[<CLIEvent>] 让它成为真正的 .NET 事件）
    [<CLIEvent>]
    member _.TitleChanged = titleChanged.Publish

// ═══ 3.1 主窗体 ═══
type MainForm() as this =
    inherit Form()

    let log = new ListBox(Dock = DockStyle.Fill)
    let addLog (msg: string) =
        // F# 插值坑：$"{expr:格式}" 只认简单标识符，DateTime.Now 后跟 ':' 会 FS0010，
        // 先拼好时间串再进插值
        let ts = DateTime.Now.ToString("HH:mm:ss")
        log.Items.Insert(0, $"{ts}  {msg}") |> ignore
    let mutable modalCount = 0

    do
        this.Text <- "窗体与生命周期"
        this.ClientSize <- Size(560, 380)
        this.StartPosition <- FormStartPosition.CenterScreen
        this.Font <- new Font("微软雅黑", 10F)

        let openModal = new Button(Text = "模态：输入姓名(S)", Dock = DockStyle.Top, Height = 36)
        let openModeless = new Button(Text = "非模态：浮动窗口", Dock = DockStyle.Top, Height = 36)

        openModal.Click.Add(fun _ ->
            use dlg = new NameDialog()
            if dlg.ShowDialog(this) = DialogResult.OK then
                modalCount <- modalCount + 1
                addLog $"模态返回 OK，姓名 = {dlg.UserName}（第 {modalCount} 次）"
            else
                addLog $"模态返回 {dlg.DialogResult}（用户取消）")

        openModeless.Click.Add(fun _ ->
            let win = new FloatingWindow(Owner = this)
            win.TitleChanged.Add(addLog)
            win.Show(this)
            addLog "非模态窗口已打开（Show 立即返回）")

        log.Items.Add "构造函数执行完毕（此时窗体还不可见）" |> ignore

        this.Controls.Add log
        this.Controls.Add openModeless
        this.Controls.Add openModal

        // ═══ 3.2 生命周期事件 ═══
        this.Load.Add(fun _ -> addLog "Load：窗体首次显示前（做初始化的好地方）")
        this.Shown.Add(fun _ -> addLog "Shown：窗体已经显示出来（Load 之后必有一次）")
        this.Activated.Add(fun _ -> addLog "Activated：成为活动窗口（切回来也会再触发）")
        this.Deactivate.Add(fun _ -> addLog "Deactivate：失去焦点（点了别的窗口）")

        // ═══ 3.3 关闭确认 ═══
        this.FormClosing.Add(fun e ->
            let r = MessageBox.Show($"日志里有 {log.Items.Count} 条记录，确定退出？",
                                    "关闭确认", MessageBoxButtons.YesNo, MessageBoxIcon.Question)
            if r = DialogResult.No then e.Cancel <- true)

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    Application.Run(MainForm())
    0
