# 06 · 字符串深度

> 对应示例：`examples/06_strings`

> **本章你将学会**：不可变性的推论、驻留机制、插值与格式、原始字符串、char 与编码、StringBuilder 的适用线。
> **前置章节**：[05 值与引用](05-value-reference.md)。

## 1. 不可变性：一切"修改"都是新建

`string` 一旦创建，内容永不改变——`ToUpper`、`Replace`、`Trim` 全都**返回新对象**，原串原封不动：

```csharp
var s1 = "hello";
var s2 = s1.ToUpper();     // s2 = "HELLO"，s1 还是 "hello"
```

三个重要推论：

1. **线程安全白送**：改不了就没有竞争（第 30 章）
2. **循环拼接是性能黑洞**：`s += x` 每次造新串、拷贝全部旧内容——O(n²) 行为（第 6 节）
3. **想"就地改字符"需要别的类型**：`Span<char>`（第 26 章）或 `StringBuilder`

## 2. 驻留（Intern）：字面量的共享

编译器把相同**字面量**折叠成同一个实例（驻留池）：

```csharp
var lit1 = "abc";
var lit2 = "abc";
ReferenceEquals(lit1, lit2)            // true  ← 同一个对象！

var built = new string(new[] {'a','b','c'});
ReferenceEquals(built, lit1)           // false ← 运行时构造不进池
ReferenceEquals(string.Intern(built), lit1)   // true ← 手动驻留后进池
```

驻留的价值：重复字面量零额外内存、字面量比较可以指针级短路。日常不用管它，但它解释了"为什么 string 的 == 可以比内容还很快"。**别用 `ReferenceEquals` 判断字符串相等**——非驻留的相等串会误判，永远 `==` / Equals。

## 3. 插值与格式：`$` 的全套

```csharp
var name = "C#"; var version = 10;
$"基础插值: {name} {version}"                    // C# 10
$"对齐与格式: |{3.14159,10:F2}|"                 // |      3.14|  宽度10、两位小数
$"条件直接进: {(version >= 10 ? "新" : "旧")}"
$"表达式也行: {name.Length} 个字符"
```

格式占位语法 `{值,宽度:格式}`，常用格式符：`F2`（定点两位）、`N0`（千分位整数）、`P1`（百分比）、`x4`/`X4`（十六进制，第 23 章示例用过）、`yyyy-MM-dd`（日期）。要输出 `{` 本身，写 `{{`。

文化（Culture）陷阱：`ToString`/插值默认用当前区域——`1.5` 在某些区域是 `1,5`。**对外协议/文件格式固定用** `CultureInfo.InvariantCulture`：`value.ToString(CultureInfo.InvariantCulture)`。界面显示才用默认文化。

## 4. 原始字符串（C# 11）：三引号消灭转义

JSON/正则/路径里的 `\"` 地狱终结者：

```csharp
var json = """
    { "name": "张三", "tags": ["a", "b"] }
    """;                          // 引号原样保留；缩进由收尾 """ 的位置决定

var withQuote = """"她说："你好"""";   // 内容含引号：定界符加到 4 个
```

规则：定界符引号数 > 内容里最长连续引号数即可；多行时首尾行不进内容、缩进自动对齐。插值版 `$"""`/`$$"""` 用 `{x}`/`{{x}}`（第 24 章示例用过 `$$`）。

## 5. char、编码与"一个字符"的陷阱

```csharp
var han = '中';
(int)han                          // 20013 = U+4E2D（码点）
Encoding.UTF8.GetByteCount("中")  // 3 字节
```

- **string 内部是 UTF-16**：每个 `char` 固定 16 位
- 大部分常用汉字占 1 个 char；**emoji、生僻字占 2 个 char（代理对）**——`"😀".Length == 2`！按 char 切字符串会切碎它们
- 真要"按用户看到的字符"数数/截断：`StringInfo`（`text.SubstringByTextElements`）或枚举 `Rune`
- 文件读写显式传 Encoding（默认 UTF-8 无 BOM）——GBK 老文件的识别/注册问题在 WPF 教程 22 章有完整实战，第 32 章 IO 再遇编码 API

## 6. StringBuilder：循环拼接的正解

```csharp
var sb = new StringBuilder();
for (var i = 0; i < 5_000; i++) sb.Append(i);   // 内部维护可变缓冲，摊还 O(1)
var result = sb.ToString();                       // 最后一次性定型
```

选型线：**3~5 个片段以内直接 `+`/插值**（编译器优化得很好，更可读）；**循环或未知次数的拼接一律 StringBuilder**。示例实测 5000 次拼接，`+=` 的耗时高出 StringBuilder 数个数量级（且随规模恶化）。

配套习惯：已知大致容量就 `new StringBuilder(capacity)` 预留（省翻倍扩容）；`AppendLine`/`AppendJoin`/`AppendFormat` 按需取用。

## 7. 常用成员速查

| 成员 | 用途 | 备注 |
|---|---|---|
| `s.Length` / `s[i]` | 长度 / 第 i 个 char | O(1) |
| `s.IndexOf/Contains/StartsWith/EndsWith` | 查找 | 传 `StringComparison.Ordinal` 显式化 |
| `s.Substring(2, 3)` / 范围 `s[2..5]` | 切片 | 产生新串；热路径用 Span（第 26 章） |
| `s.Trim/TrimStart/TrimEnd` | 去空白 | 新串 |
| `s.Split(';')` | 分割 | 数组；配合 `StringSplitOptions.RemoveEmptyEntries` |
| `string.Join(",", list)` | 拼接 | 静态方法，一次性拼接首选 |
| `string.IsNullOrEmpty / IsNullOrWhiteSpace` | 判空 | 第 21 章常客 |
| `s.Equals(other, StringComparison.OrdinalIgnoreCase)` | 忽略大小写比较 | 别 ToUpper 后比 |

## 常见坑

**循环 `+=` 拼接**：O(n²) 分配——示例量化的第一大坑。

**用 `==` 比较来自不同来源的字符串没问题，但想"省内存"手动 Intern**：驻留池永不清退，驻留大量运行时生成的串反而泄漏。字面量自会驻留，别多手。

**`"1,5"` 解析成 double 崩溃**：区域差异（逗号小数点）。解析外部数据固定 `CultureInfo.InvariantCulture`。

**切到一半的 emoji**：`Substring` 按切 char，代理对被拦腰斩断显示乱码——按文本元素切（StringInfo）。

**Split 没去空**：`"a;;b".Split(',')` 含空串元素。`RemoveEmptyEntries` 考虑加上。

## 实战建议

- 拼接阈值口诀：**少量用插值、循环用 Builder、集合用 Join**
- 所有 `IndexOf`/`StartsWith` 显式传 `StringComparison`（`Ordinal` 为默认心智，忽略大小写用 `OrdinalIgnoreCase`）——省掉"哪个重载被调了"的坑
- 路径拼接永远 `Path.Combine`（第 32 章），不用 `+ "/"`——跨平台分隔符它管
- 高频解析场景（协议/日志）→ `ReadOnlySpan<char>` 零切串（第 26 章示例演示）

## 自测

1. **`s.ToUpper()` 之后 s 变了吗？** —— 没有；不可变性决定一切"修改"返回新对象。
2. **字面量驻留是什么？影响哪个判断的行为？** —— 相同字面量折叠为同实例；影响 ReferenceEquals（但相等判断永远用 ==/Equals）。
3. **`"😀".Length` 是多少？为什么？** —— 2；UTF-16 代理对占两个 char。
4. **什么时候换 StringBuilder？** —— 循环/未知次数拼接；3~5 个片段内插值更优。

---
上一章：[05 值类型、引用类型与内存](05-value-reference.md) ｜ 下一章：[07 数组与枚举](07-arrays-enums.md)
