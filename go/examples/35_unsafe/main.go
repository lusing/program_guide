// 35_unsafe：Sizeof/Alignof/Offsetof 布局、unsafe.String/Slice 零拷贝与纪律。
// 对照 docs/35-unsafe.md。
package main

import (
	"fmt"
	"unsafe"
)

// Padded 字段顺序糟糕：A 后 7 字节填充，C 后又有 7 字节。
type Padded struct {
	A bool
	B int64
	C bool
}

// Packed 调整顺序后 A、C 共享填充。
type Packed struct {
	B int64
	A bool
	C bool
}

// ZeroCopyString []byte → string 零拷贝。
// 纪律：调用之后 b 冻结（不许再写）——string 的不可变性靠调用方维持。
func ZeroCopyString(b []byte) string {
	if len(b) == 0 {
		return ""
	}
	return unsafe.String(unsafe.SliceData(b), len(b))
}

// WritableView string → []byte 可写视图。
// 纪律：只对"底层确实是自己 byte 切片"的串用（本示例里与 ZeroCopyString 配对）。
func WritableView(s string) []byte {
	if len(s) == 0 {
		return nil
	}
	return unsafe.Slice(unsafe.StringData(s), len(s))
}

func main() {
	fmt.Println("== Sizeof / Offsetof：字段顺序决定内存 ==")
	var p Padded
	fmt.Printf("Padded: sizeof=%d  A@%d B@%d C@%d\n",
		unsafe.Sizeof(p), unsafe.Offsetof(p.A), unsafe.Offsetof(p.B), unsafe.Offsetof(p.C))
	var q Packed
	fmt.Printf("Packed: sizeof=%d  B@%d A@%d C@%d\n",
		unsafe.Sizeof(q), unsafe.Offsetof(q.B), unsafe.Offsetof(q.A), unsafe.Offsetof(q.C))
	fmt.Printf("同样的三个字段，省了 %d 字节（%.0f%%）\n",
		unsafe.Sizeof(p)-unsafe.Sizeof(q),
		100*float64(unsafe.Sizeof(p)-unsafe.Sizeof(q))/float64(unsafe.Sizeof(p)))

	fmt.Println("== Alignof：对齐要求 ==")
	fmt.Println("bool:", unsafe.Alignof(bool(false)), "/ int64:", unsafe.Alignof(int64(0)),
		"/ string:", unsafe.Alignof(""), "/ 切片头:", unsafe.Alignof([]int(nil)))

	fmt.Println("== 零拷贝：string(b) 的分配账 ==")
	buf := []byte("一段不算短的文本，用于演示拷贝的代价与零拷贝的收益")
	s := ZeroCopyString(buf)
	fmt.Println("视图相等:", s == string(buf), "/ 同一底层:",
		unsafe.StringData(s) == unsafe.SliceData(buf))

	fmt.Println("== 可写视图：底层是自己的 byte 切片才敢用 ==")
	view := WritableView(s)
	view[0] = 'X' // 改的是 buf 的第 0 字节——三方（buf/s/view）看见同一份字节
	fmt.Printf("buf 开头=%q s 开头=%q view[0]=%c\n", buf[:4], s[:4], view[0])

	fmt.Println("== 合法通道 1：布局相同的 *T1 → *T2 ==")
	type Celsius float64
	type Fahrenheit float64 // 与 Celsius 内存布局相同：一个 float64
	c := Celsius(100)
	f := (*Fahrenheit)(unsafe.Pointer(&c)) // 重解释，不搬数据
	fmt.Printf("100°C = %v°F（共享同一块内存）\n", *f*9/5+32)

	fmt.Println("== 教学结束：业务代码先怀疑设计，再谈 unsafe ==")
}
