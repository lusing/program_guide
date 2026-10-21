// 19 · 文件与文本处理演示
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.Duration
import kotlin.time.Duration as KtDuration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlin.time.measureTime
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

@OptIn(ExperimentalUuidApi::class, ExperimentalEncodingApi::class)
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

    println("== 19.10 进程执行扩展 ==")
    val proc = "java -version".execute()
    val out = proc.text()          // 先读到 EOF
    val rc = proc.waitFor()        // 再收退出码——顺序别反
    println("\"java -version\".execute(): exit=$rc, 输出非空=${out.isNotBlank()}（版本细节随机器，不进快照）")
    println("防御: redirectErrorStream(true) 合流——双管道不排空时缓冲写满会把 waitFor 挂死")

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

    println("== 19.12 kotlin.uuid：随机 UUID ==")
    val u = Uuid.random()
    val id = u.toString()
    println("random: 长度=${id.length}（8-4-4-4-12 带连字符）, 往返相等=${Uuid.parse(id) == u}")
    val fixed = Uuid.parse("550e8400-e29b-41d4-a716-446655440000")
    println("parse(固定串).toByteArray().size = ${fixed.toByteArray().size}B")
    val bad = runCatching { Uuid.parse("not-a-uuid") }.exceptionOrNull()
    println("parse(坏串) 抛: ${bad?.let { it::class.simpleName }}")
    println("newTaskId() 长度 = ${newTaskId().length}")

    println("== 19.13 kotlin.io.encoding：Base64 ==")
    val secret = "写 Kotlin 教程"
    val enc = b64(secret)
    println("encode(\"$secret\") = $enc")
    println("decode 还原 = ${String(Base64.Default.decode(enc))}")
    val tricky = byteArrayOf(0xFB.toByte(), 0xFF.toByte(), 0xBF.toByte())
    println("三字节 FB FF BF: Default=${Base64.Default.encode(tricky)}, UrlSafe=${Base64.UrlSafe.encode(tricky)}")
    println("Basic 认证头: ${basicAuth("alice", "s3cret")}")
}
