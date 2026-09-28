// 05 文本类控件：TextBox（单行/密码/多行）、NumericUpDown、RichTextBox、LinkLabel
using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;

namespace TextWin;

internal class MainForm : Form
{
    private readonly RichTextBox _rich = new();
    private readonly TextBox _user = new();
    private readonly TextBox _pwd = new();
    private readonly NumericUpDown _age = new();

    public MainForm()
    {
        Text = "文本类控件";
        ClientSize = new Size(640, 480);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // ═══ 5.1 上半区：单行输入三件套（GroupBox 当逻辑分组）═══
        var login = new GroupBox { Text = " 单行输入 ", Dock = DockStyle.Top, Height = 130 };

        var userLabel = new Label { Text = "用户名：", AutoSize = true, Location = new Point(16, 32) };
        _user.Location = new Point(100, 28);
        _user.Width = 180;
        _user.MaxLength = 12;                       // 限长
        _user.CharacterCasing = CharacterCasing.Normal;

        var pwdLabel = new Label { Text = "密码：", AutoSize = true, Location = new Point(16, 68) };
        _pwd.Location = new Point(100, 64);
        _pwd.Width = 180;
        _pwd.UseSystemPasswordChar = true;          // 系统密码圆点；也可 PasswordChar='*'

        var ageLabel = new Label { Text = "年龄：", AutoSize = true, Location = new Point(300, 32) };
        _age.SetBounds(370, 28, 110, 30);
        _age.Minimum = 1; _age.Maximum = 120;
        _age.Value = 18;
        _age.Increment = 1;
        _age.ValueChanged += (s, e) => status.Text = $"  年龄 = {_age.Value}（NumericUpDown 自带上下箭头与校验）";

        var echo = new Button { Text = "回显", Location = new Point(300, 62), Width = 90 };
        echo.Click += (s, e) =>
        {
            // 密码框的 Text 就是明文——"密码不可见"只是 UI 呈现，不是加密
            MessageBox.Show($"用户名「{_user.Text}」长度 {_user.Text.Length}\n密码（明文在内存里）「{_pwd.Text}」",
                            "回显", MessageBoxButtons.OK, MessageBoxIcon.Information);
        };

        login.Controls.AddRange(new Control[] { userLabel, _user, pwdLabel, _pwd, ageLabel, _age, echo });

        // ═══ 5.2 中部：RichTextBox——带格式文本 ═══
        var richLabel = new Label { Text = "RichTextBox（彩色追加 / 选区加粗 / 字数统计）", Dock = DockStyle.Top, Height = 26 };
        _rich.Dock = DockStyle.Fill;
        _rich.AcceptsTab = true;
        _rich.Multiline = true;                     // RichTextBox 默认就是多行
        _rich.ScrollBars = RichTextBoxScrollBars.Vertical;
        _rich.Text = "普通文本一行。\n选中一段文字再点「加粗选中」试试。\n";

        // ═══ 5.3 工具条：彩色追加演示 ═══
        var tools = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 44 };
        var red = new Button { Text = "追加红字", AutoSize = true };
        var blue = new Button { Text = "追加蓝字", AutoSize = true };
        var bold = new Button { Text = "加粗选中", AutoSize = true };
        var count = new Button { Text = "字数统计", AutoSize = true };
        red.Click += (s, e) => AppendColored("这是红色追加的一行\n", Color.Firebrick);
        blue.Click += (s, e) => AppendColored("这是蓝色追加的一行\n", Color.RoyalBlue);
        bold.Click += (s, e) =>
        {
            if (_rich.SelectionLength == 0) { MessageBox.Show("先选中一段文字"); return; }
            _rich.SelectionFont = new Font(_rich.Font, _rich.SelectionFont!.Style | FontStyle.Bold);
        };
        count.Click += (s, e) => MessageBox.Show(
            $"字符数 {_rich.Text.Length}，当前选区 {_rich.SelectionLength} 字", "统计");
        tools.Controls.AddRange(new Control[] { red, blue, bold, count });

        // ═══ 5.4 LinkLabel：点击打开网页 ═══
        var link = new LinkLabel
        {
            Text = "遇到问题？查阅 Microsoft Learn 的 WinForms 文档",
            Dock = DockStyle.Bottom,
            Height = 34,
            LinkBehavior = LinkBehavior.HoverUnderline,
        };
        link.Links.Add(8, 15, "https://learn.microsoft.com/dotnet/desktop/winforms/");   // 第 8 字起 15 字 = “Microsoft Learn”
        link.LinkClicked += (s, e) =>
        {
            // .NET Core 起 UseShellExecute 默认就是 true；用系统默认浏览器打开
            Process.Start(new ProcessStartInfo { FileName = (string)e.Link!.LinkData, UseShellExecute = true });
            link.LinkVisited = true;
        };

        status = new Label { Dock = DockStyle.Bottom, Height = 28, TextAlign = ContentAlignment.MiddleLeft, BackColor = Color.Gainsboro };

        // z 序：Fill 最先 Add 才能被 Dock 控件挤压（Dock 分配规则见 04 章 4.6）
        Controls.Add(_rich);
        Controls.Add(tools);
        Controls.Add(richLabel);
        Controls.Add(status);
        Controls.Add(login);
        Controls.Add(link);
    }

    private Label status;

    // 彩色追加 = 先把插入点挪到末尾，设置 SelectionColor，再 AppendText
    private void AppendColored(string text, Color color)
    {
        _rich.SelectionStart = _rich.Text.Length;
        _rich.SelectionLength = 0;
        _rich.SelectionColor = color;
        _rich.AppendText(text);
        _rich.SelectionColor = _rich.ForeColor;     // 恢复默认色，不影响后续手打
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
