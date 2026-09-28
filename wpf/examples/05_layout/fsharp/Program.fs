// 05 布局系统（F# 版）：与 csharp/ 的 C#+XAML 版功能一致（Grid/DockPanel/StackPanel/UniformGrid）。
// XAML 里最常写的三样东西在 F# 代码里的对应：
//   <Grid.RowDefinitions>      → grid.RowDefinitions.Add(RowDefinition(Height = GridLength.Auto))
//   Grid.Row="1"（附加属性）    → Grid.SetRow(element, 1)
//   Height="*"                 → GridLength(1., GridUnitType.Star)
module LayoutFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Controls.Primitives   // UniformGrid / StatusBar 在 Primitives 分包
open System.Windows.Media

let bold (t: string) = TextBlock(Text = t, FontWeight = FontWeights.Bold)

[<EntryPoint; STAThread>]
let main _ =
    // ── 左栏：Border + StackPanel ──
    let menu1 = Button(Content = "首页", Margin = Thickness(0., 0., 0., 8.))
    let menu2 = Button(Content = "文档", Margin = Thickness(0., 0., 0., 8.))
    let menu3 = Button(Content = "设置")
    let menuPanel = StackPanel()
    menuPanel.Children.Add(bold "菜单") |> ignore
    menuPanel.Children.Add menu1 |> ignore
    menuPanel.Children.Add menu2 |> ignore
    menuPanel.Children.Add menu3 |> ignore

    let sidebar =
        Border(Background = Brushes.AliceBlue, Margin = Thickness(0., 0., 12., 0.),
               Padding = Thickness 12., BorderBrush = Brushes.LightGray, BorderThickness = Thickness 1.,
               Child = menuPanel)

    // ── 右栏：DockPanel ──
    let title = bold "工作区"
    DockPanel.SetDock(title, Dock.Top)
    title.Margin <- Thickness(0., 0., 0., 8.)

    let editor = TextBox(Height = 90., Text = "这里展示正文内容…", TextWrapping = TextWrapping.Wrap,
                         AcceptsReturn = true)
    DockPanel.SetDock(editor, Dock.Bottom)

    let newBtn = Button(Content = "新建", Margin = Thickness(0., 0., 8., 0.))
    let saveBtn = Button(Content = "保存")
    let twoCol = Grid()
    twoCol.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength(1., GridUnitType.Star)))
    twoCol.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength(1., GridUnitType.Star)))
    Grid.SetColumn(newBtn, 0)
    Grid.SetColumn(saveBtn, 1)
    twoCol.Children.Add newBtn |> ignore
    twoCol.Children.Add saveBtn |> ignore

    let mainArea = StackPanel()
    let heading = TextBlock(Text = "主内容区域", FontSize = 16., Margin = Thickness(0., 0., 0., 8.))
    mainArea.Children.Add heading |> ignore
    mainArea.Children.Add twoCol |> ignore

    let content =
        Border(BorderBrush = Brushes.LightGray, BorderThickness = Thickness 1., Padding = Thickness 10.,
               Child = mainArea)

    let dock = DockPanel(LastChildFill = true)
    dock.Children.Add title |> ignore
    dock.Children.Add editor |> ignore
    dock.Children.Add content |> ignore

    // ── 左右两栏放进 Grid ──
    let body = Grid()
    body.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength 220.))
    body.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength(1., GridUnitType.Star)))
    Grid.SetColumn(sidebar, 0)
    Grid.SetColumn(dock, 1)
    body.Children.Add sidebar |> ignore
    body.Children.Add dock |> ignore

    // ── UniformGrid（教材 3.2.5）：5 个按钮自动等分一行 ──
    let uniform = UniformGrid(Columns = 5, Margin = Thickness(0., 12., 0., 0.))
    for i in 1..5 do
        uniform.Children.Add(Button(Content = sprintf "%d/5" i)) |> ignore

    // StatusBar 是 ItemsControl：没有 Content 属性，子项进 Items（F# 命名实参初始化器因此不可用）
    let status = StatusBar(Margin = Thickness(0., 12., 0., 0.))
    status.Items.Add(TextBlock(Text = "Ready")) |> ignore

    // ── 外层 Grid：4 行 ──
    let grid = Grid(Margin = Thickness 16.)
    grid.RowDefinitions.Add(RowDefinition(Height = GridLength.Auto))
    grid.RowDefinitions.Add(RowDefinition(Height = GridLength(1., GridUnitType.Star)))
    grid.RowDefinitions.Add(RowDefinition(Height = GridLength.Auto))
    grid.RowDefinitions.Add(RowDefinition(Height = GridLength.Auto))

    let head = TextBlock(Text = "布局示例", FontSize = 24., FontWeight = FontWeights.Bold,
                         Margin = Thickness(0., 0., 0., 12.))
    Grid.SetRow(head, 0)
    Grid.SetRow(body, 1)
    Grid.SetRow(uniform, 2)
    Grid.SetRow(status, 3)
    for c in [ head :> UIElement; body :> UIElement; uniform :> UIElement; status :> UIElement ] do
        grid.Children.Add c |> ignore

    let window = Window(Title = "Layout Demo (F#)", Height = 460., Width = 620., Content = grid)
    Application().Run window
