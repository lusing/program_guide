open System
open System.IO
open System.Text.Encodings.Web
open System.Text.Json

// ═══ 15.3 CSV 解析目标：record ═══
type Language =
    { Name: string
      Year: int
      Score: float }

// ═══ 15.4 JSON 往返的记录类型 ═══
type Book =
    { Title: string
      Author: string
      Year: int
      Tags: string list }

// ═══ 15.5 option 字段 ═══
type Profile = { Name: string; Nickname: string option }

[<EntryPoint>]
let main _ =
    let dir = Path.Combine(Path.GetTempPath(), "fsharp-guide")
    Directory.CreateDirectory(dir) |> ignore

    // ═══ 15.1 文本文件读写 ═══
    let txt = Path.Combine(dir, "notes.txt")
    File.WriteAllText(txt, "第一行\n第二行\n第三行")
    printfn "读回 %d 字符" (File.ReadAllText(txt)).Length
    File.ReadAllLines(txt) |> Array.iteri (fun i line -> printfn "行 %d: %s" (i + 1) line)

    // ═══ 15.2 追加与 Path 工具 ═══
    File.AppendAllText(txt, "\n追加的一行")
    printfn "追加后 %d 行" (File.ReadAllLines(txt).Length)
    let target = Path.Combine(dir, "sub", "deep.txt")
    printfn "Combine 生成跨平台路径：%s" target

    // ═══ 15.3 CSV 字符串 → record 列表 ═══
    let csv = "F#,2010,4.7\nC#,2000,4.5\nPython,1991,4.8"
    let languages =
        csv.Split('\n')
        |> Array.map (fun line -> line.Split(','))
        |> Array.map (fun parts ->
            { Name = parts[0]
              Year = int parts[1]
              Score = float parts[2] })
    printfn "CSV 解析 = %A" (Array.toList languages)
    printfn "平均分 = %.2f" (languages |> Array.averageBy (fun l -> l.Score))

    // ═══ 15.4 System.Text.Json 序列化 F# record ═══
    let books =
        [ { Title = "F# 实战"; Author = "张三"; Year = 2024; Tags = [ "fsharp"; ".net" ] }
          { Title = "函数式入门"; Author = "李四"; Year = 2022; Tags = [] } ]
    let options = JsonSerializerOptions(WriteIndented = true, Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping)
    let json = JsonSerializer.Serialize(books, options)
    printfn "%s" json
    let back =
        JsonSerializer.Deserialize<Book list>(json)
        |> Option.ofObj                    // Deserialize 声明返回可空，接回 option（连第 07 章）
        |> Option.defaultValue []
    printfn "往返书名 = %A" (back |> List.map (fun b -> b.Title))

    // ═══ 15.5 option 字段的 JSON 形态（.NET 9+ 原生支持）═══
    let profiles =
        [ { Name = "Alice"; Nickname = Some "Ali" }
          { Name = "Bob"; Nickname = None } ]
    printfn "%s" (JsonSerializer.Serialize(profiles))
    0
