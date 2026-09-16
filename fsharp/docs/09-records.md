# 09 · 记录类型：数据的默认形状

> 对应示例：examples/09_records

## 9.1 解决什么问题

用 class 承载数据要手写：构造函数、属性、`Equals`、`GetHashCode`、`ToString`……而"纯数据"需要的是值语义。F# record 一行定义，全套自动生成：

```fsharp
type Person =
    { Name: string
      Age: int }
    member this.Greet() = sprintf "我是 %s，%d 岁" this.Name this.Age
```

| 手写 class 需要的 | record 免费送的 |
|---|---|
| 构造函数 | `{ Name = "Alice"; Age = 30 }` |
| 属性 | `alice.Name` |
| Equals/GetHashCode | 结构相等（见 9.3） |
| ToString | `%A` 打印 `{ Name = "Alice"; Age = 30 }` |
| with 更新 | 下一节 |

record 还能带成员方法（`Greet`），但**默认仍是纯数据**。

## 9.2 with 表达式：非破坏性更新

```fsharp
let alice = { Name = "Alice"; Age = 30 }
let aliceNextYear = { alice with Age = alice.Age + 1 }
printfn "原值 = %A" alice          // Age = 30，没变
printfn "明年 = %A" aliceNextYear  // Age = 31
```

`with` **复制出新值**，原值不动——第 03 章"改数据 = 造新值"在这里落地。注意是**浅拷贝**：字段里的可变对象（如 ResizeArray）是共享的。

## 9.3 结构相等：字段相同即相等

```fsharp
let alice2 = { Name = "Alice"; Age = 30 }
let bob = { Name = "Bob"; Age = 25 }
printfn "alice = alice2 ? %b" (alice = alice2)   // true
printfn "alice = bob ? %b" (alice = bob)         // false
```

相等按**内容**比较（递归到每个字段），哈希也一致——所以能当 Map 的键、能直接去重：

```fsharp
let nameByPerson = Map [ (alice, "第一个"); (alice2, "第二个") ]
printfn "相等记录是同一个 Map 键：Count = %d" nameByPerson.Count   // 1

let team = [ alice; bob; alice2 ]
let adults =
    team
    |> List.distinct                 // alice2 与 alice 相等，去重
    |> List.filter (fun p -> p.Age >= 28)
    |> List.map (fun p -> p.Name)
// adults = ["Alice"]
```

`List.distinct`/`groupBy`/`Map` 全都吃到这份红利，不用传 IEqualityComparer。

## 9.4 解构

```fsharp
let { Name = name; Age = age } = alice
printfn "解构：name=%s age=%d" name age
```

左边是记录模式（第 05 章）——一次绑定多个字段。

## 9.5 匿名记录：临时形状

```fsharp
let profile = {| Name = "Carol"; Age = 28 |}
printfn "匿名记录 = %A" profile
printfn "字段访问 = %s" profile.Name
```

`{| ... |}` 不用预先定义类型，适合：管道中途的临时投影、和 C# 传 DTO（第 18 章）、单元测试的临时数据。字段顺序无关，结构相等。**正式领域模型别用它**——没有名字的类型没法演进。

## 9.6 struct 记录

```fsharp
[<Struct>]
type Point = { X: float; Y: float }

let p1 = { X = 1.0; Y = 2.0 }
let p2 = { X = 1.0; Y = 2.0 }
printfn "struct 相等 %b，类型 %s" (p1 = p2) (p1.GetType().Name)
```

`[<Struct>]` 让记录分配在栈上（值类型）：大量短命小值能减 GC 压力。代价：赋值即复制、大字段得不偿失、装箱场景（`obj`、集合泛型参数为接口时）反而更慢。**默认普通 record， profiler 发话再换**。

## 9.7 坑位清单

- **with 是浅拷贝**：嵌套的可变字段共享引用。
- **相等要求字段类型可比较**：字段含 `ResizeArray` 这类无结构相等的类型时 `=` 编不过（这其实是保护）。
- **匿名/命名不可互换**：`{| Name = "x" |}` 和 `Person` 是不同类型，边界处要么映射要么统一。
- **struct record 装箱**：塞进 `obj` 或非泛型容器会装箱，性能反转。
- **可变字段**：`mutable` 字段配合 `<-` 可写，但破坏值语义，仅限性能热点。
