// 15 模板（F# 版）：与 csharp/ 版功能一致。
// 模板触发器的 TargetName 在代码里是两件事：factory.Name = "Chrome" 注册部件名 +
// Setter.TargetName = "Chrome" 指名道姓地改它。
module TemplatesDemoFs.Program

open System
open System.Collections.ObjectModel
open System.ComponentModel
open System.Windows
open System.Windows.Controls
open System.Windows.Controls.Primitives   // ButtonBase（IsPressedProperty）在这里
open System.Windows.Data
open System.Windows.Media
open System.Windows.Shapes

let brushFromHex (hex: string) =
    ColorConverter.ConvertFromString hex :?> Color |> SolidColorBrush

// AgeGroup 是「为显示预加工」的属性——模板触发器只做等值比较，范围判断提前算好
type Person(name: string, age: int) =
    member _.Name = name
    member _.Age = age
    member _.AgeGroup = if age < 30 then "青年" elif age < 50 then "中年" else "资深"

type PeopleViewModel() =
    let people = ObservableCollection<Person>()
    do
        for (n, a) in [ "张三", 24; "李四", 35; "王五", 46; "赵六", 58; "孙七", 28 ] do
            people.Add(Person(n, a))
    let mutable selected = Unchecked.defaultof<Person>
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()

    member _.People = people
    member _.Selected
        with get () = selected
        and set v = selected <- v; pc.Trigger(null, PropertyChangedEventArgs "Selected")

    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

let header (t: string) = TextBlock(Text = t, FontWeight = FontWeights.Bold)
let hint (t: string) = TextBlock(Text = t, Foreground = brushFromHex "#555555")

/// PersonCard：Ellipse 圆点按 AgeGroup 变色 + 姓名 + 年龄 + 分组徽章
let personCard () : DataTemplate =
    let dotStyle = Style(typeof<Ellipse>)
    dotStyle.Setters.Add(Setter(Ellipse.FillProperty, brushFromHex "#94A3B8"))
    for (grp, hex) in [ "青年", "#3B82F6"; "中年", "#F59E0B" ] do
        let dt = DataTrigger(Binding = Binding "AgeGroup", Value = grp)
        dt.Setters.Add(Setter(Ellipse.FillProperty, brushFromHex hex))
        dotStyle.Triggers.Add dt

    let row = FrameworkElementFactory(typeof<StackPanel>)
    row.SetValue(StackPanel.OrientationProperty, Orientation.Horizontal)
    row.SetValue(FrameworkElement.MarginProperty, Thickness(0., 2., 0., 2.))

    let dot = FrameworkElementFactory(typeof<Ellipse>)
    dot.SetValue(Ellipse.WidthProperty, 10.)
    dot.SetValue(Ellipse.HeightProperty, 10.)
    dot.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    dot.SetValue(FrameworkElement.StyleProperty, dotStyle)
    row.AppendChild dot |> ignore

    let name = FrameworkElementFactory(typeof<TextBlock>)
    name.SetBinding(TextBlock.TextProperty, Binding "Name")
    name.SetValue(TextBlock.FontWeightProperty, FontWeights.Bold)
    name.SetValue(FrameworkElement.MarginProperty, Thickness(8., 0., 0., 0.))
    name.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    row.AppendChild name |> ignore

    let age = FrameworkElementFactory(typeof<TextBlock>)
    age.SetBinding(TextBlock.TextProperty, Binding("Age", StringFormat = "（{0} 岁）"))
    age.SetValue(TextBlock.ForegroundProperty, brushFromHex "#64748B")
    age.SetValue(FrameworkElement.MarginProperty, Thickness(4., 0., 0., 0.))
    age.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    row.AppendChild age |> ignore

    let badge = FrameworkElementFactory(typeof<Border>)
    badge.SetValue(Border.BackgroundProperty, brushFromHex "#F1F5F9")
    badge.SetValue(Border.CornerRadiusProperty, CornerRadius 8.)
    badge.SetValue(Border.PaddingProperty, Thickness(8., 1., 8., 1.))
    badge.SetValue(FrameworkElement.MarginProperty, Thickness(8., 0., 0., 0.))
    badge.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    let badgeText = FrameworkElementFactory(typeof<TextBlock>)
    badgeText.SetBinding(TextBlock.TextProperty, Binding "AgeGroup")
    badgeText.SetValue(TextBlock.FontSizeProperty, 11.)
    badgeText.SetValue(TextBlock.ForegroundProperty, brushFromHex "#475569")
    badge.AppendChild badgeText |> ignore
    row.AppendChild badge |> ignore

    let dt = DataTemplate(typeof<Person>)
    dt.VisualTree <- row
    dt

[<EntryPoint; STAThread>]
let main _ =
    let vm = PeopleViewModel()
    let window = Window(Title = "模板实验室 (F#)", Height = 560., Width = 520.)

    // ① ControlTemplate：圆角按钮（部件名 Chrome + 模板内部触发器）
    let chrome = FrameworkElementFactory(typeof<Border>)
    chrome.Name <- "Chrome"   // XAML 里 Border x:Name="Chrome" 的代码等价物
    chrome.SetValue(Border.CornerRadiusProperty, CornerRadius 18.)
    chrome.SetBinding(Border.BackgroundProperty, Binding("Background", RelativeSource = RelativeSource.TemplatedParent))
    chrome.SetBinding(Border.PaddingProperty, Binding("Padding", RelativeSource = RelativeSource.TemplatedParent))
    let presenter = FrameworkElementFactory(typeof<ContentPresenter>)
    presenter.SetValue(FrameworkElement.HorizontalAlignmentProperty, HorizontalAlignment.Center)
    presenter.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    chrome.AppendChild presenter |> ignore

    let roundTemplate = ControlTemplate(typeof<Button>)
    roundTemplate.VisualTree <- chrome
    // TargetName 触发器：Setter 要指名 TargetName = "Chrome"
    let targetSetter (prop: DependencyProperty) (value: obj) =
        let s = Setter(prop, value)
        s.TargetName <- "Chrome"
        s
    let hoverT = Trigger(Property = Control.IsMouseOverProperty, Value = true)
    hoverT.Setters.Add(targetSetter UIElement.OpacityProperty 0.85) |> ignore
    roundTemplate.Triggers.Add hoverT
    let pressT = Trigger(Property = ButtonBase.IsPressedProperty, Value = true)
    pressT.Setters.Add(targetSetter UIElement.OpacityProperty 0.7) |> ignore
    pressT.Setters.Add(targetSetter Border.BorderBrushProperty (brushFromHex "#0EA5E9")) |> ignore
    pressT.Setters.Add(targetSetter Border.BorderThicknessProperty (Thickness 2.)) |> ignore
    roundTemplate.Triggers.Add pressT
    let disT = Trigger(Property = Control.IsEnabledProperty, Value = false)
    disT.Setters.Add(targetSetter UIElement.OpacityProperty 0.4) |> ignore
    roundTemplate.Triggers.Add disT

    // 同一个模板，换色即换「皮肤」：BasedOn 继承再覆盖
    let blueStyle = Style(typeof<Button>)
    blueStyle.Setters.Add(Setter(Button.TemplateProperty, roundTemplate))
    blueStyle.Setters.Add(Setter(Button.BackgroundProperty, brushFromHex "#3B82F6"))
    blueStyle.Setters.Add(Setter(Button.ForegroundProperty, Brushes.White))
    blueStyle.Setters.Add(Setter(Button.PaddingProperty, Thickness(20., 10., 20., 10.)))
    let greenStyle = Style(typeof<Button>, BasedOn = blueStyle)
    greenStyle.Setters.Add(Setter(Button.BackgroundProperty, brushFromHex "#10B981"))

    let mkBtn (content: string) (style: Style) = Button(Content = content, Style = style, Margin = Thickness(0., 0., 12., 0.))
    let blue1 = mkBtn "蓝色按钮" blueStyle
    let green1 = mkBtn "绿色按钮" greenStyle
    let disabledBtn = mkBtn "禁用态" blueStyle
    disabledBtn.IsEnabled <- false
    let buttonRow = StackPanel(Orientation = Orientation.Horizontal)
    for b in [ blue1; green1; disabledBtn ] do buttonRow.Children.Add b |> ignore

    // ② DataTemplate 三处复用
    let card = personCard ()
    let listBox = ListBox(ItemTemplate = card, Margin = Thickness(0., 2., 0., 10.))
    listBox.SetBinding(ListBox.ItemsSourceProperty, Binding "People") |> ignore
    listBox.SetBinding(ListBox.SelectedItemProperty, Binding "Selected") |> ignore
    let items = ItemsControl(ItemTemplate = card, Margin = Thickness(0., 2., 0., 10.))
    items.SetBinding(ItemsControl.ItemsSourceProperty, Binding "People") |> ignore
    let single = ContentControl(ContentTemplate = card)
    single.SetBinding(ContentControl.ContentProperty, Binding "Selected") |> ignore
    let singleHost = Border(BorderBrush = brushFromHex "#CBD5E1", BorderThickness = Thickness 1.,
                            CornerRadius = CornerRadius 8., Padding = Thickness 12., Child = single)

    let panel = StackPanel(Margin = Thickness 16.)
    let ui (x: #UIElement) = x :> UIElement
    for c in [ ui (header "① ControlTemplate：圆角按钮，悬停/按压状态由模板内部触发器负责")
               ui buttonRow
               TextBlock(Text = "② DataTemplate：同一份 PersonCard 模板用在三个地方",
                         FontWeight = FontWeights.Bold, Margin = Thickness(0., 20., 0., 4.)) :> UIElement
               ui (hint "ListBox（可选）："); ui listBox
               ui (hint "ItemsControl（纯展示，无选中无高亮）："); ui items
               ui (hint "ContentControl（单个对象，选中谁显示谁）："); ui singleHost
               TextBlock(Text = "↑ 在上面的 ListBox 里点选一行，这里跟着变——模板只管长相，数据决定内容",
                         Foreground = brushFromHex "#555555", FontSize = 11.,
                         Margin = Thickness(0., 6., 0., 0.)) :> UIElement ] do
        panel.Children.Add c |> ignore

    window.Content <- ScrollViewer(VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Content = panel)
    window.DataContext <- vm
    Application().Run window
