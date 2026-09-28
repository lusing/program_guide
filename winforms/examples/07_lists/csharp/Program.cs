// 07 容器与列表控件：SplitContainer、TabControl、TreeView、ListView、ImageList、AutoScroll
using System.Drawing;
using System.Windows.Forms;

namespace ListsWin;

internal class MainForm : Form
{
    // 类别 → (名称, 单价, 产地)
    private static readonly Dictionary<string, (string Name, decimal Price, string From)[]> Catalog = new()
    {
        ["水果"] = new[] { ("苹果", 8.5m, "山东"), ("香蕉", 3.2m, "海南"), ("樱桃", 39.9m, "大连") },
        ["蔬菜"] = new[] { ("番茄", 4.0m, "寿光"), ("黄瓜", 2.8m, "廊坊"), ("土豆", 1.9m, "内蒙古") },
        ["粮油"] = new[] { ("大米", 5.6m, "五常"), ("面粉", 4.3m, "河北"), ("玉米油", 12.8m, "东北") },
    };

    private readonly TreeView _tree = new();
    private readonly ListView _list = new();
    private readonly ImageList _icons = new();
    private readonly ListView _iconList = new();
    private readonly Label _status = new();

    public MainForm()
    {
        Text = "容器与列表控件";
        ClientSize = new Size(760, 480);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // ═══ 7.1 左右分栏：SplitContainer（中间那条可拖动）═══
        var split = new SplitContainer { Dock = DockStyle.Fill };
        split.SplitterDistance = 220;               // 初始左侧宽度

        // ═══ 7.2 左栏：TreeView ═══
        _tree.Dock = DockStyle.Fill;
        _tree.HideSelection = false;
        foreach (var (cat, items) in Catalog)
        {
            var node = _tree.Nodes.Add(cat);         // 一级节点 = 类别
            node.Tag = cat;                          // Tag：随节点携带任意数据的口袋
            foreach (var (name, _, _) in items)
            {
                var child = node.Nodes.Add(name);
                child.Tag = (cat, name);             // 元组也能塞进 Tag
            }
        }
        _tree.ExpandAll();
        _tree.AfterSelect += (s, e) =>
        {
            _status.Text = $"  选中「{e.Node.Text}」（Level={e.Node.Level}，FullPath={e.Node.FullPath}）";
            RefreshList(e.Node);
        };

        // ═══ 7.3 右栏：TabControl 三页 ═══
        var tabs = new TabControl { Dock = DockStyle.Fill };

        // 第 1 页：ListView 的 Details 视图（最常用的"表格"）
        var page1 = new TabPage("明细表（Details）");
        _list.Dock = DockStyle.Fill;
        _list.View = View.Details;
        _list.FullRowSelect = true;                  // 点整行任意处都选中
        _list.GridLines = true;
        _list.Columns.Add("品名", 140);
        _list.Columns.Add("单价(元)", 90, HorizontalAlignment.Right);
        _list.Columns.Add("产地", 120);
        _list.SelectedIndexChanged += (s, e) =>
        {
            if (_list.SelectedItems.Count > 0)
                _status.Text = $"  列表选中「{_list.SelectedItems[0].Text}」";
        };
        page1.Controls.Add(_list);

        // 第 2 页：ListView 的图标视图 + ImageList（借系统图标，免资源文件）
        var page2 = new TabPage("图标视图（LargeIcon）");
        _icons.ImageSize = new Size(32, 32);
        _icons.Images.Add("shield", SystemIcons.Shield);
        _icons.Images.Add("warn", SystemIcons.Warning);
        _icons.Images.Add("info", SystemIcons.Information);
        _iconList.Dock = DockStyle.Fill;
        _iconList.View = View.LargeIcon;
        _iconList.LargeImageList = _icons;
        _iconList.Items.Add("盾牌", "shield");
        _iconList.Items.Add("警告", "warn");
        _iconList.Items.Add("信息", "info");
        page2.Controls.Add(_iconList);

        // 第 3 页：Panel + AutoScroll（内容超出出现滚动条）
        var page3 = new TabPage("滚动面板（AutoScroll）");
        var panel = new Panel { Dock = DockStyle.Fill, AutoScroll = true };
        for (int i = 1; i <= 12; i++)
        {
            var b = new Button { Text = $"按钮 {i:00}", Location = new Point(16 + (i - 1) % 3 * 130, 16 + (i - 1) / 3 * 48), Size = new Size(120, 38) };
            int captured = i;                        // 闭包捕获循环变量的经典注意点（05 之前的教训）
            b.Click += (s, e) => _status.Text = $"  滚动面板：点了按钮 {captured:00}";
            panel.Controls.Add(b);
        }
        page3.Controls.Add(panel);

        tabs.TabPages.AddRange(new TabPage[] { page1, page2, page3 });

        split.Panel1.Controls.Add(_tree);
        split.Panel2.Controls.Add(tabs);

        _status.Dock = DockStyle.Bottom;
        _status.Height = 30;
        _status.BackColor = Color.Gainsboro;
        _status.TextAlign = ContentAlignment.MiddleLeft;

        Controls.Add(split);
        Controls.Add(_status);

        // 默认展示第一个类别
        _tree.SelectedNode = _tree.Nodes[0];
    }

    // 树节点 → 明细表：一级节点列出整组，二级节点只列单条
    private void RefreshList(TreeNode node)
    {
        _list.Items.Clear();
        if (node.Level == 0)
        {
            foreach (var (name, price, from) in Catalog[(string)node.Tag])
                _list.Items.Add(new ListViewItem(new[] { name, price.ToString("F1"), from }));
        }
        else
        {
            var (cat, name) = ((string, string))node.Tag;
            var (n, price, from) = Catalog[cat].First(x => x.Name == name);
            _list.Items.Add(new ListViewItem(new[] { n, price.ToString("F1"), from }));
        }
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
