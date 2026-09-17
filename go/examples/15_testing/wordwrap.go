// WordWrap：贪心折行算法，15 章测试技术的被测对象。
package main

import "strings"

// WordWrap 按空格分词，把 s 折成每行不超过 width 字节的若干行。
// 超过 width 的单个词独占一行（允许溢出）；width <= 0 返回 nil。
// 注意：len 数的是字节，宽字符（中文）场景应先按 rune 处理。
func WordWrap(s string, width int) []string {
	if width <= 0 {
		return nil
	}
	var lines []string
	line := ""
	for _, w := range strings.Fields(s) {
		switch {
		case line == "":
			line = w
		case len(line)+1+len(w) <= width:
			line += " " + w
		default:
			lines = append(lines, line)
			line = w
		}
	}
	if line != "" {
		lines = append(lines, line)
	}
	return lines
}
