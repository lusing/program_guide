// inline 减少 Lambda 造成的对象分配
inline fun measureTime(block: () -> Unit) {
    val start = System.currentTimeMillis()
    block()
    println("Time: ${System.currentTimeMillis() - start}ms")
}

measureTime {
    // 你的代码
    Thread.sleep(100)
}
