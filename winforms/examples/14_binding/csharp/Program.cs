// 14 数据绑定：DataBindings、INotifyPropertyChanged、BindingSource/BindingList、Format
using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;

namespace BindingWin;

// ═══ 14.1 可通知的模型：属性一变就广播 ═══
public class Person : INotifyPropertyChanged
{
    private string _name = "";
    private int _age;
    private string _email = "";

    public string Name
    {
        get => _name;
        set { if (_name != value) { _name = value; OnPropertyChanged(nameof(Name)); } }
    }
    public int Age
    {
        get => _age;
        set { if (_age != value) { _age = value; OnPropertyChanged(nameof(Age)); } }
    }
    public string Email
    {
        get => _email;
        set { if (_email != value) { _email = value; OnPropertyChanged(nameof(Email)); } }
    }

    public event PropertyChangedEventHandler PropertyChanged;

    private void OnPropertyChanged(string name) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}

internal class MainForm : Form
{
    private readonly BindingSource _source = new();
    private readonly TextBox _name = new();
    private readonly NumericUpDown _age = new();
    private readonly TextBox _email = new();
    private readonly Label _ageEcho = new();
    private readonly DataGridView _grid = new();

    public MainForm()
    {
        Text = "数据绑定";
        ClientSize = new Size(680, 520);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        // ═══ 14.2 数据源：BindingList 装进 BindingSource ═══
        var people = new BindingList<Person>
        {
            new() { Name = "林一", Age = 28, Email = "linyi@example.com" },
            new() { Name = "陈二", Age = 35, Email = "chener@example.com" },
            new() { Name = "张三", Age = 41, Email = "zhangsan@example.com" },
        };
        _source.DataSource = people;

        // ═══ 14.3 表单区：控件 ← 当前对象（双向）═══
        var form = new GroupBox { Text = " 当前人员（编辑后看表格同步刷新）", Dock = DockStyle.Top, Height = 150 };
        var nl = new Label { Text = "姓名：", AutoSize = true, Location = new Point(16, 32) };
        _name.SetBounds(90, 28, 160, 30);
        _name.DataBindings.Add("Text", _source, "Name");          // 控件属性, 数据源, 属性路径

        var al = new Label { Text = "年龄：", AutoSize = true, Location = new Point(16, 70) };
        _age.SetBounds(90, 66, 90, 30);
        _age.DataBindings.Add("Value", _source, "Age");

        var el = new Label { Text = "邮箱：", AutoSize = true, Location = new Point(16, 108) };
        _email.SetBounds(90, 104, 200, 30);
        _email.DataBindings.Add("Text", _source, "Email");

        // ═══ 14.4 Format：绑定时给值做展示层转换 ═══
        _ageEcho.AutoSize = true;
        _ageEcho.Location = new Point(310, 70);
        var echoBinding = new Binding("Text", _source, "Age");
        echoBinding.Format += (s, e) => e.Value = $"{e.Value} 岁（Format 事件加工）";
        echoBinding.Parse += (s, e) => { };                        // 只读回显，Parse 留空
        _ageEcho.DataBindings.Add(echoBinding);

        form.Controls.AddRange(new Control[] { nl, _name, al, _age, el, _email, _ageEcho });

        // ═══ 14.5 导航条：BindingSource.Position 是一切的中心 ═══
        var nav = new BindingNavigator(_source) { Dock = DockStyle.Top };   // 白送的导航条
        var add = new Button { Text = "＋新增人员", Dock = DockStyle.Top, Height = 32 };
        add.Click += (s, e) =>
        {
            _source.Add(new Person { Name = "新人员", Age = 20, Email = "" });
            _source.Position = _source.Count - 1;                  // 跳到刚加的
        };

        // ═══ 表格：同一个 BindingSource ═══
        _grid.Dock = DockStyle.Fill;
        _grid.DataSource = _source;
        _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        _grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;

        Controls.Add(_grid);
        Controls.Add(add);
        Controls.Add(nav);
        Controls.Add(form);
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
