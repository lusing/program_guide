// 20 实战项目：主界面（MDI 容器 + 菜单，书 11.7.2 的主界面设计）
using System.Drawing;
using System.Windows.Forms;

namespace HotelApp;

internal class MainForm : Form
{
    public static HotelDb Db { get; } = new(Path.Combine(Path.GetTempPath(), "winforms20.db"));

    public MainForm()
    {
        Text = "客房管理系统（三层示例）";
        IsMdiContainer = true;
        ClientSize = new Size(900, 560);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        var menu = new MenuStrip();

        var miCheckIn = new ToolStripMenuItem("入住登记(&I)…") { ShortcutKeys = Keys.Control | Keys.N };
        miCheckIn.Click += (s, e) => OpenChild<CheckInForm>();
        var miCheckOut = new ToolStripMenuItem("退房结账(&O)…") { ShortcutKeys = Keys.Control | Keys.U };
        miCheckOut.Click += (s, e) => OpenChild<CheckOutForm>();
        var miQuery = new ToolStripMenuItem("住客查询(&Q)…") { ShortcutKeys = Keys.Control | Keys.F };
        miQuery.Click += (s, e) => OpenChild<QueryForm>();
        var front = new ToolStripMenuItem("前台(&F)");
        front.DropDownItems.AddRange(new ToolStripItem[] { miCheckIn, miCheckOut, miQuery, new ToolStripSeparator() });

        var miExit = new ToolStripMenuItem("退出(&X)");
        miExit.Click += (s, e) => Close();
        var sys = new ToolStripMenuItem("系统(&S)");
        sys.DropDownItems.AddRange(new ToolStripItem[] { miExit });

        var miAbout = new ToolStripMenuItem("关于(&A)…");
        miAbout.Click += (s, e) => new AboutForm().ShowDialog(this);
        var help = new ToolStripMenuItem("帮助(&H)");
        help.DropDownItems.AddRange(new ToolStripItem[] { miAbout });

        menu.Items.AddRange(new ToolStripItem[] { front, sys, help });

        var status = new StatusStrip();
        var hint = new ToolStripStatusLabel { Spring = true, TextAlign = ContentAlignment.MiddleLeft };
        hint.Text = $"  数据库：{Path.Combine(Path.GetTempPath(), "winforms20.db")}（登录 admin / 1234 已通过）";
        status.Items.Add(hint);

        Controls.Add(status);
        Controls.Add(menu);
        MainMenuStrip = menu;

        // 开场直接给一个查询窗口，桌面不空
        OpenChild<QueryForm>();
    }

    // 同类子窗体只开一份：已有就激活
    private void OpenChild<T>() where T : Form, new()
    {
        foreach (Form f in MdiChildren)
            if (f is T existing)
            {
                existing.Activate();
                return;
            }
        var child = new T { MdiParent = this };
        child.Show();
    }
}
