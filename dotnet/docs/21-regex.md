# 21 · 正则表达式：模式文本的检索与替换

> 对应示例：`examples/21_regex`

## 1. 什么时候轮到正则

判据先立好，正则不是字符串处理的默认工具：

- **定值查找**（包含 `error`、以 `.log` 结尾）→ `string.Contains/StartsWith/EndsWith`，更快更直白。
- **模式查找**（IP 形状、日期形状、邮箱形状）→ 正则。
- **结构化全文解析**（配置、JSON、CSV）→ 专用解析器（`System.Text.Json`、CSV 库）。**把正则当解析器用**是这一章的头号坑——嵌套结构、转义、多行，正则都会输给真正的 parser。

正则的领地是：日志分析、输入校验、批量文本替换——"在自由文本里捞模式"。

## 2. 三件套：IsMatch / Match / Replace

```csharp
Regex.IsMatch("user@example.com", @"^\w+@\w+\.\w+$");     // true/false：校验

var m = Regex.Match("ip=192.168.1.7", @"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})");
if (m.Success) Console.WriteLine(m.Groups[1].Value);      // 192.168.1.7

Regex.Replace(text, @"\d+", n => (int.Parse(n.Value) + 1).ToString());  // 动态替换
```

`Match` 返回的 `Match` 对象同时是"一条匹配 + 后续匹配的游标"：`m.NextMatch()` 可以手工遍历，`Matches()` 一次拿全。`Replace` 的第三个参数是 `MatchEvaluator`（第 07 章的委托）——替换值需要**计算**时（打码邮箱留首字母）只能用它，字符串重载做不了。

## 3. 组：把一条匹配拆成字段

```csharp
var m = Patterns.LogPattern().Match(line);
m.Groups["ip"].Value;        // 命名组 (?<ip>...)：按名取
m.Groups["method"].Value;
```

要点：

- `(?<name>pattern)` 命名组比 `Groups[1]`、`Groups[2]` 抗改动——模式中间插一个组，编号全错，命名不会。
- **贪婪 vs 懒惰**：`.*` 尽量多吃，`.*?` 尽量少吃。`"<a><b>"` 用 `<(.*)>` 匹配会吞整行得到 `a><b`，用 `<(.*?)>` 才得到 `a`。HTML/XML 里贪婪 `.*` 是默认错误答案。
- `\d{1,3}` 只管形状不管范围（999 也过）——要严格校验数值范围，正则捞出来后 `int.TryParse` 再验。

## 4. GeneratedRegex：编译期生成匹配代码

```csharp
static partial class Patterns
{
    [GeneratedRegex(@"(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) \[(?<time>[^\]]+)\] ""(?<method>GET|POST) (?<path>[^""]+)""")]
    public static partial Regex LogPattern();
}
```

源生成器（C# 11 起，.NET 7+）在**编译期**把模式翻译成 C# 匹配代码：启动时零模式解析、匹配更快、模式写错编译期就报、AOT/裁剪友好。热点路径一律用它。历史选项 `RegexOptions.Compiled`（运行时反射发光）如今被它取代；普通 `new Regex(...)` 适合模式需要运行时拼接的场景。

## 5. 模式串怎么写才不痛苦

- 前缀 `@"..."` 逐字字符串：`\d` 不再写成 `\\d`——正则+逐字字符串是标配。
- 模式里要同时出现引号和反斜杠时，上**原始字符串** `"""..."""`（第 02 章），彻底和转义说再见。
- 用户输入要当**字面文本**匹配时，先 `Regex.Escape(input)`——`a.b(c)` 里的 `.`、`(` 都是模式元字符。

## 6. 超时：正则也有拒绝服务

嵌套量词如 `^(a+)+$` 在"差点匹配上"的输入上指数回溯——40 个字符就能算几十亿步，这叫**灾难性回溯**，Web 服务把它当成 ReDoS 攻击面。防御是构造时给超时：

```csharp
var evil = new Regex(@"^(a+)+$", RegexOptions.None, TimeSpan.FromMilliseconds(100));
try { evil.IsMatch(input); }
catch (RegexMatchTimeoutException) { /* 放弃这次匹配 */ }
```

处理不可信输入（用户提交的模式或被匹配的文本）的正则，**超时必设**。示例第 3 段现场演示 40 字符触发超时。

## 7. 坑位清单

1. **把流式解析交给正则**：嵌套/配对结构（HTML、JSON）用正则解析是无底洞，换 parser。
2. **贪婪 `.*` 吃过头**：多数"多捞了"的 bug 都是它，收窄量词或改懒惰 `.*?`。
3. **编号组顺序依赖**：模式一改全错，用命名组 `(?<name>...)`。
4. **`^`/`$` 与多行文本**：默认只匹配整串首尾，逐行匹配要 `RegexOptions.Multiline`；`.` 默认不匹配 `\n`，跨行要 `RegexOptions.Singleline`。
5. **循环里 `new Regex` 同一模式**：白白重复解析，提出来复用（或上 `[GeneratedRegex]`）。
6. **不设超时处理用户输入** → ReDoS 挂死线程池。
7. **`Regex.Replace` 忽然变慢**：大概率是 `"$1"` 替换串里 `$` 后跟了数字/字母造成意外组引用，逐字替换用 `Regex.Escape` 或 MatchEvaluator。
