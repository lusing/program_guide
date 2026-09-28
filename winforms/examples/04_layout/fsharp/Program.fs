// 04 布局（F# 版）：Dock、Anchor、TableLayoutPanel、FlowLayoutPanel 与 DPI 缩放
module LayoutFs.Program

open System
open System.Drawing
open System.Windows.Forms

// 表格行助手：0 号列标签右对齐，1 号列控件填满
let addRow (table: TableLayoutPanel) row caption (input: Control) =
    let label = new Label(Text = caption, Dock = DockStyle.Fill,
                          TextAlign = ContentAlignment.MiddleRight,
                          Margin = Padding(0, 9, 8, 3))
    table.Controls.Add(label, 0, row)
    table.Controls.Add(input, 1, row)

[<EntryPoint>]
[<STAThread>]
let main _ =
    // 顺序铁律：EnableVisualStyles / SetCompatibleTextRenderingDefault 必须先于任何窗体创建
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    let form = new Form(Text = "布局系统", ClientSize = Size(520, 400),
                        MinimumSize = Size(420, 320),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)
    form.AutoScaleMode <- AutoScaleMode.Font

    // ═══ 4.1 底部状态：ClientSize vs Size ═══
    let sizeLabel = new Label(Dock = DockStyle.Bottom, Height = 30,
                              TextAlign = ContentAlignment.MiddleLeft,
                              BackColor = Color.Gainsboro)
    let reportSize () =
        sizeLabel.Text <- $"  ClientSize = {form.ClientSize.Width}×{form.ClientSize.Height}（拖动窗口右下角试试）"
    form.Resize.Add(fun _ -> reportSize ())
    reportSize ()

    // ═══ 4.2 FlowLayoutPanel ═══
    let flow = new FlowLayoutPanel(Dock = DockStyle.Bottom, Height = 76,
                                   FlowDirection = FlowDirection.LeftToRight)
    for name in [ "重置"; "保存"; "导出"; "打印"; "分享"; "更多…" ] do
        let b = new Button(Text = name, AutoSize = true, Margin = Padding(4))
        b.Click.Add(fun _ ->
            sizeLabel.Text <- $"[flow] 点击了「{name}」——注意本行放不下时会自动换行")
        flow.Controls.Add b

    // ═══ 4.3 Anchor 实验 ═══
    // 枚举位或（|||）别塞进构造器命名实参里——先建对象再赋属性，解析器不闹脾气
    let anchorBox = new TextBox(Location = Point(120, 250), Width = 300)
    anchorBox.Anchor <- AnchorStyles.Left ||| AnchorStyles.Top ||| AnchorStyles.Right
    let anchorLabel = new Label(Text = "Anchor →", AutoSize = true, Location = Point(16, 253))
    let anchorHint = new Label(Text = "拖宽窗口：上面这个文本框跟着变宽（锚住了左右两边）",
                               AutoSize = true, Location = Point(120, 278),
                               ForeColor = Color.DimGray)

    // ═══ 4.4 TableLayoutPanel ═══
    let table = new TableLayoutPanel(Dock = DockStyle.Top, Height = 220, ColumnCount = 2, RowCount = 4)
    table.ColumnStyles.Add(ColumnStyle(SizeType.Percent, 28f))
    table.ColumnStyles.Add(ColumnStyle(SizeType.Percent, 72f))
    table.Padding <- Padding 12

    addRow table 0 "用户名：" (new TextBox(Dock = DockStyle.Fill))
    addRow table 1 "邮箱：" (new TextBox(Dock = DockStyle.Fill))

    let combo = new ComboBox(Dock = DockStyle.Fill, DropDownStyle = ComboBoxStyle.DropDownList)
    combo.Items.AddRange([| "研发部"; "市场部"; "财务部"; "人事部" |])
    combo.SelectedIndex <- 0
    addRow table 2 "部门：" combo

    addRow table 3 "偏好：" (new CheckBox(Text = "接受通知邮件", Dock = DockStyle.Fill, AutoSize = true))

    form.Controls.Add table
    form.Controls.Add anchorLabel
    form.Controls.Add anchorBox
    form.Controls.Add anchorHint
    form.Controls.Add flow
    form.Controls.Add sizeLabel

    Application.Run form
    0
