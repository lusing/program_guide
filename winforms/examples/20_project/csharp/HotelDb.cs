// 20 实战项目：数据访问层（SQLite + 参数化查询）
using Microsoft.Data.Sqlite;

namespace HotelApp;

public class HotelDb
{
    private readonly string _conn;

    public HotelDb(string dbPath)
    {
        _conn = new SqliteConnectionStringBuilder { DataSource = dbPath }.ToString();
        using var c = Open();
        Exec(c, """
            CREATE TABLE IF NOT EXISTS rooms (
                number   TEXT PRIMARY KEY,
                type     TEXT NOT NULL,
                price    REAL NOT NULL,
                occupied INTEGER NOT NULL DEFAULT 0
            );
            CREATE TABLE IF NOT EXISTS stays (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                room       TEXT NOT NULL,
                name       TEXT NOT NULL,
                phone      TEXT NOT NULL,
                checkin    TEXT NOT NULL,
                checkout   TEXT NOT NULL,
                checkedout INTEGER NOT NULL DEFAULT 0,
                roomprice  REAL NOT NULL
            )
            """);
        if (Count(c, "SELECT COUNT(*) FROM rooms") == 0)
        {
            var seed = new (string no, string type, decimal price)[]
            {
                ("101", "单人间", 199), ("102", "单人间", 199), ("103", "单人间", 209),
                ("201", "双人间", 299), ("202", "双人间", 299),
                ("301", "豪华套房", 699), ("302", "豪华套房", 799),
            };
            foreach (var (no, type, price) in seed)
                Exec(c, $"INSERT INTO rooms (number, type, price) VALUES ('{no}', '{type}', {price})");
        }
    }

    private SqliteConnection Open()
    {
        var c = new SqliteConnection(_conn);
        c.Open();
        return c;
    }

    // ── 客房 ──
    public List<Room> Rooms(bool? occupied = null)
    {
        using var c = Open();
        using var cmd = c.CreateCommand();
        cmd.CommandText = occupied is null
            ? "SELECT number, type, price, occupied FROM rooms ORDER BY number"
            : "SELECT number, type, price, occupied FROM rooms WHERE occupied=@o ORDER BY number";
        if (occupied is not null) cmd.Parameters.AddWithValue("@o", occupied.Value ? 1 : 0);
        var list = new List<Room>();
        using var r = cmd.ExecuteReader();
        while (r.Read())
            list.Add(new Room
            {
                Number = r.GetString(0),
                Type = r.GetString(1),
                Price = (decimal)r.GetDouble(2),
                Occupied = r.GetInt32(3) == 1,
            });
        return list;
    }

    // ── 入住 ──
    public long CheckIn(string room, string name, string phone)
    {
        using var c = Open();
        using (var cmd = c.CreateCommand())
        {
            cmd.CommandText = """
                INSERT INTO stays (room, name, phone, checkin, checkout, checkedout, roomprice)
                VALUES (@r, @n, @p, @ci, '', 0, (SELECT price FROM rooms WHERE number=@r))
                """;
            cmd.Parameters.AddWithValue("@r", room);
            cmd.Parameters.AddWithValue("@n", name);
            cmd.Parameters.AddWithValue("@p", phone);
            cmd.Parameters.AddWithValue("@ci", DateTime.Now.ToString("yyyy-MM-dd HH:mm"));
            cmd.ExecuteNonQuery();
        }
        Exec(c, "UPDATE rooms SET occupied=1 WHERE number=@r", ("@r", room));
        return LastId(c);
    }

    public List<StayRecord> ActiveStays()
    {
        using var c = Open();
        using var cmd = c.CreateCommand();
        cmd.CommandText = "SELECT id, room, name, phone, checkin, checkout, checkedout, roomprice FROM stays WHERE checkedout=0 ORDER BY id DESC";
        return ReadStays(cmd);
    }

    public List<StayRecord> Search(string keyword)
    {
        using var c = Open();
        using var cmd = c.CreateCommand();
        cmd.CommandText = """
            SELECT id, room, name, phone, checkin, checkout, checkedout, roomprice FROM stays
            WHERE name LIKE @kw OR phone LIKE @kw OR room LIKE @kw
            ORDER BY id DESC
            """;
        cmd.Parameters.AddWithValue("@kw", $"%{keyword}%");
        return ReadStays(cmd);
    }

    /// 退房结账：返回账单金额
    public decimal CheckOut(long stayId)
    {
        using var c = Open();
        StayRecord stay;
        using (var cmd = c.CreateCommand())
        {
            cmd.CommandText = "SELECT id, room, name, phone, checkin, checkout, checkedout, roomprice FROM stays WHERE id=@id";
            cmd.Parameters.AddWithValue("@id", stayId);
            stay = ReadStays(cmd).Single();
        }
        var now = DateTime.Now;
        var nights = Math.Max(1, (int)Math.Ceiling((now - stay.CheckIn).TotalDays));
        decimal bill = nights * stay.RoomPrice;

        using (var cmd = c.CreateCommand())
        {
            cmd.CommandText = "UPDATE stays SET checkout=@co, checkedout=1 WHERE id=@id";
            cmd.Parameters.AddWithValue("@co", now.ToString("yyyy-MM-dd HH:mm"));
            cmd.Parameters.AddWithValue("@id", stayId);
            cmd.ExecuteNonQuery();
        }
        Exec(c, "UPDATE rooms SET occupied=0 WHERE number=@r", ("@r", stay.RoomNumber));
        return bill;
    }

    private static List<StayRecord> ReadStays(SqliteCommand cmd)
    {
        var list = new List<StayRecord>();
        using var r = cmd.ExecuteReader();
        while (r.Read())
        {
            var checkIn = DateTime.Parse(r.GetString(4));
            var checkOutStr = r.IsDBNull(5) || r.GetString(5).Length == 0 ? DateTime.Now : DateTime.Parse(r.GetString(5));
            list.Add(new StayRecord
            {
                Id = r.GetInt64(0),
                RoomNumber = r.GetString(1),
                GuestName = r.GetString(2),
                Phone = r.GetString(3),
                CheckIn = checkIn,
                CheckOut = checkOutStr,
                CheckedOut = r.GetInt32(6) == 1,
                RoomPrice = (decimal)r.GetDouble(7),
            });
        }
        return list;
    }

    // ── 工具 ──
    private static void Exec(SqliteConnection c, string sql, params (string, object)[] ps)
    {
        using var cmd = c.CreateCommand();
        cmd.CommandText = sql;
        foreach (var (k, v) in ps)
            cmd.Parameters.AddWithValue(k, v);
        cmd.ExecuteNonQuery();
    }

    private static long Count(SqliteConnection c, string sql)
    {
        using var cmd = c.CreateCommand();
        cmd.CommandText = sql;
        return (long)cmd.ExecuteScalar();
    }

    private static long LastId(SqliteConnection c)
    {
        using var cmd = c.CreateCommand();
        cmd.CommandText = "SELECT last_insert_rowid()";
        return (long)cmd.ExecuteScalar();
    }
}
