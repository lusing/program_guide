// 26 · Span<T> 与高性能内存：切视图而不是拷数据
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== Span 是什么：数组/字符串的「窗口」 =====");
var array = new[] { 10, 20, 30, 40, 50 };
Span<int> all = array;                 // 不拷贝：指向同一块内存的视图
Span<int> middle = all.Slice(1, 3);    // 切出 [20,30,40]
middle[0] = 99;                        // 通过窗口改，原数组跟着变
Console.WriteLine($"  切片改值后原数组: [{string.Join(",", array)}]");

Console.WriteLine();
Console.WriteLine("===== ReadOnlySpan<char>：零分配的字符串解析 =====");
var line = "编号=1024;名称=张三";
foreach (var token in line.Split(';'))
{
    var eq = token.IndexOf('=');
    var key = token.AsSpan(0, eq);     // 不产生新字符串！
    var value = token.AsSpan(eq + 1);
    Console.WriteLine($"  {key} = {value}（key.Length={key.Length}，零分配）");
}
Console.WriteLine("  传统 Substring 每次都分配新串；Span 只是窗口——热路径的省账利器");

Console.WriteLine();
Console.WriteLine("===== stackalloc：栈上分配小块临时内存 =====");
Span<byte> buffer = stackalloc byte[8];
for (var i = 0; i < buffer.Length; i++) buffer[i] = (byte)(i * 3);
Console.WriteLine($"  栈上 buffer: [{string.Join(",", buffer.ToArray())}]");
Console.WriteLine("  规则：小（≤1KB 量级）、生命周期限于本方法 → stackalloc；大了或要跨方法 → 数组");

Console.WriteLine();
Console.WriteLine("===== Memory<T>：能跨 await 的 Span =====");
async Task<int> SumLaterAsync()
{
    Memory<int> mem = new[] { 1, 2, 3, 4 };    // Span 不能进 async 方法（栈语义），Memory 可以
    await Task.Yield();
    var s = 0;
    foreach (var v in mem.Span) s += v;        // 用时再取 Span（Span 没有 LINQ，手写循环最快）
    return s;
}
Console.WriteLine($"  Memory 跨 await 求和: {await SumLaterAsync()}   ← Span 做不到（栈语义不许跨 await）");

Console.WriteLine();
Console.WriteLine("===== ArrayPool：大缓冲区反复租还 =====");
var pool = System.Buffers.ArrayPool<int>.Shared;
var rented = pool.Rent(1024);
try
{
    for (var i = 0; i < 5; i++) rented[i] = i * i;
    Console.WriteLine($"  租的缓冲区前 5 个: [{string.Join(",", rented.AsSpan(0, 5).ToArray())}]（容量 {rented.Length}）");
}
finally { pool.Return(rented); }               // 还回去复用，下次 Rent 可能拿同一块
Console.WriteLine("  适用：高频创建大数组的场景（网络缓冲、序列化中间区）");

Console.WriteLine();
Console.WriteLine("===== 分配量对比（GC.GetAllocatedBytesForCurrentThread）=====");
var before = GC.GetAllocatedBytesForCurrentThread();
var parts = new List<string>();
for (var i = 0; i < 1_000; i++) parts.Add("row" + i);        // 字符串拼接：每次分配
var afterSubstring = GC.GetAllocatedBytesForCurrentThread();
Console.WriteLine($"  1000 次字符串操作分配: {afterSubstring - before:N0} 字节");
Console.WriteLine("  Span 方案把这些分配中的大部分变成 0——解析器/日志/协议处理的第一优化手段");
