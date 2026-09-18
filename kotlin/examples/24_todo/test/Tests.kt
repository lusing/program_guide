// 24 实战 · 测试：JSON 解析器、编解码往返、模型纯函数、存储与 CLI 全链路
import java.io.File
import kotlin.io.path.createTempDirectory
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

// ---------- JSON 解析器 ----------

fun testScalars() {
    assertEquals(Json.Null, JsonParser.parse("null"))
    assertEquals(Json.Bool(true), JsonParser.parse("true"))
    assertEquals(Json.Num(42L), JsonParser.parse("42"))
    assertEquals(Json.Num(-7L), JsonParser.parse("-7"))
    assertEquals(Json.Num(3.5), JsonParser.parse("3.5"))
    assertEquals(Json.Num(1.0E3), JsonParser.parse("1e3"))
    assertEquals(Json.Str("hi"), JsonParser.parse("\"hi\""))
    assertEquals(Json.Str(""), JsonParser.parse("\"\""))
}

fun testNested() {
    val src = """{"a":[1,{"b":"中文"}],"c":null,"d":true}"""
    val v = JsonParser.parse(src) as Json.Obj
    assertEquals(3, v.entries.size)   // a / c / d
    val a = v["a"] as Json.Arr
    assertEquals(Json.Num(1L), a.items[0])
    assertEquals("中文", ((a.items[1] as Json.Obj)["b"] as Json.Str).v)
    assertEquals(Json.Null, v["c"])
    assertEquals(Json.Bool(true), v["d"])
}

fun testEscapes() {
    val v = JsonParser.parse("\"a\\\"b\\\\c\\nd\\u4e2d\"") as Json.Str
    assertEquals("a\"b\\c\nd中", v.v)
}

fun testMalformed() {
    assertFailsWith<IllegalArgumentException> { JsonParser.parse("{") }
    assertFailsWith<IllegalArgumentException> { JsonParser.parse("[1,]") }   // 尾逗号
    assertFailsWith<IllegalArgumentException> { JsonParser.parse("\"未闭合") }
    assertFailsWith<IllegalArgumentException> { JsonParser.parse("01x") }    // 数字后跟垃圾
    assertFailsWith<IllegalArgumentException> { JsonParser.parse("{}x") }    // 末尾多余
}

fun testWrite() {
    assertEquals("""{"a":1,"b":[true,"x"]}""",
        JsonWriter.write(Json.Obj(listOf("a" to Json.Num(1L), "b" to Json.Arr(listOf(Json.Bool(true), Json.Str("x")))))))
    assertEquals("\"tab\\there\"", JsonWriter.quote("tab\there"))
    assertEquals("null", JsonWriter.write(Json.Null))
}

// ---------- 领域模型 ----------

fun testModelOps() {
    val (l1, id1) = addTask(emptyList(), "一")
    assertEquals(1, id1)
    val (l2, id2) = addTask(l1, "  二  ")
    assertEquals(2, id2)
    assertEquals("二", l2.last().title)               // 标题已 trim
    val l3 = completeTask(l2, id1)!!
    assertEquals(listOf(true, false), l3.map { it.done })   // 第 1 项被勾选
    assertNull(completeTask(l2, 99))
    assertEquals(listOf(2), removeTask(l3, 1)!!.map { it.id })
    assertNull(removeTask(l3, 99))
    assertFailsWith<IllegalArgumentException> { addTask(l3, "   ") }
}

fun testRender() {
    val l = listOf(Task(1, "a", true), Task(2, "b"))
    assertEquals(listOf("[x] #1 a", "[ ] #2 b", "共 2 项，未完成 1 项"), renderTasks(l))
    assertEquals(listOf("[ ] #2 b", "共 2 项，未完成 1 项"), renderTasks(l, showAll = false))
}

// ---------- 存储往返 ----------

fun testStoreRoundtrip() {
    val dir = createTempDirectory("kt24").toFile()
    val f = File(dir, "t.json")
    val repo = JsonFileStore(f)
    assertEquals(emptyList(), repo.load())             // 文件不存在 → 空表
    repo.save(listOf(Task(1, "中文 \"标题\"", true), Task(2, "二")))
    val back = repo.load()
    assertEquals(listOf(Task(1, "中文 \"标题\"", true), Task(2, "二")), back)
    assertTrue(f.readText().contains("\\\"标题\\\""))   // 引号正确转义落盘
    dir.deleteRecursively()
}

fun testLegacyData() {
    // done 字段缺失的旧数据 → 默认未完成（向后兼容）
    val t = JsonParser.parse("""[{"id":1,"title":"旧任务"}]""").let { root ->
        (root as Json.Arr).items.map { it.toTask() }
    }
    assertEquals(listOf(Task(1, "旧任务", false)), t)
}

// ---------- CLI 全链路 ----------

private fun memRepo(): TaskRepository {
    var state = emptyList<Task>()     // 外层捕获变量改名，避免与 override 参数同名告警
    return object : TaskRepository {
        override fun load() = state
        override fun save(tasks: List<Task>) { state = tasks }
    }
}

fun testCliHappy() {
    val r = memRepo()
    assertEquals(EXIT_OK, runCli(r, listOf("add", "任务A")).exitCode)
    assertEquals(EXIT_OK, runCli(r, listOf("add", "任务B")).exitCode)
    assertEquals(listOf("已添加 #3 任务C"), runCli(r, listOf("add", "任务C")).lines)
    assertEquals(EXIT_OK, runCli(r, listOf("done", "1")).exitCode)
    val out = runCli(r, listOf("list"))
    assertEquals(EXIT_OK, out.exitCode)
    assertEquals("[x] #1 任务A", out.lines[0])
    assertEquals("共 3 项，未完成 2 项", out.lines.last())
    assertEquals(EXIT_OK, runCli(r, listOf("rm", "3")).exitCode)
    assertEquals("共 2 项，未完成 1 项", runCli(r, listOf("list")).lines.last())
}

fun testCliErrors() {
    val r = memRepo()
    assertEquals(EXIT_NOT_FOUND, runCli(r, listOf("done", "5")).exitCode)
    assertEquals(EXIT_USAGE, runCli(r, listOf("bogus")).exitCode)
    assertEquals(EXIT_USAGE, runCli(r, listOf("add")).exitCode)
    assertEquals(EXIT_USAGE, runCli(r, listOf("done", "abc")).exitCode)
    val help = runCli(r, emptyList())
    assertEquals(EXIT_OK, help.exitCode)
    assertTrue(help.lines.first().startsWith("用法"))
}

fun main() {
    testScalars()
    testNested()
    testEscapes()
    testMalformed()
    testWrite()
    testModelOps()
    testRender()
    testStoreRoundtrip()
    testLegacyData()
    testCliHappy()
    testCliErrors()
    println("24_todo 全部测试通过")
}
