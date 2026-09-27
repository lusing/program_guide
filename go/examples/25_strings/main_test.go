package main

import (
	"strconv"
	"strings"
	"testing"
)

func TestParsePairs(t *testing.T) {
	m, err := ParsePairs("host = 8080, retry=3")
	if err != nil {
		t.Fatal(err)
	}
	if m["host"] != 8080 || m["retry"] != 3 || len(m) != 2 {
		t.Errorf("ParsePairs = %v", m)
	}
	if _, err := ParsePairs("host=8080, broken"); err == nil {
		t.Error("缺 '=' 的字段应报错")
	}
	if _, err := ParsePairs("host=abc"); err == nil {
		t.Error("非整数值应报错")
	}
}

func TestBuilderJoin(t *testing.T) {
	got := BuilderJoin([]string{"a", "b"})
	if got != "a\nb\n" {
		t.Errorf("BuilderJoin = %q", got)
	}
	if BuilderJoin(nil) != "" {
		t.Error("空输入应得空串")
	}
}

func TestInitials(t *testing.T) {
	if got := Initials("  grace\t hopper ADA "); got != "GHA" {
		t.Errorf("Initials = %q, want GHA", got)
	}
	if got := Initials("向量"); got != "向" { // 多字节词首
		t.Errorf("Initials(中文) = %q", got)
	}
}

func TestCutAndTrim(t *testing.T) {
	k, v, ok := strings.Cut("host:8080", ":")
	if !ok || k != "host" || v != "8080" {
		t.Errorf("Cut = (%q,%q,%v)", k, v, ok)
	}
	if _, _, ok := strings.Cut("nosep", ":"); ok {
		t.Error("无分隔符时 ok 应为 false")
	}
	// Trim 的第二参数是字符集合：0x1F0 两头的 0、x 都被削
	if got := strings.Trim("0x1F0", "0x"); got != "1F" {
		t.Errorf("Trim cutset = %q, want 1F", got)
	}
	if got := strings.TrimSuffix("config.json", ".json"); got != "config" {
		t.Errorf("TrimSuffix = %q", got)
	}
}

func TestParseIntBases(t *testing.T) {
	n, err := strconv.ParseInt("0x1F", 0, 64)
	if err != nil || n != 31 {
		t.Errorf("ParseInt(0x1F) = (%v,%v)", n, err)
	}
	if _, err := strconv.Atoi("0x1F"); err == nil {
		t.Error("Atoi 不认十六进制前缀")
	}
}
