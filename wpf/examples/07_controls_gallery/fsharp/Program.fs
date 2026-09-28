// 07 核心控件画廊（F# 版）：与 csharp/ 版功能一致。
// 事件签名差异是本章重点：TextChanged/SelectionChanged/ValueChanged 各有专属委托，
// F# 里直接 .Add(fun ... -> ...)，不存在 C# 那种「共用处理器」的类型问题。
module ControlsGalleryFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Controls.Primitives   // StatusBar 在 Primitives 分包
open System.Windows.Media

let groupBox (header: string) (body: UIElement) =
    let gb = GroupBox(Header = header, Margin = Thickness(0., 0., 0., 10.))
    gb.Content <- body
    gb

[<EntryPoint; STAThread>]
let main _ =
    let status = TextBlock(Text = "等待操作…")
    let report (msg: string) = status.Text <- msg

    // ── 文本输入 ──
    let single = TextBox(Text = "单行文本框", Margin = Thickness(0., 0., 0., 6.))
    single.TextChanged.Add(fun _ -> report "TextBox 文本变了（TextChanged 是直接事件）")
    let multi = TextBox(Text = "多行文本框\n第二行", AcceptsReturn = true, TextWrapping = TextWrapping.Wrap,
                        Height = 60., VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                        Margin = Thickness(0., 0., 0., 6.))
    let pwd = PasswordBox(Password = "12345", Width = 160., HorizontalAlignment = HorizontalAlignment.Left)
    pwd.PasswordChanged.Add(fun _ -> report (pwd.GetType().Name + " 触发了 PasswordChanged"))

    let textBody = StackPanel()
    [ single :> UIElement; multi; pwd ] |> List.iter (fun c -> textBody.Children.Add c |> ignore)

    // ── 选择 ──
    let check1 = CheckBox(Content = "普通复选框", IsChecked = true, Margin = Thickness(0., 0., 0., 6.))
    check1.Checked.Add(fun _ -> report "CheckBox 触发了 Checked")
    check1.Unchecked.Add(fun _ -> report "CheckBox 触发了 Unchecked")
    let check2 = CheckBox(Content = "三态复选框（IsChecked 是 bool?）", IsThreeState = true,
                          Margin = Thickness(0., 0., 0., 6.))
    let radioA = RadioButton(Content = "选项 A", GroupName = "g1", IsChecked = true, Margin = Thickness(0., 0., 16., 0.))
    radioA.Checked.Add(fun _ -> report "RadioButton 触发了 Checked")
    let radioB = RadioButton(Content = "选项 B", GroupName = "g1")
    radioB.Checked.Add(fun _ -> report "RadioButton 触发了 Checked")

    let cityBox = ComboBox(Width = 140.)
    for city in [ "北京"; "上海"; "深圳" ] do
        cityBox.Items.Add(ComboBoxItem(Content = city, IsSelected = (city = "北京"))) |> ignore
    cityBox.SelectionChanged.Add(fun _ ->
        match cityBox.SelectedItem with
        | :? ComboBoxItem as item -> report (sprintf "ComboBox 选中了 %s" (string item.Content))
        | _ -> ())
    let radioRow = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 0., 0., 6.))
    radioRow.Children.Add radioA |> ignore
    radioRow.Children.Add radioB |> ignore
    let selectBody = StackPanel()
    [ check1 :> UIElement; check2; radioRow; cityBox ] |> List.iter (fun c -> selectBody.Children.Add c |> ignore)

    // ── 数值与进度 ──
    let progress = ProgressBar(Minimum = 0., Maximum = 100., Height = 18., Value = 40.)
    let slider = Slider(Minimum = 0., Maximum = 100., Value = 40., TickFrequency = 10.,
                        IsSnapToTickEnabled = true, Margin = Thickness(0., 0., 0., 6.))
    slider.ValueChanged.Add(fun e ->
        progress.Value <- e.NewValue
        report (sprintf "Slider = %.0f，进度条同步（事件直连演示）" e.NewValue))
    let numberBody = StackPanel()
    numberBody.Children.Add slider |> ignore
    numberBody.Children.Add progress |> ignore

    // ── 列表 ──
    let fruitBox = ListBox(Height = 110.)
    for fruit in [ "苹果"; "香蕉"; "樱桃"; "榴莲" ] do
        fruitBox.Items.Add(ListBoxItem(Content = fruit)) |> ignore
    fruitBox.SelectionChanged.Add(fun _ ->
        match fruitBox.SelectedItem with
        | :? ListBoxItem as item -> report (sprintf "ListBox 选中了 %s" (string item.Content))
        | _ -> ())
    let listBody = StackPanel()
    listBody.Children.Add fruitBox |> ignore

    // ── 菜单与工具栏（教材 4.2）──
    let miClick (header: string) =
        let m = MenuItem(Header = header)
        m.Click.Add(fun _ -> report (sprintf "菜单「%s」被点击" header))
        m
    let fileMenu = MenuItem(Header = "文件(_F)")
    fileMenu.Items.Add(miClick "新建(_N)") |> ignore
    fileMenu.Items.Add(miClick "打开(_O)") |> ignore
    fileMenu.Items.Add(Separator()) |> ignore
    fileMenu.Items.Add(miClick "退出(_X)") |> ignore
    let helpMenu = MenuItem(Header = "帮助(_H)")
    helpMenu.Items.Add(miClick "关于(_A)") |> ignore
    let menu = Menu()
    menu.Items.Add fileMenu |> ignore
    menu.Items.Add helpMenu |> ignore

    let tbBtn (label: string) =
        let b = Button(Content = label)
        b.Click.Add(fun _ -> report (sprintf "工具栏「%s」被点击" label))
        b
    let sizeBox = ComboBox(Width = 80., SelectedIndex = 0)
    sizeBox.Items.Add(ComboBoxItem(Content = "14")) |> ignore
    sizeBox.Items.Add(ComboBoxItem(Content = "18")) |> ignore
    let toolBar = ToolBar()
    toolBar.Items.Add(tbBtn "加粗") |> ignore
    toolBar.Items.Add(tbBtn "倾斜") |> ignore
    toolBar.Items.Add(Separator()) |> ignore
    toolBar.Items.Add sizeBox |> ignore
    let menuBody = StackPanel()
    menuBody.Children.Add menu |> ignore
    let tray = ToolBarTray(Margin = Thickness(0., 6., 0., 0.))
    tray.ToolBars.Add toolBar |> ignore
    menuBody.Children.Add tray |> ignore

    // ── 日期与手写（教材 4.5.4 / 4.8）──
    let picker = DatePicker(Width = 140.)
    picker.SelectedDateChanged.Add(fun _ ->
        // SelectedDate 是 Nullable<DateTime>——F# 没有 Nullable 模式匹配，判 HasValue 取 Value
        let d = picker.SelectedDate
        if d.HasValue then report (sprintf "DatePicker 选了 %s" (d.Value.ToString("yyyy-MM-dd"))) else ())
    let ink = InkCanvas(Height = 110., Background = Brushes.AliceBlue)
    let dateRow = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 0., 0., 6.))
    dateRow.Children.Add(TextBlock(Text = "日期选择：", VerticalAlignment = VerticalAlignment.Center,
                                    Margin = Thickness(0., 0., 8., 0.))) |> ignore
    dateRow.Children.Add picker |> ignore
    let dateBody = StackPanel()
    dateBody.Children.Add dateRow |> ignore
    dateBody.Children.Add ink |> ignore

    // ── 其他 ──
    let tipBtn = Button(Content = "悬停我有工具提示",
                        ToolTip = "ToolTip 是免费的，给控件加一行说明就用它",
                        Width = 220., HorizontalAlignment = HorizontalAlignment.Left,
                        Margin = Thickness(0., 0., 0., 6.))
    tipBtn.Click.Add(fun _ -> report "Button 触发了 Click")
    let expander = Expander(Header = "点我展开（Expander）", IsExpanded = false,
                            Content = TextBlock(Text = "折叠面板：放次要选项，默认收起。设置中心常见。",
                                                Margin = Thickness 8., TextWrapping = TextWrapping.Wrap))
    let miscBody = StackPanel()
    miscBody.Children.Add tipBtn |> ignore
    miscBody.Children.Add expander |> ignore

    // ── 总装 ──
    let list = StackPanel()
    for gb in [ groupBox "文本输入" textBody
                groupBox "选择" selectBody
                groupBox "数值与进度" numberBody
                groupBox "列表" listBody
                groupBox "菜单与工具栏（教材 4.2）" menuBody
                groupBox "日期与手写（教材 4.5.4 / 4.8）" dateBody
                groupBox "其他" miscBody ] do
        list.Children.Add gb |> ignore

    let top = TextBlock(Text = "每个控件的事件都汇到底部状态栏——试着操作任意一个",
                        Foreground = SolidColorBrush(Color.FromRgb(0x55uy, 0x55uy, 0x55uy)),
                        Margin = Thickness(0., 0., 0., 10.))
    let statusBar = StatusBar()
    statusBar.Items.Add status |> ignore   // StatusBar 是 ItemsControl：子项进 Items

    let dock = DockPanel(Margin = Thickness 12.)
    DockPanel.SetDock(top, Dock.Top)
    DockPanel.SetDock(statusBar, Dock.Bottom)
    dock.Children.Add top |> ignore
    dock.Children.Add statusBar |> ignore
    dock.Children.Add(ScrollViewer(VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                                   Content = list)) |> ignore

    let window = Window(Title = "控件画廊 (F#)", Height = 620., Width = 560., Content = dock)
    Application().Run window
