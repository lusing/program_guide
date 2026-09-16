# 09 · LINQ：集合查询的一等语法

> 对应示例：`examples/09_linq`

## 1. 从手写到声明式

第 08 章末尾你已经手写过 `Filter`。真实需求总是复合的：过滤 + 排序 + 投影。手写版（示例 `08_collections` 里也有影子）：

```csharp
// 过滤、按成绩倒序、再按名字，拼成 "名字:成绩" 列表——三层循环 + 临时容器
var highScorers = students
    .Where(s => s.Grade > 80)
    .OrderByDescending(s => s.Grade)
    .Select(s => $"{s.Name}:{s.Grade}")
    .ToList();
```

右边就是 LINQ：**一条方法链声明"要什么"，不写"怎么取"**。`Where/OrderBy/Select` 全是 `System.Linq` 下 `IEnumerable<T>` 的扩展方法（第 06 章机制、第 07 章的谓词在这里合流）。

## 2. 走读示例

```csharp
var data = new[]
{
    new {Name = "alice", Score = 92},
    new {Name = "bob", Score = 78},
    new {Name = "carol", Score = 86},
    new {Name = "dave", Score = 92}
};
```

**匿名类型**（`new {Name = …, Score = …}`）：不声明类直接造一行数据，编译器生成带值相等（第 05 章讲过这本来就是 record 语义）的隐藏类型。适合方法内部的临时结构；跨方法的边界请用 record。

主查询：

```csharp
var passed = data
    .Where(x => x.Score >= 80)               // 过滤
    .OrderByDescending(x => x.Score)         // 主排序（降序）
    .ThenBy(x => x.Name)                     // 次排序：同分按名字
    .Select(x => $"{x.Name}:{x.Score}")      // 投影成另一种形状
    .ToList();                               // 立即执行并固化
```

链式读法：每个算子返回新的 `IEnumerable`（`OrderBy` 返回有序视图 `IOrderedEnumerable`，所以 `ThenBy` 能接在后面），像流水线逐级加工。**顺序很重要**：先 Where 后 Select 少投影一轮；`ThenBy` 只能接在 `OrderBy` 系后面。

分组：

```csharp
var groups = data.GroupBy(x => x.Score >= 90 ? "A" : "B");
foreach (var g in groups)
{
    Console.WriteLine($"{g.Key}: {string.Join(", ", g.Select(x => x.Name))}");
}
```

`GroupBy` 返回"组的序列"，每组是一个带 `Key` 的迷你集合（本身可枚举、可再 Select）。分组键可以是任意表达式——这里是按是否 ≥90 分成 A/B 档。

## 3. 方法链 vs 查询表达式

C# 另有一套 SQL 风格语法，同一件事两种写法：

```csharp
var passed = from x in data
             where x.Score >= 80
             orderby x.Score descending, x.Name
             select $"{x.Name}:{x.Score}";
```

查询表达式会被编译成完全相同的方法链。选择惯例：**日常用方法链**（全部算子可用、lambda 可读）；多生成器 + join + 复杂分组时查询表达式更顺眼。两套都认识，团队统一一种。

## 4. 常用算子速查

| 类别 | 算子 |
|---|---|
| 过滤 | `Where(pred)`、`OfType<T>()`、`Take(n)` / `Skip(n)` / `TakeWhile` |
| 投影 | `Select(x => f(x))`、`SelectMany`（拍平嵌套）、`Distinct` |
| 排序 | `OrderBy` / `OrderByDescending` / `ThenBy` / `Reverse` |
| 分组 | `GroupBy(key)`、`ToLookup`（可重复索引的字典） |
| 聚合 | `Sum / Average / Min / Max / Count`、通用 `Aggregate(seed, func)` |
| 元素 | `First(pred)`（没有就抛）/ `FirstOrDefault`（没有给 null/default）、`Single`（恰一个）、`Any` / `All`、`Contains` |
| 集合 | `Concat`、`Union` / `Intersect` / `Except`（交集并差） |
| 固化 | `ToList` / `ToArray` / `ToDictionary(key)` |

`FirstOrDefault` 的返回是可空引用（第 10 章）——"没找到"用 null 表达，判空再解引用是标准姿势。

## 5. 延迟执行：LINQ 最重要的心智模型

`var q = data.Where(...)` 这行**什么都没算**——只是记下了查询计划（一串委托）。真正枚举 `q`（foreach / ToList / Count）时才逐元素跑流水线。两个直接后果：

**后果一：多次枚举 = 多次计算。**

```csharp
var query = ExpensiveSource().Where(x => x.Score > 80);
var a = query.Count();      // 完整跑一遍数据源
var b = query.Sum(x => x.Score);   // 又完整跑一遍！
```

要复用结果：`var list = query.ToList();`——一次计算，之后随便数。

**后果二：数据源变了，查询结果跟着变。**

```csharp
var names = new List<string> {"a"};
var q = names.Where(n => n.Length > 0);
names.Add("b");
Console.WriteLine(q.Count());   // 2——查询在 Count 时才看数据源
```

这对"查询定义一次、多处按最新数据执行"是特性；对"我以为结果是快照"是 bug。分不清时，ToList 是最诚实的动作。

## 6. 坑位清单

1. **忘了固化**（本节最常见 bug）：查询结果用两次以上 → ToList 一次。
2. **LINQ 里做副作用**：`Where(x => { Console.WriteLine(x); return true; })` 在延迟执行下何时执行不可预期——查询算子保持纯净。
3. **`First` vs `FirstOrDefault` 语义错配**："应该有却没查到"是 bug 信号 → 用 `First` 让它抛出来；"没有是正常情况" → `FirstOrDefault` + 判空。选反要么吞掉 bug 要么误抛异常。
4. **接口签名泄漏 `IEnumerable` 的实现细节**：公共方法返回 `IEnumerable<T>` 却指望调用方只枚举一次，容易踩多次枚举；需要快照语义就返回 `IReadOnlyList<T>`。
5. **GroupBy 结果依赖**：组内元素的顺序在 .NET 实现里保序（默认），但拿这个当契约写在代码里是赌博——需要顺序在键选择器或后续 OrderBy 里显式表达。
