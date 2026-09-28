// 09 数据绑定基础（F# 版）：与 csharp/ 版功能一致。
// XAML 的 {Binding ElementName=X, Path=Y} 在纯代码里的直接等价物是 Source=X 的 Binding——
// ElementName 依赖 NameScope 注册，代码建树时直接给 Source 更省事（RegisterName 路线见 20 章动画）。
module BindingDemoFs.Program

open System
open System.Windows
open System.Windows.Controls
open System.Windows.Data

let label (t: string) = TextBlock(Text = t, FontWeight = FontWeights.Bold, Margin = Thickness(0., 0., 0., 8.))

[<EntryPoint; STAThread>]
let main _ =
    let nameEntry = TextBox(Text = "Alice", Margin = Thickness(0., 0., 0., 12.))

    let valueSlider = Slider(Minimum = 0., Maximum = 100., Value = 60., Margin = Thickness(0., 0., 0., 12.))

    // {Binding ElementName=nameEntry, Path=Text, StringFormat='Hello, {0}!'}
    let hello = TextBlock(FontSize = 20., Margin = Thickness(0., 0., 0., 8.))
    let b1 = Binding("Text", Source = nameEntry, StringFormat = "Hello, {0}!")
    hello.SetBinding(TextBlock.TextProperty, b1) |> ignore

    // {Binding ElementName=valueSlider, Path=Value}（Slider.Value 是 double）
    let echo = TextBlock(FontSize = 18.)
    let b2 = Binding("Value", Source = valueSlider)
    echo.SetBinding(TextBlock.TextProperty, b2) |> ignore

    let panel = StackPanel(Margin = Thickness 20.)
    let ui (x: #UIElement) = x :> UIElement   // 异构控件列表：统一上转型（F# 列表元素必须同型）
    for c in [ ui (label "名称"); ui nameEntry
               ui (label "亮度"); ui valueSlider
               ui hello; ui echo ] do
        panel.Children.Add c |> ignore

    let window = Window(Title = "Data Binding Demo (F#)", Height = 260., Width = 420., Content = panel)
    Application().Run window
