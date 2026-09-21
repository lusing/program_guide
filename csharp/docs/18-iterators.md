# 18 · 迭代器与 yield

> 对应示例：`examples/18_iterators`

> **本章你将学会**：yield return 的语义、编译器状态机、拉模型的执行时机、手写 IEnumerator、无限序列。
> **前置章节**：[16 LINQ 延迟执行](16-linq-basics.md)、[10 IEnumerable](10-interfaces.md)。

## 1. foreach 背后的契约

`foreach (var x in seq)` 不是魔法，它要求 seq 实现 `IEnumerable<T>`，等价于：

```csharp
var enumerator = seq.GetEnumerator();
try
{
    while (enumerator.MoveNext())          // 前进
        Console.WriteLine(enumerator.Current);   // 取当前
}
finally { enumerator.Dispose(); }
```

`IEnumerable`（能被枚举）+ `IEnumerator`（枚举进行时的游标：Current/MoveNext/Reset）两个接口撑起一切：数组、List、string、LINQ 查询、字典的键……**自定义类型实现 GetEnumerator 即可被 foreach**——本章讲两种实现方式：手写（第 5 节）和 yield（主角）。

## 2. yield return：编译器替你写状态机

```csharp
static IEnumerable<int> Countdown(int from)
{
    while (from >= 0)
    {
        yield return from;      // 「还回一个值，暂停在这里」
        from--;
    }
}

foreach (var n in Countdown(3)) { }     // 3 2 1 0
```

`yield return` 的语义：**产出一个值，方法在此挂起**；调用方 MoveNext 时从挂起点继续。你写的是"产出序列的逻辑"，编译器生成一个实现 IEnumerator 的**状态机类**：把局部变量、执行位置全部收进对象，MoveNext 恢复现场跑下一节。

这就是第 16 章"延迟执行"的物理基础：**定义 Countdown 不执行任何代码**——没有集合、没有循环跑起来；每次 MoveNext 才算一步。`yield break` 提前终止（相当于 return）。

## 3. 惰性的三个实验（示例输出）

**实验一：定义不执行**

```csharp
var seq = Countdown(int.MaxValue);     // 一行都没跑！
seq.Take(3)                            // 只触发 3 次 yield——无限"序列"安全可用
```

**实验二：无限序列**

```csharp
static IEnumerable<long> Fibonacci()
{
    long a = 0, b = 1;
    while (true) { yield return a; (a, b) = (b, a + b); }   // 永不结束，但 Take(10) 只取 10 步
}
```

**实验三：拉模型**——示例给 Demo() 每步打日志：定义时零输出；`Take(2).ToList()` 只出现 2 条"取到"日志。**消费者拉一步，生产者算一步**（推模型相反：生产完再给）。

## 4. 什么时候自己写迭代器

- **按需生成序列**：数列、日期区间、分页页码——`yield return` 生成，不建中间集合
- **遍历非集合结构**：树的先序遍历、链表、自造数据源
- **包装另一个序列**：过滤/变换的流水线（LINQ 操作符就这么写的——第 17 章 MyWhere 亲手写过）
- **早退场景**：找到就停（配合调用方 Take/First，浪费零计算）

对比 List 的"先算全量再返回"：迭代器**免中间集合分配**、支持无限/流式数据——大文件逐行、网络流分帧的标准形态。

## 5. 手写 IEnumerator：看清 yield 的替身

不 yield，手写完整版（示例的 SimpleRange）：

```csharp
class SimpleRange(int start, int end) : IEnumerable<int>
{
    public IEnumerator<int> GetEnumerator() => new RangeEnum(start, end);
    // 还要实现非泛型 IEnumerable.GetEnumerator()

    private sealed class RangeEnum(int start, int end) : IEnumerator<int>
    {
        private int _current = start - 1;
        public int Current => _current;
        public bool MoveNext() => ++_current <= end;
        public void Reset() => _current = start - 1;
        public void Dispose() { }
        // 还要实现非泛型 Current
    }
}
```

20 行样板 vs yield 的 5 行——**yield return 就是让编译器替你写这个类**。什么时候必须手写：需要 Reset 真实现、并发游标共享状态、或极度性能定制（struct 枚举器省接口调用）——其余永远 yield。

## 6. 迭代器的纪律

**一个 yield 方法 = 一个枚举器工厂**：每次 GetEnumerator 返回独立游标——同一序列可被同时多次枚举（两个嵌套 foreach 不打架）。

**不能在 try-catch 块内 yield**（try-finally 可以）：状态机恢复机制的限制——需要错误处理就把 yield 移出 catch 范围或改用普通返回。

**首次 MoveNext 前参数验证不生效**：迭代器方法体（含参数检查）在 GetEnumerator 时不跑、首次 MoveNext 才跑——错误延迟暴露。解法：两层结构（外层普通方法验证参数 + 返回内层迭代器方法的返回值）——BCL 的标准做法：

```csharp
public static IEnumerable<T> MyWhere<T>(IEnumerable<T> source, Func<T,bool> pred)
{
    ArgumentNullException.ThrowIfNull(source);      // 外层立刻验证
    return Core(source, pred);                      // 迭代器在 Core 里
}
static IEnumerable<T> Core<T>(IEnumerable<T> s, Func<T,bool> p) { ... yield ... }
```

**多枚举多执行**：第 16 章的坑在物理层就是"每 GetEnumerator 重新跑状态机"。

## 常见坑

**迭代器方法体不立即执行**：调用后一行代码都没跑（首次 MoveNext 才跑）——参数验证/日志"没出现"的原因。

**foreach 中修改集合**：底层集合变了枚举器发现版本不符 → InvalidOperationException——枚举中要改，先 ToList()。

**在 yield 方法里 lock / using**：try-finally 允许但生命周期被拉长到枚举结束——锁跨到消费方是事故（死锁风险），别这么写。

**返回 null 的 IEnumerable**：返回空序列用 `yield break` 或 `Enumerable.Empty<T>()`，别返回 null。

**嵌套 yield 没摊平**：方法里 `foreach (var x in inner) yield return x;` 可以（手写 SelectMany）；但 `yield return inner;` 返回的是序列的序列——想想你要哪层。

## 实战建议

- 序列生成默认 yield（免集合分配 + 天然惰性）；真需要多次随机访问再物化 List
- 公开 API 的迭代器用"外层验证 + 内层 Core"两层结构（本章第 6 节模板）
- `Enumerable.Empty<T>()` 表示空序列；`yield break` 表达提前结束
- 管道组合思维：生成器 → Where → Select → Take，全程零中间集合——LINQ 与迭代器是一体的
- 第 28 章 `await foreach`（IAsyncEnumerable）是本章的异步版——地基在此

## 自测

1. **yield return 的语义与编译产物？** —— 产出一个值即挂起，调用方驱动恢复；编译器生成状态机类实现 IEnumerator。
2. **为什么"定义不执行"？拉模型指什么？** —— 方法体在首次 MoveNext 才开始跑；消费一步生产一步。
3. **无限序列怎么安全消费？** —— Take/First 等早退操作符，只触发所需次数的 MoveNext。
4. **迭代器参数验证的两层结构解决什么？** —— 迭代器体延迟执行导致验证延迟；外层普通方法立即验证。

---
上一章：[17 LINQ 进阶](17-linq-advanced.md) ｜ 下一章：[19 模式匹配](19-patterns.md)
