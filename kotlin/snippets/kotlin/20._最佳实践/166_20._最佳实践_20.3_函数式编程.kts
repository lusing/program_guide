// 链式调用
val result = listOf(1, 2, 3, 4, 5)
    .filter { it % 2 == 0 }
    .map { it * it }
    .sum()

// 使用 apply 初始化对象
val person = Person().apply {
    name = "Alice"
    age = 25
    city = "Beijing"
}

// 使用 with 复用接收者
with(StringBuilder()) {
    append("Hello")
    append(" ")
    append("World")
    println(toString())
}
