// 06_slices：切片三要素（指针/len/cap）、append 扩容、共享底层数组、字符串。
package main

import (
	"fmt"
	"unicode/utf8"
)

// Evens 返回新切片，不动原数据（make 预留容量，避免 append 中途搬家）。
func Evens(nums []int) []int {
	out := make([]int, 0, len(nums))
	for _, n := range nums {
		if n%2 == 0 {
			out = append(out, n)
		}
	}
	return out
}

// Tail 返回去掉首元素的视图：切片表达式不复制，共享底层数组。
func Tail(s []int) []int {
	if len(s) == 0 {
		return nil
	}
	return s[1:]
}

func main() {
	fmt.Println("== 数组 vs 切片 ==")
	arr := [3]int{1, 2, 3}  // 数组：长度是类型的一部分，赋值整份拷贝
	sl := []int{1, 2, 3, 4} // 切片：底层数组的"窗口"，赋值只拷窗口
	two := arr
	two[0] = 99
	fmt.Println(arr, two) // 数组各改各的
	fmt.Println(len(arr), len(sl), cap(sl))

	fmt.Println("== append 与扩容 ==")
	var s []int // nil 切片：能用、能 append，len=0
	for i := 1; i <= 8; i++ {
		s = append(s, i*10)
		fmt.Printf("len=%d cap=%d %v\n", len(s), cap(s), s)
	}

	fmt.Println("== 共享底层数组（头号大坑） ==")
	a := []int{1, 2, 3, 4}
	b := a[:2]
	b[0] = 99
	fmt.Println("a =", a, "← b 改了，a 也变：同一块内存")

	c := append(a[:2], 500) // 更阴：a[:2] 的 cap 还剩 2，append 原地覆盖 a[2]！
	fmt.Println("a =", a, "c =", c)

	full := []int{1, 2, 3, 4}
	view := full[1:3:3]       // 三下标切片：连 cap 一起限死
	safe := append(view, 500) // cap 不够 → 搬新家，full 安全
	fmt.Println("full =", full, "safe =", safe)

	fmt.Println("== copy：真复制 ==")
	dst := make([]int, 2)
	n := copy(dst, full)
	fmt.Println("复制了", n, "个:", dst)

	fmt.Println("== nil 与空切片 ==")
	var nilSlice []int
	empty := []int{}
	fmt.Println(nilSlice == nil, empty == nil, len(nilSlice), len(empty)) // true false 0 0

	fmt.Println("== Evens / Tail ==")
	fmt.Println(Evens([]int{1, 2, 3, 4, 5, 6}), Tail([]int{1, 2, 3}))

	fmt.Println("== 字符串：只读的字节切片 ==")
	hello := "你好 Go"
	fmt.Println("字节数", len(hello), "字符数", utf8.RuneCountInString(hello))
	fmt.Printf("首字节 %#x（不是'你'），首 rune %c\n", hello[0], []rune(hello)[0])
	bs := []byte(hello) // 转换复制一份
	rs := []rune(hello) // 按字符解码，一个 rune 一个元素
	fmt.Println(len(bs), len(rs))
	bs[0] = 'x'
	fmt.Println(hello, "← 字符串不可变，改字节切片影响不到它")
}
