// 25_strings：strings/bytes/strconv 三件套——文本处理的日常主力。
// 对照 docs/25-strings.md：Builder、Cut、Fields、Replacer、Quote、NumError。
package main

import (
	"bytes"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"unicode"
)

// ParsePairs 解析 "host=8080, retry=3" 形式的配置串。
// Cut 处理键值，外层 Split 处理分隔符——比 Index+切片的老三样清爽。
func ParsePairs(s string) (map[string]int, error) {
	m := make(map[string]int)
	for field := range strings.SplitSeq(s, ",") { // 1.24+：迭代器版 Split，不建中间切片
		k, v, ok := strings.Cut(field, "=")
		if !ok {
			return nil, fmt.Errorf("字段 %q 缺少 '='", field)
		}
		n, err := strconv.Atoi(strings.TrimSpace(v))
		if err != nil {
			return nil, fmt.Errorf("字段 %q 的值不是整数: %w", field, err)
		}
		m[strings.TrimSpace(k)] = n
	}
	return m, nil
}

// BuilderJoin 循环拼串的正规姿势：Builder + Grow。
// 对比：lines 每条 10 字节、+ 拼接要分配 N 次中间串。
func BuilderJoin(lines []string) string {
	var b strings.Builder
	b.Grow(len(lines) * 12) // 预估容量，避免中途扩容
	for _, ln := range lines {
		b.WriteString(ln)
		b.WriteByte('\n')
	}
	return b.String()
}

// Initials 取每个单词的首字母大写连起来（Fields 按任意 Unicode 空白切）。
func Initials(name string) string {
	var b strings.Builder
	for w := range strings.FieldsSeq(name) { // 1.24+：迭代器版 Fields
		r := []rune(w) // 词首可能是多字节字符，先转 rune
		if len(r) > 0 {
			b.WriteRune(unicode.ToUpper(r[0]))
		}
	}
	return b.String()
}

// 预编译的替换表：多处替换单趟扫描，且并发安全（多个 goroutine 可共用）。
var tidy = strings.NewReplacer("，", ",", "：", ":", "--", "—")

func main() {
	fmt.Println("== Builder vs + ==")
	fmt.Print(BuilderJoin([]string{"第一行", "第二行", "第三行"}))

	fmt.Println("== Cut：key=value 解析（25 章主推姿势）==")
	m, err := ParsePairs("host = 8080, retry = 3, timeout = 30")
	if err != nil {
		fmt.Println("解析失败:", err)
	} else {
		fmt.Println(m)
	}
	if _, err := ParsePairs("host=8080; broken"); err != nil {
		fmt.Println("坏字段报错:", err)
	}

	fmt.Println("== Fields / Initials ==")
	fmt.Printf("%q -> %q\n", "  grace  hopper\t ada  lovelace\n", Initials("  grace  hopper\t ada  lovelace\n"))

	fmt.Println("== Trim 家族：cutset 不是子串 ==")
	fmt.Printf("Trim(%q, \"0x\")  = %q\n", "0x1F0", strings.Trim("0x1F0", "0x")) // 把两头的 0/x 字符全削掉！
	fmt.Printf("TrimSuffix(%q) = %q\n", "config.json", strings.TrimSuffix("config.json", ".json"))

	fmt.Println("== Replacer：预编译替换表 ==")
	fmt.Println(tidy.Replace("宽限时间，重试：3--次"))

	fmt.Println("== strconv：解析与格式化 ==")
	n, _ := strconv.ParseInt("0x1F", 0, 64) // base 0 认 0x/0o/0b 前缀
	fmt.Println("0x1F =", n, "/ 255 的十六进制 =", strconv.FormatInt(255, 16))
	f, _ := strconv.ParseFloat("3.14159", 64)
	fmt.Println("FormatFloat 'f' 2 位:", strconv.FormatFloat(f, 'f', 2, 64))

	fmt.Println("== NumError：区分语法错和溢出 ==")
	if _, err := strconv.Atoi("1e9"); err != nil {
		var ne *strconv.NumError
		if errors.As(err, &ne) && ne.Err == strconv.ErrSyntax {
			fmt.Println("1e9 → ErrSyntax（Atoi 只认十进制，科学计数要用 ParseFloat）")
		}
	}
	if _, err := strconv.ParseInt("99999999999999999999", 10, 64); err != nil {
		var ne *strconv.NumError
		if errors.As(err, &ne) && ne.Err == strconv.ErrRange {
			fmt.Println("20 个 9 → ErrRange（语法对，int64 装不下）")
		}
	}

	fmt.Println("== Quote / Unquote：Go 字面量语法 ==")
	q := strconv.Quote("路径\tC:\\go\n中文\"引号\"")
	fmt.Println(q)
	back, _ := strconv.Unquote(q)
	fmt.Printf("往返一致: %v\n", back == "路径\tC:\\go\n中文\"引号\"")

	fmt.Println("== bytes：[]byte 的镜像 + Append 系热路径 ==")
	bb := []byte("go")
	bb = strconv.AppendInt(bb, 42, 10) // 追加而不是新建 string
	fmt.Printf("AppendInt 结果: %s\n", bb)
	fmt.Println("bytes.EqualFold([]byte(GO), []byte(go)) =", bytes.EqualFold([]byte("GO"), []byte("go")))

	fmt.Println("== strings.Reader：把字符串接进 IO 世界 ==")
	r := strings.NewReader("hello")
	buf := make([]byte, 4)
	nread, _ := r.Read(buf) // 20 章的 io.Reader 全家都能吃它
	fmt.Printf("读了 %d 字节: %q\n", nread, buf[:nread])
}
