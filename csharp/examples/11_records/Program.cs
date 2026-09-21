// 11 · 结构体与记录：值语义的现代写法
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 四种数据形态一张图 =====");
Console.WriteLine("  class        引用类型 | 可变为主   | 相等=同一对象");
Console.WriteLine("  record       引用类型 | 不可变为主 | 相等=内容相同（编译器合成）");
Console.WriteLine("  struct       值类型   | 小而快     | 相等=内容相同（可自定义）");
Console.WriteLine("  record struct 值类型 | 不可变为主 | 相等=内容相同 + with/解构全送");

Console.WriteLine();
Console.WriteLine("===== record：一行得到不可变数据类 =====");
var o1 = new Order(1, "张三", 99.9m);
var o2 = new Order(1, "张三", 99.9m);
Console.WriteLine($"  Equals: {o1.Equals(o2)}   ← 内容相等（class 默认是 false，record 免费送）");
Console.WriteLine($"  ToString: {o1}   ← 也是合成的，调试友好");

Console.WriteLine();
Console.WriteLine("===== with：拷贝并改（不可变世界的「修改」）=====");
var upgraded = o1 with { Amount = 199.9m };
Console.WriteLine($"  原单: {o1.Amount}");
Console.WriteLine($"  新单: {upgraded.Amount}（o1 毫发无损）");

Console.WriteLine();
Console.WriteLine("===== 解构：一拆为多 =====");
var (id, name, amount) = o1;
Console.WriteLine($"  var (id, name, amount) = o1 → {id}, {name}, {amount}");

Console.WriteLine();
Console.WriteLine("===== record struct：值语义 + 全套便利 =====");
var p1 = new Pixel(3, 4);
var p2 = new Pixel(3, 4);
Console.WriteLine($"  record struct Equals: {p1.Equals(p2)}（栈上，无堆分配）");
var moved = p1 with { X = 10 };
Console.WriteLine($"  with 后: {moved}（原 {p1}）");

Console.WriteLine();
Console.WriteLine("===== 结构体的适用线 =====");
Console.WriteLine("  ≤16 字节、不可变、拷贝廉价 → struct（Point/DateTime 都这么设计）");
Console.WriteLine("  超过这个量级用 class/record——大 struct 拷贝反而慢");

record Order(int Id, string Customer, decimal Amount);

record struct Pixel(int X, int Y);
