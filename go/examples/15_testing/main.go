// 15_testing 的演示程序：本体在 wordwrap.go / wordwrap_test.go。
// 跑测试：go test -v .；跑基准：go test -bench .；跑模糊：go test -fuzz FuzzWordWrap
package main

import "fmt"

func main() {
	text := "Go 的测试是语言内建的：go test 一个命令搞定单元、基准、模糊与示例输出校验。"
	for i, line := range WordWrap(text, 24) {
		fmt.Printf("%2d| %s\n", i+1, line)
	}
}
