package lib

/** 问好——lib 模块对外提供的纯函数。 */
fun greeting(name: String): String = "Hello, $name!"

/** 按出现次数统计词频，返回按次数降序、同次数按字典序的稳定结果。 */
fun wordFreq(text: String): List<Pair<String, Int>> =
    text.split(Regex("\\s+")).filter { it.isNotBlank() }
        .groupingBy { it.lowercase() }
        .eachCount()
        .entries
        .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key })
        .map { it.key to it.value }

object LibInfo {
    const val NAME: String = "kt-gradle-demo-lib"
    const val VERSION: String = "1.0.0"
}
