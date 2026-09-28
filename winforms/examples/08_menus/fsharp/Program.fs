// 08 菜单、工具栏与状态栏（F# 版）
module MenusFs.Program

open System
open System.Drawing
open System.Windows.Forms

[<EntryPoint>]
[<STAThread>]
let main _ =
    // 顺序铁律：EnableVisualStyles / SetCompatibleTextRenderingDefault 必须先于任何窗体创建
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    let form = new Form(Text = "菜单工具栏示例——迷你编辑器", ClientSize = Size(720, 480),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let editor = new RichTextBox(Dock = DockStyle.Fill)
    editor.Text <- "试试：菜单、Ctrl+N、在正文里点右键、拖宽看状态栏数字。\n"

    // ═══ 8.5 状态栏 ═══
    let hint = new ToolStripStatusLabel(Spring = true, TextAlign = ContentAlignment.MiddleLeft)
    let count = new ToolStripStatusLabel(Text = "0 字")
    let status = new StatusStrip()
    let statusItems: ToolStripItem[] = [| hint; count |]
    status.Items.AddRange statusItems
    let say msg = hint.Text <- "  " + msg
    say "就绪"

    // ═══ 8.1 菜单栏 ═══
    // 小工厂：菜单项 = 文字 + 可选快捷键 + 点击行为
    let item text shortcut onClick =
        let mi = new ToolStripMenuItem(Text = text)
        if shortcut <> Keys.None then
            mi.ShortcutKeys <- shortcut      // 枚举位或先算好再赋值（命名实参里写 ||| 要括号）
            mi.ShowShortcutKeys <- true
        mi.Click.Add(fun _ -> onClick ())
        mi.Tag <- text.Replace("&", "")
        mi
    let sep () = new ToolStripSeparator() :> ToolStripItem
    let drop text (children: ToolStripItem array) =
        let m = new ToolStripMenuItem(Text = text)
        m.DropDownItems.AddRange children
        m :> ToolStripItem
    let toolBtn text tip onClick =
        let b = new ToolStripButton(Text = text, ToolTipText = tip, Tag = tip)
        b.Click.Add(fun _ -> onClick ())
        b :> ToolStripItem

    let menu = new MenuStrip()
    let tool = new ToolStrip(GripStyle = ToolStripGripStyle.Hidden)

    let miNew = item "新建(&N)" (Keys.Control ||| Keys.N) (fun () -> editor.Clear(); say "新建文档")
    let miSave = item "保存(&S)" (Keys.Control ||| Keys.S) (fun () -> say "保存到哪？—— 09 章的 SaveFileDialog 负责")
    let miQuit = item "退出(&Q)" (Keys.Control ||| Keys.Q) (fun () -> form.Close())
    menu.Items.Add(drop "文件(&F)" [| miNew :> ToolStripItem; miSave; sep (); miQuit |]) |> ignore

    let miAll = item "全选(&A)" (Keys.Control ||| Keys.A) (fun () -> editor.SelectAll())
    let miCopy = item "复制(&C)" (Keys.Control ||| Keys.C) (fun () -> editor.Copy())
    let miClear = item "清空" Keys.None (fun () -> editor.Clear())
    menu.Items.Add(drop "编辑(&E)" [| miAll :> ToolStripItem; miCopy; sep (); miClear |]) |> ignore

    // 视图：CheckOnClick 的勾选菜单
    let miTool = new ToolStripMenuItem(Text = "工具栏(&T)", Checked = true, CheckOnClick = true)
    miTool.Click.Add(fun _ -> tool.Visible <- miTool.Checked)
    let miStatus = new ToolStripMenuItem(Text = "状态栏(&B)", Checked = true, CheckOnClick = true)
    miStatus.Click.Add(fun _ -> status.Visible <- miStatus.Checked)
    menu.Items.Add(drop "视图(&V)" [| miTool :> ToolStripItem; miStatus |]) |> ignore

    let miAbout = item "关于(&A)" Keys.F1 (fun () ->
        MessageBox.Show(form, "迷你编辑器 1.0\n三语言示例 · 08 章", "关于") |> ignore)
    menu.Items.Add(drop "帮助(&H)" [| miAbout :> ToolStripItem |]) |> ignore

    // ═══ 8.2 工具栏 ═══
    tool.Items.AddRange [| toolBtn "新建" "新建文档 (Ctrl+N)" miNew.PerformClick
                           toolBtn "保存" "保存 (Ctrl+S)" miSave.PerformClick
                           new ToolStripSeparator() :> ToolStripItem
                           toolBtn "全选" "全选 (Ctrl+A)" miAll.PerformClick
                           toolBtn "清空" "清空文档" miClear.PerformClick |]

    // ═══ 8.3 右键菜单 ═══
    let ctx = new ContextMenuStrip()
    ctx.Items.AddRange [| item "剪切" (Keys.Control ||| Keys.X) (fun () -> editor.Cut()) :> ToolStripItem
                          item "复制" (Keys.Control ||| Keys.C) (fun () -> editor.Copy())
                          item "粘贴" (Keys.Control ||| Keys.V) (fun () -> editor.Paste())
                          sep ()
                          item "全选" (Keys.Control ||| Keys.A) (fun () -> editor.SelectAll()) |]
    editor.ContextMenuStrip <- ctx

    editor.TextChanged.Add(fun _ ->
        count.Text <- $"{editor.Text.Length} 字")

    // 鼠标扫过菜单/工具项时状态栏给提示（Items 是非泛型集合，先 Seq.cast）
    for strip in [ menu :> ToolStrip; tool :> ToolStrip; ctx :> ToolStrip ] do
        for it in strip.Items |> Seq.cast<ToolStripItem> do
            match it.Tag with
            | :? String as tip when tip.Length > 0 -> it.MouseEnter.Add(fun _ -> say tip)
            | _ -> ()

    form.Controls.Add editor
    form.Controls.Add tool
    form.Controls.Add status
    form.Controls.Add menu
    form.MainMenuStrip <- menu

    Application.Run form
    0
