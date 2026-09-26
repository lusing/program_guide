// 31 的测试：MiniJson、端到端（真服务 + 真请求）、Flow 轮询
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.runBlocking
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

fun testMiniJsonEncode() {
    assertEquals("""{"a":1,"b":"x","c":[1,2]}""", MiniJson.encode(linkedMapOf("a" to 1, "b" to "x", "c" to listOf(1, 2))))
    assertEquals(""""a\"b"""", MiniJson.encode("a\"b"))
    assertEquals("null", MiniJson.encode(null))
}

fun testMiniJsonParseFlat() {
    val m = MiniJson.parseFlat("""{"user":"ann","n":42,"ok":true,"x":null}""")
    assertEquals("ann", m["user"]); assertEquals(42L, m["n"])
    assertEquals(true, m["ok"]); assertEquals(null, m["x"])
    val l = MiniJson.parseList("""[{"id":1,"text":"a"},{"id":2,"text":"b"}]""")
    assertEquals(2, l.size); assertEquals(1L, l[0]["id"]); assertEquals("b", l[1]["text"])
}

fun testEndToEnd() {
    val server = RestServer(Repo())
    val port = server.start()
    try {
        val api = ApiClient(port)
        assertEquals(401, assertFailsWith<ApiException> { api.messagesSince(0) }.status)   // 未认证
        assertEquals(401, assertFailsWith<ApiException> { api.login("ann", "错密码") }.status)
        val token = api.login("ann", "pw-ann")
        assertEquals("tok-ann", token)
        assertContains(api.users(), "ann")
        assertContains(api.addUser("cat"), "cat")
        assertEquals(400, assertFailsWith<ApiException> { api.addUser("x") }.status)       // 校验
        assertEquals(409, assertFailsWith<ApiException> { api.addUser("ann") }.status)     // 冲突
        api.postMessage("hello")
        val msgs = api.messagesSince(3)
        assertEquals(1, msgs.size)
        assertEquals("hello", msgs[0]["text"])
        assertEquals("ann", msgs[0]["from"])
        assertEquals(404, assertFailsWith<ApiException> { api.raw("GET", "/nope") }.status)   // 未知路由
    } finally { server.stop() }
}

fun testSecondToken() {
    val server = RestServer(Repo())
    val port = server.start()
    try {
        val api = ApiClient(port)
        api.login("bob", "pw-bob")                      // 令牌表通用：bob 登录也能拉
        assertTrue(api.messagesSince(0).isNotEmpty())
    } finally { server.stop() }
}

fun testPollFlow() {
    val server = RestServer(Repo())
    val port = server.start()
    try {
        val api = ApiClient(port)
        api.login("ann", "pw-ann")
        var polls = 0
        val seen = mutableListOf<String>()
        runBlocking {
            pollFlow(api, from = 0, maxPolls = 10) { polls++ }.take(2).collect { seen.add(it) }
        }
        assertEquals(1, polls)          // 第一轮就有 3 条，take(2) 即取消
        assertEquals(2, seen.size)
        assertTrue(seen[0].startsWith("bob: "))
    } finally { server.stop() }
}

fun main() {
    testMiniJsonEncode()
    testMiniJsonParseFlat()
    testEndToEnd()
    testSecondToken()
    testPollFlow()
    println("31_http 全部测试通过")
}
