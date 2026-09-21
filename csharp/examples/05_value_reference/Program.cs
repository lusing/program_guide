// 05 · 值类型与引用类型：赋值的那一刻就分岔了
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 赋值语义：拷贝 vs 别名 =====");

// struct：值类型——赋值 = 整体拷贝，两份独立
var p1 = new Point { X = 1, Y = 2 };
var p2 = p1;
p2.X = 99;
Console.WriteLine($"struct: p1.X = {p1.X}, p2.X = {p2.X}   ← 改 p2 不影响 p1（拷贝）");

// class：引用类型——赋值 = 复制"地址"，两个名字指同一个对象
var c1 = new Coord { X = 1, Y = 2 };
var c2 = c1;
c2.X = 99;
Console.WriteLine($"class : c1.X = {c1.X}, c2.X = {c2.X}   ← c1 也变了（同一个对象）");

Console.WriteLine();
Console.WriteLine("===== 相等性的分岔 =====");
var p3 = new Point { X = 1, Y = 2 };
Console.WriteLine($"struct ==: {p1.Equals(p3)}   ← 值类型按「内容」相等（改 p1 前的坐标）");
var c3 = new Coord { X = 99, Y = 2 };
Console.WriteLine($"class ==: {ReferenceEquals(c1, c3)}   ← 引用类型默认按「身份」（除非重写 Equals，第 11 章 record 免费送）");

Console.WriteLine();
Console.WriteLine("===== 装箱与拆箱 =====");
int number = 42;
object boxed = number;          // 装箱：值类型 → 堆上的 object 包装（分配 + 拷贝）
int unboxed = (int)boxed;       // 拆箱：显式强转取回
Console.WriteLine($"装箱后拆箱: {unboxed}");
Console.WriteLine("  热路径上反复装箱（如把 struct 塞进非泛型集合）是隐形性能杀手——第 12 章泛型消灭它");

Console.WriteLine();
Console.WriteLine("===== 内存布局（心智图）=====");
Console.WriteLine("""
  栈（快，随方法帧回收）          堆（GC 管理）
  ┌──────────────────┐        ┌──────────────────┐
  │ p1  [1, 2]       │        │ c1 ──────────┐   │
  │ p2  [99, 2]      │        │              ▼   │
  │ c1 (引用/地址)────┼───────►│ Coord 对象 [99,2] │
  │ c2 (引用/地址)────┼───────►│   ↑ 同一个        │
  └──────────────────┘        └──────────────────┘
  """);

struct Point { public int X; public int Y; }
class Coord { public int X; public int Y; }
