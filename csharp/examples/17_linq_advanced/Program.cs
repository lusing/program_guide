// 17 · LINQ 进阶：分组、连接、聚合与自造操作符
Console.OutputEncoding = System.Text.Encoding.UTF8;

var employees = new List<Employee>
{
    new("张三", "研发", 18000), new("李四", "设计", 15000),
    new("王五", "研发", 21000), new("赵六", "测试", 13000),
    new("孙七", "研发", 17500), new("周八", "设计", 16000),
};
var departments = new List<Department>
{
    new("研发", "R&D"), new("设计", "Design"), new("测试", "QA"),
};

Console.WriteLine("===== GroupBy：分组统计 =====");
foreach (var g in employees.GroupBy(e => e.Department))
    Console.WriteLine($"  {g.Key,-4} {g.Count()} 人，平均 {g.Average(e => e.Salary):N0}，最高薪 {g.OrderByDescending(e => e.Salary).First().Name}");
Console.WriteLine("  GroupBy 返回 IGrouping<Key, T>：每个组自带 Key 与组内序列");

Console.WriteLine();
Console.WriteLine("===== Join：两个集合的数据库式连接 =====");
var joined = employees.Join(departments,             // 外表
    e => e.Department,                               // 内键
    d => d.Name,                                     // 外键
    (e, d) => $"{e.Name} → {d.English}");            // 结果选择器
foreach (var row in joined) Console.WriteLine($"  {row}");

Console.WriteLine();
Console.WriteLine("===== SelectMany：压平嵌套 =====");
var teams = new List<Team> { new("A 组", new[] { "甲", "乙" }), new("B 组", new[] { "丙", "丁" }) };
foreach (var member in teams.SelectMany(t => t.Members, (t, m) => $"{t.Name}:{m}"))
    Console.WriteLine($"  {member}");
Console.WriteLine("  两层嵌套 → 一层平铺（对应 SQL 里 SELECT 一对多展平）");

Console.WriteLine();
Console.WriteLine("===== Aggregate：万能聚合（能表达 Sum/Max/…）=====");
var total = employees.Aggregate(0m, (acc, e) => acc + e.Salary);
var longest = new[] { "C#", "Java", "F#" }.Aggregate((a, b) => a.Length >= b.Length ? a : b);
Console.WriteLine($"  薪水总额 {total:N0}；最长名字 {longest}");

Console.WriteLine();
Console.WriteLine("===== 自造操作符：MyWhere 的两种实现 =====");
static IEnumerable<T> MyWhere<T>(IEnumerable<T> source, Func<T, bool> pred)
{
    foreach (var item in source)
        if (pred(item))
            yield return item;          // 迭代器实现（第 18 章拆解原理）
}
var mine = MyWhere(employees, e => e.Salary > 16000).Select(e => e.Name);
Console.WriteLine($"  MyWhere 结果: {string.Join(", ", mine)}——LINQ 操作符没有魔法，就是扩展方法 + yield");

Console.WriteLine();
Console.WriteLine("===== 两个性能坑 =====");
var q = employees.Where(e => e.Salary > 15000);
Console.WriteLine($"  坑1 多次枚举: Count={q.Count()}，Max={q.Max(e => e.Salary):N0}");
Console.WriteLine("    —— 查询被完整跑了两遍！热路径上先 ToList() 缓存再反复用");
Console.WriteLine($"  坑2 判断有无元素: Any()={employees.Any(e => e.Salary > 20000)}");
Console.WriteLine("    —— 用 Any() 而不是 Count() > 0：Any 看到第一个就返回，Count 要数完");

record Employee(string Name, string Department, decimal Salary);
record Department(string Name, string English);
record Team(string Name, string[] Members);
