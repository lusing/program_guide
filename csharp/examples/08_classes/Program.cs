// 08 · 类与封装：字段、属性、构造、静态——对象的基本盘
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 属性：字段的守门员 =====");
var acc = new Account("小明", 100m);
Console.WriteLine(acc.Describe());
acc.Deposit(50m);
Console.WriteLine($"存款 50 后: {acc.Balance}");
try { acc.Deposit(-1m); }
catch (ArgumentException ex) { Console.WriteLine($"非法入参被属性/方法拦下: {ex.Message}"); }
Console.WriteLine("  Money 只能通过方法改变——外部只读，这就是封装");

Console.WriteLine();
Console.WriteLine("===== 构造函数链与初始化器 =====");
var p1 = new Person("张三", 24) { City = "北京" };   // 括号后 { } 是对象初始化器
Console.WriteLine($"{p1.Name} / {p1.Age} / {p1.City}");
var p2 = new Person("李四");                          // 可选参数版构造
Console.WriteLine($"{p2.Name} / {p2.Age}（默认）");

Console.WriteLine();
Console.WriteLine("===== init：只能在建对象时赋值 =====");
// p1.Name = "王五";       // ✘ 编译错误：init 属性只在初始化时开放
var cfg = new Config { Timeout = 30 };
// cfg.Timeout = 60;      // ✘ 同上
Console.WriteLine($"Config.Timeout = {cfg.Timeout}（init 属性：不可变对象的安全感）");

Console.WriteLine();
Console.WriteLine("===== static：属于类而不是实例 =====");
Console.WriteLine($"实例计数: {Person.Created}（每 new 一次 +1）");
Console.WriteLine($"static const: 圆周率 = {Math2.Pi:F6}（const 编译期定死，static readonly 运行期初始化）");

Console.WriteLine();
Console.WriteLine("===== 索引器与分部类 =====");
var week = new WeekDays();
Console.WriteLine($"week[0] = {week[0]}, week[6] = {week[6]}   ← 像数组一样用对象");
Console.WriteLine($"week[\"三\"] = {week["三"]}   ← 索引器可以重载：同名不同参数，按内容反查下标");

Console.WriteLine();
Console.WriteLine("===== 分部类与分部方法：一个类拆几半，编译期合并 =====");
var report = new Report("月报");
report.Append("第一段");
report.Append("第二段");
Console.WriteLine($"  {report.Title}: {report.Sections.Count} 段，约 {report.EstimatedLength()} 字   ← 两半声明拼成了同一个类");
_ = new SilentHook();
Console.WriteLine("  SilentHook 的 OnCreated() 没写实现：构造照常，调用点被编译器整体移除（不报错也不执行）");
Console.WriteLine("  规则（实测）：无访问修饰符 + void = 经典形态（实现可省略）；一旦写出修饰符或非 void 返回值就升级为");
Console.WriteLine("  扩展形态、必须两半都有实现（缺实现 CS8795、非 void 没修饰符 CS8796）");

class Account
{
    private decimal _balance;                        // 私有字段：实现细节
    public string Owner { get; }                     // 只读属性（构造后不可变）
    public decimal Balance => _balance;              // 表达式属性：只读对外

    public Account(string owner, decimal initial)
    {
        Owner = owner;
        _balance = initial;
    }

    public void Deposit(decimal amount)
    {
        if (amount <= 0) throw new ArgumentException("存款必须为正数", nameof(amount));
        _balance += amount;
    }

    public string Describe() => $"{Owner} 的账户余额 {_balance:N2}";
}

class Person
{
    public static int Created { get; private set; }  // 静态属性：全类共享
    public string Name { get; }
    public int Age { get; }
    public string? City { get; set; }                // 可空默认值用 ?（第 21 章）

    public Person(string name, int age = 18)         // 可选参数减少构造函数重载
    {
        Name = name;
        Age = age;
        Created++;
    }
}

class Config
{
    public int Timeout { get; init; }
}

static class Math2
{
    public const double Pi = 3.141593;               // const：编译期常量
    public static readonly DateTime BuiltAt = DateTime.Now;  // 运行期一次初始化
}

class WeekDays
{
    private readonly string[] _days = { "一", "二", "三", "四", "五", "六", "日" };
    public string this[int i] => $"周{_days[i]}";                 // 索引器：this[参数]
    public int this[string day] => Array.IndexOf(_days, day);     // 重载：参数不同即可（接口里也能声明索引器）
}

// 分部类：同一个类拆成多份声明（可跨文件，也可像这样同文件多段）——编译器合并成一个类
partial class Report
{
    public string Title { get; }
    public List<string> Sections { get; } = new();   // 「手写的一半」：核心状态

    public Report(string title) => Title = title;

    public void Append(string s)
    {
        Sections.Add(s);
        OnAppended(s);                                // 经典分部方法调用点：没实现就被移除，有实现就接上
    }

    partial void OnAppended(string s);                // 经典形态：无修饰符 + void → 实现可以省略

    public partial int EstimatedLength();             // 扩展形态：有修饰符、可返回值 → 必须有实现（CS8795）
}

partial class Report                                  // 想象这段在另一个文件（或源生成器写出的 .g.cs）
{
    partial void OnAppended(string s) => Console.WriteLine($"    [钩子] 追加了「{s}」");

    public partial int EstimatedLength() => Title.Length + Sections.Sum(s => s.Length);
}

partial class SilentHook
{
    public SilentHook() => OnCreated();               // 调用点存在……

    partial void OnCreated();                         // ……但实现缺席：编译后这里什么都不剩
}
