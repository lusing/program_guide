# 45 · XML 与 LINQ to XML

> 对应示例：`examples/45_xml`

> **本章你将学会**：用 XElement/XAttribute 函数式构建 XML 树、保存加载往返、LINQ 查询 XML、命名空间第一大坑、原地改 vs 函数式转换、认识老派的 XmlDocument/XPath、大文件的 XmlReader 流式读取。
> **前置章节**：[16 LINQ 基础](16-linq-basics.md)、[17 LINQ 进阶](17-linq-advanced.md)、[32 文件与 IO](32-files-io.md)、[33 JSON](33-json.md)。

两本参考教材（唐大仕版 9.2 节、《经典教程》第 12 章）都设 XML 专章。现代后端世界 JSON 当道，但 **csproj 本身、Office 文档（.docx）、SOAP、Maven 配置**全是 XML——而且「树 + 查询 + 流式」的三层结构与 JSON 一一同构，学一棵树举一反三。

## 1. 函数式构建：XML 是拼出来的，不是拼字符串拼出来的

```csharp
var catalog = new XElement("catalog",
    new XElement("book", new XAttribute("id", "b001"),
        new XElement("title", "C# 实战（第9版）"),
        new XElement("price", 89.0)));
```

`XElement`/`XAttribute` 构造器接受任意个子节点——**XML 树直接「长」出来**。转义、闭合、编码由 API 保证；手拼字符串既会踩转义坑又是注入入口（与 [33 章](33-json.md)「别手拼 JSON」同一军规）。

三层 API 分工（与 JSON 的 JsonDocument/JsonNode/Utf8JsonReader 完全同构）：

| 层 | XML | JSON（33 章） | 用途 |
|---|---|---|---|
| 查询/DOM | `XDocument`/`XElement` | `JsonNode` | 常规大小，随机访问 |
| 流式 | `XmlReader`/`XmlWriter` | `Utf8JsonReader` | 大文件不进内存 |
| 序列化 | 手写映射 | `[JsonSerializable]` 源生成 | 对象 ↔ 文本 |

## 2. 保存与加载

```csharp
var doc = new XDocument(new XDeclaration("1.0", "utf-8", null), catalog);
doc.Save(path);                    // 带声明落盘
var loaded = XDocument.Load(path); // 读回整棵树
```

示例实测往返：写出的文件头 `<?xml version="1.0" encoding="utf-8"?>`，读回 18 个节点一个不差。

## 3. LINQ 查询：Descendants 是主力

```csharp
var pricey = from b in loaded.Descendants(ns + "book")
             where (double)b.Element(ns + "price") > 60
             orderby (double)b.Element(ns + "price") descending
             select new { Title = (string)b.Element(ns + "title"), ... };
```

- `Descendants()` 递归找全部后代；`Elements()` 只找直接子级——「明明有却查不到」先想层级
- `(double)element`、`(string)attribute` 的**显式转换运算符**是取值的惯用法（比 `.Value` 好在 null 上更宽容）
- 16/17 章全套 LINQ（Where/OrderBy/GroupBy/Select）原样照用——示例里标签 GroupBy 计数一行流

## 4. 命名空间：XML 的第一大坑

示例实测（同一棵树）：

```text
Descendants("book")       → 0 个
Descendants(ns + "book")  → 3 个
```

根元素写了 `xmlns=...` 后，**所有元素都进了命名空间**——裸名查询一律空结果。「XML 明明有数据就是查 0 个」九成是这个坑。正确写法先备好 `XNamespace ns = "https://…"`，再 `ns + "book"` 拼限定名。

## 5. 原地改 vs 函数式转换

X-DOM 是**可变**的（`SetValue`/`SetAttributeValue`/`Remove` 原地改），但更推荐的流水线写法是**函数式转换**：整树深拷贝（`new XElement(oldRoot)`）再改新树。示例实测：打折树第一本 ¥71.2，原树仍是 ¥89.0——与 [11 章](11-records.md) record 的 `with`、[37 章](37-collections.md) Immutable 集合同一思想：**不改共享结构，产出新版本**。

## 6. 老代码识别：XmlDocument 与 XPath

```csharp
var dom = new XmlDocument();
dom.Load(path);
dom.SelectSingleNode("//*[local-name()='title']");   // XPath
```

W3C DOM 风格的 `XmlDocument` 在 WinForms/WPF 老项目里大量存在——读得懂、能维护即可，新代码用 LINQ to XML。`XPathSelectElements` 扩展方法让 XPath 与 LINQ 互通；带默认命名空间时 XPath 用 `local-name()` 绕开（否则同一个坑再来一遍）。

## 7. XmlReader：大文件的「不建树」模式

```csharp
using var reader = XmlReader.Create(path);
while (reader.Read())
    if (reader.NodeType == XmlNodeType.Element) { /* 只向前扫一遍 */ }
```

示例对同一文件一次前向扫描数出 18 个元素。**几 GB 的导出文件 `XDocument.Load` 会撑爆内存**——只向前、不缓存、边读边处理的流式模型是唯一解（[26 章 Span](26-span.md) 的「不拷贝」哲学、JSON 章的 Utf8JsonReader 同款）。

## 常见坑

**根上 xmlns 后裸名查询**：`Descendants("book")` 永远空——必须 `ns + "book"`（第 4 节实测）。

**手拼 XML 字符串**：`<`/`&`/引号转义、CDATA、编码全靠自己——构造器树一劳永逸。

**大文件上 XDocument.Load**：内存翻几倍起步——XmlReader 流式。

**`.Value` vs 显式转换**：`(string)el` 在缺失时给 null，`el.Value` 直接 NullReferenceException——取值用转换运算符。

## 实战建议

- 新项目选型：API/配置优先 JSON（33 章）；对接 SOAP/Office/老系统才碰 XML
- 读第三方 XML 先看根上有没有 xmlns——有就把 XNamespace 备好，别等 0 结果再查
- 树到树的清洗/转换用「深拷贝 + 改新树」的函数式写法，原树当只读事实源
- 超过几十 MB 的文件一律 XmlReader/XmlWriter，配合 `yield return` 包装成 IEnumerable 流水线

## 自测

1. **LINQ to XML 里 Elements 与 Descendants 的区别？** —— 直接子级 vs 全部后代（递归）。
2. **为什么 Descendants("book") 查不到带默认命名空间的元素？** —— 限定的真名是 {ns}book，裸名不匹配——用 ns + "book"。
3. **函数式转换与 record with 的共同思想？** —— 不改共享结构，拷贝产出新版本。
4. **什么规模/场景必须 XmlReader？** —— 大文件（数十 MB 以上）/一次性顺序处理，内存装不下整树。
5. **XML 三层 API 与 JSON 哪三个类一一对应？** —— XDocument↔JsonNode、XmlReader↔Utf8JsonReader、（序列化层）源生成器。

---
上一章：[44 预处理指令与代码组织](44-preprocessing.md) ｜ 返回：[README](../README.md)
