# 33 · 序列化与 JSON

> 对应示例：`examples/33_json`

> **本章你将学会**：System.Text.Json 基础、常用特性、JsonDocument 查询、源生成序列化、注意事项清单。
> **前置章节**：[11 record](11-records.md)、[24 源生成器](24-metaprogramming.md)。

## 1. 序列化在干什么

对象（内存里的图）↔ 文本/字节（可传输可保存）的双向转换：

```csharp
var repo = new Repo { Name = "csharp-tutorial", Stars = 1024, ... };

var json = JsonSerializer.Serialize(repo, JsonOpts);      // 对象 → JSON 文本
var back = JsonSerializer.Deserialize<Repo>(json, JsonOpts)!;   // JSON → 对象
```

反序列化是"按 JSON 的字段名找到同名属性填进去"——**类型安全**：字段对不上（缺了/类型不符）要么用默认值要么抛，绝不含糊地静默错。

## 2. 常用特性：把 C# 形状捏成 JSON 形状

```csharp
public class Repo
{
    [JsonPropertyName("name")]        // 属性改名（对接蛇形命名 API：name/stars/updated_at）
    public string Name { get; set; } = "";

    [JsonIgnore]                      // 这个字段不出现在 JSON 里（密码/内部状态）
    public string? SecretToken { get; set; }

    [JsonConverter(typeof(DateTimeConverter))]   // 自定义转换（格式/多态）
    public DateTime UpdatedAt { get; set; }
}
```

| 特性 | 作用 |
|---|---|
| `[JsonPropertyName("x")]` | 属性名映射 |
| `[JsonIgnore]` | 跳过序列化 |
| `[JsonConverter(T)]` | 该属性用自定义转换器 |
| `[JsonExtensionData("ext")]` | 收容未知字段（兼容老版本数据） |
| `[JsonInclude]` | 让私有字段/私有属性也参与 |

选项对象（JsonSerializerOptions）管全局：命名策略（`JsonSerializerDefaults.Web` = camelCase + 不区分大小写）、缩进、枚举转字符串（`JsonStringEnumConverter`）——**全局策略一份，特性做例外**。

## 3. JsonDocument：不建模直接查

结构不定 / 只取几个字段时，别为一次查询建整棵类树：

```csharp
using var doc = JsonDocument.Parse(json);
var root = doc.RootElement;
root.GetProperty("name")           // 按名取
root.GetProperty("tags")[1]        // 按下标取
root.EnumerateArray()              // 遍历
```

JsonDocument 是**只读 DOM**（解析后的树），用完 Dispose（内部池化了缓冲）。写方向的对应物是 `Utf8JsonWriter`（手写高性能 JSON 输出）。**DOM 灵活但有解析全量成本**；强类型零建模成本但形状钉死——按数据的"稳定程度"选。

## 4. 源生成序列化（第 24 章的落地）

```csharp
[JsonSerializable(typeof(Repo))]
public partial class SourceGenContext : JsonSerializerContext { }

var fastJson = JsonSerializer.Serialize(repo, SourceGenContext.Default.Repo);
```

编译期生成 Repo 的序列化代码（`obj/**/*JsonSerializerContext*.g.cs` 里**亲眼可读**）——对比默认反射模式：

| | 反射模式（默认） | 源生成模式 |
|---|---|---|
| 启动 | 首次序列化反射构建元数据（慢） | 编译期付清（快） |
| 运行时 | 反射读写属性 | 生成代码直调 |
| AOT/裁剪 | 受限/不可用 | ✓ 完全支持 |
| 出错时机 | 运行时 | 编译期（类型不支持直接构建失败） |

**AOT 发布（NativeAOT/裁剪）强制源生成**；高性能启动敏感场景（云函数冷启动）收益明显。实体多就 `typeof` 列一排（或换 `JsonSerializerContext` 派生类自动聚合）。

## 5. 注意事项清单

- **属性可写**：序列化要 public set 或 init；**私有字段默认不参与**（要就 [JsonInclude]）
- **无参构造**：反序列化需要能造对象——record 的位置构造器被自动支持（11 章的福利）
- **循环引用**：A 引用 B、B 引用 A → 默认抛异常——配 `ReferenceHandler.Preserve` 或改设计
- **大小写**：默认**区分**；API 互通用 `PropertyNameCaseInsensitive = true`（Web 预设自带）
- **枚举**：默认数字；要字符串加 converter
- **未知字段**：默认忽略（宽容）——严格模式可配置
- **流式大 JSON**：`SerializeAsync(stream, ...)` / `DeserializeAsyncEnumerable`（JSON 数组逐项吐——28 章异步流）

## 6. 性能档位

```text
源生成强类型  >  反射强类型  >  JsonDocument DOM  >  Newtonsoft.Json(第三方)
   (最快,AOT安全)                                        (功能最全,老项目常见)
```

新项目 System.Text.Json 无悬念；读老代码会遇 Newtonsoft（Json.NET）——概念同构（特性名不同：JsonProperty vs JsonPropertyName），半天即可互译。

## 常见坑

**属性只有 get**：反序列化装不进去（默认值/空）——加 init/set。

**字段名大小写对不上**：API 给 `Name` 你收 `name`——PropertyNameCaseInsensitive 或 JsonPropertyName，别肉眼对半天。

**DateTime 带 T 和 Z**：ISO 8601 是默认——要"yyyy-MM-dd HH:mm:ss"自定义 converter；时区语义（Local/Utc/Unspecified）序列化前后要对齐。

**Dictionary 的键**：非字符串键要 converter；键的命名策略默认**不**跟随全局（`DictionaryKeyPolicy` 单独设）。

**源生成上下文忘了注册类型**：`JsonException: 没有为 X 注册生成器`——`[JsonSerializable(typeof(X))]` 补上重编。

**敏感字段进了日志**：ToString/序列化把 token 带出去——[JsonIgnore] 从第一天就位（示例的 SecretToken 演示）。

## 实战建议

- API 边界模型一律 **record + 命名特性**：不可变 + 字段映射 + ToString 排查三连（11 章组合拳）
- 全局 options 单例复用（每次 new JsonSerializerOptions 有缓存损失）；DI 场景用框架注册的那份（dotnet 教程 16 章）
- 配置文件读写：SerializeAsync 写临时文件再替换（原子性，WPF 教程 21 章的原则）+ 反序列化容错（坏了用默认 + 告警）
- 发布目标含 AOT → 从第一天用源生成模式，别等上线再迁移
- 需要手工操作 JSON 的场景分三档：改模型 > JsonDocument 查 > Utf8JsonWriter 拼——别拿字符串拼接当序列化

## 自测

1. **反序列化的"类型安全"指什么？** —— 按字段名+类型严格映射；对不上就默认/抛，不静默乱装。
2. **源生成模式的四大优势？** —— 启动快、运行时直调、AOT 支持、编译期报错。
3. **JsonDocument 适用场景？** —— 结构不定/只取少数字段；代价是解析全量 DOM。
4. **循环引用的两个出路？** —— ReferenceHandler.Preserve（打标记）或改设计去环。

---
上一章：[32 文件与 IO](32-files-io.md) ｜ 下一章：[34 诊断与日志](34-diagnostics.md) ｜ 返回：[README](../README.md)
