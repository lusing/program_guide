# 37 · 集合体系与选型

> 对应示例：`examples/37_collections`

> **本章你将学会**：BCL 集合家族的分工与复杂度账单、只读视图与不可变集合的区别、遍历时修改为什么会炸、以及「数据结构课概念 → BCL 现成类」的映射。
> **前置章节**：[07 数组与枚举](07-arrays-enums.md)、[12 泛型](12-generics.md)、[18 迭代器](18-iterators.md)。

第 07 章讲过数组，第 12 章的示例一直拿 `List<T>`/`Dictionary` 当泛型的例子——但「集合本身」还没有专门讲过。这一章补上：**三本参考教材（《Visual C# 从入门到精通》第 18 章「使用集合」、《大学程序设计》第 14 章「数据结构」、《从零开始学》第 9 章）都把集合当重点**，因为真实 C# 代码里，选错集合是性能问题的高发区。

## 1. List\<T\>：动态数组，默认答案

`List<T>` 是「会自己长大的数组」：内部一个数组 + Count/Capacity 两个计数器。

```csharp
var primes = new List<int> { 2, 3, 5, 7 };
primes.Add(11);                       // 尾部追加：均摊 O(1)
primes.AddRange([13, 17]);
primes.Insert(0, 1);                  // 中间插入：O(n)
```

示例实测：空表 `Capacity=0`，加 5 个元素后 `Capacity=8`——**扩容按倍数走**（不是每 Add 一次分配一次），把「偶尔搬家」的成本摊到每次 Add 上。所以 Add 是「均摊 O(1)」，不是「每次 O(1)」；中间 Insert/Remove 是 O(n)，后面的元素整体 memmove。

**何时不用 List**：频繁中间插删（且实测真的慢）、需要在头部插删（考虑 `LinkedList` 或干脆倒序用 List）、需要按键查表（Dictionary）。

## 2. Dictionary\<TKey,TValue\>：哈希表

```csharp
var scores = new Dictionary<string, int> { ["Ada"] = 95, ["Grace"] = 97 };
if (scores.TryGetValue("Ada", out var ada))      // 判断 + 取值一次完成
    Console.WriteLine(ada);

foreach (var word in text.Split(' '))            // 词频统计：最高频用法
    freq[word] = freq.GetValueOrDefault(word) + 1;
```

三个高频惯用法：

- **TryGetValue 代替 ContainsKey + 索引**：后者哈希两遍（ContainsKey 一遍、取值一遍）
- **`dict[key] = dict.GetValueOrDefault(key) + 1`**：计数器三件套的老写法是 `if (!TryGet) Add`，现在一行
- **KeyValuePair 解构**：`foreach (var (k, v) in dict)` 直接拆开

代价：无序（遍历顺序不保证）、内存开销比数组大（桶 + 装箱不发生但哈希码缓存、链表/开放寻址结构）、键必须正确实现 `GetHashCode`/`Equals`（自定义 struct 键忘了就是查不到，record struct 免费送）。

## 3. HashSet 与 Sorted 家族

```csharp
var a = new HashSet<int> { 1, 2, 3, 4 };
var b = new HashSet<int> { 3, 4, 5, 6 };
a.IntersectWith(b);                   // {3,4}：集合运算 O(n)
var uniq = new HashSet<int>(dup);     // 去重且保序（首次出现位置）
```

判重/交并差用 `HashSet<T>`——`List.Contains` 是 O(n)，在循环里判重就成了 O(n²)。

有序家族二选一：

| | SortedList<K,V> | SortedDictionary<K,V> |
|---|---|---|
| 内部结构 | 两个数组（键、值） | 红黑树 |
| 随机访问 | O(1)（数组下标） | O(log n) |
| 插入/删除 | O(n)（挪数组） | O(log n) |
| 内存 | 紧凑 | 每节点一个对象 |
| 适合 | 小数据、填一次查多次 | 大数据、频繁插删 |

## 4. Queue / Stack / PriorityQueue

```csharp
var queue = new Queue<string>();
queue.Enqueue("任务A");                // FIFO：BFS、生产者-消费者
var stack = new Stack<string>();
stack.Push("底部");                    // LIFO：DFS、撤销栈、解析器（36 章解释器用过）

var pq = new PriorityQueue<string, int>();
pq.Enqueue("高优先", 1); pq.Enqueue("低优先", 5);
pq.Dequeue();                          // "高优先"——最小堆，数字小先出
```

`PriorityQueue<TElement,TPriority>`（.NET 6+）替你实现了数据结构课的「二叉堆」——调度、Dijkstra、Top-K 都用它，别再手写堆。

## 5. LinkedList\<T\>：真的需要它的人不多

```csharp
var ll = new LinkedList<int>();
var node = ll.Find(2)!;                // 拿到的是「节点」不是值
ll.AddAfter(node, 3);                  // 已知节点旁插入 O(1)
```

这是 BCL 里唯一暴露「节点」概念的集合。它的 O(1) 插入**前提是手里已有节点**——先 `Find` 就是 O(n)。每元素一个节点对象（GC 压力、缓存不友好），没有随机访问；`List` 的中间插入虽是 O(n) 但常数极小（memmove 一段连续内存）。**先实测再换 LinkedList**，多数场景换完更慢。

## 6. 只读视图 vs 不可变集合

```csharp
var mutable = new List<int> { 1, 2, 3 };
ReadOnlyCollection<int> view = mutable.AsReadOnly();
mutable.Add(4);                        // 视图跟着变：view == [1,2,3,4]
view[0] = 99;                          // NotSupportedException（防误写，不防背后有人改）

var frozen = ImmutableArray.Create(1, 2, 3);   // System.Collections.Immutable（BCL 内置）
var bigger = frozen.Add(4);            // 返回新数组：旧 [1,2,3] 新 [1,2,3,4]
```

两者解决不同问题：**AsReadOnly 是「权限声明」**（我不许你改，但别人还能改原表），**Immutable 是「数据形态」**（改了就是新对象，旧快照永远不变）。跨线程共享后不再改的数据、要安全暴露给外部的快照——用 Immutable；频繁修改的构建期用普通 List，最后转出去。

## 7. 遍历时修改：版本号机制

```csharp
var bad = new List<int> { 1, 2, 3, 4, 5 };
foreach (var x in bad)
    if (x % 2 == 0) bad.Remove(x);     // InvalidOperationException!
```

List 内部有个 `version` 字段，每次修改 +1；枚举器的 `MoveNext` 发现版本变了就抛异常——**这是故意炸给你看**，否则遍历行为未定义。正解三选一：

```csharp
bad.RemoveAll(x => x % 2 == 0);        // ① 框架替你处理版本（首选）
foreach (var x in bad.ToArray())       // ② 拷贝一份再删原表
    if (x % 2 == 0) bad.Remove(x);
for (int i = bad.Count - 1; i >= 0; i--)   // ③ 倒序 for（正序会跳元素）
    if (bad[i] % 2 == 0) bad.RemoveAt(i);
```

Dictionary 同理（改键更要命）。Concurrent 系列家族用精细枚举语义代替「直接炸」。

## 8. Array 静态家族

数组除了语法，还有一套 `System.Array` 静态工具（《从零开始学》第 5 章的「Array 类」专题）：

```csharp
int[] arr = [5, 2, 8, 1, 9, 3];
Array.Sort(arr);                                  // 原地排序
Array.BinarySearch(arr, 8);                       // 二分（必须先有序）
Array.Resize(ref arr, arr.Length + 2);            // 注意 ref！新数组+拷贝
var evens = Array.FindAll(arr, x => x % 2 == 0);  // Find/FindIndex/Exists/TrueForAll...
var big = Array.ConvertAll(arr, x => x * 10);     // 映射（≈ Select+ToArray，零枚举开销）
```

`Resize` 的 `ref` 提醒你：数组定长，扩容 = 新数组 + 拷贝 + 更新引用——这正是 List 自动帮你做的事。

## 9. 数据结构课 → BCL 映射

《大学程序设计》第 14 章教手写线性表/栈/队列；工程答案是**先查 BCL 有没有现成的**：

| 数据结构 | BCL 类 |
|---|---|
| 顺序表 | `List<T>` |
| 链表 | `LinkedList<T>` |
| 栈 | `Stack<T>` |
| 队列 | `Queue<T>`（并发 `ConcurrentQueue<T>`） |
| 哈希表 | `Dictionary<K,V>` |
| 集合 | `HashSet<T>` |
| 有序表 | `SortedDictionary<K,V>` |
| 优先队列/堆 | `PriorityQueue<TElement,TPriority>` |

## 10. 非泛型集合 ArrayList/Hashtable：教材讲、新代码别用

三本教材都花大篇幅讲 `ArrayList`/`Hashtable`——它们是 .NET 1.x **没有泛型时代**的遗产，元素类型是 `object`：

```csharp
var mixed = new ArrayList { 1, "二", 3.0 };   // 什么都能塞——这正是问题
int x = (int)mixed[1];                        // 运行时 InvalidCastException
```

示例实测两个代价：**int 全部装箱**（[05 章](05-value-reference.md)的分配账单）、**类型安全拖到运行期**（强转当场翻脸）。2005 年 C# 2.0 起 `List<T>`/`Dictionary<K,V>` 编译期类型安全 + 免装箱 + 更快，全方位替代。见到老代码按口诀迁移：见 `ArrayList` 想 `List<T>`，见 `Hashtable` 想 `Dictionary<K,V>`。

## 11. 复杂度总表与并发

```
┌────────────────────┬─────────┬──────────┬──────────┐
│ 类型               │ 索引/查 │ 插入(尾) │ 插入(中)  │
├────────────────────┼─────────┼──────────┼──────────┤
│ List<T>            │ O(1)    │ 均摊O(1) │ O(n)     │
│ Dictionary<K,V>    │ O(1)哈希│ 均摊O(1) │ —        │
│ HashSet<T>         │ O(1)哈希│ 均摊O(1) │ —        │
│ SortedDictionary   │ O(log n)│ O(log n) │ O(log n) │
│ LinkedList<T>      │ O(n)    │ O(1)     │ O(1)*    │
└────────────────────┴─────────┴──────────┴──────────┘
```

多线程读写用 `ConcurrentDictionary` 等并发家族——示例实测：1000 次 `Parallel.For` 并发计数，`AddOrUpdate` 原子累加总和恰好 1000（`lock + Dictionary` 的粗锁版本在竞争下既慢又容易丢更新，见 [30 章线程安全](30-thread-safety.md)）。

## 常见坑

**foreach 里改集合炸 InvalidOperationException**：版本号机制（第 7 节），用 RemoveAll/先拷贝/倒序 for。

**把 AsReadOnly 当「防御性拷贝」**：只是视图，原表变了视图跟着变（第 6 节）。要真快照就 `ToList()` 或 Immutable。

**自定义 struct 做 Dictionary 键忘了 Equals/GetHashCode**：哈希查找失灵——record struct 免费送这两个。

**List 当队列用（Insert(0,...) + RemoveAt(0)）**：两端都是 O(n)——用 `Queue<T>`。

**倒序遍历写了正序**：`for (i=0; i<Count; i++) RemoveAt(i)` 删一个跳一个。

## 实战建议

- 默认 `List<T>`；按键查表 `Dictionary`；判重 `HashSet`；要有序 `Sorted*`；多线程 `Concurrent*`；共享只读 `Immutable*`
- 集合参数类型收到最窄（`IEnumerable<T>`/`IReadOnlyList<T>`）——协变可用 + 不暴露修改能力
- 怀疑集合是瓶颈：先 BenchmarkDotNet 实测（换 LinkedList 前必测），再看复杂度表找目标
- 需要魔改集合行为时先想扩展方法（[40 章 Effective 条 28](40-effective-generics.md)），别急着继承

## 自测

1. **List.Add 为什么是「均摊」O(1)？** —— 扩容按倍数走，搬家成本摊进各次 Add（Capacity 从 0→4→8 的实测）。
2. **AsReadOnly 和 ImmutableArray 的本质区别？** —— 视图（权限声明，跟原表联动）vs 新实例（数据形态，旧快照不变）。
3. **遍历时修改为什么炸？三种正解？** —— version 字段被 MoveNext 检查；RemoveAll / 先拷贝 / 倒序 for。
4. **SortedList 与 SortedDictionary 怎么选？** —— 小且查多 → 数组版（O(1) 随机访问、内存紧凑）；大且插删多 → 树版（O(log n)）。
5. **PriorityQueue 出队顺序由什么决定？** —— 优先级比较（默认最小堆：数字小先出），与入队顺序无关。

---
上一章：[36 实战：MiniLang 解释器](36-minilang.md) ｜ 下一章：[38 Effective C#·语言习惯](38-effective-habits.md) ｜ 返回：[README](../README.md)
