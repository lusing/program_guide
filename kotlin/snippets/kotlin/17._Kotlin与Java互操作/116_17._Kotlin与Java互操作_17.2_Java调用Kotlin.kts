// Kotlin 文件: Utils.kt

// 顶层函数
@JvmName("joinToStringCustom")
fun join(list: List<String>, separator: String): String {
    return list.joinToString(separator)
}

// 扩展函数
@JvmName("capitalizeFirst")
fun String.capitalizeFirstChar(): String {
    return replaceFirstChar { it.uppercase() }
}
