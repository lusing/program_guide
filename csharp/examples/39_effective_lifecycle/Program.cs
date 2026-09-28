// 39 · Effective C#·初始化与对象生命周期（书第 2 章 条 11-17 的工程细则）
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 条 12: 字段声明处直接初始化（多构造函数自动生效） =====");
var a1 = new Widget("A");                       // 两个构造函数都自动带上 labels 初始化
var a2 = new Widget("B", 10);
Console.WriteLine($"  Widget(\"A\").Labels.Count = {a1.Labels.Count}，Widget(\"B\",10) 同样 = {a2.Labels.Count}");
Console.WriteLine("  初始化器被编译器放进「每个」构造函数开头——加新构造函数不会忘初始化");
Console.WriteLine("  三个例外（不该用初始化器）：");
Console.WriteLine("   ① 初始化为 0/null——运行时本来就清零了，写了是重复劳动（还多一条 initobj 指令）");
var w2 = new WidgetTwo(16);                     // 例外②的反模式实测
Console.WriteLine($"   ② 例外②实测: WidgetTwo 声明处 new() 了 List，构造函数里又 new 了一个替换它（最终 count={w2.Labels.Count}，头一个白建）。修法：初始化方式因构造函数而异 → 删初始化器，全部链到主构造函数");
Console.WriteLine("   ③ 初始化可能抛异常 → 挪进构造函数（初始化器无法 try/catch）");

Console.WriteLine();
Console.WriteLine("===== 对象构造的 8 步顺序（首次创建该类型的实例） =====");
Console.WriteLine("  ① 静态字段清零 ② 静态字段初始化器 ③ 基类静态ctor ④ 本类静态ctor");
Console.WriteLine("  ⑤ 实例字段清零 ⑥ 实例字段初始化器 ⑦ 基类实例ctor ⑧ 本类实例ctor");
var order = new InitOrder();
Console.WriteLine($"  实测（见下面输出）: 派生类【字段初始化器】先于【基类构造函数】执行！");
Console.WriteLine("  推论：基类构造函数里能看到派生类字段初始化器的值——这正是条 16 灾难的根源");

Console.WriteLine();
Console.WriteLine("===== 条 16: 绝对不在构造函数里调用虚函数 =====");
var vd = new VirtualDerived();
Console.WriteLine($"  基类 ctor 里 VFunc() 返回的是 \"{vd.BaseSaw}\"");
Console.WriteLine($"  而构造函数最终赋的值是 \"{vd.Final}\"——基类根本读不到");
Console.WriteLine("  原因对照 8 步顺序：派生字段初始化器（第⑥步）先于基类 ctor（第⑦步）先于派生 ctor（第⑧步）");
Console.WriteLine("  基类 ctor 期间调用派生重写 → 派生的最终状态还没建立，读到的是半成品。FxCop 会报此问题");

Console.WriteLine();
Console.WriteLine("===== 条 13: 静态成员的三种初始化方式 =====");
Console.WriteLine($"  静态初始化器: Config.Default = \"{Config.Default}\"（简单赋值首选）");
Console.WriteLine($"  静态构造函数: Config.Loaded（复杂逻辑可 try/catch）= \"{Config.Loaded}\"");
try
{
    var _ = Broken.Once;                        // 静态 ctor 抛异常 → TypeInitializationException
}
catch (TypeInitializationException ex)
{
    Console.WriteLine($"  静态 ctor 抛异常 → {ex.GetType().Name}（包裹真实异常）");
    Console.WriteLine("  更糟：该类型在本次进程中永久不可用——CLR 不会再试第二次静态 ctor");
}
Console.WriteLine("  复杂/昂贵初始化还可以 Lazy<T> 推迟到首次访问（线程安全由它管）");
var lazy = new Lazy<Heavy>(() => new Heavy());
Console.WriteLine($"  Lazy 实测: 未触碰 IsValueCreated={lazy.IsValueCreated}；触碰后={((Func<bool>)(() => { var _ = lazy.Value; return lazy.IsValueCreated; }))()}");

Console.WriteLine();
Console.WriteLine("===== 条 14: 构造链 this(...) 删减重复 + 默认参数 =====");
var c1 = new Chain("x");
var c2 = new Chain("y", 5);
Console.WriteLine($"  Chain(\"x\") → name={c1.Name} count={c1.Count};  Chain(\"y\",5) → count={c2.Count}");
Console.WriteLine("  三个构造函数共用逻辑：全部 this(...) 链到主构造函数，不复制粘贴、不提取辅助方法");
Console.WriteLine("  为什么不用「私有辅助方法 InitAll()」：辅助方法版每个 ctor 都重复执行字段初始化器+调基类 ctor；");
Console.WriteLine("  链式版编译器只在链尾做一次。且 readonly 字段只有构造函数/初始化器能赋——辅助方法赋不了");
Console.WriteLine("  默认参数可进一步收缩构造函数数量，但默认值嵌进调用点（同条 2 的 const 语义）——");
Console.WriteLine("  改默认值要重编调用方；并且 new() 泛型约束只认「显式无参构造」，全默认参数不算——");
Console.WriteLine("  想被 where T : new() 用就得显式写一个无参构造。默认值还得是编译期常量：");
Console.WriteLine("  \"\" 可以，string.Empty 不行（它是静态属性不是 const）");

Console.WriteLine();
Console.WriteLine("===== 条 15: 不创建无谓的对象（分配/回收都要钱） =====");
const int N = 200_000;
var sw = System.Diagnostics.Stopwatch.StartNew();
var sink = 0L;
for (int i = 0; i < N; i++)
{
    var payload = new int[8];                   // 每轮新分配（演示热路径反模式）
    payload[0] = i; sink += payload[0];
}
sw.Stop();
var perAlloc = sw.ElapsedTicks;
var cached = new int[8];                        // 提升出来复用
sw.Restart();
for (int i = 0; i < N; i++)
{
    cached[0] = i; sink += cached[0];           // 零新分配
}
sw.Stop();
Console.WriteLine($"  循环内 new int[8] × {N}: {perAlloc} ticks；复用同一数组: {sw.ElapsedTicks} ticks（sink={sink}）");
Console.WriteLine("  原理：分配+GC 压力都是成本。热路径里反复创建的同构对象 → 提升为成员/静态缓存");
Console.WriteLine("  书的三个手段：①频繁例程的局部引用对象提升成成员 ②常用实例做静态（Brushes.Black 思路）");
Console.WriteLine("               ③不可变类型配 builder（String → StringBuilder）");

Console.WriteLine();
Console.WriteLine("===== 条 15 附: 字符串三写法的分配账 =====");
sw.Restart();
var s1 = "";
for (int i = 0; i < 2_000; i++) s1 += "x";      // 每轮一个新 string（旧的成垃圾）
sw.Stop(); var plusEqual = sw.ElapsedTicks;
var sb = new System.Text.StringBuilder();
sw.Restart();
for (int i = 0; i < 2_000; i++) sb.Append('x');
var s2 = sb.ToString();
sw.Stop(); var sbTicks = sw.ElapsedTicks;
Console.WriteLine($"  += 循环 2000 次: {plusEqual} ticks；StringBuilder 同样 2000 次: {sbTicks} ticks（长度 {s1.Length}={s2.Length}）");
Console.WriteLine("  少量拼接用插值字符串（编译器优化成 string.Concat）；循环拼接才上 StringBuilder");

Console.WriteLine();
Console.WriteLine("===== 条 11 / 17 回顾（详见第 25 章） =====");
Console.WriteLine("  资源管理心智模型：GC 只管内存；数据库连接/句柄等非托管资源要 IDisposable + using");
Console.WriteLine("  终结器是兜底不是手段（多活一代、专用线程跑）；标准 Dispose 模板见第 25 章第 4 节");

Console.WriteLine();
Console.WriteLine("  本章与第 25 章的分工：25 章讲 GC 与 Dispose 模式（条 11/17），本章讲初始化与分配习惯（条 12-16）");

public class Widget
{
    private readonly List<string> labels = new();        // 条 12：初始化器
    public IReadOnlyCollection<string> Labels => labels;
    public Widget(string name) { labels.Add(name); }
    public Widget(string name, int extra) { labels.Add(name); labels.Add($"extra{extra}"); }
}

public class WidgetTwo                          // 例外②的反模式（正解：删掉初始化器，构造函数链到主 ctor）
{
    public List<int> Labels = new();            // ← 这个 List 在带 size 的构造路径上是白建的
    public WidgetTwo(int size) => Labels = new List<int>(size);
}

public class InitOrder
{
    static InitOrder() => Console.WriteLine("  [类型初始化] InitOrder 静态构造函数（首次 new 前）");
    public InitOrder() => Console.WriteLine("  [第⑧步] InitOrder 实例构造函数（静态的④在其之前）");
}

public static class Config
{
    public static readonly string Default = "default.json";        // 静态初始化器（方式一）
    public static readonly string Loaded = LoadOrDefault();        // 逻辑放静态方法（方式二：可 try/catch）
    private static string LoadOrDefault()
    {
        try { return "loaded.json"; }
        catch { return "fallback.json"; }
    }
}

public static class Broken
{
    public static readonly int Once = Explode();
    private static int Explode() => throw new InvalidOperationException("初始化失败");
}

public sealed class Heavy { public Heavy() => Console.WriteLine("  [Heavy] 昂贵对象被构造了"); }

public class Chain
{
    public string Name { get; }
    public int Count { get; }
    public Chain() : this("anonymous") { }
    public Chain(string name) : this(name, 0) { }                  // 链式：删减重复
    public Chain(string name, int count) { Name = name; Count = count; }
}

public class VirtualBase
{
    public readonly string BaseSaw;
    public VirtualBase() => BaseSaw = VFunc();                     // 反面教材：ctor 里调虚函数
    public virtual string VFunc() => "VFunc in Base";
}
public sealed class VirtualDerived : VirtualBase
{
    private readonly string _msg = "Set by initializer";           // 第⑥步先跑
    private readonly string? _final;
    public VirtualDerived() => _final = "Constructed in Derived";  // 第⑧步后跑
    public override string VFunc() => _msg;                        // 基类 ctor 调到的就是这个——半成品
    public string Final => _final ?? "(未初始化)";
}
