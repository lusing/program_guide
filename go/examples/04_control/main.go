// 04_control：for 是唯一循环；switch 默认不穿透；标签跳转；类型 switch。
package main

import "fmt"

// FizzBuzz：switch 无表达式形态（case 写条件）。
func FizzBuzz(n int) string {
	switch {
	case n%15 == 0:
		return "FizzBuzz"
	case n%3 == 0:
		return "Fizz"
	case n%5 == 0:
		return "Buzz"
	}
	return fmt.Sprint(n)
}

// Classify 用类型 switch 给 any（= interface{}）分流。
func Classify(v any) string {
	switch x := v.(type) {
	case nil:
		return "空值"
	case int:
		return fmt.Sprintf("整数 %d", x)
	case string:
		return "字符串 " + x
	case []string:
		return fmt.Sprintf("字符串切片，长度 %d", len(x))
	default:
		return fmt.Sprintf("其他类型 %T", x)
	}
}

// Find 双层循环找目标：标签 break 一步跳出（Go 没有 break 2）。
func Find(grid [][]int, target int) (row, col int, ok bool) {
outer:
	for r, rowVals := range grid {
		for c, v := range rowVals {
			if v == target {
				row, col, ok = r, c, true
				break outer // 命中后直接跳出双层
			}
		}
	}
	return // 命名返回值裸返回（下一章细讲）
}

func main() {
	fmt.Println("== for 的四种形态 ==")
	for i := 0; i < 3; i++ { // ① 经典三段式
		fmt.Print(i, " ")
	}
	fmt.Println()

	n := 0
	for n < 3 { // ② 只有条件（其他语言的 while）
		fmt.Print(n, " ")
		n++
	}
	fmt.Println()

	for i := range 3 { // ③ range 整数（1.22+），等价 ① 更顺手
		fmt.Print(i, " ")
	}
	fmt.Println()

	sum := 0
	for { // ④ 无限循环 + break
		sum += 5
		if sum >= 15 {
			break
		}
	}
	fmt.Println("无限循环攒到", sum)

	fmt.Println("== range 家族 ==")
	words := []string{"苹果", "梨", "枣"}
	for i, w := range words {
		fmt.Printf("[%d]%s ", i, w)
	}
	fmt.Println()
	ages := map[string]int{"阿 G": 18, "阿 Z": 25}
	for name, age := range ages { // map 遍历顺序故意随机（坑位清单）
		fmt.Printf("%s=%d ", name, age)
	}
	fmt.Println()

	fmt.Println("== switch：默认不穿透 ==")
	for i := range 5 {
		switch i {
		case 0, 2, 4: // 一个 case 多个值
			fmt.Println(i, "偶")
		default:
			fmt.Println(i, "奇")
		}
	}
	switch lang := "go"; lang { // switch 带初始化语句，作用域限于 switch
	case "go", "zig":
		fmt.Println("系统语言阵营")
	default:
		fmt.Println("其他")
	}
	switch 1 { // fallthrough：显式穿透（不判断下一个 case 的条件）
	case 1:
		fmt.Print("一 ")
		fallthrough
	case 99:
		fmt.Println("被 fallthrough 穿进 99（条件根本没看）")
	}

	fmt.Println("== 标签跳转 ==")
	grid := [][]int{{1, 2}, {3, 4}}
	r, c, ok := Find(grid, 4)
	fmt.Printf("找到 4 于 (%d,%d)? %v\n", r, c, ok)

	fmt.Println("== FizzBuzz 与类型 switch ==")
	for i := 1; i <= 5; i++ {
		fmt.Print(FizzBuzz(i), " ")
	}
	fmt.Println()
	for _, v := range []any{nil, 42, "文本", []string{"a"}, 3.14} {
		fmt.Println(" ", Classify(v))
	}
}
