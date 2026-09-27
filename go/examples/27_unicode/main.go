// 27_unicode：len vs RuneCount、range 的字节下标、unicode 分类、utf8/utf16 编解码。
// 对照 docs/27-unicode.md。
package main

import (
	"fmt"
	"unicode"
	"unicode/utf16"
	"unicode/utf8"
)

// CountCJK 统计字符串里的 CJK 字符数（汉字 + 假名 + 谚文）。
func CountCJK(s string) int {
	n := 0
	for _, r := range s {
		if unicode.In(r, unicode.Han, unicode.Hiragana, unicode.Katakana, unicode.Hangul) {
			n++
		}
	}
	return n
}

// Truncate 按 rune 边界安全截断（字节截断会切出半个字符）。
func Truncate(s string, max int) string {
	if utf8.RuneCountInString(s) <= max {
		return s
	}
	rs := []rune(s)
	return string(rs[:max]) + "…"
}

func main() {
	fmt.Println("== len 是字节，RuneCount 是字符 ==")
	s := "Go语言🚀"
	fmt.Printf("%q: len=%d, 字符=%d\n", s, len(s), utf8.RuneCountInString(s))

	fmt.Println("== range：rune 值 + 字节下标（会跳）==")
	for i, r := range "语言" {
		fmt.Printf("  下标 %d → U+%04X %c\n", i, r, r)
	}

	fmt.Println("== 解码原语 ==")
	b := []byte("语言")
	r, size := utf8.DecodeRune(b)
	fmt.Printf("DecodeRune: U+%04X %c，占 %d 字节\n", r, r, size)
	buf := make([]byte, 4)
	n := utf8.EncodeRune(buf, '🚀')
	fmt.Printf("EncodeRune 🚀: 写了 %d 字节 = % X\n", n, buf[:n])

	fmt.Println("== 非法字节：U+FFFD 且继续 ==")
	bad := []byte{0x61, 0xff, 0x62} // a, 非法字节, b
	fmt.Println("Valid:", utf8.Valid(bad))
	for i, r := range string(bad) {
		fmt.Printf("  下标 %d → U+%04X %q\n", i, r, r)
	}

	fmt.Println("== unicode 分类 ==")
	fmt.Println("IsHan('语') =", unicode.Is(unicode.Han, '语'), "/ IsHan('Go' 的 G) =", unicode.Is(unicode.Han, 'G'))
	fmt.Println("IsDigit('7') =", unicode.IsDigit('7'), "/ IsNumber('⑦') =", unicode.IsNumber('⑦'))
	fmt.Printf("ToLower('A')=%c SimpleFold 链: ", unicode.ToLower('A'))
	for f := unicode.SimpleFold('A'); f != 'A'; f = unicode.SimpleFold(f) {
		fmt.Printf("%c ", f)
	}
	fmt.Println()

	fmt.Println("== CJK 统计 + rune 安全截断 ==")
	fmt.Println("CountCJK(\"Go语言，カナ，한국\") =", CountCJK("Go语言，カナ，한국"))
	fmt.Printf("Truncate(%q, 4) = %q\n", "abcdefg", Truncate("abcdefg", 4))
	fmt.Printf("Truncate(%q, 4) = %q\n", "语言文字", Truncate("语言文字", 4))

	fmt.Println("== utf16：emoji 是代理对 ==")
	u16 := utf16.Encode([]rune("Go🚀"))
	fmt.Printf("utf16.Encode: %v（🚀 占两个码元）\n", u16)
	back := string(utf16.Decode(u16))
	fmt.Println("Decode 还原:", back, "/ IsSurrogate(0xD83D) =", utf16.IsSurrogate(rune(0xD83D)))
}
