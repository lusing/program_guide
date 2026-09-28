// 09 通用对话框：MessageBox 高级用法、Open/Save/Color/Font/FolderBrowser，串成迷你编辑器
using System.Drawing;
using System.Windows.Forms;

namespace DialogsWin;

internal class MainForm : Form
{
    private readonly RichTextBox _editor = new();
    private readonly ToolStripStatusLabel _status = new();
    private string _file = null;        // 当前文件（null = 未命名）
    private bool _dirty;

    public MainForm()
    {
        Text = "迷你编辑器——对话框大全";
        ClientSize = new Size(720, 480);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        var menu = new MenuStrip();

        // ═══ 9.1 打开文件对话框 ═══
        var miOpen = new ToolStripMenuItem("打开(&O)…") { ShortcutKeys = Keys.Control | Keys.O };
        miOpen.Click += (s, e) =>
        {
            using var dlg = new OpenFileDialog
            {
                Title = "挑一个文本文件",
                Filter = "文本文件|*.txt;*.md|日志|*.log|所有文件|*.*",   // 显示名|通配符，成对出现
                InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
                Multiselect = false,
                CheckFileExists = true,                  // 选不存在的文件直接拦下
            };
            if (dlg.ShowDialog(this) != DialogResult.OK) return;   // 取消就什么都不做

            _editor.Text = File.ReadAllText(dlg.FileName);         // 默认按 UTF-8 读
            _file = dlg.FileName;
            _dirty = false;
            UpdateTitle();
            Say($"打开 {dlg.FileName}");
        };

        // ═══ 9.2 保存/另存为对话框 ═══
        var miSave = new ToolStripMenuItem("保存(&S)") { ShortcutKeys = Keys.Control | Keys.S };
        miSave.Click += (s, e) => Save(false);
        var miSaveAs = new ToolStripMenuItem("另存为(&A)…");
        miSaveAs.Click += (s, e) => Save(true);

        var miQuit = new ToolStripMenuItem("退出(&Q)");
        miQuit.Click += (s, e) => Close();

        var fileMenu = new ToolStripMenuItem("文件(&F)");
        fileMenu.DropDownItems.AddRange(new ToolStripItem[] { miOpen, miSave, miSaveAs, new ToolStripSeparator(), miQuit });

        // ═══ 9.3 颜色与字体对话框 ═══
        var miColor = new ToolStripMenuItem("文字颜色(&C)…");
        miColor.Click += (s, e) =>
        {
            using var dlg = new ColorDialog { Color = _editor.ForeColor, FullOpen = true };  // 直接展开自定义区
            if (dlg.ShowDialog(this) == DialogResult.OK)
                _editor.SelectionColor = dlg.Color;     // 只改选区（无选区=改后续输入）
        };

        var miFont = new ToolStripMenuItem("字体(&F)…");
        miFont.Click += (s, e) =>
        {
            using var dlg = new FontDialog
            {
                ShowColor = false,
                MinSize = 9,
                MaxSize = 36,
                FontMustExist = true,
            };
            if (dlg.ShowDialog(this) == DialogResult.OK)
                _editor.SelectionFont = dlg.Font;       // 选中文字换字体；没选中就影响后续输入
        };

        // ═══ 9.4 浏览文件夹对话框 ═══
        var miDir = new ToolStripMenuItem("统计文件夹(&D)…");
        miDir.Click += (s, e) =>
        {
            using var dlg = new FolderBrowserDialog
            {
                Description = "选一个文件夹，统计里面文本文件的数量",
                UseDescriptionForTitle = true,
            };
            if (dlg.ShowDialog(this) != DialogResult.OK) return;
            int n = Directory.GetFiles(dlg.SelectedPath, "*.txt", SearchOption.TopDirectoryOnly).Length;
            Say($"{dlg.SelectedPath} 下有 {n} 个 .txt（只看第一层）");
        };

        var fmtMenu = new ToolStripMenuItem("格式(&M)");
        fmtMenu.DropDownItems.AddRange(new ToolStripItem[] { miColor, miFont, miDir });

        menu.Items.AddRange(new ToolStripItem[] { fileMenu, fmtMenu });

        _editor.Dock = DockStyle.Fill;
        _editor.TextChanged += (s, e) => { _dirty = true; UpdateTitle(); };
        _editor.Text = "改一个字看标题出现 *，再按 Ctrl+S 保存。\n格式菜单里四个对话框随便玩。\n";

        var statusStrip = new StatusStrip();
        _status.Spring = true;
        _status.TextAlign = ContentAlignment.MiddleLeft;
        statusStrip.Items.Add(_status);
        Say("就绪");

        // ═══ 9.5 关闭前确认：三按钮消息框的完整形态 ═══
        FormClosing += (s, e) =>
        {
            if (!_dirty) return;
            var r = MessageBox.Show(this,
                "内容有未保存的修改。\n「是」保存后退出，「否」直接退出，「取消」留在编辑器。",
                "迷你编辑器", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Warning);
            if (r == DialogResult.Cancel)
                e.Cancel = true;
            else if (r == DialogResult.Yes)
            {
                Save(false);
                // 保存被取消（比如另存为对话框点取消）就别退出了
                if (_dirty) e.Cancel = true;
            }
        };

        Controls.Add(_editor);
        Controls.Add(statusStrip);
        Controls.Add(menu);
        MainMenuStrip = menu;
        UpdateTitle();
    }

    private void Say(string msg) => _status.Text = "  " + msg;

    private void UpdateTitle() =>
        Text = $"迷你编辑器——{( _file is null ? "未命名" : Path.GetFileName(_file))}{(_dirty ? " *" : "")}";

    // saveAs = true 强制弹保存框（另存为）；false 时已有文件就直接写
    private void Save(bool saveAs)
    {
        if (_file is null || saveAs)
        {
            using var dlg = new SaveFileDialog
            {
                Filter = "文本文件|*.txt|所有文件|*.*",
                DefaultExt = "txt",                    // 配 AddExtension：没写扩展名自动补
                AddExtension = true,
                OverwritePrompt = true,                // 覆盖已有文件前确认（默认就开，写出来图个明白）
                FileName = _file is null ? "新文档.txt" : Path.GetFileName(_file),
            };
            if (dlg.ShowDialog(this) != DialogResult.OK) { Say("取消保存"); return; }
            _file = dlg.FileName;
        }
        File.WriteAllText(_file, _editor.Text);        // 默认 UTF-8 无 BOM 写
        _dirty = false;
        UpdateTitle();
        Say($"已保存到 {_file}");
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
