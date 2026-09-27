package main

import (
	"testing"
	"unicode"
	"unicode/utf16"
	"unicode/utf8"
)

func TestCounts(t *testing.T) {
	s := "Go语言"
	if len(s) != 8 {
		t.Errorf("len = %d, want 8 字节", len(s))
	}
	if utf8.RuneCountInString(s) != 4 {
		t.Errorf("RuneCount = %d, want 4", utf8.RuneCountInString(s))
	}
}

func TestCountCJK(t *testing.T) {
	if got := CountCJK("Go语言，カナ，한국"); got != 6 { // 语+言+カ+ナ+한+국；全角逗号是标点
		t.Errorf("CountCJK = %d, want 6", got)
	}
	if got := CountCJK("Go 1.27"); got != 0 {
		t.Errorf("CountCJK = %d, want 0", got)
	}
}

func TestTruncateRuneSafe(t *testing.T) {
	if got := Truncate("语言文字", 3); got != "语言文…" {
		t.Errorf("Truncate = %q", got)
	}
	if got := Truncate("语言", 5); got != "语言" {
		t.Errorf("不足上限应原样返回，got %q", got)
	}
	// 截断结果必须是合法 UTF-8（字节截断会切出半个字符）
	if !utf8.ValidString(Truncate("🚀🚀🚀", 1)) {
		t.Error("rune 截断结果应为合法 UTF-8")
	}
}

func TestDecodeInvalid(t *testing.T) {
	r, size := utf8.DecodeRune([]byte{0xff})
	if r != utf8.RuneError || size != 1 {
		t.Errorf("非法字节 = (%U,%d)，want (U+FFFD,1)", r, size)
	}
}

func TestUTF16SurrogatePair(t *testing.T) {
	u16 := utf16.Encode([]rune("🚀"))
	if len(u16) != 2 { // BMP 外的字符是两个码元
		t.Errorf("emoji 应编码为两个码元，got %v", u16)
	}
	// '🚀' = U+1F680 → 高位 U+D83D + 低位 U+DE80
	if u16[0] != 0xD83D || u16[1] != 0xDE80 {
		t.Errorf("代理对 = %X，want D83D DE80", u16)
	}
	if got := string(utf16.Decode(u16)); got != "🚀" {
		t.Errorf("往返 = %q", got)
	}
}

func TestClassification(t *testing.T) {
	if !unicode.IsDigit('7') || unicode.IsDigit('⑦') {
		t.Error("IsDigit 只认十进制数字字符")
	}
	if !unicode.IsNumber('⑦') {
		t.Error("IsNumber 应认 ⑦")
	}
	if !unicode.Is(unicode.Han, '语') || unicode.Is(unicode.Han, 'G') {
		t.Error("汉字表判断")
	}
}
