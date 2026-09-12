// Hello World 示例
// 文件位置: samples/basics/Hello/Program.cs

// 使用语句
using System;

// 主程序
Console.WriteLine("Hello, .NET 10!");

// 字符串插值
string name = "世界";
Console.WriteLine($"你好, {name}!");

// 格式化数字
double pi = 3.14159;
Console.WriteLine($"Pi 的值: {pi:F2}");

// 多行字符串 (C# 11+)
string multiLine = """
    这是多行字符串
    可以包含
    任意内容
    """;
Console.WriteLine(multiLine);

// 原始字符串字面量 (C# 11+)
string xml = """
    <root>
        <item>value</item>
    </root>
    """;
Console.WriteLine(xml);