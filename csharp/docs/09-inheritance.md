# 09 · 继承与多态

> 对应示例：`examples/09_inheritance`

> **本章你将学会**：virtual/override/abstract/sealed 四件套、多态的运行机制、object 的虚方法、隐藏（new）与覆写（override）的区别。
> **前置章节**：[08 类与封装](08-classes.md)。

## 1. 多态：同一句话，各表其意

示例的核心一幕——**基类引用装着不同子类，同一句调用各自行为**：

```csharp
List<Shape> shapes = new() { new Circle(2), new Rect(3, 4), new Square(5) };
foreach (var s in shapes)
    Console.WriteLine($"{s.Name}: {s.Area():F2}");
// Circle: 12.57 / 矩形: 12.00 / 正方形: 25.00
```

`s.Area()` 一句代码，三个类三个答案。机制：**虚方法表（vtable）**——每个对象头部带"我真实类型的函数表"，调用虚方法时按表分发到真身。**编译期看变量类型，运行期看对象真身**——这就是动态分派。

多态的工程价值：调用方（`foreach` 循环）不关心具体类型，**新增形状不改调用方一行代码**——这就是"开闭原则"的语言基础。

## 2. 四件套：virtual / override / abstract / sealed

```csharp
abstract class Shape                        // 抽象类：不能 new，只能被继承
{
    public abstract double Area();          // 抽象成员：无实现，子类必须实现
    public virtual string Name => GetType().Name;   // 虚成员：有默认实现，子类可覆写
}

class Circle(double radius) : Shape         // ": 基类" 建立继承
{
    public override double Area() => Math.PI * radius * radius;   // 必须 override
    public override string Name => "圆";    // 可选覆写
}

sealed class Square(double side) : Rect(side, side) { }   // sealed：到此为止不许再继承
```

| 关键字 | 语义 | 谁写 |
|---|---|---|
| `virtual` | 这个成员**允许**被子类替换 | 基类 |
| `override` | 我要替换基类的虚成员 | 子类（签名必须一致） |
| `abstract` | 只有签名没有实现，**强迫**子类实现 | 基类（类也必须 abstract） |
| `sealed` | 禁止再被子类继承（或：覆写到我为止） | 任何类/成员 |

设计直觉：**没写 virtual 的方法就是"定稿"**——C# 方法默认非虚（与 Java 相反），这是刻意的：非虚调用快、行为可预测。**为扩展点而设计**时才开 virtual。

## 3. 向上转型与里氏替换（LSP）

```csharp
Shape asShape = new Circle(1);    // 向上转型：永远安全，不需要 cast
```

子类对象当基类用——继承链上"是一个"（is-a）关系。**里氏替换原则**：子类必须能无痛顶替父类——不削弱行为、不收紧前置条件、不放松后置条件。反例：`Square : Rect` 的 `set_Width` 会让正方形不再方——经典的设计教训。示例里 Square 覆写了 `Name` 但没破坏 Area 语义，合规。

**C# 单继承**：一个类只能有一个基类（`class Dog : Animal, IPet, IMakeSound` 里 Animal 是唯一的类，后面全是接口——第 10 章）。多重"能做什么"用接口表达。

## 4. object：所有类的隐性基类

不写继承的类都继承自 `object`，它给了三个可覆写的虚方法：

```csharp
ToString()      // 人话描述——调试/日志的门面
Equals(obj)     // 内容相等（默认比引用）
GetHashCode()   // 哈希码——Equals 的孪生兄弟（Equals 相等则哈希必须相等）
```

示例的 Circle 手工重写了三个（约 10 行样板）。**第 11 章的 record 把这 10 行变成 1 行**——这是"数据类用 record"的最强理由。还有一对常用：`GetType()`（运行时真身，第 23 章）、`ReferenceEquals()`（强制比引用）。

## 5. 隐藏（new）与覆写（override）：一字之差天壤之别

```csharp
class Base { public virtual string Say() => "Base.Say"; public string Hi() => "Base.Hi"; }
class Derived : Base
{
    public override string Say() => "Derived.Say";   // 覆写：虚分发
    public new string Hi() => "Derived.Hi";          // 隐藏：新方法遮住旧名
}

Derived d = new();
Base b = d;
b.Say()   // "Derived.Say" ← override 看对象真身
b.Hi()    // "Base.Hi"     ← new 看变量类型！
```

**override 参与 vtable 分发；new 只是同名遮蔽**——用基类引用调用时绕过遮蔽，跑的是基类版本。`new` 几乎总是设计坏味道（调用方行为取决于变量类型），示例用它只为演示差异。看到编译器警告"用 new 隐藏基类成员"时，先想是不是该 override 或改名。

## 6. 组合优于继承（老生常谈但真）

继承表达 **is-a**（猫是动物），组合表达 **has-a**（车有引擎）：

```csharp
class Car { private readonly Engine _engine = new(); }   // 组合
```

继承的代价：子类与基类**深度耦合**（基类改动殃及全部子类）、基类实现细节泄漏给子类。经验法则：**超过两层的继承树就要审视**；想复用代码先想组合/委托，is-a 关系清晰才上继承。

## 常见坑

**忘了 override**：子类写了个同名方法没加 override → 变成隐藏（编译器警告），多态失效——"明明重写了怎么没生效"的元凶。

**抽象类 new 不了**：`new Shape()` 编译错误。抽象类是契约 + 部分实现的半成品，只能 new 它的具体子类。

**Equals 重写了 GetHashCode 忘了**：字典/哈希集合直接失灵（按哈希分桶找不到对象）。两个必须成对。

**调用 base 的时机**：`override` 方法里 `base.Say()` 可复用父类逻辑；忘了调导致父类初始化被跳过（构造链同理）。

**用继承凑代码复用**：Stack 想复用 List 的代码继承 List——is-a 关系是假的，接口语义全歪。复用用组合。

## 实战建议

- 默认非虚；确定是扩展点再 virtual，且给足文档（子类该怎么覆写）
- 数据载体不要继承链——直接 record（第 11 章）；继承留给"行为家族"（不同解析器、不同渲染器）
- 每个类要么有被继承的设计（documented virtual），要么 sealed 封顶——中间态最危险
- 覆写 ToString 顺手，覆写 Equals/GetHashCode 用 record 自动合成

## 自测

1. **多态的运行机制？** —— vtable：对象携带真实类型的函数表，虚调用按真身分发。
2. **virtual/override/abstract/sealed 各自的语义？** —— 允许替换/执行替换/强制实现/禁止再继承。
3. **new 隐藏与 override 的区别？** —— 隐藏按变量类型静态绑定；override 按对象真身动态分发。
4. **为什么说 C# 方法默认非虚是好设计？** —— 调用快、行为可预测、扩展点显式声明。

---
上一章：[08 类与封装](08-classes.md) ｜ 下一章：[10 接口](10-interfaces.md) ｜ 返回：[README](../README.md)
