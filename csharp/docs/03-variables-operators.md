# 03 · 变量、类型与运算符

> 对应示例：`examples/03_variables_operators`

> **本章你将学会**：声明与 var 推断、数值类型选型、类型转换的四条路、溢出防护、易错运算符。
> **前置章节**：[02 工具链](02-toolchain.md)。

## 1. 声明与推断

```csharp
int explicitInt = 42;                // 显式类型
var inferred = "编译器推断为 string";   // var：编译器替你写类型
const double TaxRate = 0.13;         // const：编译期常量，声明时必须初始化
```

**var 不是弱类型**——推断发生在编译期，之后类型钉死，`inferred = 123` 直接编译错误。什么时候用 var：右侧类型一目了然（`new Person()`、字面量）时用它省噪音；右侧看不出类型（复杂 LINQ）时显式写类型帮读者。

## 2. 数值类型选型表

| 类型 | 字节 | 范围/精度 | 用在 |
|---|---|---|---|
| `int` | 4 | ±21 亿 | **默认整数** |
| `long` | 8 | ±9.2×10¹⁸ | 大数（时间戳、ID） |
| `double` | 8 | 15~16 位有效数字 | **默认小数**（科学计算） |
| `decimal` | 16 | 28 位有效数字 | **钱**（二进制误差敏感场景） |
| `float` | 4 | 6~9 位 | 图形/游戏（省内存） |

为什么钱用 decimal——二进制浮点存不下 0.1：

```text
0.1m + 0.2m  = 0.3        （decimal：十进制存储，精确）
0.1  + 0.2   = 0.30000000000000004   （double：二进制近似）
```

示例程序当场打印这对对比。规则：**金额一律 decimal，物理计算 double，别混**。

## 3. 类型转换的四条路

```csharp
int small = 100;
long wide = small;                        // ① 隐式：小 → 大，安全，编译器放行
int back = (int)3.99;                     // ② 显式强转：大 → 小，程序员担责 → 3（截断，不是四舍五入）
int parsed = int.Parse("123");            // ③ Parse：失败抛异常
bool ok = int.TryParse("12x", out int v); // ④ TryParse：失败返回 false，不抛——外部输入首选
```

- 隐式转换的方向表：int→long→float→double…（无损方向自动，有损方向必须强转）
- 强转 `(int)3.99` 是**向零截断**，想四舍五入用 `Math.Round`
- **面对用户输入永远 TryParse**——Parse 一份非法输入就是一次崩溃（第 22 章异常的预告）

## 4. 溢出：静默的环绕

整数运算超出范围不会报错，而是**环绕**到另一头：

```csharp
int max = int.MaxValue;
Console.WriteLine(max + 1);   // -2147483648 ！
```

默认 unchecked（静默环绕）；要抓它有两条路：

```csharp
checked { var overflow = max + 1; }        // 块内抛 OverflowException
// 或工程级：<CheckForOverflowUnderflow>true</...>
```

实务判断：**位运算、哈希、序列化场景**不在乎溢出（甚至利用环绕）；**计数、求和、金额**要防护——用 long 扩容或 checked。示例演示了块内抛异常的完整写法。

## 5. 易错运算符清单

```csharp
7 / 2       // 3   ← 整数除整数还是整数！
7 / 2.0     // 3.5 ← 想要小数，至少一边是小数
7 % 2       // 1   ← 取余（判断奇偶/循环取号）

int i = 5;
i++         // 表达式值 = 5（先用后加）
++i         // 表达式值 = 7（先加后用）——单独一行时两者无区别

s ?? "(兜底)"       // null 合并：s 为 null 取右边
s?.Length ?? -1     // null 条件：s 为 null 整个表达式为 null，不再空引用异常
```

`?.` 与 `??` 的组合是第 21 章可空安全的前菜。其余运算符（比较、逻辑、位、移位）行为符合直觉，用到再查表——**先记住上面这五个易错点**。

## 6. 类型信息三件套

```csharp
object anything = "hello";
anything.GetType().Name      // "String"——运行时真身（object 变量装的是 string）
anything is string           // true——类型测试（第 19 章模式匹配的入口）
typeof(string)               // Type 对象（第 23 章反射的入口）
```

`GetType()` 看的是**运行时**真身——变量声明成 object 也骗不了它。这是多态（第 09 章）能工作的底层机制。

## 常见坑

**int 除法丢精度**：`3 / 2 == 1`。百分比计算 `count / total * 100` 全是 0 的经典原因——先把一边转 double：`(double)count / total * 100`。

**强转 double 到 int 想四舍五入**：`(int)2.7` 是 2。要 `Math.Round` / `(int)(x + 0.5)`。

**Parse 用户输入**：外部数据格式不可信，TryParse + else 分支提示，而不是 Parse + 崩溃。

**float/double 比相等**：`0.1 + 0.2 == 0.3` 为 false！浮点比较用 `Math.Abs(a - b) < 1e-9` 或直接 decimal。

**checked 忘了 decimal 也适用**：decimal 溢出**默认就抛** OverflowException（它不做静默环绕），int 才需要显式 checked。

## 实战建议

- 数值选型口诀：**整数 int、金额 decimal、其他小数 double**；两个都不够再想 long/float
- IDE 的警告（可能溢出/精度丢失）当回事——它们九成九是对的
- 类型转换失败是业务流程的一部分：解析配置、处理表单，一律 TryXxx 模式
- 看到魔法数字（0.13、0.85）就提成 const——名字是第一层文档

## 自测

1. **var 是弱类型吗？** —— 不是；编译期推断后类型钉死，换类型赋值编译错误。
2. **为什么 0.1+0.2 ≠ 0.3？怎么解决？** —— double 是二进制近似；金额用 decimal，浮点比较用误差容忍。
3. **隐式转换的方向规则？** —— 无损方向（小→大）自动；有损方向必须显式强转。
4. **int 溢出默认发生什么？怎么抓？** —— 静默环绕；checked 块/工程级开关抛 OverflowException。
5. **Parse 与 TryParse 怎么选？** —— 内部可信数据可 Parse；任何外部输入一律 TryParse。

---
上一章：[02 工具链与第一个程序](02-toolchain.md) ｜ 下一章：[04 流程控制与方法](04-control-methods.md) ｜ 返回：[README](../README.md)
