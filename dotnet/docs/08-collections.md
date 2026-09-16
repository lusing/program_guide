# 08 · 集合：List、Dictionary 与 IEnumerable

> 对应示例：`examples/08_collections`

## 1. 选型表：先选对容器

| 容器 | 语义 | 典型查找 | 何时用 |
|---|---|---|---|
| `List<T>` | 有序可变序列 | 按索引 O(1)；按值 O(n) | 默认的"一串东西" |
| `Dictionary<K,V>` | 键值映射 | 按键 O(1) | "根据 X 找 Y" |
| `HashSet<T>` | 去重集合 | O(1) | 存在性判断、去重 |
| `Queue<T>` / `Stack<T>` | FIFO / LIFO | — | 任务队列 / 撤销栈 |
| `SortedList<K,V>` / `SortedDictionary<K,V>` | 有序映射 | O(log n) | 要按键序遍历 |

误用最多的两条：该用 HashSet 查存在性却用 List.Contains（O(n)）；该用 Dictionary 做映射却 List + FindIndex 扫全表。

## 2. List：日常主力

示例的第一段：

```csharp
var fruits = new List<string> {"Apple", "Banana", "Cherry"};
fruits.Add("Date");
fruits.Insert(1, "Blueberry");
fruits.Remove("Banana");
```

集合初始化器（`{...}` 直接填元素）+ 增删的常规阵容。查找系 API 值得记：`FindIndex(pred)`（第一个满足的下标，没有返回 -1）、`Find/FindAll(pred)`、`Contains`、`IndexOf`。容量角度：List 内部是数组，扩容时整体搬迁——能预估量级就 `new List<T>(capacity)`。

## 3. Dictionary：映射

```csharp
var ages = new Dictionary<string, int>
{
    ["Alice"] = 25,
    ["Bob"] = 30,
    ["Charlie"] = 35
};
ages["David"] = 40;
ages.TryAdd("Grace", 50);
ages.Remove("Charlie");
```

索引器语法（`["Alice"] = 25`）是字典特有的初始化写法。**读值的三种姿势**是字典日常：

```csharp
var age = ages["Alice"];                       // 1. 键不存在 → 抛 KeyNotFoundException
if (ages.TryGetValue("Bob", out var bobAge))   // 2. 一步试探 + 取值（推荐）
{ /* bobAge 可用 */ }
var maybe = ages.GetValueOrDefault("Zoe", -1); // 3. 不存在给默认值，不抛
```

遍历时元素类型是 `KeyValuePair<K,V>`：

```csharp
foreach (var kvp in ages)
{
    Console.WriteLine($"{kvp.Key} = {kvp.Value}");
}
```

键的纪律：键必须不可变且判等稳定——string、int、record（第 05 章的值相等）都合格；可变 class 做键是自找麻烦。

## 4. IEnumerable<T>：集合的抽象面

所有容器都实现 `IEnumerable<T>`——"能被 foreach 的东西"。方法参数尽量收 `IEnumerable<T>` 而不是 `List<T>`：数组、List、LINQ 结果、迭代器产物就都能传进来，API 的面就宽了（本教程示例的函数签名都这么做）。

配套武器是**迭代器方法**——`yield return` 惰性产出序列：

```csharp
static IEnumerable<int> Fibonacci(int count)
{
    int a = 0, b = 1;
    for (int i = 0; i < count; i++)
    {
        yield return a;          // 产出一个，暂停；调用方要下一个再继续
        (a, b) = (b, a + b);
    }
}
```

调用 `Fibonacci(10)` 并不执行循环体——**枚举时才逐个产出**（延迟执行的机制根基，第 09 章 LINQ 全靠它；异步版本 `IAsyncEnumerable` 在第 13 章）。

## 5. 自定义扩展方法：给 List 加能力

示例的收尾展示了第 06 章扩展方法的实战——"找到并移除第一个满足条件的元素"：

```csharp
var removed = fruits.PopIfMatch(x => x == "Date");
Console.WriteLine($"removed={removed ?? "none"}");
```

`PopIfMatch` 不是 BCL 的方法，是示例自己定义的：

```csharp
static class ListExtensions
{
    public static T? PopIfMatch<T>(this List<T> list, Predicate<T> predicate)
    {
        var index = list.FindIndex(predicate);
        if (index < 0) return default;
        var value = list[index];
        list.RemoveAt(index);
        return value;
    }
}
```

逐块看：`this List<T>` 使它对所有 `List<T>` 可见；`Predicate<T>`（`Func<T,bool>` 的别名）把条件外包给调用方——第 07 章的高阶函数模式；`default`/`T?` 处理"没找到"的返回（配合 `?? "none"` 的兜底输出，这条链路连到第 10 章）。

## 6. 坑位清单

1. **遍历时增删集合**：`foreach` 中 `Add/Remove` 抛 InvalidOperationException——先 `.ToList()` 固化再改，或倒序 for。
2. **结构体字典键可变**：`Dictionary<Point,int>` 的 Point（struct）取出后改字段，字典内部哈希位置失效，之后再查不到——struct 键必须不可变（第 04 章的告诫在这里兑现）。
3. **List.Contains 当存在性集合**：万级数据 × 频繁 Contains → 换 HashSet，O(n) 变 O(1)。
4. **迭代器多次枚举**：`IEnumerable` 每次枚举重跑一遍生成逻辑——耗时逻辑的结果要 `.ToList()` 存下来（第 09 章展开成完整一节）。
5. **`GetValueOrDefault` vs `[]` 的语义差**：前者静默给默认值可能掩盖"键本该存在"的错误；键缺失是异常状态时用 `TryGetValue` 并显式处理。
