// 20 实战项目：入住登记（书 11.7.5 的入住设计）
using System.Drawing;
using System.Windows.Forms;

namespace HotelApp;

internal class CheckInForm : Form
{
    private readonly ComboBox _room = new();
    private readonly TextBox _name = new();
    private readonly TextBox _phone = new();
    private readonly Label _price;

    public CheckInForm()
    {
        Text = "入住登记";
        ClientSize = new Size(400, 220);
        StartPosition = FormStartPosition.CenterParent;
        Font = new Font("微软雅黑", 10F);

        var rl = new Label { Text = "空房：", AutoSize = true, Location = new Point(20, 24) };
        _room.DropDownStyle = ComboBoxStyle.DropDownList;
        _room.SetBounds(90, 20, 180, 30);
        foreach (var r in MainForm.Db.Rooms(occupied: false))
            _room.Items.Add($"{r.Number} · {r.Type} · ￥{r.Price}/晚");
        if (_room.Items.Count == 0)
            _room.Items.Add("（暂无空房）");
        _room.SelectedIndex = 0;
        _room.SelectedIndexChanged += (s, e) => RefreshPrice();

        var nl = new Label { Text = "姓名：", AutoSize = true, Location = new Point(20, 62) };
        _name.SetBounds(90, 58, 180, 30);
        var pl = new Label { Text = "电话：", AutoSize = true, Location = new Point(20, 100) };
        _phone.SetBounds(90, 96, 180, 30);

        _price = new Label { AutoSize = true, Location = new Point(288, 24), ForeColor = Color.DarkSlateBlue };

        var ok = new Button { Text = "办理入住", Location = new Point(90, 140), Width = 110 };
        ok.Click += (s, e) =>
        {
            if (_room.Text.StartsWith("（")) { MessageBox.Show("没有空房可住"); return; }
            if (_name.Text.Trim().Length == 0) { MessageBox.Show("请填姓名"); return; }
            string roomNumber = _room.Text.Split(' ')[0];
            MainForm.Db.CheckIn(roomNumber, _name.Text.Trim(), _phone.Text.Trim());
            MessageBox.Show($"「{_name.Text}」入住 {roomNumber} 成功", "入住");
            ReloadRooms();
        };
        var close = new Button { Text = "关窗", Location = new Point(210, 140), Width = 80 };
        close.Click += (s, e) => Close();

        Controls.AddRange(new Control[] { rl, _room, nl, _name, pl, _phone, ok, close, _price });
        RefreshPrice();
    }

    private void ReloadRooms()
    {
        _room.Items.Clear();
        foreach (var r in MainForm.Db.Rooms(occupied: false))
            _room.Items.Add($"{r.Number} · {r.Type} · ￥{r.Price}/晚");
        if (_room.Items.Count == 0) _room.Items.Add("（暂无空房）");
        _room.SelectedIndex = 0;
        RefreshPrice();
    }

    private void RefreshPrice()
    {
        _price.Text = _room.Text.StartsWith("（") ? "" : $"价格\n{_room.Text.Split('·')[2].Trim()}";
    }
}
