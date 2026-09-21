// 18 · 迭代器与 yield：惰性序列的发动机
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== yield return：写一个就能被 foreach 的序列 =====");
foreach (var n in Countdown(3))
    Console.Write($" {n}");
Console.WriteLine("  ← Countdown 只写了「产出 3、2、1、0」，没管集合");

static IEnumerable<int> Countdown(int from)
{
    while (from >= 0)
    {
        yield return from;      // 「还回一个值，暂停在这里」
        from--;
    }
}

Console.WriteLine();
Console.WriteLine("===== 惰性：要一个算一个 =====");
var seq = Countdown(int.MaxValue);   // 没有循环爆栈：一行都没执行！
Console.WriteLine($"  定义完还没执行任何代码；取前 3 个：{string.Join(",", seq.Take(3))}");
Console.WriteLine("  Take(3) 只触发了 3 次 yield——无限序列也能安全使用");

Console.WriteLine();
Console.WriteLine("===== 无限斐波那契 =====");
static IEnumerable<long> Fibonacci()
{
    long a = 0, b = 1;
    while (true) { yield return a; (a, b) = (b, a + b); }
}
Console.WriteLine($"  前 10 项: {string.Join(", ", Fibonacci().Take(10))}");

Console.WriteLine();
Console.WriteLine("===== 执行时机的显微镜 =====");
static IEnumerable<int> Demo()
{
    Console.WriteLine("    [Demo 开始执行]");
    yield return 1;
    yield return 2;
    yield return 3;
}
var withLog = Demo().Select(x => { Console.WriteLine($"    [取到 {x}]"); return x; });
Console.WriteLine("  （定义完成，尚无输出）");
var firstTwo = withLog.Take(2).ToList();
Console.WriteLine($"  Take(2).ToList() 后共输出 {firstTwo.Count} 条日志");
Console.WriteLine("  （每个元素都是被「拉」出来的——推拉之别：迭代器是拉模型）");

Console.WriteLine();
Console.WriteLine("===== 手写 IEnumerator：yield 的背后 =====");
var range = new SimpleRange(1, 4);
foreach (var i in range) Console.Write($" {i}");
Console.WriteLine("  ← SimpleRange 用最原始的方式实现了 GetEnumerator（不用 yield，效果等价）");
Console.WriteLine("  yield return 的本质：编译器生成一个状态机类实现 IEnumerator（去 obj 里看 *.g.cs 可验证）");

Console.WriteLine();
Console.WriteLine("===== yield break：提前结束 =====");
static IEnumerable<int> UntilNegative(IEnumerable<int> source)
{
    foreach (var x in source)
    {
        if (x < 0) yield break;     // 相当于 return：终止序列
        yield return x;
    }
}
Console.WriteLine($"  遇负停: {string.Join(",", UntilNegative(new[] { 1, 2, -1, 5 }))}");

class SimpleRange(int start, int end) : IEnumerable<int>
{
    public IEnumerator<int> GetEnumerator() => new RangeEnum(start, end);
    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();

    private sealed class RangeEnum(int start, int end) : IEnumerator<int>
    {
        private int _current = start - 1;
        public int Current => _current;
        object System.Collections.IEnumerator.Current => Current;
        public bool MoveNext() => ++_current <= end;
        public void Reset() => _current = start - 1;
        public void Dispose() { }
    }
}
