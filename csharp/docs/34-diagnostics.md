# 34 · 诊断与日志

> 对应示例：`examples/34_diagnostics`

> **本章你将学会**：Debug/Trace 的差异、[Conditional] 裁剪、Stopwatch 量测、堆栈与进程信息、Metrics 计数器、日志的选型与写法。
> **前置章节**：[22 异常](22-exceptions.md)、[14 特性](23-reflection-attributes.md)。

## 1. Debug 与 Trace：两个输出通道

```csharp
Debug.WriteLine("这条 Release 里没有");    // 只在 DEBUG 配置编译进去——零生产开销
Trace.WriteLine("任何配置都在");            // 生产也保留（默认输出到调试器/监听器）
```

**口诀：临时调试 Debug、生产追踪 Trace/ILogger**。Debug 的"Release 里消失"不是开关判断——**调用点整体不编译**（连参数求值都省），下一节的 [Conditional] 是它的可自定义版。

## 2. [Conditional]：方法调用按配置裁剪

```csharp
public static class Log
{
    [Conditional("DEBUG")]
    public static void Verbose(string message) => Console.WriteLine($"[VERBOSE] {message}");
}

Log.Verbose("Debug 配置才编译这行");   // Release：这行调用整体消失
```

与 `#if DEBUG` 的区别：**方法体只写一处**，调用点自动随配置消失——日志/调试钩子分发的标准做法。BCL 的 Debug.Assert 全家就是它。

## 3. Stopwatch：性能讨论的尺子

```csharp
var sw = Stopwatch.StartNew();
// 被测代码
sw.Stop();
Console.WriteLine(sw.Elapsed.TotalMicroseconds);
```

**没有量测的性能判断都是玄学**——26 章（分配量）、29-31 章（耗时）的每个结论背后都是它。进阶：`dotnet-counters`（进程级指标）、`dotnet-trace`（CPU 采样火焰图）、BenchmarkDotNet（严格基准，防 JIT/GC 干扰的统计学设计）。**日常 Stopwatch、严肃上 BenchmarkDotNet**。

## 4. 堆栈与进程信息

```csharp
new StackTrace().GetFrame(2)?.GetMethod()?.Name     // 我是谁（调用链上溯）
Environment.StackTrace                              // 全栈字符串
Process.GetCurrentProcess().WorkingSet64 / 1024 / 1024   // 内存 MB
GC.CollectionCount(0)                               // GC 次数（25 章排查入口）
```

**错误日志必带栈**（`ex.ToString()` 不是 `ex.Message`——22 章）——`Environment.StackTrace` 是不带异常时看"我怎么到这的"的窗口。

## 5. Metrics：现代计数器

```csharp
var meter = new System.Diagnostics.Metrics.Meter("tutorial.demo");
var counter = meter.CreateCounter<int>("requests", unit: "次", description: "请求数");
counter.Add(3);
counter.Add(5, new KeyValuePair<string, object?>("route", "/api/data"));   // 带标签（维度）
```

Meter（命名空间化的仪表盘）→ Counter（累加）/ Gauge（瞬时值）/ Histogram（分布）三件仪表。**OpenTelemetry 兼容**——`dotnet-counters monitor` 实时看、或接 OTel 导到 Prometheus/Grafana。与"打日志"的分工：**日志记事件（谁干了什么），Metrics 记量（干了多少/多快）**——一个是叙事一个是曲线，监控体系两条腿。

## 6. 日志的选型与写法

现实项目的分层：

```text
接口层   Microsoft.Extensions.Logging 的 ILogger（结构化、等级过滤、DI 注入）
输出端   Console / 滚动文件 / OpenTelemetry（集中式）——provider 插拔
小工具   TraceSource + 监听器（零依赖够用）
```

**结构化日志的写法**（模板占位，不拼字符串）：

```csharp
_logger.LogInformation("用户 {UserId} 下单 {OrderId}，金额 {Amount}", userId, orderId, amount);
// 日志系统按结构存字段——能按 UserId 精确检索、聚合，而不是在文本里 grep
```

等级语义：Trace < Debug < Information < Warning < Error < Critical——生产默认 Information 起。**日志三问**：这条日志谁看？出了什么事要看它？看不看得出原因？——答不上来的日志是噪音。

## 7. 诊断工具箱总览

| 工具 | 看什么 | 章节 |
|---|---|---|
| Stopwatch / BenchmarkDotNet | 代码耗时 | 本章/26 |
| GC.GetAllocatedBytes | 分配量 | 26 |
| dotnet-counters | 进程实时指标（CPU/内存/GC/线程） | 25 |
| dotnet-dump | 内存快照找泄漏 | 25 |
| dotnet-trace | CPU 火焰图 | 31 |
| 日志（ILogger/OTel） | 事件叙事 | 本章 |
| Metrics | 量与趋势 | 本章 |

## 常见坑

**Console.WriteLine 当生产日志**：无等级/无结构/无落盘——小脚本无所谓，服务不行；但调试输出用 Console 完全合理（分清场合）。

**Debug.WriteLine 留在生产逻辑里**：它本来就会消失（无害）——**有害的是反过来**：把 Debug.Assert 当生产校验（Release 里它不存在！校验要真抛，22 章）。

**日志吞异常只记 message**：`catch (Exception ex) { _log.Error(ex.Message); }`——栈丢了；**把 ex 整个交给日志框架**（`_log.Error(ex, "下单失败 {OrderId}", orderId)`）。

**结构化日志拼好字符串再传**：`_log.Info($"用户 {id} 下单")`——结构没了，白瞎了检索能力。

**性能"体感优化"**：没量测就重构——26/31 章的量测纪律再强调一次。

## 实战建议

- 项目第一天就把日志骨架立起来（ILogger + Console provider 起步，后续插文件/OTel）——事后补日志是灾难
- 关键路径埋三类点：入口（请求/命令参数）、出口（结果+耗时）、异常（完整 ex + 上下文）
- Metrics 从两个数起步：请求量 Counter、耗时 Histogram——够撑起第一块监控面板，再加维度
- 本地诊断组合拳：dotnet-counters 挂着跑压测 → 指标异常时 dotnet-dump 抓现场（25 章流程）
- WPF 教程 02 章的 DispatcherUnhandledException + 本章全局日志 = 桌面应用的"黑匣子"标配

## 自测

1. **Debug 与 Trace 的编译差异？** —— Debug 调用点在 Release 整体消失（零开销）；Trace 常驻。
2. **[Conditional] 相比 #if 的优势？** —— 方法体单点维护，调用点按配置自动裁剪。
3. **结构化日志为什么用占位模板？** —— 字段被结构化存储，可精确检索/聚合，而非文本 grep。
4. **日志与 Metrics 的分工？** —— 事件叙事（谁干了什么）vs 量的曲线（干了多少/多快）。

---
上一章：[33 序列化与 JSON](33-json.md) ｜ 下一章：[35 单元测试](35-testing.md) ｜ 返回：[README](../README.md)
