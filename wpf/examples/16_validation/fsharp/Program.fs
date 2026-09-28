// 16 数据验证（F# 版）：与 csharp/ 版功能一致——INotifyDataErrorInfo 全套。
// 接口三件：HasErrors / GetErrors(非泛型 IEnumerable) / ErrorsChanged（要 CLIEvent）。
// 界面侧的 (Validation.Errors)[0].ErrorContent 绑定在代码里照用：Binding + ElementName（先 RegisterName）。
module ValidationDemoFs.Program

open System
open System.Collections
open System.Collections.Generic
open System.ComponentModel
open System.Windows
open System.Windows.Controls
open System.Windows.Data
open System.Windows.Media

let brushFromHex (hex: string) =
    ColorConverter.ConvertFromString hex :?> Color |> SolidColorBrush

// ── ViewModel：INPC + INotifyDataErrorInfo 双接口 ──
type FormViewModel() as this =
    let errors = Dictionary<string, List<string>>()
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let ec = Event<EventHandler<DataErrorsChangedEventArgs>, DataErrorsChangedEventArgs>()

    let mutable userName = ""
    let mutable ageText = ""
    let mutable email = ""
    let mutable result = ""

    let hasErrors () = errors.Values |> Seq.exists (fun l -> l.Count > 0)

    let setErrors (name: string) (newErrors: List<string>) =
        let changed =
            match errors.TryGetValue(name) with
            | false, _ -> true
            | true, old -> not (old.Count = newErrors.Count && Seq.forall2 (=) old newErrors)
        if changed then
            if newErrors.Count = 0 then errors.Remove(name) |> ignore
            else errors[name] <- newErrors
            ec.Trigger(this, DataErrorsChangedEventArgs(name))
            pc.Trigger(this, PropertyChangedEventArgs("HasErrors"))

    let validateUserName () =
        let e = List<string>()
        if String.IsNullOrWhiteSpace userName then e.Add "用户名不能为空"
        elif userName.Length < 2 then e.Add "用户名至少 2 个字符"
        setErrors "UserName" e
    let validateAge () =
        let e = List<string>()
        if String.IsNullOrWhiteSpace ageText then e.Add "年龄不能为空"
        else
            match Int32.TryParse ageText with
            | true, age when age >= 18 && age <= 60 -> ()
            | true, _ -> e.Add "年龄必须在 18 到 60 之间"
            | false, _ -> e.Add "年龄必须是整数"
        setErrors "AgeText" e
    let validateEmail () =
        let e = List<string>()
        if not (String.IsNullOrEmpty email) && not (email.Contains '@') then
            e.Add "邮箱必须包含 @（留空表示不填）"
        setErrors "Email" e

    member _.UserName
        with get () = userName
        and set v = userName <- v; pc.Trigger(this, PropertyChangedEventArgs "UserName"); validateUserName ()
    member _.AgeText
        with get () = ageText
        and set v = ageText <- v; pc.Trigger(this, PropertyChangedEventArgs "AgeText"); validateAge ()
    member _.Email
        with get () = email
        and set v = email <- v; pc.Trigger(this, PropertyChangedEventArgs "Email"); validateEmail ()
    member _.Result
        with get () = result
        and set v = result <- v; pc.Trigger(this, PropertyChangedEventArgs "Result")

    member _.Submit() =
        let ok = not (hasErrors ())
        this.Result <-
            if not ok then "表单有错误，请按红框提示修改后再提交。"
            else (sprintf "提交成功：%s，%d 岁%s" userName (Int32.Parse ageText)
                    (if String.IsNullOrEmpty email then "，未留邮箱" else sprintf "，邮箱 %s" email))

    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

    interface INotifyDataErrorInfo with
        [<CLIEvent>]
        member _.ErrorsChanged = ec.Publish
        member _.HasErrors = hasErrors ()
        member _.GetErrors(propertyName: string) : IEnumerable =
            match propertyName with
            | null -> Seq.empty<string> :> IEnumerable
            | name ->
                match errors.TryGetValue(name) with
                | true, list -> list :> IEnumerable
                | _ -> Seq.empty<string> :> IEnumerable

let label (t: string) = TextBlock(Text = t)
let red = brushFromHex "#EF4444"
let hintColor = brushFromHex "#555555"

[<EntryPoint; STAThread>]
let main _ =
    let vm = FormViewModel()
    let window = Window(Title = "表单验证 (F#)", Height = 440., Width = 440.)

    // 自定义错误模板：红框 + 叹号（悬停看完整信息）——15 章工厂法的又一次实战
    let errTemplate = ControlTemplate()
    let row = FrameworkElementFactory(typeof<StackPanel>)
    row.SetValue(StackPanel.OrientationProperty, Orientation.Horizontal)
    let frame = FrameworkElementFactory(typeof<Border>)
    frame.SetValue(Border.BorderBrushProperty, red)
    frame.SetValue(Border.BorderThicknessProperty, Thickness 1.5)
    frame.SetValue(Border.CornerRadiusProperty, CornerRadius 4.)
    frame.AppendChild(FrameworkElementFactory(typeof<AdornedElementPlaceholder>)) |> ignore
    row.AppendChild frame |> ignore
    let mark = FrameworkElementFactory(typeof<TextBlock>)
    mark.SetValue(TextBlock.TextProperty, "!")
    mark.SetValue(TextBlock.ForegroundProperty, red)
    mark.SetValue(TextBlock.FontWeightProperty, FontWeights.Bold)
    mark.SetValue(TextBlock.FontSizeProperty, 16.)
    mark.SetValue(FrameworkElement.MarginProperty, Thickness(6., 0., 0., 0.))
    mark.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    // 模板里的 DataContext 是 Validation.Errors 集合——[0].ErrorContent 直接索引
    mark.SetBinding(FrameworkElement.ToolTipProperty, Binding("[0].ErrorContent"))
    row.AppendChild mark |> ignore
    errTemplate.VisualTree <- row

    // 一行「标签 + 输入框 + 红字」的三连
    let mkField (propName: string) (labelText: string) (tailMargin: double) =
        let box = TextBox(Margin = Thickness(0., 2., 0., 2.))
        let b = Binding(propName, UpdateSourceTrigger = UpdateSourceTrigger.PropertyChanged,
                        ValidatesOnNotifyDataErrors = true)
        box.SetBinding(TextBox.TextProperty, b) |> ignore
        Validation.SetErrorTemplate(box, errTemplate)
        let errLine = TextBlock(Foreground = red, FontSize = 11., Margin = Thickness(4., 0., 0., tailMargin))
        // XAML 的 {Binding (Validation.Errors)[0].ErrorContent, ElementName=X} → 代码版
        window.RegisterName(propName + "Box", box)
        let eb = Binding("(Validation.Errors)[0].ErrorContent", ElementName = propName + "Box", FallbackValue = "")
        errLine.SetBinding(TextBlock.TextProperty, eb) |> ignore
        [ label labelText :> UIElement; box; errLine ]

    let intro = TextBlock(Text = "逐字输入体会验证时机（UpdateSourceTrigger=PropertyChanged）",
                          Foreground = hintColor, Margin = Thickness(0., 0., 0., 14.),
                          TextWrapping = TextWrapping.Wrap)
    let fields =
        mkField "UserName" "用户名（必填 ≥2 字符）" 10.
        @ mkField "AgeText" "年龄（18–60 的整数）" 10.
        @ mkField "Email" "邮箱（可留空；填了须含 @）" 16.

    let submit = Button(Content = "提交", Width = 120., HorizontalAlignment = HorizontalAlignment.Left)
    submit.Click.Add(fun _ -> vm.Submit ())
    let resultLine = TextBlock(Margin = Thickness(0., 16., 0., 0.), TextWrapping = TextWrapping.Wrap,
                               FontWeight = FontWeights.Bold)
    resultLine.SetBinding(TextBlock.TextProperty, Binding "Result") |> ignore

    let panel = StackPanel(Margin = Thickness 20.)
    (intro :> UIElement :: fields @ [ submit; resultLine ]) |> List.iter (fun c -> panel.Children.Add c |> ignore)

    window.Content <- panel
    window.DataContext <- vm
    Application().Run window
