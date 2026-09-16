using System.Numerics;

static T Sum<T>(IEnumerable<T> source) where T : INumber<T>
{
    var total = T.Zero;
    foreach (var item in source)
    {
        total += item;
    }
    return total;
}

var sum = Sum(new[] {1, 2, 3, 4, 5});
Console.WriteLine($"sum={sum}");
Console.WriteLine(new string("dotnet".Reverse().ToArray()));
