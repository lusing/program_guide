// 高阶函数
fun operate(a: Int, b: Int, operation: (Int, Int) -> Int): Int {
    return operation(a, b)
}

val sum = operate(10, 5) { x, y -> x + y }
val diff = operate(10, 5) { x, y -> x - y }
