// 26_regexp：RE2 语义、查找家族、命名分组、替换的 $ 陷阱。
// 对照 docs/26-regexp.md。
package main

import (
	"fmt"
	"regexp"
	"strings"
)

// 写死的模式用 MustCompile：写错就在启动时炸，而不是线上静默失配。
var (
	logRe   = regexp.MustCompile(`^(?P<date>\d{4}-\d{2}-\d{2}) (?P<level>\w+) (?P<msg>.*)$`)
	wordRe  = regexp.MustCompile(`[a-zA-Z]+`)
	emailRe = regexp.MustCompile(`(\w+)@(\w+)\.com`)
)

// LogLine 是命名分组的解析结果。
type LogLine struct {
	Date  string
	Level string
	Msg   string
}

// ParseLogLine 用命名分组抽字段；不匹配返回 ok=false（而不是错误）。
func ParseLogLine(s string) (LogLine, bool) {
	m := logRe.FindStringSubmatch(s)
	if m == nil {
		return LogLine{}, false
	}
	return LogLine{
		Date:  m[logRe.SubexpIndex("date")],
		Level: m[logRe.SubexpIndex("level")],
		Msg:   m[logRe.SubexpIndex("msg")],
	}, true
}

// Highlight 把 keywords 当字面量高亮：QuoteMeta 先转义，防用户词里的元字符。
func Highlight(s string, keywords []string) string {
	for _, kw := range keywords {
		re := regexp.MustCompile("(?i)" + regexp.QuoteMeta(kw))
		s = re.ReplaceAllString(s, "[${0}]") // ${0} = 整个匹配，花括号防后缀粘连
	}
	return s
}

func main() {
	fmt.Println("== 匹配入门：MatchString / FindAllString ==")
	fmt.Println("MatchString:", logRe.MatchString("2026-09-27 INFO ok"))
	fmt.Println("第一个匹配:", wordRe.FindString("42 is the answer"))
	fmt.Println("全部匹配:", wordRe.FindAllString("go rust go python go", -1))
	fmt.Println("限 2 个:", wordRe.FindAllString("go rust go python go", 2))

	fmt.Println("== 子匹配与命名分组 ==")
	line := "2026-09-27 WARN 磁盘 85%"
	if lp, ok := ParseLogLine(line); ok {
		fmt.Printf("date=%s level=%s msg=%s\n", lp.Date, lp.Level, lp.Msg)
	}
	fmt.Println("不匹配一行:", func() string {
		if _, ok := ParseLogLine("不是日志"); !ok {
			return "ok=false（用 ok 而不是 error 表达'格式不合'）"
		}
		return "??"
	}())

	fmt.Println("== 替换：$1 与 ${1} 的区别 ==")
	fmt.Println(emailRe.ReplaceAllString("联系 a@b.com 或 c@d.com", "$1 AT $2"))
	// $1x 的 x 会被当成变量名一部分 → 空串；${1}x 才对
	fmt.Printf("$1x      → %q（x 被吞进分组名，整体成空串）\n", emailRe.ReplaceAllString("a@b.com", "$1x"))
	fmt.Printf("${1}x    → %q\n", emailRe.ReplaceAllString("a@b.com", "${1}x"))
	fmt.Printf("Literal  → %q（不展开 $，字面替换）\n", emailRe.ReplaceAllLiteralString("a@b.com", "$1"))

	fmt.Println("== 函数替换：先转大写再包壳 ==")
	fmt.Println(emailRe.ReplaceAllStringFunc("a@b.com c@d.com", strings.ToUpper))

	fmt.Println("== Split / QuoteMeta ==")
	fmt.Printf("%q\n", regexp.MustCompile(`[,;]\s*`).Split("a, b;c", -1))
	fmt.Println("QuoteMeta(\"a.b*(\") =", regexp.QuoteMeta("a.b*("))

	fmt.Println("== 高亮用户关键词（防注入）==")
	fmt.Println(Highlight("Go 和 go 都叫 GO；1.5*3 不是 go", []string{"go", "1.5*3"}))

	fmt.Println("== (?i)(?m) 修饰符 ==")
	re := regexp.MustCompile(`(?im)^warning`)
	fmt.Println(re.FindAllString("WARNING: a\nok\nwarning: b", -1))
}
