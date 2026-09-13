static async Task<int> WorkAsync(int n)
{
    await Task.Delay(10);
    return n * n;
}

var tasks = Enumerable.Range(1, 5).Select(WorkAsync);
var results = await Task.WhenAll(tasks);
Console.WriteLine(string.Join(", ", results));

await foreach (var x in SequenceAsync())
{
    Console.Write($"{x} ");
}
Console.WriteLine();

static async IAsyncEnumerable<int> SequenceAsync()
{
    for (int i = 1; i <= 3; i++)
    {
        await Task.Delay(5);
        yield return i;
    }
}

