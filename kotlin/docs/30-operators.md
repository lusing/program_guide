# 30 · 运算符与约定全景：从 plus 到 invoke

> 对应示例：`examples/30_operators/`
>
> operator 约定全景表、不可重载清单、`%`(rem) 与 `mod` 的演化史与语义差、
> 复数类实战、BigDecimal 的 `==` scale 陷阱、get/set/invoke/in/iterator 约定。

## 30.1 约定全景：运算符只是具名函数

Kotlin 没有"运算符重载"这个语言特性，只有**约定（conventions）**：编译器把 `a + b` 翻译成 `a.plus(b)`、`a in b` 翻译成 `b.contains(a)`。函数标上 `operator` 就能吃到对应语法：

| 语法 | 约定函数 | 备注 |
|---|---|---|
| `+a` `-a` `!a` | `unaryPlus/unaryMinus/not` | 一元 |
| `++a` `--a` | `inc/dec` | 必须返回新值给回赋 |
| `a + b` `- * / %` | `plus/minus/times/div/rem` | 二元算术 |
| `a += b` 等 | `plusAssign` 等 **或** `plus` | 二选一，同时有则编译错（歧义） |
| `a .. b` / `a until b` / `downTo` / `step` | `rangeTo` / `rangeUntil` | until 自 1.9 有约定 |
| `a in b` / `!in` | `b.contains(a)` | **接收者反转** |
| `a[i]` 读/写 | `get`/`set`（参数任意个） | 多维下标就多参数 |
| `a(...)` | `invoke` | 对象当函数调（23 章 DSL 的 `router("/a")`） |
| `a < b` `>=` 等 | `compareTo` | 一次实现四个符号 |
| `for (x in a)` | `iterator()` + `next()`/`hasNext()` | 自己的类型可进 for |
| `a == b` | `equals` | **不能自己 operator 声明**（只能 override 自 Any） |

反编译一眼看穿：`a + b` 的字节码就是 `INVOKESTATIC Complex.plus` —— 纯语法糖，零运行时魔法。

## 30.2 不可重载清单

`&&` `||`（短路语义无法用函数保证）、`?:`、`===`/`!==`（身份比较是运行时原语）、`=`（赋值）、以及 `==`（只能 override `equals`，不能新造）。另外 Kotlin **没有** `>>>` 运算符（用 `ushr` 函数，26 章）。

## 30.3 `%` 的两个名字：rem 与 mod 的演化史

一段浓缩的语言演化课：早期 `%` 的约定函数叫 `mod`；**1.2 更名 `rem`**（取余，与 Java/C 一致——符号随**被除数**）；**1.5 又引入真正的 `mod`**（数学模——符号随**除数**）。今天的对照（实测 2.4.20）：

```kotlin
-7 % 4        // -3   rem：符号随被除数
(-7).mod(4)   //  1   mod：符号随除数
7 % -4        //  3
7.mod(-4)     // -1
```

注意 `mod` 是**普通函数不是 infix**——`-7 mod 4` 编译不过（报 "'infix' modifier is required"），只能中点写法 `(-7).mod(4)`。选型：哈希桶/环形缓冲/周期对齐用 `mod`，兼容 C/Java 语义用 `%`。

## 30.4 实战：复数四则运算

```kotlin
data class Complex(val re: Double, val im: Double) {
    operator fun plus(o: Complex) = Complex(re + o.re, im + o.im)
    operator fun minus(o: Complex) = Complex(re - o.re, im - o.im)
    operator fun times(o: Complex) = Complex(re * o.re - im * o.im, re * o.im + im * o.re)
    operator fun unaryMinus() = Complex(-re, -im)
    val modulus get() = sqrt(re * re + im * im)
}

val z = (Complex(1.0, 2.0) + Complex(3.0, 4.0)) * Complex(0.0, 1.0)
```

`data class` 顺带送上基于分量的 `equals`/`hashCode`——数学值类型与 data class 是天作之合。复数**没有全序**，所以不给它 `compareTo`（按模比较是半序，会违反比较契约的反对称性——真要排序就 `sortedBy { it.modulus }`，别实现 Comparable）。

## 30.5 BigDecimal：Kotlin 替 JDK 补的运算符 + `==` 陷阱

Kotlin 标准库已经给 `BigDecimal` 写好了 `plus/minus/times/div/unaryMinus/rem` 扩展——直接吃运算符语法：

```kotlin
val a = BigDecimal("0.1") + BigDecimal("0.2")     // 0.3（精确！Double 是 0.30000000000000004）
```

但 `==` 有坑：`equals` 把 **scale（小数位数）** 也算进去——

```kotlin
BigDecimal("2.0") == BigDecimal("2.00")           // false！1 位小数 vs 2 位小数
BigDecimal("2.0") < BigDecimal("2.00")            // false
BigDecimal("2.0") > BigDecimal("2.00")            // false  ← compareTo 说数值相等
BigDecimal("2.0").compareTo(BigDecimal("2.00"))   // 0
```

`==` 不等、`<` `>` 都 false——因为 `==` 走 equals（带 scale）而 `<` 走 compareTo（纯数值）。**金额比较一律 compareTo**（`==` 换 `compareTo(...) == 0`），equals 只用于"完全相同的表示"。同一陷阱家族：`-0.0 == 0.0` 是 true（IEEE）但 `1/-0.0 != 1/0.0`。

## 30.6 get/set/contains/invoke/iterator 五连

```kotlin
class Matrix2 {                                    // 2×2 矩阵
    operator fun get(r: Int, c: Int): Double = ...
    operator fun set(r: Int, c: Int, v: Double) { ... }   // 下标可以有任意多个参数
    operator fun contains(v: Double) = ...         // v in matrix
}

class Greeter(val g: String) { operator fun invoke(name: String) = "$g, $name!" }
val hi = Greeter("你好"); hi("Kotlin")              // 对象当函数调

class Countdown(val start: Int) {                  // 自定义类型进 for
    operator fun iterator() = object : IntIterator() { var cur = start
        override fun hasNext() = cur > 0; override fun nextInt() = cur-- }
}
for (i in Countdown(3)) { ... }                    // 3 2 1
```

约定是把"语法"借给"语义贴切"的类型的——矩阵的 `m[0, 1]`、断言库的 `1 should 1`（23 章）、协程的 `channel.trySend()` 家族，全在这套机制上生长。

## 本章坑位

- `+=` 的两条路（`plusAssign` vs `plus`）同时提供 → 编译错（歧义）；`val` 集合的 `+=` 走 plusAssign 生成新集合
- `==` 在 BigDecimal 上比的是 equals（含 scale），数值比较用 compareTo
- `mod` 不是 infix：`-7 mod 4` 编译不过，写 `(-7).mod(4)`
- 复数这类无全序类型别实现 Comparable——用 `sortedBy { 键 }`
- `inc/dec` 必须返回自增后的值（别就地改 `this`，不可变类直接返回新实例）
