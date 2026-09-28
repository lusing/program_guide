// 15 DataGridView：手工列、三种特殊列、校验、条件着色、主从联动
using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;

namespace GridWin;

public class Order
{
    public int Id { get; set; }
    public string Customer { get; set; } = "";
    public string Product { get; set; } = "";
    public int Qty { get; set; }
    public decimal Price { get; set; }
    public bool Paid { get; set; }
    public decimal Total => Qty * Price;      // 计算属性：只读列
}

internal class MainForm : Form
{
    private readonly BindingList<Order> _orders = new();
    private readonly BindingSource _source = new();
    private readonly DataGridView _grid = new();
    private readonly ComboBox _customer = new();
    private readonly Label _sum = new();

    public MainForm()
    {
        Text = "DataGridView 深入";
        ClientSize = new Size(760, 520);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        _orders.Add(new Order { Id = 1, Customer = "林一", Product = "键盘", Qty = 2, Price = 299, Paid = true });
        _orders.Add(new Order { Id = 2, Customer = "林一", Product = "显示器", Qty = 1, Price = 1899, Paid = false });
        _orders.Add(new Order { Id = 3, Customer = "陈二", Product = "鼠标", Qty = 5, Price = 89, Paid = false });
        _orders.Add(new Order { Id = 4, Customer = "陈二", Product = "内存条", Qty = 2, Price = 459, Paid = true });
        _orders.Add(new Order { Id = 5, Customer = "张三", Product = "U盘", Qty = 10, Price = 39, Paid = true });
        _source.DataSource = _orders;
        _source.ListChanged += (s, e) => RefreshSum();

        // ═══ 15.1 主从联动：下拉选客户 → 表格只看这个客户 ═══
        var filterBox = new GroupBox { Text = " 主从联动 ", Dock = DockStyle.Top, Height = 74 };
        var fl = new Label { Text = "客户：", AutoSize = true, Location = new Point(14, 32) };
        _customer.DropDownStyle = ComboBoxStyle.DropDownList;
        _customer.SetBounds(70, 28, 140, 30);
        _customer.Items.AddRange(_orders.Select(o => o.Customer).Distinct().ToArray());
        _customer.SelectedIndex = 0;
        _customer.SelectedIndexChanged += (s, e) => ApplyFilter();
        var all = new CheckBox { Text = "看全部", AutoSize = true, Location = new Point(230, 30) };
        all.CheckedChanged += (s, e) => ApplyFilter();
        filterBox.Controls.AddRange(new Control[] { fl, _customer, all });

        // ═══ 15.2 手工列：关掉自动生成，精确定义 ═══
        _grid.Dock = DockStyle.Fill;
        _grid.AutoGenerateColumns = false;
        _grid.DataSource = _source;
        _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        _grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        _grid.AllowUserToAddRows = false;                 // 数据只走代码加，不靠表格底行

        _grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "单号", DataPropertyName = "Id", FillWeight = 10, ReadOnly = true });
        _grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "客户", DataPropertyName = "Customer", FillWeight = 16 });
        // 列可以不只是文本：
        var productCol = new DataGridViewComboBoxColumn
        {
            HeaderText = "商品", DataPropertyName = "Product", FillWeight = 18,
        };
        productCol.DataSource = new List<string> { "键盘", "鼠标", "显示器", "内存条", "U盘" };
        _grid.Columns.Add(productCol);
        _grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "数量", DataPropertyName = "Qty", FillWeight = 12 });
        _grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "单价", DataPropertyName = "Price", FillWeight = 14, DefaultCellStyle = new DataGridViewCellStyle { Format = "C", Alignment = DataGridViewContentAlignment.MiddleRight } });
        _grid.Columns.Add(new DataGridViewCheckBoxColumn { HeaderText = "已付", DataPropertyName = "Paid", FillWeight = 10 });
        _grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = "合计", DataPropertyName = "Total", FillWeight = 14, ReadOnly = true, DefaultCellStyle = new DataGridViewCellStyle { Format = "C", Alignment = DataGridViewContentAlignment.MiddleRight, ForeColor = Color.DarkSlateBlue } });
        // 按钮列：事件在 CellContentClick 里认列处理
        _grid.Columns.Add(new DataGridViewButtonColumn { HeaderText = "操作", Text = "删除", UseColumnTextForButtonValue = true, FillWeight = 10 });

        // ═══ 15.3 校验：数量必须 1..99 ═══
        _grid.CellValidating += (s, e) =>
        {
            if (_grid.Columns[e.ColumnIndex].DataPropertyName != "Qty") return;
            if (!int.TryParse(e.FormattedValue?.ToString(), out int qty) || qty < 1 || qty > 99)
            {
                e.Cancel = true;                                   // 光标困在单元格里
                _grid.Rows[e.RowIndex].ErrorText = "数量必须是 1~99 的整数";
            }
        };
        _grid.CellEndEdit += (s, e) => _grid.Rows[e.RowIndex].ErrorText = null;

        // ═══ 15.4 条件着色：合计 ≥ 1000 的行底色提醒（反例分支必须显式恢复，否则滚动时残留）═══
        _grid.CellFormatting += (s, e) =>
        {
            if (e.RowIndex < 0 || _grid.Rows[e.RowIndex].DataBoundItem is not Order row) return;
            e.CellStyle.BackColor = row.Total >= 1000 ? Color.MistyRose : Color.White;
        };

        // ═══ 按钮列的点击 ═══
        _grid.CellContentClick += (s, e) =>
        {
            if (_grid.Columns[e.ColumnIndex] is DataGridViewButtonColumn &&
                _grid.Rows[e.RowIndex].DataBoundItem is Order doomed)
            {
                _orders.Remove(doomed);
                ApplyFilter();
            }
        };

        _sum.Dock = DockStyle.Bottom;
        _sum.Height = 30;
        _sum.BackColor = Color.Gainsboro;
        _sum.TextAlign = ContentAlignment.MiddleLeft;

        Controls.Add(_grid);
        Controls.Add(_sum);
        Controls.Add(filterBox);
        ApplyFilter();
    }

    // BindingList<T> 不支持 Filter——主从联动的朴素做法：换一个只装匹配项的视图列表
    private void ApplyFilter()
    {
        var view = new BindingList<Order>(_orders.Where(o => o.Customer == (string)_customer.SelectedItem).ToList());
        _source.DataSource = view;
        RefreshSum();
    }

    private void RefreshSum()
    {
        var view = (BindingList<Order>)_source.DataSource;
        _sum.Text = $"  当前列出 {view.Count} 单，合计 {view.Sum(o => o.Total):C}（改个数量试试，合计实时变）";
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
