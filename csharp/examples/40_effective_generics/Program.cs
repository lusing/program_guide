// 40 · Effective C#·泛型设计（书第 3 章 条 18-28）：约束、特化与变体
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 条 18: 只定义刚好够用的约束 =====");
static bool AreEqualConstrained<T>(T left, T right) where T : IEquatable<T>
    => left!.Equals(right);                     // 有约束：编译器知道有强类型 Equals
static bool AreEqualFlexible<T>(T left, T right)   // 无约束：运行期探测，能优则优
    => left is IEquatable<T> eq ? eq.Equals(right) : left!.Equals(right);
Console.WriteLine($"  where T : IEquatable<T> 版: {AreEqualConstrained(1, 1)}（调用方被迫实现接口）");
Console.WriteLine($"  无约束 is IEquatable<T> 探测版: {AreEqualFlexible(1, 1)}（用得上就用强类型，用不上回落 object.Equals）");
Console.WriteLine("  约束是双向合同：给编译器证据（少转一次型），也给调用方门槛（要求越多用户越少）");
Console.WriteLine("  书的判据：把可有可无的要求删掉，只留缺它就编译不过/就写不出来的那些");

Console.WriteLine();
Console.WriteLine("===== 条 19: 运行期类型检查实现「特定类型的特化算法」 =====");
static List<T> Materialize<T>(IEnumerable<T> source) =>
    source is ICollection<T> col ? new List<T>(col) : source.ToList();   // 运行期探测，分路
var fast = new FastSource<int>([0, 1, 2, 3, 4]);                  // 整块拷贝源（GetEnumerator 会抛异常）
var items1 = Materialize(fast);
Console.WriteLine($"  ICollection<T> 特化路径: 成功灌入 [{string.Join(",", items1)}] 且【从未逐个枚举】");
var counting = new CountingSequence<int>(Enumerable.Range(0, 5).Select(x => x));  // 计数枚举器
var items2 = Materialize(counting);
Console.WriteLine($"  退化 IEnumerable 路径: 逐个枚举了 {counting.Moves} 个元素（每个都要走一次 MoveNext）");
Console.WriteLine("  同一个泛型方法，对「编译期类型相同、运行期能力不同」的参数给出不同效率的实现；");
Console.WriteLine("  这就是 IEnumerable<T> 上用 is ICollection<T> 探测的意义（BCL 的 Reverse/ToList 也这么干）");

Console.WriteLine();
Console.WriteLine("===== 条 20: IComparable<T> 与 IComparer<T> 定义顺序关系 =====");
var customers = new List<Customer> { new("Ada", 950), new("Linus", 880), new("Grace", 970) };
customers.Sort();                                // 自然顺序（按 Name，IComparable<T>）
Console.WriteLine($"  自然顺序(Sort()): {string.Join(" < ", customers.Select(c => c.Name))}");
var nameA = new Customer("Ada", 1); var nameG = new Customer("Grace", 2);
Console.WriteLine($"  运算符重载: Ada < Grace = {nameA < nameG}（operator < 内部调 CompareTo，保持一致）");
customers.Sort(Customer.CompareByRevenue);       // 备选顺序（静态方法暴露比较器）
Console.WriteLine($"  备选顺序(按营收): {string.Join(" < ", customers.Select(c => $"{c.Name}:{c.Revenue}"))}");
var a = new Customer("X", 100); var b = new Customer("Y", 100);
Console.WriteLine($"  CompareTo==0 但 Equals={(a.CompareTo(b) == 0)}? {a.CompareTo(b)} / {a.Equals(b)} ← 顺序与相等是两件事");

Console.WriteLine();
Console.WriteLine("===== 条 21: 泛型类要照顾实现了 IDisposable 的类型参数 =====");
using var engine = new DriverEngine<TempFileDriver>();
engine.Run();                                    // T 实现了 IDisposable → 引擎负责释放
using var engine2 = new DriverEngine<PlainDriver>();
engine2.Run();                                   // T 没实现也一样能用
Console.WriteLine("  局部变量场景的关键写法: using (driver as IDisposable) —— 没实现时是 null，using(null) 安全跳过");
Console.WriteLine("  若 T 的实例是成员字段 → 泛型类自己实现 IDisposable，在 Dispose 里 (_driver as IDisposable)?.Dispose()");

Console.WriteLine();
Console.WriteLine("===== 条 22: 泛型协变与逆变（in / out） =====");
IEnumerable<CelestialBody> bodies = new List<Planet> { new() };   // out：IEnumerable 协变
Console.WriteLine("  IEnumerable<out T>: List<Planet> 可以当 IEnumerable<CelestialBody> 用（只出不进）");
CelestialBody[] arr = new Planet[3];             // 数组协变是历史遗留——写入会炸：
try { arr[0] = new Asteroid(); }
catch (ArrayTypeMismatchException) { Console.WriteLine("  数组协变写入 Planet[] ← Asteroid → ArrayTypeMismatchException（运行时才炸）"); }
IComparer<CelestialBody> massComparer = Comparer<CelestialBody>.Create((x, y) => x.Mass.CompareTo(y.Mass));
var planets = new List<Planet> { new() { Mass = 3 }, new() { Mass = 1 }, new() { Mass = 2 } };
planets.Sort(massComparer);                      // 逆变：IComparer<CelestialBody> 用在要 IComparer<Planet> 的地方
Console.WriteLine($"  IComparer<in T> 逆变: 拿「比 CelestialBody」的比较器去 Sort(List<Planet>) → {string.Join(",", planets.Select(p => p.Mass))}");
Console.WriteLine("  记法：只出现在输出位 → out（协变）；只出现在输入位 → in（逆变）；既进又出 → 不变（如 IList<T>）");

Console.WriteLine();
Console.WriteLine("===== 条 23: 用「委托参数」要求类型提供方法（不造接口） =====");
static T AddVia<T>(T a, T b, Func<T, T, T> add) => add(a, b);    // 要求「T 能相加」却不定义 IAdd<T> 接口
Console.WriteLine($"  AddVia(3, 4, (a,b) => a+b) = {AddVia(3, 4, (a, b) => a + b)}");
Console.WriteLine($"  AddVia(1.5, 2.5, (a,b) => a+b) = {AddVia(1.5, 2.5, (a, b) => a + b)}");
Console.WriteLine("  C# 约束表达不了「有运算符/有静态方法/有带参构造」→ 用委托当合同，lambda 即实现");
Console.WriteLine("  BCL 同款思路：Zip(odd, even, (a,b) => ...) 的第三个参数就是「要求你提供合成方法」");

Console.WriteLine();
Console.WriteLine("===== 条 24: 有泛型方法就别再造针对基类/接口的重载 =====");
Derived d = new();
OverloadProbe.WriteMessage(d);                   // 谁被调了？
Console.WriteLine("  ↑ 打印的是 Generic 版——编译器把 T=Derived 视为完全匹配，优于「要向上转型」的基类版");
Console.Write("  想调基类版得显式转型: ");
OverloadProbe.WriteMessage2((Base)d);
Console.WriteLine("  规则：泛型方法总能精确匹配，会抢在基类/接口重载之前被选中——");
Console.WriteLine("  数值类型例外（int/double 无继承关系），所以 Enumerable.Max 有 int/double 等一串具体重载");

Console.WriteLine();
Console.WriteLine("===== 条 25: 泛型方法优先于泛型类（工具类别整体泛型化） =====");
Console.WriteLine($"  Utils.Max(3, 9) = {Utils.Max(3, 9)}（调用方不用写类型参数——推断）");
Console.WriteLine($"  Utils.Max(2.5, 1.5) = {Utils.Max(2.5, 1.5)}（命中 int/double 具体重载，直接比大小不走比较器）");
Console.WriteLine($"  Utils.Max(\"a\", \"b\") = {Utils.Max("a", "b")}（落到泛型版 Comparer<T>）");
Console.WriteLine("  判据：类型参数只是方法参数的类型 → 泛型方法（非泛型类）；类型参数要当字段/实现泛型接口 → 泛型类");

Console.WriteLine();
Console.WriteLine("===== 条 26: 实现泛型接口的同时实现非泛型接口 =====");
var n1 = new Name("Lovelace", "Ada"); var n2 = new Name("Lovelace", "Ada");
Console.WriteLine($"  IEquatable<Name>.Equals: {n1.Equals(n1)}；object.Equals(重写后调泛型版): {n1!.Equals((object?)n2)}");
IComparable comparable = n1;                      // 老代码拿到的是非泛型 IComparable
Console.WriteLine($"  经 IComparable 调: {comparable.CompareTo(n2)}（显式实现 → 无意中调不到，老 API 依然能用）");
Console.WriteLine("  套路：核心逻辑写泛型版；非泛型版【显式接口实现】包一层转发（防止误用+兼容旧 API）");
Console.WriteLine("  连带责任：重写 Equals 必须同时重写 GetHashCode；实现 IEquatable<T> 应配套 ==/!= 运算符");

Console.WriteLine();
Console.WriteLine("===== 条 27: 接口只放必备契约，其余交给扩展方法 =====");
var c = new Customer("Ada", 950);
var bob = new Customer("Bob", 100); var zoe = new Customer("Zoe", 1);
Console.WriteLine($"  IComparable<T> + 扩展: Ada.GreaterThan(Bob) = {c.GreaterThan(bob)}；Ada.LessThan(Zoe) = {c.LessThan(zoe)}");
Console.WriteLine("  Enumerable 对 IEnumerable<T> 的 50+ 个扩展方法就是这套哲学：接口只留 GetEnumerator，");
Console.WriteLine("  Where/Select/OrderBy 全是外挂——实现者零负担，功能还能后加");
Console.WriteLine("  注意：类里的同名实例方法优先于扩展方法（但仅当按「类的编译期类型」调用时）");

Console.WriteLine();
Console.WriteLine("===== 条 28: 用扩展方法增强「已构造的泛型类型」 =====");
var vip = new List<Customer> { new("Ada", 950), new("Linus", 880), new("Grace", 970), new("Newbie", 5) };
Console.WriteLine($"  IEnumerable<Customer>.TotalRevenue() = {vip.TotalRevenue()}");
Console.WriteLine($"  IEnumerable<Customer>.LostProspects() = [{string.Join(",", vip.LostProspects().Select(c => c.Name))}]");
Console.WriteLine("  针对封闭泛型（List<Customer>）写扩展，不用继承也不用包装——");
Console.WriteLine("  比起 CustomerList : List<Customer> 子类：扩展接受任何 IEnumerable<Customer>（含 LINQ 查询结果）");

// ---------- 类型定义 ----------

internal sealed class FastSource<T>(T[] data) : ICollection<T>
{
    public int Count => data.Length;
    public void CopyTo(T[] array, int arrayIndex) => data.CopyTo(array, arrayIndex);   // 整块拷贝
    public IEnumerator<T> GetEnumerator() => throw new InvalidOperationException("被要求逐个枚举（慢路径）！");
    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();
    bool ICollection<T>.IsReadOnly => true;
    void ICollection<T>.Add(T item) => throw new NotSupportedException();
    void ICollection<T>.Clear() => throw new NotSupportedException();
    bool ICollection<T>.Contains(T item) => ((ICollection<T>)data).Contains(item);
    bool ICollection<T>.Remove(T item) => throw new NotSupportedException();
}

internal sealed class CountingSequence<T>(IEnumerable<T> inner) : IEnumerable<T>
{
    public int Moves { get; private set; }
    public IEnumerator<T> GetEnumerator()
    {
        foreach (var x in inner) { Moves++; yield return x; }
    }
    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();
}

public sealed class Customer(string name, int revenue) : IComparable<Customer>, IComparable
{
    public string Name { get; } = name;
    public int Revenue { get; } = revenue;
    public int CompareTo(Customer? other) => string.CompareOrdinal(Name, other?.Name);
    int IComparable.CompareTo(object? obj) => CompareTo(obj as Customer ?? throw new ArgumentException(nameof(obj)));
    public static int CompareByRevenue(Customer? x, Customer? y) => (x?.Revenue ?? 0).CompareTo(y?.Revenue ?? 0);
    public static bool operator <(Customer a, Customer b) => a.CompareTo(b) < 0;
    public static bool operator >(Customer a, Customer b) => a.CompareTo(b) > 0;
}

public interface IDriver { void Work(); }

public sealed class TempFileDriver : IDriver, IDisposable
{
    public void Work() => Console.WriteLine("  [TempFileDriver] 工作中（占着临时文件）");
    public void Dispose() => Console.WriteLine("  [TempFileDriver] Dispose 被调用（引擎经 as IDisposable 释放）");
}
public sealed class PlainDriver : IDriver { public void Work() => Console.WriteLine("  [PlainDriver] 工作中（无资源要释放）"); }

public sealed class DriverEngine<T> : IDisposable where T : IDriver, new()
{
    private readonly T _driver = new();
    public void Run() => _driver.Work();
    public void Dispose() => (_driver as IDisposable)?.Dispose();
}

public abstract class CelestialBody { public double Mass { get; set; } }
public sealed class Planet : CelestialBody { }
public sealed class Asteroid : CelestialBody { }

public class Base { }
public class Derived : Base { }
public static class OverloadProbe
{
    public static void WriteMessage<T>(T obj) => Console.WriteLine("[Generic] WriteMessage<T>(T obj)");
    public static void WriteMessage(Base b) => Console.WriteLine("[Base] WriteMessage(Base b)");
    public static void WriteMessage2(Base b) => Console.WriteLine("[Base] WriteMessage(Base b) ← 显式转型后命中基类版");
}

public static class Utils
{
    public static int Max(int a, int b) => a > b ? a : b;            // 具体重载：最快
    public static double Max(double a, double b) => a > b ? a : b;
    public static T Max<T>(T a, T b) => Comparer<T>.Default.Compare(a, b) >= 0 ? a : b;
}

public sealed class Name(string last, string first) : IEquatable<Name>, IComparable<Name>, IComparable
{
    private readonly (string, string) _v = (last, first);
    public bool Equals(Name? other) => other is not null && _v == other._v;
    public override bool Equals(object? obj) => Equals(obj as Name);
    public override int GetHashCode() => _v.GetHashCode();
    public static bool operator ==(Name? a, Name? b) => a?.Equals(b) ?? b is null;
    public static bool operator !=(Name? a, Name? b) => !(a == b);
    public int CompareTo(Name? other) => other is null ? 1 : _v.CompareTo(other._v);
    int IComparable.CompareTo(object? obj) => CompareTo(obj as Name ?? throw new ArgumentException(nameof(obj)));
}

file static class ComparableExtensions
{
    public static bool GreaterThan<T>(this T left, T right) where T : IComparable<T> => left.CompareTo(right) > 0;
    public static bool LessThan<T>(this T left, T right) where T : IComparable<T> => left.CompareTo(right) < 0;
}

file static class CustomerExtensions
{
    public static int TotalRevenue(this IEnumerable<Customer> source) => source.Sum(c => c.Revenue);
    public static IEnumerable<Customer> LostProspects(this IEnumerable<Customer> source)
        => from c in source where c.Revenue < 100 select c;
}
