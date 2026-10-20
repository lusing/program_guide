# 11 · 泛型 ⭐

> 对应示例：`examples/11_generics/`（`src/Main.kt` 一个文件承载全部演示：Box/Producer/Consumer/Refillable/sum 重载/parseOf/parseAs；`test/Tests.kt` 断言行为，`expected.txt` 输出快照）。全部代码经四层验证：`kotlinc -Werror` 零告警 → kotlin.test 单测通过 → 运行 exit 0 → 输出与 `expected.txt` 逐字节一致。环境：Kotlin 2.4.21（K2）+ JDK 21。

泛型是静态类型语言里"一次编写、处处安全复用"的基石：没有它，容器只能装 `Object`，每次取出都要强制转换，类型错误全部推迟到运行时的 `ClassCastException`。Kotlin 的泛型站在 Java 的肩膀上做了三件升级：**声明处型变**（`out`/`in`，在类声明时标一次，所有使用点受益）、**`where` 多重约束**、以及 **`reified`**——配合 `inline` 把泛型实参保留到运行时，补上 Java 泛型最大的那块短板。当然，JVM 的**类型擦除**地基没变，这一章也会把擦除的边界量给你看：知道墙在哪里，才知道 `reified` 为什么只是半张门票。

---

## 11.1 为什么需要泛型

先回到没有泛型的年代。Java 1.4 的 `ArrayList` 只认识 `Object`：

```java
List list = new ArrayList();
list.add("文本");
String s = (String) list.get(0);   // 取出必须强转，转错就是运行时异常
```

问题有两个：一是**啰嗦**，每次读取都要强转；二是**危险**——`list.add(42)` 编译器不拦，直到某次 `get` 强转才炸。泛型把"这个容器装什么"提升为类型的一部分：`List<String>` 在编译期就拒绝 `add(42)`，读取时编译器自动插入不可见的强转，并保证它永远成功。

Kotlin 完整继承了这套编译期保证，再追加四件工具，本章逐个展开：

| 工具 | 解决什么 | 小节 |
| --- | --- | --- |
| 声明处型变 `out`/`in` | `Box<Cat>` 与 `Box<Animal>` 的子类型关系 | 11.3 |
| 星投影 `*` | 类型实参未知时的安全使用 | 11.4 |
| `where` 多重约束 | 要求 T 同时满足多个上界 | 11.5 |
| `reified` + `inline` | 运行时保留泛型实参 | 11.6 |

类型擦除（11.7）不是工具，而是 JVM 地基的限制——所有泛型只活在编译期，理解它才能理解上面每样工具的真实边界。

---

## 11.2 泛型类与泛型函数

最小的泛型类长这样：

```kotlin
/** 简单泛型容器 */
class Box<T>(private val item: T) {
    fun get(): T = item
    override fun toString() = "Box($item)"
}
```

`T` 是**类型参数**：声明类时它是占位符，实例化时被替换成具体类型。`private val item: T` 和 `fun get(): T` 里的 `T` 跟着类走——`Box<Int>` 的 `get()` 返回 `Int`，`Box<String>` 的 `get()` 返回 `String`，编译器全程盯梢。

使用点靠**构造器类型推断**，不用重复写类型实参：

```kotlin
println(Box(42)); println(Box("文本"))
```

输出：

```text
Box(42)
Box(文本)
```

源码里留了一行被注释的编译错，值得停下来看一眼：

```kotlin
// val b: Box<Int> = Box(1L)   // ← 编译错：类型实参必须严格匹配
```

`Box(1L)` 是 `Box<Long>`，与 `Box<Int>` **没有**任何子类型关系——泛型默认**不变**（invariant）。这不是刁难，而是安全底线；11.3 会讲放开它的条件与代价。

泛型函数把类型参数放在函数名前的尖括号里，`maxOf3` 还顺带演示了**上界约束**：

```kotlin
/** 泛型函数 + 上界约束 */
fun <T : Comparable<T>> maxOf3(a: T, b: T, c: T): T = maxOf(a, maxOf(b, c))
```

`<T : Comparable<T>>` 读作"T 必须能和自己比较大小"——[Comparable](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-comparable/index.html) 是 Kotlin 的可比较接口，对应 Java 的 `Comparable`。有了这个约束，函数体才能安全调用标准库的 [maxOf](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/max-of.html)（它自己也声明了同样的上界）。

```kotlin
println("maxOf3(1,5,3) = ${maxOf3(1, 5, 3)}, maxOf3('b','a','c') = ${maxOf3('b', 'a', 'c')}")
```

输出：`maxOf3(1,5,3) = 5, maxOf3('b','a','c') = c`——`Int` 和 `Char` 都实现了 `Comparable`，同一份代码直接复用。

一个不写就生效的默认值：类型参数的**默认上界是 `Any?`**，即可空。想禁止 null 就显式写 `<T : Any>`（11.5 的 `Repo` 就是这么做的）。

对应单测把容器行为钉死：

```kotlin
fun testBox() {
    assertEquals(42, Box(42).get())
    assertEquals("Box(文本)", Box("文本").toString())
}
```

---

## 11.3 型变：数组协变之坑、out 与 in

### 先复习 Java 的历史包袱

`main` 开头的注释把这段历史浓缩成了两行：

```kotlin
val ints = arrayOf(1, 2, 3)
// Java: Object[] o = ints; o[0] = "x"; → ArrayStoreException（数组运行时记得元素类型）
```

Java 数组是**协变**的：`Int[]` 可以赋给 `Object[]`。这当年是为了让 `Arrays.sort(Object[])` 一个方法排序所有数组，代价是类型系统出现窟窿——往 `Object[]` 里塞 `String`，编译器放行，运行时数组发现元素类型不对才抛 `ArrayStoreException`。错误被推迟到运行时，是 Java 设计者后来公开承认的妥协。

Kotlin 的选择分两步：

1. **`Array<Int>` 不能赋给 `Array<Any>`**——数组保持"不变"，窟窿在编译期就焊死；
2. 但下面这行是合法的：

```kotlin
val animals: List<Animal> = listOf(Cat(), Dog())   // List<Cat>/List<Dog> 都是 List<Animal>
println("协变读取: ${animals.map { it.sound() }}")
```

输出：`协变读取: [喵, 汪]`。凭什么 `List` 可以而 `Array` 不行？因为 Kotlin 的 [List](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/-list/index.html) 接口声明就是 `List<out E>`——**声明处协变**。`List` 是只读接口，没有任何"往里写"的方法，`E` 永远只出现在返回值位置，协变天然安全。一句话总结本节的全部直觉：**只读的数据可以安全协变，可写的不行**。

### out：协变（生产者）

自定义类型想获得同样的能力，用 `out` 标注：

```kotlin
/** out 协变：只生产 T（只出现在"返回值"位置）→ Box<Cat> 可当 Box<Animal> 用 */
interface Producer<out T> { fun produce(): T }
```

`out` 是向编译器签下的合同：**T 只出现在"产出"位置**（函数返回值），永不出现在参数位置，编译器负责强制执行——违反即编译错。作为回报，子类型关系**顺着**继承方向走：`Cat : Animal` 蕴含 `Producer<Cat> : Producer<Animal>`，所以叫"协"变。

```kotlin
class CatFarm(private val cat: Cat) : Producer<Cat> {
    override fun produce(): Cat = cat
}
```

```kotlin
val p: Producer<Animal> = CatFarm(Cat())           // out：Producer<Cat> → Producer<Animal>
println("Producer<Animal>.produce().sound() = ${p.produce().sound()}")
```

输出：`Producer<Animal>.produce().sound() = 喵`。静态类型是 `Producer<Animal>`，产出按 `Animal` 看待；运行时对象还是那只猫，`sound()` 动态分派出"喵"（07 章的多态在这里照常工作）。

为什么 `out` 必须禁止 T 出现在参数位置？反证法：假如 `Producer` 有 `fun set(x: T)`，那把 `CatFarm` 当 `Producer<Animal>` 用时就能 `set(Dog())`——猫场里被塞进一条狗，类型系统当场破产。`out` 用"功能阉割"（只读）换来了"子类型兼容"。

### in：逆变（消费者）

镜像的另一面：

```kotlin
/** in 逆变：只消费 T（只出现在"参数"位置）→ Comparator<Animal> 可当 Comparator<Cat> 用 */
interface Consumer<in T> { fun consume(x: T) }
```

`in` 的合同相反：**T 只出现在"消费"位置**（函数参数）。子类型关系因此**逆着**继承方向走：`Consumer<Animal> : Consumer<Cat>`——一个"什么动物都能喂"的消费者，当然能胜任"只消费猫"的岗位，这就是逆变的全部直觉。

```kotlin
class AnyConsumer : Consumer<Animal> {
    var last: String = "（空）"
    override fun consume(x: Animal) { last = x.sound() }
}
```

```kotlin
val ac = AnyConsumer()
val c: Consumer<Cat> = ac                          // in：Consumer<Animal> → Consumer<Cat>
c.consume(Cat())
println("逆变消费后 last = ${ac.last}")
```

输出：`逆变消费后 last = 喵`。`c` 的静态类型只承诺喂猫，底下其实是能处理一切动物的 `AnyConsumer`，能力富余所以安全。

标准库里最著名的 `in` 实例是 [Comparator](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-comparator/index.html)：`Comparator<in T>`——`Comparator<Animal>` 可以拿去排 `List<Cat>`，比较器只要能比较父类，就一定能比较子类。

记方向有个流传很广的口诀 **PECS**（Producer Extends, Consumer Super，出自 *Effective Java*）——这套说法在 2018–2020 年的 Kotlin 书里很常见。Kotlin 化之后更好记：**生产者 `out`、消费者 `in`**。

两个方向的测试一起钉死：

```kotlin
fun testVariance() {
    val p: Producer<Animal> = CatFarm(Cat())        // out 协变
    assertEquals("喵", p.produce().sound())
    val ac = AnyConsumer()
    val c: Consumer<Cat> = ac                        // in 逆变
    c.consume(Cat())
    assertEquals("喵", ac.last)
}

fun testCovariantList() {
    val animals: List<Animal> = listOf(Cat(), Dog())
    assertEquals(listOf("喵", "汪"), animals.map { it.sound() })
}
```

---

## 11.4 星投影：类型实参未知时仍能安全使用

有时你拿到一个集合，**不知道也不关心**它的元素类型——只想问大小、挨个读出来。第一反应可能是 `List<Any?>`：对只读 `List` 它确实接得住一切（`List` 声明处协变，`List<Int>` 是 `List<Any?>` 的子类型），但换成不变的可变族就露馅——`MutableList<Int>` **不是** `MutableList<Any?>` 的子类型（能写 `Any?` 的列表，绝不能接受只承诺装 `Int` 的列表）。通用且准确的写法是星投影：

```kotlin
val unknown: List<*> = listOf(1, "二", 3.0)
println("List<*> 大小 = ${unknown.size}（能读出 Any?）")
val first: Any? = unknown.first()
println("第一个元素 = $first")
fun printSize(xs: List<*>) = println("printSize: 共 ${xs.size} 个元素")
printSize(unknown)
```

输出：

```text
List<*> 大小 = 3（能读出 Any?）
第一个元素 = 1
printSize: 共 3 个元素
```

`List<*>` 等价于 `List<out Any?>`：读出来一律按 `Any?` 对待（[first](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/first.html) 的返回类型就是 `Any?`），写入则被禁止——编译器不知道真实元素类型，任何写入都可能污染容器，干脆全禁。这对应 Java 的 `List<?>`，但 Kotlin 把它做成了类型系统的一等构造而非通配符语法。星投影对不变类型同样有效：`MutableList<*>`、`Array<*>` 都能接住任意实例（读 `Any?`、禁写），养成"与元素类型无关就写 `*`"的习惯，参数类型永远不会踩到不变性的坑。

`printSize` 还顺手演示了一个 Kotlin 特性：它是 `main` 内部的**局部函数**，只服务这一小段逻辑，不污染顶层命名空间。

什么时候用星投影？参数只读、逻辑与元素类型无关时——打印、计数、抽查。它是函数参数收窄的惯用法，比写死 `Any?` 更能表达"我真的不关心"。

---

## 11.5 约束与 where

11.2 见过单上界 `<T : Comparable<T>>`。真实需求常常不止一条：比如"既要能取长度，又要能互相比较"。尖括号里塞不下两个上界，Kotlin 给了 `where` 子句：

```kotlin
/** 多重约束：where 子句——T 既有 length 又能互相比较 */
fun <T> longerOf(a: T, b: T): T where T : CharSequence, T : Comparable<T> =
    if (a.length >= b.length) a else b
```

读法：`T` 同时是 `CharSequence`（有 `length`）和 `Comparable<T>`（能两两比较），两个约束用逗号并列，缺一不可。这对应 Java 的 `T extends CharSequence & Comparable<T>`，但挪到了参数列表之后，长签名不再挤在一行里。

```kotlin
println("longerOf(\"abc\", \"xy\") = ${longerOf("abc", "xy")}   // String 同时满足两个约束")
println("longerOf(\"ab\", \"xyz\") = ${longerOf("ab", "xyz")}")
```

输出：

```text
longerOf("abc", "xy") = abc   // String 同时满足两个约束
longerOf("ab", "xyz") = xyz
```

`String` 恰好两个接口都实现，顺利过关；换个只满足其一的类型（`StringBuilder` 有 `length` 但没实现 `Comparable`），编译期直接拒收。注意函数体里其实只用了 `length`——`Comparable` 约束在这里是"顺带声明能力"的教学演示，真实代码请只为用到的能力加约束，约束越少函数复用面越宽。

泛型类也能加约束，还能给构造参数带默认值：

```kotlin
/** 泛型 + 默认类型参数（与接口/委托组合的常见姿势见 09） */
class Repo<T : Any>(private val initial: List<T> = emptyList()) {
    private val items = initial.toMutableList()
    fun add(x: T) = items.add(x)
    fun all(): List<T> = items.toList()
    fun <R> map(f: (T) -> R): List<R> = items.map(f)
}
```

三个细节：① `<T : Any>` 把默认上界 `Any?` 钉成非空，仓库里不许存 null；② 构造参数默认值 [emptyList](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/empty-list.html) 让 `Repo<Int>()` 也能空手起家；③ `map` 是**成员泛型函数**，自带独立的类型参数 `R`——类的 `T` 和函数的 `R` 各管各的。

```kotlin
val repo = Repo(listOf(1, 2))
repo.add(3)
println("Repo.all() = ${repo.all()}, map翻倍 = ${repo.map { it * 2 }}")
```

输出：`Repo.all() = [1, 2, 3], map翻倍 = [2, 4, 6]`。`Repo(listOf(1, 2))` 靠构造器推断出 `Repo<Int>`；`all()` 返回拷贝而非内部 `items` 本身——10 章讲过的"交出只读拷贝"防御手法，这里再用一次。

约束行为的测试：

```kotlin
fun testWhere() {
    assertEquals("abc", longerOf("abc", "xy"))
    assertEquals("xyz", longerOf("ab", "xyz"))
    assertEquals(maxOf3(1, 9, 4), 9)
}
```

---

## 11.6 reified：把泛型实参带进运行时

先直面问题。想写一个"按类型过滤"的泛型函数：

```kotlin
fun <T> List<Any>.pick(): List<T> = filter { it is T }   // ✗ 编译错
```

`it is T` 过不了编译——11.7 要讲的类型擦除让 `T` 在运行时荡然无存，`is` 无从检查。Java 时代的解法是调用方手动递上 `Class<T>` 对象，又啰嗦又容易拿错。

Kotlin 的答案是 `inline` + `reified`：

```kotlin
/** reified：inline 才能保留类型实参，做运行时过滤不需要传 Class 对象 */
inline fun <reified T> List<Any>.pick(): List<T> = filterIsInstance<T>()
```

机制一句话：`inline` 让编译器把函数体**复制到每个调用点**，复制时把 `T` 替换成调用点的具体类型——`mixed.pick<Int>()` 处展开成 `filterIsInstance<Int>()`，而 `Int` 是具体的、`is` 可检查的类型，编译通过。`reified`（具体化）就是"这个类型参数在内联展开后依然可用"的标记。顺带一提，函数体里调的 [filterIsInstance](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/filter-is-instance.html) 本身就是标准库用一模一样的 `inline` + `reified` 写的——`pick` 只是给它包了个更语义化的名字。

```kotlin
val mixed: List<Any> = listOf(1, "a", 2, "b", 3.5)
println("mixed.pick<Int>() = ${mixed.pick<Int>()}")
println("mixed.pick<String>() = ${mixed.pick<String>()}")
println("42.isA<Int>() = ${42.isA<Int>()}, \"x\".isA<Int>() = ${"x".isA<Int>()}")
```

输出：

```text
mixed.pick<Int>() = [1, 2]
mixed.pick<String>() = [a, b]
42.isA<Int>() = true, "x".isA<Int>() = false
```

`isA` 是另一个 reified 小工具——把 `is` 检查封装成泛型扩展：

```kotlin
inline fun <reified T> Any?.isA(): Boolean = this is T
```

接收者是 `Any?`：连 null 都能问（`null is T` 恒为 false，除非 `T` 本身可空）。

`reified` 的能力清单与边界要记牢：

- **能**：`is`/`as` 检查与转换、`T::class` 拿 KClass（进而 `.java` 拿 JVM `Class`，11.9 的 `parseAs` 就靠它）；
- **不能**：直接 `T()` 构造实例（要构造请传工厂 lambda）；拿到 `T` 自己的泛型实参（`T = List<Int>` 时只能检查 `is List<*>`）；脱离 `inline` 单独存在——`reified` 是内联展开的附属能力。

这套写法在 2018–2020 年的 Kotlin 书里就很常见——那是 Gson/Retrofit 的年代，Java 侧要靠 `TypeToken` 反射戏法绕擦除，Kotlin 侧一个 `reified` 直连。到今天，它依然是 JVM 上把泛型实参保留到运行时的**唯一语言级通道**。

测试：

```kotlin
fun testReified() {
    val mixed: List<Any> = listOf(1, "a", 2, "b", 3.5)
    assertEquals(listOf(1, 2), mixed.pick<Int>())
    assertEquals(listOf("a", "b"), mixed.pick<String>())
    assertTrue(42.isA<Int>())
    assertTrue(!("x".isA<Int>()))
}
```

---

## 11.7 类型擦除：泛型只活在编译期

`reified` 为什么要靠 `inline` 曲线救国？因为 JVM 的地基叫**类型擦除**：泛型是编译器的台前戏法，字节码里只有原始类型（`List`）加上编译器自动插入的强转。这是 Java 5 引入泛型时为了兼容 1.4 字节码定下的规矩，Kotlin 照单继承。

`main` 里的这段是最直接的物证：

```kotlin
val li: List<Int> = listOf(1)
val ls: List<String> = listOf("a")
println("li::class == ls::class → ${li::class == ls::class}   // 运行时都是同一个 ArrayList")
println("li::class.java.name = ${li::class.java.name}   // .java 是通往 JVM Class 的逃生舱")
// if (li is List<Int>) {}    // ← 编译错：无法在运行时检查被擦除的类型参数
val anyList: Any = li
println("静态类型时检查恒真（警告），先转 Any 再查星投影: ${anyList is List<*>}")
```

输出：

```text
li::class == ls::class → true   // 运行时都是同一个 ArrayList
li::class.java.name = java.util.Collections$SingletonList   // .java 是通往 JVM Class 的逃生舱
静态类型时检查恒真（警告），先转 Any 再查星投影: true
```

逐行拆：

1. `li::class == ls::class` 为 `true`——`::class` 拿到的是运行时的 KClass，`List<Int>` 与 `List<String>` 的类型实参擦除后共享同一个运行时类。
2. 第二行揭晓这个类到底是谁：`java.util.Collections$SingletonList`。不是注释里随口说的 ArrayList——`listOf` 单元素走 `SingletonList`，正是 10 章实测过的"按大小分派实现"；两个单元素列表连实现类都是同一个，`==` 成立得顺理成章。`.java` 则是 KClass 通往 JVM `Class` 对象的桥，Java 反射 API 大多要它。
3. `li is List<Int>` 编译错：运行时根本没有"`List<Int>`"这个东西可查。但**星投影可以查**：`anyList is List<*>` 问的只是"是不是某种 List"，类型实参不参与，合法。
4. 为什么要先 `val anyList: Any = li` 绕一道？K2 对"静态类型已知"的表达式做恒真 `is` 检查会给警告——`li is List<*>` 在编译期就确定为 true，查了白查。教程全程 `-Werror`，警告即错误，所以先把静态类型放宽成 `Any`，检查才有信息量。这个"先转 `Any` 再查"的手法，10 章查集合实现类时已经用过一次。

擦除的三个日常后果，后面全会撞上：

- `is` 检查最细只能到 `List<*>` 粒度；
- 只差泛型实参的重载在 JVM 上签名相同，直接冲突（11.9 的 `@JvmName`）；
- 想在运行时拿类型只剩两条路：传 `Class` 对象，或 `reified`。

测试把边界钉住：

```kotlin
fun testErasure() {
    val li: List<Int> = listOf(1)
    val ls: List<String> = listOf("a")
    assertTrue(li::class == ls::class)               // 运行时类型相同
    val anyList: Any = li                            // 先放开静态类型，星投影检查才有信息量
    assertTrue(anyList is List<*>)
    assertTrue(anyList !is Set<*>)
}
```

---

## 11.8 与其他语言对照

示例程序把这个对照浓缩成了一行输出：

```kotlin
println("Kotlin: 声明处型变（out/in）+ reified；Java: 使用处通配符 ? extends；C#：out/in；Rust：所有泛型单态化")
```

展开成表格，顺便补上 C++：

| 语言 | 型变在哪标 | 运行时保留泛型？ | 一句话 |
| --- | --- | --- | --- |
| Java | 使用处：`? extends T` / `? super T` 每次手写 | 否（擦除） | 灵活但啰嗦，标错一处全线编译错 |
| **Kotlin** | **声明处：`out`/`in` 标一次处处受益**（也保留使用处投影，如 `MutableList<out T>`） | 否（擦除），`reified` 局部挽回 | JVM 擦除地基上把体验做到最省 |
| C# | 声明处：`out`/`in`（接口与委托） | 是（CLR 原生具体化） | 泛型是运行时公民，`is List<int>` 合法 |
| C++ | 无子类型型变概念 | 模板是编译期代码生成，每份实例化独立 | 零开销，顺带解锁图灵完备的模板元编程 |
| Rust | 型变基本只与生命周期相关，极少手写 | 单态化（monomorphization），每份实例化独立 | 编译期展开，用二进制体积换零运行时成本 |

启示：写 Kotlin 不要怀念 Java 的"每次使用处标通配符"——声明处型变让库作者一次决策、所有调用方受益；也别羡慕 C#/Rust 的运行时类型，JVM 的擦除是既定事实，`reified` + 传 `Class` 就是全部弹药。下一节看弹药怎么打满。

---

## 11.9 型变细则、签名冲突与 reified 工程化

三个进阶细节，都是真实代码评审里能挖出来的点。

### 细节一：out 类里的 private 消费位是合法的

```kotlin
/** out 类里的 private 成员不受型变位置限制——内部可变、外部只读（协变与可变性的和解） */
class Refillable<out T>(private var current: T, private val next: (T) -> T) {
    fun get(): T = current
    fun advance(): T { current = next(current); return current }
    // fun set(v: T) { current = v }   // ✗ 公开消费位：out 违例编译错（文档 11.10）
}
```

`private var current: T`——`var` 自带 setter，参数位置明明消费了 `T`，`out` 凭什么放行？因为 `private` 成员外部够不着：型变规则保护的是"外部调用者会怎么用 T"，私有读写不影响外部安全，编译器索性豁免。效果是**内部可变、外部只读**：`get()`/`advance()` 照常工作，类对外仍是纯粹的生产者。而被注释掉的 `fun set(v: T)` 是公开消费位——一旦公开，`Refillable<Int>` 当 `Refillable<Number>` 用时就能 `set(1.5)` 打进一个 `Double`，所以必须编译错。

```kotlin
val counter: Refillable<Int> = Refillable(1) { it + 10 }
val asNumber: Refillable<Number> = counter        // out：Int 生产者可当 Number 生产者
println("Refillable: get=${asNumber.get()}, advance=${counter.advance()}（private var 内部可变，外部只读）")
```

输出：`Refillable: get=1, advance=11（private var 内部可变，外部只读）`。`asNumber.get()` 按 `Number` 读出 1；`counter.advance()` 走 `next(1)` 得 11——两个引用指向同一对象，协变视图与真实实例互不干扰。标准库里 `List<out E>` 能协变又能自由遍历，靠的正是同一套"公开接口只产出"的设计。

测试：

```kotlin
fun testVarianceDetails() {
    val c = Refillable(1) { it + 10 }
    val asNumber: Refillable<Number> = c              // out 协变
    assertEquals(1, asNumber.get())
    assertEquals(11, c.advance())
    // 公开 set(v: T) 会编译错（out 违例）——见 Main 注释与文档 11.10
}
```

### 细节二：擦除让同名重载撞车，@JvmName 解围

```kotlin
/** 同名重载擦除后 JVM 签名相同 → platform declaration clash 编译错；@JvmName 区分后共存 */
@JvmName("sumInts")
fun sum(xs: List<Int>): Int = xs.sum()
@JvmName("sumStrs")
fun sum(xs: List<String>): String = xs.joinToString("-")
```

Kotlin 源码层面这是两个合法重载——参数类型不同嘛。但擦除后两者都是 `sum(List)`，JVM 重载决议只看擦除后的签名，`platform declaration clash` 编译错。[@JvmName](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.jvm/-jvm-name/index.html) 给它们在字节码层面各起一个名字（`sumInts`/`sumStrs`），冲突消失；而 Kotlin 调用方看到的依然是同名 `sum`，重载解析按实参的静态类型自动选择，完全无感。

```kotlin
println("同名 sum 重载: Int 版=${sum(listOf(1, 2, 3))}, String 版=${sum(listOf("a", "b"))}（@JvmName 消除擦除冲突）")
```

输出：`同名 sum 重载: Int 版=6, String 版=a-b（@JvmName 消除擦除冲突）`。String 版内部用的 [joinToString](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/join-to-string.html)，08 章就登过场。

测试：

```kotlin
fun testErasedOverloads() {
    assertEquals(6, sum(listOf(1, 2, 3)))
    assertEquals("a-b", sum(listOf("a", "b")))
}
```

### 细节三：reified 工程化——把旧式 Class 参数包装掉

先承认现实：Java 生态里大量 API 是"吃 `Class<T>`"的形状——`Gson.fromJson(String, Class<T>)` 就是典型。示例用 `parseOf` 复刻这种形状：

```kotlin
/** 旧式"吃 Class<T>"的 API（Gson.fromJson 同形状） */
@Suppress("UNCHECKED_CAST")
fun <T : Any> parseOf(raw: String, cls: Class<T>): T? = when (cls) {
    Int::class.javaObjectType -> raw.toIntOrNull()
    Long::class.javaObjectType -> raw.toLongOrNull()
    String::class.javaObjectType -> raw.trim('"')
    else -> null
} as T?
```

两个看点：① `Int::class.javaObjectType`——Kotlin 的 `Int` 到 JVM 有 `int`/`Integer` 两副面孔，`javaObjectType` 稳定给出包装类 `java.lang.Integer`（与 `javaPrimitiveType` 相对），拿来做 `Class` 相等比较才不会踩基本类型的坑；② [toIntOrNull](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/to-int-or-null.html) 一族是"解析失败给 null"而非抛异常的良民 API。`when` 已按 `cls` 分派，末尾的 `as T?` 强转实际安全，`@Suppress("UNCHECKED_CAST")` 如实压制告警——`-Werror` 下每一个警告都必须有说法。

调用方每次都要递 `Class` 对象，啰嗦且容易拿错。`reified` 包装一层：

```kotlin
/** reified 工程化：包装成无参泛型扩展——调用方再也不传 Class */
inline fun <reified T : Any> String.parseAs(): T? = parseOf(this, T::class.javaObjectType)
```

`T::class.javaObjectType` 在函数体内拿到 `Class<T>` 转交旧实现——旧代码一行不动，调用形式脱胎换骨：

```kotlin
println("旧式传 Class: ${parseOf("42", Int::class.javaObjectType)}")
println("reified 包装: \"42\".parseAs<Int>()=${"42".parseAs<Int>()}, \"hi\".parseAs<String>()=${"\"hi\"".parseAs<String>()}, \"x\".parseAs<Long>()=${"x".parseAs<Long>()}")
```

输出：

```text
旧式传 Class: 42
reified 包装: "42".parseAs<Int>()=42, "hi".parseAs<String>()=hi, "x".parseAs<Long>()=null
```

`"\"hi\""` 这个字面量本身是带引号的 `"hi"`，`parseAs<String>` 走 `trim('"')` 剥掉引号得 `hi`；`"x".parseAs<Long>()` 返回 null——`toLongOrNull` 解析失败，与 04 章的空安全链路无缝衔接。

这种"reified 包装旧 Class API"的手法在 2018–2020 年的 Kotlin 书里常见于 JSON 解析与依赖注入封装。今天的 kotlinx.serialization 用编译器插件直接生成序列化器，连 `reified` 都绕开了；但手写轻量封装时，`inline` + `reified` 仍是成本最低、体验最好的工具。

测试把新旧两种调用一起钉死：

```kotlin
fun testReifiedWrapper() {
    assertEquals(42, "42".parseAs<Int>())
    assertEquals("hi", "\"hi\"".parseAs<String>())
    assertEquals(null, "x".parseAs<Long>())
    assertEquals(42L, parseOf("42", Long::class.javaObjectType))
}
```

---

## 11.10 坑位清单

1. **默认不变**：`Box<Int>` 与 `Box<Number>` 毫无子类型关系。需要兼容就自己标 `out`/`in`，或者干脆用本就协变的只读接口（`List`）。
2. **`out` 位置写了 setter**：公开消费位直接编译错；改 `private` 可豁免，但豁免的是可见性，不是规则本身。
3. **星投影 ≠ `Any?`**：`List<*>` 读出来是 `Any?`，写不进去（null 除外）；想写就必须知道真实类型。
4. **`is List<Int>` 编译错**：运行时只能查到 `is List<*>` 粒度；要更细就 `reified`。
5. **恒真检查在 `-Werror` 下炸**：K2 对静态已知类型的 `is` 检查给警告，先转 `Any` 再查星投影。
6. **`reified` 离不开 `inline`**：`inline` 与虚函数（`open`/`abstract`/`override`）不兼容——内联要求编译期唯一确定函数体，想多态就别想 `reified`。
7. **泛型数组直接建不了**：`Array<T>` 在擦除下没有组件类型可用，标准姿势是 `inline` + `reified` 里调 `arrayOfNulls<T>(n)`。
8. **同名重载只差泛型实参**：擦除后签名相同 → `platform declaration clash`，用 `@JvmName` 给字节码名消歧。
9. **默认上界是 `Any?`**：公开 API 想拒绝 null，及早写 `<T : Any>`；等调用方传了 null 再收紧就是破坏性变更。
10. **`out`/`in` 标反方向**：记住"生产 `out`、消费 `in`"。标反的典型症状："`Producer<Cat>` 怎么不能当 `Producer<Animal>` 用？"

---

上一章：[10 集合](10-collections.md) · 下一章：[12 ⭐高阶函数与 Lambda](12-lambdas.md)
