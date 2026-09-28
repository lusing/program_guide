// 12 命令系统（F# 版）：与 csharp/ 版功能一致。
// 两套命令机制并存：RelayCommand（ICommand 自实现，配 MVVM）与 WPF 命令库
// （ApplicationCommands.* 的 RoutedUICommand，配 CommandBinding——教材 9.2）。
module CommandDemoFs.Program

open System
open System.ComponentModel
open System.Windows
open System.Windows.Controls
open System.Windows.Data
open System.Windows.Input

type RelayCommand(execute: obj -> unit, ?canExecute: obj -> bool) =
    let canChanged = Event<EventHandler, EventArgs>()
    interface ICommand with
        [<CLIEvent>]
        member _.CanExecuteChanged = canChanged.Publish
        member _.CanExecute p = match canExecute with Some f -> f p | None -> true
        member _.Execute p = execute p
    member _.RaiseCanExecuteChanged() = canChanged.Trigger(null, EventArgs.Empty)

type MainViewModel() as this =
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let mutable taskName = "学习 WPF 命令"
    let mutable statusText = "待执行"
    // 环引用解法：TaskName 的 setter 要调 addCmd.RaiseCanExecuteChanged()，而命令体又要摸属性——
    // 先占位再在 do 块里补上（F# 没有 C# 的「字段初始化器引用 this」余地）
    let mutable addCmd = Unchecked.defaultof<RelayCommand>
    do addCmd <- RelayCommand(
            (fun _ -> this.StatusText <- sprintf "命令已执行: %s" this.TaskName),
            (fun _ -> not (String.IsNullOrWhiteSpace this.TaskName)))

    member private _.Notify(n: string) = pc.Trigger(this, PropertyChangedEventArgs n)

    member _.TaskName
        with get () = taskName
        and set v =
            if taskName <> v then
                taskName <- v
                this.Notify "TaskName"
                addCmd.RaiseCanExecuteChanged()   // 输入变了 → 命令可执行性要重算
    member _.StatusText
        with get () = statusText
        and set v =
            if statusText <> v then
                statusText <- v
                this.Notify "StatusText"

    member _.AddTaskCommand : ICommand = addCmd :> ICommand

    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

[<EntryPoint; STAThread>]
let main _ =
    let vm = MainViewModel()

    let nameBox = TextBox(Width = 250., HorizontalAlignment = HorizontalAlignment.Left, Margin = Thickness(0., 0., 0., 12.))
    nameBox.SetBinding(TextBox.TextProperty,
                       Binding("TaskName", UpdateSourceTrigger = UpdateSourceTrigger.PropertyChanged)) |> ignore

    let runBtn = Button(Content = "执行命令", Width = 140., Height = 36.)
    runBtn.SetBinding(Button.CommandProperty, Binding "AddTaskCommand") |> ignore

    let status = TextBlock(Margin = Thickness(0., 12., 0., 0.), FontSize = 16.)
    status.SetBinding(TextBlock.TextProperty, Binding "StatusText") |> ignore

    // WPF 命令库（教材 9.2.5）：ApplicationCommands.Copy 是现成的 RoutedUICommand
    let window = Window(Title = "Command Demo (F#)", Height = 260., Width = 420.)
    window.CommandBindings.Add(
        CommandBinding(ApplicationCommands.Copy,
                       ExecutedRoutedEventHandler(fun _ _ ->
                           MessageBox.Show(window, "ApplicationCommands.Copy 执行（WPF 命令库）", "Command") |> ignore),
                       CanExecuteRoutedEventHandler(fun _ e -> e.CanExecute <- true))) |> ignore
    let libBtn = Button(Content = "命令库: 复制（Ctrl+C 也可）", Command = ApplicationCommands.Copy,
                        Width = 200., Height = 32., Margin = Thickness(0., 16., 0., 0.))

    let panel = StackPanel(Margin = Thickness 20.)
    for c in [ TextBlock(Text = "命令系统示例", FontSize = 22., FontWeight = FontWeights.Bold,
                         Margin = Thickness(0., 0., 0., 12.)) :> UIElement
               nameBox; runBtn; status; libBtn ] do
        panel.Children.Add c |> ignore

    window.Content <- panel
    window.DataContext <- vm
    Application().Run window
