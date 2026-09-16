# 15 · 文件与 JSON：数据进出

> 对应示例：examples/15_files_json

## 15.1 解决什么问题

教程级程序到真实工具的第一步是"数据能留下"：读写文件、解析 CSV、和 JSON 打交道。F# 调 `System.IO` 与 `System.Text.Json`（STJ）即可，零第三方依赖；.NET 9 起 STJ 原生认识 F# 的 record、option 与判别联合。

## 15.2 文本文件读写

```fsharp
let dir = Path.Combine(Path.GetTempPath(), "fsharp-guide")
Directory.CreateDirectory(dir) |> ignore

let txt = Path.Combine(dir, "notes.txt")
File.WriteAllText(txt, "第一行\n第二行\n第三行")
printfn "读回 %d 字符" (File.ReadAllText(txt)).Length
File.ReadAllLines(txt) |> Array.iteri (fun i line -> printfn "行 %d: %s" (i + 1) line)
```

| API | 语义 |
|---|---|
| `File.WriteAllText / ReadAllText` | 整文件一次性 |
| `File.ReadAllLines` | 按行读成数组 |
| `File.ReadLines` | 惰性逐行（大文件流式，返回 seq） |
| `File.AppendAllText` | 追加 |
| `File.Copy / Delete / Exists` | 常规操作 |

追加演示：

```fsharp
File.AppendAllText(txt, "\n追加的一行")
printfn "追加后 %d 行" (File.ReadAllLines(txt).Length)   // 4
```

## 15.3 Path 工具：跨平台路径

```fsharp
let target = Path.Combine(dir, "sub", "deep.txt")
printfn "Combine 生成跨平台路径：%s" target
// Windows: F:\temp\fsharp-guide\sub\deep.txt
// macOS:   /var/folders/xx/.../T/fsharp-guide/sub/deep.txt
// Linux:   /tmp/fsharp-guide/sub/deep.txt
```

`Combine` 按当前系统拼分隔符；`GetTempPath` 拿临时目录（示例统一写这里，避免污染仓库）。跨平台三注意：路径分隔符别硬编码 `\`、行尾 LF/CRLF 用文本 API 自动处理、编码显式 UTF-8。

## 15.4 CSV 字符串 → record 列表

```fsharp
let csv = "F#,2010,4.7\nC#,2000,4.5\nPython,1991,4.8"
let languages =
    csv.Split('\n')
    |> Array.map (fun line -> line.Split(','))
    |> Array.map (fun parts ->
        { Name = parts[0]
          Year = int parts[1]
          Score = float parts[2] })
printfn "平均分 = %.2f" (languages |> Array.averageBy (fun l -> l.Score))   // 4.67
```

`split → 映射进 record` 是小数据解析的标准管道。局限也说清楚：字段含引号/逗号/换行的真 CSV 需要真正的解析器（CsvHelper 包），教学管线只适合干净数据。

## 15.5 System.Text.Json 序列化 F# 类型

```fsharp
type Book =
    { Title: string
      Author: string
      Year: int
      Tags: string list }

let options = JsonSerializerOptions(WriteIndented = true, Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping)
let json = JsonSerializer.Serialize(books, options)
```

`.NET 9+ 内置 F# 支持`——record、`list`、option、DU 直接可序列化，不用第三方包。两个实用选项：`WriteIndented`（缩进美化）、`Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping`（中文不转义成 `\uXXXX`，内部数据可放心用；面向公网的 API 保持默认转义更稳妥）。

反序列化 + 往返验证：

```fsharp
let back =
    JsonSerializer.Deserialize<Book list>(json)
    |> Option.ofObj                    // Deserialize 声明返回可空，接回 option（连第 07 章）
    |> Option.defaultValue []
printfn "往返书名 = %A" (back |> List.map (fun b -> b.Title))
// ["F# 实战"; "函数式入门"]
```

`Deserialize` 的 C# 签名标注可空返回——F# 9 nullness 会让直接绑定报警告，`Option.ofObj` 一接就干净（示例实测输出逐字段一致）。

## 15.6 option 字段的 JSON 形态

```fsharp
type Profile = { Name: string; Nickname: string option }

let profiles =
    [ { Name = "Alice"; Nickname = Some "Ali" }
      { Name = "Bob"; Nickname = None } ]
printfn "%s" (JsonSerializer.Serialize(profiles))
// [{"Name":"Alice","Nickname":"Ali"},{"Name":"Bob","Nickname":null}]
```

`Some x` → 值本身、`None` → `null`（内置转换器的约定）。反序列化时 `null` 回到 `None`，往返对称。若要"缺字段"而非 `null`，需自定义 `JsonConverter<FSharpOption<T>>` 或改用可空注解字段——第 16 章的 Web API 走 HTTP JSON 默认 camelCase，同一套机制。

## 15.7 坑位清单

- **编码显式 UTF-8**：`WriteAllText(path, text)` 默认无 BOM UTF-8（.NET Core 起）；与其他系统对接时显式传 `Encoding.UTF8` 防歧义。
- **路径分隔符**：硬编码 `\` 在 Linux 上崩；一律 `Path.Combine`。
- **反序列化可空**：`Deserialize` 可能返回 null（JSON 字面 `null`），ofObj 兜底。
- **大小写敏感**：STJ 默认属性名精确匹配；来料 camelCase 时配 `PropertyNamingPolicy = JsonNamingPolicy.CamelCase`。
- **DU 的 JSON 形态**：内置支持有默认形态（带 Case/Fields 字段的包装对象）；对外协议要先序列化样例确认，或自定义 converter。
