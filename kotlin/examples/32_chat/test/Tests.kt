// 32 的测试：机器人规则表驱动、穷尽渲染、事件工厂、端到端剧本（真服务 + 双客户端）
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

fun testEchoBot() {
    // 表驱动：规则机器人零随机零时钟，可逐字断言
    val table = listOf(
        "你好，聊天室" to "你好！我是回声机器人",
        "Kotlin 好学吗？" to "好问题！「Kotlin 好学吗」的答案是：42",
        "再见" to "再见，下次见！",
        "随便说点什么" to "回声: 随便说点什么",
    )
    for ((input, want) in table) assertEquals(want, EchoBot.replyTo(input))
}

fun testRenderEvent() {
    assertEquals("*** ann 进入聊天室", renderEvent(ChatEvent.Joined(4, "ann")))
    assertEquals("[bob] 你好", renderEvent(ChatEvent.Said(1, "bob", "你好")))
    assertEquals("*** cat 离开", renderEvent(ChatEvent.Left(9, "cat")))
}

fun testEventFactory() {
    val e = ChatEvent.of(linkedMapOf("type" to "said", "id" to 2L, "from" to "cat", "text" to "在吗"))
    assertEquals(ChatEvent.Said(2, "cat", "在吗"), e)
    assertFailsWith<IllegalArgumentException> { ChatEvent.of(mapOf("type" to "boom")) }
    assertEquals(6L, e.id + 4L)
}

fun testUnauthorized() {
    val server = ChatServer()
    val port = server.start()
    try {
        val e = assertFailsWith<ApiException> { ChatApi(port).eventsSince(0) }
        assertEquals(401, e.status)
    } finally { server.stop() }
}

fun testScriptedConversation() {
    val server = ChatServer()
    val port = server.start()
    try {
        val view = TranscriptView()
        val ann = ChatPresenter(view, ChatApi(port))
        val botApi = ChatApi(port)

        ann.onJoin("ann")
        botApi.join("bot")
        for (text in listOf("你好，聊天室", "Kotlin 好学吗？")) {
            ann.onSay(text)
            botApi.say(EchoBot.replyTo(text))
        }
        ann.onSay("   ")                      // 错误路径进字幕
        ann.onSay("再见")
        botApi.say(EchoBot.replyTo("再见"))
        ann.onLeave()

        assertEquals(
            listOf(
                "[bob] 你好",
                "[cat] 在吗",
                "[bob] 终端聊天室上线",
                "*** ann 进入聊天室",
                "*** bot 进入聊天室",
                "[ann] 你好，聊天室",
                "[bot] 你好！我是回声机器人",
                "[ann] Kotlin 好学吗？",
                """[错误] {"error":"text blank"}""",      // 错误即时进字幕；bot 第二条回复要等下次 refresh
                "[bot] 好问题！「Kotlin 好学吗」的答案是：42",
                "[ann] 再见",
                "[bot] 再见，下次见！",
                "*** ann 离开",
            ),
            view.transcript,
        )
        // 游标推进用最后事件 id：leave 后再刷新不重复
        ann.refresh()
        assertEquals(13, view.transcript.size)             // 13 行字幕 = 12 个事件 + 1 条错误行
        assertTrue(server.events.size >= 12)
        assertContains(server.events.map { it.id }, 12L)
    } finally { server.stop() }
}

fun main() {
    testEchoBot()
    testRenderEvent()
    testEventFactory()
    testUnauthorized()
    testScriptedConversation()
    println("32_chat 全部测试通过")
}
