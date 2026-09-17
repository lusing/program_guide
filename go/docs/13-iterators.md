# 13 · 迭代器：range over func ⭐

> 对应示例：`examples/13_iterators/`

1.23 起，**函数可以直接被 for range**——自定义类型从此不用实现任何接口就能进循环。

## 13.1 迭代器就是一个函数

```go
type Seq[V any] func(yield func(V) bool)      // 标准库 iter.Seq

func IntRange(lo, hi int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for i := lo; i < hi; i++ {
			if !yield(i) {       // yield 返回 false = 调用方 break 了
				return           // 生成器立刻停止：不浪费一步
			}
		}
	}
}

for i := range IntRange(0, 5) { fmt.Print(i) }   // 0 1 2 3 4
```

机制：`yield` 是**编译器塞进来的回调**。循环体变成 yield 的函数体；`break` 让 yield 返回 false，生成器据此收摊。对比 C++ 的 iterator 对象（要写 begin/end/++/== 五件套）——一个函数搞定。

## 13.2 Seq2：双值序列

```go
type Seq2[K, V any] func(yield func(K, V) bool)

for k, v := range Pairs(keys, vals) { }    // 键值对迭代
for i, v := range slices.Backward(s) { }   // 反向带下标
```

`map` 的 range、`slices.Backward`、`maps.Keys` 背后全是 Seq2/Seq。

## 13.3 给自己的类型长出 range

```go
type List struct { head, tail *node }

func (l *List) All() iter.Seq[int] {
	return func(yield func(int) bool) {
		for n := l.head; n != nil; n = n.next {
			if !yield(n.val) {
				return
			}
		}
	}
}

for v := range list.All() { }    // 自定义容器直接进循环
```

`slices.Values(s)`、`maps.Keys(m)` 就是这个模式的标准库版本。**All() 每次调用生成新迭代器，容器本身不锁状态**——遍历时改容器照样是你的责任。

## 13.4 适配器：Seq 进 Seq 出

```go
func Filter[V any](seq iter.Seq[V], keep func(V) bool) iter.Seq[V] {
	return func(yield func(V) bool) {
		for v := range seq {
			if keep(v) && !yield(v) {
				return
			}
		}
	}
}

evens := Filter(IntRange(0, 10), func(v int) bool { return v%2 == 0 })
fmt.Println(slices.Collect(evens))    // [0 2 4 6 8]
```

惰性求值：定义 evens 时一个数都没生成，Collect 才驱动整条管道——**中间不落切片**（对比 12 章 Collect 才落地的语义）。

## 13.5 标准库现成货

| 出处 | 迭代器 |
|---|---|
| `slices` | `Values`、`Backward`、`Sorted`、`Collect`、`AppendSeq`、`EqualFunc`… |
| `maps` | `Keys`、`Values`（1.23+ 起返回 Seq） |
| `strings` | `SplitSeq`、`FieldsSeq`、`LinesSeq`（1.24+，gopls 会建议你换） |
| `iter` | `Pull`（见下） |

`strings.SplitSeq(s, ",")` 替代 `strings.Split`——不落中间切片，老代码 modernize 会自动提示。

## 13.6 iter.Pull：推改拉

```go
next, stop := iter.Pull(IntRange(5, 10))
defer stop()                 // 用完必 stop，让生成器执行清理

v, ok := next()              // 5, true
v, ok = next()               // 6, true
```

range 是**推模式**（生成器主动喂）；`Pull` 把迭代器翻成**拉模式**（我要一个你给一个）——需要中途穿插别的逻辑、或把两个迭代器交错消费时用。代价是生成器跑在后台 goroutine 里，必须 stop 善后。

## 13.7 什么时候还是手写循环

迭代器适合"**序列语义**"（遍历、过滤、变换）。一次性算法、需要提前多出口的复杂逻辑、性能敏感内循环——普通 for 更直白。迭代器是工具不是教义。

## 13.8 坑位清单

1. **yield 返回 false 必须停**：拿到 false 还继续循环 = 调用方已经 break 了你还狂生成——不仅浪费，行为未定义。
2. **迭代器里别改容器**：遍历中 append/删除元素，行为和普通循环一样不可靠。
3. **Pull 不 stop 泄漏 goroutine**：defer stop() 是标配（1.23 时代还会真泄漏，现在靠 GC 兜底但语义上仍应显式关）。
4. **老教程的接口式迭代器**：`type Iterator interface { Next() bool }` 是 1.23 前的民间方案——新代码一律 Seq 函数。
5. **Seq 是一次性的吗**：取决于实现——每次调用 `list.All()` 得到新迭代器是惯例，复用同一个 Seq 变量两次以上前先看它的实现。

---
