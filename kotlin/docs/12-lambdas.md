# 12 · 高阶函数与 Lambda ⭐

> 对应示例：`examples/12_lambdas/`（`src/Main.kt` 演示 + `test/Tests.kt` 断言 + `expected.txt` 输出快照）
>
> 函数类型、`it`、函数引用、真闭包、带接收者的函数类型、
> 作用域函数五件套、inline 与非局部返回——Kotlin 表达力的发动机。

## 12.1 为什么要把函数当值传来传去

写代码时经常遇到"流程固定、步骤可变"的场景：过滤列表时，循环框架不变，变的是判断条件；排序时，遍历与交换不变，变的是比较逻辑；点按钮时，"点击"这件事不变，变的是"点击后干什么"。Java 8 之前的解法是单方法接口：为每一种可变的步骤定义接口、写匿名内部类——五行仪式换一行逻辑。

Kotlin 把函数提升为**一等值**：函数可以存进变量、当参数传递、当返回值返回，类型系统里有专门的**函数类型** `(参数类型...) -> 返回类型`。不需要为每个回调发明接口名，lambda 就地写出那一小段可变的逻辑。参数或返回值带函数类型的函数，就叫**高阶函数**。

本章示例程序的四个顶层定义，恰好覆盖"函数是一等值"的四种用法，后面各节逐一展开：

```kotlin
/** 函数类型：(Int, Int) -> Int；参数可以是函数，返回值也可以是函数 */
fun operate(a: Int, b: Int, op: (Int, Int) -> Int): Int = op(a, b)

/** 返回函数的高阶函数（柯里化的雏形，22 章细讲） */
fun multiplier(k: Int): (Int) -> Int = { it * k }

/** 带接收者的函数类型：T.() -> R——lambda 里的 this 就是 T */
fun <T> T.printlned(tag: String, block: T.() -> String): String = "[$tag] ${block()}"

/** 高阶函数自定义：像标准库 filter 一样工作 */
fun <T> myFilter(items: List<T>, pred: (T) -> Boolean): List<T> {
    val out = mutableListOf<T>()
    for (x in items) if (pred(x)) out.add(x)
    return out
}
```

`operate` 的第三个参数 `op` 类型是 `(Int, Int) -> Int`——"吃两个 Int、吐一个 Int 的函数"；`multiplier` 的**返回值**类型是 `(Int) -> Int`；`printlned` 的参数 `block` 是带接收者的函数类型（12.6 节）；`myFilter` 演示自己写一个 `filter` 同款高阶函数（12.9 节）。

## 12.2 lambda 基本形

lambda 是"没有名字的函数字面量"，写在一对花括号里：`{ 参数 -> 函数体 }`。示例 main 的开头：

```kotlin
    println("== 12.2 lambda 基本形 ==")
    val square: (Int) -> Int = { x -> x * x }
    val cube = { x: Int -> x * x * x }              // 类型写在参数上，变量省略声明
    println("square(5) = ${square(5)}, cube(3) = ${cube(3)}")
    val sum2: (Int, Int) -> Int = { a, b -> a + b }
    println("sum2(3, 4) = ${sum2(3, 4)}")
```

输出（`expected.txt` 开头三行）：

```text
== 12.2 lambda 基本形 ==
square(5) = 25, cube(3) = 27
sum2(3, 4) = 7
```

三种写法说明：类型标注可以放等号左边（变量类型），也可以放 lambda 的参数上（`x: Int`），编译器从哪边拿到信息都行——两边都省才会报"无法推断类型"。多参数 lambda 用逗号分隔参数，**最后一行表达式的值就是返回值**，不需要 `return`。调用函数值和调用普通函数一样用圆括号：`square(5)`。

两个示例没直接演示但常用的形态，顺带记住：返回 `Unit` 的 lambda 直接写 `val log: (String) -> Unit = { println(it) }`；**函数类型本身可空**时要加括号——`(() -> Int)?` 是"可空的函数"，`() -> Int?` 是"返回可空 Int 的函数"，一个括号两种语义。

## 12.3 it：单参数 lambda 的隐式名

lambda 只有一个参数、且没写 `->` 时，编译器自动给它起名 `it`：

```kotlin
    println("== 12.3 it：单参数 lambda 的隐式名 ==")
    val isEven: (Int) -> Boolean = { it % 2 == 0 }
    println("isEven(4) = ${isEven(4)}")
    // it 只在单参数时可用；多参数必须命名；不用的参数可以叫 _
```

输出：

```text
== 12.3 it：单参数 lambda 的隐式名 ==
isEven(4) = true
```

`{ it % 2 == 0 }` 等价于 `{ x: Int -> x % 2 == 0 }`，省掉了参数声明。这是 Kotlin 链式集合操作简洁手感的来源。

两条边界规则（注释里点到的）：

1. **多参数没有 `it`**。两个及以上参数必须写全 `{ a, b -> ... }`，这时写 `it` 直接编译失败。
2. **用不到的参数叫 `_`**（比如解构 Pair 只用一半：`{ (_, second) -> ... }`），`_` 明确告诉读者"这里有个参数但我不关心"。

什么时候该放弃 `it` 改显式命名？lambda 嵌套（lambda 里再写 lambda）或参数含义不直观时——`it` 永远指**最内层** lambda 的参数，嵌套两层极易读串。

## 12.4 把函数当值传递

这一节看 `operate` 的三种喂法，以及"函数进集合"和"函数返回函数"。示例代码：

```kotlin
    println("== 12.4 把函数当值传递 ==")
    println("operate(6, 3, { a, b -> a * b }) = ${operate(6, 3, { a, b -> a * b })}")
    println("operate(6, 3) { a, b -> a - b } = ${operate(6, 3) { a, b -> a - b }}   // 尾随 lambda")
    println("operate(6, 3, ::maxOf) = ${operate(6, 3, ::maxOf)}")   // 函数引用 ::
    // ::minOf 重载太多，放进集合时给个明确的函数类型帮编译器选 minOf(Int, Int)
    val ops: List<(Int, Int) -> Int> = listOf(::minOf, ::maxOf)
    println("函数也能进集合: ${ops.joinToString { it(2, 9).toString() }}")
    val triple = multiplier(3)
    println("multiplier(3)(7) = ${triple(7)}        // 返回的函数带着自己的 k")
```

输出：

```text
== 12.4 把函数当值传递 ==
operate(6, 3, { a, b -> a * b }) = 18
operate(6, 3) { a, b -> a - b } = 3   // 尾随 lambda
operate(6, 3, ::maxOf) = 6
函数也能进集合: 2, 9
multiplier(3)(7) = 21        // 返回的函数带着自己的 k
```

逐行解读：

**第一种：lambda 写在参数列表里**。`operate(6, 3, { a, b -> a * b })` 把就地写的乘法传进去。能写，但括号里塞花括号很丑。

**第二种：尾随 lambda（trailing lambda）**。约定：函数**最后一个参数**是函数类型时，lambda 可以挪到圆括号外面。`operate(6, 3) { a, b -> a - b }` 和前一种完全等价——这就是 `list.filter { ... }.map { ... }` 链式写法的语法地基。标准库高阶函数清一色把函数参数放在最后，就是为了让调用方能用尾随 lambda。

**第三种：函数引用 `::`**。逻辑已有现成函数时，用 `::函数名` 把它变成值：`operate(6, 3, ::maxOf)` 里的 [maxOf](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/max-of.html) 是标准库比较函数。lambda 和 `::` 的取舍很简单：逻辑现成用引用，就地一两行用 lambda。

**函数进集合**。`val ops: List<(Int, Int) -> Int> = listOf(::minOf, ::maxOf)` 把两个函数引用装进 List——函数值和 Int、String 一样能当集合元素。注意源码里的注释：[minOf](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/min-of.html) 重载太多（两个/三个/可变参数、各种数值类型），编译器单看 `::minOf` 不知道选哪个；标注 `List<(Int, Int) -> Int>` 等于告诉它"我要吃两个 Int 的那个版本"。随后 `ops.joinToString { it(2, 9).toString() }` 对每个函数元素执行 `it(2, 9)`，所以输出 `2, 9`。

**函数返回函数**。`multiplier(k: Int): (Int) -> Int = { it * k }` 吃一个因子，吐出"乘这个因子的函数"。`val triple = multiplier(3)` 拿到的 `triple` 是一个**记住了 k=3** 的函数，`triple(7)` 得 21。每次调用 `multiplier` 产出的函数都携带自己的 `k`，互不干扰——这是柯里化的雏形（把多参数函数拆成一串单参数函数），第 22 章细讲。

## 12.5 闭包：lambda 捕获外部变量

lambda 体内可以直接读写**定义处**的局部变量，这就是闭包（closure）：

```kotlin
    println("== 12.5 闭包：lambda 捕获外部变量 ==")
    var calls = 0
    val counted = { calls++; calls * 10 }
    println(counted()); println(counted()); println(counted())
    println("calls 被闭包改到 = $calls")
    // Java 里 lambda 只能捕获 effectively final；Kotlin 能捕获 var——这是真闭包
```

输出：

```text
== 12.5 闭包：lambda 捕获外部变量 ==
10
20
30
calls 被闭包改到 = 3
```

`counted` 是零参数 lambda，体内却引用了外层的 `var calls`——每调一次 `calls` 加一并返回 `calls * 10`，三次调用依次输出 10、20、30，最后 `calls` 变成 3。lambda 和外层代码读写的是**同一份**变量。

和 Java 的关键差别：Java 的 lambda 只能捕获 **effectively final** 的局部变量（赋值后不再变的），Kotlin 的 lambda 能捕获并**修改** `var`——这才是"真闭包"的含义。实现上，被捕获的 `var` 会被包进一个共享引用容器，lambda 与外层代码持有同一个容器。

能力越大越要小心：捕获了 `var` 的 lambda 一旦被传进异步/并发代码，就成了**共享可变状态**——第 15 章讲的竞态，根源之一就是这种"顺手捕获"。把 lambda 传出去之前，想想是不是把值拷一份（用参数传入）更稳。

## 12.6 带接收者的 lambda：`T.() -> R`

普通函数类型的参数是显式传的；**带接收者的函数类型** `T.() -> R` 则让 lambda 体内的 `this` 指向某个 `T` 对象。示例里的 `printlned`：

```kotlin
/** 带接收者的函数类型：T.() -> R——lambda 里的 this 就是 T */
fun <T> T.printlned(tag: String, block: T.() -> String): String = "[$tag] ${block()}"
```

调用现场：

```kotlin
    println("== 12.6 带接收者的 lambda：T.() -> R ==")
    println(10.printlned("平方") { (this * this).toString() })
    println("kotlin".printlned("长度") { "$length（this=$this）" })
```

输出：

```text
== 12.6 带接收者的 lambda：T.() -> R ==
[平方] 100
[长度] 6（this=kotlin）
```

`printlned` 自身是扩展函数（第 13 章细讲扩展），所以在任意 `T` 上可调；它把 `block()` 当"接收者上的无参函数"来调。调用方的 lambda 里：`this` 就是接收者对象（`10` 或 `"kotlin"`），成员可以**裸用**——`"$length"` 实际是 `this.length`，这就是第二行输出 `6（this=kotlin）` 的来历。

这个特性是 **DSL（领域特定语言）的地基**：`apply`/`run`/`with`/`buildString` 全靠它让 lambda 里省掉对象前缀，第 23 章的 HTML builder 用的是同一招。

## 12.7 作用域函数五件套

标准库有五个形似的函数——[let](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/let.html)、[run](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/run.html)、[with](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/with.html)、[apply](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/apply.html)、[also](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/also.html)，统称**作用域函数**：都在一个对象上执行一段 lambda，区别只在两个维度——**对象以什么身份进 lambda**（`this` 还是 `it`）、**返回什么**（lambda 的结果还是对象本身）。

示例用一个 data class 把五个全演了一遍：

```kotlin
data class Player(val name: String, var score: Int)
```

```kotlin
    println("== 12.7 作用域函数五件套 ==")
    val p: Player? = Player("Ada", 90)
    // let：对可空值做"非空才执行"，it 是值
    p?.let { println("let: ${it.name} 得分 ${it.score}") }
    // run：对象 + 计算结果，this 是对象
    val ada = p!!                                   // !! 断言一次，之后智能转换为非空
    val bonus = ada.run { score * 2 }
    println("run: bonus = $bonus")
    // with：显式传对象，this 是对象（不是扩展）
    with(ada) { score += 5; println("with: 修改后 ${this.name}=${score}") }
    // apply：配置对象并返回对象本身（this 是对象，返回 this）
    val p2 = Player("Bob", 0).apply { score = 50; println("apply: 配置中 name=$name") }
    println("apply 产物: $p2")
    // also：做点副作用（打印/日志/校验）并返回对象本身（it 是值）
    val p3 = Player("Carol", 60).also { println("also: 创建了 ${it.name}") }
    println("also 产物: $p3")
```

输出：

```text
== 12.7 作用域函数五件套 ==
let: Ada 得分 90
run: bonus = 180
with: 修改后 Ada=95
apply: 配置中 name=Bob
apply 产物: Player(name=Bob, score=50)
also: 创建了 Carol
also 产物: Player(name=Carol, score=60)
```

逐个对照输出看行为：

- **`p?.let { ... }`**：`?.` 保证只有 `p` 非空才进 lambda；lambda 里 `it` 就是 `p` 本体。这是"可空值非空才做事"的惯用法。返回值是 lambda 最后一行。
- **`ada.run { score * 2 }`**：`this` 是 `ada`，所以 `score` 不用写 `ada.score`；返回 lambda 的结果 180（90×2）。`run` 适合"在对象语境里算一个值"。
- **`with(ada) { ... }`**：功能同 `run`，但不是扩展——对象当普通参数传。`score += 5` 把 90 改成 95（输出 `修改后 Ada=95`）。适合"对同一对象连续做一串操作"。
- **`Player("Bob", 0).apply { score = 50; ... }`**：`this` 是新对象，lambda 里做配置；**返回值是对象本身**而非 lambda 结果，所以 `p2` 是 `Player(name=Bob, score=50)`。`apply` 的主场是"建完对象就地配置，然后接着用这个对象"。
- **`Player("Carol", 60).also { ... }`**：和 `apply` 一样返回对象本身，但 lambda 里对象是 `it`——适合"顺路做点副作用（打日志、校验）再把对象传下去"。输出证实：`also 产物` 还是原来那个 Carol。

测试代码专门用引用相等验证了 `also` 的"返回同一实例"：

```kotlin
    val same = p.also { }
    assertTrue(same === p)                // also 返回同一实例（引用相等）
```

`===` 是引用相等（同一个对象），不是值相等——`also` 确实没造新对象。

两个维度画成选型表：

| 函数 | lambda 里的对象 | 返回值 | 一句话场景 |
|---|---|---|---|
| `let` | `it` | lambda 结果 | `x?.let { ... }` 非空才执行；临时变换 |
| `run` | `this` | lambda 结果 | 在对象语境里算个值 |
| `with` | `this`（参数传入） | lambda 结果 | 对同一对象连做多步（不是扩展） |
| `apply` | `this` | **对象本身** | 配置/初始化后返回自身 |
| `also` | `it` | **对象本身** | 顺路副作用后返回自身 |

口诀：**改对象拿对象 → apply；拿值 → run/let；带副作用拿对象 → also**。`it` 还是 `this` 的取舍：嵌套作用域里选 `it`（可改名）避免 `this` 歧义。

## 12.8 inline 与非局部返回

标准库的 [forEach](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/for-each.html)、[map](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/map.html)、[firstOrNull](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/first-or-null.html) 都是 `inline` 函数：编译器把函数体和 lambda **原样铺进调用处**，不生成 lambda 对象。两个直接后果：

1. **零调用开销**——没有函数对象分配、没有虚调用，写 `list.map { ... }` 和手写 for 循环一样快；
2. **允许非局部返回**——lambda 里的裸 `return` 退出的是**外层函数**，不是 lambda 本身。

示例代码：

```kotlin
    println("== 12.8 inline 与非局部返回 ==")
    val found = listOf(1, 2, 3, 4).firstOrNull { it > 2 }
    println("firstOrNull { >2 } = $found            // forEach/firstOrNull 都是 inline")
    // inline lambda 里 return 直接退出外层函数（非局部返回）：
    fun firstNegative(xs: List<Int>): Int? {
        xs.forEach { if (it < 0) return it }        // return 出的是 firstNegative！
        return null
    }
    println("firstNegative = ${firstNegative(listOf(3, -7, 9))}")
    // 非 inline 的高阶函数里 lambda 不能非局部返回：
    // myFilter(listOf(1)) { return }  ← 编译错（myFilter 非 inline）
```

输出：

```text
== 12.8 inline 与非局部返回 ==
firstOrNull { >2 } = 3            // forEach/firstOrNull 都是 inline
firstNegative = -7
```

`firstNegative` 里的 `return it` 不是"从 forEach 的 lambda 出来继续循环"，而是**直接从 firstNegative 返回**——命中 `-7` 时整个函数就结束了；遍历完都没负数才走到 `return null`。这种"在遍历中提前终止整个外层函数"的写法，只有 forEach 是 inline 才合法。测试里同时断言了命中和未命中两种情况：

```kotlin
    assertEquals(-7, firstNegative(listOf(3, -7, 9)))
    assertNull(firstNegative(listOf(1, 2)))
```

源码最后两行注释是反面教材：`myFilter` 没标 `inline`，往它的 lambda 里写裸 `return` 是**编译错**。想在非 inline lambda 里"退出本次 lambda"（或 inline lambda 里只想跳过当轮），用**带标签返回**：`return@forEach`（标签名默认是函数名）。

自己写高阶函数时的三个修饰词：

- `inline`：整体内联。收益是性能 + 允许非局部返回；它也是唯一能用 `reified` 类型参数的地方（第 11 章泛型讲过 reified）。
- `noinline`：标记某个函数参数"不要内联"——当这个 lambda 要被**存起来**或**传给别的非 inline 函数**时必须加，否则编译不过。
- `crossinline`：内联但**禁止非局部返回**——lambda 会在另一个执行上下文里跑（比如被包进 Runnable、丢给线程），此时非局部返回语义上说不通，编译器强制禁止。

## 12.9 自己写高阶函数

理解了函数类型，写一个 `filter` 同款函数就是顺手的事。再看一遍示例里的 `myFilter`：

```kotlin
/** 高阶函数自定义：像标准库 filter 一样工作 */
fun <T> myFilter(items: List<T>, pred: (T) -> Boolean): List<T> {
    val out = mutableListOf<T>()
    for (x in items) if (pred(x)) out.add(x)
    return out
}
```

泛型 `<T>` 让它对任何元素类型可用；参数 `pred: (T) -> Boolean` 是"判断一个 T 要不要留"的函数——函数参数放最后，调用方就能用尾随 lambda：

```kotlin
    println("== 12.9 自己写高阶函数 ==")
    println("myFilter(1..10, 偶数) = ${myFilter((1..10).toList()) { it % 2 == 0 }}")
    val names = listOf("ada", "bob", "carol")
    println("myFilter(名字长度>3) = ${myFilter(names) { it.length > 3 }}")
```

输出：

```text
== 12.9 自己写高阶函数 ==
myFilter(1..10, 偶数) = [2, 4, 6, 8, 10]
myFilter(名字长度>3) = [carol]
```

同一套循环框架，换了判断函数就换了行为——这正是 12.1 节说的"流程固定、步骤可变"。标准库的 `filter`/`map`/`any`/`all` 全是这个形状；自己写库或工具函数时，认出这个形状，就把可变的部分抽成函数参数。测试文件对 `myFilter` 做了三组断言，包括空结果的情形：

```kotlin
fun testMyFilter() {
    assertEquals(listOf(2, 4), myFilter((1..5).toList()) { it % 2 == 0 })
    assertEquals(emptyList(), myFilter(listOf(1)) { false })
    assertTrue(myFilter(listOf("ab", "abc")) { it.length == 3 } == listOf("abc"))
}
```

## 12.10 坑位清单

1. **裸 `return` 在 inline lambda 里穿透外层函数**——`forEach { return }` 退的是外层函数。只想退出当轮，写 `return@forEach`。
2. **`it` 嵌套立刻显式命名**——lambda 里再写 lambda 时 `it` 永远指最内层，两层 `it` 是读串 bug 的温床。
3. **`apply`/`run`/`with` 里 `this` 指接收者**，同名局部变量会被遮蔽；必要时写全 `this.x`，嵌套时改用 `let`/`also`（`it` 可以改名）。
4. **五件套返回值方向不同**——`apply`/`also` 返回对象，`let`/`run`/`with` 返回 lambda 结果。写 `val x = p.apply { ... }.let { ... }` 这种链时，心里要清楚每一环在传什么。
5. **函数类型可空要括号**：`(() -> Int)?` 是"可空函数"，`() -> Int?` 是"返回可空 Int"——一个括号两种语义。
6. **捕获 `var` 的 lambda 是共享可变状态**——传进异步/并发代码前，先想想值拷贝是不是更稳（15 章竞态细讲）。
7. **重载多的函数引用要帮编译器选**：`listOf(::minOf, ::maxOf)` 必须标注集合元素类型，否则编译器面对一堆重载无法决定。

## 本章验证

本章示例通过四层验证（与本教程所有章节一致）：`kotlinc -Werror` 零告警编译 → `kotlin.test` 断言全过（Tests.kt 共 7 组测试，覆盖函数类型、柯里化雏形、闭包、接收者 lambda、myFilter、非局部返回、五件套）→ 程序运行退出码 0 → stdout 与 `expected.txt` 逐字节一致。工具链：Kotlin 2.4.21（K2 编译器）+ JDK 21。

---

上一章：[11 ⭐泛型](11-generics.md) · 下一章：[13 ⭐扩展](13-extensions.md)
