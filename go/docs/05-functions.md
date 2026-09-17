# 05 · 函数

> 对应示例：`examples/05_functions/`

## 5.1 多返回值：为错误而生

```go
func Div(a, b int) (int, error) {
	if b == 0 {
		return 0, errors.New("除数为零")
	}
	return a / b, nil
}

q, err := Div(7, 2)
if err != nil { ... }        // Go 的"异常处理"就是这三行，一天写五十遍
```

Go 没有异常。函数把"正常结果"和"错误"并排返回，调用方当场检查——**错误是值**（10 章展开）。惯用法两条：

- 不想要结果时 `_` 丢掉：`_, err := Div(1, 0)`；但 **err 不要丢**（vet 会唠叨）；
- 想看一眼又懒得接：`if _, err := f(); err != nil {`。

## 5.2 命名返回值与裸 return

```go
func Title(full string) (first, last string) {  // 返回值带名字
	parts := strings.SplitN(full, " ", 2)
	first = parts[0]
	if len(parts) == 2 {
		last = parts[1]
	}
	return                                          // 裸 return
}
```

命名返回值**进函数就被零值初始化**，裸 `return` 把它们带出去。短函数（<10 行）尚可，长函数里裸 return 是可读性黑洞——团队规范普遍禁用。它的正经用途是 defer 里改返回值（`defer func() { err = wrap(err) }()`，10 章见到）。

## 5.3 变参

```go
func Sum(nums ...int) int { }     // 函数内 nums 是 []int

Sum()                              // 零个
Sum(1, 2, 3)
Sum([]int{4, 5}...)                // 切片展开传入
```

`...T` 本质是"语法糖切片"。注意**传切片进去后函数内 append 可能影响外部**（06 章共享底层数组的坑在这里等着）。

## 5.4 defer：函数的退场仪式

```go
f, err := os.Open(path)
if err != nil { return err }
defer f.Close()          // 就地登记"退场前必做"，忘记关文件的 bug 从此绝迹
```

三条规则：

1. **LIFO**：多个 defer 按登记逆序执行（后进先出）；
2. **参数立刻求值**：`defer fmt.Println(x)` 记住的是登记瞬间的 x，不是执行时的；
3. defer 可以改命名返回值——panic 场景的兜底钩子。

```go
x := 1
defer fmt.Println("defer 记住的 x =", x)   // 打 1
x = 2
```

要"执行时的值"就包一层闭包：`defer func() { fmt.Println(x) }()`。

## 5.5 函数是一等值：闭包与高阶函数

```go
counter := 0
inc := func() int { counter++; return counter }   // 匿名函数

func Counter() func() int {   // 闭包 = 函数 + 捕获的环境
	count := 0
	return func() int { count++; return count }
}
next := Counter()
next(); next()   // 1, 2——count 活在闭包里，外面摸不到

doubled := Apply([]int{1, 2}, func(n int) int { return n * 2 })  // 高阶函数
```

标准库的 `sort.Slice(s, less)`、`http.HandlerFunc`、迭代器（13 章）全都建立在这块地基上。

**1.22 前后对比**（并发第一大坑，如今已填平）：

```go
for i := 0; i < 3; i++ {
	go func() { fmt.Println(i) }()  // 1.21：三个"3"（共享同一个 i）
}                                    // 1.22+：0,1,2（每轮新副本）
```

老代码里 `func() { ... } (i)` 手动传副本的写法已成历史，但面试还爱考。

## 5.6 没有重载、没有默认参数

同一个包里 `func f(a int)` 和 `func f(a, b int)` 不能共存，参数默认值也不存在。替代方案：变参、options 模式（`func New(opts ...Option)`）、或干脆起两个名字。少一个特性，少十种"调用姿势猜猜看"。

## 5.7 init 函数：包的自动初始化

每个包可以有零或多个 `func init()`，在 main 之前自动执行（14 章展开）。能用变量初始化表达式解决的别用 init。

## 5.8 坑位清单

1. **defer 参数立刻求值**：循环里 `defer f.Close(i)` 记的全是当时的 i——要延迟求值就套闭包。
2. **裸 return + 命名返回值**：函数中段 return 全靠读函数头才知道返回什么——长函数禁用。
3. **变参传切片再 append**：函数里 append 可能踩到调用方切片的内存（06 章三下标切片讲为什么）。
4. **循环里 defer**：defer 挂在函数不是循环上，循环一千次就攒一千个——把循环体抽成函数，或手动管理。
5. **err 被丢弃**：`f()` 单独成行丢错误——vet 的 unusedresult 检查器抓的就是这个。

---
