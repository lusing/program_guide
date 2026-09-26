// 31 · 领域模型、内存仓储、MiniJson 编解码、业务错误类型

data class User(val id: Long, val name: String) {
    /** VO：只放该出门的字段——内部以后加敏感列也不会泄漏 */
    fun toVo(): Map<String, Any?> = mapOf("id" to id, "name" to name)
}

data class Message(val id: Long, val from: String, val text: String) {
    fun toVo(): Map<String, Any?> = mapOf("id" to id, "from" to from, "text" to text)
}

/** 业务错误：带 HTTP 状态码，全局映射器统一翻译 */
class AppError(val status: Int, val code: String) : Exception(code)

class Repo {
    val users = mutableListOf(User(1, "ann"), User(2, "bob"))
    val messages = mutableListOf(
        Message(1, "bob", "你好"),
        Message(2, "cat", "在吗"),
        Message(3, "bob", "终端聊天室上线"),
    )
    private var nextUserId = 3L
    private var nextMsgId = 4L

    fun addUser(name: String): User {
        if (name.length < 2) throw AppError(400, "name too short")          // 校验在仓储入口
        if (users.any { it.name == name }) throw AppError(409, "name exists")
        val u = User(nextUserId++, name); users += u; return u
    }

    fun addMessage(from: String, text: String): Message {
        if (text.isBlank()) throw AppError(400, "text blank")
        val m = Message(nextMsgId++, from, text.trim()); messages += m; return m
    }

    fun messagesSince(since: Int): List<Message> = messages.filter { it.id > since }
}

/** 极简 JSON：类型分派编码 + 平坦对象/数组解析（完整递归下降版见 24 章） */
object MiniJson {
    fun encode(v: Any?): String = when (v) {
        null -> "null"
        is String -> "\"" + v.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
        is Boolean, is Number -> v.toString()
        is Map<*, *> -> v.entries.joinToString(",", "{", "}") { encode(it.key) + ":" + encode(it.value) }
        is Iterable<*> -> v.joinToString(",", "[", "]") { encode(it) }
        else -> encode(v.toString())
    }

    /** 平坦对象：{"a":"x","b":1,"c":true,"d":null}（不嵌套、字符串内转义不还原） */
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

    /** 平坦对象数组：[ {...}, {...} ]（按花括号配对切分） */
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
