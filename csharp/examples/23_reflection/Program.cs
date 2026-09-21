// 23 · 反射与特性：程序在运行时读取自己的元数据
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== Type：一切反射的入口 =====");
Type t1 = typeof(Worker);               // 编译期已知类型
Worker w = new("反射");
Type t2 = w.GetType();                  // 运行期取实例的真身
Console.WriteLine($"  typeof 与 GetType 同指: {t1 == t2}（{t1.FullName}）");
Console.WriteLine($"  是否类/抽象/密封: {t1.IsClass}, {t1.IsAbstract}, {t1.IsSealed}");

Console.WriteLine();
Console.WriteLine("===== 枚举成员 =====");
foreach (var p in typeof(Worker).GetProperties())
    Console.WriteLine($"  属性 {p.PropertyType.Name,-7} {p.Name}");
foreach (var m in typeof(Worker).GetMethods(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.DeclaredOnly))
    if (!m.IsSpecialName) Console.WriteLine($"  方法 {m.ReturnType.Name,-7} {m.Name}()");

Console.WriteLine();
Console.WriteLine("===== 特性（Attribute）：贴在代码上的元数据 =====");
foreach (var attr in typeof(Worker).GetCustomAttributes(false))
    if (attr is AuthorAttribute a)
        Console.WriteLine($"  [Author] 作者={a.Name}, 版本={a.Version}");

Console.WriteLine();
Console.WriteLine("===== 动态实例化与调用 =====");
var obj = Activator.CreateInstance(typeof(Worker), "动态造的")!;
var method = obj.GetType().GetMethod("Greet")!;
Console.WriteLine($"  反射调用 Greet: {method.Invoke(obj, Array.Empty<object>())}");

var prop = obj.GetType().GetProperty("Name")!;
Console.WriteLine($"  反射读属性 Name: {prop.GetValue(obj)}");
prop.SetValue(obj, "改过的");
Console.WriteLine($"  反射写属性后: {((Worker)obj).Name}   ← Activator 返回 object，取具体成员先强转");

Console.WriteLine();
Console.WriteLine("===== typeof vs nameof vs GetType =====");
Console.WriteLine("  typeof(Worker)  → Type 对象（数据）");
Console.WriteLine("  nameof(Worker)  → \"Worker\"（字符串，编译期，重构安全）");
Console.WriteLine("  w.GetType()     → 实例运行时的真身（可能是子类）");

Console.WriteLine();
Console.WriteLine("===== 性能与边界 =====");
Console.WriteLine("  反射比直接调用慢一个数量级以上——热路径缓存 MethodInfo 或改用委托缓存");
Console.WriteLine("  Trimmed/AOT 场景反射受限——第 24 章源生成器是替代路线");
Console.WriteLine("  反射能绕过访问修饰符的很多门——序列化器/DI 容器靠它，但别拿来破坏封装");

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Struct)]
public sealed class AuthorAttribute(string name) : Attribute
{
    public string Name { get; } = name;
    public double Version { get; set; }
}

[Author("张三", Version = 1.2)]
public class Worker(string name)
{
    public string Name { get; set; } = name;
    public int Age { get; set; }

    public string Greet() => $"你好，我是 {Name}";
}
