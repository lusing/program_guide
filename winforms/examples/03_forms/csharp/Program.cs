// 03 窗体属性、生命周期与两种子窗体（模态/非模态）
using System.Drawing;
using System.Windows.Forms;

namespace FormsWin;

// ═══ 3.1 主窗体：生命周期事件全记录 ═══
internal class MainForm : Form
{
    private readonly ListBox _log = new();
    private int _modalCount = 0;

    public MainForm()
    {
        Text = "窗体与生命周期";
        ClientSize = new Size(560, 380);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // 顶部按钮条
        var openModal = new Button { Text = "模态：输入姓名(S)", Dock = DockStyle.Top, Height = 36 };
        var openModeless = new Button { Text = "非模态：浮动窗口", Dock = DockStyle.Top, Height = 36 };
        openModeless.Dock = DockStyle.Top;
        openModal.Click += (s, e) =>
        {
            using var dlg = new NameDialog();
            // ShowDialog：模态——不关掉它，主窗体的代码停在这一行，也点不回主窗体
            if (dlg.ShowDialog(this) == DialogResult.OK)   // this 作为 owner
                Log($"模态返回 OK，姓名 = {dlg.UserName}（第 {++_modalCount} 次）");
            else
                Log($"模态返回 {dlg.DialogResult}（用户取消）");
        };
        openModeless.Click += (s, e) =>
        {
            var win = new FloatingWindow { Owner = this };   // Owner：始终浮在本窗体之上、随主窗体最小化
            win.TitleChanged += msg => Log($"浮动窗口来消息：{msg}");
            win.Show(this);                                    // Show：非模态——立刻返回，两边都能操作
            Log("非模态窗口已打开（Show 立即返回）");
        };

        // 日志列表贴满余下空间
        _log.Dock = DockStyle.Fill;
        _log.Items.Add("构造函数执行完毕（此时窗体还不可见）");

        Controls.Add(_log);
        Controls.Add(openModeless);   // Dock 布局后加的先占位：加控件顺序 = Fill 最后加（见 04 章）
        Controls.Add(openModal);

        // ═══ 3.2 生命周期事件：触发的先后顺序看日志 ═══
        Load += (s, e) => Log("Load：窗体首次显示前（做初始化的好地方）");
        Shown += (s, e) => Log("Shown：窗体已经显示出来（Load 之后必有一次）");
        Activated += (s, e) => Log("Activated：成为活动窗口（切回来也会再触发）");
        Deactivate += (s, e) => Log("Deactivate：失去焦点（点了别的窗口）");

        // ═══ 3.3 关闭确认：FormClosing 里还能"反悔" ═══
        FormClosing += (s, e) =>
        {
            var r = MessageBox.Show($"日志里有 {_log.Items.Count} 条记录，确定退出？",
                                    "关闭确认", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
            if (r == DialogResult.No)
                e.Cancel = true;              // 撤销关闭——FormClosed 就不会再触发
        };
        FormClosed += (s, e) => { /* 这里通常做清理；写到日志看不见了，留空 */ };
    }

    private void Log(string msg) => _log.Items.Insert(0, $"{DateTime.Now:HH:mm:ss}  {msg}");
}

// ═══ 3.4 模态子窗体：对话框的"标准件"写法 ═══
internal class NameDialog : Form
{
    private readonly TextBox _name;

    public string UserName => _name.Text;

    public NameDialog()
    {
        Text = "输入姓名";
        FormBorderStyle = FormBorderStyle.FixedDialog;   // 对话框不该被拖大小
        MaximizeBox = false; MinimizeBox = false;
        ClientSize = new Size(320, 120);
        StartPosition = FormStartPosition.CenterParent;  // 落在父窗体中央
        Font = new Font("微软雅黑", 10F);

        var label = new Label { Text = "姓名：", Dock = DockStyle.Top, Height = 32, TextAlign = ContentAlignment.MiddleLeft };
        _name = new TextBox { Dock = DockStyle.Top, Text = "" };

        var ok = new Button { Text = "确定", DialogResult = DialogResult.OK, Dock = DockStyle.Left, Width = 96 };
        var cancel = new Button { Text = "取消", DialogResult = DialogResult.Cancel, Dock = DockStyle.Right, Width = 96 };
        // DialogResult 属性是捷径：点击即关窗并把结果带回给 ShowDialog 的返回值
        AcceptButton = ok;          // 回车 = 确定
        CancelButton = cancel;      // Esc = 取消（顺便处理了 FormClosing 反悔问题）

        Controls.Add(ok);
        Controls.Add(cancel);
        Controls.Add(_name);
        Controls.Add(label);
    }
}

// ═══ 3.5 非模态子窗体：用事件向主窗体"汇报" ═══
internal class FloatingWindow : Form
{
    private int _ticks = 0;

    // 自定义事件：子窗体不认识主窗体，靠事件把消息递出去（11 章细讲）
    public event Action<string> TitleChanged;

    public FloatingWindow()
    {
        Text = "浮动窗口";
        ClientSize = new Size(300, 150);
        StartPosition = FormStartPosition.Manual;

        var shout = new Button { Text = "向主窗体发消息", Dock = DockStyle.Fill };
        shout.Click += (s, e) => TitleChanged?.Invoke($"第 {++_ticks} 次汇报");
        Controls.Add(shout);
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
