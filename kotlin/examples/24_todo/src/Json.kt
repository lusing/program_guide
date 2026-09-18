// 24 实战 · 手写 JSON：解析器（递归下降）+ 编码器——零依赖的教学实现
// 支持：对象/数组/字符串（含 \u 转义）/数字/true/false/null；数字解析为 Long 或 Double

sealed interface Json {
    data object Null : Json
    data class Bool(val v: Boolean) : Json
    data class Num(val v: Number) : Json
    data class Str(val v: String) : Json
    data class Arr(val items: List<Json>) : Json
    data class Obj(val entries: List<Pair<String, Json>>) : Json {
        operator fun get(key: String): Json? = entries.firstOrNull { it.first == key }?.second
    }
}

object JsonParser {
    fun parse(src: String): Json {
        val p = P(src)
        p.ws()
        val v = p.value()
        p.ws()
        require(p.i >= src.length) { "JSON 末尾有多余内容（位置 ${p.i}）" }
        return v
    }

    private class P(val s: String) {
        var i = 0
        fun ws() { while (i < s.length && s[i].isWhitespace()) i++ }
        fun expect(c: Char) {
            require(i < s.length && s[i] == c) { "期望 '$c'，位置 $i 附近: ${s.substring(i, minOf(i + 8, s.length))}" }
            i++
        }
        fun value(): Json {
            require(i < s.length) { "JSON 意外结束" }
            return when (s[i]) {
                '{' -> obj()
                '[' -> arr()
                '"' -> Json.Str(string())
                't' -> lit("true", Json.Bool(true))
                'f' -> lit("false", Json.Bool(false))
                'n' -> lit("null", Json.Null)
                else -> number()
            }
        }
        fun lit(word: String, v: Json): Json {
            require(s.startsWith(word, i)) { "非法字面量，位置 $i" }
            i += word.length
            return v
        }
        fun peek(c: Char): Boolean = i < s.length && s[i] == c
        fun obj(): Json.Obj {
            expect('{'); ws()
            val entries = mutableListOf<Pair<String, Json>>()
            if (peek('}')) { i++; return Json.Obj(entries) }
            while (true) {
                val k = string(); ws(); expect(':'); ws()
                entries += k to value(); ws()
                when {
                    peek(',') -> { i++; ws() }
                    peek('}') -> { i++; return Json.Obj(entries) }
                    else -> throw IllegalArgumentException("对象里期望 ',' 或 '}'，位置 $i")
                }
            }
        }
        fun arr(): Json.Arr {
            expect('['); ws()
            val items = mutableListOf<Json>()
            if (peek(']')) { i++; return Json.Arr(items) }
            while (true) {
                items += value(); ws()
                when {
                    peek(',') -> { i++; ws() }
                    peek(']') -> { i++; return Json.Arr(items) }
                    else -> throw IllegalArgumentException("数组里期望 ',' 或 ']'，位置 $i")
                }
            }
        }
        fun string(): String {
            expect('"')
            val out = StringBuilder()
            while (true) {
                require(i < s.length) { "字符串未闭合" }
                when (val c = s[i]) {
                    '"' -> { i++; return out.toString() }
                    '\\' -> {
                        i++
                        require(i < s.length) { "转义未闭合" }
                        when (val e = s[i]) {
                            '"' -> out.append('"'); '\\' -> out.append('\\'); '/' -> out.append('/')
                            'b' -> out.append('\b'); 'f' -> out.append('\u000C'); 'n' -> out.append('\n')
                            'r' -> out.append('\r'); 't' -> out.append('\t')
                            'u' -> {
                                require(i + 4 < s.length) { "\\u 转义不完整" }
                                out.append(s.substring(i + 1, i + 5).toInt(16).toChar())
                                i += 4
                            }
                            else -> throw IllegalArgumentException("非法转义 \\$e")
                        }
                        i++
                    }
                    else -> { out.append(c); i++ }
                }
            }
        }
        fun number(): Json.Num {
            val start = i
            if (i < s.length && s[i] == '-') i++
            require(i < s.length && s[i].isDigit()) { "非法数字，位置 $i" }
            while (i < s.length && s[i].isDigit()) i++
            var isDouble = false
            if (i < s.length && s[i] == '.') {
                isDouble = true; i++
                require(i < s.length && s[i].isDigit()) { "小数点后缺数字" }
                while (i < s.length && s[i].isDigit()) i++
            }
            if (i < s.length && (s[i] == 'e' || s[i] == 'E')) {
                isDouble = true; i++
                if (i < s.length && (s[i] == '+' || s[i] == '-')) i++
                require(i < s.length && s[i].isDigit()) { "指数缺数字" }
                while (i < s.length && s[i].isDigit()) i++
            }
            val text = s.substring(start, i)
            return Json.Num(if (isDouble) text.toDouble() else text.toLong())
        }
    }
}

object JsonWriter {
    fun write(v: Json): String = when (v) {
        Json.Null -> "null"
        is Json.Bool -> v.v.toString()
        is Json.Num -> v.v.toString()
        is Json.Str -> quote(v.v)
        is Json.Arr -> v.items.joinToString(",", "[", "]") { write(it) }
        is Json.Obj -> v.entries.joinToString(",", "{", "}") { "${quote(it.first)}:${write(it.second)}" }
    }

    fun quote(s: String): String = buildString {
        append('"')
        for (c in s) when (c) {
            '"' -> append("\\\""); '\\' -> append("\\\\")
            '\n' -> append("\\n"); '\r' -> append("\\r"); '\t' -> append("\\t")
            '\u000C' -> append("\\f")
            else -> if (c < ' ') append("\\u%04x".format(c.code)) else append(c)
        }
        append('"')
    }
}

/** 领域对象 ↔ JSON 的转换（编解码各 ~10 行，正是 data class + when 的甜区） */
fun Task.toJson(): Json = Json.Obj(
    listOf("id" to Json.Num(id), "title" to Json.Str(title), "done" to Json.Bool(done)),
)

fun Json.toTask(): Task {
    val obj = this as? Json.Obj ?: error("任务必须是 JSON 对象")
    val id = (obj["id"] as? Json.Num ?: error("id 缺失")).v.toInt()
    val title = (obj["title"] as? Json.Str ?: error("title 缺失")).v
    val done = (obj["done"] as? Json.Bool)?.v ?: false   // 旧数据缺 done 字段 → 默认未完成
    return Task(id, title, done)
}

fun tasksToJson(tasks: List<Task>): String = JsonWriter.write(Json.Arr(tasks.map { it.toJson() }))

fun tasksFromJson(src: String): List<Task> {
    val root = JsonParser.parse(src)
    require(root is Json.Arr) { "根节点必须是数组" }
    return root.items.map { it.toTask() }
}
