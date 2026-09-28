# 39 · Effective C#·初始化与生命周期（条 11-17）

> 对应示例：`examples/39_effective_lifecycle`

> **本章你将学会**：对象构造的 8 步顺序、字段初始化器的三个例外、静态成员的三种初始化方式与 TypeInitializationException、构造链 this(...) 与默认参数的取舍、少造无谓对象的三个手段、以及「构造函数里调用虚函数」为什么是灾难。
> **前置章节**：[08 类与封装](08-classes.md)、[09 继承](09-inheritance.md)、[25 GC 与内存管理](25-gc.md)。

《Effective C#》第 2 章讲 .NET 资源管理。其中条 11（GC 心智模型）和条 17（标准 Dispose 模式）本教程已在 [25 章](25-gc.md)展开——本章专注剩下的条 12-16：**初始化的顺序、重复的删法、分配的克制**。这些都是「写类的时候每天都要做的小决定」。

## 1. 对象构造的 8 步顺序（一切的原点）

构建某类型的**第一个**实例时，CLR 依次执行：

1. 静态字段清零
2. 静态字段初始化器执行
3. 基类静态构造函数
4. 本类静态构造函数
5. 实例字段清零
6. **本类实例字段初始化器执行**
7. 基类实例构造函数
8. 本类实例构造函数

之后的新实例从第 5 步开始（静态只来一次）。

这张表里最容易忽视的是 **⑥ 先于 ⑦**：派生类的字段初始化器在基类构造函数**之前**跑。示例实测印证（InitOrder/VirtualDerived 的输出行序），而它是第 6 节灾难的根源。

## 2. 条 12：字段声明处直接初始化

```csharp
public class Widget
{
    private readonly List<string> labels = new();   // 每个构造函数自动带上这段
    public Widget(string name) { labels.Add(name); }
    public Widget(string name, int extra) { labels.Add(name); labels.Add($"extra{extra}"); }
}
```

初始化器被编译器放进**每个**构造函数开头——将来加新构造函数不会忘初始化。三个例外（写了反而错/白写）：

1. **初始化为 0/null**：CLR 本来就清零（第 1/5 步），再写是重复劳动（`= 0` 还好，`= null` 走 initobj 多一次指令）
2. **各构造函数初始化方式不同**：示例实测 `WidgetTwo`——声明处 new 了一个 List，带 size 的构造函数又 new 一个替换它，头一个白建（垃圾多一件）。修法：**删初始化器，构造函数全部 this(...) 链到主构造函数**
3. **初始化可能抛异常**：初始化器无法 try/catch——挪进构造函数处理

## 3. 条 13：静态成员的三种初始化方式

```csharp
public static class Config
{
    public static readonly string Default = "default.json";   // ① 简单赋值：初始化器
    public static readonly string Loaded = LoadOrDefault();    // ② 复杂逻辑放静态方法（可 try/catch）
}
static Broken() => throw new InvalidOperationException(...); // ③ 静态构造函数（显式控制时机）
```

静态构造函数在「首次访问该类型的任何成员」前由 CLR 调用，每个类最多一个、不能带参。**它的异常是核弹**——示例实测：

```text
Broken.Once → TypeInitializationException（包裹真实异常）
且该类型在本次进程中永久不可用——CLR 不会再试第二次静态构造函数
```

昂贵的初始化用 `Lazy<T>` 推迟（示例实测 `IsValueCreated` 从 False 到 True 的翻转），线程安全由它管。单例的两种写法（静态初始化器版 / Lazy 版）都由此派生。

## 4. 条 14：构造链删减重复，而不是复制粘贴

多个构造函数共用逻辑时，**全部 `this(...)` 链到一个主构造函数**：

```csharp
public class Chain
{
    public Chain() : this("anonymous") { }
    public Chain(string name) : this(name, 0) { }
    public Chain(string name, int count) { Name = name; Count = count; }   // 主构造函数
}
```

为什么**不用私有辅助方法**（C++ 老习惯）？两个实测可验证的差距：

- **效率**：辅助方法版里每个构造函数都重复执行「字段初始化器 + 调基类构造函数」；链式版编译器只在**链尾**做一次
- **能力**：`readonly` 字段只能在构造函数（或初始化器）里赋值——辅助方法赋不了

C# 12 的主构造函数（`class Chain(string name, int count)`）是这套惯例的语言化。

**默认参数**能进一步收缩构造函数数量，但记住两件事（书反复强调）：

- 默认值嵌进**调用点**（同条 2 的 const 语义）——改默认值要重编所有调用方
- `where T : new()` 只认**显式**无参构造——全默认参数不算数，想被泛型 new 出来就得显式写一个无参版本
- 默认值必须是编译期常量：`""` 可以，`string.Empty` 不行（静态属性）

## 5. 条 15：不创建无谓的对象

GC 很高效，但「分配 + 回收」本身就是成本。示例实测（.NET 10，200000 次循环）：

```text
循环内 new int[8]：37526 ticks
复用同一数组：      2013 ticks     ← 18 倍差距
```

书的三个手段：

1. **频繁例程里的局部引用对象提升为成员**（paint handler 里的 Font 是书的经典例子）
2. **常用实例做静态共享**（`Brushes.Black` 的惰性缓存思路：首次创建后反复返回同一个）
3. **不可变类型配 builder**：String 不可变 → StringBuilder 可变积累 → 一次成型

字符串版实测（2000 次拼接）：`+=` 循环 9790 ticks，StringBuilder 503 ticks——每个 `+=` 都新建 string（旧的成垃圾）。少量拼接用插值字符串（编译器优化成 `string.Concat`），**循环里**才上 StringBuilder。

## 6. 条 16：绝对不在构造函数里调用虚函数

```csharp
public class VirtualBase
{
    public readonly string BaseSaw;
    public VirtualBase() => BaseSaw = VFunc();          // 反面教材
    public virtual string VFunc() => "VFunc in Base";
}
public sealed class VirtualDerived : VirtualBase
{
    private readonly string _msg = "Set by initializer";  // ⑥
    private readonly string? _final;
    public VirtualDerived() => _final = "Constructed in Derived";  // ⑧
    public override string VFunc() => _msg;
}
```

示例实测输出：`BaseSaw == "Set by initializer"`，而 `_final` 最终是 `"Constructed in Derived"`——**基类构造函数读到的永远是派生类的半成品**。

对照第 1 节的顺序就明白：基类 ctor（⑦）跑的时候，派生字段初始化器（⑥）已执行、派生构造函数（⑧）还没跑——虚分派又按运行时类型走到 `VirtualDerived.VFunc()`。C++ 里同样代码直接崩溃（纯虚调用），C# 只是「不崩但读到半吊子状态」，更隐蔽。FxCop/分析器会报此模式；**需要「构造后钩子」就显式两阶段**（构造完再调 Initialize/工厂方法）。

## 7. 条 11 / 17 与第 25 章的分工

资源管理的完整图景（GC 只管内存、IDisposable + using 管非托管、终结器是兜底、标准 Dispose 模板）在 [25 章](25-gc.md)第 2-4 节——本章不再重复。一句话衔接：**25 章讲「怎么释放」，本章讲「怎么少产生需要释放的东西」**。

## 常见坑

**基类构造函数里调虚函数读到怪值**：⑥先于⑦的顺序 + 虚分派（第 6 节），改成两阶段初始化。

**静态构造函数抛异常后整个类型不可用**：TypeInitializationException 且不再重试——静态初始化必须能兜住自己的异常。

**字段初始化器 + 构造函数里再赋值**：白建一个对象（第 2 节例外②），初始化方式有分化的字段别用初始化器。

**把 InitAll 辅助方法当构造链用**：readonly 赋不了、基类构造函数重复调（第 4 节）。

**热路径里反复 new 同构对象**：分配本身是成本（第 5 节 18 倍实测）——提升为成员或静态缓存。

## 实战建议

- 默认动作：字段能就地初始化就就地（除三个例外）；多个构造函数一律 this(...) 链式
- 静态成员：简单赋值用初始化器，复杂/可能失败的逻辑放静态方法并在里面 try/catch，昂贵的用 Lazy<T>
- 循环里的字符串拼接必上 StringBuilder；非字符串对象看实测数据再优化（别猜）
- 任何「构造期间的行为」都问一句：此时派生类初始化完了吗？

## 自测

1. **8 步顺序里最容易出事故的相对位置？** —— 派生字段初始化器（⑥）先于基类构造函数（⑦）。
2. **字段初始化器的三个例外？** —— 0/null 白写、按构造函数分化、可能抛异常。
3. **静态构造函数异常的后果？** —— TypeInitializationException 包裹 + 类型在进程中永久不可用。
4. **构造链 vs 私有辅助方法，两个硬差距？** —— 基类构造函数/初始化器只在链尾执行一次；readonly 只有构造函数能赋。
5. **为什么要记住「分配也是成本」？** —— new + GC 回收都有价（18 倍实测差距），热路径少造对象。

---
上一章：[38 Effective C#·语言习惯](38-effective-habits.md) ｜ 下一章：[40 Effective C#·泛型设计](40-effective-generics.md) ｜ 返回：[README](../README.md)
