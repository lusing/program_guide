# 28 · 容器：heap / list / ring 与二分查找

> 对应示例：`examples/28_container/`。切片 + map（06/07 章）覆盖九成场景；这三个老容器各有一席之地。

## 28.1 container/heap：实现五个方法，换一个堆

```go
type IntHeap []int
func (h IntHeap) Len() int            { return len(h) }
func (h IntHeap) Less(i, j int) bool  { return h[i] < h[j] }   // < 小顶堆；> 大顶堆
func (h IntHeap) Swap(i, j int)       { h[i], h[j] = h[j], h[i] }
func (h *IntHeap) Push(x any)         { *h = append(*h, x.(int)) }
func (h *IntHeap) Pop() any {
	old := *h
	n := len(old)
	x := old[n-1]
	*h = old[:n-1]
	return x
}

heap.Init(h)      // 已有数据整理成堆（O(n)）
heap.Push(h, 3)   // 插入（注意：传指针——要改底层数组）
heap.Pop(h)       // 弹出堆顶（最小/最大）
heap.Fix(h, i)    // 第 i 个元素的优先级变了，就地修复
heap.Remove(h, i) // 删掉第 i 个
```

协议的坑设计得很故意：**Push/Pop 用指针接收者**（它们改切片），Len/Less/Swap 用值接收者——拷贝一个 heap 类型出来用，堆就悄悄坏了（vet 的 copylocks 抓不到这种逻辑错）。另一个高频错：**Pop 是你自己实现的**——习惯性以为库帮你弹了，结果 `heap.Pop(h)` 内部调你的 Pop，两个都写就乱了。规矩：库里管上下滤，**进出堆都必须走 heap.Push/heap.Pop，别直接 append**。

## 28.2 优先队列：堆的正经用法

```go
type Task struct {
	Name     string
	Priority int
}
type TaskQueue []Task
// ...Less 按 Priority 比（相同优先级比 Name，保证出队顺序确定）

// 排期：不停"塞任务、取最紧急的"——排序每次 O(n log n)，堆每次 O(log n)
```

Top-K（流式数据里维护前 K 大）、Dijkstra、定时器队列、合并 K 个有序流——凡是"反复取极值"的场景都是堆。**一次排完不再动的直接 `slices.Sort`**（12 章），别硬套堆。

## 28.3 container/list：双向链表

```go
l := list.New()
e1 := l.PushBack(1)        // 返回 *Element（结点句柄）
e2 := l.PushFront(2)
l.InsertBefore(0, e1)      // 拿着句柄 O(1) 插
l.Remove(e2)               // 拿着句柄 O(1) 删
for e := l.Front(); e != nil; e = e.Next() {
    fmt.Println(e.Value)   // any 类型，取回要断言
}
```

链表的唯一优势是**持句柄 O(1) 删除**（LRU 缓存的键→结点 map 就是标准配合）。`e.Value` 是 `any`——类型安全自己负责。**List 不能浅拷贝**（复制结构等于拆散链子），零值 List 可直接用但别值传递。

## 28.4 container/ring：定长环

```go
r := ring.New(3)           // 3 个空结点的环
for i := 0; i < 3; i++ { r.Value = i; r = r.Next() }
r.Do(func(v any) { ... })  // 遍历一圈
r.Move(n) / r.Prev() / r.Link(...) / r.Unlink(n)
```

环形缓冲（最近 N 条日志、滑动窗口）用它省掉自己管理下标。`ring.New(1)` 合法但 `New(0)` 返回 nil——**容量至少为 1**。

## 28.5 sort.Search：谓词二分

12 章的 `slices.BinarySearch(x, target)` 只会找"具体的值"；`sort.Search` 找"**第一个满足谓词的下标**"——谓词单调（前假后真）即可：

```go
// 有序切片里找第一个 >= target 的位置（等于 std::lower_bound）
i := sort.Search(len(a), func(i int) bool { return a[i] >= target })

// 完全不碰切片：解方程"第一个 f(i) 为真的 i"（f 单调）
n := sort.Search(math.MaxInt, func(i int) bool { return i*i >= x }) // 平方根取整
```

`sort.Search` 返回的范围是 `[0, n]`——**可能返回 n**（全都满足不了/都不满足时）。全都不满足谓词时返回 0，要区分"找到了"与"没有"：`if i < len(a) && a[i] == target`。

## 28.6 选型速查

| 场景 | 用 |
|---|---|
| 一次排序 | `slices.Sort`（12 章） |
| 流式反复取极值 / Top-K | `container/heap` |
| 持句柄 O(1) 删除（LRU） | `container/list` + map |
| 定长环形缓冲 | `container/ring` |
| 找具体值 | `slices.BinarySearch` |
| 找边界/解单调方程 | `sort.Search` |

## 28.7 坑位清单

1. **heap.Push 传值不传指针**：编译不过（协议就是指针）——但自作聪明绕过去后堆不更新，静默错。
2. **自己调自己的 Push/Pop**：进出堆只走 `heap.Push/heap.Pop`，自己那两个方法是被库回调的。
3. **Pop 写成取 h[0]**：协议规定弹的是**最后一个元素**（库在调用你之前已把堆顶换到末尾）——抄标准注释实现，别自由发挥。
4. **List 值拷贝**：拆链子——一律 `*list.List` + `list.New()`。
5. **`e.Value` 忘了断言**：它是 any，比较/运算前要 `.(Task)`。
6. **sort.Search 越界**：可能返回 len——用前先 `i < len(a)` 判界。
7. **ring.New(1-n)**：容量 0 返回 nil，下一个调用就 nil panic。

---
