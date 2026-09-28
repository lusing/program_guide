// 37 · 集合体系与选型：从数组到并发字典的 BCL 全家福
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== List<T>：动态数组，绝大多数场景的默认答案 =====");
var primes = new List<int> { 2, 3, 5, 7 };
primes.Add(11);                          // 尾部追加：均摊 O(1)
primes.AddRange([13, 17]);
primes.Insert(0, 1);                     // 中间插入：O(n)，后面的元素整体挪
primes.RemoveAt(0);
Console.WriteLine($"  内容: {string.Join(", ", primes)}   Count={primes.Count} Capacity={primes.Capacity}");
Console.WriteLine("  Capacity 翻倍增长（0→4→8→16）——Add 是均摊 O(1)，不是每次 O(1)");
Console.WriteLine("  索引访问 O(1)；中间插入/删除 O(n)——频繁中间插删换 LinkedList 或换算法");

var big = new List<int>();
Console.WriteLine($"  空表 Capacity={big.Capacity}");
for (int i = 0; i < 5; i++) big.Add(i);
Console.WriteLine($"  加 5 个后 Capacity={big.Capacity}（按倍扩容，不是加一个alloc一次）");

Console.WriteLine();
Console.WriteLine("===== Dictionary<TKey,TValue>：哈希表，键值查找 O(1) =====");
var scores = new Dictionary<string, int>
{
    ["Ada"] = 95, ["Linus"] = 88, ["Grace"] = 97,   // 集合初始化器（索引写法）
};
scores["Dennis"] = 91;                    // 不存在则新增
scores["Linus"] = 90;                     // 存在则覆盖
Console.WriteLine($"  Grace={scores["Grace"]}  共 {scores.Count} 人");
if (scores.TryGetValue("Ada", out var ada))       // TryGetValue：查+取一步，避免二次哈希
    Console.WriteLine($"  TryGetValue(\"Ada\") → {ada}（判断+取值一次搞定，比 ContainsKey+索引快一倍哈希）");

foreach (var (name, score) in scores)               // KeyValuePair 解构
    if (score >= 92) Console.WriteLine($"  {name}: {score}");

var text = "the quick brown fox jumps over the lazy dog the end";
var freq = new Dictionary<string, int>();
foreach (var word in text.Split(' '))
    freq[word] = freq.GetValueOrDefault(word) + 1;  // 计数惯用法：缺省 0 + 1
Console.WriteLine($"  词频统计: the × {freq["the"]}（Dictionary 计数是最高频用法之一）");

Console.WriteLine();
Console.WriteLine("===== HashSet<T> / Sorted 家族 / Queue / Stack =====");
var a = new HashSet<int> { 1, 2, 3, 4 };
var b = new HashSet<int> { 3, 4, 5, 6 };
a.IntersectWith(b);                      // 交集：原地修改
Console.WriteLine($"  HashSet 交集 {{1..4}} ∩ {{3..6}} = {{{string.Join(",", a)}}}（集合运算 O(n)，List.Contains 是 O(n²)）");
var dup = new[] { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3 };
Console.WriteLine($"  去重: {string.Join(",", new HashSet<int>(dup))}（保序：首次出现的位置）");

var sorted1 = new SortedList<int, string> { [3] = "c", [1] = "a", [2] = "b" };   // 数组实现，内存紧凑
var sorted2 = new SortedDictionary<int, string> { [3] = "c", [1] = "a", [2] = "b" }; // 红黑树
Console.WriteLine($"  SortedList 与 SortedDictionary 输出同为按键有序: {sorted1[1]}{sorted1[2]}{sorted1[3]}");
Console.WriteLine("  选型：小数据+内存敏感 → SortedList（数组，随机访问 O(1)）；大数据+频繁插删 → SortedDictionary（B 树，插删 O(log n)）");

var queue = new Queue<string>();
queue.Enqueue("任务A"); queue.Enqueue("任务B"); queue.Enqueue("任务C");
Console.WriteLine($"  Queue FIFO: 出队 {queue.Dequeue()} → 剩 [{string.Join(", ", queue)}]（BFS、生产者-消费者缓冲）");
var stack = new Stack<string>();
stack.Push("底部"); stack.Push("中间"); stack.Push("顶部");
Console.WriteLine($"  Stack LIFO: 弹栈 {stack.Pop()} → 剩 [{string.Join(", ", stack)}]（DFS、撤销栈、解析器）");

Console.WriteLine();
Console.WriteLine("===== LinkedList<T>：真的需要它的人不多 =====");
var ll = new LinkedList<int>();
ll.AddLast(1); ll.AddLast(2); ll.AddLast(4);
var node = ll.Find(2)!;                  // 拿到节点（不是值）
ll.AddAfter(node, 3);                    // 节点级插入 O(1)——这是它存在的唯一理由
Console.WriteLine($"  节点插入后: {string.Join("→", ll)}");
Console.WriteLine("  代价：每元素一个节点对象（指针+GC 压力），无随机访问，缓存不友好");
Console.WriteLine("  List 中间插 O(n) 但常数极小（memmove）——实测通常比 LinkedList 快，先测再换");

Console.WriteLine();
Console.WriteLine("===== 只读视图 vs 不可变集合 =====");
var mutable = new List<int> { 1, 2, 3 };
System.Collections.ObjectModel.ReadOnlyCollection<int> view = mutable.AsReadOnly();
mutable.Add(4);
Console.WriteLine($"  只读「视图」: 原表加 4 后视图也变 → [{string.Join(",", view)}]（包装，不是拷贝）");
try { var _ = ((IList<int>)view)[0] = 99; }
catch (NotSupportedException) { Console.WriteLine("  视图禁止写入 → NotSupportedException（防误用，不防背后有人改）"); }

var frozen = System.Collections.Immutable.ImmutableArray.Create(1, 2, 3);
Console.WriteLine($"  ImmutableArray: [{string.Join(",", frozen)}]（System.Collections.Immutable，net10 内置零依赖）");
var frozen2 = frozen.Add(4);              // 返回新数组
Console.WriteLine($"  Add(4) 返回新实例: 旧=[{string.Join(",", frozen)}] 新=[{string.Join(",", frozen2)}]");
Console.WriteLine("  每次修改都建新集合：小集合/共享快照用 Immutable；频繁改用普通 List 最后 AsReadOnly");

Console.WriteLine();
Console.WriteLine("===== 遍历时修改：InvalidOperationException =====");
var bad = new List<int> { 1, 2, 3, 4, 5 };
try
{
    foreach (var x in bad)
        if (x % 2 == 0) bad.Remove(x);    // 版本号机制：MoveNext 检查 version 字段
}
catch (InvalidOperationException ex)
{
    Console.WriteLine($"  foreach 中 Remove → {ex.GetType().Name}: 集合已修改，遍历失效");
}
// 正解三选一：
bad.RemoveAll(x => x % 2 == 0);          // ① RemoveAll：框架替你处理版本
Console.WriteLine($"  正解① RemoveAll: [{string.Join(",", bad)}]");
var c2 = new List<int> { 1, 2, 3, 4, 5 };
foreach (var x in c2.ToArray())          // ② 拷贝一份再遍历
    if (x % 2 == 0) c2.Remove(x);
Console.WriteLine($"  正解② 先 ToArray 再删: [{string.Join(",", c2)}]");
Console.WriteLine("  正解③ 倒序 for + RemoveAt（正序 for 会跳元素——删除后索引前移）");

Console.WriteLine();
Console.WriteLine("===== Array 静态家族（从零开始学书的 Array 类专题） =====");
int[] arr = [5, 2, 8, 1, 9, 3];
Array.Sort(arr);
Console.WriteLine($"  Array.Sort: [{string.Join(",", arr)}]（int[] 快排/introsort）");
Console.WriteLine($"  Array.BinarySearch(8) → 下标 {Array.BinarySearch(arr, 8)}（必须先有序）");
Array.Resize(ref arr, arr.Length + 2);   // ref！扩容是「新数组+拷贝」，旧引用要更新
arr[^2] = 7; arr[^1] = 6;                // Resize 后两个新格子默认 0，这里填上值
Console.WriteLine($"  Array.Resize 后: [{string.Join(",", arr)}]");
var evens = Array.FindAll(arr, x => x % 2 == 0);
Console.WriteLine($"  Array.FindAll: [{string.Join(",", evens)}]（还有 Find/FindIndex/FindLast/Exists/TrueForAll）");
var doubled = Array.ConvertAll(arr, x => x * 10);
Console.WriteLine($"  Array.ConvertAll: [{string.Join(",", doubled)}]（映射，等价 LINQ Select + ToArray，但零枚举开销）");

Console.WriteLine();
Console.WriteLine("===== 数据结构课 → BCL 映射（大学教材第 14 章的「现成答案」） =====");
Console.WriteLine("  线性表(顺序表) → List<T>          线性表(链表) → LinkedList<T>");
Console.WriteLine("  栈 → Stack<T>                     队列 → Queue<T>（并发用 ConcurrentQueue<T>）");
Console.WriteLine("  哈希表 → Dictionary<K,V>          集合 → HashSet<T>");
Console.WriteLine("  有序表 → SortedDictionary<K,V>    不打算手写二叉堆——PriorityQueue<TElement,TPriority>（.NET 6+）");
var pq = new PriorityQueue<string, int>();
pq.Enqueue("低优先", 5); pq.Enqueue("高优先", 1); pq.Enqueue("中优先", 3);
Console.WriteLine($"  PriorityQueue 出队序: {pq.Dequeue()} → {pq.Dequeue()} → {pq.Dequeue()}（最小堆，数字小先出）");

Console.WriteLine();
Console.WriteLine("===== 选型速查（复杂度表） =====");
Console.WriteLine("  ┌────────────────────┬─────────┬──────────┬──────────┐");
Console.WriteLine("  │ 类型                │ 索引/查 │ 插入(尾) │ 插入(中)  │");
Console.WriteLine("  ├────────────────────┼─────────┼──────────┼──────────┤");
Console.WriteLine("  │ List<T>             │ O(1)    │ 均摊O(1) │ O(n)     │");
Console.WriteLine("  │ Dictionary<K,V>     │ O(1)哈希│ 均摊O(1) │ —        │");
Console.WriteLine("  │ HashSet<T>          │ O(1)哈希│ 均摊O(1) │ —        │");
Console.WriteLine("  │ SortedDictionary    │ O(log n)│ O(log n) │ O(log n) │");
Console.WriteLine("  │ LinkedList<T>       │ O(n)    │ O(1)     │ O(1)*    │");
Console.WriteLine("  └────────────────────┴─────────┴──────────┴──────────┘");
Console.WriteLine("  * LinkedList 的 O(1) 前提是手里已有节点；先 Find 就是 O(n)");
Console.WriteLine();
Console.WriteLine("  并发场景：ConcurrentDictionary（细粒度锁/无锁读）代替 lock+Dictionary");
var cd = new System.Collections.Concurrent.ConcurrentDictionary<int, int>();
System.Threading.Tasks.Parallel.For(0, 1000, i =>
    cd.AddOrUpdate(i % 10, 1, (_, old) => old + 1));    // 原子计数，无丢失
Console.WriteLine($"  1000 次并发计数落进 10 个桶: 总和={cd.Values.Sum()}（lock+Dictionary 版在竞争下会丢更新）");
Console.WriteLine();
Console.WriteLine("  记忆口诀：默认 List；要查表就 Dictionary；要判重就 HashSet；要顺序就 Sorted*；");
Console.WriteLine("            多线程读写就 Concurrent*；跨线程共享后不再改就 Immutable*。");
