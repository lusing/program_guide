# 17 · EF Core：用 C# 对象操作数据

> 对应示例：`examples/17_efcore`

## 1. ORM 的直觉

没有 ORM：手写 SQL、手搬参数、手把行映射回对象——三段全是样板。EF Core（Entity Framework Core）让你**用 LINQ 表达查询、用对象属性表达变更**，翻译 SQL 的事交给它：

```csharp
var alice = db.Users.FirstOrDefault(x => x.Name == "Alice");
```

这行 LINQ（第 09 章的方法链）被 EF Core 翻译成 `SELECT TOP(1) … WHERE Name = 'Alice'`，结果自动装配成 User 对象。数据库表 ↔ C# 类，映射一次，处处受用。

## 2. 实体与上下文

示例的类型定义：

```csharp
public sealed class AppDbContext : DbContext
{
    public DbSet<User> Users => Set<User>();

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseInMemoryDatabase("GuideDotnetSamples");
}

public sealed class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}
```

- **实体（User）**：普通 C# 类。`Id` 约定为主键（自增）；`Name/Email` 用 `= string.Empty` 初始化——非可空属性不给默认值会触发 EF 的模型校验警告（第 10 章的契约在 ORM 层的延伸）。这里用 class 而非 record：EF 要能改属性（变更追踪需要 set），实体的身份语义（同一行同一个对象）也更像 class（第 05 章的选型判据）。
- **DbContext**：与数据库的一次会话。`DbSet<User>` 是"Users 表的句柄"，LINQ 从这里发起。一个请求/一次操作一个短命 DbContext 是惯例。
- `UseInMemoryDatabase("名字")`：**教学专用**的内存"数据库"——不落盘、无 SQL。生产换 `UseSqlServer/UseSqlite/UseNpgsql` 一行切换，本章代码风格不变。

## 3. CRUD 四式

示例的 Main 流程正好覆盖增查改查全流程：

```csharp
using var db = new AppDbContext();
db.Database.EnsureCreated();
```

`using`（DbContext 实现 IDisposable）确保会话结束释放；`EnsureCreated()` 按模型建库（教学用；生产用 Migrations，见 §5）。

**增**：

```csharp
if (!db.Users.Any())
{
    db.Users.AddRange(
        new User {Name = "Alice", Email = "alice@example.com"},
        new User {Name = "Bob", Email = "bob@example.com"}
    );
    db.SaveChanges();
}
```

`Add/AddRange` 只是登记"要插入"，**`SaveChanges` 才真正开事务写库**——所有登记在一个事务里批量提交。忘记 SaveChanges 是新手第一大坑（数据"莫名"没进去）。

**查**：

```csharp
var alice = db.Users.FirstOrDefault(x => x.Name == "Alice");
```

LINQ 被**翻译成 SQL 在数据库执行**（不是拉全表到内存再筛！）——`Where/OrderBy/Select/First…` 都有 SQL 对应物；翻译不了的算子（自定义方法体等）会抛"无法翻译"异常。想拉到内存再算：`.AsEnumerable()` 之后的 LINQ 就是本地求值。

**改**——注意没有 `Update` 调用：

```csharp
if (alice is not null)
{
    alice.Email = "alice@newmail.com";
    db.SaveChanges();
}
```

**变更追踪**（change tracking）是 EF 的核心机制：查出来的实体被上下文盯着，`SaveChanges` 时对比出"Email 变了"，生成精准的 `UPDATE … SET Email=…`。改属性 → SaveChanges，两步，没有 Update 调用。

**查全表**：

```csharp
var users = db.Users.OrderBy(x => x.Id).ToList();
Console.WriteLine($"users={users.Count}");
```

## 4. InMemory 的取舍

InMemory 提供程序把"数据库"放在进程内存里：快、零配置、适合本教程与部分单元测试。但它是**面向 .NET 对象的存储**而非关系数据库：不校验外键/唯一约束、不执行真实 SQL 语义、没有并发事务行为。测试"LINQ 翻译对不对、约束生效没有"要用 SQLite 内存库（`UseSqlite("DataSource=:memory:")`）或真库的测试容器。

## 5. EnsureCreated vs Migrations

`EnsureCreated()` 按当前模型一次性建库——简单粗暴，**模型变了它不会更新结构**（只对空库有效）。生产的正解是 Migrations：

```bash
dotnet ef migrations add Init       # 模型 → 迁移脚本（代码文件）
dotnet ef database update          # 应用迁移到库
```

迁移是版本化的数据库结构演进历史，可审阅、可回滚、团队共享。教程用 EnsureCreated 是为了零工具依赖；真实项目第一天就该上 Migrations。

## 6. 坑位清单

1. **忘 `SaveChanges`**：Add 之后不 Save，数据从未进库（还以为自己加了）。
2. **被追踪实体的"顺手修改"**：查出来的实体改了属性，之后**任何**一次 SaveChanges 都会把它写库——哪怕你以为只是临时改改。不想被追踪：`AsNoTracking()` 查询。
3. **N+1 查询**：循环里逐个 `db.Users.First(…)` 取关联数据 → 1 次查列表 + N 次查明细；关联数据用 `Include(x => x.Orders)` 一次 JOIN 回来。
4. **InMemory 测试通过 ≠ SQL 行为正确**：约束、事务、SQL 方言差异它全不模拟（§4）。
5. **LINQ 里塞 C# 方法**：`Where(x => Normalize(x.Name) == …)` 的自定义方法无法翻译成 SQL——报 InvalidOperationException；能翻译的只有表达式树可表达的算子。
