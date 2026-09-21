// 19 · 模式匹配：类型测试 + 解构 + 条件的合体语法
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== is 的进化：测试 + 声明 + 属性一次完成 =====");
object[] values = { 42, "hello", new Point(3, 4), null };
foreach (var v in values)
{
    // is + 模式的组合判断
    var desc = v switch
    {
        int n when n > 100 => "大于 100 的 int",
        int n              => $"int: {n}",
        string { Length: 0 } => "空字符串（属性模式）",
        string s           => $"string: {s}（长度 {s.Length}）",
        Point { X: 0, Y: 0 } => "原点（属性模式精确匹配）",
        Point p            => $"Point({p.X},{p.Y})",
        null               => "null",
        _                  => "其他",
    };
    Console.WriteLine($"  {desc}");
}

Console.WriteLine();
Console.WriteLine("===== switch 表达式：关系模式与逻辑模式 =====");
static string Classify(int score) => score switch
{
    < 0 or > 100 => "非法分数",              // 关系模式 + or
    >= 90        => "优秀",
    >= 60 and < 90 => "及格",                // and 组合
    0            => "零分",
    _            => "不及格",
};
foreach (var s in new[] { 95, 70, 0, -5, 120 })
    Console.WriteLine($"  {s,4} → {Classify(s)}");

Console.WriteLine();
Console.WriteLine("===== 位置模式：按 Deconstruct 匹配 =====");
static string WhereAmI(Point p) => p switch
{
    (0, 0)   => "原点",
    (0, _)   => "在 y 轴上",                  // _ 丢弃该位置
    (_, 0)   => "在 x 轴上",
    (var x, var y) => $"一般位置 ({x},{y})",  // var 捕获该位置
};
Console.WriteLine($"  {WhereAmI(new Point(0, 0))}；{WhereAmI(new Point(0, 5))}；{WhereAmI(new Point(3, 4))}");

Console.WriteLine();
Console.WriteLine("===== 列表模式（C# 11）：匹配序列形状 =====");
static string Describe(int[] a) => a switch
{
    []            => "空数组",
    [var single]  => $"只有一个 {single}",
    [var first, .., var last] => $"首 {first} 尾 {last}（共 {a.Length} 个）",   // .. 切片模式
    _ => "其他",
};
var single = new[] { 7 };
var several = new[] { 1, 2, 3, 4 };
Console.WriteLine($"  {Describe(Array.Empty<int>())}");
Console.WriteLine($"  {Describe(single)}");
Console.WriteLine($"  {Describe(several)}");

Console.WriteLine();
Console.WriteLine("===== 模式匹配替代成串的 if-as =====");
Shape shape = new Circle(2);
if (shape is Circle { Radius: > 1 } big)     // 一行完成：类型测试 + 属性条件 + 命名
    Console.WriteLine($"  大圆，面积 {big.Area():F2}");
else
    Console.WriteLine("  不是大圆");
Console.WriteLine("  老写法要 4 行：is Circle c && c.Radius > 1 && (big = c) != null …");

readonly record struct Point(int X, int Y);

abstract class Shape { }
sealed class Circle(double radius) : Shape
{
    public double Radius { get; } = radius;
    public double Area() => Math.PI * Radius * Radius;
}
