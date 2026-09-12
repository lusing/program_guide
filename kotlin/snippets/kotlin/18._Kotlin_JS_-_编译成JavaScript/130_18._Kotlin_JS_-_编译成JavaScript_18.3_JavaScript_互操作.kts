import kotlin.js.Json

// 动态类型
external fun console.log(message: Any?)

external interface Window {
    val innerWidth: Int
    fun alert(message: String)
}

external val window: Window

fun main() {
    console.log("Hello from Kotlin!")
    window.alert("Kotlin says hello!")
}
