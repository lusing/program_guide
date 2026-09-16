open System
open System.IO

// ═══ 11.1 接口定义 ═══
type ILogger =
    abstract member Log: string -> unit

// ═══ 11.1 对象表达式：不定义类直接实现接口 ═══
let consoleLogger =
    { new ILogger with
        member _.Log msg = printfn "[console] %s" msg }

// ═══ 11.2 抽象类与继承 ═══
[<AbstractClass>]
type Animal(name: string) =
    abstract member Speak: unit -> string
    member _.Name = name

type Dog(name: string, breed: string) =
    inherit Animal(name)
    override this.Speak() = sprintf "%s（%s）：汪！" this.Name breed

// ═══ 11.3 类：隐式构造、私有可变状态、静态成员 ═══
type Counter(start: int) =
    let mutable current = start          // 私有可变状态
    member _.Value = current             // 只读属性
    member this.Increment() =
        current <- current + 1
        this                              // 返回自身，支持链式调用
    member _.Reset() = current <- start
    static member Start() = Counter 0

// ═══ 11.4 IDisposable 与 use 绑定 ═══
type TempFile(path: string) =
    do File.WriteAllText(path, "临时内容")
    interface IDisposable with
        member _.Dispose() =
            File.Delete path
            printfn "已删除 %s" path

[<EntryPoint>]
let main _ =

    // ═══ 11.1 对象表达式（可带参数）═══
    consoleLogger.Log "对象表达式无需先定义类"
    let prefixLogger prefix =
        { new ILogger with
            member _.Log msg = printfn "[%s] %s" prefix msg }
    (prefixLogger "db").Log "带参数的对象表达式"

    // ═══ 11.2 多态 ═══
    let animals: Animal list = [ Dog("旺财", "柴犬"); Dog("来福", "边牧") ]
    animals |> List.iter (fun a -> printfn "%s" (a.Speak()))

    // ═══ 11.3 有状态对象 ═══
    let c = Counter.Start()
    c.Increment().Increment().Increment() |> ignore
    printfn "counter = %d" c.Value
    c.Reset()
    printfn "reset 后 = %d" c.Value

    // ═══ 11.4 use 绑定自动释放 ═══
    let path = Path.Combine(Path.GetTempPath(), "fsharp-demo.txt")
    use tmp = new TempFile(path)
    printfn "正在使用临时文件……（main 结束时自动 Dispose）"

    // ═══ 11.5 函数式与 OOP 的分工 ═══
    let count = animals |> List.length     // 集合处理仍交给函数式
    printfn "一共 %d 只动物" count
    0
