open System

// ═══ 9.1 基本记录：还可以带成员 ═══
type Person =
    { Name: string
      Age: int }
    member this.Greet() = sprintf "我是 %s，%d 岁" this.Name this.Age

// ═══ 9.7 struct 记录：栈上分配 ═══
[<Struct>]
type Point = { X: float; Y: float }

[<EntryPoint>]
let main _ =

    // ═══ 9.1 构造与字段访问 ═══
    let alice = { Name = "Alice"; Age = 30 }
    printfn "%s" (alice.Greet())
    printfn "alice.Name = %s" alice.Name

    // ═══ 9.2 with 表达式：非破坏性更新 ═══
    let aliceNextYear = { alice with Age = alice.Age + 1 }
    printfn "原值 = %A" alice
    printfn "明年 = %A" aliceNextYear

    // ═══ 9.3 结构相等：字段相同即相等 ═══
    let alice2 = { Name = "Alice"; Age = 30 }
    let bob = { Name = "Bob"; Age = 25 }
    printfn "alice = alice2 ? %b" (alice = alice2)
    printfn "alice = bob ? %b" (alice = bob)
    let nameByPerson = Map [ (alice, "第一个"); (alice2, "第二个") ]
    printfn "相等记录是同一个 Map 键：Count = %d" nameByPerson.Count

    // ═══ 9.5 解构 ═══
    let { Name = name; Age = age } = alice
    printfn "解构：name=%s age=%d" name age

    // ═══ 9.6 匿名记录：临时形状 ═══
    let profile = {| Name = "Carol"; Age = 28 |}
    printfn "匿名记录 = %A" profile
    printfn "字段访问 = %s" profile.Name

    // ═══ 9.7 struct 记录 ═══
    let p1 = { X = 1.0; Y = 2.0 }
    let p2 = { X = 1.0; Y = 2.0 }
    printfn "struct 相等 %b，类型 %s" (p1 = p2) (p1.GetType().Name)

    // ═══ 9.8 记录 + 集合管道 ═══
    let team = [ alice; bob; alice2 ]
    let adults =
        team
        |> List.distinct                 // alice2 与 alice 相等，去重
        |> List.filter (fun p -> p.Age >= 28)
        |> List.map (fun p -> p.Name)
    printfn "adults = %A" adults
    0
