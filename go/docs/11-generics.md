# 11 · 泛型 ⭐

> 对应示例：`examples/11_generics/`

Go 1.18（2022 年）才补上泛型——此前十年"复制粘贴三个类型的 Max"是日常。设计取向：**够用就好，不做 C++ 模板元编程**。

## 11.1 泛型函数：类型参数 + 约束

```go
func Max[T cmp.Ordered](a, b T) T {
	if a > b {
		return a
	}
	return b
}

Max(3, 9)          // T 推断为 int
Max(3.14, 2.72)    // float64
Max("苹果", "梨")   // string（字典序）
```

`[T cmp.Ordered]` 是类型参数；`cmp.Ordered` 是**约束**（constraint）——允许哪些类型进来。没有约束编译器不敢用 `>`（哪些类型支持比较？）。

标准库常备约束（都在 `cmp` 和 `cmp` 以外两处）：

| 约束 | 含义 |
|---|---|
| `any` | 无约束（= interface{}） |
| `comparable` | 可用 == 比较（能当 map 键） |
| `cmp.Ordered` | 支持 < > 比较的全部数值与字符串 |

## 11.2 泛型类型

```go
type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) { s.items = append(s.items, v) }

func (s *Stack[T]) Pop() (T, bool) {
	if len(s.items) == 0 {
		var zero T          // 泛型里拿零值：声明即可
		return zero, false
	}
	top := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return top, true
}

s := &Stack[string]{}
```

注意**方法不重复声明类型参数**：接收者 `*Stack[T]` 带来了 T，方法里直接用。

## 11.3 自定义约束：类型集合

```go
type Number interface {
	~int | ~int64 | ~float64    // | 列举类型；~ 表示"底层类型是"
}

func Sum[T Number](nums []T) T { ... }

type Meters int
Sum([]Meters{100, 200})     // ~int 放行：Meters 底层是 int
```

`~int` 的波浪号是关键：不带 `~` 只有裸 int 过关，所有 `type X int` 命名类型全被拒——约束几乎总是要 `~`。

## 11.4 泛型管道函数

```go
func Filter[T any](in []T, keep func(T) bool) []T
func Map[T, U any](in []T, f func(T) U) []U    // 类型可以多个
```

这两个（以及标准库 13 章的迭代器）覆盖了大部分"以前要反射"的场景。

## 11.5 什么时候不用泛型

泛型解决"**多个类型、同一套逻辑**"。它不解决：

- **运行时才知道类型** → 那是 `any` + 类型断言/反射的活；
- **一个类型的一套逻辑** → 普通函数足够；
- **接口能表达的事** → 小接口 + 具体类型通常更 Go 味（`io.Reader` 比 `Read[T]` 优雅）。

标准库团队的建议原话大意：从具体类型开始写，第三个类型出现时再抽象成泛型。

## 11.6 性能注脚

Go 泛型用 GC shape stenciling：同"形状"（指针/直接存值分类）共享一份代码，值类型有字典开销——**别指望 C++ 模板那种零成本**。日常代码无感，热点路径先测再抽象。

## 11.7 泛型改变了哪些标准库

1.21 起标准库批量泛型化，**新代码请默认用这些**（12 章专讲）：`slices`（Sort/Index/Contains/Equal…）、`maps`（Clone/Copy/Keys…）、`sync.Map` 之外还有 `atomic.Pointer[T]`。老的 `sort.Ints` / `container/list` 进入维护模式。

## 11.8 坑位清单

1. **约束忘了 ~**：`int | int64` 拒绝 `type Meters int`——自定义数值约束基本都要 `~`。
2. **泛型方法不存在**：`func (s Stack[T]) Map[U any](...)` 编译错——方法不能有自己的类型参数，只有函数可以（设计取舍，暂时无解）。
3. **推断失败要显式补**：`FromJSON[Profile](data)`（21 章）——空切片、any 参数等场景编译器推不出 T，方括号显式给。
4. **comparable ≠ Ordered**：可 == 未必可 <（结构体可比但不能排序）；排序约束用 `cmp.Ordered`。
5. **别拿泛型写抽象大词**：`Monad[T]`、`Functor[T]` 风格在 Go 水土不服——接口 + 组合才是本地哲学。

---
