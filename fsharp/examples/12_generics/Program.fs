open System

// ═══ 12.2 显式约束：equality / comparison ═══
let areEqual (x: 'T when 'T : equality) (y: 'T) = x = y
let smallest list = list |> List.reduce (fun a b -> if a < b then a else b)

// ═══ 12.3 inline + SRTP：对"支持运算的类型"通用 ═══
let inline square (x: ^T) : ^T = x * x
let inline twiceSum (a: ^T) (b: ^T) : ^T = (a + b) + (a + b)

// ═══ 12.3 SRTP 成员约束：任何带 Area 成员的类型 ═══
let inline area2D (s: ^S) : float = (^S: (member Area: float) s)

type Disk = { Radius: float } with
    member this.Area = Math.PI * this.Radius * this.Radius

type Rect = { W: float; H: float } with
    member this.Area = this.W * this.H

// ═══ 12.4 度量单位 ═══
[<Measure>] type kg
[<Measure>] type m
[<Measure>] type s

[<EntryPoint>]
let main _ =

    // ═══ 12.1 自动泛化 ═══
    let firstOf list = List.head list       // 'a list -> 'a
    printfn "firstOf [3;1;2] = %d" (firstOf [ 3; 1; 2 ])
    printfn "firstOf ['a';'b'] = %c" (firstOf [ 'a'; 'b' ])

    // ═══ 12.2 约束演示 ═══
    printfn "smallest [5;2;9] = %d" (smallest [ 5; 2; 9 ])
    printfn "areEqual 1 1 = %b" (areEqual 1 1)

    // ═══ 12.3 SRTP：同一函数适配 int / float ═══
    printfn "square 4 = %d" (square 4)
    printfn "square 1.5 = %.2f" (square 1.5)
    printfn "twiceSum 3 4 = %d" (twiceSum 3 4)
    printfn "twiceSum 1.5 2.5 = %.1f" (twiceSum 1.5 2.5)

    // ═══ 12.3 成员约束：不同类型都点得出 Area ═══
    printfn "disk.Area = %.2f" (area2D { Radius = 2.0 })
    printfn "rect.Area = %.2f" (area2D { W = 3.0; H = 4.0 })

    // ═══ 12.4 度量单位：单位参与类型检查 ═══
    let mass = 75.0<kg>
    let height = 1.78<m>
    let distance = 100.0<m>
    let time = 9.58<s>
    let speed = distance / time            // m/s
    let bmi = mass / (height * height)     // kg/m^2
    // let wrong = mass + height           // 编译错误：kg 与 m 不能相加
    printfn "mass = %.1f kg" (float mass)  // float 剥掉单位用于打印
    printfn "speed = %.2f m/s" (float speed)
    printfn "bmi = %.1f" (float bmi)
    0
