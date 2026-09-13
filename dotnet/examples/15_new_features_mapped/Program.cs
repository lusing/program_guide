using System.Diagnostics;
using System.Numerics;
using System.Text;
using System.Text.Json;

Console.WriteLine("=== New Features Mapped ===");

int million = 1_000_000;
int binary = 0b1010_1010;
Console.WriteLine($"million={million}, binary={binary}");

var calc = new Calculator();
Console.WriteLine($"calc={calc.Add(2, 3)}");

var spanText = "apple,banana,cherry".AsSpan();
var comma = spanText.IndexOf(',');
var first = spanText[..comma];
Console.WriteLine($"first={first.ToString()}");

Console.WriteLine($"generic-int={AddNumbers(5, 3)}");
Console.WriteLine($"generic-double={AddNumbers(2.5, 3.5)}");

var person = new Person("Alice", 25);
var json = JsonSerializer.Serialize(person, new JsonSerializerOptions {WriteIndented = false});
Console.WriteLine(json);

var sw = Stopwatch.StartNew();
var sb = new StringBuilder();
for (int i = 0; i < 3000; i++) sb.Append(i);
sw.Stop();
Console.WriteLine($"stringbuilder-ms={sw.ElapsedMilliseconds}");

await foreach (var n in GenerateNumbers())
{
    Console.Write($"{n} ");
}
Console.WriteLine();

static T AddNumbers<T>(T a, T b) where T : INumber<T> => a + b;

static async IAsyncEnumerable<int> GenerateNumbers()
{
    for (int i = 1; i <= 3; i++)
    {
        await Task.Delay(5);
        yield return i;
    }
}

public record Person(string Name, int Age);

partial class Calculator
{
    partial void OnCalculated(int result);

    public int Add(int a, int b)
    {
        var r = a + b;
        OnCalculated(r);
        return r;
    }
}

partial class Calculator
{
    partial void OnCalculated(int result) => Console.WriteLine($"calculated={result}");
}

