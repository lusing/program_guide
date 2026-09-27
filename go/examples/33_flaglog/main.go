// 33_flaglog：flag 子命令与自定义 Value、log 老牌日志、slog 结构化、expvar 指标。
// 对照 docs/33-flaglog.md。
package main

import (
	"expvar"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net/http/httptest"
	"os"
	"strconv"
	"strings"
)

// ---------- flag：自定义 Value ----------

// IntList 实现 flag.Value：命令行给 "1,2,3"。
type IntList []int

func (l *IntList) String() string {
	if l == nil {
		return ""
	}
	parts := make([]string, len(*l))
	for i, v := range *l {
		parts[i] = strconv.Itoa(v)
	}
	return strings.Join(parts, ",")
}

// Set 每出现一次参数调一次（-ids 1,2 -ids 3 → 1,2,3）。
func (l *IntList) Set(s string) error {
	for _, part := range strings.Split(s, ",") {
		n, err := strconv.Atoi(strings.TrimSpace(part))
		if err != nil {
			return fmt.Errorf("%q 不是整数: %w", part, err)
		}
		*l = append(*l, n)
	}
	return nil
}

// ---------- flag：子命令 ----------

// ParseAdd 解析 `add -n 3 -- ids 1,2`，返回重复次数与 ID 列表。
// 用 FlagSet 而不是全局 flag：库代码/测试都要能安全调用。
func ParseAdd(args []string) (n int, ids IntList, err error) {
	fs := flag.NewFlagSet("add", flag.ContinueOnError)
	fs.SetOutput(os.Stdout) // 出错时的 usage 默认打 stderr——示例里改到 stdout（本教程要求 stderr 干净）
	fs.IntVar(&n, "n", 1, "重复次数")
	fs.Var(&ids, "ids", "逗号分隔的 ID 列表（可多次出现）")
	if err := fs.Parse(args); err != nil {
		return 0, nil, err
	}
	if fs.NArg() > 0 {
		return 0, nil, fmt.Errorf("多余的位置参数: %v", fs.Args())
	}
	return n, ids, nil
}

// ---------- expvar：注册一次，热路径只 Add ----------

var (
	hits   = expvar.NewInt("demo_hits")
	buildV expvar.String // String 没有 NewString 构造器，Publish 时取地址
)

func init() {
	buildV.Set("v1.27-33")
	expvar.Publish("demo_build", &buildV)
	expvar.Publish("demo_tags", expvar.Func(func() any {
		return map[string]string{"chapter": "33", "topic": "flag/log"}
	}))
}

// SlogDemo 把同一批日志分别打成文本和 JSON，返回两段输出。
func SlogDemo() (text, json string) {
	var tb, jb strings.Builder

	th := slog.NewTextHandler(&tb, &slog.HandlerOptions{Level: slog.LevelDebug})
	logger := slog.New(th)
	logger.Debug("调试默认被丢，Level 放行才输出")
	logger.Info("用户登录", "user", "ada", "attempts", 3)
	logger.Warn("慢查询", "sql", "SELECT * FROM t", "took", "120ms")

	jh := slog.NewJSONHandler(&jb, nil)
	j2 := slog.New(jh).With("module", "auth").WithGroup("request")
	j2.Error("被拒绝", "path", "/login", "code", 401)
	return tb.String(), jb.String()
}

func main() {
	fmt.Println("== flag：子命令 + 自定义 Value ==")
	n, ids, err := ParseAdd([]string{"-n", "3", "-ids", "1,2", "-ids", "3"})
	if err != nil {
		fmt.Println("解析失败:", err)
	} else {
		fmt.Printf("n=%d ids=%v\n", n, ids)
	}
	if _, _, err := ParseAdd([]string{"-ids", "a,b"}); err != nil {
		fmt.Println("坏参数报错:", err)
	}
	if _, _, err := ParseAdd([]string{"多余的"}); err != nil {
		fmt.Println("位置参数报错:", err)
	}

	fmt.Println("== slog：文本给 人，JSON 给 机器 ==")
	text, jsons := SlogDemo()
	fmt.Print(text)
	fmt.Print(jsons)

	fmt.Println("== expvar：/debug/vars 长什么样 ==")
	hits.Add(2)
	req := httptest.NewRequest("GET", "/debug/vars", nil)
	rec := httptest.NewRecorder()
	expvar.Handler().ServeHTTP(rec, req)
	body := rec.Body.String()
	for _, key := range []string{"demo_hits", "demo_build", "demo_tags", "memstats"} {
		fmt.Printf("  %s 出现: %v\n", key, strings.Contains(body, `"`+key+`"`))
	}

	fmt.Println("== log → slog 打通：SetDefault 后老 log 走新 handler ==")
	var buf strings.Builder
	slog.SetDefault(slog.New(slog.NewTextHandler(&buf, nil)))
	log.Printf("老代码的 log.Printf") // 1.21+：默认 logger 接到 slog 上，格式跟着变
	fmt.Print(buf.String())
}
