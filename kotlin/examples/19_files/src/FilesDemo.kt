// 19 · 文件与文本：File 扩展、useLines、walk、java.time、Regex、手写极简 JSON 编码器
// 运行期工作目录 = 本示例目录；所有文件读写都落在 build/demo/ 下（.gitignore 已忽略）
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.Duration
import java.time.Period
import java.time.format.DateTimeFormatter
import kotlin.time.Duration as KtDuration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlin.time.measureTime
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

// ---------- 文本与目录 ----------

/** Groovy 风格进程扩展：redirectErrorStream 合流——双管道不排空时 waitFor 会死锁 */
fun String.execute(): Process =
    ProcessBuilder(*split(Regex("\\s+")).toTypedArray())
        .redirectErrorStream(true)
        .start()

fun Process.text(): String = inputStream.bufferedReader().readText()

/** 逐行流式处理大文件：useLines 用完自动关流，常量内存 */
fun countWords(file: File): Int =
    file.useLines { lines -> lines.sumOf { it.split(Regex("\\s+")).count { w -> w.isNotEmpty() } } }

fun writeCsv(path: File, rows: List<List<String>>) {
    path.parentFile?.mkdirs()
    path.writeText(rows.joinToString("\n") { it.joinToString(",") })
}

fun readCsv(path: File): List<List<String>> =
    path.readLines().filter { it.isNotBlank() }.map { it.split(",") }

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

// ---------- java.time ----------

fun formatDate(d: LocalDate): String = d.format(DateTimeFormatter.ofPattern("yyyy年MM月dd日"))

fun daysBetween(a: LocalDate, b: LocalDate): Int = Period.between(a, b).days

fun describeDuration(d: Duration): String {
    val h = d.toHours(); val m = d.toMinutes() % 60; val s = d.seconds % 60
    return "${h}时${m}分${s}秒"
}

// ---------- Regex ----------

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

// ---------- 极简 JSON 编码器（只编码，24 章实战项目会补解析器） ----------

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

// ---------- kotlin.time：Kotlin 自己的时间 API（多平台，java.time 的对应物） ----------

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

// ---------- kotlin.uuid：随机 UUID（24 章 todo 项目的 id 生成策略升级版） ----------

/** 生成任务 id：随机 UUID v4——多客户端并发/数据合并场景不会撞 id（24 章注释的兑现） */
@OptIn(ExperimentalUuidApi::class)
fun newTaskId(): String = Uuid.random().toString()

// ---------- kotlin.io.encoding：Base64（二进制数据进文本协议的标准操作） ----------

/** Base64 标准字母表：JWT、data URI、邮件附件都用它 */
@OptIn(ExperimentalEncodingApi::class)
fun b64(s: String): String = Base64.Default.encode(s.encodeToByteArray())

/** HTTP Basic 认证头：Base64("user:pass")——教科书级用例 */
@OptIn(ExperimentalEncodingApi::class)
fun basicAuth(user: String, pass: String): String =
    "Basic " + Base64.Default.encode("$user:$pass".encodeToByteArray())

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
