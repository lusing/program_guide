# Go 开发指南

## 1. 什么是 Go

Go 是由 Google 推出的开源编程语言，特点是：

- 简洁、快速、可维护
- 适合服务端开发、CLI 工具、云原生和系统编程
- 语法清晰，学习曲线相对平缓
- 原生支持并发编程（goroutine + channel）

本教程将围绕以下内容展开：

- 基础语法
- 变量和类型
- 函数和参数
- 结构体与方法
- 并发编程
- 真实工程编译与验证

---

## 2. 本地工具链

本机安装路径：

- Go：`G:\scoop\apps\go\current\bin\go.exe`

验证命令：

```powershell
& 'G:\scoop\apps\go\current\bin\go.exe' version
```

一个最小的 Go 程序可以直接这样运行：

```powershell
& 'G:\scoop\apps\go\current\bin\go.exe' run G:\code\guide\go\examples\01_hello\main.go
```

---

## 3. 最小 Go 程序

```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, Go!")
}
```

关键点：

- `package main`：程序入口包
- `import "fmt"`：导入标准库
- `func main()`：程序入口函数
- `fmt.Println()`：输出文本

---

## 4. 变量与基础类型

```go
package main

import "fmt"

func main() {
    var age int = 30
    name := "Alice"
    pi := 3.14
    ok := true

    fmt.Println("age:", age)
    fmt.Println("name:", name)
    fmt.Println("pi:", pi)
    fmt.Println("ok:", ok)
}
```

常见类型：

- `int`：整数
- `float64`：浮点数
- `string`：字符串
- `bool`：布尔值

Go 允许使用短变量声明 `:=`，但在作用域内必须有一个新变量被声明。

---

## 5. 函数

```go
package main

import "fmt"

func add(a int, b int) int {
    return a + b
}

func main() {
    result := add(5, 7)
    fmt.Println("5 + 7 =", result)
}
```

函数是 Go 代码组织的核心，适合封装逻辑、降低重复代码。Go 支持：

- 普通函数
- 多返回值
- 可变参数
- 匿名函数

---

## 6. 控制流

```go
package main

import "fmt"

func main() {
    score := 85

    if score >= 90 {
        fmt.Println("优秀")
    } else if score >= 70 {
        fmt.Println("良好")
    } else {
        fmt.Println("需加油")
    }

    for i := 0; i < 3; i++ {
        fmt.Println("i =", i)
    }
}
```

Go 中 `for` 是唯一的循环语句，但它用途非常灵活。它可以用于：

- 普通计数循环
- 条件循环
- 无限循环
- 遍历切片/数组/映射

---

## 7. 数组、切片与映射

```go
package main

import "fmt"

func main() {
    nums := []int{1, 2, 3, 4}
    nums = append(nums, 5)
    fmt.Println(nums)

    person := map[string]int{
        "Alice": 18,
        "Bob": 25,
    }
    fmt.Println(person["Alice"])
}
```

Go 的集合类型常见：

- `[]T`：切片
- `map[K]V`：映射
- `array`：固定长度数组

切片非常常见，因为它能更自然地处理动态数据。

---

## 8. 结构体

```go
package main

import "fmt"

type Person struct {
    Name string
    Age  int
}

func main() {
    p := Person{Name: "Alice", Age: 30}
    fmt.Println(p.Name, p.Age)
}
```

Go 的结构体是组合数据的核心方式。它常用于：

- 配置项
- 业务对象
- 数据传输结构
- 复杂状态表达

---

## 9. 方法和接收者

```go
package main

import "fmt"

type Person struct {
    Name string
}

func (p Person) Greet() string {
    return "Hello, " + p.Name
}

func main() {
    p := Person{Name: "Alice"}
    fmt.Println(p.Greet())
}
```

Go 通过方法让结构体具有行为；它是一种给予类型行为的常见模式。

---

## 10. 并发：goroutine

Go 最具特色的特性之一是并发：

```go
package main

import (
    "fmt"
    "time"
)

func worker(id int) {
    fmt.Println("worker", id, "start")
    time.Sleep(500 * time.Millisecond)
    fmt.Println("worker", id, "done")
}

func main() {
    for i := 0; i < 3; i++ {
        go worker(i)
    }
    time.Sleep(1 * time.Second)
}
```

说明：

- `go worker(i)`：启动 goroutine
- goroutine 轻量且高效，适合任务并行
- `channel` 是协作式通信的常用机制

---

## 11. channel 与通信

```go
package main

import "fmt"

func main() {
    messages := make(chan string, 2)
    messages <- "hello"
    messages <- "world"

    fmt.Println(<-messages)
    fmt.Println(<-messages)
}
```

`channel` 能让 goroutine 进行安全、高效的通信，是 Go 并发模型的关键机制。

---

## 12. 一个更完整的项目结构

真实 Go 项目通常会使用以下结构：

```text
project/
├── go.mod
├── cmd/
│   └── app/
│       └── main.go
├── internal/
│   ├── config/
│   └── service/
├── pkg/
│   └── util/
└── README.md
```

这个结构适合：

- CLI 工具
- HTTP 服务
- 微服务
- 代码组织清晰的应用程序

---

## 13. 本目录示例概览

本目录中的示例包括：

- `01_hello`：最小 Go 程序
- `02_variables`：变量和基础数据类型
- `03_functions`：函数与返回值
- `04_structs`：结构体和方法
- `05_concurrency`：并发 goroutine

这些示例覆盖了 Go 的核心基础，并为后续网络编程、CLI、服务端开发打下基础。

---

## 14. 实战建议

学习 Go 时建议按这个顺序：

1. 先写最小程序，确认编译/运行正常
2. 学习变量、函数和控制流
3. 掌握切片、映射和结构体
4. 学会错误处理和包管理
5. 进入 goroutine 与 channel
6. 最后逐步进入 HTTP、数据库和 CLI 项目

---

## 15. 结论

Go 是一门非常适合工程实践的语言：

- 运行高效
- 语法简单
- 并发能力强
- 适合后端与系统开发

在本仓库中，我们通过真实的本机 Go 工具链验证每个示例，这确保了源码不是“看起来能运行”，而是确实可以编译和执行。

---

## 16. 本仓库中可用的命令

```powershell
cd G:\code\guide\go
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -Project 04_structs
```

清理输出：

```powershell
.\build.ps1 -Clean
```

这样既满足本仓库的统一标准，也能确保每个 Go 示例都经过真实编译验证。
