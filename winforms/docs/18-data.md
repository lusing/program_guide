# 18 · SQLite 与 ADO.NET：参数化查询与三层雏形

> 对应示例：`examples/18_data`（通讯录：建库 + 增删改查 + 搜索 + 注入免疫演示；cpp 目录是 C# 数据层 + C++/CLI UI 的混合方案）

> **本章你将学会**：SQLite 建库建表、参数化查询防注入、DataReader/ExecuteScalar/ExecuteNonQuery、三层雏形、C++/CLI 调 C# 类库。
> **前置章节**：[15 DataGridView](15-datagridview.md)。泛化的数据访问见 [dotnet 22 章](../../dotnet/docs/22-networking.md)的分层讨论与 [17 章 EF Core](../../dotnet/docs/17-efcore.md)。

## 1. 为什么是 SQLite

教材（书的第 6 章）用 SQL Server + `System.Data.SqlClient`——读者得先装数据库服务。现代轻量正解是 **SQLite**（单文件库、零安装）+ `Microsoft.Data.Sqlite`（NuGet：`dotnet add package Microsoft.Data.Sqlite`，本教程钉 10.0.0）。**ADO.NET 的形状没变**：Connection → Command → Reader 三件套，换库只换类名前缀。

```csharp
_connString = new SqliteConnectionStringBuilder { DataSource = dbPath }.ToString();
using var conn = new SqliteConnection(_connString);   // using：连接即资源
conn.Open();
```

## 2. 建库建表 + 首次播种

```csharp
Exec(conn, """
    CREATE TABLE IF NOT EXISTS contacts (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name  TEXT NOT NULL,
        phone TEXT NOT NULL,
        city  TEXT NOT NULL
    )
    """);
if (Convert.ToInt64(Scalar(conn, "SELECT COUNT(*) FROM contacts")) == 0)
{ …插入三条种子数据… }
```

`CREATE TABLE IF NOT EXISTS` + 计数判断 = 打开就绪的"自建库"模式（18 示例把库放 `%TEMP%`）。

## 3. 参数化查询：防注入的正解

```csharp
cmd.CommandText = """
    SELECT id, name, phone, city FROM contacts
    WHERE name LIKE @kw OR phone LIKE @kw OR city LIKE @kw
    ORDER BY id
    """;
cmd.Parameters.AddWithValue("@kw", $"%{keyword}%");   // ★ 值是值，永远是值
```

`@kw` 是占位符，用户输入**永远不拼进 SQL 文本**。18 示例的搜索框欢迎你输入 `' OR '1'='1`——它会被当成 9 个普通字符去 LIKE 匹配，查不到任何东西（状态栏照常汇报 0 条）。**拼接字符串进 SQL 是教科书级漏洞**：老教材"字符串拼接查询"的示例代码在现实里就是注入事故。

## 4. Command 的三种执行

| 方法 | 返回 | 场景 |
|---|---|---|
| `ExecuteReader()` | `DataReader`（向前只读游标） | SELECT 多行 |
| `ExecuteNonQuery()` | 受影响行数 | INSERT/UPDATE/DELETE |
| `ExecuteScalar()` | 单个值（object） | COUNT、查单个字段 |

```csharp
var table = new DataTable();
using var reader = cmd.ExecuteReader();
table.Load(reader);            // reader 全量灌进 DataTable → 直接当 DataGridView 数据源
```

`table.Load(reader)` 是"多行结果 → 可绑定表格"的最短路径（15 章绑定复习）。

## 5. 三层雏形

18 示例的工程结构就是三层的最小样：

```text
UI（窗体、事件处理器）
  └─ 只认识 ContactRepository 的公开方法（Add/Update/Delete/All）
       └─ 只认识 SQL 与连接串（DAL）
            └─ SQLite 文件
```

好处在改动半径：换数据库只动 Repository；改界面不碰 SQL。[20 章](20-project.md)把这个雏形长成完整的客房管理系统。

## 6. C++/CLI 的混合方案（本章特色）

C++/CLI 工程吃 NuGet 很别扭（vcxproj 的包还原链路不可靠）——**正统做法：数据层独立成 C# 类库，C++ 侧只 ProjectReference 它**：

```text
cpp/
├── datalib/
│   ├── DataLib.csproj        net10.0-windows 类库 + Microsoft.Data.Sqlite
│   └── Repository.cs         public class ContactRepository（与 C# 版同款）
├── DataCpp.vcxproj           C++/CLI UI：using namespace DataLib;
└── host/
    └── DataHost.csproj       启动器
```

C++ 侧用起来与 C# 无异：

```cpp
using namespace DataLib;
_repo = gcnew ContactRepository(db);
_grid->DataSource = _repo->All(_search->Text->Trim());
```

**实测坑（本教程踩过）**：`host → vcxproj → DataLib.csproj` 的引用链**不会把 NuGet 依赖传递到最终 exe**——deps.json 里 Microsoft.Data.Sqlite 缺席，运行时 `FileNotFoundException` 崩溃。修法：**包在最终输出工程（host）上再声明一次**。教训：混合链路里，运行时依赖要对"最终 exe"负责。

## 7. 三语言差异

F# 版把数据层放独立文件 `Repository.fs`（`module DataFs.Repository`），构造函数里 `do` 建库播种——与 UI 文件物理分层。注意 F# 的 LIKE 模式：

```fsharp
// F# 插值串里 % 是 printf 引导符：以 % 开头的模式用拼接
let pattern = "%" + keyword + "%"
cmd.Parameters.AddWithValue("@kw", pattern) |> ignore
```

（写 `$"%%{keyword}%%"` 也行——`%%` 是转义的百分号。）

## 坑位清单

1. `AddWithValue` 拼进 SQL 文本 → 注入；占位符 + Parameters 是唯一正解。
2. 连接不复用也不 `using` → 句柄泄漏；每批操作一个 `using var conn` 开关。
3. `ExecuteScalar` 返回 object 直接 `is 0` 比较 → 装箱的 long 与 int 恒不等；`Convert.ToInt64`。
4. 混合链路（vcxproj 中转 csproj）的 NuGet 依赖不流动 → 最终 exe 再声明一次包。
5. F# `$"%{kw}%"` → FS3376；用拼接或 `%%`。

## 自测

1. ADO.NET 三件套是什么？SQLite 版与教材的 SqlClient 版形状差多少？
2. `' OR '1'='1` 在参数化查询里的下场？
3. 三种 Execute 各自的返回与场景？
4. `DataTable.Load(reader)` 替你做了什么？
5. C++/CLI 的混合方案里，NuGet 包为什么要在 host 上声明两次？（链路原因）

---

上一章：[17 文件 IO 与加密](17-io-crypto.md) · 下一章：[19 发布与部署](19-publish.md)
