# 02 · 第一个程序

> 对应示例：`examples/02_hello/`（`src/Main.kt` 演示输出、`test/Tests.kt` 单元测试、`expected.txt` 黄金快照）
>
> 本章目标不是"打印一行字"，而是把**从源码到运行**的全链路走通一遍：
> 编译器把 `.kt` 变成什么、`java` 命令凭什么能找到入口、测试怎么写、输出怎么钉死。
> 顺带拿下三个天天要用的语法常量：`fun main()`、字符串模板、单表达式函数。
> 这一章走通了，后面 30 章只是在这个骨架上换血肉。

## 2.1 Hello, World：消失的仪式代码

先看 Java 的最小程序，感受它要求你背下来的"仪式"：

```java
public class Hello {                       // 类名必须和文件名一致
    public static void main(String[] args) {  // 五件套一个不能少
        System.out.println("Hello, Java!");
    }
}
```

一个打印动作，被迫先理解 class、`public static`、数组参数、`System.out` 四个尚未学习的概念。
C++ 稍好（`int main() { std::cout << ...; }`），但仍要交代返回值和链接标准库；Go 要求 `package main` + `func main()`；Rust 要求 `fn main()`。
Kotlin 的判断是：**入口就是入口，不该裹在类里**——函数可以脱离类直接存在于文件顶层：

```kotlin
fun main() {
    println("== 2.2 第一个程序 ==")
    println("Hello, Kotlin!")
    ...
}
```

（以上及以下所有 Kotlin 代码块均逐字摘自 `examples/02_hello/src/Main.kt`，仅省略与当前小节无关的行，用 `...` 标出。）

没有类、没有 `static`、没有分号、不需要参数时连 `args` 都可以不声明。
[`println`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/println.html) 是 kotlin.io 包的顶层函数，等价于 Java 的 `System.out.println`——打印一行并按平台换行（Windows 追加 `\r\n`，macOS/Linux 追加 `\n`）。

**"没有类"只是源码层面的观感，JVM 上类仍然存在。**
Kotlin 文件里的顶层函数会被编译进一个合成类，类名规则是「文件名去扩展名 + `Kt`」：`Main.kt` → `MainKt`，`main` 成为它的 `public static` 方法。
所以 JVM 的入口契约一个字符都没被破坏，`java MainKt` 就能启动——这一点在 2.2 节手工编译时会立刻用到。
想改这个合成类的名字，用 `@file:JvmName("...")`，那是 18 章 Java 互操作的内容。

与 Go 的 `package main` 强制隔离、Rust 的 `fn main()` 必须在 crate 根部相比，Kotlin 的约定更宽松：**任何文件的顶层 `main` 都是合法入口**。
本教程利用这一点，让每个示例同时拥有两个入口——`MainKt`（演示）和 `TestsKt`（测试），2.7 节会看到。

## 2.2 用 kotlinc 手工编译一次：理解 Gradle 之前先懂底层

17 章之前我们不碰 Gradle，全程用编译器直驱。先把底层两个事实钉牢：

**事实一：两种产物形态。**

```bash
# 形态 A：-include-runtime，把 kotlin-stdlib 打进 jar，产物可独立运行
kotlinc-jvm Main.kt -include-runtime -d hello.jar
java -jar hello.jar

# 形态 B：只产 .class，运行时用 -cp 挂 kotlin-stdlib.jar（脚本用的就是这种，快）
kotlinc-jvm -Werror -d out Main.kt
java -cp "out:/opt/local/share/java/kotlin/lib/kotlin-stdlib.jar" MainKt    # macOS/Linux，分隔符 ':'
java -cp "out;G:\scoop\apps\kotlin\current\lib\kotlin-stdlib.jar" MainKt    # Windows，分隔符 ';'
```

形态 A 适合分发给别人双击/直跑；形态 B 适合开发期反复编译——少一次打 jar，快一个数量级。
注意运行命令里的类名是 **`MainKt`** 而不是 `Main` 或 `main`：这就是 2.1 节说的合成类名，写错了 JVM 只回你一句 `找不到或无法加载主类`。

**事实二：`-Werror` 是教程的硬门槛。**

它把编译器的一切告警升格为错误。入口脚本 `run-all.sh` / `build.ps1` 的 L1 层比 `-Werror` 更苛刻：除了退出码为 0，还要求**编译日志完全为空**——编译器一句话都不许说。
为什么对自己这么狠？因为告警是技术债的最早形态（废弃 API、未使用变量、类型不确定），教程示例不允许带着债出场。

**中文环境的两个编码开关。** 脚本运行 JVM 时统一加了：

```
-Dfile.encoding=UTF-8 -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8
```

`-Dstdout.encoding` 是 JDK 19+ 才有的开关，专治 Windows 控制台输出中文乱码；macOS/Linux 上 JDK 18+ 默认 UTF-8，加上无害。
这是教程把底线钉在 JDK 21 的又一个实际理由（01 章还讲过 konanc 在 JDK ≥ 24 崩溃的上限理由）。

手工敲一遍上述命令，看到 `Hello, Kotlin!` 打出来，你就已经掌握了后面所有示例的编译模型——脚本只是把同样的事做得更严。

## 2.3 字符串模板：`$` 的两种形态

字符串拼接是所有语言里出现频率最高的操作之一，也最容易写得丑。
Java 长期靠 `+` 拼接和 `String.format("%s + %s = %d", a, b, a+b)`，前者碎片化后者参数与占位符远距离对应；
Go 有 `fmt.Sprintf`，Rust 有 `format!` 宏——都是"模板在左、数据在右"的两段式。
Kotlin 的选择是把插值内建进字符串字面量，数据和模板写在一起：

```kotlin
val a = 1
val b = 2
println("$a + $b = ${a + b}")          // $变量 与 ${表达式}
val lang = "Kotlin"
val ver = "2.4.21"
println("你好, $lang $ver")
println("花括号里还能调方法: ${lang.uppercase()}")
```

（`ver` 是示例源码里硬编码的演示字符串，与本教程工具链版本一致。想知道"运行时真实的编译器版本"，标准库另有 [KotlinVersion.CURRENT](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-kotlin-version/-current.html)——25 章多平台探针用的就是它；它不适合进快照，因为换个工具链就会变，本教程的取舍是**教学内容写死、真实版本用 API 取**。）

两种形态的分工：

- **`$变量名`**：最简形式，紧跟标识符。编译器遇到 `$` 后会尽量多吃合法标识符字符——所以 `"$name_1"` 取的是变量 `name_1`，不是 `name` 加字面量 `_1`；想切断就用花括号形态。
- **`${任意表达式}`**：花括号内是完整 Kotlin 表达式，可以是运算（`a + b`）、函数调用、甚至 `if`——因为 Kotlin 里 `if` 是表达式（03 章细讲）。

第三行演示了花括号里调方法：[`uppercase()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/uppercase.html) 按 Unicode 规则转大写、与Locale 无关（Java 的 `toUpperCase()` 默认跟随系统 Locale，在土耳其语环境里会把 `i` 变成 `İ`，是经典环境相关 bug；Kotlin 这个设计直接铲掉了它）。

这段代码在 expected.txt 里的真实输出：

```
== 2.3 字符串模板 ==
1 + 2 = 3
你好, Kotlin 2.4.21
花括号里还能调方法: KOTLIN
```

`$a + $b = ${a + b}` 这一行值得盯一眼：模板只负责**排版**，`${}` 里发生的计算在运行期照常求值——`1 + 2 = 3` 里的 `3` 不是写死的。
这和 Rust 1.58+ 的 `println!("{a} + {b} = {}", a + b)` 神似，但 Kotlin 从 1.0 就是这个形态，且花括号内允许任意表达式，不只是标识符。

**何时不用模板**：要重复拼接构造长字符串时，模板依然每次产生新对象，应该用 `buildString`（2.5 节登场）；要做 i18n 时，模板把词序写死在源码里，得退回 `MessageFormat` 类资源文件——日常代码里模板够用且应是默认选择。

## 2.4 函数的两种身体

Kotlin 函数有两种写法，语义完全等价，取舍标准是**函数体有多长**：

```kotlin
/** 最普通的函数：块体 + 显式返回类型 */
fun greet(name: String): String {
    return "你好, $name!"
}

/** 单表达式函数：等号即函数体，返回类型可推断（公共 API 建议显式写） */
fun repeatGreet(word: String, times: Int): String = word.repeat(times)
```

`greet` 是块体：花括号包裹，可以有多条语句，靠 `return` 交出结果，返回类型 `: String` 写不写都行（写了是文档）。

`repeatGreet` 是单表达式函数：去掉花括号和 `return`，用 `=` 直连一个表达式。
它体内调用的 [`repeat(times)`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/repeat.html) 是 CharSequence 的扩展函数——返回把自身重复 n 次的新字符串，`"哈".repeat(3)` 得 `"哈哈哈"`，`n = 0` 得空串，`n < 0` 抛 `IllegalArgumentException`（2.7 节的测试会验证 0 这个边界）。

两个注意点：

1. **返回类型推断**：单表达式函数的返回类型编译器推得出来，可以省。但这个示例坚持写了 `: String`——公共 API 的返回类型属于契约的一部分，显式写出后，函数体内部改动就不会悄悄改变对外签名。这是风格，不是强制。
2. **`return` 的归属**：块体里 `return` 必须有（除非返回 `Unit`）；单表达式体里写 `return` 反而是语法错误。混用两种形态是新手高频编译错误。

Java 没有等价物（最接近的是 lambda `->` 和方法引用）；C++11 的尾随返回类型、Rust 的"末尾表达式即返回值"（不写 `return` 不加分号）在精神上相通——Kotlin 把"函数 = 表达式"这个函数式直觉直接缝进了语法。
对照输出（expected.txt）：

```
== 2.4 函数初体验 ==
greet("世界") = 你好, 世界!
repeatGreet("哈", 3) = 哈哈哈
```

## 2.5 命令行参数，以及"让 main 薄如纸"的结构

需要命令行参数时，`main` 声明一个 `args` 参数：

```kotlin
fun main(args: Array<String>) { ... }   // 不需要参数时整个参数列表都可以省
```

[`arrayOf("add", "42")`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/array-of.html) 这类工厂函数造出 `Array<String>`；数组用 `args.size` 取长度（是属性不是 `length()` 方法）、用 `args[i]` 下标访问。

但示例的重点不在参数本身，而在**代码结构**。`main` 里没有参数处理逻辑，只有一行调用：

```kotlin
    println("== 2.5 命令行参数（用固定参数演示）==")
    print(renderArgs(arrayOf("add", "42")))
```

逻辑全部收进一个纯函数：

```kotlin
/** 演示 main 如何接收命令行参数：逻辑放进纯函数，测试才好写 */
fun renderArgs(args: Array<String>): String = buildString {
    appendLine("参数个数: ${args.size}")
    for ((i, a) in args.withIndex()) appendLine("参数[$i]: $a")
}
```

逐段拆：

- [`buildString { ... }`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/build-string.html)：标准库给的字符串构建入口。花括号是一个"接收者 lambda"——块内的 `this` 是一个 `StringBuilder`，块里直接调它的方法，最后整个构建结果作为返回值。它取代的是 Java 里 `StringBuilder sb = new ...; sb.append(...); sb.toString()` 的三段式仪式。lambda 与接收者的完整语法在 12 章展开，这里先会认。
- [`appendLine(...)`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/append-line.html)：追加内容再追加换行。**它追加的永远是 `\n`**，不是 Windows 的 `\r\n`——这个与 `println` 平台相关的分歧点，会在 2.7 节的测试里成为必须知道的事实。
- [`args.withIndex()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/with-index.html)：把数组包成"带下标的可迭代序列"，产出 `(index, value)` 对；`for ((i, a) in ...)` 的圆括号写法叫**解构声明**，一次循环同时拿到下标和元素。Java 里同样的需求要 `for (int i = 0; i < args.length; i++)` 手工维护下标，Go 的 `for i, a := range args` 与之最近。
- 外层用 [`print`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/print.html)（不追加换行）而不是 `println`：因为 `buildString` 的结果**末尾已经带 `\n`**（最后一次 `appendLine` 留下的），再用 `println` 会多出一个空行，快照比对就挂了。输出函数的选择取决于内容里有没有自带换行——这是本节藏着的第二个知识点。

为什么坚持"main 薄如纸"？因为 `main` 是程序里**唯一没法被测试直接调用的函数**（它的参数来自进程命令行）。逻辑沉进 `renderArgs` 这种"进什么出什么"的纯函数后，2.7 节的测试才能随手喂 `arrayOf("add", "42")` 进去、比对字符串出来。这个"入口组装 + 纯函数内核"的分层会贯穿全书每一个示例。

对照输出（expected.txt 末三行，`print` 所以最后一行末尾的 `\n` 来自内容本身）：

```
== 2.5 命令行参数（用固定参数演示）==
参数个数: 2
参数[0]: add
参数[1]: 42
```

## 2.6 三种"立即跑"的形态

手写 `.kt` + kotlinc 是正道，但日常还有三种更轻的玩法，各有适用面：

```bash
# 1. 脚本模式：.kts 文件，顶层直接写语句，不需要 main 包装
echo 'println("脚本里直接写语句")' > hello.kts
kotlin hello.kts

# 2. REPL：交互式逐行求值，试 API 最快
kotlinc-jvm        # 不带参数即进入，:quit 退出

# 3. kotlin 命令直跑 .kt：编译+运行一步完成（每次冷启动编译，比 kotlinc+java 慢）
kotlin hello.kt
```

`.kts` 脚本适合替代 bash 写一次性工具——有完整类型检查和 stdlib，比 shell 的暗坑体面得多；Gradle 的 `build.gradle.kts` 用的就是它。
REPL 适合回答"这个 API 边界行为是什么"（比如 `-3 % 2` 得几），三秒出答案，比写个 main 快。
真实工程仍归 Gradle 管（17 章），三种轻形态是探索和胶水，不是工程形态。

## 2.7 测试：kotlin.test + 手写 main 入口

`examples/02_hello/test/Tests.kt` 全文如下（逐字引用）：

```kotlin
// 02 的测试：kotlin.test 断言 + 极简 main 入口（无 JUnit runner）
// 真实工程里用 JUnit5 跑 @Test —— 见 17_gradle 与 docs/20-testing.md
import kotlin.test.assertEquals

fun testGreet() {
    assertEquals("你好, Kotlin!", greet("Kotlin"))
    assertEquals("你好, 世界!", greet("世界"))
}

fun testRepeatGreet() {
    assertEquals("哈哈哈", repeatGreet("哈", 3))
    assertEquals("", repeatGreet("哈", 0))
}

fun testRenderArgs() {
    val out = renderArgs(arrayOf("add", "42"))
    // 注意：Kotlin 的 appendLine 追加 '\n'，不是平台的 lineSeparator——测试期望也要用 '\n'
    assertEquals("参数个数: 2\n参数[0]: add\n参数[1]: 42\n", out)
    assertEquals(0, renderArgs(emptyArray()).lines().first().filter { it.isDigit() }.toInt())
}

fun main() {
    testGreet()
    testRepeatGreet()
    testRenderArgs()
    println("02_hello 全部测试通过")
}
```

**为什么是这个形态？** 没有 JUnit、没有 `@Test` 注解、没有 runner——一个普通 `main` 顺序调用测试函数，断言失败就抛异常中断，全部通过则打印最后一行。
原因很实际：示例用 kotlinc 直编，不想为每个示例拉一套 JUnit runner；而 kotlin-test.jar 随 Kotlin 发行版自带，挂上 classpath 就有 [`assertEquals`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin-test/kotlin.test/assert-equals.html) 可用——参数顺序是**期望在前、实际在后**（写反了报错信息会误导你），失败时抛出带比对详情的 `AssertionError`。
测试文件同样编译出顶层入口类：`Tests.kt` → `TestsKt`，脚本的 L2 层跑的就是它。JUnit5 的正统形态（`@Test`、参数化、生命周期）留到 17 章 Gradle 工程里讲。

三个测试函数各藏一个考点：

1. **`testGreet` / `testRepeatGreet`**：验证 2.4 节两个函数的基本行为，外加 `repeatGreet("哈", 0)` 这条边界——`repeat(0)` 返回空串，边界值测试是这套极简框架下最便宜的纪律。
2. **`testRenderArgs` 第一条断言**：期望值逐字符写死了 `"参数个数: 2\n参数[0]: add\n参数[1]: 42\n"`——**包括末尾的 `\n`**（`appendLine` 留下的），且全文用 `\n` 而不是平台换行符。这就是 2.5 节强调的事实：测试期望与 `appendLine` 的固定 `\n` 对齐后，同一份测试在 Windows 和 macOS 上行为一致；若错用 `System.lineSeparator()` 构造期望值，Windows 上永远红。
3. **`testRenderArgs` 第二条断言**：对空参数数组的链式处理，值得从左往右读一遍——[`emptyArray()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/empty-array.html) 造空数组喂进去，结果字符串用 [`.lines()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/lines.html) 按行切成 `List<String>`，[`.first()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/first.html) 取首行（即 `"参数个数: 0"`），`.filter { it.isDigit() }` 用 [`isDigit`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/is-digit.html) 只留下数字字符（得 `"0"`），最后 [`.toInt()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/to-int.html) 解析成整数与 `0` 比对。这条断言同时验证了"空数组不崩"和"个数渲染正确"，也是全书的第一次链式调用亮相——09 章集合操作会把这种风格推到主场。

## 2.8 示例与验证：把本章跑一遍

示例目录的构成（全书 22 个 kotlinc 示例统一布局）：

```
examples/02_hello/
├── src/Main.kt        # 演示：分节打印，对应 expected.txt
├── test/Tests.kt      # 测试：kotlin.test 断言 + 手写 main
└── expected.txt       # 黄金快照：MainKt 运行的标准输出
```

跑它（在仓库根目录）：

```bash
./run-all.sh 02_hello          # macOS / Linux
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_hello   # Windows
```

脚本对本章示例依次执行四层验证，输出形如：

```
[Example] 02_hello
  [L1] 编译通过（-Werror，日志为空）
  [L2] 测试通过
  [L3] 运行通过（exit 0 / stderr 空 / stdout 非空且无控制字符）
  [L4] 输出快照一致
```

四层各防一类事故：L1 防告警和编译错误；L2 防逻辑回归；L3 防"崩了/什么都没打/打了乱码控制符"；L4 防输出被无意改动——改输出必须走 `--update` 显式刷新快照并人工核对。
`expected.txt` 的完整内容（也是 `MainKt` 运行的逐字输出，供你手跑后自行比对）：

```
== 2.2 第一个程序 ==
Hello, Kotlin!
== 2.3 字符串模板 ==
1 + 2 = 3
你好, Kotlin 2.4.21
花括号里还能调方法: KOTLIN
== 2.4 函数初体验 ==
greet("世界") = 你好, 世界!
repeatGreet("哈", 3) = 哈哈哈
== 2.5 命令行参数（用固定参数演示）==
参数个数: 2
参数[0]: add
参数[1]: 42
```

## 2.9 坑位清单

1. **`MainKt` 不是 `Main`**：`java` 直跑时用「文件名 + `Kt`」的合成类名；写错只会看到 `找不到或无法加载主类`，JVM 不会提示你正确类名是什么。想自定义用 `@file:JvmName("...")`（18 章）。
2. **`println` 与 `appendLine` 换行不同**：前者跟随平台（Windows `\r\n`），后者永远 `\n`。凡是要和字符串字面量、快照文件比对的内容，统一用 `buildString` + `appendLine` 生产；脚本 L4 比对前也会先把 `\r` 剥掉，双保险。
3. **Windows 控制台中文乱码**：JVM 侧加 `-Dstdout.encoding=UTF-8`（JDK 19+），PowerShell 侧还要 `[Console]::OutputEncoding = [Text.Encoding]::UTF8`，缺一个都可能乱——脚本只负责 JVM 这一半。
4. **PATH 上的 java 不可信**：它可能指向老 JRE 或别的 JDK。脚本宁可按"JAVA_HOME → 平台已知位置 → PATH"的顺序探测并校验大版本号（必须 21），也不直接用 `java`；你手工实验时请显式写 `$JAVA_HOME/bin/java`。
5. **`-include-runtime` 不是默认**：漏了它直接 `java -jar`，启动即 `NoClassDefFoundError: kotlin/jvm/internal/Intrinsics`——因为 stdlib 不在 jar 里。教学环境统一走 `-cp` 挂 `kotlin-stdlib.jar` 的形态 B。
6. **单表达式函数里写 `return`**：`fun f() = return 1` 直接编译错误；两种函数身体的规则不通用，切换形态时记得把 `return` 和花括号一起换。
7. **模板里紧跟的标识符会被"吃掉"**：`"$lang版"` 里 `$lang` 后紧跟的是全角字符所以安全，但 `"$name_1"`、`"$xpx"` 会被解析成另一个变量名——边界含糊时一律写 `${}` 形态。
8. **`.kts` 脚本里顶层语句自上而下执行**：没有 main 包装也意味着没有"入口之外不执行"的保护，写工具脚本时注意把可复用逻辑抽成函数，别全摊在顶层。

---

上一章：[01 全景](01-overview.md) · 下一章：[03 变量类型控制流](03-basics.md)
