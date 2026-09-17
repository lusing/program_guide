// 07_maps：字面量、ok 惯用法、nil 陷阱、set 惯用法、有序遍历。
package main

import (
	"fmt"
	"sort"
	"strings"
)

// WordCount 统计词频：缺键取零值起步，counts[w]++ 不用先判存在。
func WordCount(s string) map[string]int {
	counts := make(map[string]int)
	for _, w := range strings.Fields(s) {
		counts[w]++
	}
	return counts
}

// SortedKeys 键排序后返回——需要有序输出时的标准姿势（map 遍历无序）。
func SortedKeys(m map[string]int) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

// Set 用 map 实现 set（Go 没有内置 set）：值类型 struct{} 不占内存。
type Set map[string]struct{}

func (s Set) Add(k string)      { s[k] = struct{}{} }
func (s Set) Has(k string) bool { _, ok := s[k]; return ok }

func main() {
	fmt.Println("== 字面量与访问 ==")
	ages := map[string]int{
		"阿 G": 18,
		"阿 Z": 25,
	}
	fmt.Println("阿 Z 的年龄:", ages["阿 Z"])

	// ok 惯用法：缺失的键返回零值 0，ok 才说明键存不存在
	if age, ok := ages["阿 Q"]; ok {
		fmt.Println("阿 Q:", age)
	} else {
		fmt.Println("阿 Q 不在（读到零值", age, "——不能靠值判断存在性）")
	}

	fmt.Println("== 增删改与 len ==")
	ages["新同学"] = 30
	delete(ages, "阿 G")
	fmt.Println(ages, "len =", len(ages))

	fmt.Println("== 有序遍历（先取键再排序） ==")
	for _, k := range SortedKeys(ages) {
		fmt.Printf("%s=%d ", k, ages[k])
	}
	fmt.Println()

	fmt.Println("== 词频统计 ==")
	counts := WordCount("go is fun go is fast go wins")
	for _, w := range SortedKeys(counts) {
		fmt.Printf("%s×%d ", w, counts[w])
	}
	fmt.Println()

	fmt.Println("== set 惯用法 ==")
	tags := Set{"go": {}, "zig": {}}
	tags.Add("rust")
	fmt.Println("有 go?", tags.Has("go"), "有 java?", tags.Has("java"), "共", len(tags), "个")

	fmt.Println("== nil map：读不慌，写就炸 ==")
	var m map[string]int
	fmt.Println("nil map 读缺失键:", m["x"], "len:", len(m))
	// m["x"] = 1 // ← 取消注释立刻 panic: assignment to entry in nil map
	_ = m
}
