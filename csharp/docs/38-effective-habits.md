# 38 · Effective C#·语言习惯（条 1-10）

> 对应示例：`examples/38_effective_habits`

> **本章你将学会**：《Effective C#（第 3 版）》第 1 章的十条日常写法军规——var 的判据、readonly vs const 的跨程序集陷阱、is/as 与强转的语义差、插值字符串与区域文化、nameof、多播委托的两个坑、null 条件触发事件、装箱的隐匿处、new 修饰符。
> **前置章节**：[03 变量与运算符](03-variables-operators.md)、[05 值与引用](05-value-reference.md)、[06 字符串](06-strings.md)、[13 委托](13-delegates.md)、[14 事件](14-events.md)。

第 36 章之前，本教程把语言机制讲完了；37-42 章是「书本篇」——按四本参考书扩充的进阶内容。本章对应《Effective C#》第 1 章：**这些条目不讲新语法，讲的是「同一件事的两种写法，哪种在真实工程里不咬人」**。

## 1. 条 1：优先 var，不是总是 var

var 的收益是「注意力放在语义」：`jobsQueuedByRegion` 这个名字已经把用途说清了，写全 `Dictionary<int, Queue<string>>` 不增加信息。但有两条边界：

**数值变量别用 var**——隐式数值转换会让结果随右边类型悄悄变：

```csharp
var f = GetMagicNumber();      // 返回类型 int/float/double/decimal，total 结果各不相同
var total = 100 * f / 6;       // f 是 int 时整数除法砍掉小数——var 掩盖了这个变化
```

**查询结果的类型影响执行方式**（书里最重要的例子）：把 `IQueryable<string>` 查询结果声明成 `IEnumerable<string>` 能编译（前者继承后者），但后续 Where 从 `Queryable.Where`（翻译成 SQL 远程执行）降级成 `Enumerable.Where`（把数据全拉回本地过滤）——性能差一个数量级且无任何警告。用 var 让编译器保留最强的类型。

> 判据一句话：**读者必须看到类型才能读懂 → 写出类型；否则 var**。

## 2. 条 2：考虑用 readonly 代替 const

两种常量的机制完全不同：

| | `const` | `static readonly` |
|---|---|---|
| 绑定时机 | 编译期 | 运行期 |
| 值的限制 | 基元类型/字符串/null | 任意类型，可算出来 |
| 存在形式 | **字面量嵌入调用方的 IL** | 引用读取 |
| 跨程序集 | 改了值只重发库 DLL → **调用方还用旧值** | 新值立即生效 |
| 语义 | 改 public const = 改接口 | 改 readonly = 改实现 |

**两程序集实测**（.NET 10；复现方法：建 Infra/App 两个工程，App 引用 Infra，改 Infra 常量后只重编 Infra 并覆盖其 DLL，再运行 App）：

```text
库 Infra.dll：const int EndValue = 10; static readonly int StartValue = 1;
App 引用后输出: 1 2 3 4 5 6 7 8 9

改库为 EndValue = 15; StartValue = 2; 只重编+重发 Infra.dll，不重编 App:
App 再运行输出: 2 3 4 5 6 7 8 9     ← StartValue 生效(从2开始)，EndValue 仍旧值10！
```

循环从 2 开始（readonly 新值生效）却仍停在 9（const 的 10 被编进了 App 的 IL）。**const 只该用于：attribute 参数、switch case 标签、enum 定义、确实永不变的值**（如数学常数）。其余场景，包括「版本号」「限额」这类看起来像常量的东西，一律 readonly。

## 3. 条 3：is / as 优先于强制转换

三种转换方式的语义差异（比「语法长短」重要得多）：

```csharp
object o = Factory.GetObject();
var t1 = o as MyType;              // 失败 → null，不执行用户转换运算符
var t2 = (MyType)o;                // 失败 → InvalidCastException；可能走用户转换（按编译期类型找）
if (o is MyType t3) { ... }        // 判断+转换+绑定变量一步完成（现代写法）
```

实测要点（示例 38 第 3 节）：

- `SecondType` 里定义了到 `MyType` 的转换运算符，但 `(MyType)(object)secondType` **照样炸**——强转按**编译期类型**（object）找转换运算符，找不到就直接按运行时类型做引用转换，二者无继承关系 → 异常。用户转换运算符只在**编译期已知双方类型**时才参与
- **as 不能用于非空值类型**（int 装不下 null）——值类型判转用 `is int x` 模式匹配
- **foreach 对非泛型 IEnumerable 用的是 cast 不是 as**——元素类型不匹配当场炸
- `Enumerable.Cast<double>()` 同理是 cast：int 序列 `Cast<double>()` 运行时失败，得 `Select(x => (double)x)`（数值转换不是引用转换，Cast 不做）
- 要判断「恰好是这个类型而不是子类」用 `GetType() == typeof(X)`；`is`/`as` 遵循多态

## 4. 条 4：用内插字符串取代 string.Format

插值把表达式直接写进洞里，静态可查（序号与参数数量错位这种运行时错误不存在了）。三个进阶点：

```csharp
Console.WriteLine($"{count * 100 + 5:C0}");          // 格式说明符
Console.WriteLine($"{(count > 2 ? "多" : "少")}");    // 条件表达式必须括号（冒号歧义）
Console.WriteLine($"{(count > 2 ? $"{user} 太多了" : "刚好")}");  // 可以嵌套
```

**两个警告**：①洞里的值类型会装箱进 `params object[]`（热路径上手工 `ToString()`，见条 9）；②**插值不产生参数化 SQL**——洞里的值直接拼进字符串，拿它拼 SQL 依然注入。

## 5. 条 5：FormattableString 处理区域敏感输出

插值字符串的类型由**目标类型**决定：

```csharp
string s = $"价格 {price:N2}";                    // 立即按当前文化格式化
FormattableString fs = $"价格 {price:N2}";         // 保留「格式串+参数」，延迟格式化
```

示例实测同一个 `fs` 输出：默认文化 `1,234.56`，de-DE `1.234,56`（小数点变逗号）。需要**跨区域输出**（多语言报表）或**给机器解析**（用 `FormattableString.Invariant` 防本机文化干扰）时才用它——平时直接 string 更省。两个细节：给方法传参时别写 `string` 重载（编译器会优先选 string 版本）；`fs` 别做成扩展方法调用（点号左侧会强制生成 string）。

## 6. 条 6：nameof 消灭「名字当字符串」

```csharp
throw new ArgumentNullException(nameof(value));    // 重命名时重构工具连这里一起改
PropertyChanged?.Invoke(this, new(nameof(Name)));  // INPC 标配
```

`nameof(System.Int32.MaxValue)` 返回 `MaxValue`——**总是局部名**。凡是「符号名字写成硬字符串」的地方（异常参数、特性参数、INPC、路由名）都该换：静态分析器由此能校验参数位置错误。

## 7. 条 7：委托表示回调——多播的两个坑

所有委托都是多播委托，`+=` 挂多个目标后有**两个陷阱**（示例实测）：

```csharp
Func<bool> chain = CheckUser;      // 返回 true
chain += CheckCache;               // 返回 false
var result = chain();              // false ← 只取最后一个目标的返回值！
// 且某个目标抛异常 → 后面的目标全部不执行
```

正解：关键场合**手动遍历委托列表**，自己收集返回值、自己包异常：

```csharp
foreach (Func<bool> target in chain.GetInvocationList())
{
    try { results.Add(target()); }
    catch (Exception ex) { /* 记日志，链不断 */ }
}
```

事件处理程序（第 14 章）是同一件事：触发方要假设任意订阅者抛异常。

## 8. 条 8：用 ?.Invoke() 触发事件

```csharp
Updated?.Invoke(this, counter);    // C# 6+ 标准写法
```

旧三行写法（拷快照、判空、调用）防的是「判空之后、调用之前别的线程退订置 null」的竞态。`?.` 左侧**只求值一次**，语义等价（同样是快照），一行写完。没有订阅者时事件字段是 null，直接 `Updated(this, e)` 会 NullReferenceException——这是新手最常见的事件崩溃。

## 9. 条 9：装箱的隐匿处

第 05 章讲过装箱的机制与代价；这条给**三个隐匿触发点**：

1. **插值字符串**：`$"{firstNumber}"` 的值类型被装箱进 object 数组（条 4 的警告）
2. **非泛型集合/接口**：`ArrayList`、`IEnumerable`（非泛型版）
3. **值类型调接口方法**：`IEquatable<Point> boxed = p1;` ——接口引用装箱

另一个实测：`List<Point>` 不装箱，但**取出即拷贝**——`list[0].Bump()` 改不动元素（改的是副本），`foreach` 里改可变 struct 同理。**书的推论：把值类型设计成不可变**（这也是 record struct 存在的理由之一）。

## 10. 条 10：new 修饰符的唯一合法场景

```csharp
BaseWidget w = new MyWidget();     // MyWidget 里 new 隐藏了 Normalize()
w.Normalize();                     // 基类版本
((MyWidget)w).Normalize();         // 子类版本 ← 同一个对象，两种行为！
```

new 不是 override——非虚方法静态绑定，行为随「引用的编译期类型」变。示例实测确认了这个分裂行为。它只该用于一种场景：**新版基类塞进了与你现有子类成员重名的方法**（你无法改基类，改名子类成员代价太大）。即便如此也是权宜之计——能改名就改名。

## 常见坑

**数值变量用 var 掩盖整除**：`var x = a / b` 随右边类型变语义——数值显式声明类型。

**把 const 用于会随版本演进的值**：重发库 DLL 后调用方拿着旧字面量跑（第 2 节实测）。

**强转「定义了转换运算符」的类型失败还纳闷**：运算符按编译期类型匹配，`(MyType)(object)second` 不走你的运算符（第 3 节）。

**多播委托拿返回值**：只有最后一个目标的返回值生效（第 7 节）。

**在插值洞里写 `\"`**：非逐字插值字符串的洞里不能放转义引号——先提取变量再插值（本教程写示例时实测撞过，编译器报 CS8076）。

## 实战建议

- 团队规范可以定成：**数值显式、查询用 var、其余随意但名字要表意**
- 所有「对外常量」默认 readonly，const 留给 attribute/case 标签/enum
- 转换一律先想 `is` 模式匹配，`as` 处理引用类型，强转只留给「确信不会失败」（失败即 bug）
- 事件触发统一 `?.Invoke`；关键回调链手动 GetInvocationList 分派
- 值类型默认不可变（record struct），可变 struct 的每个「取出」都是拷贝陷阱

## 自测

1. **const 与 readonly 跨程序集的行为差异及原因？** —— const 字面量嵌入调用方 IL（改了要全员重编），readonly 运行期按引用读（重发即生效）。
2. **强转什么时候不走用户定义的转换运算符？** —— 源的编译期类型与目标类型之间没有该运算符时（如经 object 中转）。
3. **多播委托的两个坑与解法？** —— 返回值只取最后、异常断链；GetInvocationList 手动分派。
4. **?.Invoke 与「判空后调用」的等价性在哪？** —— 左侧只求值一次 = 拷贝快照语义，线程安全等价。
5. **装箱的三个隐匿处？** —— 插值字符串的 object 数组、非泛型集合、值类型转接口引用。

---
上一章：[37 集合体系与选型](37-collections.md) ｜ 下一章：[39 Effective C#·初始化与生命周期](39-effective-lifecycle.md) ｜ 返回：[README](../README.md)
