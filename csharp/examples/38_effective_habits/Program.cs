// 38 · Effective C#·语言习惯（书第 1 章 条 1-10）：日常写法的十条军规
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 条 1: var 的使用判据（优先，不是总是） =====");
var names = new List<string> { "Ada", "Grace" };   // 构造表达式右边写着类型 → var 很清楚
Console.WriteLine($"  var names = new List<string>{{...}}: 右边能看出类型，var 让读者聚焦语义");
// 数值变量要显式——隐式数值转换会让结果随右边类型悄悄变：
double magic = 100.0 / 6;
Console.WriteLine($"  数值别用 var：100.0/6 = {magic:F4}（若右边是整数除法，值直接变 0/16——var 会掩盖这种变化）");
Console.WriteLine("  书的判据：读者必须看到类型才能读懂 → 写出类型；否则 var");

Console.WriteLine();
Console.WriteLine("===== 条 2: readonly 优先于 const（跨程序集实测见本章文档） =====");
const int CompileTime = 10;                        // 编译期：字面量直接嵌进调用方 IL
Console.WriteLine($"  const int CompileTime = {CompileTime}（只能基元类型/字符串/null，天生 static）");
Console.WriteLine($"  static readonly int Runtime = {Limits.Runtime}（可 new DateTime()、可算出来、可按实例设 readonly）");
Console.WriteLine("  两程序集实测（见 docs/38）：只重发库 DLL 时 readonly 新值生效、const 仍旧值——");
Console.WriteLine("  改 public const 等于改接口（调用方全部要重编），改 readonly 等于改实现");

Console.WriteLine();
Console.WriteLine("===== 条 3: is / as 优先于强制转换 =====");
object o = new SecondType();
// 强转走「编译期类型」找用户转换——object → MyType 没有定义，运行时直接炸：
try { var m = (MyType)o; }
catch (InvalidCastException) { Console.WriteLine("  (MyType)o 强转 → InvalidCastException（编译期类型 object 上没定义转换）"); }
var st = o as SecondType;                          // as：失败得 null，不炸
Console.WriteLine($"  o as SecondType → {(st is null ? "null" : "成功")}（转换不成引用类型就给 null，不用 try/catch）");
object boxedInt = 42;
// int 是值类型不能 as（无法表达 null）——转 int? 再判：
if (boxedInt is int maybe) Console.WriteLine("  模式匹配 is int maybe：值类型判转的现代写法（as 的替代）");
Console.WriteLine("  foreach 对非泛型 IEnumerable 用的是 cast 不是 as → 元素类型不匹配当场炸");
Console.WriteLine("  Enumerable.Cast<double>() 同理是 cast：ints.Cast<double>() 运行时失败，得 Select(x => (double)x)");

Console.WriteLine();
Console.WriteLine("===== 条 4: 内插字符串取代 string.Format =====");
var user = "Ada"; var count = 3;
Console.WriteLine($"  旧: string.Format(\"{{0}} 有 {{1}} 条\", user, count) —— 序号与参数对不上要运行时才发现");
Console.WriteLine($"  新: \"{user} 有 {count} 条\" —— 表达式直接写在洞里，静态可查");
Console.WriteLine($"  洞里可放表达式: {count * 100 + 5:C0}（格式说明符 :C0）、{(count > 2 ? "多" : "少")}（条件要括号，否则冒号歧义）");
Console.WriteLine($"  嵌套插值: {(count > 2 ? $"{user} 太多了" : "刚好")}");
Console.WriteLine("  警告：插值不产生参数化 SQL——洞里的值直接拼进字符串，拼 SQL 依然注入");

Console.WriteLine();
Console.WriteLine("===== 条 5: FormattableString 与区域文化 =====");
double price = 1234.56;
FormattableString fs = $"价格 {price:N2}";          // 目标类型是 FormattableString → 编译器生成「延迟格式化」对象
var de = System.String.Format(System.Globalization.CultureInfo.GetCultureInfo("de-DE"), fs.Format, fs.GetArguments());
Console.WriteLine($"  同一个插值，不同区域: 默认={fs}  de-DE={de.Replace(" ", " ")}（小数点变逗号）");
Console.WriteLine($"  Invariant（解析用）: {FormattableString.Invariant($"{{price:N2}}")} → {FormattableString.Invariant($"{price:N2}")}");
Console.WriteLine("  只在跨区域输出时才需要 FormattableString——平时直接 string 更省事");

Console.WriteLine();
Console.WriteLine("===== 条 6: nameof 取代硬编码名字字符串 =====");
static void Guard(string? value)
{
    if (value is null) throw new ArgumentNullException(nameof(value));   // 改名时重构工具连这里一起改
}
try { Guard(null); } catch (ArgumentNullException ex) { Console.WriteLine($"  nameof 参数守卫: {ex.ParamName}（分析器还能校验参数位置）"); }
Console.WriteLine($"  nameof(System.Int32.MaxValue) → {nameof(System.Int32.MaxValue)}（总是返回局部名，不是全名）");
Console.WriteLine("  用在: INPC 的属性名、异常参数名、特性参数、路由名——凡是「名字当字符串」的地方");

Console.WriteLine();
Console.WriteLine("===== 条 7: 委托表示回调 + 多播的两个坑 =====");
Func<bool> chain = () => { Console.WriteLine("  [检查用户] 返回 true"); return true; };
chain += () => { Console.WriteLine("  [检查缓存] 返回 false（被无视了）"); return false; };
Console.WriteLine($"  多播调用结果 = {chain()} ← 只取最后一个目标的返回值，前面全被无视");
Func<bool> safe = () => { Console.WriteLine("  [目标A] OK"); return true; };
safe += () => throw new InvalidOperationException("目标B 炸了");
try { safe(); } catch (InvalidOperationException) { Console.WriteLine("  某个目标抛异常 → 后面的目标全部不执行（链断）"); }
// 手动遍历委托列表：自己拿返回值 + 自己包异常
var results = new List<bool>();
foreach (Func<bool> target in safe.GetInvocationList())
{
    try { results.Add(target()); }
    catch (Exception ex) { Console.WriteLine($"  手动遍历 GetInvocationList 逐个包异常: {ex.Message} —— 链不断"); }
}
Console.WriteLine($"  两个问题都靠 GetInvocationList 手动分派解决（事件处理尤其要记得）");

Console.WriteLine();
Console.WriteLine("===== 条 8: 用 ?.Invoke() 触发事件（线程安全快照一行写法） =====");
var pub = new Publisher();
pub.Updated += (_, n) => Console.WriteLine($"  订阅者收到 n={n}");
pub.Raise(1);
pub.Raise(2);
Console.WriteLine("  旧三行写法 var h = Updated; if (h != null) h(this, e) 是「拷一份快照再调」——防的是");
Console.WriteLine("  判空之后、调用之前别的线程退订把事件置 null。?.Invoke 左侧只求值一次，等价且一行");

Console.WriteLine();
Console.WriteLine("===== 条 9: 装箱的隐匿之处 =====");
int first = 1, second = 2;
Console.WriteLine($"  插值字符串 {first} + {second} 每个值类型洞都可能装箱（params object[] 装配）");
Console.WriteLine($"  手工 ToString 防: {first.ToString()} + {second.ToString()}（热路径上值得，偶发不用管）");
var p1 = new Point(1);
IEquatable<Point> boxed = p1;      // 接口引用值类型 → 装箱
Console.WriteLine("  值类型转接口/object 的三个隐匿处: 插值、非泛型集合、接口调用——都装箱");
var list = new List<Point> { new(1) };  // 泛型集合不装箱
var copy = list[0]; copy.Bump();         // 取出的是拷贝——改的是副本
Console.WriteLine($"  List<Point>[0].X={list[0].X}（取出即拷贝：值类型集合里的元素改不动，除非整存整取）");
Console.WriteLine("  书的推论：把值类型设计成不可变（record struct 的理由之一）");

Console.WriteLine();
Console.WriteLine("===== 条 10: new 修饰符——同一对象、两种行为 =====");
BaseWidget w = new MyWidget();
MyWidget w2 = new MyWidget();
Console.WriteLine($"  ((BaseWidget)w).Normalize() → {w.Normalize()}");
Console.WriteLine($"  ((MyWidget)w2).Normalize()  → {w2.Normalize()}");
Console.WriteLine("  同一个对象，经基类引用调是基类版本、经子类引用调是子类版本——非虚方法是静态绑定的");
Console.WriteLine("  new 不是 override：它只是在子类命名空间里另放一个同名方法。行为随「引用的编译期类型」变，");
Console.WriteLine("  只该用在「新版基类塞进了与你现有子类成员重名的方法」这一种场合");

public class SecondType { }
public class MyType { }
public class MyType2 { public static explicit operator MyType2(SecondType s) => new(); }

internal static class Limits { public static readonly int Runtime = Compute(); private static int Compute() => Environment.TickCount % 7 + 11; }

internal struct Point : IEquatable<Point>   // 故意可变：演示值类型拷贝语义的坑
{
    public int X; public Point(int x) => X = x;
    public bool Equals(Point other) => X == other.X;
    public override string ToString() => $"({X})";
    public void Bump() => X++;
}

public class Publisher
{
    public event EventHandler<int>? Updated;
    public void Raise(int n) => Updated?.Invoke(this, n);   // 条 8 的正解写法
}

public class BaseWidget { public string Normalize() => "基类版本"; }
public class MyWidget : BaseWidget { public new string Normalize() => "子类版本"; }
