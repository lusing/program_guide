// 06 选择类控件：RadioButton 的互斥范围、ComboBox、CheckedListBox、DateTimePicker、TrackBar
using System.Drawing;
using System.Windows.Forms;

namespace SelectWin;

internal class MainForm : Form
{
    private readonly FlowLayoutPanel _deptFlow = new();
    private readonly FlowLayoutPanel _typeFlow = new();
    private readonly ComboBox _city = new();
    private readonly CheckedListBox _hobbies = new();
    private readonly DateTimePicker _date = new();
    private readonly TrackBar _volume = new();
    private readonly Label _volumeLabel = new();
    private readonly Label _status = new();

    public MainForm()
    {
        Text = "选择类控件";
        ClientSize = new Size(660, 460);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // ═══ 6.1 RadioButton：互斥范围 = 直接容器 ═══
        // 同一容器内的 RadioButton 自动互斥；两组各自互斥 → 放进两个 GroupBox
        var deptBox = new GroupBox { Text = " 部门（互斥组 A）", Dock = DockStyle.Fill };
        _deptFlow.Dock = DockStyle.Fill;
        _deptFlow.FlowDirection = FlowDirection.TopDown;
        foreach (var d in new[] { "研发", "测试", "设计" })
        {
            var rb = new RadioButton { Text = d, AutoSize = true };
            rb.CheckedChanged += (s, e) => { if (rb.Checked) _status.Text = $"  部门 → {d}"; };
            _deptFlow.Controls.Add(rb);
        }
        ((RadioButton)_deptFlow.Controls[0]).Checked = true;    // 默认选中第一项
        deptBox.Controls.Add(_deptFlow);

        var typeBox = new GroupBox { Text = " 用工类型（互斥组 B）", Dock = DockStyle.Fill };
        _typeFlow.Dock = DockStyle.Fill;
        _typeFlow.FlowDirection = FlowDirection.TopDown;
        foreach (var t in new[] { "全职", "实习" })
            _typeFlow.Controls.Add(new RadioButton { Text = t, AutoSize = true });
        ((RadioButton)_typeFlow.Controls[1]).Checked = true;
        typeBox.Controls.Add(_typeFlow);

        // ═══ 6.2 ComboBox：DropDownList 只能选不能输 ═══
        var cityBox = new GroupBox { Text = " 城市（ComboBox，DropDownList 只能选）", Dock = DockStyle.Fill };
        _city.Dock = DockStyle.Top;
        _city.DropDownStyle = ComboBoxStyle.DropDownList;
        _city.Items.AddRange(new object[] { "北京", "上海", "广州", "深圳", "杭州" });
        _city.SelectedIndex = 0;
        _city.SelectedIndexChanged += (s, e) =>
            _status.Text = $"  城市 → {_city.SelectedItem}（索引 {_city.SelectedIndex}）";
        cityBox.Controls.Add(_city);

        // ═══ 6.3 CheckedListBox：勾选列表 ═══
        var hobbyBox = new GroupBox { Text = " 兴趣（CheckedListBox，可多选）", Dock = DockStyle.Fill };
        _hobbies.Dock = DockStyle.Fill;
        _hobbies.CheckOnClick = true;               // 点一次就勾上（默认要先点两下）
        _hobbies.Items.AddRange(new object[] { "看书", "游戏", "爬山", "摄影", "做饭" });
        hobbyBox.Controls.Add(_hobbies);

        // ═══ 6.4 + 6.5 日期与滑块 ═══
        var miscBox = new GroupBox { Text = " 日期与音量 ", Dock = DockStyle.Fill };
        var dateLabel = new Label { Text = "入职日期：", AutoSize = true, Location = new Point(12, 30) };
        _date.SetBounds(100, 26, 200, 30);
        _date.Format = DateTimePickerFormat.Long;    // 还有 Short/Time/Custom（配 CustomFormat）
        _date.Value = DateTime.Today;
        _date.ValueChanged += (s, e) => _status.Text = $"  入职 → {_date.Value:yyyy-MM-dd（dddd）}";

        var volLabel = new Label { Text = "音量：", AutoSize = true, Location = new Point(12, 76) };
        _volumeLabel.AutoSize = true;
        _volumeLabel.Location = new Point(100, 106);
        _volume.SetBounds(96, 70, 220, 45);
        _volume.Minimum = 0; _volume.Maximum = 100;
        _volume.Value = 60;
        _volume.TickFrequency = 10;                  // 刻度密度
        _volume.Scroll += (s, e) => _volumeLabel.Text = $"音量 = {_volume.Value}（拖动时连续触发 Scroll）";
        _volumeLabel.Text = $"音量 = {_volume.Value}";

        var summary = new Button { Text = "汇总我的选择", Location = new Point(12, 136), AutoSize = true };
        summary.Click += (s, e) => MessageBox.Show(this, DescribeSelections(), "汇总");

        miscBox.Controls.AddRange(new Control[] { dateLabel, _date, volLabel, _volume, _volumeLabel, summary });

        // ═══ 布局：左列两格 + 右列上下拆 ═══
        var rightSplit = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 2 };
        rightSplit.RowStyles.Add(new RowStyle(SizeType.Percent, 55f));
        rightSplit.RowStyles.Add(new RowStyle(SizeType.Percent, 45f));
        rightSplit.Controls.Add(miscBox, 0, 0);
        rightSplit.Controls.Add(hobbyBox, 0, 1);

        var grid = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 2 };
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50f));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50f));
        grid.RowStyles.Add(new RowStyle(SizeType.Percent, 45f));
        grid.RowStyles.Add(new RowStyle(SizeType.Percent, 55f));
        grid.Controls.Add(deptBox, 0, 0);
        grid.Controls.Add(typeBox, 1, 0);
        grid.Controls.Add(cityBox, 0, 1);
        grid.Controls.Add(rightSplit, 1, 1);

        _status.Dock = DockStyle.Bottom;
        _status.Height = 30;
        _status.BackColor = Color.Gainsboro;
        _status.TextAlign = ContentAlignment.MiddleLeft;

        Controls.Add(grid);
        Controls.Add(_status);
    }

    private string DescribeSelections()
    {
        var hobbies = new List<string>();
        foreach (int i in _hobbies.CheckedIndices)
            hobbies.Add((string)_hobbies.Items[i]);
        return $"部门：{CheckedText(_deptFlow)}\n用工：{CheckedText(_typeFlow)}\n" +
               $"城市：{_city.SelectedItem}\n入职：{_date.Value:yyyy-MM-dd}\n音量：{_volume.Value}\n" +
               $"兴趣：{(hobbies.Count == 0 ? "（无）" : string.Join("、", hobbies))}";
    }

    private static string CheckedText(FlowLayoutPanel flow)
    {
        foreach (Control c in flow.Controls)
            if (c is RadioButton { Checked: true } rb)
                return rb.Text;
        return "（未选）";
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
