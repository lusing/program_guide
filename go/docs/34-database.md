# 34 · 数据库接口：database/sql

> 对应示例：`examples/34_database/`。标准库定义接口、第三方驱动实现——示例里我们**自己写一个进程内驱动**，零外部依赖把 API 面全走一遍。

## 34.1 sql.DB：连接池，不是连接

```go
db, err := sql.Open("mysql", "user:pass@/db")   // 不连接！只构建池
defer db.Close()

db.Ping()                       // 真正建立连接（健康检查）
db.SetMaxOpenConns(25)          // 池上限（默认无限）
db.SetMaxIdleConns(25)          // 空闲保留数（默认 2）
db.SetConnMaxLifetime(5 * time.Minute)   // 连接最长服役（数据库端会踢闲置连接）

stats := db.Stats()             // OpenConnections / InUse / WaitCount …
```

`Open` 的两个参数：**驱动名**（驱动自己 `sql.Register` 时登记的）与**数据源串**（格式驱动自定，database/sql 不解析）。sql.DB 并发安全、全局一份——**每查询开一个 Open 是头号误用**。

## 34.2 驱动长什么样（示例里手写一个）

```go
// 驱动的最小骨架——实现 driver.Driver，包一个 init 注册
type memDriver struct{}
func (memDriver) Open(name string) (driver.Conn, error) { return &memConn{}, nil }

type memConn struct{}
func (c *memConn) Prepare(q string) (driver.Stmt, error) { ... }
func (c *memConn) Close() error { return nil }
func (c *memConn) Begin() (driver.Tx, error) { return memTx{}, nil }

type memStmt struct{ query string }
func (s *memStmt) NumInput() int            // 参数个数（? 的数量）
func (s *memStmt) Query(args []driver.Value) (driver.Rows, error) { ... }
func (s *memStmt) Exec(args []driver.Value) (driver.Result, error) { ... }

type memRows struct{ /* 列名 + 行数据 + 游标 */ }
func (r *memRows) Columns() []string
func (r *memRows) Next(dest []driver.Value) error   // 没数据了返回 io.EOF

func init() { sql.Register("mem", memDriver{}) }
db, _ := sql.Open("mem", "")   // 我们的"数据库"是进程内一个切片
```

真实项目用现成驱动（`go-sql-driver/mysql`、`jackc/pgx`、`mattn/go-sqlite3`、`modernc.org/sqlite`——纯 Go 无 cgo），import 进来触发 init 注册即可。手写一遍的意义：**看清 database/sql 与驱动的分工**——池化、超时、类型转换、事务语义全是标准库的，驱动只负责"执行 SQL、吐行"。

## 34.3 查询：Query / QueryRow / Scan

```go
rows, err := db.Query("SELECT id, name, age FROM users WHERE age >= ?", 18)
defer rows.Close()
for rows.Next() {                  // 一次推进一行（流式，不全进内存）
    var id, age int
    var name string
    if err := rows.Scan(&id, &name, &age); err != nil { ... }   // 列序对齐 SELECT
}
if err := rows.Err(); err != nil { ... }   // 迭代期的错误在这里！

var name string
err := db.QueryRow("SELECT name FROM users WHERE id = ?", 7).Scan(&name)
// 没查到：sql.ErrNoRows（errors.Is 判）——QueryRow 内部等首行，不返回 rows
```

**Scan 的参数顺序 = SELECT 列顺序**（结构体字段顺序帮不上忙）。`?` 占位符由驱动转义——**永远不 fmt.Sprintf 拼 SQL**（注入就是这么来的）。

## 34.4 NULL：NullX 或指针

```go
var nick sql.NullString
rows.Scan(&id, &nick)      // NULL → nick.Valid == false，不报错
// 或者直接用指针：var nick *string —— NULL → nil

// 写侧：实现 driver.Valuer 的自定义类型，或直接传 nil
db.Exec("UPDATE users SET nick = ?", nil)  // 置 NULL
```

NULL 扫进普通 `string`/`int` 直接报错 `converting NULL to string`——这是从别的语言过来的第一颗雷。

## 34.5 预备语句与事务

```go
stmt, err := db.Prepare("SELECT name FROM users WHERE id = ?")  // 编译一次
defer stmt.Close()
stmt.QueryRow(1) / stmt.QueryRow(2)      // 反复执行：省解析（驱动/服务端缓存）

tx, err := db.Begin()                    // 拿一条连接锁住直到提交
defer tx.Rollback()                      // 兜底：没 Commit 的 tx 一定回滚
tx.Exec("UPDATE accounts SET bal = bal - 100 WHERE id = ?", 1)
tx.Exec("UPDATE accounts SET bal = bal + 100 WHERE id = ?", 2)
if err := tx.Commit(); err != nil { ... } // 两步都成功才提交
```

事务三条路全走 `tx`（不是 db）——**混用 db.Exec 会掉出事务**。惯用法是 `defer tx.Rollback()` 永远挂着：Commit 成功后的 Rollback 返回 ErrTxDone，无害。

## 34.6 context 版本与速查

一切都有 ctx 版本（`QueryContext / ExecContext / BeginTx`）——18 章的取消链照常生效，超时自动释放连接。生产代码默认用 Context 版本。

| 需求 | 用 |
|---|---|
| 一行一值 | `QueryRow().Scan()`，`errors.Is(err, sql.ErrNoRows)` |
| 多行流式 | `Query` + `Next` + `Scan` + `Err` |
| NULL | `sql.NullString` / `*string` |
| 重复执行 | `Prepare` 复用 stmt |
| 原子多步 | `Begin` + 全走 tx + `Commit` |
| 健康检查 | `db.PingContext` |

## 34.7 坑位清单

1. **Open 当连接用**：它只建池——连接在第一次用时才建立；每请求 Open/Close 是反模式，全局一份。
2. **rows 没 Close**：连接回不了池，泄漏到上限全站等连接——`defer rows.Close()` 肌肉记忆。
3. **忘 rows.Err()**：迭代中途断连只表现为循环提前结束——循环后必查。
4. **NULL 扫进普通类型**：报 converting NULL——NullX/指针。
5. **fmt 拼 SQL**：注入洞——`?` 占位 + 参数。
6. **tx 里用 db.Exec**：掉出事务静默不原子——事务期全部走 tx。
7. **Commit 后又 Rollback 出错**：那是 ErrTxDone，无害——defer 兜底正为此设计。
8. **Scan 列序不匹配**：错位读值不报错（类型对得上时）——SELECT 写清列名，与 Scan 一一对齐。

---

---

上一章：[33 命令行与日志](33-flaglog.md) · 下一章：[35 底层窥视](35-unsafe.md)
