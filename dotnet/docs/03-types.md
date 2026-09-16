# 03 · 类型与控制流：C# 的地面规则

> 对应示例：`examples/03_types`

## 1. 基本类型一览

C# 的基本类型都是 BCL 类型的缩写别名（`int` 就是 `System.Int32`），跨语言对照着记最快：

| 类型 | BCL 名 | 备注 |
|---|---|---|
| `int` / `long` | Int32 / Int64 | 有符号整数；字面量 `42`、`42L` |
| `double` / `float` | Double / Single | 浮点；`3.14`、`3.14f`——科学计算用 |
| `decimal` | Decimal | 十进制浮点，无二进制误差；**钱用它**，字面量后缀 `m` |
| `bool` / `char` | Boolean / Char | `true`；`'a'`（单引号是 char，双引号是 string） |
| `string` | String | 引用类型，不可变（见 §4） |
| `byte` / `nint` | Byte / IntPtr | `0b1010`、`0xFF`；`nint` 是平台字长的整数 |

## 2. var：推断而非动态

```csharp
var n = 10;          // n 是 int，编译期确定，等价于 int n = 10;
// var x;            // 编译错：必须初始化（没有推断依据）
```

`var` 是**编译期类型推断**，不是动态类型——推断之后类型就钉死了，和 JS 的 `var` 完全两回事。适用准则：右侧类型显而易见就用 `var`（`new` 表达式、方法名自解释）；右侧看不出类型时写显式类型，替读者省一次心智解析。

## 3. 数组与集合预告

```csharp
var nums = new[] {1, 2, 3, 4, 5};   // 推断为 int[]
```

数组定长、协变、日常出镜率其实不高——**真实项目里 List/Dictionary 才是主力**，第 08 章展开。这里先记住：看到 `new[] {...}` 是数组，看到 `new List<int> {...}` 是列表。

## 4. string 是不可变的

```csharp
var s = "dotnet";
var t = s.ToUpper();   // s 没变，t 是新串
```

每次"修改"都产生新对象。循环里拼接字符串是 O(n²) 级的分配灾难——循环内拼接用 `StringBuilder`（第 20 章的示例有实测对比）。常用成员速查：

| 成员 | 效果 |
|---|---|
| `Length` | 字符数（UTF-16 码元数，见文末跨平台提示） |
| `s[i]` | 取 char |
| `Substring(2, 3)` / `Split(',')` | 切片 / 分割（每次分配新串，热点路径见第 15 章 Span） |
| `Contains/StartsWith/Replace/Trim` | 望文生义 |
| `string.Join(", ", list)` / `string.Format` | 拼接与格式化 |

## 5. switch 表达式：值，不是语句

示例的核心演示：

```csharp
int n = 10;
string sign = n switch
{
    > 0 => "positive",
    < 0 => "negative",
    _ => "zero"
};
```

传统 switch 是**语句**（一段跳转逻辑）；C# 8 起 switch 可以是**表达式**（产出一个值）。三件套：

- 各分支形如 `模式 => 值`，逗号分隔；
- `> 0`、`< 0` 是**关系模式**，`_` 是兜底；
- 赋值右侧直接接表达式，天然配合 `var` / `return`。

分支模式远不止关系比较——属性模式 `{Age: < 18}`、组合 `and/or` 在第 05 章与 record 一起讲，那才是模式匹配的主场。

## 6. 循环

```csharp
var nums = new[] {1, 2, 3, 4, 5};
int total = 0;
foreach (var x in nums)
{
    total += x;
}
```

`for`（带索引）、`foreach`（遍历一切 `IEnumerable`）、`while`/`do` 与其他语言一致。C# 的日常默认是 **foreach**——需要索引、需要跳步、循环中要修改集合时才换 `for`。LINQ（第 09 章）之后，很多 `foreach + 累加`的代码会整个消失。

## 7. 方法与参数

示例没写方法（后面章节的示例都有），但参数规则现在就要认识：

```csharp
// out：方法"返回"多个值之一（TryParse 惯用法，第 11 章主角）
if (int.TryParse("42", out var parsed)) { /* parsed 可用 */ }

// 默认参数与 params
static int Sum(int a, int b = 0) => a + b;
static int SumAll(params int[] values) => values.Sum();

// ref/in：按引用传（ref 可写回，in 只读）；数组、接口参数默认传"引用的值"
static void Bump(ref int x) => x++;
```

注意 `static int Sum(...) => a + b;` 的**表达式体方法**：单表达式成员可以 `=>` 收尾，与普通花括号体完全等价，示例里会大量出现。

> **跨平台提示**：`char` 是 UTF-16 码元，`string.Length` 数的是码元不是"用户感知的字符"——emoji、部分汉字组合会占 2 个码元。跨平台/多语言文本处理要注意；读写文件务必显式 `Encoding.UTF8`（第 12 章展开）。

## 8. 坑位清单

1. **整数运算不抛异常**：`int.MaxValue + 1` 静默溢出为负；要检查用 `checked` 块。除法 `7 / 2 == 3`（整型截断），要小数先转 `7.0 / 2`。
2. **decimal 后缀**：`3.14m` 少写 `m` 就是 double，精度语义全变。
3. **string 判等**：`==` 按值比较（运算符重载过），这是 C# 与 Java 的重要差异；但 `object` 引用下比较会退回引用语义，装箱场景用 `string.Equals(a, b)`。
4. **`char` 与单字符 string**：`'a'` 是 char、`"a"` 是 string，`c == "a"` 直接编译错。
5. **var 不是万能**：`var x = null;` 编译错（推断不出）；接口声明、方法参数不能用 var。
