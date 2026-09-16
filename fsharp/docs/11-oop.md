# 11 · 面向对象在 F#：何时回到类

> 对应示例：examples/11_oop

## 11.1 解决什么问题

F# 函数优先，但 OOP 设施完整。三类场景值得回到类：**框架互操作**（GUI 控件、ASP.NET 过滤器要求类与接口）、**有状态组件**（连接池、缓存——状态需要封装边界）、**层次多态**（继承体系表达"是什么"）。原则：数据建模用 record/DU（第 09/10 章），行为与边界用函数，**只有需要"封装了状态的服务对象"时才写类**。

## 11.2 接口与对象表达式：匿名实现

```fsharp
type ILogger =
    abstract member Log: string -> unit

let consoleLogger =
    { new ILogger with
        member _.Log msg = printfn "[console] %s" msg }
```

`{ new 接口 with member ... }` 是**对象表达式**——不定义类直接实现接口，等价于 C# 的匿名类。这是 F# 里"小适配器/回调对象"的标准写法，还能带参数闭包：

```fsharp
let prefixLogger prefix =
    { new ILogger with
        member _.Log msg = printfn "[%s] %s" prefix msg }

(prefixLogger "db").Log "带参数的对象表达式"   // [db] ...
```

示例里调用是 `(prefixLogger "db").Log "带参数的对象表达式"`——**成员访问优先级高于函数应用**，`(f "x").Member` 的括号不能省（示例编译时踩过）。

## 11.3 抽象类与继承

```fsharp
[<AbstractClass>]
type Animal(name: string) =
    abstract member Speak: unit -> string
    member _.Name = name

type Dog(name: string, breed: string) =
    inherit Animal(name)
    override this.Speak() = sprintf "%s（%s）：汪！" this.Name breed
```

关键词表：`inherit`（继承）、`abstract`（抽象成员）、`override`（覆写）、`base`（访问基类成员）。多态照常工作：

```fsharp
let animals: Animal list = [ Dog("旺财", "柴犬"); Dog("来福", "边牧") ]
animals |> List.iter (fun a -> printfn "%s" (a.Speak()))
```

F# 类默认**不可继承**吗？不——默认可继承但成员默认非虚（没有 C# 的 virtual/非 virtual 之争，要覆写必须基类 abstract 或 virtual 声明）。

## 11.4 类解剖：构造、状态、静态成员

```fsharp
type Counter(start: int) =
    let mutable current = start          // 私有可变状态（对外不可见）
    member _.Value = current             // 只读属性
    member this.Increment() =
        current <- current + 1
        this                              // 返回自身，支持链式调用
    member _.Reset() = current <- start
    static member Start() = Counter 0

let c = Counter.Start()
c.Increment().Increment().Increment() |> ignore
printfn "counter = %d" c.Value           // 3
```

要点：**主构造参数** `(start: int)` 在整个类体可见；`let` 绑定是私有字段；`member` 是公开成员；`this`/`_` 自引用按需（只读访问用 `_`）；静态成员工厂是惯用法。

## 11.5 IDisposable 与 use 绑定

```fsharp
type TempFile(path: string) =
    do File.WriteAllText(path, "临时内容")
    interface IDisposable with
        member _.Dispose() =
            File.Delete path
            printfn "已删除 %s" path

use tmp = new TempFile(path)   // main 结束时自动 Dispose
```

`use` = `let` + 离开作用域自动 Dispose（确定性释放）；异步版是 `use!`（第 13 章）。F# 里实现 IDisposable 的场景比 C# 少——资源多在 `async`/管道边界集中管理。

## 11.6 函数式与 OOP 的分工

示例结尾的态度：

```fsharp
let count = animals |> List.length     // 集合处理仍交给函数式
```

| 用 | 场景 |
|---|---|
| record / DU | 数据、领域模型 |
| 纯函数 + 管道 | 变换、业务规则 |
| 类 + 接口 | 框架集成点、有状态服务 |
| 对象表达式 | 一次性接口实现 |

## 11.7 坑位清单

- **`(f "x").Member` 括号**：成员访问优先级高于函数应用，不加括号会去 `"x"` 上找成员。
- **接口成员显式实现**：F# 实现接口是显式的，实例要先转接口类型才点得出成员（`tmp :> IDisposable`）。
- **override 拼错**：拼错成员名会静默变成新成员（有告警 FS0026），盯编译输出。
- **主构造参数不是字段**：`(name: string)` 想暴露给外部要再 `member _.Name = name`。
- **可变状态默认私有**：`let mutable` 只有类内可见，跨类改状态需 `member val` 或方法——这是好事。
