// 20 实战项目：程序入口 + 登录窗体（书 11.7.1 的登录设计）
using System.Drawing;
using System.Windows.Forms;

namespace HotelApp;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        // 登录门卫： DialogResult 决定是否放行主程序
        using (var login = new LoginForm())
            if (login.ShowDialog() != DialogResult.OK)
                return;

        Application.Run(new MainForm());
    }
}

// 登录：演示场景用固定账号（真实系统要连库 + 哈希口令，见 docs/20-project.md 的"生产化清单"）
internal class LoginForm : Form
{
    private readonly TextBox _user = new();
    private readonly TextBox _pwd = new();

    public LoginForm()
    {
        Text = "客房管理系统 - 登录";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        ClientSize = new Size(320, 150);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);
        MaximizeBox = false; MinimizeBox = false;

        var ul = new Label { Text = "账号：", AutoSize = true, Location = new Point(24, 24) };
        _user.SetBounds(90, 20, 180, 30);
        var pl = new Label { Text = "密码：", AutoSize = true, Location = new Point(24, 62) };
        _pwd.SetBounds(90, 58, 180, 30);
        _pwd.UseSystemPasswordChar = true;

        var ok = new Button { Text = "登录", DialogResult = DialogResult.OK, Location = new Point(90, 100), Width = 84 };
        var cancel = new Button { Text = "退出", DialogResult = DialogResult.Cancel, Location = new Point(186, 100), Width = 84 };
        ok.Click += (s, e) =>
        {
            if (_user.Text.Trim() != "admin" || _pwd.Text != "1234")
            {
                MessageBox.Show(this, "账号或密码不对（演示：admin / 1234）", "登录",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                DialogResult = DialogResult.None;       // 拦下"确定"，窗体不关
            }
        };
        AcceptButton = ok;
        CancelButton = cancel;

        Controls.AddRange(new Control[] { ul, _user, pl, _pwd, ok, cancel });
    }
}
