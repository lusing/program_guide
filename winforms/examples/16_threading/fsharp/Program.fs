// 16 UI 线程模型（F# 版）：Async + Task.Run + Progress + Invoke
module ThreadingFs.Program

open System
open System.Diagnostics
open System.Drawing
open System.Threading
open System.Threading.Tasks
open System.Windows.Forms

// 数素数：后台线程跑，进度经 IProgress 汇报、取消经 CancellationToken
let countPrimes (max: int) (progress: IProgress<int>) (ct: CancellationToken) =
    let mutable count = 0
    for n = 2 to max do
        ct.ThrowIfCancellationRequested()
        let mutable prime = true
        let mutable d = 2
        while prime && d * d <= n do
            if n % d = 0 then prime <- false
            d <- d + 1
        if prime then count <- count + 1
        if n % (max / 100) = 0 then progress.Report(n * 100 / max)
    count

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "UI 线程与后台任务（F#）", ClientSize = Size(680, 440),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    // ═══ 16.1 卡死演示 ═══
    let freeze = new GroupBox(Text = " 反面教材：在 UI 线程上睡 2 秒 ", Dock = DockStyle.Top, Height = 76)
    let state = new Label(Dock = DockStyle.Top, Height = 30)
    let sleep = new Button(Text = "睡 2 秒（点我然后拖动窗口）", Dock = DockStyle.Fill)
    sleep.Click.Add(fun _ ->
        state.Text <- "  UI 线程睡 2 秒——这期间不处理任何消息（拖不动、点不响）"
        Thread.Sleep 2000
        state.Text <- "  醒了。正经做法见下")
    freeze.Controls.Add sleep

    // ═══ 16.2/16.3 后台计算 ═══
    let work = new GroupBox(Text = " 后台数素数（0..2,000,000）", Dock = DockStyle.Top, Height = 130)
    let bar = new ProgressBar(Dock = DockStyle.Top, Height = 26)
    let row = new FlowLayoutPanel(Dock = DockStyle.Top, Height = 46)
    let start = new Button(Text = "开始（Async + Task.Run + Progress）", AutoSize = true)
    let stop = new Button(Text = "取消", AutoSize = true, Enabled = false)
    let mutable cts: CancellationTokenSource option = None

    start.Click.Add(fun _ ->
        // Async.StartImmediate：async 块在 UI 线程启动，await 后续自动回来
        Async.StartImmediate(async {
            start.Enabled <- false
            stop.Enabled <- true
            let c = new CancellationTokenSource()
            cts <- Some c
            let progress = Progress<int>(fun p ->
                bar.Value <- min p 100
                state.Text <- $"  进度 {p}%%")
            // F# 的 try/with 与 try/finally 是两个结构，不能像 C# 那样三合一：套两层
            try
                try
                    let! count = Async.AwaitTask(Task.Run(fun () -> countPrimes 2000000 progress c.Token))
                    let verdict = if count = 148933 then "（与已知值一致 ✔）" else "（不对！）"
                    state.Text <- $"  完成：{count:N0} 个素数{verdict}"
                with :? OperationCanceledException ->
                    state.Text <- "  已取消"
            finally
                start.Enabled <- true
                stop.Enabled <- false
                c.Dispose()
                cts <- None }))
    stop.Click.Add(fun _ -> match cts with Some c -> c.Cancel() | None -> ())
    let rowControls: Control[] = [| start; stop |]
    row.Controls.AddRange rowControls

    let result = new Label(Text = "答案应是 148933（2×10⁶ 内素数个数，已知值当断言）",
                           AutoSize = true, Dock = DockStyle.Top, ForeColor = Color.DimGray)
    work.Controls.Add row
    work.Controls.Add result
    work.Controls.Add state
    work.Controls.Add bar

    // ═══ 16.4/16.5 两种 Timer ═══
    let timers = new GroupBox(Text = " 两种 Timer：Forms（UI 线程）/ Threading（线程池）", Dock = DockStyle.Fill)
    let mutable uiTicks = 0
    let formsTimer = new Label(Dock = DockStyle.Top, Height = 34,
                               Text = "Forms.Timer：0（Tick 直接改 UI，天然安全）")
    let threadTimer = new Label(Dock = DockStyle.Top, Height = 34,
                                Text = "Threading.Timer：0（回调在线程池，改 UI 必须 Invoke）")
    let elapsed = new Label(Dock = DockStyle.Top, Height = 34)
    let watch = Stopwatch.StartNew()

    let uiTimer = new Timer(Interval = 500)
    uiTimer.Tick.Add(fun _ ->
        uiTicks <- uiTicks + 1
        formsTimer.Text <- $"Forms.Timer：{uiTicks}（Tick 直接改 UI，天然安全）")
    uiTimer.Start()

    let mutable poolTicks = 0
    let poolTimer = new System.Threading.Timer((fun _ ->
        poolTicks <- poolTicks + 1
        // 句柄未建（定时器可能抢在窗体显示前开火）就跳过这一拍；
        // 直接改 threadTimer.Text 会抛跨线程异常，BeginInvoke 丢给 UI 线程执行
        if threadTimer.IsHandleCreated then
            threadTimer.BeginInvoke(fun () ->
                threadTimer.Text <- $"Threading.Timer：{poolTicks}（回调在线程池，改 UI 必须 Invoke）"
                let secs = watch.Elapsed.TotalSeconds
                let s = secs.ToString("F0")
                elapsed.Text <- $"  已运行 {s} 秒") |> ignore), null, 0, 500)

    timers.Controls.Add elapsed
    timers.Controls.Add threadTimer
    timers.Controls.Add formsTimer

    form.Controls.Add timers
    form.Controls.Add work
    form.Controls.Add freeze

    form.FormClosed.Add(fun _ ->
        (match cts with Some c -> c.Cancel() | None -> ())
        poolTimer.Dispose()
        uiTimer.Stop())

    Application.Run form
    0
