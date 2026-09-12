// 控制流示例
// 文件位置: samples/basics/ControlFlow/Program.cs

// if-else 语句
int number = 10;

if (number > 0)
{
    Console.WriteLine("正数");
}
else if (number < 0)
{
    Console.WriteLine("负数");
}
else
{
    Console.WriteLine("零");
}

// switch 表达式 (C# 8+)
string result = number switch
{
    > 0 => "正数",
    < 0 => "负数",
    _ => "零"
};

// 模式匹配 (C# 10+)
object value = "Hello";
string patternMatch = value switch
{
    string s when s.Length > 5 => "长字符串",
    string s => "短字符串",
    int _ => "整数",
    _ => "其他类型"
};

// foreach 循环
var fruits = new[] { "Apple", "Banana", "Cherry" };
foreach (var fruit in fruits)
{
    Console.WriteLine(fruit);
}

// for 循环
for (int i = 0; i < 5; i++)
{
    Console.WriteLine($"计数: {i}");
}

// while 循环
int counter = 0;
while (counter < 3)
{
    Console.WriteLine($" WHILE: {counter}");
    counter++;
}

// do-while 循环
int doCounter = 0;
do
{
    Console.WriteLine($"DO WHILE: {doCounter}");
    doCounter++;
} while (doCounter < 3);

// break 和 continue
for (int i = 0; i < 10; i++)
{
    if (i == 3) continue;  // 跳过 3
    if (i == 7) break;     // 停止在 7
    Console.WriteLine(i);
}

// 实体模式匹配 (C# 10+)
var person = new { Name = "Alice", Age = 25 };
string personDescription = person switch
{
    { Name: "Alice" } => "找到 Alice",
    { Age: >= 18 } => "成年人",
    _ => "其他人"
};

// 位置模式匹配 (C# 10+)
var point = (X: 3, Y: 4);
string position = point switch
{
    (0, 0) => "原点",
    (0, _) => "Y轴",
    (_, 0) => "X轴",
    (_, _) when point.X == point.Y => "对角线",
    (_, _) => "普通点"
};