# 03 · 变量、类型与控制流

> 对应示例：`examples/03_basics/`
>
> 假设你会 Java/C 系语法。本章聚焦**与直觉不同的部分**：
> val 的"只读引用"语义、无隐式数值加宽、when 表达式、区间与标签。

## 3.1 val 与 var：默认不可变

```kotlin
val pi = 3.14159          // 只读引用（推荐默认）
var counter = 0           // 可重新赋值（需要时才用）
// pi = 3.14              // ← 编译错：val 不能重新赋值
```

关键认知：**val 锁的是"引用"，不是"内容"**——

```kotlin
val list = mutableListOf(1)
list.add(2)               // ✓ 完全合法：list 指向的对象是可变的
// list = mutableListOf() // ✘ 编译错：不能改指向
```

类型可省则推断：`val million = 1_000_000_000_000` 直接推断为 `Long`（超出 Int 范围时字面量自动升位）。数字字面量支持 `_` 分组和十六进制 `0xFF`、二进制 `0b1010`。

## 3.2 数值类型：没有隐式加宽（与 Java 最大的日常差异）

Kotlin 一切类型是对象（编译期按需优化成原始类型），**数值转换必须显式**：

```kotlin
val a: Int = 100
val b: Long = a.toLong()      // ✓ 显式转换
// val c: Long = a            // ← 编译错：类型不匹配
// a + b                      // ← 编译错：Int + Long 不允许
val bytes: Byte = 42
println(bytes.toInt())        // ✓
```

为什么这么设计？Java 的隐式加宽 + 重载解析是无数 bug 的来源（`int` 溢出、`long` 比较错）。Kotlin 选择"转换写在脸上"。转换方向：`toByte()/toShort()/toInt()/toLong()/toFloat()/toDouble()/toChar()`。

**越界转换是截断，不是饱和**：

```kotlin
1000.toByte()     // = -24   （0x3E8 的低 8 位 0xE8，补码）
300.toByte()      // = 44    （0x12C → 0x2C）
```

位运算用命名函数：`and or xor shl shr ushr inv`（不是 Java 的 `& | ^ << >>>`——`&` 在 Kotlin 里没有位运算含义）。

整除规则：`3 / 2 = 1`（Int 除法截断）、`3.0 / 2 = 1.5`。

## 3.3 字符与布尔

`Char` 是真正的字符（不是数字）：`'K'.code` 取码点 75。字符区间 `'a'..'z'` 可用于 `in` 检查。布尔就 `true/false` 三件套 `&& || !`（短路求值）。

## 3.4 字符串与原始字符串

```kotlin
val s = "kotlin"
s.length; s.uppercase(); s.take(3); s.repeat(2)
val raw = """
    三引号里
        换行、反斜杠、$ 都是字面量（$ 例外见坑 6）
""".trimIndent()
```

`trimIndent()` 按最短行对齐——写多行模板（SQL、HTML）的标准姿势。字符串遍历 `for (ch in "kot")` 直接逐字符。

## 3.5 if 是表达式

```kotlin
fun maxOf(x: Int, y: Int) = if (x > y) x else y
```

三元运算符 `?:`？Kotlin 没有——`if/else` 表达式全面替代它（也就没有"左结合嵌套三元"的灾难）。

## 3.6 when：更强的 switch

四种形态，全是表达式：

```kotlin
// 1) 值匹配（含多值、区间、集合成员）
fun describe(n: Int) = when (n) {
    0 -> "零"
    1, 2, 3 -> "小"
    in 4..9 -> "中"
    else -> "大"
}

// 2) 无主体的布尔分支（替代 if-else 链）
fun sign(n: Int) = when {
    n > 0 -> "正"
    n < 0 -> "负"
    else -> "零"
}

// 3) 类型 + 智能转换
val kind = when (anyVal) {
    is Int -> "整数 ${anyVal + 1}"        // anyVal 自动智能转换为 Int
    is String -> "字符串，长度 ${anyVal.length}"
    else -> "其他"
}

// 4) 守卫条件（Kotlin 2.1+ 稳定）
when (n) {
    in 1..100 if n % 2 == 0 -> "小偶数"
    in 1..100 -> "小奇数"
    else -> "范围外"
}
```

when 作表达式（有值返回）时**必须穷尽**——密封类型配合这一点是 Kotlin 模式匹配的根基（08 章）。

## 3.7 循环与区间

```kotlin
for (i in 1..5) {}            // 闭区间 1..5
for (i in 10 downTo 1 step 3) // 10 7 4 1
for (i in 0 until 3) {}       // 半开 0 1 2（经典 off-by-one 解药）
for (i in 0..6 step 2) {}     // 步进
repeat(3) { }                 // 重复 N 次（高阶函数形态）

while (cond) {}               // 传统 while 与 do-while 都在
for ((k, v) in map) {}        // 解构遍历
for ((i, x) in list.withIndex()) {}
```

区间是 `IntRange` 对象，能当集合用：`(1..5).toList()`、`3 in 1..5`。

## 3.8 标签：break/continue/return 的精确制导

```kotlin
outer@ for (i in 1..3) {
    for (j in 1..3) {
        if (i * j > 2) break@outer         // 直接跳出外层
    }
}
```

更常见的是**隐式标签**：lambda 上的 `return@forEach` 只退出那次 lambda（12 章配合 inline 讲非局部返回）。

## 3.9 类型系统小总览

| 类别 | 类型 | 备注 |
|---|---|---|
| 整数 | Byte(8) Short(16) Int(32) Long(64) | 无隐式转换；`Int.MAX_VALUE = 2147483647` |
| 浮点 | Float(32) Double(64) | 默认推断 Double；字面量 `1.5f` |
| 其他 | Boolean, Char, String, Unit, Nothing | Unit≈void；Nothing=永不返回（16 章） |
| 无符号 | UByte…ULong | 特殊场景，本教程不展开 |

## 3.10 坑位清单

1. **`Int + Long` 编译不过**——不是性能建议，是硬错误。`.toLong()` 写起来烦，但是 bug 换来的。
2. **越界转换截断**：`1000.toByte() = -24`，不是 clamp 也不是异常。
3. **`0 until n`** 是 `[0, n)`——写索引循环优先用它，`0..n-1` 容易手滑。
4. when 表达式漏 else（非密封类型时）→ 编译错"when must be exhaustive"。
5. 字符串比较用 `==`（equals 语义）；`===` 才是引用相等。`"a" == "a"` 恒 true（与 Java 的 `==` 陷阱相反方向）。
6. 原始字符串行尾 `$` 会把结尾 `"""` 吃成模板起点——写正则这类以 `$` 结尾的模式时要么去掉锚点要么 `${'$'}`（19 章实测）。
7. `shr` 是算术右移（补符号位），`ushr` 才是无符号右移——处理位标志别用错。
