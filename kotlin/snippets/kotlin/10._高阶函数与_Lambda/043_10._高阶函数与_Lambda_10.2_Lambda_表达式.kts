// 基本 Lambda
val add: (Int, Int) -> Int = { x, y -> x + y }

// 单参数 Lambda (it)
val squared = listOf(1, 2, 3, 4).map { it * it }

// with 与 run
val str = "Hello"
with(str) {
    println(length)
    println(uppercase())
}

val result = run {
    val x = 10
    val y = 20
    x + y
}
