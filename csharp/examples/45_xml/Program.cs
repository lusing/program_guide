// 45 · XML 与 LINQ to XML：两本教材专讲、本教程此前空白的另一棵数据树
using System.Xml.Linq;
using System.Xml.XPath;

Console.OutputEncoding = System.Text.Encoding.UTF8;

// ===== 1. 函数式构建：XML 是「构造器拼出来的树」 =====
XNamespace ns = "https://example.com/schema/books";
var catalog = new XElement(ns + "catalog",
    new XAttribute("updated", "2026-09-28"),
    new XElement(ns + "book", new XAttribute("id", "b001"),
        new XElement(ns + "title", "C# 实战（第9版）"),
        new XElement(ns + "price", 89.0),
        new XElement(ns + "tags",
            new XElement(ns + "tag", "C#"),
            new XElement(ns + "tag", "入门"))),
    new XElement(ns + "book", new XAttribute("id", "b002"),
        new XElement(ns + "title", "Effective C#"),
        new XElement(ns + "price", 79.0),
        new XElement(ns + "tags", new XElement(ns + "tag", "进阶"))),
    new XElement(ns + "book", new XAttribute("id", "b003"),
        new XElement(ns + "title", "编译原理"),
        new XElement(ns + "price", 128.0),
        new XElement(ns + "tags",
            new XElement(ns + "tag", "原理"),
            new XElement(ns + "tag", "进阶"))));

Console.WriteLine("===== 函数式构建：元素+属性像搭积木 =====");
Console.WriteLine(catalog);
Console.WriteLine("  没有字符串拼 XML——结构由对象树保证，转义/闭合永远正确（对比手拼字符串的注入与转义坑）");

// ===== 2. 保存与加载：真实的文件往返 =====
var path = Path.Combine(Path.GetTempPath(), "catalog45.xml");
var doc = new XDocument(new XDeclaration("1.0", "utf-8", null), catalog);
doc.Save(path);
Console.WriteLine();
Console.WriteLine("===== 保存 → 再加载 =====");
Console.WriteLine($"  已写入: {path}");
Console.WriteLine("  文件开头 120 字符: " + File.ReadAllText(path)[..120].Replace("\r\n", "⏎"));
var loaded = XDocument.Load(path);
Console.WriteLine($"  XDocument.Load 读回: 根元素 {loaded.Root!.Name.LocalName}，共 {loaded.Descendants().Count()} 个节点");

// ===== 3. LINQ 查 XML：Descendants 是主力 =====
Console.WriteLine();
Console.WriteLine("===== 查询：Descendants + LINQ =====");
var pricey = from b in loaded.Descendants(ns + "book")
             where (double)b.Element(ns + "price")! > 60
             orderby (double)b.Element(ns + "price")! descending
             select new { Title = (string)b.Element(ns + "title")!, Price = (double)b.Element(ns + "price")! };
foreach (var b in pricey)
    Console.WriteLine($"  {b.Title,-14} ¥{b.Price:F1}");
var sum = loaded.Descendants(ns + "price").Sum(p => (double)p);
Console.WriteLine($"  总书价: ¥{sum:F1}（Descendants 递归找全部同名元素；Elements 只找直接子级）");
var tagGroups = loaded.Descendants(ns + "tag").GroupBy(t => (string)t)
    .Select(g => $"{g.Key}×{g.Count()}");
Console.WriteLine($"  标签分组: {string.Join("，", tagGroups)}——16/17 章的 LINQ 原样照用");

// ===== 4. 命名空间：XML 的第一大坑 =====
Console.WriteLine();
Console.WriteLine("===== 命名空间：不带 ns 查询 = 空结果 =====");
int bareCount = loaded.Descendants("book").Count();
int nsCount = loaded.Descendants(ns + "book").Count();
Console.WriteLine($"  Descendants(\"book\")       → {bareCount} 个");
Console.WriteLine($"  Descendants(ns + \"book\")  → {nsCount} 个");
Console.WriteLine("  根上写了 xmlns 后，所有元素都进了命名空间——裸名查不到。「明明有却查 0 个」九成是这个坑");

// ===== 5. 修改：原地改 vs 函数式转换 =====
Console.WriteLine();
Console.WriteLine("===== 原地改 vs 函数式转换 =====");
var sale = new XElement(loaded.Root!);                       // 深拷贝构造
foreach (var p in sale.Descendants(ns + "price"))
    p.Value = ((double)p * 0.8).ToString("F1");              // X-DOM 支持原地改
var origPrice = (double)loaded.Descendants(ns + "price").First();
var salePrice = (double)sale.Descendants(ns + "price").First();
Console.WriteLine($"  打折后第一本 ¥{origPrice:F1} → ¥{salePrice:F1}；原树仍是 ¥{(double)loaded.Descendants(ns + "price").First():F1}");
Console.WriteLine("  X-DOM 可变，但「拷贝整树再改、返回新树」的函数式转换更常用于流水线——与 11 章 record 的 with 同一思想");

// ===== 6. 老派 XmlDocument（DOM）与 XPath =====
Console.WriteLine();
Console.WriteLine("===== XmlDocument 与 XPath：认识老代码 =====");
var dom = new System.Xml.XmlDocument();
dom.Load(path);
var firstTitle = dom.SelectSingleNode("//*[local-name()='title']");
Console.WriteLine($"  XmlDocument.SelectSingleNode → {firstTitle!.InnerText}（W3C DOM 风格，WinForms/WPF 老项目常见）");
var xpathPrices = loaded.XPathSelectElements("//*[local-name()='price']").Select(p => (double)p);
Console.WriteLine($"  XPathSelectElements 求和: ¥{xpathPrices.Sum():F1}（XPath 一行抵一段遍历；带命名空间时用 local-name() 绕开）");

// ===== 7. 流式读取：大文件不整棵进内存 =====
Console.WriteLine();
Console.WriteLine("===== XmlReader：只向前、不建树 =====");
int elementCount = 0;
string? firstTag = null;
using (var reader = System.Xml.XmlReader.Create(path))
{
    while (reader.Read())
    {
        if (reader.NodeType != System.Xml.XmlNodeType.Element) continue;
        elementCount++;
        if (firstTag is null && reader.LocalName == "tag")
            firstTag = reader.ReadElementContentAsString();
    }
}
Console.WriteLine($"  一次前向扫描: 元素 {elementCount} 个，第一个 tag = {firstTag}");
Console.WriteLine("  几 GB 的导出文件用 XDocument.Load 会撑爆内存——XmlReader/XmlWriter 流式处理（26 章 Span 同款「不拷贝」哲学）");

// ===== 8. XML vs JSON：怎么选 =====
Console.WriteLine();
Console.WriteLine("===== 选型：XML 还是 JSON =====");
Console.WriteLine("  JSON：现代 API/前后端的事实标准，更短（33 章 System.Text.Json）");
Console.WriteLine("  XML：老系统/SOAP/Office 文档(.docx)/Maven·csproj 配置的世界仍全是它");
Console.WriteLine("  共同点：都是树、都有「查询 API + 流式 API + 序列化」三层——学会一棵树，另一棵举一反三");

File.Delete(path);
Console.WriteLine();
Console.WriteLine($"（临时文件 {Path.GetFileName(path)} 已清理）");
