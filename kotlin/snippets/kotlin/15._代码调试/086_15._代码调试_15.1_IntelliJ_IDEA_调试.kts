// 监视表达式
val data = listOf(1, 2, 3, 4, 5)
val filtered = data.filter { it > 2 }
val mapped = filtered.map { it * 2 }

// Watch expressions:
// filtered.size
// mapped.sum()
// data[0]

// 字符串模板调试
val name = "Alice"
val age = 25
println("Debug: name=$name, age=$age")  // 简单调试

// 使用 require
fun process(value: Int) {
    require(value > 0) { "Value must be positive, but was $value" }
    // ...
}

// 使用 check
fun getItem(index: Int): String {
    check(index in 0..list.size) { "Index: $index, size: ${list.size}" }
    return list[index]
}
