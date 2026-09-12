// 方法示例
// 文件位置: samples/basics/Methods/Program.cs

// 基本方法
int Add(int a, int b)
{
    return a + b;
}

// 返回值方法
string GetMessage() => "Hello from method!";

// out 参数
void Divide(int a, int b, out int result)
{
    result = a / b;
}

// ref 参数
void Increment(ref int value)
{
    value++;
}

// params 参数
int Sum(params int[] numbers)
{
    int total = 0;
    foreach (var num in numbers)
    {
        total += num;
    }
    return total;
}

// 可选参数
string Greet(string name, string prefix = "Mr.", int times = 1)
{
    return string.Join(" ", Enumerable.Repeat($"{prefix} {name}", times));
}

// async 方法
async Task<int> GetValueAsync()
{
    await Task.Delay(100);
    return 42;
}

// 泛型方法
T GetDefault<T>() => default(T);

T Identity<T>(T value) => value;

// 主方法的多种写法

// 传统写法
static void Main(string[] args)
{
    Console.WriteLine("传统 Main 方法");
}

// 简化写法 (C# 9+)
// 顶层语句无需 Main 方法
Console.WriteLine("使用顶层语句");

// 测试方法
Console.WriteLine($"10 + 20 = {Add(10, 20)}");
Console.WriteLine(GetMessage());

Divide(10, 3, out int quotient);
Console.WriteLine($"10 / 3 = {quotient}");

int num = 5;
Increment(ref num);
Console.WriteLine($"递增后: {num}");

Console.WriteLine($"总和: {Sum(1, 2, 3, 4, 5)}");
Console.WriteLine(Greet("Alice"));
Console.WriteLine(Greet("Bob", prefix: "Dr.", times: 3));

// 泛型方法调用
Console.WriteLine($"默认 int: {GetDefault<int>()}");
Console.WriteLine($"默认 string: {GetDefault<string>()}");
Console.WriteLine($"Identity: {Identity(123)}");