// 32 · 剧本对话：ann 加入 → 对话 → bot 逐条回复 → 告别 → 离开；快照即逐字回放

fun main() {
    println("== 32.1 起服务与 MVP 装配 ==")
    val server = ChatServer()
    val port = server.start()
    val view = TranscriptView()
    val ann = ChatPresenter(view, ChatApi(port))            // 用户一：ann
    val botApi = ChatApi(port)                              // 用户二：规则机器人
    println("ChatServer 已启动（临时端口），TranscriptView + ChatPresenter + ChatApi 装配完成")

    println("== 32.2 ann 加入并读历史 ==")
    ann.onJoin("ann")

    println("== 32.3 对话与机器人 ==")
    val annSays = listOf("你好，聊天室", "Kotlin 好学吗？")
    botApi.join("bot")                                      // bot 加入（此刻 ann 还没刷新，游标在 3）
    for (text in annSays) {
        ann.onSay(text)
        botApi.say(EchoBot.replyTo(text))                   // bot 对每条 ann 消息回复一次
    }

    println("== 32.4 错误路径也走 View ==")
    ann.onSay("   ")                                        // 空文本 → 400 → showError 进字幕

    println("== 32.5 告别与离开 ==")
    ann.onSay("再见")
    botApi.say(EchoBot.replyTo("再见"))
    ann.onLeave()

    println("== 32.6 完整字幕（快照即回放）==")
    view.transcript.forEach(::println)
    server.stop()
}
