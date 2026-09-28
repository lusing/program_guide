// 14 触发器（F# 版）：与 csharp/ 版功能一致——四类触发器全部代码化。
//   Trigger       = Trigger(Property = ..., Value = ...)
//   MultiTrigger  = conditions 逐个 Add（Condition 有 (DP, value) 构造器）
//   DataTrigger   = Binding 指到源头控件 + Value
//   EventTrigger  = ctor 收 RoutedEvent；Storyboard 装进 BeginStoryboard 再进 Actions
module TriggersDemoFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Data
open System.Windows.Media
open System.Windows.Media.Animation

let brushFromHex (hex: string) =
    ColorConverter.ConvertFromString hex :?> Color |> SolidColorBrush

let header (t: string) = TextBlock(Text = t, FontWeight = FontWeights.Bold, Margin = Thickness(0., 8., 0., 8.))

[<EntryPoint; STAThread>]
let main _ =
    let window = Window(Title = "触发器实验室 (F#)", Height = 520., Width = 460.)

    // ① 属性触发器
    let focusStyle = Style(typeof<TextBox>)
    focusStyle.Setters.Add(Setter(TextBox.MarginProperty, Thickness(0., 0., 0., 8.)))
    focusStyle.Setters.Add(Setter(TextBox.PaddingProperty, Thickness(6., 4., 6., 4.)))
    let ft = Trigger(Property = TextBox.IsKeyboardFocusWithinProperty, Value = true)
    ft.Setters.Add(Setter(TextBox.BackgroundProperty, brushFromHex "#FFFBEB"))
    ft.Setters.Add(Setter(TextBox.BorderBrushProperty, brushFromHex "#F59E0B"))
    focusStyle.Triggers.Add ft
    let focusBox = TextBox(Text = "点我获得焦点试试", Style = focusStyle)

    // ② 多条件触发器：悬停且可用才加深 + 不可用置灰
    let primaryStyle = Style(typeof<Button>)
    primaryStyle.Setters.Add(Setter(Button.BackgroundProperty, brushFromHex "#3B82F6"))
    primaryStyle.Setters.Add(Setter(Button.ForegroundProperty, Brushes.White))
    primaryStyle.Setters.Add(Setter(Button.PaddingProperty, Thickness(14., 8., 14., 8.)))
    let multi = MultiTrigger()
    multi.Conditions.Add(Condition(Control.IsMouseOverProperty, true))
    multi.Conditions.Add(Condition(Control.IsEnabledProperty, true))
    multi.Setters.Add(Setter(Button.BackgroundProperty, brushFromHex "#1D4ED8"))
    primaryStyle.Triggers.Add multi
    let disabled = Trigger(Property = Control.IsEnabledProperty, Value = false)
    disabled.Setters.Add(Setter(Button.BackgroundProperty, brushFromHex "#CBD5E1"))
    disabled.Setters.Add(Setter(Button.ForegroundProperty, brushFromHex "#64748B"))
    primaryStyle.Triggers.Add disabled

    let agreeBox = CheckBox(Content = "同意协议（勾选后按钮变为可用）", Margin = Thickness(0., 0., 0., 8.))
    let submit = Button(Content = "提交", Width = 120., HorizontalAlignment = HorizontalAlignment.Left,
                        Style = primaryStyle)
    submit.SetBinding(Button.IsEnabledProperty, Binding("IsChecked", Source = agreeBox)) |> ignore

    // ③ 数据触发器：一个 CheckBox 驱动面板+文字换肤（零事件代码）
    let darkBox = CheckBox(Content = "夜间模式", Margin = Thickness(0., 0., 0., 8.))
    let panelStyle = Style(typeof<Border>)
    panelStyle.Setters.Add(Setter(Border.BackgroundProperty, brushFromHex "#F1F5F9"))
    let dt = DataTrigger(Binding = Binding("IsChecked", Source = darkBox), Value = true)
    dt.Setters.Add(Setter(Border.BackgroundProperty, brushFromHex "#1E293B"))
    panelStyle.Triggers.Add dt
    let textStyle = Style(typeof<TextBlock>)
    textStyle.Setters.Add(Setter(TextBlock.ForegroundProperty, brushFromHex "#0F172A"))
    let dt2 = DataTrigger(Binding = Binding("IsChecked", Source = darkBox), Value = true)
    dt2.Setters.Add(Setter(TextBlock.ForegroundProperty, brushFromHex "#E2E8F0"))
    textStyle.Triggers.Add dt2
    let panelText = TextBlock(Text = "两个 DataTrigger（面板背景 + 文字颜色）同时响应一个状态", Style = textStyle)
    let darkPanel = Border(CornerRadius = CornerRadius 8., Padding = Thickness 16.,
                          Margin = Thickness(0., 0., 0., 8.), Style = panelStyle, Child = panelText)

    // ④ 事件触发器：窗口淡入 + 按钮滑过伸缩
    let fadeIn = DoubleAnimation(From = Nullable 0., To = Nullable 1., Duration = Duration(TimeSpan.FromSeconds 0.6))
    Storyboard.SetTarget(fadeIn, window)
    Storyboard.SetTargetProperty(fadeIn, PropertyPath(Window.OpacityProperty))
    let fadeInSb = Storyboard()
    fadeInSb.Children.Add fadeIn |> ignore
    let loadedTrigger = EventTrigger(FrameworkElement.LoadedEvent)
    (loadedTrigger.Actions.Add(BeginStoryboard(Storyboard = fadeInSb)) |> ignore)
    window.Triggers.Add loadedTrigger |> ignore

    let hoverBtn = Button(Content = "鼠标滑过我", Width = 120., HorizontalAlignment = HorizontalAlignment.Left)
    // EventTrigger 的 Actions 是只读集合——没有初始化器捷径，只能逐个 Add：
    let onEnter = EventTrigger(UIElement.MouseEnterEvent)
    let enterSb = Storyboard()
    let enterA = DoubleAnimation(To = Nullable 180., Duration = Duration(TimeSpan.FromSeconds 0.25))
    Storyboard.SetTarget(enterA, hoverBtn)
    Storyboard.SetTargetProperty(enterA, PropertyPath(Button.WidthProperty))
    enterSb.Children.Add enterA |> ignore
    onEnter.Actions.Add(BeginStoryboard(Storyboard = enterSb)) |> ignore
    hoverBtn.Triggers.Add onEnter |> ignore

    let onLeave = EventTrigger(UIElement.MouseLeaveEvent)
    let leaveSb = Storyboard()
    let leaveA = DoubleAnimation(To = Nullable 120., Duration = Duration(TimeSpan.FromSeconds 0.25))
    Storyboard.SetTarget(leaveA, hoverBtn)
    Storyboard.SetTargetProperty(leaveA, PropertyPath(Button.WidthProperty))
    leaveSb.Children.Add leaveA |> ignore
    onLeave.Actions.Add(BeginStoryboard(Storyboard = leaveSb)) |> ignore
    hoverBtn.Triggers.Add onLeave |> ignore

    // 总装
    let panel = StackPanel(Margin = Thickness 16.)
    let ui (x: #UIElement) = x :> UIElement
    for c in [ ui (header "① 属性触发器：点击输入框获得焦点，背景与边框自动变色"); ui focusBox
               ui (header "② 多条件触发器：按钮「悬停 且 可用」才变深色"); ui agreeBox; ui submit
               ui (header "③ 数据触发器：CheckBox 的状态驱动整个面板换肤（零代码）"); ui darkBox; ui darkPanel
               ui (header "④ 事件触发器：鼠标移入/移出，按钮宽度动画伸缩（动画预告）"); ui hoverBtn ] do
        panel.Children.Add c |> ignore

    window.Content <- ScrollViewer(VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Content = panel)
    Application().Run window
