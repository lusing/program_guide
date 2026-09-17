package main

import (
	"fmt"
	"os"
	"slices"
	"strings"
	"sync"
	"testing"
	"testing/synctest"
	"time"
)

// 表驱动测试：Go 单测的标准形态。t.Run 开子测试，失败时带用例名。
func TestWordWrap(t *testing.T) {
	t.Parallel() // 与其他可并行测试并发跑（go test -parallel 控制并发度）
	cases := []struct {
		name  string
		in    string
		width int
		want  []string
	}{
		{"正好一行放下", "go is fun", 10, []string{"go is fun"}},
		{"折成两行", "go is fun", 5, []string{"go is", "fun"}},
		{"超长词独占", "supercali fragilistic", 5, []string{"supercali", "fragilistic"}},
		{"多个空格视作一个", "a  b", 10, []string{"a b"}},
		{"空串", "", 10, nil},
		{"非法宽度", "abc", 0, nil},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			mustWrap(t, tc.in, tc.width, tc.want)
		})
	}
}

// 断言辅助函数：t.Helper() 让报错定位到调用行，而不是本函数内部。
func mustWrap(t *testing.T, in string, width int, want []string) {
	t.Helper()
	got := WordWrap(in, width)
	if !slices.Equal(got, want) {
		t.Errorf("WordWrap(%q, %d) = %q, want %q", in, width, got, want)
	}
}

// Example 函数：go test 会逐行核对 Output 注释——文档即测试。
func ExampleWordWrap() {
	for _, l := range WordWrap("go is simple go is fast", 9) {
		fmt.Println(l)
	}
	// Output:
	// go is
	// simple go
	// is fast
}

// 基准测试：go test -bench . -benchmem。
// b.Loop()（1.24+）自动排除循环外准备代码、防止编译器把循环体优化掉，
// 取代老的 for i := 0; i < b.N; i++ + b.ResetTimer 组合拳。
func BenchmarkWordWrap(b *testing.B) {
	text := strings.Repeat("the quick brown fox jumps over the lazy dog ", 100)
	for b.Loop() {
		_ = WordWrap(text, 40)
	}
}

// 模糊测试：go test -fuzz=FuzzWordWrap 才开始随机探索；
// 平时 go test 只回放种子语料（零成本回归）。
// 断言的是不变量：任何一行要么不超宽，要么是不含空格的单个词。
func FuzzWordWrap(f *testing.F) {
	f.Add("go is fun", 5)
	f.Add("a b c", 1)
	f.Add("", 3)
	f.Fuzz(func(t *testing.T, s string, width int) {
		if width <= 0 || width > 4096 {
			return
		}
		for _, line := range WordWrap(s, width) {
			if len(line) > width && strings.Contains(line, " ") {
				t.Fatalf("行 %q 宽 %d 超限且含空格", line, width)
			}
		}
	})
}

// synctest 气泡（1.25+）：假时钟让"五路并发等 4 分钟"瞬间跑完。
// 1.27 实测签名是 Test(t, func(t *testing.T))——老教程的 Run(func()) 已改版。
func TestConcurrentSleepSynctest(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		start := time.Now()
		var wg sync.WaitGroup
		for i := range 5 {
			wg.Go(func() { // 闭包捕获的 i 是本轮迭代专属副本（1.22+ 语义）
				time.Sleep(time.Duration(i) * time.Minute)
			})
		}
		wg.Wait() // 气泡里 WaitGroup.Wait 可靠阻塞 → 时间直接快进
		if elapsed := time.Since(start); elapsed < 4*time.Minute {
			t.Errorf("五路最长睡 4 分钟，只过了 %v", elapsed)
		}
	})
}

// t.TempDir：每个测试独立临时目录，结束自动删除。
// t.Cleanup 是 LIFO：这里先挂"目录应已删除"的检查，再要目录，
// 让 TempDir 自己的清理先跑、检查后跑——顺序反了就会误报。
func TestTempDirAutoCleanup(t *testing.T) {
	var dir string
	t.Cleanup(func() {
		if _, err := os.Stat(dir); !os.IsNotExist(err) {
			t.Errorf("测试结束后临时目录应被删除: %v", err)
		}
	})
	dir = t.TempDir()
	if _, err := os.Stat(dir); err != nil {
		t.Fatalf("临时目录应存在: %v", err)
	}
}
