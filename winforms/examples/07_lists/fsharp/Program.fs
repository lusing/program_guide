// 07 容器与列表控件（F# 版）
module ListsFs.Program

open System
open System.Drawing
open System.Windows.Forms

// 类别 → (名称, 单价, 产地)。F# 里直接用不可变 list 建目录，比 Dictionary 更顺
let catalog =
    [ "水果", [ "苹果", 8.5m, "山东"; "香蕉", 3.2m, "海南"; "樱桃", 39.9m, "大连" ]
      "蔬菜", [ "番茄", 4.0m, "寿光"; "黄瓜", 2.8m, "廊坊"; "土豆", 1.9m, "内蒙古" ]
      "粮油", [ "大米", 5.6m, "五常"; "面粉", 4.3m, "河北"; "玉米油", 12.8m, "东北" ] ]
    |> Map.ofList

[<EntryPoint>]
[<STAThread>]
let main _ =
    // 顺序铁律：EnableVisualStyles / SetCompatibleTextRenderingDefault 必须先于任何窗体创建
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    let form = new Form(Text = "容器与列表控件", ClientSize = Size(760, 480),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let status = new Label(Dock = DockStyle.Bottom, Height = 30,
                           TextAlign = ContentAlignment.MiddleLeft, BackColor = Color.Gainsboro)

    // ═══ 7.1 SplitContainer ═══
    let split = new SplitContainer(Dock = DockStyle.Fill, SplitterDistance = 220)

    // ═══ 7.2 TreeView ═══
    let tree = new TreeView(Dock = DockStyle.Fill, HideSelection = false)
    for KeyValue(cat, items) in catalog do   // Map 迭代给 KeyValuePair，用 KeyValue 模式解
        let node = tree.Nodes.Add cat
        node.Tag <- cat
        for name, _, _ in items do
            let child = node.Nodes.Add name
            child.Tag <- (cat, name)
    tree.ExpandAll()

    let list = new ListView(Dock = DockStyle.Fill, View = View.Details,
                            FullRowSelect = true, GridLines = true)
    list.Columns.Add("品名", 140) |> ignore
    list.Columns.Add("单价(元)", 90, HorizontalAlignment.Right) |> ignore
    list.Columns.Add("产地", 120) |> ignore
    list.SelectedIndexChanged.Add(fun _ ->
        if list.SelectedItems.Count > 0 then
            status.Text <- $"  列表选中「{list.SelectedItems.[0].Text}」")

    // 树节点 → 明细表：一级节点列出整组，二级节点只列单条
    let refreshList (node: TreeNode) =
        list.Items.Clear()
        let items =
            if node.Level = 0 then catalog[node.Tag :?> string]
            else
                let cat, name = node.Tag :?> string * string
                catalog[cat] |> List.filter (fun (n, _, _) -> n = name)
        for name, price, from in items do
            let p = price.ToString("F1")
            list.Items.Add(new ListViewItem([| name; p; from |])) |> ignore

    tree.AfterSelect.Add(fun e ->
        status.Text <- $"  选中「{e.Node.Text}」（Level={e.Node.Level}，FullPath={e.Node.FullPath}）"
        refreshList e.Node)

    // ═══ 7.3 TabControl 三页 ═══
    let tabs = new TabControl(Dock = DockStyle.Fill)

    let page1 = new TabPage("明细表（Details）")
    page1.Controls.Add list

    let page2 = new TabPage("图标视图（LargeIcon）")
    let icons = new ImageList(ImageSize = Size(32, 32))
    icons.Images.Add("shield", SystemIcons.Shield)
    icons.Images.Add("warn", SystemIcons.Warning)
    icons.Images.Add("info", SystemIcons.Information)
    let iconList = new ListView(Dock = DockStyle.Fill, View = View.LargeIcon, LargeImageList = icons)
    for text, key in [ "盾牌", "shield"; "警告", "warn"; "信息", "info" ] do
        iconList.Items.Add(text, key) |> ignore
    page2.Controls.Add iconList

    let page3 = new TabPage("滚动面板（AutoScroll）")
    let panel = new Panel(Dock = DockStyle.Fill, AutoScroll = true)
    // F# 的 for 循环变量每次迭代都是新绑定——不用像 C# 那样手动拷贝捕获变量
    for i in 1..12 do
        let col, row = (i - 1) % 3, (i - 1) / 3
        // F# 插值没有 C# 的 {expr:格式} 后缀；printf 风格写法是 $"%02d{i}"，
        // 这里为了三语言对照统一用 ToString
        let label = i.ToString("00")
        let b = new Button(Text = $"按钮 {label}",
                           Location = Point(16 + col * 130, 16 + row * 48), Size = Size(120, 38))
        b.Click.Add(fun _ -> status.Text <- $"  滚动面板：点了按钮 {label}")
        panel.Controls.Add b
    page3.Controls.Add panel

    tabs.TabPages.AddRange [| page1; page2; page3 |]

    split.Panel1.Controls.Add tree
    split.Panel2.Controls.Add tabs

    form.Controls.Add split
    form.Controls.Add status

    tree.SelectedNode <- tree.Nodes.[0]

    Application.Run form
    0
