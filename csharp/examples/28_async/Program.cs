// 28 · async/await：异步的"表象"与"内脏"
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 同步 vs 异步：谁占着线程 =====");
static void SyncWork()
{
    Console.WriteLine($"  [同步] 线程 {Environment.CurrentManagedThreadId} 被 Sleep 占住 300ms");
    Thread.Sleep(300);
}
static async Task AsyncWork()
{
    Console.WriteLine($"  [异步前] 线程 {Environment.CurrentManagedThreadId}");
    await Task.Delay(300);                    // 挂起：线程被释放去干别的
    Console.WriteLine($"  [异步后] 线程 {Environment.CurrentManagedThreadId}（控制台无 UI 上下文，可能换线程）");
}
SyncWork();
await AsyncWork();

Console.WriteLine();
Console.WriteLine("===== await 的本质：方法的「拆段」 =====");
Console.WriteLine("""
  你写的：                         编译器改写的（状态机）：
  async Task F()                    async Task F()
  {                                 {
      A();                              A();
      await Slow();        ──►          var t = Slow();
      B();                              await t;  // 此处"断开"：先返回，
  }                                      //        完成后从这继续 B();
                                         B();
                                     }
  """);
Console.WriteLine("  关键：await 不是「等待阻塞」，是「挂起让路」——方法提前返回，完成后续体排队续跑");

Console.WriteLine();
Console.WriteLine("===== 顺序 await vs 并行启动 =====");
var sw = System.Diagnostics.Stopwatch.StartNew();
await Task.Delay(200);
await Task.Delay(200);
Console.WriteLine($"  顺序 await 两个 200ms: {sw.ElapsedMilliseconds}ms");

sw.Restart();
var t1 = Task.Delay(200);            // 先启动（任务已在跑）
var t2 = Task.Delay(200);
await Task.WhenAll(t1, t2);          // 再等待
Console.WriteLine($"  并行启动再等待:    {sw.ElapsedMilliseconds}ms   ← 差别就是「先启动还是先等」");

Console.WriteLine();
Console.WriteLine("===== async 签名的纪律 =====");
Console.WriteLine("  public API 一律返回 Task/Task<T>，不要 async void（异常没人接）");
Console.WriteLine("  async void 只给事件处理器（框架契约）——WPF 教程 21 章同款规则");
Console.WriteLine("  库代码里 await 后接 ConfigureAwait(false) 防上下文捕获；UI 代码不接");

Console.WriteLine();
Console.WriteLine("===== 异步流：await foreach =====");
static async IAsyncEnumerable<int> ProduceAsync()
{
    for (var i = 1; i <= 3; i++)
    {
        await Task.Delay(50);        // 模拟异步生产（网络/文件）
        yield return i * 10;
    }
}
await foreach (var item in ProduceAsync())
    Console.WriteLine($"  收到 {item}");
Console.WriteLine("  IAsyncEnumerable<T>：异步版的迭代器（第 18 章 yield 的异步形态）");
