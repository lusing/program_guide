# 26 · 数值与数组：加宽、装箱与原语数组

> 对应示例：`examples/26_numbers_arrays/`
>
> 无隐式加宽与转换函数族、字面值与溢出回绕、装箱身份语义（Integer 缓存陷阱）、
> `Array<T>` vs `IntArray` 原语数组、无符号家族、装箱开销微基准。

## 26.1 无隐式加宽：转换必须显式

```kotlin
val i: Int = 1
val l: Long = i          // ✗ 编译错：type mismatch
val l2: Long = i.toLong()   // ✓ 显式转换

val b: Byte = 1
val s: Short = b.toShort()
```

Kotlin 连 `Int → Long` 这种"安全加宽"都不做隐式转换——理由是**重载解析会变得含糊**（`plus(Long)` 还是 `plus(Int)`？）。代价是 Java/C++ 程序员高频撞墙，收益是类型即文档。转换函数族全家：

`toByte() · toShort() · toInt() · toLong() · toFloat() · toDouble() · toChar()`

缩小方向的语义是**截断取低位**，不是四舍五入：

```kotlin
257.toByte()      // 1   （257 = 0x101，取低 8 位）
1000.toShort()    // 1000（放得下就原样）
65.toChar()       // 'A'
'A'.code          // 65
```

进制方向用 `toString(radix)` 与 `String.toInt(radix)`：

```kotlin
255.toString(16)        // "ff"
"ff".toInt(16)          // 255
"1010".toInt(2)         // 10
```

## 26.2 字面值、边界与位运算

```kotlin
val dec = 1_000_000        // 下划线分隔（JDK 8 起 Java 也有）
val hex = 0xFF             // 255
val bin = 0b1010           // 10
val big = 1_000_000_000_000L   // Long 后缀 L
// 注意：前导零直接编译错——017 报 "leading zeros are not allowed"
// Kotlin 用禁掉前导零的方式根除 C 式八进制陷阱（017 在 C 里是 15）
```

**溢出是回绕，不报警**（与 Rust 的 debug 溢出 panic 相反）：

```kotlin
val max = Int.MAX_VALUE
println(max + 1)     // -2147483648（回绕到最小值）
```

直接写 `Int.MAX_VALUE + 1` 这种**常量表达式**会在编译期报错；绕成变量就是静默回绕——所以边界运算自己心里要有数。位运算不是运算符而是**中缀函数**（Char/Int/Long 通用，无 `>>>` 运算符）：

| 写法 | 语义 |
|---|---|
| `a shl b` | 左移（=`<<`） |
| `a shr b` | 算术右移（=`>>`，带符号） |
| `a ushr b` | 无符号右移（=`>>>`） |
| `a and b` / `a or b` / `a xor b` | 与 / 或 / 异或 |
| `a.inv()` | 按位取反（无 `~` 运算符） |

```kotlin
1 shl 10          // 1024
(-8) shr 1        // -4（算术右移，符号位保留）
(-8) ushr 1       // 2147483644（当无符号数右移）
0xFF and 0x0F     // 15
```

另外 `Char` 在 Kotlin 里**不是数字**（不像 C/Java 的隐式提升），`'A' + 1` 不合法，要走 `'A' + 1.toChar()` 或 `('A'.code + 1).toChar()`。

## 26.3 装箱：`Int` vs `Int?` 的身份陷阱

非空 `Int` 在 JVM 上就是基本类型 `int`（零开销）；一旦可空 `Int?`，只能装进 `java.lang.Integer` 盒子。`==` 恒安全（调 `equals`），但身份比较 `===` 对装箱值是个坑——**K2 干脆直接禁止**：

```kotlin
val a: Int? = 1000
val b: Int? = 1000
a === b    // ✗ 编译告警：identity equality ... is prohibited（-Werror 直接挂）
```

编译器在保护你：`Integer.valueOf` 会缓存 **-128..127** 的小值（JLS 规定必须缓存、允许更多），于是身份比较的结果随数值范围漂移：

```kotlin
val x: Int? = 100;  val y: Int? = 100
(x as Any) === (y as Any)      // true  —— 落在缓存里，同一个对象
val a2: Int? = 1000; val b2: Int? = 1000
(a2 as Any) === (b2 as Any)    // false —— 缓存外，各装各的
```

（`as Any` 是为了绕开 K2 的禁止告警做教学演示；生产代码里装箱值就该用 `==`。）教训有二：**装箱值永远用 `==`**；**装箱有真实的内存与身份代价**——这正是下面原语数组存在的理由。

## 26.4 数组三件套与原语数组

引用数组三种造法：

```kotlin
val a = arrayOf(1, 2, 3)             // Array<Int>（装箱！）
val n = arrayOfNulls<String>(3)      // Array<String?>，全 null
val sq = Array(5) { it * it }        // [0,1,4,9,16]——lambda 参数是下标
```

原语数组 `IntArray/ShortArray/ByteArray/LongArray/FloatArray/DoubleArray/CharArray/BooleanArray` 内部就是 JVM 的 `int[]` 等，**不装箱**：

```kotlin
val ia = intArrayOf(2, 4, 6)
val ib = IntArray(5) { it * 2 }     // 同样有工厂
ia.sum()                            // 12
```

两个体系**没有继承关系**（`Array<Int>` 不是 `IntArray` 的超类型——Java 泛型数组的历史包袱），互转有现成函数：

```kotlin
val boxed: Array<Int> = ia.toTypedArray()
val raw: IntArray = boxed.toIntArray()
```

选型规则一句话：**元素是对象就用 `Array<T>`，数值密集（矩阵/缓冲/计数表）一律原语数组**。

## 26.5 无符号家族

`UByte/UShort/UInt/ULong`（1.5 转正）+ 原语版 `UIntArray` 等，字面值后缀 `u`/`U`：

```kotlin
val u: UInt = 255u
val big = 4_000_000_000u        // Int 放不下，UInt 放得下
UInt.MAX_VALUE                  // 4294967295
u.toString(16)                  // "ff"
1u shl 4                        // 16（位运算全套同样有）
```

与有符号互转：`toInt()` 保**数值**（4_000_000_000u.toInt() 截断），`toLong()` 扩展；位重解释用 `.toInt() then .toUInt()`。无符号的定位是**协议解析、位标志、防负数下标**等场景，日常业务代码仍用有符号。

注意坑：类型已转正，但**部分 API 仍标实验**——`uintArrayOf`、`UIntArray.sorted()` 等在 2.4.20 仍要 `@OptIn(ExperimentalUnsignedTypes::class)`（否则 `-Werror` 直接挂）；`listOf(1u, 2u).sorted()` 则不受限。

## 26.6 装箱开销微基准

"装箱慢"不该是教条。千万次求和，`IntArray` vs `Array<Int>`：

```kotlin
val n = 10_000_000
val raw = IntArray(n) { it }
val boxed = Array(n) { it }     // 10_000_000 个 Integer 盒子
// 各求和若干轮，取最优——耗时毫秒数不进输出（快照要稳定），只对比结论
```

实测（JDK 21）：两者结果恒等，`IntArray` 明显更快、内存占用约为装箱版的 1/4（Integer 盒子 16 字节 vs int 4 字节）。数字会随机器漂移，结论方向不变——**热路径数值集合选原语数组**。

## 本章坑位

- `Int + Long` 编不过不是 bug，是设计：显式 `.toLong()`
- `===` 比较装箱数字被 K2 禁止——这坑编译器替你踩了
- `Array(5) { it * 2 }` 的 `it` 是**下标**不是元素
- `max + 1` 静默回绕（变量）；常量表达式才在编译期报错
- `017` 编译不过——前导零被整体禁止（八进制陷阱堵死在源头）
