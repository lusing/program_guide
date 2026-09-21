// 31 · 并行编程：ThreadPool、Parallel 与 PLINQ
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 线程从哪来：ThreadPool =====");
Console.WriteLine($"  线程池当前线程数: {ThreadPool.ThreadCount}");
ThreadPool.QueueUserWorkItem(_ => Console.WriteLine($"  [QueueUserWorkItem] 跑在线程 {Environment.CurrentManagedThreadId}"));
await Task.Delay(100);                             // 给队列任务一点时间打印
Console.WriteLine("  Task.Run 底层就是线程池——别手 new Thread（除非需要前台线程/精细控制）");

Console.WriteLine();
Console.WriteLine("===== Parallel.For：数据并行 =====");
var sw = System.Diagnostics.Stopwatch.StartNew();
var squares = new long[10];
for (var i = 0; i < squares.Length; i++) squares[i] = (long)i * i;   // 串行基线
sw.Restart();
Parallel.For(0, squares.Length, i => squares[i] = (long)i * i);      // 并行版
Console.WriteLine($"  Parallel.For 完成 {squares.Length} 项（前 5: {string.Join(",", squares.AsSpan(0, 5).ToArray())}）");
Console.WriteLine("  语义：把循环体分发给线程池；下标独立、循环体无共享状态才安全");

Console.WriteLine();
Console.WriteLine("===== Parallel.ForEach + 取消 =====");
using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(200));
try
{
    Parallel.ForEach(Enumerable.Range(1, 1000),
        new ParallelOptions { CancellationToken = cts.Token, MaxDegreeOfParallelism = 4 },
        i => Thread.SpinWait(50_000));
}
catch (OperationCanceledException)
{
    Console.WriteLine("  并行循环被取消（Token 传播到所有工作线程）");
}

Console.WriteLine();
Console.WriteLine("===== PLINQ：查询自动并行 =====");
var numbers = Enumerable.Range(1, 2_000_000).ToArray();
sw.Restart();
var seqSum = numbers.Where(n => n % 2 == 0).Sum(n => (long)n);        // LINQ 串行（求和上限超 int，转 long）
var seqTime = sw.ElapsedMilliseconds;
sw.Restart();
var parSum = numbers.AsParallel().Where(n => n % 2 == 0).Sum(n => (long)n);   // PLINQ
Console.WriteLine($"  200 万筛偶求和: 串行 {seqTime}ms vs 并行 {sw.ElapsedMilliseconds}ms（结果一致 {seqSum == parSum}）");
Console.WriteLine("  注意：小数据量并行反而慢（调度开销 > 收益），先量测再切");

Console.WriteLine();
Console.WriteLine("===== 并行度选择 =====");
Console.WriteLine($"  环境 CPU 核数: {Environment.ProcessorCount}");
Console.WriteLine("  CPU 密集 → 默认并行度≈核数；混合 IO → 可超核（MaxDegreeOfParallelism 调高）");
Console.WriteLine("  一切并行改写都要以量测开头、量测收尾——「感觉会快」不算数");
