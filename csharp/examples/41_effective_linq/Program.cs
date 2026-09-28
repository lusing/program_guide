// 41 · Effective C#·LINQ 惯用法（书第 4 章 条 29-44）：从迭代器设计到闭包陷阱
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 条 29: 返回序列的 API 用迭代器方法写 =====");
static IEnumerable<int> Squares(int n)
{
    Console.WriteLine($"    [Squares] 开始生成（此刻才执行）");
    for (int i = 1; i <= n; i++) yield return i * i;
}
var squares = Squares(5);                          // 定义查询——一行都不跑
Console.WriteLine("  调用 Squares(5) 后：还没执行任何生成代码（延迟到首次枚举）");
Console.WriteLine($"  首个元素: {squares.First()}（此刻才进入方法体）");
Console.WriteLine("  调用方要快照就 ToList()/ToArray()，要流式就 foreach——选择权留给调用方");
static IEnumerable<int> SquaresChecked(int n)
{
    ArgumentOutOfRangeException.ThrowIfNegative(n);   // 演示：参数检查必须放在非迭代器外壳里
    return SquaresCore(n);
    static IEnumerable<int> SquaresCore(int count) { for (int i = 1; i <= count; i++) yield return i * i; }
}
try { var _ = SquaresChecked(-1); }
catch (ArgumentOutOfRangeException) { Console.WriteLine("  注意：迭代器方法的参数检查会延迟到首次枚举才炸——用「外壳方法」立即检查"); }

Console.WriteLine();
Console.WriteLine("===== 条 30: 查询语句优先于循环（声明式 vs 命令式） =====");
var nums = new[] { 5, 2, 9, 1, 7 };
var imperative = new List<int>();
foreach (var n in nums) if (n % 2 != 0) imperative.Add(n * 10);
imperative.Sort((x, y) => y.CompareTo(x));         // 命令式：三段代码讲一件事
var declarative = from n in nums
                  where n % 2 != 0
                  orderby n descending
                  select n * 10;                   // 声明式：一句话讲完
Console.WriteLine($"  命令式: [{string.Join(",", imperative)}]   查询式: [{string.Join(",", declarative)}]");
Console.WriteLine("  查询式只描述「要什么」（过滤/排序/投影），不描述「怎么做」——读的人少翻译一层");
Console.WriteLine("  且各子句是可拼接的独立步骤，复用与组合比循环体容易");

Console.WriteLine();
Console.WriteLine("===== 条 31/33: 序列 API 要易拼接；元素用时再生成 =====");
static IEnumerable<T> Unique<T>(IEnumerable<T> source)
{
    var seen = new HashSet<T>();
    foreach (var item in source)
        if (seen.Add(item)) yield return item;     // 迭代器：拉一个处理一个
}
static IEnumerable<T> Squared<T>(IEnumerable<T> source, Func<T, T> f)
    => source.Select(f);
var pipeline = Squared(Unique(new[] { 3, 1, 3, 2, 1, 4 }), x => x * 2);
Console.WriteLine($"  Unique → Square 管道（单遍历）: [{string.Join(",", pipeline)}]");
Console.WriteLine("  两个迭代器方法串起来，源序列只走一遍、每个元素流经全流程——");
Console.WriteLine("  对比命令式：先建去重集合再建平方集合（两遍历+两个中间集合）");

Console.WriteLine();
Console.WriteLine("===== 条 32/34: 迭代逻辑与谓词/函数解耦；函数参数放松耦合 =====");
static IEnumerable<T> SampleEvery<T>(IEnumerable<T> source, int step)
{
    int i = 0;
    foreach (var item in source) { if (i++ % step == 0) yield return item; }
}
static TAcc Fold<TAcc, TSrc>(IEnumerable<TSrc> source, TAcc seed, Func<TAcc, TSrc, TAcc> folder)
{
    var acc = seed;
    foreach (var item in source) acc = folder(acc, item);
    return acc;
}
Console.WriteLine($"  每 3 个取样: [{string.Join(",", SampleEvery(nums, 3))}]（遍历逻辑与业务无关）");
var joined = Fold(nums, "", (acc, x) => acc + x);
Console.WriteLine($"  自制 Fold 求和: {Fold(nums, 0, (acc, x) => acc + x)}（等价 Aggregate）");
Console.WriteLine($"  自制 Fold 拼串: {joined} → 元素与初值类型不同也能用");
Console.WriteLine("  遍历方式（采样/过滤/跳读）与对元素做什么（函数/谓词）是两个维度——分开放");
Console.WriteLine("  少为一个方法定义接口——Func/Action/Predicate 参数就是最松的耦合");

Console.WriteLine();
Console.WriteLine("===== 条 36: 查询表达式 → 方法调用的映射 =====");
var words = new[] { "apple", "fig", "banana", "kiwi" };
var byLen =
    from w in words
    where w.Length > 3
    orderby w.Length
    select w.ToUpper();
Console.WriteLine($"  查询表达式: [{string.Join(",", byLen)}]");
var byLenMethods = words.Where(w => w.Length > 3).OrderBy(w => w.Length).Select(w => w.ToUpper());
Console.WriteLine($"  等价方法链: [{string.Join(",", byLenMethods)}]（编译器就是把前者翻译成后者）");
Console.WriteLine("  映射表: where→Where、select→Select、orderby/thenby→OrderBy/ThenBy(Descending)、");
Console.WriteLine("          多个 from→SelectMany、join→Join、join...into→GroupJoin、group...by→GroupBy");
var pairs = from a in new[] { 1, 2 } from b in new[] { 'x', 'y' } select $"{a}{b}";
Console.WriteLine($"  双 from = SelectMany（笛卡尔积）: [{string.Join(",", pairs)}]");
Console.WriteLine("  有的操作符没有查询语法（Take/Skip/First/Max...）——两套写法混用是常态");

Console.WriteLine();
Console.WriteLine("===== 条 37: 惰性求值 + 无穷序列（Take 能停，Where 停不下来） =====");
static IEnumerable<int> AllNumbers() { for (var i = 0; ; i++) yield return i; }
var firstTen = AllNumbers().Take(10).ToList();     // Take：取够就不再拉 → 无穷序列安全
Console.WriteLine($"  无穷序列 + Take(10): [{string.Join(",", firstTen)}]");
Console.WriteLine("  但 AllNumbers().Where(n => n < 10) 永远停不下来——Where 逐个判断，永远等不到尽头");
Console.WriteLine("  必须看完整个序列的操作: OrderBy/Max/Min/Aggregate/Reverse...——前面尽量先过滤:");
var products = new[] { (Name: "A", Stock: 300), (Name: "B", Stock: 50), (Name: "C", Stock: 990), (Name: "D", Stock: 80) };
var good = products.OrderBy(p => p.Name).Where(p => p.Stock > 100);   // 反例：全排序后才过滤
var good2 = products.Where(p => p.Stock > 100).OrderBy(p => p.Name);  // 正解：先过滤再排序
Console.WriteLine($"  先排序后过滤 vs 先过滤后排序，结果相同 [{string.Join(",", good2.Select(p => p.Name))}]，后者排序的数据量更小");
Console.WriteLine("  规则：把「必须看全序列」的操作（排序/聚合）尽量放到查询链尾部");

Console.WriteLine();
Console.WriteLine("===== 条 38: 复用 lambda 的正确姿势（别把谓词提取成普通方法） =====");
var employees = new[]
{
    new Employee("Ada", "S", 8000), new Employee("Bob", "H", 6500),
    new Employee("Cyd", "S", 9000), new Employee("Eve", "H", 4000),
    new Employee("Fay", "S", 5500),
};
var highPaid = from e in employees where e.MonthlySalary > 6000 && e.Classification == "S" select e;
Console.WriteLine($"  内联 lambda 过滤: [{string.Join(",", highPaid.Select(e => e.Name))}]");
var lowPaid = employees.Where(e => e.Classification == "S" && e.MonthlySalary < 6000);
Console.WriteLine("  想复用谓词时别提成「普通方法」——IQueryable 场景下方法调用进不了表达式树（无法翻译成 SQL）");
Console.WriteLine("  正解：提成返回 IEnumerable<T> 的迭代器扩展方法，整个查询步骤一起复用:");
var salaried = employees.LowPaidSalaried();
Console.WriteLine($"  LowPaidSalaried() 扩展: [{string.Join(",", salaried.Select(e => e.Name))}]（步骤级复用，兼容两种 LINQ）");

Console.WriteLine();
Console.WriteLine("===== 条 39: 别在 Func/Action 里抛异常（强异常保证的前哨） =====");
var staff = employees.Select(e => e with { MonthlySalary = e.MonthlySalary * 11 / 10 }).ToArray();  // 新序列，不动源
Console.WriteLine($"  「返回新序列」式加薪 10%: {string.Join(",", staff.Select(e => $"{e.Name}:{e.MonthlySalary}"))}——源数组原样");
try
{
    foreach (var e in employees.Select(x => x with { MonthlySalary = x.MonthlySalary == 6500 ? throw new InvalidOperationException("薪资数据异常") : x.MonthlySalary * 11 / 10 }))
        _ = e;
}
catch (InvalidOperationException) { Console.WriteLine("  原地修改式（foreach 里改属性）一旦中途炸：一半改了一半没改——状态损坏"); }
Console.WriteLine("  两种改法: ①保证 lambda 绝不抛（先验证）②拷贝-处理-替换（宁可多分配）");

Console.WriteLine();
Console.WriteLine("===== 条 40: 尽早执行 vs 延迟执行——副作用是分水岭 =====");
int counter = 0;
Func<int> next = () => ++counter;
var eagerValue = next();                            // 命令式：立刻算
var lazyValue = new Lazy<int>(next);                // 声明式：用的时候算
Console.WriteLine($"  立即执行: {eagerValue}（此时 counter={counter}）；延迟: IsValueCreated={lazyValue.IsValueCreated}");
var v = lazyValue.Value;
Console.WriteLine($"  触碰延迟值: {v}（counter={counter}）——无副作用时两者等价，有副作用时行为随时机变");
Console.WriteLine("  判据：方法有副作用（IO/全局态/时间）→ 执行时机影响结果 → 想清楚要快照还是要逻辑");

Console.WriteLine();
Console.WriteLine("===== 条 41: 别把昂贵的资源捕获进闭包 =====");
var leaked = ClosureDemo.QueryThatCapturesHog();
Console.WriteLine("  迭代前: 资源已被闭包拖住（ResourceHog 尚未 Dispose）");
foreach (var _ in leaked.Take(2)) { }
Console.WriteLine("  只取了 2 个元素，但整个序列的委托持着 ResourceHog——它活到「序列不再被引用」为止");
var clean = ClosureDemo.QueryThatOwnsHog();
foreach (var _ in clean.Take(2)) { }
Console.WriteLine("  正解：把昂贵资源的开+关封在迭代器方法内部（谁拥有谁释放），每轮枚举一个生命周期");

Console.WriteLine();
Console.WriteLine("===== 条 42: IEnumerable 与 IQueryable 的分界（回顾 17 章） =====");
Console.WriteLine("  IEnumerable<T> → lambda 编译成委托，本地逐个执行（LINQ to Objects）");
Console.WriteLine("  IQueryable<T>  → lambda 变成表达式树，provider 翻译后远程执行（数据库）");
Console.WriteLine("  变量类型写错会静默降级: IQueryable<string> q 声明成 IEnumerable<string> → 后续 Where 走本地版把数据全拉回来");
Console.WriteLine("  经验: 接到 IQueryable 就保持 IQueryable（var 让编译器选对的）；确实要本地执行才 AsEnumerable()");

Console.WriteLine();
Console.WriteLine("===== 条 43: Single/First 把「假设」写进代码 =====");
var goalMakers = new[] { ("Ada", 8), ("Bob", 3), ("Cyd", 5), ("Eve", 3) };
var top = goalMakers.OrderByDescending(g => g.Item2).First();
Console.WriteLine($"  First: 最佳射手 {top.Item1}（至少一人——否则抛 InvalidOperationException）");
var maybeTop = goalMakers.OrderByDescending(g => g.Item2).FirstOrDefault();
var emptyFirst = Array.Empty<(string, int)>().OrderByDescending(g => g.Item2).FirstOrDefault();
Console.WriteLine($"  FirstOrDefault: 有值时={maybeTop.Item1}；空表时 Item1=\"{emptyFirst.Item1}\"（string 的 default 是 null，不炸）");
var third = goalMakers.OrderByDescending(g => g.Item2).Skip(2).First();
Console.WriteLine($"  Skip(2).First(): 第三射手 {third.Item1}");
try { var _ = goalMakers.Single(g => g.Item2 == 3); }
catch (InvalidOperationException) { Console.WriteLine("  Single：恰好匹配 Bob 和 Eve 两人 → 抛异常（假设「有且仅有一个」被当场验证）"); }
Console.WriteLine("  语义速记: Single=有且仅有一个 / SingleOrDefault=零或一 / First=至少一个取首个——用对方法=把假设写成可执行的断言");

Console.WriteLine();
Console.WriteLine("===== 条 44: 不要修改「绑定变量」 =====");
int index = 20;
var seq = from n in Enumerable.Range(0, 5) select n + index;    // 闭包捕获 index（嵌套类字段化）
Console.WriteLine($"  定义后、枚举前改 index=100");
index = 100;
Console.WriteLine($"  枚举结果: [{string.Join(",", seq)}] ← 用的是新值 100，不是定义时的 20");
Console.WriteLine("  原理: 捕获的变量被提升为编译器生成嵌套类的字段——闭包内外看到同一个存储位置");
Console.WriteLine("  推论: 定义查询后又改捕获变量 = 隐式改写查询本身。要么别改，要么定义前拷贝一份 var start = index;");

Console.WriteLine();
Console.WriteLine("===== 本章小结：LINQ 的设计观 =====");
Console.WriteLine("  API 层: 返回 IEnumerable（迭代器）、参数收 Func（松耦合）、步骤拼管道（单遍历）");
Console.WriteLine("  执行层: 默认惰性、Where/OrderBy 认清全序列代价、快照才 ToList");
Console.WriteLine("  安全层: lambda 不抛异常、闭包不捕获昂贵资源、绑定变量只读");

public sealed record Employee(string Name, string Classification, int MonthlySalary);

file static class EmployeeExtensions
{
    public static IEnumerable<Employee> LowPaidSalaried(this IEnumerable<Employee> source) =>
        from e in source where e.Classification == "S" && e.MonthlySalary < 6000 select e;
}

file sealed class ResourceHog : IDisposable
{
    public ResourceHog() => Console.WriteLine("    [ResourceHog] 构造（昂贵资源）");
    public void Dispose() => Console.WriteLine("    [ResourceHog] Dispose");
}

file static class ClosureDemo
{
    public static IEnumerable<int> QueryThatCapturesHog()
    {
        var hog = new ResourceHog();                    // 被下面 lambda 捕获 → 活到序列死
        return Enumerable.Range(0, 10).Select(n => { _ = hog; return n; });
    }
    public static IEnumerable<int> QueryThatOwnsHog()
    {
        using var hog = new ResourceHog();              // 资源生命周期 = 单次枚举
        foreach (var n in Enumerable.Range(0, 10)) yield return n;
    }
}
