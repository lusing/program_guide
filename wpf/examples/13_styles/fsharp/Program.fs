// 13 资源与样式（F# 版）：与 csharp/ 版功能一致。
// 两个代码建树的关键换算：
//   {StaticResource key}   → Resources[key] 取出直接赋值（或 SetBinding 时用）
//   {DynamicResource key}  → SetResourceReference(属性, key)——改资源就地刷新（换肤的根基）
//   {TemplateBinding X}    → Binding("X", RelativeSource = RelativeSource.TemplatedParent)
module StyleDemoFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Data
open System.Windows.Media

let brushFromHex (hex: string) =
    ColorConverter.ConvertFromString hex :?> Color |> SolidColorBrush

[<EntryPoint; STAThread>]
let main _ =
    let window = Window(Title = "Style Demo (F#)", Height = 280., Width = 500.)

    // ── PrimaryButtonStyle：样式 + 模板 + 触发器 ──
    // ControlTemplate 里 XAML 的 TemplateBinding 是标记扩展，代码里没有——
    // 等价物是 RelativeSource.TemplatedParent 的普通 Binding
    let borderF = FrameworkElementFactory(typeof<Border>)
    borderF.SetBinding(Border.BackgroundProperty,
                       Binding("Background", RelativeSource = RelativeSource.TemplatedParent))
    borderF.SetBinding(Border.PaddingProperty,
                       Binding("Padding", RelativeSource = RelativeSource.TemplatedParent))
    borderF.SetValue(Border.CornerRadiusProperty, CornerRadius 6.)
    let presenter = FrameworkElementFactory(typeof<ContentPresenter>)
    presenter.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Center)
    borderF.AppendChild presenter |> ignore

    let template = ControlTemplate(typeof<Button>)
    template.VisualTree <- borderF

    let primaryStyle = Style(typeof<Button>)
    primaryStyle.Setters.Add(Setter(Button.BackgroundProperty, brushFromHex "#3B82F6"))
    primaryStyle.Setters.Add(Setter(Button.ForegroundProperty, Brushes.White))
    primaryStyle.Setters.Add(Setter(Button.FontWeightProperty, FontWeights.Bold))
    primaryStyle.Setters.Add(Setter(Button.PaddingProperty, Thickness(14., 8., 14., 8.)))
    primaryStyle.Setters.Add(Setter(Button.MarginProperty, Thickness(0., 0., 12., 0.)))
    primaryStyle.Setters.Add(Setter(Button.TemplateProperty, template))
    // Trigger 没有 (属性, 值) 构造器——命名实参初始化是 XAML 属性语法的直接对应
    let hover = Trigger(Property = Control.IsMouseOverProperty, Value = true)
    hover.Setters.Add(Setter(Button.BackgroundProperty, brushFromHex "#2563EB"))
    primaryStyle.Triggers.Add hover

    // ── AccentTextStyle ──
    let accentStyle = Style(typeof<TextBlock>)
    accentStyle.Setters.Add(Setter(TextBlock.ForegroundProperty, brushFromHex "#1D4ED8"))
    accentStyle.Setters.Add(Setter(TextBlock.FontSizeProperty, 18.))
    accentStyle.Setters.Add(Setter(TextBlock.FontWeightProperty, FontWeights.Bold))

    // ── 动态资源换肤（教材 10.3.2 / 11.3.5）──
    let skins = [| brushFromHex "#8B5CF6"; brushFromHex "#0EA5E9"; brushFromHex "#F59E0B" |]
    window.Resources.Add("accentBrush", skins.[0]) |> ignore
    let mutable skinIndex = 0
    let skinBtn = Button(Content = "动态资源皮肤（点我换肤）", Foreground = Brushes.White,
                         Padding = Thickness(14., 8., 14., 8.), HorizontalAlignment = HorizontalAlignment.Left)
    skinBtn.SetResourceReference(Button.BackgroundProperty, "accentBrush")   // = {DynamicResource accentBrush}
    skinBtn.Click.Add(fun _ ->
        skinIndex <- (skinIndex + 1) % skins.Length
        window.Resources.["accentBrush"] <- skins.[skinIndex])

    // ── 总装（{StaticResource X} = 建好后直接赋值）──
    let title = TextBlock(Text = "样式与资源示例", Margin = Thickness(0., 0., 0., 12.), Style = accentStyle)
    let save = Button(Content = "保存", Style = primaryStyle)
    let cancel = Button(Content = "取消", Width = 96.)
    let buttonRow = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 0., 0., 12.))
    buttonRow.Children.Add save |> ignore
    buttonRow.Children.Add cancel |> ignore
    let box = TextBox(Text = "统一风格的文本框", Height = 32., Width = 260.,
                      HorizontalAlignment = HorizontalAlignment.Left, Margin = Thickness(0., 0., 0., 12.))

    let panel = StackPanel(Margin = Thickness 20.)
    for c in [ title :> UIElement; buttonRow; box; skinBtn ] do
        panel.Children.Add c |> ignore

    window.Content <- panel
    Application().Run window
