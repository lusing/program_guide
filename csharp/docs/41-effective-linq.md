# 41 · Effective C#·LINQ 惯用法（条 29-44）

> 对应示例：`examples/41_effective_linq`

> **本章你将学会**：把序列 API 设计成「可拼接的单遍历管道」、查询表达式与方法调用的映射表、惰性求值与无穷序列的边界操作符、lambda 复用的正确姿势、闭包捕获昂贵资源的生命周期问题、Single/First 把假设写成断言、绑定变量的修改陷阱。
> **前置章节**：[16 LINQ 基础](16-linq-basics.md)、[17 LINQ 进阶](17-linq-advanced.md)、[15 Lambda 与闭包](15-lambdas.md)、[18 迭代器](18-iterators.md)。

16/17 章教了 LINQ 的用法（操作符、延迟执行、IQueryable 分界）；本章是《Effective C#》第 4 章的**设计视角**——不只「会用查询」，还知道**怎么设计自己的序列 API**、**惰性求值在什么情况下咬人**。

## 1. 条 29：返回序列的 API 用迭代器方法写

```csharp
static IEnumerable<int> Squares(int n)
{
    Console.WriteLine("开始生成");          // 这行要到首次枚举才执行（实测）
    for (int i = 1; i <= n; i++) yield return i * i;
}
var squares = Squares(5);        // 调用后：一行生成代码都没跑
var first = squares.First();     // 此刻才进入方法体
```

迭代器方法把选择权交给调用方：要快照 `ToList()/ToArray()`，要流式 `foreach`——直接返回 `List<T>` 的 API 做不到后者。

**一个必踩的坑**：迭代器方法的参数检查会**延迟到首次枚举**才炸（编译器把整个方法体搬进状态机）。修法是「外壳 + 核心」两层：

```csharp
static IEnumerable<int> SquaresChecked(int n)
{
    ArgumentOutOfRangeException.ThrowIfNegative(n);   // 外壳：普通方法，立即检查
    return SquaresCore(n);
    static IEnumerable<int> SquaresCore(int count) { for (...) yield return ...; }
}
```

## 2. 条 30：查询语句优先于循环

同一个任务（取奇数×10 按降序）：

```csharp
// 命令式：三段代码讲一件事
var result = new List<int>();
foreach (var n in nums) if (n % 2 != 0) result.Add(n * 10);
result.Sort((x, y) => y.CompareTo(x));

// 声明式：一句话
var result2 = from n in nums where n % 2 != 0 orderby n descending select n * 10;
```

查询式只描述「要什么」（过滤/排序/投影），循环式描述「怎么做」（读者自己脑内翻译）。更重要的是**可组合性**：查询的每个子句是独立步骤，能拼、能复用；循环体是一整块。命令式循环几乎总有一个查询式的对应写法——先想查询，不行再写循环。

## 3. 条 31/33：拼管道，元素用时再生成

```csharp
static IEnumerable<T> Unique<T>(IEnumerable<T> source)
{
    var seen = new HashSet<T>();
    foreach (var item in source)
        if (seen.Add(item)) yield return item;
}
var pipeline = someSeq.Unique().Select(x => x * 2);
```

两个迭代器方法串起来，**源序列只走一遍**、每个元素依次流经全部环节——像弹珠沿轨道下滑，前面的珠子先过障碍。对比命令式（先建去重集合、再建平方集合）：两遍历 + 两个中间集合。这是「序列进、序列出」方法的设计范式：参数 `IEnumerable<T>`、返回 `IEnumerable<T>`、内部 `yield return`。

## 4. 条 32/34：迭代逻辑与「做什么」解耦；函数参数放松耦合

「怎么遍历」（采样/过滤/跳读）与「对元素做什么」是两个维度，分开：

```csharp
static IEnumerable<T> SampleEvery<T>(IEnumerable<T> source, int step) { ... }   // 遍历逻辑
static TAcc Fold<TAcc, TSrc>(IEnumerable<TSrc> src, TAcc seed, Func<TAcc, TSrc, TAcc> f) { ... }
```

`Fold` 就是 `Aggregate` 的自制版——**函数参数（Func/Action/Predicate）是最松的耦合**：不为一个方法定义接口、不逼调用方建类，一个 lambda 即实现。「接口还是委托」的判据：该能力是**类型的固有承诺**（IComparable/IEquatable）→ 接口；只是**本次算法要的一个函数** → 委托。

## 5. 条 36：查询表达式 → 方法调用的映射

编译器把查询表达式翻译成方法调用，映射表：

| 查询子句 | 方法 |
|---|---|
| `where` | `Where` |
| `select` | `Select` |
| `orderby` / `thenby`（+ `descending`） | `OrderBy` / `ThenBy`（`Descending`） |
| 多个 `from` | `SelectMany` |
| `join` | `Join` |
| `join ... into` | `GroupJoin` |
| `group ... by` | `GroupBy` |

两个实测细节：`select` 直接选范围变量时会被**优化掉**（退化 select）；双 `from` 生成笛卡尔积（`[1x,1y,2x,2y]`）。**Take/Skip/First/Max 等没有查询语法**——两套写法混用是常态，团队里统一风格即可。两套参考实现在 `Enumerable`（IEnumerable 版，委托）与 `Queryable`（IQueryable 版，表达式树）。

## 6. 条 37：惰性求值 + 无穷序列的「边界操作符」

```csharp
static IEnumerable<int> AllNumbers() { for (var i = 0; ; i++) yield return i; }
AllNumbers().Take(10);           // ✓ Take 是边界：取够就不再拉
AllNumbers().Where(n => n < 10); // ✘ 死循环：Where 逐个判断，永远等不到尽头
```

**必须看完整个序列**的操作符：`OrderBy`（要全量才能排）、`Max/Min`、`Aggregate`、`Reverse`、`GroupBy`——无穷序列上全是死循环。有限序列上它们也最贵，所以**把「看全序列」的操作尽量放查询链尾部**：

```csharp
products.OrderBy(p => p.Name).Where(p => p.Stock > 100);  // 全量排序后才过滤
products.Where(p => p.Stock > 100).OrderBy(p => p.Name);  // ✓ 先过滤，排序量变小
```

需要快照（多次使用、数据要冻结）才 `ToList()/ToArray()`。

## 7. 条 38：复用 lambda 的正确姿势

想复用「过滤低薪正编」的谓词，**别提成普通方法**：

```csharp
// ✘ 普通方法：IQueryable 场景下 e.LowPaid(e) 这种方法调用进不了表达式树（翻译不成 SQL）
bool LowPaid(Employee e) => e.Classification == "S" && e.MonthlySalary < 6000;

// ✓ 迭代器扩展方法：整个查询步骤一起复用，IEnumerable/IQueryable 通吃
public static IEnumerable<Employee> LowPaidSalaried(this IEnumerable<Employee> source) =>
    from e in source where e.Classification == "S" && e.MonthlySalary < 6000 select e;
```

原理：LINQ to Objects 把 lambda 编译成**委托**（方法调用无所谓）；LINQ to SQL/EF 把 lambda 变成**表达式树**再翻译——表达式树里只能有已知的运算符/成员，你自己的方法调用翻译不了就抛异常。所以复用单位是「查询步骤」（返回序列的方法），不是「谓词片段」。

## 8. 条 39：别在 Func/Action 里抛异常

```csharp
foreach (var e in employees.Select(x => x with { Salary = x.Salary * 11 / 10 }))  // ✓ 返回新序列
// vs
foreach (var e in employees) e.Salary *= 1.1;                                     // ✘ 原地修改
```

原地修改版在第 N 个元素抛异常时：前 N-1 个已改、后面的没改——**半个状态，无法回滚**（你不知道处理到哪）。两种修法：①让 lambda 绝不抛（先验证后操作，能跳过的跳过）；②**拷贝-处理-替换**（Select 返回新序列，全部成功才替换原引用）——多花分配，买强异常保证（详见 [42 章条 48](42-effective-exceptions.md)）。

## 9. 条 40：尽早执行 vs 延迟执行——副作用是分水岭

```csharp
DoStuff(Method1(), Method2(), Method3());                    // 命令式：三个方法立刻执行
DoStuff(() => Method1(), () => Method2(), () => Method3());  // 声明式：用到才执行
```

传递**数据**（结果）还是传递**算法**（委托/查询）？判据：

- **有副作用**（IO/全局态/读时钟）：执行时机影响结果——想要快照就及早求值，想要「最新值」才延迟
- **无副作用且不可变**：两者等价，按性能选（数据小传数据，数据大且不全用传算法）
- 混合策略：缓存过的值直接返回，未缓制的现算

示例实测：`Lazy<int>` 触碰前 `IsValueCreated=False`，`counter` 不动；触碰后才 +1——「同一份代码，行为随时机变」的微缩演示。

## 10. 条 41：别把昂贵的资源捕获进闭包

```csharp
IEnumerable<int> QueryThatCapturesHog()
{
    var hog = new ResourceHog();                     // 昂贵资源
    return Enumerable.Range(0, 10).Select(n => { _ = hog; return n; });  // 闭包捕获！
}
// 迭代前：hog 活着（被返回的委托链持有）
// 只取 2 个元素：hog 还是活着——活到「序列不再被引用」为止
```

捕获变量的生命周期 = 委托的生命周期（[15 章](15-lambdas.md)的闭包提升机制）。示例实测两种写法的 Dispose 时机：捕获版**从未释放**；正解版在**单次枚举结束（含 Take 提前退出）时立刻释放**：

```csharp
IEnumerable<int> QueryThatOwnsHog()
{
    using var hog = new ResourceHog();               // 资源生命周期 = 单次枚举
    foreach (var n in Enumerable.Range(0, 10)) yield return n;
}
```

更隐蔽的变体：方法里有多个 lambda 时，**编译器会把同一作用域的所有闭包合并进一个嵌套类**——你以为只返回了「不碰昂贵资源的那个查询」，实际它也拖着别人的资源。修法：把昂贵资源的计算拆成独立方法（各自作用域各自闭包）。

## 11. 条 42：IEnumerable vs IQueryable（衔接 17 章）

17 章讲过机制分界；Effective 条 1/42 的补充是**变量声明的静默降级**：`IQueryable<string> q` 若声明成 `IEnumerable<string>`，后续 Where 从数据库侧执行降级成本地执行——数据全拉回来过滤，编译器一声不吭。经验：**接到 IQueryable 保持 IQueryable（用 var），确实要本地执行才显式 AsEnumerable()**；一个方法要同时服务两种序列时用 `AsQueryable()` 归一。

## 12. 条 43：Single / First 把假设写成可执行的断言

| 方法 | 语义 | 空序列 | 多个匹配 |
|---|---|---|---|
| `Single` | 有且仅有一个 | 抛 | **抛** |
| `SingleOrDefault` | 零或一 | default | **抛** |
| `First` | 至少一个，取首个 | 抛 | 取首个 |
| `FirstOrDefault` | 可能为空，取首个 | default | 取首个 |

示例实测：射手榜 `Single(g => g.Score == 3)` 恰好匹配两人 → 当场抛 InvalidOperationException。**用对方法 = 把「我认为结果长什么样」写成机器可验证的断言**——假设错了立刻炸在离错误最近的地方，而不是让错误数据流到下游。找特定位置用 `Skip(n).First()`（强调要的是元素不是序列）。

## 13. 条 44：不要修改绑定变量

```csharp
int index = 20;
var seq = from n in Enumerable.Range(0, 5) select n + index;   // 闭包捕获
index = 100;                                                   // 定义后、枚举前修改
foreach (var x in seq) ...                                     // 100,101,102,103,104 ！
```

实测输出用的是**新值 100**——捕获变量被提升为嵌套类字段（[15 章](15-lambdas.md)第 3 节的机制），闭包内外看到**同一个存储位置**，「定义查询时的值」这个直觉是错的。推论：定义查询后修改被捕获的变量 = 隐式改写查询本身。规则：**绑定变量只读**；确实要快照语义就先拷贝 `var start = index;` 再捕获 `start`。

## 常见坑

**迭代器方法的参数校验延迟爆炸**：调用点不炸、枚举点才炸——外壳方法立即检查（条 29）。

**无穷序列接 Where/OrderBy/Max**：死循环——只能接 Take/TakeWhile/First 这类边界操作符（条 37）。

**谓词提成普通方法想跨 LINQ 复用**：IQueryable 翻译不了方法调用——提成返回序列的迭代器扩展（条 38）。

**查询结果存进 IEnumerable 变量**：IQueryable 静默降级本地执行（条 42）。

**定义查询后改捕获变量**：结果用的是新值（条 44 实测），快照语义先拷贝。

**闭包里捕获 IDisposable/大对象**：生命周期被拖长到序列死亡（条 41），资源开闭封在迭代器内部。

## 实战建议

- 自己写序列 API 的公式：外壳校验 + 迭代器核心 + `IEnumerable<T>` 进出
- 查询链排序：能过滤的先过滤，「看全序列」的操作（排序/聚合/分组）放尾部
- 复用查询逻辑以「步骤」为单位（返回序列的扩展方法），同时服务两种 LINQ
- 需要快照语义（冻结数据供多次使用）显式 ToList，并让读者看到这行是有意的
- 捕获变量在定义查询之后视为只读；昂贵资源永远不进闭包

## 自测

1. **迭代器方法为什么要「外壳 + 核心」两层写？** —— 参数校验必须在调用点立即执行，而迭代器方法体延迟到首次枚举。
2. **哪些操作符在无穷序列上安全？** —— Take/TakeWhile/First 等「到边界即停」的；Where/OrderBy/Max 会看全序列 → 死循环。
3. **复用 lambda 为什么提成「返回序列的方法」而不是普通谓词方法？** —— IQueryable 把 lambda 变表达式树，自定义方法调用翻译不了；序列方法两个世界通吃。
4. **闭包捕获昂贵资源的后果与修法？** —— 生命周期拖到委托死亡；把资源的开闭封进迭代器方法内部（每次枚举一个生命周期）。
5. **Single 与 First 的语义差？** —— Single 把「有且仅有一个」写成断言（多了少了都抛）；First 只要求至少一个。

---
上一章：[40 Effective C#·泛型设计](40-effective-generics.md) ｜ 下一章：[42 Effective C#·异常设计](42-effective-exceptions.md) ｜ 返回：[README](../README.md)
