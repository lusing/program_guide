var fruits = new List<string> {"Apple", "Banana", "Cherry"};
fruits.Add("Date");
fruits.Insert(1, "Blueberry");
fruits.Remove("Banana");

var removed = fruits.PopIfMatch(x => x == "Date");
Console.WriteLine($"removed={removed ?? "none"}");

var ages = new Dictionary<string, int>
{
    ["Alice"] = 25,
    ["Bob"] = 30,
    ["Charlie"] = 35
};
ages["David"] = 40;
ages.TryAdd("Grace", 50);
ages.Remove("Charlie");

var namesLongerThan3 = ages
    .Where(kvp => kvp.Key.Length > 3)
    .Select(kvp => kvp.Key)
    .OrderBy(x => x)
    .ToList();

var students = new List<Student>
{
    new("Alice", 20, 85),
    new("Bob", 22, 92),
    new("Charlie", 19, 78),
    new("David", 21, 88),
    new("Eve", 20, 95)
};

var highScorers = students
    .Where(s => s.Grade > 80)
    .OrderByDescending(s => s.Grade)
    .Select(s => $"{s.Name}:{s.Grade}")
    .ToList();

var groupedByAge = students.GroupBy(s => s.Age);
foreach (var group in groupedByAge)
{
    Console.WriteLine($"age {group.Key}: {string.Join(", ", group.Select(s => s.Name))}");
}

Console.WriteLine($"names={string.Join("/", namesLongerThan3)}");
Console.WriteLine($"high={string.Join(" | ", highScorers)}");

record Student(string Name, int Age, int Grade);

static class ListExtensions
{
    public static T? PopIfMatch<T>(this List<T> list, Predicate<T> predicate)
    {
        var index = list.FindIndex(predicate);
        if (index < 0) return default;
        var value = list[index];
        list.RemoveAt(index);
        return value;
    }
}
