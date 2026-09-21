# 16 · LINQ 基础

> 对应示例：`examples/16_linq_basic`

> **本章你将学会**：方法链与查询语法、高频操作符、延迟执行的语义与陷阱、立即执行操作符。
> **前置章节**：[12 泛型](12-generics.md)、[15 Lambda](15-lambdas.md)。

## 1. LINQ 是什么：集合的声明式查询

"找出研发部的人，按薪水降序，只取名字和薪水"——命令式要写三层循环 + 临时列表；LINQ 一条链：

```csharp
var result = employees
    .Where(e => e.Department == "研发")          // 过滤
    .OrderByDescending(e => e.Salary)            // 排序
    .Select(e => new { e.Name, e.Salary });      // 投影
```

读代码 = 读需求：**写"要什么"而不是"怎么拿"**。LINQ（Language Integrated Query）把查询能力做进了语言——操作对象集合（本章）、数据库（EF 的 IQueryable）、XML、乃至自造数据源（第 18 章迭代器打底）。

## 2. 两种语法：方法链与查询语法

```csharp
// 方法链（主流）
var r1 = employees.Where(e => ...).OrderByDescending(e => ...).Select(e => ...);

// 查询语法（SQL 脸）
var r2 = from e in employees
         where e.Department == "研发"
         orderby e.Salary descending
         select new { e.Name, e.Salary };
// 编译后与 r1 完全相同——查询语法只是方法链的糖
```

| | 方法链 | 查询语法 |
|---|---|---|
| 覆盖度 | 全部操作符 | 子集（无 First/Count 等） |
| lambda 可见性 | 显式 | 隐式 |
| 何时用 | 默认 | 复杂 from/join/group 时更清晰 |

本教程默认方法链；看懂两种即可互译。

## 3. 高频操作符速查（示例全部实测）

| 操作符 | 作用 | 变体/备注 |
|---|---|---|
| `Where(pred)` | 过滤 | 位置任意、可多次 |
| `Select(proj)` | 投影变形 | SelectMany 压平嵌套（第 17 章） |
| `OrderBy(key)` / `OrderByDescending` | 主排序 | ThenBy 追加次序 |
| `First(pred)` | 第一个 | 无则**抛异常** |
| `FirstOrDefault(pred)` | 第一个 | 无则默认值（引用类型 null）——外部数据用它 |
| `Single(pred)` | 有且仅有一个 | 0 个或 ≥2 个都抛（表达"业务上唯一"） |
| `Any(pred)` / `All(pred)` | 存在性/全称判断 | **比 Count()>0 高效得多** |
| `Count(pred)` / `LongCount` | 计数 | 遍历一次 |
| `Max/Min/Sum/Average` | 聚合 | 空序列抛异常（用 ...OrDefault） |
| `Contains(item)` | 成员判断 | — |
| `Take(n)` / `Skip(n)` | 取前 n / 跳前 n | 分页 = Skip(page*size).Take(size) |
| `Distinct()` | 去重 | 默认按 Equals；可传比较器 |
| `OfType<T>()` / `Cast<T>()` | 类型过滤/转换 | 非泛型集合救场 |

`First vs FirstOrDefault vs Single` 是面试常客，更是 bug 高发区：**确定有才 First，不确定用 FirstOrDefault，业务唯一性用 Single**。

## 4. 延迟执行：定义时不跑

最重要的语义——**查询是配方，不是结果**：

```csharp
var query = employees.Where(e => e.Salary > 16000);
Console.WriteLine(query.Count());        // 2 —— 此刻才执行（第一次）

employees.Add(new Employee("新来的", "研发", 30000, 30));
Console.WriteLine(query.Count());        // 3 ！又执行了一遍，结果变了
```

- **定义**查询 = 记下"以后这么算"；**枚举**（foreach/Count/ToList...）才真正跑
- 每次枚举**重新执行**——数据变了结果跟着变（新鲜的代价/福利）
- 收益：能组合大查询而中间不留整份中间结果（第 17 章 Where 链 Where 只是叠加条件）；无限序列可消费（第 18 章 Take(3)）

**推论（性能坑）**：同一 query 枚举两次 = 完整跑两遍。要复用结果先 `ToList()` 定格。

## 5. 立即执行：定格的操作符

```csharp
var frozen = employees.Where(e => e.Salary > 16000).ToList();   // 立刻执行、装入列表
employees.Add(...);                                              // 再加人
frozen.Count                                                     // 不变——快照
```

立即执行家族：`ToList/ToArray/ToDictionary/ToHashSet`（收进容器）、`Count/Max/Sum...`（聚合出标量）、`First/Any/Contains`（枚举到答案即停）。**ToList 的三个用途**：定格复用、多次消费、把"查询"变"数据"传出去。

## 6. 匿名类型：Select 的临时形状

`Select(e => new { e.Name, e.Salary })` 里的 `new { }` 是**匿名类型**——编译器生成的临时只读类型，属性名自动推断。它的值相等按内容（record 的近亲）。用途：中间投影的临时形状；出方法边界就得换具名 record（匿名类型名字你写不出来）。

## 常见坑

**多次枚举同一查询**：跑两遍、数据还可能变——复用先 ToList（示例实测演示）。

**First 找不到抛异常**：不确定有就 FirstOrDefault + null 判断（第 21 章 `?.` 配套）。

**聚合空序列**：`Empty.Max()` 抛 InvalidOperationException——用 `DefaultIfEmpty(0).Max()` 或 ...OrDefault。

**Count() vs Any()**：判断"有没有"永远 Any（首个命中即停）；Count 要数完。集合的 `Count` 属性（List）是 O(1)，`Count()` 方法可能 O(n)。

**修改正在枚举的集合**：foreach 里 Add/Remove → InvalidOperationException。先 `ToList()` 再改，或用 for 反向遍历。

**在 Where 里做副作用**（写日志、改状态）：查询可能延迟执行 0 次或 N 次——副作用不可预期。查询保持纯函数。

## 实战建议

- 链式排版（每个操作符一行）——可读性是 LINQ 的卖点，别一行到底
- 管道思维：**过滤要趁早**（Where 放 Select 前，少投影无用的字段；数据源端过滤 > 内存过滤——EF 场景更是天差地别）
- 分页三件套 `OrderBy → Skip → Take` 顺序不能乱（Skip 依赖确定序）
- 调试 LINQ：断点打在 lambda 里看逐项流转；或中间插 `.ToList()` 观察阶段结果
- 每写一条查询，心里标注它是"配方"还是"结果"——延迟执行意识是 LINQ 分水岭

## 自测

1. **方法链与查询语法的关系？** —— 查询语法编译成方法链，等价糖；方法链覆盖更全。
2. **延迟执行的含义与两条推论？** —— 定义时不跑、枚举才跑；多次枚举跑多遍 + 数据变化反映到结果。
3. **First/FirstOrDefault/Single 怎么选？** —— 确定有 / 不确定 / 业务唯一（0 或 ≥2 都抛）。
4. **ToList 的三个用途？** —— 定格复用、多次消费、查询转数据。

---
上一章：[15 Lambda 与闭包](15-lambdas.md) ｜ 下一章：[17 LINQ 进阶](17-linq-advanced.md)
