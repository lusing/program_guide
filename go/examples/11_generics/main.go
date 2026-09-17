// 11_generics：类型参数、cmp.Ordered/comparable 约束、泛型容器与管道。
package main

import (
	"cmp"
	"fmt"
	"strings"
)

// Max 泛型函数：T 受 cmp.Ordered 约束（支持 < 比较的类型集合）。
func Max[T cmp.Ordered](a, b T) T {
	if a > b {
		return a
	}
	return b
}

// Stack 泛型容器：方法不用重复声明类型参数，跟着接收者走。
type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) { s.items = append(s.items, v) }

func (s *Stack[T]) Pop() (T, bool) {
	if len(s.items) == 0 {
		var zero T // 泛型里拿零值的标准姿势
		return zero, false
	}
	top := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return top, true
}

func (s *Stack[T]) Len() int { return len(s.items) }

// Filter / Map：约束是 any，类型责任交给传入的函数。
func Filter[T any](in []T, keep func(T) bool) []T {
	out := make([]T, 0, len(in))
	for _, v := range in {
		if keep(v) {
			out = append(out, v)
		}
	}
	return out
}

func Map[T, U any](in []T, f func(T) U) []U {
	out := make([]U, len(in))
	for i, v := range in {
		out[i] = f(v)
	}
	return out
}

// Number 自定义约束：| 列举类型集合，~ 表示"底层类型是"（命名类型也算）。
type Number interface {
	~int | ~int64 | ~float64
}

func Sum[T Number](nums []T) T {
	var total T
	for _, n := range nums {
		total += n
	}
	return total
}

func main() {
	fmt.Println("== 一个 Max 吃三种类型 ==")
	fmt.Println(Max(3, 9), Max(3.14, 2.72), Max("苹果", "梨")) // 字符串按字典序

	fmt.Println("== 泛型容器 ==")
	s := &Stack[string]{}
	s.Push("go")
	s.Push("zig")
	v, _ := s.Pop()
	fmt.Println(v, "还剩", s.Len())

	fmt.Println("== Filter / Map 管道 ==")
	words := []string{"go", "rust", "zig", "c"}
	shorts := Filter(words, func(w string) bool { return len(w) <= 2 })
	fmt.Println(shorts,
		Map(words, func(w string) int { return len(w) }),
		Map(shorts, strings.ToUpper))

	fmt.Println("== 自定义约束 ==")
	fmt.Println(Sum([]int{1, 2, 3}), Sum([]float64{0.5, 0.25}))
	type Meters int // 底层是 int → 过 ~int 这一关
	fmt.Println(Sum([]Meters{100, 200}))
}
