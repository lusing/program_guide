// 集合示例 - List
// 文件位置: samples/collections/List/Program.cs

using System;
using System.Collections.Generic;
using System.Linq;

// 测试数据
var fruits = new List<string> { "Apple", "Banana", "Cherry" };

// 添加元素
fruits.Add("Date");
fruits.Insert(1, "Blueberry");

// 删除元素
fruits.Remove("Banana");
fruits.RemoveAt(0);
var removed = fruits.PopIfMatch(f => f == "Date"); // 自定义扩展

// 查找元素
bool hasApple = fruits.Contains("Apple");
int cherryIndex = fruits.IndexOf("Cherry");

// 遍历
foreach (var fruit in fruits)
{
    Console.WriteLine(fruit);
}

// LINQ 查询
var sorted = fruits.OrderBy(f => f.Length).ToList();
var withA = fruits.Where(f => f.Contains('a')).ToList();
var count = fruits.Count(f => f.Length > 5);

// 转换
var upperFruits = fruits.Select(f => f.ToUpper()).ToList();
var indexed = fruits.Select((fruit, index) => new { Index = index, Fruit = fruit }).ToList();

// 分组
var words = new List<string> { "apple", "avocado", "banana", "apricot" };
var grouped = words.GroupBy(w => w[0]).ToDictionary(g => g.Key, g => g.ToList());

// 合并
var moreFruits = new List<string> { "Elderberry", "Fig" };
var allFruits = fruits.Concat(moreFruits).ToList();

// 集合运算
var set1 = new HashSet<int> { 1, 2, 3, 4 };
var set2 = new HashSet<int> { 3, 4, 5, 6 };
var union = set1.Union(set2).ToList();
var intersection = set1.Intersect(set2).ToList();
var difference = set1.Except(set2).ToList();

// 确保容量
var list = new List<int>(capacity: 100);
for (int i = 0; i < 50; i++)
{
    list.Add(i);
}

// 使用 RemoveAll
var numbers = new List<int> { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
numbers.RemoveAll(n => n % 2 == 0); // 移除所有偶数

// 扩展方法: Pop
public static class ListExtensions
{
    public static T? Pop<T>(this List<T> list)
    {
        if (list.Count == 0) return default;
        var item = list[list.Count - 1];
        list.RemoveAt(list.Count - 1);
        return item;
    }

    public static T? PopIfMatch<T>(this List<T> list, Func<T, bool> predicate)
    {
        var index = list.FindIndex(predicate);
        if (index == -1) return default;
        var item = list[index];
        list.RemoveAt(index);
        return item;
    }
}