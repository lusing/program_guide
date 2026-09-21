// 21 · 可空引用类型：null 从"运行时炸弹"变"编译期红波浪"
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 两类可空，一个符号 =====");
int? maybe = null;                      // 可空值类型：真的多一个状态（HasValue）
string? maybeText = null;               // 可空引用类型（NRT）：只是编译期标注，运行时仍是引用
Console.WriteLine($"  int? 为 null: HasValue={maybe.HasValue}, ??兜底={maybe ?? -1}");
Console.WriteLine($"  string? 为 null: {maybeText?.Length ?? -1}   ← ?. 只在非 null 时取值");

Console.WriteLine();
Console.WriteLine("===== NRT 是编译期分析，不是运行时保证 =====");
string danger = GetSneakyNull();
Console.Write($"  编译器放行的非可空变量，实际装着: ");
Console.WriteLine(danger is null ? "null！（外部输入不受保护）" : danger);
Console.WriteLine("  教训：公共 API 入口仍要运行时检查，NRT 只是第一道门");

static string GetSneakyNull() => null!;   // !：骗过编译器的"我知道不是null"断言

Console.WriteLine();
Console.WriteLine("===== 防御三件套 =====");
static int LenOf(string? s)
{
    ArgumentNullException.ThrowIfNull(s);   // ① 入口显式拒绝 null（抛 ArgumentNullException）
    return s.Length;                        // 检查后编译器知道 s 非 null
}
Console.WriteLine($"  ThrowIfNull 后: {LenOf("hello")} 个字符");

var config = new Dictionary<string, string?> { ["host"] = "db01", ["port"] = null };
var host = config["host"] ?? "localhost";               // ② ?? 兜底
var port = config.GetValueOrDefault("port") ?? "3306";  // 缺键/空值都有默认
Console.WriteLine($"  兜底: host={host}, port={port}");

_ = "  张三  ".Trim();                                  // ③ 数据源头就清洗成非空

Console.WriteLine();
Console.WriteLine("===== 值类型可空的典型场景 =====");
var found = new[] { 1, 3, 5 }.FirstOrDefault(n => n % 2 == 0);   // 没找到 = 0，分不清"没找到"和"恰好是0"
var found2 = new[] { 1, 3, 5 }.Cast<int?>().FirstOrDefault(n => n % 2 == 0);  // int? 版：没找到 = null
Console.WriteLine($"  找偶数: int 版={found}（歧义！），int? 版={found2?.ToString() ?? "null（明确没找到）"}");

Console.WriteLine();
Console.WriteLine("===== 文件级开关与注解家族 =====");
Console.WriteLine("  csproj 的 <Nullable>enable</Nullable> 打开全项目检查");
Console.WriteLine("  [MaybeNull] 返回值可能为 null；[NotNull] 参数回填后非空；#nullable disable 临时关闭");
Console.WriteLine("  老项目迁移：enable + 逐文件修，别追求一次清零");
