package main

import (
	"regexp"
	"testing"
)

func TestParseLogLine(t *testing.T) {
	lp, ok := ParseLogLine("2026-09-27 ERROR 连接超时")
	if !ok {
		t.Fatal("合法日志行应匹配")
	}
	if lp.Date != "2026-09-27" || lp.Level != "ERROR" || lp.Msg != "连接超时" {
		t.Errorf("ParseLogLine = %+v", lp)
	}
	if _, ok := ParseLogLine("2026-9-27 ERROR 日期不足两位"); ok {
		t.Error("\\d{2} 不匹配单位数日")
	}
}

func TestFindAllCountSemantics(t *testing.T) {
	re := regexp.MustCompile(`\d+`)
	if got := re.FindAllString("1 22 333", -1); len(got) != 3 {
		t.Errorf("-1 应返回全部，got %v", got)
	}
	if got := re.FindAllString("1 22 333", 2); len(got) != 2 {
		t.Errorf("n=2 应限两个，got %v", got)
	}
	if got := re.FindAllString("1 22 333", 0); got != nil {
		t.Errorf("n=0 应返回 nil，got %v", got)
	}
}

func TestReplaceExpansion(t *testing.T) {
	re := regexp.MustCompile(`(\w+)@example\.com`)
	if got := re.ReplaceAllString("bob@example.com", "$1x"); got != "" {
		t.Errorf("$1x 应把 1x 当分组名而得空串，got %q", got)
	}
	if got := re.ReplaceAllString("bob@example.com", "${1}x"); got != "bobx" {
		t.Errorf("${1}x = %q, want bobx", got)
	}
	if got := re.ReplaceAllLiteralString("bob@example.com", "$1"); got != "$1" {
		t.Errorf("Literal 应不展开 $1，got %q", got)
	}
}

func TestHighlightQuotesMeta(t *testing.T) {
	got := Highlight("算式 1.5*3 与 1x53 都在", []string{"1.5*3"})
	if got != "算式 [1.5*3] 与 1x53 都在" {
		t.Errorf("Highlight = %q（. 和 * 未被当元字符）", got)
	}
	if got := Highlight("GO go Go", []string{"go"}); got != "[GO] [go] [Go]" {
		t.Errorf("(?i) 大小写不敏感高亮 = %q", got)
	}
}

func TestRE2Limits(t *testing.T) {
	if _, err := regexp.Compile(`(?P<x>a)\1`); err == nil {
		t.Error("RE2 不支持反向引用，应编译失败")
	}
	if _, err := regexp.Compile(`a(?=b)`); err == nil {
		t.Error("RE2 不支持环视，应编译失败")
	}
}
