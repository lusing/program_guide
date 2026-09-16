[<EntryPoint>]
let main _ =

    // ═══ 3.1 基本类型与字面量 ═══
    let i = 42            // int（int32）
    let big = 42L         // int64
    let f = 3.14          // float（double）
    let money = 19.99m    // decimal（金额）
    let c = 'A'
    let b = true
    printfn "int=%d int64=%d float=%f decimal=%M char=%c bool=%b" i big f money c b

    // ═══ 3.2 类型推断与显式注解 ═══
    let x = 10
    let y = x + 5                 // 同类型才可直接运算
    // let z = x + 3.14            // 编译错误：int 与 float 不能隐式互转
    let z = float x + 3.14        // 显式转换：float x 把 int 变 float
    printfn "y=%d z=%.2f" y z
    let toUpper (s: string) = s.ToUpper()   // 参数注解：调用 .NET API 时常见
    printfn "%s" (toUpper "fsharp")

    // ═══ 3.3 自动泛化 ═══
    let identity x = x            // 推断为 'a -> 'a：什么类型都能传
    printfn "identity 5 = %d" (identity 5)
    printfn "identity hi = %s" (identity "hi")

    // ═══ 3.4 不可变性是默认 ═══
    let baseValue = 10
    let next = baseValue + 1      // next 是新值，baseValue 不变
    printfn "base=%d next=%d" baseValue next

    // ═══ 3.5 let mutable：需要可变时显式声明 ═══
    let mutable counter = 0
    counter <- counter + 1        // <- 赋值运算符
    counter <- counter + 10
    printfn "counter = %d" counter

    // ═══ 3.6 ref cell：另一种可变容器 ═══
    let cell = ref 0
    cell := !cell + 5             // := 写入，! 读取
    printfn "cell = %d" !cell

    // ═══ 3.7 unit：没有有意义的返回值 ═══
    let greet () = printfn "hello"  // 无参函数必须写 ()
    greet ()
    let nothing = ignore 42         // ignore：把任意值变成 unit
    printfn "unit 打印为 %A" nothing

    // ═══ 3.8 数值边界速查 ═══
    printfn "int 上限 = %d" System.Int32.MaxValue
    printfn "int64 上限 = %d" System.Int64.MaxValue
    0
