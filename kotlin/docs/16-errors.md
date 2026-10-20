# 16 · 异常与错误处理

> 对应示例：`examples/16_errors/`（`src/Main.kt` + `test/Tests.kt`，Kotlin 2.4.21 / K2，JDK 21）
>
> try/throw 都是表达式、`Nothing` 类型、require/check/error 校验三件套、
> runCatching/Result 函数式错误管道、sealed 异常层级、use 自动关闭，
> 以及贯穿全章的那个问题：错误到底该"抛出去"，还是"当值传回来"。

## 16.1 错误的两种世界观

函数失败了，怎么告诉调用方？古往今来的答案只有两类：

- **抛出去**：控制流直接跳到最近的 catch，中间的栈帧全部退栈。好处是"挡不住"——你想忽略都不行（除非你故意吞）；坏处是签名上看不出来，调用方得靠文档或踩坑才知道会抛什么。
- **当值传回来**：失败是返回值的一部分（可空、`Result`、sealed 结果类型）。好处是类型签名自解释，编译器强制调用方处理；坏处是层层透传要写管道代码。

Kotlin 对两条路都给了一等支持：表达式化的 try、`Nothing` 类型、sealed 类让"抛"这条路干净；[`runCatching`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/run-catching.html)/[`Result`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-result/index.html) 让"值"这条路顺手。同时 Kotlin 废除了 Java 的 checked exception（16.10 细谈），所以"抛不抛、抛什么"不再被编译器按头——**这成了一个真正的设计决策**，16.9 会给出选型表。

本章示例里有一对双胞胎类，分别代表两种风格，后面每一节都会回到它们：

```kotlin
/** 域层：抛异常版 */
class Store1 {
    private val data = mutableMapOf("a" to 1)
    fun get(k: String): Int = data[k] ?: throw AppError.NotFound(k)
}

/** 域层：返回 Result 版——调用方被迫处理失败可能 */
class Store2 {
    private val data = mutableMapOf("a" to 1)
    fun get(k: String): Result<Int> =
        data[k]?.let { Result.success(it) } ?: Result.failure(AppError.NotFound(k))
}
```

同样的数据、同样的失败场景（key 不存在），一个 throw、一个返回 `Result.failure`。先把两兄弟的长相记住，我们从最基础的语法开始。

## 16.2 try 是表达式

Java 的 try 是语句：想把"解析成功给值、失败给兜底"写成一个表达式，得先声明变量再在两个分支里分别赋值。Kotlin 的 try **是表达式**：try 块的值是其最后一个表达式的值，catch 块同理，整条 try 可以直接放在赋值号右边：

```kotlin
val a = try { "42".toInt() } catch (e: NumberFormatException) { null }
val b = try { "x".toInt() } catch (e: NumberFormatException) { null }
println("parse: a=$a, b=$b")
println("parseLen(\"abc\") = ${parseLen("abc")}")
```

- `"42".toInt()` 正常返回 `42`，try 块产出 `Int`；catch 分支产出 `null`。两个分支类型的最小公共上界是 `Int?`，所以 `a: Int? = 42`。
- `"x".toInt()` 抛出 [`NumberFormatException`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-number-format-exception/index.html)，被 catch 接住，`b = null`。
- 这里用的 [`toInt()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/to-int.html) 是"可能失败"的典型 API；`parseLen` 则是示例文件里把同样写法提炼出的单行函数：

```kotlin
/** try 是表达式：有值 */
fun parseLen(s: String): Int = try { s.length } catch (e: Exception) { -1 }
```

输出：

```text
parse: a=42, b=null
parseLen("abc") = 3
```

两个提醒：

1. **finally 不参与求值**。try 表达式可以有 finally 块，但它只做清理，不贡献值——值的来源永远只有 try 块和 catch 块的最后一个表达式。
2. 对于"解析数字"这个具体场景，更地道的写法其实是 [`"42".toIntOrNull()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/to-int-or-null.html)——标准库已经把"失败给 null"封装好了（04 章）。try 表达式的价值在于**任意**"试一下、失败就兜底"的逻辑都能一行写完，而不只是数字解析。

## 16.3 自定义异常：sealed 层级

抛异常的第一个工程问题是：抛什么。直接 `throw Exception("...")` 等于没分类，调用方只能靠字符串匹配区分错误。示例的做法是**密封异常层级**：

```kotlin
/** 自定义异常层级：业务错误一个根，子类按域分 */
sealed class AppError(message: String) : Exception(message) {
    class NotFound(val key: String) : AppError("找不到: $key")
    class Invalid(val why: String) : AppError("非法输入: $why")
}
```

- 根类继承 [`Exception`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-exception/index.html)，所以整个层级都是合法的异常。
- `sealed` 意味着子类集合封闭、有穷（08 章的 ADT 思想）——业务错误有多少种，一眼数得清。
- 每个子类携带**结构化字段**（`key`、`why`），消息在构造时就拼好，调用方既能拿 `e.message` 给人看，也能拿 `e.key` 做程序化处理。

抛它的是 16.1 见过的 `Store1`：`data[k] ?: throw AppError.NotFound(k)`——elvis 右侧放 throw，取不到值就炸。接它的一侧：

```kotlin
val s1 = Store1()
println("get(\"a\") = ${s1.get("a")}")
try {
    s1.get("zzz")
} catch (e: AppError.NotFound) {
    println("捕获 NotFound: ${e.message}")
} catch (e: AppError) {
    println("捕获 AppError: ${e.message}")          // sealed → 有穷分支，else 都不用
}
```

输出：

```text
get("a") = 1
捕获 NotFound: 找不到: zzz
```

catch 块按**从上到下的第一个匹配**生效，所以子类在前、根在后（顺序反了编译器会警告后面的分支不可达）。sealed 的好处在这里兑现：层级有穷，`catch (e: AppError)` 一个分支就能兜住全部业务错误；以后给层级加新子类时，IDE 能列出所有兄弟类，你不会忘了还有哪种错误没处理。

测试侧用 [`assertFailsWith`](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-fails-with.html) 验证"抛的是精确子类，且消息正确"——它的返回值就是捕获到的那只异常，可以继续断言：

```kotlin
fun testExceptions() {
    val s = Store1()
    assertEquals(1, s.get("a"))
    val e = assertFailsWith<AppError.NotFound> { s.get("zzz") }   // 精确子类
    assertEquals("找不到: zzz", e.message)
    // sealed 根：catch (e: AppError) 一个分支就能覆盖全部子类（Main 里演示）
}
```

## 16.4 require / check / error：校验三件套

有一类"异常"其实不是业务失败，而是**程序员犯了错**：参数传了负数、对象状态不对劲。这种场景不该手写 `if (!cond) throw ...`，标准库给了语义更明确的三件套：

```kotlin
/** 标准库的内置校验：require(参数) / check(状态) / error(直接抛) */
fun shrink(s: String, n: Int): String {
    require(n >= 0) { "n 不能为负（参数校验）: $n" }    // IllegalArgumentException
    check(s.length >= n) { "串太短（状态校验）" }       // IllegalStateException
    return s.take(n)
}
```

main 里三种情况各触发一次：

```kotlin
println(shrink("kotlin", 3))
try { shrink("kt", -1) } catch (e: IllegalArgumentException) { println("require: ${e.message}") }
try { shrink("kt", 5) } catch (e: IllegalStateException) { println("check: ${e.message}") }
```

输出：

```text
kot
require: n 不能为负（参数校验）: -1
check: 串太短（状态校验）
```

| 函数 | 语义 | 抛出 | 用途 |
|---|---|---|---|
| [`require(cond) { msg }`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/require.html) | 调用方契约 | [`IllegalArgumentException`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-illegal-argument-exception/index.html) | 公开 API 的参数防线 |
| [`check(cond) { msg }`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/check.html) | 自身状态 | [`IllegalStateException`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-illegal-state-exception/index.html) | "到这儿不该为假"的断言 |
| [`error(msg)`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/error.html) | 直接抛 | `IllegalStateException` | 不可达分支 / elvis 兜底 |

细节：

1. **消息是惰性 lambda**。`{ "n 不能为负（参数校验）: $n" }` 只在条件不成立时才求值——正常路径上零字符串拼接开销。消息里带上现场数据（`$n`），排查时不用猜。
2. `require` vs `check` 的区别不在行为而在**语义标注**：前者读作"调用方的锅"，后者读作"我自己的锅"。异常类型不同，上层可以据此区分。配套的 [`requireNotNull`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/require-not-null.html)/[`checkNotNull`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/check-not-null.html) 专门对付可空值。
3. `error(...)` 等价于 `throw IllegalStateException(...)`，但返回类型是 `Nothing`（16.7），所以能出现在任何需要值的位置：`val x = maybe ?: error("must exist")`。
4. 示例里 `s.take(n)` 是 [`take`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/take.html)：`shrink("kotlin", 3)` 取前 3 个字符得 `"kot"`。

对应测试：

```kotlin
fun testRequireCheck() {
    assertEquals("kot", shrink("kotlin", 3))
    assertFailsWith<IllegalArgumentException> { shrink("kt", -1) }
    assertFailsWith<IllegalStateException> { shrink("kt", 5) }
}
```

## 16.5 runCatching 与 Result 链

现在换一条轨：把"试一下就炸"变成"试一下给个盒子"。[`runCatching`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/run-catching.html) 执行一块代码，成功装进 [`Result.success`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-result/index.html)，失败（任何 Throwable）装进 `Result.failure`——**异常在边界被翻译成了值**：

```kotlin
val r1 = runCatching { "42".toInt() }
val r2 = runCatching { "x".toInt() }
println("成功: getOrNull=${r1.getOrNull()}, isFailure=${r1.isFailure}")
println("失败: getOrElse={${r2.getOrElse { -1 }}}")
println("map: ${r1.map { it * 2 }.getOrNull()}, recoverCatching: ${r2.recoverCatching { 0 }.getOrNull()}")
r1.fold({ println("fold 成功分支: $it") }, { println("fold 失败分支: $it") })
r2.fold({ println("不会到这") }, { println("fold 失败分支: ${it.message}") })
val chained = runCatching { "8" }
    .mapCatching { it.toInt() }
    .mapCatching { it * 100 }
println("mapCatching 链: ${chained.getOrDefault(-1)}")
```

输出（注意第二行大括号是字符串模板里字面输出的 `{ }`）：

```text
成功: getOrNull=42, isFailure=false
失败: getOrElse={-1}
map: 84, recoverCatching: 0
fold 成功分支: 42
fold 失败分支: For input string: "x"
mapCatching 链: 800
```

逐个成员说清（都在 [`Result` 类索引页](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-result/index.html)下）：

- `getOrNull()`：成功给值、失败给 null——最暴力的消费方式，等于把失败原因扔掉。
- `getOrElse { -1 }`：失败时执行 lambda 给兜底值，`r2` 走这里得 `-1`。
- `map { it * 2 }`：只对成功值变换，`42 → 84`；失败原样穿过。
- `recoverCatching { 0 }`：只对失败做恢复，`r2` 从 Failure 变回 Success(0)。
- `fold(onSuccess, onFailure)`：两分支终结消费。`r1` 走成功分支打印 `42`；`r2` 走失败分支，`it` 是那只 `NumberFormatException`，`it.message` 是 `For input string: "x"`。
- `mapCatching { it.toInt() }`：和 `map` 的区别是关键——**`mapCatching` 会把变换 lambda 里抛出的异常也装成 Failure**，而 `map` 不兜底（变换里炸了会直接抛出去）。变换可能失败时（比如这里的 `toInt()`），永远用 `mapCatching`。链上任何一步失败，后续步骤全部短路，最后的 `getOrDefault(-1)` 拿到的是链尾状态：`"8" → 8 → 800`。

测试里有一条专门验证链式短路——第一步解析就失败，第二步根本不会执行：

```kotlin
assertEquals(800, runCatching { "8" }.mapCatching { it.toInt() }.mapCatching { it * 100 }.getOrDefault(-1))
assertEquals(-1, runCatching { "8x" }.mapCatching { it.toInt() }.getOrDefault(-1))
```

一个必须记住的警告：`runCatching` 捕获的是**一切 Throwable**，包括协程的 `CancellationException`（15 章）。所以**别用 `runCatching` 包住含挂起点的代码块**——它会把"协程被取消"误当成一次普通失败吞进盒子，破坏结构化并发。要捕就捕具体异常类型。

## 16.6 Result 版领域函数

`runCatching` 是"在边界翻译"；`Store2` 则更进一步——**API 签名本身就是 Result**，失败可能性写在类型里：

```kotlin
class Store2 {
    private val data = mutableMapOf("a" to 1)
    fun get(k: String): Result<Int> =
        data[k]?.let { Result.success(it) } ?: Result.failure(AppError.NotFound(k))
}
```

消费侧用 `fold` 两分支处理：

```kotlin
val s2 = Store2()
s2.get("a").fold({ println("成功: $it") }, { println("失败: ${it.message}") })
s2.get("zz").fold({ println("成功: $it") }, { println("失败: ${it.message}") })
```

输出：

```text
成功: 1
失败: 找不到: zz
```

和 `Store1` 对照着看，差异全在调用方的处境：`Store1.get` 的签名 `fun get(k: String): Int` 对失败**只字不提**，不读实现就不知道会抛 `NotFound`；`Store2.get` 的 `Result<Int>` 把"我可能失败"刻进了类型，想拿值就必须表态怎么处理。这就是 16.1 说的"编译器强制处理"。

顺带澄清一个历史包袱：Kotlin 1.5 之前 `Result` 不允许直接作返回类型（需要编译器开关），老文章里的警告就来自那个年代。**现在（1.5 起，含本教程的 2.4.21）`Result` 作返回类型是完全合法的常规用法**——`Store2` 在 `-Werror` 下零告警编译通过就是证据。

测试里还演示了 `exceptionOrNull()`——`getOrNull()` 的镜像，失败时给你那只异常，成功时给 null：

```kotlin
fun testStore2() {
    val s = Store2()
    assertEquals(1, s.get("a").getOrDefault(-1))
    assertTrue(s.get("zz").isFailure)
    val msg = s.get("zz").exceptionOrNull()?.message
    assertEquals("找不到: zz", msg)
}
```

## 16.7 Nothing：永不返回的类型

示例文件顶部有两行看起来很平常、其实很值得玩味的代码：

```kotlin
/** throw 是 Nothing 型表达式——可以出现在任何需要值的地方 */
val fallback: Int = try { throw AppError.Invalid("demo") } catch (e: AppError.Invalid) { 0 }
fun boom(): Nothing = throw AppError.Invalid("必炸")
```

`throw` 在 Kotlin 里是表达式，而且它的类型是 [`Nothing`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-nothing/index.html)——**没有任何实例、是所有类型的子类型**的类型。第一行里 try 分支的类型是 `Nothing`，catch 分支是 `Int`，公共上界是 `Int`，所以 `fallback: Int` 成立（运行结果是 `0`，因为 throw 出去立刻被接住了）。第二行 `boom()` 声明返回 `Nothing`，等于向编译器承诺"这个函数永远不会正常返回"，函数体一个 throw 正好兑现。

`Nothing` 最实用的出场在 elvis 右侧：

```kotlin
println("throw 也是表达式: fallback=$fallback")
val list = listOf(1)
val first = list.firstOrNull() ?: boom()     // elvis 右侧 Nothing → first: Int
println("Nothing 参与 elvis: first=$first")
```

输出：

```text
throw 也是表达式: fallback=0
Nothing 参与 elvis: first=1
```

[`firstOrNull()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/first-or-null.html) 返回 `Int?`。elvis 右侧的 `boom()` 类型是 `Nothing`——它是 `Int` 的子类型，所以整个表达式的类型被收窄为**非空的 `Int`**：`first` 可以直接当 Int 用，不用再判空。语义也正好："取不到就终止"，要么有值，要么程序根本走不到下一行。

`Nothing` 的三个高频出场，记一下：`throw`、`error("...")`（16.4）、[`TODO()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-t-o-d-o.html)。它们都能塞进任何需要值的位置，让"这条路径到此为止"通过类型检查。测试：

```kotlin
fun testNothing() {
    assertEquals(0, fallback)
    assertEquals(1, listOf(1).firstOrNull() ?: boom())
}
```

## 16.8 use：自动关闭（try-with-resources）

资源（文件、流、连接）用完必须关，哪怕中途抛异常——Java 的答案是 try-with-resources，Kotlin 把它做成了标准库函数 [`use`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/use.html)：

```kotlin
"第一行\n第二行".reader().use { r ->
    println("读出字符数: ${r.readText().length}")
}   // use 结束自动 close
```

[`reader()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/reader.html) 把字符串包成 `StringReader`，`use` 把它交给 lambda 使用，**无论 lambda 正常结束还是抛异常，返回前都会调用 `close()`**。输出：

```text
读出字符数: 7
```

7 的来历：`"第一行\n第二行"` 是 3 个汉字 + 1 个换行符 + 3 个汉字，`readText()` 原样读出，`length` 即 7。

`use` 不是字符串/IO 的专利，任何实现 [`AutoCloseable`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-auto-closeable/index.html)（或老式 `Closeable`）的类型都能用，而且 `use` 自身的返回值就是 lambda 的返回值。测试用一个自制资源精确验证了"关闭时机"——**use 块内还没关，use 返回后必关**：

```kotlin
fun testUse() {
    var closed = false
    class Res : AutoCloseable { override fun close() { closed = true } }
    Res().use { assertEquals(true, !closed) }    // use 里还没关
    assertTrue(closed)                            // use 返回后必关
}
```

还有一个容易忽略的保证：如果 lambda 抛了异常、`close()` 也抛了异常，后者的异常会被抑制（suppressed）挂到前者上，不会把原始错误盖掉——和 Java try-with-resources 的行为一致。

## 16.9 策略选型：什么时候 throw，什么时候返回值

语法都齐了，回到 16.1 的设计决策。示例程序的最后一屏直接把答案打印了出来：

```text
== 16.9 策略选型 ==
  编程错误/调用方 bug → require/throw 快速失败 | 可预期的业务失败 → Result/sealed 返回值
  混合用法：内部 throw，边界 runCatching 转 Result——26 行的 Store1/Store2 是两种风格
```

展开成选型表：

| 场景 | 选择 | 理由 |
|---|---|---|
| 调用方 bug（传了非法参数） | `require` / throw | 快速失败，堆栈就是最好的错误报告 |
| 自身不变量被打破 | `check` / `error` | 同上——这不是"业务"，是程序写错了 |
| **可预期的业务失败**（查无此键、解析失败、网络超时） | `Result` / sealed 返回值 / `xxxOrNull` | 写进类型签名，调用方被迫表态 |
| 边界适配（第三方库抛异常，你的 API 是值风格） | `runCatching` | 异常 → 值的翻译器 |
| 跨协程/线程的失败 | 异常沿作用域树传播（14 章），到边界再转 Result | 挂起的栈没法靠返回值逐层透传 |

"混合用法"是服务端代码里最常见的组合：**内部各层用 throw 快速失败**（写起来痛快，堆栈完整），**在模块/协程边界用 `runCatching` 统一转 Result**（给调用方一个必须处理的类型）。`Store1`/`Store2` 这 26 行双胞胎就是两种极端风格的标本，真实项目里往往两者各取一段。

反面教材也记两条：不要用异常做正常流程控制（拿 `catch` 当 `if` 用，又慢又难读）；不要在管道末端忘记消费（`getOrNull()` 之后没判空，等于把异常世界的坑搬回了值世界）。

## 16.10 与 Java checked exception 对照

Java 的 checked exception 强制调用方 catch 或在签名上 `throws` 声明。Kotlin **没有** checked exception——不强制捕获、没有 `throws` 关键字。设计理由是实践观察：强制声明并没有带来更可靠的程序，反而催生了海量的吞异常样板（`catch (e: Exception) { /* 忽略 */ }`）和无意义的逐层 `throws` 转贴。Kotlin 用两道别的防线替代：空安全消灭了最大的运行时异常源（NPE）；可预期的失败鼓励走值通道（`Result`/可空/sealed），由编译器通过类型系统强制处理——比异常签名更可靠，因为它不会像 `throws` 那样被一键转贴。

互操作上：调用会抛 checked exception 的 Java 方法，Kotlin 侧随意，不 catch 也不报错；反过来，Kotlin 函数想让 Java 调用方看到 `throws` 声明，需要加 `@Throws` 注解（18 章讲互操作时细说）。

## 16.11 坑位清单

1. **空 catch 是万恶之源**。`catch (e: Exception) { }` 把bug从"立刻崩溃"变成"哪天悄悄数据不对"。至少记日志，拿不准就 rethrow。
2. `runCatching` 捕获一切 Throwable，包括 [`CancellationException`](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-cancellation-exception/index.html)。协程里别用它包挂起点；要捕捕具体类型。
3. `map` 和 `mapCatching` 选错：`map` 的变换里抛异常会直接炸出去，不会被装盒。变换可能失败就用 `mapCatching`。
4. `getOrThrow()`/`getOrNull()` 忘记兜底，等于绕一圈又回到异常/可空世界。管道末端用 `fold`/`getOrElse`/`getOrDefault` 明确收尾。
5. **finally 里写 return 会吃掉 try 里正在传播的异常**（JVM 老坑，Kotlin 一样）。finally 只做清理，别返回值。
6. catch 分支顺序必须**先子类后父类**。写反了父类分支先匹配，子类分支成了死代码（编译器会警告，`-Werror` 下直接不过）。
7. `TODO()`/`error()` 返回 `Nothing`，用它初始化的 val 编译能过、运行必炸。它们是脚手架，不是生产代码的占位值——提交前搜一遍。
8. 别为了"风格统一"把一切都塞进 Result。**编程错误就该炸**（require/check），把 bug 包装成业务失败只会让调用方写出无意义的恢复分支。

## 本章验证

- `src/Main.kt` 与 `test/Tests.kt` 在 Kotlin 2.4.21（K2）/ JDK 21 下 `kotlinc -Werror` 编译，零告警。
- `Tests.kt` 六个测试全绿：`testExceptions`（sealed 层级 + `assertFailsWith` 精确子类）、`testRequireCheck`（三件套异常类型）、`testResultChain`（含链式短路）、`testStore2`（Result 版 API + `exceptionOrNull`）、`testNothing`（elvis + `Nothing`）、`testUse`（关闭时机）。
- 运行 `MainKt` 正常退出（exit 0），输出与 `expected.txt` 逐字节一致——本章所有输出块均引自该快照。

---

上一章：[15 ⭐Channel与Flow](15-flow.md) · 下一章：[17 工程化与 Gradle](17-gradle.md)
