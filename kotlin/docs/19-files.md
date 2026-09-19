# 19 · 文件与文本处理

> 对应示例：`examples/19_files/`（File 扩展、useLines、walk、java.time、Regex、手写 JSON 编码器）
>
> Kotlin 直接复用 `java.io`/`java.nio`，再铺一层扩展函数让手感现代化；
> 时间处理永远用 java.time；正则用 Kotlin 的三引号原始字符串写。

## 19.1 读写文件：一行一个世界

```kotlin
val f = File("build/demo/hello.txt")
f.parentFile?.mkdirs()                 // 建父目录（可空链——目录可能不存在）
f.writeText("第一行\n第二行")          // 写全文（默认 UTF-8）
f.appendText("\n追加")                 // 追加
f.readText()                           // 读全文
f.readLines()                          // 读成 List<String>（整文件进内存）
f.exists(); f.length(); f.name; f.extension
```

对照 Java 的 `Files.write(path, bytes)`/BufferedReader 样板——Kotlin 的扩展函数直接挂在 `File` 上。小文件（配置、模板）用这些就够。

## 19.2 useLines：大文件流式处理

```kotlin
fun countWords(file: File): Int =
    file.useLines { lines ->                       // Sequence<String>，用完自动关
        lines.sumOf { it.split(Regex("\\s+")).count { w -> w.isNotEmpty() } }
    }
```

`useLines` 把文件变成**逐行 Sequence**（22 章的惰性）：内存恒定，任何大小的日志都能数。`use { }` 是通用的自动关闭（16 章）。

## 19.3 目录操作

```kotlin
File(tree, "a/1.txt").apply { parentFile.mkdirs(); writeText("A1") }
File(tree, "3.txt").copyTo(File(tree, "copy.txt"), overwrite = true)
copied.delete()
tree.deleteRecursively()                 // 删目录树（危险操作，路径要核死）

File(root).walkTopDown()                 // 深度优先遍历（Sequence<File>）
    .filter { it.isFile }
    .map { it.name }
    .take(10)
```

`walkTopDown()/walkBottomUp()` 是**惰性遍历**——能接 `filter/map/take`，删目录前先"列出要删的"检查一遍是安全习惯。

⚠️ **跨平台坑：`File.path` 的分隔符随平台变。** 构造时写 `File("build/demo")` 没问题（Windows 一样吃 `/`），但**一旦把 `path` 打印出来、写进快照或断言，就绑死在作者这台机器上了**：Windows 给 `a\1.txt`，macOS/Linux 给 `a/1.txt`，同一份 `expected.txt` 不可能两边都成立。要输出/比对路径就先归一：

```kotlin
val rel = file.relativeTo(root).path.replace(File.separatorChar, '/')   // 或 Kotlin 的 invariantSeparatorsPath
```

本示例 19.5 的目录树（`treeListing`）和 24 章的存储文件路径都按这条改过——否则 Windows 上写着 `build\demo\tasks.json` 的快照，换到 macOS 跑就一片红。

## 19.4 java.time：别再碰 Date/Calendar

```kotlin
val today = LocalDate.of(2026, 9, 18)        // 日期（无时间）
val now = LocalDateTime.now()                // 日期时间
val d = Duration.ofSeconds(9354)             // 精确时长（机器时间）
val p = Period.between(a, b)                 // 日历年月日差（人类时间）

today.format(DateTimeFormatter.ofPattern("yyyy年MM月dd日"))
today.plusDays(45); today.withDayOfMonth(1)
```

三个易混概念：

| 类型 | 语义 | 例 |
|---|---|---|
| `Period` | 人类时间差（年/月/日分量） | 生日年龄 |
| `Duration` | 机器时间差（秒/纳秒） | 计时、超时 |
| `Instant` | UTC 时间线上的点 | 时间戳 |

**大坑实测**：`Period.between(today, yearEnd).days` 返回 **13**——它是"3 个月零 13 天"的**分量**，不是总天数！总天数要用 `ChronoUnit.DAYS.between(a, b)`（= 104）。示例代码把两者都打出来对照。

## 19.5 Regex：三引号里少转义

```kotlin
Regex("\\d+")                          // 普通串：\\d
Regex("""\d+""")                       // 原始字符串：单 \（推荐）

val m = Regex("""^(\d{2}:\d{2}:\d{2}) \[(\w+)] (.*)""").find(line)
val (ts, level, msg) = m!!.destructured    // 按捕获组解构
```

常用：`find/findAll/containsMatchIn/replace/split/matchEntire`。`destructured` 把捕获组按解构声明取出来（`(\w+)` 圆括号 = 捕获组）。

⚠️ **原始字符串的行尾 `$` 陷阱**（本教程实测翻车）：`"""(.*)$"""` 的 `$"""` 会被解析成字符串模板 `$"` → 语法错。要么去掉行尾锚点（`.*` 贪婪到行尾，多数场景等价），要么写 `${'$'}`。

## 19.6 buildString 与字符串组装

```kotlin
val report = buildString {
    appendLine("== 标题 ==")
    for (x in items) appendLine(x)
}
```

循环拼接永远用 `buildString`（StringBuilder 的接收者语法糖，23 章前奏），不要 `+` 累加（O(n²)）。

## 19.7 实战：手写极简 JSON 编码器

不许依赖库时，JSON 编码 30 行搞定——正好复习 08 章的递归 + when：

```kotlin
fun toJson(v: Any?): String = when (v) {
    null -> "null"
    is String -> "\"${jsonEscape(v)}\""
    is Boolean -> v.toString()
    is Int, is Long, is Double -> v.toString()
    is Map<*, *> -> v.entries.joinToString(", ", "{", "}") {
        "\"${jsonEscape(it.key.toString())}\": ${toJson(it.value)}"
    }
    is List<*> -> v.joinToString(", ", "[", "]") { toJson(it) }
    else -> "\"${jsonEscape(v.toString())}\""
}

fun jsonEscape(s: String): String = buildString {
    for (c in s) when (c) {
        '"' -> append("\\\""); '\\' -> append("\\\\")
        '\n' -> append("\\n"); '\t' -> append("\\t")
        else -> if (c < ' ') append("\\u%04x".format(c.code)) else append(c)
    }
}
```

编码器只需要 `when (类型)` 分派 + 递归。**解析器**（字符串→值）要递归下降 100 来行——24 章实战项目完整实现并配测试。

## 19.8 编码与平台

- Kotlin 源文件、`writeText/readText` 默认 **UTF-8**（跨平台一致）。
- Windows 控制台是另码事：JVM 输出加 `-Dstdout.encoding=UTF-8`（JDK 19+），PowerShell 侧 `[Console]::OutputEncoding = UTF8`——本教程 build.ps1 已内置。
- 处理旧系统 GBK 文件：`File.readText(charset("GBK"))`。

## 19.9 坑位清单

1. **`Period.days` 是分量不是总天数**（19.4 实测：13 vs 104）——总差值用 `ChronoUnit.DAYS`。
2. **原始字符串行尾 `$`**（19.5）——正则行尾锚的高频翻车点。
3. `readLines/readText` 把整文件拉进内存——日志级文件用 `useLines`。
4. `File("相对路径")` 相对的是**进程工作目录**，不是源码目录——本教程示例统一在示例目录下跑（build.ps1 Push-Location）。
5. `deleteRecursively` 失败会静默返回 false（个别文件占用时）——重要删除要检查返回值。
6. Windows 路径分隔符混用：展示路径前 `replace('\\', '/')` 统一（快照测试才稳定）。
7. `copyTo(target)` 默认 **不覆盖**——同名会抛 FileAlreadyExistsException，要覆盖传 `overwrite = true`。
