when (x) {
    1 -> println("x == 1")
    2 -> println("x == 2")
    3, 4 -> println("x is 3 or 4")
    in 5..10 -> println("x is 5-10")
    !in 20..30 -> println("x is not 20-30")
    is String -> println("x is a String")
    else -> println("default")
}

// 带参数的 when
when (x) {
    in 1..10 -> println("in range")
    !in 20..30 -> println("not in range")
}
