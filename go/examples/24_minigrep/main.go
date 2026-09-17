// 24_minigrep：实战项目——flag 解析 + 并发递归搜索 + ANSI 高亮。
// 用法：minigrep [-i] [-r] [-n] [-c auto|always|never] 模式 [文件或目录...]
// 退出码：0 有命中；1 无命中；2 用法错误（对齐 grep 惯例）。
package main

import (
	"flag"
	"fmt"
	"os"

	"minigrep/internal/grep"
)

func main() {
	os.Exit(run())
}

// run 把主体拆出来：main 只留 os.Exit，逻辑可测试。
func run() int {
	opts := grep.Options{}
	flag.BoolVar(&opts.IgnoreCase, "i", false, "忽略大小写")
	flag.BoolVar(&opts.Recursive, "r", false, "递归搜索目录")
	flag.BoolVar(&opts.ShowLines, "n", false, "显示行号")
	flag.StringVar(&opts.ColorMode, "c", "auto", "颜色 auto|always|never")
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "用法: minigrep [选项] 模式 [文件或目录...]")
		flag.PrintDefaults()
	}
	flag.Parse()

	if flag.NArg() < 1 {
		flag.Usage()
		return 2
	}
	pattern := flag.Arg(0)
	targets := flag.Args()[1:]
	if len(targets) == 0 {
		targets = []string{"."} // 不给目标就搜当前目录
	}

	m, err := grep.NewMatcher(pattern, opts.IgnoreCase)
	if err != nil {
		fmt.Fprintln(os.Stderr, "错误:", err)
		return 2
	}

	// 着色判定：管道/重定向（非字符设备）自动关色，输出保持干净
	color := opts.ColorMode == "always" ||
		(opts.ColorMode == "auto" && isTerminal(os.Stdout))

	total := 0
	for _, target := range targets {
		var matches []grep.Match
		if opts.Recursive {
			matches, err = grep.SearchTree(target, m, opts)
		} else {
			matches, err = grep.SearchFile(target, m, opts)
		}
		if err != nil {
			fmt.Fprintln(os.Stderr, "跳过:", err) // 单个目标失败不拖垮全局
			continue
		}
		for _, hit := range matches {
			prefix := ""
			if opts.Recursive || len(targets) > 1 {
				prefix = hit.Path + ":"
			}
			if opts.ShowLines {
				prefix += fmt.Sprintf("%d:", hit.Line)
			}
			fmt.Println(prefix + m.Highlight(hit.Text, color))
			total++
		}
	}
	if total == 0 {
		return 1
	}
	return 0
}

// isTerminal 判断文件是不是终端（stat 模式含字符设备位）。
func isTerminal(f *os.File) bool {
	info, err := f.Stat()
	if err != nil {
		return false
	}
	return info.Mode()&os.ModeCharDevice != 0
}
