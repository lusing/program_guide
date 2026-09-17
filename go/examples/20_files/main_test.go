package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCountLines(t *testing.T) {
	if n, err := CountLines(strings.NewReader("a\nb\nc\n")); err != nil || n != 3 {
		t.Errorf("三行 = (%d,%v)", n, err)
	}
	if n, err := CountLines(strings.NewReader("没有换行")); err != nil || n != 1 {
		t.Errorf("无换行 (%d,%v)", n, err)
	}
	// 2 MiB 的单行：Scanner 默认 64KiB 上限会报错，CountLines 调过 Buffer 才能扛住
	long := strings.Repeat("x", 2<<20)
	if n, err := CountLines(strings.NewReader(long)); err != nil || n != 1 {
		t.Errorf("超长行 (%d,%v)", n, err)
	}
}

func TestWriteThenRead(t *testing.T) {
	path := filepath.Join(t.TempDir(), "demo.txt")
	if err := WriteThenRead(path); err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if got := strings.Count(string(b), "\n"); got != 3 {
		t.Errorf("文件应有 3 个换行, got %d", got)
	}
}

func TestWalkGoFiles(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "a.go"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "b.txt"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	sub := filepath.Join(dir, "sub")
	if err := os.Mkdir(sub, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(sub, "c.go"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	got, err := WalkGoFiles(dir)
	if err != nil || len(got) != 2 {
		t.Fatalf("WalkGoFiles = (%v,%v)", got, err)
	}
	if filepath.Base(got[0]) != "a.go" || filepath.Base(got[1]) != "c.go" {
		t.Errorf("遍历顺序不对: %v", got)
	}
}

func TestEmbeddedNotice(t *testing.T) {
	data, err := noticeFS.ReadFile("notice.txt")
	if err != nil {
		t.Fatal(err)
	}
	if len(data) == 0 {
		t.Error("嵌入文件不该为空")
	}
}
