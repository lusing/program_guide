// 声明外部 JavaScript 库的类型
external interface JQuery {
    fun click(handler: (dynamic) -> Unit): JQuery
    fun text(): String
    fun text(value: String): JQuery
}

external fun jQuery(selector: String): JQuery
external val `$`: (String) -> JQuery

// 使用
fun main() {
    `$`("#button").click {
        console.log("Button clicked!")
    }
}
