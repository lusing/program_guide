# 12 · 泛型

> 对应示例：`examples/12_generics`

> **本章你将学会**：泛型方法与泛型类、约束家族、泛型 vs object 的性能账、协变与逆变。
> **前置章节**：[05 装箱](05-value-reference.md)、[10 IComparable](10-interfaces.md)。

## 1. 泛型解决什么问题

不泛型的世界只有两条路写"通用 Max"：

```csharp
// 路 1：为每个类型写一份——int/string/double……重复到天荒地老
// 路 2：参数用 object——装箱（第 05 章实测慢一个数量级）+ 处处强转 + 运行时才知道类型对不对
static object Max(object a, object b) => ((IComparable)a).CompareTo(b) >= 0 ? a : b;
```

泛型是第三条路：**类型作参数，编译器按需生成强类型版本**：

```csharp
static T Max<T>(T a, T b) where T : IComparable<T>
    => a.CompareTo(b) >= 0 ? a : b;

Max(3, 7)                       // T = int：直接比，零装箱
Max("apple", "banana")          // T = string
Max(2.5, 1.5)                   // T = double——同一份代码
```

`T` 是**类型参数**，调用时用实参类型"填空"。JIT 为每个值类型 T 生成独立机器码（int 版/string 版各一份），引用类型共享一份——**强类型 + 零装箱 + 零重复代码**三全其美。

## 2. 约束（where）：给 T 划底线

没有约束的 T 只能当 object 用。约束声明"T 必须具备什么"：

```csharp
static T Max<T>(T a, T b) where T : IComparable<T>    // 必须可比较
class Repo<T> where T : class, new()                  // 引用类型 + 有无参构造
```

约束家族速查：

| 约束 | 含义 | 换来的能力 |
|---|---|---|
| `where T : IComparable<T>` | 实现某接口 | 能调接口成员 |
| `where T : BaseClass` | 是某类或其子类 | 能用基类成员 |
| `where T : class` | 引用类型 | 可比 null |
| `where T : struct` | 值类型 | 栈语义/不可 null |
| `where T : new()` | 有公共无参构造 | 能 `new T()` |
| `where T : notnull` | 非可空 | 配合 NRT（第 21 章） |
| `where T2 : T1` | 与另一参数相关 | 类型间的依赖 |

约束是**给编译器的证据**——有了 `IComparable<T>` 证据，`a.CompareTo(b)` 才编译通过；也是**给调用者的合同**。泛型类（如示例的 LightStack）与泛型方法、泛型接口（`IEnumerable<T>`）三处都能用约束。

## 3. 泛型 vs object：装箱账单（实测）

示例跑的对比实验：

```csharp
var list = new ArrayList();                  // 非泛型：int → object 装箱
for (var i = 0; i < 100_000; i++) list.Add(i);

var glist = new List<int>(100_000);          // 泛型：裸 int 存储
for (var i = 0; i < 100_000; i++) glist.Add(i);
```

ArrayList 慢一个数量级且产生 **10 万个堆对象**（GC 压力）；List<int> 零装箱、连续内存、CPU 缓存友好。2005 年 C# 2.0 泛型登场后，`ArrayList/Hashtable` 全线退役——新代码**禁止**使用非泛型集合。

## 4. BCL 泛型集合选型

| 集合 | 语义 | 典型 |
|---|---|---|
| `List<T>` | 动态数组 | 默认序列容器 |
| `Dictionary<K,V>` | 哈希表 | 按键快取（O(1)） |
| `HashSet<T>` | 去重集合 | 唯一性/集合运算 |
| `Queue<T>` / `Stack<T>` | 先进先出 / 后进先出 | 任务队列/撤销栈 |
| `LinkedList<T>` | 双链表 | 频繁中段插删（少见） |
| `ReadOnlyCollection<T>` 等只读包装 | 防外部改 | API 返回值 |

用法心智：**查找按键 → Dictionary；保序遍历 → List；去重 → HashSet**。线程安全版本在第 30 章（ConcurrentDictionary/Channel）。

## 5. 协变与逆变：out 与 in

泛型接口/委托的类型参数可以标注方向：

```csharp
IEnumerable<object> objs = new List<string> { "a", "b" };   // ✓ 协变 out
Action<object> printObj = o => ...;
Action<string> printStr = printObj;                          // ✓ 逆变 in
```

- **协变（out T）**：接口只**产出** T（IEnumerable、IEnumerator）——string 序列可以当 object 序列用（产出更具体的没问题）
- **逆变（in T）**：接口只**消费** T（Action、IComparer）——处理 object 的动作可以当处理 string 的用（能处理宽的就能处理窄的）
- **不变（无标注）**：既产又消（IList<T>、Dictionary<K,V>）——`List<string>` 不能当 `List<object>` 用！因为 List 既可读（产）又可写（消），双向通了就会写出 `object` 进 `string` 列表的事故

记忆法：**产出 out 协变、消费 in 逆变、可读可写不标注**。这是编译器在替你挡类型系统的洞。

## 6. 泛型的边界

- 泽型参数不能做运算符（`a + b` 编译不过——运算符是静态绑定的；数值泛型算法要用技巧：`INumber<T>`（.NET 7+ 的泛型数学接口）或第 36 章解释器那样自己 dispatch）
- 静态字段按"每个封闭类型"各一份：`LightStack<int>.Count` 与 `LightStack<string>.Count` 是两个字段——也是泛型缓存的原理（每 T 一份缓存）
- 运行时拿不到 T 的反射信息（`typeof(T)` 在编译期就定了）——第 23 章反射与泛型的组合有坑

## 常见坑

**`List<string>` 赋给 `List<object>` 编译错误**：IList 是不变（第 5 节）。只读地用就转 `IEnumerable<object>`（协变救场）。

**约束不够编译不过**：`a.CompareTo(b)` 报错——加 `where T : IComparable<T>`。约束不是负担，是编译器的证据链。

**泛型类里静态状态串味**：静态字段按封闭类型隔离——想要全局一份就放非泛型类。

**new() 约束调带参构造不行**：`new T(x)` 不存在——传工厂委托 `Func<T>`（dotnet 教程 DI 的做法）。

**值类型做 Dictionary 键忘了相等语义**：自定义 struct 键要正确实现 Equals/GetHashCode（record struct 免费送）——否则查找失灵。

## 实战建议

- 写第二份相似代码时抽泛型；一份时别急着抽（YAGNI）
- 约束写到"刚好够用"：能 `where T : IComparable<T>` 就别 `where T : IComparable`
- API 集合参数用窄接口（`IEnumerable<T>`/`IReadOnlyList<T>`），实现内部才用 List——协变可用 + 不暴露修改能力
- `INumber<T>`（.NET 7+）是数值泛型算法的正解，别再手写运算符分发

## 自测

1. **泛型相比 object 方案的三重收益？** —— 强类型编译期检查、零装箱、代码复用。
2. **约束给谁看？换来什么？** —— 给编译器证据（解锁成员调用）；给调用者合同。
3. **协变/逆变/不变各对应什么使用形态？** —— 产 out / 消 in / 既产又消不标注（List 不可协变的原因）。
4. **静态字段在泛型类里几份？** —— 每个封闭类型（T 的每个具体化）各一份。

---
上一章：[11 结构体与记录](11-records.md) ｜ 下一章：[13 委托](13-delegates.md) ｜ 返回：[README](../README.md)
