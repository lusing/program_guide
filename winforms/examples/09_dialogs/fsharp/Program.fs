// 09 通用对话框（F# 版）
module DialogsFs.Program

open System
open System.IO
open System.Drawing
open System.Windows.Forms

[<EntryPoint>]
[<STAThread>]
let main _ =
    // 顺序铁律：EnableVisualStyles / SetCompatibleTextRenderingDefault 必须先于任何窗体创建
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    let form = new Form(ClientSize = Size(720, 480), StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let editor = new RichTextBox(Dock = DockStyle.Fill,
                                 Text = "改一个字看标题出现 *，再按 Ctrl+S 保存。\n格式菜单里四个对话框随便玩。\n")
    let mutable file: string option = None
    let mutable dirty = false

    let status = new ToolStripStatusLabel(Spring = true, TextAlign = ContentAlignment.MiddleLeft)
    let say msg = status.Text <- "  " + msg

    let updateTitle () =
        let name = match file with Some f -> Path.GetFileName f | None -> "未命名"
        let star = if dirty then " *" else ""
        let t = $"迷你编辑器——{name}{star}"
        form.Text <- t

    // ═══ 保存逻辑：saveAs = true 强制弹框 ═══
    let save saveAs =
        let pickPath () =
            use dlg = new SaveFileDialog(Filter = "文本文件|*.txt|所有文件|*.*",
                                         DefaultExt = "txt", AddExtension = true,
                                         OverwritePrompt = true, FileName = "新文档.txt")
            if dlg.ShowDialog(form) <> DialogResult.OK then None else Some dlg.FileName
        let target =
            if file.IsNone || saveAs then pickPath ()
            else file
        match target with
        | None -> say "取消保存"
        | Some path ->
            file <- Some path
            File.WriteAllText(path, editor.Text)
            dirty <- false
            updateTitle ()
            say $"已保存到 {path}"

    let menu = new MenuStrip()

    // ═══ 9.1 打开 ═══
    // F# 坑：位或表达式当命名实参的值必须括号包住（否则 ||| 被解析断开）
    let ctrlO = Keys.Control ||| Keys.O
    let miOpen = new ToolStripMenuItem(Text = "打开(&O)…", ShortcutKeys = ctrlO)
    miOpen.Click.Add(fun _ ->
        use dlg = new OpenFileDialog(Title = "挑一个文本文件",
                                     Filter = "文本文件|*.txt;*.md|日志|*.log|所有文件|*.*",
                                     InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
                                     CheckFileExists = true)
        if dlg.ShowDialog(form) = DialogResult.OK then
            editor.Text <- File.ReadAllText dlg.FileName
            file <- Some dlg.FileName
            dirty <- false
            updateTitle ()
            say $"打开 {dlg.FileName}")

    let ctrlS = Keys.Control ||| Keys.S
    let miSave = new ToolStripMenuItem(Text = "保存(&S)", ShortcutKeys = ctrlS)
    miSave.Click.Add(fun _ -> save false)
    let miSaveAs = new ToolStripMenuItem(Text = "另存为(&A)…")
    miSaveAs.Click.Add(fun _ -> save true)
    let miQuit = new ToolStripMenuItem(Text = "退出(&Q)")
    miQuit.Click.Add(fun _ -> form.Close())

    let fileMenu = new ToolStripMenuItem(Text = "文件(&F)")
    let fileItems: ToolStripItem[] =
        [| miOpen :> ToolStripItem; miSave; miSaveAs; new ToolStripSeparator(); miQuit |]
    fileMenu.DropDownItems.AddRange fileItems

    // ═══ 9.3 颜色 / 字体 ═══
    let miColor = new ToolStripMenuItem(Text = "文字颜色(&C)…")
    miColor.Click.Add(fun _ ->
        use dlg = new ColorDialog(Color = editor.ForeColor, FullOpen = true)
        if dlg.ShowDialog(form) = DialogResult.OK then
            editor.SelectionColor <- dlg.Color)

    let miFont = new ToolStripMenuItem(Text = "字体(&F)…")
    miFont.Click.Add(fun _ ->
        use dlg = new FontDialog(ShowColor = false, MinSize = 9, MaxSize = 36, FontMustExist = true)
        if dlg.ShowDialog(form) = DialogResult.OK then
            editor.SelectionFont <- dlg.Font)

    // ═══ 9.4 文件夹浏览 ═══
    let miDir = new ToolStripMenuItem(Text = "统计文件夹(&D)…")
    miDir.Click.Add(fun _ ->
        use dlg = new FolderBrowserDialog(Description = "选一个文件夹，统计里面文本文件的数量",
                                          UseDescriptionForTitle = true)
        if dlg.ShowDialog(form) = DialogResult.OK then
            let n = Directory.GetFiles(dlg.SelectedPath, "*.txt", SearchOption.TopDirectoryOnly).Length
            // 注意：枚举值当实参要留括号——F# 会把 SearchOption.TopDirectoryOnly 解析成命名参数报 FS0691
            say $"{dlg.SelectedPath} 下有 {n} 个 .txt（只看第一层）")

    let fmtMenu = new ToolStripMenuItem(Text = "格式(&M)")
    let fmtItems: ToolStripItem[] = [| miColor :> ToolStripItem; miFont; miDir |]
    fmtMenu.DropDownItems.AddRange fmtItems

    let menuItems: ToolStripItem[] = [| fileMenu :> ToolStripItem; fmtMenu |]
    menu.Items.AddRange menuItems

    editor.TextChanged.Add(fun _ ->
        dirty <- true
        updateTitle ())

    let statusStrip = new StatusStrip()
    statusStrip.Items.Add status
    say "就绪"

    // ═══ 9.5 关闭前三按钮确认 ═══
    form.FormClosing.Add(fun e ->
        if dirty then
            let r = MessageBox.Show(form,
                "内容有未保存的修改。\n「是」保存后退出，「否」直接退出，「取消」留在编辑器。",
                "迷你编辑器", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Warning)
            if r = DialogResult.Cancel then e.Cancel <- true
            elif r = DialogResult.Yes then
                save false
                if dirty then e.Cancel <- true)   // 保存被取消就别退出

    form.Controls.Add editor
    form.Controls.Add statusStrip
    form.Controls.Add menu
    form.MainMenuStrip <- menu
    updateTitle ()

    Application.Run form
    0
