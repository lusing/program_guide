# 40 · Effective C#·泛型设计（条 18-28）

> 对应示例：`examples/40_effective_generics`

> **本章你将学会**：约束的「刚好够用」原则、运行期类型检查做算法特化、IComparable/IComparer 的完整礼仪、泛型类对 IDisposable 类型参数的义务、协变逆变的设计用法、委托当约束、泛型方法 vs 泛型类、泛型接口配非泛型接口、接口最小化与扩展已构造类型。
> **前置章节**：[12 泛型](12-generics.md)、[10 接口](10-interfaces.md)、[20 扩展方法](20-extensions-operators.md)。

第 12 章教了泛型的机制（约束家族、协变逆变的概念）；本章讲《Effective C#》第 3 章的**设计层**问题：约束给多少、算法怎么特化、类型参数放在类上还是方法上、接口怎么定义才既好实现又好用。

## 1. 条 18：只定义刚好够用的约束

无约束的 T 只能当 object 用（运行期检查+强转满天飞）；约束太多又把用户挡在门外。**两头都是坑，找折中**：

```csharp
static bool AreEqualConstrained<T>(T left, T right) where T : IEquatable<T>
    => left.Equals(right);               // 有约束：强类型 Equals

static bool AreEqualFlexible<T>(T left, T right)      // 无约束：运行期探测
    => left is IEquatable<T> eq ? eq.Equals(right) : left!.Equals(right);
```

第二种写法体现一个重要模式：**「用得上就优化，用不上就回落」**——类型参数实现了 IEquatable\<T\> 就走强类型版，否则回落到 object.Equals。对库作者，这比强制约束友好。判据：**删掉这条约束代码还能写吗？**（能写但变丑 → 考虑探测回落；根本写不了 → 留下）。

new/struct/class 这三个约束尤其要三思：很多 `new T()` 的需求其实 `default(T)` 就够（找第一个满足谓词的元素，找不到返回默认值——不需要构造）。

## 2. 条 19：运行期类型检查实现「特定类型的特化算法」

泛型越通用，越用不上具体类型的优势。C# 允许在泛型代码里**探测运行期能力，走更快路径**——书的 ReverseEnumerable 例子，示例 40 用探针复现：

```csharp
static List<T> Materialize<T>(IEnumerable<T> source) =>
    source is ICollection<T> col ? new List<T>(col)      // 特化：整块 CopyTo
                                 : source.ToList();      // 退化：逐个枚举
```

实测：给一个「GetEnumerator 直接抛异常」的 ICollection 探针源，特化路径**成功灌入且从未逐个枚举**；给普通惰性序列则逐个枚举 5 个元素。BCL 里 `Enumerable.Reverse`/`ToList` 对 `IList<T>`/`ICollection<T>` 的探测就是这套。关键点：**探测看的是运行期类型**（参数可能声明为 IEnumerable 却实际实现 ICollection），所以不能只加一个 IList 重载了事——要在外壳方法里 `is` 判断。连 string 都值得特化（它支持随机访问却不实现 IList\<char\>——书的 ReverseStringEnumerator 例子）。

## 3. 条 20：IComparable\<T\> 与 IComparer\<T\> 定义顺序关系

一个类型要进排序/二分/有序集合，就得定义顺序。完整礼仪（示例实测每一条）：

```csharp
public sealed class Customer(string name, int revenue)
    : IComparable<Customer>, IComparable
{
    public int CompareTo(Customer? other) => string.CompareOrdinal(Name, other?.Name);  // ① 自然顺序
    int IComparable.CompareTo(object? obj) => CompareTo(obj as Customer ?? throw ...); // ② 非泛型版【显式实现】
    public static int CompareByRevenue(Customer? x, Customer? y) => ...;               // ③ 备选顺序
    public static bool operator <(Customer a, Customer b) => a.CompareTo(b) < 0;       // ④ 运算符
    public static bool operator >(Customer a, Customer b) => a.CompareTo(b) > 0;
}
```

- **① 自然顺序**（按 Name）给 `Sort()` 用；**③ 备选顺序**用静态比较器暴露（按营收）——不用每个调用点写 lambda
- **② 非泛型 IComparable 显式实现**：老代码兼容；显式实现意味着「无意中调不到」，必须经 IComparable 引用才走它——把误用挡在编译期
- **④ 运算符**内部调 CompareTo，保证 `<` 与 Sort 的顺序一致
- **CompareTo 返回 0 ≠ Equals 为 true**——顺序与相等是两个独立概念（示例实测 `X.CompareTo(Y) == -1` 而 `Equals == false`），IEquatable\<T\> 对 T **不变**（Planet 不等于 Moon，协变没有意义）

## 4. 条 21：泛型类要照顾实现了 IDisposable 的类型参数

约束表达不了「T 可能有 Dispose 也可能没有」。凡是用 `T` 创建了实例的泛型代码，都要处理这种可能：

```csharp
// 局部变量场景：as 后 using（null 也安全）
using (driver as IDisposable)
{
    driver.Work();
}

// 成员字段场景：泛型类自己实现 IDisposable
public sealed class DriverEngine<T> : IDisposable where T : IDriver, new()
{
    private readonly T _driver = new();
    public void Dispose() => (_driver as IDisposable)?.Dispose();
}
```

示例实测两种 T（实现/未实现 IDisposable）都正确工作。漏掉这段的后果：T 带非托管资源时悄悄泄漏——用户不会怪自己传的 T，会怪你的类。

## 5. 条 22：考虑支持协变与逆变

第 12 章讲了 out/in 的机制；这条讲**设计责任**：定义泛型接口和委托时尽量标注 in/out，让编译器替你把类型系统的洞挡住。

两个实测警示：

```csharp
CelestialBody[] arr = new Planet[3];       // 数组协变（历史遗留）
arr[0] = new Asteroid();                    // 编译通过！运行时 ArrayTypeMismatchException

IComparer<CelestialBody> byMass = Comparer<CelestialBody>.Create(...);
planets.Sort(byMass);                       // 逆变：比 CelestialBody 的比较器用
                                            // 在要 IComparer<Planet> 的地方 ✓
```

数组协变是 .NET 1.x 的遗产——写入错误**运行时**才炸，这是「协变不安全」的活教材；泛型的 out/in 标注则让这类错误**编译期**就被抓住。IEquatable\<T\> 故意不变（相等必须同类型）；委托的变体规则：只进的方法参数用 in、只出的返回值用 out（`Func<in T, out TResult>`）。

## 6. 条 23：用委托要求类型参数「提供某种方法」

C# 约束表达不了「有 + 运算符 / 有某静态方法 / 有带参构造」。书的答案：**把方法签名写成委托参数**：

```csharp
static T AddVia<T>(T a, T b, Func<T, T, T> add) => add(a, b);
AddVia(3, 4, (a, b) => a + b);        // 调用方一个 lambda 搞定
```

对比「定义 IAdd\<T\> 接口 + 调用方实现接口 + 指定封闭类型」三步走，委托方案调用方只写一行 lambda。BCL 的 `Zip(first, second, (a, b) => ...)`、`Fold/Aggregate`、第 41 章的整个函数参数家族都是这个思路。**判据**：这个「要求」是不是类型的固有承诺（IComparable 是 → 接口），还是只是本次算法需要的一个函数（→ 委托）。

## 7. 条 24：有泛型方法，就别造针对基类/接口的重载

重载解析的冷知识（示例实测）：

```csharp
static void WriteMessage<T>(T obj);     // 泛型版
static void WriteMessage(Base b);       // 基类版
WriteMessage(new Derived());            // 打印 [Generic]！
((Base)new Derived()).WriteMessage2();  // 显式转型才命中基类版
```

**泛型方法总能精确匹配**（T = Derived），优于「要向上转型」的基类版/接口版——你以为给基类加的便捷重载，实际永远调不到。数值类型例外（int/double 间无继承关系），所以 `Enumerable.Max` 有 int/double/... 一串具体重载是对的；类体系内别这么干。真要为「功能更强的参数」优化，用第 2 节的运行期探测，不是重载。

## 8. 条 25：泛型方法优先于泛型类

工具类别整个泛型化：

```csharp
public static class Utils          // 非泛型类 + 泛型方法 + 具体重载
{
    public static int Max(int a, int b) => a > b ? a : b;          // 最快
    public static double Max(double a, double b) => ...;
    public static T Max<T>(T a, T b) => Comparer<T>.Default...;    // 兜底
}
Utils.Max(3, 9);                   // 不用写类型参数——推断 + 命中具体重载
```

泛型类 `Utils<T>` 的三宗罪：每次调用都写类型参数；类型参数要满足**整个类**的所有约束；以后加针对某类型的优化版，已按 `Utils<T>` 用起来的调用方切不过去。

**判据一句话**：类型参数只出现在方法签名里 → 泛型方法（非泛型类）；类型参数要当字段类型 / 类要实现泛型接口（集合就是典型）→ 泛型类。

## 9. 条 26：实现泛型接口的同时实现非泛型接口

和第 3 节的 IComparable 同理，以 IEquatable 为例的完整礼仪：

- 核心逻辑写泛型版 `Equals(Name? other)`
- `override Equals(object?)` 转发到泛型版（否则老 API 走 object 引用比较得到错答案）
- 重写 Equals 就必须重写 `GetHashCode`（第 08 章的合同）
- 实现 IEquatable\<T\> 应配套 `==`/`!=` 运算符
- 非泛型版一律**显式接口实现**——正常调用解析到泛型版，只有拿旧接口引用时才走非泛型版

## 10. 条 27/28：接口最小化 + 扩展已构造类型

**条 27**：接口只放必备契约，便捷方法全用扩展方法补——`IEnumerable<T>` 只有 GetEnumerator，Where/Select/OrderBy 是 Enumerable 类的 50+ 个外挂。自己也这么干：

```csharp
public static bool GreaterThan<T>(this T left, T right) where T : IComparable<T>
    => left.CompareTo(right) > 0;        // IComparable<T> 立刻「多了」GreaterThan/LessThan
```

注意优先级规则：类自己的同名方法优先于扩展方法，但**只在按类的编译期类型调用时**成立——按接口引用调用走的仍是扩展版。所以「类重写扩展方法的逻辑」必须与扩展行为一致，否则同一个对象两种调法两种行为。

**条 28**：针对**已构造的泛型类型**写扩展，代替继承：

```csharp
public static int TotalRevenue(this IEnumerable<Customer> source) => source.Sum(c => c.Revenue);
```

比起 `CustomerList : List<Customer>` 子类：扩展接受**任何** IEnumerable\<Customer\>（含 LINQ 查询结果），不动存储模型。`Enumerable` 对 `IEnumerable<int>` 的 Sum/Average 特化重载就是官方示范。

## 常见坑

**给基类/接口写与泛型方法同签名的重载**：永远被泛型版抢占（条 24 实测），删掉或改成运行期探测。

**泛型工具类 `Utils<T>`**：调用方被迫处处写类型参数（条 25），改非泛型类 + 泛型方法。

**值类型 T 忘了 `is` 探测的 as 检查**：`as` 需要可空目标；探测用 `is` 模式。

**实现了 IEquatable\<T\> 却不重写 object.Equals/GetHashCode/==**：老代码按 object 引用比较拿到错答案（条 26 完整礼仪清单）。

**类里同名方法与扩展方法行为不一致**：按类调 vs 按接口调产生两种行为（条 27 尾注）。

## 实战建议

- 每写一条约束自问「删了它代码写不出来吗」；能用「探测 + 回落」就不要强制
- 泛型算法优先做运行期能力探测（is ICollection/is IList），收益立竿见影且不增加调用方负担
- 顺序关系四件套一起上：IComparable\<T\> + 显式 IComparable + 静态备选比较器 + 运算符
- 用 T 创建实例的泛型类，Dispose 里 `(_driver as IDisposable)?.Dispose()` 是标配
- 接口设计完问一遍：哪些成员能用「基础成员 + 扩展方法」推出来？能推出来的删掉

## 自测

1. **「刚好够用」的约束怎么判断？** —— 删掉后写不出（编译不过）→ 留；能写但丑 → 考虑运行期探测回落。
2. **为什么泛型方法会抢基类重载？** —— 泛型参数可精确匹配（T=Derived），基类版需要向上转型，精确匹配优先。
3. **泛型方法 vs 泛型类的判据？** —— 类型参数是否要做字段类型/是否要实现泛型接口；否则泛型方法。
4. **实现 IEquatable\<T\> 的连带责任？** —— 重写 Equals/GetHashCode、配 ==/!=、（兼容场景）非泛型接口显式实现。
5. **数组协变为什么危险？** —— 写入不匹配元素编译期不报、运行时 ArrayTypeMismatchException；泛型 out/in 标注把同类错误提前到编译期。

---
上一章：[39 Effective C#·初始化与生命周期](39-effective-lifecycle.md) ｜ 下一章：[41 Effective C#·LINQ 惯用法](41-effective-linq.md) ｜ 返回：[README](../README.md)
