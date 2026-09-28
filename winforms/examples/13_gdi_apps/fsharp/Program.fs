// 13 GDI+ 应用（F# 版）
module ChartFs.Program

open System
open System.Drawing
open System.Drawing.Drawing2D
open System.Windows.Forms

// ═══ 13.1 柱形图 ═══
type BarChart() as this =
    inherit Control()

    let labels = [| "1月"; "2月"; "3月"; "4月"; "5月"; "6月" |]
    let mutable values = [| 42; 68; 55; 90; 73; 61 |]

    do
        this.Dock <- DockStyle.Fill
        this.BackColor <- Color.White
        let combined = ControlStyles.AllPaintingInWmPaint ||| ControlStyles.UserPaint |||
                       ControlStyles.OptimizedDoubleBuffer ||| ControlStyles.ResizeRedraw
        this.SetStyle(combined, true)

    member _.Randomize(rng: Random) =
        values <- Array.init 6 (fun _ -> rng.Next(20, 100))
        this.Invalidate()

    override this.OnPaint(e: PaintEventArgs) =
        base.OnPaint e
        let g = e.Graphics
        g.SmoothingMode <- SmoothingMode.AntiAlias

        let plot = Rectangle(40, 16, this.Width - 60, this.Height - 50)
        let max = 100.0f
        let slot = float32 plot.Width / float32 values.Length
        let barW = slot * 0.6f

        use axis = new Pen(Color.Gray, 1.0f)
        g.DrawLine(axis, plot.Left, plot.Top, plot.Left, plot.Bottom)
        g.DrawLine(axis, plot.Left, plot.Bottom, plot.Right, plot.Bottom)
        for tick in 0..4 do
            let y = float32 plot.Bottom - float32 plot.Height * float32 tick / 4.0f
            g.DrawString(string (tick * 25), this.Font, Brushes.Gray, 2.0f, y - float32 this.Font.Height / 2.0f)
            g.DrawLine(axis, float32 plot.Left - 4.0f, y, float32 plot.Left, y)

        use brush = new LinearGradientBrush(rect = plot, color1 = Color.CornflowerBlue,
                                            color2 = Color.RoyalBlue,
                                            linearGradientMode = LinearGradientMode.Vertical)
        for i = 0 to values.Length - 1 do
            let h = float32 plot.Height * float32 values.[i] / max
            let bar = RectangleF(float32 plot.Left + float32 i * slot + (slot - barW) / 2.0f,
                                 float32 plot.Bottom - h, barW, h)
            g.FillRectangle(brush, bar)
            g.DrawString(string values.[i], this.Font, Brushes.Black, bar.X, bar.Y - float32 this.Font.Height)
            g.DrawString(labels.[i], this.Font, Brushes.DimGray,
                         float32 plot.Left + float32 i * slot + slot / 2.0f - 12.0f, float32 plot.Bottom + 4.0f)

// ═══ 13.2 验证码位图 ═══
let makeCaptcha (rng: Random) =
    let pool = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"      // 去掉易混字符 I1O0
    let code = String.init 4 (fun _ -> string pool.[rng.Next pool.Length])
    let bmp = new Bitmap(160, 48)
    use g = Graphics.FromImage bmp
    g.Clear Color.AliceBlue
    use font = new Font("Consolas", 20.0f, FontStyle.Bold)
    for i = 0 to 3 do
        g.TranslateTransform(20.0f + float32 i * 34.0f, 24.0f)
        g.RotateTransform(float32 (rng.Next(-25, 26)))
        let size = g.MeasureString(string code.[i], font)
        let ink = new SolidBrush(Color.FromArgb(rng.Next(80, 180), rng.Next(80, 180), rng.Next(80, 180)))
        g.DrawString(string code.[i], font, ink, -size.Width / 2.0f, -size.Height / 2.0f)
        ink.Dispose()
        g.ResetTransform()
    for _ = 1 to 6 do
        use p = new Pen(Color.FromArgb(rng.Next(120, 220), 0, 0), 1.5f)
        g.DrawLine(p, rng.Next 160, rng.Next 48, rng.Next 160, rng.Next 48)
    code, bmp

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "GDI+ 应用（F#）", ClientSize = Size(720, 560),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)
    let rng = Random 2026

    // 柱形图区
    let chart = new BarChart()
    let chartBox = new GroupBox(Text = " 柱形图（每次随机数据）", Dock = DockStyle.Top, Height = 240)
    let rand = new Button(Text = "换一组数据", Dock = DockStyle.Bottom)
    rand.Click.Add(fun _ -> chart.Randomize rng)
    chartBox.Controls.Add chart
    chartBox.Controls.Add rand

    // 验证码区
    let mutable code = ""
    let captcha = new PictureBox(Size = Size(160, 48), Location = Point(16, 40),
                                 BorderStyle = BorderStyle.FixedSingle)
    let newCaptcha () =
        let c, bmp = makeCaptcha rng
        code <- c
        match captcha.Image with
        | null -> ()
        | old -> old.Dispose()          // F# 没有 ?. 运算符，模式匹配判空
        captcha.Image <- bmp
    captcha.Click.Add(fun _ -> newCaptcha ())

    let capBox = new GroupBox(Text = " 图片验证码 ", Dock = DockStyle.Top, Height = 130)
    let refresh = new Button(Text = "看不清？换一张", Location = Point(190, 50), AutoSize = true)
    refresh.Click.Add(fun _ -> newCaptcha ())
    let answer = new TextBox(Font = new Font("Consolas", 14.0f))
    answer.SetBounds(330, 44, 140, 30)
    let check = new Button(Text = "验证", Location = Point(490, 42), AutoSize = true)
    check.Click.Add(fun _ ->
        let ok = String.Equals(answer.Text.Trim(), code, StringComparison.OrdinalIgnoreCase)
        let msg = if ok then "通过！" else $"不对，答案是「{code}」"
        MessageBox.Show(form, msg, "验证结果") |> ignore
        if ok then newCaptcha ())
    let capHint = new Label(Text = "点击图片也能换（不区分大小写）", AutoSize = true, Location = Point(16, 96))
    let capControls: Control[] = [| captcha; refresh; answer; check; capHint |]
    capBox.Controls.AddRange capControls

    // ═══ 13.3 旋转文字 ═══
    let spinBox = new GroupBox(Text = " 坐标变换：旋转的文字 ", Dock = DockStyle.Top, Height = 120)
    let spin = new Label(Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleCenter,
                         Font = new Font("微软雅黑", 16.0f, FontStyle.Bold), Text = "WinForms")
    let mutable angle = 0
    let timer = new Timer(Interval = 50)
    timer.Tick.Add(fun _ ->
        angle <- (angle + 5) % 360
        let bmp = new Bitmap(spin.Width, spin.Height)
        use g = Graphics.FromImage bmp
        g.SmoothingMode <- SmoothingMode.AntiAlias
        g.TranslateTransform(float32 bmp.Width / 2.0f, float32 bmp.Height / 2.0f)
        g.RotateTransform(float32 angle)
        let size = g.MeasureString(spin.Text, spin.Font)
        g.DrawString(spin.Text, spin.Font, Brushes.RoyalBlue, -size.Width / 2.0f, -size.Height / 2.0f)
        match spin.BackgroundImage with
        | null -> ()
        | old -> old.Dispose()
        spin.BackgroundImage <- bmp)
    timer.Start()
    spinBox.Controls.Add spin

    form.Controls.Add spinBox
    form.Controls.Add capBox
    form.Controls.Add chartBox

    newCaptcha ()

    Application.Run form
    0
