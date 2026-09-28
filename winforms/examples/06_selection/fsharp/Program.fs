// 06 选择类控件（F# 版）
module SelectFs.Program

open System
open System.Drawing
open System.Windows.Forms

// 从一组控件里挑出选中项的文字（RadioButton 互斥组专用）
let checkedText (flow: FlowLayoutPanel) =
    flow.Controls
    |> Seq.cast<Control>
    |> Seq.tryPick (fun c ->
        match c with
        | :? RadioButton as rb when rb.Checked -> Some rb.Text
        | _ -> None)
    |> Option.defaultValue "（未选）"

[<EntryPoint>]
[<STAThread>]
let main _ =
    // 顺序铁律：EnableVisualStyles / SetCompatibleTextRenderingDefault 必须先于任何窗体创建
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false
    let form = new Form(Text = "选择类控件", ClientSize = Size(660, 460),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let status = new Label(Dock = DockStyle.Bottom, Height = 30,
                           TextAlign = ContentAlignment.MiddleLeft, BackColor = Color.Gainsboro)

    // ═══ 6.1 RadioButton 互斥组 ═══
    let deptFlow = new FlowLayoutPanel(Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown)
    let deptBox = new GroupBox(Text = " 部门（互斥组 A）", Dock = DockStyle.Fill)
    for d in [ "研发"; "测试"; "设计" ] do
        let rb = new RadioButton(Text = d, AutoSize = true)
        rb.CheckedChanged.Add(fun _ -> if rb.Checked then status.Text <- $"  部门 → {d}")
        deptFlow.Controls.Add rb
    (deptFlow.Controls.[0] :?> RadioButton).Checked <- true
    deptBox.Controls.Add deptFlow

    let typeFlow = new FlowLayoutPanel(Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown)
    let typeBox = new GroupBox(Text = " 用工类型（互斥组 B）", Dock = DockStyle.Fill)
    for t in [ "全职"; "实习" ] do
        typeFlow.Controls.Add(new RadioButton(Text = t, AutoSize = true))
    (typeFlow.Controls.[1] :?> RadioButton).Checked <- true
    typeBox.Controls.Add typeFlow

    // ═══ 6.2 ComboBox ═══
    let city = new ComboBox(Dock = DockStyle.Top, DropDownStyle = ComboBoxStyle.DropDownList)
    city.Items.AddRange [| "北京"; "上海"; "广州"; "深圳"; "杭州" |]
    city.SelectedIndex <- 0
    city.SelectedIndexChanged.Add(fun _ ->
        status.Text <- $"  城市 → {city.SelectedItem}（索引 {city.SelectedIndex}）")
    let cityBox = new GroupBox(Text = " 城市（ComboBox，DropDownList 只能选）", Dock = DockStyle.Fill)
    cityBox.Controls.Add city

    // ═══ 6.3 CheckedListBox ═══
    let hobbies = new CheckedListBox(Dock = DockStyle.Fill, CheckOnClick = true)
    hobbies.Items.AddRange [| "看书"; "游戏"; "爬山"; "摄影"; "做饭" |]
    let hobbyBox = new GroupBox(Text = " 兴趣（CheckedListBox，可多选）", Dock = DockStyle.Fill)
    hobbyBox.Controls.Add hobbies

    // ═══ 6.4 + 6.5 日期与滑块 ═══
    let miscBox = new GroupBox(Text = " 日期与音量 ", Dock = DockStyle.Fill)
    let date = new DateTimePicker(Format = DateTimePickerFormat.Long, Value = DateTime.Today)
    date.SetBounds(100, 26, 200, 30)
    // F# 规则（FS3373）：内插洞里不能出现带引号的字符串字面量——先 let 绑定再进洞
    date.ValueChanged.Add(fun _ ->
        let s = date.Value.ToString("yyyy-MM-dd")
        status.Text <- $"  入职 → {s}")
    let volume = new TrackBar(Minimum = 0, Maximum = 100, Value = 60, TickFrequency = 10)
    volume.SetBounds(96, 70, 220, 45)
    let volumeLabel = new Label(AutoSize = true, Location = Point(100, 106), Text = "音量 = 60")
    volume.Scroll.Add(fun _ -> volumeLabel.Text <- $"音量 = {volume.Value}（拖动时连续触发 Scroll）")
    let summary = new Button(Text = "汇总我的选择", Location = Point(12, 136), AutoSize = true)
    summary.Click.Add(fun _ ->
        let picked = [ for i in hobbies.CheckedIndices -> string hobbies.Items.[int i] ]
        let hobbyText = if picked.IsEmpty then "（无）" else String.concat "、" picked
        let hire = date.Value.ToString("yyyy-MM-dd")
        MessageBox.Show(form,
            $"部门：{checkedText deptFlow}\n用工：{checkedText typeFlow}\n城市：{city.SelectedItem}\n" +
            $"入职：{hire}\n音量：{volume.Value}\n兴趣：{hobbyText}", "汇总") |> ignore)

    let miscControls: Control[] =
        [| new Label(Text = "入职日期：", AutoSize = true, Location = Point(12, 30))
           date
           new Label(Text = "音量：", AutoSize = true, Location = Point(12, 76))
           volume; volumeLabel; summary |]
    miscBox.Controls.AddRange miscControls

    // ═══ 布局 ═══
    let rightSplit = new TableLayoutPanel(Dock = DockStyle.Fill, RowCount = 2)
    rightSplit.RowStyles.Add(RowStyle(SizeType.Percent, 55f))
    rightSplit.RowStyles.Add(RowStyle(SizeType.Percent, 45f))
    rightSplit.Controls.Add(miscBox, 0, 0)
    rightSplit.Controls.Add(hobbyBox, 0, 1)

    let grid = new TableLayoutPanel(Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 2)
    grid.ColumnStyles.Add(ColumnStyle(SizeType.Percent, 50f))
    grid.ColumnStyles.Add(ColumnStyle(SizeType.Percent, 50f))
    grid.RowStyles.Add(RowStyle(SizeType.Percent, 45f))
    grid.RowStyles.Add(RowStyle(SizeType.Percent, 55f))
    grid.Controls.Add(deptBox, 0, 0)
    grid.Controls.Add(typeBox, 1, 0)
    grid.Controls.Add(cityBox, 0, 1)
    grid.Controls.Add(rightSplit, 1, 1)

    form.Controls.Add grid
    form.Controls.Add status

    Application.Run form
    0
