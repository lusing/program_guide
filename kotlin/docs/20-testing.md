# 20 · 测试 ⭐

> 对应示例：`examples/20_testing/`——`src/Testing.kt` 是被测对象（一个小型任务清单领域：`TaskStore` 接口 + `InMemoryStore` 假实现 + `fizzbuzz`/`grade`/`rollDie` 三个纯函数），`src/Main.kt` 是断言画廊与方法论演示，`test/Tests.kt` 是完整测试集。
>
> 测试是教程里最"非语言特性"的一章，却可能是最值钱的一章：前面 19 章每个示例都靠它验证。本章回答三个问题——kotlin.test 的断言工具箱有什么、本教程"自写 main + 断言"的形态为什么成立（以及与 JUnit5 的对应关系）、以及超越语法的测试方法论（表驱动、边界值、可复现随机、假实现）。

## 20.1 被测对象：一个最小但完整的领域

讲测试不能对着真空讲。示例准备了一组够小但五脏俱全的被测代码（`Testing.kt` 全文）：

```kotlin
interface TaskStore {
    fun add(title: String): Int
    fun complete(id: Int): Boolean
    fun all(): List<Task2>
}

data class Task2(val id: Int, val title: String, val done: Boolean = false)

/** 内存实现：生产代码用文件/数据库实现（24 章） */
class InMemoryStore : TaskStore {
    private val items = mutableListOf<Task2>()
    private var next = 1
    override fun add(title: String): Int {
        require(title.isNotBlank()) { "标题不能为空" }
        val t = Task2(next++, title)
        items += t
        return t.id
    }
    override fun complete(id: Int): Boolean {
        val i = items.indexOfFirst { it.id == id }
        if (i < 0) return false
        items[i] = items[i].copy(done = true)
        return true
    }
    override fun all(): List<Task2> = items.toList()
}

/** 表驱动经典例：fizzbuzz */
fun fizzbuzz(n: Int): String = when {
    n % 15 == 0 -> "FizzBuzz"
    n % 3 == 0 -> "Fizz"
    n % 5 == 0 -> "Buzz"
    else -> n.toString()
}

/** 分数分级（边界测试的好目标） */
fun grade(score: Int): Char {
    require(score in 0..100) { "分数越界: $score" }
    return when {
        score >= 90 -> 'A'
        score >= 80 -> 'B'
        score >= 60 -> 'C'
        else -> 'D'
    }
}

/** 随机数：测试里用固定种子保证可复现（nextInt(from, until) 是左闭右开） */
fun rollDie(rng: kotlin.random.Random): Int = rng.nextInt(1, 7)
```

这组代码是按"可测性"挑的：`fizzbuzz` 是多分支纯函数（表驱动的绝佳素材）；`grade` 有 0–100 的四段分界和两个越界异常（边界值分析的绝佳素材）；`rollDie` 把随机源做成**参数**（可复现测试的关键设计）；`InMemoryStore` 是带状态、带校验（[require](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/require.html) 不满足抛 `IllegalArgumentException`）、带"查无此项"分支（`complete` 找不到 id 返回 `false`）的有副作用对象（行为验证的素材）。注意 `complete` 里用 [indexOfFirst](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/index-of-first.html) 定位、用 data class 的 `copy(done = true)` 生成修改后的新实例——`all()` 返回 `items.toList()` 防御性拷贝，外部拿不到内部可变的 `items`（18 章那条"只读是视角"纪律的应用）。

## 20.2 kotlin.test 断言画廊

[kotlin.test](https://kotlinlang.org/api/core/kotlin-test/) 是官方断言库，API 与框架无关（同一份断言，底层可以是 JUnit4/5/TestNG）。`Main.kt` 第一节把常用断言摆在一起：

```kotlin
println("== 20.2 断言画廊 ==")
assertEquals(4, 2 + 2, "普通相等（带失败消息）")
assertTrue("kotlin".startsWith("kot"))
assertContains(listOf(1, 2, 3), 2)
assertContains("hello world", "wor")
println("  assertEquals / assertTrue / assertContains / assertNull 全家——见 test/Tests.kt")
val e = assertFailsWith<IllegalArgumentException> { grade(101) }
println("  assertFailsWith: ${e.message}")
```

输出：

```
== 20.2 断言画廊 ==
  assertEquals / assertTrue / assertContains / assertNull 全家——见 test/Tests.kt
  assertFailsWith: 分数越界: 101
```

逐个讲：

- [assertEquals](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-equals.html)（expected, actual, message）：**期望在前、实际在后**——反了的话失败消息会误导人。第三参数是失败消息，养成必写的习惯（20.3 讲为什么）。
- [assertTrue](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-true.html) / `assertFalse`：布尔断言。能用它就不用 `assertEquals(true, x)`——失败消息更有信息量。
- [assertContains](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-contains.html)：三栖断言——集合含元素、字符串含子串、区间含值，一个 API 全包。
- [assertFailsWith](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-fails-with.html)`<异常类型> { 代码块 }`：**反向断言**——块内必须真的抛出指定异常，否则测试失败。它还**返回捕获到的异常对象**，所以示例能打印 `e.message`（输出 `分数越界: 101`）——校验"抛了"之外还能校验"抛得对"（消息里带了具体分数）。`Tests.kt` 的 `testStoreValidation` 用它守输入校验：`InMemoryStore().add("   ")`（纯空白标题）必须被 `require` 拦下。
- [assertNull](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-null.html) / `assertNotNull`：空性断言（`Tests.kt` 的 `testAssertGallery` 里有 `assertNull(null)`）。

浮点相等是特例，`Tests.kt` 给了标准姿势：

```kotlin
assertEquals(1.0 / 3.0 + 1.0 / 3.0 + 1.0 / 3.0, 1.0, 1e-9)   // 浮点用误差容限
```

三个 1/3 相加在二进制浮点下是 0.99999... 或 1.0000...1，与 1.0 不严格相等——**浮点断言永远用带 `absoluteTolerance` 的三参重载**，容限按量级选（这里是 1e-9）。不带容限的 `assertEquals(0.3, 0.1 + 0.2)` 是新人测试里的经典红。

## 20.3 表驱动：一表胜十函数

测试多分支函数时，新手会写十个几乎一样的测试函数；老手把"输入 → 期望"摆成一张表，循环断言（`Main.kt`）：

```kotlin
println("== 20.3 表驱动 ==")
val table = listOf(
    1 to "1", 3 to "Fizz", 5 to "Buzz", 15 to "FizzBuzz", 98 to "98",
)
for ((input, want) in table) {
    assertEquals(want, fizzbuzz(input), "fizzbuzz($input)")
    println("  fizzbuzz($input) = $want ✓")
}
```

输出：

```
== 20.3 表驱动 ==
  fizzbuzz(1) = 1 ✓
  fizzbuzz(3) = Fizz ✓
  fizzbuzz(5) = Buzz ✓
  fizzbuzz(15) = FizzBuzz ✓
  fizzbuzz(98) = 98 ✓
```

表驱动赢在三处：**新增用例 = 加一行表**（`Tests.kt` 的 `testFizzbuzzTable` 就扩到了 7 行，含 `10 to "Buzz"`、`30 to "FizzBuzz"`）；用例列表本身就是活的规格文档；循环体只有一处，断言写法改一次全表受益。还有一条细节：失败消息 `"fizzbuzz($input)"` 带上了**输入**——红的时候看到的是 `fizzbuzz(15): expected <FizzBuzz> but was <Fizz>`，一眼定位是哪行表坏了；写"应该相等"这类废话消息等于没写。

## 20.4 边界值分析：分段函数只测分界两侧

`grade` 把 0–100 切成四段。穷举 101 个输入没必要——**等价类划分**说同一段内行为相同，每段取代表即可；而 bug 最爱藏在**分界的两侧**（`>=` 写成 `>` 就错一分界）。所以测试表是（`Main.kt`）：

```kotlin
println("== 20.4 边界值 ==")
// grade 的四个边界：59/60 79/80 89/90 以及两端 0/100
for ((s, g) in listOf(0 to 'D', 59 to 'D', 60 to 'C', 79 to 'C', 80 to 'B', 89 to 'B', 90 to 'A', 100 to 'A')) {
    assertEquals(g, grade(s), "grade($s)")
    println("  grade($s) = $g ✓")
}
```

输出八行全绿：

```
== 20.4 边界值 ==
  grade(0) = D ✓
  grade(59) = D ✓
  grade(60) = C ✓
  grade(79) = C ✓
  grade(80) = B ✓
  grade(89) = B ✓
  grade(90) = A ✓
  grade(100) = A ✓
```

59/60、79/80、89/90 三对**夹击**三个分界，0 和 100 守住合法域两端。`Tests.kt` 的 `testGradeBoundaries` 在同样八例之外再加两发异常断言：

```kotlin
assertFailsWith<IllegalArgumentException> { grade(-1) }
assertFailsWith<IllegalArgumentException> { grade(101) }
```

越界两侧各一针——`require(score in 0..100)` 的行为至此被完全钉死：合法输入的分段、非法输入的异常，没有任何灰色地带。这就是"行为被测试钉死"的含义：以后谁把 `>= 90` 改成 `> 90`，红的会是测试而不是用户。

## 20.5 可复现的"随机"：把种子注入进去

随机数测试的朴素写法（断言"在 1..6 之间"）太弱，而直接断言具体序列又"每次运行不一样"。解法只有一个：**随机源当参数传，测试传固定种子**。`rollDie(rng: kotlin.random.Random)` 的签名就是这么设计的（而不是在函数体内 `Random.nextInt()` 写死全局随机源）：

```kotlin
println("== 20.5 固定种子的『随机』 ==")
val rng = Random(42)
val rolls = List(5) { rollDie(rng) }
println("  Random(42) 的 5 次掷骰: $rolls（每次运行都一样——可复现测试）")
val again = Random(42)                        // 同种子的新实例 → 同序列
assertEquals(rolls, List(5) { rollDie(again) }, "同种子同序列")
```

输出：

```
== 20.5 固定种子的『随机』 ==
  Random(42) 的 5 次掷骰: [6, 1, 6, 3, 2]（每次运行都一样——可复现测试）
```

[Random(seed)](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.random/-random.html) 是 stdlib 提供的**可复现生成器工厂**：同种子产生同序列（官方文档同时提醒两点——JVM 上这个生成器**不是线程安全的**；未来 Kotlin 版本可能换算法，所以 `[6, 1, 6, 3, 2]` 这个具体序列别写进跨版本承诺里，写进本版本快照没问题）。`rollDie` 里的 [nextInt(1, 7)](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.random/-random/next-int.html) 是**左闭右开**区间——1 到 6，注释专门标了。

`Tests.kt` 的 `testSeededRandom` 把思想推到完整：

```kotlin
val r1 = List(10) { rollDie(Random(42)) }
val r2 = List(10) { rollDie(Random(42)) }
assertEquals(r1, r2)                       // 同种子 → 同序列
assertContains(1..6, r1.first())           // 值域内
assertTrue(r1.all { it in 1..6 })
```

三个断言各司其职：同种子同序列（可复现性本身）、值域约束（弱断言但便宜）、`assertContains(1..6, …)` 顺带演示了区间版 assertContains。这就是**依赖注入的最小形态**：不装框架，只是"会变的东西从参数进来"。

## 20.6 假实现（fake）：观察副作用的最轻替身

纯函数断言返回值就行；有状态的 store 要验证的是**行为的副作用**。测试替身的谱系里，`InMemoryStore` 属于最轻的一档——**fake（假实现）**：一个行为近似真实、但砍掉外部依赖（磁盘/网络/数据库）的可用实现。它本身就是生产代码的一部分（24 章会有文件版 store 实现同一个接口），测试注入它既快又确定：

```kotlin
println("== 20.6 行为验证：用假实现观察副作用 ==")
val store = InMemoryStore()
val id1 = store.add("写教程")
val id2 = store.add("改示例")
store.complete(id1)
println("  all() = ${store.all()}")
assertEquals(listOf(true, false), store.all().map { it.done })
assertEquals(false, store.complete(99), "完成不存在的 id 返回 false")
println("  complete(99) = false ✓")
```

输出：

```
== 20.6 行为验证：用假实现观察副作用 ==
  all() = [Task2(id=1, title=写教程, done=true), Task2(id=2, title=改示例, done=false)]
  complete(99) = false ✓
```

验证策略是"操作 → 观察状态"：add 两个、complete 一个，然后断言 `all()` 投影出的 done 序列是 `[true, false]`；再补一针"完成不存在的 id 返回 false"。`Tests.kt` 的三个 store 测试分得更细：`testStoreBasics` 守 id 从 1 自增（`assertEquals(1, id)`）与 `Task2(1, "任务")` 的完整相等（data class 的 equals 红利）；`testStoreComplete` 守完成语义与查无此项；`testStoreValidation` 守空白标题抛异常。

谱系另一端是 **mock**（MockK 等库）：不实现行为，只录制"被调了几次、参数是什么"——验证**交互**而非状态。本教程用 fake 是因为场景里状态可观察；当你要测的对象是"调用第三方支付接口"这类不可观察副作用时，mock 才有必要。背后的设计原则同一个——**依赖倒置**：领域逻辑依赖接口（`TaskStore`），生产注入文件/DB 实现，测试注入 fake。

## 20.7 本教程的测试形态：main + 断言 vs JUnit5

看 `Tests.kt` 的 main：

```kotlin
fun main() {
    testStoreBasics()
    testStoreComplete()
    testStoreValidation()
    testFizzbuzzTable()
    testGradeBoundaries()
    testSeededRandom()
    testAssertGallery()
    println("20_testing 全部测试通过")
}
```

没有 `@Test`、没有框架——测试就是普通函数，main 顺序调用，**能打印出"全部测试通过"这行就说明没有断言炸过**（断言失败抛 `AssertionError`，进程非零退出，构建脚本的 L2 层变红）。选这个形态是因为教程环境是裸 kotlinc：没有 JUnit runner 可装，而"零配置、双击可跑、失败即停"对教学反而是优点——修复一进一退，注意力集中在第一个失败上。

真实工程用 JUnit5（17 章的 Gradle 工程已完整演示），对应关系是一张直译表：

```kotlin
class GreetingTest {                          // 教程：fun testGreeting()
    @Test
    fun greetingInsertsName() {               // 教程：main 里手动调用 → 框架反射调度
        assertEquals("Hello, Kotlin!", greeting("Kotlin"))
    }
}
```

断言库**一模一样**（kotlin.test），变的只是调度方式：框架换来失败隔离（一个红不影响其他）、生命周期钩子（`@BeforeEach` 建临时目录之类）、参数化测试与并发执行。Kotlin 反引号还能给测试起带空格的名字（``fun `add then complete marks done`()``），JUnit 报告里可读性极佳。

协程测试的最朴素形态是 `runBlocking { ... }` 里直接断言（14/15 章的测试就是这么写的）；进阶用 kotlinx-coroutines-test 的 `runTest`——虚拟时间让 `delay` 瞬间跳过。本教程场景小，`runBlocking` 足够讲清语义，工程里换 `runTest` 只是换一个入口函数。

## 20.8 测试该测什么：启发式清单

1. **正常路径**（happy path）——`testStoreBasics`。
2. **空/零/空串/空列表**——空文件词数（19 章）、空白标题（本章）。
3. **边界两侧**——20.4 的八例夹击。
4. **非法输入**——该抛的抛（`assertFailsWith`），该返回 false/null 的返回（`complete(99)`）。
5. **幂等与往返**——save 再 load 等于原值（19 章 CSV、24 章存储）。
6. **不变量**——排序后仍含全部元素、同种子同序列（`testSeededRandom`）。

命名约定二选一，团队统一即可：本教程用 `test<被测><场景>`（`testStoreComplete`）；JUnit5 工程里可用反引号句子。

## 20.9 坑位清单

1. **浮点相等不带容限必翻车**（0.1 + 0.2 ≠ 0.3）——用三参 `assertEquals`。
2. `assertFailsWith` 的块**必须真的抛**——重构把 `require` 删了，测试会静默变绿。所以异常断言的期望消息也该校验（像 Main 里打印 `e.message` 那样）。
3. **测试里别 `Thread.sleep` 等异步**——慢且脆；协程用 `runTest` 虚拟时钟，时间相关的逻辑注入时钟接口（fake clock）。
4. **共享可变状态造成顺序依赖**：测试间共享的 object 单例会被上一个测试改脏——每个测试自建实例（本章每个 `InMemoryStore()` 都是 new 的），或显式重置。
5. **随机不注种子 = CI 定期抽风**——`Random(42)` 注入，一次解决。
6. 断言消息写"应该相等"等于没写——写**输入与期望**（`grade($s)`、`fizzbuzz($input)`），失败时不用复现就能定位。
7. 文件测试不碰真实目录——`createTempDirectory` 沙盒 + 用完清场（19.8 节）。

---

上一章：[19 文件与文本](19-files.md) · 下一章：[21 并发线程](21-concurrency.md)
