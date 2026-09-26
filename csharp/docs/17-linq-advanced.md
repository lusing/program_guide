# 17 · LINQ 进阶

> 对应示例：`examples/17_linq_advanced`

> **本章你将学会**：GroupBy/Join/SelectMany/Aggregate、自造 LINQ 操作符、IEnumerable vs IQueryable、性能陷阱清单。
> **前置章节**：[16 LINQ 基础](16-linq-basics.md)、[10 接口](10-interfaces.md)。

## 1. GroupBy：分组统计

```csharp
foreach (var g in employees.GroupBy(e => e.Department))
    Console.WriteLine($"{g.Key,-4} {g.Count()} 人，平均 {g.Average(e => e.Salary):N0}");
// 研发  3 人，平均 18833
// 设计  2 人，平均 15500
```

`GroupBy` 返回 `IEnumerable<IGrouping<TKey, T>>`——**每个组自带 Key 与组内序列**（g 本身就是该组的元素集合，可直接 Count/Average/foreach）。常见进阶：

```csharp
.ToDictionary(g => g.Key, g => g.ToList())          // 分组结果装箱成字典
.GroupBy(e => e.Department, e => e.Name)            // 只取组内某字段
.GroupBy(e => e.Department).OrderByDescending(g => g.Count())   // 组再排序
```

分组键可以是复合的：`GroupBy(e => (e.Department, e.Level))`（元组键）。

## 2. Join：两个集合的连接

```csharp
var joined = employees.Join(departments,           // 内表
    e => e.Department,                             // 内表键（employee 的部门名）
    d => d.Name,                                   // 外表键（department 的名字）
    (e, d) => $"{e.Name} → {d.English}");          // 命中后的结果选择器
```

等值连接（inner join）的标准形态：四个参数 = 外表 + 内键 + 外键 + 结果投影。变体家族：

- `GroupJoin`：一对多的 LEFT JOIN（部门 → 员工列表）
- 查询语法 `join d in departments on e.Department equals d.Name`（可读性更好）
- **没有非等值 Join**——非等值条件用"from 双 from + where"或先拉内存再说

## 3. SelectMany：压平嵌套

```csharp
var teams = new List<Team> { new("A 组", ["甲","乙"]), new("B 组", ["丙","丁"]) };

teams.SelectMany(t => t.Members)                    // ["甲","乙","丙","丁"]——两层变一层
teams.SelectMany(t => t.Members, (t, m) => $"{t.Name}:{m}")   // 带上父信息
```

**"组 → 成员"的展开**全靠它：订单列表 → 所有订单行、文件列表 → 所有行文本。对照：Select 对每个元素产出一个结果（保形），SelectMany 产出**一串**结果（摊平）。LINQ 里最难直觉的一个，记住"压平"二字。

## 4. Aggregate：万能聚合

```csharp
employees.Aggregate(0m, (acc, e) => acc + e.Salary);          // 种子 + 累加函数 = Sum
new[] { "C#", "Java", "F#" }.Aggregate((a, b) => a.Length >= b.Length ? a : b);   // 无种子版
```

Reduce/fold 模式：`种子 → 逐项累积 → 最终值`。Sum/Min/Max/Count 都是它的特例。无种子重载用第一个元素当种子（空序列抛异常）。**日常优先专用操作符**（可读性），Aggregate 留给"没有现成聚合"的场景（拼接自定义状态、多字段一起累计）。

## 5. 自造操作符：LINQ 没有魔法

```csharp
static IEnumerable<T> MyWhere<T>(IEnumerable<T> source, Func<T, bool> pred)
{
    foreach (var item in source)
        if (pred(item))
            yield return item;              // yield 是第 18 章主角
}
```

`employees.MyWhere(e => e.Salary > 16000)` 和官方 Where 行为一致——**LINQ 操作符 = 扩展方法（第 20 章）+ 迭代器（第 18 章）**，两个你已经（即将）掌握的机制。这个祛魅很重要：它意味着你可以**给自己类型加一套查询操作符**（自定义日志管道、配置查询），行为与 LINQ 无缝融合。

## 6. IEnumerable vs IQueryable（重要分界）

```csharp
IEnumerable<T>    // 内存查询：操作符是 Func<>，lambda 编译成机器码就地执行
IQueryable<T>     // 表达式树查询：操作符收 Expression<>，可被"翻译"成 SQL
```

EF Core 的 `DbSet<T>` 是 IQueryable——`Where(u => u.Age > 18)` 被翻译成 `WHERE Age > 18` 在**数据库**执行；误用 `.AsEnumerable()`/`.ToList()` 后的查询在**内存**执行（全表拉回来再筛——经典性能事故）。规则：**数据库端能做的（过滤/排序/分页）保持 IQueryable；内存专属操作（自定义方法、复杂对象逻辑）先物化再 LINQ**。详见 dotnet 教程 17 章。

## 7. 性能陷阱清单（示例实测）

| 陷阱 | 后果 | 解法 |
|---|---|---|
| 多次枚举同一查询 | 跑 N 遍 | ToList 定格 |
| `Count() > 0` | 数完全部 | `Any()` |
| `Where` 在 `OrderBy` 后 | 排完再筛白排 | 过滤趁早（Where 前置） |
| 循环里单查（`foreach + First`） | N+1 查询 | 先 ToDictionary 再循环查 |
| 大集合 `Contains(list2)` | O(n×m) | list2 转 HashSet |
| Select 里 new 重对象 | 全量构造 | 只投影要用的；必要时惰性 |

第 4 条"**N+1**"在 EF 场景是头号杀手：循环 1000 次员工查部门 = 1001 次查询——`departments.ToDictionary(d => d.Name)` 一字典解决。

## 常见坑

**GroupBy 后用组忘了 Key**：g 是组内元素序列，组名在 `g.Key`。

**Join 键类型不一致**：int 键 join string 键静默无结果（不报错！）——键类型/语义对齐。

**SelectMany 后丢父信息**：压平后只剩叶子——用双参重载 `(t, m) => ...` 或先 Select 匿名类型带父。

**Aggregate 空序列无种子**：抛异常——提供种子或先 Any 判断。

**IQueryable 上调自定义方法**：翻译不了 SQL 抛运行时异常（或更糟：整个查询被拉回内存）——翻译边界内的表达式保持"SQL 能表达"。

## 实战建议

- 报表类需求的心智：**GroupBy → 组内聚合 → 组排序 → ToDictionary**，一条链完成
- 自定义数据管道直接抄 MyWhere 模式：扩展方法 + yield，与 LINQ 语法自然衔接（第 36 章解释器也可挂上查询操作符）
- EF 查询每条都问一遍"这发生在数据库还是内存"——IQueryable 分界意识价值连城
- 复杂查询分步调试：每步 ToList 观察中间结果，正确后合链（保留 ToList 与否按需）

## 自测

1. **GroupBy 返回的每个元素是什么？** —— IGrouping<TKey,T>：Key + 组内元素序列（本身可枚举可聚合）。
2. **Select 与 SelectMany 的区别？** —— 保形投影 vs 摊平嵌套。
3. **IEnumerable 与 IQueryable 的本质分界？** —— Func 机器码内存执行 vs Expression 树可翻译（SQL）。
4. **N+1 问题怎么发生怎么解？** —— 循环内单查；先 ToDictionary 一次载入。

---
上一章：[16 LINQ 基础](16-linq-basics.md) ｜ 下一章：[18 迭代器与 yield](18-iterators.md) ｜ 返回：[README](../README.md)
