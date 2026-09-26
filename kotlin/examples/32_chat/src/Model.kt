// 32 · 领域事件（sealed，统一 id 游标）+ 业务错误 + MiniJson（复用 31 章实现，示例间不互相 import）

class AppError(val status: Int, val code: String) : Exception(code)

sealed class ChatEvent {
    abstract val id: Long      // 每种事件都有单调 id——since 游标对全部事件统一推进

    data class Joined(override val id: Long, val user: String) : ChatEvent()
    data class Said(override val id: Long, val from: String, val text: String) : ChatEvent()
    data class Left(override val id: Long, val user: String) : ChatEvent()

    fun toVo(): Map<String, Any?> = when (this) {
        is Joined -> mapOf("type" to "joined", "id" to id, "user" to user)
        is Said -> mapOf("type" to "said", "id" to id, "from" to from, "text" to text)
        is Left -> mapOf("type" to "left", "id" to id, "user" to user)
    }

    companion object {
        /** 工厂：把传输层 Map 还原成密封层级——type 对不上就是坏输入 */
        fun of(m: Map<String, Any?>): ChatEvent = when (m["type"]) {
            "joined" -> Joined(m["id"] as Long, m["user"] as String)
            "said" -> Said(m["id"] as Long, m["from"] as String, m["text"] as String)
            "left" -> Left(m["id"] as Long, m["user"] as String)
            else -> throw IllegalArgumentException("未知事件类型: ${m["type"]}")
        }
    }
}

/** 穷尽渲染：加第四种事件时编译器逼着补分支（08 章思想在实战闭环） */
fun renderEvent(e: ChatEvent): String = when (e) {
    is ChatEvent.Joined -> "*** ${e.user} 进入聊天室"
    is ChatEvent.Said -> "[${e.from}] ${e.text}"
    is ChatEvent.Left -> "*** ${e.user} 离开"
}

/** 与 31 章相同的极简 JSON（示例工程彼此独立，各自携带一份） */
object MiniJson {
    fun encode(v: Any?): String = when (v) {
        null -> "null"
        is String -> "\"" + v.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
        is Boolean, is Number -> v.toString()
        is Map<*, *> -> v.entries.joinToString(",", "{", "}") { encode(it.key) + ":" + encode(it.value) }
        is Iterable<*> -> v.joinToString(",", "[", "]") { encode(it) }
        else -> encode(v.toString())
    }

    fun parseFlat(json: String): Map<String, Any?> {
        val out = linkedMapOf<String, Any?>()
        val s = json.trim().removePrefix("{").removeSuffix("}").trim()
        if (s.isEmpty()) return out
        var i = 0
        while (i < s.length) {
            val kEnd = s.indexOf('"', i + 1)
            val key = s.substring(i + 1, kEnd)
            i = s.indexOf(':', kEnd) + 1
            while (i < s.length && s[i] == ' ') i++
            val start = i
            when {
                s[i] == '"' -> i = s.indexOf('"', start + 1) + 1
                else -> { val e = s.indexOf(',', start); i = if (e < 0) s.length else e }
            }
            out[key] = value(s.substring(start, i))
            while (i < s.length && (s[i] == ',' || s[i] == ' ')) i++
        }
        return out
    }

    fun parseList(json: String): List<Map<String, Any?>> {
        val s = json.trim().removePrefix("[").removeSuffix("]")
        if (s.isBlank()) return emptyList()
        val items = mutableListOf<String>()
        var depth = 0; var start = -1
        for (idx in s.indices) {
            when (s[idx]) {
                '{' -> { if (depth == 0) start = idx; depth++ }
                '}' -> { depth--; if (depth == 0) items += s.substring(start, idx + 1) }
            }
        }
        return items.map(::parseFlat)
    }

    private fun value(raw: String): Any? = when {
        raw.startsWith("\"") -> raw.removePrefix("\"").removeSuffix("\"")
        raw == "true" -> true
        raw == "false" -> false
        raw == "null" -> null
        else -> raw.trim().toLongOrNull() ?: raw.trim().toDouble()
    }
}
