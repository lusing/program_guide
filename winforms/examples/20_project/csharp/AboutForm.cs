// 20 实战项目：关于窗口（书 11.7.9 的帮助设计）
using System.Drawing;
using System.Windows.Forms;

namespace HotelApp;

internal class AboutForm : Form
{
    public AboutForm()
    {
        Text = "关于";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        ClientSize = new Size(380, 200);
        StartPosition = FormStartPosition.CenterParent;
        Font = new Font("微软雅黑", 10F);
        MaximizeBox = false; MinimizeBox = false;

        var body = new Label
        {
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleCenter,
            Text = "客房管理系统 1.0\nWinForms 三层示例（UI → HotelDb → SQLite）\n\n登录：admin / 1234\n数据库：%TEMP%\\winforms20.db",
        };
        var ok = new Button { Text = "确定", DialogResult = DialogResult.OK, Dock = DockStyle.Bottom, Height = 34 };
        Controls.Add(body);
        Controls.Add(ok);
        AcceptButton = ok;
    }
}
