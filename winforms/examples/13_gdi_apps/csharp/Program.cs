// 13 GDI+ 应用：柱形图、图片验证码、坐标变换（书的 9.4 两例的现代版）
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace ChartWin;

// ═══ 13.1 柱形图控件 ═══
internal class BarChart : Control
{
    private static readonly string[] Labels = { "1月", "2月", "3月", "4月", "5月", "6月" };
    private int[] _values = { 42, 68, 55, 90, 73, 61 };

    public BarChart()
    {
        Dock = DockStyle.Fill;
        BackColor = Color.White;
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint |
                 ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
    }

    public void Randomize(Random rng)
    {
        for (int i = 0; i < _values.Length; i++)
            _values[i] = rng.Next(20, 100);
        Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        var plot = new Rectangle(40, 16, Width - 60, Height - 50);   // 留出轴和标签的边距
        int max = 100;                                                // 纵轴固定 0..100，好对比
        float barW = plot.Width / (float)_values.Length * 0.6f;       // 柱宽 = 槽位 60%

        // 轴
        using var axis = new Pen(Color.Gray, 1f);
        g.DrawLine(axis, plot.Left, plot.Top, plot.Left, plot.Bottom);
        g.DrawLine(axis, plot.Left, plot.Bottom, plot.Right, plot.Bottom);
        for (int tick = 0; tick <= 4; tick++)                          // 刻度 0/25/50/75/100
        {
            float y = plot.Bottom - plot.Height * tick / 4f;
            g.DrawString((tick * 25).ToString(), Font, Brushes.Gray, 2, y - Font.Height / 2f);
            g.DrawLine(axis, plot.Left - 4, y, plot.Left, y);
        }

        // 柱子 + 数值 + 月份
        float slot = plot.Width / (float)_values.Length;
        var brush = new LinearGradientBrush(plot, Color.CornflowerBlue, Color.RoyalBlue, LinearGradientMode.Vertical);
        for (int i = 0; i < _values.Length; i++)
        {
            float h = plot.Height * _values[i] / (float)max;
            var bar = new RectangleF(plot.Left + i * slot + (slot - barW) / 2, plot.Bottom - h, barW, h);
            g.FillRectangle(brush, bar);
            g.DrawString(_values[i].ToString(), Font, Brushes.Black, bar.X, bar.Y - Font.Height);
            g.DrawString(Labels[i], Font, Brushes.DimGray, plot.Left + i * slot + slot / 2 - 12, plot.Bottom + 4);
        }
        brush.Dispose();
    }
}

internal class MainForm : Form
{
    private readonly BarChart _chart = new();
    private readonly PictureBox _captcha = new();
    private readonly TextBox _answer = new();
    private readonly Random _rng = new(2026);
    private readonly Label _spin;
    private string _code = "";
    private int _angle;
    private readonly System.Windows.Forms.Timer _timer = new();

    public MainForm()
    {
        Text = "GDI+ 应用";
        ClientSize = new Size(720, 560);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // ═══ 13.1 柱形图区 ═══
        var chartBox = new GroupBox { Text = " 柱形图（每次随机数据）", Dock = DockStyle.Top, Height = 240 };
        var rand = new Button { Text = "换一组数据", Dock = DockStyle.Bottom };
        rand.Click += (s, e) => _chart.Randomize(_rng);
        chartBox.Controls.Add(_chart);
        chartBox.Controls.Add(rand);

        // ═══ 13.2 验证码区 ═══
        var capBox = new GroupBox { Text = " 图片验证码 ", Dock = DockStyle.Top, Height = 130 };
        _captcha.Size = new Size(160, 48);
        _captcha.Location = new Point(16, 40);
        _captcha.BorderStyle = BorderStyle.FixedSingle;
        _captcha.Click += (s, e) => NewCaptcha();

        var refresh = new Button { Text = "看不清？换一张", Location = new Point(190, 50), AutoSize = true };
        refresh.Click += (s, e) => NewCaptcha();

        _answer.SetBounds(330, 44, 140, 30);
        _answer.Font = new Font("Consolas", 14F);

        var check = new Button { Text = "验证", Location = new Point(490, 42), AutoSize = true };
        check.Click += (s, e) =>
        {
            bool ok = string.Equals(_answer.Text.Trim(), _code, StringComparison.OrdinalIgnoreCase);
            MessageBox.Show(this, ok ? "通过！" : $"不对，答案是「{_code}」", "验证结果");
            if (ok) NewCaptcha();
        };

        var capHint = new Label { Text = "点击图片也能换（区分大小写不敏感）", AutoSize = true, Location = new Point(16, 96) };
        capBox.Controls.AddRange(new Control[] { _captcha, refresh, _answer, check, capHint });

        // ═══ 13.3 旋转文字区（坐标变换）═══
        var spinBox = new GroupBox { Text = " 坐标变换：旋转的文字（TranslateTransform + RotateTransform）", Dock = DockStyle.Top, Height = 120 };
        _spin = new Label
        {
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleCenter,
            Font = new Font("微软雅黑", 16F, FontStyle.Bold),
            Text = "WinForms",
        };
        _timer.Interval = 50;
        _timer.Tick += (s, e) =>
        {
            _angle = (_angle + 5) % 360;
            // 用 Transform 把整个标签画成旋转位图：先平移到中心再旋转再画
            var bmp = new Bitmap(_spin.Width, _spin.Height);
            using (var g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.TranslateTransform(bmp.Width / 2f, bmp.Height / 2f);   // 原点搬到中心
                g.RotateTransform(_angle);                               // 旋转坐标系
                var size = g.MeasureString(_spin.Text, _spin.Font);
                g.DrawString(_spin.Text, _spin.Font, Brushes.RoyalBlue, -size.Width / 2, -size.Height / 2);
            }
            var old = _spin.BackgroundImage;
            _spin.BackgroundImage = bmp;
            old?.Dispose();
        };
        _timer.Start();
        spinBox.Controls.Add(_spin);

        Controls.Add(spinBox);
        Controls.Add(capBox);
        Controls.Add(chartBox);

        NewCaptcha();
    }

    // ═══ 13.2 生成验证码位图：随机字符 + 每字旋转 + 干扰线 ═══
    private void NewCaptcha()
    {
        const string pool = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";    // 去掉易混字符 I1O0
        char[] chars = new char[4];
        for (int i = 0; i < 4; i++)
            chars[i] = pool[_rng.Next(pool.Length)];
        _code = new string(chars);
        _answer.Clear();

        var bmp = new Bitmap(160, 48);
        using (var g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.AliceBlue);
            using var font = new Font("Consolas", 20F, FontStyle.Bold);
            for (int i = 0; i < 4; i++)
            {
                g.TranslateTransform(20 + i * 34, 24);               // 挪到每个字的格心
                g.RotateTransform(_rng.Next(-25, 26));               // 每字随机歪
                var size = g.MeasureString(_code[i].ToString(), font);
                g.DrawString(_code[i].ToString(), font,
                    new SolidBrush(Color.FromArgb(_rng.Next(80, 180), _rng.Next(80, 180), _rng.Next(80, 180))),
                    -size.Width / 2, -size.Height / 2);
                g.ResetTransform();                                  // 画完一个记得复位
            }
            for (int i = 0; i < 6; i++)                              // 干扰线
                using (var p = new Pen(Color.FromArgb(_rng.Next(120, 220), 0, 0), 1.5f))
                    g.DrawLine(p, _rng.Next(160), _rng.Next(48), _rng.Next(160), _rng.Next(48));
        }
        var old = _captcha.Image;
        _captcha.Image = bmp;
        old?.Dispose();
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
