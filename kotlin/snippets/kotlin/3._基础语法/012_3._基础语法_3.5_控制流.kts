// if 是表达式，有返回值
val max = if (a > b) a else b

// 多条件
val result = when {
    a > b -> "a > b"
    a < b -> "a < b"
    else -> "a == b"
}
