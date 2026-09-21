# 10 · 接口

> 对应示例：`examples/10_interfaces`

> **本章你将学会**：接口契约的思维、显式实现、默认接口实现、IComparable 等系统接口、接口 vs 抽象类。
> **前置章节**：[09 继承与多态](09-inheritance.md)。

## 1. 接口是"能做什么"的契约

继承（第 09 章）回答 **is-a**（是一个什么）；接口回答 **can-do**（能做什么）：

```csharp
interface IPet { string Name { get; } }
interface IMakeSound { string Sound(); }

class Dog(string name) : Animal, IPet, IMakeSound    // 单继承 + 多接口
{
    public string Name { get; } = name;
    public string Sound() => "汪！";
}
```

`Dog` 是 Animal（血统），同时"能当宠物""能发声"（能力）。接口的多重实现补上了 C# 单继承的表达力。**接口引用**与基类引用一样支持多态：

```csharp
IPet pet = dog;          // 只看得见契约里的成员
IMakeSound s = dog;      // 同一个对象的另一张面孔
```

接口的成员天然全是"抽象"的（传统上无实现体），实现类必须全部落地。**它是对消费者的承诺**：拿到 `IPet` 的代码可以放心调 `Name`——不关心背后是 Dog 还是 Cat 还是测试用的 FakePet。这份"背后随便换"的能力是第 35 章可测试性的地基。

## 2. 框架怎么用接口：IComparable 的例子

`Array.Sort` 为什么什么类型都能排？它只依赖一个契约：

```csharp
class Temperature(double celsius) : IComparable<Temperature>
{
    public double Celsius { get; } = celsius;
    public int CompareTo(Temperature? other) => Celsius.CompareTo(other?.Celsius ?? 0);
}

var temps = new List<Temperature> { new(30.5), new(28.1), new(31.0) };
temps.Sort();     // Sort 调 CompareTo——"怎么比"是数据自己的事
```

这就是**框架设计模式**：框架定义契约，你实现契约，框架在合适的时机回调你。常用系统接口速查：

| 接口 | 承诺 | 谁消费 |
|---|---|---|
| `IComparable<T>` | 我知道怎么排序 | Sort、OrderBy |
| `IEquatable<T>` | 我知道怎么算相等 | Contains、Distinct |
| `IEnumerable<T>` | 我能被遍历 | foreach、LINQ 全家（第 16、18 章） |
| `IDisposable` | 我持有要释放的资源 | using（第 25 章） |
| `IFormattable` | 我知道怎么格式化自己 | ToString(fmt, culture) |

## 3. 显式接口实现：撞名时的分流

两个接口有同名成员，或想把这个成员"只给接口视角"用——**显式实现**：

```csharp
interface IPrinter { void Print(string s); }
interface ILaser { void Print(string s); }

class MultiPrinter : IPrinter, ILaser
{
    public void Print(string s) => ...                  // 类自己的公开 Print
    void IPrinter.Print(string s) => ...                // 显式实现：无 public，类型名限定
    void ILaser.Print(string s) => ...
}

printer.Print("普通调用");                        // 类公开版
((IPrinter)printer).Print("...");                 // 必须转接口才能到显式版
```

显式实现**不成为类的公开成员**——只能通过对应接口引用调用。用途：撞名分流、把冷门成员藏进接口视角、让一个类对两个接口呈现不同行为。

## 4. 默认接口实现（C# 8）：慎用的扩展机制

接口成员可以带默认实现：

```csharp
interface ILogger
{
    void Log(string message);                                    // 必须实现
    void Info(string message) => Log($"[INFO] {message}");       // 默认实现
}

class LegacyLogger : ILogger
{
    public void Log(string message) => ...                       // 只写 Log，Info 白得
}

((ILogger)legacy).Info("...");    // 注意：必须通过接口引用调用！
```

设计动机：给老接口加新成员**不破坏已有实现类**（当年 `IEnumerable` 想加方法没这能力，只能 LINQ 扩展方法绕——第 20 章）。代价：接口开始有实现 = 走向"多继承的复杂度"，且默认实现必须通过接口引用调用（类上看不见）。**当"接口加方法的兼容手段"用，别当日常工具**。

## 5. 接口 vs 抽象类：一次说清

| | 接口 | 抽象类 |
|---|---|---|
| 关系语义 | can-do（能力） | is-a（血统） |
| 数量 | 实现任意多个 | 只继承一个 |
| 字段/状态 | 无（只能属性/方法签名） | 有 |
| 构造函数 | 无 | 有 |
| 成员访问修饰 | 默认 public | 任意 |
| 加新成员 | 默认实现才能不破坏 | 加虚成员天然安全 |

选型口诀：**共享代码/有状态 → 抽象类；定义能力/多实现 → 接口**。现实中常常组合：抽象基类放公共实现，接口定义对外契约。

## 6. 依赖倒置：接口的终极价值

```csharp
// 不好的：高层直接依赖低层细节
class OrderService
{
    private readonly SqlOrderRepository _repo = new();   // 换存储要改这里
}

// 好的：双方都依赖抽象
class OrderService(IOrderRepository repo) { ... }        // 注入什么用什么
```

**高层与低层都依赖接口**，互不认识——这个"倒置"让：换实现零成本（测试塞 FakeRepo，第 35 章）、模块可并行开发、部署可拆分。这是 ASP.NET Core 整个生态的架构基石，本仓库 dotnet 教程 16 章的 DI 容器是它的工业化形态。

## 常见坑

**接口 new 不了**：`new IPet()` 编译错误——契约不是实物。new 实现类。

**实现了接口没实现全**：少一个成员编译错误，是好事——契约的完整性由编译器站岗。

**显式实现的成员从类上找不到**：`printer.Print` 看不到显式版——它只在接口视角存在，先转接口。

**默认实现被当基类继承理解**：接口默认实现没有 `base.Xxx()` 那样的复用通道（要调 `((ILogger)this).Info(...)`），设计复杂度陡增——简单场景直接抽象类。

**为"可能用到"造接口**：只有一个实现且无测试替身需求的类，直接类就好——接口是成本（多一层间接），先痛后抽象。

## 实战建议

- 设计 API 的对外参数/返回值优先接口类型（`IEnumerable<T>` 而非 `List<T>`）——给调用方最大自由，也防住"返回内部 List 被外部改"的事故
- 接口按能力拆小：IPet + IMakeSound 优于 IPetThatMakesSound——小契约可自由组合
- 命名：能力用 I 动词/名词（IDisposable、IComparable）；查询/断言用 Can/Has/Is 前缀
- 一个接口一个成员也没问题（IDisposable 就一个）——小而准好过大而空

## 自测

1. **接口与抽象类各自的表达对象？** —— can-do 能力契约（多实现）vs is-a 血统（共享代码与状态）。
2. **显式实现什么时候用？调用方式？** —— 接口撞名/藏成员；只能通过接口引用调用。
3. **默认接口实现解决什么问题？代价？** —— 老接口加成员不破坏实现类；引入实现复杂度且必须接口引用调用。
4. **"双方依赖抽象"带来什么？** —— 实现可替换（测试替身）、模块解耦、并行开发。

---
上一章：[09 继承与多态](09-inheritance.md) ｜ 下一章：[11 结构体与记录](11-records.md)
