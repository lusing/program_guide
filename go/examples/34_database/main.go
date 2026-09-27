// 34_database：手写进程内驱动（零依赖），把 database/sql 的 API 面全走一遍。
// 对照 docs/34-database.md。
package main

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"errors"
	"fmt"
	"io"
	"strings"
	"sync"
)

// ---------- 进程内的"表" ----------

// User 是一行数据；Nick 可空（演示 NULL）。
type User struct {
	ID   int64
	Name string
	Age  int64
	Nick *string // nil = NULL
}

var (
	mu    sync.Mutex
	users = []User{
		{1, "ada", 36, addr("数学女王")},
		{2, "linus", 55, nil},
		{3, "grace", 45, addr("海军上将")},
	}
	nextID = int64(4)
)

func addr(s string) *string { return &s }

// resetTable 测试隔离用：每个用例从同一份数据出发（表是进程内全局的）。
func resetTable() {
	mu.Lock()
	defer mu.Unlock()
	users = []User{
		{1, "ada", 36, addr("数学女王")},
		{2, "linus", 55, nil},
		{3, "grace", 45, addr("海军上将")},
	}
	nextID = 4
}

// ---------- driver.Driver / Conn ----------

type memDriver struct{}

func (memDriver) Open(string) (driver.Conn, error) { return &memConn{}, nil }

type memConn struct {
	snapshot []User // Begin 时拍快照；Rollback 恢复——真数据库的回滚语义
}

func (c *memConn) Prepare(q string) (driver.Stmt, error) { return &memStmt{query: q}, nil }
func (c *memConn) Close() error                          { return nil }
func (c *memConn) Begin() (driver.Tx, error) {
	mu.Lock()
	defer mu.Unlock()
	c.snapshot = append([]User(nil), users...)
	return memTx{conn: c}, nil
}

// Ping 实现 driver.Pinger：db.Ping() 不用碰查询路径。
func (c *memConn) Ping(context.Context) error { return nil }

type memTx struct{ conn *memConn }

func (t memTx) Commit() error { t.conn.snapshot = nil; return nil }
func (t memTx) Rollback() error {
	mu.Lock()
	defer mu.Unlock()
	if t.conn.snapshot != nil {
		users = t.conn.snapshot // 未提交的写入一笔勾销
		t.conn.snapshot = nil
	}
	return nil
}

// ---------- driver.Stmt ----------

type memStmt struct{ query string }

func (s *memStmt) Close() error  { return nil }
func (s *memStmt) NumInput() int { return strings.Count(s.query, "?") }
func (s *memStmt) Exec(args []driver.Value) (driver.Result, error) {
	mu.Lock()
	defer mu.Unlock()
	if !strings.HasPrefix(s.query, "INSERT") {
		return nil, fmt.Errorf("不支持的语句: %s", s.query)
	}
	name, _ := args[0].(string)
	age, _ := args[1].(int64)
	users = append(users, User{ID: nextID, Name: name, Age: age, Nick: nil})
	nextID++
	return memResult{rows: 1, lastID: nextID - 1}, nil
}

func (s *memStmt) Query(args []driver.Value) (driver.Rows, error) {
	mu.Lock()
	defer mu.Unlock()

	q := s.query
	// 列清单（教学级解析：SELECT a, b FROM ...，不认 * 和 JOIN）
	cols := []string{"id", "name", "age", "nick"}
	if i := strings.Index(q, " FROM "); i >= 0 {
		cols = nil
		for _, c := range strings.Split(strings.TrimPrefix(q[:i], "SELECT "), ",") {
			cols = append(cols, strings.TrimSpace(c))
		}
	}
	filterID, hasID := int64(-1), false
	minAge := int64(0)
	if strings.Contains(q, "WHERE id = ?") {
		filterID, hasID = args[0].(int64)
	} else if strings.Contains(q, "WHERE age >= ?") {
		minAge, _ = args[0].(int64)
	}

	rows := &memRows{cols: cols}
	for _, u := range users {
		if hasID && u.ID != filterID {
			continue
		}
		if u.Age < minAge {
			continue
		}
		rows.rows = append(rows.rows, project(u, cols))
	}
	return rows, nil
}

// project 把一行 User 按列清单展开成 driver.Value（nil = NULL）。
func project(u User, cols []string) []driver.Value {
	out := make([]driver.Value, len(cols))
	for i, c := range cols {
		switch c {
		case "id":
			out[i] = u.ID
		case "name":
			out[i] = u.Name
		case "age":
			out[i] = u.Age
		case "nick":
			if u.Nick != nil {
				out[i] = *u.Nick
			}
		}
	}
	return out
}

// ---------- driver.Rows ----------

type memRows struct {
	cols []string
	rows [][]driver.Value
	i    int
}

func (r *memRows) Columns() []string { return r.cols }
func (r *memRows) Close() error      { return nil }
func (r *memRows) Next(dest []driver.Value) error {
	if r.i >= len(r.rows) {
		return io.EOF // 迭代结束的约定信号
	}
	copy(dest, r.rows[r.i])
	r.i++
	return nil
}

type memResult struct{ rows, lastID int64 }

func (r memResult) LastInsertId() (int64, error) { return r.lastID, nil }
func (r memResult) RowsAffected() (int64, error) { return r.rows, nil }

func init() { sql.Register("mem", memDriver{}) }

// ---------- database/sql 的用法面 ----------

// Adults 查成年用户（Query + Next + Scan 流式）。
func Adults(db *sql.DB, minAge int64) ([]User, error) {
	rows, err := db.Query("SELECT id, name, age, nick FROM users WHERE age >= ?", minAge)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []User
	for rows.Next() {
		var u User
		var nick sql.NullString
		if err := rows.Scan(&u.ID, &u.Name, &u.Age, &nick); err != nil {
			return nil, err
		}
		if nick.Valid {
			u.Nick = addr(nick.String)
		}
		out = append(out, u)
	}
	return out, rows.Err() // 迭代期的错误在循环之后查
}

// NameByID 单行查询：QueryRow + ErrNoRows。
func NameByID(db *sql.DB, id int64) (string, error) {
	var name string
	err := db.QueryRow("SELECT name FROM users WHERE id = ?", id).Scan(&name)
	return name, err
}

func main() {
	db, err := sql.Open("mem", "")
	if err != nil {
		fmt.Println("Open:", err)
		return
	}
	defer db.Close()
	db.SetMaxOpenConns(1) // 演示用：池上限 1

	if err := db.Ping(); err != nil {
		fmt.Println("Ping:", err)
		return
	}

	fmt.Println("== Query：流式 + NULL 用 NullString ==")
	adults, err := Adults(db, 40)
	if err != nil {
		fmt.Println("Adults:", err)
		return
	}
	for _, u := range adults {
		nick := "NULL"
		if u.Nick != nil {
			nick = *u.Nick
		}
		fmt.Printf("  id=%d %-6s age=%d nick=%s\n", u.ID, u.Name, u.Age, nick)
	}

	fmt.Println("== QueryRow：没查到是 sql.ErrNoRows ==")
	if name, err := NameByID(db, 2); err == nil {
		fmt.Println("  id=2 →", name)
	}
	if _, err := NameByID(db, 99); err != nil {
		fmt.Println("  id=99 →", err, "/ errors.Is ErrNoRows:", errors.Is(err, sql.ErrNoRows))
	}

	fmt.Println("== Prepare：编译一次反复执行 ==")
	stmt, err := db.Prepare("SELECT name FROM users WHERE id = ?")
	if err != nil {
		fmt.Println("Prepare:", err)
		return
	}
	defer stmt.Close()
	for _, id := range []int64{1, 3} {
		var name string
		if err := stmt.QueryRow(id).Scan(&name); err == nil {
			fmt.Printf("  id=%d → %s\n", id, name)
		}
	}

	fmt.Println("== Exec：INSERT 拿 RowsAffected / LastInsertId ==")
	res, err := db.Exec("INSERT INTO users (name, age) VALUES (?, ?)", "ken", 70)
	if err != nil {
		fmt.Println("Exec:", err)
		return
	}
	n, _ := res.RowsAffected()
	id, _ := res.LastInsertId()
	fmt.Printf("  插入成功：影响 %d 行，新 id=%d\n", n, id)
	all, _ := Adults(db, 0)
	fmt.Println("  现在", len(all), "个用户")

	fmt.Println("== 事务：Begin 后全走 tx ==")
	tx, err := db.Begin()
	if err != nil {
		fmt.Println("Begin:", err)
		return
	}
	defer tx.Rollback() // 兜底：Commit 成功后这里返回 ErrTxDone，无害
	if _, err := tx.Exec("INSERT INTO users (name, age) VALUES (?, ?)", "tmp", 1); err != nil {
		fmt.Println("tx.Exec:", err)
		return
	}
	if err := tx.Commit(); err != nil {
		fmt.Println("Commit:", err)
		return
	}
	fmt.Println("  提交成功（defer 的 Rollback 会拿到 ErrTxDone，无害）")

	fmt.Println("== Stats：池的体检 ==")
	st := db.Stats()
	fmt.Printf("  OpenConnections=%d InUse=%d Idle=%d\n", st.OpenConnections, st.InUse, st.Idle)
}
