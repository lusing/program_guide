// 23 · 类型安全 DSL：带接收者 lambda + @DslMarker + 中缀断言 + invoke 约定

// ---------- 1. HTML builder：DSL 的教科书形态 ----------

@DslMarker        // 作用域标记：外层接收者的隐式 this 不再"漏"进内层 lambda
annotation class HtmlDsl

@HtmlDsl
class Tag(val name: String) : Node {
    private val children = mutableListOf<Node>()
    private val attrs = linkedMapOf<String, String>()

    var text: String = ""
        set(v) { children += Node.Text(v) }        // 赋值即追加文本节点

    fun attr(k: String, v: String) { attrs[k] = v }

    /** 嵌套标签：block 的接收者就是新建的子标签 */
    fun tag(name: String, block: Tag.() -> Unit = {}) {
        val t = Tag(name)
        t.block()
        children += t
    }

    fun body(block: Tag.() -> Unit) = tag("body", block)
    fun div(block: Tag.() -> Unit) = tag("div", block)
    fun p(block: Tag.() -> Unit) = tag("p", block)
    fun h1(block: Tag.() -> Unit) = tag("h1", block)

    override fun render(): String = buildString {
        append("<$name")
        for ((k, v) in attrs) append(" $k=\"$v\"")
        if (children.isEmpty()) { append("/>") } else {
            append(">")
            for (c in children) append(c.render())
            append("</$name>")
        }
    }
}

sealed interface Node {
    fun render(): String
    data class Text(val value: String) : Node {
        override fun render(): String = value
    }
}

fun html(block: Tag.() -> Unit): Tag = Tag("html").apply(block)

// ---------- 2. 中缀 DSL：should eq 风格的断言 ----------

infix fun <T> T.should(expected: T): T {
    check(this == expected) { "断言失败: 期望 $expected, 实际 $this" }
    return this
}

infix fun <T> T.eq(expected: T) = should(expected)

// ---------- 3. invoke 约定：对象本身可调用 ----------

class Router {
    private val routes = mutableListOf<String>()
    operator fun invoke(path: String): String {
        routes += path
        return "已注册 $path（累计 ${routes.size} 条）"
    }
}

// ---------- 4. 类型安全构建器：依赖声明 ----------

class Deps {
    val list = mutableListOf<String>()
    fun implementation(id: String) { list += "implementation: $id" }
    fun testImplementation(id: String) { list += "test: $id" }
}
fun dependencies(block: Deps.() -> Unit): List<String> = Deps().apply(block).list
