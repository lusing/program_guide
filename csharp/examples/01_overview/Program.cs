// 01 · C# 与 .NET 全景：这个程序回答"我跑在哪、由什么组成"
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== C# 与 .NET 全景 =====");

// 语言层：编译器把 C# 编译成 IL（中间语言），运行时 JIT 把 IL 编译成机器码
Console.WriteLine("C# 语言版本（编译时由 SDK 决定）: 搭配 .NET 10 的最新版");
Console.WriteLine($"运行时版本: {Environment.Version}");
Console.WriteLine($"CLR 所在目录: {System.Runtime.InteropServices.RuntimeEnvironment.GetRuntimeDirectory()}");

// 平台层：BCL（基础类库）里有什么
Console.WriteLine();
Console.WriteLine("===== 平台信息（BCL 提供）=====");
Console.WriteLine($"操作系统: {System.Runtime.InteropServices.RuntimeInformation.OSDescription}");
Console.WriteLine($"进程架构: {System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture}");
Console.WriteLine($"当前目录: {Environment.CurrentDirectory}");
Console.WriteLine($"GC 代数上限: {System.GC.MaxGeneration}");

// 代码在哪个"程序集"里：一个 csproj 编译成一个 dll/exe
Console.WriteLine();
Console.WriteLine("===== 程序集 =====");
var asm = typeof(Program).Assembly;
Console.WriteLine($"程序集名: {asm.GetName().Name}");
Console.WriteLine($"程序集路径: {asm.Location}");

// 编译期信息：编译成 IL 不直接成机器码，JIT 在运行时才翻译
Console.WriteLine();
Console.WriteLine("===== 一句话总结 =====");
Console.WriteLine("你写 C# → 编译成 IL 装进程序集 → CLR 加载 → JIT 逐方法翻译成机器码 → 跑起来");
Console.WriteLine("本教程 36 章只讲一件事：把这条流水线上的「语言层」讲透。");
