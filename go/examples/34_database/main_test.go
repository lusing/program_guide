package main

import (
	"database/sql"
	"errors"
	"testing"
)

func openMem(t *testing.T) *sql.DB {
	t.Helper()
	resetTable()
	db, err := sql.Open("mem", "")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	return db
}

func TestAdultsFilter(t *testing.T) {
	db := openMem(t)
	got, err := Adults(db, 46) // 只有 55 岁的 linus
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 1 || got[0].Name != "linus" || got[0].Nick != nil {
		t.Errorf("Adults(46) = %+v", got)
	}
}

func TestNullScan(t *testing.T) {
	db := openMem(t)
	got, err := Adults(db, 0)
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 3 {
		t.Fatalf("应有 3 行，got %d", len(got))
	}
	if got[0].Nick == nil || *got[0].Nick != "数学女王" {
		t.Errorf("ada 的 nick 应非 NULL，got %v", got[0].Nick)
	}
	if got[1].Nick != nil {
		t.Errorf("linus 的 nick 应为 NULL，got %v", *got[1].Nick)
	}
}

func TestNameByIDErrNoRows(t *testing.T) {
	db := openMem(t)
	name, err := NameByID(db, 1)
	if err != nil || name != "ada" {
		t.Errorf("NameByID(1) = (%q,%v)", name, err)
	}
	if _, err := NameByID(db, 100); !errors.Is(err, sql.ErrNoRows) {
		t.Errorf("应得 sql.ErrNoRows，got %v", err)
	}
}

func TestInsertAndCount(t *testing.T) {
	db := openMem(t)
	res, err := db.Exec("INSERT INTO users (name, age) VALUES (?, ?)", "ken", 70)
	if err != nil {
		t.Fatal(err)
	}
	if n, _ := res.RowsAffected(); n != 1 {
		t.Errorf("RowsAffected = %d, want 1", n)
	}
	if id, _ := res.LastInsertId(); id != 4 {
		t.Errorf("LastInsertId = %d, want 4", id)
	}
	got, err := Adults(db, 0)
	if err != nil || len(got) != 4 {
		t.Errorf("插入后应 4 行，got (%d,%v)", len(got), err)
	}
}

func TestTransactionCommit(t *testing.T) {
	db := openMem(t)
	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	if _, err := tx.Exec("INSERT INTO users (name, age) VALUES (?, ?)", "tx1", 1); err != nil {
		t.Fatal(err)
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	got, _ := Adults(db, 0)
	if len(got) != 4 {
		t.Errorf("提交后应 4 行，got %d", len(got))
	}
}

func TestTransactionRollback(t *testing.T) {
	db := openMem(t)
	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := tx.Exec("INSERT INTO users (name, age) VALUES (?, ?)", "ghost", 1); err != nil {
		t.Fatal(err)
	}
	if err := tx.Rollback(); err != nil {
		t.Fatal(err)
	}
	got, _ := Adults(db, 0)
	if len(got) != 3 {
		t.Errorf("回滚后应仍 3 行，got %d", len(got))
	}
}

func TestPingAndStats(t *testing.T) {
	db := openMem(t)
	if err := db.Ping(); err != nil {
		t.Fatal(err)
	}
	if st := db.Stats(); st.OpenConnections < 1 {
		t.Errorf("Ping 后应有连接，got %+v", st)
	}
}
