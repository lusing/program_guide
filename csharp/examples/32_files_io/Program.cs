// 32 · 文件与 IO：File、Directory 与 Stream 三层
Console.OutputEncoding = System.Text.Encoding.UTF8;

var dir = Path.Combine(Path.GetTempPath(), "csharp-tutorial-io");
Directory.CreateDirectory(dir);
var file = Path.Combine(dir, "demo.txt");

Console.WriteLine("===== File：一行搞定常用操作 =====");
await File.WriteAllTextAsync(file, "第一行\r\n第二行\r\n");
var content = await File.ReadAllTextAsync(file);
Console.WriteLine($"  写入后读回 {content.Length} 字符: {content.Replace("\r\n", " / ")}");
File.AppendAllText(file, "追加的一行\r\n");
Console.WriteLine($"  追加后: {(await File.ReadAllLinesAsync(file)).Length} 行");
Console.WriteLine($"  存在吗: {File.Exists(file)}；大小 {new FileInfo(file).Length} 字节");

Console.WriteLine();
Console.WriteLine("===== Directory 与 Path =====");
Directory.CreateDirectory(Path.Combine(dir, "子目录"));
foreach (var d in Directory.GetDirectories(dir)) Console.WriteLine($"  子目录: {d}");
Console.WriteLine($"  Path.Combine: {Path.Combine(dir, "a", "b.txt")}   ← 永远用它拼路径，别手写 / 或 \\");
Console.WriteLine($"  Path 拆解: 目录={Path.GetDirectoryName(file)}, 文件名={Path.GetFileName(file)}, 扩展名={Path.GetExtension(file)}");

Console.WriteLine();
Console.WriteLine("===== Stream：流式读写的分工 =====");
var binary = Path.Combine(dir, "data.bin");
using (var fs = new FileStream(binary, FileMode.Create))
using (var writer = new BinaryWriter(fs))
{
    writer.Write(42);
    writer.Write("你好");
    writer.Write(3.14);
}
using (var fs = new FileStream(binary, FileMode.Open))
using (var reader = new BinaryReader(fs))
{
    Console.WriteLine($"  二进制读回: {reader.ReadInt32()}, {reader.ReadString()}, {reader.ReadDouble()}");
}

Console.WriteLine();
Console.WriteLine("===== 编码：写明，别赌默认 =====");
var gbk = Path.Combine(dir, "gbk.txt");
await File.WriteAllTextAsync(file, "默认 UTF-8（无 BOM）");
System.Text.Encoding.RegisterProvider(System.Text.CodePagesEncodingProvider.Instance);  // GBK 系编码要注册
await File.WriteAllTextAsync(gbk, "简体中文", System.Text.Encoding.GetEncoding("GB18030"));
Console.WriteLine($"  UTF-8 字节数: {System.Text.Encoding.UTF8.GetByteCount("简体中文")}；GB18030: {System.Text.Encoding.GetEncoding("GB18030").GetByteCount("简体中文")}");
Console.WriteLine("  WPF 教程 22/25 章的编码识别器就是这套 API 的完整应用");

Console.WriteLine();
Console.WriteLine("===== 清理与习惯 =====");
Directory.Delete(dir, recursive: true);
Console.WriteLine("  临时目录已清理（Delete recursive）");
Console.WriteLine("  习惯：IO 一律 async 版 + try/catch（磁盘满/权限/占用都会抛）；路径拼接用 Path.Combine");
