module Tests

open System
open Xunit

// ═══ 17.1 被测代码：纯函数（第 08 章风格）═══
let parseInt input =
    if String.IsNullOrWhiteSpace input then Error "输入为空"
    else
        match Int32.TryParse input with
        | true, v -> Ok v
        | false, _ -> Error $"无法解析：{input}"

let inRange lo hi v =
    if v < lo || v > hi then Error $"超出 [{lo}, {hi}]" else Ok v

// ═══ 17.1 被测代码：多分支逻辑 ═══
let classify n =
    if n % 15 = 0 then "FizzBuzz"
    elif n % 3 = 0 then "Fizz"
    elif n % 5 = 0 then "Buzz"
    else string n

// ═══ 17.2 Fact：单一事实 ═══
type 解析与校验 () =

    [<Fact>]
    let ``正常整数解析为 Ok`` () =
        Assert.Equal(Ok 42, parseInt "42")

    [<Theory>]
    [<InlineData("abc")>]
    [<InlineData("")>]
    [<InlineData("  ")>]
    let ``非法输入解析为 Error`` (input: string) =
        Assert.True(match parseInt input with Error _ -> true | _ -> false)

    [<Fact>]
    let ``范围校验两端都检查`` () =
        Assert.Equal(Ok 5, inRange 1 10 5)
        Assert.True(match inRange 1 10 99 with Error _ -> true | _ -> false)

// ═══ 17.3 Theory：数据驱动 ═══
type FizzBuzz () =

    [<Theory>]
    [<InlineData(15, "FizzBuzz")>]
    [<InlineData(9, "Fizz")>]
    [<InlineData(10, "Buzz")>]
    [<InlineData(7, "7")>]
    let ``分类正确`` (n: int) (expected: string) =
        Assert.Equal(expected, classify n)
