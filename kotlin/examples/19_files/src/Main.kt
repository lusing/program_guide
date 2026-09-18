// 19 · 文件与文本处理演示
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.Duration

fun main() {
    val demo = File("build/demo")     // 相对路径 → examples/19_files/build/demo（已 gitignore）

    println("== 19.2 写与读 ==")
    val hello = File(demo, "hello.txt")
    hello.parentFile?.mkdirs()
    hello.writeText("第一行：kotlin\n第二行：文件")
    hello.appendText("\n第三行：追加")
    println("readText():"); hello.readLines().forEach { println("  $it") }
    println("exists=${hello.exists()}, 大小=${hello.length()}B, 绝对路径=${hello.absolutePath.replace('\\', '/').substringAfterLast("examples/")}")

    println("== 19.3 useLines 流式处理 ==")
    val words = File(demo, "words.txt")
    words.writeText("kotlin is fun\nfiles are easy\nstreams save memory")
    println("words.txt 词数 = ${countWords(words)}")

    println("== 19.4 CSV 往返（naive 版：不处理引号转义）==")
    val csv = File(demo, "data.csv")
    writeCsv(csv, listOf(listOf("name", "age"), listOf("张三", "30"), listOf("李四", "41")))
    println(readCsv(csv).joinToString(" / ") { it.joinToString("|") })

    println("== 19.5 目录树 walk ==")
    val tree = File(demo, "tree").apply { deleteRecursively(); mkdirs() }
    File(tree, "a/1.txt").apply { parentFile.mkdirs(); writeText("A1") }
    File(tree, "a/b/2.txt").apply { parentFile.mkdirs(); writeText("B2-longer") }
    File(tree, "3.txt").writeText("T3")
    treeListing(tree).forEach { println("  $it") }

    println("== 19.6 拷贝与删除 ==")
    val copied = File(tree, "3-copy.txt")
    File(tree, "3.txt").copyTo(copied, overwrite = true)
    println("复制后存在 ${copied.name}: ${copied.exists()}")
    copied.delete()
    println("删除后: ${copied.exists()}")

    println("== 19.7 java.time（不可变、线程安全，别再用 Date/Calendar）==")
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

    println("== 19.8 Regex ==")
    println("toSnakeCase(HTTPServer) = ${toSnakeCase("HTTPServer")}")
    println("toSnakeCase(myKotlinVar2) = ${toSnakeCase("myKotlinVar2")}")
    val logs = listOf(
        "09:15:00 [INFO] 服务启动",
        "garbage line",
        "09:15:03 [WARN] 磁盘 85%",
    )
    for (l in logs) println("  ${parseLog(l) ?: "（不匹配）"}")

    println("== 19.9 极简 JSON 编码器 ==")
    val task = mapOf(
        "id" to 1,
        "title" to "写 Kotlin 教程",
        "done" to false,
        "tags" to listOf("docs", "wip"),
        "note" to "带\"引号\"与\n换行",
        "due" to null,
    )
    println(toJson(task))
}
