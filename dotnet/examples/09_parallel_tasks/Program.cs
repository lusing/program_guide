using System.Collections.Concurrent;
using System.Threading;

var nums = Enumerable.Range(1, 1000).ToArray();
var dict = new ConcurrentDictionary<int, int>();
int total = 0;

Parallel.ForEach(nums, n =>
{
    var sq = n * n;
    dict[n] = sq;
    Interlocked.Add(ref total, n);
});

Console.WriteLine($"count={dict.Count}, total={total}");

