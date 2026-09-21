// 06 · 字符串深度：不可变、驻留、插值与原始字面量
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 不可变性 =====");
var s1 = "hello";
var s2 = s1.ToUpper();          // 不是"修改 s1"，而是新造一个字符串
Console.WriteLine($"s1 = {s1}, s2 = {s2}   ← 原 string 永远不变，一切「修改」都返回新对象");

Console.WriteLine();
Console.WriteLine("===== 驻留（Intern）：相同字面量共享一个实例 =====");
var lit1 = "abc";
var lit2 = "abc";
Console.WriteLine($"字面量 ReferenceEquals: {ReferenceEquals(lit1, lit2)}   ← 编译期驻留，同一对象");
var built = new string(new[] { 'a', 'b', 'c' });
Console.WriteLine($"运行时构造 ReferenceEquals: {ReferenceEquals(built, lit1)}   ← 不驻留（不同对象）");
Console.WriteLine($"Intern 后: {ReferenceEquals(string.Intern(built), lit1)}");

Console.WriteLine();
Console.WriteLine("===== 插值与格式 =====");
var name = "C#";
var version = 10;
Console.WriteLine($"基础插值: {name} {version}");
Console.WriteLine($"对齐与格式: |{3.14159,10:F2}|   ← 宽度 10、保留 2 位");
Console.WriteLine($"条件表达式直接进: {(version >= 10 ? "新" : "旧")}");

Console.WriteLine();
Console.WriteLine("===== 原始字符串（C# 11）：三引号，无需转义 =====");
var json = """
    { "name": "张三", "tags": ["a", "b"] }
    """;
Console.WriteLine(json);
var withQuote = """"她说："你好"""";   // 内容里有引号：定界符加到 4 个
Console.WriteLine(withQuote);

Console.WriteLine();
Console.WriteLine("===== 字符与编码 =====");
var han = '中';
Console.WriteLine($"'中' 的 Unicode 码点: U+{(int)han:X4}");
Console.WriteLine($"UTF-8 编码字节数: {System.Text.Encoding.UTF8.GetByteCount("中")} 字节");
Console.WriteLine("  string 内部是 UTF-16；char 是 16 位——生僻字/emoji 占两个 char（代理对）");

Console.WriteLine();
Console.WriteLine("===== StringBuilder：循环拼接的正确工具 =====");
var sw = System.Diagnostics.Stopwatch.StartNew();
var bad = "";
for (var i = 0; i < 5_000; i++) bad += i;            // 每次循环都造新 string（演示用，规模已调小）
sw.Stop();
var t1 = sw.ElapsedTicks;
sw.Restart();
var sb = new System.Text.StringBuilder();
for (var i = 0; i < 5_000; i++) sb.Append(i);
var good = sb.ToString();
sw.Stop();
Console.WriteLine($"5000 次拼接: += 耗时 {t1} ticks，StringBuilder {sw.ElapsedTicks} ticks（结果等长 {bad.Length == good.Length}）");
Console.WriteLine("  规律：个位数拼接随意用 +；循环里一律 StringBuilder");
