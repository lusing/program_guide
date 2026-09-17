// 13_iterators：range over func（1.23+）——迭代器就是普通函数。
package main

import (
	"fmt"
	"iter"
	"slices"
)

// IntRange 生成 [lo, hi)：迭代器 = func(yield func(T) bool)。
func IntRange(lo, hi int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for i := lo; i < hi; i++ {
			if !yield(i) { // yield 返回 false = 调用方 break 了
				return
			}
		}
	}
}

// Filter 迭代器适配器：进一个 Seq，出一个 Seq，不落中间切片。
func Filter[V any](seq iter.Seq[V], keep func(V) bool) iter.Seq[V] {
	return func(yield func(V) bool) {
		for v := range seq {
			if keep(v) && !yield(v) {
				return
			}
		}
	}
}

// List 自定义容器 + All 方法：让 *List 直接被 for range。
type List struct {
	head, tail *node
	len        int
}

type node struct {
	val  int
	next *node
}

func (l *List) Push(v int) {
	n := &node{val: v}
	if l.tail == nil {
		l.head = n
	} else {
		l.tail.next = n
	}
	l.tail = n
	l.len++
}

// All 返回遍历自身的迭代器（标准库 slices.Values 就是这个模式）。
func (l *List) All() iter.Seq[int] {
	return func(yield func(int) bool) {
		for n := l.head; n != nil; n = n.next {
			if !yield(n.val) {
				return
			}
		}
	}
}

// Pairs 演示 Seq2：双值序列（键值对）。
func Pairs[K, V any](keys []K, vals []V) iter.Seq2[K, V] {
	return func(yield func(K, V) bool) {
		for i, k := range keys {
			if i >= len(vals) {
				return
			}
			if !yield(k, vals[i]) {
				return
			}
		}
	}
}

func main() {
	fmt.Println("== 自定义序列 ==")
	for i := range IntRange(0, 5) {
		fmt.Print(i, " ")
	}
	fmt.Println()

	fmt.Println("== 提前 break：生成器立刻停 ==")
	for i := range IntRange(0, 100) {
		if i >= 3 {
			break
		}
		fmt.Print(i, " ")
	}
	fmt.Println()

	fmt.Println("== 适配器组合（不落中间切片） ==")
	evens := Filter(IntRange(0, 10), func(v int) bool { return v%2 == 0 })
	fmt.Println(slices.Collect(evens)) // 迭代器 → 切片

	fmt.Println("== 自定义容器被 range ==")
	list := &List{}
	for v := range []int{10, 20, 30} {
		list.Push(v)
	}
	for v := range list.All() {
		fmt.Print(v, " ")
	}
	fmt.Println()

	fmt.Println("== Seq2 双值 ==")
	for k, v := range Pairs([]string{"a", "b"}, []int{1, 2}) {
		fmt.Printf("%s=%d ", k, v)
	}
	fmt.Println()

	fmt.Println("== 标准库现成货 ==")
	words := []string{"go", "zig", "c"}
	for i, w := range slices.Backward(words) { // 反向带下标
		fmt.Printf("[%d]%s ", i, w)
	}
	fmt.Println()

	fmt.Println("== iter.Pull：推模式变拉模式 ==")
	next, stop := iter.Pull(IntRange(5, 10))
	defer stop() // 惯例：用完必须 stop，让生成器善后
	v1, _ := next()
	v2, _ := next()
	fmt.Println("手动拉两次:", v1, v2)
}
