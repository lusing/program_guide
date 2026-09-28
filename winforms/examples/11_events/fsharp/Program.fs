// 11 事件与委托（F# 版）
// F# 的两种风格都要会：
//   ① .NET 风格：Event<T> + [<CLIEvent>]，C#/C++ 侧也能 += 订阅
//   ② Observable 风格：事件当 IObservable 流，用 filter/map/merge 组合（F# 的杀手锏）
module EventsFs.Program

open System
open System.Drawing
open System.Windows.Forms

// ═══ 11.1/11.2 事件源：F# 惯用 Event<_> ═══
type Thermometer(seed: int) as this =

    let reading = Event<Thermometer * float * float>()   // (来源, 温度, 变化量)
    let rng = Random seed
    let mutable temp = 20.0

    /// .NET 风格事件（编译成真正的 CLI 事件，可 +=）
    [<CLIEvent>]
    member _.Reading = reading.Publish

    member _.Poll() =
        let next = temp + (rng.NextDouble() - 0.5) * 2.0
        let delta = next - temp
        temp <- next
        reading.Trigger(this, next, delta)

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "事件与委托（F#）", ClientSize = Size(560, 420),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let thermo = Thermometer 42

    let display = new Label(Dock = DockStyle.Top, Height = 60,
                            TextAlign = ContentAlignment.MiddleCenter,
                            Font = new Font("微软雅黑", 20F), Text = "20.0 °C")
    let log = new ListBox(Dock = DockStyle.Fill)
    let hint = new Label(Dock = DockStyle.Top, Height = 34, Text = "告警流（>20.5°C 才记录）—— Observable.filter 的功劳",
                         ForeColor = Color.DimGray)

    // ═══ 11.3 .NET 风格订阅：与 C# 的 += 等价 ═══
    let mutable count = 0
    thermo.Reading.Add(fun (src, t, d) ->
        count <- count + 1
        display.Text <- $"{t:F1} °C"
        let arrow = if d >= 0.0 then $"+{d:F2}" else $"{d:F2}"
        log.Items.Insert(0, $"#{count:D3}  {t:F2}°C（变化 {arrow}）") |> ignore)

    // ═══ 11.4 Observable 风格：把 IEvent 当流来组合 ═══
    thermo.Reading                                // IEvent<...> 本身就是 IObservable
    |> Observable.filter (fun (_, t, _) -> t > 20.5)
    |> Observable.map (fun (_, t, d) ->
        // 格式串不能以 + / 数字开头（F# 插值规则），先算好箭头字符串
        let arrow = if d >= 0.0 then $"+{d:F2}" else $"{d:F2}"
        $"★ 高温 {t:F2}°C（{arrow}）")
    |> Observable.subscribe (fun msg -> form.Text <- msg)

    let timer = new Timer(Interval = 500)
    timer.Tick.Add(fun _ -> thermo.Poll ())
    timer.Start()

    form.Controls.Add log
    form.Controls.Add hint
    form.Controls.Add display

    Application.Run form
    0
