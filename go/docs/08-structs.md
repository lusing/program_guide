# 08 · 结构体与方法

> 对应示例：`examples/08_structs/`

## 8.1 定义与字面量

```go
type Rect struct {
	Min, Max Point    // 同类型字段并排
	Tag      string   // 命名式字面量的主力写法（空行分组是惯例）
}

r1 := Rect{Min: Point{0, 0}, Max: Point{3, 4}} // 命名式：抗变更，主力
r2 := Rect{Point{0, 0}, Point{3, 4}, ""}       // 位置式：加字段全崩，≤3 字段才用
r3 := Rect{Max: Point{3, 4}}                   // 缺省字段取零值
```

结构体是值类型：赋值、传参全字段复制。字段名大写 = 导出（包外可见），小写 = 私有（14 章可见性规则）。

## 8.2 方法：接收者决定"值方法"还是"指针方法"

```go
func (r Rect) Area() float64 { ... }        // 值接收者：拿到 r 的副本
func (r *Rect) Scale(k float64) { ... }     // 指针接收者：改的就是本体
```

选择法则：

| 场景 | 用 |
|---|---|
| 要修改自身 / 结构体大 / 一致性（已有指针方法） | `*T` |
| 只读小结构体 / map 元素等不可寻址场合 | `T` |

语法糖：**可寻址的值自动取地址**调指针方法——`r.Scale(2)` 背后是 `(&r).Scale(2)`，`value.Scale(3)` 对局部变量照样生效。坑在接口（09 章）：只有 `*Rect` 拥有 Scale 时，`Rect` 值塞进接口会缺方法，编译不过。

## 8.3 构造函数惯例：NewXxx

```go
func NewRect(x0, y0, x1, y1 float64) *Rect {   // 返回指针是主流
	if x1 < x0 || y1 < y0 {                     // 顺手做规范化/校验
		x0, y0, x1, y1 = x1, y1, x0, y0
	}
	return &Rect{Min: Point{x0, y0}, Max: Point{x1, y1}}
}
```

没有构造器语法、没有析构（GC 管），`NewXxx` 纯靠惯例。多个构造器就带后缀：`NewServerWithTLS(...)`。

## 8.4 Stringer：控制打印长相

```go
func (r Rect) String() string {
	return fmt.Sprintf("Rect(%.0f,%.0f)", r.Min.X, r.Min.Y)
}
fmt.Println(r)      // 自动调 String()——fmt.Stringer 接口
```

和 Java toString、Rust 的 `Display` 同席。实现了它，`%v` `%s` `Println` 全走你写的方法——**日志友好性的一半靠它**。

## 8.5 嵌入：组合替代继承

```go
type Person struct {
	Name string
	Age  int
}
func (p Person) Greet() string { return "我是 " + p.Name }

type Employee struct {
	Person            // 嵌入：只有类型名，没有字段名
	Company string
}

emp := Employee{Person: Person{"阿G", 30}, Company: "BigCorp"}
emp.Name        // 提升字段：直达 Person.Name
emp.Greet()     // 提升方法
emp.Person.Name // 显式走全路径也行
```

嵌入 = **编译器帮你写转发**（`emp.Greet()` → `emp.Person.Greet()`），不是继承：

- **没有多态**：`emp.Greet()` 的接收者是内层的 Person，Employee 覆盖不了它给"父类引用"看；
- 同名字段/方法时**外层遮蔽**内层，不重载；
- 多重嵌入撞名（两个内嵌类型都有 `Name`）→ 必须写全路径，否则编译错。

Go 的口号是"组合优于继承"——嵌入是把组合写顺手的语法糖。

## 8.6 结构体比较与拷贝

```go
Point{1, 2} == Point{1, 2}                 // true：字段全可比较 → 结构体可比较
// 含切片/map 字段的结构体 == 是编译错（不可比较），只能 reflect.DeepEqual
```

可比较结构体能当 **map 键**、能用 `==`——轻量值类型（坐标、区间）享受这套。函数返回大结构体不心疼：逃逸分析 + 值语义下 RVO 语义清晰，拷贝成本交给编译器。

## 8.7 结构体标签：元数据挂件

```go
type Profile struct {
	Name string `json:"name"`   // 反引号原始字符串：给 json/orm 等库看
}
```

标签本身不影响编译，`reflect` 读取（21 章 JSON 玩转它）。

## 8.8 坑位清单

1. **值接收者改字段是哑弹**：编译能过、逻辑静默失效——改状态必须指针接收者。
2. **接口方法集 mismatch**：指针方法只属于 `*T`；`var s Shape = value` 报"没实现"时先查这个（09 章）。
3. **nil 接收者调方法能跑**：`var p *Rect; p.Area()` 会 panic，但 `(*MyErr)(nil).Error()` 若不碰字段就能跑——typed-nil 的近亲（09 章大坑）。
4. **嵌入不是继承**：想覆写父类行为的多态设计搬不过来，改用接口 + 小类型组合。
5. **含切片字段的结构体复制是浅拷贝**：副本与本体共享底层数组——深拷贝自己写或用 `slices.Clone`。

---
