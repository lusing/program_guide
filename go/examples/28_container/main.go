// 28_container：heap 优先队列、list 双向链表、ring 环、sort.Search 谓词二分。
// 对照 docs/28-container.md。
package main

import (
	"container/heap"
	"container/list"
	"container/ring"
	"fmt"
	"sort"
)

// ---------- 小顶堆 ----------

// IntHeap 按 container/heap 协议实现的最小堆。
type IntHeap []int

func (h IntHeap) Len() int           { return len(h) }
func (h IntHeap) Less(i, j int) bool { return h[i] < h[j] }
func (h IntHeap) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }
func (h *IntHeap) Push(x any)        { *h = append(*h, x.(int)) }
func (h *IntHeap) Pop() any { // 协议规定：弹的是最后一个元素（库已把堆顶换到这里）
	old := *h
	n := len(old)
	x := old[n-1]
	*h = old[:n-1]
	return x
}

// HeapSort 用堆把切片排成升序（演示"反复取极值"的典型用法）。
func HeapSort(s []int) []int {
	h := IntHeap(s)
	heap.Init(&h)
	out := make([]int, 0, len(s))
	for h.Len() > 0 {
		out = append(out, heap.Pop(&h).(int))
	}
	return out
}

// ---------- 优先队列 ----------

// Task 是待调度任务。
type Task struct {
	Name     string
	Priority int // 数值越大越紧急
}

// TaskQueue 大顶堆：Priority 优先，平局按 Name 保证顺序确定。
type TaskQueue []Task

func (q TaskQueue) Len() int { return len(q) }
func (q TaskQueue) Less(i, j int) bool {
	if q[i].Priority != q[j].Priority {
		return q[i].Priority > q[j].Priority // 大顶堆：数值大先出
	}
	return q[i].Name < q[j].Name // 平局按名，保证顺序确定（测试才好断言）
}
func (q TaskQueue) Swap(i, j int) { q[i], q[j] = q[j], q[i] }
func (q *TaskQueue) Push(x any)   { *q = append(*q, x.(Task)) }
func (q *TaskQueue) Pop() any {
	old := *q
	n := len(old)
	x := old[n-1]
	*q = old[:n-1]
	return x
}

// PopAll 按优先级从高到低弹出全部任务。
func PopAll(q *TaskQueue) []string {
	out := make([]string, 0, q.Len())
	for q.Len() > 0 {
		out = append(out, heap.Pop(q).(Task).Name)
	}
	return out
}

// ---------- sort.Search ----------

// LowerBound 返回有序切片中第一个 >= target 的下标（可能等于 len）。
func LowerBound(a []int, target int) int {
	return sort.Search(len(a), func(i int) bool { return a[i] >= target })
}

// IntSqrt 求不小于平方根的最小整数（√x 向上取整）：谓词二分解单调方程。
func IntSqrt(x int) int {
	return sort.Search(x, func(i int) bool { return i*i >= x })
}

func main() {
	fmt.Println("== heap：协议五方法 + Init/Push/Pop ==")
	h := &IntHeap{5, 2, 8, 1}
	heap.Init(h)
	heap.Push(h, 3)
	for h.Len() > 0 {
		fmt.Print(heap.Pop(h).(int), " ")
	}
	fmt.Println()

	fmt.Println("== 堆排序（反复取极值）==")
	fmt.Println(HeapSort([]int{5, 2, 8, 1, 9, 3}))

	fmt.Println("== 优先队列：平局按名稳定 ==")
	q := &TaskQueue{}
	for _, t := range []Task{{"备份", 1}, {"告警", 9}, {"清理", 1}, {"发布", 5}} {
		heap.Push(q, t)
	}
	fmt.Println(PopAll(q))

	fmt.Println("== list：持句柄 O(1) 删除（LRU 的骨架）==")
	l := list.New()
	back := l.PushBack("a")
	mid := l.PushBack("b")
	l.PushBack("c")
	l.MoveToFront(mid) // 最近使用的挪到队头
	l.Remove(back)     // 淘汰最旧
	for e := l.Front(); e != nil; e = e.Next() {
		fmt.Print(e.Value, " ")
	}
	fmt.Println()

	fmt.Println("== ring：定长环形缓冲（最近 N 条）==")
	r := ring.New(3)
	logs := []string{"l1", "l2", "l3", "l4"}
	for _, ln := range logs {
		r.Value = ln
		r = r.Next() // 写满后自动绕回覆盖最旧的
	}
	// 起点在最后写入的结点：从这里 Do 一圈是 l2 l3 l4（l1 已被 l4 覆盖）
	r.Do(func(v any) { fmt.Print(v, " ") })
	fmt.Println()

	fmt.Println("== sort.Search：谓词二分 ==")
	a := []int{1, 3, 5, 7, 9}
	fmt.Println("第一个 >= 6 的下标:", LowerBound(a, 6), "值:", a[LowerBound(a, 6)])
	fmt.Println("都满足不了 → 返回 len:", LowerBound(a, 99))
	fmt.Println("IntSqrt(10) =", IntSqrt(10), "/ IntSqrt(16) =", IntSqrt(16))
}
