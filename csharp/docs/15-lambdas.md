# 15 · Lambda 与闭包

> 对应示例：`examples/15_lambdas`

> **本章你将学会**：lambda 的形态、闭包的捕获语义、循环变量捕获的历史陷阱、static lambda、表达式树。
> **前置章节**：[13 委托](13-delegates.md)。

## 1. lambda：方法的字面量

字符串有字面量 `"abc"`，方法也有字面量——lambda：

```csharp
Func<int, int> square = x => x * x;             // 表达式体：一行一件事
Func<int, int, int> add = (a, b) => a + b;      // 多参数必须括号
Action<string> shout = s => { Console.WriteLine(s.ToUpper() + "!"); };   // 语句体要大括号
```

lambda 无需类型声明（从委托变量/参数推断）、无需方法名、写在使用的现场——它让"函数"获得了和 int/string 一样的**就地表达能力**。第 13 章的策略注入、第 16 章的 LINQ 条件全靠它。

三条形态规则：单参数可省括号（`x =>`）；语句体必须 `{ }` 且有 return；类型推断不了时显式标注 `(int x, int y) =>`。

## 2. 闭包：lambda 带走了环境

lambda 不止是代码——它**捕获所在作用域的变量**，连变量带代码打包成闭包：

```csharp
int factor = 10;
Func<int, int> scale = x => x * factor;   // 捕获 factor

factor = 20;                              // 之后再改
scale(5)                                  // 100 ！不是 50
```

关键语义：**捕获的是变量本身，不是创建时的值**。lambda 里用的是"活的 factor"——它和外界的 factor 是同一个存储位置。机制：编译器把被捕获的变量提升到堆上的闭包对象里，内外共享。

闭包的威力：无参数的 `Func<int>` 能"记住"外部状态；柯里化、计数器、缓存都能用几行闭包表达。代价：被捕获的局部变量**从栈搬到堆**（闭包对象）——性能敏感处留意分配。

## 3. 经典陷阱：循环变量捕获

```csharp
var actions = new List<Func<int>>();
for (var i = 0; i < 3; i++)
    actions.Add(() => i);          // 捕获 i

// 现代打印：0 1 2 ✓（C# 5 起：每轮迭代 i 是新变量）
// C# 4 时代打印：3 3 3 ✗（所有 lambda 共享一个 i，循环结束 i=3）
```

语言层已修复（foreach 和 for 均每轮新变量），但**教训永不过时**：闭包捕获变量，如果"每份 lambda 该有独立状态"，就让每份捕获**不同的变量**（老代码的 `var copy = i;` 手法就是人造每轮新变量）。WPF/WinForms 的 UI 循环生成控件回调时仍会踩到变体形态。

## 4. static lambda：禁止捕获

```csharp
Func<int, int> pure = static x => x + 1;    // static 修饰
// static int outer = 10; pure = static x => x + outer;  ← 编译错误！
```

`static lambda` 由编译器**保证不捕获任何变量**——想捕获直接编译错误。价值：意图文档（这是个纯函数）+ 防误捕获（重构成 static 失败时你就知道它偷偷依赖环境了）。工具方法、并行体（第 31 章）里加 static 是好习惯。

## 5. 表达式树：lambda 的"源码"形态

同样一个箭头，两种编译产物：

```csharp
Func<int, int> compiled = x => (x + 1) * 2;                        // 编译成机器码——可执行
Expression<Func<int, int>> tree = x => (x + 1) * 2;                // 编译成数据结构！

tree.ToString()          // "x => ((x + 1) * 2)" —— 语法树可打印
var fn = tree.Compile(); // 数据可以再编译回可执行
fn(10)                   // 22
```

**Expression 是"代码即数据"**：lambda 的结构（参数、运算、嵌套）被存成一棵树。它的用武之地：**EF Core 把它翻译成 SQL**（`Where(u => u.Age > 18)` 变 `WHERE Age > 18`——机器码没法翻译，数据才能）、动态查询拼接、规则引擎。普通业务代码用 `Func`；要**翻译/分析/转发**逻辑时用 `Expression`。

## 6. lambda 的一切使用场景串门

| 场景 | 形态 | 章节 |
|---|---|---|
| 策略参数 | `Sort(list, (a,b) => ...)` | 13 |
| 事件订阅 | `obj.Ev += (s,e) => ...` | 14 |
| LINQ 条件/投影 | `Where(x => ...)`、`Select(x => ...)` | 16-17 |
| 任务体 | `Task.Run(() => ...)` | 29 |
| 线程/并行体 | `Parallel.For(..., i => ...)` | 31 |
| 测试替身 | `new FakeRepo { FindFunc = id => ... }` | 35 |

一个语言机制贯穿现代 C# 全部范式——这章的投资回报率极高。

## 常见坑

**在 lambda 里改外部变量当"返回值"用**：`int result; list.ForEach(x => result += x);`——数据流被藏进闭包，可读性崩坏；要结果用 LINQ 的 Sum 或普通 foreach。

**闭包捕获 this**：实例方法里的 lambda 隐式捕获 this（哪怕只用了一个字段）——整个对象被闭包拖着活。事件订阅 + 闭包 = 泄漏放大器。

**语句 lambda 和表达式 lambda 混淆 Expression**：`Expression<Func<>>` 只能装**表达式体** lambda；`x => { ... }` 语句体装不进（编译错误）——表达式树装不下任意语句。

**多线程下闭包共享变量**：捕获的变量被主线程和 Task 同时读写——竞态（第 30 章专题）。闭包共享 ≠ 线程安全。

**性能热点的闭包分配**：高频路径上 `x => x + _factor` 每次调用可能分配闭包对象——static lambda 或局部函数（零分配）替代。

## 实战建议

- lambda 三行为限：超过就提局部函数或方法——**可读性优先**
- 明确不捕获就加 `static`——白纸黑字的纯函数承诺
- "lambda 里访问了局部变量"时停一秒：想清楚捕获的是谁、活多久、谁还会改它
- Expression 只在需要"翻译"时出现；进程内直接跑的逻辑用 Func（快）
- 惯用名 `x => x.Foo` 的单参数叫 x/item/t——短到不必命名过多

## 自测

1. **闭包捕获的是值还是变量？怎么验证？** —— 变量本身；创建后改外部变量，lambda 结果跟着变。
2. **C# 5 前后的循环捕获行为差异？** —— 旧：共享变量全打印终值；新：每轮新变量。
3. **static lambda 提供什么保证？** —— 编译期禁止捕获（捕获即报错）。
4. **Func 与 Expression<Func> 的本质区别？** —— 机器码（执行）vs 语法树数据（可翻译/分析/再编译）。

---
上一章：[14 事件](14-events.md) ｜ 下一章：[16 LINQ 基础](16-linq-basics.md) ｜ 返回：[README](../README.md)
