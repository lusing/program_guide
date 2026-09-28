// 06 布局实验室（F# 版）：与 csharp/ 版功能一致。
// 四个实验：SharedSizeGroup 共享尺寸 / Viewbox 缩放 / ScrollViewer+WrapPanel / 星号比例。
module LayoutLabFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Media

let brushFromHex (hex: string) =
    ColorConverter.ConvertFromString hex :?> Color |> SolidColorBrush

let note (t: string) = TextBlock(Text = t, Foreground = SolidColorBrush(Color.FromRgb(0x55uy, 0x55uy, 0x55uy)))

/// 三个 label/编辑行，标签列挂同一个 SharedSizeGroup
let sharedRow (label: string) (value: string) =
    let g = Grid(Margin = Thickness(0., 0., 0., 6.))
    g.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength.Auto, SharedSizeGroup = "label"))
    g.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength(1., GridUnitType.Star)))
    let l = TextBlock(Text = label + "：", FontWeight = FontWeights.Bold)
    let box = TextBox(Text = value)
    Grid.SetColumn(box, 1)
    g.Children.Add l |> ignore
    g.Children.Add box |> ignore
    g

[<EntryPoint; STAThread>]
let main _ =
    // ── Tab① 共享尺寸 ──
    let tab1Host = StackPanel(Margin = Thickness 12.)
    Grid.SetIsSharedSizeScope(tab1Host, true)   // XAML 的 Grid.IsSharedSizeScope="True" → 这个静态方法
    tab1Host.Children.Add(note "两个独立的 Grid，标签列却能对齐——SharedSizeGroup 的功劳") |> ignore
    for (l, v) in [ "姓名", "王小明"; "电子邮箱地址", "xiaoming@example.com"; "部门", "研发中心" ] do
        tab1Host.Children.Add(sharedRow l v) |> ignore

    // ── Tab② Viewbox ──
    let scaleBox = Viewbox(Stretch = Media.Stretch.Uniform)
    let fixedPanel =
        StackPanel(Width = 300., Height = 120., Background = Brushes.AliceBlue)
    let cap = TextBlock(Text = "我是 300×120 的固定面板", FontSize = 16.,
                        HorizontalAlignment = HorizontalAlignment.Center, Margin = Thickness 8.)
    let innerBtn = Button(Content = "窗口再小我也完整", Width = 160., Height = 30.,
                          HorizontalAlignment = HorizontalAlignment.Center)
    fixedPanel.Children.Add cap |> ignore
    fixedPanel.Children.Add innerBtn |> ignore
    scaleBox.Child <- fixedPanel   // Viewbox 是 Decorator：子元素属性叫 Child，不叫 Content

    let setStretch (s: Media.Stretch) _ =
        scaleBox.Stretch <- s
    let mkRadio (label: string) (checked': bool) (s: Media.Stretch) =
        let r = RadioButton(Content = label, IsChecked = checked', Margin = Thickness(0., 0., 16., 0.))
        r.Checked.Add(setStretch s)
        r
    let radioPanel = StackPanel(Orientation = Orientation.Horizontal)
    radioPanel.Children.Add(mkRadio "Uniform（等比）" true Media.Stretch.Uniform) |> ignore
    radioPanel.Children.Add(mkRadio "Fill（拉伸）" false Media.Stretch.Fill) |> ignore
    radioPanel.Children.Add(mkRadio "None（原样）" false Media.Stretch.None) |> ignore

    let tab2Top = StackPanel(Margin = Thickness(0., 0., 0., 10.))
    tab2Top.Children.Add(note "下面这块面板固定 300×120，拖动窗口大小看它如何整体缩放") |> ignore
    tab2Top.Children.Add radioPanel |> ignore
    let tab2 = DockPanel(Margin = Thickness 12.)
    DockPanel.SetDock(tab2Top, Dock.Top)
    tab2.Children.Add tab2Top |> ignore
    tab2.Children.Add(Border(BorderBrush = SolidColorBrush(Color.FromRgb(0xBBuy, 0xBBuy, 0xBBuy)),
                             BorderThickness = Thickness 1.,
                             Background = SolidColorBrush(Color.FromRgb(0xFAuy, 0xFAuy, 0xFAuy)),
                             Child = scaleBox)) |> ignore

    // ── Tab③ 滚动与折行 ──
    let chipPanel = WrapPanel()
    let palette =
        [| "#3B82F6"; "#10B981"; "#F59E0B"; "#EF4444"; "#8B5CF6"; "#14B8A6" |]
        |> Array.map brushFromHex
    for i in 1..50 do
        let chip = Border(Background = palette[(i - 1) % palette.Length],
                          CornerRadius = CornerRadius 12.,
                          Padding = Thickness(12., 5., 12., 5.),
                          Margin = Thickness(0., 0., 8., 8.),
                          Child = TextBlock(Text = sprintf "标签 %02d" i, Foreground = Brushes.White))
        chipPanel.Children.Add chip |> ignore
    let tab3top = note "50 个标签放进 WrapPanel，宽度不够自动折行；整体再套 ScrollViewer 保证滚得动"
    tab3top.TextWrapping <- TextWrapping.Wrap
    let tab3 = DockPanel(Margin = Thickness 12.)
    DockPanel.SetDock(tab3top, Dock.Top)
    tab3top.Margin <- Thickness(0., 0., 0., 10.)
    tab3.Children.Add tab3top |> ignore
    tab3.Children.Add(ScrollViewer(VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                                   Content = chipPanel)) |> ignore

    // ── Tab④ 星号与 Auto ──
    let col1 = Border(Background = brushFromHex "#DBEAFE", Margin = Thickness(0., 0., 4., 0.),
                      Child = TextBlock(Text = "1*", HorizontalAlignment = HorizontalAlignment.Center,
                                        VerticalAlignment = VerticalAlignment.Center))
    let col2 = Border(Background = brushFromHex "#DCFCE7", Margin = Thickness(0., 0., 4., 0.),
                      Child = TextBlock(Text = "2*", HorizontalAlignment = HorizontalAlignment.Center,
                                        VerticalAlignment = VerticalAlignment.Center))
    let col3 = Border(Background = brushFromHex "#FEF3C7",
                      Child = TextBlock(Text = "Auto 自动列", Margin = Thickness(12., 0., 12., 0.),
                                        VerticalAlignment = VerticalAlignment.Center))
    let starGrid = Grid()
    starGrid.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength(1., GridUnitType.Star), MinWidth = 80.))
    starGrid.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength(2., GridUnitType.Star), MinWidth = 120.))
    starGrid.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength.Auto))
    Grid.SetColumn(col2, 1)
    Grid.SetColumn(col3, 2)
    starGrid.Children.Add col1 |> ignore
    starGrid.Children.Add col2 |> ignore
    starGrid.Children.Add col3 |> ignore

    let sizeReport = note ""
    starGrid.SizeChanged.Add(fun _ ->
        sizeReport.Text <- sprintf "实际列宽  1* → %.0fpx   2* → %.0fpx   Auto → %.0fpx"
                                    col1.ActualWidth col2.ActualWidth col3.ActualWidth)

    let tab4 = Grid(Margin = Thickness 12.)
    tab4.RowDefinitions.Add(RowDefinition(Height = GridLength.Auto))
    tab4.RowDefinitions.Add(RowDefinition(Height = GridLength(1., GridUnitType.Star)))
    tab4.RowDefinitions.Add(RowDefinition(Height = GridLength.Auto))
    let desc = note "三列宽度 1* : 2* : Auto。拖动窗口宽度：前两列按 1:2 瓜分剩余空间，第三列永远刚好包住内容"
    desc.TextWrapping <- TextWrapping.Wrap
    desc.Margin <- Thickness(0., 0., 0., 10.)
    Grid.SetRow(desc, 0)
    Grid.SetRow(starGrid, 1)
    Grid.SetRow(sizeReport, 2)
    sizeReport.Margin <- Thickness(0., 10., 0., 0.)
    tab4.Children.Add desc |> ignore
    tab4.Children.Add starGrid |> ignore
    tab4.Children.Add sizeReport |> ignore

    // ── TabControl ──
    let tabs = TabControl(Margin = Thickness 8.)
    for (header, content) in [ "共享尺寸", tab1Host :> UIElement
                               "Viewbox 缩放", tab2 :> UIElement
                               "滚动与折行", tab3 :> UIElement
                               "星号与 Auto", tab4 :> UIElement ] do
        tabs.Items.Add(TabItem(Header = header, Content = content)) |> ignore

    let window = Window(Title = "布局实验室 (F#)", Height = 420., Width = 640., Content = tabs)
    Application().Run window
