# 17 · 工程化与 Gradle

> 对应示例：`examples/17_gradle/`——一个真实可构建的 Gradle **多模块**工程：`settings.gradle.kts` + 根 `build.gradle.kts` 统领全局，`lib/` 是纯函数库模块（含 JUnit5 测试），`app/` 是应用模块（含测试 + fat jar 打包任务）。
>
> 前 16 章我们一直用 `kotlinc` 直接编译单个文件——这对理解语言机制是最好的方式，但真实项目从来不是一堆散文件。本章看 Kotlin 项目在工业界是怎么组织起来的：目录约定、构建脚本、依赖管理、多模块拆分、测试编排、产物打包。版本基线：Kotlin **2.4.21**（K2 编译器）、JDK **21**、Gradle **9.7.1**（Kotlin DSL）。

## 17.1 为什么需要构建工具

`kotlinc Main.kt -include-runtime -d app.jar` 在单文件时很爽快，但一旦项目长大，手工编译会遇到一堵堵墙：

1. **依赖解析**。要用 OkHttp，得自己去 Maven Central 找 jar、下载、传给 `-classpath`；OkHttp 又依赖 Okio，Okio 又依赖……这条传递链手工维护是灾难。构建工具的核心职责之一就是**声明坐标、自动拉取整条传递依赖树**。
2. **增量编译**。改了一个文件，不该把 500 个文件全部重编。构建工具跟踪任务输入输出，只重跑受影响的部分。
3. **测试编排**。编译主代码、编译测试代码、跑测试、失败时给出报告——这是一套固定流程，应该一键完成。
4. **多模块**。大项目要拆成多个模块控制耦合（见 17.5），模块间有编译顺序依赖，手工排不现实。
5. **产物打包**。jar、fat jar、分发包、Docker 镜像……每种产物都是一段可复用的构建逻辑。

Kotlin 世界的答案是 **Gradle**。理由很实际：Kotlin DSL（`.gradle.kts`）让构建脚本本身就是类型安全的 Kotlin 代码——有自动补全、有编译期检查、能重构，Gradle 官方与 JetBrains 都把它作为一等公民对待；Android Studio 和 IntelliJ 新建 Kotlin 项目默认就是 Gradle。最终效果：`gradle build` 一条命令，编译、测试、打包全部完成。

## 17.2 工程结构：约定优于配置

示例工程的完整布局：

```
17_gradle/
├── settings.gradle.kts                 # 工程名 + 包含哪些模块 + 依赖仓库
├── build.gradle.kts                    # 根脚本：统一锁插件版本（apply false）
├── lib/
│   ├── build.gradle.kts                # lib 模块脚本
│   └── src/
│       ├── main/kotlin/lib/Greeting.kt     # 主代码
│       └── test/kotlin/lib/GreetingTest.kt # 测试代码
├── app/
│   ├── build.gradle.kts                # app 模块脚本（含 fat jar 任务）
│   └── src/
│       ├── main/kotlin/Main.kt
│       └── test/kotlin/AppTest.kt
└── expected.txt                        # 程序运行输出的快照
```

这里最重要的思想是 **约定优于配置（convention over configuration）**：你不需要告诉 Gradle"源码在哪"，因为 `kotlin("jvm")` 插件内置了约定——`src/main/kotlin` 和 `src/main/java` 自动成为主源集，`src/test/kotlin`、`src/test/java` 自动成为测试源集，`src/main/resources` 自动打进 jar。只要按约定摆文件，构建脚本就只剩"声明依赖"这一件事。反过来，如果你把 `Main.kt` 随手放在模块根目录，Gradle 根本看不到它——新手的"代码没编译进去"十有八九是目录没按约定摆。

注意 `lib/src/main/kotlin/lib/Greeting.kt` 里 `lib` 出现了两次：第一个 `lib/` 是 **Gradle 模块名**，第二个 `lib/` 是 **Kotlin 包名**（文件里 `package lib`）。这是两套正交的概念，只是本例恰好同名——包结构必须等于目录结构，这是 Kotlin/Java 的硬性约定。

## 17.3 settings.gradle.kts：工程的"户口本"

```kotlin
rootProject.name = "kt-gradle-demo"

// 依赖仓库集中声明（现代写法）：模块里不再写 repositories
dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}

include("lib", "app")
```

这个文件在构建的**初始化阶段**最先执行，回答三个全局问题：

- **工程叫什么**：`rootProject.name` 决定根工程名（也影响默认产物名）。
- **依赖从哪拉**：`dependencyResolutionManagement { repositories { mavenCentral() } }` 把仓库声明**集中**在 settings 里。这是 Gradle 7 之后的推荐写法——老教程里每个模块各写一遍 `repositories { mavenCentral() }`，模块一多就会漂移（有的写 `jcenter()`——那个仓库 2021 年已停止服务，老书上到处都是它）。集中声明后，模块脚本里再写 `repositories` 会直接报错，从机制上保证全工程只有一个依赖来源。
- **有哪些模块**：`include("lib", "app")` 把两个子目录注册为 Gradle 子工程。没写进 `include` 的目录，Gradle 视而不见。

## 17.4 根 build.gradle.kts：只锁版本，不应用

```kotlin
// 根构建脚本：只统一声明插件版本，不在这里 apply
plugins {
    kotlin("jvm") version "2.4.21" apply false
}
```

多模块工程的头号纪律是 **版本只写一处**。根脚本用 `version "2.4.21" apply false` 声明"本工程使用 Kotlin 插件 2.4.21，但根工程自己不应用它"；子模块再 `kotlin("jvm")` 时不带版本号，自动继承根处声明。这样全工程的 Kotlin 编译器版本永远一致——两个模块各写一遍版本号，升级时漏改一个，就会出现"同一工程两套编译器"的灵异问题。

`apply false` 是关键：没有它，根工程（一个没有任何源码的空壳）也会尝试应用 Kotlin 插件，白白拖慢配置阶段。这个"根锁版本、子模块应用"的模式是 Gradle 多模块的标准姿势，任何模块数量的工程都照搬即可。

## 17.5 lib 模块：库代码与它的构建脚本

先看 lib 提供的全部能力（`lib/src/main/kotlin/lib/Greeting.kt` 全文）：

```kotlin
package lib

/** 问好——lib 模块对外提供的纯函数。 */
fun greeting(name: String): String = "Hello, $name!"

/** 按出现次数统计词频，返回按次数降序、同次数按字典序的稳定结果。 */
fun wordFreq(text: String): List<Pair<String, Int>> =
    text.split(Regex("\\s+")).filter { it.isNotBlank() }
        .groupingBy { it.lowercase() }
        .eachCount()
        .entries
        .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key })
        .map { it.key to it.value }

object LibInfo {
    const val NAME: String = "kt-gradle-demo-lib"
    const val VERSION: String = "1.0.0"
}
```

三个成员各有看点：

- `greeting` 是最小纯函数，串插值输出 `Hello, 名字!`。
- `wordFreq` 是一条标准的集合流水线：先用 [Regex](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/-regex/index.html) 按空白切分并滤掉空串；[`groupingBy { it.lowercase() }`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/grouping-by.html) 把单词**按小写形式惰性分组**（注意大小写归一发生在分组键上，所以 `"Kotlin"` 和 `"kotlin"` 计入同一组）；[`.eachCount()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/each-count.html) 把每组折叠成计数，得到 `Map<String, Int>`；然后 [`sortedWith`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/sorted-with.html) 用 [compareByDescending](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/compare-by-descending.html) 配 [thenBy](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/then-by.html) 组成**两级比较器**——先按次数降序，同次数再按键字典序，保证输出稳定（快照比对能过的前提）；最后 `.map { it.key to it.value }` 把 `Map.Entry` 转成 `Pair` 列表。
- `object LibInfo` 演示 Kotlin 的单例声明，`const val` 是编译期常量（内联到使用处，不占字段）。

对应的构建脚本 `lib/build.gradle.kts` 全文：

```kotlin
plugins {
    kotlin("jvm")   // 版本继承根目录，多模块版本不漂移
}

kotlin {
    jvmToolchain(21)
}

// implementation：内部实现细节，不泄漏给下游（对照 api：会出现在下游的编译 classpath）
dependencies {
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}
```

逐段讲：

- `plugins { kotlin("jvm") }`：**不带版本号**，继承根脚本的 2.4.21（17.4 节的纪律在这里兑现）。
- `kotlin { jvmToolchain(21) }`：**Java 工具链**声明。它告诉 Gradle"用 JDK 21 编译并面向 21 的字节码"。工具链机制的价值在于**与构建机环境解耦**：哪怕 CI 机器默认装的是别的 JDK，Gradle 也会自动探测（必要时自动下载）一个 JDK 21 来编译。这比老教程里手工配 `sourceCompatibility`/`targetCompatibility` 可靠得多。
- `dependencies { testImplementation(kotlin("test")) }`：只声明测试依赖。[`kotlin("test")`](https://kotlinlang.org/api/core/kotlin-test/) 是个"智能"坐标——它本身不写死框架，你后面配了 `useJUnitPlatform()`，它就自动解析成 kotlin-test-junit5；配 TestNG 就解析成对应适配器。lib 模块不依赖任何外部库，所以主代码一个 `implementation` 都不需要。
- `tasks.test { useJUnitPlatform() }`：把内置的 `test` 任务切到 **JUnit 5 平台**。Gradle 历史上默认跑 JUnit 4，忘了这行是最常见的"测试明明写了却一个都没跑"的原因——JUnit5 的 `@Test`（`org.junit.jupiter.api.Test`）在 JUnit4 运行器下会被静默跳过。

## 17.6 app 模块：组装 lib 能力

`app/src/main/kotlin/Main.kt` 全文：

```kotlin
import lib.LibInfo
import lib.greeting
import lib.wordFreq

/** app 的演示入口：组合 lib 提供的能力。 */
fun renderReport(names: List<String>, text: String): String = buildString {
    appendLine("== ${LibInfo.NAME} v${LibInfo.VERSION} ==")
    for (n in names) appendLine(greeting(n))
    appendLine("词频: " + wordFreq(text).joinToString(", ") { "${it.first}x${it.second}" })
    appendLine("来自 ${names.size} 位调用者")
}

fun main() {
    print(renderReport(listOf("Gradle", "Kotlin"), "kotlin gradle kotlin build gradle kotlin"))
}
```

`renderReport` 故意做成**返回字符串而不是直接打印**——这是可测试性的关键设计：纯函数好断言，`main` 只负责把结果 `print` 出去（16 章之前我们一直这么组织代码，到了 Gradle 工程里这个习惯直接变现为单测）。实现上用了 [buildString](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/build-string.html)：lambda 里 `this` 是 `StringBuilder`，[appendLine](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/append-line.html) 追加一行并换行。词频行用 [joinToString](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/join-to-string.html) 把 `Pair` 列表拼成 `"kotlinx3, gradlex2, buildx1"` 这样的串——注意格式串 `"${it.first}x${it.second}"`，所以是 `词x次数`（`kotlinx3` 读作"kotlin 出现 3 次"）。

app 的构建脚本（`app/build.gradle.kts` 全文）：

```kotlin
plugins {
    kotlin("jvm")
    application   // 提供 run 任务与可执行 jar 的 Main-Class 清单
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    implementation(project(":lib"))          // 多模块依赖：app 用 lib
    testImplementation(kotlin("test"))
}

application {
    mainClass.set("MainKt")
}

tasks.test {
    useJUnitPlatform()
}

// fat jar：把 runtimeClasspath 全部解包进一个可 `java -jar` 直跑的包
val appAllJar = tasks.register<Jar>("appAllJar") {
    archiveBaseName.set("app")
    archiveClassifier.set("all")
    manifest { attributes["Main-Class"] = application.mainClass.get() }
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from(sourceSets.main.get().output)
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) }) {
        exclude("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA")
    }
}

tasks.named("build") { dependsOn(appAllJar) }
```

上半部分与 lib 同构，增量知识集中在四处：

1. **`application` 插件**：提供 `run` 任务（`gradle run` 直接跑 main），并要求你在 `application { mainClass.set(...) }` 里指明入口类。这里写的是 `"MainKt"`——`Main.kt` 顶层的 `main` 函数被编译成名为 `MainKt` 的类的静态方法（12 章讲过的"文件 facade 类"规则），不是 `Main`。
2. **`implementation(project(":lib"))`**：模块间依赖的标准声明。`project(":lib")` 引用 settings 里 `include` 的那个模块。用 `implementation` 而不是 `api`：app 是终端模块，不存在"下游"，选什么都无所谓；但在库模块里这个区别生死攸关——`implementation` 声明的依赖**不会**出现在下游的编译 classpath（库内部用什么 HTTP 客户端是它自己的事），`api` 声明的依赖会（下游代码可以直接 `import` 它）。库作者滥用 `api` 会把整个依赖树漏给所有用户，版本冲突时苦不堪言；反过来该用 `api` 时用了 `implementation`，下游会"找不到类"。**默认 `implementation`，确实是你公开 API 的一部分才升 `api`。**
3. **`tasks.register<Jar>(...)`**：注册一个自定义任务（17.9 节详解 fat jar 逻辑）。用 `register` 而不是 `create` 是**配置避免（configuration avoidance）**的现代写法——任务只在真正需要执行时才实例化，配置阶段更快。
4. **`tasks.named("build") { dependsOn(appAllJar) }`**：把 fat jar 挂到标准 `build` 任务后面，保证 `gradle build` 一条命令连 fat jar 一起产出。

app 的测试（`app/src/test/kotlin/AppTest.kt` 全文）：

```kotlin
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AppTest {
    @Test
    fun reportContainsGreetings() {
        val r = renderReport(listOf("A", "B"), "a a b")
        assertTrue(r.contains("Hello, A!"))
        assertTrue(r.contains("Hello, B!"))
    }

    @Test
    fun reportEndsWithCallerCount() {
        val r = renderReport(listOf("A", "B", "C"), "x")
        assertTrue(r.trimEnd().endsWith("来自 3 位调用者"))
        assertEquals(3, r.lineSequence().count { it.startsWith("Hello,") })
    }
}
```

测试直接调用主源集的顶层函数 `renderReport`（同一模块内，`main` 旁边的函数天然可被测试 import），用 [assertTrue](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-true.html) 和 [assertEquals](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-equals.html) 断言内容。第二个测试用 [lineSequence](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/line-sequence.html) 把报告按行拆成序列，数出问候行的行数——`renderReport` 返回纯字符串的设计让这些断言写起来毫无障碍。

lib 的测试（`lib/src/test/kotlin/lib/GreetingTest.kt` 全文）同构：

```kotlin
package lib

import kotlin.test.Test
import kotlin.test.assertEquals

class GreetingTest {
    @Test
    fun greetingInsertsName() {
        assertEquals("Hello, Kotlin!", greeting("Kotlin"))
    }

    @Test
    fun wordFreqCountsAndSorts() {
        assertEquals(
            listOf("a" to 2, "b" to 1),
            wordFreq("a b a"),
        )
    }
}
```

`wordFreqCountsAndSorts` 验证了 17.5 节说的排序约定：`"a b a"` 里 a 出现 2 次、b 出现 1 次，期望 `[("a", 2), ("b", 1)]`——先按次数降序，同次数按字典序，结果是确定性的，这正是快照比对和单测都能稳定通过的前提。

## 17.7 运行输出：快照说了什么

`gradle build` 之后用 fat jar 运行（见 17.9），程序输出与 `expected.txt` 逐字节一致：

```
== kt-gradle-demo-lib v1.0.0 ==
Hello, Gradle!
Hello, Kotlin!
词频: kotlinx3, gradlex2, buildx1
来自 2 位调用者
```

对照 `Main.kt` 的输入 `renderReport(listOf("Gradle", "Kotlin"), "kotlin gradle kotlin build gradle kotlin")` 逐行核对：

- 第 1 行来自 `appendLine("== ${LibInfo.NAME} v${LibInfo.VERSION} ==")`——lib 的 `const val` 常量被 app 跨模块使用。
- 第 2–3 行是循环 `for (n in names) appendLine(greeting(n))`，两个名字各产一行。
- 第 4 行：文本里 kotlin 出现 3 次、gradle 2 次、build 1 次，`wordFreq` 按次数降序输出，再被 `"${it.first}x${it.second}"` 格式化成 `kotlinx3, gradlex2, buildx1`。
- 第 5 行：`names.size` 是 2。

模块拆分的意义在这份输出里清晰可见：**词频算法住在 lib，报告组装住在 app**，lib 不知道自己会被谁用、app 不知道词频怎么算——两边各自有测试守着。

## 17.8 日常命令

```powershell
gradle build                 # 编译 + 测试 + 打包（最常用）
gradle test                  # 只跑测试
gradle run                   # application 插件：跑 mainClass
gradle clean                 # 清产物
gradle :app:dependencies     # 看依赖树（排查冲突神器）
gradle --no-daemon build     # CI 环境禁守护进程
```

**Gradle Daemon** 是常驻后台的编译进程：第一次构建要启动 JVM、加载插件、解析配置，第二次起 Daemon 把这些全留在内存里，增量构建常常秒级完成。代价是占内存——机器卡顿时 `gradle --stop` 清掉。CI 环境用 `--no-daemon`：一次性任务不需要常驻进程，还能避免并行构建互相踩内存。首次构建还要联网从 Maven Central 拉插件和依赖（本教程 17 章第一次 build 约 4 分钟），之后有本地缓存就快了。

依赖冲突时的排查姿势：同一库被两条路径拉出两个版本，Gradle 默认取高版本，偶尔不是你要的——`gradle :app:dependencies` 打印依赖树，找到是谁引入的，再用 `constraints { implementation("组:名") { version { strictly("...") } } }` 钉死。

## 17.9 fat jar：可 `java -jar` 直跑的产物

普通 `jar` 任务打出来的包**只含本模块的 class**——`java -jar app.jar` 一跑就 `NoClassDefFoundError`，因为 lib 的类、stdlib 都不在里面。分发插件（`distributions`）生成带启动脚本的目录，能用但不够"一个文件走天下"。**fat jar（uber jar）** 的思路是把整条运行时 classpath 全部解包进同一个 jar。示例里的任务（17.6 节已引用全文）逐行拆解：

```kotlin
val appAllJar = tasks.register<Jar>("appAllJar") {
    archiveBaseName.set("app")
    archiveClassifier.set("all")
    manifest { attributes["Main-Class"] = application.mainClass.get() }
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from(sourceSets.main.get().output)
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) }) {
        exclude("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA")
    }
}
```

- `archiveBaseName` + `archiveClassifier`：产物名拼成 `app-all.jar`（baseName-classifier 是 jar 命名约定）。
- `manifest { attributes["Main-Class"] = ... }`：写清单文件，`java -jar` 靠它找入口。这里复用 `application.mainClass`，入口名只写一处。
- `from(sourceSets.main.get().output)`：打进本模块的编译输出。
- `from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) })`：核心一步——遍历运行时 classpath，目录直接加，**jar 文件用 `zipTree` 当场解包**再加（这就是"fat"的含义：依赖的 class 被拆出来平铺进同一个包）。
- `exclude("META-INF/*.SF", ...)`：**签名文件三件套必须剔除**。依赖 jar 若是签名过的，解包重混后签名失效，JVM 校验签名文件会抛 `Invalid signature file digest`——fat jar 跑不起来十有八九是这个原因。剔除签名文件是最省事的解法是业界惯例。
- `duplicatesStrategy = DuplicatesStrategy.EXCLUDE`：多个依赖带同名资源（如各自的 `META-INF/` 元数据）时，取第一个、跳过后续，避免打包冲突报错。

## 17.10 本教程的验证链（17 章特例）

其他章节的验证是四层：kotlinc `-Werror` 零告警 → kotlin.test → 运行 exit 0 → expected.txt 快照比对。17 章换成 Gradle 后骨架不变，工具升级：

```powershell
pwsh -File build.ps1 -Example 17_gradle
# 内部执行：gradle --no-daemon clean build（编译 + JUnit5 测试，含 lib 与 app 两个模块）
#           → java -jar app/build/libs/app-all.jar（运行，输出与 expected.txt 快照比对）
```

"编译、测试、运行、快照"四件事一件不少——构建工具变了，工程纪律不变。这也演示了 fat jar 任务挂在 `build` 后面的价值：验证脚本不用记任何额外任务名。

## 17.11 与 Maven 对照（给有 Java 背景的读者）

| | Gradle (Kotlin DSL) | Maven |
|---|---|---|
| 脚本 | build.gradle.kts（类型安全代码） | pom.xml（XML 声明） |
| 多模块 | `include` + `project(":x")` | parent + `<modules>` |
| 自定义任务 | 任务即 Kotlin 代码，任意逻辑 | 写插件或堆 profile |
| 增量/缓存 | 增量编译 + 构建缓存，标配 | 有限 |
| Kotlin 官方立场 | **首选**，DSL 一等公民 | 支持，但属于二等公民 |

Android、IntelliJ、Spring Initializr 生成的 Kotlin 项目默认全部 Gradle。老书上的 Gradle 章节多半还是 Groovy DSL（`build.gradle`，字符串拼接、动态类型）——语法上把单引号换双引号、`apply plugin:` 换 `plugins {}` 只是表面，真正的升级是 Kotlin DSL 的**类型安全**：写错属性名编译期就报错，而不是构建跑到一半才炸。

## 17.12 坑位清单

1. **版本只写一处**（根 `plugins` 块或 version catalog）。两个模块各写一遍 `version "2.4.21"`，升级时必漂移。
2. `implementation` vs `api` 用错的表现：下游突然"找不到类"（该 `api` 用了 `implementation`），或依赖泄漏引发版本冲突（滥用 `api`）。库项目默认 `implementation`。
3. **JDK 工具链 ≠ 运行 Gradle 自己的 JDK**。`jvmToolchain(21)` 指编译目标；而 Gradle 9.x 自身需要 JDK 17+ 才能启动——本机 `JAVA_HOME` 若指向 JDK 8，Gradle 进程都起不来，错误信息和"找不到 21 工具链"完全是两回事。
4. fat jar 的**签名文件必须剔**（`.SF`/`.DSA`/`.RSA` 三连），否则运行期 `Invalid signature file digest`。
5. 依赖冲突：先 `gradle :app:dependencies` 看树，再 `constraints`/`strictly` 钉版本，别盲目排除。
6. Daemon 吃内存——机器卡时 `gradle --stop`。
7. 首次构建必须联网（拉插件与依赖）；离线环境要提前预热缓存或搭内网镜像。
8. `mainClass` 写类名不是文件名：`Main.kt` 的顶层 main 编译后叫 `MainKt`（除非用 `@file:JvmName` 改名，见 18 章）。

---

上一章：[16 错误处理](16-errors.md) · 下一章：[18 ⭐Java 互操作](18-javainterop.md)
