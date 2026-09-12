// 集合示例 - Dictionary
// 文件位置: samples/collections/Dictionary/Program.cs

using System;
using System.Collections.Generic;
using System.Linq;

// 创建字典
var ages = new Dictionary<string, int>
{
    ["Alice"] = 25,
    ["Bob"] = 30,
    ["Charlie"] = 35
};

// 添加元素
ages["David"] = 40;
ages.Add("Eve", 45);

// 访问元素
Console.WriteLine($"Alice 的年龄: {ages["Alice"]}");
Console.WriteLine($"使用 TryGetValue:");
if (ages.TryGetValue("Bob", out int bobAge))
{
    Console.WriteLine($"Bob 的年龄: {bobAge}");
}

// 检查键是否存在
bool hasAlice = ages.ContainsKey("Alice");
bool hasGrace = ages.ContainsKey("Grace");

// 检查值是否存在
bool hasAge30 = ages.ContainsValue(30);

// 删除元素
ages.Remove("Charlie");

// 遍历
foreach (var kvp in ages)
{
    Console.WriteLine($"{kvp.Key}: {kvp.Value}");
}

// LINQ 查询
var namesLongerThan3 = ages.Where(kvp => kvp.Key.Length > 3).Select(kvp => kvp.Key).ToList();
var averageAge = ages.Values.Average();

// 字典转换
var reversed = ages.ToDictionary(kvp => kvp.Value, kvp => kvp.Key);

// 默认值
var defaultValue = ages.GetValueOrDefault("Frank", -1);

// 使用 TryAdd (C# 9+)
ages.TryAdd("Alice", 100); // Alice 已存在，不会添加
ages.TryAdd("Grace", 50);  // Grace 不存在，会添加

// 字典初始化器 (C# 12+)
var settings = new Dictionary<string, string>
{
    ["Theme"] = "Dark",
    ["Language"] = "Chinese"
};

// 并行遍历 (PLINQ)
var parallelResult = ages.AsParallel()
    .Where(kvp => kvp.Value > 30)
    .Select(kvp => kvp.Key)
    .ToList();

// 字典合并
var dict1 = new Dictionary<string, int> { ["A"] = 1, ["B"] = 2 };
var dict2 = new Dictionary<string, int> { ["C"] = 3, ["D"] = 4 };
var merged = dict1.Concat(dict2).ToDictionary(k => k.Key, v => v.Value);

// 尝试移除并获取值 (C# 10+)
ages.TryRemove("Bob", out int removedValue);