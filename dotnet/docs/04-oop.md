# 04 · 面向对象：类、继承、接口与多态

> 对应示例：`examples/04_oop`

## 1. 多态解决什么问题

假设程序要处理一批图形，每个图形会报告自己的面积。没有继承的写法是 `if (类型 == 圆) … else if (类型 == 方) …`——每加一种形状，所有调用点都要改。面向对象的核心收益：**调用方只依赖抽象，新增实现不动调用方**。示例的主线就是这一段：

```csharp
var shapes = new List<Shape>
{
    new Circle("c1", 2.0),
    new Square("s1", 3.0),
};

foreach (var s in shapes)
{
    Console.WriteLine(s.Describe());   // 多态：同一次调用，各自执行自己的实现
}
```

`s.Describe()` 一行代码，圆执行圆的实现、方执行方的实现——运行时按对象的**实际类型**分发。下面把支撑这件事的每一块拆开。

## 2. 类与成员：属性是主角

```csharp
abstract class Shape(string name)          // 主构造函数（C# 12）
{
    public string Name { get; } = name;    // 只读自动属性

    public abstract double Area { get; }   // 抽象成员：子类必须实现

    public virtual string Describe() => $"{Name}: area={Area:F2}";   // 虚方法：子类可覆盖
}
```

三个要点：

- **属性（property）不是字段**：`Name { get; }` 是一对 get/set 方法的语法糖，外部读起来像字段。可以只 get（只读）、可以 get/set、可以在 set 里做校验——**对外暴露状态用属性，类内部私有状态用字段**，这是 C# 的硬惯例（Java 的 getXxx/setXxx 在这里不存在）。
- **主构造函数（C# 12）**：`class Shape(string name)` 把构造参数直接挂到类头，参数在类的整个声明体内可用。等价于老写法"构造函数 + 赋值给字段/属性"，但省掉三行样板。工程里新旧写法并存，看到都要认识。
- `{ get; } = name;` 把主构造参数固化成只读属性——比捕获参数本身更明确（坑位清单第 4 条）。

## 3. 继承四件套：virtual / override / abstract / sealed

| 修饰 | 谁用 | 语义 |
|---|---|---|
| `virtual` | 父类 | 允许（但不强制）子类覆盖 |
| `abstract` | 父类 | 强制子类实现（类因此不能实例化） |
| `override` | 子类 | 覆盖父类的 virtual/abstract 成员 |
| `sealed` | 类或 override | 到此为止，不允许再继承/再覆盖 |

```csharp
class Circle(string name, double radius) : Shape(name)   // 用 base 的主构造函数链
{
    public override double Area => Math.PI * radius * radius;

    public override string Describe() => $"[圆] {base.Describe()}";   // base. 调用父类实现
}

sealed class Square(string name, double side) : Shape(name)
{
    public override double Area => side * side;
}
```

- `Circle(...) : Shape(name)` 把自己的构造参数转交给父类——构造链必须通到最顶层。
- `base.Describe()` 在覆盖中调用父类版本，做增量定制（圆在标准描述前加了标签）。
- `Square` 标了 `sealed`：意图是"方就是方"，谁也别再派生。C# 默认允许继承、鼓励在明确时 `sealed`——与 Java 的默认 final 相反，团队约定比语言更重要。

`Area` 是**抽象属性**——属性也能 abstract/virtual，不只方法。这让 Shape 的子类契约完整：有名字、有面积、能自我描述。

## 4. 接口：能做什么

```csharp
interface ILogger                          // 接口：只规定"能做什么"
{
    void Log(string message);
}

sealed class ConsoleLogger : ILogger       // sealed：这个类不允许再被继承
{
    public void Log(string message) => Console.WriteLine($"[log] {message}");
}
```

示例的调用方只认接口：

```csharp
static void Report(Shape shape, ILogger logger)
{
    logger.Log(shape.Describe());
}

Report(shapes[0], new ConsoleLogger());   // 依赖接口而非具体类
```

接口 vs 抽象类：

| | 接口 | 抽象类 |
|---|---|---|
| 表达 | 能力（can-do） | 分类（is-a） |
| 一个类能要几个 | 多个 | 一个 |
| 能带实现/状态 | C# 8 起可有默认实现，无字段 | 都可以 |
| 典型用途 | `ILogger`、`IEnumerable<T>` | `Shape` 这类共享骨架的家族 |

判据：多个不相关类型都具备同一能力 → 接口；一族类型共享部分实现 → 抽象类。第 18 章测试一章会再吃一次接口的红利（FakeLogger 靠它替换真实现）。

## 5. struct：值类型的轻量对象

```csharp
struct Point(int x, int y)                 // 结构体：小而不可变的值对象
{
    public int X { get; } = x;
    public int Y { get; } = y;
    public override string ToString() => $"({X},{Y})";
}
```

class vs struct 的分界：

| | class | struct |
|---|---|---|
| 语义 | 引用（拷贝的是地址） | 值（拷贝的是内容） |
| 存活 | 堆 + GC | 通常栈 / 内联在调用者里 |
| 何时用 | 默认 | 小（≤16 字节左右）、不可变、短命：坐标、复数、金额 |

C# 的 struct 不是 C 那种裸内存——它能带属性、方法、实现接口，是"值语义的迷你类"。`int`、`double`、`bool` 本身就是 struct，所以 `3.ToString()` 合法。性能视角在第 15 章（栈分配）会回来。

## 6. static：属于类型本身

```csharp
static class Counter                       // 静态类：不能实例化，只放静态成员
{
    public static int Count { get; set; }

    public static void Increment() => Count++;
}
```

静态成员挂在类型上而非实例上，全进程共享一份。静态类（`static class`）则是"只有静态成员"的容器，常用于工具方法集（第 08 章的扩展方法类必须声明为 static）。滥用静态状态是可测性杀手（第 18 章），示例里 `Counter.Count = 0;` 的重置正是那种别扭感的演示——状态该归属实例时别放进 static。

## 7. 坑位清单

1. **`new` 隐藏 vs `override`**：子类方法没写 `override` 而签名相同，是**隐藏**（编译器警告 CS0114/CS0108）——父类引用调用时仍执行父类版本，多态悄悄失效。看到警告立刻修。
2. **构造链漏传**：父类没有无参构造时，子类构造必须显式 `: base(...)`，否则编译错。
3. **struct 可变的坑**：可变 struct 在只读上下文/属性返回值上修改会静默丢失（改的是副本）。struct 一律做成不可变。
4. **主构造参数的生存期**：主构造参数若只在构造期间用（赋给属性），别让编译器把它捕获成隐藏字段——显式赋给属性（如 `{ get; } = name;`）意图更清楚。
5. **abstract 类里的抽象属性忘了实现**：报 CS0534，提示会点名缺哪个成员，照补即可。
