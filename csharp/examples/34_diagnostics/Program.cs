// 34 · 诊断与日志：从 Debug.WriteLine 到 Metrics
using System.Diagnostics;

Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== Debug 与 Trace：开发期 vs 全期 =====");
// Debug.WriteLine 只在 Debug 配置编译进去（Release 里不存在——零开销）
Debug.WriteLine("这条 Release 里没有");
Trace.WriteLine("这条任何配置都在（默认输出到调试器/监听器）");
Console.WriteLine("  口诀：临时调试 Debug，生产追踪 Trace/ILogger");

Console.WriteLine();
Console.WriteLine("===== Stopwatch：一切性能讨论的尺子 =====");
var sw = Stopwatch.StartNew();
var s = 0;
for (var i = 0; i < 1_000_000; i++) s += i;
sw.Stop();
Console.WriteLine($"  100 万次累加: {s:N0}，耗时 {sw.Elapsed.TotalMicroseconds:F0}µs");
Console.WriteLine("  性能优化的第一原则：没有 Stopwatch 的快慢判断都是玄学");

Console.WriteLine();
Console.WriteLine("===== [Conditional]：按配置裁剪 =====");
Log.Verbose("Debug 配置才编译这行");
Console.WriteLine("  [Conditional(\"DEBUG\")] 让调用点在 Release 里整体消失（连参数求值都不做）");

Console.WriteLine();
Console.WriteLine("===== 堆栈与进程信息 =====");
Console.WriteLine($"  当前方法链: {new StackTrace().GetFrame(2)?.GetMethod()?.Name ?? "(顶层)"}");
Console.WriteLine($"  进程: {Process.GetCurrentProcess().ProcessName}，物理内存 {Process.GetCurrentProcess().WorkingSet64 / 1024 / 1024} MB");
Console.WriteLine($"  GC 代数回收计数: gen0={GC.CollectionCount(0)} gen1={GC.CollectionCount(1)}");

Console.WriteLine();
Console.WriteLine("===== Metrics：现代计数器（OpenTelemetry 兼容）=====");
var meter = new System.Diagnostics.Metrics.Meter("tutorial.demo");
var counter = meter.CreateCounter<int>("requests", unit: "次", description: "请求数");
counter.Add(3);
counter.Add(5, new KeyValuePair<string, object?>("route", "/api/data"));
Console.WriteLine("  Meter/Counter 已记录——配合 dotnet-counters 或 OTel 导出即可观测");

Console.WriteLine();
Console.WriteLine("===== 日志的现实选型 =====");
Console.WriteLine("  应用层：Microsoft.Extensions.Logging.ILogger（结构化，等级过滤）");
Console.WriteLine("  输出端：控制台/文件(滚动)/OpenTelemetry(集中式)——provider 插拔");
Console.WriteLine("  习惯：message 用模板占位（\"用户 {UserId} 下单\"）而不是字符串拼接——保留结构");
Console.WriteLine("  没有依赖注入的小工具：TraceSource + 监听器也够用");

public static class Log
{
    [Conditional("DEBUG")]
    public static void Verbose(string message) => Console.WriteLine($"  [VERBOSE] {message}");
}
