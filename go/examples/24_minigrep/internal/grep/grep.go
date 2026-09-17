// Package grep 是迷你 grep 的核心：正则匹配、逐行扫描、并发目录遍历。
package grep

import (
	"bufio"
	"cmp"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"slices"
	"strings"
	"sync"
)

// Match 一次命中：哪个文件第几行、该行长什么样。
type Match struct {
	Path string
	Line int
	Text string
}

// Options 搜索选项（由 main 的 flag 填充）。
type Options struct {
	IgnoreCase bool
	Recursive  bool
	ShowLines  bool
	ColorMode  string // auto / always / never
}

// Matcher 把正则编译一次，处处复用。
type Matcher struct {
	re *regexp.Regexp
}

// NewMatcher 编译模式；忽略大小写在正则前加 (?i)。
func NewMatcher(pattern string, ignoreCase bool) (*Matcher, error) {
	if ignoreCase {
		pattern = "(?i)" + pattern
	}
	re, err := regexp.Compile(pattern)
	if err != nil {
		return nil, fmt.Errorf("正则不合法 %q: %w", pattern, err)
	}
	return &Matcher{re: re}, nil
}

// MatchText 报告一行文本是否命中。
func (m *Matcher) MatchText(text string) bool {
	return m.re.MatchString(text)
}

// Highlight 给命中片段包 ANSI 红色；关色时原样返回。
func (m *Matcher) Highlight(line string, color bool) string {
	if !color {
		return line
	}
	return m.re.ReplaceAllStringFunc(line, func(s string) string {
		return "\x1b[31m" + s + "\x1b[0m"
	})
}

// SearchFile 逐行扫描单个文件。
func SearchFile(path string, m *Matcher, opts Options) ([]Match, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var hits []Match
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 64*1024), 4<<20) // 长行上限放大到 4 MiB
	lineNo := 0
	for sc.Scan() {
		lineNo++
		if m.MatchText(sc.Text()) {
			hits = append(hits, Match{Path: path, Line: lineNo, Text: sc.Text()})
		}
	}
	return hits, sc.Err()
}

// SearchTree 并发搜索目录树：WalkDir 收集文件，worker pool 分头扫描，
// 结果按 (路径, 行号) 排序后返回——输出确定，测试可断言。
func SearchTree(root string, m *Matcher, opts Options) ([]Match, error) {
	// ① 串行收集待扫文件（跳过隐藏目录与隐藏文件）
	var files []string
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		name := d.Name()
		if strings.HasPrefix(name, ".") {
			if d.IsDir() && path != root {
				return filepath.SkipDir
			}
			if !d.IsDir() {
				return nil // 隐藏文件：跳过
			}
		}
		if !d.IsDir() {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	// ② worker pool：jobs 发文件，results 收命中
	workers := min(runtime.NumCPU(), 8)
	jobs := make(chan string)
	results := make(chan []Match)

	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for path := range jobs {
				hits, err := SearchFile(path, m, opts)
				if err == nil && len(hits) > 0 {
					results <- hits
				}
			}
		})
	}

	// 投递完关 jobs；等工人都收工再关 results——经典 fan-in 收尾
	go func() {
		for _, f := range files {
			jobs <- f
		}
		close(jobs)
		wg.Wait()
		close(results)
	}()

	var all []Match
	for hits := range results {
		all = append(all, hits...)
	}
	slices.SortFunc(all, func(a, b Match) int {
		if c := strings.Compare(a.Path, b.Path); c != 0 {
			return c
		}
		return cmp.Compare(a.Line, b.Line)
	})
	return all, nil
}
