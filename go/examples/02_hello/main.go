// 02_hello：最小 Go 程序与 fmt 输出动词。
// 学法：go run . → 改代码 → 再跑；go test . 验证逻辑（main_test.go）。
package main

import (
	"fmt"
	"unicode/utf8"
)

// Greet 返回问候语（main 与测试共用，逻辑都抽成这样的小函数）。
func Greet(name string) string {
	if name == "" {
		return "你好，匿名者！"
	}
	return "你好，" + name + "！"
}

// Shout 把句子变成"喊出来"的形态。
func Shout(s string) string {
	return s + "!!!"
}

func main() {
	fmt.Println(Greet("Go"))
	fmt.Println(Shout("跑起来了"))

	// Printf 动词速览：Go 的格式动词比 C 少，日常 %v 一把梭。
	fmt.Println("== Printf 动词 ==")
	fmt.Printf("%v %v %v\n", 42, 3.14, true)      // %v：任意值的默认形态
	fmt.Printf("%T %T %T\n", 42, 3.14, "文本")      // %T：打类型
	fmt.Printf("%d %x %o %b\n", 255, 255, 8, 5)   // 十/十六/八/二进制
	fmt.Printf("%q\n", "带引号打出来")                  // %q：字符串加引号
	fmt.Printf("[%6.2f][%-8s]\n", 3.14159, "左对齐") // 宽度与对齐
	fmt.Printf("%+v\n", struct {                  // %+v：结构体带字段名
		Name string
		Age  int
	}{"阿 G", 18})

	fmt.Println("== 字符串与 rune ==")
	s := "你好 Go"
	fmt.Println("len（字节数）:", len(s))
	fmt.Println("字符数:", utf8.RuneCountInString(s))
	for i, r := range s { // range 字符串按 rune 迭代（i 是字节下标！）
		fmt.Printf("  [%d] %c %U\n", i, r, r)
	}
}
