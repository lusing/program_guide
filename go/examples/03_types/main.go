// 03_types：零值、声明三件套（var/:=/const）、iota 枚举、显式转换。
package main

import (
	"fmt"
	"math"
)

// Weekday 用 const + iota 做枚举（Go 没有 enum 关键字）。
type Weekday int

const (
	Sunday Weekday = iota // 从 0 开始递增
	Monday
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
)

// String 实现 fmt.Stringer，让 %v / Println 打名字而不是数字。
func (d Weekday) String() string {
	return [...]string{"周日", "周一", "周二", "周三", "周四", "周五", "周六"}[d]
}

// 新命名类型：即使底层都是 float64，Celsius 与 Fahrenheit 也不能混算。
type Celsius float64
type Fahrenheit float64

func CToF(c Celsius) Fahrenheit { return Fahrenheit(c*9/5 + 32) }

// Clamp 夹在 [lo, hi]：min/max 是 1.21+ 内建，不是库函数。
func Clamp(v, lo, hi int) int {
	return min(max(v, lo), hi)
}

func main() {
	fmt.Println("== 零值：Go 没有\"未初始化\"这回事 ==")
	var i int
	var f float64
	var s string
	var b bool
	var p *int
	fmt.Println(i, f, s == "", b, p == nil) // 0 0 "" false nil

	fmt.Println("== 声明三件套 ==")
	var name string = "显式类型" // 完整形态：包级或零值明确时用
	var age = 18             // 省类型：靠右值推断
	const pi = 3.14159       // 无类型常量：精度任意，用时才定型
	fmt.Println(name, age, pi*2)

	fmt.Println("== 显式转换：Go 不做隐式 ==")
	var big int64 = 1 << 40
	small := int32(big) // 截断：2^40 的低 32 位全是 0 → 得 0，编译器不拦
	fmt.Println(big, small)
	f64 := 3.99
	fmt.Println(int(f64))             // 向零截断 → 3
	fmt.Println(int(math.Round(f64))) // 四舍五入要显式 Round → 4

	fmt.Println("== iota 枚举 ==")
	fmt.Println(Monday, Saturday) // 打的是中文名（Stringer 生效）

	fmt.Println("== 新命名类型 ==")
	c := Celsius(37.0)
	fmt.Printf("体温 %g°C = %g°F\n", c, CToF(c))

	fmt.Println("== min/max/clear 内建（1.21+） ==")
	fmt.Println(Clamp(150, 0, 100), min(3, 1, 2), max(3, 1, 2))
	nums := []int{1, 2, 3, 4}
	clear(nums) // 切片/映射清空
	m := map[string]int{"a": 1}
	clear(m)
	fmt.Println(nums, len(m))
}
