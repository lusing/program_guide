// DSL 示例
html {
    head {
        title { +"My Page" }
    }
    body {
        h1 { +"Welcome" }
    }
}

// 定义
fun html(block: HTML.() -> Unit): HTML {
    val html = HTML()
    html.block()
    return html
}
