// 18 数据层（C# 类库，供 C++/CLI UI 调用）
using System.Data;
using Microsoft.Data.Sqlite;

namespace DataLib;

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

    /// 返回 DataTable——C++/CLI 侧直接能当 DataGridView 数据源用
    public DataTable All(string keyword)
    {
        using var conn = new SqliteConnection(_connString);
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            SELECT id, name, phone, city FROM contacts
            WHERE name LIKE @kw OR phone LIKE @kw OR city LIKE @kw
            ORDER BY id
            """;
        cmd.Parameters.AddWithValue("@kw", $"%{keyword}%");
        var table = new DataTable();
        table.Load(cmd.ExecuteReader());
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
        return cmd.ExecuteNonQuery();
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
        return cmd.ExecuteScalar();
    }
}
