// 16 UI 线程模型：卡死、Task.Run、IProgress、Invoke、三种 Timer、async/await
using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;

namespace ThreadingWin;

internal class MainForm : Form
{
    private readonly ProgressBar _bar = new();
    private readonly Label _state = new();
    private readonly Label _formsTimer = new();
    private readonly Label _threadTimer = new();
    private readonly Label _elapsed = new();
    private Button _start;
    private CancellationTokenSource _cts;
    private readonly System.Windows.Forms.Timer _uiTimer = new();
    private System.Threading.Timer _poolTimer;
    private int _poolTicks;
    private int _uiTicks;
    private readonly Stopwatch _watch = Stopwatch.StartNew();

    public MainForm()
    {
        Text = "UI 线程与后台任务";
        ClientSize = new Size(680, 440);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // ═══ 16.1 卡死演示：UI 线程忙 = 整个窗口无响应 ═══
        var freeze = new GroupBox { Text = " 反面教材：在 UI 线程上睡 2 秒 ", Dock = DockStyle.Top, Height = 76 };
        var sleep = new Button { Text = "睡 2 秒（点我然后拖动窗口）", Dock = DockStyle.Fill };
        sleep.Click += (s, e) =>
        {
            _state.Text = "  UI 线程睡 2 秒——这期间不处理任何消息（拖不动、点不响）";
            Thread.Sleep(2000);
            _state.Text = "  醒了。正经做法见下";
        };
        freeze.Controls.Add(sleep);

        // ═══ 16.2/16.3 后台计算 + 进度 + 取消 ═══
        var work = new GroupBox { Text = " 后台数素数（0..2,000,000）", Dock = DockStyle.Top, Height = 130 };
        _bar.Dock = DockStyle.Top;
        _bar.Height = 26;
        _state.Dock = DockStyle.Top;
        _state.Height = 30;
        var row = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 46 };
        _start = new Button { Text = "开始（Task.Run + IProgress）", AutoSize = true };
        var stop = new Button { Text = "取消", AutoSize = true };
        stop.Enabled = false;
        _start.Click += async (s, e) => await RunAsync(stop);
        stop.Click += (s, e) => _cts?.Cancel();
        row.Controls.AddRange(new Control[] { _start, stop });

        var result = new Label { Text = "答案应是 148933（2×10⁶ 内素数个数，已知值当断言）", AutoSize = true, Dock = DockStyle.Top, ForeColor = Color.DimGray };
        work.Controls.Add(row);
        work.Controls.Add(result);
        work.Controls.Add(_state);
        work.Controls.Add(_bar);

        // ═══ 16.4/16.5 三种 Timer 对照 ═══
        var timers = new GroupBox { Text = " 三种 Timer：Forms（UI 线程）/ Threading（线程池）", Dock = DockStyle.Fill };
        _formsTimer.Dock = DockStyle.Top;
        _formsTimer.Height = 34;
        _formsTimer.Text = "Forms.Timer：0（Tick 直接改 UI，天然安全）";
        _threadTimer.Dock = DockStyle.Top;
        _threadTimer.Height = 34;
        _threadTimer.Text = "Threading.Timer：0（回调在线程池，改 UI 必须 Invoke）";
        _elapsed.Dock = DockStyle.Top;
        _elapsed.Height = 34;

        _uiTimer.Interval = 500;
        _uiTimer.Tick += (s, e) => _formsTimer.Text = $"Forms.Timer：{++_uiTicks}（Tick 直接改 UI，天然安全）";
        _uiTimer.Start();

        _poolTimer = new System.Threading.Timer(_ =>
        {
            _poolTicks++;
            // 句柄还没建好（定时器可能抢在窗体显示前开火）→ 跳过这一拍
            if (!_threadTimer.IsHandleCreated) return;
            // 下面两行若直接写 _threadTimer.Text = ... → 跨线程操作异常
            // Invoke：同步等 UI 线程执行完；BeginInvoke：丢下就走（别拿返回值）
            _threadTimer.BeginInvoke(() =>
            {
                _threadTimer.Text = $"Threading.Timer：{_poolTicks}（回调在线程池，改 UI 必须 Invoke）";
                _elapsed.Text = $"  已运行 {_watch.Elapsed.TotalSeconds:F0} 秒";
            });
        }, null, 0, 500);

        timers.Controls.Add(_elapsed);
        timers.Controls.Add(_threadTimer);
        timers.Controls.Add(_formsTimer);

        Controls.Add(timers);
        Controls.Add(work);
        Controls.Add(freeze);
    }

    // ═══ 16.6 async/await 事件处理器： UI 不卡、进度回 UI、可取消 ═══
    private async Task RunAsync(Button stop)
    {
        _start.Enabled = false;
        stop.Enabled = true;
        _cts = new CancellationTokenSource();
        var progress = new Progress<int>(p =>                 // Progress<T> 自动回到 UI 线程
        {
            _bar.Value = Math.Min(p, 100);
            _state.Text = $"  进度 {p}%";
        });
        try
        {
            int count = await Task.Run(() => CountPrimes(2_000_000, progress, _cts.Token));
            _state.Text = $"  完成：{count:N0} 个素数{(count == 148933 ? "（与已知值一致 ✔）" : "（不对！）")}";
        }
        catch (OperationCanceledException)
        {
            _state.Text = "  已取消";
        }
        finally
        {
            _start.Enabled = true;
            stop.Enabled = false;
            _cts.Dispose();
            _cts = null;
        }
    }

    private static int CountPrimes(int max, IProgress<int> progress, CancellationToken ct)
    {
        int count = 0;
        for (int n = 2; n <= max; n++)
        {
            ct.ThrowIfCancellationRequested();               // 每 512 个数查一次取消更省；这里简单起见每轮查
            bool prime = true;
            for (int d = 2; d * d <= n; d++)
                if (n % d == 0) { prime = false; break; }
            if (prime) count++;
            if (n % (max / 100) == 0)
                progress.Report(n * 100 / max);               // 后台线程调用 → Progress 转投 UI 线程
        }
        return count;
    }

    protected override void OnFormClosed(FormClosedEventArgs e)
    {
        _cts?.Cancel();
        _poolTimer?.Dispose();
        _uiTimer?.Stop();
        base.OnFormClosed(e);
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
