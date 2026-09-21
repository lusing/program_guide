// 16 · LINQ 基础：对集合的声明式查询
Console.OutputEncoding = System.Text.Encoding.UTF8;

var employees = new List<Employee>
{
    new("张三", "研发", 18000, 24),
    new("李四", "设计", 15000, 31),
    new("王五", "研发", 21000, 46),
    new("赵六", "测试", 13000, 28),
    new("孙七", "研发", 17500, 35),
};

Console.WriteLine("===== 方法链（最常用）=====");
var result = employees
    .Where(e => e.Department == "研发")          // 过滤
    .OrderByDescending(e => e.Salary)            // 排序
    .Select(e => new { e.Name, e.Salary });      // 投影成匿名类型
foreach (var r in result)
    Console.WriteLine($"  {r.Name}: {r.Salary:N0}");

Console.WriteLine();
Console.WriteLine("===== 查询语法（同一件事的 SQL 脸）=====");
var result2 = from e in employees
              where e.Department == "研发"
              orderby e.Salary descending
              select new { e.Name, e.Salary };
Console.WriteLine($"  两种写法结果一致: {result.Count() == result2.Count()}（编译后完全相同，查询语法会被翻译成方法链）");

Console.WriteLine();
Console.WriteLine("===== 高频操作符速查 =====");
Console.WriteLine($"  Count(研发): {employees.Count(e => e.Department == "研发")}");
Console.WriteLine($"  First(薪水>20k): {employees.First(e => e.Salary > 20000).Name}");
Console.WriteLine($"  FirstOrDefault(薪水>99k): {employees.FirstOrDefault(e => e.Salary > 99000)?.Name ?? "(null，不抛异常)"}");
Console.WriteLine($"  Any(年龄>45): {employees.Any(e => e.Age > 45)}");
Console.WriteLine($"  Max/Min/Avg 薪水: {employees.Max(e => e.Salary):N0} / {employees.Min(e => e.Salary):N0} / {employees.Average(e => e.Salary):N0}");
Console.WriteLine($"  Contains(李四): {employees.Select(e => e.Name).Contains("李四")}");

Console.WriteLine();
Console.WriteLine("===== 延迟执行：定义时不跑，消费时才跑 =====");
var query = employees.Where(e => e.Salary > 16000);
Console.WriteLine($"  定义后 count={query.Count()}   ← 第一次求值");
employees.Add(new Employee("新来的", "研发", 30000, 30));
Console.WriteLine($"  集合变了再数 count={query.Count()}   ← 第二次求值，结果变了！");
Console.WriteLine("  query 不是结果快照，是「如何算」的配方——每次枚举重新执行");

Console.WriteLine();
Console.WriteLine("===== 立即执行：ToList/ToArray/ToDictionary 定格 =====");
var frozen = employees.Where(e => e.Salary > 16000).ToList();   // 立刻执行并装入列表
employees.Add(new Employee("更后来的", "设计", 40000, 29));
Console.WriteLine($"  ToList 后再加人: {frozen.Count}（不再受集合变化影响）");

record Employee(string Name, string Department, decimal Salary, int Age);
