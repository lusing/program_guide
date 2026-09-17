package grep

import (
	"os"
	"path/filepath"
	"slices"
	"testing"
)

func newMatcher(t *testing.T, pattern string, ignoreCase bool) *Matcher {
	t.Helper()
	m, err := NewMatcher(pattern, ignoreCase)
	if err != nil {
		t.Fatal(err)
	}
	return m
}

func write(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestMatchText(t *testing.T) {
	m := newMatcher(t, `func \w+`, false)
	if !m.MatchText("func main() {}") {
		t.Error("应命中")
	}
	if m.MatchText("var x = 1") {
		t.Error("不该命中")
	}
}

func TestIgnoreCase(t *testing.T) {
	if !newMatcher(t, "go", true).MatchText("GO IS FUN") {
		t.Error("-i 应命中大写")
	}
	if newMatcher(t, "go", false).MatchText("GO IS FUN") {
		t.Error("默认大小写敏感，不该命中")
	}
}

func TestNewMatcherBadPattern(t *testing.T) {
	if _, err := NewMatcher("([", false); err == nil {
		t.Error("非法正则应报错")
	}
}

func TestHighlight(t *testing.T) {
	m := newMatcher(t, "go", false)
	if got, want := m.Highlight("go go", true), "\x1b[31mgo\x1b[0m \x1b[31mgo\x1b[0m"; got != want {
		t.Errorf("Highlight = %q, want %q", got, want)
	}
	if got := m.Highlight("go", false); got != "go" {
		t.Errorf("关色应原样返回: %q", got)
	}
}

func TestSearchFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "a.txt")
	write(t, path, "alpha\nbeta function\ngamma\nfunction delta\n")
	hits, err := SearchFile(path, newMatcher(t, "function", false), Options{})
	if err != nil {
		t.Fatal(err)
	}
	if len(hits) != 2 || hits[0].Line != 2 || hits[1].Line != 4 {
		t.Errorf("hits = %+v, want 第 2、4 行", hits)
	}
	if hits[0].Text != "beta function" {
		t.Errorf("第 2 行内容 = %q", hits[0].Text)
	}
}

func TestSearchTree(t *testing.T) {
	dir := t.TempDir()
	if err := os.Mkdir(filepath.Join(dir, "sub"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Mkdir(filepath.Join(dir, ".git"), 0o755); err != nil {
		t.Fatal(err)
	}
	write(t, filepath.Join(dir, "top.go"), "func a(){}\n")
	write(t, filepath.Join(dir, "sub", "deep.go"), "x\nfunc b(){}\n")
	write(t, filepath.Join(dir, ".hidden"), "func secret(){}\n")
	write(t, filepath.Join(dir, ".git", "cfg"), "func nope(){}\n")

	hits, err := SearchTree(dir, newMatcher(t, `func \w+`, false), Options{})
	if err != nil {
		t.Fatal(err)
	}
	var bases []string
	for _, h := range hits {
		bases = append(bases, filepath.Base(h.Path))
	}
	// 按完整路径排序：sub/deep.go 在 top.go 之前；隐藏文件/目录全跳过
	if !slices.Equal(bases, []string{"deep.go", "top.go"}) {
		t.Errorf("命中文件 = %v, want [deep.go top.go]", bases)
	}
}

func TestSearchTreeNoHits(t *testing.T) {
	dir := t.TempDir()
	write(t, filepath.Join(dir, "a.txt"), "nothing here\n")
	hits, err := SearchTree(dir, newMatcher(t, "zzz", false), Options{})
	if err != nil {
		t.Fatal(err)
	}
	if len(hits) != 0 {
		t.Errorf("不该有命中: %+v", hits)
	}
}
