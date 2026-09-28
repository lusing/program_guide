// 21 异步与线程模型（F# 版）：与 csharp/ 版功能一致。
// F# 的 async/await 对应物是 task { } 计算表达式——与 C# 的 async/await 同一同步上下文语义，
// await 之后自动回到 UI 线程，INPC 更新不用 Dispatcher。
module AsyncProgressDemoFs.Program

open System
open System.ComponentModel
open System.Threading.Tasks
open System.Windows
open System.Windows.Controls
open System.Windows.Data
open System.Windows.Input

type RelayCommand(execute: obj -> unit) =
    let canChanged = Event<EventHandler, EventArgs>()
    interface ICommand with
        [<CLIEvent>]
        member _.CanExecuteChanged = canChanged.Publish
        member _.CanExecute _ = true
        member _.Execute p = execute p

type MainViewModel() as this =
    let pc = Event<PropertyChangedEventHandler, PropertyChangedEventArgs>()
    let mutable progress = 0
    let mutable statusText = "等待开始"

    member _.Progress
        with get () = progress
        and set v =
            if progress <> v then
                progress <- v
                pc.Trigger(this, PropertyChangedEventArgs "Progress")
    member _.StatusText
        with get () = statusText
        and set v =
            if statusText <> v then
                statusText <- v
                pc.Trigger(this, PropertyChangedEventArgs "StatusText")

    member _.StartCommand : ICommand =
        RelayCommand(fun _ -> this.RunAsync() |> ignore)   // 即发即忘（C# 的 _ = RunAsync()）

    member private _.RunAsync() : Task =
        task {
            for i in 0..10..100 do
                this.Progress <- i
                this.StatusText <- sprintf "处理中 %d%%" i
                do! Task.Delay 200
            this.StatusText <- "完成"
        } :> Task

    interface INotifyPropertyChanged with
        [<CLIEvent>]
        member _.PropertyChanged = pc.Publish

[<EntryPoint; STAThread>]
let main _ =
    let vm = MainViewModel()

    let bar = ProgressBar(Height = 20., Minimum = 0., Maximum = 100., Margin = Thickness(0., 0., 0., 12.))
    bar.SetBinding(ProgressBar.ValueProperty, Binding "Progress") |> ignore
    let status = TextBlock(FontSize = 16., Margin = Thickness(0., 0., 0., 12.))
    status.SetBinding(TextBlock.TextProperty, Binding "StatusText") |> ignore
    let start = Button(Content = "启动任务", Width = 140., Height = 36.)
    start.SetBinding(Button.CommandProperty, Binding "StartCommand") |> ignore

    let panel = StackPanel(Margin = Thickness 20.)
    panel.Children.Add(TextBlock(Text = "异步任务与进度", FontSize = 22., FontWeight = FontWeights.Bold,
                                 Margin = Thickness(0., 0., 0., 12.))) |> ignore
    for c in [ bar :> UIElement; status; start ] do panel.Children.Add c |> ignore

    let window = Window(Title = "Async Progress Demo (F#)", Height = 220., Width = 420., Content = panel)
    window.DataContext <- vm
    Application().Run window
