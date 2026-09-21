// 09 · 继承与多态：同一句话，各表其意
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 多态：一个基类引用，各自的行为 =====");
List<Shape> shapes = new() { new Circle(2), new Rect(3, 4), new Square(5) };
foreach (var s in shapes)
    Console.WriteLine($"  {s.Name,-8} 面积 {s.Area(),8:F2}");
Console.WriteLine("  同一句 s.Area()，三个类给出三个答案——运行时按真实类型分发（虚方法表）");

Console.WriteLine();
Console.WriteLine("===== abstract：只定义契约，不提供实现 =====");
// var s = new Shape();    // ✘ 抽象类不能实例化——只能被继承
Console.WriteLine("  Shape 是抽象类：Area 必须由子类实现；Name 有默认实现可覆写");

Console.WriteLine();
Console.WriteLine("===== sealed：到此为止，不许再继承 =====");
Console.WriteLine("  Square 标了 sealed——设计定稿、防误用时用它（string 也是 sealed）");

Console.WriteLine();
Console.WriteLine("===== 里氏替换（LSP）：子类必须能无痛顶替父类 =====");
var c = new Circle(1);
Shape asShape = c;             // 向上转型永远安全
Console.WriteLine($"  Circle → Shape 调 Name: {asShape.Name}（子类没削弱父类行为 = 合规）");

Console.WriteLine();
Console.WriteLine("===== object 的虚方法：每个类的隐性基类 =====");
Console.WriteLine($"  ToString(): {new Circle(1)}");
Console.WriteLine($"  Equals(同参): {new Circle(1).Equals(new Circle(1))}   ← 我们重写了；record 更省（第 11 章）");

Console.WriteLine();
Console.WriteLine("===== 隐藏与覆写的区别（new vs override）=====");
Derived d = new();
Base b = d;
Console.WriteLine($"  override: b.Say() = {b.Say()}   ← 虚分发，看真身");
Console.WriteLine($"  new 隐藏: b.Hi() = {b.Hi()}   ← 非虚，看变量类型（隐藏是坑，少用）");

abstract class Shape
{
    public abstract double Area();                   // 抽象成员：子类必须实现
    public virtual string Name => GetType().Name;    // 虚属性：子类可覆写
}

class Circle(double radius) : Shape                  // 主构造函数（C# 12）：参数直接进成员用
{
    public double Radius { get; } = radius;          // 想暴露给外部（含 Equals 比较）就落成属性
    public override double Area() => Math.PI * radius * radius;
    public override string ToString() => $"Circle(r={radius})";
    public override bool Equals(object? obj) => obj is Circle other && other.Radius == Radius;
    public override int GetHashCode() => Radius.GetHashCode();
}

class Rect(double w, double h) : Shape
{
    public override double Area() => w * h;
    public override string Name => "矩形";
}

sealed class Square(double side) : Rect(side, side)
{
    public override string Name => "正方形";
}

class Base
{
    public virtual string Say() => "Base.Say";
    public string Hi() => "Base.Hi";
}

class Derived : Base
{
    public override string Say() => "Derived.Say";
    public new string Hi() => "Derived.Hi";          // new：故意隐藏（不推荐）
}
