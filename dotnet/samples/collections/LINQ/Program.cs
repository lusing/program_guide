// LINQ 查询示例
// 文件位置: samples/collections/LINQ/Program.cs

using System;
using System.Collections.Generic;
using System.Linq;

// 测试数据
var students = new List<Student>
{
    new Student { Name = "Alice", Age = 20, Grade = 85 },
    new Student { Name = "Bob", Age = 22, Grade = 92 },
    new Student { Name = "Charlie", Age = 19, Grade = 78 },
    new Student { Name = "David", Age = 21, Grade = 88 },
    new Student { Name = "Eve", Age = 20, Grade = 95 }
};

// 查询表达式语法
var highScorers = from s in students
                  where s.Grade > 80
                  orderby s.Grade descending
                  select s;

// 方法语法
var youngStudents = students
    .Where(s => s.Age < 21)
    .OrderBy(s => s.Name)
    .ToList();

// 转换
var names = students.Select(s => s.Name).ToList();
var nameAndGrade = students.Select(s => new { s.Name, s.Grade }).ToList();

// 分组
var groupedByAge = students.GroupBy(s => s.Age).ToList();
foreach (var group in groupedByAge)
{
    Console.WriteLine($"年龄 {group.Key}: {string.Join(", ", group.Select(s => s.Name))}");
}

// 聚合
var count = students.Count();
var averageGrade = students.Average(s => s.Grade);
var maxGrade = students.Max(s => s.Grade);
var min_grade = students.Min(s => s.Grade);

// 投影
var summaries = students.Select(s => new
{
    s.Name,
    Level = s.Grade >= 90 ? "优秀" : s.Grade >= 80 ? "良好" : "一般"
}).ToList();

// 联接
var courses = new List<Course>
{
    new Course { StudentName = "Alice", CourseName = "Math" },
    new Course { StudentName = "Bob", CourseName = "Physics" },
    new Course { StudentName = "Alice", CourseName = "Chemistry" }
};

var joinResult = students
    .Join(courses,
        s => s.Name,
        c => c.StudentName,
        (s, c) => new { s.Name, c.CourseName })
    .ToList();

// 分页
var page1 = students.OrderBy(s => s.Name).Skip(1).Take(2).ToList();

// 特殊查询
var distinctAges = students.Select(s => s.Age).Distinct().ToList();
var allAgesArePositive = students.All(s => s.Age > 0);
var anyAbove90 = students.Any(s => s.Grade > 90);

// 元素操作
var firstStudent = students.First();
var lastStudent = students.Last();
var secondStudent = students.Skip(1).Take(1).First();

// 模式匹配 (C# 9+)
var patternResult = students
    .Select(s => s switch
    {
        { Grade: >= 90 } => $"{s.Name} - 优秀",
        { Grade: >= 80 } => $"{s.Name} - 良好",
        _ => $"{s.Name} - 需要努力"
    })
    .ToList();

// 类: Student 和 Course
class Student
{
    public string Name { get; set; } = string.Empty;
    public int Age { get; set; }
    public int Grade { get; set; }
}

class Course
{
    public string StudentName { get; set; } = string.Empty;
    public string CourseName { get; set; } = string.Empty;
}