var data = new[]
{
    new {Name = "alice", Score = 92},
    new {Name = "bob", Score = 78},
    new {Name = "carol", Score = 86},
    new {Name = "dave", Score = 92}
};

var passed = data
    .Where(x => x.Score >= 80)
    .OrderByDescending(x => x.Score)
    .ThenBy(x => x.Name)
    .Select(x => $"{x.Name}:{x.Score}")
    .ToList();

var groups = data.GroupBy(x => x.Score >= 90 ? "A" : "B");
foreach (var g in groups)
{
    Console.WriteLine($"{g.Key}: {string.Join(", ", g.Select(x => x.Name))}");
}
Console.WriteLine(string.Join(" | ", passed));

