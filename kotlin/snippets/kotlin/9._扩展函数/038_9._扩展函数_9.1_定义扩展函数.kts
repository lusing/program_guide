// 为 String 添加函数
fun String.lastChar(): Char = this[this.length - 1]

// 为 List 添加函数
fun <T> List<T>.second(): T = this[1]

// 使用
"Hello".lastChar()  // 'o'
listOf(1, 2, 3).second()  // 2
