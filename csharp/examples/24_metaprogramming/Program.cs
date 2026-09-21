// 24 · 元编程：dynamic、源生成器模式与编译期能力
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== dynamic：编译器闭眼，运行时解析 =====");
dynamic d = 1;
Console.WriteLine($"  d 是 int: {d + 1}");
d = "现在我是字符串";                       // 同一变量随意换类型（编译器不再检查）
Console.WriteLine($"  d 变 string: {d.ToUpper()}");
Console.WriteLine("  代价：没有 IntelliSense、没有编译期检查、有运行时开销");
Console.WriteLine("  合理用途：与动态语言/COM 互操作；业务代码别用");

Console.WriteLine();
Console.WriteLine("===== ExpandoObject：运行时长出成员 =====");
dynamic bag = new System.Dynamic.ExpandoObject();
bag.Name = "小明";
bag.Hello = (Action)(() => Console.WriteLine($"  你好，{bag.Name}"));
bag.Hello();
Console.WriteLine("  成员运行时添加——动态对象的字典本质");

Console.WriteLine();
Console.WriteLine("===== 编译期元编程的家底 =====");
Console.WriteLine("  泛型（第 12 章）    → 编译期生成强类型代码");
Console.WriteLine("  lambda/表达式树（第 15 章）→ 代码即数据");
Console.WriteLine("  反射（第 23 章）    → 运行时读元数据");
Console.WriteLine("  源生成器（本节主角）→ 编译期间生成新 C# 代码并入编译");

Console.WriteLine();
Console.WriteLine("===== 源生成器的机制：partial + 编译期代码生成 =====");
// 源生成器看到的输入：partial 类 + 特性标注
// 它在编译期生成另一半 partial 代码（下面 GeneratedHalf 就是"模拟产物"）
var person = new Person("张三", 24) with { Age = 25 };
Console.WriteLine($"  使用生成代码: {person.ToJson()}");
Console.WriteLine("  —— ToJson 不在源文件里写：模拟源生成器为 record 生成的序列化方法");

Console.WriteLine();
Console.WriteLine("===== 真实世界的源生成器 =====");
Console.WriteLine("  System.Text.Json 的 JsonSerializerContext（第 33 章实操）");
Console.WriteLine("  CommunityToolkit.Mvvm 的 [ObservableProperty]（WPF 教程 11 章提过）");
Console.WriteLine("  正则的 [GeneratedRegex]——编译期生成匹配器，快过运行时编译");
Console.WriteLine("  共同卖点：零反射、AOT 友好、启动快——反射的现代替代品");

Console.WriteLine();
Console.WriteLine("===== 为什么源生成器赢了运行时生成 =====");
Console.WriteLine("  反射 Emit / 表达式树编译：运行时开销 + AOT 不可用");
Console.WriteLine("  源生成器：编译期一次付清，运行时全是普通代码");

public sealed record Person(string Name, int Age);

// 模拟"源生成器产物"：真实生成器把这样的代码写进 obj/../Generated/*.g.cs
public static partial class PersonJsonExtensions
{
    public static string ToJson(this Person p)
        => $$"""{"Name":"{{p.Name}}","Age":{{p.Age}}}""";
}
