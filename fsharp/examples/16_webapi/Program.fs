module Program

open System
open System.Net.Http
open System.Text
open System.Text.Json
open Microsoft.AspNetCore.Builder
open Microsoft.AspNetCore.Http

// ═══ 16.2 待办数据模型与内存存储 ═══
type Todo = { Id: int; Title: string; Done: bool }

let todosStore = ResizeArray<Todo>()

// ═══ 16.1 定义全部端点（F# 惯用法：显式 Func<...> 委托，避免多重载决议歧义）═══
let buildApp () =
    let builder = WebApplication.CreateBuilder()
    let app = builder.Build()

    app.MapGet("/", Func<string>(fun () -> "F# Minimal API 自测")) |> ignore

    app.MapGet("/todos", Func<IResult>(fun () ->
        if todosStore.Count = 0 then
            Results.NotFound("还没有待办")
        else
            Results.Ok(todosStore.ToArray()))) |> ignore

    app.MapPost("/todos", Func<Todo, IResult>(fun todo ->
        todosStore.Add todo
        Results.Created($"/todos/{todo.Id}", todo))) |> ignore

    app.MapDelete("/todos/{id:int}", Func<int, IResult>(fun id ->
        let removed = todosStore.RemoveAll(fun t -> t.Id = id)
        if removed > 0 then
            Results.NoContent()
        else
            Results.NotFound($"没有 id={id} 的待办"))) |> ignore

    app

// ═══ 16.4 自测：启动 → HttpClient 逐个端点验证 → 退出 ═══
[<EntryPoint>]
let main _ =
    let app = buildApp ()
    app.Urls.Add("http://127.0.0.1:0")          // 端口 0 = 随机可用端口
    app.StartAsync().GetAwaiter().GetResult() |> ignore

    let test = task {
        use client = new HttpClient()
        let baseUri = Seq.head app.Urls

        let! created =
            let payload = JsonSerializer.Serialize({ Id = 1; Title = "学 F#"; Done = false })
            let content = new StringContent(payload, Encoding.UTF8, "application/json")
            client.PostAsync(baseUri + "/todos", content)
        printfn "POST /todos → %O" created.StatusCode

        let! list = client.GetAsync(baseUri + "/todos")
        let! body = list.Content.ReadAsStringAsync()
        printfn "GET /todos → %O：%s" list.StatusCode body

        let! deleted = client.DeleteAsync(baseUri + "/todos/1")
        printfn "DELETE /todos/1 → %O" deleted.StatusCode

        let! empty = client.GetAsync(baseUri + "/todos")
        printfn "GET /todos → %O（已清空）" empty.StatusCode
    }
    test.GetAwaiter().GetResult()

    app.StopAsync().GetAwaiter().GetResult() |> ignore
    printfn "自测完成，正常退出。"
    0
