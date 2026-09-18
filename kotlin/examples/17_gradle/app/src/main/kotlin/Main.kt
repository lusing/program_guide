import lib.LibInfo
import lib.greeting
import lib.wordFreq

/** app 的演示入口：组合 lib 提供的能力。 */
fun renderReport(names: List<String>, text: String): String = buildString {
    appendLine("== ${LibInfo.NAME} v${LibInfo.VERSION} ==")
    for (n in names) appendLine(greeting(n))
    appendLine("词频: " + wordFreq(text).joinToString(", ") { "${it.first}x${it.second}" })
    appendLine("来自 ${names.size} 位调用者")
}

fun main() {
    print(renderReport(listOf("Gradle", "Kotlin"), "kotlin gradle kotlin build gradle kotlin"))
}
