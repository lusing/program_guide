// 08 路由事件（F# 版）：与 csharp/ 版功能一致——隧道/冒泡可视化 + 自定义路由事件（教材 6.3）。
// F# 的挂载写法全是 window.AddHandler(RoutedEvent, 委托)：XAML 里的 PreviewMouseDown="..." 在代码里
// 就是 AddHandler(UIElement.PreviewMouseDownEvent, MouseButtonEventHandler(...))。
module RoutedEventsFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Input   // MouseButtonEventHandler / MouseButtonEventArgs 在这里
open System.Windows.Media

/// 自定义路由事件（教材 6.3）：EventManager.RegisterRoutedEvent 注册一个冒泡策略的 Alarm 事件
type AlarmButton() as this =
    inherit Button()
    static let alarmEvent =
        EventManager.RegisterRoutedEvent("Alarm", RoutingStrategy.Bubble,
                                         typeof<RoutedEventHandler>, typeof<AlarmButton>)
    static member AlarmEvent = alarmEvent
    member _.RaiseAlarm() =
        this.RaiseEvent(RoutedEventArgs(AlarmButton.AlarmEvent, this))
    // C# 侧还有一个 event Alarm { add; remove; } 包装器——F# 没有 add/remove 访问器语法，
    // 挂载直接走 AddHandler(AlarmButton.AlarmEvent, 委托)（下面 window 挂载处就是这么写的）

let nameOf (o: obj) =
    match o with
    | :? FrameworkElement as fe when not (String.IsNullOrEmpty fe.Name) -> fe.Name
    | :? FrameworkElement as fe -> fe.GetType().Name
    | null -> "?"
    | o -> o.GetType().Name

[<EntryPoint; STAThread>]
let main _ =
    let log = ListBox(FontFamily = Media.FontFamily("Consolas"))
    let stopAtMiddle = CheckBox(Content = "在中间层（Grid）截停：e.Handled = true", Margin = Thickness(0., 6., 0., 0.))

    let logLine (stage: string) (eventName: string) (sender: obj) (e: RoutedEventArgs) =
        log.Items.Add(sprintf "%-4s %-18s 挂载点=%-12s 源头=%s" stage eventName (nameOf sender) (nameOf e.OriginalSource)) |> ignore
        if log.Items.Count > 0 then log.ScrollIntoView(log.Items.[log.Items.Count - 1])

    let clear = Button(Content = "清空", Width = 70., VerticalAlignment = VerticalAlignment.Bottom)
    clear.Click.Add(fun _ -> log.Items.Clear())

    // 三层容器：Window → Border → Grid → StackPanel → 按钮
    let deep = Button(Content = "最深处的按钮", Padding = Thickness(12., 8., 12., 8.))
    let custom = AlarmButton(Content = "自定义事件", Padding = Thickness(12., 8., 12., 8.), Margin = Thickness(12., 0., 0., 0.))
    custom.Click.Add(fun _ -> custom.RaiseAlarm())

    let layerStack = StackPanel(Orientation = Orientation.Horizontal,
                                HorizontalAlignment = HorizontalAlignment.Center,
                                VerticalAlignment = VerticalAlignment.Center)
    layerStack.Children.Add(TextBlock(Text = "StackPanel 层", VerticalAlignment = VerticalAlignment.Center,
                                      Margin = Thickness(0., 0., 12., 0.))) |> ignore
    layerStack.Children.Add deep |> ignore
    layerStack.Children.Add custom |> ignore

    let layerGrid = Grid(Background = SolidColorBrush(Color.FromRgb(0xF1uy, 0xF5uy, 0xF9uy)), Margin = Thickness 16.)
    layerGrid.Children.Add layerStack |> ignore

    let layerBorder = Border(BorderBrush = SolidColorBrush(Color.FromRgb(0x94uy, 0xA3uy, 0xB8uy)),
                             BorderThickness = Thickness 2., CornerRadius = CornerRadius 8.,
                             Padding = Thickness 16., Margin = Thickness(0., 0., 0., 12.), Child = layerGrid)

    let window = Window(Title = "路由事件可视化 (F#)", Height = 480., Width = 560.)

    let mountTunnel (el: UIElement) (label: string) (maybeStop: bool) =
        el.AddHandler(UIElement.PreviewMouseDownEvent,
            MouseButtonEventHandler(fun _ e ->
                logLine "隧道" label (box el) e
                // IsChecked 是 Nullable<bool>——F# 里判真用 GetValueOrDefault（没有 x = true 的可空比较）
                if maybeStop && stopAtMiddle.IsChecked.GetValueOrDefault() then
                    e.Handled <- true
                    logLine "……" "截停 e.Handled" (box el) e),
            true) |> ignore

    let mountBubble (el: UIElement) (label: string) =
        el.AddHandler(UIElement.MouseDownEvent,
            MouseButtonEventHandler(fun _ e -> logLine "冒泡" label (box el) e), true) |> ignore

    mountTunnel window "Window.PreviewMouseDown" false
    mountTunnel layerBorder "Border.PreviewMouseDown" false
    mountTunnel layerGrid "Grid.PreviewMouseDown" true
    mountTunnel deep "Button.PreviewMouseDown" false
    mountTunnel custom "Button.PreviewMouseDown" false

    mountBubble deep "Button.MouseDown"
    mountBubble custom "Button.MouseDown"
    mountBubble layerGrid "Grid.MouseDown"
    mountBubble layerBorder "Border.MouseDown"
    mountBubble window "Window.MouseDown"

    deep.Click.Add(fun _ -> logLine "路由" "Button.Click" (box deep) (RoutedEventArgs(Button.ClickEvent, deep)))
    // 自定义路由事件：挂到 window 上看它从按钮一路冒泡上来
    window.AddHandler(AlarmButton.AlarmEvent,
        RoutedEventHandler(fun s e -> logLine "路由" "自定义 Alarm 冒泡到 Window" s e)) |> ignore

    // 总装
    let bottom = Grid()
    bottom.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength(1., GridUnitType.Star)))
    bottom.ColumnDefinitions.Add(ColumnDefinition(Width = GridLength.Auto))
    Grid.SetColumn(clear, 1)
    bottom.Children.Add log |> ignore
    bottom.Children.Add clear |> ignore

    let top = StackPanel(Margin = Thickness(0., 0., 0., 10.))
    let intro = TextBlock(Text = "点下面的按钮或空白处，看事件如何先隧道（根→子）再冒泡（子→根）穿过三层容器",
                          Foreground = SolidColorBrush(Color.FromRgb(0x55uy, 0x55uy, 0x55uy)), TextWrapping = TextWrapping.Wrap)
    top.Children.Add intro |> ignore
    top.Children.Add stopAtMiddle |> ignore

    let dock = DockPanel(Margin = Thickness 12.)
    DockPanel.SetDock(top, Dock.Top)
    DockPanel.SetDock(bottom, Dock.Bottom)
    dock.Children.Add top |> ignore
    dock.Children.Add bottom |> ignore
    dock.Children.Add layerBorder |> ignore

    window.Content <- dock
    Application().Run window
