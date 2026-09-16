# 02 · 第一个程序：从 Main 到顶层语句

> 对应示例：`examples/02_hello`

## 1. 十一行里发生了什么

先看示例全文——一个完整的、可运行的 C# 程序：

```csharp
var name = "dotnet";
Console.WriteLine($"Hello, {name}!");

var json = """
{
  "topic": ".NET",
  "level": "beginner"
}
""";
Console.WriteLine(json);
```

没有 class、没有 Main、没有 using——这不是简化掉的伪代码，是 C# 的**顶层语句**（top-level statements）：整个文件就是程序入口。对写过脚本语言的人，这是 C# 最友好的门面；对写过老 C# 的人，这是 C# 9 起的官方姿势。

## 2. 编译器在背后做了什么

顶层语句不是"没有入口"，而是编译器替你生成。上面等价于传统写法：

```csharp
using System;

class Program
{
    static void Main(string[] args)
    {
        var name = "dotnet";
        Console.WriteLine($"Hello, {name}!");
        // …
    }
}
```

三条规则：

- 一个工程里**只能有一个文件**包含顶层语句；其余文件照常写类、记录、方法（后面的示例大量出现：顶层逻辑在前，类型定义垫后）。
- 顶层语句里可以用 `args`（命令行参数），编译器生成的 Main 签名带着它。
- `await` 可以直接用在顶层（第 13 章的示例全靠这一点）。

顺带一提 `Console.WriteLine` 为什么不用 `using System;`——工程开了 `ImplicitUsings`（第 01 章讲过），常用命名空间自动引入。

## 3. 插值字符串：$ 开头的模板

`$"Hello, {name}!"` 里，`$` 把字符串变成模板，`{}` 内是任意表达式：

```csharp
var price = 3.14159;
Console.WriteLine($"{price:F2}");        // 3.14——格式化说明符
Console.WriteLine($"{"hi",10}");         // 右对齐到 10 列
Console.WriteLine($"{DateTime.Now:yyyy-MM-dd}");   // 2026-09-16
```

跨语言对照：相当于 Python 的 f-string、JS 的模板串，但格式说明符沿袭 .NET 的Composite Formatting，日期/数字的格式串非常丰富。

## 4. 原始字符串字面量：三个引号

示例的第二段：

```csharp
var json = """
{
  "topic": ".NET",
  "level": "beginner"
}
""";
```

三个及以上连续双引号开启**原始字符串字面量**（C# 11）：内部不处理任何转义，`\n` 就是反斜杠加 n，引号不用写成 `\"`。结尾 `"""` 的**缩进位置决定内容去掉多少前导空白**——上面 `"""` 顶格，所以内容各行的公共缩进被剥掉，`json` 的值从 `{` 开始。写 JSON、正则、SQL、路径（`C:\dir\file` 不用再 `\\`）时，它终结了转义地狱。

原始字符串也能配插值：`$"""` 开头即可；`{}` 冲突时加更多 `$`（`$$"""` 用 `$${expr}` 插值）。

## 5. 跑起来

```bash
cd examples/02_hello
dotnet run
```

预期输出两段：问候语和那段 JSON。试着改 `name`、给 JSON 加一个字段——热身完毕。

## 6. 坑位清单

1. **两个文件都有顶层语句**：报错 CS8803（"只能有一个顶层语句文件"）。把第二个文件的逻辑挪进方法或类。
2. **`$` 与 `@` 的顺序**：逐字插值串是 `$@"..."` 或 `@$"..."`（两者皆可）；而 `"""` 原始字符串已经天然"逐字"，一般不再需要 `@`。
3. **顶层语句后不能再声明方法之前的类型**：类型声明必须出现在所有顶层语句之后——把类型放文件末尾。
4. **分号可省的错觉**：语句末尾的分号在 C# 里不能省（与 JS/Python 不同），示例里能省的只有那些"块"结束的位置。
