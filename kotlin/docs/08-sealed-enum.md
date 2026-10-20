# 08 · 密封类、枚举与 when

> 对应示例：`examples/08_sealed_enum/`（含带属性的 Planet 枚举、抽象方法 Ops 枚举、sealed interface Expr 表达式树求值与渲染、OrderState 状态机、when 守卫条件、entries 遍历）。全部代码经四层验证：`kotlinc -Werror` 零告警 → kotlin.test 单测通过 → 运行 exit 0 → 输出与 `expected.txt` 逐字节一致。环境：Kotlin 2.4.21（K2）+ JDK 21。

这一章讲 Kotlin 里"封闭的集合"如何用类型系统表达：枚举封的是**值的集合**，密封类/接口封的是**类型的集合**。两者共同的超能力是——`when` 的穷尽性可以被编译器检查，"漏分支"从运行时 bug 变成编译期错误。

---

## 8.1 为什么需要"穷尽性"

Java 的 `switch` 长期以来不检查分支是否覆盖所有情况，漏写一个 `case`，程序静默走错路。后来 Java 给 switch 加了箭头语法和穷尽性检查，但只对枚举和 sealed 类型生效——这正说明一个道理：**穷尽性检查的前提，是编译器知道"全集"是什么**。枚举和密封类型就是把"全集"告诉编译器的两种方式，而 `when` 是消费这个信息的语法。

这件事的价值要在"改代码"时才真正兑现。新写代码时，分支齐不齐你自己心里有数；三个月后给枚举加一个常量、给 sealed 加个子类，还能不能找齐所有需要处理的地方，靠的全是编译器。把 `when` 写成穷尽表达式（而不是带兜底的 `else`），等于给未来的自己雇了一个不收钱的代码审查员——这一章的所有示例都贯彻这个原则。

---

## 8.2 枚举：带构造参数、方法，甚至抽象方法

Kotlin 的 `enum class` 与 Java 的 enum 同宗：每个常量是一个单例对象。但写起来更轻：

```kotlin
enum class Planet(val gravity: Double) {
    MERCURY(3.7), EARTH(9.81), MARS(3.71), JUPITER(24.79);

    /** 每个枚举常量自己的实现 */
    fun weightOn(earthKg: Double): Double = earthKg * gravity
    override fun toString(): String = "$name(g=$gravity)"
}
```

- 主构造器参数 `gravity` 让每个常量携带数据；常量列表后的分号**必须写**（有成员时），这是 Kotlin 里少数几个分号不省略的地方。
- `weightOn` 是普通成员方法，`toString()` 被覆写成 `"$name(g=$gravity)"`——`name` 是每个枚举常量自带的常量名属性。
- 遍历用 `Planet.entries`（Kotlin 1.9 引入的 `EnumEntries`，类型是 `List<Planet>`，官方文档：[EnumEntries](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.enums/-enum-entries/index.html)），替代老的 `values()`——`values()` 每次调用都新拷贝一个数组，`entries` 是预分配好的列表。

输出（第一行是 `Planet.entries.joinToString(" | ")` 的产物——`joinToString` 对每个元素调 `toString()`，所以打出来的正是覆写后的 `MERCURY(g=3.7)` 形态；[joinToString 官方文档](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/join-to-string.html)）：

```text
行星: MERCURY(g=3.7) | EARTH(g=9.81) | MARS(g=3.71) | JUPITER(g=24.79)
60kg 在 EARTH = 588.6 N
60kg 在 MARS  = 222.6 N
```

测试守住基本行为：`assertEquals(9.81, Planet.EARTH.gravity)`、`assertEquals(4, Planet.entries.size)`、`assertEquals(60.0 * 3.71, Planet.MARS.weightOn(60.0), 1e-9)`。

枚举还自带三样工具：`name`（常量名字符串）、`ordinal`（声明下标，从 0 开始）、`valueOf("EARTH")`（按名反查常量）。其中 `ordinal` 是公认的坑——**把 ordinal 存进数据库或日志后，调整常量声明顺序就会读错数据**；持久化场景请存 `name`。`valueOf` 对非法名字抛 `IllegalArgumentException`，想容错就用 `entries.firstOrNull { it.name == key }`。

枚举还能再进一步——**给每个常量一份独立的方法实现**，声明抽象方法即可：

```kotlin
enum class Ops {
    ADD { override fun apply(a: Int, b: Int) = a + b },
    SUB { override fun apply(a: Int, b: Int) = a - b },
    MUL { override fun apply(a: Int, b: Int) = a * b };

    abstract fun apply(a: Int, b: Int): Int
}
```

这等价于 Java 的 constant-specific method implementation：每个常量是一个匿名子类。运行 `for (op in Ops.entries) println("6 ${op.name} 3 = ${op.apply(6, 3)}")`：

```text
6 ADD 3 = 9
6 SUB 3 = 3
6 MUL 3 = 18
```

测试逐条断言：

```kotlin
assertEquals(9, Ops.ADD.apply(6, 3))
assertEquals(3, Ops.SUB.apply(6, 3))
assertEquals(18, Ops.MUL.apply(6, 3))
```

**何时用这个形态**：操作的种类固定且很少（加减乘除、几个解析策略）时它最紧凑——一个文件、一个类，行为与名字绑在一起。种类会增长、需要携带数据、或每个种类要有多个实例时，该上密封类型（8.4）。

与 Java 的写法定性相同、定量更省：Kotlin 不需要给每个常量写 `public abstract`/`@Override` 注解样板，常量体里直接 `override fun apply(...)` 即可，少了将近一半的仪式代码。

顺便一提，现代 Kotlin 还有一种替代思路：`enum class Ops(val apply: (Int, Int) -> Int)`，把 lambda 存进构造参数，`ADD { a, b -> a + b }`。功能等价、代码更短，但堆栈轨迹里没有具名类、反射也看不出层次，调试体验略差；示例选的"抽象方法 + 常量体覆写"是更经典、更好调试的写法，两种都值得认识。

---

## 8.3 when 的完整形态

`when` 不只是"switch 的替身"，它的分支条件可以是常量、范围、多个值、`is` 类型检查（07 章已见），还能叠加**守卫条件**：

```kotlin
val desc = when (n) {
    0 -> "零"
    in 1..5 -> "1..5"
    6, 7 -> "六或七"
    else -> "更大"
}
```

```text
n=0→零 n=3→1..5 n=7→六或七
```

三个分支各演示一种条件：相等值、区间 `in`、逗号并列多值。`when` 用作**表达式**（有返回值）时，如果编译器无法证明穷尽，就必须写 `else`。这里 `n` 是普通 `Int`，全集无限，所以 `else` 不可省——对照 8.4，那里 `when` 的主语是 sealed 类型，`else` 就能安全省略。

还有一种无主语形态 `when { cond1 -> ...; cond2 -> ... }`，等价于 `if-else if` 链，示例没用到；经验是：有主语能写就带主语，模式匹配的力量才发挥得出来。

守卫条件（Kotlin 2.1 起稳定）允许在分支后追加 `if` 细化：

```kotlin
val withGuard = when (val n = 10) {
    in 1..100 if n % 2 == 0 -> "小偶数"      // 守卫条件（2.1+ 稳定）
    in 1..100 -> "小奇数"
    else -> "范围外"
}
```

注意 `when (val n = 10)` 这种**主语内联声明**写法：`n` 的作用域覆盖所有分支与守卫，省得在外面先声明一次。匹配顺序是从上到下，`in 1..100 if n % 2 == 0` 先检查；10 命中它，输出：

```text
守卫条件: 小偶数
```

把 `n` 换成 11 就会落到第二个分支 `"小奇数"`，换成 200 落到 `else`——三个分支各管一段，互不重叠也不留缝，这是好的分支设计的样子。

没有守卫时，要把"偶数"拆出来得写两层嵌套 `when` 或在分支体里 `if`——守卫把这种"范围 + 附加条件"的判别压成了一行。

守卫表达式里可以用主语变量、可以做任意计算，但记住它只在**前面条件匹配后**才求值：`in 1..100 if n % 2 == 0` 对 200 不会触发取余运算，因为范围检查已经失败。这个短路语义保证了守卫里的代码永远面对"已满足前置条件"的输入。

---

## 8.4 密封继承：表达式树与 ADT

现在解决枚举解决不了的问题：**每个"种类"要携带不同结构的数据，且可以有多个实例**。比如表达式树的节点——`Add(1, 2)` 和 `Add(3, 4)` 是同类不同实例，枚举常量做不到。

`sealed interface`（或 `sealed class`）规定：**所有直接子类必须声明在同一编译单元内**，对编译器而言子类型全集已知：

```kotlin
sealed interface Expr {
    data class Num(val v: Double) : Expr
    data class Add(val l: Expr, val r: Expr) : Expr
    data class Mul(val l: Expr, val r: Expr) : Expr
    data class Neg(val e: Expr) : Expr
    data object Zero : Expr                      // 2.2+：无状态单例用 data object
}
```

这就是函数式语言里的**代数数据类型（ADT）**：一个类型等于若干"构造子"的并。注意它还是**递归**定义——`Add` 的两个字段类型又是 `Expr`，于是任意深度的表达式树都能用这五个构造子拼出来，这正是"代数"二字的含义：小表达式通过运算（Add/Mul/Neg）组合成大表达式。

子类型用 `data class` 白嫖 equals/hashCode/toString/copy（06 章）；无状态的 `Zero` 用 `data object`——既是单例又有像样的 `toString()`（打印 `Zero` 而不是一串哈希）。`Zero` 还有一个数学身份：加法的单位元，`Add(x, Zero)` 恒等于 `x`，做表达式化简时它是天然的归并目标。

`when` 消费 sealed 类型时**不需要 `else`**，且新增子类型后所有漏掉的分支编译报错：

```kotlin
fun eval(e: Expr): Double = when (e) {
    is Expr.Num -> e.v
    is Expr.Add -> eval(e.l) + eval(e.r)
    is Expr.Mul -> eval(e.l) * eval(e.r)
    is Expr.Neg -> -eval(e.e)
    Expr.Zero -> 0.0
}
```

`is` 分支内智能转换照常工作（`e.v`、`e.l` 直接用）；`Zero` 是 object，直接比引用。递归在这里也顺理成章：`eval(e.l) + eval(e.r)` 对每个子树再求值，不需要任何循环或栈的显式管理——树有多高，递归就有多深，结构与算法同形。

`render` 与 `eval` 同构，把树渲染成带括号的字符串。运行：

```kotlin
val expr: Expr = Expr.Add(Expr.Num(1.0), Expr.Mul(Expr.Num(2.0), Expr.Neg(Expr.Num(3.5))))
println("render = ${render(expr)}")
println("eval   = ${eval(expr)}")
```

```text
render = (1.0 + (2.0 × (-3.5)))
eval   = -6.0
```

测试把这个例子原样断言了，并且每个构造子的最小行为都有独立用例：

```kotlin
assertEquals(1.0, eval(Expr.Num(1.0)))
assertEquals(0.0, eval(Expr.Zero))
assertEquals(4.0, eval(Expr.Add(Expr.Num(1.0), Expr.Num(3.0))))
assertEquals(-6.0, eval(Expr.Neg(Expr.Mul(Expr.Num(2.0), Expr.Num(3.0)))))
// 1 + 2×(-3.5) = -6
assertEquals(-6.0, eval(Expr.Add(Expr.Num(1.0), Expr.Mul(Expr.Num(2.0), Expr.Neg(Expr.Num(3.5))))))
```

`render` 的测试同样按构造子铺开：`"(1.0 + 3.0)"`、`"(-2.0)"`、`"0"` 各一条。这种"每个构造子一条断言 + 一个组合用例"的测法，与 ADT 的结构天然对齐——类型定义本身就是测试大纲。

**工程收益**：假设需求变更要加 `Expr.Div`——你只需定义子类，然后编译器会立刻在 `eval`、`render` 以及代码库里**每一个**针对 `Expr` 的穷尽 `when` 处报错，漏一处都编不过。这就是注释里"序列化/渲染永不漏分支"的含义：改类型、编译器领路改代码，是 ADT 最值钱的重构体验。

`sealed class` 与 `sealed interface` 的区别很小：class 版本可以有构造器和状态；interface 版本允许子类型同时继承别的类。拿不准就用 interface。

还有一点容易被忽略：`when` 用作**语句**（不取返回值）时，即使不穷尽也只是警告而不是错误；用作**表达式**时才强制穷尽。所以消费 sealed 类型时，尽量把 `when` 写成表达式赋给 `val` 或直接 `return`——让编译器站在你这边，而不是靠自觉。本节的 `eval`、`render`、`nextAction` 全是 `fun f(...) = when (...)` 的表达式体写法，这不是巧合。

---

## 8.5 状态机：sealed + when 的表驱动

订单生命周期是 sealed 的第二个经典战场——每个状态携带的数据不同（已支付有金额、已发货有单号），且状态全集封闭：

```kotlin
sealed interface OrderState {
    data object Created : OrderState
    data class Paid(val amount: Int) : OrderState
    data class Shipped(val tracking: String) : OrderState
    data object Done : OrderState
}

fun nextAction(s: OrderState): String = when (s) {
    OrderState.Created -> "等待支付"
    is OrderState.Paid -> "已收款 ${s.amount}，安排发货"
    is OrderState.Shipped -> "运输中（${s.tracking}），等签收"
    OrderState.Done -> "订单完成，可归档"
}
```

无状态的两个状态用 `data object`（引用相等，全局单例）；带数据的用 `data class`。遍历一条完整生命周期：

```text
  等待支付
  已收款 199，安排发货
  运输中（SF123456），等签收
  订单完成，可归档
```

测试四态全覆盖：

```kotlin
assertEquals("等待支付", nextAction(OrderState.Created))
assertEquals("已收款 199，安排发货", nextAction(OrderState.Paid(199)))
assertEquals("运输中（SF123456），等签收", nextAction(OrderState.Shipped("SF123456")))
assertEquals("订单完成，可归档", nextAction(OrderState.Done))
```

相比传统的"枚举 + 一堆 if-else 查外部状态"，这个写法的优势是**数据跟着状态走**：`Paid` 天然持有 `amount`，不可能出现"状态是已支付但金额字段为 null"这种非法组合——类型系统直接消灭了非法状态，这就是"make illegal states unrepresentable"。

这个模式还有自然的演化路径：今天要打印"下一步动作"，明天可能要做状态持久化（`toJson`）、合法迁移检查（`canTransitionTo`）。每加一个横切功能，就再写一个穷尽 `when` 的顶层函数；每加一个状态，编译器把所有这些函数全部标红。相比把方法塞进 enum 常量体（8.2 的 Ops 写法），sealed + 外部函数的组合在功能维度上是开放的——**类型封闭、操作开放**，这正是访问者模式想实现却实现得很笨重的目标。

---

## 8.6 枚举 vs 密封：选型表

示例最后自己总结了一行：

```text
枚举 = 值的固定集合（单例常量）；密封 = 类型的固定集合（可携带数据、可有多个实例）
```

展开成决策表：

| 维度 | enum class | sealed interface/class |
| --- | --- | --- |
| 封闭的是什么 | 值的集合（每个常量全局单例） | 类型的集合（每类可建多实例） |
| 携带数据 | 所有常量同构（同一份构造参数签名） | 各子类型异构（各自声明属性） |
| 相等性 | 引用相等（`==` 即 `===`） | data class 按值相等 |
| 天然带的东西 | `name`、`ordinal`、`entries`、`valueOf` | 无（就是普通类层级 + 封闭性） |
| 典型场景 | 星期、方向、planet、固定操作集 | 表达式树、状态机、Result/Either、UI 事件 |

一句话：种类固定且每个种类一个实例就够——枚举；种类固定但每个种类要带自己的数据、要多实例——密封。两者经常组合：sealed 里无状态的叶子用 `data object`（相当于手写枚举项），带状态的用 `data class`。

反过来说，两种类型都不适合"种类会由使用方扩展"的场景：插件系统、SPI、用户自定义策略这类开放集合，请回到普通接口/抽象类（07 章），让任何人都能实现。封闭性的价值恰恰在于"不许扩展"——编译器因此敢替你检查穷尽。选型的本质问题是：**这个集合的未来变化，由你控制还是由别人控制？** 由你控制，sealed/enum 是最优解；由别人控制，开放接口才是。

---

## 8.7 对照其他语言

| 能力 | Java | Kotlin | Rust / Haskell |
| --- | --- | --- | --- |
| 枚举携带数据 | 可以（构造器 + 字段） | 可以，语法更轻 | Rust enum 每个变体可携带不同数据 |
| 常量各自实现方法 | 可以（匿名类体） | 可以（同左） | 不适用 |
| 封闭的子类型全集 | sealed class（17+） | sealed class/interface（原生） | ADT 是语言核心 |
| 穷尽性检查 | switch 表达式/模式 switch（21） | when 表达式（一直都有） | match（一直都有） |
| 模式内绑定字段 | record patterns（21） | is + 智能转换 / data class 解构 | 解构是模式匹配原生能力 |
| 守卫条件 | guarded pattern（21） | `if` 守卫（2.1+ 稳定） | `if` 守卫（一直都有） |

可以看到 Java 21 的模式匹配三件套（sealed、record patterns、switch 穷尽）基本是在补 Kotlin/函数式语言十年前就有的课；而 Kotlin 与 Rust 的差距主要在**模式内直接解构字段**——Kotlin 靠 data class 的 `componentN` 解构（06 章）在 `val (l, r) = e` 这种局部场景找补。

学习路线上的建议：先在 Kotlin 里把"穷尽 when + ADT"用熟，这套心智模型可以几乎无损地平移到 Rust 的 `enum` + `match` 或 Swift 的 `enum` + `switch`；反过来，理解了这些语言再看 Java 21 的模式 switch，也只会觉得是同一思想的方言。模式匹配不是某个语言的特性，而是一种组织"数据 vs 操作"关系的世界观。

---

## 8.8 坑位清单

1. **枚举有成员时别忘分号**：常量列表与成员之间那个 `;` 是强制的，全 Kotlin 最不能省的分号。
2. **`values()` vs `entries`**：前者每次返回新数组，后者（1.9+）是复用列表；新代码统一用 `entries`。
3. **穷尽 `when` 用作表达式时，sealed/enum 才可以省 `else`**；但如果你想要"未来加类型时编译报错提醒我"，就别习惯性补 `else`——`else` 会把新类型静默吞掉。
4. **守卫条件有顺序**：分支自上而下匹配，带 `if` 的分支挡在裸分支前面时先求值守卫；把最具体的条件放最前。
5. **`data object` 不是枚举的完全替代**：它没有 `name`/`ordinal`/`entries` 体系；需要序号、按名查找时还是 enum。
6. **sealed 子类型必须同编译单元**：库作者加了子类型，使用方编译期立刻感知——这正是特性而非限制，别把子类型声明到别的模块去。
7. **状态机别混用"枚举 + 外部可空字段"**：`Paid` 的金额就长在 `Paid` 里，用可空字段外挂等于放弃了类型系统白送的正确性。
8. **枚举常量体里别放可变状态**：枚举常量是全局单例，`var` 字段等于全局变量，测试之间会互相污染；要状态请用 sealed + data class，每处用自己的实例。
9. **`valueOf` 对大小写敏感且不可容错**：处理用户输入/外部配置时先 `uppercase()` 或用 `entries.firstOrNull` 查找，别让一个脏字符串炸掉整个解析流程。
10. **guard 与对象分支混写时注意匹配顺序**：`is X if cond` 不匹配会落到后面的裸 `is X`，顺序写反（裸分支在前）守卫分支就成了死代码——编译器会警告，但 `-Werror` 下直接编不过，这是好事。

---

上一章：[07 继承与接口](07-inheritance.md) · 下一章：[09 ⭐object与委托](09-delegation.md)
