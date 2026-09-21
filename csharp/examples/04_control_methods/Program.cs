// 04 · 流程控制与方法：if/switch 的现代形态 + 参数的五种花样
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== switch 表达式（C# 8 起，优于老 switch 语句）=====");
static string GradeOf(int score) => score switch
{
    >= 90 => "优秀",
    >= 80 => "良好",
    >= 60 => "及格",
    _     => "不及格",          // _ 是丢弃模式：兜底
};
foreach (var s in new[] { 95, 83, 66, 40 })
    Console.WriteLine($"  {s} → {GradeOf(s)}");

Console.WriteLine();
Console.WriteLine("===== 循环三件套 + foreach =====");
var sum = 0;
for (var i = 1; i <= 5; i++) sum += i;
Console.WriteLine($"  for 累加 1..5 = {sum}");

var k = 0;
while (k < 3) k++;
Console.WriteLine($"  while 计数 = {k}");

foreach (var ch in "abc")
    Console.Write(ch + " ");
Console.WriteLine(" ← foreach 遍历 string（本质是枚举 IEnumerator，第 18 章）");

Console.WriteLine();
Console.WriteLine("===== 方法参数的五种花样 =====");

// ① 可选参数 + ② 命名参数
static string Greet(string name, string greeting = "你好") => $"{greeting}，{name}！";
Console.WriteLine($"  可选参: {Greet("小明")}");
Console.WriteLine($"  命名参: {Greet("小明", greeting: "早上好")}");

// ③ out：方法"返回"多个值
static bool TryParsePair(string input, out int left, out int right)
{
    var parts = input.Split(',');
    left = right = 0;
    if (parts.Length != 2) return false;
    return int.TryParse(parts[0], out left) && int.TryParse(parts[1], out right);
}
if (TryParsePair("3,7", out var a, out var b))
    Console.WriteLine($"  out 双返回: a={a}, b={b}");

// ④ ref：把变量本身传进去（改的是调用方的）
static void Bump(ref int n) => n++;
var counter = 10;
Bump(ref counter);
Console.WriteLine($"  ref 后 counter = {counter}（直接改了调用方的变量）");

// ⑤ params：可变数量参数
static int Sum(params int[] numbers) => numbers.Sum();
Console.WriteLine($"  params: Sum(1,2,3,4) = {Sum(1, 2, 3, 4)}");

Console.WriteLine();
Console.WriteLine("===== 重载与局部函数 =====");
static void ShowInt(int x)    => Console.WriteLine($"  ShowInt(int): {x}");
static void ShowStr(string s) => Console.WriteLine($"  ShowStr(string): {s}");
ShowInt(42); ShowStr("42");
Console.WriteLine("  注意：局部函数不能重载（同名直接 CS0128），重载要放在类型成员层面");

int Fib(int n) => n <= 1 ? n : Fib(n - 1) + Fib(n - 2);   // 局部函数：仅本作用域可见
Console.WriteLine($"  局部函数 Fib(10) = {Fib(10)}");
