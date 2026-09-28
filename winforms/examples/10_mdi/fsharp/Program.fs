// 10 SDI 与 MDI（F# 版）
module MdiFs.Program

open System
open System.Drawing
open System.Windows.Forms

// ═══ 10.1 子窗体 ═══
type ChildForm(index: int) as this =
    inherit Form()

    let editor = new RichTextBox(Dock = DockStyle.Fill)

    do
        this.Text <- $"文档 {index}"
        this.Width <- 420
        this.Height <- 300
        editor.Text <- $"我是第 {index} 个子文档。\n"
        this.Controls.Add editor

    member _.Editor = editor

[<EntryPoint>]
[<STAThread>]
let main _ =
    // 顺序铁律：EnableVisualStyles / SetCompatibleTextRenderingDefault 必须先于任何窗体创建
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    let form = new Form(Text = "MDI 多文档示例", ClientSize = Size(860, 560),
                        StartPosition = FormStartPosition.CenterScreen)
    form.IsMdiContainer <- true
    form.Font <- new Font("微软雅黑", 10F)

    let mutable created = 0

    let status = new ToolStripStatusLabel(Spring = true, TextAlign = ContentAlignment.MiddleLeft)
    let refreshStatus () =
        let active =
            match form.ActiveMdiChild with
            | :? ChildForm as c -> $"「{c.Text}」{c.Editor.Text.Length} 字"
            | _ -> "（无）"
        status.Text <- $"  子窗体 {form.MdiChildren.Length} 个；活动文档：{active}"

    // ═══ 10.2/10.3 菜单 ═══
    let menu = new MenuStrip()

    let miNew = new ToolStripMenuItem(Text = "新建文档(&N)")
    miNew.ShortcutKeys <- Keys.Control ||| Keys.N
    let newChild () =
        created <- created + 1
        let child = new ChildForm(created, MdiParent = form,
                                  StartPosition = FormStartPosition.Manual,
                                  Location = Point(30 * (created % 8), 30 * (created % 8)))
        child.Editor.TextChanged.Add(fun _ -> refreshStatus ())
        child.Show()
        refreshStatus ()
    miNew.Click.Add(fun _ -> newChild ())

    let miQuit = new ToolStripMenuItem(Text = "退出(&Q)")
    miQuit.Click.Add(fun _ -> form.Close())

    let fileMenu = new ToolStripMenuItem(Text = "文件(&F)")
    let fileItems: ToolStripItem[] = [| miNew :> ToolStripItem; new ToolStripSeparator(); miQuit |]
    fileMenu.DropDownItems.AddRange fileItems

    let layoutItem text layout =
        let mi = new ToolStripMenuItem(Text = text)
        mi.Click.Add(fun _ -> form.LayoutMdi layout)
        mi :> ToolStripItem

    let winMenu = new ToolStripMenuItem(Text = "窗口(&W)")
    let winItems: ToolStripItem[] =
        [| layoutItem "层叠排列(&C)" MdiLayout.Cascade
           layoutItem "垂直平铺(&V)" MdiLayout.TileVertical
           layoutItem "水平平铺(&H)" MdiLayout.TileHorizontal
           layoutItem "排列图标(&A)" MdiLayout.ArrangeIcons
           new ToolStripSeparator() :> ToolStripItem |]
    winMenu.DropDownItems.AddRange winItems
    // MdiWindowListItem 在 MenuStrip 上（不在菜单项上）：指定项后面自动填子窗体清单
    menu.MdiWindowListItem <- (winItems.[0] :?> ToolStripMenuItem)

    let menuItems: ToolStripItem[] = [| fileMenu :> ToolStripItem; winMenu |]
    menu.Items.AddRange menuItems

    let statusStrip = new StatusStrip()
    statusStrip.Items.Add status

    form.MdiChildActivate.Add(fun _ -> refreshStatus ())

    form.Controls.Add statusStrip
    form.Controls.Add menu
    form.MainMenuStrip <- menu

    newChild ()
    newChild ()

    Application.Run form
    0
