# 09 · 接口 ⭐

> 对应示例：`examples/09_interfaces/`

接口是 Go 最有味道的设计——**它把"谁实现谁"的方向反转了**。

## 9.1 隐式实现：实现者不用签字

```go
type Shape interface {
	Area() float64
}

type Rect struct{ W, H float64 }
func (r Rect) Area() float64 { return r.W * r.H }   // 没写 implements Shape！

shapes := []Shape{Rect{3, 4}, Circle{1}}            // 直接装进去
```

只要方法集对得上，类型就实现了接口——**接口在消费方定义，生产方毫不知情**。你给自己的类型加个 `Write(p []byte) (int, error)`，它立刻是 `io.Writer`，标准库 writers 全部认账。对比 Java/C# 的显式 implements：第三方类型实现你接口的"事后追认"只有隐式模型做得到。

## 9.2 接口值 = (动态类型, 动态值) 两元组

```go
var s Shape            // (nil, nil)
fmt.Println(s == nil)  // true

s = Rect{3, 4}         // (Rect, {3 4})
fmt.Printf("%T\n", s)  // main.Rect——类型信息跟着走
v := s.Area()          // 动态派发到 Rect.Area
```

接口不是指针，是**16 字节的小盒子**（类型指针 + 数据指针）。装值进去类型信息保留——`%T`、类型断言、反射都靠它。

## 9.3 类型断言与类型 switch

```go
if s, ok := v.(Shape); ok {          // 逗号 ok：断言失败不 panic
	fmt.Println(s.Area())
}

switch x := v.(type) {               // 类型 switch（04 章见过）
case int:      fmt.Println(x + 1)    // 每个分支里 x 自动是断言后的类型
case string:   fmt.Println(len(x))
}
```

单断言不带 ok（`v.(Shape)`）失败直接 **panic**——只在"我百分百确定"或"panic 即 bug"的场合用。

## 9.4 typed-nil：接口第一大坑

```go
type MyError struct{ Msg string }
func (e *MyError) Error() string { return e.Msg }

func BadRelease() error {
	var e *MyError      // e == nil
	return e            // 装进接口：(类型 *MyError, 值 nil) → != nil！
}

err := BadRelease()
fmt.Println(err == nil)    // false——明明"返回了 nil"
```

接口的 nil 判断要求**两元组都空**。具体类型的 nil 指针塞进 error 接口，类型那一半非空，`== nil` 就是 false。调用方 `if err != nil` 误判"出错了"。**正确姿势：返回具体的 nil 字面量，别返回具体类型的 nil 指针变量**：

```go
func GoodRelease() error { return nil }
```

## 9.5 小接口哲学：接口由使用方定义

标准库的镇馆之宝没有一个超过 3 个方法：

| 接口 | 方法数 | 一句话 |
|---|---|---|
| `error` | 1 | `Error() string` |
| `fmt.Stringer` | 1 | 控制打印 |
| `io.Reader` / `io.Writer` | 1 | 一切 IO 的地基（20 章） |
| `sort.Interface` | 3 | Len/Less/Swap |
| `http.Handler` | 1 | 一个函数就是一个服务（22 章） |

设计法则：**先写消费代码，长出最小接口**——函数参数要什么方法，接口就声明什么方法。十几方法的大接口（Java 风）在 Go 是设计事故。`any`（= `interface{}`）是逃生舱不是常规武器——用了它就意味着接下来要类型断言/反射。

## 9.6 接口的接缝

```go
type ReadWriter interface {     // 接口组合：小接口拼大接口
	Reader
	Writer
}
```

- **空接口 `any`** 能装一切，但取出来要断言——静态类型检查到此为止；
- **接口不能装接口自己循环嵌入**；
- 值实现的方法集 = 值方法；指针实现 = 值 + 指针方法（08 章坑位的根源）。

## 9.7 常见标准接口速查

| 接口 | 实现 after-effects |
|---|---|
| `fmt.Stringer` | `String() string`：Println/%v 调它 |
| `error` | `Error() string`：成为错误（10 章） |
| `io.Reader`/`Writer` | 接入全部 IO 管道（20 章） |
| `sort.Interface` | `sort.Sort` 认你（12 章） |
| `json.Marshaler` | 自定义序列化（21 章） |

## 9.8 坑位清单

1. **typed-nil**（9.4 节全坑）：函数返回 `*MyErr` 类型的 nil 变量当 error → 调用方 `err != nil` 误判——返回 `nil` 字面量。
2. **值装接口丢指针方法**：`var s Shape = rect` 编译不过（Scale 只在 `*Rect` 上）——装指针 `&rect` 或给值也补方法。
3. **断言不带 ok 失败即 panic**：不确定就永远写 `v, ok := x.(T)`。
4. **接口比较的暗雷**：两个接口可比较，但动态类型不可比较（存了切片）时 `==` 直接 panic。
5. **nil 接收者方法调用**：接口非 nil 但值为 nil，方法里解引用才炸——方法开头 `if e == nil` 防御是标准库惯例。

---
