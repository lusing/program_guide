// 变量和数据类型示例
// 文件位置: samples/basics/Variables/Program.cs

// 基本数据类型
int age = 25;
double price = 19.99;
decimal money = 99.99m;
float rate = 3.14f;
bool isActive = true;
char initial = 'A';
string name = "Alice";

// Nullable 类型
int? nullableNumber = null;
DateTime? birthDate = null;

// 隐式类型 var
var count = 10;        // 推断为 int
var text = "Hello";    // 推断为 string
var person = new { Name = "Bob", Age = 30 };  // 匿名类型

// 字面量改进 (C# 10+)
var bigNumber = 1_000_000;     // 下划线作为分隔符
var binary = 0b0010_1010;      // 二进制字面量
var hex = 0xFF;                // 十六进制

// 数组
int[] numbers = { 1, 2, 3, 4, 5 };
string[] names = new string[3];

// 字符串操作
string sentence = "Hello, World!";
Console.WriteLine(sentence.Length);
Console.WriteLine(sentence.ToUpper());
Console.WriteLine(sentence.Replace("World", "NET 10"));

// 插值字符串
string city = "Beijing";
int year = 2024;
Console.WriteLine($"{city} 在 {year} 年很美好");

// 旋转字符串 (C# 11+)
string rotated = "Hello"[..2] + "Hello"[2..];  // "lloHe"
Console.WriteLine(rotated);