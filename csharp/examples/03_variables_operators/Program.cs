// 03 · 变量、类型与运算符：强类型世界的规矩
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 声明与推断 =====");
int explicitInt = 42;                    // 显式类型
var inferred = "编译器推断为 string";      // var：仍是强类型，只是让编译器写类型
const double TaxRate = 0.13;             // const：编译期常量
Console.WriteLine($"{explicitInt} / {inferred} / 税率 {TaxRate}");

Console.WriteLine();
Console.WriteLine("===== 数值类型一览（字节数与范围）=====");
Console.WriteLine($"int   {sizeof(int)} 字节  范围 {int.MinValue} ~ {int.MaxValue}");
Console.WriteLine($"long  {sizeof(long)} 字节  范围 {long.MinValue:N0} ~ {long.MaxValue:N0}");
Console.WriteLine($"double {sizeof(double)} 字节  约 15~16 位有效数字");
Console.WriteLine($"decimal {sizeof(decimal)} 字节  28 位有效数字——钱用它（{0.1m + 0.2m} vs double 的 {0.1 + 0.2}）");

Console.WriteLine();
Console.WriteLine("===== 类型转换的四种路 =====");
int small = 100;
long wide = small;                        // ① 隐式：安全的小→大，编译器放行
int back = (int)3.99;                     // ② 显式（强转）：大→小，程序员担责 → 3（截断不是四舍五入）
string text = "123";
int parsed = int.Parse(text);             // ③ Parse：失败抛异常
bool ok = int.TryParse("12x", out int v); // ④ TryParse：失败返回 false，不抛——首选
Console.WriteLine($"隐式 {wide}；强转 3.99→{back}；Parse {parsed}；TryParse \"12x\" → ok={ok}, v={v}");

Console.WriteLine();
Console.WriteLine("===== 溢出与 checked =====");
int max = int.MaxValue;
Console.WriteLine($"unchecked（默认）: {max + 1}   ← 环绕成最小值，静默错误！");
checked
{
    try
    {
        var overflow = max + 1;           // checked 块内抛 OverflowException
        Console.WriteLine(overflow);
    }
    catch (OverflowException)
    {
        Console.WriteLine("checked 块内: 溢出被抓住（OverflowException）");
    }
}

Console.WriteLine();
Console.WriteLine("===== 运算符速查（本例演示易错的三组）=====");
Console.WriteLine($"整数除法 7 / 2 = {7 / 2}，取余 7 % 2 = {7 % 2}");
Console.WriteLine($"想让结果是小数：7 / 2.0 = {7 / 2.0}");
int i = 5;
Console.WriteLine($"i++ 作为表达式先用后加：{i++}（之后 i = {i}）");
Console.WriteLine($"++i 先加后用：{++i}");
var s = null as string;
Console.WriteLine($"?? 与 ?.: {(s ?? "(null 兜底)")} / 长度 {s?.Length ?? -1}");

Console.WriteLine();
Console.WriteLine("===== 类型信息 =====");
object anything = "hello";
Console.WriteLine($"GetType 看运行时真身: {anything.GetType().Name}（object 变量装着 string）");
Console.WriteLine($"is 判断: {anything is string}, {anything is int}");
