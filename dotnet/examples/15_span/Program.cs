var text = "10,20,30,40";
ReadOnlySpan<char> span = text.AsSpan();
var sum = 0;
var start = 0;

for (var i = 0; i <= span.Length; i++)
{
    if (i == span.Length || span[i] == ',')
    {
        var part = span[start..i];
        sum += int.Parse(part);
        start = i + 1;
    }
}

Span<int> data = stackalloc int[3];
data[0] = 7;
data[1] = 8;
data[2] = 9;
Console.WriteLine($"sum={sum}, last={data[^1]}");

