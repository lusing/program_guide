// 12 GDI+ 基础（F# 版）：自绘控件用类 + override OnPaint
module GdiBasicsFs.Program

open System
open System.Drawing
open System.Drawing.Drawing2D
open System.Windows.Forms

// ═══ 12.1 画布 ═══
type Canvas() as this =
    inherit Panel()

    let mutable stroke = ResizeArray<Point>()      // F# 可变集合当 List<Point>
    let mutable smooth = true

    do
        this.Dock <- DockStyle.Fill
        this.BackColor <- Color.White
        let combined = ControlStyles.AllPaintingInWmPaint ||| ControlStyles.UserPaint |||
                       ControlStyles.OptimizedDoubleBuffer ||| ControlStyles.ResizeRedraw
        this.SetStyle(combined, true)

    member _.ClearStroke() =
        stroke.Clear()
        this.Invalidate()

    member _.ToggleSmooth() =
        smooth <- not smooth
        this.Invalidate()
        smooth

    override this.OnPaint(e: PaintEventArgs) =
        base.OnPaint e
        let g = e.Graphics
        if smooth then g.SmoothingMode <- SmoothingMode.AntiAlias

        // —— Pen 家族 ——
        use pen = new Pen(Color.SteelBlue, 3f)
        g.DrawLine(pen, 20, 20, 180, 60)

        use dash = new Pen(Color.OrangeRed, 2f, DashStyle = DashStyle.Dash)
        g.DrawRectangle(dash, 20, 80, 160, 70)

        use thick = new Pen(Color.FromArgb(120, 30, 144), 6f,
                            StartCap = LineCap.Round, EndCap = LineCap.ArrowAnchor)
        g.DrawLine(thick, 220, 100, 380, 100)

        // —— Brush 家族 ——
        use solid = new SolidBrush(Color.FromArgb(140, Color.MediumSeaGreen))
        g.FillEllipse(solid, 220, 20, 140, 70)

        use hatch = new HatchBrush(HatchStyle.DiagonalCross, Color.Gray, Color.WhiteSmoke)
        g.FillRectangle(hatch, 20, 170, 160, 70)

        let rect = new Rectangle(220, 140, 160, 80)
        use grad = new LinearGradientBrush(rect, Color.RoyalBlue, Color.White, LinearGradientMode.Vertical)
        g.FillEllipse(grad, rect)
        g.DrawEllipse(pen, rect)

        // —— 曲线与多边形（F# 无隐式数值转换：float 重载要写 420.0f）——
        g.DrawBezier(pen, 420.0f, 180.0f, 470.0f, 20.0f, 500.0f, 220.0f, 560.0f, 120.0f)
        g.DrawPolygon(pen, [| Point(420, 30); Point(500, 55); Point(470, 110); Point(430, 95) |])

        // —— 文本（Brushes.* 共享缓存，不能 use）——
        g.DrawString("这段字是 DrawString 画的", this.Font, Brushes.DimGray, 20.0f, 250.0f)

        // ═══ 鼠标笔迹：全量重画 ═══
        if stroke.Count > 1 then
            use ink = new Pen(Color.Black, 2f)
            g.DrawLines(ink, stroke.ToArray())

    override this.OnMouseDown(e: MouseEventArgs) =
        base.OnMouseDown e
        stroke <- ResizeArray<Point>()
        stroke.Add e.Location
        this.Invalidate()

    override this.OnMouseMove(e: MouseEventArgs) =
        base.OnMouseMove e
        if e.Button = MouseButtons.Left && stroke.Count > 0 then
            stroke.Add e.Location
            this.Invalidate()

[<EntryPoint>]
[<STAThread>]
let main _ =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault false

    let form = new Form(Text = "GDI+ 绘图基础（F#）", ClientSize = Size(760, 480),
                        StartPosition = FormStartPosition.CenterScreen)
    form.Font <- new Font("微软雅黑", 10F)

    let canvas = new Canvas()

    let bar = new FlowLayoutPanel(Dock = DockStyle.Top, Height = 44)
    let clear = new Button(Text = "清空笔迹", AutoSize = true)
    clear.Click.Add(fun _ -> canvas.ClearStroke ())
    let mutable smoothText = "抗锯齿：开"
    let smooth = new Button(Text = smoothText, AutoSize = true)
    smooth.Click.Add(fun _ ->
        let on' = canvas.ToggleSmooth ()
        smoothText <- if on' then "抗锯齿：开" else "抗锯齿：关"
        smooth.Text <- smoothText)
    let hint = new Label(Text = "｜在空白处按住左键拖动 = 手写笔迹（拖大窗口试试）",
                         AutoSize = true, Padding = Padding(6, 10, 0, 0))
    let barControls: Control[] = [| clear; smooth; hint |]
    bar.Controls.AddRange barControls

    form.Controls.Add canvas
    form.Controls.Add bar

    Application.Run form
    0
