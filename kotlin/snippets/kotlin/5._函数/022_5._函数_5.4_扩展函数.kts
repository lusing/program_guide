// 为现有类添加新功能
fun String.lastChar(): Char = this[this.length - 1]

"Hello".lastChar()  // 'o'

// 带接收者的函数字面量
val sum = { x: Int, y: Int -> x + y }
