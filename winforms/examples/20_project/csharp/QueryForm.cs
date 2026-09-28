// 20 实战项目：住客查询（书 11.7.7 的查询设计）
using System.Drawing;
using System.Windows.Forms;

namespace HotelApp;

internal class QueryForm : Form
{
    private readonly TextBox _search = new();
    private readonly ListView _list = new();
    private readonly Label _summary = new();

    public QueryForm()
    {
        Text = "住客查询";
        ClientSize = new Size(720, 420);
        Font = new Font("微软雅黑", 10F);

        var bar = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 44 };
        var lbl = new Label { Text = "姓名/电话/房号：", AutoSize = true, Padding = new Padding(0, 10, 0, 0) };
        _search.Width = 180;
        var go = new Button { Text = "查询", AutoSize = true };
        go.Click += (s, e) => Reload();
        _search.KeyDown += (s, e) => { if (e.KeyCode == Keys.Enter) Reload(); };
        bar.Controls.AddRange(new Control[] { lbl, _search, go });

        _list.Dock = DockStyle.Fill;
        _list.View = View.Details;
        _list.FullRowSelect = true;
        _list.GridLines = true;
        _list.Columns.Add("入住", 90);
        _list.Columns.Add("退房", 90);
        _list.Columns.Add("房号", 60);
        _list.Columns.Add("姓名", 80);
        _list.Columns.Add("电话", 110);
        _list.Columns.Add("状态", 160);

        _summary.Dock = DockStyle.Bottom;
        _summary.Height = 30;
        _summary.BackColor = Color.Gainsboro;

        Controls.Add(_list);
        Controls.Add(_summary);
        Controls.Add(bar);
        Reload();
    }

    private void Reload()
    {
        _list.Items.Clear();
        var stays = MainForm.Db.Search(_search.Text.Trim());
        int inHouse = 0;
        foreach (var st in stays)
        {
            if (!st.CheckedOut) inHouse++;
            var row = new ListViewItem(st.CheckIn.ToString("MM-dd HH:mm"));
            row.SubItems.Add(st.CheckedOut ? st.CheckOut.ToString("MM-dd HH:mm") : "-");
            row.SubItems.Add(st.RoomNumber);
            row.SubItems.Add(st.GuestName);
            row.SubItems.Add(st.Phone);
            row.SubItems.Add(st.Status);
            row.ForeColor = st.CheckedOut ? Color.Gray : Color.Black;
            _list.Items.Add(row);
        }
        _summary.Text = $"  共 {stays.Count} 条记录，其中在住 {inHouse} 人（已退的灰显）";
    }
}
