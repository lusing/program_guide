// 04_oop：类、继承、接口、多态——C# 的面向对象骨架
var shapes = new List<Shape>
{
    new Circle("c1", 2.0),
    new Square("s1", 3.0),
};

foreach (var s in shapes)
{
    Console.WriteLine(s.Describe());   // 多态：同一次调用，各自执行自己的实现
}

Report(shapes[0], new ConsoleLogger());   // 依赖接口而非具体类

var p = new Point(3, 4);                  // struct：值类型，赋值即复制
Console.WriteLine($"point={p}");

Counter.Count = 0;                        // 静态成员属于类型本身
Counter.Increment();
Console.WriteLine($"counter={Counter.Count}");

static void Report(Shape shape, ILogger logger)
{
    logger.Log(shape.Describe());
}

interface ILogger                          // 接口：只规定"能做什么"
{
    void Log(string message);
}

sealed class ConsoleLogger : ILogger       // sealed：这个类不允许再被继承
{
    public void Log(string message) => Console.WriteLine($"[log] {message}");
}

abstract class Shape(string name)          // 主构造函数（C# 12）
{
    public string Name { get; } = name;    // 只读自动属性

    public abstract double Area { get; }   // 抽象成员：子类必须实现

    public virtual string Describe() => $"{Name}: area={Area:F2}";   // 虚方法：子类可覆盖
}

class Circle(string name, double radius) : Shape(name)   // 用 base 的主构造函数链
{
    public override double Area => Math.PI * radius * radius;

    public override string Describe() => $"[圆] {base.Describe()}";   // base. 调用父类实现
}

sealed class Square(string name, double side) : Shape(name)
{
    public override double Area => side * side;
}

struct Point(int x, int y)                 // 结构体：小而不可变的值对象
{
    public int X { get; } = x;
    public int Y { get; } = y;
    public override string ToString() => $"({X},{Y})";
}

static class Counter                       // 静态类：不能实例化，只放静态成员
{
    public static int Count { get; set; }

    public static void Increment() => Count++;
}
