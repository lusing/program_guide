module Todo.Tests

open Xunit

type 解析测试 () =

    [<Fact>]
    let ``无参数默认 show`` () =
        Assert.Equal(Ok(Todo.Command.Show), Todo.parse [||])

    [<Fact>]
    let ``add 支持多词标题`` () =
        Assert.Equal(Ok(Todo.Command.Add "buy milk"), Todo.parse [| "add"; "buy"; "milk" |])

    [<Theory>]
    [<InlineData("done", "abc")>]
    [<InlineData("remove", "x")>]
    [<InlineData("frobnicate", "")>]
    let ``非法命令返回 Error`` (cmd: string) (arg: string) =
        let argv = if arg = "" then [| cmd |] else [| cmd; arg |]
        Assert.True(match Todo.parse argv with Error _ -> true | _ -> false)

type 应用测试 () =

    let seed: Todo.Todo list =
        [ { Id = 1; Title = "旧任务"; Done = false } ]

    [<Fact>]
    let ``add 生成递增 id 并置于头部`` () =
        match Todo.apply (Todo.Command.Add "新任务") seed with
        | Ok (state, report) ->
            let added = List.head state
            Assert.Equal(2, added.Id)
            Assert.Equal("新任务", added.Title)
            Assert.False(added.Done)
            Assert.Equal("已添加 #2 新任务", report)
        | Error e -> failwith e

    [<Fact>]
    let ``done 只改目标项`` () =
        match Todo.apply (Todo.Command.Done 1) seed with
        | Ok (state, report) ->
            Assert.True((List.head state).Done)
            Assert.Equal(1, List.length state)
            Assert.Equal("完成 #1", report)
        | Error e -> failwith e

    [<Fact>]
    let ``remove 删除指定项`` () =
        match Todo.apply (Todo.Command.Remove 1) seed with
        | Ok (state, _) -> Assert.Empty(state)
        | Error e -> failwith e

    [<Fact>]
    let ``操作不存在的 id 返回 Error`` () =
        Assert.True(match Todo.apply (Todo.Command.Done 9) seed with Error _ -> true | _ -> false)
        Assert.True(match Todo.apply (Todo.Command.Remove 9) seed with Error _ -> true | _ -> false)

    [<Fact>]
    let ``reset 清空状态`` () =
        match Todo.apply Todo.Command.Reset seed with
        | Ok (state, msg) ->
            Assert.Empty(state)
            Assert.Equal("状态已清空", msg)
        | Error e -> failwith e
