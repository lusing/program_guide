// ═══ 10.1 简单 DU：形状 ═══
type Shape =
    | Circle of radius: float
    | Rectangle of width: float * height: float

let area shape =
    match shape with
    | Circle r -> System.Math.PI * r * r
    | Rectangle (w, h) -> w * h

// ═══ 10.2 单 case DU：强类型包装 ═══
type OrderId = OrderId of int
type Email = Email of string

let makeEmail (s: string) = if s.Contains "@" then Some(Email s) else None

// ═══ 10.3 递归 DU：表达式树 ═══
type Expr =
    | Num of float
    | Var of string
    | Add of Expr * Expr
    | Mul of Expr * Expr

let rec eval (vars: Map<string, float>) expr =
    match expr with
    | Num v -> v
    | Var name -> Map.find name vars
    | Add (a, b) -> eval vars a + eval vars b
    | Mul (a, b) -> eval vars a * eval vars b

let rec toStr expr =
    match expr with
    | Num v -> string v
    | Var n -> n
    | Add (a, b) -> sprintf "(%s + %s)" (toStr a) (toStr b)
    | Mul (a, b) -> sprintf "(%s * %s)" (toStr a) (toStr b)

// ═══ 10.4 递归 DU：JSON 值建模 ═══
type Json =
    | JString of string
    | JNumber of float
    | JBool of bool
    | JArray of Json list
    | JObject of (string * Json) list

let rec depth json =
    match json with
    | JString _ | JNumber _ | JBool _ -> 1
    | JArray items -> 1 + (items |> List.map depth |> List.fold max 0)
    | JObject fields -> 1 + (fields |> List.map (snd >> depth) |> List.fold max 0)

// ═══ 10.5 RequireQualifiedAccess：强制写全名 ═══
[<RequireQualifiedAccess>]
type Status = Active | Paused | Stopped

[<EntryPoint>]
let main _ =

    // ═══ 10.1 构造与 match ═══
    printfn "圆面积 = %.2f" (area (Circle 3.0))
    printfn "矩形面积 = %.2f" (area (Rectangle(2.0, 5.0)))

    // ═══ 10.2 单 case DU 防混淆 ═══
    let orderNo = OrderId 1001
    let (OrderId raw) = orderNo          // 解构取出原始值
    printfn "订单号原始值 = %d" raw
    match makeEmail "a@b.com" with
    | Some (Email e) -> printfn "合法邮箱：%s" e
    | None -> printfn "非法邮箱"

    // ═══ 10.3 表达式树求值：(2 + x) * 3，x = 4 ═══
    let expr = Mul(Add(Num 2.0, Var "x"), Num 3.0)
    let vars = Map [ ("x", 4.0) ]
    printfn "%s = %.1f" (toStr expr) (eval vars expr)

    // ═══ 10.4 JSON 深度计算 ═══
    let sample =
        JObject [ ("name", JString "guide")
                  ("tags", JArray [ JString "fsharp"; JString "dotnet" ]) ]
    printfn "JSON 嵌套深度 = %d" (depth sample)

    // ═══ 10.5 必须写 Status.Active 而不是裸 Active ═══
    let state = Status.Active
    printfn "状态 = %A" state
    0
