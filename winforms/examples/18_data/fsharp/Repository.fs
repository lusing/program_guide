// 18 数据层（F#）：UI 只认识这个模块
module DataFs.Repository

open System.Data
open Microsoft.Data.Sqlite

type ContactRepository(dbPath: string) =

    let connString = SqliteConnectionStringBuilder(DataSource = dbPath).ToString()

    let exec (conn: SqliteConnection) sql =
        use cmd = conn.CreateCommand()
        cmd.CommandText <- sql
        cmd.ExecuteNonQuery()

    let scalar (conn: SqliteConnection) sql =
        use cmd = conn.CreateCommand()
        cmd.CommandText <- sql
        cmd.ExecuteScalar()

    do
        use conn = new SqliteConnection(connString)
        conn.Open()
        exec conn """
            CREATE TABLE IF NOT EXISTS contacts (
                id    INTEGER PRIMARY KEY AUTOINCREMENT,
                name  TEXT NOT NULL,
                phone TEXT NOT NULL,
                city  TEXT NOT NULL
            )""" |> ignore
        if scalar conn "SELECT COUNT(*) FROM contacts" |> string |> int = 0 then
            exec conn "INSERT INTO contacts (name, phone, city) VALUES ('林一', '13800000001', '北京')" |> ignore
            exec conn "INSERT INTO contacts (name, phone, city) VALUES ('陈二', '13800000002', '上海')" |> ignore
            exec conn "INSERT INTO contacts (name, phone, city) VALUES ('张三', '13800000003', '广州')" |> ignore

    /// 查询（参数化：值永远是值，绝不拼进 SQL 文本）
    member _.All(keyword: string) : DataTable =
        use conn = new SqliteConnection(connString)
        conn.Open()
        use cmd = conn.CreateCommand()
        cmd.CommandText <- """
            SELECT id, name, phone, city FROM contacts
            WHERE name LIKE @kw OR phone LIKE @kw OR city LIKE @kw
            ORDER BY id"""
        // F# 插值串里 % 是 printf 引导符：以 % 开头的模式用拼接更省心（或写 %%）
        let pattern = "%" + keyword + "%"
        cmd.Parameters.AddWithValue("@kw", pattern) |> ignore
        let table = DataTable()
        use reader = cmd.ExecuteReader()
        table.Load reader
        table

    member _.Add(name: string, phone: string, city: string) =
        use conn = new SqliteConnection(connString)
        conn.Open()
        use cmd = conn.CreateCommand()
        cmd.CommandText <- "INSERT INTO contacts (name, phone, city) VALUES (@n, @p, @c)"
        cmd.Parameters.AddWithValue("@n", name) |> ignore
        cmd.Parameters.AddWithValue("@p", phone) |> ignore
        cmd.Parameters.AddWithValue("@c", city) |> ignore
        cmd.ExecuteNonQuery()

    member _.Update(id: int64, name: string, phone: string, city: string) =
        use conn = new SqliteConnection(connString)
        conn.Open()
        use cmd = conn.CreateCommand()
        cmd.CommandText <- "UPDATE contacts SET name=@n, phone=@p, city=@c WHERE id=@id"
        cmd.Parameters.AddWithValue("@n", name) |> ignore
        cmd.Parameters.AddWithValue("@p", phone) |> ignore
        cmd.Parameters.AddWithValue("@c", city) |> ignore
        cmd.Parameters.AddWithValue("@id", id) |> ignore
        cmd.ExecuteNonQuery()

    member _.Delete(id: int64) =
        use conn = new SqliteConnection(connString)
        conn.Open()
        use cmd = conn.CreateCommand()
        cmd.CommandText <- "DELETE FROM contacts WHERE id=@id"
        cmd.Parameters.AddWithValue("@id", id) |> ignore
        cmd.ExecuteNonQuery()
