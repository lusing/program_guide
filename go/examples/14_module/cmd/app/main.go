// cmd/app：程序入口。Go 生态惯例——main 包尽量薄，逻辑放进库里。
package main

import (
	"fmt"

	"layout/internal/store"
	"layout/pkg/units"
)

func main() {
	fmt.Println("== internal/ 包：只有 layout 模块内能 import ==")
	s := &store.Store{}
	s.Set("lang", "go")
	s.Set("os", "windows")
	for _, k := range s.Keys() {
		v, _ := s.Get(k)
		fmt.Printf("%s=%s ", k, v)
	}
	fmt.Println()
	if _, err := s.Get("nope"); err != nil {
		fmt.Println("缺键错误:", err)
	}

	fmt.Println("== pkg/ 包：允许被其他模块引用 ==")
	fmt.Println(units.FormatBytes(512), units.FormatBytes(4096), units.FormatBytes(5_000_000))
}
