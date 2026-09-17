// 05_functions：多返回值、命名返回、变参、defer、闭包、高阶函数。
package main

import (
	"errors"
	"fmt"
	"strings"
)

// Div：Go 没有异常，错误是普通返回值——多返回值为此而生。
func Div(a, b int) (int, error) {
	if b == 0 {
		return 0, errors.New("除数为零")
	}
	return a / b, nil
}

// Sum 变参：函数内 nums 就是 []int。
func Sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

// Counter 返回闭包 = 函数 + 它捕获的环境。
func Counter() func() int {
	count := 0
	return func() int {
		count++
		return count
	}
}

// Apply 高阶函数：函数是一等值，能当参数传。
func Apply(nums []int, f func(int) int) []int {
	out := make([]int, len(nums))
	for i, n := range nums {
		out[i] = f(n)
	}
	return out
}

// Title 命名返回值 + 裸 return：短函数尚可，长函数是可读性黑洞。
func Title(full string) (first, last string) {
	parts := strings.SplitN(full, " ", 2)
	first = parts[0]
	if len(parts) == 2 {
		last = parts[1]
	}
	return
}

func main() {
	fmt.Println("== 多返回值与错误 ==")
	if q, err := Div(7, 2); err != nil {
		fmt.Println("出错:", err)
	} else {
		fmt.Println("7/2 =", q)
	}
	if _, err := Div(1, 0); err != nil {
		fmt.Println("捕获:", err)
	}

	fmt.Println("== 变参：零个、多个、切片展开 ==")
	fmt.Println(Sum(), Sum(1, 2, 3), Sum([]int{4, 5}...))

	fmt.Println("== 命名返回值 ==")
	f, l := Title("Rob Pike")
	fmt.Println(f, "·", l)

	fmt.Println("== defer：LIFO，函数退场前必执行 ==")
	defer fmt.Println("defer ①（最先注册，最后执行）")
	defer fmt.Println("defer ②（后注册，先执行）")
	fmt.Println("正常逻辑……")

	fmt.Println("== defer 求值时机：参数立刻求值，执行延后 ==")
	x := 1
	defer fmt.Println("defer 记住的 x =", x) // 注册瞬间就把 1 算好了
	x = 2
	fmt.Println("main 里的 x =", x)

	fmt.Println("== 闭包 ==")
	next := Counter()
	fmt.Println(next(), next(), next()) // 1 2 3
	another := Counter()
	fmt.Println(another()) // 1：两次 Counter 各有各的 count

	fmt.Println("== 高阶函数 ==")
	doubled := Apply([]int{1, 2, 3}, func(n int) int { return n * 2 })
	fmt.Println(doubled)
}
