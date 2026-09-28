// 43 · 常用工具类型：日期时间、Guid、Uri、Math、Random——四本教材共讲、本教程此前只顺带
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== DateTime：一个时刻 =====");
var release = new DateTime(2026, 11, 10, 9, 0, 0);   // 年月日时分秒
Console.WriteLine($"  构造: {release}");
Console.WriteLine($"  属性: Year={release.Year} Month={release.Month} Day={release.Day} DayOfWeek={release.DayOfWeek}");
Console.WriteLine($"  长短格式: {release.ToLongDateString()} {release.ToShortTimeString()}");
Console.WriteLine($"  自定义格式串: {release:yyyy/MM/dd HH:mm:ss}（大小写有语义：mm=分钟 MM=月份）");
Console.WriteLine("  注意 DateTime 是 struct（值类型）——11 章讲过它和 TimeSpan、Guid 一样是不可变小结构");

Console.WriteLine();
Console.WriteLine("===== 解析：Parse / TryParse / ParseExact =====");
var zh = System.Globalization.CultureInfo.GetCultureInfo("zh-CN");
DateTime parsed = DateTime.Parse("2026-12-25", System.Globalization.CultureInfo.InvariantCulture);
Console.WriteLine($"  Parse(\"2026-12-25\") → {parsed:yyyy-MM-dd}（ISO 形态各文化都认，最稳的机器格式）");
if (DateTime.TryParse("2027年2月14日", zh, System.Globalization.DateTimeStyles.None, out DateTime loose))
    Console.WriteLine($"  TryParse 中文串(zh-CN): {loose:yyyy-MM-dd}（按文化认本地写法——但别依赖它写解析器）");
try { DateTime.ParseExact("2026-02-30", "yyyy-MM-dd", null); }
catch (FormatException) { Console.WriteLine("  ParseExact(\"2026-02-30\") → FormatException：日期本身非法，格式对了也没用"); }
if (DateTime.TryParseExact("31/12/2026", "dd/MM/yyyy", null, System.Globalization.DateTimeStyles.None, out DateTime exact))
    Console.WriteLine($"  TryParseExact(\"31/12/2026\", \"dd/MM/yyyy\") → {exact:yyyy-MM-dd}（格式钉死，交接文件首选）");
else
    Console.WriteLine("  TryParseExact 失败");
Console.WriteLine("  选型：用户输入 → TryParse；机器格式 → TryParseExact；确信合法 → Parse");

Console.WriteLine();
Console.WriteLine("===== Now / UtcNow / Kind：本地时间是个「显示层」概念 =====");
var now = DateTime.Now;
var utc = DateTime.UtcNow;
Console.WriteLine($"  Now    = {now:yyyy-MM-dd HH:mm:ss}  Kind={now.Kind}");
Console.WriteLine($"  UtcNow = {utc:yyyy-MM-dd HH:mm:ss}  Kind={utc.Kind}");
Console.WriteLine($"  差值   = {(now - utc).TotalHours:F1} 小时（本机时区偏移，随夏令时变）");
Console.WriteLine("  规则：存储/比较/传给别的系统用 UtcNow；给人看的那一刻才转本地");
var naive = new DateTime(2026, 6, 1, 12, 0, 0);          // Kind=Unspecified：不知道代表哪个时区
var stamped = DateTime.SpecifyKind(naive, DateTimeKind.Utc);
Console.WriteLine($"  SpecifyKind: {naive.Kind} → {stamped.Kind}（只贴标签不改数值；转 UTC 该用 .ToUniversalTime()）");

Console.WriteLine();
Console.WriteLine("===== TimeSpan：一段时间（时长/差值） =====");
var film = new TimeSpan(2, 21, 0);                        // 《指环王3》加长版 2小时21分
var extra = TimeSpan.FromMinutes(11);
Console.WriteLine($"  时长: {film}  加彩蛋 {extra} → 共 {film + extra}");
var start = new DateTime(2026, 10, 1, 19, 0, 0);
Console.WriteLine($"  {start:MM-dd HH:mm} 开场，散场 {start + film + extra:HH:mm}");
Console.WriteLine($"  总分钟数: {(film + extra).TotalMinutes:F0}（Total 系列给小数；Minutes 只给余数部分）");
Console.WriteLine("  陷阱：film.Minutes 是 21 不是 141——要总时长用 TotalMinutes");

Console.WriteLine();
Console.WriteLine("===== DateOnly / TimeOnly（.NET 6+）：纯日期、纯时间 =====");
var birthday = new DateOnly(2027, 3, 14);
var openTime = new TimeOnly(9, 30);
Console.WriteLine($"  生日 {birthday}（无时区无时分秒——生日/截止日就该用它，别拿 DateTime 凑）");
Console.WriteLine($"  营业开始 {openTime}，闭店 {openTime.AddHours(10)}，再过 8 小时 → {openTime.AddHours(18)}（24 小时环，超出自动回绕）");
Console.WriteLine($"  DateTime ↔ 拆装: {birthday.ToDateTime(openTime)}；{DateTime.Now:HH:mm} 取 TimeOnly → {TimeOnly.FromDateTime(DateTime.Now)}");

Console.WriteLine();
Console.WriteLine("===== TimeZoneInfo：跨时区换算 =====");
Console.WriteLine($"  本机时区: {TimeZoneInfo.Local.Id}（UTC{(TimeZoneInfo.Local.BaseUtcOffset >= TimeSpan.Zero ? "+" : "")}{TimeZoneInfo.Local.BaseUtcOffset:hh\\:mm}）");
TimeZoneInfo? ny = TryFindZone("America/New_York", "Eastern Standard Time");
if (ny is not null)
{
    var meetingUtc = new DateTime(2026, 11, 10, 14, 0, 0, DateTimeKind.Utc);
    Console.WriteLine($"  UTC {meetingUtc:HH:mm} 的会议 → 纽约 {TimeZoneInfo.ConvertTimeFromUtc(meetingUtc, ny):yyyy-MM-dd HH:mm}");
    Console.WriteLine($"    纽约当时偏移 {ny.GetUtcOffset(meetingUtc)}（11 月已结束夏令时，EST=-5）");
}
static TimeZoneInfo? TryFindZone(string ianaId, string windowsId)
{
    try { return TimeZoneInfo.FindSystemTimeZoneById(ianaId); }        // .NET 6+ 双平台都认 IANA
    catch (TimeZoneNotFoundException) { }
    try { return TimeZoneInfo.FindSystemTimeZoneById(windowsId); }    // 兜底：老 Windows ID
    catch (TimeZoneNotFoundException) { return null; }
}

Console.WriteLine();
Console.WriteLine("===== Guid：全局唯一标识符 =====");
var g1 = Guid.NewGuid();
var g2 = Guid.NewGuid();
Console.WriteLine($"  NewGuid(): {g1}");
Console.WriteLine($"  再来一个: {g2}（122 位随机熵，碰撞概率小到可以当不可能）");
Console.WriteLine($"  ToString(\"N\"): {g1:N}（无连字符，36→32 字符，做文件名/字典键常用）");
Console.WriteLine($"  字节数: {g1.ToByteArray().Length}（128 位，16 字节——就是个 struct）");
Console.WriteLine("  连续两次运行本程序，两个 Guid 都不同（与 Random 同种子不同，没有种子概念）");

Console.WriteLine();
Console.WriteLine("===== Uri：统一资源标识符的拆解 =====");
var url = new Uri("https://learn.microsoft.com:443/zh-cn/dotnet/api/system.datetime?view=net-10.0#ctor");
Console.WriteLine($"  {url}");
Console.WriteLine($"  Scheme={url.Scheme}  Host={url.Host}  Port={url.Port}（https 默认 443 不显式写也返回 443）");
Console.WriteLine($"  路径={url.AbsolutePath}");
Console.WriteLine($"  查询={url.Query}  片段={url.Fragment}");
Console.WriteLine($"  拼接: {new Uri(url, "system.timespan")}（相对路径解析——爬虫/分页 URL 的标准做法）");
if (Uri.TryCreate("not a url", UriKind.Absolute, out _))
    Console.WriteLine("  TryCreate 认为 'not a url' 合法（它允许 mailto: 等任意 scheme）");
else
    Console.WriteLine("  TryCreate(\"not a url\") → false（用户输入先过这关再 new）");

Console.WriteLine();
Console.WriteLine("===== Math：比「会开方」更重要的是这些 =====");
Console.WriteLine($"  Math.Sqrt(2)={Math.Sqrt(2):F6}  Math.Pow(2,10)={Math.Pow(2, 10)}  Math.Abs(-7)={Math.Abs(-7)}");
Console.WriteLine($"  Math.Sign(-3.5)={Math.Sign(-3.5)}（返回 -1/0/1，不是原值）");
Console.WriteLine($"  Math.Truncate(-2.7)={Math.Truncate(-2.7)} vs (int)(-2.7)={(int)(-2.7)}（截断向零，转换也向零；四舍五入才是 Round）");
Console.WriteLine($"  Math.Round(2.5)={Math.Round(2.5)}  Math.Round(3.5)={Math.Round(3.5)}（银行家舍入：.5 取偶数！）");
Console.WriteLine($"  Math.Clamp(150, 0, 100)={Math.Clamp(150, 0, 100)}（限幅一行搞定：音量/进度/游戏血条）");
Console.WriteLine($"  Math.Max/Math.Min: {Math.Max(3, 9)} / {Math.Min(3, 9)}");

Console.WriteLine();
Console.WriteLine("===== Random：同种子=同序列（可复现实验的前提） =====");
var r1 = new Random(42);
var r2 = new Random(42);
int[] seq1 = [.. Enumerable.Range(0, 6).Select(_ => r1.Next(100))];
int[] seq2 = [.. Enumerable.Range(0, 6).Select(_ => r2.Next(100))];
Console.WriteLine($"  new Random(42) 实例A: [{string.Join(", ", seq1)}]");
Console.WriteLine($"  new Random(42) 实例B: [{string.Join(", ", seq2)}]");
Console.WriteLine("  两组完全相同——种子决定一切。游戏回放/单元测试/抽样复现就靠它（贪吃蛇确定性回放同款原理）");
Console.WriteLine("  教材时代的坑：老 .NET Framework 里循环内 new Random() 用时钟做种，快速连建多个实例同种子同序列——");
Console.WriteLine("  现代 .NET 已修：无参构造从全局熵取种，随便 new。但「共享一个实例或用 Random.Shared」仍是好习惯");

var pick = Random.Shared.Next(1, 7);                      // Next 上界开区间：1..6
Console.WriteLine($"  Random.Shared.Next(1,7) 掷骰子 → {pick}（上界不开！要 1..6 就写 (1,7)）");
string[] menu = ["宫保鸡丁", "鱼香肉丝", "麻婆豆腐", "回锅肉", "水煮鱼"];
var chosen = Random.Shared.GetItems(menu, 3);             // .NET 8+：有放回抽 3 个
Console.WriteLine($"  GetItems 有放回抽3: {string.Join("、", chosen)}");
var shuffled = (string[])menu.Clone();
Random.Shared.Shuffle(shuffled);                          // .NET 8+：原地洗牌（Fisher-Yates）
Console.WriteLine($"  Shuffle 洗牌: {string.Join(" → ", shuffled)}");
Console.WriteLine($"  安全随机: RandomNumberGenerator.GetInt32(1, 7) → {System.Security.Cryptography.RandomNumberGenerator.GetInt32(1, 7)}");
Console.WriteLine("  （验证码/密钥/令牌用 RandomNumberGenerator——Random 是可预测的统计随机）");

Console.WriteLine();
Console.WriteLine("===== 速查：这批类型的「身份」 =====");
Console.WriteLine("  DateTime/TimeSpan/DateOnly/TimeOnly/Guid → 全是 struct：不可变、赋值即拷贝");
Console.WriteLine("  存储/序列化用 UTC + ISO 8601（33 章 JSON 默认就这么干）；显示才转本地/本地文化");
Console.WriteLine("  需要明确「哪个人看的是哪个时区」→ DateTime 不够用，上 DateTimeOffset（带偏移的瞬间）");
