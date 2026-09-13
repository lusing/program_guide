static (bool ok, int value, string error) ParsePositive(string text)
{
    if (!int.TryParse(text, out var n))
    {
        return (false, 0, "invalid-int");
    }

    return n > 0 ? (true, n, "") : (false, 0, "not-positive");
}

foreach (var input in new[] {"42", "-1", "abc"})
{
    try
    {
        var r = ParsePositive(input);
        Console.WriteLine(r.ok ? $"ok:{r.value}" : $"err:{r.error}");
    }
    catch (Exception ex)
    {
        Console.WriteLine(ex.Message);
    }
}

