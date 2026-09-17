// 20_files：io.Reader/Writer 抽象、bufio、WalkDir、os.Root、go:embed。
package main

import (
	"bufio"
	"bytes"
	"embed"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
)

//go:embed notice.txt
var noticeFS embed.FS // 编译期把文件内容嵌进二进制

// CountLines 流式数行：Scanner 默认按行；默认行上限 64KiB，超长行必须调 Buffer。
func CountLines(r io.Reader) (int, error) {
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 0, 64*1024), 4<<20) // 单行上限放大到 4 MiB
	n := 0
	for sc.Scan() {
		n++
	}
	return n, sc.Err()
}

// WriteThenRead 一写一读：WriteFile 一把写，Open + defer Close 手工读。
func WriteThenRead(path string) error {
	if err := os.WriteFile(path, []byte("第一行\n第二行\n第三行\n"), 0o644); err != nil {
		return err
	}
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	n, err := CountLines(f)
	if err != nil {
		return err
	}
	fmt.Println("  行数:", n)
	return nil
}

// WalkGoFiles 递归收集 .go 文件：WalkDir 回调拿 DirEntry（比老 Walk 少一次 stat）。
func WalkGoFiles(root string) ([]string, error) {
	var found []string
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err // 目录不可访问：直接上抛，WalkDir 停止
		}
		if !d.IsDir() && filepath.Ext(path) == ".go" {
			found = append(found, path)
		}
		return nil
	})
	return found, err
}

func must(err error) {
	if err != nil {
		fmt.Println("出错了:", err)
		os.Exit(1)
	}
}

func main() {
	fmt.Println("== 临时文件：写 → 读 → 数行 ==")
	tmp, err := os.CreateTemp("", "guide-*.txt")
	must(err)
	must(tmp.Close())
	defer os.Remove(tmp.Name())
	must(WriteThenRead(tmp.Name()))

	fmt.Println("== bytes.Buffer 也是 io.Writer/Reader ==")
	var buf bytes.Buffer
	buf.WriteString("go\nzig\n")
	n, err := CountLines(&buf)
	must(err)
	fmt.Println("  内存里数行:", n)

	fmt.Println("== go:embed：文件编进 exe ==")
	notice, err := noticeFS.ReadFile("notice.txt")
	must(err)
	fmt.Println("  嵌入内容:", string(notice))

	fmt.Println("== WalkDir 递归找本目录的 .go ==")
	files, err := WalkGoFiles(".")
	must(err)
	for _, f := range files {
		fmt.Println("  ", filepath.Base(f))
	}

	fmt.Println("== os.Root（1.24+）：钉死根，杜绝 ../ 逃逸 ==")
	root, err := os.OpenRoot(".")
	must(err)
	defer root.Close()
	data, err := root.ReadFile("notice.txt")
	must(err)
	fmt.Println("  Root 内读文件长度:", len(data))
	if _, err := root.ReadFile("../go.mod"); err != nil {
		fmt.Println("  越界读取被拒:", err)
	}
}
