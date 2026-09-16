# 12 · 文件与 JSON：最常用的 IO 两件套

> 对应示例：`examples/12_files_json`

## 1. File：一站式的静态便利方法

小文件读写是最高频的 IO，BCL 的 `File` 静态类把"打开-操作-关闭"压成一次调用：

| 方法 | 语义 |
|---|---|
| `File.ReadAllText(path)` / `ReadAllText(path, Encoding.UTF8)` | 整个文件读成一个 string |
| `File.WriteAllText(path, text)` | 整个覆盖写 |
| `File.AppendAllText(path, text)` | 追加 |
| `File.Exists(path)` / `Delete(path)` | 望文生义 |
| `File.ReadAllLines(path)` | 读成 `string[]`（每行一个） |

这些一次性方法每次内部都开合流——循环里反复读同一文件别用它们；大文件（上百 MB）也别，用 `File.Open` + 流式处理。对教程与日常脚本，它们覆盖 90% 场景。

路径操作交给 `Path`（示例在用）：

```csharp
var path = Path.Combine(Path.GetTempPath(), "dotnet-user.json");
```

`Path.Combine` 拼路径（见下方跨平台提示）、`GetTempPath` 系统临时目录、`GetFileName/GetExtension/GetDirectoryName` 拆路径。

> **跨平台提示（三条铁律）**：
> 1. **永远 `Path.Combine` 拼路径**，不手写 `"\\"` 或 `"/"`——Windows 用 `\`、Linux/macOS 用 `/`，Combine 替你选对。
> 2. **读写必须显式传 `Encoding.UTF8`**：不传编码的单参重载用"系统当前 ANSI 代码页"——同一份代码在中文 Windows 与 Linux 上读同一个文件，一个正常一个乱码（坑位清单第 1 条）。
> 3. **文本行尾交给系统**：Windows 是 `\r\n`、Linux 是 `\n`。跨平台交换文本要么统一约定（JSON 就没有行尾问题），要么用 `Environment.NewLine` 生成当前系统样式。

## 2. System.Text.Json：序列化与反序列化

示例全文只有 13 行，覆盖了最小闭环：

```csharp
using System.Text.Json;

var user = new User(1, "alice");
var path = Path.Combine(Path.GetTempPath(), "dotnet-user.json");
var json = JsonSerializer.Serialize(user, new JsonSerializerOptions {WriteIndented = true});
File.WriteAllText(path, json);

var loaded = File.ReadAllText(path);
var obj = JsonSerializer.Deserialize<User>(loaded);
Console.WriteLine($"{obj?.Id}:{obj?.Name}");

record User(int Id, string Name);
```

逐段看：

- `JsonSerializer.Serialize(obj, options)`：对象 → JSON 字符串。`WriteIndented = true` 是缩进美化（调试友好；线上传输不缩进）。
- `File.WriteAllText(path, json)` 落盘，`ReadAllText` 读回——IO 部分是上一节的方法。
- `JsonSerializer.Deserialize<User>(loaded)`：字符串 → 对象（**泛型**告诉它目标类型）。
- `obj?.Id`：反序列化返回 `User?`（第 10 章）——**JSON 顶层是 `null` 是合法输入**，`?.` 判空是标准姿势。

record 与 JSON 是天作之合（第 05 章）：位置属性名即字段名、不可变构造恰好匹配"从文本构造数据"、无多余行为。API 请求/响应、配置文件、缓存载荷，全部是"record + JsonSerializer"。

## 3. 常用选项

`JsonSerializerOptions` 决定映射细节，常用的：

```csharp
var options = new JsonSerializerOptions
{
    WriteIndented = true,                      // 缩进
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,   // C# 的 UserName ↔ JSON 的 userName
};
```

两个实践要点：

- **实例要复用**：options 内部有解析缓存，每次 new 会重复构建（BCL 后来加了缓存源，但复用仍是零成本习惯）；静态只读字段存一份即可。
- 大小写：默认是**精确大小写匹配**——C# 属性 `Name` 序列化成 `"Name"`，而 Web 世界惯例是 camelCase；配 `PropertyNamingPolicy` 打通。

## 4. JSON 与可空（连回第 10 章）

字段在 JSON 里缺失时：引用类型得 null、`int` 得 0——**数值 0 与"缺失"无法区分**，这是 int 类型的盲区。解法在类型上：`record Config(int Retries, string? NextPageToken)` 用 `string?` 表达"可缺失"；需要区分 0/缺失的数值用 `int?`。反序列化目标类型就是把 JSON 形状翻译成 C# 契约——第 10 章的功课后置到这兑现。

## 5. 坑位清单

1. **无 Encoding 参数的读写乱码**：中文 Windows 上默认 GBK，文件若是 UTF-8（现代默认）就花——`ReadAllText(path, Encoding.UTF8)` 一律显式。
2. **字段名不匹配静默得默认值**：JSON 是 `user_name` 而 C# 属性是 `UserName`，反序列化**不报错**，得 null——排查"字段莫名是 null"先看名字大小写/命名策略。
3. **临时文件不清理**：示例写临时目录无妨；长期运行的服务往 temp 塞文件是磁盘慢性泄漏——`try/finally` 里 `File.Delete` 或用完即弃的命名规则。
4. **路径硬编码 `/` 或 `\`**：Windows 上能跑、Linux 上炸（或反之）——见开头的跨平台铁律。
5. **大文件用 ReadAllText**：几百 MB 一口气进内存；流式处理用 `File.Open` + `StreamReader` 逐行，或 JSON 的 `JsonDocument`/`DeserializeAsyncEnumerable`。
