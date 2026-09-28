// 10 绑定进阶（F# 版）：与 csharp/ 版功能一致。
// 三件套的 F# 形态：
//   INPC          → Event<_,_> + [<CLIEvent>] 暴露（接口成员的硬性要求 FS0859）
//   ObservableCollection → 直接用（元素内部变化仍靠 INPC）
//   DataTemplate  → 代码建树只能 FrameworkElementFactory（VisualTree 工厂）
module BindingAdvancedFs.Program

open System
open System.Collections.ObjectModel
open System.Collections.Specialized
open System.ComponentModel
open System.Globalization
open System.Windows
open System.Windows.Controls
open System.Windows.Data

// ── 转换器 ──
type BoolToVisibilityConverter() =
    interface IValueConverter with
        member _.Convert(value, _, _, _) : obj =
            match value with
            | :? bool as b when b -> box Visibility.Visible
            | _ -> box Visibility.Collapsed
        member _.ConvertBack(value, _, _, _) : obj =
            match value with
            | :? Visibility as v -> box (v = Visibility.Visible)
            | _ -> box false

type FullNameConverter() =
    interface IMultiValueConverter with
        member _.Convert(values: obj[], _, _, _) : obj =
            let last = if values.Length > 0 then string values.[0] else ""
            let first = if values.Length > 1 then string values.[1] else ""
            box (last + first)
        member _.ConvertBack(_, _, _, _) : obj[] =
            raise (NotSupportedException "单向聚合，不回写")

// ── INPC 实体：Event + CLIEvent 是 F# 的标准姿势 ──
type TaskItem() as this =
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let mutable name = ""
    let mutable isDone = false
    member _.Name
        with get () = name
        and set v = name <- v; pc.Trigger(this, PropertyChangedEventArgs "Name")
    member _.Done
        with get () = isDone
        and set v = isDone <- v; pc.Trigger(this, PropertyChangedEventArgs "Done")
    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

type MainViewModel() as this =
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let notify (n: string) = pc.Trigger(this, PropertyChangedEventArgs n)
    let mutable firstName = "三"
    let mutable lastName = "张"
    let mutable progress = 30.
    let mutable selectedTask = Unchecked.defaultof<TaskItem>   // 可空引用：绑定SelectedItem
    let mutable taskCount = 0
    let mutable showStats = true
    let tasks = ObservableCollection<TaskItem>()
    do
        for n in [ "学习绑定四要素"; "实现 INPC"; "用上 ObservableCollection" ] do
            tasks.Add(TaskItem(Name = n))
        tasks.CollectionChanged.Add(fun _ ->
            taskCount <- tasks.Count
            notify "TaskCount")
        taskCount <- tasks.Count

    member _.FirstName with get () = firstName and set v = firstName <- v; notify "FirstName"
    member _.LastName with get () = lastName and set v = lastName <- v; notify "LastName"
    member _.Progress with get () = progress and set v = progress <- v; notify "Progress"
    member _.Tasks = tasks
    member _.SelectedTask with get () = selectedTask and set v = selectedTask <- v; notify "SelectedTask"
    member _.TaskCount = taskCount
    member _.ShowStats with get () = showStats and set v = showStats <- v; notify "ShowStats"

    member _.AddTask(name: string) =
        if not (String.IsNullOrWhiteSpace name) then
            tasks.Add(TaskItem(Name = name.Trim()))
    member _.RemoveSelected() =
        // F# 自定义类默认不接受 null 字面量（没有 AllowNullLiteral）——判空走 ReferenceEquals
        if not (obj.ReferenceEquals(selectedTask, null)) then tasks.Remove selectedTask |> ignore

    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

let header (t: string) = TextBlock(Text = t, FontWeight = FontWeights.Bold, Margin = Thickness(0., 0., 0., 8.))

[<EntryPoint; STAThread>]
let main _ =
    let vm = MainViewModel()

    // ① MultiBinding：两个源聚合成一个目标
    let lastBox = TextBox(Width = 120., ToolTip = "姓", Margin = Thickness(0., 0., 8., 0.))
    lastBox.SetBinding(TextBox.TextProperty,
                       Binding("LastName", UpdateSourceTrigger = UpdateSourceTrigger.PropertyChanged)) |> ignore
    let firstBox = TextBox(Width = 120., ToolTip = "名")
    firstBox.SetBinding(TextBox.TextProperty,
                        Binding("FirstName", UpdateSourceTrigger = UpdateSourceTrigger.PropertyChanged)) |> ignore
    let nameRow = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 0., 0., 4.))
    nameRow.Children.Add lastBox |> ignore
    nameRow.Children.Add firstBox |> ignore
    let fullName = TextBlock(FontSize = 20., Margin = Thickness(0., 4., 0., 16.))
    let mb = MultiBinding(Converter = FullNameConverter())
    mb.Bindings.Add(Binding "LastName") |> ignore
    mb.Bindings.Add(Binding "FirstName") |> ignore
    fullName.SetBinding(TextBlock.TextProperty, mb) |> ignore

    // ② 数值绑定 + StringFormat
    let slider = Slider(Minimum = 0., Maximum = 100., Margin = Thickness(0., 0., 0., 4.))
    slider.SetBinding(Slider.ValueProperty, Binding "Progress") |> ignore
    let bar = ProgressBar(Minimum = 0., Maximum = 100., Height = 18., Margin = Thickness(0., 0., 0., 4.))
    bar.SetBinding(ProgressBar.ValueProperty, Binding "Progress") |> ignore
    let pct = TextBlock(Margin = Thickness(0., 0., 0., 16.))
    pct.SetBinding(TextBlock.TextProperty, Binding("Progress", StringFormat = "完成 {0:F0}%")) |> ignore

    // ③ 集合绑定 + ItemTemplate（FrameworkElementFactory）
    let newTaskBox = TextBox(Width = 240., Margin = Thickness(0., 0., 8., 0.))
    let addBtn = Button(Content = "添加", Width = 70.)
    let addTask () =
        vm.AddTask newTaskBox.Text
        newTaskBox.Text <- ""
        newTaskBox.Focus() |> ignore
    addBtn.Click.Add(fun _ -> addTask ())
    newTaskBox.KeyDown.Add(fun e -> if e.Key = Input.Key.Enter then addTask ())
    let inputRow = StackPanel(Orientation = Orientation.Horizontal, Margin = Thickness(0., 0., 0., 6.))
    inputRow.Children.Add newTaskBox |> ignore
    inputRow.Children.Add addBtn |> ignore

    let dt = DataTemplate(typeof<TaskItem>)
    let row = FrameworkElementFactory(typeof<StackPanel>)
    row.SetValue(StackPanel.OrientationProperty, Orientation.Horizontal)
    let cb = FrameworkElementFactory(typeof<CheckBox>)
    cb.SetBinding(CheckBox.IsCheckedProperty, Binding "Done")
    cb.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    let tb = FrameworkElementFactory(typeof<TextBlock>)
    tb.SetBinding(TextBlock.TextProperty, Binding "Name")
    tb.SetValue(FrameworkElement.MarginProperty, Thickness(8., 0., 0., 0.))
    tb.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Center)
    row.AppendChild cb |> ignore
    row.AppendChild tb |> ignore
    dt.VisualTree <- row

    let taskList = ListBox(Height = 150., Margin = Thickness(0., 0., 0., 6.), ItemTemplate = dt)
    taskList.SetBinding(ListBox.ItemsSourceProperty, Binding "Tasks") |> ignore
    taskList.SetBinding(ListBox.SelectedItemProperty, Binding "SelectedTask") |> ignore
    let removeBtn = Button(Content = "删除选中项", Width = 110., HorizontalAlignment = HorizontalAlignment.Left,
                          Margin = Thickness(0., 0., 0., 16.))
    removeBtn.Click.Add(fun _ -> vm.RemoveSelected ())

    // ④ 转换器：bool → Visibility
    let showCheck = CheckBox(Content = "显示统计面板（转换器演示）", Margin = Thickness(0., 0., 0., 6.))
    showCheck.SetBinding(CheckBox.IsCheckedProperty, Binding "ShowStats") |> ignore
    let countLine = TextBlock()
    countLine.SetBinding(TextBlock.TextProperty, Binding("TaskCount", StringFormat = "共 {0} 项任务")) |> ignore
    let selectedLine = TextBlock(Foreground = Media.Brushes.Gray)
    selectedLine.SetBinding(TextBlock.TextProperty,
                            Binding("SelectedTask.Name", StringFormat = "当前选中：{0}",
                                    TargetNullValue = "（无）")) |> ignore
    let statsBody = StackPanel()
    statsBody.Children.Add countLine |> ignore
    statsBody.Children.Add selectedLine |> ignore
    let stats = Border(Background = Media.Brushes.WhiteSmoke, CornerRadius = CornerRadius 8.,
                       Padding = Thickness 12., Child = statsBody)
    stats.SetBinding(UIElement.VisibilityProperty, Binding("ShowStats", Converter = BoolToVisibilityConverter())) |> ignore

    // 总装
    let panel = StackPanel(Margin = Thickness 16.)
    let ui (x: #UIElement) = x :> UIElement
    for c in [ ui (header "① MultiBinding：姓 + 名 = 全名"); ui nameRow; ui fullName
               ui (header "② Slider 驱动进度：值格式化全靠 StringFormat"); ui slider; ui bar; ui pct
               ui (header "③ 任务列表：ObservableCollection + 元素 INPC"); ui inputRow; ui taskList; ui removeBtn
               ui showCheck; ui stats ] do
        panel.Children.Add c |> ignore

    let window = Window(Title = "绑定进阶实验室 (F#)", Height = 520., Width = 480., Content = ScrollViewer(Content = panel))
    window.DataContext <- vm   // 窗口设一次，整棵树可绑（DataContext 继承）
    Application().Run window
