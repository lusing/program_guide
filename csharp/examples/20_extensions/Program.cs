// 20 · 扩展方法与运算符重载：给别人的类型加你的能力
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 扩展方法：this 参数的魔法 =====");
var text = "hello world";
Console.WriteLine($"  {text.Truncate(8)}          ← string 没有 Truncate，我们加的");
Console.WriteLine($"  {3.IsEven()}               ← int 也没有 IsEven");
Console.WriteLine("  本质：static 静态类 + this 参数，编译器把 obj.Foo(x) 翻译成 Ext.Foo(obj, x)");
Console.WriteLine("  LINQ 的 Where/Select 全是扩展方法——你天天在用自己也能写的语法糖");

Console.WriteLine();
Console.WriteLine("===== C# 14 扩展成员：一个 extension 块管一族成员 =====");
var r = new Rect(3, 4);
Console.WriteLine($"  r.Area(): {r.Area()}   ← 方法也是扩展来的（C# 14 新语法）");
Console.WriteLine($"  r.IsSquare: {r.IsSquare}");
Console.WriteLine("  extension 块把「接收者类型 + 一组成员」打包，比散装静态方法内聚");

Console.WriteLine();
Console.WriteLine("===== 运算符重载：让自定义类型像内建类型 =====");
Money price = 19.99m;
Money total = price * 3;
Money withTip = total + new Money(5m);
Console.WriteLine($"  price * 3 = {total}；+5 小费 = {withTip}");
Console.WriteLine($"  total == new Money(59.97m): {total == new Money(59.97m)}   ← == 也重载了");

Console.WriteLine();
Console.WriteLine("===== 隐式/显式转换 =====");
Celsius c = 25;                      // double → Celsius：隐式（无损）
Console.WriteLine($"  Celsius c = 25 → {c}");
double back = c;                     // Celsius → double：隐式
Fahrenheit f = (Fahrenheit)c;        // 有精度/语义跳跃：显式
Console.WriteLine($"  显式转华氏: {f}（还原成 double: {back}）");
Console.WriteLine("  规则：绝不丢信息 → implicit；可能丢/可能失败 → explicit");

Console.WriteLine();
Console.WriteLine("===== 全景：Money 的运算符清单见文件底部 =====");

// ---------- 经典扩展方法（C# 3 起可用）----------
public static class StringExtensions
{
    public static string Truncate(this string s, int max)
        => s.Length <= max ? s : s[..max] + "…";

    public static bool IsEven(this int n) => n % 2 == 0;
}

// ---------- C# 14 扩展成员（一个块声明一族）----------
public static class RectExtensions
{
    extension(Rect r)
    {
        public double Area() => r.Width * r.Height;
        public bool IsSquare => Math.Abs(r.Width - r.Height) < 1e-9;
    }
}

public readonly record struct Rect(double Width, double Height);

public readonly struct Money(decimal amount)
{
    public decimal Amount { get; } = amount;
    public override string ToString() => $"￥{Amount:N2}";
    public static implicit operator Money(decimal d) => new(d);   // decimal → Money 顺手转
    public static Money operator +(Money a, Money b) => new(a.Amount + b.Amount);
    public static Money operator *(Money m, int times) => new(m.Amount * times);
    public static bool operator ==(Money a, Money b) => a.Amount == b.Amount;
    public static bool operator !=(Money a, Money b) => !(a == b);
    public override bool Equals(object? obj) => obj is Money m && m.Amount == Amount;
    public override int GetHashCode() => Amount.GetHashCode();
}

public readonly struct Celsius(double degrees)
{
    public double Degrees { get; } = degrees;
    public override string ToString() => $"{Degrees}℃";
    public static implicit operator Celsius(double d) => new(d);
    public static implicit operator double(Celsius c) => c.Degrees;
    public static explicit operator Fahrenheit(Celsius c) => new(c.Degrees * 9 / 5 + 32);
}

public readonly struct Fahrenheit(double degrees)
{
    public double Degrees { get; } = degrees;
    public override string ToString() => $"{Degrees}℉";
}
