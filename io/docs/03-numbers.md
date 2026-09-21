# 03 · 数字：只有一种 Number

> 对应示例：[`examples/03_numbers/03_numbers.io`](../examples/03_numbers/03_numbers.io)

Io 的数值模型只有一句话：**只有一个 `Number` 原型，整数与浮点的区别只是值**。
这一章要把这句话的三层后果讲透——打印出来可能看不出类型、除法永远给浮点、
比较必须区分「值相等」与「同一」；再补上优先级、舍入、进制、位运算这一批
「用之前必须实测过一次」的细节。

章节末尾那个 `自检` 小节是示例的回归脚手架（它把本章的结论汇总成断言，跑完打印 `自检：全部通过`），属于逐字节比对的一部分，这里不重复。

## 3.1 只有一种数值类型：Number

```text
-- 3.1 只有一种数值类型：Number
1   isKindOf(Number) = true
1.0 isKindOf(Number) = true
1   proto isIdenticalTo(Number) = true
1.0 proto isIdenticalTo(Number) = true
1 asString   = 1
1.0 asString = 1
1.5 asString = 1.5
1 == 1.0 = true
1 isIdenticalTo(1) = true
```

```io
show("1   isKindOf(Number)", 1 isKindOf(Number))
show("1.0 isKindOf(Number)", 1.0 isKindOf(Number))
show("1   proto isIdenticalTo(Number)", 1 proto isIdenticalTo(Number))
show("1.0 proto isIdenticalTo(Number)", 1.0 proto isIdenticalTo(Number))
show("1 asString  ", 1 asString)
show("1.0 asString", 1.0 asString)
show("1.5 asString", 1.5 asString)
show("1 == 1.0", 1 == 1.0)
show("1 isIdenticalTo(1)", 1 isIdenticalTo(1))
```

结论：没有 `Int` / `Int32` / `Float` / `Double` 这些类，`1` 和 `1.0` 的 proto 都是同一个
`Number` 对象，`isKindOf(Number)` 都为真。这带来两个必须记住的后果：

- **`asString` 不保真**：`1.0 asString` 就是 `"1"`，打印、拼接、写日志时**看不出**
  它是浮点。需要保形状就得自己格式化（见 3.5）。
- **相等有两档**：`==` 比的是值（`1 == 1.0` 为 `true`），`isIdenticalTo` 比的是
  「同一个对象」（`1 isIdenticalTo(1)` 为 `true`，因为 Io 对小整数做了复用）。
  写断言时两者都能用，但含义不同——用哪个，取决于你想问「数值相等」还是「同一个东西」。

> **为什么重要**：唯一一种数值类型让运算符、比较、容器都只需要一套实现；
> 代价是「类型」这条线索从输出里消失了。凡是「整数/浮点行为不同」的地方
> （除法、位运算、格式化），都只能靠**运算符本身**去区分，不能靠类型判断。

## 3.2 除法永远给浮点，取模带符号

```text
-- 3.2 除法永远给浮点，取模带符号
7 / 2 = 3.5
7 / 2.0 = 3.5
7 % 2 = 1
-7 / 2 = -3.5
-7 % 3 = -1
7 % -3 = 1
```

```io
show("7 / 2", 7 / 2)
show("7 / 2.0", 7 / 2.0)
show("7 % 2", 7 % 2)
show("-7 / 2", -7 / 2)
show("-7 % 3", -7 % 3)
show("7 % -3", 7 % -3)
chk("没有整除运算符", 7 / 2, 3.5)
chk("取模跟被除数符号走（同 C）", -7 % 3, -1)
```

结论：**`/` 永远做真除法**，`7 / 2` 是 `3.5`，没有「整除」运算符；要整数商自己
`floor` 或 `(7 / 2) floor`。`%` 的符号跟着**被除数**走（同 C 的 `%`）：`-7 % 3` 给 `-1`，
`7 % -3` 给 `1`。

> **为什么重要**：从 C / Go / Python 2 迁移过来的人第一常见错误，就是假设 `7 / 2` 是 `3`。
> 在 Io 里「整除」是一个需要显式表达的意图，别再找 `/` 的特例形式。

## 3.3 运算符优先级与结合性：** 是左结合

```text
-- 3.3 运算符优先级与结合性：** 是左结合
2 + 3 * 4 = 14
(2 + 3) * 4 = 20
10 - 2 - 3 = 5
2 ** 3 ** 2 = 64
2 ** (3 ** 2) = 512
2 ** -1 = 0.5
```

```io
show("2 + 3 * 4", 2 + 3 * 4)
show("(2 + 3) * 4", (2 + 3) * 4)
show("10 - 2 - 3", 10 - 2 - 3)
show("2 ** 3 ** 2", 2 ** 3 ** 2)
show("2 ** (3 ** 2)", 2 ** (3 ** 2))
show("2 ** -1", 2 ** -1)
chk("幂运算左结合（与数学惯例相反）", 2 ** 3 ** 2, 64)
chk("指数可以是负数", 2 ** -1, 0.5)
```

结论：四则运算的优先级与直觉一致（`*` 紧于 `+`，减法左结合），但 **`**` 是左结合**：

- `2 ** 3 ** 2` = `(2 ** 3) ** 2` = `64`，不是数学惯例的 `2 ** (3 ** 2)` = `512`。
- 想要真正的幂塔，必须自己加括号。
- 指数可以是负数（`2 ** -1` = `0.5`），因为一元负号在这里被当成操作数的一部分。

优先级表本身是可以查的（[6.4](06-messages.md) 用 `OperatorTable operators` 把整张表
打了出来）：`**` 是 1、`%` 和 `*` 是 2、`+` 是 3。

> **为什么重要**：`**` 的左结合是 Io 与几乎所有语言的分歧点。凡是「幂的幂」，
> 一律显式加括号——别依赖记忆，也别依赖别人的代码习惯。

## 3.4 陷阱：一元负号比消息绑定松

```text
-- 3.4 陷阱：一元负号比消息绑定松
-4 abs    = -4
(-4) abs  = 4
-4 squared = -16
```

```io
show("-4 abs   ", -4 abs)
show("(-4) abs ", (-4) abs)
show("-4 squared", -4 squared)
chk("要取负数的绝对值必须加括号", (-4) abs, 4)
chk("不加括号就是 -(4 abs)", -4 abs, -4)
```

结论：`-4 abs` 解析成 `-(4 abs)` —— 一元负号的绑定**比消息（`abs`、`squared` 这些
一元消息）松**。于是 `-4 abs` 先算 `4 abs` 得 4，再取负得 `-4`；`-4 squared`
同理是 `-(4 squared)` = `-16`。要给负数施加方法，**先加括号**：`(-4) abs` = `4`。

> **为什么重要**：这是「运算符 vs 消息」绑定关系的第一个实例（06 章会给出完整的
> 「一元消息 > 关键字消息 > 二元运算符」链条）。凡是「方法作用在负数上」的表达式，
> 括号不是风格问题，是正确性问题。

## 3.5 浮点格式化与误差

```text
-- 3.5 浮点格式化与误差
1 / 3 = 0.3333333333333333
(1 / 3) asString(0, 6) = 0.333333
2 sqrt = 1.4142135623730951
2 sqrt squared = 2.0000000000000004
0.1 + 0.2 = 0.3
(0.1 + 0.2) == 0.3 = false
```

```io
show("1 / 3", 1 / 3)
show("(1 / 3) asString(0, 6)", (1 / 3) asString(0, 6))
show("2 sqrt", 2 sqrt)
show("2 sqrt squared", 2 sqrt squared)
show("0.1 + 0.2", 0.1 + 0.2)
chk("sqrt 再平方不等于原数", 2 sqrt squared == 2, false)
chk("误差量级 1e-16", ((2 sqrt squared - 2) abs) < 1e-15, true)
show("(0.1 + 0.2) == 0.3", (0.1 + 0.2) == 0.3)
```

结论：`Number` 的浮点部分就是 IEEE 754 双精度，误差与 C 一模一样：

- `asString` 默认给足有效位（`1 / 3` 打 16 位），要控制精度用
  `asString(整数位数, 小数位数)` —— `asString(0, 6)` 固定 6 位小数，这是**唯一**可靠的
  格式化手段。
- `2 sqrt squared` 打开是 `2.0000000000000004`，所以 `== 2` 为 `false`；
  `0.1 + 0.2` **打印**成 `0.3`（舍入到最短可辨识表示）但 `== 0.3` 也是 `false`。

判浮点相等只能比误差：`((a - b) abs) < 1e-15`。

> **为什么重要**：`0.1 + 0.2 = 0.3` 与 `(0.1 + 0.2) == 0.3 = false` 这两行放在一起，
> 就是「打印是给人看的、比较是给机器算的」的最好教材。断言里永远不要直接 `==` 浮点。

## 3.6 无穷与 NaN

```text
-- 3.6 无穷与 NaN
1 / 0 = inf
0 / 0 = nan
(0 / 0) isNan = true
(1 / 0) isNan = false
(0 / 0) == (0 / 0) = false
Number constants pi = 3.1415926536
Number constants e  = 2.7182818285
```

```io
show("1 / 0", 1 / 0)
show("0 / 0", 0 / 0)
show("(0 / 0) isNan", (0 / 0) isNan)
show("(1 / 0) isNan", (1 / 0) isNan)
show("(0 / 0) == (0 / 0)", (0 / 0) == (0 / 0))
chk("除零不报错，给 inf", (1 / 0) asString, "inf")
chk("NaN 不等于自己", (0 / 0) == (0 / 0), false)
show("Number constants pi", Number constants pi asString(0, 10))
show("Number constants e ", Number constants e asString(0, 10))
```

结论：除零**不抛异常**，直接按 IEEE 754 给 `inf` / `nan`。判定用 `isNan`
（`inf` 的 `isNan` 是 `false`），而 NaN 的经典性质在这里照样成立：**`nan == nan` 是
`false`**，所以「x 是 NaN 吗」永远要问 `isNan`，不能拿 `==` 试。

常量表在 `Number constants` 上：`pi`、`e` 等，精度按 `asString(0, 10)` 自己定。

> **为什么重要**：Io 的算术错误一律「安静地产出一个特殊值」。这意味着输入端不合法时
> 你不会收到异常，而是拿到 `inf`/`nan` 一路传下去，直到输出时才诡异。
> 关键计算后加一次 `isNan` / `isFinite` 检查，比事后 debug 便宜得多。

## 3.7 取整族与比较

```text
-- 3.7 取整族与比较
3.7 floor = 3
3.2 ceil  = 4
[3.5 2.5 1.5 0.5 -2.5] round = list(4, 3, 2, 1, -3)
2.5 floor / 2.5 ceil = list(2, 3)
5 max(3) = 5
5 min(3) = 3
5 minMax(1, 3) = 3
2 between(1, 3) = true
7 isEven = false
7 isOdd = true
```

```io
show("3.7 floor", 3.7 floor)
show("3.2 ceil ", 3.2 ceil)
// round 是「四舍五入，.5 一律远离零」——不是银行家舍入（不是四舍六入五成双）
show("[3.5 2.5 1.5 0.5 -2.5] round",
     list(3.5 round, 2.5 round, 1.5 round, 0.5 round, (-2.5) round) asString)
show("2.5 floor / 2.5 ceil", list(2.5 floor, 2.5 ceil) asString)
show("5 max(3)", 5 max(3))
show("5 min(3)", 5 min(3))
show("5 minMax(1, 3)", 5 minMax(1, 3))
show("2 between(1, 3)", 2 between(1, 3))
show("7 isEven", 7 isEven)
show("7 isOdd", 7 isOdd)
chk(".5 一律远离零舍入：2.5 得 3（银行家舍入会给 2）", 2.5 round, 3)
chk("负数同理：-2.5 得 -3", (-2.5) round, -3)
chk("floor/ceil 不看符号，分别向 -inf/+inf 走", list(2.5 floor, 2.5 ceil) asString, "list(2, 3)")
chk("Number 没有 truncate，往零取整要自己写", Number hasSlot("truncate"), false)
```

结论：取整三个方法分工清楚——`floor` 向下、`ceil` 向上、`round` 四舍五入。
`minMax(lo, hi)` 是「夹到区间里」（`5 minMax(1, 3)` = `3`），`between(lo, hi)` 返回布尔。

上面那一行把五个 `.5` 一起打出来，就是为了钉死 `round` 的口径：
`0.5 → 1`、`1.5 → 2`、`2.5 → 3`、`3.5 → 4`、`-2.5 → -3`。
**`.5` 一律朝远离零的方向走，不是银行家舍入**（银行家舍入下 `2.5` 应该给 `2`）。
另一个容易记错的点：`floor`/`ceil` **不看符号**，只看数轴方向，
所以 `2.5 floor` 是 `2`、`2.5 ceil` 是 `3`，两者与 `.5` 的取舍规则无关。

顺带一条：`Number` **没有 `truncate`**（往零取整）。要 `truncate` 得自己写，
`x < 0 ifTrue(ceil) ifFalse(floor)` 或者直接 `x asInteger`。

> **为什么重要**：`round` 在 `.5` 上会带来 1 的偏差，金额、分页、索引计算里
> 这类偏差会累积。要可预测的舍入就自己写 `floor(x + 0.5)`，或者在接口层禁用 `.5`。

## 3.8 进制转换与字符码

```text
-- 3.8 进制转换与字符码
255 toBase(16) = ff
42 toBase(2) = 101010
97 asHex = 61
42 asBinary = 00101010
436 asOctal = 664
65 asCharacter = A
"7".asNumber + 1 = 8
"3.5" asNumber = 3.5
```

```io
show("255 toBase(16)", 255 toBase(16))
show("42 toBase(2)", 42 toBase(2))
show("97 asHex", 97 asHex)
show("42 asBinary", 42 asBinary)
show("436 asOctal", 436 asOctal)
show("65 asCharacter", 65 asCharacter)
show("\"7\".asNumber + 1", "7" asNumber + 1)
show("\"3.5\" asNumber", "3.5" asNumber)
chk("asHex 会补齐整字节", 7 asHex, "07")
chk("字符串转数字", "12abc" asNumber, 12)
```

结论：三条输出路线各有性格——

- `toBase(n)`：通用进制转换，不补前导零（`255 toBase(16)` = `ff`）。
- `asHex` / `asBinary` / `asOctal`：按「整字节」补零（`7 asHex` = `"07"`，
  `42 asBinary` = `"00101010"`），适合拼字节级十六进制转储。
- `asCharacter`：码点转字符（`65 asCharacter` = `A`），与 `Sequence at` 的方向相反。
- 反向的 `asNumber` 是**最长前缀解析**：`"12abc" asNumber` 给 `12`，`"3.5" asNumber`
  给 `3.5`；解析不了就不会给你惊喜，但也**不会报错**。

> **为什么重要**：`asHex` 补零、`toBase` 不补零这个差别，决定了你拼出来的十六进制串
> 能不能按固定宽度对齐。写协议/转储代码时先决定用哪一个。

## 3.9 位运算

```text
-- 3.9 位运算
6 & 3 = 2
6 | 3 = 7
6 ^ 3 = 5
1 << 4 = 16
256 >> 4 = 16
6 bitwiseAnd(3) = 2
6 bitwiseXor(3) = 5
6 bitwiseComplement = -7
```

```io
show("6 & 3", 6 & 3)
show("6 | 3", 6 | 3)
show("6 ^ 3", 6 ^ 3)
show("1 << 4", 1 << 4)
show("256 >> 4", 256 >> 4)
show("6 bitwiseAnd(3)", 6 bitwiseAnd(3))
show("6 bitwiseXor(3)", 6 bitwiseXor(3))
show("6 bitwiseComplement", 6 bitwiseComplement)
chk("& | ^ 就是位运算消息的语法糖", 6 & 3, 6 bitwiseAnd(3))
```

结论：`&`、`|`、`^`、`<<`、`>>` 都是**消息的语法糖**，真正的名字是
`bitwiseAnd` / `bitwiseOr` / `bitwiseXor` 等；取反叫 **`bitwiseComplement`**，
**没有** `bitwiseNot`。`6 bitwiseComplement` 给 `-7`，因为取的是补码意义上的按位取反
（`~6` = `-7`）。

> **为什么重要**：把 `& | ^` 当作「运算符」而不是「消息」，会让你在需要
> `perform("&", x)`、自定义优先级或重载时找不到北（[6.3](06-messages.md) 会看到
> `2 perform("+", 3)` 与 `2 + 3` 完全等价）。名字记错则直接报「不响应」。

## 3.10 陷阱：integerMax 是 32 位常量，不是溢出边界

```text
-- 3.10 陷阱：integerMax 是 32 位常量，不是溢出边界
Number integerMax = 2147483647
Number integerMax + 1 = 2147483648
Number longMax = 9223372036854775808
```

```io
show("Number integerMax", Number integerMax)
show("Number integerMax + 1", Number integerMax + 1)
show("Number longMax", Number longMax)
chk("加一不会回绕", Number integerMax + 1 > Number integerMax, true)
```

结论：`integerMax` 只是 32 位整数上限这个**常量值**（`2147483647`），它不是 Io 数值的
边界：`integerMax + 1` 得到 `2147483648`，**不会回绕**。`longMax` 同理是常量。
Io 内部按更宽的整数存，溢出行为与 C 的 `int` 完全不同。

> **为什么重要**：拿 `integerMax` 当「会不会溢出」的判据，是最典型的「照搬 C 直觉」错误。
> 需要边界就明确写出来（或者干脆改用位掩码 `& 0xffffffff`），别把常量当机制。

## 3.11 数学方法

```text
-- 3.11 数学方法
10 factorial = 3628800
5 squared = 25
2 pow(10) = 1024
5 choose(2) = 10
5 permute(2) = 20
16 sqrt = 4
(2 sqrt) floor = 1
```

```io
show("10 factorial", 10 factorial)
show("5 squared", 5 squared)
show("2 pow(10)", 2 pow(10))
show("5 choose(2)", 5 combinations(2))
show("5 permute(2)", 5 permutations(2))
show("16 sqrt", 16 sqrt)
show("(2 sqrt) floor", (2 sqrt) floor)
chk("factorial", 10 factorial, 3628800)
chk("floor 把无理数收成整数", (2 sqrt) floor, 1)
```

结论：常用数学方法都在 `Number` 上，写法一律是「接收者 + 方法」：

- 幂与根：`squared`（平方）、`pow(n)`、`sqrt`。
- 计数：`factorial`、`combinations(k)`（组合，示例标签写作 `choose`）、
  `permutations(k)`（排列，示例标签写作 `permute`）——注意**标签是展示文本，
  真正的方法名是 `combinations` / `permutations`**。
- `(2 sqrt) floor` 把无理数收成整数，是「先算后取整」的惯用写法。

> **为什么重要**：Io 的标准库把数学分散在 `Number` 的方法槽里，没有独立的 `math` 模块；
> 找不到函数时先 `Number slotNames` 看一眼，比翻文档快。

## 3.12 坑位清单

1. **以为 `7 / 2` 是 3** → `/` 永远是真除法，整数商要显式 `floor`。
2. **`1.0 asString` 与 `1 asString` 分不清** → 两者都是 `"1"`，要保形状得自己格式化。
3. **把 `**` 当右结合** → Io 的 `**` 左结合，`2 ** 3 ** 2` 是 64，幂塔要加括号。
4. **`-4 abs` 得到 4** → 一元负号绑定松，先算 `4 abs`，要正确结果写 `(-4) abs`。
5. **用 `==` 比较浮点结果** → `(0.1 + 0.2) == 0.3` 是 false，改比误差。
6. **用 `==` 检测 NaN** → `nan == nan` 是 false，检测一律用 `isNan`。
7. **假设 `round` 是银行家舍入** → 实测是四舍五入（远离零），`2.5 round` 给 3。
8. **用 `toBase(16)` 拼定宽十六进制** → 它不补零，定宽要改用 `asHex`。
9. **记不存在的方法名 `bitwiseNot`** → 取反是 `bitwiseComplement`，结果是 `-7` 这类负数。
10. **拿 `Number integerMax` 当溢出边界** → 它只是 32 位常量，`+ 1` 不会回绕。

---

上一章：[02 · 第一行输出与最小心智模型](02-hello.md) · 下一章：[04 · 序列：字节串、码点串与不可变字面量](04-sequences.md)
