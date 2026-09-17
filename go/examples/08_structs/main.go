// 08_structs：结构体、值/指针接收者、构造函数惯例、嵌入组合、Stringer。
package main

import "fmt"

// Point 小结构体：值语义传递合适（够小、不需要共享）。
type Point struct {
	X, Y float64
}

func (p Point) Dist2() float64 { return p.X*p.X + p.Y*p.Y } // 值接收者：拿到副本

// Rect 的构造函数：Go 没有构造器语法，NewXxx 惯例补位。
type Rect struct {
	Min, Max Point
}

func NewRect(x0, y0, x1, y1 float64) *Rect {
	if x1 < x0 || y1 < y0 { // 规范化：把角点整理成"左下-右上"
		x0, y0, x1, y1 = x1, y1, x0, y0
	}
	return &Rect{Min: Point{x0, y0}, Max: Point{x1, y1}}
}

func (r Rect) Area() float64 {
	return (r.Max.X - r.Min.X) * (r.Max.Y - r.Min.Y)
}

// Scale 修改自身：必须指针接收者。值接收者只改副本（编译能过、逻辑是错的）。
func (r *Rect) Scale(k float64) {
	r.Min.X *= k
	r.Min.Y *= k
	r.Max.X *= k
	r.Max.Y *= k
}

// String 实现 fmt.Stringer：Println/%v 会自动调它。
func (r Rect) String() string {
	return fmt.Sprintf("Rect(%.0f,%.0f %g×%g)",
		r.Min.X, r.Min.Y, r.Max.X-r.Min.X, r.Max.Y-r.Min.Y)
}

// Person 将被嵌入 Employee：字段和方法都会被"提升"。
type Person struct {
	Name string
	Age  int
}

func (p Person) Greet() string { return "我是 " + p.Name }

// Employee 嵌入 Person——Go 的"继承"其实是组合 + 名字提升。
type Employee struct {
	Person  // 嵌入的是类型，不是命名字段
	Company string
	Salary  float64
}

func main() {
	fmt.Println("== 字面量两种写法 ==")
	p1 := Point{1, 2}       // 位置式：加字段就全崩，只适合 2-3 个字段
	p2 := Point{X: 3, Y: 4} // 命名式：可读、抗变更，主力
	fmt.Println(p1, p2, p2.Dist2())

	fmt.Println("== 构造函数与接收者 ==")
	r := NewRect(3, 4, 0, 0) // 传反了角点，构造函数负责规范化
	fmt.Println(r.Area())
	r.Scale(2) // 语法糖：Go 自动取 r 的地址调用指针方法
	fmt.Println(r)

	value := Rect{Min: Point{0, 0}, Max: Point{2, 2}}
	value.Scale(3) // 局部变量可寻址，同样自动取地址，改的就是它
	fmt.Println(value.Area())

	fmt.Println("== 嵌入：组合替代继承 ==")
	emp := Employee{Person: Person{"阿 G", 30}, Company: "BigCorp", Salary: 100}
	fmt.Println(emp.Name)           // 提升字段：直接点出来
	fmt.Println(emp.Greet())        // 提升方法
	fmt.Println(emp.Person.Greet()) // 显式走全路径也行

	fmt.Println("== 结构体比较 ==")
	fmt.Println(Point{1, 2} == Point{1, 2}) // 字段全部可比较 → 可 ==、可当 map 键
	fmt.Println(Rect{Min: Point{1, 1}, Max: Point{2, 2}} == *NewRect(1, 1, 2, 2))
}
