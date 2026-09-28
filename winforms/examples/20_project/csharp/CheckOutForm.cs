// 20 实战项目：退房结账（书 11.7.6 的退房设计）
using System.Drawing;
using System.Windows.Forms;

namespace HotelApp;

internal class CheckOutForm : Form
{
    private readonly ListBox _stays = new();
    private readonly Label _preview = new();

    public CheckOutForm()
    {
        Text = "退房结账";
        ClientSize = new Size(560, 360);
        StartPosition = FormStartPosition.CenterParent;
        Font = new Font("微软雅黑", 10F);

        var hint = new Label
        {
            Text = "在住名单（入住时间 / 房号 / 姓名）：",
            Dock = DockStyle.Top,
            Height = 28,
        };
        _stays.Dock = DockStyle.Fill;
        _preview.Dock = DockStyle.Bottom;
        _preview.Height = 60;
        _preview.ForeColor = Color.DarkSlateBlue;

        var bar = new FlowLayoutPanel { Dock = DockStyle.Bottom, Height = 44 };
        var pay = new Button { Text = "结账退房", AutoSize = true };
        pay.Click += (s, e) =>
        {
            if (_stays.SelectedItem is not StayTag tag) { MessageBox.Show("先选中一位在住客人"); return; }
            decimal bill = MainForm.Db.CheckOut(tag.Id);
            MessageBox.Show(this, $"{tag.Desc}\n账单：￥{bill}", "退房完成");
            Reload();
        };
        var refresh = new Button { Text = "刷新", AutoSize = true };
        refresh.Click += (s, e) => Reload();
        bar.Controls.AddRange(new Control[] { pay, refresh });

        _stays.SelectedIndexChanged += (s, e) => RefreshPreview();

        Controls.Add(_stays);
        Controls.Add(bar);
        Controls.Add(_preview);
        Controls.Add(hint);
        Reload();
    }

    private void Reload()
    {
        _stays.Items.Clear();
        foreach (var st in MainForm.Db.ActiveStays())
            _stays.Items.Add(new StayTag(st.Id, $"{st.CheckIn:MM-dd HH:mm}  {st.RoomNumber} 房  {st.GuestName}（{st.Phone}）  ￥{st.RoomPrice}/晚"));
        _preview.Text = "  选中客人后这里显示预估账单";
    }

    private void RefreshPreview()
    {
        if (_stays.SelectedItem is not StayTag tag) return;
        var st = MainForm.Db.ActiveStays().Single(x => x.Id == tag.Id);
        int nights = Math.Max(1, (int)Math.Ceiling((DateTime.Now - st.CheckIn).TotalDays));
        _preview.Text = $"  预估：{nights} 晚 × ￥{st.RoomPrice} = ￥{nights * st.RoomPrice}（不足一天按一天计）";
    }

    // ListBox 里放对象而不是字符串：显示用 ToString，取值用 Id（07 章 Tag 思路的同款）
    private record StayTag(long Id, string Desc)
    {
        public override string ToString() => Desc;
    }
}
