// 12 · 泛型：一份代码，多种类型，编译期把关
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 泛型方法：类型参数当占位符 =====");
static T Max<T>(T a, T b) where T : IComparable<T>    // 约束：T 必须可比较
    => a.CompareTo(b) >= 0 ? a : b;
Console.WriteLine($"  Max(3, 7) = {Max(3, 7)}");
Console.WriteLine($"  Max(\"apple\", \"banana\") = {Max("apple", "banana")}");
Console.WriteLine($"  Max(2.5, 1.5) = {Max(2.5, 1.5)}   ← 同一份代码，三种类型，无装箱");

Console.WriteLine();
Console.WriteLine("===== 泛型类：自己造一个 Stack<T> =====");
var stack = new LightStack<int>(4);
stack.Push(1); stack.Push(2); stack.Push(3);
Console.WriteLine($"  Pop 两次: {stack.Pop()}, {stack.Pop()}，剩余 {stack.Count} 个");

Console.WriteLine();
Console.WriteLine("===== 约束（where）家族 =====");
static void MustBeClass<T>(T item) where T : class => Console.WriteLine($"  class 约束: {item?.GetType().Name}");
static void MustBeStruct<T>(T item) where T : struct => Console.WriteLine($"  struct 约束: {item.GetType().Name}（栈上值）");
static void Newable<T>() where T : new() => Console.WriteLine($"  new() 约束: 可 new T() → {new T().GetType().Name}");
MustBeClass("字符串");
MustBeStruct(42);
Newable<DateTime>();

Console.WriteLine();
Console.WriteLine("===== 泛型 vs object：装箱账单 =====");
var list = new System.Collections.ArrayList();
var sw = System.Diagnostics.Stopwatch.StartNew();
for (var i = 0; i < 100_000; i++) list.Add(i);          // 每次装箱（int → object 堆分配）
var boxedTime = sw.ElapsedMilliseconds;
var sum = 0;
foreach (int i in list) sum += i;                        // 每次拆箱
sw.Restart();
var glist = new List<int>(100_000);
for (var i = 0; i < 100_000; i++) glist.Add(i);
sw.Stop();
Console.WriteLine($"  10 万次 Add: ArrayList {boxedTime}ms vs List<int> {sw.ElapsedMilliseconds}ms（还省下百万级分配）");

Console.WriteLine();
Console.WriteLine("===== 协变与逆变：out 与 in =====");
IEnumerable<object> objs = new List<string> { "a", "b" };   // out T：string 序列当 object 序列用
Console.WriteLine($"  协变 IEnumerable<out T>: {string.Join(",", objs)}");
Action<object> printObj = o => Console.WriteLine($"  逆变 Action<in T>: 收到 {o}");
Action<string> printStr = printObj;                         // in T：object 动作当 string 动作用
printStr("逆变成功");
Console.WriteLine("  口诀：产出用 out（协变），消费用 in（逆变）");

class LightStack<T>(int capacity)
{
    private readonly T[] _items = new T[capacity];
    private int _top;

    public int Count => _top;

    public void Push(T item) => _items[_top++] = item;

    public T Pop() => _items[--_top];
}
