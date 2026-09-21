// 15 · Lambda 与闭包：函数值捕获了它的环境
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== lambda 的形态 =====");
Func<int, int> square = x => x * x;                    // 表达式体
Func<int, int, int> add = (a, b) => a + b;            // 多参数必须带括号
Action<string> shout = s =>
{                                                      // 语句体：要大括号
    Console.WriteLine($"  {s.ToUpper()}!");
};
Console.WriteLine($"  square(5) = {square(5)}, add(2,3) = {add(2, 3)}");
shout("hello lambda");

Console.WriteLine();
Console.WriteLine("===== 闭包：lambda 带走了变量本身 =====");
int factor = 10;
Func<int, int> scale = x => x * factor;   // 捕获的是 factor 变量（不是当时的值）
factor = 20;
Console.WriteLine($"  factor 改成 20 后调用: scale(5) = {scale(5)}   ← 捕获的是变量，跟着变");

Console.WriteLine();
Console.WriteLine("===== 经典陷阱：for 循环变量捕获 =====");
var actions = new List<Func<int>>();
for (var i = 0; i < 3; i++)
    actions.Add(() => i);                  // C# 5 起：每轮迭代 i 都是新变量
foreach (var fn in actions) Console.Write($" {fn()}");
Console.WriteLine("  ← 打印 0 1 2：每轮 i 是独立变量（C# 4 之前共享一个变量，会打印 3 3 3）");

Console.WriteLine();
Console.WriteLine("===== static lambda：禁止捕获 =====");
Func<int, int> pure = static x => x + 1;   // static：编译器保证不捕获任何变量
Console.WriteLine($"  static lambda: {pure(41)}   ← 想捕获会直接编译错误");

Console.WriteLine();
Console.WriteLine("===== 表达式树：lambda 的「源码」形态 =====");
System.Linq.Expressions.Expression<Func<int, int>> expr = x => (x + 1) * 2;
Console.WriteLine($"  表达式树: {expr}   ← 不是可执行代码，是语法树（EF 翻译成 SQL 靠它）");
var compiled = expr.Compile();             // 编译后才可执行
Console.WriteLine($"  Compile()(10) = {compiled(10)}");
Console.WriteLine("  Func 是编译好的机器码；Expression 是数据——第 23 章反射家族的近亲");
