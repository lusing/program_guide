# 02 · 值、运算符与表达式

对应示例：`../examples/Ch02ValuesOperators.tla`

这一章讲 TLA+ 的"数据"和"函数"长什么样。它没有真正的状态机，我们只想把表达式
**算出来并验证**——所以用一个小技巧：搭一个只有一个状态的空转 spec，把每条要演示的
等式写成一条"不变式"（`INVARIANT`）。TLC 检查通过，就等于这条等式被机器实测为真。
连 `2 + 3 = 5` 都是跑出来的，而不是嘴上说说。

```tla
VARIABLES tick
Init == tick = 0
Next == tick' = tick          \* 永远原地踏步，只有一个状态
Spec == Init /\ [][Next]_<<tick>>
```

本机实测：`2 states generated, 1 distinct states found ... No error has been found.`

## 基本值类型

| 类型 | 字面量 | 说明 |
|---|---|---|
| 整数 | `0` `-3` `42` | 来自 `EXTENDS Integers`；`Nat` 是 0,1,2,…，`Int` 是全体整数 |
| 布尔 | `TRUE` `FALSE` | 注意全大写 |
| 字符串 | `"hello"` | 双引号；⚠ **不能含非 ASCII 字符**（见 [19 章](19-pitfalls.md)） |
| 元组 | `<<1, 2, 3>>` | 尖角括号；其实就是序列，下标从 **1** 开始 |
| 记录 | `[name |-> "ada", age |-> 36]` | 命名字段；`|->` 读作"映射到" |
| 集合 | `{1, 2, 3}` | 无序无重复（第 03 章详讲） |
| 函数 | `[x \in 1..3 |-> x * x]` | 数学映射（第 03 章详讲） |

## 算术：注意 `\div` 和 `%` 的真实行为

```tla
2 + 3 * 4 = 14          \* 优先级同数学：先乘后加
7 \div 2 = 3            \* 整数除法
7 % 2 = 1               \* 取余
```

负数下有两个**实测**坑（很多人会想当然写错）：

```tla
-3 \div 2 = -1          \* TLC 的 \div 向「零」截断，不是向下取整
-3 % 2 = 1              \* TLC 的 % 要求除数为正，结果恒在 0..(b-1)
```

- `\div` 向零截断：`-3 \div 2` 得 `-1`（不是 `-2`）。
- `%` 的**第二个参数必须是正数**，否则 TLC 直接报错
  `The second argument of % should be a positive number`；结果总是非负，
  落在 `0..(b-1)`，所以 `-3 % 2 = 1`。
- 二者各自独立定义，**不满足** `(-3 \div 2)*2 + (-3 % 2) = -3` 这种配套关系，
  别拿命令式语言的直觉套。

## 自定义运算符（就是数学函数）

用 `==` 定义，左边是形参、右边是表达式：

```tla
Double(x)  == 2 * x
Add(a, b)  == a + b
Abs(x)     == IF x < 0 THEN -x ELSE x
Sign(n)    == CASE n > 0 -> 1
                [] n = 0 -> 0
                [] OTHER -> -1
```

- `IF ... THEN ... ELSE ...` 是表达式（有值），不是语句。
- `CASE` 用 `[]` 分隔各分支（`[]` 在这里读作"或"），`OTHER` 兜底。
- 注意 `Sign` 这种用 `CASE` 写的，比嵌套 `IF` 清晰得多。

### LET ... IN：局部定义

```tla
Hypotenuse(a, b) ==
  LET sq(x) == x * x
  IN  sq(a) + sq(b)        \* 3,4 -> 25（= 5^2）
```

`LET` 在表达式内部临时定义算子，作用域仅限 `IN` 之后。

### RECURSIVE：递归算子

递归必须先用 `RECURSIVE` 声明函数名，TLC 才认：

```tla
RECURSIVE Fact(_)
Fact(n) == IF n = 0 THEN 1 ELSE n * Fact(n - 1)   \* Fact(5) = 120
```

### CHOOSE：选一个满足条件的元素

```tla
Max(S) == CHOOSE x \in S : \A y \in S : x >= y     \* Max({3,7,2}) = 7
```

`CHOOSE x \in S : P(x)` 返回某个满足 `P` 的 `x`（数学里的描述算子 ι）。
若满足者唯一，结果就是那个唯一值；若一个都没有，则未定义、TLC 会报错。

## 布尔与逻辑值

```tla
TRUE  \land FALSE = FALSE     \* \land 与 /\ 等价
TRUE  \lor  FALSE = TRUE      \* \lor  与 \/ 等价
~TRUE = FALSE
FALSE => TRUE = TRUE          \* 假前提蕴含任何结论都为真
TRUE <=> TRUE = TRUE
```

`/\` 与 `\land`、`\/` 与 `\lor` 完全等价，纯属书写风格（ASCII vs 符号）。
完整逻辑见第 04 章。

## 字符串

```tla
"hello" = "hello"
"abc" # "abd"            \* # 和 /= 都是「不等于」
Len("hello") = 5         \* Len 对字符串也给长度
("ab" \o "cd") = "abcd"  \* \o 拼接
```

实测确认：`Len`、`\o` 对字符串都可用（TLC 把字符串当字符序列处理）。但**字符串字面量
里不能有中文/非 ASCII**——这是词法层的硬限制。

## 元组与记录

```tla
<<1, 2, 3>>[2] = 2                    \* 下标从 1 开始
Len(<<1, 2, 3>>) = 3
[name |-> "ada", age |-> 36].name = "ada"   \* 点号取字段
[x |-> 1, y |-> 2] = [y |-> 2, x |-> 1]     \* 记录与字段书写顺序无关
```

集合、序列、函数、记录这"四大数据结构"是 TLA+ 建模的主力，下一章逐个讲透。

---
上一章：[01 · 第一个规格](01-first-spec.md) ｜ 下一章：[03 · 四大内置数据结构](03-data-structures.md) ｜ 返回：[README](../README.md)
