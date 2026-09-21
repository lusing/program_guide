// 07 · 数组与枚举：最底层的一组数据 + 常量的类型化
Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===== 数组的三种形态 =====");
int[] one = { 5, 3, 8, 1 };                        // 一维（长度固定，创建即定）
int[,] grid = { { 1, 2 }, { 3, 4 } };              // 多维（矩形，每行同长）
int[][] jagged = { new[] { 1 }, new[] { 1, 2 }, new[] { 1, 2, 3 } };  // 交错（数组的数组）
Console.WriteLine($"一维 {one.Length} 个；多维 {grid.GetLength(0)}×{grid.GetLength(1)}；交错各行 {string.Join("/", jagged.Select(r => r.Length))}");

Console.WriteLine();
Console.WriteLine("===== Array 类的常用操作 =====");
Array.Sort(one);
Console.WriteLine($"排序后: [{string.Join(", ", one)}]");
Array.Reverse(one);
Console.WriteLine($"反转后: [{string.Join(", ", one)}]");
Console.WriteLine($"二分查找 8 的下标: {Array.BinarySearch(one, 8)}（要求已排序——先 Sort 再查）");
Console.WriteLine("  提示：日常集合优先 List<T>/Dictionary<,>（第 12 章泛型），数组胜在固定长度与性能");

Console.WriteLine();
Console.WriteLine("===== 枚举：给整数起名字 =====");
var lv = Level.High;
Console.WriteLine($"值: {lv}，底层值: {(int)lv}，名字: {lv.ToString()}");
Console.WriteLine($"从数字还原: {(Level)1}");
Console.WriteLine($"Enum.TryParse(\"High\"): {Enum.TryParse<Level>("High", out var parsed)} → {parsed}");

Console.WriteLine();
Console.WriteLine("===== [Flags]：位标志枚举 =====");
var mine = Perms.Read | Perms.Write;
Console.WriteLine($"组合: {mine}");
Console.WriteLine($"HasFlag(Read): {mine.HasFlag(Perms.Read)}, HasFlag(Exec): {mine.HasFlag(Perms.Exec)}");
Console.WriteLine($"去掉 Write 后: {mine & ~Perms.Write}");

// 类型声明统一放在顶层语句之后
enum Level { Low = 0, Mid = 1, High = 2 }

[Flags]
enum Perms { None = 0, Read = 1, Write = 2, Exec = 4 }
