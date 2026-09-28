// 02 第一个 WinForms 程序（F# 版）：与 csharp/ 目录的 C# 版功能完全一致
module HelloFs.Program

open System
open System.Drawing
open System.Windows.Forms

[<EntryPoint>]
[<STAThread>]
let main _ =
    // F# 平铺风格的关键顺序：这两个 Application 调用必须在创建任何窗体/控件之前，
    // 否则 SetCompatibleTextRenderingDefault 抛 InvalidOperationException（实测坑）
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    // ── 2.1 窗体：F# 里通常不定义 Form 子类，直接 new + 属性初始化器 ──
    let form = new Form(Text = "你好，WinForms（F#）", Width = 420, Height = 170)
    form.StartPosition <- FormStartPosition.CenterScreen
    form.Font <- new Font("微软雅黑", 10F)

    // ── 2.2 控件三步：创建设属性 → 挂事件 → Controls.Add ──
    let label = new Label(Text = "等你点击下面的按钮",
                          Dock = DockStyle.Top, Height = 60,
                          TextAlign = ContentAlignment.MiddleCenter)
    let button = new Button(Text = "点我一下", Dock = DockStyle.Bottom, Height = 45)

    // 事件接线：F# 用 .Add（IObservable 侧还有 Observable.subscribe，见 11 章）
    let mutable count = 0
    button.Click.Add(fun _ ->
        count <- count + 1
        label.Text <- $"第 {count} 次点击——F# 版与 C# 版行为一致")

    form.Controls.Add label
    form.Controls.Add button

    Application.Run form
    0
