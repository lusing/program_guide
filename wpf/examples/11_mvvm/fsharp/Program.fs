// 11 MVVM 模式（F# 版）：与 csharp/ 版功能一致。
// F# 的 MVVM 三件：INPC 用 Event+CLIEvent；RelayCommand 直接闭包；
// 「View 只认 ViewModel，一行事件处理器都没有」在 F# 里体现得更纯粹。
module MvvmDemoFs.Program

open System
open System.ComponentModel
open System.Windows
open System.Windows.Controls
open System.Windows.Data
open System.Windows.Input

// ── RelayCommand：命令对象的 F# 形态（execute/canExecute 都是函数值）──
type RelayCommand(execute: obj -> unit, ?canExecute: obj -> bool) =
    let canChanged = Event<EventHandler, EventArgs>()
    interface ICommand with
        [<CLIEvent>]
        member _.CanExecuteChanged = canChanged.Publish
        member _.CanExecute parameter =
            match canExecute with Some f -> f parameter | None -> true
        member _.Execute parameter = execute parameter
    member _.RaiseCanExecuteChanged() = canChanged.Trigger(null, EventArgs.Empty)

// ── ViewModel ──
type MainViewModel() as this =
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let mutable taskName = "学习 WPF"
    let mutable statusMessage = "待处理"

    let addTask = RelayCommand(fun _ ->
        if String.IsNullOrWhiteSpace taskName then
            statusMessage <- "任务名称不能为空。"
            pc.Trigger(this, PropertyChangedEventArgs "StatusMessage")
        else
            statusMessage <- sprintf "已添加任务: %s" taskName
            pc.Trigger(this, PropertyChangedEventArgs "StatusMessage"))

    member _.TaskName
        with get () = taskName
        and set v =
            if taskName <> v then
                taskName <- v
                pc.Trigger(this, PropertyChangedEventArgs "TaskName")
    member _.StatusMessage
        with get () = statusMessage
        and set v =
            if statusMessage <> v then
                statusMessage <- v
                pc.Trigger(this, PropertyChangedEventArgs "StatusMessage")
    member _.AddTaskCommand = addTask :> ICommand

    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

[<EntryPoint; STAThread>]
let main _ =
    let vm = MainViewModel()

    let nameBox = TextBox(Margin = Thickness(0., 0., 0., 12.))
    nameBox.SetBinding(TextBox.TextProperty,
                       Binding("TaskName", UpdateSourceTrigger = UpdateSourceTrigger.PropertyChanged)) |> ignore

    let status = TextBlock(FontSize = 18., Margin = Thickness(0., 0., 0., 12.))
    status.SetBinding(TextBlock.TextProperty, Binding "StatusMessage") |> ignore

    let addBtn = Button(Content = "添加任务", Width = 150., Height = 36.)
    addBtn.SetBinding(Button.CommandProperty, Binding "AddTaskCommand") |> ignore

    let panel = StackPanel(VerticalAlignment = VerticalAlignment.Center)
    panel.Children.Add(TextBlock(Text = "任务名称", FontWeight = FontWeights.Bold,
                                 Margin = Thickness(0., 0., 0., 8.))) |> ignore
    panel.Children.Add nameBox |> ignore
    panel.Children.Add status |> ignore
    panel.Children.Add addBtn |> ignore

    let window = Window(Title = "MVVM Demo (F#)", Height = 240., Width = 420.,
                        Content = Grid(Margin = Thickness 20.))
    (window.Content :?> Grid).Children.Add panel |> ignore
    window.DataContext <- vm
    Application().Run window
