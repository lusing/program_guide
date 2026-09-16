# 06 · 泛型与扩展方法：写一次，处处安全

> 对应示例：`examples/06_generics`

## 1. 没有泛型的世界

想写一个"求数组总和"的函数，若类型各写一份，int 一份、long 一份、double 一份……靠 `object` 统一则装箱 + 强转，性能与安全双输：

```csharp
// 前泛型时代的写法——每次调用都装箱，取回都要强转
static object SumObj(object[] values) { /* … */ }
int s = (int)SumObj(new object[] {1, 2, 3});
```

泛型把"类型"变成参数，**一份逻辑 + 编译期类型检查 + 零装箱**。示例的主体是一个现代泛型方法：

```csharp
using System.Numerics;

static T Sum<T>(IEnumerable<T> source) where T : INumber<T>
{
    var total = T.Zero;
    foreach (var item in source)
    {
        total += item;
    }
    return total;
}
```

## 2. 逐块拆开

- `Sum<T>`：`T` 是类型参数，调用时确定——`Sum(new[] {1, 2, 3})` 里编译器**推断** `T = int`，不必手写 `Sum<int>(…)`。
- `IEnumerable<T>`：参数类型本身也用 `T`，"给我任意元素类型的序列"。集合与 LINQ（第 08、09 章）整个建立在 `IEnumerable<T>` 之上。
- `where T : INumber<T>`：**约束**——要求 T 实现 `INumber<T>`（数字抽象接口）。没有它，`total += item` 编译不过：编译器不知道任意 T 支持加法。
- `T.Zero` 与 `+=`：`INumber<T>` 定义了**静态抽象成员**（`static abstract`，C# 11 起的泛型数学机制），让"零是什么""怎么相加"由 T 自己回答。

约束种类速查：

| 约束 | 含义 |
|---|---|
| `where T : class` / `struct` | 引用类型 / 不可空值类型 |
| `where T : new()` | 有无参构造（可 `new T()`） |
| `where T : SomeInterface` / `BaseClass` | 实现接口 / 继承基类 |
| `where T : notnull` / `unmanaged` | 非空 / 非托管内存布局 |
| 多个约束 | `where T : class, IComparable<T>, new()` |

调用端：

```csharp
var sum = Sum(new[] {1, 2, 3, 4, 5});
Console.WriteLine($"sum={sum}");
```

`Sum` 对 `int[]`、`double[]`、`decimal[]`……一切数字序列直接可用——这就是泛型数学的意义：库作者写一次，全部数值类型受益。

## 3. 泛型的三个居住地

泛型不止方法：**类**（`List<T>`、`Dictionary<TKey,TValue>`——BCL 集合全是泛型类）、**接口**（`IEnumerable<T>`、`IEquatable<T>`）、**方法**（本文的 `Sum<T>`）。都可以带约束。日常更多是**消费**泛型而非编写；写自己的泛型时机：工具函数对多种类型做同构逻辑（序列处理、缓存包装、结果类型）。

顺带澄清：泛型的类型实参在运行时**真实存在**（ unlike Java 的类型擦除），`List<int>` 内部真的是紧凑的 int 数组——这是 .NET 泛型零装箱的根基。

## 4. 扩展方法：给别人的类型加方法

示例最后一行：

```csharp
Console.WriteLine(new string("dotnet".Reverse().ToArray()));
```

`"dotnet"` 是 string，BCL 的 string 并没有 `Reverse` 方法——它是 `Enumerable.Reverse<T>` 这个扩展方法"贴"上去的。定义一个扩展方法 = 普通静态方法 + 第一个参数前的 `this`：

```csharp
static class StringExtras
{
    public static string Shout(this string s) => s.ToUpperInvariant() + "!";
}

Console.WriteLine("hi".Shout());   // HI! —— 像实例方法一样调用
```

三条纪律：

- 必须放在**顶级、非泛型的 static 类**里（编译器只在这里找）；
- 本质是 `Shout("hi")` 的语法糖——访问不了目标类型的私有成员；
- **发现性靠 using**：没 using 扩展方法所在的命名空间，点不出来（坑位清单第 2 条）。

LINQ 的全部方法（`Where/Select/OrderBy`……）都是 `System.Linq` 命名空间下的扩展方法——第 09 章的主角，其实是本章机制的最大规模应用。自定义扩展方法实战在第 08 章（给 `List<T>` 加 `PopIfMatch`）。

## 5. 坑位清单

1. **`where T : new()` 的边界**：约束只保证无参构造，不保证有意义的默认状态；值类型默认 `default(T)` 全零。
2. **扩展方法"不见了"**：九成是缺 `using System.Linq;`（或扩展类所在命名空间）——报错是"string 不包含 Reverse 的定义"，具有极强误导性。
3. **运算符与泛型**：C# 11 之前泛型里写不了 `a + b`；`INumber<T>` 等静态抽象接口（.NET 7+）才解决。老代码的泛型数学全靠表达式树或各类型重载。
4. **协变逆变别硬记**：`IEnumerable<out T>` 协变（`IEnumerable<string>` 可当 `IEnumerable<object>` 用）、`List<T>` 不变——容器"只读"才可协变，"可写"必须不变。遇到编译错 CS0266 再回来查这句。
