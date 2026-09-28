// 18 SQLite 与 ADO.NET：建库建表、参数化查询、DataReader、三层雏形
using System.Data;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.Data.Sqlite;

namespace DataWin;

// ═══ 18.4 数据层：UI 只认识这个类（三层雏形里的 DAL+一点业务）═══
public class ContactRepository
{
    private readonly string _connString;

    public ContactRepository(string dbPath)
    {
        _connString = new SqliteConnectionStringBuilder { DataSource = dbPath }.ToString();
        using var conn = new SqliteConnection(_connString);
        conn.Open();
        Exec(conn, """
            CREATE TABLE IF NOT EXISTS contacts (
                id    INTEGER PRIMARY KEY AUTOINCREMENT,
                name  TEXT NOT NULL,
                phone TEXT NOT NULL,
                city  TEXT NOT NULL
            )
            """);
        if (Convert.ToInt64(Scalar(conn, "SELECT COUNT(*) FROM contacts")) == 0)
        {
            Exec(conn, "INSERT INTO contacts (name, phone, city) VALUES ('林一', '13800000001', '北京')");
            Exec(conn, "INSERT INTO contacts (name, phone, city) VALUES ('陈二', '13800000002', '上海')");
            Exec(conn, "INSERT INTO contacts (name, phone, city) VALUES ('张三', '13800000003', '广州')");
        }
    }

    public DataTable All(string keyword)
    {
        using var conn = new SqliteConnection(_connString);
        conn.Open();
        // ═══ 18.2 参数化查询：值永远是值，绝不拼进 SQL 文本 ═══
        using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT id, name, phone, city FROM contacts
            WHERE name LIKE @kw OR phone LIKE @kw OR city LIKE @kw
            ORDER BY id
            """;
        cmd.Parameters.AddWithValue("@kw", $"%{keyword}%");
        var table = new DataTable();
        using var reader = cmd.ExecuteReader();      // DataReader：一行一行向前读
        table.Load(reader);                          // Load 把 reader 全量灌进 DataTable（列名/类型自动）
        return table;
    }

    public int Add(string name, string phone, string city)
    {
        using var conn = new SqliteConnection(_connString);
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = "INSERT INTO contacts (name, phone, city) VALUES (@n, @p, @c)";
        cmd.Parameters.AddWithValue("@n", name);
        cmd.Parameters.AddWithValue("@p", phone);
        cmd.Parameters.AddWithValue("@c", city);
        return cmd.ExecuteNonQuery();                // 增删改都用 ExecuteNonQuery（返回受影响行数）
    }

    public int Update(long id, string name, string phone, string city)
    {
        using var conn = new SqliteConnection(_connString);
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = "UPDATE contacts SET name=@n, phone=@p, city=@c WHERE id=@id";
        cmd.Parameters.AddWithValue("@n", name);
        cmd.Parameters.AddWithValue("@p", phone);
        cmd.Parameters.AddWithValue("@c", city);
        cmd.Parameters.AddWithValue("@id", id);
        return cmd.ExecuteNonQuery();
    }

    public int Delete(long id)
    {
        using var conn = new SqliteConnection(_connString);
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = "DELETE FROM contacts WHERE id=@id";
        cmd.Parameters.AddWithValue("@id", id);
        return cmd.ExecuteNonQuery();
    }

    private static void Exec(SqliteConnection conn, string sql)
    {
        using var cmd = conn.CreateCommand();
        cmd.CommandText = sql;
        cmd.ExecuteNonQuery();
    }

    private static object Scalar(SqliteConnection conn, string sql)
    {
        using var cmd = conn.CreateCommand();
        cmd.CommandText = sql;
        return cmd.ExecuteScalar();                  // 单值查询（COUNT 等）
    }
}

internal class MainForm : Form
{
    private readonly ContactRepository _repo;
    private readonly DataGridView _grid = new();
    private readonly TextBox _name = new();
    private readonly TextBox _phone = new();
    private readonly TextBox _city = new();
    private readonly TextBox _search = new();
    private readonly Label _status = new();
    private long _selectedId;

    public MainForm()
    {
        Text = "通讯录（SQLite）";
        ClientSize = new Size(700, 480);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("微软雅黑", 10F);

        string db = Path.Combine(Path.GetTempPath(), "winforms18.db");
        _repo = new ContactRepository(db);

        var editor = new GroupBox { Text = " 联系人（先在表格里选中一行，再编辑/删除）", Dock = DockStyle.Top, Height = 120 };
        editor.Controls.Add(Caption("姓名：", 30));
        Field(_name, 30);
        editor.Controls.Add(Caption("电话：", 66));
        Field(_phone, 66);
        editor.Controls.Add(Caption("城市：", 102));
        Field(_city, 102);

        var add = new Button { Text = "新增", Location = new Point(430, 26), AutoSize = true };
        var upd = new Button { Text = "保存修改", Location = new Point(510, 26), AutoSize = true };
        var del = new Button { Text = "删除选中", Location = new Point(430, 60), AutoSize = true };
        add.Click += (s, e) => { _repo.Add(_name.Text, _phone.Text, _city.Text); Reload("已新增"); };
        upd.Click += (s, e) =>
        {
            if (_selectedId == 0) { Say("先在表格里选中一行"); return; }
            _repo.Update(_selectedId, _name.Text, _phone.Text, _city.Text);
            Reload("已修改");
        };
        del.Click += (s, e) =>
        {
            if (_selectedId == 0) { Say("先在表格里选中一行"); return; }
            _repo.Delete(_selectedId);
            Reload("已删除");
        };
        editor.Controls.AddRange(new Control[] { add, upd, del });

        var searchBox = new GroupBox { Text = " 搜索（参数化——试试输入 ' OR '1'='1 也只是当普通文本）", Dock = DockStyle.Top, Height = 70 };
        _search.SetBounds(16, 28, 240, 30);
        var go = new Button { Text = "查", Location = new Point(270, 26), AutoSize = true };
        go.Click += (s, e) => Reload(null);
        _search.KeyDown += (s, e) => { if (e.KeyCode == Keys.Enter) Reload(null); };
        searchBox.Controls.AddRange(new Control[] { _search, go });

        _grid.Dock = DockStyle.Fill;
        _grid.ReadOnly = true;
        _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        _grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        _grid.AllowUserToAddRows = false;
        _grid.CellClick += (s, e) =>
        {
            if (e.RowIndex < 0) return;
            var row = _grid.Rows[e.RowIndex];
            _selectedId = (long)row.Cells["id"].Value;
            _name.Text = (string)row.Cells["name"].Value;
            _phone.Text = (string)row.Cells["phone"].Value;
            _city.Text = (string)row.Cells["city"].Value;
        };

        _status.Dock = DockStyle.Bottom;
        _status.Height = 30;
        _status.BackColor = Color.Gainsboro;

        Controls.Add(_grid);
        Controls.Add(searchBox);
        Controls.Add(editor);
        Controls.Add(_status);
        Reload(null);
        Say($"数据库：{db}");
    }

    private static Label Caption(string text, int y) =>
        new() { Text = text, AutoSize = true, Location = new Point(16, y + 4) };

    private static void Field(TextBox box, int y)
    {
        box.Location = new Point(70, y);
        box.Width = 200;
    }

    private void Reload(string message)
    {
        _grid.DataSource = _repo.All(_search.Text.Trim());
        if (_grid.Columns.Contains("id")) _grid.Columns["id"].FillWeight = 15;
        _selectedId = 0;
        if (message != null) Say($"{message}，当前 {_grid.RowCount} 条");
    }

    private void Say(string msg) => _status.Text = "  " + msg;
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
