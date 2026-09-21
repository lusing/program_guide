// 30 · 线程安全：竞态、锁与并发集合
using System.Collections.Concurrent;

Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 竞态条件：两个线程同时改一个数 =====");
var counter = 0;
Parallel.For(0, 100_000, _ => counter++);        // 10 万次 ++
Console.WriteLine($"  无保护计数: {counter}（期望 100000——丢的都丢在「读改写」的缝里）");

counter = 0;
Parallel.For(0, 100_000, _ => Interlocked.Increment(ref counter));   // 原子操作
Console.WriteLine($"  Interlocked: {counter}   ✓ 原子 = 不可分割，无缝可钻");

Console.WriteLine();
Console.WriteLine("===== lock：一个房间一把钥匙 =====");
var gate = new object();
var list = new List<int>();
Parallel.For(0, 1_000, i =>
{
    lock (gate)                                   // 同一时刻只有一个线程在块内
    {
        list.Add(i);
    }
});
Console.WriteLine($"  lock 保护 List: {list.Count} 个   ✓（List 本身不线程安全）");
Console.WriteLine("  规则：锁对象私有（private readonly object）、锁粒度最小、绝不在锁内 await");

Console.WriteLine();
Console.WriteLine("===== ConcurrentDictionary：免锁并发字典 =====");
var stats = new ConcurrentDictionary<string, int>();
Parallel.For(0, 10_000, i => stats.AddOrUpdate("hits", 1, (_, v) => v + 1));
Console.WriteLine($"  10_000 次 AddOrUpdate: hits={stats["hits"]}   ✓（键值对级原子）");

Console.WriteLine();
Console.WriteLine("===== Channel：生产者/消费者的现代答案 =====");
var channel = System.Threading.Channels.Channel.CreateBounded<string>(4);
var producer = Task.Run(async () =>
{
    foreach (var msg in new[] { "任务A", "任务B", "任务C", "完成" })
    {
        await channel.Writer.WriteAsync(msg);     // 满了就等（背压）
        Console.WriteLine($"  [生产] {msg}");
    }
});
var consumer = Task.Run(async () =>
{
    await foreach (var msg in channel.Reader.ReadAllAsync())
    {
        Console.WriteLine($"  [消费] {msg}");
        if (msg == "完成") break;
    }
});
await Task.WhenAll(producer, consumer);
Console.WriteLine("  Channel 替代 BlockingQueue：异步等待而不是占线程阻塞");

Console.WriteLine();
Console.WriteLine("===== 死锁的样子（演示锁顺序，不真死锁）=====");
Console.WriteLine("  线程1: lock(A) → 想拿 B；线程2: lock(B) → 想拿 A → 互相等到天荒地老");
Console.WriteLine("  预防：全局约定加锁顺序（如按锁对象 Id 排序）、用超时 Monitor.TryEnter、减少嵌套");
Console.WriteLine("  lock(obj1) { lock(obj2) {...} } 这种嵌套每多一层，死锁概率翻倍");
