// 33 · 序列化与 System.Text.Json：反射版与源生成版
using System.Text.Json;
using System.Text.Json.Serialization;

Console.OutputEncoding = System.Text.Encoding.UTF8;

var repo = new Repo
{
    Name = "csharp-tutorial",
    Stars = 1024,
    UpdatedAt = new DateTime(2026, 9, 1, 0, 0, 0, DateTimeKind.Utc),
    Tags = new List<string> { "tutorial", "csharp" },
    SecretToken = "不该被序列化的字段",
};

Console.WriteLine("===== 基础序列化 / 反序列化 =====");
var json = JsonSerializer.Serialize(repo, JsonOptsHolder.JsonOpts);
Console.WriteLine($"  {json}");
var back = JsonSerializer.Deserialize<Repo>(json, JsonOptsHolder.JsonOpts)!;
Console.WriteLine($"  读回: {back.Name} ⭐{back.Stars}（类型安全：字段对得上才能还原）");

Console.WriteLine();
Console.WriteLine("===== 常用特性 =====");
Console.WriteLine("  [JsonPropertyName(\"name\")]  → 属性改名（对接外部 API 的蛇形命名）");
Console.WriteLine("  [JsonIgnore]                 → SecretToken 没出现在 json 里，就是它");
Console.WriteLine("  [JsonConverter(typeof(…))]   → 自定义转换（日期格式、多态）");

Console.WriteLine();
Console.WriteLine("===== JsonDocument：不建模直接查 DOM =====");
using var doc = JsonDocument.Parse(json);
var root = doc.RootElement;
Console.WriteLine($"  name = {root.GetProperty("name")}");
Console.WriteLine($"  tags[1] = {root.GetProperty("tags")[1]}");
Console.WriteLine("  场景：结构不定/只取几个字段——省得为一次查询建整棵类树");

Console.WriteLine();
Console.WriteLine("===== 源生成序列化（第 24 章的落地）=====");
var fastJson = JsonSerializer.Serialize(repo, SourceGenContext.Default.Repo);
Console.WriteLine($"  {fastJson}");
Console.WriteLine("  JsonSerializerContext 在编译期生成序列化代码：启动快、无反射、AOT 可用");
Console.WriteLine("  产物在 obj/**/*JsonSerializerContext*.g.cs——亲眼可见的「源生成器」");

Console.WriteLine();
Console.WriteLine("===== 注意点 =====");
Console.WriteLine("  属性用 public set（init 也行），私有字段默认不序列化");
Console.WriteLine("  枚举转字符串用 JsonStringEnumConverter");
Console.WriteLine("  循环引用配 ReferenceHandler.Cycle；大文件用 SerializeAsync 流式写");

public class Repo
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("stars")]
    public int Stars { get; set; }

    [JsonPropertyName("updated_at")]
    public DateTime UpdatedAt { get; set; }

    [JsonPropertyName("tags")]
    public List<string> Tags { get; set; } = new();

    [JsonIgnore]
    public string? SecretToken { get; set; }
}

public static class JsonOptsHolder
{
    public static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);
}

[JsonSerializable(typeof(Repo))]
public partial class SourceGenContext : JsonSerializerContext { }
