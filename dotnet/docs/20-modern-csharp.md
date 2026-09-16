# 20 · 现代 C# 纵览：从 C# 9 到 13+

> 对应示例：`examples/20_modern`

## 1. 版本时间线：每版替你省了什么

本教程各章其实已经用遍了现代特性，这章把它们按版本串起来——**每行记住"它替你省了什么"**就够了：

| 版本 | 特性 | 替你省了什么 | 本教程 |
|---|---|---|---|
| C# 9 | record、`init`、关系/逻辑模式、顶层语句 | 30 行相等性代码；一行入口 | 第 05/02 章 |
| C# 10 | 全局 using、文件范围命名空间、record struct | 每文件一堆 using、一层缩进 | 第 01 章（ImplicitUsings） |
| C# 11 | 原始字符串、列表模式、`required` | 转义地狱；构造校验样板 | 第 02 章 |
| C# 12 | 主构造函数、集合表达式 `[1, 2, 3]` | 构造样板；`new List<int>` 长类型名 | 第 04/18 章 |
| C# 13/14+ | `params` 集合、`lock` 对象类型、partial 事件/构造器 | 弹性参数；逃跑的反模式 | 持续演进 |

一个容易忽略的事实：**语言版本跟 SDK 走，而 API 可用性跟 TargetFramework 走**——`LangVersion` 能在老目标上开新语法，但用到新 BCL 类型照样编译错（第 19 章 §4 的三角债）。日常不设 LangVersion，SDK 给什么用什么最省心。

## 2. 走读示例

示例 `20_modern` 是各章特性的"全明星串烧"，按主题分组看：

**数字字面量**（第 03 章的延伸）：

```csharp
int million = 1_000_000;          // 数字分隔符：肉眼可读
int binary = 0b1010_1010;         // 二进制字面量：位运算场景
```

**partial 的现代形态**——partial 方法从"必须 void、无人调用则蒸发"演进到可有实现/返回值（生成器代码的主场）：

```csharp
partial class Calculator
{
    partial void OnCalculated(int result);      // 声明

    public int Add(int a, int b)
    {
        var r = a + b;
        OnCalculated(r);                        // 无实现时这个调用整体消失
        return r;
    }
}

partial class Calculator
{
    partial void OnCalculated(int result) => Console.WriteLine($"calculated={result}");
}
```

**泛型数学**（第 06 章的主角在此复用，一行版）：

```csharp
static T AddNumbers<T>(T a, T b) where T : INumber<T> => a + b;

Console.WriteLine($"generic-int={AddNumbers(5, 3)}");      // 8
Console.WriteLine($"generic-double={AddNumbers(2.5, 3.5)}");   // 6
```

**record + JSON**（第 05/12 章的组合拳）：`new Person("Alice", 25)` 序列化一行。

**StringBuilder 与不可变 string**（第 03 章的告诫，这里带秒表）：

```csharp
var sw = Stopwatch.StartNew();
var sb = new StringBuilder();
for (int i = 0; i < 3000; i++) sb.Append(i);
sw.Stop();
Console.WriteLine($"stringbuilder-ms={sw.ElapsedMilliseconds}");
```

循环内拼接：`sb.Append(i)`（复用内部缓冲）而不是 `s += i`（每轮新 string）——第 15 章的心法在普通 string 领域的对应物。

**await foreach**（第 13 章异步流）与 **Span 切片**（第 15 章）：

```csharp
var spanText = "apple,banana,cherry".AsSpan();
var comma = spanText.IndexOf(',');
var first = spanText[..comma];                // 窗口切片，零分配
```

## 3. 怎么跟进新版本

- 每年 11 月随 .NET 大版本看一眼官方 "What's new in C# NN" 文档（Microsoft Learn）；
- SDK 升级后 IDE/编译器自动获得新语法，**老项目不改一行也能继续编译**——语言演进高度向后兼容；
- 甄别标准回到工程：新语法是否**替团队省样板、省坑**（record 之于相等性）？只是写法更炫（多一种等价写法）就缓缓，统一风格比追新重要。

## 4. 坑位清单

1. **新语法 ≠ 新运行时可用**：`LangVersion=latest` + 老目标 = 语法过了、类型缺失编译错（IsExternalInit 是常客，第 19 章）。
2. **团队最低 SDK 版本**：用了 C# 12 主构造函数，同事的旧 SDK 编不过——团队统一 SDK 版本或暂缓使用。
3. **过度追新糖**：一行能写完不等于该写成一行（嵌套三元、`??=` 连发）；代码是写给读的人的。
4. **`partial void` 的静默消失**：没人提供实现时调用点整句蒸发——依赖它做副作用会"有时灵有时不灵"，副作用的挂点要保证实现存在。
