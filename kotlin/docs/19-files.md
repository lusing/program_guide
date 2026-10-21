# 19 · 文件与文本处理

> 对应示例：`examples/19_files/`——`src/FilesDemo.kt` 是全部可复用函数（File 扩展封装、useLines 流式计数、CSV 往返、目录树遍历、java.time 封装、snake_case 与日志解析正则、手写 JSON 编码器、kotlin.time 计时封装、UUID 生成、Base64 编码、进程执行扩展），`src/Main.kt` 逐节演示，`test/Tests.kt` 用临时目录做全量断言。
>
> Kotlin 没有造自己的 IO 体系——它直接复用 `java.io`/`java.nio`，再用**扩展函数**把 Java 时代的样板代码铺平成现代手感。本章沿示例的真实代码走一遍日常文本处理的完整工具箱，并把老书（Kotlin 1.x / Java 8 时代）里的写法全部升级到 JDK 21 + stdlib 扩展：时间处理用 java.time（永不回头碰 `Date`/`Calendar`），正则用三引号原始字符串写，临时目录用 `kotlin.io.path` 扩展建；最后三节补上标准库里三个"JVM 之外也要能用"的多平台 API——kotlin.time、kotlin.uuid、kotlin.io.encoding。

## 19.1 本章地图：Kotlin 没有自己的 IO 体系

先建立总图景：**Kotlin 不为 IO 另起炉灶**。`java.io.File`、`java.nio.file.Path`、`java.time` 全部原样可用，标准库做的是用**扩展函数**把 Java 时代的样板铺平成现代手感——`writeText`/`readLines`/`useLines`/`walkTopDown` 全是扩展。本章沿示例的真实代码走一遍日常文本处理的完整工具箱：

```text
19.2  写与读          File 扩展四件套 + 跨机器快照技巧
19.3  useLines        大文件恒定内存逐行流式
19.4  CSV 往返        读写 + 集合管道的最小实战
19.5  目录树 walk      Sequence 化的递归遍历
19.6  拷贝与删除      copyTo 的 overwrite 默认值
19.7  java.time       不可变时间 API（别再用 Date/Calendar）
19.8  Regex           三引号原始字符串 + 捕获组解构
19.9  JSON 编码器      when 表达式 + 递归的复习材料
19.10 进程执行        "cmd".execute() 扩展 + 双管道死锁防御
19.11 kotlin.time     Kotlin 自己的 Duration（多平台）
19.12 kotlin.uuid     随机 UUID（v4）
19.13 Base64          kotlin.io.encoding（二进制进文本协议）
19.14 测试            临时目录里的文件断言
19.15 编码与平台杂项  UTF-8、GBK、相对路径锚点
19.16 坑位清单
```

老书（Kotlin 1.x / Java 8 时代）里的 `Date`/`Calendar`、`FileUtils`、单线程正则套路，本章全部升级到 JDK 21 + stdlib 扩展的现代写法。

---

## 19.2 写与读：扩展函数铺平的样板

先看演示代码（`Main.kt` 开头一节）：

```kotlin
val demo = File("build/demo")     // 相对路径 → examples/19_files/build/demo（已 gitignore）

println("== 19.2 写与读 ==")
val hello = File(demo, "hello.txt")
hello.parentFile?.mkdirs()
hello.writeText("第一行：kotlin\n第二行：文件")
hello.appendText("\n第三行：追加")
println("readText():"); hello.readLines().forEach { println("  $it") }
println("exists=${hello.exists()}, 大小=${hello.length()}B, 绝对路径=${hello.absolutePath.replace('\\', '/').substringAfterLast("examples/")}")
```

对应输出：

```
== 19.2 写与读 ==
readText():
  第一行：kotlin
  第二行：文件
  第三行：追加
exists=true, 大小=56B, 绝对路径=19_files/build/demo/hello.txt
```

对照 Java 的写法——`Files.write(path, content.getBytes(StandardCharsets.UTF_8))`、读要开 `BufferedReader` 再 try-with-resources——Kotlin 把这一切收进了 [`File`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/io/File.html) 的扩展函数：

- [`writeText`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/write-text.html)：**写全文，默认 UTF-8**（编码参数可换，但 UTF-8 这个默认本身就修掉了 Java 时代"平台默认编码"的老坑）。
- [`appendText`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/append-text.html)：追加模式。输出里"第三行"紧接前文，因为第二次写入以 `\n` 开头。
- [`readLines`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/read-lines.html)：读成 `List<String>`（整文件进内存，大文件见 19.3）；全文字符串用 `readText`。
- `hello.parentFile?.mkdirs()`：`parentFile` 返回可空（根目录没有父），用 `?.` 顺手调 `mkdirs()`——建父目录不存在的整个链。
- 元信息：`exists()`、`length()`（字节数）、`absolutePath`。注意 **56B 的算术**：UTF-8 里中文 3 字节/字——`第一行：`（12B）+ `kotlin`（6B）+ `\n` + `第二行：文件`（18B）+ `\n` + `第三行：追加`（18B）= 56。测试里 `assertEquals(11, f.length())` 验的是同一规律（`一\n二\n三` = 3×3 + 2）。
- 路径打印处的 `replace('\\', '/')` 与 [substringAfterLast](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/substring-after-last.html)：`absolutePath` 在不同机器上不同（作者机器是 `/Volumes/.../examples/19_files/...`），快照不可能比对绝对路径——**先归一分隔符、再截取稳定尾部**，这是让 `expected.txt` 跨机器成立的通用技巧，19.5 的目录树还会用到。

小文件（配置、模板、CSV）用这组 API 就够；需要更细的节制时它们都有带 `charset` 参数的重载。

## 19.3 useLines：大文件的恒定内存处理

`readLines` 把整文件拉进内存——几个 G 的日志这么读就是 OOM。正确姿势是**逐行流式**（`FilesDemo.kt`）：

```kotlin
/** 逐行流式处理大文件：useLines 用完自动关流，常量内存 */
fun countWords(file: File): Int =
    file.useLines { lines -> lines.sumOf { it.split(Regex("\\s+")).count { w -> w.isNotEmpty() } } }
```

[useLines](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/use-lines.html) 做两件事：把文件变成 **`Sequence<String>`**（逐行惰性产出，任意时刻内存里只有一行），并在 lambda 返回后**自动关闭底层流**（它就是 `use {}` 模式在"行序列"上的特化，16 章讲过 `use` 的通用形态）。lambda 内是标准的序列流水线：[sumOf](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/sum-of.html) 累加每行的词数，`split(Regex("\\s+"))` 按空白切、滤掉空串。

演示与输出：

```kotlin
val words = File(demo, "words.txt")
words.writeText("kotlin is fun\nfiles are easy\nstreams save memory")
println("words.txt 词数 = ${countWords(words)}")
```

```
words.txt 词数 = 9
```

3 + 3 + 3 = 9。测试里还覆盖了边界：`testCountWords` 断言 `kotlin is\nfun yes` → 4、空文件 → 0（空 `Sequence` 的 `sumOf` 是 0）。**纪律：文件可能上 G 就选 `useLines`，确定很小才 `readLines`。**

## 19.4 CSV 往返：读写 + 集合管道的最小实战

CSV 是"读写 + 集合流水线"的最小实战（`FilesDemo.kt`）：

```kotlin
fun writeCsv(path: File, rows: List<List<String>>) {
    path.parentFile?.mkdirs()
    path.writeText(rows.joinToString("\n") { it.joinToString(",") })
}

fun readCsv(path: File): List<List<String>> =
    path.readLines().filter { it.isNotBlank() }.map { it.split(",") }
```

写：嵌套 [joinToString](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/join-to-string.html) 先把每行拼成逗号串、再把行拼成换行串，一次 `writeText` 落盘（整串一次写比循环 append 快得多）。读：`readLines` 滤空行再逐行 `split`。Main 里的往返输出：

```
== 19.4 CSV 往返（naive 版：不处理引号转义）==
name|age / 张三|30 / 李四|41
```

注释里"naive 版"是诚实的：这版**不处理引号转义**——字段里含逗号或换行就破了。生产用 OpenCSV 之类；这里要的是把读写套路跑通，测试 `testCsvRoundtrip` 守的也是"往返一致"而非 RFC 4180 全特性。

## 19.5 目录树遍历：walk 序列

```kotlin
/** walk：递归遍历目录树（深度优先），排序保证输出稳定 */
fun treeListing(root: File): List<String> =
    root.walkTopDown()
        .sortedBy { it.path }
        .map {
            // 跨平台：File.path 在 Windows 上是 'a\1.txt'、在 macOS/Linux 上是 'a/1.txt'，
            // 而 expected.txt 只有一份 → 统一归一成 '/'（Kotlin 里 '/' 两种平台都能当分隔符用）。
            val rel = it.relativeTo(root).path.replace(File.separatorChar, '/')
            val kind = if (it.isDirectory) "[D]" else "(${it.length()}B)"
            "$rel $kind"
        }
        .toList()
```

[walkTopDown](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/walk-top-down.html) 返回 **`Sequence<File>`**——惰性深度优先遍历，能接 `filter/map/take` 全家桶，大目录不会一次性爆内存（还有个 `walkBottomUp`，自底向上，删目录树时子先父后）。`sortedBy { it.path }` 不为别的：**文件系统枚举顺序不稳定**，快照比对必须先排序。

注释里那条跨平台纪律是本教程实测的坑：`File.path` 的分隔符随平台变（Windows `\`、macOS/Linux `/`），构造路径时写 `/` 两边都认，**但一旦把 `path` 打印出来进快照，就绑死在单平台了**。所以用 [relativeTo](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/relative-to.html) 取相对路径后统一 `replace(File.separatorChar, '/')`。

演示造树、列树：

```kotlin
val tree = File(demo, "tree").apply { deleteRecursively(); mkdirs() }
File(tree, "a/1.txt").apply { parentFile.mkdirs(); writeText("A1") }
File(tree, "a/b/2.txt").apply { parentFile.mkdirs(); writeText("B2-longer") }
File(tree, "3.txt").writeText("T3")
treeListing(tree).forEach { println("  $it") }
```

```
== 19.5 目录树 walk ==
   [D]
  3.txt (2B)
  a [D]
  a/1.txt (2B)
  a/b [D]
  a/b/2.txt (9B)
```

第一行是根目录自身：`relativeTo(root)` 得空串，`[D]` 标记目录；`B2-longer` 9 字节所以 `(9B)`。开头的 `apply { deleteRecursively(); mkdirs() }` 是**幂等重置**的惯用法——[deleteRecursively](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/delete-recursively.html) 删整棵树（危险操作，路径必须核死；且失败时静默返回 `false`，重要删除要检查返回值）。

## 19.6 拷贝与删除

```kotlin
val copied = File(tree, "3-copy.txt")
File(tree, "3.txt").copyTo(copied, overwrite = true)
println("复制后存在 ${copied.name}: ${copied.exists()}")
copied.delete()
println("删除后: ${copied.exists()}")
```

```
== 19.6 拷贝与删除 ==
复制后存在 3-copy.txt: true
删除后: false
```

[copyTo](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/copy-to.html) 默认**不覆盖**——目标已存在会抛 `FileAlreadyExistsException`，要覆盖显式传 `overwrite = true`。这个默认是保护性的：覆盖是破坏性操作，必须是你明说。

## 19.7 java.time：不可变、线程安全，别再用 Date/Calendar

`java.util.Date`/`Calendar` 是 Java 1.x 的遗产：可变（共享即地狱）、月份从 0 起、API 反直觉。**JDK 8 引入的 java.time 是唯一正确答案**——不可变、线程安全、语义清晰。Kotlin 直接复用它（18 章的互操作红利）。`FilesDemo.kt` 的三个封装：

```kotlin
fun formatDate(d: LocalDate): String = d.format(DateTimeFormatter.ofPattern("yyyy年MM月dd日"))

fun daysBetween(a: LocalDate, b: LocalDate): Int = Period.between(a, b).days

fun describeDuration(d: Duration): String {
    val h = d.toHours(); val m = d.toMinutes() % 60; val s = d.seconds % 60
    return "${h}时${m}分${s}秒"
}
```

先分清三个易混概念：

| 类型 | 语义 | 典型用途 |
|---|---|---|
| [Period](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/Period.html) | 人类时间差：**年/月/日三个分量** | 年龄、账期 |
| [Duration](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/Duration.html) | 机器时间差：秒/纳秒 | 计时、超时 |
| [Instant](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/Instant.html) | UTC 时间线上的一个点 | 时间戳 |

演示代码与输出：

```kotlin
val today = LocalDate.of(2026, 9, 18)
println("formatDate: ${formatDate(today)}")
println("today + 45 天 = ${today.plusDays(45)}")
val yearEnd = LocalDate.of(2026, 12, 31)
// 经典坑：Period.days 是"分量"（3 个月零 13 天 → days=13），不是总天数！
println("Period(today→年末).days = ${daysBetween(today, yearEnd)}（分量，不是 104！）")
println("ChronoUnit.DAYS 总天数 = ${java.time.temporal.ChronoUnit.DAYS.between(today, yearEnd)}")
val start = LocalDateTime.of(2026, 9, 18, 9, 0, 0)
println("时长 9354 秒 = ${describeDuration(Duration.ofSeconds(9354))}")
println("本月每天（前 5 个）: ${(1..5).map { today.withDayOfMonth(it) }.joinToString()}")
```

```
== 19.7 java.time（不可变、线程安全，别再用 Date/Calendar）==
formatDate: 2026年09月18日
today + 45 天 = 2026-11-02
Period(today→年末).days = 13（分量，不是 104！）
ChronoUnit.DAYS 总天数 = 104
时长 9354 秒 = 2时35分54秒
本月每天（前 5 个）: 2026-09-01, 2026-09-02, 2026-09-03, 2026-09-04, 2026-09-05
```

逐个看：

- [LocalDate](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/LocalDate.html) 是"日期无时间"；`format` 配 [DateTimeFormatter.ofPattern](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/format/DateTimeFormatter.html) 输出 `2026年09月18日`。
- `plusDays(45)` 返回**新对象**（不可变性：原值不变，9/18 + 45 天 = 11/2，跨年跨月自动处理）。
- **本章最大的坑**：`Period.between(today, yearEnd).days` 得 **13**——它是"3 个月零 13 天"的**日的分量**，不是总天数！要总天数用 [ChronoUnit.DAYS.between](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/temporal/ChronoUnit.html)（= 104）。测试 `testDates` 故意断言 `assertEquals(13, daysBetween(...))`，把这个"坑"固化成文档——读到 13 就不会误以为函数坏了。
- `Duration.ofSeconds(9354)`：`toHours()` 得 2，`toMinutes() % 60` 得 35（注意取余——`toMinutes()` 是总分钟 155），`seconds % 60` 得 54 → `2时35分54秒`。
- `withDayOfMonth(it)` 生成同月各日——不可变 API 的"修改"全部返回新实例，链式拼装安全。

## 19.8 Regex：三引号里少转义

Kotlin 正则是 [Regex](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/-regex/index.html) 类（包着 `java.util.regex`）。第一条经验：**用三引号原始字符串写正则**——`Regex("\\d+")` 里的 `\\d` 是 Java 遗产的双层转义，`Regex("""\d+""")` 里单反斜杠直达正则引擎，可读性差一倍。

示例的两个实战正则（`FilesDemo.kt`）：

```kotlin
/** 命名校名转 snake_case：连续大写一起处理（HTTPServer → http_server） */
fun toSnakeCase(s: String): String =
    s.replace(Regex("([a-z0-9])([A-Z])"), "$1_$2")
        .replace(Regex("([A-Z]+)([A-Z][a-z])"), "$1_$2")
        .lowercase()

data class LogLine(val ts: String, val level: String, val msg: String)

fun parseLog(line: String): LogLine? {
    // 坑：原始字符串里行尾 $ 会和收尾的 """ 组成 $模板——要么去掉行尾锚点，要么写 ${'$'}
    val m = Regex("""^(\d{2}:\d{2}:\d{2}) \[(\w+)] (.*)""").find(line) ?: return null
    val (ts, level, msg) = m.destructured
    return LogLine(ts, level, msg)
}
```

`toSnakeCase` 用两遍 [replace(Regex, …)](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/replace.html)：第一遍 `([a-z0-9])([A-Z])` 在"小写/数字 → 大写"的边界插 `_`（`myKotlin` → `my_Kotlin`）；第二遍 `([A-Z]+)([A-Z][a-z])` 处理**连续大写结尾接单词**的场景（`HTTPServer` → `HTTP_Server`）；最后 [lowercase](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/lowercase.html)。`$1`/`$2` 是反向引用捕获组。输出验证了两条路径：

```
toSnakeCase(HTTPServer) = http_server
toSnakeCase(myKotlinVar2) = my_kotlin_var2
```

（测试还补了 `getHTTPResponse` → `get_http_response`——连续大写在中间的情况，两遍替换缺一不可。）

`parseLog` 演示**解析**而非替换：[find](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/-regex/find.html) 返回可空的 `MatchResult`，`?:` 提前返回 null 处理不匹配；`m.destructured` 把**捕获组**按解构声明拆出来——`(\d{2}:\d{2}:\d{2})`、`(\w+)`、`(.*)` 三组依次赋给 `ts/level/msg`（[destructured](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/-match-result/destructured.html) 的 `component1..N` 对应第 1..N 个捕获组）。`\[` 转义左方括号、`]` 在字符类外不用转。输出：

```
  LogLine(ts=09:15:00, level=INFO, msg=服务启动)
  （不匹配）
  LogLine(ts=09:15:03, level=WARN, msg=磁盘 85%)
```

注释里那条**行尾 `$` 陷阱**是本教程实测翻车记录：`"""(.*)$"""` 里 `$"""` 会被 Kotlin 解析器看成字符串模板的开头（`$"`），直接语法错误。两个解法：去掉行尾锚点（`.*` 本来就贪婪到行尾，多数场景等价），或写 `${'$'}` 显式转义。示例选了前者。

## 19.9 手写极简 JSON 编码器

不许依赖库时，JSON **编码**（值 → 字符串）三十行搞定——它是 08 章递归 + when 表达式的绝佳复习材料（`FilesDemo.kt` 全文）：

```kotlin
fun jsonEscape(s: String): String = buildString {
    for (c in s) when (c) {
        '"' -> append("\\\"")
        '\\' -> append("\\\\")
        '\n' -> append("\\n")
        '\r' -> append("\\r")
        '\t' -> append("\\t")
        else -> if (c < ' ') append("\\u%04x".format(c.code)) else append(c)
    }
}

fun toJson(v: Any?): String = when (v) {
    null -> "null"
    is String -> "\"${jsonEscape(v)}\""
    is Boolean -> v.toString()
    is Int, is Long, is Double -> v.toString()
    is Map<*, *> -> v.entries.joinToString(", ", "{", "}") {
        "\"${jsonEscape(it.key.toString())}\": ${toJson(it.value)}"
    }
    is List<*> -> v.joinToString(", ", "[", "]") { toJson(it) }
    else -> "\"${jsonEscape(v.toString())}\""   // 兜底：当字符串
}
```

结构一目了然：`toJson` 用 when 按类型分派——`null`、字符串（加引号并转义）、布尔、数字、Map（递归编码每个 value）、List（递归编码每个元素），`else` 兜底当字符串。`jsonEscape` 用 [buildString](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/build-string.html) 逐字符处理：五个具名转义 + **控制字符统一 `\uXXXX`**（`c < ' '` 判出所有 0x00–0x1F，`"\\u%04x".format(c.code)` 格式化成四位十六进制）。

演示输入覆盖了几乎所有分支：

```kotlin
val task = mapOf(
    "id" to 1,
    "title" to "写 Kotlin 教程",
    "done" to false,
    "tags" to listOf("docs", "wip"),
    "note" to "带\"引号\"与\n换行",
    "due" to null,
)
println(toJson(task))
```

```
{"id": 1, "title": "写 Kotlin 教程", "done": false, "tags": ["docs", "wip"], "note": "带\"引号\"与\n换行", "due": null}
```

嵌套 List、null 值、字符串里的引号与换行转义（`\"`、`\n`）全在输出里可见。测试 `testJson` 的断言更细：`toJson("a\"b")` → `"a\"b"`、`toJson("line\nnext")` → `"line\nnext"`、中文与引号混合的 Map 也过了。编码器够用，**解析器**（字符串 → 值）需要递归下降，篇幅翻倍——24 章的实战项目会完整实现并配测试。

顺带一提：`buildString` 的惯用法在 19.4 的 `writeCsv` 和这里反复出现——**循环拼字符串永远用 StringBuilder 系**（`buildString` 只是它的接收者语法糖），`+` 累加是 O(n²) 的反模式。

## 19.10 进程执行：给 Kotlin 装上 Groovy 的 `"cmd".execute()`

老书（Groovy 背景）里有个讨喜的写法：`"ls -R".execute()`。用扩展函数三行搬到 Kotlin——但示例顺手修掉了书上版本的**死锁隐患**：

```kotlin
/** Groovy 风格进程扩展：redirectErrorStream 合流——双管道不排空时 waitFor 会死锁 */
fun String.execute(): Process =
    ProcessBuilder(*split(Regex("\\s+")).toTypedArray())
        .redirectErrorStream(true)
        .start()

fun Process.text(): String = inputStream.bufferedReader().readText()
```

`String.execute()`：[ProcessBuilder](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/ProcessBuilder.html) 按空白切分命令行（`*...toTypedArray()` 展开成 vararg），[`redirectErrorStream(true)`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/ProcessBuilder.html#redirectErrorStream(boolean)) 把 stderr 合并进 stdout，启动进程。`Process.text()` 把输出流读成字符串（`inputStream` 在 Process 上指"子进程的 stdout"）。

**为什么合流是生死攸关的**：子进程的 stdout、stderr 是两条独立管道，内核各给几 KB 缓冲。父进程若只读 stdout 而子进程往 stderr 狂写，缓冲一满**子进程阻塞在写、父进程阻塞在 `waitFor`**——经典双管道死锁。`java -version` 恰好是那个"往 stderr 输出版本信息"的反直觉命令（示例输出注释明说），不排空 stderr 必挂。合流后一条管道一个读者，结构上免疫。

调用顺序同样有讲究：

```kotlin
val proc = "java -version".execute()
val out = proc.text()          // 先读到 EOF
val rc = proc.waitFor()        // 再收退出码——顺序别反
println("\"java -version\".execute(): exit=$rc, 输出非空=${out.isNotBlank()}（版本细节随机器，不进快照）")
println("防御: redirectErrorStream(true) 合流——双管道不排空时缓冲写满会把 waitFor 挂死")
```

```
== 19.10 进程执行扩展 ==
"java -version".execute(): exit=0, 输出非空=true（版本细节随机器，不进快照）
防御: redirectErrorStream(true) 合流——双管道不排空时缓冲写满会把 waitFor 挂死
```

先 `text()` 读到 EOF（排空管道，子进程得以跑完），再 `waitFor()` 收退出码——反过来的话缓冲写满照样挂。版本字符串随机器而变，所以快照里只钉 `exit=0` 和"输出非空"两个稳定事实；测试 `testProcessExecute` 断言的也是这两条。这就是"快照友好设计"的意识：**易变信息不进快照，稳定事实必须进**。

## 19.11 kotlin.time：Kotlin 自己的 Duration 与计时

19.7 用的 `java.time.Duration` 是 JDK 专属——**Kotlin 多平台代码用不了它**（没有 JVM 的 Kotlin/JS、Kotlin/Native 平台上没有 java.time）。标准库的答案在 [kotlin.time](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.time/)：同名的 `Duration` 类（1.6 起稳定）+ `TimeSource` 打点 + `measureTime` 计时块。示例同时 import 了两个同名类，用**别名**区分（`src/Main.kt` 第 5-10 行）：

```kotlin
import java.time.Duration
import kotlin.time.Duration as KtDuration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlin.time.measureTime
```

`java.time.Duration`（JVM 的：`toHours()`/`toMinutes()`/`seconds`）与 `kotlin.time.Duration`（多平台的：`inWholeMinutes`/`toComponents`/`parseIsoString`）同名不同包——别名 import 之后，源码里 `Duration` 指前者、`KtDuration` 指后者，各归其位。

`90.seconds`、`900.milliseconds` 这类写法不是语法糖宏，而是 **`Duration.Companion` 上的扩展属性**——所以必须显式 `import kotlin.time.Duration.Companion.seconds`（扩展不 import 就没有，21.8 的原子类扩展还会再撞一次）。`FilesDemo.kt` 的两个封装：

```kotlin
/** kotlin.time.Duration 拆时/分/秒：toComponents 是成员函数，不需要 import */
fun describeKtDuration(d: KtDuration): String =
    d.toComponents { h, m, s, _ -> "${h}时${m}分${s}秒" }

/** 单调时钟打点：不受系统改表影响，测"耗时"用它；挂钟时间（日志时间戳）才用 System.currentTimeMillis */
fun timedSum(n: Int): Pair<Long, KtDuration> {
    val mark = TimeSource.Monotonic.markNow()
    var acc = 0L
    for (i in 1..n) acc += i
    return acc to mark.elapsedNow()
}
```

演示（`src/Main.kt` 第 92-105 行）与输出：

```kotlin
println("== 19.11 kotlin.time：Duration 与计时 ==")
val ttl = 90.seconds                                   // Int.seconds → kotlin.time.Duration
println("ttl = $ttl（inWholeMinutes=${ttl.inWholeMinutes}, 秒分量=${ttl.inWholeSeconds % 60}）")
println("ISO-8601 解析: ${KtDuration.parseIsoString("PT2H45M30S")}")
println("toComponents: ${describeKtDuration(9354.seconds)}")
println("比较/运算: 1.seconds > 900.milliseconds = ${1.seconds > 900.milliseconds}, 30.seconds + 45.seconds = ${30.seconds + 45.seconds}")
val mark = TimeSource.Monotonic.markNow()
Thread.sleep(5)
println("markNow/elapsedNow: 睡 5ms 后 >= 1ms = ${mark.elapsedNow() >= 1.milliseconds}")
var sum = 0L
val cost = measureTime { sum = (1..100_000).sumOf { it.toLong() } }
println("measureTime(10万求和) = $sum, 耗时非负 = ${cost >= 0.seconds}")
val (ts, tc) = timedSum(100_000)
println("timedSum(10万) = $ts, 同款耗时非负 = ${tc >= 0.seconds}")
```

```
== 19.11 kotlin.time：Duration 与计时 ==
ttl = 1m 30s（inWholeMinutes=1, 秒分量=30）
ISO-8601 解析: 2h 45m 30s
toComponents: 2时35分54秒
比较/运算: 1.seconds > 900.milliseconds = true, 30.seconds + 45.seconds = 1m 15s
markNow/elapsedNow: 睡 5ms 后 >= 1ms = true
measureTime(10万求和) = 5000050000, 耗时非负 = true
timedSum(10万) = 5000050000, 同款耗时非负 = true
```

逐个看：

- `ttl = 1m 30s`：`Duration.toString()` 输出 ISO-8601 风格的短格式（`1m 30s`），比 java.time 的 `PT1M30S` 好读。
- [toComponents](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.time/-duration/to-components.html) 把 Duration 拆成时/分/秒/纳秒四个分量交给 lambda——**成员函数**（不用 import，与 19.7 手写的 `toMinutes() % 60` 算术说再见）。注意 lambda 的第四参数是纳秒分量，示例用 `_` 丢弃。
- `parseIsoString("PT2H45M30S")` 在 **Companion** 上（`KtDuration.parseIsoString(...)`），与 `Duration.parse` 家族一起，解析失败抛 `IllegalArgumentException`。
- 比较和算术直接用运算符：`>`、`+` 都返回 `Duration`，单位不同也能比（内部统一换算）。
- [TimeSource.Monotonic](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.time/-time-source/-monotonic.html)：**单调时钟**，不受系统改表/闰秒影响，测"一段代码跑多久"必须用它。反过来，给日志打时间戳要用挂钟（`System.currentTimeMillis()` 或 `java.time.Instant`）——两者用途不同，混用是隐蔽 bug 源。
- [measureTime](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.time/measure-time.html) 是 `markNow/elapsedNow` 两行的语法糖：返回 lambda 的耗时。注意快照里只断言 `耗时非负 = true`——**具体毫秒数每次运行都不同，进了快照就是每跑必红**（19.10 的同款纪律：易变信息降维成稳定断言）。测试 `testKotlinTimeUuidBase64` 断言的也是 `>= 0.seconds` 与 `400.days.inWholeHours == 9600` 这类恒定事实。

## 19.12 kotlin.uuid：随机 UUID（v4）

生成唯一 id 是老需求，`java.util.UUID.randomUUID()` 当然能用——但那是 JVM 专属，且 `kotlin.uuid.Uuid` 给了**值语义 + 严格解析**（`src/FilesDemo.kt` 第 112-113 行）：

```kotlin
/** 生成任务 id：随机 UUID v4——多客户端并发/数据合并场景不会撞 id（24 章注释的兑现） */
@OptIn(ExperimentalUuidApi::class)
fun newTaskId(): String = Uuid.random().toString()
```

演示（`src/Main.kt` 第 107-115 行）与输出：

```kotlin
println("== 19.12 kotlin.uuid：随机 UUID ==")
val u = Uuid.random()
val id = u.toString()
println("random: 长度=${id.length}（8-4-4-4-12 带连字符）, 往返相等=${Uuid.parse(id) == u}")
val fixed = Uuid.parse("550e8400-e29b-41d4-a716-446655440000")
println("parse(固定串).toByteArray().size = ${fixed.toByteArray().size}B")
val bad = runCatching { Uuid.parse("not-a-uuid") }.exceptionOrNull()
println("parse(坏串) 抛: ${bad?.let { it::class.simpleName }}")
println("newTaskId() 长度 = ${newTaskId().length}")
```

```
== 19.12 kotlin.uuid：随机 UUID ==
random: 长度=36（8-4-4-4-12 带连字符）, 往返相等=true
parse(固定串).toByteArray().size = 16B
parse(坏串) 抛: IllegalArgumentException
newTaskId() 长度 = 36
```

- [Uuid.random()](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.uuid/-uuid/random.html) 生成 **v4**（随机版）；`toString()` 是标准 36 字符形式（32 个十六进制 + 4 个连字符），`toByteArray()` 是原始 16 字节。
- `Uuid.parse` **严格校验**：坏串直接抛 `IllegalArgumentException`（不像有些解析器返回 null）。示例用 `runCatching { }.exceptionOrNull()` 捕获并打印异常类名——这是 13 章 `runCatching` 的标准用法。
- `Uuid.parse(id) == u` 为 `true`：Uuid 是 **data class 风格的值类型**，`==` 比内容不比引用。测试里把这条往返固化成断言（`assertEquals(id, Uuid.parse(id).toString())`），并 `assertFailsWith<IllegalArgumentException>` 锁住坏串行为。
- **`@OptIn(ExperimentalUuidApi::class)` 是必须的**：kotlin.uuid 目前还是实验性 API（2.4 仍是）。opt-in 标在哪有个讲究：示例标在**每个用到它的函数**上（`newTaskId`），而 `Main.kt` 的 `main` 上也标了一份——因为 main 直接调用了 `Uuid.random()`/`Uuid.parse`。**标注的作用域是"声明处及其调用点"**：库里标了，调用方不标照样编译不过（这正是 opt-in 机制的目的：让使用者显式知悉风险）。这与 26 章无符号类型的 `@OptIn(ExperimentalUnsignedTypes::class)` 是同一套机制。
- 什么时候用 UUID 而不是自增 id：多客户端并发写入、数据合并、id 会暴露给外部的场景。单机单表的内部主键，自增更省（索引更小）。24 章的 todo 实战项目会把 id 策略从自增升级成 UUID，注释早在那里埋好。

## 19.13 kotlin.io.encoding：Base64

Base64 把任意字节流编码成**纯 ASCII 文本**——邮箱附件、data URI、JWT、HTTP Basic 认证，凡是"二进制数据要过文本协议"的地方都是它。标准库 [kotlin.io.encoding](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io.encoding/) 提供了多平台实现（`src/FilesDemo.kt` 第 118-124 行）：

```kotlin
/** Base64 标准字母表：JWT、data URI、邮件附件都用它 */
@OptIn(ExperimentalEncodingApi::class)
fun b64(s: String): String = Base64.Default.encode(s.encodeToByteArray())

/** HTTP Basic 认证头：Base64("user:pass")——教科书级用例 */
@OptIn(ExperimentalEncodingApi::class)
fun basicAuth(user: String, pass: String): String =
    "Basic " + Base64.Default.encode("$user:$pass".encodeToByteArray())
```

演示（`src/Main.kt` 第 117-124 行）与输出：

```kotlin
println("== 19.13 kotlin.io.encoding：Base64 ==")
val secret = "写 Kotlin 教程"
val enc = b64(secret)
println("encode(\"$secret\") = $enc")
println("decode 还原 = ${String(Base64.Default.decode(enc))}")
val tricky = byteArrayOf(0xFB.toByte(), 0xFF.toByte(), 0xBF.toByte())
println("三字节 FB FF BF: Default=${Base64.Default.encode(tricky)}, UrlSafe=${Base64.UrlSafe.encode(tricky)}")
println("Basic 认证头: ${basicAuth("alice", "s3cret")}")
```

```
== 19.13 kotlin.io.encoding：Base64 ==
encode("写 Kotlin 教程") = 5YaZIEtvdGxpbiDmlZnnqIs=
decode 还原 = 写 Kotlin 教程
三字节 FB FF BF: Default=+/+/, UrlSafe=-_-_
Basic 认证头: Basic YWxpY2U6czNjcmV0
```

- `encode`/`decode` 都在 `ByteArray` 上工作——字符串先 `encodeToByteArray()`（UTF-8）进、`String(...)` 出。这与 Java 的 `Base64.getEncoder()` 等价，但**多平台可用**且 API 更 Kotlin。
- **两套字母表**：[Base64.Default](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io.encoding/-base64/-default.html) 用标准字母表（第 62、63 个字符是 `+` 和 `/`），[Base64.UrlSafe](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io.encoding/-base64/-url-safe.html) 把这两个换成 `-` 和 `_`——因为 `+` 和 `/` 在 URL 和文件名里有特殊含义。第三字节 `FB FF BF` 编码后正好落在字母表尾部，`+/+` → `-_-` 的差异一眼可见。**往 URL/路径里塞 Base64 时忘换 UrlSafe，是经典的"偶发 404"事故源。**
- `Basic YWxpY2U6czNjcmV0` 就是 `Base64("alice:s3cret")`——HTTP Basic 认证的完整构造。注意这只是**编码不是加密**：任何人 base64 解回来就是明文密码，所以 Basic 认证必须配 HTTPS。
- 与 19.12 同样需要 `@OptIn(ExperimentalEncodingApi::class)`（实验性 API，标在函数上）。
- 测试断言 `b64("你好") == "5L2g5aW9"`：`你好` 两字 UTF-8 是 6 字节 → Base64 恰好 8 字符无填充。解码还原、Basic 头构造都逐字节锁死。

## 19.14 测试：临时目录里的文件断言

文件测试的第一纪律：**不碰真实目录**——用 [createTempDirectory](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io.path/create-temp-directory.html)（`kotlin.io.path` 包，java.nio.file.Path 的 stdlib 扩展）在系统临时区开沙盒，用完 `deleteRecursively` 清场（`Tests.kt` 节选）：

```kotlin
fun tmpDir(): File = createTempDirectory("kt19").toFile()

fun testWriteRead() {
    val dir = tmpDir()
    val f = File(dir, "a.txt")
    f.writeText("一\n二\n三")
    assertEquals(listOf("一", "二", "三"), f.readLines())
    assertEquals(11, f.length())         // UTF-8：中文 3B/字 ×3 + 2 个换行
    assertTrue(f.length() > 0)
    f.appendText("四")
    assertEquals("一\n二\n三四", f.readText())
    dir.deleteRecursively()
}
```

`assertEquals(11, f.length())` 把 19.2 的字节算术固化成断言；`appendText("四")` 不带换行，所以读回是 `三四` 连在一行——追加语义被精准确认。其余测试与前文一一对应：`testCsvRoundtrip` 守 CSV 往返一致，`testDates` 守 `13`（Period 分量）与 `2时35分54秒`，`testRegex` 守三种 snake_case 形态与 `parseLog` 的 null 分支（[assertNull](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-null.html)），`testJson` 守转义细节，`testProcessExecute` 守退出码与输出非空，`testKotlinTimeUuidBase64` 守 Duration 换算、UUID 往返与坏串异常、Base64 已知向量。文件、时间、正则、JSON、进程、多平台标准库七块能力全部在测试网里。

## 19.15 编码与平台杂项

- Kotlin 源文件、`writeText`/`readText` 一律 **UTF-8**——跨平台一致，不用想。
- Windows 控制台是另一码事：JVM 19+ 加 `-Dstdout.encoding=UTF-8`，PowerShell 侧 `[Console]::OutputEncoding = UTF8`（本教程构建脚本已内置，中文输出不乱码）。
- 对接旧系统的 GBK 文件：`File("x.txt").readText(charset("GBK"))` 显式给编码。
- `File("相对路径")` 相对的是**进程工作目录**而非源码目录——本教程示例统一在各自示例目录下运行（脚本 `Push-Location`），所以 `build/demo/...` 能落在示例内的忽略目录里。

## 19.16 坑位清单

1. **`Period.days` 是分量不是总天数**（实测 13 vs 104）——总差值用 `ChronoUnit.DAYS.between`。
2. **原始字符串行尾 `$`**：`"""(.*)$"""` 的 `$"""` 撞字符串模板——去锚点或 `${'$'}`。
3. `readLines`/`readText` 整文件进内存——日志级文件用 `useLines`。
4. `File("相对路径")` 锚在进程工作目录——示例要在示例目录下跑。
5. `deleteRecursively` 失败静默返回 `false`（文件被占用时）——重要删除检查返回值。
6. 路径进快照/断言前先归一分隔符（`replace(File.separatorChar, '/')`）——否则 Windows 与 macOS/Linux 快照互不相容。
7. `copyTo(target)` 默认**不覆盖**，同名抛 `FileAlreadyExistsException`——要覆盖传 `overwrite = true`。
8. 子进程**双管道不排空会死锁**——`redirectErrorStream(true)` 合流，且先 `text()` 读完再 `waitFor()`。
9. naive CSV 不处理引号内逗号/换行——生产数据用专业库。
10. `90.seconds` 报 unresolved：`seconds`/`milliseconds`/`days` 是 `Duration.Companion` 上的扩展属性，必须逐个 import。
11. `java.time.Duration` 与 `kotlin.time.Duration` 同名同址不同包——同时用时 `import ... as KtDuration` 起别名。
12. `Uuid.parse` 坏串抛 `IllegalArgumentException`（不返回 null），且 kotlin.uuid / kotlin.io.encoding 是实验性 API，调用方也要 `@OptIn`。
13. Base64 往 URL/文件名里塞必须换 `Base64.UrlSafe`（`+/` → `-_`），否则偶发解析失败；Basic 认证只是编码不是加密，必须配 HTTPS。
14. 计时快照只断言非负/量级——`measureTime` 的具体值每次运行都不同，进快照就是每跑必红。

---

上一章：[18 ⭐Java 互操作](18-javainterop.md) · 下一章：[20 ⭐测试](20-testing.md)
