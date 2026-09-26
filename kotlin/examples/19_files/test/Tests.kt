// 19 的测试：文件读写、CSV、正则、JSON 编码（用临时目录，不污染示例目录）
import java.io.File
import java.time.Duration
import java.time.LocalDate
import kotlin.io.path.createTempDirectory
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

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

fun testCountWords() {
    val dir = tmpDir()
    val f = File(dir, "w.txt")
    f.writeText("kotlin is\nfun yes")
    assertEquals(4, countWords(f))
    f.writeText("")
    assertEquals(0, countWords(f))
    dir.deleteRecursively()
}

fun testCsvRoundtrip() {
    val dir = tmpDir()
    val f = File(dir, "d.csv")
    writeCsv(f, listOf(listOf("a", "1"), listOf("b", "2")))
    assertEquals(listOf(listOf("a", "1"), listOf("b", "2")), readCsv(f))
    dir.deleteRecursively()
}

fun testDates() {
    assertEquals("2026年09月18日", formatDate(LocalDate.of(2026, 9, 18)))
    assertEquals(13, daysBetween(LocalDate.of(2026, 9, 18), LocalDate.of(2026, 12, 31)))
    assertEquals("2时35分54秒", describeDuration(Duration.ofSeconds(9354)))
}

fun testRegex() {
    assertEquals("http_server", toSnakeCase("HTTPServer"))
    assertEquals("my_kotlin_var2", toSnakeCase("myKotlinVar2"))
    assertEquals("get_http_response", toSnakeCase("getHTTPResponse"))
    val good = parseLog("09:15:00 [INFO] ok")!!
    assertEquals("09:15:00", good.ts)
    assertEquals("INFO", good.level)
    assertEquals("ok", good.msg)
    assertNull(parseLog("not a log line"))
}

fun testJson() {
    assertEquals("null", toJson(null))
    assertEquals("42", toJson(42))
    assertEquals("true", toJson(true))
    assertEquals("\"a\\\"b\"", toJson("a\"b"))
    assertEquals("[1, \"x\", null]", toJson(listOf(1, "x", null)))
    assertEquals("""{"id": 1, "t": "买\"菜\""}""", toJson(mapOf("id" to 1, "t" to "买\"菜\"")))
    assertEquals("\"line\\nnext\"", toJson("line\nnext"))
}

fun testProcessExecute() {
    val p = "java -version".execute()
    val out = p.text()               // 先读 EOF
    val rc = p.waitFor()             // 再收码
    assertEquals(0, rc)
    assertTrue(out.isNotBlank())     // -version 输出走 stderr，合流后统一可读
}

fun main() {
    testWriteRead()
    testCountWords()
    testCsvRoundtrip()
    testDates()
    testRegex()
    testJson()
    testProcessExecute()
    println("19_files 全部测试通过")
}
