// 11 事件与委托：EventHandler 模式、自定义事件、多播、解绑
using System.Drawing;
using System.Windows.Forms;

namespace EventsWin;

// ═══ 11.1 事件参数类：EventArgs 派生 + 有意义的数据 ═══
public class TempEventArgs : EventArgs
{
    public double Temp { get; }
    public double Delta { get; }
    public TempEventArgs(double temp, double delta) { Temp = temp; Delta = delta; }
}

// ═══ 11.2 事件源：一个模拟温度计 ═══
public class Thermometer
{
    private readonly Random _rng = new(42);
    private double _temp = 20.0;

    // event 关键字 = 限制外部只能 += / -=，不能直接调用或清空
    public event EventHandler<TempEventArgs> Reading;

    public void Poll()
    {
        double next = _temp + (_rng.NextDouble() - 0.5) * 2.0;   // 随机漂移 ±1°C
        double delta = next - _temp;
        _temp = next;
        Reading?.Invoke(this, new TempEventArgs(next, delta));   // this 当 sender：订阅方能区分事件来自谁
    }
}

internal class MainForm : Form
{
    private readonly Thermometer _thermo = new();
    private readonly Label _display = new();
    private readonly ListBox _log = new();
    private readonly Button _toggle;
    private int _eventsReceived;

    public MainForm()
    {
        Text = "事件与委托";
        ClientSize = new Size(560, 420);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        _display.Dock = DockStyle.Top;
        _display.Height = 60;
        _display.TextAlign = ContentAlignment.MiddleCenter;
        _display.Font = new Font("微软雅黑", 20F);
        _display.Text = "20.0 °C";

        _toggle = new Button { Text = "暂停记录（解绑订阅者 B）", Dock = DockStyle.Top, Height = 36 };
        _toggle.Click += (s, e) => ToggleSubscriber();

        _log.Dock = DockStyle.Fill;

        // ═══ 11.3 订阅：两个订阅者 = 多播委托链 ═══
        _thermo.Reading += OnReadingA;      // 订阅者 A：更新大数字
        _thermo.Reading += OnReadingB;      // 订阅者 B：写日志
        _bSubscribed = true;

        // ═══ 11.4 驱动：窗体定时器每 500ms 拉一次读数 ═══
        var timer = new System.Windows.Forms.Timer { Interval = 500 };
        timer.Tick += (s, e) => _thermo.Poll();
        timer.Start();

        Controls.Add(_log);
        Controls.Add(_toggle);
        Controls.Add(_display);
    }

    // 订阅者 A：方法组直接转委托（最省事的接线方式）
    private void OnReadingA(object? sender, TempEventArgs e) =>
        _display.Text = $"{e.Temp:F1} °C";

    // 订阅者 B：也记录日志
    private void OnReadingB(object? sender, TempEventArgs e)
    {
        _eventsReceived++;
        _log.Items.Insert(0, $"#{_eventsReceived:D3}  {e.Temp:F2}°C（变化 {e.Delta:+0.00;-0.00}）" +
                             $"{(ReferenceEquals(sender, _thermo) ? "  sender 验证通过" : "")}");
    }

    private bool _bSubscribed;

    // ═══ 11.5 解绑与重绑：-= 必须给"同一个方法"（方法组等价）═══
    private void ToggleSubscriber()
    {
        if (_bSubscribed)
        {
            _thermo.Reading -= OnReadingB;      // 方法组再次转换，仍等于第一次的委托（编译器合成相等）
            _toggle.Text = "恢复记录（重绑订阅者 B）";
        }
        else
        {
            _thermo.Reading += OnReadingB;
            _toggle.Text = "暂停记录（解绑订阅者 B）";
        }
        _bSubscribed = !_bSubscribed;
        _log.Items.Insert(0, _bSubscribed ? "── 订阅者 B 已接回 ──" : "── 订阅者 B 已解绑：只剩大数字在动 ──");
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
