// require - 用于参数验证
fun divide(a: Int, b: Int): Int {
    require(b != 0) { "Divisor cannot be zero" }
    return a / b
}

// check - 用于状态验证
fun getElement(list: List<Int>, index: Int): Int {
    check(index in list.indices) { "Index out of bounds: $index" }
    return list[index]
}

// requireNotNull - 非空检查
fun process(name: String?) {
    val validName = requireNotNull(name) { "Name cannot be null" }
    println(validName)
}

// checkNotNull
fun process2(name: String?) {
    val validName = checkNotNull(name) { "Name cannot be null" }
    println(validName)
}

// assert - 调试断言
fun process3(value: Int) {
    assert(value > 0) { "Value must be positive" }
    // ...
}
