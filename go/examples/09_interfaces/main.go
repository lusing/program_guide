// 09_interfaces：隐式实现、接口值两元组、断言、typed-nil 大坑。
package main

import "fmt"

// Shape 小接口：Go 的哲学是"接口由使用方定义"，越小越有用。
type Shape interface {
	Area() float64
}

type Rect struct{ W, H float64 }

func (r Rect) Area() float64 { return r.W * r.H }

type Circle struct{ R float64 }

func (c Circle) Area() float64 { return 3.141592653589793 * c.R * c.R }

// TotalArea 只依赖 Area 方法：任何实现了 Shape 的类型都能传，
// 包括将来才写的类型——隐式实现，接口不用认领实现者。
func TotalArea(shapes []Shape) float64 {
	total := 0.0
	for _, s := range shapes {
		total += s.Area()
	}
	return total
}

// Describe 用类型断言（逗号 ok 形态）逐个试。
func Describe(v any) string {
	if s, ok := v.(Shape); ok {
		return fmt.Sprintf("Shape，面积 %g", s.Area())
	}
	if i, ok := v.(int); ok {
		return fmt.Sprintf("整数 %d", i)
	}
	return fmt.Sprintf("类型 %T", v)
}

// MyError 演示 typed-nil：*MyError 的 nil 塞进 error 接口后 != nil。
type MyError struct{ Msg string }

func (e *MyError) Error() string { return "MyError: " + e.Msg }

// BadRelease 永远返回"非 nil"的接口错误——经典事故现场。
func BadRelease() error {
	var e *MyError // e 本身是 nil
	return e       // 接口 = (类型 *MyError, 值 nil) → 与 nil 比较为 false
}

// GoodRelease 正确姿势：直接返回字面量 nil。
func GoodRelease() error {
	return nil
}

func main() {
	fmt.Println("== 隐式实现：一个接口吃多种类型 ==")
	shapes := []Shape{
		Rect{W: 3, H: 4},
		Circle{R: 1},
	}
	fmt.Println(TotalArea(shapes))

	fmt.Println("== 接口值 = (动态类型, 动态值) ==")
	var s Shape
	fmt.Println("空接口值 == nil:", s == nil)
	s = shapes[0]
	fmt.Printf("%T %v\n", s, s) // 存进接口后，类型信息还在

	fmt.Println("== 类型断言 ==")
	for _, v := range []any{shapes[1], 42, "文本"} {
		fmt.Println(" ", Describe(v))
	}

	fmt.Println("== typed-nil：接口第一大坑 ==")
	err := BadRelease()
	fmt.Println("BadRelease()  == nil ?", err == nil)           // false！
	fmt.Println("GoodRelease() == nil ?", GoodRelease() == nil) // true

	fmt.Println("== any 只是 interface{} 的别名 ==")
	var x any = 19
	fmt.Println(x, fmt.Sprintf("%T", x))
}
