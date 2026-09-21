// 10 · 接口：能做什么的契约（与继承 orthogonal 的另一条轴）
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 基本面：类实现接口 =====");
var dog = new Dog("旺财");
IPet pet = dog;                       // 接口引用：只看得见契约里的成员
IMakeSound s = dog;
Console.WriteLine($"  IPet: {pet.Name}；IMakeSound: {s.Sound()}——一个对象，多张契约面孔");

Console.WriteLine();
Console.WriteLine("===== 排序为什么能通：IComparable<T> =====");
var nums = new[] { 5, 1, 3 };
Array.Sort(nums);                     // Sort 只依赖 IComparable 契约，谁实现谁就能被排
Console.WriteLine($"  int 实现 IComparable<int>: [{string.Join(", ", nums)}]");

var temps = new List<Temperature> { new(30.5), new(28.1), new(31.0) };
temps.Sort();                         // 温度自己定义的"怎么比"被 Sort 采用
Console.WriteLine($"  Temperature 按摄氏度排序: {string.Join(" < ", temps.Select(t => t.Celsius))}");

Console.WriteLine();
Console.WriteLine("===== 显式接口实现：两个接口撞名时 =====");
var printer = new MultiPrinter();
printer.Print("普通调用");             // 调到类的公开 Print
((IPrinter)printer).Print("走 IPrinter");   // 显式实现必须先转接口才能调
((ILaser)printer).Print("走 ILaser");
Console.WriteLine("  显式实现不带 public——它只属于接口，避免撞名污染类的公开面");

Console.WriteLine();
Console.WriteLine("===== 默认接口实现（C# 8）：给契约配默认行为 =====");
var legacy = new LegacyLogger();
((ILogger)legacy).Info("来自默认实现");  // 默认实现必须通过接口引用调用（类上没有这个方法）
Console.WriteLine("  默认实现的价值：给老接口加新成员不破坏已有实现类（慎用，见正文坑节）");

Console.WriteLine();
Console.WriteLine("===== 接口 vs 抽象类 =====");
Console.WriteLine("  is-a 且共享代码 → 抽象类；can-do 且要多重 → 接口");
Console.WriteLine($"  Dog 是 Animal（单继承）+ 能 IPet/IMakeSound（多接口）");

interface IPet { string Name { get; } }
interface IMakeSound { string Sound(); }

abstract class Animal { }

class Dog(string name) : Animal, IPet, IMakeSound
{
    public string Name { get; } = name;
    public string Sound() => "汪！";
}

class Temperature(double celsius) : IComparable<Temperature>
{
    public double Celsius { get; } = celsius;
    public int CompareTo(Temperature? other) => Celsius.CompareTo(other?.Celsius ?? 0);
}

interface IPrinter { void Print(string s); }
interface ILaser { void Print(string s); }

class MultiPrinter : IPrinter, ILaser
{
    public void Print(string s) => Console.WriteLine($"  [类公开] {s}");
    void IPrinter.Print(string s) => Console.WriteLine($"  [喷墨] {s}");
    void ILaser.Print(string s) => Console.WriteLine($"  [激光] {s}");
}

interface ILogger
{
    void Log(string message);                       // 必须实现
    void Info(string message) => Log($"[INFO] {message}");   // 默认实现
}

class LegacyLogger : ILogger
{
    public void Log(string message) => Console.WriteLine($"  {message}");
}
