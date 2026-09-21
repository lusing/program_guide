// 25 · GC 与内存管理：托管世界也需要你管"非托管"
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 分代回收：新对象死得快 =====");
var young = new object();
Console.WriteLine($"  新对象在第 {GC.GetGeneration(young)} 代");
GC.Collect();                                       // 强制回收（演示用；生产代码别调）
Console.WriteLine($"  回收后活下来的进第 {GC.GetGeneration(young)} 代");
Console.WriteLine($"  各代回收次数: gen0={GC.CollectionCount(0)}, gen1={GC.CollectionCount(1)}, gen2={GC.CollectionCount(2)}");
Console.WriteLine("  逻辑：gen0 最常扫（对象朝生暮死），gen2 很少扫（老对象贵）");

Console.WriteLine();
Console.WriteLine("===== IDisposable + using：非托管资源的纪律 =====");
using (var file = new ManagedResource("数据库连接"))
{
    file.Use();
}                                                   // 离开作用域自动 Dispose
Console.WriteLine("  using 块结束 → Dispose 被调用（确定性释放，不等 GC）");

using var file2 = new ManagedResource("文件句柄");  // using 声明：作用域结束释放
file2.Use();
Console.WriteLine("  using 声明（C# 8）：不加大括号，当前作用域结束释放");

Console.WriteLine();
Console.WriteLine("===== 终结器：最后的兜底，不是主手段 =====");
Console.WriteLine("  ~ManagedResource() 只在 GC 回收时才跑——时机不可控，可能永远不跑");
Console.WriteLine("  Dispose 模式：Dispose(true) 管托管+非托管，终结器调 Dispose(false)");
Console.WriteLine("  有终结器的对象要多活一代才被回收——能不用终结器就不用");

Console.WriteLine();
Console.WriteLine("===== WeakReference：不阻止回收的「引用」 =====");
static WeakReference TrackTemporary()
{
    var big = new byte[1024];         // big 在方法返回后失去强引用
    return new WeakReference(big);
}
var weak = TrackTemporary();
GC.Collect();
Console.WriteLine($"  目标还活着吗: {weak.IsAlive}   ← GC 时无人强引用就回收");
Console.WriteLine("  用途：缓存（丢了就重算）、事件防泄漏（WeakEventManager）");

Console.WriteLine();
Console.WriteLine("===== 实践清单 =====");
Console.WriteLine("  ① 优先短生命周期小对象——gen0 回收近乎免费");
Console.WriteLine("  ② 大数组/大字符串复用（ArrayPool，第 26 章）");
Console.WriteLine("  ③ 持有非托管资源 → IDisposable + using，别依赖终结器");
Console.WriteLine("  ④ 怀疑泄漏用 dotnet-counters / dotnet-dump 看 GC 计数与代大小，别瞎 GC.Collect");

public sealed class ManagedResource(string name) : IDisposable
{
    public void Use() => Console.WriteLine($"  使用 {name}");
    public void Dispose()
    {
        Console.WriteLine($"  [Dispose] 释放 {name}");
        GC.SuppressFinalize(this);      // 已显式释放，跳过终结器
    }
    ~ManagedResource() => Console.WriteLine($"  [终结器] {name} 被回收时兜底");
}
