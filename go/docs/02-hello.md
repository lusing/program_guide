# 02 · 第一个程序

> 对应示例：`examples/02_hello/`

## 2.1 三条命令跑起来

```powershell
cd go/examples/02_hello
go run .              # 编译到临时目录 + 立即运行：改代码 → 看结果的最快路径
go test .             # 跑 main_test.go 里的测试
go build -o a.exe .   # 产可执行文件（`.` = 当前目录的包）
```

注意目标是 **`.`（目录/包）而不是 main.go（文件）**——Go 的编译单位是包。文件名单独传也能跑，但多文件包立刻翻车；从第一天就用目录思维。

## 2.2 最小程序解剖

```go
package main // main 包 + 无参 main 函数 = 可执行程序

import (
	"fmt"
	"unicode/utf8"
)

func main() {
	fmt.Println("你好，Go！")
}
```

- `import` 未使用会**编译失败**（不是警告）——Go 用这条逼你删死代码；
- main 无参数无返回值；命令行参数走 `os.Args` 或 flag 包（24 章），退出码走 `os.Exit`；
- `{` 必须和函数声明同行（gofmt 强制），自成一行的 `{` 编译不过。

## 2.3 Println 与 Printf：动词速查

`fmt.Println` 空格分隔 + 换行；`fmt.Printf` 用**动词**（比 C 的格式符少得多，日常 `%v` 一把梭）：

| 动词 | 含义 | 例 |
|---|---|---|
| `%v` | 任意值默认形态 | `{3 4}` |
| `%+v` | 结构体带字段名 | `{Name:阿G Age:18}` |
| `%#v` | Go 语法形态 | `main.Point{X:3, Y:4}` |
| `%T` | 类型 | `main.Point` |
| `%d` `%x` `%o` `%b` | 整数四种进制 | `255` `ff` `377` `11111111` |
| `%g` `%e` `%f` | 浮点（自适应/科学/定点） | `3.14` |
| `%s` `%q` | 字符串 / 加引号 | `hi` `"hi"` |
| `%c` `%U` | 字符 / Unicode 码点 | `你` `U+4F60` |
| `%6.2f` `%-8s` | 宽度与小数位、左对齐 | `[  3.14][hi      ]` |
| `%%` | 百分号本身 | `%` |

## 2.4 字符串初见：字节与 rune

```go
s := "你好 Go"
len(s)                        // 8：字节数（UTF-8 编码，中文 3 字节）
utf8.RuneCountInString(s)     // 5：字符数
for i, r := range s { }       // 按 rune 迭代，i 是字节下标（会跳）
```

Go 字符串是**不可变的字节切片**，内部按 UTF-8 存。`s[0]` 拿到的是首字节不是首字符——中文处理的全部坑都源于此，06 章展开。

## 2.5 test 文件初见

```go
// main_test.go：文件名 _test.go 结尾，go test 自动发现
func TestGreet(t *testing.T) {
	if got, want := Greet("Go"), "你好，Go！"; got != want {
		t.Errorf("Greet(\"Go\") = %q, want %q", got, want)
	}
}
```

和 Zig 的 `test` 块一样，测试是**语言内建**：不装框架、不写配置，`go test .` 直接跑。本教程每个示例都带测试（build.ps1 的验证靠它），15 章系统讲表驱动、基准、模糊测试。

## 2.6 gofmt：格式即法律

```powershell
gofmt -l .    # 列出待格式化文件（输出为空 = 合格；退出码恒 0）
gofmt -w .    # 原地格式化
```

Go 没有格式圣战——gofmt 输出就是唯一格式（tab 缩进、对齐由它说了算）。本仓库 build.ps1 用 `gofmt -l` 把关每个示例：**写完代码直接 `gofmt -w .`，永远不在这件事上花脑细胞**。

## 2.7 坑位清单

1. **`go run main.go` vs `go run .`**：前者只编单文件，多文件包直接报"undefined"；养成目录习惯。
2. **未使用的 import / 局部变量是编译错误**：调代码时先注释 import 会连环炸，删干净再编。
3. **`{` 自成一行编译不过**：C++ 风格的大括号放法在 Go 是语法错误。
4. **Windows 控制台中文乱码**：`chcp 65001` 切 UTF-8 代码页（本仓库 build.ps1 已代设）。
5. **`fmt.Println` 打指针默认给地址**：自定义类型实现 `String() string`（Stringer 接口，08 章）才有友好输出。

---
