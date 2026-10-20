# 13 · 扩展 ⭐

> 对应示例：`examples/13_extensions/`（`src/Main.kt` 演示 + `test/Tests.kt` 断言 + `expected.txt` 输出快照）
>
> 扩展函数、扩展属性、可空接收者、泛型扩展、伴生对象扩展，
> 以及两条铁律：静态解析、成员优先——不改源码给类型"外挂"能力。

## 13.1 为什么需要扩展

想给 `String` 加一个 `initials()`（取首字母缩写）方法，摆在面前的老路有三条，都不好走：

1. **改源码**——`String` 是 JDK 的类，改不了；
2. **继承**——`String` 是 final 的，不能继承；就算能继承，到处强制转型也很丑；
3. **工具类**——写 `StringUtils.initials(s)`，Java 老传统。能用，但调用方向反了（"人找函数"而不是"对象.方法"），IDE 补全也帮不上忙，链式调用更无从谈起。

Kotlin 的**扩展**给出第四条路：在不修改、不继承原类的前提下，给已有类型"外挂"新函数和新属性，调用时和真成员一模一样：`"Ada Lovelace Byron".initials()`。它不是猴子补丁——扩展**不修改**原类的字节码，只是编译器帮你把 `s.initials()` 翻译成静态函数调用 `initials(s)`。理解这一点，13.7 和 13.8 两条铁律就顺理成章了。

## 13.2 扩展函数

语法：在函数名前加**接收者类型**，`fun 接收者类型.函数名(...)`；函数体内 `this` 就是接收者对象（可省略）。示例里的三个扩展：

```kotlin
/** 扩展函数：给已有类型"外挂"新方法——不改源码、无继承 */
fun String.initials(): String =
    split(Regex("\\s+")).filter { it.isNotBlank() }.joinToString("") { it.take(1).uppercase() + "." }

fun String.toSlug(): String = trim().lowercase().replace(Regex("\\s+"), "-")

fun Int.timesRepeat(s: String): String = s.repeat(this)
```

调用现场（和调真成员没有任何区别）：

```kotlin
    println("== 13.2 扩展函数 ==")
    println("\"Ada Lovelace Byron\".initials() = ${"Ada Lovelace Byron".initials()}")
    println("\"  Kotlin 编程 指南 \".toSlug() = '${"  Kotlin 编程 指南 ".toSlug()}'")
    println("3.timesRepeat(\"哈\") = ${3.timesRepeat("哈")}")
```

输出：

```text
== 13.2 扩展函数 ==
"Ada Lovelace Byron".initials() = A.L.B.
"  Kotlin 编程 指南 ".toSlug() = 'kotlin-编程-指南'
3.timesRepeat("哈") = 哈哈哈
```

逐个看：

- **`initials()`** 是标准库函数的组合拳：`split(`[Regex](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/-regex/index.html)`("\\s+"))` 按空白切词 → `filter { it.isNotBlank() }` 丢掉空段 → `joinToString("")` 把每段的首字母大写加 `.` 拼起来。三个名字切出 `A.L.B.`。测试还覆盖了双名的情形：`assertEquals("A.L.", "Ada Lovelace".initials())`。
- **`toSlug()`**：`trim()` 去两端空白 → `lowercase()` 全小写 → 内部连续空白替换成 `-`。输出里中文原样保留、英文小写化：`'kotlin-编程-指南'`。测试断言了纯空格 padding 的情形：`assertEquals("kotlin", "  Kotlin  ".toSlug())`。
- **`Int.timesRepeat(s)`**：接收者是 `Int`，函数体里 `this` 就是那个整数，`s.repeat(this)` 调的是标准库 [repeat](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/repeat.html)。`3.timesRepeat("哈")` 输出 `哈哈哈`；`0.timesRepeat("x")` 是空串（测试覆盖）。

注意一个事实：扩展函数体内能访问接收者的 **public** 成员（`length`、`repeat`……），但访问不了 `private`/`internal`（跨模块时）成员——扩展不是"钻进类里"，只是站在类外、享受成员般的调用语法。

## 13.3 扩展属性

属性也能扩展，但有一条硬限制：**扩展属性不能有 backing field**（你不能往别人的类里塞存储），必须每次现算——所以只能写 getter（var 扩展属性还要写 setter），且不能初始化：

```kotlin
/** 扩展属性：没有 backing field，必须现算 */
val String.shoutLen: Int get() = length + 1
val <T> List<T>.secondOrNullExt: T? get() = getOrNull(1)
```

调用：

```kotlin
    println("== 13.3 扩展属性 ==")
    println("\"hey!\".shoutLen = ${"hey!".shoutLen}")
    println("listOf(1,2,3).secondOrNullExt = ${listOf(1, 2, 3).secondOrNullExt}")
    println("listOf(1).secondOrNullExt = ${listOf(1).secondOrNullExt}")
```

输出：

```text
== 13.3 扩展属性 ==
"hey!".shoutLen = 5
listOf(1,2,3).secondOrNullExt = 2
listOf(1).secondOrNullExt = null
```

`shoutLen` 每次访问都算 `length + 1`（`"hey!"` 得 5）；`secondOrNullExt` 是泛型扩展属性，委托给标准库 [getOrNull](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/get-or-null.html)——有第二号元素返回它，没有返回 `null`（`listOf(1)` 的输出证实）。因为不能存状态，扩展属性的定位是**派生量的便捷语法**，不是新字段。

## 13.4 可空接收者

接收者类型本身可以可空——`fun String?.orDash()` 意味着**连 null 都能调它**，函数体里 `this` 的类型是 `String?`：

```kotlin
/** 可空接收者：接收者本身就是 String? —— 04 章空安全 × 扩展 */
fun String?.orDash(): String = this ?: "—"
```

调用：

```kotlin
    println("== 13.4 可空接收者 ==")
    val s: String? = null
    println("null.orDash() = ${s.orDash()}")
    println("\"有值\".orDash() = ${"有值".orDash()}")
```

输出：

```text
== 13.4 可空接收者 ==
null.orDash() = —
"有值".orDash() = 有值
```

`s` 是 null，但 `s.orDash()` 不抛 NPE——因为 `orDash` 声明在 `String?` 上，体内用 `this ?: "—"` 给出兜底。测试里更直白：`assertEquals("—", null.orDash())`——字面量 null 上直接调。

这是第 04 章空安全和扩展的乘积：把"为 null 时的默认行为"收编进类型本身的操作集，调用点就不用反复写 `if (s == null) "—" else s`。标准库深谙此道：`isNullOrEmpty`、`orEmpty` 都是可空接收者扩展。什么时候用？**null 有明确业务含义**（"没有就显示破折号""没有就是空串"）时；null 代表程序错误时别用——那是在吞 bug。

## 13.5 泛型扩展

扩展可以带类型参数，一次对一整族类型生效：

```kotlin
/** 泛型扩展：对所有 List 生效 */
fun <T> List<T>.interspersed(sep: String): String = joinToString(sep)
```

```kotlin
    println("== 13.5 泛型扩展 ==")
    println("interspersed = ${listOf("a", "b", "c").interspersed(" · ")}")
```

输出：

```text
== 13.5 泛型扩展 ==
interspersed = a · b · c
```

`<T>` 写在 `fun` 之后、接收者类型之前；`List<T>` 是接收者，`T` 在函数体里可用。`interspersed` 直接委托给 [joinToString](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/join-to-string.html)。泛型扩展是标准库集合操作的主力形态——`map`/`filter`/`firstOrNull` 全是 `fun <T, R> Iterable<T>.xxx()` 这个形状。

## 13.6 伴生对象扩展

类有伴生对象时，可以给**伴生对象**（"类的静态侧"）挂扩展，效果接近 Java 的静态工厂方法：

```kotlin
/** 伴生对象扩展：给"类的静态侧"挂函数（工厂 ofYuan 在类内，ofCents 在类外） */
class Money(val cents: Long) {
    companion object { fun ofYuan(y: Long) = Money(y * 100) }
}
fun Money.Companion.ofCents(c: Long): Money = Money(c)
```

```kotlin
    println("== 13.6 伴生对象扩展 ==")
    val m1 = Money.ofYuan(3)
    val m2 = Money.Companion.ofCents(250)   // 也能写 Money.ofCents(250)
    println("ofYuan(3) → ${m1.cents} 分；ofCents(250) → ${m2.cents} 分")
```

输出：

```text
== 13.6 伴生对象扩展 ==
ofYuan(3) → 300 分；ofCents(250) → 250 分
```

对比两个工厂：`ofYuan` 写在类内的伴生对象里（类作者的权力）；`ofCents` 是**类外的人**通过 `fun Money.Companion.ofCents(...)` 后挂上去的——接收者是 `Money.Companion` 这个伴生对象的类型。调用侧两种写法等价：`Money.Companion.ofCents(250)` 或省略 `Companion` 写 `Money.ofCents(250)`（源码注释点出，测试两种都验了）。

用途很实际：给第三方库的类型补工厂。库的作者没提供你想要的构造入口，只要它留了伴生对象（哪怕空的），你就能外挂一个 `ofXxx`，调用方看起来和官方 API 一体。

## 13.7 成员优先于扩展

如果类里已有同名成员，扩展写了也白写——**成员永远赢**：

```kotlin
/** 成员与扩展同名：成员优先（编译器会警告 EXTENSION_SHADOWED_BY_MEMBER——这里故意演示） */
class Doc(val title: String) {
    fun render() = "成员渲染: $title"
}
@Suppress("EXTENSION_SHADOWED_BY_MEMBER")   // 教学演示专用；真实代码里这就是"删掉扩展"的信号
fun Doc.render() = "扩展渲染: ${title.uppercase()}"
```

```kotlin
    println("== 13.7 成员优先于扩展 ==")
    println(Doc("t").render())       // 成员渲染胜出；要调扩展得用全限定名
```

输出：

```text
== 13.7 成员优先于扩展 ==
成员渲染: t
```

`Doc("t").render()` 调到的是成员，输出 `成员渲染: t`；扩展版（会输出大写的 `扩展渲染: T`）被完全遮蔽。平时编译器会发 `EXTENSION_SHADOWED_BY_MEMBER` 警告，示例用 `@Suppress` 压掉它只为演示——注释说得很白：真实代码里看到这个警告，正确反应是**删掉扩展**（或者改名），而不是压警告。测试固化了这个行为：`assertEquals("成员渲染: t", Doc("t").render())`。

这条规则的推论：扩展**不可能**覆盖（override）成员，也拦截不了别人对成员的调用——它从来不在虚方法分发的牌桌上。

## 13.8 静态解析：扩展不分发

扩展最重要、也最容易翻车的一条铁律：**调哪个扩展，看变量的编译期（声明）类型，不看运行时类型**。示例用一对父子类做了对照实验：

```kotlin
/** 扩展是静态解析的关键证据：调用哪个扩展看"声明的类型"，不看运行时类型 */
open class Animal2 { open fun who() = "Animal2" }
class Dog2 : Animal2() { override fun who() = "Dog2" }
fun Animal2.tag() = "[A]"
fun Dog2.tag() = "[D]"
```

```kotlin
    println("== 13.8 静态解析：扩展不分发 ==")
    val a: Animal2 = Dog2()
    println("a.who() = ${a.who()}        // 虚方法：运行时类型 Dog2")
    println("a.tag() = ${a.tag()}        // 扩展：编译期类型 Animal2 决定 [A]")
```

输出：

```text
== 13.8 静态解析：扩展不分发 ==
a.who() = Dog2        // 虚方法：运行时类型 Dog2
a.tag() = [A]        // 扩展：编译期类型 Animal2 决定 [A]
```

同一个变量 `a`（声明 `Animal2`、实际装着 `Dog2`）：

- `a.who()` 是**虚方法**，走 JVM 动态分发，看运行时类型——输出 `Dog2`；
- `a.tag()` 是**扩展**，编译期就按声明类型 `Animal2` 选定了 `Animal2.tag`——输出 `[A]`，哪怕对象明明是 Dog2。

测试把三种情形都钉死了：

```kotlin
fun testStaticResolution() {
    val a: Animal2 = Dog2()
    assertEquals("[A]", a.tag())          // 声明类型决定扩展
    assertEquals("[D]", Dog2().tag())
    assertEquals("Dog2", a.who())         // 虚方法看运行时类型
}
```

原因回到 13.1 那句话：扩展只是**静态函数的语法糖**，`a.tag()` 编译完就是 `tag(a)`——重载决议在编译期完成，参数静态类型是 `Animal2`，自然选 `Animal2.tag`。运行时根本没有"查表分发"的环节。

实践含义：想靠扩展做多态是缘木求鱼。需要"按运行时类型走不同逻辑"就老老实实写成员 + override（或用 when + 智能转换）；扩展的定位是**给确定类型加便捷操作**。

## 13.9 标准库本身就是扩展大展

学完扩展再回头看，Kotlin 标准库对 JDK 类几乎"零侵入"——你天天用的函数大半是扩展：

```kotlin
    println("== 13.9 标准库本身就是扩展大展 ==")
    // let/run/also/apply、String.toIntOrNull、各种集合管道——全是扩展函数
    println("\"42\".toIntOrNull() = ${"42".toIntOrNull()}  ← String 的扩展")
    println("listOf(1,2).map{it+1} = ${listOf(1, 2).map { it + 1 }}  ← Iterable 的扩展")
```

输出：

```text
== 13.9 标准库本身就是扩展大展 ==
"42".toIntOrNull() = 42  ← String 的扩展
listOf(1,2).map{it+1} = [2, 3]  ← Iterable 的扩展
```

[toIntOrNull](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/to-int-or-null.html) 是 `String` 的扩展（解析失败返回 null 而不是抛异常，第 16 章还会用到它）；[map](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/map.html) 是 `Iterable` 的扩展；第 12 章的作用域函数五件套也全是扩展。这揭示了一个设计哲学：**核心类保持极简，能力以扩展形式按需 import**——你项目里给业务类型写扩展，正是在用和标准库同样的方式组织代码。

## 13.10 扩展还是成员：取舍

理解了机制，取舍就清晰了：

**写成员**，当这段逻辑是类型的**核心职责**、需要访问私有状态、或需要多态分发（override）。成员在虚方法分发的牌桌上，扩展不在。

**写扩展**，当满足以下任一条件：

- 类不是你写的（JDK、第三方库），改不了源码；
- 逻辑是**特定场景下的便捷视角**而非类型本职——`String.toSlug()` 对"文章标题"场景有用，但不配进 `String` 本身；
- 想保持核心类小巧，把领域相关的辅助操作按包组织、按需 import（标准库正是这么做的）。

反过来说，两个"别写扩展"的信号：一是发现自己在扩展里拼命想碰私有成员（说明它该是成员）；二是发现调用点遍布全项目且人人都要（说明它该进类型的定义，或该考虑包装类）。

## 13.11 坑位清单

1. **以为扩展能多态**——13.8 是翻车现场高发区：扩展按声明类型静态选择，不看运行时类型。要动态分发请用成员 override。
2. **和成员同名写了也白写**——成员永远优先（13.7），编译器警告 `EXTENSION_SHADOWED_BY_MEMBER` 时正确动作是删/改扩展，不是 `@Suppress`。
3. **扩展属性当字段用**——没有 backing field，每次访问都重算；`val String.shoutLen get() = length + 1` 不能初始化、不能存值。
4. **可空接收者吞 bug**——`String?.orDash()` 适合"null 有业务含义"的场景；null 代表程序错误时，给默认值的扩展会把本该炸的问题悄悄抹平。
5. **扩展访问不了私有成员**——扩展是"站在类外"的静态函数，只能碰 public（同模块可加 internal）成员；想改内部状态请写成员。
6. **import 不到就"不存在"**——扩展按包组织，换了文件忘了 import，IDE 里就像函数消失了一样；同名扩展不同包时，import 哪个用哪个。
7. **给第三方类型挂扩展 ≠ 修改它**——扩展只在本模块的调用点生效，别人拿不到你的扩展；别指望靠扩展"修复"库的行为让全项目自动受益，该写包装类时写包装类。

## 本章验证

本章示例通过四层验证（与本教程所有章节一致）：`kotlinc -Werror` 零告警编译 → `kotlin.test` 断言全过（Tests.kt 共 7 组测试，覆盖扩展函数、扩展属性、可空接收者、静态解析、成员优先、伴生扩展）→ 程序运行退出码 0 → stdout 与 `expected.txt` 逐字节一致。工具链：Kotlin 2.4.21（K2 编译器）+ JDK 21。

---

上一章：[12 ⭐lambda与作用域函数](12-lambdas.md) · 下一章：[14 ⭐协程基础](14-coroutines.md)
