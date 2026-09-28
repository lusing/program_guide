// 10 SDI 与 MDI：多文档界面、子窗体管理、窗口菜单
using System.Drawing;
using System.Windows.Forms;

namespace MdiWin;

// ═══ 10.1 子窗体：一个"文档" ═══
internal class ChildForm : Form
{
    public readonly RichTextBox Editor = new();

    public ChildForm(int index)
    {
        Text = $"文档 {index}";
        Width = 420; Height = 300;
        MdiParent = null;              // 由创建方赋值——MdiParent 决定它是谁的子窗体
        Font = new Font("微软雅黑", 10F);

        Editor.Dock = DockStyle.Fill;
        Editor.Text = $"我是第 {index} 个子文档。\n";
        Controls.Add(Editor);
    }
}

// ═══ 10.2 父窗体：MDI 容器 ═══
internal class MainForm : Form
{
    private int _created;
    private readonly ToolStripStatusLabel _status = new();

    public MainForm()
    {
        Text = "MDI 多文档示例";
        IsMdiContainer = true;                 // 一句话变身 MDI 容器（背景色也会变）
        ClientSize = new Size(860, 560);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        var menu = new MenuStrip();

        var miNew = new ToolStripMenuItem("新建文档(&N)") { ShortcutKeys = Keys.Control | Keys.N };
        miNew.Click += (s, e) => NewChild();
        var miQuit = new ToolStripMenuItem("退出(&Q)");
        miQuit.Click += (s, e) => Close();
        var fileMenu = new ToolStripMenuItem("文件(&F)");
        fileMenu.DropDownItems.AddRange(new ToolStripItem[] { miNew, new ToolStripSeparator(), miQuit });

        // ═══ 10.3 窗口菜单：布局四件套 + 子窗体清单（MdiWindowListItem 白送）═══
        var winMenu = new ToolStripMenuItem("窗口(&W)");
        var miCascade = new ToolStripMenuItem("层叠排列(&C)");
        miCascade.Click += (s, e) => LayoutMdi(MdiLayout.Cascade);
        var miTileV = new ToolStripMenuItem("垂直平铺(&V)");
        miTileV.Click += (s, e) => LayoutMdi(MdiLayout.TileVertical);
        var miTileH = new ToolStripMenuItem("水平平铺(&H)");
        miTileH.Click += (s, e) => LayoutMdi(MdiLayout.TileHorizontal);
        var miArrange = new ToolStripMenuItem("排列图标(&A)");
        miArrange.Click += (s, e) => LayoutMdi(MdiLayout.ArrangeIcons);
        winMenu.DropDownItems.AddRange(new ToolStripItem[]
        {
            miCascade, miTileV, miTileH, miArrange, new ToolStripSeparator(),
        });
        // MdiWindowListItem 在 MenuStrip 上：指定的那一项后面会被自动填充子窗体清单
        menu.MdiWindowListItem = miCascade;

        menu.Items.AddRange(new ToolStripItem[] { fileMenu, winMenu });

        var statusStrip = new StatusStrip();
        _status.Spring = true;
        _status.TextAlign = ContentAlignment.MiddleLeft;
        statusStrip.Items.Add(_status);

        MdiChildActivate += (s, e) => RefreshStatus();    // 活动子窗体切换
        FormClosed += (s, e) => { /* 主窗体关闭会带走所有子窗体，无需逐个处理 */ };

        Controls.Add(statusStrip);
        Controls.Add(menu);
        MainMenuStrip = menu;

        NewChild();
        NewChild();
    }

    private void NewChild()
    {
        var child = new ChildForm(++_created)
        {
            MdiParent = this,                          // ★ 认父：从此受容器管理
            StartPosition = FormStartPosition.Manual,
            Location = new Point(30 * (_created % 8), 30 * (_created % 8)),   // 级联错位
        };
        child.Editor.TextChanged += (s, e) => RefreshStatus();
        child.Show();
        RefreshStatus();
    }

    private void RefreshStatus()
    {
        var active = ActiveMdiChild as ChildForm;
        string activeInfo = active is null
            ? "（无）"
            : $"「{active.Text}」{active.Editor.Text.Length} 字";
        _status.Text = $"  子窗体 {MdiChildren.Length} 个；活动文档：{activeInfo}";
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
