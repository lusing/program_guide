// 08 菜单、工具栏与状态栏：MenuStrip、ContextMenuStrip、ToolStrip、StatusStrip、快捷键
using System.Drawing;
using System.Windows.Forms;

namespace MenusWin;

internal class MainForm : Form
{
    private readonly RichTextBox _editor = new();
    private readonly ToolStripStatusLabel _hint = new();
    private readonly ToolStripStatusLabel _count = new();
    private readonly ToolStrip _tool = new();
    private readonly StatusStrip _status = new();

    public MainForm()
    {
        Text = "菜单工具栏示例——迷你编辑器";
        ClientSize = new Size(720, 480);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // ═══ 8.1 菜单栏：顶级菜单与下拉项 ═══
        var menu = new MenuStrip();

        // 文件
        var miNew = Item("新建(&N)", Keys.Control | Keys.N, () => { _editor.Clear(); Say("新建文档"); });
        var miSave = Item("保存(&S)", Keys.Control | Keys.S, () => Say("保存到哪？—— 09 章的 SaveFileDialog 负责"));
        var miQuit = Item("退出(&Q)", Keys.Control | Keys.Q, () => Close());
        menu.Items.Add(Menu("文件(&F)", miNew, miSave, Sep(), miQuit));

        // 编辑
        var miAll = Item("全选(&A)", Keys.Control | Keys.A, () => _editor.SelectAll());
        var miCopy = Item("复制(&C)", Keys.Control | Keys.C, () => _editor.Copy());
        var miClear = Item("清空", Keys.None, () => _editor.Clear());
        menu.Items.Add(Menu("编辑(&E)", miAll, miCopy, Sep(), miClear));

        // 视图：CheckOnClick 的勾选菜单 = 工具栏/状态栏开关
        var miTool = new ToolStripMenuItem("工具栏(&T)") { Checked = true, CheckOnClick = true };
        miTool.Click += (s, e) => _tool.Visible = miTool.Checked;
        var miStatus = new ToolStripMenuItem("状态栏(&B)") { Checked = true, CheckOnClick = true };
        miStatus.Click += (s, e) => _status.Visible = miStatus.Checked;
        menu.Items.Add(Menu("视图(&V)", miTool, miStatus));

        // 帮助
        var miAbout = Item("关于(&A)", Keys.F1, () =>
            MessageBox.Show(this, "迷你编辑器 1.0\n三语言示例 · 08 章", "关于"));
        menu.Items.Add(Menu("帮助(&H)", miAbout));

        // ═══ 8.2 工具栏：按钮 + 分隔线；点击直接复用菜单项的 PerformClick ═══
        _tool.GripStyle = ToolStripGripStyle.Hidden;
        _tool.Items.Add(ToolBtn("新建", "新建文档 (Ctrl+N)", miNew.PerformClick));
        _tool.Items.Add(ToolBtn("保存", "保存 (Ctrl+S)", miSave.PerformClick));
        _tool.Items.Add(new ToolStripSeparator());
        _tool.Items.Add(ToolBtn("全选", "全选 (Ctrl+A)", miAll.PerformClick));
        _tool.Items.Add(ToolBtn("清空", "清空文档", miClear.PerformClick));

        // ═══ 8.3 右键菜单：ContextMenuStrip 挂到 RichTextBox ═══
        var ctx = new ContextMenuStrip();
        ctx.Items.Add(Item("剪切", Keys.Control | Keys.X, () => _editor.Cut()));
        ctx.Items.Add(Item("复制", Keys.Control | Keys.C, () => _editor.Copy()));
        ctx.Items.Add(Item("粘贴", Keys.Control | Keys.V, () => _editor.Paste()));
        ctx.Items.Add(Sep());
        ctx.Items.Add(Item("全选", Keys.Control | Keys.A, () => _editor.SelectAll()));
        _editor.ContextMenuStrip = ctx;

        // ═══ 8.4 编辑区 ═══
        _editor.Dock = DockStyle.Fill;
        _editor.Text = "试试：菜单、Ctrl+N、在正文里点右键、拖宽看状态栏数字。\n";

        // ═══ 8.5 状态栏：Spring 让一个标签吃满剩余宽度 ═══
        _hint.Spring = true;
        _hint.TextAlign = ContentAlignment.MiddleLeft;
        _count.Text = "0 字";
        _status.Items.AddRange(new ToolStripItem[] { _hint, _count });
        Say("就绪");

        _editor.TextChanged += (s, e) => _count.Text = $"{_editor.Text.Length} 字";

        // 鼠标扫过菜单/工具项时状态栏给提示（Tag 里存说明文字）
        foreach (var strip in new ToolStrip[] { menu, _tool, ctx })
            foreach (ToolStripItem it in strip.Items)
                if (it.Tag is string tip && tip.Length > 0)
                    it.MouseEnter += (s, e) => Say(tip);

        Controls.Add(_editor);
        Controls.Add(_tool);
        Controls.Add(_status);
        Controls.Add(menu);
        MainMenuStrip = menu;                          // 告诉窗体谁是主菜单（Alt 激活等行为）
    }

    private void Say(string msg) => _hint.Text = "  " + msg;

    // —— 小工厂：菜单项 = 文字 + 可选快捷键 + 点击行为，Tag 顺带存状态栏提示 ——
    private static ToolStripMenuItem Item(string text, Keys shortcut, Action onClick)
    {
        var mi = new ToolStripMenuItem(text);
        if (shortcut != Keys.None) { mi.ShortcutKeys = shortcut; mi.ShowShortcutKeys = true; }
        mi.Click += (s, e) => onClick();
        mi.Tag = text.Replace("&", "");
        return mi;
    }

    private static ToolStripMenuItem Menu(string text, params ToolStripItem[] children)
    {
        var m = new ToolStripMenuItem(text);
        m.DropDownItems.AddRange(children);
        return m;
    }

    private static ToolStripSeparator Sep() => new();

    private static ToolStripButton ToolBtn(string text, string tip, Action onClick)
    {
        var b = new ToolStripButton(text) { ToolTipText = tip, Tag = tip };
        b.Click += (s, e) => onClick();
        return b;
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
