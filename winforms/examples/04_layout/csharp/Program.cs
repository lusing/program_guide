// 04 布局：Dock、Anchor、TableLayoutPanel、FlowLayoutPanel 与 DPI 缩放
using System.Drawing;
using System.Windows.Forms;

namespace LayoutWin;

internal class MainForm : Form
{
    private readonly Label _sizeLabel = new();
    private readonly TextBox _anchorBox = new();

    public MainForm()
    {
        Text = "布局系统";
        ClientSize = new Size(520, 400);
        MinimumSize = new Size(420, 320);          // 再小也缩不下去
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // AutoScaleMode.Font：按字体尺寸整体缩放界面——高 DPI 屏不糊不挤的官方答案
        AutoScaleMode = AutoScaleMode.Font;

        // ═══ 4.1 底部状态：ClientSize vs Size ═══
        // Size 含标题栏和边框；ClientSize 只是客户区。布局关心的是后者
        _sizeLabel.Dock = DockStyle.Bottom;
        _sizeLabel.Height = 30;
        _sizeLabel.TextAlign = ContentAlignment.MiddleLeft;
        _sizeLabel.Padding = new Padding(8, 0, 0, 0);
        _sizeLabel.BackColor = Color.Gainsboro;
        Resize += (s, e) => ReportSize();
        ReportSize();

        // ═══ 4.2 FlowLayoutPanel：按钮流水线（宽度不够自动换行）═══
        var flow = new FlowLayoutPanel { Dock = DockStyle.Bottom, Height = 76, FlowDirection = FlowDirection.LeftToRight };
        foreach (var name in new[] { "重置", "保存", "导出", "打印", "分享", "更多…" })
        {
            var b = new Button { Text = name, AutoSize = true };
            b.Margin = new Padding(4);
            b.Click += (s, e) => _sizeLabel.Text = $"[flow] 点击了「{name}」——注意本行放不下时会自动换行";
            flow.Controls.Add(b);
        }

        // ═══ 4.3 Anchor 实验：随窗体一起伸缩的文本框 ═══
        _anchorBox.Anchor = AnchorStyles.Left | AnchorStyles.Top | AnchorStyles.Right;  // 左上钉住、右边跟随
        _anchorBox.Location = new Point(120, 250);
        _anchorBox.Width = 300;
        var anchorLabel = new Label { Text = "Anchor →", AutoSize = true, Location = new Point(16, 253) };
        var anchorHint = new Label
        {
            Text = "拖宽窗口：上面这个文本框跟着变宽（锚住了左右两边）",
            AutoSize = true,
            Location = new Point(120, 278),
            ForeColor = Color.DimGray,
        };

        // ═══ 4.4 TableLayoutPanel：两列表单 ═══
        var table = new TableLayoutPanel { Dock = DockStyle.Top, Height = 220, ColumnCount = 2, RowCount = 4 };
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 28f));   // 列宽按比例分
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 72f));
        table.Padding = new Padding(12);

        AddRow(table, 0, "用户名：", new TextBox { Dock = DockStyle.Fill });
        AddRow(table, 1, "邮箱：", new TextBox { Dock = DockStyle.Fill });
        AddRow(table, 2, "部门：", new ComboBox
        {
            Dock = DockStyle.Fill,
            DropDownStyle = ComboBoxStyle.DropDownList,
        });
        var combo = (ComboBox)table.GetControlFromPosition(1, 2)!;
        combo.Items.AddRange(new object[] { "研发部", "市场部", "财务部", "人事部" });
        combo.SelectedIndex = 0;

        var notify = new CheckBox { Text = "接受通知邮件", Dock = DockStyle.Fill, AutoSize = true };
        AddRow(table, 3, "偏好：", notify);

        Controls.Add(table);
        Controls.Add(anchorLabel);
        Controls.Add(_anchorBox);
        Controls.Add(anchorHint);
        Controls.Add(flow);        // Dock 顺序：后加的先占坑（z序与 Dock 分配的规则见 4.6）
        Controls.Add(_sizeLabel);
    }

    // 表格行助手：0 号列标签右对齐，1 号列控件填满
    private static void AddRow(TableLayoutPanel table, int row, string caption, Control input)
    {
        var label = new Label
        {
            Text = caption,
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleRight,
            Margin = new Padding(0, 9, 8, 3),
        };
        table.Controls.Add(label, 0, row);
        table.Controls.Add(input, 1, row);
    }

    private void ReportSize()
    {
        _sizeLabel.Text = $"  ClientSize = {ClientSize.Width}×{ClientSize.Height}，AnchorBox 宽 {_anchorBox.Width}（拖动窗口右下角试试）";
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
