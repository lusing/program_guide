// 13 · 委托：把"方法"当值传递
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 委托是什么：类型安全的函数指针 =====");
MathOp add = static (a, b) => a + b;        // MathOp 委托装着一个 lambda（第 15 章）
MathOp mul = static (a, b) => a * b;
Console.WriteLine($"  add(3,4) = {Run(add, 3, 4)}");
Console.WriteLine($"  mul(3,4) = {Run(mul, 3, 4)}   ← 同一个 Run，策略由调用方注入");

Console.WriteLine();
Console.WriteLine("===== 内置三件套：Action / Func / Predicate =====");
Action<string> print = static s => Console.WriteLine($"  Action（无返回）: {s}");
print("你好");
Func<int, int, int> sum = static (a, b) => a + b;
Console.WriteLine($"  Func（有返回）: {sum(2, 3)}");
Predicate<int> isEven = static n => n % 2 == 0;        // 等价 Func<int,bool>
Console.WriteLine($"  Predicate: 4 是偶数？{isEven(4)}");
Console.WriteLine("  规则：0~16 个入参，要返回值用 Func<... TResult>，不要用 Action/Predicate");

Console.WriteLine();
Console.WriteLine("===== 多播委托：+= 串起一条调用链 =====");
Notification notify = Channels.SendEmail;    // 方法组转换：直接给方法名
notify += Channels.SendSms;                   // 订阅两个方法
notify += static m => Console.WriteLine($"  [日志] 已通知 {m}");
notify("服务器告警");
Console.WriteLine($"  调用链上的方法数: {notify.GetInvocationList().Length}");
notify -= Channels.SendSms;                   // 退订
Console.WriteLine($"  退订后剩: {notify.GetInvocationList().Length} 个");

Console.WriteLine();
Console.WriteLine("===== 委托 vs 接口：策略的两种表达 =====");
var data = new[] { 3, 1, 2 };
Array.Sort(data, static (a, b) => b.CompareTo(a));   // lambda 策略：轻量、一次性的逻辑
Console.WriteLine($"  降序排序: [{string.Join(",", data)}]");
Console.WriteLine("  选型：一句话的逻辑用 lambda；有状态/多方法契约用接口（如 IComparer<T> 的完整实现）");

Console.WriteLine();
Console.WriteLine("===== 方法组转换：直接把方法名塞给委托 =====");
var list = new List<string> { "b", "A", "c" };
list.Sort(StringComparer.OrdinalIgnoreCase);          // 传的是"方法/对象"，不是调用
Console.WriteLine($"  忽略大小写排序: [{string.Join(",", list)}]");

static int Run(MathOp op, int x, int y) => op(x, y);

delegate int MathOp(int a, int b);
delegate void Notification(string message);

static class Channels
{
    public static void SendEmail(string m) => Console.WriteLine($"  [邮件] {m}");
    public static void SendSms(string m) => Console.WriteLine($"  [短信] {m}");
}
