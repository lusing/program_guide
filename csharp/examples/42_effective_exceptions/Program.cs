// 42 · Effective C#·异常设计（书第 5 章 条 45-50）：契约、保证与筛选器
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 条 45: 方法契约被违背时抛异常（并提供「先试后做」路径） =====");
var worker = new WidgetWorker();
try { worker.DoWork(widgetsReady: false); }                    // 只给执行方法：用户被迫 try/catch
catch (InvalidOperationException ex) { Console.WriteLine($"  DoWork(false) → {ex.GetType().Name}: {ex.Message}"); }
Console.WriteLine($"  TryDoWork(false) → {worker.TryDoWork(widgetsReady: false)}（同一失败，返回 false 不抛——正常流程不用异常当控制流）");
worker.DoWork(widgetsReady: true);                             // 满足前置条件才真正执行
Console.WriteLine("  BCL 同款配对: File.Open(抛) ↔ File.Exists(查)；int.Parse(抛) ↔ int.TryParse(试)");
Console.WriteLine("  原则：异常给「违约」，返回值给「可预期的分支」；抛异常比错误码贵得多");

Console.WriteLine();
Console.WriteLine("===== 条 47: 为应用程序创建专属异常（按「处理方式」分型） =====");
Console.WriteLine("  分型依据不是错误来源，而是「调用方能不能用不同办法恢复」:");
Console.WriteLine("   - 找不到配置文件 → 回落默认值     → 可恢复 → ConfigurationNotFoundException");
Console.WriteLine("   - 网络断连       → 重试/降级       → 可恢复 → DownstreamUnavailableException");
Console.WriteLine("   - 数据损坏       → 停机报警         → 不可恢复 → DataCorruptedException");
var api = new PaymentGateway();
try { api.Charge(30); }
catch (DownstreamUnavailableException ex)                       // 按类型分派处理策略
{
    Console.WriteLine($"  catch (DownstreamUnavailable): {ex.Message} → 走降级队列");
    Console.WriteLine($"    InnerException 保留了底层真相: {ex.InnerException!.GetType().Name}: {ex.InnerException.Message}");
}
Console.WriteLine("  异常转换（translate）：底层 TimeoutException 包进领域异常当 InnerException——");
Console.WriteLine("  调用方按业务语义 catch，排查时仍能挖到根因");
Console.WriteLine("  实现惯例：把基类常用构造函数配齐（无参/带消息/带 InnerException）；");

Console.WriteLine();
Console.WriteLine("===== 条 48: 优先做出强异常保证（拷贝-处理-替换） =====");
var ledger = new Ledger();
ledger.Add(new Entry(1)); ledger.Add(new Entry(-2));            // 第 2 笔会让翻倍操作抛异常
try { ledger.ApplyAll(e => e with { Value = CheckedDouble(e.Value) }); }
catch (ArgumentException ex) { Console.WriteLine($"  ApplyAll 在第 2 笔炸了: {ex.Message}"); }
Console.WriteLine($"  强保证版账本: [{string.Join(",", ledger.Items.Select(e => e.Value))}] ← 全是旧值，干净回滚");
var naive = new List<Entry> { new(1), new(-2) };
try
{
    for (int i = 0; i < naive.Count; i++)                       // 反面：原地修改
        naive[i] = naive[i] with { Value = CheckedDouble(naive[i].Value) };
}
catch (ArgumentException) { }
Console.WriteLine($"  原地修改版: [{string.Join(",", naive.Select(e => e.Value))}] ← 第 1 笔已改、第 2 笔没改——半个状态");
Console.WriteLine("  三级保证: 基本（不泄漏、状态合法）< 强（要么全成要么全没变）< no-throw（绝不抛）");
Console.WriteLine("  no-throw 的四个特例：Dispose、终结器、when 筛选器、委托目标——里面绝不抛");

Console.WriteLine();
Console.WriteLine("===== 条 49: 异常筛选器代替「捕获再重抛」（保住现场） =====");
try { CrashesWith(42); }
catch (ArgumentException ex) when (ex.ParamName is not null && ex.ParamName.Length > 0)
{
    Console.WriteLine($"  when 筛选命中（ParamName={ex.ParamName}），栈顶是【原始抛出点】: {ex.StackTrace!.Split('\n')[0].Trim()}");
}
try { CrashesWith(42); }
catch (ArgumentException ex)
{
    if (ex.ParamName is null) throw;                            // 反面教材：先捕获再判断再重抛
    Console.WriteLine($"  catch-判断-重抛版: 报告位置变成了 throw 所在行（原始现场已被栈展开冲掉）");
    Console.WriteLine("  （差异：筛选器在栈展开【前】评估——false 就当这个 catch 不存在，继续往上找）");
}
Console.WriteLine("  典型场景: Task.Exception 是 AggregateException 要筛 InnerExceptions、COMException 筛 HResult、");
Console.WriteLine("           HttpException 筛状态码——类型相同内容不同，一律用 when");

Console.WriteLine();
Console.WriteLine("===== 条 50: 筛选器的副作用妙用（永远 false 的日志钩子） =====");
Program2.RunFaultProbe();
Console.WriteLine("  WithLog 内部挂着 catch (Exception e) when Log(e) —— Log 打印日志后【返回 false】：");
Console.WriteLine("  不拦截、不打扰栈展开，却把每个路过的异常都记了账（含最终未被处理的）");
Console.WriteLine("  另一招: catch (Exception) when (Debugger.IsAttached is false) —— 调试器连着时不吞异常，");
Console.WriteLine("  让断点直接停在抛出点（构建配置无关，看的是运行期状态）");

Console.WriteLine();
Console.WriteLine("===== 全书 50 条收束：三条心法 =====");
Console.WriteLine("  ① 语言习惯（条 1-10）：让编译器替你把关——var/is-as/nameof/?.Invoke/防装箱");
Console.WriteLine("  ② 资源与生命周期（条 11-17 + 39 章）：初始化讲顺序、分配讲克制、释放讲模式");
Console.WriteLine("  ③ 泛型/LINQ/异常（条 18-50）：约束够用就好、查询默认惰性、异常做保证——");
Console.WriteLine("     三者的公共内核是「把假设写进类型系统，把不变量留给运行时验证」");

static int CheckedDouble(int v)
{
    if (v < 0) throw new ArgumentException("负数不能入账", nameof(v));
    return v * 2;
}
static void CrashesWith(int mode) => throw new ArgumentException("模式错误", paramName: mode == 42 ? "mode" : null);

public sealed class WidgetWorker
{
    public void DoWork(bool widgetsReady)
    {
        if (!widgetsReady) throw new InvalidOperationException("部件未就绪，无法执行 DoWork");
        Console.WriteLine("  DoWork(true) → 真正干活");
    }
    public bool TryDoWork(bool widgetsReady)
    {
        if (!widgetsReady) return false;
        DoWork(widgetsReady: true);
        return true;
    }
}

public class ConfigurationNotFoundException : Exception
{
    public ConfigurationNotFoundException() { }
    public ConfigurationNotFoundException(string message) : base(message) { }
    public ConfigurationNotFoundException(string message, Exception inner) : base(message, inner) { }
    // 书（第 3 版，2016）要求第四个「序列化构造函数」——.NET 8 起二进制异常序列化已淘汰（SYSLIB0051），
    // 实测编译警告，现代 .NET 不再需要它。这行注释就是书与本时代 API 的差异记录
}
public class DownstreamUnavailableException : Exception
{
    public DownstreamUnavailableException(string message, Exception inner) : base(message, inner) { }
}

public sealed class PaymentGateway
{
    public void Charge(decimal amount)
    {
        try { SimulateRemoteCall(); }
        catch (TimeoutException inner)                            // 异常转换：根因进 InnerException
        {
            throw new DownstreamUnavailableException("支付通道暂不可用", inner);
        }
    }
    private static void SimulateRemoteCall() => throw new TimeoutException("上游 30s 无响应");
}

public readonly record struct Entry(int Value);

public sealed class Ledger
{
    public List<Entry> Items { get; } = [];
    public void Add(Entry e) => Items.Add(e);
    public void ApplyAll(Func<Entry, Entry> f)
    {
        var updated = new List<Entry>(Items.Count);              // 强保证：拷贝-处理-替换
        foreach (var e in Items) updated.Add(f(e));              // 炸在半路也不碰原表
        Items.Clear();
        Items.AddRange(updated);
    }
}

public sealed class FaultProbe
{
    private int _faults;
    public void Broken() => throw new InvalidOperationException("探测目标第 1 号故障");
    // 永远 false 的筛选器：只记录，不处理——放在方法体里演示等价于挂在调用侧
    private bool Log(Exception e)
    {
        Console.WriteLine($"    [when Log] 记录异常 #{++_faults}: {e.GetType().Name}（筛选器返回 false，继续上抛）");
        return false;
    }
    public void WithLog(Action action)
    {
        try { action(); }
        catch (Exception e) when (Log(e)) { }                    // Log 永 false → 这个 catch 永不吞
    }
}

file static class Program2
{
    public static void RunFaultProbe()
    {
        var probe = new FaultProbe();
        try { probe.WithLog(probe.Broken); }
        catch (InvalidOperationException ex) { Console.WriteLine($"  业务 catch 收到: {ex.Message}"); }
    }
}
