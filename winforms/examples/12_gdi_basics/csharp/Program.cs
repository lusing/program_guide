// 12 GDI+ 基础：Paint 事件、Graphics、Pen/Brush、失效-重绘模型、双缓冲
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace GdiBasicsWin;

// ═══ 12.1 画布 = Panel 子类：自绘控件的四件套 SetStyle ═══
internal class Canvas : Panel
{
    public List<Point> Stroke = new();        // 鼠标画的自由笔迹
    public bool Smooth = true;

    public Canvas()
    {
        Dock = DockStyle.Fill;
        BackColor = Color.White;
        // 自绘控件标准四开关：
        SetStyle(ControlStyles.AllPaintingInWmPaint |   // 擦背景不走 WM_ERASEBKGND（防闪烁一半）
                 ControlStyles.UserPaint |              // 自己画全部内容
                 ControlStyles.OptimizedDoubleBuffer |  // 先画到内存位图再一次性上屏（双缓冲）
                 ControlStyles.ResizeRedraw,            // 尺寸一变就整面重画
                 true);
    }

    // ═══ 12.2 一切绘制都发生在 OnPaint / Paint 事件里 ═══
    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        Graphics g = e.Graphics;                       // 这一块剪辑区之外不要画（脏矩形机制）
        if (Smooth)
        {
            g.SmoothingMode = SmoothingMode.AntiAlias; // 抗锯齿：圆弧斜线的锯齿消失
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;
        }

        // —— Pen 家族：颜色 / 宽度 / 虚线样式 ——
        using var pen = new Pen(Color.SteelBlue, 3f);
        g.DrawLine(pen, 20, 20, 180, 60);

        using var dash = new Pen(Color.OrangeRed, 2f)
        {
            DashStyle = DashStyle.Dash,                // 虚线；Dot/DashDot 也在此
        };
        g.DrawRectangle(dash, 20, 80, 160, 70);

        using var thick = new Pen(Color.FromArgb(120, 30, 144), 6f)
        {
            StartCap = LineCap.Round,                  // 线端圆头
            EndCap = LineCap.ArrowAnchor,              // 箭头：画流程图的老朋友
        };
        g.DrawLine(thick, 220, 100, 380, 100);

        // —— Brush 家族：Solid / Hatch（影线）/ LinearGradient ——
        using (var solid = new SolidBrush(Color.FromArgb(140, Color.MediumSeaGreen)))
            g.FillEllipse(solid, 220, 20, 140, 70);    // 半透明：140/255

        using (var hatch = new HatchBrush(HatchStyle.DiagonalCross, Color.Gray, Color.WhiteSmoke))
            g.FillRectangle(hatch, 20, 170, 160, 70);

        var rect = new Rectangle(220, 140, 160, 80);
        using (var grad = new LinearGradientBrush(rect, Color.RoyalBlue, Color.White, LinearGradientMode.Vertical))
        {
            g.FillEllipse(grad, rect);
            g.DrawEllipse(pen, rect);                  // 描边 + 填充是两次调用
        }

        // —— 曲线与多边形 ——
        g.DrawBezier(pen, 420, 180, 470, 20, 500, 220, 560, 120);   // 三次贝塞尔
        g.DrawPolygon(pen, new Point[] { new(420, 30), new(500, 55), new(470, 110), new(430, 95) });

        // —— 文本也是"画"出来的（Brushes.* 是共享缓存，别 using/Dispose 它）——
        g.DrawString("这段字是 DrawString 画的", Font, Brushes.DimGray, 20, 250);

        // ═══ 12.3 鼠标笔迹：OnPaint 每次全量重画 Stroke ═══
        if (Stroke.Count > 1)
        {
            using var ink = new Pen(Color.Black, 2f);
            g.DrawLines(ink, Stroke.ToArray());
        }
    }

    // ═══ 12.4 失效-重绘模型：鼠标事件只改数据 + Invalidate，绝不在事件里直接画 ═══
    protected override void OnMouseDown(MouseEventArgs e)
    {
        base.OnMouseDown(e);
        Stroke.Clear();
        Stroke.Add(e.Location);
        Invalidate();
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        if (e.Button == MouseButtons.Left && Stroke.Count > 0)
        {
            Stroke.Add(e.Location);
            Invalidate();       // 请求重画 → 系统稍后调 OnPaint（可能合并多次请求）
        }
    }
}

internal class MainForm : Form
{
    public MainForm()
    {
        Text = "GDI+ 绘图基础";
        ClientSize = new Size(760, 480);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        var canvas = new Canvas();

        var bar = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 44 };
        var clear = new Button { Text = "清空笔迹", AutoSize = true };
        clear.Click += (s, e) => { canvas.Stroke.Clear(); canvas.Invalidate(); };
        var smooth = new Button { Text = "抗锯齿：开", AutoSize = true };
        smooth.Click += (s, e) =>
        {
            canvas.Smooth = !canvas.Smooth;
            smooth.Text = $"抗锯齿：{(canvas.Smooth ? "开" : "关")}";
            canvas.Invalidate();
        };
        var hint = new Label
        {
            Text = "｜在空白处按住左键拖动 = 手写笔迹（整个窗口拖大试试：ResizeRedraw）",
            AutoSize = true,
            Padding = new Padding(6, 10, 0, 0),
        };
        bar.Controls.AddRange(new Control[] { clear, smooth, hint });

        Controls.Add(canvas);
        Controls.Add(bar);
    }
}

internal static class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
    }
}
