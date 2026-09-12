// 简单的 DSL 示例
fun buildString(block: StringBuilder.() -> Unit): String {
    return StringBuilder().apply(block).toString()
}

val str = buildString {
    append("Hello")
    append(" ")
    append("World")
}

// HTML DSL
fun html(block: HTML.() -> Unit): HTML = HTML().apply(block)

class HTML {
    private val children = mutableListOf<Tag>()

    fun body(block: Body.() -> Unit) {
        children.add(Body().apply(block))
    }
}

class Body : Tag() {
    fun h1(block: Heading.() -> Unit) {
        children.add(Heading().apply(block))
    }
}

open class Tag {
    private val children = mutableListOf<Tag>()

    fun childrenString(): String =
        children.joinToString("\n") { it.render() }

    open fun render(): String =
        "<${this::class.simpleName}>${childrenString()}</${this::class.simpleName}>"
}

class Heading : Tag() {
    operator fun String.unaryPlus() {
        children.add(Text(this@Heading, this))
    }
}

class Text(private val parent: Tag, private val text: String) : Tag() {
    override fun render(): String = text
}
